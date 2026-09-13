import 'package:flutter_test/flutter_test.dart';
import 'package:mneme/recitation/normalized_text.dart';

void main() {
  group('normalizeRecitationText', () {
    test('tokenizes a quatrain with exact UTF-16 offsets', () {
      const text =
          'Я помню чудное мгновенье:\n'
          'Передо мной явилась ты,\n'
          'Как мимолётное виденье,\n'
          'Как гений чистой красоты.';
      final normalized = normalizeRecitationText(text);
      expect(normalized.original, text);
      expect(normalized.tokens.length, 15);
      final first = normalized.tokens.first;
      expect(first.surface, 'Я');
      expect(first.key, 'я');
      expect(first.start, 0);
      expect(first.end, 1);
      expect(first.lineIndex, 0);
      final last = normalized.tokens.last;
      expect(last.surface, 'красоты');
      expect(last.key, 'красоты');
      expect(text.substring(last.start, last.end), 'красоты');
      expect(last.lineIndex, 3);
      expect(
        normalized.tokens
            .where((token) => token.lineIndex == 2)
            .map((token) => token.surface),
        containsAllInOrder(<String>['Как', 'мимолётное', 'виденье']),
      );
    });

    test('maps ё to е in keys, never in surfaces', () {
      final normalized = normalizeRecitationText('Ёлка мимолётная');
      expect(
        normalized.tokens.map((token) => token.key),
        ['елка', 'мимолетная'],
      );
      expect(
        normalized.tokens.map((token) => token.surface),
        ['Ёлка', 'мимолётная'],
      );
    });

    test('strips stress marks only on Cyrillic bases', () {
      final cyrillic = normalizeRecitationText('мгнове\u0301нье');
      expect(cyrillic.tokens.single.key, 'мгновенье');
      expect(cyrillic.tokens.single.surface, 'мгнове\u0301нье');
      final latin = normalizeRecitationText('cafe\u0301');
      expect(latin.tokens.single.key, 'café');
    });

    test('preserves French accents for composed and decomposed input', () {
      const composedText = "l'amour et l'été";
      const decomposedText = "l'amour et l'e\u0301te\u0301";
      final composed = normalizeRecitationText(composedText);
      final decomposed = normalizeRecitationText(decomposedText);
      expect(
        composed.tokens.map((token) => token.key),
        ["l'amour", 'et', "l'été"],
      );
      expect(
        decomposed.tokens.map((token) => token.key),
        composed.tokens.map((token) => token.key),
      );
      expect(
        composed.original.substring(
          composed.tokens.last.start,
          composed.tokens.last.end,
        ),
        "l'été",
      );
      final normalized = normalizeRecitationText('l’amour ‘вес’на');
      expect(
        normalized.tokens.map((token) => token.key),
        ["l'amour", "вес'на"],
      );
      expect(normalized.tokens.first.surface, 'l’amour');
    });

    test('tokenizes digits as words', () {
      final normalized = normalizeRecitationText('19 июля 1825');
      expect(
        normalized.tokens.map((token) => token.key),
        ['19', 'июля', '1825'],
      );
    });

    test('counts CRLF, lone CR, and blank lines as line breaks', () {
      final crlf = normalizeRecitationText('один\r\nдва');
      expect(crlf.tokens.last.lineIndex, 1);
      final loneCr = normalizeRecitationText('один\rдва');
      expect(loneCr.tokens.last.lineIndex, 1);
      final blankLines = normalizeRecitationText('\n\nслово');
      expect(blankLines.tokens.single.lineIndex, 2);
    });

    test('returns no tokens for punctuation-only or empty input', () {
      for (final text in ['', '!!! ...', '—“ ”…']) {
        final normalized = normalizeRecitationText(text);
        expect(normalized.tokens, isEmpty);
        expect(normalized.anchorText, '');
        expect(normalized.anchorTokenIndices, isEmpty);
      }
    });

    test('maps every anchor character back to its source token', () {
      const text = 'Как мимолётное виденье';
      final normalized = normalizeRecitationText(text);
      expect(normalized.anchorText, 'как мимолетное виденье');
      expect(
        normalized.anchorTokenIndices.length,
        normalized.anchorText.length,
      );
      final secondStart = normalized.anchorText.indexOf('мимолетное');
      final secondEnd = secondStart + 'мимолетное'.length;
      for (var i = secondStart; i < secondEnd; i++) {
        expect(normalized.anchorTokenIndices[i], 1);
      }
      final firstSpace = normalized.anchorText.indexOf(' ');
      expect(normalized.anchorTokenIndices[firstSpace], 0);
      final secondSpace = normalized.anchorText.lastIndexOf(' ');
      expect(normalized.anchorTokenIndices[secondSpace], 1);
      for (var i = 0; i < normalized.anchorText.length; i++) {
        final character = normalized.anchorText[i];
        if (character == ' ') continue;
        final key = normalized.tokens[normalized.anchorTokenIndices[i]].key;
        expect(key, contains(character));
      }
    });

    test('keeps offsets correct across non-token surrogate pairs', () {
      const text = '😀слово';
      final normalized = normalizeRecitationText(text);
      final token = normalized.tokens.single;
      expect(token.start, 2);
      expect(text.substring(token.start, token.end), 'слово');
    });
  });
}
