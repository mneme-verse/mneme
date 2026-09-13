import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mneme/features/recitation/cubit/recitation_cubit.dart';
import 'package:mneme/recitation/matcher.dart';
import 'package:mneme/repository/poetry_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockPoetryRepository extends Mock implements PoetryRepository {}

const _body = 'Once upon a midnight dreary, while I pondered weak and weary';

RecitationCandidate candidate({String body = _body}) => RecitationCandidate(
  passageId: 1,
  poemId: 1,
  poemTitle: 'The Raven',
  poemBody: body,
  startToken: 0,
  endToken: 12,
);

void main() {
  group('RecitationCubit', () {
    late PoetryRepository poetryRepository;

    setUp(() {
      poetryRepository = MockPoetryRepository();
    });

    test('starts idle and ignores transcripts until started', () async {
      final cubit = RecitationCubit(poetryRepository: poetryRepository);
      addTearDown(cubit.close);
      expect(cubit.state.phase, RecitationPhase.idle);

      await cubit.onTranscript('once upon a midnight');
      expect(cubit.state.phase, RecitationPhase.idle);
      expect(cubit.state.hypothesis, isEmpty);
      verifyNever(() => poetryRepository.findCandidatePassages(any()));
    });

    blocTest<RecitationCubit, RecitationState>(
      'locates the poem and marks every word correct',
      build: () {
        when(
          () => poetryRepository.findCandidatePassages(any()),
        ).thenAnswer((_) async => [candidate()]);
        return RecitationCubit(poetryRepository: poetryRepository);
      },
      act: (cubit) async {
        cubit.start();
        await cubit.onTranscript('Once upon a midnight');
      },
      expect: () => [
        isA<RecitationState>()
            .having((s) => s.phase, 'phase', RecitationPhase.listening)
            .having((s) => s.located, 'located', isNull),
        isA<RecitationState>()
            .having(
              (s) => s.located?.poemTitle,
              'poem title',
              'The Raven',
            )
            .having((s) => s.score, 'score', 1.0)
            .having(
              (s) => s.feedback.take(4).map((w) => w.verdict),
              'first words',
              everyElement(WordVerdict.correct),
            )
            .having(
              (s) => s.feedback.skip(4).map((w) => w.verdict),
              'unreached words',
              everyElement(WordVerdict.pending),
            ),
      ],
    );

    blocTest<RecitationCubit, RecitationState>(
      'marks a misrecognized word wrong with what was heard',
      build: () {
        when(
          () => poetryRepository.findCandidatePassages(any()),
        ).thenAnswer((_) async => [candidate()]);
        return RecitationCubit(poetryRepository: poetryRepository);
      },
      act: (cubit) async {
        cubit.start();
        await cubit.onTranscript('Once upon banana midnight');
      },
      expect: () => [
        isA<RecitationState>(),
        isA<RecitationState>()
            .having((s) => s.located, 'located', isNotNull)
            .having(
              (s) => s.feedback[2].verdict,
              'third word',
              WordVerdict.wrong,
            )
            .having((s) => s.feedback[2].heard, 'heard', 'banana')
            .having(
              (s) => s.feedback[3].verdict,
              'fourth word',
              WordVerdict.correct,
            ),
      ],
    );

    blocTest<RecitationCubit, RecitationState>(
      'stays unlocated on silence without failing',
      build: () => RecitationCubit(poetryRepository: poetryRepository),
      act: (cubit) async {
        cubit.start();
        await cubit.onTranscript('   ');
      },
      expect: () => [
        isA<RecitationState>(),
        isA<RecitationState>()
            .having((s) => s.hypothesis, 'hypothesis', '   ')
            .having((s) => s.located, 'located', isNull)
            .having((s) => s.error, 'error', isNull),
      ],
      verify: (_) {
        verifyNever(() => poetryRepository.findCandidatePassages(any()));
      },
    );

    blocTest<RecitationCubit, RecitationState>(
      'stays unlocated when nothing matches well enough',
      build: () {
        when(
          () => poetryRepository.findCandidatePassages(any()),
        ).thenAnswer((_) async => [candidate()]);
        return RecitationCubit(poetryRepository: poetryRepository);
      },
      act: (cubit) async {
        cubit.start();
        await cubit.onTranscript('completely unrelated utterance here');
      },
      expect: () => [
        isA<RecitationState>(),
        isA<RecitationState>()
            .having((s) => s.located, 'located', isNull)
            .having((s) => s.error, 'error', isNull),
      ],
    );

    blocTest<RecitationCubit, RecitationState>(
      'keeps the hypothesis and reports retrieval failures',
      build: () {
        when(
          () => poetryRepository.findCandidatePassages(any()),
        ).thenThrow(Exception('database is locked'));
        return RecitationCubit(poetryRepository: poetryRepository);
      },
      act: (cubit) async {
        cubit.start();
        await cubit.onTranscript('once upon a midnight');
      },
      expect: () => [
        isA<RecitationState>(),
        isA<RecitationState>()
            .having((s) => s.hypothesis, 'hypothesis', 'once upon a midnight')
            .having((s) => s.error, 'error', isNotNull),
      ],
    );

    blocTest<RecitationCubit, RecitationState>(
      'stop ends listening but keeps the last attempt visible',
      build: () {
        when(
          () => poetryRepository.findCandidatePassages(any()),
        ).thenAnswer((_) async => [candidate()]);
        return RecitationCubit(poetryRepository: poetryRepository);
      },
      act: (cubit) async {
        cubit.start();
        await cubit.onTranscript('once upon a midnight');
        cubit.stop();
      },
      expect: () => [
        isA<RecitationState>(),
        isA<RecitationState>().having(
          (s) => s.located?.poemTitle,
          'located',
          'The Raven',
        ),
        isA<RecitationState>()
            .having((s) => s.phase, 'phase', RecitationPhase.idle)
            .having(
              (s) => s.located?.poemTitle,
              'kept title',
              'The Raven',
            ),
      ],
    );
  });
}
