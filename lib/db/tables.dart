// coverage:ignore-file
import 'package:drift/drift.dart';

class Poems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  // Stores denormalized author string for FTS, e.g. "Author 1, Author 2"
  TextColumn get authorNames => text()();
  TextColumn get body => text()();
  // Stores single year as string (e.g., "1845") or range as JSON
  // array (e.g., "[1800, 1802]")
  TextColumn get year => text().nullable()();
  // Stores alternative titles from duplicate poems as JSON array
  TextColumn get altTitles => text().nullable()();
}

class Authors extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get poemCount => integer()();
}

class PoemAuthors extends Table {
  IntColumn get poemId => integer().references(Poems, #id)();
  IntColumn get authorId => integer().references(Authors, #id)();

  @override
  Set<Column> get primaryKey => {poemId, authorId};
}

class Metadata extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
