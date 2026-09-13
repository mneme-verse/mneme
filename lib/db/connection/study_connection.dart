import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Opens the private study database (`study.db`).
///
/// The study database is never downloaded or replaced; review history is
/// keyed by stable poem keys and survives corpus replacement. The explicit
/// file is opened directly, never drift's default `<name>.sqlite` path.
QueryExecutor openStudyConnection({
  // Overridable for tests; production uses the application documents dir.
  Directory? documentsDir,
}) {
  return LazyDatabase(() async {
    final dbFolder = documentsDir ?? await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'study.db'));

    return driftDatabase(
      name: 'study',
      native: DriftNativeOptions(
        databasePath: () async => file.path,
        // Explicit so opening never touches path_provider method channels
        // (and avoids /tmp on sandboxed platforms).
        tempDirectoryPath: () async => dbFolder.path,
        shareAcrossIsolates: true,
      ),
    );
  });
}
