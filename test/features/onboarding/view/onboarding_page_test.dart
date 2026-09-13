import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mneme/features/onboarding/cubit/onboarding_cubit.dart';
import 'package:mneme/features/onboarding/view/onboarding_page.dart';
import 'package:mneme/l10n/gen/app_localizations.dart';
import 'package:mneme/resources/corpus_manifest.dart';
import 'package:mneme/resources/resource_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockOnboardingCubit extends MockCubit<OnboardingState>
    implements OnboardingCubit {}

void main() {
  group('OnboardingView', () {
    late OnboardingCubit onboardingCubit;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      onboardingCubit = MockOnboardingCubit();
      whenListen(
        onboardingCubit,
        Stream.value(const OnboardingState.languageSelection()),
        initialState: const OnboardingState.languageSelection(),
      );
      when(
        () => onboardingCubit.selectLanguage(any()),
      ).thenAnswer((_) async {});
    });

    Widget buildSubject() {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: onboardingCubit,
          child: const OnboardingView(),
        ),
      );
    }

    testWidgets('renders language selection with Russian first', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      expect(find.text('Select Language'), findsOneWidget);
      final russian = find.text('Русский');
      final english = find.text('English');
      expect(russian, findsOneWidget);
      expect(english, findsOneWidget);
      expect(
        tester.getTopLeft(russian).dy < tester.getTopLeft(english).dy,
        isTrue,
        reason: 'Russian must be offered first',
      );
    });

    testWidgets('calls selectLanguage when a language is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.tap(find.text('English'));
      verify(() => onboardingCubit.selectLanguage('en')).called(1);
    });

    testWidgets('shows progress and cancel while installing', (tester) async {
      whenListen(
        onboardingCubit,
        Stream.value(
          const OnboardingState(
            phase: OnboardingPhase.installing,
            language: 'ru',
            resource: OnboardingResource.corpus,
            receivedBytes: 10,
            totalBytes: 100,
          ),
        ),
        initialState: const OnboardingState(
          phase: OnboardingPhase.installing,
          language: 'ru',
          resource: OnboardingResource.corpus,
          receivedBytes: 10,
          totalBytes: 100,
        ),
      );
      await tester.pumpWidget(buildSubject());
      expect(find.text('Downloading poem corpus'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('shows retry and language change after failure', (
      tester,
    ) async {
      whenListen(
        onboardingCubit,
        Stream.value(
          OnboardingState(
            phase: OnboardingPhase.failed,
            language: 'ru',
            error: StateError('boom'),
          ),
        ),
        initialState: OnboardingState(
          phase: OnboardingPhase.failed,
          language: 'ru',
          error: StateError('boom'),
        ),
      );
      await tester.pumpWidget(buildSubject());
      expect(find.text('Installation failed'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      verify(() => onboardingCubit.selectLanguage('ru')).called(1);
      await tester.tap(find.text('Choose a different language'));
      verify(() => onboardingCubit.resetToLanguageSelection()).called(1);
    });

    testWidgets('shows the model label while the model downloads', (
      tester,
    ) async {
      const installing = OnboardingState(
        phase: OnboardingPhase.installing,
        language: 'ru',
        resource: OnboardingResource.speechModel,
        receivedBytes: 10,
        totalBytes: 100,
      );
      whenListen(
        onboardingCubit,
        Stream.value(installing),
        initialState: installing,
      );
      await tester.pumpWidget(buildSubject());
      expect(find.text('Downloading speech model'), findsOneWidget);
    });

    testWidgets('shows progress while completing', (tester) async {
      const completed = OnboardingState(
        phase: OnboardingPhase.completed,
        language: 'ru',
      );
      whenListen(
        onboardingCubit,
        Stream.value(completed),
        initialState: completed,
      );
      await tester.pumpWidget(buildSubject());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('notifies when onboarding completes', (tester) async {
      String? completedWith;
      whenListen(
        onboardingCubit,
        Stream.value(
          const OnboardingState(
            phase: OnboardingPhase.completed,
            language: 'ru',
          ),
        ),
        initialState: const OnboardingState.languageSelection(),
      );
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider.value(
            value: onboardingCubit,
            child: OnboardingView(
              onCompleted: (language) => completedWith = language,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(completedWith, 'ru');
    });
  });

  group('OnboardingPage', () {
    late ResourceRepository resources;
    late CorpusManifestClient manifestClient;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      resources = ResourceRepository(
        modelDir: Directory.systemTemp.createTempSync('page-models'),
        corpusDir: Directory.systemTemp.createTempSync('page-corpora'),
      );
      manifestClient = CorpusManifestClient(
        manifestUrl: Uri.parse('https://example.test/manifest.json'),
      );
    });

    test('route builds a page with the provided dependencies', () {
      final route = OnboardingPage.route(
        resources: resources,
        manifestClient: manifestClient,
      );
      expect(route, isA<MaterialPageRoute<void>>());
    });

    testWidgets('route shows onboarding when pushed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                OnboardingPage.route(
                  resources: resources,
                  manifestClient: manifestClient,
                ),
              ),
              child: const Text('go'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      expect(find.text('Select Language'), findsOneWidget);
    });
  });
}
