import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:es_compression/zstd.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mneme/db/connection/flutter_connection.dart';
import 'package:mneme/db/database.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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
    final rows = await (db.select(
      db.poems,
    )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    return [for (final row in rows) row.title];
  }

  test('opens the prepared db file instead of a fresh database', () async {
    await insertPoem(File(p.join(docsDir.path, 'en.db')), 'Prepared poem');

    expect(await readTitles('en'), ['Prepared poem']);
  });

  test('decompressed pack takes precedence over the previous db', () async {
    final source = File(p.join(supportDir.path, 'source.db'));
    await insertPoem(source, 'Pack poem');
    final packDir = Directory(p.join(supportDir.path, 'corpora'))..createSync();
    await File(
      p.join(packDir.path, 'ru.db.zst'),
    ).writeAsBytes(ZstdCodec().encode(await source.readAsBytes()));

    await insertPoem(File(p.join(docsDir.path, 'ru.db')), 'Stale poem');

    final titles = await readTitles('ru');
    expect(titles, contains('Pack poem'));
    expect(titles, isNot(contains('Stale poem')));
  });

  test('stale schema files are replaced by the installed pack', () async {
    final stale = File(p.join(docsDir.path, 'ru.db'));
    sqlite3.open(stale.path)
      ..execute('PRAGMA user_version = 1;')
      ..dispose();

    final source = File(p.join(supportDir.path, 'source.db'));
    await insertPoem(source, 'Pack poem');
    final packDir = Directory(p.join(supportDir.path, 'corpora'))..createSync();
    await File(
      p.join(packDir.path, 'ru.db.zst'),
    ).writeAsBytes(ZstdCodec().encode(await source.readAsBytes()));

    expect(await readTitles('ru'), ['Pack poem']);
  });

  test('reopening with the same pack skips decompression', () async {
    final source = File(p.join(supportDir.path, 'source.db'));
    await insertPoem(source, 'Pack poem');
    final packDir = Directory(p.join(supportDir.path, 'corpora'))..createSync();
    await File(
      p.join(packDir.path, 'ru.db.zst'),
    ).writeAsBytes(ZstdCodec().encode(await source.readAsBytes()));
    await insertPoem(File(p.join(docsDir.path, 'ru.db')), 'Stale poem');

    expect(await readTitles('ru'), ['Pack poem']);
    final dbFile = File(p.join(docsDir.path, 'ru.db'));
    final firstWrite = dbFile.lastModifiedSync();
    expect(File('${dbFile.path}.pack').existsSync(), isTrue);

    expect(await readTitles('ru'), ['Pack poem']);
    expect(dbFile.lastModifiedSync(), firstWrite);
  });

  test('current schema files are kept as is', () async {
    final file = File(p.join(docsDir.path, 'en.db'));
    await insertPoem(file, 'Kept poem');

    await invalidateStaleCorpusSchema(file);

    expect(file.existsSync(), isTrue);
    expect(await readTitles('en'), ['Kept poem']);
  });

  test('v1 databases are rebuilt on open', () async {
    final file = File(p.join(docsDir.path, 'en.db'));
    sqlite3.open(file.path)
      ..execute('CREATE TABLE poems (id INTEGER PRIMARY KEY, title TEXT);')
      ..execute('PRAGMA user_version = 1;')
      ..dispose();

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    expect(await db.select(db.poems).get(), isEmpty);

    await db
        .into(db.poems)
        .insert(
          PoemsCompanion.insert(
            title: 'Fresh poem',
            authorNames: 'Test Author',
            body: 'Test body',
            poemKey: 'fresh',
            language: 'en',
            contentHash: 'b' * 64,
          ),
        );
    expect(
      (await db.select(db.poems).get()).single.title,
      'Fresh poem',
    );
  });

  group('bundled asset fallback', () {
    late Uint8List assetBytes;

    setUp(() async {
      final source = File(p.join(supportDir.path, 'source.db'));
      await insertPoem(source, 'Asset poem');
      assetBytes = await source.readAsBytes();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => docsDir.path,
          );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            null,
          );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', null);
    });

    Future<List<String>> readTitlesWithoutDir(String name) async {
      final db = AppDatabase(
        openCorpusConnection(name: name, supportDir: supportDir),
      );
      addTearDown(db.close);
      final rows = await (db.select(
        db.poems,
      )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
      return [for (final row in rows) row.title];
    }

    test('copies the bundled asset when nothing is installed', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler(
            'flutter/assets',
            (message) async => ByteData.view(assetBytes.buffer),
          );
      expect(await readTitlesWithoutDir('en'), ['Asset poem']);
    });

    test('missing assets open an empty database', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (message) async => null);
      expect(await readTitlesWithoutDir('en'), isEmpty);
    });
  });
}
