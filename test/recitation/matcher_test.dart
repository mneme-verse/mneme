import 'package:flutter_test/flutter_test.dart';
import 'package:mneme/recitation/matcher.dart';

void main() {
  group('alignRecitation', () {
    test('marks a perfect recitation all correct', () {
      final result = alignRecitation(
        expectedKeys: const ['я', 'помню', 'чудное', 'мгновенье'],
        hypothesisKeys: const ['я', 'помню', 'чудное', 'мгновенье'],
      );

      expect(result.extraWords, 0);
      expect(result.matchedWords, 4);
      expect(
        result.words.map((word) => word.verdict),
        everyElement(WordVerdict.correct),
      );
      expect(
        result.words.map((word) => word.tokenIndex),
        [0, 1, 2, 3],
      );
    });

    test('reports a misrecognized word with what was heard', () {
      final result = alignRecitation(
        expectedKeys: const ['once', 'upon', 'a', 'midnight'],
        hypothesisKeys: const ['once', 'upon', 'banana', 'midnight'],
      );

      expect(result.matchedWords, 3);
      expect(result.words[2].verdict, WordVerdict.wrong);
      expect(result.words[2].heard, 'banana');
      expect(result.words[3].verdict, WordVerdict.correct);
    });

    test('marks a skipped word wrong without shifting the rest', () {
      final result = alignRecitation(
        expectedKeys: const ['once', 'upon', 'a', 'midnight', 'dreary'],
        hypothesisKeys: const ['once', 'upon', 'midnight', 'dreary'],
      );

      expect(result.words[2].verdict, WordVerdict.wrong);
      expect(result.words[2].heard, isNull);
      expect(result.words[3].verdict, WordVerdict.correct);
      expect(result.words[4].verdict, WordVerdict.correct);
    });

    test('counts restarted words as extras, never as errors', () {
      final result = alignRecitation(
        expectedKeys: const ['я', 'помню'],
        hypothesisKeys: const ['я', 'помню', 'я', 'помню'],
      );

      expect(result.matchedWords, 2);
      expect(result.extraWords, 2);
      expect(
        result.words.map((word) => word.verdict),
        everyElement(WordVerdict.correct),
      );
    });

    test('marks unreached trailing words pending, not wrong', () {
      final result = alignRecitation(
        expectedKeys: const ['я', 'помню', 'чудное', 'мгновенье'],
        hypothesisKeys: const ['я', 'помню'],
      );

      expect(result.words[0].verdict, WordVerdict.correct);
      expect(result.words[1].verdict, WordVerdict.correct);
      expect(result.words[2].verdict, WordVerdict.pending);
      expect(result.words[3].verdict, WordVerdict.pending);
    });

    test('marks everything pending when nothing was heard', () {
      final result = alignRecitation(
        expectedKeys: const ['я', 'помню'],
        hypothesisKeys: const [],
      );

      expect(result.matchedWords, 0);
      expect(
        result.words.map((word) => word.verdict),
        everyElement(WordVerdict.pending),
      );
    });
  });

  group('scoreRecitation and isLocated', () {
    test('scores precision over the hypothesis length', () {
      expect(
        scoreRecitation(
          expectedKeys: const ['a', 'b', 'c', 'd'],
          hypothesisKeys: const ['a', 'b'],
        ),
        1.0,
      );
      expect(
        scoreRecitation(
          expectedKeys: const ['a', 'b', 'c', 'd'],
          hypothesisKeys: const ['a', 'x'],
        ),
        0.5,
      );
      expect(
        scoreRecitation(
          expectedKeys: const ['a', 'b'],
          hypothesisKeys: const [],
        ),
        0,
      );
    });

    test('refuses to locate on one or two matching words', () {
      expect(isLocated(matchedWords: 2, score: 1), isFalse);
      expect(isLocated(matchedWords: 3, score: 0.4), isFalse);
      expect(isLocated(matchedWords: 3, score: 0.75), isTrue);
    });
  });
}
