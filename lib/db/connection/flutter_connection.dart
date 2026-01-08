import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

QueryExecutor openConnection({
  required String name,
  AssetBundle? bundle,
  DriftNativeOptions? options,
}) {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, '$name.db'));

    if (!file.existsSync()) {
      try {
        final assets = bundle ?? rootBundle;
        // We expect the asset to be at 'assets/database/$name.db'
        final blob = await assets.load('assets/database/$name.db');
        await file.writeAsBytes(blob.buffer.asUint8List());
        debugPrint('Successfully copied pre-populated database from assets.');
      } on Object catch (e) {
        debugPrint('Error copying database asset: $e');
      }
    }

    return driftDatabase(
      name: name,
      // Cannot be const because of the closure capturing local variable 'file'
      native:
          options ??
          DriftNativeOptions(
            databasePath: () async => file.path,
            shareAcrossIsolates: true,
          ),
    );
  });
}
