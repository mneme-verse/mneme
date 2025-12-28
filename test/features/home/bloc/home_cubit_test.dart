import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mneme/db/database.dart';
import 'package:mneme/features/home/bloc/home_cubit.dart';
import 'package:mneme/repository/poetry_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockPoetryRepository extends Mock implements PoetryRepository {}

void main() {
  group('HomeCubit', () {
    late PoetryRepository poetryRepository;

    setUp(() {
      poetryRepository = MockPoetryRepository();
    });

    test('initial state is HomeInitial', () {
      expect(HomeCubit(poetryRepository).state, isA<HomeInitial>());
    });

    blocTest<HomeCubit, HomeState>(
      'emits [HomeLoading, HomeLoaded] when fetchAuthors succeeds (initial)',
      build: () {
        when(
          () => poetryRepository.getAuthors(),
        ).thenAnswer(
          (_) async => [
            const Author(name: 'Author 1', poemCount: 10, id: 1),
            const Author(name: 'Author 2', poemCount: 5, id: 2),
          ],
        );
        return HomeCubit(poetryRepository);
      },
      act: (cubit) => cubit.fetchAuthors(),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeLoaded>()
            .having((s) => s.authors.length, 'authors length', 2)
            .having((s) => s.hasReachedMax, 'hasReachedMax', true),
      ],
    );

    blocTest<HomeCubit, HomeState>(
      'emits [HomeLoaded] with appended authors when fetchAuthors succeeds '
      '(pagination)',
      build: () {
        when(
          () => poetryRepository.getAuthors(),
        ).thenAnswer(
          (_) async => [const Author(name: 'A1', poemCount: 1, id: 1)],
        );
        when(
          () => poetryRepository.getAuthors(offset: 1),
        ).thenAnswer(
          (_) async => [const Author(name: 'A2', poemCount: 2, id: 2)],
        );
        return HomeCubit(poetryRepository);
      },
      seed: () => HomeLoaded([const Author(name: 'A1', poemCount: 1, id: 1)]),
      act: (cubit) => cubit.fetchAuthors(offset: 1),
      expect: () => [
        isA<HomeLoaded>()
            .having((s) => s.authors.length, 'authors length', 2)
            .having((s) => s.authors.last.name, 'last author', 'A2'),
      ],
    );

    blocTest<HomeCubit, HomeState>(
      'emits [HomeLoading, HomeError] when fetchAuthors fails',
      build: () {
        when(
          () => poetryRepository.getAuthors(),
        ).thenThrow(Exception('oops'));
        return HomeCubit(poetryRepository);
      },
      act: (cubit) => cubit.fetchAuthors(),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeError>().having((s) => s.message, 'message', contains('oops')),
      ],
    );
  });
}
