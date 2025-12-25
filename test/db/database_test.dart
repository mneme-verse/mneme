import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mneme/db/database.dart';
import 'package:mneme/db/seed_data.dart';
import 'package:mneme/repository/poetry_repository.dart';

void main() {
  late AppDatabase db;
  late PoetryRepository repo;

  setUp(() async {
    // Use in-memory database for tests
    db = AppDatabase(NativeDatabase.memory());
    repo = PoetryRepository(db);

    // Seed the database with mock data
    await seedDatabase(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Mock Database Integration', () {
    test('contains 5 mock poems', () async {
      final count = await db.poems.count().getSingle();
      expect(count, 5);
    });

    test('FTS search works for "Raven"', () async {
      final results = await repo.searchPoems('Raven', ['en']);
      expect(results, hasLength(1));
      expect(results.first.title, 'The Raven');
    });

    test('FTS search works for Russian content', () async {
      final results = await repo.searchPoems('чудное', ['ru']);
      expect(results, hasLength(1));
      expect(results.first.title, 'Я помню чудное мгновенье');
    });

    test('Language filter excludes other languages', () async {
      final results = await repo.searchPoems('', [
        'en',
      ]); // Empty query = all in language
      expect(results, hasLength(3));
      expect(results.every((p) => p.language == 'en'), isTrue);
    });

    test('getRandomPoem returns a poem in selected language', () async {
      final poem = await repo.getRandomPoem(['ru']);
      expect(poem, isNotNull);
      expect(poem!.language, 'ru');
    });
  });
}
