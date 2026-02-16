import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:mneme/db/tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Poems, Authors, PoemAuthors, Metadata])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();

        // Manually create FTS5 table
        await customStatement(
          // ignore: lines_longer_than_80_chars // SQL statement
          "CREATE VIRTUAL TABLE poems_fts USING fts5(title, author, body, alt_titles, content='poems', content_rowid='id')",
        );

        // Create triggers to keep FTS in sync
        await createFtsTriggers();
      },
    );
  }

  /// Create FTS triggers to keep the FTS index in sync with the poems table
  Future<void> createFtsTriggers() async {
    // Trigger for INSERT operations
    await customStatement('''
      CREATE TRIGGER poems_ai AFTER INSERT ON poems BEGIN
        INSERT INTO poems_fts (rowid, title, author, body, alt_titles) VALUES (new.id, new.title, new.author_names, new.body, new.alt_titles);
      END;
    ''');

    // Trigger for DELETE operations
    await customStatement('''
      CREATE TRIGGER poems_ad AFTER DELETE ON poems BEGIN
        INSERT INTO poems_fts (poems_fts, rowid, title, author, body, alt_titles) VALUES ('delete', old.id, old.title, old.author_names, old.body, old.alt_titles);
      END;
    ''');

    // Trigger for UPDATE operations
    await customStatement('''
      CREATE TRIGGER poems_au AFTER UPDATE ON poems BEGIN
        INSERT INTO poems_fts (poems_fts, rowid, title, author, body, alt_titles) VALUES ('delete', old.id, old.title, old.author_names, old.body, old.alt_titles);
        INSERT INTO poems_fts (rowid, title, author, body, alt_titles) VALUES (new.id, new.title, new.author_names, new.body, new.alt_titles);
      END;
    ''');
  }

  /// Bulk insert poems using JSON for performance
  Future<void> batchInsertPoems(List<Map<String, dynamic>> poems) async {
    if (poems.isEmpty) return;

    final jsonString = json.encode(poems);

    await customStatement(
      r'''
      INSERT INTO poems (id, title, author_names, body, year, alt_titles)
      SELECT
        json_extract(value, '$.id'),
        json_extract(value, '$.title'),
        json_extract(value, '$.author_names'),
        json_extract(value, '$.body'),
        json_extract(value, '$.year'),
        json_extract(value, '$.alt_titles')
      FROM json_each(?)
      ''',
      [jsonString],
    );
  }

  /// Bulk insert authors using JSON
  Future<void> batchInsertAuthors(List<Map<String, dynamic>> authors) async {
    if (authors.isEmpty) return;

    final jsonString = json.encode(authors);

    await customStatement(
      r'''
      INSERT INTO authors (id, name, poem_count)
      SELECT
        json_extract(value, '$.id'),
        json_extract(value, '$.name'),
        json_extract(value, '$.poem_count')
      FROM json_each(?)
      ''',
      [jsonString],
    );
  }

  /// Bulk insert poem-author relations
  Future<void> batchInsertPoemAuthors(
    List<Map<String, dynamic>> relations,
  ) async {
    if (relations.isEmpty) return;

    final jsonString = json.encode(relations);

    await customStatement(
      r'''
      INSERT INTO poem_authors (poem_id, author_id)
      SELECT
        json_extract(value, '$.poem_id'),
        json_extract(value, '$.author_id')
      FROM json_each(?)
      ''',
      [jsonString],
    );
  }
}
