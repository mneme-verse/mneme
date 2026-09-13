import 'package:drift/drift.dart';
// DriftRemoteException is only exported through the experimental remote
// API, and this use only reads its failure cause.
// ignore: implementation_imports
import 'package:drift/src/remote/communication.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:mneme/db/study_database.dart';
import 'package:sqlite3/sqlite3.dart';

/// SQLITE_BUSY: a concurrent transaction holds the write lock.
const _sqliteBusy = 5;

/// SQLITE_CONSTRAINT_UNIQUE: a concurrent insert won the unique slot.
const _sqliteConstraintUnique = 2067;

/// SQLite primary result code for [error], unwrapping the isolate
/// boundary: drift serves databases from a background isolate and
/// surfaces failures as [DriftRemoteException]. Null when the error is
/// not a SQLite failure.
int? _sqliteResultCode(Object error) {
  final cause = error is DriftRemoteException ? error.remoteCause : error;
  return cause is SqliteException ? cause.resultCode : null;
}

/// SQLite extended result code for [error]. See [_sqliteResultCode].
int? _sqliteExtendedCode(Object error) {
  final cause = error is DriftRemoteException ? error.remoteCause : error;
  return cause is SqliteException ? cause.extendedResultCode : null;
}

/// Persists FSRS scheduling state, keyed by stable poem keys.
/// Cards are database-allocated (never time-based ids) and all datetimes
/// are stored as UTC epoch milliseconds. Review submission recomputes from
/// the stored card inside one transaction, and one (card, instant) slot
/// accepts a single review, so retried submissions cannot schedule twice.
/// The repository never grades recitation itself: callers pass an explicit
/// [fsrs.Rating].
class StudyRepository {
  StudyRepository(this._db, {fsrs.Scheduler? scheduler})
    : _scheduler = scheduler ?? fsrs.Scheduler();

  final StudyDatabase _db;
  final fsrs.Scheduler _scheduler;

  /// Returns the card for [poemKey], creating a new learning card when the
  /// poem has never been reviewed.
  Future<fsrs.Card> getOrCreateCard(String poemKey) {
    return _db.transaction(() => _getOrCreateCard(poemKey));
  }

  /// Cards due at [asOf] (default now), earliest first, at most [limit].
  Future<List<fsrs.Card>> dueCards({DateTime? asOf, int limit = 20}) async {
    final at = (asOf ?? DateTime.now().toUtc()).toUtc();
    final rows =
        await (_db.select(_db.studyCards)
              ..where(
                (card) => card.dueMillis.isSmallerOrEqualValue(
                  at.millisecondsSinceEpoch,
                ),
              )
              ..orderBy([(card) => OrderingTerm.asc(card.dueMillis)])
              ..limit(limit))
            .get();
    return [for (final row in rows) _toCard(row)];
  }

  /// Review logs for [poemKey], newest first. Empty for unseen poems.
  Future<List<fsrs.ReviewLog>> reviewHistory(String poemKey) async {
    final card = await (_db.select(
      _db.studyCards,
    )..where((row) => row.poemKey.equals(poemKey))).getSingleOrNull();
    if (card == null) return [];
    final rows =
        await (_db.select(_db.studyReviewLogs)
              ..where((log) => log.cardId.equals(card.id))
              ..orderBy([(log) => OrderingTerm.desc(log.reviewMillis)]))
            .get();
    return [for (final row in rows) _toLog(row)];
  }

  /// Applies [rating] to the card for [poemKey] and records the review.
  ///
  /// [reviewDateTime] defaults to now and is normalized to UTC, as FSRS
  /// requires. A repeated submission for the same card and instant returns
  /// the stored outcome without rescheduling; the first submission wins.
  Future<({fsrs.Card card, fsrs.ReviewLog log})> submitReview({
    required String poemKey,
    required fsrs.Rating rating,
    DateTime? reviewDateTime,
    int? reviewDuration,
  }) async {
    final at = (reviewDateTime ?? DateTime.now().toUtc()).toUtc();
    // A busy snapshot (concurrent writer) backs off and retries; anything
    // else propagates. Five attempts ride out submission bursts without
    // spinning forever on a wedged lock.
    for (var attempt = 0; ; attempt++) {
      try {
        return await _db.transaction(
          () => _submitOnce(
            poemKey: poemKey,
            rating: rating,
            at: at,
            reviewDuration: reviewDuration,
          ),
        );
      } on Exception catch (error) {
        if (_sqliteResultCode(error) != _sqliteBusy || attempt >= 4) {
          rethrow;
        }
        await Future<void>.delayed(Duration(milliseconds: 50 * (attempt + 1)));
      }
    }
  }

