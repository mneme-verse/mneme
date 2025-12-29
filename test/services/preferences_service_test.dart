import 'package:flutter_test/flutter_test.dart';
import 'package:mneme/services/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late PreferencesService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    service = PreferencesService(prefs: prefs);
  });

  group('PreferencesService', () {
    test('getSelectedLanguage returns null when not set', () {
      expect(service.getSelectedLanguage(), isNull);
    });

    test('setSelectedLanguage saves and retrieves language', () async {
      await service.setSelectedLanguage('en');
      expect(service.getSelectedLanguage(), equals('en'));
    });

    test('clearSelectedLanguage removes language', () async {
      await service.setSelectedLanguage('en');
      await service.clearSelectedLanguage();
      expect(service.getSelectedLanguage(), isNull);
    });
  });
}
