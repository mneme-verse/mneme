import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:es_compression/zstd.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mneme/db/connection/flutter_connection.dart';
import 'package:mneme/db/database.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory docsDir;
  late Directory supportDir;

  setUp(() {
    docsDir = Directory.systemTemp.createTempSync('mneme-conn-docs');
    supportDir = Directory.systemTemp.createTempSync('mneme-conn-support');
  });

  tearDown(() {
    docsDir.deleteSync(recursive: true);
    supportDir.deleteSync(recursive: true);
  });

  Future<void> insertPoem(File file, String title) async {
    final db = AppDatabase(NativeDatabase(file));
    await db
        .into(db.poems)
        .insert(
          PoemsCompanion.insert(
            title: title,
            authorNames: 'Test Author',
            body: 'Test body',
            poemKey: 'key-$title',
            language: 'en',
            contentHash: 'a' * 64,
          ),
        );
    await db.close();
  }

  Future<List<String>> readTitles(String name) async {
    final db = AppDatabase(
      openCorpusConnection(
        name: name,
        supportDir: supportDir,
        documentsDir: docsDir,
      ),
    );
    addTearDown(db.close);
    final rows =
        await (db.select(db.poems)
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get();
    return [for (final row in rows) row.title];
  }

  test('opens the prepared db file instead of a fresh database', () async {
    await insertPoem(File(p.join(docsDir.path, 'en.db')), 'Prepared poem');

    expect(await readTitles('en'), ['Prepared poem']);
  });

  test('decompressed pack takes precedence over the previous db', () async {
    final source = File(p.join(supportDir.path, 'source.db'));
    await insertPoem(source, 'Pack poem');
    final packDir = Directory(p.join(supportDir.path, 'corpora'))
      ..createSync();
    await File(
      p.join(packDir.path, 'ru.db.zst'),
    ).writeAsBytes(ZstdCodec().encode(await source.readAsBytes()));

    await insertPoem(File(p.join(docsDir.path, 'ru.db')), 'Stale poem');

    final titles = await readTitles('ru');
    expect(titles, contains('Pack poem'));
    expect(titles, isNot(contains('Stale poem')));
  });
}
