import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing user preferences.
class PreferencesService {
  PreferencesService({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;

  static const _selectedLanguageKey = 'selected_language';

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
}
