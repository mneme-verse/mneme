import 'package:bloc/bloc.dart';
import 'package:mneme/recitation/matcher.dart';
import 'package:mneme/recitation/normalized_text.dart';
import 'package:mneme/repository/poetry_repository.dart';

/// Phases of a recitation attempt.
enum RecitationPhase {
  /// No recitation in progress; transcripts are ignored.
  idle,

  /// Accepting transcripts and reporting word feedback.
  listening,
}

/// The located poem position. Token bounds index the normalized poem, so the
/// UI can highlight source words through their stored offsets.
class LocatedPassage {
  const LocatedPassage({
    required this.poemId,
    required this.poemTitle,
    required this.startToken,
    required this.endToken,
  });

  final int poemId;
  final String poemTitle;
  final int startToken;
  final int endToken;
}

/// Typed recitation state.
class RecitationState {
  const RecitationState({
    required this.phase,
    this.hypothesis = '',
    this.located,
    this.feedback = const [],
    this.extraWords = 0,
    this.score = 0,
    this.error,
  });

  const RecitationState.initial() : this(phase: RecitationPhase.idle);

  final RecitationPhase phase;

  /// The latest transcript text, as produced by the recognizer.
  final String hypothesis;

  /// The identified poem position, null while unlocated or uncertain.
  final LocatedPassage? located;

  /// Per-word feedback over the located window, in poem-token order.
  final List<WordFeedback> feedback;

  /// Hypothesis words matching no expected word (repetitions, restarts).
  final int extraWords;

  /// Match precision of the located window, zero while unlocated.
  final double score;

  /// The last retrieval failure, if any. Location and hypothesis are kept.
  final Object? error;

  RecitationState copyWith({
    RecitationPhase? phase,
    String? hypothesis,
    LocatedPassage? located,
    bool clearLocated = false,
    List<WordFeedback>? feedback,
    int? extraWords,
    double? score,
    Object? error,
  }) {
    return RecitationState(
      phase: phase ?? this.phase,
      hypothesis: hypothesis ?? this.hypothesis,
      located: clearLocated ? null : (located ?? this.located),
      feedback: feedback ?? this.feedback,
      extraWords: extraWords ?? this.extraWords,
      score: score ?? this.score,
      error: error,
    );
  }
}

/// Scores live transcripts against the corpus and reports word feedback.
///
/// The cubit never invents transcript words: [onTranscript] takes recognizer
/// output, retrieves candidate passages with FTS, and aligns the hypothesis
/// against the best candidate window. A null [RecitationState.located] is an
/// honest uncertainty signal, not a failure.
class RecitationCubit extends Cubit<RecitationState> {
  RecitationCubit({required PoetryRepository poetryRepository})
    : _poetryRepository = poetryRepository,
      super(const RecitationState.initial());

  final PoetryRepository _poetryRepository;

  /// Normalized poem bodies by poem id, kept for the session.
  final _normalizedBodies = <int, NormalizedText>{};

  /// Starts accepting transcripts, clearing any previous attempt.
  void start() {
    emit(const RecitationState(phase: RecitationPhase.listening));
  }

  /// Stops accepting transcripts, keeping the last attempt visible.
  void stop() {
    emit(state.copyWith(phase: RecitationPhase.idle));
  }

  /// Scores one recognizer transcript, interim or final.
  Future<void> onTranscript(String text) async {
    if (state.phase != RecitationPhase.listening) return;

    final hypothesisKeys = normalizeRecitationText(text).tokens
        .map((token) => token.key)
        .toList();
    if (hypothesisKeys.isEmpty) {
      emit(
        state.copyWith(
          hypothesis: text,
          clearLocated: true,
          feedback: const [],
          extraWords: 0,
          score: 0,
        ),
      );
      return;
    }

    try {
      final candidates = await _poetryRepository.findCandidatePassages(
        hypothesisKeys,
      );
      final located = _locateBest(candidates, hypothesisKeys);
      if (located == null) {
        emit(
          state.copyWith(
            hypothesis: text,
            clearLocated: true,
            feedback: const [],
            extraWords: 0,
            score: 0,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          hypothesis: text,
          located: located.passage,
          feedback: located.feedback,
          extraWords: located.extraWords,
          score: located.score,
        ),
      );
    } on Exception catch (error) {
      emit(state.copyWith(hypothesis: text, error: error));
    }
  }

  _Located? _locateBest(
    List<RecitationCandidate> candidates,
    List<String> hypothesisKeys,
  ) {
    _Located? best;
    for (final candidate in candidates) {
      final normalized = _normalizedBodies.putIfAbsent(
        candidate.poemId,
        () => normalizeRecitationText(candidate.poemBody),
      );
      final start = candidate.startToken.clamp(0, normalized.tokens.length);
      final end = candidate.endToken.clamp(start, normalized.tokens.length);
      if (start >= end) continue;
      final expectedKeys = [
        for (var i = start; i < end; i++) normalized.tokens[i].key,
      ];
      final alignment = alignRecitation(
        expectedKeys: expectedKeys,
        hypothesisKeys: hypothesisKeys,
      );
      final score = hypothesisKeys.isEmpty
          ? 0.0
          : alignment.matchedWords / hypothesisKeys.length;
      if (!isLocated(matchedWords: alignment.matchedWords, score: score)) {
        continue;
      }
      if (best == null ||
          score > best.score ||
          (score == best.score &&
              alignment.matchedWords > best.alignment.matchedWords)) {
        best = _Located(
          passage: LocatedPassage(
            poemId: candidate.poemId,
            poemTitle: candidate.poemTitle,
            startToken: start,
            endToken: end,
          ),
          feedback: [
            for (final word in alignment.words)
              (
                tokenIndex: word.tokenIndex + start,
                verdict: word.verdict,
                heard: word.heard,
              ),
          ],
          extraWords: alignment.extraWords,
          score: score,
          alignment: alignment,
        );
      }
    }
    return best;
  }
}

class _Located {
  const _Located({
    required this.passage,
    required this.feedback,
    required this.extraWords,
    required this.score,
    required this.alignment,
  });

  final LocatedPassage passage;
  final List<WordFeedback> feedback;
  final int extraWords;
  final double score;
  final AlignmentResult alignment;
}
