import 'package:mneme/constants.dart';
import 'package:mneme/services/database_downloader.dart';
import 'package:mneme/services/manifest_service.dart';

/// Orchestrates database initialization including downloading if needed.
class DatabaseInitializer {
  DatabaseInitializer({
    ManifestService? manifestService,
    DatabaseDownloader? databaseDownloader,
  }) : _manifestService = manifestService ?? ManifestService(),
       _databaseDownloader = databaseDownloader ?? DatabaseDownloader();

  final ManifestService _manifestService;
  final DatabaseDownloader _databaseDownloader;

  /// Initialize the database for [language].
  /// Downloads if not available locally.
  Future<void> initializeDatabase({
    required String language,
    void Function(int received, int total)? onProgress,
  }) async {
    // Check if already available
    if (await _databaseDownloader.isDatabaseAvailable(language)) {
      return;
    }

    // Fetch manifest
    final manifest = await _manifestService.fetchManifest();

    // Get language entry from manifest
    final languageEntry = manifest[language] as Map<String, dynamic>?;
    if (languageEntry == null) {
      throw Exception('Language $language not found in manifest');
    }

    // Extract file info
    final filename = languageEntry['file'] as String;
    final size = languageEntry['size'] as int;

    // Construct download URL
    final downloadUrl = '$kDatabaseReleaseBaseUrl/$filename';

    // Download and decompress
    await _databaseDownloader.downloadDatabase(
      lang: language,
      url: downloadUrl,
      expectedSize: size,
      onProgress: onProgress,
    );
  }

  /// Check if database is available for [language].
  Future<bool> isDatabaseAvailable(String language) async {
    return _databaseDownloader.isDatabaseAvailable(language);
  }
}
