import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mneme/features/onboarding/cubit/onboarding_cubit.dart';
import 'package:mneme/features/onboarding/view/onboarding_page.dart';
import 'package:mneme/l10n/gen/app_localizations.dart';
import 'package:mneme/repository/poetry_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockOnboardingCubit extends MockCubit<String?>
    implements OnboardingCubit {}

class MockPoetryRepository extends Mock implements PoetryRepository {}

void main() {
  group('OnboardingPage', () {
    late OnboardingCubit onboardingCubit;
    late PoetryRepository poetryRepository;

    setUp(() {
      onboardingCubit = MockOnboardingCubit();
      poetryRepository = MockPoetryRepository();
    });

    Widget buildSubject() {
      return RepositoryProvider.value(
        value: poetryRepository,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider.value(
            value: onboardingCubit,
            child: const OnboardingView(),
          ),
        ),
      );
    }

    testWidgets('renders language selection structure', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.text('Select Language'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Русский'), findsOneWidget);
    });

    testWidgets('calls completeOnboarding when language selected', (
      tester,
    ) async {
      when(
        () => onboardingCubit.completeOnboarding(any()),
      ).thenAnswer((_) async {});
      await tester.pumpWidget(buildSubject());

      await tester.tap(find.text('English'));
      verify(() => onboardingCubit.completeOnboarding('en')).called(1);
    });
  });

  group('OnboardingPage Integration', () {
    late PoetryRepository poetryRepository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      poetryRepository = MockPoetryRepository();
    });

    test('route returns correct route', () {
      expect(OnboardingPage.route(), isA<MaterialPageRoute<void>>());
    });

    testWidgets('renders OnboardingView and instantiates cubit', (
      tester,
    ) async {
      await tester.pumpWidget(
        RepositoryProvider.value(
          value: poetryRepository,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: OnboardingPage(),
          ),
        ),
      );
      expect(find.byType(OnboardingView), findsOneWidget);
    });

    testWidgets('completes onboarding when language selected', (tester) async {
      // Mock getAuthors for HomePage which might be loaded on navigation
      when(() => poetryRepository.getAuthors()).thenAnswer((_) async => []);

      await tester.pumpWidget(
        RepositoryProvider.value(
          value: poetryRepository,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: OnboardingPage(),
          ),
        ),
      );

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_completed'), true);
      expect(prefs.getString('selected_language'), 'en');
    });
  });
}
