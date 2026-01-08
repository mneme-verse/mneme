import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mneme/features/language_selection/cubit/language_selection_cubit.dart';
import 'package:mneme/features/language_selection/models/language_model.dart';
import 'package:mneme/features/language_selection/view/language_selection_page.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/helpers.dart';

class MockLanguageSelectionCubit extends MockCubit<LanguageSelectionState>
    implements LanguageSelectionCubit {}

void main() {
  group('LanguageSelectionPage', () {
    late LanguageSelectionCubit cubit;

    setUp(() {
      cubit = MockLanguageSelectionCubit();
      when(() => cubit.loadLanguages()).thenAnswer((_) async {});
    });

    testWidgets('renders LanguageSelectionView', (tester) async {
      when(() => cubit.state).thenReturn(const LanguageSelectionState());
      await tester.pumpApp(
        BlocProvider.value(
          value: cubit,
          child: const LanguageSelectionView(),
        ),
      );
      expect(find.byType(LanguageSelectionView), findsOneWidget);
    });

    testWidgets('renders loading indicator when status is loading', (
      tester,
    ) async {
      when(() => cubit.state).thenReturn(
        const LanguageSelectionState(status: LanguageSelectionStatus.loading),
      );
      await tester.pumpApp(
        BlocProvider.value(
          value: cubit,
          child: const LanguageSelectionView(),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders error view when status is error', (tester) async {
      when(() => cubit.state).thenReturn(
        const LanguageSelectionState(
          status: LanguageSelectionStatus.error,
          errorMessage: 'Something went wrong',
        ),
      );
      await tester.pumpApp(
        BlocProvider.value(
          value: cubit,
          child: const LanguageSelectionView(),
        ),
      );
      expect(find.text('Error: Something went wrong'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('calls loadLanguages when retry button is tapped', (
      tester,
    ) async {
      when(() => cubit.state).thenReturn(
        const LanguageSelectionState(status: LanguageSelectionStatus.error),
      );
      await tester.pumpApp(
        BlocProvider.value(
          value: cubit,
          child: const LanguageSelectionView(),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      verify(() => cubit.loadLanguages()).called(1);
    });

    testWidgets('renders list of languages when status is loaded', (
      tester,
    ) async {
      const language = LanguageModel(
        code: 'en',
        name: 'English',
        license: LicenseModel(text: 'CC', url: 'url'),
        size: 100,
        hash: 'hash',
        version: '1.0',
      );

      when(() => cubit.state).thenReturn(
        const LanguageSelectionState(
          status: LanguageSelectionStatus.loaded,
          availableLanguages: [language],
        ),
      );
      await tester.pumpApp(
        BlocProvider.value(
          value: cubit,
          child: const LanguageSelectionView(),
        ),
      );

      expect(find.text('English'), findsOneWidget);
      expect(find.text('CC (Tap for license)'), findsNothing);
      expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);
    });

    testWidgets('calls selectLanguage when language is tapped', (tester) async {
      const language = LanguageModel(
        code: 'en',
        name: 'English',
        license: LicenseModel(text: 'CC', url: 'url'),
        size: 100,
        hash: 'hash',
        version: '1.0',
      );

      when(() => cubit.state).thenReturn(
        const LanguageSelectionState(
          status: LanguageSelectionStatus.loaded,
          availableLanguages: [language],
        ),
      );
      when(() => cubit.selectLanguage(language)).thenAnswer((_) async {});

      await tester.pumpApp(
        BlocProvider.value(
          value: cubit,
          child: const LanguageSelectionView(),
        ),
      );

      await tester.tap(find.text('English'));
      verify(() => cubit.selectLanguage(language)).called(1);
    });

    testWidgets('renders downloading view when status is downloading', (
      tester,
    ) async {
      const language = LanguageModel(
        code: 'en',
        name: 'English',
        license: LicenseModel(text: 'CC', url: 'url'),
        size: 100,
        hash: 'hash',
        version: '1.0',
      );

      when(() => cubit.state).thenReturn(
        const LanguageSelectionState(
          status: LanguageSelectionStatus.downloading,
          selectedLanguage: language,
          downloadProgress: 0.5,
        ),
      );

      await tester.pumpApp(
        BlocProvider.value(
          value: cubit,
          child: const LanguageSelectionView(),
        ),
      );

      expect(find.textContaining('Downloading English'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('calls onSelectionComplete when status becomes success', (
      tester,
    ) async {
      whenListen(
        cubit,
        Stream.fromIterable([
          const LanguageSelectionState(
            status: LanguageSelectionStatus.downloading,
          ),
          const LanguageSelectionState(status: LanguageSelectionStatus.success),
        ]),
        initialState: const LanguageSelectionState(
          status: LanguageSelectionStatus.downloading,
        ),
      );

      var onCompleteCalled = false;
      await tester.pumpApp(
        BlocProvider.value(
          value: cubit,
          child: LanguageSelectionView(
            onSelectionComplete: () => onCompleteCalled = true,
          ),
        ),
      );

      await tester.pump(); // trigger listener
      expect(onCompleteCalled, isTrue);
    });

    testWidgets('shows license dialog when info button is tapped', (
      tester,
    ) async {
      const language = LanguageModel(
        code: 'en',
        name: 'English',
        license: LicenseModel(text: 'CC', url: 'url'),
        size: 100,
        hash: 'hash',
        version: '1.0',
      );

      when(() => cubit.state).thenReturn(
        const LanguageSelectionState(
          status: LanguageSelectionStatus.loaded,
          availableLanguages: [language],
        ),
      );
      await tester.pumpApp(
        BlocProvider.value(
          value: cubit,
          child: const LanguageSelectionView(),
        ),
      );

      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();

      expect(find.text('License Information'), findsOneWidget);
      // "English" is present in both the main list (behind dialog) and the
      // dialog.
      expect(find.text('English'), findsAtLeastNWidgets(1));
      // "CC" should only be in the dialog now (as it was removed from list
      // subtitle)
      expect(find.text('CC'), findsOneWidget);
    });
  });
}
