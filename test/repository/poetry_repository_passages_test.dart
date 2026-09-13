import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mneme/db/database.dart';
import 'package:mneme/db/seed_data.dart';
import 'package:mneme/repository/poetry_repository.dart';

import '../../tool/builder.dart';

void main() {
  late AppDatabase db;
  late PoetryRepository repository;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await seedDatabase(db, language: 'en');
    await buildPassages(db);
    await db.customStatement(
      'INSERT INTO passages_fts (rowid, search_text) '
      'SELECT id, search_text FROM poem_passages',
    );
    repository = PoetryRepository(db);
  });

  group('findCandidatePassages', () {
    test('finds the passage containing the recited words', () async {
      final candidates = await repository.findCandidatePassages(
        const ['once', 'upon', 'midnight'],
      );

      expect(candidates, isNotEmpty);
      final raven = candidates.first;
      expect(raven.poemId, 1);
      expect(raven.startToken, 0);
      expect(raven.poemBody, contains('midnight'));
    });

    test('returns no candidates for empty input without querying', () async {
      expect(await repository.findCandidatePassages(const []), isEmpty);
      expect(
        await repository.findCandidatePassages(const ['', '  ']),
        isEmpty,
      );
    });

    test('treats hostile input as literal text, never FTS syntax', () async {
      final injected = await repository.findCandidatePassages(
        const ['" OR "1"="1', 'midnight) OR (1=1'],
      );

      // Quoted literals match no passage; the query must not throw and must
      // not degenerate into returning the whole table.
      expect(injected, isEmpty);
    });

    test('respects the candidate limit', () async {
      final candidates = await repository.findCandidatePassages(
        const ['the'],
        limit: 1,
      );

      expect(candidates.length, lessThanOrEqualTo(1));
    });

    test('queries the tail of long transcripts', () async {
      final filler = List.filled(12, 'xyzzy');
      final candidates = await repository.findCandidatePassages(
        [...filler, 'midnight', 'dreary'],
      );

      expect(
        candidates.map((candidate) => candidate.poemId),
        contains(1),
      );
    });
  });
}
