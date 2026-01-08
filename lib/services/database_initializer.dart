import 'package:mneme/services/database_downloader.dart';

/// Orchestrates database initialization including downloading if needed.
class DatabaseInitializer {
  DatabaseInitializer({
    DatabaseDownloader? databaseDownloader,
  }) : _databaseDownloader = databaseDownloader ?? DatabaseDownloader();

  final DatabaseDownloader _databaseDownloader;

  /// Initialize the database for [language].
  ///
  /// Downloads if not available locally using the provided [url],
  /// [expectedSize], and optional [expectedHash] from the manifest.
  Future<void> initializeDatabase({
    required String language,
    required String url,
    required int expectedSize,
    String? expectedHash,
    void Function(int received, int total)? onProgress,
  }) async {
    // Check if already available
    if (await _databaseDownloader.isDatabaseAvailable(language)) {
      return;
    }

    // Download and decompress
    await _databaseDownloader.downloadDatabase(
      lang: language,
      url: url,
      expectedSize: expectedSize,
      expectedHash: expectedHash,
      onProgress: onProgress,
    );
  }

  /// Check if database is available for [language].
  Future<bool> isDatabaseAvailable(String language) async {
    return _databaseDownloader.isDatabaseAvailable(language);
  }
}
