import 'package:flutter_test/flutter_test.dart';
import 'package:mneme/services/database_downloader.dart';
import 'package:mneme/services/database_initializer.dart';
import 'package:mneme/services/manifest_service.dart';
import 'package:mocktail/mocktail.dart';

class MockManifestService extends Mock implements ManifestService {}

class MockDatabaseDownloader extends Mock implements DatabaseDownloader {}

void main() {
  late MockManifestService mockManifestService;
  late MockDatabaseDownloader mockDatabaseDownloader;
  late DatabaseInitializer initializer;

  setUp(() {
    mockManifestService = MockManifestService();
    mockDatabaseDownloader = MockDatabaseDownloader();
    initializer = DatabaseInitializer(
      manifestService: mockManifestService,
      databaseDownloader: mockDatabaseDownloader,
    );
  });

  group('DatabaseInitializer', () {
    test('skips download if database already available', () async {
      when(
        () => mockDatabaseDownloader.isDatabaseAvailable('en'),
      ).thenAnswer((_) async => true);

      await initializer.initializeDatabase(language: 'en');

      verify(() => mockDatabaseDownloader.isDatabaseAvailable('en')).called(1);
      verifyNever(() => mockManifestService.fetchManifest());
      verifyNever(
        () => mockDatabaseDownloader.downloadDatabase(
          lang: any(named: 'lang'),
          url: any(named: 'url'),
          expectedSize: any(named: 'expectedSize'),
        ),
      );
    });

    test('downloads database if not available', () async {
      final manifest = {
        'en': {
          'file': 'en.db.zst',
          'size': 1024,
          'hash': 'abc123',
          'version': '1.0+1',
        },
      };

      when(
        () => mockDatabaseDownloader.isDatabaseAvailable('en'),
      ).thenAnswer((_) async => false);
      when(
        () => mockManifestService.fetchManifest(),
      ).thenAnswer((_) async => manifest);
      when(
        () => mockDatabaseDownloader.downloadDatabase(
          lang: any(named: 'lang'),
          url: any(named: 'url'),
          expectedSize: any(named: 'expectedSize'),
        ),
      ).thenAnswer((_) async {});

      await initializer.initializeDatabase(language: 'en');

      verify(() => mockDatabaseDownloader.isDatabaseAvailable('en')).called(1);
      verify(() => mockManifestService.fetchManifest()).called(1);
      verify(
        () => mockDatabaseDownloader.downloadDatabase(
          lang: 'en',
          url:
              'https://github.com/mneme-verse/mneme/releases/download/data-v1.0+1/en.db.zst',
          expectedSize: 1024,
        ),
      ).called(1);
    });

    test('throws if language not in manifest', () async {
      when(
        () => mockDatabaseDownloader.isDatabaseAvailable('fr'),
      ).thenAnswer((_) async => false);
      when(
        () => mockManifestService.fetchManifest(),
      ).thenAnswer(
        (_) async => <String, dynamic>{'en': <String, dynamic>{}},
      );

      expect(
        () => initializer.initializeDatabase(language: 'fr'),
        throwsException,
      );
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
