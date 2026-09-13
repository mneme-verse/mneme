import 'package:drift/drift.dart';
import 'package:mneme/db/study_tables.dart';

part 'study_database.g.dart';

/// Private study database: FSRS cards and review logs.
///
/// Separate file from any downloadable corpus pack; keyed by stable poem
/// keys so history survives corpus replacement.
@DriftDatabase(tables: [StudyCards, StudyReviewLogs])
class StudyDatabase extends _$StudyDatabase {
  StudyDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
