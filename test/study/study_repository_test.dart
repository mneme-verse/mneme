import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:mneme/db/connection/study_connection.dart';
import 'package:mneme/db/study_database.dart';
import 'package:mneme/repository/study_repository.dart';
import 'package:path/path.dart' as p;

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
}
