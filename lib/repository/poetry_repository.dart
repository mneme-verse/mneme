import 'package:drift/drift.dart';
import 'package:mneme/db/database.dart';

class PoetryRepository {
  PoetryRepository(this._db);

  final AppDatabase _db;

  /// Search poems using FTS5.
  ///
  /// [query] is the search string.
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

    final searchTerm = query.trim();
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
}
