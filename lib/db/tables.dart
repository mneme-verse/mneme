// coverage:ignore-file
import 'package:drift/drift.dart';

class Poems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get authorNames => text()();
  TextColumn get body => text()();
  TextColumn get year => text().nullable()();
  TextColumn get altTitles => text().nullable()();
  TextColumn get poemKey => text().withLength(min: 1, max: 256)();
  TextColumn get language => text().withLength(min: 2, max: 5)();
  TextColumn get contentHash => text().withLength(min: 64, max: 64)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {poemKey},
  ];
}

class PoemPassages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get poemId => integer().references(Poems, #id)();
  IntColumn get startToken => integer()();
  IntColumn get endToken => integer()();
  TextColumn get searchText => text()();

  @override
  Set<Column> get primaryKey => {id};
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
