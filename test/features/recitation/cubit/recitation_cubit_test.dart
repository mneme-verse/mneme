import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mneme/features/recitation/cubit/recitation_cubit.dart';
import 'package:mneme/recitation/matcher.dart';
import 'package:mneme/repository/poetry_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockPoetryRepository extends Mock implements PoetryRepository {}

const _body = 'Once upon a midnight dreary, while I pondered weak and weary';

RecitationCandidate candidate({
  String body = _body,
  int passageId = 1,
  int startToken = 0,
  int endToken = 12,
}) => RecitationCandidate(
  passageId: passageId,
  poemId: 1,
  poemTitle: 'The Raven',
  poemBody: body,
  startToken: startToken,
  endToken: endToken,
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
    blocTest<RecitationCubit, RecitationState>(
      'locates mid-window recitation at its offset',
      build: () {
        when(
          () => poetryRepository.findCandidatePassages(any()),
        ).thenAnswer((_) async => [candidate()]);
        return RecitationCubit(poetryRepository: poetryRepository);
      },
      act: (cubit) async {
        cubit.start();
        await cubit.onTranscript('midnight dreary while I');
      },
      expect: () => [
        isA<RecitationState>(),
        isA<RecitationState>()
            .having((s) => s.located?.startToken, 'start', 3)
            .having((s) => s.score, 'score', 1.0)
            .having(
              (s) => s.feedback.map((w) => w.verdict),
              'verdicts',
              everyElement(isNot(WordVerdict.wrong)),
            ),
      ],
    );

    blocTest<RecitationCubit, RecitationState>(
      'discards transcripts that finish after stop',
      build: () {
        when(
          () => poetryRepository.findCandidatePassages(any()),
        ).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return [candidate()];
        });
        return RecitationCubit(poetryRepository: poetryRepository);
      },
      act: (cubit) async {
        cubit.start();
        final pending = cubit.onTranscript('once upon a midnight');
        cubit.stop();
        await pending;
      },
      expect: () => [
        isA<RecitationState>().having(
          (s) => s.located,
          'listening unlocated',
          isNull,
        ),
        isA<RecitationState>()
            .having((s) => s.phase, 'phase', RecitationPhase.idle)
            .having((s) => s.located, 'stays unlocated', isNull),
      ],
    );

    for (final order in ['wide-first', 'narrow-first']) {
      blocTest<RecitationCubit, RecitationState>(
        'resolves overlapping windows identically ($order)',
        build: () {
          final wide = candidate(passageId: 9);
          final narrow = candidate(passageId: 2, startToken: 3, endToken: 8);
          when(
            () => poetryRepository.findCandidatePassages(any()),
          ).thenAnswer(
            (_) async =>
                order == 'wide-first' ? [wide, narrow] : [narrow, wide],
          );
          return RecitationCubit(poetryRepository: poetryRepository);
        },
        act: (cubit) async {
          cubit.start();
          await cubit.onTranscript('midnight dreary while I');
        },
        expect: () => [
          isA<RecitationState>(),
          isA<RecitationState>()
              .having((s) => s.located?.startToken, 'start', 3)
              .having((s) => s.located?.endToken, 'end', 8),
        ],
      );
    }

    blocTest<RecitationCubit, RecitationState>(
      'locates transcripts longer than the passage window',
      build: () {
        when(
          () => poetryRepository.findCandidatePassages(any()),
        ).thenAnswer((_) async => [candidate()]);
        return RecitationCubit(poetryRepository: poetryRepository);
      },
      act: (cubit) async {
        cubit.start();
        final long = List.filled(
          6,
          'Once upon a midnight dreary while I pondered weak and weary',
        ).join(' ');
        await cubit.onTranscript(long);
      },
      expect: () => [
        isA<RecitationState>(),
        isA<RecitationState>()
            .having((s) => s.located?.startToken, 'start', 0)
            .having((s) => s.score, 'score', 1.0)
            .having((s) => s.extraWords, 'extra words', greaterThan(0)),
      ],
    );

    test('closing during retrieval discards the result silently', () async {
      when(
        () => poetryRepository.findCandidatePassages(any()),
      ).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return [candidate()];
      });
      final cubit = RecitationCubit(poetryRepository: poetryRepository);
      addTearDown(() async {
        if (!cubit.isClosed) await cubit.close();
      });
      cubit.start();
      final pending = cubit.onTranscript('once upon a midnight');
      await cubit.close();
      // Must not throw or emit on the closed cubit.
      await pending;
      expect(cubit.state.located, isNull);
    });
  });
}
