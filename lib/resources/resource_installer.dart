import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

/// Thrown when a download is canceled through [InstallCancelToken].
class InstallCanceledException implements Exception {
  const InstallCanceledException(this.resourceId);

  final String resourceId;

  @override
  String toString() => 'InstallCanceledException($resourceId)';
}

/// Thrown when downloaded bytes do not match the locked SHA-256.
class HashMismatchException implements Exception {
  const HashMismatchException(this.resourceId, this.actualSha256);

  final String resourceId;
  final String actualSha256;

  @override
  String toString() => 'HashMismatchException($resourceId, $actualSha256)';
}

/// Cooperative cancellation for installs.
class InstallCancelToken {
  bool _canceled = false;

  bool get isCanceled => _canceled;

  void cancel() => _canceled = true;
}

/// Progress of an in-flight download.
class InstallProgress {
  const InstallProgress({
    required this.receivedBytes,
    required this.totalBytes,
  });

  final int receivedBytes;

  /// Total bytes from the locked resource, or the server's content length
  /// when unknown.
  final int totalBytes;
}

/// Downloads a locked resource, verifies it against its pinned SHA-256 and
/// installs it atomically: bytes land in a `<id>.part` file next to the
/// final destination, and only a fully verified download is renamed into
/// place.
///
/// A canceled or failed install never touches the destination file.
class ResourceInstaller {
  ResourceInstaller({
    required http.Client client,
    required this.destinationDir,
  }) : _client = client;

  final http.Client _client;
  final Directory destinationDir;

  /// Installs a resource as `destinationDir/<id>` unless a file with the
  /// expected hash is already there.
  ///
  /// [onProgress] receives cumulative byte counts. Throws
  /// [InstallCanceledException] when [cancelToken] is canceled and
  /// [HashMismatchException] when verification fails.
  Future<File> install(
    String id,
    Uri url,
    String expectedSha256, {
    int? expectedSize,
    InstallCancelToken? cancelToken,
    void Function(InstallProgress progress)? onProgress,
  }) async {
    final destination = _destinationFor(id);
    if (await _fileMatches(destination, expectedSha256)) {
      return destination;
    }

    await destinationDir.create(recursive: true);
    final partial = File('${destination.path}.part');
    // Resume interrupted downloads: a surviving `.part` file restarts the
    // transfer where it stalled (screen lock, Doze, dead zone) instead of
    // from zero. Both release CDNs honor Range; a server that answers 200
    // restarts cleanly, and 416 (stale oversized part) does too.
    final resumeFrom = _prefixLength(partial);
    try {
      return await _attemptInstall(
        id: id,
        url: url,
        expectedSha256: expectedSha256,
        expectedSize: expectedSize,
        cancelToken: cancelToken,
        onProgress: onProgress,
        partial: partial,
        destination: destination,
        resumeFrom: resumeFrom,
      );
    } on _RestartCleanly {
      // The prefix cannot be continued: wipe it and transfer once from
      // zero. A second restart signal is a server failure, not a stale
      // prefix, so it propagates.
      if (partial.existsSync()) partial.deleteSync();
      return _attemptInstall(
        id: id,
        url: url,
        expectedSha256: expectedSha256,
        expectedSize: expectedSize,
        cancelToken: cancelToken,
        onProgress: onProgress,
        partial: partial,
        destination: destination,
        resumeFrom: 0,
      );
    }
  }

