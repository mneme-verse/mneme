import 'package:flutter_test/flutter_test.dart';
import 'package:mneme/utils/path_sanitizer.dart';

void main() {
  group('PathSanitizer', () {
    group('isValidLanguageCode', () {
      test('returns true for simple codes', () {
        expect(PathSanitizer.isValidLanguageCode('en'), isTrue);
        expect(PathSanitizer.isValidLanguageCode('fr'), isTrue);
      });

      test('returns true for codes with hyphens', () {
        expect(PathSanitizer.isValidLanguageCode('en-US'), isTrue);
        expect(PathSanitizer.isValidLanguageCode('zh-Hans'), isTrue);
      });

      test('returns false for codes with path separators', () {
        expect(PathSanitizer.isValidLanguageCode('en/US'), isFalse);
        expect(PathSanitizer.isValidLanguageCode('../en'), isFalse);
        expect(PathSanitizer.isValidLanguageCode(r'en\US'), isFalse);
      });

      test('returns false for codes with special characters', () {
        expect(PathSanitizer.isValidLanguageCode('en_US'), isFalse);
        expect(PathSanitizer.isValidLanguageCode('en.db'), isFalse);
        expect(PathSanitizer.isValidLanguageCode('en;'), isFalse);
      });

      test('returns false for empty string', () {
        expect(PathSanitizer.isValidLanguageCode(''), isFalse);
      });
    });

    group('isSafeFilename', () {
      test('returns true for simple filenames', () {
        expect(PathSanitizer.isSafeFilename('en.db'), isTrue);
        expect(PathSanitizer.isSafeFilename('data.zst'), isTrue);
      });

      test('returns false for path separators', () {
        expect(PathSanitizer.isSafeFilename('sub/en.db'), isFalse);
        expect(PathSanitizer.isSafeFilename(r'sub\en.db'), isFalse);
      });

      test('returns false for parent directory references', () {
        expect(PathSanitizer.isSafeFilename('../en.db'), isFalse);
        expect(
          PathSanitizer.isSafeFilename('en..db'),
          isFalse,
        ); // technically safe but we block ..
      });
    });
  });
}
