import 'dart:io';
import 'dart:isolate';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:es_compression/zstd.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Opens the corpus database for [name] (`ru`, `en`, ...).
///
/// An installed corpus pack at `<supportDir>/corpora/<name>.db.zst` (placed
/// there by `ResourceRepository` after SHA-256 verification) takes
/// precedence: it is decompressed over the previous `<name>.db`. Without a
/// pack the bundled asset `assets/database/<name>.db` is copied once.
/// The prepared `<name>.db` file itself is opened; drift never substitutes
/// its default `<name>.sqlite` path.
QueryExecutor openCorpusConnection({
  required String name,
  required Directory supportDir,
  // Overridable for tests; production uses the application documents dir.
  Directory? documentsDir,
}) {
  return LazyDatabase(() async {
    final dbFolder = documentsDir ?? await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, '$name.db'));
    final pack = File(p.join(supportDir.path, 'corpora', '$name.db.zst'));

    if (pack.existsSync()) {
      final compressed = await Isolate.run(() {
        return ZstdDecoder().convert(File(pack.path).readAsBytesSync());
      });
      await file.writeAsBytes(compressed, flush: true);
      debugPrint('Decompressed installed corpus pack for "$name".');
    } else if (!file.existsSync()) {
      try {
        // We expect the asset to be at 'assets/database/$name.db'
        final blob = await rootBundle.load('assets/database/$name.db');
        await file.writeAsBytes(blob.buffer.asUint8List(), flush: true);
        debugPrint('Successfully copied pre-populated database from assets.');
      } on Object catch (e) {
        debugPrint('Error copying database asset: $e');
      }
    }

    return driftDatabase(
      name: name,
      native: DriftNativeOptions(
        databasePath: () async => file.path,
        // Explicit so opening never touches path_provider method channels
        // (and avoids /tmp on sandboxed platforms).
        tempDirectoryPath: () async => supportDir.path,
        shareAcrossIsolates: true,
      ),
    );
  });
}