  /// Transfers one attempt, resuming from [resumeFrom] when positive.
  /// Throws [_RestartCleanly] when the server refuses the prefix.
  Future<File> _attemptInstall({
    required String id,
    required Uri url,
    required String expectedSha256,
    required int? expectedSize,
    required InstallCancelToken? cancelToken,
    required void Function(InstallProgress progress)? onProgress,
    required File partial,
    required File destination,
    required int resumeFrom,
  }) async {
    final digestSink = _DigestCollector();
    final hasher = sha256.startChunkedConversion(digestSink);
    if (resumeFrom > 0) {
      await partial.openRead().forEach(hasher.add);
    }
    var received = resumeFrom;
    var total = expectedSize;
    final sink = partial.openWrite(
      mode: resumeFrom > 0 ? FileMode.append : FileMode.write,
    );

    try {
      final response = await _sendRange(url, resumeFrom);
      if (response.statusCode == 416 && resumeFrom > 0) {
        await response.stream.drain<void>();
        throw const _RestartCleanly();
      }
      if (response.statusCode != 200 && response.statusCode != 206) {
        await response.stream.drain<void>();
        throw HttpException(
          'Unexpected status ${response.statusCode} for $url',
        );
      }
      if (response.statusCode == 200 && resumeFrom > 0) {
        // The server ignored Range: the fed prefix is useless, restart.
        await response.stream.drain<void>();
        throw const _RestartCleanly();
      }
      total =
          expectedSize ??
          (response.statusCode == 206
              ? resumeFrom + (response.contentLength ?? 0)
              : response.contentLength ?? 0);
      await for (final chunk in response.stream) {
        if (cancelToken?.isCanceled ?? false) {
          // The `await for` below cancels its subscription when this
          // throws; the stream must not be drained manually here.
          throw InstallCanceledException(id);
        }
        sink.add(chunk);
        hasher.add(chunk);
        received += chunk.length;
        onProgress?.call(
          InstallProgress(receivedBytes: received, totalBytes: total),
        );
      }
      await sink.flush();
      await sink.close();
      hasher.close();

      final actualSha256 = digestSink.digest.toString();
      if (actualSha256 != expectedSha256) {
        throw HashMismatchException(id, actualSha256);
      }
      if (expectedSize != null && received != expectedSize) {
        throw HashMismatchException(id, actualSha256);
      }
      // A cancel that lands after the last chunk (from a final progress
      // callback, or while flushing and hashing) must still win: the
      // verified file is never installed after cancellation.
      if (cancelToken?.isCanceled ?? false) {
        throw InstallCanceledException(id);
      }

      // Atomic cutover: rename(2) replaces the destination atomically on
      // the supported POSIX targets (Android, Linux), so a crash can
      // leave the old or the new file behind, never a missing resource.
      // A stale backup from a previous version is removed if present.
      final staleBackup = File('${destination.path}.bak');
      if (staleBackup.existsSync()) {
        staleBackup.deleteSync();
      }
      await partial.rename(destination.path);
      return destination;
    } catch (error) {
      await sink.close();
      if (error is HashMismatchException || error is _RestartCleanly) {
        // A wrong prefix can never resume: drop it so the next attempt
        // starts clean. Canceled and failed transfers keep their prefix
        // for resume.
        if (partial.existsSync()) partial.deleteSync();
      }
      rethrow;
    }
  }

  /// Sends GET, asking to resume from [from] when positive.
  Future<http.StreamedResponse> _sendRange(Uri url, int from) {
    final request = http.Request('GET', url)
      ..followRedirects = true
      ..maxRedirects = 5;
    if (from > 0) request.headers['Range'] = 'bytes=$from-';
    return _client.send(request);
  }

  /// Length of a resumable prefix, zero when absent.
  int _prefixLength(File partial) {
    if (!partial.existsSync()) return 0;
    return partial.lengthSync();
  }

  /// Destination file for [id] without touching the filesystem.
  File pathFor(String id) => _destinationFor(id);

  /// Removes an installed resource. Missing files are not an error.
  Future<void> uninstall(String id) async {
    final destination = _destinationFor(id);
    if (destination.existsSync()) {
      destination.deleteSync();
    }
    for (final suffix in ['.part', '.bak']) {
      final leftover = File('${destination.path}$suffix');
      if (leftover.existsSync()) {
        leftover.deleteSync();
      }
    }
  }

  /// True when [id] is installed with the expected bytes.
  Future<bool> isInstalled(String id, String expectedSha256) async {
    return _fileMatches(_destinationFor(id), expectedSha256);
  }

  /// True when a file exists for [id]. Launch gate only; use [isInstalled]
  /// when the bytes must be verified.
  bool exists(String id) => _destinationFor(id).existsSync();

  File _destinationFor(String id) {
    if (!_isSafeFileName(id)) {
      throw ArgumentError.value(id, 'id', 'must be a plain file name');
    }
    return File(
      '${destinationDir.path}${Platform.pathSeparator}$id',
    );
  }

  /// File names must be single path segments so a manifest-controlled id
  /// can never escape [destinationDir]. The allowlist rejects separators,
  /// drive prefixes and dot segments in one check.
  bool _isSafeFileName(String id) {
    if (id.isEmpty || id == '.' || id == '..') return false;
    return RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(id);
  }

  Future<bool> _fileMatches(File file, String expectedSha256) async {
    if (!file.existsSync()) return false;
    // Stream the hash: installed models are hundreds of megabytes and
    // must never be buffered fully in memory for a validity check.
    final collector = _DigestCollector();
    final hasher = sha256.startChunkedConversion(collector);
    try {
      await file.openRead().forEach(hasher.add);
    } finally {
      hasher.close();
    }
    return collector.digest.toString() == expectedSha256.toLowerCase();
  }
}

/// Collects the final [Digest] produced by a chunked hash conversion.
class _DigestCollector implements Sink<Digest> {
  Digest? digest;

  @override
  void add(Digest data) {
    digest = data;
  }

  @override
  void close() {}
}

/// Signals that the server refused the resume prefix: the caller wipes
/// it and transfers once from zero.
class _RestartCleanly implements Exception {
  const _RestartCleanly();
}
