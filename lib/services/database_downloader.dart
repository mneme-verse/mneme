import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:es_compression/zstd.dart' as es;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:zstandard/zstandard.dart';

/// Service to handle downloading and decompressing the database.
class DatabaseDownloader {
  DatabaseDownloader({
    Dio? dio,
    Zstandard? zstandard,
    es.ZstdCodec? esZstd,
  }) : _dio = dio ?? Dio(),
       _zstandard = zstandard ?? Zstandard(),
       _esZstd = esZstd ?? es.ZstdCodec();

  final Dio _dio;
  final Zstandard _zstandard;
  final es.ZstdCodec _esZstd;

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
    void Function(int count, int total)? onProgress,
  }) async {
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
    } catch (e) {
      // Clean up if download fails
      final file = File(zstPath);
      if (file.existsSync()) {
        await file.delete();
      }
      throw Exception('Download failed: $e');
    }

    // 2. Decompress .zst to .db using zstandard package
    try {
      final compressedBytes = await File(zstPath).readAsBytes();
      List<int>? decompressedBytes;
      if (Platform.isLinux) {
        decompressedBytes = _esZstd.decode(compressedBytes);
      } else {
        decompressedBytes = await _zstandard.decompress(
          Uint8List.fromList(compressedBytes),
        );
      }
      if (decompressedBytes == null) {
        throw Exception('Decompression failed: Result is null');
      }
      await File(dbPath).writeAsBytes(decompressedBytes);

      // 3. Cleanup .zst file
      await File(zstPath).delete();
    } catch (e) {
      // Clean up if decompression fails
      final file = File(dbPath);
      if (file.existsSync()) {
        await file.delete();
      }
      throw Exception('Decompression failed: $e');
    }
  }

  Future<String> _getDatabasePath(String lang) async {
    final docsDir = await getApplicationDocumentsDirectory();
    return p.join(docsDir.path, '$lang.db');
  }
}
