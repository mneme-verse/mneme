import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mneme/app/view/app.dart';
import 'package:mneme/features/home/view/home_page.dart';
import 'package:mneme/features/language_selection/view/language_selection_page.dart';
import 'package:mneme/repository/poetry_repository.dart';
import 'package:mneme/services/database_initializer.dart';
import 'package:mneme/services/preferences_service.dart';
import 'package:mocktail/mocktail.dart';

class MockPreferencesService extends Mock implements PreferencesService {}

class MockDatabaseInitializer extends Mock implements DatabaseInitializer {}

class MockPoetryRepository extends Mock implements PoetryRepository {}

void main() {
  const channel = MethodChannel('plugins.flutter.io/path_provider');

  TestWidgetsFlutterBinding.ensureInitialized();

  group('App', () {
    late PreferencesService preferencesService;
    late DatabaseInitializer databaseInitializer;
    late PoetryRepository poetryRepository;
    late List<Directory> tempDirs;

    setUp(() {
      preferencesService = MockPreferencesService();
      databaseInitializer = MockDatabaseInitializer();
      poetryRepository = MockPoetryRepository();
      languageSelectionCubit = MockLanguageSelectionCubit();
      when(
        () => languageSelectionCubit.state,
      ).thenReturn(
        const LanguageSelectionState(status: LanguageSelectionStatus.loaded),
      );
      when(
        () => languageSelectionCubit.loadLanguages(),
      ).thenAnswer((_) async {});

      tempDirs = [];

      when(() => preferencesService.init()).thenAnswer((_) async {});
      when(
        () => databaseInitializer.isDatabaseAvailable(
          any(),
        ),
      ).thenAnswer((_) async => true);

      when(
        () => poetryRepository.getAuthors(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => []);
      when(() => poetryRepository.close()).thenAnswer((_) async {});

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (methodCall) async {
            final dir = Directory.systemTemp.createTempSync();
            tempDirs.add(dir);
            return dir.path;
          });
    });

    tearDown(() {
      for (final dir in tempDirs) {
        if (dir.existsSync()) {
          dir.deleteSync(recursive: true);
        }
      }
    });

    testWidgets('renders CircularProgressIndicator when initializing', (
      tester,
    ) async {
      final completer = Completer<void>();
      // Delay init to catch loading state
      when(() => preferencesService.init()).thenAnswer((_) {
        return completer.future;
      });

      await tester.pumpWidget(
        App(
          preferencesService: preferencesService,
          databaseInitializer: databaseInitializer,
        ),
      );
      // Pump to start the animation
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders LanguageSelectionPage when no language selected', (
      tester,
    ) async {
      when(() => preferencesService.getSelectedLanguage()).thenReturn(null);

      await tester.pumpWidget(
        App(
          preferencesService: preferencesService,
          databaseInitializer: databaseInitializer,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LanguageSelectionPage), findsOneWidget);
    });

    testWidgets('renders HomePage when language selected', (tester) async {
      when(() => preferencesService.getSelectedLanguage()).thenReturn('en');

      await tester.pumpWidget(
        App(
          preferencesService: preferencesService,
          databaseInitializer: databaseInitializer,
          repositoryBuilder: (_) => poetryRepository,
        ),
      );

      // Need to pump enough to settle async initialization
      await tester.pump(); // Start init
      await tester.pump(); // Init done
      await tester.pump(); // Set state

      expect(find.byType(HomePage), findsOneWidget);
      verify(
        () => databaseInitializer.isDatabaseAvailable('en'),
      ).called(1);
    });

    testWidgets('initializes for language when selection completes', (
      tester,
    ) async {
      when(() => preferencesService.getSelectedLanguage()).thenReturn(null);

      await tester.pumpWidget(
        App(
          preferencesService: preferencesService,
          databaseInitializer: databaseInitializer,
          repositoryBuilder: (_) => poetryRepository,
        ),
      );
      await tester.pumpAndSettle();

      final page = tester.widget<LanguageSelectionPage>(
        find.byType(LanguageSelectionPage),
      );

      // Update mock to return language now
      when(() => preferencesService.getSelectedLanguage()).thenReturn('es');

      // Trigger callback
      page.onSelectionComplete?.call();
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
      verify(
        () => databaseInitializer.isDatabaseAvailable('es'),
      ).called(1);
    });

    testWidgets(
      'renders LanguageSelectionPage when database not available',
      (
        tester,
      ) async {
        when(() => preferencesService.getSelectedLanguage()).thenReturn('en');
        when(
          () => databaseInitializer.isDatabaseAvailable('en'),
        ).thenAnswer((_) async => false);
        when(
          () => preferencesService.clearSelectedLanguage(),
        ).thenAnswer((_) async => true);

        await tester.pumpWidget(
          App(
            preferencesService: preferencesService,
            databaseInitializer: databaseInitializer,
            repositoryBuilder: (_) => poetryRepository,
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(LanguageSelectionPage), findsOneWidget);
      },
    );

    testWidgets(
      'navigates to LanguageSelectionPage when settings pressed',
      (tester) async {
        when(() => preferencesService.getSelectedLanguage()).thenReturn('en');
        when(
          () => preferencesService.clearSelectedLanguage(),
        ).thenAnswer((_) async => true);

        await tester.pumpWidget(
          App(
            preferencesService: preferencesService,
            databaseInitializer: databaseInitializer,
            repositoryBuilder: (_) => poetryRepository,
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HomePage), findsOneWidget);

        await tester.tap(find.widgetWithIcon(IconButton, Icons.settings));
        await tester.pumpAndSettle();

        verify(() => preferencesService.clearSelectedLanguage()).called(1);
        expect(find.byType(LanguageSelectionPage), findsOneWidget);
      },
    );
    testWidgets(
      'renders LanguageSelectionPage when initialization fails',
      (tester) async {
        when(() => preferencesService.getSelectedLanguage()).thenReturn('en');
        when(
          () => databaseInitializer.isDatabaseAvailable('en'),
        ).thenThrow(Exception('init failed'));
        when(
          () => preferencesService.clearSelectedLanguage(),
        ).thenAnswer((_) async => true);

        await tester.pumpWidget(
          App(
            preferencesService: preferencesService,
            databaseInitializer: databaseInitializer,
            repositoryBuilder: (_) => poetryRepository,
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(LanguageSelectionPage), findsOneWidget);
        verify(() => preferencesService.clearSelectedLanguage()).called(1);
      },
    );
  });
}
