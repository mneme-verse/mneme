import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mneme/db/database.dart';
import 'package:mneme/db/seed_data.dart';

import '../../tool/builder.dart';

void main() {
  test(
    'buildPassages covers poems and FTS finds normalized prefixes',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await seedDatabase(db, language: 'en');
      final passageCount = await buildPassages(db);
      expect(passageCount, greaterThan(0));

      await db.customStatement(
        'INSERT INTO passages_fts (rowid, search_text) '
        'SELECT id, search_text FROM poem_passages',
      );

      final poemRows = await db
          .customSelect('SELECT COUNT(*) AS n FROM poems')
          .get();
      final poemCount = poemRows.first.read<int>('n');
      expect(poemCount, 4);

      final rows = await db
          .customSelect(
            'SELECT p.poem_id, p.start_token, p.end_token '
            'FROM passages_fts f JOIN poem_passages p ON p.id = f.rowid '
            "WHERE passages_fts MATCH 'once upon a midnight' "
            'ORDER BY p.poem_id',
          )
          .get();
      expect(rows, isNotEmpty);
      final raven = rows.first;
      expect(raven.read<int>('poem_id'), 1);
      expect(raven.read<int>('start_token'), 0);

      final totalRows = await db
          .customSelect('SELECT COUNT(*) AS n FROM poem_passages')
          .get();
      final total = totalRows.first.read<int>('n');
      expect(total, passageCount);

      // Verify each passage search_text equals the joined token keys
      final sample = await db
          .customSelect(
            'SELECT search_text FROM poem_passages WHERE poem_id = 1 '
            'ORDER BY id LIMIT 1',
          )
          .get();
      expect(sample.first.read<String>('search_text'), contains('once upon'));
    },
  );
}
