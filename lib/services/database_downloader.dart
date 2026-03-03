import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:es_compression/zstd.dart' as es;
import 'package:mneme/utils/path_sanitizer.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:zstandard/zstandard.dart';

/// Exception thrown by [DatabaseDownloader] operations.
class DatabaseDownloadException implements Exception {
  DatabaseDownloadException(this.message);
  final String message;
  @override
  String toString() => 'DatabaseDownloadException: $message';
}

/// Service to handle downloading and decompressing the database.
class DatabaseDownloader {
  DatabaseDownloader({
    Dio? dio,
    Zstandard? zstandard,
    es.ZstdCodec? esZstd,
    bool? isLinux,
  }) : _dio = dio ?? Dio(), // coverage:ignore-line
       _zstandard = zstandard,
       _esZstd = esZstd ?? es.ZstdCodec(), // coverage:ignore-line
       _isLinux = isLinux ?? Platform.isLinux;

  final Dio _dio;
  final Zstandard? _zstandard;
  final es.ZstdCodec _esZstd;
  final bool _isLinux;

  /// Lazily initialized [Zstandard] instance used on non-Linux platforms.
  late final Zstandard _lazyZstandard = _zstandard ?? Zstandard();

  /// Returns the [Zstandard] instance, creating it lazily.
  /// Only called on non-Linux platforms.
  Zstandard get _zstd => _lazyZstandard;

  /// Checks if the database file for [lang] exists.
  Future<bool> isDatabaseAvailable(String lang) async {
    final dbPath = await _getDatabasePath(lang);
    return File(dbPath).existsSync();
  }

  /// Downloads and extracts the database for [lang].
  ///
  /// [url] is the direct link to the .db.zst file.
  /// [onProgress] can be used to track download progress.
  Future<void> downloadDatabase({
    required String lang,
    required String url,
    required int expectedSize,
    String? expectedHash,
    void Function(int count, int total)? onProgress,
  }) async {
    if (!PathSanitizer.isValidLanguageCode(lang)) {
      throw ArgumentError('Invalid language code: $lang');
    }
    final docsDir = await getApplicationDocumentsDirectory();
    final zstPath = p.join(docsDir.path, '$lang.db.zst');
    final dbPath = p.join(docsDir.path, '$lang.db');

    // 1. Download .zst file
    try {
      await _dio.download(
        url,
        zstPath,
        onReceiveProgress: onProgress,
      );

      final downloadedFile = File(zstPath);
      final actualSize = await downloadedFile.length();
      if (actualSize != expectedSize) {
        throw DatabaseDownloadException(
          'Download failed: size mismatch (expected $expectedSize bytes, '
          'got $actualSize bytes)',
        );
      }

      // Verify hash of the compressed file if provided
      if (expectedHash != null) {
        final digest = await sha256.bind(downloadedFile.openRead()).first;
        if (digest.toString() != expectedHash) {
          throw DatabaseDownloadException(
            'Hash mismatch (expected $expectedHash, got $digest)',
          );
        }
      }
    } catch (e) {
      await _deleteIfExists(zstPath);
      if (e is DatabaseDownloadException) rethrow;
      throw DatabaseDownloadException('Download failed: $e');
    }

    // 2. Decompress .zst to .db
    try {
      if (_isLinux) {
        final inputStream = File(zstPath).openRead();
        final outputStream = File(dbPath).openWrite();
        await inputStream.transform(_esZstd.decoder).pipe(outputStream);
      } else {
        // zstandard package does not currently support streaming decompression
        final compressedBytes = await File(zstPath).readAsBytes();
        final decompressedBytes = await _zstd.decompress(
          Uint8List.fromList(compressedBytes),
        );
        if (decompressedBytes == null) {
          throw DatabaseDownloadException(
            'Decompression failed: Result is null',
          );
        }
        await File(dbPath).writeAsBytes(decompressedBytes);
      }
    } catch (e) {
      await _deleteIfExists(dbPath);
      await _deleteIfExists(zstPath);
      if (e is DatabaseDownloadException) rethrow;
      throw DatabaseDownloadException('Decompression failed: $e');
    }

    // 3. Cleanup .zst file
    await _deleteIfExists(zstPath);
  }

  Future<void> _deleteIfExists(String path) async {
    final file = File(path);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  Future<String> _getDatabasePath(String lang) async {
    if (!PathSanitizer.isValidLanguageCode(lang)) {
      throw ArgumentError('Invalid language code: $lang');
    }
    final docsDir = await getApplicationDocumentsDirectory();
    return p.join(docsDir.path, '$lang.db');
  }
}
