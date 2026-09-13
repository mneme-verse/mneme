import 'package:unorm_dart/unorm_dart.dart' as unorm;

/// A word's immutable coordinates in the original UTF-16 source.
typedef RecitationToken = ({
  int start,
  int end,
  int lineIndex,
  String surface,
  String key,
});

/// Comparison text with a source-token mapping for every UTF-16 anchor unit.
class NormalizedText {
  const NormalizedText({
    required this.original,
    required this.tokens,
    required this.anchorText,
    required this.anchorTokenIndices,
  });

  final String original;
  final List<RecitationToken> tokens;
  final String anchorText;

  /// Separators belong to the preceding token; surrogate halves share a token.
  final List<int> anchorTokenIndices;
}

final _words = RegExp(
  r"[\p{L}\p{M}\p{N}]+(?:['’‘ʼ][\p{L}\p{M}\p{N}]+)*",
  unicode: true,
);
final _mark = RegExp(r'^\p{M}$', unicode: true);
final _cyrillic = RegExp(r'^\p{Script=Cyrillic}$', unicode: true);

/// Normalize keys separately, never the source used for display coordinates.
NormalizedText normalizeRecitationText(String text) {
  final tokens = <RecitationToken>[];
  final anchor = StringBuffer();
  final mapping = <int>[];
  var scanned = 0;
  var line = 0;
  for (final match in _words.allMatches(text)) {
    while (scanned < match.start) {
      final unit = text.codeUnitAt(scanned);
      if (unit == 10 ||
          (unit == 13 &&
              (scanned + 1 == text.length ||
                  text.codeUnitAt(scanned + 1) != 10))) {
        line++;
      }
      scanned++;
    }
    final surface = match.group(0)!;
    final key = _comparisonKey(surface);
    if (tokens.isNotEmpty) {
      anchor.write(' ');
      mapping.add(tokens.length - 1);
    }
    anchor.write(key);
    mapping.addAll(List<int>.filled(key.length, tokens.length));
    tokens.add((
      start: match.start,
      end: match.end,
      lineIndex: line,
      surface: surface,
      key: key,
    ));
  }
  return NormalizedText(
    original: text,
    tokens: List.unmodifiable(tokens),
    anchorText: anchor.toString(),
    anchorTokenIndices: List.unmodifiable(mapping),
  );
}

String _comparisonKey(String surface) {
  final decomposed = unorm.nfd(surface.toLowerCase());
  final result = StringBuffer();
  var cyrillicBase = false;
  for (final rune in decomposed.runes) {
    final character = String.fromCharCode(rune);
    final isMark = _mark.hasMatch(character);
    if (!isMark) cyrillicBase = _cyrillic.hasMatch(character);
    if (cyrillicBase && (rune == 0x300 || rune == 0x301)) continue;
    result.write(character);
  }
  return unorm
      .nfc(result.toString())
      .replaceAll('ё', 'е')
      .replaceAll(
        RegExp('[’‘ʼ]'),
        "'",
      );
}
