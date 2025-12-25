import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app.db'));

    if (!file.existsSync()) {
      try {
        // We expect the asset to be at 'assets/database/app.db'
        final blob = await rootBundle.load('assets/database/app.db');
        await file.writeAsBytes(blob.buffer.asUint8List());
        debugPrint('Successfully copied pre-populated database from assets.');
      } on Object catch (e) {
        debugPrint('Error copying database asset: $e');
      }
    }

    return driftDatabase(
      name: 'app',
      native: const DriftNativeOptions(
        shareAcrossIsolates: true,
      ),
    );
  });
}
