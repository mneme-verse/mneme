// coverage:ignore-file
import 'package:drift/drift.dart';

class Poems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get author => text()();
  TextColumn get body => text()();
  TextColumn get year => text().nullable()();
  TextColumn get language => text()();
}
