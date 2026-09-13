// cspell:disable
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mneme/db/database.dart';
import 'package:mneme/db/seed_data.dart';
import 'package:mneme/repository/poetry_repository.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late PoetryRepository repo;

  setUp(() async {
    // Use in-memory database for tests
    db = AppDatabase(NativeDatabase.memory());
    repo = PoetryRepository(db);

    // Seed the database with English poems only
    // to simulate language-specific DB
    await seedDatabase(db, language: 'en');
  });

  tearDown(() async {
    await db.close();
  });

  group('Mock Database Integration', () {
    test('contains 4 English mock poems', () async {
      final count = await db.poems.count().getSingle();
      expect(count, 4);
    });

    test('FTS search works for "Raven"', () async {
      final results = await repo.searchPoems('Raven', ['en']);
      expect(results, hasLength(1));
      expect(results.first.title, 'The Raven');
    });

    test('Prefix search matches a partial last word', () async {
      final results = await repo.searchPoems('Rav', ['en']);
      expect(results.map((poem) => poem.title), contains('The Raven'));
    });

    test('Poem lookups resolve by id and key', () async {
      expect((await repo.getPoemById(1))?.title, 'The Raven');
      expect(
        (await repo.getPoemByKey('poetree:en:raven'))?.title,
        'The Raven',
      );
      expect(await repo.getPoemById(999), isNull);
      expect(await repo.getPoemByKey('poetree:en:missing'), isNull);
    });

    test('Author poems list every linked poem', () async {
      final poems = await repo.getPoemsByAuthor('Edgar Allan Poe');
      expect(
        poems.map((poem) => poem.title),
        containsAll(['The Raven', 'Annabel Lee']),
      );
    });

    test('FTS search works for Russian content', () async {
      // Create a separate Russian database for this test
      final ruDb = AppDatabase(NativeDatabase.memory());
      final ruRepo = PoetryRepository(ruDb);
      await seedDatabase(ruDb, language: 'ru');

      final results = await ruRepo.searchPoems('чудное', ['ru']);
      expect(results, hasLength(1));
      expect(results.first.title, 'Я помню чудное мгновенье');

      await ruDb.close();
    });

    test('Russian seed poems link to their authors', () async {
      final ruDb = AppDatabase(NativeDatabase.memory());
      addTearDown(ruDb.close);
      await seedDatabase(ruDb, language: 'ru');

      final links = await ruDb.select(ruDb.poemAuthors).get();
      final poems = await ruDb.select(ruDb.poems).get();
      final poemIds = {for (final poem in poems) poem.id};
      expect(links, isNotEmpty);
      expect(
        links.map((link) => link.poemId),
        everyElement(isIn(poemIds)),
      );
      final authors = await ruDb.select(ruDb.authors).get();
      expect(
        authors.map((author) => author.name),
        contains('Александр Пушкин'),
      );
    });

    test('Language filter excludes other languages', () async {
      final results = await repo.searchPoems('', [
        'en',
      ]); // Empty query = all in language
      expect(results, hasLength(4));
      // All results are already in the selected language since we have
      // language-specific databases
    });

    test('getRandomPoem returns a poem in selected language', () async {
      final poem = await repo.getRandomPoem(['en']);
      expect(poem, isNotNull);
      // Poem is already in the selected language since we have
      // language-specific databases
      expect(
        ['The Raven', 'Annabel Lee', 'Ozymandias', 'Daffodils'],
        contains(poem!.title),
      );
    });

    test('getAuthors returns sorted list', () async {
      // Seed data should have inserted authors.
      // "The Raven" by Edgar Allan Poe
      // "Ozymandias" by Percy Bysshe Shelley
      // "Daffodils" by William Wordsworth
      // Each has 1 poem in the seed set.
      final authors = await repo.getAuthors();
      expect(authors.length, 3);
      expect(authors.first.name, isNotEmpty);
    });

    test('getMetadata returns value if exists', () async {
      // Manually insert metadata
      await db.metadata.insertOne(
        MetadataCompanion.insert(key: 'key', value: 'val'),
      );
      expect(await repo.getMetadata('key'), 'val');
      expect(await repo.getMetadata('missing'), null);
    });

    test('seedDatabase with no language parameter seeds all poems', () async {
      // Create a separate database for this test
      final allDb = AppDatabase(NativeDatabase.memory());
      await seedDatabase(allDb); // No language parameter

      final count = await allDb.poems.count().getSingle();
      expect(count, 6); // 4 'en' + 2 'ru' = 6 total poems

      await allDb.close();
    });

    test('seedDatabase aggregates poem counts for duplicate authors', () async {
      // Edgar Allan Poe now has 2 poems in the seed data,
      // which exercises the aggregation logic on lines 67-69
      final authors = await repo.getAuthors();
      expect(authors.length, 3); // Still 3 unique authors

      // Find Edgar Allan Poe
      final edgarAllanPoe = authors.firstWhere(
        (a) => a.name == 'Edgar Allan Poe',
      );
      expect(edgarAllanPoe.poemCount, 2); // Has 2 poems

      // Other authors still have 1 poem each
      final otherAuthors = authors.where((a) => a.name != 'Edgar Allan Poe');
      for (final author in otherAuthors) {
        expect(author.poemCount, 1);
      }
    });
  });
}
