import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:mneme/db/connection/study_connection.dart';
import 'package:mneme/db/study_database.dart';
import 'package:mneme/repository/study_repository.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StudyDatabase db;
  late StudyRepository repository;

  setUp(() {
    db = StudyDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    repository = StudyRepository(
      db,
      scheduler: fsrs.Scheduler(enableFuzzing: false),
    );
  });

  group('StudyRepository', () {
    test('creates one stable learning card per poem', () async {
      final first = await repository.getOrCreateCard('eugene-onegin-1-1');
      final second = await repository.getOrCreateCard('eugene-onegin-1-1');
      final other = await repository.getOrCreateCard('raven');

      expect(first.state, fsrs.State.learning);
      expect(second.cardId, first.cardId);
      expect(other.cardId, isNot(first.cardId));
    });

    test('good review schedules forward and records history', () async {
      final at = DateTime.utc(2026, 9, 13, 12);

      final result = await repository.submitReview(
        poemKey: 'raven',
        rating: fsrs.Rating.good,
        reviewDateTime: at,
        reviewDuration: 45000,
      );

      expect(result.card.due.isAfter(at), isTrue);
      expect(result.log.rating, fsrs.Rating.good);
      expect(result.log.reviewDateTime, at);

      final history = await repository.reviewHistory('raven');
      expect(history, hasLength(1));
      expect(history.single, result.log);
      expect(await repository.reviewHistory('unseen'), isEmpty);
    });

    test('identical resubmission schedules once', () async {
      final at = DateTime.utc(2026, 9, 13, 12);

      final first = await repository.submitReview(
        poemKey: 'raven',
        rating: fsrs.Rating.good,
        reviewDateTime: at,
      );
      final retry = await repository.submitReview(
        poemKey: 'raven',
        rating: fsrs.Rating.good,
        reviewDateTime: at,
      );

      expect(retry.log, first.log);
      expect(retry.card.due, first.card.due);
      expect(await repository.reviewHistory('raven'), hasLength(1));
    });

    test('same-instant conflicting rating keeps the first review', () async {
      final at = DateTime.utc(2026, 9, 13, 12);

      await repository.submitReview(
        poemKey: 'raven',
        rating: fsrs.Rating.good,
        reviewDateTime: at,
      );
      final conflict = await repository.submitReview(
        poemKey: 'raven',
        rating: fsrs.Rating.again,
        reviewDateTime: at,
      );

      expect(conflict.log.rating, fsrs.Rating.good);
      expect(await repository.reviewHistory('raven'), hasLength(1));
    });

    test('normalizes non-UTC review times instead of throwing', () async {
      final local = DateTime(2026, 9, 13, 12);

      final result = await repository.submitReview(
        poemKey: 'raven',
        rating: fsrs.Rating.good,
        reviewDateTime: local,
      );

      expect(result.log.reviewDateTime.isUtc, isTrue);
      expect(
        result.log.reviewDateTime.millisecondsSinceEpoch,
        local.millisecondsSinceEpoch,
      );
    });

    test('dueCards returns only due cards, earliest first', () async {
      await repository.submitReview(
        poemKey: 'early',
        rating: fsrs.Rating.good,
        // ignore: avoid_redundant_argument_values -- explicit Y/M/D dates
        reviewDateTime: DateTime.utc(2020, 1, 1),
      );
      await repository.submitReview(
        poemKey: 'later',
        rating: fsrs.Rating.good,
        // ignore: avoid_redundant_argument_values -- explicit Y/M/D dates
        reviewDateTime: DateTime.utc(2021, 6, 1),
      );
      await repository.submitReview(
        poemKey: 'future',
        rating: fsrs.Rating.good,
        reviewDateTime: DateTime.utc(2026, 9, 13, 12),
      );

      final asOf = DateTime.utc(2026, 9, 13, 12);
      final due = await repository.dueCards(asOf: asOf);

      expect(due, hasLength(2));
      expect(due.first.due.isBefore(due.last.due), isTrue);
      expect(
        due.every((card) => !card.due.isAfter(asOf)),
        isTrue,
      );
    });

    test('reviewHistory lists newest first', () async {
      await repository.submitReview(
        poemKey: 'raven',
        rating: fsrs.Rating.again,
        reviewDateTime: DateTime.utc(2026, 9, 13, 12),
      );
      await repository.submitReview(
        poemKey: 'raven',
        rating: fsrs.Rating.good,
        reviewDateTime: DateTime.utc(2026, 9, 13, 13),
      );

      final history = await repository.reviewHistory('raven');

      expect(history, hasLength(2));
      expect(history.first.rating, fsrs.Rating.good);
      expect(history.last.rating, fsrs.Rating.again);
    });
  });

  test('repository works with the default scheduler', () async {
    final card = await StudyRepository(db).getOrCreateCard('raven');
    expect(card.state, fsrs.State.learning);
  });

  test('study connection falls back to the documents directory', () async {
    final docs = Directory.systemTemp.createTempSync('mneme-study-docs');
    addTearDown(() => docs.deleteSync(recursive: true));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => docs.path,
        );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            null,
          ),
    );

    final opened = StudyDatabase(openStudyConnection());
    addTearDown(opened.close);
    await opened.customSelect('SELECT 1').get();

    expect(File(p.join(docs.path, 'study.db')).existsSync(), isTrue);
  });

  test('study connection opens the explicit study file', () async {
    final docs = Directory.systemTemp.createTempSync('mneme-study-docs');
    addTearDown(() => docs.deleteSync(recursive: true));

    final opened = StudyDatabase(openStudyConnection(documentsDir: docs));
    final card = await StudyRepository(
      opened,
      scheduler: fsrs.Scheduler(enableFuzzing: false),
    ).getOrCreateCard('raven');
    await opened.close();

    final reread = StudyDatabase(
      NativeDatabase(File(p.join(docs.path, 'study.db'))),
    );
    addTearDown(reread.close);
    final cards = await StudyRepository(
      reread,
      scheduler: fsrs.Scheduler(enableFuzzing: false),
    ).dueCards(asOf: DateTime.now().toUtc().add(const Duration(minutes: 1)));

    expect(cards.map((entry) => entry.cardId), contains(card.cardId));
  });
  test('concurrent identical submissions keep a single outcome', () async {
    final docs = Directory.systemTemp.createTempSync('mneme-study-race');
    addTearDown(() => docs.deleteSync(recursive: true));
    final at = DateTime.utc(2026, 9, 13, 12);
    Future<({fsrs.Card card, fsrs.ReviewLog log})> submit() {
      final connection = StudyDatabase(openStudyConnection(documentsDir: docs));
      final repository = StudyRepository(
        connection,
        scheduler: fsrs.Scheduler(enableFuzzing: false),
      );
      return repository
          .submitReview(
            poemKey: 'raven',
            rating: fsrs.Rating.good,
            reviewDateTime: at,
          )
          .whenComplete(connection.close);
    }

    final outcomes = await Future.wait(List.generate(64, (_) => submit()));

    final first = outcomes.first;
    for (final outcome in outcomes.skip(1)) {
      expect(outcome.card.cardId, first.card.cardId);
      expect(
        outcome.log.reviewDateTime,
        first.log.reviewDateTime,
      );
    }
    final check = StudyDatabase(openStudyConnection(documentsDir: docs));
    addTearDown(check.close);
    final history = await StudyRepository(
      check,
      scheduler: fsrs.Scheduler(enableFuzzing: false),
    ).reviewHistory('raven');
    expect(history, hasLength(1));
  });

  test('busy snapshot backs off and retries once', () async {
    final docs = Directory.systemTemp.createTempSync('mneme-study-busy');
    addTearDown(() => docs.deleteSync(recursive: true));
    final db = StudyDatabase(openStudyConnection(documentsDir: docs));
    addTearDown(db.close);
    await db.customSelect('SELECT 1').get();
    final repository = StudyRepository(
      db,
      scheduler: fsrs.Scheduler(enableFuzzing: false),
    );

    final locker = sqlite3.open(p.join(docs.path, 'study.db'));
    addTearDown(locker.dispose);
    locker.execute('BEGIN IMMEDIATE');
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 20)).then((_) {
        locker.execute('ROLLBACK');
      }),
    );

    final at = DateTime.utc(2026, 9, 13, 12);
    final result = await repository.submitReview(
      poemKey: 'raven',
      rating: fsrs.Rating.good,
      reviewDateTime: at,
    );
    expect(result.log.rating, fsrs.Rating.good);
    expect(result.log.reviewDateTime, at);
  });

  group('conflict recovery', () {
    late Directory docs;
    late StudyDatabase seedDb;

    setUp(() async {
      docs = Directory.systemTemp.createTempSync('mneme-study-conflict');
      seedDb = StudyDatabase(openStudyConnection(documentsDir: docs));
      addTearDown(seedDb.close);
      addTearDown(() => docs.deleteSync(recursive: true));
    });

    Future<StudyDatabase> lyingDb({required String table}) async {
      final state = _RaceState()..table = table;
      final executor = _RaceExecutor(
        NativeDatabase(File(p.join(docs.path, 'study.db'))),
        state,
      );
      final database = StudyDatabase(executor);
      addTearDown(database.close);
      return database;
    }

    test('lost log race returns the stored outcome', () async {
      final at = DateTime.utc(2026, 9, 13, 12);
      final seeder = StudyRepository(
        seedDb,
        scheduler: fsrs.Scheduler(enableFuzzing: false),
      );
      final stored = await seeder.submitReview(
        poemKey: 'raven',
        rating: fsrs.Rating.hard,
        reviewDateTime: at,
      );

      final repository = StudyRepository(
        await lyingDb(table: 'study_review_logs'),
        scheduler: fsrs.Scheduler(enableFuzzing: false),
      );
      final retry = await repository.submitReview(
        poemKey: 'raven',
        rating: fsrs.Rating.good,
        reviewDateTime: at,
      );

      expect(retry.card.cardId, stored.card.cardId);
      expect(retry.log.rating, fsrs.Rating.hard);
      expect(retry.log.reviewDateTime, at);
    });

    test('lost card race reuses the stored card', () async {
      final seeder = StudyRepository(
        seedDb,
        scheduler: fsrs.Scheduler(enableFuzzing: false),
      );
      final stored = await seeder.getOrCreateCard('raven');

      final repository = StudyRepository(
        await lyingDb(table: 'study_cards'),
        scheduler: fsrs.Scheduler(enableFuzzing: false),
      );
      final card = await repository.getOrCreateCard('raven');

      expect(card.cardId, stored.cardId);
    });
  });
}

