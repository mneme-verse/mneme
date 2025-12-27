import 'dart:io';

import 'package:drift/native.dart';
import 'package:mneme/db/database.dart';
import 'package:mneme/db/seed_data.dart';

void main() async {
  // ignore_for_file: avoid_print // CLI tool uses print for progress updates
  const dbPath = 'assets/database/en.db';
  final file = File(dbPath);

  if (file.existsSync()) {
    file.deleteSync();
  }

  print('Opening $dbPath via AppDatabase...');

  // Use NativeDatabase for pure Dart execution
  final db = AppDatabase(NativeDatabase(file));

  print('Inserting mock data...');
  await seedDatabase(db);

  await db.close();

  print('Mock database generated at $dbPath');
}
