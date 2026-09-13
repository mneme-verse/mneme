// coverage:ignore-file
import 'package:drift/drift.dart';

/// Review state, keyed by stable corpus identity.
///
/// Lives in the study database, never in a downloadable corpus pack, so
/// review history survives corpus replacement.
class StudyCards extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Stable poem identity from the corpus builder, not a local row id.
  TextColumn get poemKey => text().withLength(min: 1, max: 256).unique()();

  /// FSRS `State` value.
  IntColumn get state => integer()();
  IntColumn get step => integer().nullable()();
  RealColumn get stability => real().nullable()();
  RealColumn get difficulty => real().nullable()();

  /// UTC epoch milliseconds. Integers keep due-ordering exact.
  IntColumn get dueMillis => integer()();
  IntColumn get lastReviewMillis => integer().nullable()();
}

class StudyReviewLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get cardId => integer().references(StudyCards, #id)();

  /// FSRS `Rating` value.
  IntColumn get rating => integer()();

  /// UTC epoch milliseconds.
  IntColumn get reviewMillis => integer()();
  IntColumn get reviewDurationMillis => integer().nullable()();

  /// One review slot per card and instant: retries of the same submission
  /// collide instead of scheduling twice. First submission wins.
  @override
  List<String> get customConstraints => [
    'UNIQUE (card_id, review_millis)',
  ];
}