/// Simulates a lost race deterministically: the next `runSelect` — even
/// inside a transaction — returns no rows, so a pre-check misses a row
/// that a concurrent writer committed. The following insert then hits its
/// UNIQUE constraint and the repository must recover the stored outcome.
class _RaceState {
  bool lieArmed = true;

  /// Only lie for statements touching [table]; other selects pass through
  /// so each test arms exactly the pre-check it wants to lose.
  String? table;
}

class _RaceExecutor implements QueryExecutor {
  _RaceExecutor(this._inner, this._state);

  final QueryExecutor _inner;
  final _RaceState _state;

  List<Map<String, Object?>>? _lie(String statement) {
    if (!_state.lieArmed) return null;
    if (_state.table != null && !statement.contains(_state.table!)) {
      return null;
    }
    _state.lieArmed = false;
    return const [];
  }

  @override
  SqlDialect get dialect => _inner.dialect;

  @override
  Future<bool> ensureOpen(QueryExecutorUser user) => _inner.ensureOpen(user);

  @override
  Future<List<Map<String, Object?>>> runSelect(
    String statement,
    List<Object?> args,
  ) async => _lie(statement) ?? _inner.runSelect(statement, args);

  @override
  Future<int> runInsert(String statement, List<Object?> args) =>
      _inner.runInsert(statement, args);

