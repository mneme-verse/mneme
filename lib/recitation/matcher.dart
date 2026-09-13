/// Word-level comparison of a speech-recognition hypothesis against the
/// expected poem text.
///
/// All inputs are normalized token keys from `normalizeRecitationText`; the
/// matcher never sees display surfaces or audio. It cannot tell whether a
/// matched word was pronounced well, only that the recognizer produced the
/// expected word.
library;

/// Verdict for one expected word.
enum WordVerdict {
  /// The recognizer produced the expected word.
  correct,

  /// The word was skipped or a different word was heard.
  wrong,

  /// Nothing heard yet at or after this position (recitation in progress).
  pending,
}

/// Feedback for one expected token.
///
/// `tokenIndex` is the token's index in the normalized poem, so the UI can
/// highlight the source word via its stored offsets. `heard` is the
/// normalized hypothesis key when a different word was heard, null when the
/// word was skipped or nothing was heard yet.
typedef WordFeedback = ({
  int tokenIndex,
  WordVerdict verdict,
  String? heard,
});

/// Result of aligning one hypothesis against one expected token window.
class AlignmentResult {
  const AlignmentResult({required this.words, required this.extraWords});

  /// One entry per expected token, in poem-token order.
  final List<WordFeedback> words;

  /// Hypothesis words consumed by no expected token (repetitions, restarts).
  final int extraWords;

  /// Expected words the recognizer produced.
  int get matchedWords =>
      words.where((word) => word.verdict == WordVerdict.correct).length;
}

/// Minimum hypothesis words that must match before a passage locates.
const minLocatedWords = 3;

/// Minimum `matchedWords / hypothesisLength` for a passage to locate.
const minLocatedScore = 0.5;

/// Aligns [hypothesisKeys] against [expectedKeys] with word edit distance.
///
/// Substitutions cost 2 (one wrong word, not a skip plus an insertion), so a
/// misrecognized word reports what was heard. Insertions (repeated or
/// restarted words) never punish expected tokens; they count as
/// [AlignmentResult.extraWords]. Leading skips are [WordVerdict.wrong]:
/// alignment assumes the window is where recitation happens. Trailing
/// unreached tokens are [WordVerdict.pending], never wrong, so live
/// recitation does not flag words the learner has not reached.
AlignmentResult alignRecitation({
  required List<String> expectedKeys,
  required List<String> hypothesisKeys,
}) {
  final distances = _editDistances(expectedKeys, hypothesisKeys);
  final operations = _backtrack(distances, expectedKeys, hypothesisKeys);

  var lastHeardOp = -1;
  for (var i = 0; i < operations.length; i++) {
    if (operations[i].type != _OpType.delete) lastHeardOp = i;
  }

  final words = <WordFeedback>[];
  var extraWords = 0;
  var tokenIndex = 0;
  for (var i = 0; i < operations.length; i++) {
    final op = operations[i];
    switch (op.type) {
      case _OpType.match:
        words.add((
          tokenIndex: tokenIndex,
          verdict: WordVerdict.correct,
          heard: null,
        ));
        tokenIndex++;
      case _OpType.substitute:
        words.add((
          tokenIndex: tokenIndex,
          verdict: WordVerdict.wrong,
          heard: hypothesisKeys[op.hypothesisIndex],
        ));
        tokenIndex++;
      case _OpType.delete:
        words.add((
          tokenIndex: tokenIndex,
          verdict: i > lastHeardOp ? WordVerdict.pending : WordVerdict.wrong,
          heard: null,
        ));
        tokenIndex++;
      case _OpType.insert:
        extraWords++;
    }
  }
  return AlignmentResult(words: words, extraWords: extraWords);
}

/// Precision of [hypothesisKeys] against [expectedKeys]: matched words over
/// hypothesis length. Zero when the hypothesis is empty.
double scoreRecitation({
  required List<String> expectedKeys,
  required List<String> hypothesisKeys,
}) {
  if (hypothesisKeys.isEmpty) return 0;
  final matched = alignRecitation(
    expectedKeys: expectedKeys,
    hypothesisKeys: hypothesisKeys,
  ).matchedWords;
  return matched / hypothesisKeys.length;
}

/// Whether an alignment is strong enough to claim "which poem and where".
bool isLocated({required int matchedWords, required double score}) =>
    matchedWords >= minLocatedWords && score >= minLocatedScore;

enum _OpType { match, substitute, delete, insert }

typedef _Op = ({_OpType type, int hypothesisIndex});

List<List<int>> _editDistances(
  List<String> expectedKeys,
  List<String> hypothesisKeys,
) {
  final distances = List.generate(
    expectedKeys.length + 1,
    (i) => List.filled(hypothesisKeys.length + 1, 0),
  );
  for (var i = 1; i <= expectedKeys.length; i++) {
    distances[i][0] = i;
  }
  for (var j = 1; j <= hypothesisKeys.length; j++) {
    distances[0][j] = j;
  }
  for (var i = 1; i <= expectedKeys.length; i++) {
    for (var j = 1; j <= hypothesisKeys.length; j++) {
      final substitution =
          distances[i - 1][j - 1] +
          (expectedKeys[i - 1] == hypothesisKeys[j - 1] ? 0 : 2);
      var best = substitution;
      final deletion = distances[i - 1][j] + 1;
      if (deletion < best) best = deletion;
      final insertion = distances[i][j - 1] + 1;
      if (insertion < best) best = insertion;
      distances[i][j] = best;
    }
  }
  return distances;
}

List<_Op> _backtrack(
  List<List<int>> distances,
  List<String> expectedKeys,
  List<String> hypothesisKeys,
) {
  final operations = <_Op>[];
  var i = expectedKeys.length;
  var j = hypothesisKeys.length;
  while (i > 0 || j > 0) {
    if (i > 0 &&
        j > 0 &&
        distances[i][j] ==
            distances[i - 1][j - 1] +
                (expectedKeys[i - 1] == hypothesisKeys[j - 1] ? 0 : 2)) {
      operations.add((
        type: expectedKeys[i - 1] == hypothesisKeys[j - 1]
            ? _OpType.match
            : _OpType.substitute,
        hypothesisIndex: j - 1,
      ));
      i--;
      j--;
    } else if (i > 0 && distances[i][j] == distances[i - 1][j] + 1) {
      operations.add((type: _OpType.delete, hypothesisIndex: -1));
      i--;
    } else {
      operations.add((type: _OpType.insert, hypothesisIndex: j - 1));
      j--;
    }
  }
  return operations.reversed.toList();
}