  Future<({fsrs.Card card, fsrs.ReviewLog log})> _submitOnce({
    required String poemKey,
    required fsrs.Rating rating,
    required DateTime at,
    required int? reviewDuration,
  }) async {
    final card = await _getOrCreateCard(poemKey);
    final existing =
        await (_db.select(_db.studyReviewLogs)..where(
              (log) =>
                  log.cardId.equals(card.cardId) &
                  log.reviewMillis.equals(at.millisecondsSinceEpoch),
            ))
            .getSingleOrNull();
    if (existing != null) return (card: card, log: _toLog(existing));

    final result = _scheduler.reviewCard(
      card,
      rating,
      reviewDateTime: at,
      reviewDuration: reviewDuration,
    );
    // The log insert claims the slot first: on a lost race nothing has
    // been rescheduled yet, so returning the winner leaves no stale
    // loser state behind.
    try {
      await _db
          .into(_db.studyReviewLogs)
          .insert(
            StudyReviewLogsCompanion.insert(
              cardId: card.cardId,
              rating: rating.value,
              reviewMillis: at.millisecondsSinceEpoch,
              reviewDurationMillis: Value(reviewDuration),
            ),
          );
    } on Exception catch (error) {
      // A concurrent submission won this slot: return its outcome
      // instead of scheduling twice.
      if (_sqliteExtendedCode(error) != _sqliteConstraintUnique) rethrow;
      final winner =
          await (_db.select(_db.studyReviewLogs)..where(
                (log) =>
                    log.cardId.equals(card.cardId) &
                    log.reviewMillis.equals(at.millisecondsSinceEpoch),
              ))
              .getSingleOrNull();
      if (winner == null) rethrow;
      final fresh =
          await (_db.select(_db.studyCards)..where(
                (row) => row.id.equals(card.cardId),
              ))
              .getSingle();
      return (card: _toCard(fresh), log: _toLog(winner));
    }
    await (_db.update(
      _db.studyCards,
    )..where((row) => row.id.equals(card.cardId))).write(
      StudyCardsCompanion(
        state: Value(result.card.state.value),
        step: Value(result.card.step),
        stability: Value(result.card.stability),
        difficulty: Value(result.card.difficulty),
        dueMillis: Value(result.card.due.millisecondsSinceEpoch),
        lastReviewMillis: Value(
          result.card.lastReview?.millisecondsSinceEpoch,
        ),
      ),
    );
    return (card: result.card, log: result.reviewLog);
  }

  Future<fsrs.Card> _getOrCreateCard(String poemKey) async {
    final existing =
        await (_db.select(_db.studyCards)..where(
              (row) => row.poemKey.equals(poemKey),
            ))
            .getSingleOrNull();
    if (existing != null) return _toCard(existing);

    final now = DateTime.now().toUtc();
    try {
      final id = await _db
          .into(_db.studyCards)
          .insert(
            StudyCardsCompanion.insert(
              poemKey: poemKey,
              state: fsrs.State.learning.value,
              dueMillis: now.millisecondsSinceEpoch,
            ),
          );
      return fsrs.Card(cardId: id, due: now);
    } on Exception catch (error) {
      // A concurrent creation won the poem key: use its card.
      if (_sqliteExtendedCode(error) != _sqliteConstraintUnique) rethrow;
      final winner =
          await (_db.select(_db.studyCards)..where(
                (row) => row.poemKey.equals(poemKey),
              ))
              .getSingleOrNull();
      if (winner != null) return _toCard(winner);
      rethrow;
    }
  }

  fsrs.Card _toCard(StudyCard row) => fsrs.Card(
    cardId: row.id,
    state: fsrs.State.fromValue(row.state),
    step: row.step,
    stability: row.stability,
    difficulty: row.difficulty,
    due: DateTime.fromMillisecondsSinceEpoch(row.dueMillis, isUtc: true),
    lastReview: row.lastReviewMillis == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(
            row.lastReviewMillis!,
            isUtc: true,
          ),
  );

  fsrs.ReviewLog _toLog(StudyReviewLog row) => fsrs.ReviewLog(
    cardId: row.cardId,
    rating: fsrs.Rating.fromValue(row.rating),
    reviewDateTime: DateTime.fromMillisecondsSinceEpoch(
      row.reviewMillis,
      isUtc: true,
    ),
    reviewDuration: row.reviewDurationMillis,
  );
}
