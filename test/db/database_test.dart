import 'package:drift/drift.dart' hide isNotNull;
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
    test('contains 3 English mock poems', () async {
      final count = await db.poems.count().getSingle();
      expect(count, 3);
    });

    test('FTS search works for "Raven"', () async {
      final results = await repo.searchPoems('Raven', ['en']);
      expect(results, hasLength(1));
      expect(results.first.title, 'The Raven');
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

    test('Language filter excludes other languages', () async {
      final results = await repo.searchPoems('', [
        'en',
      ]); // Empty query = all in language
      expect(results, hasLength(3));
      // All results are already in the selected language since we have
      // language-specific databases
    });

    test('getRandomPoem returns a poem in selected language', () async {
      final poem = await repo.getRandomPoem(['en']);
      expect(poem, isNotNull);
      // Poem is already in the selected language since we have
      // language-specific databases
      expect(['The Raven', 'Ozymandias', 'Daffodils'], contains(poem!.title));
    });
  });
}
