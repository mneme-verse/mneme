import 'package:flutter_test/flutter_test.dart';
import 'package:mneme/features/language_selection/models/language_model.dart';

void main() {
  group('LanguageModel', () {
    const licenseJson = {
      'text': 'License Text',
      'url': 'http://license.url',
    };
    const licenseModel = LicenseModel(
      text: 'License Text',
      url: 'http://license.url',
    );

    const languageJson = {
      'file': 'en.db.zst',
      'size': 1024,
      'hash': 'abc',
      'version': '1.0',
      'license': licenseJson,
    };

    const languageModel = LanguageModel(
      code: 'en',
      name: 'English',
      license: licenseModel,
      size: 1024,
      hash: 'abc',
      version: '1.0',
    );

    test('supports value equality', () {
      expect(
        const LanguageModel(
          code: 'en',
          name: 'English',
          license: licenseModel,
          size: 1024,
          hash: 'abc',
          version: '1.0',
        ),
        equals(languageModel),
      );
    });

    test('fromJson creates correct instance', () {
      expect(
        LanguageModel.fromJson('en', languageJson, 'English'),
        equals(languageModel),
      );
    });

    test('props are correct', () {
      expect(
        languageModel.props,
        equals(['en', 'English', licenseModel, 1024, 'abc', '1.0']),
      );
    });
  });

  group('LicenseModel', () {
    const json = {
      'text': 'License Text',
      'url': 'http://license.url',
    };
    const model = LicenseModel(
      text: 'License Text',
      url: 'http://license.url',
    );

    test('supports value equality', () {
      expect(
        const LicenseModel(
          text: 'License Text',
          url: 'http://license.url',
        ),
        equals(model),
      );
    });

    test('fromJson creates correct instance', () {
      expect(LicenseModel.fromJson(json), equals(model));
    });

    test('props are correct', () {
      expect(model.props, equals(['License Text', 'http://license.url']));
    });
  });
}
