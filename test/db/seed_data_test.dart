import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mneme/db/database.dart';
import 'package:mneme/db/seed_data.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'seedDatabase seeds all languages when no language is specified',
    () async {
      await seedDatabase(db);

      final count = await db.poems.count().getSingle();
      // 3 English + 2 Russian
      expect(count, 5);
    },
  );
}
