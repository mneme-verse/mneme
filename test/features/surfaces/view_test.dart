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
import 'package:mneme/repository/study_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockReaderCubit extends MockCubit<ReaderState> implements ReaderCubit {}

class MockSearchCubit extends MockCubit<SearchState> implements SearchCubit {}

class MockStudyCubit extends MockCubit<StudyState> implements StudyCubit {}

class MockAuthorCubit extends MockCubit<AuthorState> implements AuthorCubit {}

class MockStudyRepository extends Mock implements StudyRepository {}

/// Pumps [child] with Material localizations and the repositories pushed
/// routes resolve, mirroring the app root.
Future<void> pumpLocalized(
  WidgetTester tester,
  Widget child, {
  PoetryRepository? poetry,
  StudyRepository? study,
}) {
  final home = MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
  if (poetry == null && study == null) return tester.pumpWidget(home);
  return tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        if (poetry != null) RepositoryProvider.value(value: poetry),
        if (study != null) RepositoryProvider.value(value: study),
      ],
      child: home,
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

    testWidgets('missing and error states render messages', (tester) async {
      whenListen(
        cubit,
        const Stream<ReaderState>.empty(),
        initialState: const ReaderMissing(),
      );
      await pumpLocalized(
        tester,
        BlocProvider.value(
          value: cubit,
          child: const ReaderView(reviewMode: false),
        ),
      );
      expect(find.text('Poem not found'), findsOneWidget);
    });

    testWidgets('error state renders the message', (tester) async {
      whenListen(
        cubit,
        const Stream<ReaderState>.empty(),
        initialState: const ReaderError('db gone'),
      );
      await pumpLocalized(
        tester,
        BlocProvider.value(
          value: cubit,
          child: const ReaderView(reviewMode: false),
        ),
      );
      expect(find.text('db gone'), findsOneWidget);
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

    testWidgets('loading state renders a spinner', (tester) async {
      whenListen(
        cubit,
        Stream<SearchState>.fromIterable(const [SearchLoading()]),
        initialState: const SearchLoading(),
      );
      await pumpLocalized(
        tester,
        BlocProvider.value(
          value: cubit,
          child: const SearchView(activeLanguages: ['ru']),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('loaded results open the reader', (tester) async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await seedDatabase(db, language: 'en');
      final poetry = PoetryRepository(db);
      final poems = await poetry.searchPoems('Rav', ['en']);
      whenListen(
        cubit,
        const Stream<SearchState>.empty(),
        initialState: SearchLoaded(poems),
      );
      await pumpLocalized(
        tester,
        BlocProvider.value(
          value: cubit,
          child: const SearchView(activeLanguages: ['en']),
        ),
        poetry: poetry,
      );
      await tester.tap(find.text('The Raven'));
      await tester.pumpAndSettle();
      expect(find.text('Once upon a midnight dreary...'), findsOneWidget);
    });
  });

  group('StudyView navigation', () {
    testWidgets('tapping a due row opens the review reader', (tester) async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await seedDatabase(db, language: 'en');
      final poetry = PoetryRepository(db);
      final StudyCubit cubit = MockStudyCubit();
      whenListen(
        cubit,
        const Stream<StudyState>.empty(),
        initialState: const StudyLoaded([
          (poemId: 1, title: 'The Raven', authorNames: 'Edgar Allan Poe'),
        ]),
      );
      await pumpLocalized(
        tester,
        BlocProvider.value(value: cubit, child: const StudyView()),
        poetry: poetry,
        study: MockStudyRepository(),
      );
      await tester.tap(find.text('The Raven'));
      await tester.pumpAndSettle();
      expect(find.text('Good'), findsOneWidget);
    });
  });

  group('StudyView back navigation', () {
    testWidgets('leaving without grading skips the reload', (tester) async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await seedDatabase(db, language: 'en');
      final poetry = PoetryRepository(db);
      final StudyCubit cubit = MockStudyCubit();
      var loads = 0;

      Future<void> countLoad(_) async {
        loads++;
      }

      whenListen(
        cubit,
        const Stream<StudyState>.empty(),
        initialState: const StudyLoaded([
          (poemId: 1, title: 'The Raven', authorNames: 'Edgar Allan Poe'),
        ]),
      );
      when(cubit.load).thenAnswer(countLoad);
      await pumpLocalized(
        tester,
        BlocProvider.value(value: cubit, child: const StudyView()),
        poetry: poetry,
        study: MockStudyRepository(),
      );
      await tester.tap(find.text('The Raven'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(loads, 0);
    });
  });

  group('AuthorView navigation', () {
    testWidgets('tapping a poem opens the reader', (tester) async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await seedDatabase(db, language: 'en');
      final poetry = PoetryRepository(db);
      final AuthorCubit cubit = MockAuthorCubit();
      final poems = await poetry.getPoemsByAuthor('Edgar Allan Poe');
      whenListen(
        cubit,
        const Stream<AuthorState>.empty(),
        initialState: AuthorLoaded(poems),
      );
      await pumpLocalized(
        tester,
        BlocProvider.value(
          value: cubit,
          child: const AuthorView(authorName: 'Edgar Allan Poe'),
        ),
        poetry: poetry,
      );
      await tester.tap(find.text('Annabel Lee'));
      await tester.pumpAndSettle();
      expect(
        find.text('It was many and many a year ago...'),
        findsOneWidget,
      );
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
