// coverage:ignore-file
import 'package:drift/drift.dart';

class Poems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  // Stores JSON array of author names, e.g., ["Author 1", "Author 2"]
  TextColumn get author => text()();
  TextColumn get body => text()();
  // Stores single year as string (e.g., "1845") or range as JSON
  // array (e.g., "[1800, 1802]")
  TextColumn get year => text().nullable()();
  // Stores alternative titles from duplicate poems as JSON array
  TextColumn get altTitles => text().nullable()();
}

class Metadata extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
