import 'package:bloc_test/bloc_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:mneme/db/database.dart';
import 'package:mneme/db/seed_data.dart';
import 'package:mneme/features/author/cubit/author_cubit.dart';
import 'package:mneme/features/reader/cubit/reader_cubit.dart';
import 'package:mneme/features/search/cubit/search_cubit.dart';
import 'package:mneme/repository/poetry_repository.dart';
import 'package:mneme/repository/study_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockPoetryRepository extends Mock implements PoetryRepository {}

class MockStudyRepository extends Mock implements StudyRepository {}

/// Seeds an English in-memory database for the group repository.
Future<PoetryRepository> _seededRepo() async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final repo = PoetryRepository(db);
  await seedDatabase(db, language: 'en');
  return repo;
}

void main() {
  late PoetryRepository repo;

  setUp(() async => repo = await _seededRepo());

  group('ReaderCubit', () {
    setUp(() => registerFallbackValue(fsrs.Rating.good));

    blocTest<ReaderCubit, ReaderState>(
      'loads a poem by id',
      build: () => ReaderCubit(repo),
      act: (cubit) => cubit.load(1),
      expect: () => [
        const ReaderLoading(),
        isA<ReaderLoaded>().having(
          (state) => state.poem.title,
          'title',
          'The Raven',
        ),
      ],
    );

    blocTest<ReaderCubit, ReaderState>(
      'missing poem emits missing',
      build: () => ReaderCubit(repo),
      act: (cubit) => cubit.load(999),
      expect: () => [const ReaderLoading(), const ReaderMissing()],
    );

    blocTest<ReaderCubit, ReaderState>(
      'repository failure emits error, never throws',
      build: () {
        final failing = MockPoetryRepository();
        when(
          () => failing.getPoemById(any()),
        ).thenThrow(Exception('db gone'));
        return ReaderCubit(failing);
      },
      act: (cubit) => cubit.load(1),
      expect: () => [const ReaderLoading(), isA<ReaderError>()],
    );

    late MockStudyRepository study;

    blocTest<ReaderCubit, ReaderState>(
      'grade records the rating for the loaded poem',
      build: () {
        study = MockStudyRepository();
        when(
          () => study.submitReview(
            poemKey: any(named: 'poemKey'),
            rating: any(named: 'rating'),
          ),
        ).thenAnswer(
          (_) async => (
            card: fsrs.Card(cardId: 1),
            log: fsrs.ReviewLog(
              cardId: 1,
              rating: fsrs.Rating.good,
              reviewDateTime: DateTime.utc(2026, 9, 13),
            ),
          ),
        );
        return ReaderCubit(repo, study);
      },
      act: (cubit) async {
        await cubit.load(1);
        await cubit.grade(fsrs.Rating.good);
      },
      expect: () => [
        const ReaderLoading(),
        isA<ReaderLoaded>(),
      ],
      verify: (_) => verify(
        () => study.submitReview(
          poemKey: 'poetree:en:raven',
          rating: fsrs.Rating.good,
        ),
      ).called(1),
    );

    blocTest<ReaderCubit, ReaderState>(
      'grade without a study repository is a no-op',
      build: () => ReaderCubit(repo),
      act: (cubit) async {
        await cubit.load(1);
        await cubit.grade(fsrs.Rating.good);
      },
      expect: () => [
        const ReaderLoading(),
        isA<ReaderLoaded>(),
      ],
    );
  });

  group('AuthorCubit', () {
    blocTest<AuthorCubit, AuthorState>(
      'repository failure emits error',
      build: () {
        final failing = MockPoetryRepository();
        when(
          () => failing.getPoemsByAuthor(any()),
        ).thenThrow(Exception('db gone'));
        return AuthorCubit(failing);
      },
      act: (cubit) => cubit.load('Poe'),
      expect: () => [const AuthorLoading(), isA<AuthorError>()],
    );

    blocTest<AuthorCubit, AuthorState>(
      'loads the author poems',
      build: () => AuthorCubit(repo),
      act: (cubit) => cubit.load('Edgar Allan Poe'),
      expect: () => [
        const AuthorLoading(),
        isA<AuthorLoaded>().having(
          (state) => state.poems.length,
          'count',
          2,
        ),
      ],
    );
  });

  group('SearchCubit', () {
    late MockPoetryRepository failing;

    setUp(() => failing = MockPoetryRepository());

    blocTest<SearchCubit, SearchState>(
      'empty query resets to initial without touching the repo',
      build: () => SearchCubit(failing),
      act: (cubit) => cubit.query('   ', ['en']),
      expect: () => [const SearchInitial()],
      verify: (_) => verifyNever(() => failing.searchPoems(any(), any())),
    );

    blocTest<SearchCubit, SearchState>(
      'debounced query settles into one result',
      build: () => SearchCubit(repo, debounce: Duration.zero),
      act: (cubit) => cubit.query('Rav', ['en']),
      wait: const Duration(milliseconds: 20),
      expect: () => [
        const SearchLoading(),
        isA<SearchLoaded>().having(
          (state) => state.poems.map((poem) => poem.title),
          'titles',
          contains('The Raven'),
        ),
      ],
    );

    blocTest<SearchCubit, SearchState>(
      'repository failure emits error',
      build: () {
        final failing = MockPoetryRepository();
        when(
          () => failing.searchPoems(any(), any()),
        ).thenThrow(Exception('db gone'));
        return SearchCubit(failing, debounce: Duration.zero);
      },
      act: (cubit) => cubit.query('Rav', ['en']),
      wait: const Duration(milliseconds: 20),
      expect: () => [const SearchLoading(), isA<SearchError>()],
    );

    blocTest<SearchCubit, SearchState>(
      'rapid keystrokes keep only the latest result',
      build: () => SearchCubit(
        repo,
        debounce: const Duration(milliseconds: 30),
      ),
      act: (cubit) => cubit
        ..query('Rav', ['en'])
        ..query('Annabel', ['en']),
      wait: const Duration(milliseconds: 150),
      expect: () => [
        const SearchLoading(),
        isA<SearchLoaded>().having(
          (state) => state.poems.map((poem) => poem.title),
          'titles',
          contains('Annabel Lee'),
        ),
      ],
    );
  });
}
