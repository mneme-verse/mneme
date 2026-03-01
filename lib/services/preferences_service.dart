import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing user preferences.
class PreferencesService {
  PreferencesService({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;

  static const _selectedLanguageKey = 'selected_language';
  static const _cachedManifestKey = 'cached_manifest';

  /// Initialize the preferences service.
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get the selected language code, or null if not set.
  String? getSelectedLanguage() {
    return _prefs?.getString(_selectedLanguageKey);
  }

  /// Set the selected language code.
  Future<bool> setSelectedLanguage(String languageCode) async {
    await init();
    return _prefs!.setString(_selectedLanguageKey, languageCode);
  }

  /// Clear the selected language.
  Future<bool> clearSelectedLanguage() async {
    await init();
    return _prefs!.remove(_selectedLanguageKey);
  }

  /// Get the cached manifest JSON string, or null if not set.
  String? getCachedManifest() {
    return _prefs?.getString(_cachedManifestKey);
  }

  /// Set the cached manifest JSON string.
  Future<bool> setCachedManifest(String manifestJson) async {
    await init();
    return _prefs!.setString(_cachedManifestKey, manifestJson);
  }
}
