import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:mneme/constants.dart';

/// Service to fetch the database manifest from GitHub Releases.
class ManifestService {
  ManifestService({
    Dio? dio,
  }) : _dio = dio ?? Dio();

  final Dio _dio;

  // Default manifest URL; callers can override via the `urlOverride` parameter.
  static const _manifestUrl = '$kDatabaseReleaseBaseUrl/manifest.json';

  /// Fetches and parses the manifest.json
  Future<Map<String, dynamic>> fetchManifest({String? urlOverride}) async {
    final url = urlOverride ?? _manifestUrl;
    try {
      final response = await _dio.get<dynamic>(url);
      if (response.statusCode == 200 && response.data != null) {
        // Dio might return the data as String or Map depending on content-type
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return data;
        } else if (data is String) {
          // Parse JSON string manually
          return Map<String, dynamic>.from(
            jsonDecode(data) as Map,
          );
        } else {
          throw Exception('Unexpected response type: ${data.runtimeType}');
        }
      } else {
        throw Exception(
          'Failed to fetch manifest: ${response.statusCode} '
          '${response.statusMessage}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching manifest: $e');
    }
  }
}