  @override
  Future<int> runUpdate(String statement, List<Object?> args) =>
      _inner.runUpdate(statement, args);

  @override
  Future<int> runDelete(String statement, List<Object?> args) =>
      _inner.runDelete(statement, args);

  @override
  Future<void> runCustom(String statement, [List<Object?>? args]) =>
      _inner.runCustom(statement, args);

  @override
  Future<void> runBatched(BatchedStatements statements) =>
      _inner.runBatched(statements);

  @override
  TransactionExecutor beginTransaction() =>
      _RaceTransaction(_inner.beginTransaction(), _state);

  @override
  QueryExecutor beginExclusive() => _inner.beginExclusive();

  @override
  Future<void> close() => _inner.close();
}

class _RaceTransaction implements TransactionExecutor {
  _RaceTransaction(this._inner, this._state);

  final TransactionExecutor _inner;
  final _RaceState _state;

  List<Map<String, Object?>>? _lie(String statement) {
    if (!_state.lieArmed) return null;
    if (_state.table != null && !statement.contains(_state.table!)) {
      return null;
    }
    _state.lieArmed = false;
    return const [];
  }

  @override
  SqlDialect get dialect => _inner.dialect;

  @override
  bool get supportsNestedTransactions => _inner.supportsNestedTransactions;

  @override
  Future<bool> ensureOpen(QueryExecutorUser user) => _inner.ensureOpen(user);

  @override
  Future<List<Map<String, Object?>>> runSelect(
    String statement,
    List<Object?> args,
  ) async => _lie(statement) ?? _inner.runSelect(statement, args);

  @override
  Future<int> runInsert(String statement, List<Object?> args) =>
      _inner.runInsert(statement, args);

  @override
  Future<int> runUpdate(String statement, List<Object?> args) =>
      _inner.runUpdate(statement, args);

  @override
  Future<int> runDelete(String statement, List<Object?> args) =>
      _inner.runDelete(statement, args);

  @override
  Future<void> runCustom(String statement, [List<Object?>? args]) =>
      _inner.runCustom(statement, args);

  @override
  Future<void> runBatched(BatchedStatements statements) =>
      _inner.runBatched(statements);

  @override
  TransactionExecutor beginTransaction() => this;

  @override
  QueryExecutor beginExclusive() => this;

  @override
  Future<void> send() => _inner.send();

  @override
  Future<void> rollback() => _inner.rollback();

  @override
  Future<void> close() => _inner.close();
}
