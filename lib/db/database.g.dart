// GENERATED CODE - DO NOT MODIFY BY HAND

// coverage:ignore-file
// ignore_for_file: type=lint

part of 'database.dart';

// ignore_for_file: type=lint
class $PoemsTable extends Poems with TableInfo<$PoemsTable, Poem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PoemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<String> year = GeneratedColumn<String>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    author,
    body,
    year,
    language,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'poems';
  @override
  VerificationContext validateIntegrity(
    Insertable<Poem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    } else if (isInserting) {
      context.missing(_authorMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    } else if (isInserting) {
      context.missing(_languageMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Poem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Poem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}year'],
      ),
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
    );
  }

  @override
  $PoemsTable createAlias(String alias) {
    return $PoemsTable(attachedDatabase, alias);
  }
}

class Poem extends DataClass implements Insertable<Poem> {
  final int id;
  final String title;
  final String author;
  final String body;
  final String? year;
  final String language;
  const Poem({
    required this.id,
    required this.title,
    required this.author,
    required this.body,
    this.year,
    required this.language,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['author'] = Variable<String>(author);
    map['body'] = Variable<String>(body);
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<String>(year);
    }
    map['language'] = Variable<String>(language);
    return map;
  }

  PoemsCompanion toCompanion(bool nullToAbsent) {
    return PoemsCompanion(
      id: Value(id),
      title: Value(title),
      author: Value(author),
      body: Value(body),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      language: Value(language),
    );
  }

  factory Poem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Poem(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      author: serializer.fromJson<String>(json['author']),
      body: serializer.fromJson<String>(json['body']),
      year: serializer.fromJson<String?>(json['year']),
      language: serializer.fromJson<String>(json['language']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'author': serializer.toJson<String>(author),
      'body': serializer.toJson<String>(body),
      'year': serializer.toJson<String?>(year),
      'language': serializer.toJson<String>(language),
    };
  }

  Poem copyWith({
    int? id,
    String? title,
    String? author,
    String? body,
    Value<String?> year = const Value.absent(),
    String? language,
  }) => Poem(
    id: id ?? this.id,
    title: title ?? this.title,
    author: author ?? this.author,
    body: body ?? this.body,
    year: year.present ? year.value : this.year,
    language: language ?? this.language,
  );
  Poem copyWithCompanion(PoemsCompanion data) {
    return Poem(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      author: data.author.present ? data.author.value : this.author,
      body: data.body.present ? data.body.value : this.body,
      year: data.year.present ? data.year.value : this.year,
      language: data.language.present ? data.language.value : this.language,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Poem(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('body: $body, ')
          ..write('year: $year, ')
          ..write('language: $language')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, author, body, year, language);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Poem &&
          other.id == this.id &&
          other.title == this.title &&
          other.author == this.author &&
          other.body == this.body &&
          other.year == this.year &&
          other.language == this.language);
}

class PoemsCompanion extends UpdateCompanion<Poem> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> author;
  final Value<String> body;
  final Value<String?> year;
  final Value<String> language;
  const PoemsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.body = const Value.absent(),
    this.year = const Value.absent(),
    this.language = const Value.absent(),
  });
  PoemsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String author,
    required String body,
    this.year = const Value.absent(),
    required String language,
  }) : title = Value(title),
       author = Value(author),
       body = Value(body),
       language = Value(language);
  static Insertable<Poem> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? author,
    Expression<String>? body,
    Expression<String>? year,
    Expression<String>? language,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (author != null) 'author': author,
      if (body != null) 'body': body,
      if (year != null) 'year': year,
      if (language != null) 'language': language,
    });
  }

  PoemsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? author,
    Value<String>? body,
    Value<String?>? year,
    Value<String>? language,
  }) {
    return PoemsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      body: body ?? this.body,
      year: year ?? this.year,
      language: language ?? this.language,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (year.present) {
      map['year'] = Variable<String>(year.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PoemsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('body: $body, ')
          ..write('year: $year, ')
          ..write('language: $language')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PoemsTable poems = $PoemsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [poems];
}

typedef $$PoemsTableCreateCompanionBuilder =
    PoemsCompanion Function({
      Value<int> id,
      required String title,
      required String author,
      required String body,
      Value<String?> year,
      required String language,
    });
typedef $$PoemsTableUpdateCompanionBuilder =
    PoemsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> author,
      Value<String> body,
      Value<String?> year,
      Value<String> language,
    });

class $$PoemsTableFilterComposer extends Composer<_$AppDatabase, $PoemsTable> {
  $$PoemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PoemsTableOrderingComposer
    extends Composer<_$AppDatabase, $PoemsTable> {
  $$PoemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PoemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PoemsTable> {
  $$PoemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);
}

class $$PoemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PoemsTable,
          Poem,
          $$PoemsTableFilterComposer,
          $$PoemsTableOrderingComposer,
          $$PoemsTableAnnotationComposer,
          $$PoemsTableCreateCompanionBuilder,
          $$PoemsTableUpdateCompanionBuilder,
          (Poem, BaseReferences<_$AppDatabase, $PoemsTable, Poem>),
          Poem,
          PrefetchHooks Function()
        > {
  $$PoemsTableTableManager(_$AppDatabase db, $PoemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PoemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PoemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PoemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> author = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String?> year = const Value.absent(),
                Value<String> language = const Value.absent(),
              }) => PoemsCompanion(
                id: id,
                title: title,
                author: author,
                body: body,
                year: year,
                language: language,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required String author,
                required String body,
                Value<String?> year = const Value.absent(),
                required String language,
              }) => PoemsCompanion.insert(
                id: id,
                title: title,
                author: author,
                body: body,
                year: year,
                language: language,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PoemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PoemsTable,
      Poem,
      $$PoemsTableFilterComposer,
      $$PoemsTableOrderingComposer,
      $$PoemsTableAnnotationComposer,
      $$PoemsTableCreateCompanionBuilder,
      $$PoemsTableUpdateCompanionBuilder,
      (Poem, BaseReferences<_$AppDatabase, $PoemsTable, Poem>),
      Poem,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PoemsTableTableManager get poems =>
      $$PoemsTableTableManager(_db, _db.poems);
}
