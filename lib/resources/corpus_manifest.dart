import 'dart:convert';

import 'package:http/http.dart' as http;

/// Base URL of the published schema-two corpus release.
Uri corpusReleaseBase(String tag) =>
    Uri.parse('https://github.com/mneme-verse/mneme/releases/download/$tag');

/// Current corpus release tag. App releases and corpus data tags stay
/// separate, so bumping this never touches app versioning.
const corpusReleaseTag = 'data-v1';

/// One language pack from the published `manifest.json`.
class CorpusPackInfo {
  const CorpusPackInfo({
    required this.language,
    required this.file,
    required this.sha256,
    required this.sizeBytes,
    required this.version,
  });

  final String language;
  final String file;
  final String sha256;
  final int sizeBytes;
  final String version;
}

/// Thrown when the published manifest does not satisfy the schema-two
/// contract.
class CorpusManifestException implements Exception {
  const CorpusManifestException(this.message);

  final String message;

  @override
  String toString() => 'CorpusManifestException($message)';
}

/// Fetches and validates the corpus manifest, then resolves pack URLs.
class CorpusManifestClient {
  CorpusManifestClient({
    http.Client? client,
    Uri? manifestUrl,
  }) : _client = client ?? http.Client(),
       manifestUrl =
           manifestUrl ??
           corpusReleaseBase(corpusReleaseTag).resolve('manifest.json');

  final http.Client _client;
  final Uri manifestUrl;

  /// Returns the pack entry for [language].
  ///
  /// Throws [CorpusManifestException] for missing entries or entries that
  /// violate the schema-two contract (`sha256` hex, positive size,
  /// `schema_version` 2).
  Future<CorpusPackInfo> packFor(String language) async {
    final response = await _client.get(manifestUrl);
    if (response.statusCode != 200) {
      throw CorpusManifestException(
        'manifest fetch failed: HTTP ${response.statusCode}',
      );
    }

    final Map<String, dynamic> manifest;
    try {
      manifest =
          json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } on FormatException catch (error) {
      throw CorpusManifestException('manifest is not JSON: $error');
    }

    final entry = manifest[language];
    if (entry is! Map<String, dynamic>) {
      throw CorpusManifestException(
        'manifest has no entry for "$language" and no fallback is allowed',
      );
    }

    final schemaVersion = entry['schema_version'];
    if (schemaVersion != 2) {
      throw CorpusManifestException(
        'unsupported schema_version $schemaVersion for "$language"',
      );
    }

    final sha256 = entry['sha256'];
    if (sha256 is! String || !RegExp(r'^[0-9a-f]{64}$').hasMatch(sha256)) {
      throw CorpusManifestException(
        'entry "$language" lacks a valid sha256 checksum',
      );
    }

    final size = entry['size'];
    if (size is! int || size <= 0) {
      throw CorpusManifestException(
        'entry "$language" lacks a positive size',
      );
    }

    final file = entry['file'];
    if (file is! String || !file.endsWith('.db.zst')) {
      throw CorpusManifestException(
        'entry "$language" lacks a .db.zst file name',
      );
    }

    return CorpusPackInfo(
      language: language,
      file: file,
      sha256: sha256,
      sizeBytes: size,
      version: (entry['version'] ?? '').toString(),
    );
  }

  /// Download URL for [pack] inside the same release as the manifest.
  Uri packUrl(CorpusPackInfo pack) => manifestUrl.resolve(pack.file);
}
