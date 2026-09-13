import 'package:bloc_test/bloc_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mneme/db/database.dart';
import 'package:mneme/db/seed_data.dart';
import 'package:mneme/features/author/cubit/author_cubit.dart';
import 'package:mneme/features/reader/cubit/reader_cubit.dart';
import 'package:mneme/features/search/cubit/search_cubit.dart';
import 'package:mneme/repository/poetry_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockPoetryRepository extends Mock implements PoetryRepository {}

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
  });

  group('AuthorCubit', () {
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
