import 'package:drift/drift.dart';
import 'package:mneme/db/tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Poems])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();

        // Manually create FTS5 table
        await customStatement(
          // ignore: lines_longer_than_80_chars // SQL statement
          "CREATE VIRTUAL TABLE poems_fts USING fts5(title, author, body, content='poems', content_rowid='id')",
        );

        // Create triggers to keep FTS in sync
        await customStatement('''
        CREATE TRIGGER poems_ai AFTER INSERT ON poems BEGIN
          INSERT INTO poems_fts (rowid, title, author, body) VALUES (new.id, new.title, new.author, new.body);
        END;
        ''');
        await customStatement('''
        CREATE TRIGGER poems_ad AFTER DELETE ON poems BEGIN
          INSERT INTO poems_fts (poems_fts, rowid, title, author, body) VALUES ('delete', old.id, old.title, old.author, old.body);
        END;
        ''');
        await customStatement('''
        CREATE TRIGGER poems_au AFTER UPDATE ON poems BEGIN
          INSERT INTO poems_fts (poems_fts, rowid, title, author, body) VALUES ('delete', old.id, old.title, old.author, old.body);
          INSERT INTO poems_fts (rowid, title, author, body) VALUES (new.id, new.title, new.author, new.body);
        END;
        ''');
      },
    );
  }
}
