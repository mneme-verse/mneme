/// Utility to sanitize and validate file paths and language codes.
class PathSanitizer {
  /// Returns true if [code] is a valid language code (e.g., "en", "en-US").
  /// Only allows alphanumeric characters and hyphens.
  static bool isValidLanguageCode(String code) {
    final regex = RegExp(r'^[a-zA-Z0-9-]+$');
    return regex.hasMatch(code);
  }

  /// Returns true if [filename] is a safe filename (no path separators or ..).
  static bool isSafeFilename(String filename) {
    if (filename.contains('/') || filename.contains(r'\')) {
      return false;
    }
    if (filename.contains('..')) {
      return false;
    }
    return true;
  }
}
