import 'package:drift/drift.dart';
import 'package:mneme/db/database.dart';

class PoetryRepository {
  PoetryRepository(this._db);

  final AppDatabase _db;

  /// Search poems using FTS5 with as-you-type prefix matching.
  ///
  /// [query] is the search string; the last term becomes a prefix query
  /// (`Pus` matches `Pushkin`), so results narrow while typing.
  /// [activeLanguages] filters results by language code.
  Future<List<Poem>> searchPoems(
    String query,
    List<String> activeLanguages, {
    int limit = 20,
    int offset = 0,
  }) async {
    // If query is empty, return standard list
    // (active DB is already language specific)
    if (query.trim().isEmpty) {
      return (_db.select(_db.poems)..limit(limit, offset: offset)).get();
    }

    // Use customSelect for FTS5
    // We select from poems table based on FTS match
    // Note: '?' in customSelect is a variable placeholder.
    // WHERE language IN (?) is tricky in raw SQL with Drift (list expansion).
    // Drift's customSelect handles variables but for IN clause it expects
    // explicit placeholders or we can build the query.

    // Safer approach: Use Variable.withString for activeLanguages?
    // No, IN takes a list. Drift `customSelect` variables are positional.
    // If we have variable number of languages, we need to generate
    // placeholders.

    final searchTerm = _prefixTerm(query);
    const sql = '''
      SELECT poems.* 
      FROM poems 
      JOIN poems_fts ON poems.id = poems_fts.rowid 
      WHERE poems_fts MATCH ? 
      LIMIT ? OFFSET ?
    ''';

    final variables = [
      Variable.withString(searchTerm),
      Variable.withInt(limit),
      Variable.withInt(offset),
    ];

    final rows = await _db
        .customSelect(
          sql,
          variables: variables,
          // No table object for poems_fts, but we read from poems effectively
          readsFrom: {_db.poems},
        )
        .get();

    return rows.map((row) => _db.poems.map(row.data)).toList();
  }

  /// Get a random poem from the active languages.
  Future<Poem?> getRandomPoem(List<String> activeLanguages) async {
    final query = _db.select(_db.poems)
      ..orderBy([(t) => OrderingTerm.random()])
      ..limit(1);

    return query.getSingleOrNull();
  }

  /// Get list of authors sorted by poem count (descending).
  Future<List<Author>> getAuthors({int limit = 20, int offset = 0}) {
    return (_db.select(_db.authors)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.poemCount, mode: OrderingMode.desc),
          ])
          ..limit(limit, offset: offset))
        .get();
  }

  /// Get metadata value by key.
  Future<String?> getMetadata(String key) async {
    final query = _db.select(_db.metadata)..where((t) => t.key.equals(key));
    final result = await query.getSingleOrNull();
    return result?.value;
  }

  /// Finds recitation passages matching the recognized words.
  ///
  /// [termKeys] are normalized hypothesis keys. Each key becomes a quoted
  /// FTS5 term joined with OR, so hostile input stays a literal search and
  /// can never inject FTS syntax. At most 12 terms are queried: the first
  /// 4 anchor the passage start and the last 8 cover the live recitation
  /// edge, so long cumulative transcripts keep retrieving where the
  /// learner currently is. Most relevant passages come first (`rank`),
  /// then passage id, so common words cannot starve a later poem past
  /// the [limit]. Empty input short-circuits to no candidates.
  Future<List<RecitationCandidate>> findCandidatePassages(
    List<String> termKeys, {
    int limit = 5,
  }) async {
    final keys = termKeys.where((term) => term.isNotEmpty).toList();
    // First 4 anchor the passage start, last 8 the live recitation edge.
    // Short inputs keep every term through deduplication below.
    final tailStart = keys.length - 8 < 4 ? 4 : keys.length - 8;
    final selected = {
      ...keys.take(4),
      if (keys.length > 4) ...keys.sublist(tailStart),
    };
    final terms = selected
        .map((term) => '"${term.replaceAll('"', '""')}"')
        .toList();
    if (terms.isEmpty) return [];
    const sql = '''
      SELECT p.id AS passage_id, p.poem_id, p.start_token, p.end_token,
        poems.title, poems.body
      FROM passages_fts
      JOIN poem_passages p ON p.id = passages_fts.rowid
      JOIN poems ON poems.id = p.poem_id
      WHERE passages_fts MATCH ?
      ORDER BY rank, p.id
      LIMIT ?
    ''';
    final rows = await _db
        .customSelect(
          sql,
          variables: [
            Variable.withString(terms.join(' OR ')),
            Variable.withInt(limit),
          ],
          readsFrom: {_db.poems, _db.poemPassages},
        )
        .get();
    return [
      for (final row in rows)
        RecitationCandidate(
          passageId: row.read<int>('passage_id'),
          poemId: row.read<int>('poem_id'),
          poemTitle: row.read<String>('title'),
          poemBody: row.read<String>('body'),
          startToken: row.read<int>('start_token'),
          endToken: row.read<int>('end_token'),
        ),
    ];
  }

  /// One poem by database id, null when absent.
  Future<Poem?> getPoemById(int id) {
    return (_db.select(
      _db.poems,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// One poem by stable builder key, null when absent.
  Future<Poem?> getPoemByKey(String poemKey) {
    return (_db.select(
      _db.poems,
    )..where((t) => t.poemKey.equals(poemKey))).getSingleOrNull();
  }

  /// Poems for one author, most prolific ordering is the caller's concern;
  /// here insertion order keeps the author's list stable.
  Future<List<Poem>> getPoemsByAuthor(String authorName) async {
    final rows = await (_db.select(_db.poemAuthors).join([
      innerJoin(
        _db.authors,
        _db.authors.id.equalsExp(_db.poemAuthors.authorId),
      ),
      innerJoin(_db.poems, _db.poems.id.equalsExp(_db.poemAuthors.poemId)),
    ])..where(_db.authors.name.equals(authorName))).get();
    return rows.map((row) => row.readTable(_db.poems)).toList();
  }
}

/// Turns a raw query into an FTS5 prefix query on its last term, so
/// as-you-type input narrows results (`Pus` matches `Pushkin`). Terms that
/// cannot take the prefix operator pass through unchanged.
String _prefixTerm(String query) {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return trimmed;
  final lastSpace = trimmed.lastIndexOf(RegExp(r'\s'));
  final head = lastSpace < 0 ? '' : '${trimmed.substring(0, lastSpace)} ';
  final tail = lastSpace < 0 ? trimmed : trimmed.substring(lastSpace + 1);
  if (tail.endsWith('*') || tail.endsWith('"')) return trimmed;
  if (!RegExp(r'[\p{L}\p{N}]$', unicode: true).hasMatch(tail)) {
    return trimmed;
  }
  return '$head$tail*';
}

/// One FTS passage hit: the poem it belongs to plus the token window the
/// hypothesis matched. The cubit normalizes [poemBody] for detailed
/// alignment; the window bounds select the expected tokens.
class RecitationCandidate {
  const RecitationCandidate({
    required this.passageId,
    required this.poemId,
    required this.poemTitle,
    required this.poemBody,
    required this.startToken,
    required this.endToken,
  });

  final int passageId;
  final int poemId;
  final String poemTitle;
  final String poemBody;
  final int startToken;
  final int endToken;
}
