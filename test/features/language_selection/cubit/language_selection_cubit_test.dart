import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mneme/features/language_selection/cubit/language_selection_cubit.dart';
import 'package:mneme/features/language_selection/models/language_model.dart';
import 'package:mneme/services/database_initializer.dart';
import 'package:mneme/services/manifest_service.dart';
import 'package:mneme/services/preferences_service.dart';
import 'package:mocktail/mocktail.dart';

class MockManifestService extends Mock implements ManifestService {}

class MockDatabaseInitializer extends Mock implements DatabaseInitializer {}

class MockPreferencesService extends Mock implements PreferencesService {}

class _ThrowingMap extends Fake implements Map<String, dynamic> {
  @override
  bool get isNotEmpty => true;

  @override
  bool get isEmpty => false;

  @override
  int get length => 0;

  @override
  Iterable<String> get keys => [];

  @override
  void forEach(void Function(String key, dynamic value) action) {
    // Return empty for jsonEncode
  }

  // Custom method that we know dart:convert jsonEncode calls:
  dynamic toJson() => <String, dynamic>{};

  @override
  Iterable<MapEntry<String, dynamic>> get entries =>
      throw Exception('Parsing error');
}

void main() {
  group('LanguageSelectionCubit', () {
    late ManifestService manifestService;
    late DatabaseInitializer databaseInitializer;
    late PreferencesService preferencesService;
    late LanguageSelectionCubit cubit;

    const licenseModel = LicenseModel(
      text: 'License',
      url: 'url',
    );

    const enModel = LanguageModel(
      code: 'en',
      name: 'English',
      license: licenseModel,
      size: 100,
      hash: 'hash',
      version: '1.0',
    );

    const deModel = LanguageModel(
      code: 'de',
      name: 'Deutsch',
      license: licenseModel,
      size: 100,
      hash: 'hash',
      version: '1.0',
    );

    final manifestData = {
      'en': {
        'file': 'en.db.zst',
        'name': 'English',
        'size': 100,
        'hash': 'hash',
        'version': '1.0',
        'license': {'text': 'License', 'url': 'url'},
      },
      'de': {
        'file': 'de.db.zst',
        'name': 'Deutsch',
        'size': 100,
        'hash': 'hash',
        'version': '1.0',
        'license': {'text': 'License', 'url': 'url'},
      },
    };

    setUp(() {
      manifestService = MockManifestService();
      databaseInitializer = MockDatabaseInitializer();
      preferencesService = MockPreferencesService();

      cubit = LanguageSelectionCubit(
        manifestService: manifestService,
        databaseInitializer: databaseInitializer,
        preferencesService: preferencesService,
      );
    });

    test('initial state is correct', () {
      expect(cubit.state, const LanguageSelectionState());
    });

    group('loadLanguages', () {
      blocTest<LanguageSelectionCubit, LanguageSelectionState>(
        'emits [loading, loaded] when successful',
        setUp: () {
          when(
            () => manifestService.fetchManifest(),
          ).thenAnswer((_) async => manifestData);
        },
        build: () => cubit,
        act: (cubit) => cubit.loadLanguages(),
        expect: () => [
          const LanguageSelectionState(status: LanguageSelectionStatus.loading),
          const LanguageSelectionState(
            status: LanguageSelectionStatus.loaded,
            // Sorted alphabetically by name: Deutsch, English
            availableLanguages: [deModel, enModel],
          ),
        ],
      );

      blocTest<LanguageSelectionCubit, LanguageSelectionState>(
        'emits [loading, error] when fetch fails',
        setUp: () {
          when(
            () => manifestService.fetchManifest(),
          ).thenThrow(Exception('Network error'));
        },
        build: () => cubit,
        act: (cubit) => cubit.loadLanguages(),
        expect: () => [
          const LanguageSelectionState(status: LanguageSelectionStatus.loading),
          const LanguageSelectionState(
            status: LanguageSelectionStatus.error,
            errorMessage: 'Exception: Network error',
          ),
        ],
      );
      blocTest<LanguageSelectionCubit, LanguageSelectionState>(
        'filters out non-language manifest entries',
        setUp: () {
          when(
            () => manifestService.fetchManifest(),
          ).thenAnswer(
            (_) async => <String, dynamic>{
              ...manifestData,
              // Non-map metadata entry
              'license': 'MIT',
              // Map missing required keys
              'meta': <String, dynamic>{'version': '1.0'},
            },
          );
        },
        build: () => cubit,
        act: (cubit) => cubit.loadLanguages(),
        expect: () => [
          const LanguageSelectionState(status: LanguageSelectionStatus.loading),
          const LanguageSelectionState(
            status: LanguageSelectionStatus.loaded,
            // Only valid language entries, sorted: Deutsch, English
            availableLanguages: [deModel, enModel],
          ),
        ],
      );

      blocTest<LanguageSelectionCubit, LanguageSelectionState>(
        'emits [loading, loaded] with empty list '
        'when manifest has only non-language entries',
        setUp: () {
          when(
            () => manifestService.fetchManifest(),
          ).thenAnswer(
            (_) async => <String, dynamic>{
              'en': 'not a map',
            },
          );
        },
        build: () => cubit,
        act: (cubit) => cubit.loadLanguages(),
        expect: () => [
          const LanguageSelectionState(status: LanguageSelectionStatus.loading),
          const LanguageSelectionState(
            status: LanguageSelectionStatus.loaded,
          ),
        ],
      );

      blocTest<LanguageSelectionCubit, LanguageSelectionState>(
        'emits [loading, loaded] when entry fromJson throws',
        setUp: () {
          when(
            () => manifestService.fetchManifest(),
          ).thenAnswer(
            (_) async => <String, dynamic>{
              'en': <String, dynamic>{
                'file': 'en.db.zst',
                'size': 100,
                'hash': 'hash',
                // 'license' is a String instead of a Map — causes fromJson
                // to throw a TypeError.
                'license': 'not a map',
                'version': '1.0',
              },
            },
          );
        },
        build: () => cubit,
        act: (cubit) => cubit.loadLanguages(),
        expect: () => [
          const LanguageSelectionState(status: LanguageSelectionStatus.loading),
          const LanguageSelectionState(
            status: LanguageSelectionStatus.loaded,
          ),
        ],
      );

      blocTest<LanguageSelectionCubit, LanguageSelectionState>(
        'emits [loading, error] when manifest processing throws synchronously',
        setUp: () {
          when(
            () => manifestService.fetchManifest(),
          ).thenAnswer((_) async => _ThrowingMap());
          when(
            () => preferencesService.setCachedManifest(any()),
          ).thenAnswer((_) async => true);
        },
        build: () => cubit,
        act: (cubit) => cubit.loadLanguages(),
        expect: () => [
          const LanguageSelectionState(status: LanguageSelectionStatus.loading),
          isA<LanguageSelectionState>()
              .having(
                (s) => s.status,
                'status',
                LanguageSelectionStatus.error,
              )
              .having(
                (s) => s.errorMessage,
                'errorMessage',
                'Exception: Parsing error',
              ),
        ],
      );
    });

    group('selectLanguage', () {
      blocTest<LanguageSelectionCubit, LanguageSelectionState>(
        'emits [downloading, success] when successful',
        setUp: () {
          when(
            () => databaseInitializer.initializeDatabase(
              language: 'en',
              url: any(named: 'url'),
              expectedSize: any(named: 'expectedSize'),
              expectedHash: any(named: 'expectedHash'),
              onProgress: any(named: 'onProgress'),
            ),
          ).thenAnswer((_) async {});
          when(
            () => preferencesService.setSelectedLanguage('en'),
          ).thenAnswer((_) async => true);
        },
        build: () => cubit,
        act: (cubit) => cubit.selectLanguage(enModel),
        expect: () => [
          const LanguageSelectionState(
            status: LanguageSelectionStatus.downloading,
            selectedLanguage: enModel,
          ),
          const LanguageSelectionState(
            status: LanguageSelectionStatus.success,
            selectedLanguage: enModel,
          ),
        ],
      );

      blocTest<LanguageSelectionCubit, LanguageSelectionState>(
        'emits progress updates during download',
        setUp: () {
          when(
            () => databaseInitializer.initializeDatabase(
              language: 'en',
              url: any(named: 'url'),
              expectedSize: any(named: 'expectedSize'),
              expectedHash: any(named: 'expectedHash'),
              onProgress: any(named: 'onProgress'),
            ),
          ).thenAnswer((invocation) async {
            final callback =
                invocation.namedArguments[#onProgress]
                    as void Function(int, int);
            callback(50, 100);
          });
          when(
            () => preferencesService.setSelectedLanguage('en'),
          ).thenAnswer((_) async => true);
        },
        build: () => cubit,
        act: (cubit) => cubit.selectLanguage(enModel),
        expect: () => [
          const LanguageSelectionState(
            status: LanguageSelectionStatus.downloading,
            selectedLanguage: enModel,
          ),
          const LanguageSelectionState(
            status: LanguageSelectionStatus.downloading,
            selectedLanguage: enModel,
            downloadProgress: 0.5,
          ),
          const LanguageSelectionState(
            status: LanguageSelectionStatus.success,
            selectedLanguage: enModel,
            downloadProgress: 0.5,
          ),
        ],
      );

      blocTest<LanguageSelectionCubit, LanguageSelectionState>(
        'emits [downloading, error] when initialization fails',
        setUp: () {
          when(
            () => databaseInitializer.initializeDatabase(
              language: 'en',
              url: any(named: 'url'),
              expectedSize: any(named: 'expectedSize'),
              expectedHash: any(named: 'expectedHash'),
              onProgress: any(named: 'onProgress'),
            ),
          ).thenThrow(Exception('Download error'));
        },
        build: () => cubit,
        act: (cubit) => cubit.selectLanguage(enModel),
        expect: () => [
          const LanguageSelectionState(
            status: LanguageSelectionStatus.downloading,
            selectedLanguage: enModel,
          ),
          const LanguageSelectionState(
            status: LanguageSelectionStatus.error,
            selectedLanguage: enModel,
            errorMessage: 'Exception: Download error',
          ),
        ],
      );
    });
  });

  group('LanguageSelectionState', () {
    test('supports value equality', () {
      expect(
        const LanguageSelectionState(),
        equals(const LanguageSelectionState()),
      );
    });

    test('copyWith works correctly', () {
      final state = const LanguageSelectionState().copyWith(
        status: LanguageSelectionStatus.loading,
        downloadProgress: 0.5,
        errorMessage: 'error',
      );
      expect(state.status, LanguageSelectionStatus.loading);
      expect(state.downloadProgress, 0.5);
      expect(state.errorMessage, 'error');

      final copy = state.copyWith();
      expect(copy.status, state.status);
      expect(copy.downloadProgress, state.downloadProgress);
      expect(copy.errorMessage, state.errorMessage);
    });

    test('props are correct', () {
      expect(
        const LanguageSelectionState().props,
        equals(<Object?>[LanguageSelectionStatus.initial, [], null, 0.0, null]),
      );
    });
  });
}
