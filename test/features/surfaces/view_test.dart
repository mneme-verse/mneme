import 'package:bloc_test/bloc_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:mneme/db/database.dart';
import 'package:mneme/db/seed_data.dart';
import 'package:mneme/features/author/cubit/author_cubit.dart';
import 'package:mneme/features/author/view/author_page.dart';
import 'package:mneme/features/reader/cubit/reader_cubit.dart';
import 'package:mneme/features/reader/view/reader_page.dart';
import 'package:mneme/features/search/cubit/search_cubit.dart';
import 'package:mneme/features/search/view/search_page.dart';
import 'package:mneme/features/study/cubit/study_cubit.dart';
import 'package:mneme/features/study/view/study_page.dart';
import 'package:mneme/l10n/gen/app_localizations.dart';
import 'package:mneme/repository/poetry_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockReaderCubit extends MockCubit<ReaderState> implements ReaderCubit {}

class MockSearchCubit extends MockCubit<SearchState> implements SearchCubit {}

class MockStudyCubit extends MockCubit<StudyState> implements StudyCubit {}

class MockAuthorCubit extends MockCubit<AuthorState> implements AuthorCubit {}

/// Pumps [child] with Material localizations.
Future<void> pumpLocalized(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  group('ReaderView', () {
    late ReaderCubit cubit;

    setUp(() {
      cubit = MockReaderCubit();
      registerFallbackValue(fsrs.Rating.good);
    });

    testWidgets('shows poem title and body when loaded', (tester) async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await seedDatabase(db, language: 'en');
      final poem = await PoetryRepository(db).getPoemById(1);
      whenListen(
        cubit,
        const Stream<ReaderState>.empty(),
        initialState: ReaderLoaded(poem!),
      );
      await pumpLocalized(
        tester,
        BlocProvider.value(
          value: cubit,
          child: const ReaderView(reviewMode: false),
        ),
      );
      expect(find.text('The Raven'), findsOneWidget);
      expect(find.textContaining('midnight dreary'), findsOneWidget);
    });

    testWidgets('grade button records the rating', (tester) async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await seedDatabase(db, language: 'en');
      final poem = await PoetryRepository(db).getPoemById(1);
      whenListen(
        cubit,
        const Stream<ReaderState>.empty(),
        initialState: ReaderLoaded(poem!),
      );
      when(() => cubit.grade(any())).thenAnswer((_) async {});
      await pumpLocalized(
        tester,
        BlocProvider.value(
          value: cubit,
          child: const ReaderView(reviewMode: true),
        ),
      );
      await tester.tap(find.text('Good'));
      verify(() => cubit.grade(fsrs.Rating.good)).called(1);
    });
  });

  group('SearchView', () {
    late SearchCubit cubit;

    setUp(() => cubit = MockSearchCubit());

    testWidgets('typing queries the cubit with the language', (tester) async {
      whenListen(
        cubit,
        const Stream<SearchState>.empty(),
        initialState: const SearchInitial(),
      );
      await pumpLocalized(
        tester,
        BlocProvider.value(
          value: cubit,
          child: const SearchView(activeLanguages: ['ru']),
        ),
      );
      await tester.enterText(find.byType(TextField), 'Pus');
      verify(() => cubit.query('Pus', ['ru'])).called(1);
    });
  });

  group('StudyView', () {
    late StudyCubit cubit;

    setUp(() => cubit = MockStudyCubit());

    testWidgets('empty queue explains nothing is due', (tester) async {
      whenListen(
        cubit,
        const Stream<StudyState>.empty(),
        initialState: const StudyLoaded([]),
      );
      await pumpLocalized(
        tester,
        BlocProvider.value(value: cubit, child: const StudyView()),
      );
      expect(find.text('Nothing due'), findsOneWidget);
    });
  });

  group('AuthorView', () {
    late AuthorCubit cubit;

    setUp(() => cubit = MockAuthorCubit());

    testWidgets('missing cubit states are unreachable in order', (
      tester,
    ) async {
      whenListen(
        cubit,
        const Stream<AuthorState>.empty(),
        initialState: const AuthorLoading(),
      );
      await pumpLocalized(
        tester,
        BlocProvider.value(
          value: cubit,
          child: const AuthorView(authorName: 'Poe'),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('ReaderPage', () {
    test('route carries poem id and review mode', () {
      final route = ReaderPage.route(poemId: 7, reviewMode: true);
      expect(route, isA<MaterialPageRoute<bool>>());
    });
  });
}
