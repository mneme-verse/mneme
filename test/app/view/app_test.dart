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

    setUp(() {
      preferencesService = MockPreferencesService();
      databaseInitializer = MockDatabaseInitializer();
      poetryRepository = MockPoetryRepository();

      when(() => preferencesService.init()).thenAnswer((_) async {});
      when(
        () => databaseInitializer.initializeDatabase(
          language: any(named: 'language'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((_) async {});

      when(
        () => poetryRepository.getAuthors(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => []);
      when(() => poetryRepository.close()).thenAnswer((_) async {});

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            return Directory.systemTemp.createTempSync().path;
          });
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
        () => databaseInitializer.initializeDatabase(language: 'en'),
      ).called(1);
    });

    testWidgets('uses default repository when builder is null', (tester) async {
      when(() => preferencesService.getSelectedLanguage()).thenReturn('en');

      await tester.pumpWidget(
        App(
          preferencesService: preferencesService,
          databaseInitializer: databaseInitializer,
        ),
      );

      await tester.pump(); // Start init
      await tester.pump(); // Init done
      await tester.pump(); // Set state

      expect(find.byType(HomePage), findsOneWidget);
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
        () => databaseInitializer.initializeDatabase(language: 'es'),
      ).called(1);
    });

    testWidgets(
      'renders LanguageSelectionPage on error initializing language',
      (
        tester,
      ) async {
        when(() => preferencesService.getSelectedLanguage()).thenReturn('en');
        when(
          () => databaseInitializer.initializeDatabase(language: 'en'),
        ).thenThrow(Exception('oops'));

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
          () => databaseInitializer.initializeDatabase(language: 'en'),
        ).thenAnswer((_) async {});
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
  });
}
