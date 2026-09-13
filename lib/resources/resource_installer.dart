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
    final sink = partial.openWrite();
    final digestSink = _DigestCollector();
    final hasher = sha256.startChunkedConversion(digestSink);
    var received = 0;
    var total = expectedSize;

    try {
      final request = http.Request('GET', url)
        ..followRedirects = true
        ..maxRedirects = 5;
      final response = await _client.send(request);
      if (response.statusCode != 200) {
        await response.stream.drain<void>();
        throw HttpException(
          'Unexpected status ${response.statusCode} for $url',
        );
      }
      total = expectedSize ?? response.contentLength ?? 0;
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

      // Atomic cutover: stage the previous file aside so a crash or a
      // failed rename never loses the last known-good resource.
      final backup = File('${destination.path}.bak');
      if (backup.existsSync()) {
        backup.deleteSync();
      }
      final hadDestination = destination.existsSync();
      if (hadDestination) {
        destination.renameSync(backup.path);
      }
      try {
        await partial.rename(destination.path);
      } catch (_) {
        if (hadDestination && !destination.existsSync()) {
          backup.renameSync(destination.path);
        }
        rethrow;
      }
      if (backup.existsSync()) {
        backup.deleteSync();
      }
      return destination;
    } catch (_) {
      await sink.close();
      if (partial.existsSync()) {
        partial.deleteSync();
      }
      rethrow;
    }
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
