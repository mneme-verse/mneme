import 'package:flutter_test/flutter_test.dart';
import 'package:mneme/services/database_downloader.dart';
import 'package:mneme/services/database_initializer.dart';
import 'package:mocktail/mocktail.dart';

class MockDatabaseDownloader extends Mock implements DatabaseDownloader {}

void main() {
  late MockDatabaseDownloader mockDatabaseDownloader;
  late DatabaseInitializer initializer;

  setUp(() {
    mockDatabaseDownloader = MockDatabaseDownloader();
    initializer = DatabaseInitializer(
      databaseDownloader: mockDatabaseDownloader,
    );
  });

  group('DatabaseInitializer', () {
    test('skips download if database already available', () async {
      when(
        () => mockDatabaseDownloader.isDatabaseAvailable('en'),
      ).thenAnswer((_) async => true);

      await initializer.initializeDatabase(
        language: 'en',
        url: 'http://example.com/en.db.zst',
        expectedSize: 1024,
      );

      verify(() => mockDatabaseDownloader.isDatabaseAvailable('en')).called(1);
      verifyNever(
        () => mockDatabaseDownloader.downloadDatabase(
          lang: any(named: 'lang'),
          url: any(named: 'url'),
          expectedSize: any(named: 'expectedSize'),
          expectedHash: any(named: 'expectedHash'),
          onProgress: any(named: 'onProgress'),
        ),
      );
    });

    test('downloads database if not available', () async {
      when(
        () => mockDatabaseDownloader.isDatabaseAvailable('en'),
      ).thenAnswer((_) async => false);
      when(
        () => mockDatabaseDownloader.downloadDatabase(
          lang: any(named: 'lang'),
          url: any(named: 'url'),
          expectedSize: any(named: 'expectedSize'),
          expectedHash: any(named: 'expectedHash'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((_) async {});

      await initializer.initializeDatabase(
        language: 'en',
        url: 'http://example.com/en.db.zst',
        expectedSize: 1024,
        expectedHash: 'abc123',
      );

      verify(() => mockDatabaseDownloader.isDatabaseAvailable('en')).called(1);
      verify(
        () => mockDatabaseDownloader.downloadDatabase(
          lang: 'en',
          url: 'http://example.com/en.db.zst',
          expectedSize: 1024,
          expectedHash: 'abc123',
          onProgress: any(named: 'onProgress'),
        ),
      ).called(1);
    });

    test('isDatabaseAvailable delegates to downloader', () async {
      when(
        () => mockDatabaseDownloader.isDatabaseAvailable('en'),
      ).thenAnswer((_) async => true);

      final result = await initializer.isDatabaseAvailable('en');

      expect(result, isTrue);
      verify(() => mockDatabaseDownloader.isDatabaseAvailable('en')).called(1);
    });
  });
}
