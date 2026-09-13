import 'package:bloc_test/bloc_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:mneme/db/database.dart';
import 'package:mneme/db/seed_data.dart';
import 'package:mneme/db/study_database.dart';
import 'package:mneme/features/study/cubit/study_cubit.dart';
import 'package:mneme/repository/poetry_repository.dart';
import 'package:mneme/repository/study_repository.dart';

void main() {
  late PoetryRepository poetry;
  late StudyRepository study;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final corpus = AppDatabase(NativeDatabase.memory());
    addTearDown(corpus.close);
    poetry = PoetryRepository(corpus);
    await seedDatabase(corpus, language: 'en');

    final studyDb = StudyDatabase(NativeDatabase.memory());
    addTearDown(studyDb.close);
    study = StudyRepository(
      studyDb,
      scheduler: fsrs.Scheduler(enableFuzzing: false),
    );
  });

  group('StudyCubit', () {
    blocTest<StudyCubit, StudyState>(
      'empty queue loads with no rows',
      build: () => StudyCubit(study, poetry),
      act: (cubit) => cubit.load(),
      expect: () => [
        const StudyLoading(),
        isA<StudyLoaded>().having((state) => state.due, 'due', isEmpty),
      ],
    );

    blocTest<StudyCubit, StudyState>(
      'due card resolves its poem title',
      build: () => StudyCubit(study, poetry),
      setUp: () async {
        await study.getOrCreateCard('poetree:en:raven');
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const StudyLoading(),
        isA<StudyLoaded>()
            .having((state) => state.due.length, 'count', 1)
            .having(
              (state) => state.due.first.title,
              'title',
              'The Raven',
            ),
      ],
    );
  });
}
