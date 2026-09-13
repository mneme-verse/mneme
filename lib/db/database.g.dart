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
  static const VerificationMeta _authorNamesMeta = const VerificationMeta(
    'authorNames',
  );
  @override
  late final GeneratedColumn<String> authorNames = GeneratedColumn<String>(
    'author_names',
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
  static const VerificationMeta _altTitlesMeta = const VerificationMeta(
    'altTitles',
  );
  @override
  late final GeneratedColumn<String> altTitles = GeneratedColumn<String>(
    'alt_titles',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _poemKeyMeta = const VerificationMeta(
    'poemKey',
  );
  @override
  late final GeneratedColumn<String> poemKey = GeneratedColumn<String>(
    'poem_key',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 256,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 2,
      maxTextLength: 5,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentHashMeta = const VerificationMeta(
    'contentHash',
  );
  @override
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
    'content_hash',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 64,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    authorNames,
    body,
    year,
    altTitles,
    poemKey,
    language,
    contentHash,
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
    if (data.containsKey('author_names')) {
      context.handle(
        _authorNamesMeta,
        authorNames.isAcceptableOrUnknown(
          data['author_names']!,
          _authorNamesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_authorNamesMeta);
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
    if (data.containsKey('alt_titles')) {
      context.handle(
        _altTitlesMeta,
        altTitles.isAcceptableOrUnknown(data['alt_titles']!, _altTitlesMeta),
      );
    }
    if (data.containsKey('poem_key')) {
      context.handle(
        _poemKeyMeta,
        poemKey.isAcceptableOrUnknown(data['poem_key']!, _poemKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_poemKeyMeta);
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    } else if (isInserting) {
      context.missing(_languageMeta);
    }
    if (data.containsKey('content_hash')) {
      context.handle(
        _contentHashMeta,
        contentHash.isAcceptableOrUnknown(
          data['content_hash']!,
          _contentHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentHashMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {poemKey},
  ];
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
      authorNames: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_names'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}year'],
      ),
      altTitles: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alt_titles'],
      ),
      poemKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}poem_key'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      contentHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_hash'],
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
  final String authorNames;
  final String body;
  final String? year;
  final String? altTitles;
  final String poemKey;
  final String language;
  final String contentHash;
  const Poem({
    required this.id,
    required this.title,
    required this.authorNames,
    required this.body,
    this.year,
    this.altTitles,
    required this.poemKey,
    required this.language,
    required this.contentHash,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['author_names'] = Variable<String>(authorNames);
    map['body'] = Variable<String>(body);
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<String>(year);
    }
    if (!nullToAbsent || altTitles != null) {
      map['alt_titles'] = Variable<String>(altTitles);
    }
    map['poem_key'] = Variable<String>(poemKey);
    map['language'] = Variable<String>(language);
    map['content_hash'] = Variable<String>(contentHash);
    return map;
  }

  PoemsCompanion toCompanion(bool nullToAbsent) {
    return PoemsCompanion(
      id: Value(id),
      title: Value(title),
      authorNames: Value(authorNames),
      body: Value(body),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      altTitles: altTitles == null && nullToAbsent
          ? const Value.absent()
          : Value(altTitles),
      poemKey: Value(poemKey),
      language: Value(language),
      contentHash: Value(contentHash),
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
      authorNames: serializer.fromJson<String>(json['authorNames']),
      body: serializer.fromJson<String>(json['body']),
      year: serializer.fromJson<String?>(json['year']),
      altTitles: serializer.fromJson<String?>(json['altTitles']),
      poemKey: serializer.fromJson<String>(json['poemKey']),
      language: serializer.fromJson<String>(json['language']),
      contentHash: serializer.fromJson<String>(json['contentHash']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'authorNames': serializer.toJson<String>(authorNames),
      'body': serializer.toJson<String>(body),
      'year': serializer.toJson<String?>(year),
      'altTitles': serializer.toJson<String?>(altTitles),
      'poemKey': serializer.toJson<String>(poemKey),
      'language': serializer.toJson<String>(language),
      'contentHash': serializer.toJson<String>(contentHash),
    };
  }

  Poem copyWith({
    int? id,
    String? title,
    String? authorNames,
    String? body,
    Value<String?> year = const Value.absent(),
    Value<String?> altTitles = const Value.absent(),
    String? poemKey,
    String? language,
    String? contentHash,
  }) => Poem(
    id: id ?? this.id,
    title: title ?? this.title,
    authorNames: authorNames ?? this.authorNames,
    body: body ?? this.body,
    year: year.present ? year.value : this.year,
    altTitles: altTitles.present ? altTitles.value : this.altTitles,
    poemKey: poemKey ?? this.poemKey,
    language: language ?? this.language,
    contentHash: contentHash ?? this.contentHash,
  );
  Poem copyWithCompanion(PoemsCompanion data) {
    return Poem(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      authorNames: data.authorNames.present
          ? data.authorNames.value
          : this.authorNames,
      body: data.body.present ? data.body.value : this.body,
      year: data.year.present ? data.year.value : this.year,
      altTitles: data.altTitles.present ? data.altTitles.value : this.altTitles,
      poemKey: data.poemKey.present ? data.poemKey.value : this.poemKey,
      language: data.language.present ? data.language.value : this.language,
      contentHash: data.contentHash.present
          ? data.contentHash.value
          : this.contentHash,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Poem(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('authorNames: $authorNames, ')
          ..write('body: $body, ')
          ..write('year: $year, ')
          ..write('altTitles: $altTitles, ')
          ..write('poemKey: $poemKey, ')
          ..write('language: $language, ')
          ..write('contentHash: $contentHash')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    authorNames,
    body,
    year,
    altTitles,
    poemKey,
    language,
    contentHash,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Poem &&
          other.id == this.id &&
          other.title == this.title &&
          other.authorNames == this.authorNames &&
          other.body == this.body &&
          other.year == this.year &&
          other.altTitles == this.altTitles &&
          other.poemKey == this.poemKey &&
          other.language == this.language &&
          other.contentHash == this.contentHash);
}

class PoemsCompanion extends UpdateCompanion<Poem> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> authorNames;
  final Value<String> body;
  final Value<String?> year;
  final Value<String?> altTitles;
  final Value<String> poemKey;
  final Value<String> language;
  final Value<String> contentHash;
  const PoemsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.authorNames = const Value.absent(),
    this.body = const Value.absent(),
    this.year = const Value.absent(),
    this.altTitles = const Value.absent(),
    this.poemKey = const Value.absent(),
    this.language = const Value.absent(),
    this.contentHash = const Value.absent(),
  });
  PoemsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String authorNames,
    required String body,
    this.year = const Value.absent(),
    this.altTitles = const Value.absent(),
    required String poemKey,
    required String language,
    required String contentHash,
  }) : title = Value(title),
       authorNames = Value(authorNames),
       body = Value(body),
       poemKey = Value(poemKey),
       language = Value(language),
       contentHash = Value(contentHash);
  static Insertable<Poem> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? authorNames,
    Expression<String>? body,
    Expression<String>? year,
    Expression<String>? altTitles,
    Expression<String>? poemKey,
    Expression<String>? language,
    Expression<String>? contentHash,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (authorNames != null) 'author_names': authorNames,
      if (body != null) 'body': body,
      if (year != null) 'year': year,
      if (altTitles != null) 'alt_titles': altTitles,
      if (poemKey != null) 'poem_key': poemKey,
      if (language != null) 'language': language,
      if (contentHash != null) 'content_hash': contentHash,
    });
  }

  PoemsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? authorNames,
    Value<String>? body,
    Value<String?>? year,
    Value<String?>? altTitles,
    Value<String>? poemKey,
    Value<String>? language,
    Value<String>? contentHash,
  }) {
    return PoemsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      authorNames: authorNames ?? this.authorNames,
      body: body ?? this.body,
      year: year ?? this.year,
      altTitles: altTitles ?? this.altTitles,
      poemKey: poemKey ?? this.poemKey,
      language: language ?? this.language,
      contentHash: contentHash ?? this.contentHash,
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
    if (authorNames.present) {
      map['author_names'] = Variable<String>(authorNames.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (year.present) {
      map['year'] = Variable<String>(year.value);
    }
    if (altTitles.present) {
      map['alt_titles'] = Variable<String>(altTitles.value);
    }
    if (poemKey.present) {
      map['poem_key'] = Variable<String>(poemKey.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PoemsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('authorNames: $authorNames, ')
          ..write('body: $body, ')
          ..write('year: $year, ')
          ..write('altTitles: $altTitles, ')
          ..write('poemKey: $poemKey, ')
          ..write('language: $language, ')
          ..write('contentHash: $contentHash')
          ..write(')'))
        .toString();
  }
}

class $AuthorsTable extends Authors with TableInfo<$AuthorsTable, Author> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuthorsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _poemCountMeta = const VerificationMeta(
    'poemCount',
  );
  @override
  late final GeneratedColumn<int> poemCount = GeneratedColumn<int>(
    'poem_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, poemCount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'authors';
  @override
  VerificationContext validateIntegrity(
    Insertable<Author> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('poem_count')) {
      context.handle(
        _poemCountMeta,
        poemCount.isAcceptableOrUnknown(data['poem_count']!, _poemCountMeta),
      );
    } else if (isInserting) {
      context.missing(_poemCountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Author map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Author(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      poemCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}poem_count'],
      )!,
    );
  }

  @override
  $AuthorsTable createAlias(String alias) {
    return $AuthorsTable(attachedDatabase, alias);
  }
}

class Author extends DataClass implements Insertable<Author> {
  final int id;
  final String name;
  final int poemCount;
  const Author({required this.id, required this.name, required this.poemCount});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['poem_count'] = Variable<int>(poemCount);
    return map;
  }

  AuthorsCompanion toCompanion(bool nullToAbsent) {
    return AuthorsCompanion(
      id: Value(id),
      name: Value(name),
      poemCount: Value(poemCount),
    );
  }

  factory Author.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Author(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      poemCount: serializer.fromJson<int>(json['poemCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'poemCount': serializer.toJson<int>(poemCount),
    };
  }

  Author copyWith({int? id, String? name, int? poemCount}) => Author(
    id: id ?? this.id,
    name: name ?? this.name,
    poemCount: poemCount ?? this.poemCount,
  );
  Author copyWithCompanion(AuthorsCompanion data) {
    return Author(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      poemCount: data.poemCount.present ? data.poemCount.value : this.poemCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Author(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('poemCount: $poemCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, poemCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Author &&
          other.id == this.id &&
          other.name == this.name &&
          other.poemCount == this.poemCount);
}

class AuthorsCompanion extends UpdateCompanion<Author> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> poemCount;
  const AuthorsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.poemCount = const Value.absent(),
  });
  AuthorsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int poemCount,
  }) : name = Value(name),
       poemCount = Value(poemCount);
  static Insertable<Author> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? poemCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (poemCount != null) 'poem_count': poemCount,
    });
  }

  AuthorsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? poemCount,
  }) {
    return AuthorsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      poemCount: poemCount ?? this.poemCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (poemCount.present) {
      map['poem_count'] = Variable<int>(poemCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuthorsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('poemCount: $poemCount')
          ..write(')'))
        .toString();
  }
}

class $PoemAuthorsTable extends PoemAuthors
    with TableInfo<$PoemAuthorsTable, PoemAuthor> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PoemAuthorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _poemIdMeta = const VerificationMeta('poemId');
  @override
  late final GeneratedColumn<int> poemId = GeneratedColumn<int>(
    'poem_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES poems (id)',
    ),
  );
  static const VerificationMeta _authorIdMeta = const VerificationMeta(
    'authorId',
  );
  @override
  late final GeneratedColumn<int> authorId = GeneratedColumn<int>(
    'author_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES authors (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [poemId, authorId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'poem_authors';
  @override
  VerificationContext validateIntegrity(
    Insertable<PoemAuthor> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('poem_id')) {
      context.handle(
        _poemIdMeta,
        poemId.isAcceptableOrUnknown(data['poem_id']!, _poemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_poemIdMeta);
    }
    if (data.containsKey('author_id')) {
      context.handle(
        _authorIdMeta,
        authorId.isAcceptableOrUnknown(data['author_id']!, _authorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_authorIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {poemId, authorId};
  @override
  PoemAuthor map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PoemAuthor(
      poemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}poem_id'],
      )!,
      authorId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}author_id'],
      )!,
    );
  }

  @override
  $PoemAuthorsTable createAlias(String alias) {
    return $PoemAuthorsTable(attachedDatabase, alias);
  }
}

class PoemAuthor extends DataClass implements Insertable<PoemAuthor> {
  final int poemId;
  final int authorId;
  const PoemAuthor({required this.poemId, required this.authorId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['poem_id'] = Variable<int>(poemId);
    map['author_id'] = Variable<int>(authorId);
    return map;
  }

  PoemAuthorsCompanion toCompanion(bool nullToAbsent) {
    return PoemAuthorsCompanion(
      poemId: Value(poemId),
      authorId: Value(authorId),
    );
  }

  factory PoemAuthor.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PoemAuthor(
      poemId: serializer.fromJson<int>(json['poemId']),
      authorId: serializer.fromJson<int>(json['authorId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'poemId': serializer.toJson<int>(poemId),
      'authorId': serializer.toJson<int>(authorId),
    };
  }

  PoemAuthor copyWith({int? poemId, int? authorId}) => PoemAuthor(
    poemId: poemId ?? this.poemId,
    authorId: authorId ?? this.authorId,
  );
  PoemAuthor copyWithCompanion(PoemAuthorsCompanion data) {
    return PoemAuthor(
      poemId: data.poemId.present ? data.poemId.value : this.poemId,
      authorId: data.authorId.present ? data.authorId.value : this.authorId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PoemAuthor(')
          ..write('poemId: $poemId, ')
          ..write('authorId: $authorId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(poemId, authorId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PoemAuthor &&
          other.poemId == this.poemId &&
          other.authorId == this.authorId);
}

class PoemAuthorsCompanion extends UpdateCompanion<PoemAuthor> {
  final Value<int> poemId;
  final Value<int> authorId;
  final Value<int> rowid;
  const PoemAuthorsCompanion({
    this.poemId = const Value.absent(),
    this.authorId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PoemAuthorsCompanion.insert({
    required int poemId,
    required int authorId,
    this.rowid = const Value.absent(),
  }) : poemId = Value(poemId),
       authorId = Value(authorId);
  static Insertable<PoemAuthor> custom({
    Expression<int>? poemId,
    Expression<int>? authorId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (poemId != null) 'poem_id': poemId,
      if (authorId != null) 'author_id': authorId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PoemAuthorsCompanion copyWith({
    Value<int>? poemId,
    Value<int>? authorId,
    Value<int>? rowid,
  }) {
    return PoemAuthorsCompanion(
      poemId: poemId ?? this.poemId,
      authorId: authorId ?? this.authorId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (poemId.present) {
      map['poem_id'] = Variable<int>(poemId.value);
    }
    if (authorId.present) {
      map['author_id'] = Variable<int>(authorId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PoemAuthorsCompanion(')
          ..write('poemId: $poemId, ')
          ..write('authorId: $authorId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MetadataTable extends Metadata
    with TableInfo<$MetadataTable, MetadataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<MetadataData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  MetadataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MetadataData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $MetadataTable createAlias(String alias) {
    return $MetadataTable(attachedDatabase, alias);
  }
}

class MetadataData extends DataClass implements Insertable<MetadataData> {
  final String key;
  final String value;
  const MetadataData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  MetadataCompanion toCompanion(bool nullToAbsent) {
    return MetadataCompanion(key: Value(key), value: Value(value));
  }

  factory MetadataData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MetadataData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  MetadataData copyWith({String? key, String? value}) =>
      MetadataData(key: key ?? this.key, value: value ?? this.value);
  MetadataData copyWithCompanion(MetadataCompanion data) {
    return MetadataData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MetadataData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MetadataData &&
          other.key == this.key &&
          other.value == this.value);
}

class MetadataCompanion extends UpdateCompanion<MetadataData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const MetadataCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MetadataCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<MetadataData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MetadataCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return MetadataCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MetadataCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PoemPassagesTable extends PoemPassages
    with TableInfo<$PoemPassagesTable, PoemPassage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PoemPassagesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _poemIdMeta = const VerificationMeta('poemId');
  @override
  late final GeneratedColumn<int> poemId = GeneratedColumn<int>(
    'poem_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES poems (id)',
    ),
  );
  static const VerificationMeta _startTokenMeta = const VerificationMeta(
    'startToken',
  );
  @override
  late final GeneratedColumn<int> startToken = GeneratedColumn<int>(
    'start_token',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTokenMeta = const VerificationMeta(
    'endToken',
  );
  @override
  late final GeneratedColumn<int> endToken = GeneratedColumn<int>(
    'end_token',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _searchTextMeta = const VerificationMeta(
    'searchText',
  );
  @override
  late final GeneratedColumn<String> searchText = GeneratedColumn<String>(
    'search_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    poemId,
    startToken,
    endToken,
    searchText,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'poem_passages';
  @override
  VerificationContext validateIntegrity(
    Insertable<PoemPassage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('poem_id')) {
      context.handle(
        _poemIdMeta,
        poemId.isAcceptableOrUnknown(data['poem_id']!, _poemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_poemIdMeta);
    }
    if (data.containsKey('start_token')) {
      context.handle(
        _startTokenMeta,
        startToken.isAcceptableOrUnknown(data['start_token']!, _startTokenMeta),
      );
    } else if (isInserting) {
      context.missing(_startTokenMeta);
    }
    if (data.containsKey('end_token')) {
      context.handle(
        _endTokenMeta,
        endToken.isAcceptableOrUnknown(data['end_token']!, _endTokenMeta),
      );
    } else if (isInserting) {
      context.missing(_endTokenMeta);
    }
    if (data.containsKey('search_text')) {
      context.handle(
        _searchTextMeta,
        searchText.isAcceptableOrUnknown(data['search_text']!, _searchTextMeta),
      );
    } else if (isInserting) {
      context.missing(_searchTextMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PoemPassage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PoemPassage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      poemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}poem_id'],
      )!,
      startToken: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_token'],
      )!,
      endToken: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_token'],
      )!,
      searchText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search_text'],
      )!,
    );
  }

  @override
  $PoemPassagesTable createAlias(String alias) {
    return $PoemPassagesTable(attachedDatabase, alias);
  }
}

class PoemPassage extends DataClass implements Insertable<PoemPassage> {
  final int id;
  final int poemId;
  final int startToken;
  final int endToken;
  final String searchText;
  const PoemPassage({
    required this.id,
    required this.poemId,
    required this.startToken,
    required this.endToken,
    required this.searchText,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['poem_id'] = Variable<int>(poemId);
    map['start_token'] = Variable<int>(startToken);
    map['end_token'] = Variable<int>(endToken);
    map['search_text'] = Variable<String>(searchText);
    return map;
  }

  PoemPassagesCompanion toCompanion(bool nullToAbsent) {
    return PoemPassagesCompanion(
      id: Value(id),
      poemId: Value(poemId),
      startToken: Value(startToken),
      endToken: Value(endToken),
      searchText: Value(searchText),
    );
  }

  factory PoemPassage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PoemPassage(
      id: serializer.fromJson<int>(json['id']),
      poemId: serializer.fromJson<int>(json['poemId']),
      startToken: serializer.fromJson<int>(json['startToken']),
      endToken: serializer.fromJson<int>(json['endToken']),
      searchText: serializer.fromJson<String>(json['searchText']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'poemId': serializer.toJson<int>(poemId),
      'startToken': serializer.toJson<int>(startToken),
      'endToken': serializer.toJson<int>(endToken),
      'searchText': serializer.toJson<String>(searchText),
    };
  }

  PoemPassage copyWith({
    int? id,
    int? poemId,
    int? startToken,
    int? endToken,
    String? searchText,
  }) => PoemPassage(
    id: id ?? this.id,
    poemId: poemId ?? this.poemId,
    startToken: startToken ?? this.startToken,
    endToken: endToken ?? this.endToken,
    searchText: searchText ?? this.searchText,
  );
  PoemPassage copyWithCompanion(PoemPassagesCompanion data) {
    return PoemPassage(
      id: data.id.present ? data.id.value : this.id,
      poemId: data.poemId.present ? data.poemId.value : this.poemId,
      startToken: data.startToken.present
          ? data.startToken.value
          : this.startToken,
      endToken: data.endToken.present ? data.endToken.value : this.endToken,
      searchText: data.searchText.present
          ? data.searchText.value
          : this.searchText,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PoemPassage(')
          ..write('id: $id, ')
          ..write('poemId: $poemId, ')
          ..write('startToken: $startToken, ')
          ..write('endToken: $endToken, ')
          ..write('searchText: $searchText')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, poemId, startToken, endToken, searchText);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PoemPassage &&
          other.id == this.id &&
          other.poemId == this.poemId &&
          other.startToken == this.startToken &&
          other.endToken == this.endToken &&
          other.searchText == this.searchText);
}

class PoemPassagesCompanion extends UpdateCompanion<PoemPassage> {
  final Value<int> id;
  final Value<int> poemId;
  final Value<int> startToken;
  final Value<int> endToken;
  final Value<String> searchText;
  const PoemPassagesCompanion({
    this.id = const Value.absent(),
    this.poemId = const Value.absent(),
    this.startToken = const Value.absent(),
    this.endToken = const Value.absent(),
    this.searchText = const Value.absent(),
  });
  PoemPassagesCompanion.insert({
    this.id = const Value.absent(),
    required int poemId,
    required int startToken,
    required int endToken,
    required String searchText,
  }) : poemId = Value(poemId),
       startToken = Value(startToken),
       endToken = Value(endToken),
       searchText = Value(searchText);
  static Insertable<PoemPassage> custom({
    Expression<int>? id,
    Expression<int>? poemId,
    Expression<int>? startToken,
    Expression<int>? endToken,
    Expression<String>? searchText,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (poemId != null) 'poem_id': poemId,
      if (startToken != null) 'start_token': startToken,
      if (endToken != null) 'end_token': endToken,
      if (searchText != null) 'search_text': searchText,
    });
  }

  PoemPassagesCompanion copyWith({
    Value<int>? id,
    Value<int>? poemId,
    Value<int>? startToken,
    Value<int>? endToken,
    Value<String>? searchText,
  }) {
    return PoemPassagesCompanion(
      id: id ?? this.id,
      poemId: poemId ?? this.poemId,
      startToken: startToken ?? this.startToken,
      endToken: endToken ?? this.endToken,
      searchText: searchText ?? this.searchText,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (poemId.present) {
      map['poem_id'] = Variable<int>(poemId.value);
    }
    if (startToken.present) {
      map['start_token'] = Variable<int>(startToken.value);
    }
    if (endToken.present) {
      map['end_token'] = Variable<int>(endToken.value);
    }
    if (searchText.present) {
      map['search_text'] = Variable<String>(searchText.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PoemPassagesCompanion(')
          ..write('id: $id, ')
          ..write('poemId: $poemId, ')
          ..write('startToken: $startToken, ')
          ..write('endToken: $endToken, ')
          ..write('searchText: $searchText')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PoemsTable poems = $PoemsTable(this);
  late final $AuthorsTable authors = $AuthorsTable(this);
  late final $PoemAuthorsTable poemAuthors = $PoemAuthorsTable(this);
  late final $MetadataTable metadata = $MetadataTable(this);
  late final $PoemPassagesTable poemPassages = $PoemPassagesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    poems,
    authors,
    poemAuthors,
    metadata,
    poemPassages,
  ];
}

typedef $$PoemsTableCreateCompanionBuilder =
    PoemsCompanion Function({
      Value<int> id,
      required String title,
      required String authorNames,
      required String body,
      Value<String?> year,
      Value<String?> altTitles,
      required String poemKey,
      required String language,
      required String contentHash,
    });
typedef $$PoemsTableUpdateCompanionBuilder =
    PoemsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> authorNames,
      Value<String> body,
      Value<String?> year,
      Value<String?> altTitles,
      Value<String> poemKey,
      Value<String> language,
      Value<String> contentHash,
    });

final class $$PoemsTableReferences
    extends BaseReferences<_$AppDatabase, $PoemsTable, Poem> {
  $$PoemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PoemAuthorsTable, List<PoemAuthor>>
  _poemAuthorsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.poemAuthors,
    aliasName: $_aliasNameGenerator(db.poems.id, db.poemAuthors.poemId),
  );

  $$PoemAuthorsTableProcessedTableManager get poemAuthorsRefs {
    final manager = $$PoemAuthorsTableTableManager(
      $_db,
      $_db.poemAuthors,
    ).filter((f) => f.poemId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_poemAuthorsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PoemPassagesTable, List<PoemPassage>>
  _poemPassagesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.poemPassages,
    aliasName: $_aliasNameGenerator(db.poems.id, db.poemPassages.poemId),
  );

  $$PoemPassagesTableProcessedTableManager get poemPassagesRefs {
    final manager = $$PoemPassagesTableTableManager(
      $_db,
      $_db.poemPassages,
    ).filter((f) => f.poemId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_poemPassagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

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

  ColumnFilters<String> get authorNames => $composableBuilder(
    column: $table.authorNames,
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

  ColumnFilters<String> get altTitles => $composableBuilder(
    column: $table.altTitles,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get poemKey => $composableBuilder(
    column: $table.poemKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> poemAuthorsRefs(
    Expression<bool> Function($$PoemAuthorsTableFilterComposer f) f,
  ) {
    final $$PoemAuthorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.poemAuthors,
      getReferencedColumn: (t) => t.poemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PoemAuthorsTableFilterComposer(
            $db: $db,
            $table: $db.poemAuthors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> poemPassagesRefs(
    Expression<bool> Function($$PoemPassagesTableFilterComposer f) f,
  ) {
    final $$PoemPassagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.poemPassages,
      getReferencedColumn: (t) => t.poemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PoemPassagesTableFilterComposer(
            $db: $db,
            $table: $db.poemPassages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
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

  ColumnOrderings<String> get authorNames => $composableBuilder(
    column: $table.authorNames,
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

  ColumnOrderings<String> get altTitles => $composableBuilder(
    column: $table.altTitles,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get poemKey => $composableBuilder(
    column: $table.poemKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
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

  GeneratedColumn<String> get authorNames => $composableBuilder(
    column: $table.authorNames,
    builder: (column) => column,
  );

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get altTitles =>
      $composableBuilder(column: $table.altTitles, builder: (column) => column);

  GeneratedColumn<String> get poemKey =>
      $composableBuilder(column: $table.poemKey, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => column,
  );

  Expression<T> poemAuthorsRefs<T extends Object>(
    Expression<T> Function($$PoemAuthorsTableAnnotationComposer a) f,
  ) {
    final $$PoemAuthorsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.poemAuthors,
      getReferencedColumn: (t) => t.poemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PoemAuthorsTableAnnotationComposer(
            $db: $db,
            $table: $db.poemAuthors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> poemPassagesRefs<T extends Object>(
    Expression<T> Function($$PoemPassagesTableAnnotationComposer a) f,
  ) {
    final $$PoemPassagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.poemPassages,
      getReferencedColumn: (t) => t.poemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PoemPassagesTableAnnotationComposer(
            $db: $db,
            $table: $db.poemPassages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
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
          (Poem, $$PoemsTableReferences),
          Poem,
          PrefetchHooks Function({bool poemAuthorsRefs, bool poemPassagesRefs})
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
                Value<String> authorNames = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String?> year = const Value.absent(),
                Value<String?> altTitles = const Value.absent(),
                Value<String> poemKey = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String> contentHash = const Value.absent(),
              }) => PoemsCompanion(
                id: id,
                title: title,
                authorNames: authorNames,
                body: body,
                year: year,
                altTitles: altTitles,
                poemKey: poemKey,
                language: language,
                contentHash: contentHash,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required String authorNames,
                required String body,
                Value<String?> year = const Value.absent(),
                Value<String?> altTitles = const Value.absent(),
                required String poemKey,
                required String language,
                required String contentHash,
              }) => PoemsCompanion.insert(
                id: id,
                title: title,
                authorNames: authorNames,
                body: body,
                year: year,
                altTitles: altTitles,
                poemKey: poemKey,
                language: language,
                contentHash: contentHash,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$PoemsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({poemAuthorsRefs = false, poemPassagesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (poemAuthorsRefs) db.poemAuthors,
                    if (poemPassagesRefs) db.poemPassages,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (poemAuthorsRefs)
                        await $_getPrefetchedData<
                          Poem,
                          $PoemsTable,
                          PoemAuthor
                        >(
                          currentTable: table,
                          referencedTable: $$PoemsTableReferences
                              ._poemAuthorsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PoemsTableReferences(
                                db,
                                table,
                                p0,
                              ).poemAuthorsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.poemId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (poemPassagesRefs)
                        await $_getPrefetchedData<
                          Poem,
                          $PoemsTable,
                          PoemPassage
                        >(
                          currentTable: table,
                          referencedTable: $$PoemsTableReferences
                              ._poemPassagesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PoemsTableReferences(
                                db,
                                table,
                                p0,
                              ).poemPassagesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.poemId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
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
      (Poem, $$PoemsTableReferences),
      Poem,
      PrefetchHooks Function({bool poemAuthorsRefs, bool poemPassagesRefs})
    >;
typedef $$AuthorsTableCreateCompanionBuilder =
    AuthorsCompanion Function({
      Value<int> id,
      required String name,
      required int poemCount,
    });
typedef $$AuthorsTableUpdateCompanionBuilder =
    AuthorsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> poemCount,
    });

final class $$AuthorsTableReferences
    extends BaseReferences<_$AppDatabase, $AuthorsTable, Author> {
  $$AuthorsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PoemAuthorsTable, List<PoemAuthor>>
  _poemAuthorsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.poemAuthors,
    aliasName: $_aliasNameGenerator(db.authors.id, db.poemAuthors.authorId),
  );

  $$PoemAuthorsTableProcessedTableManager get poemAuthorsRefs {
    final manager = $$PoemAuthorsTableTableManager(
      $_db,
      $_db.poemAuthors,
    ).filter((f) => f.authorId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_poemAuthorsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AuthorsTableFilterComposer
    extends Composer<_$AppDatabase, $AuthorsTable> {
  $$AuthorsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get poemCount => $composableBuilder(
    column: $table.poemCount,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> poemAuthorsRefs(
    Expression<bool> Function($$PoemAuthorsTableFilterComposer f) f,
  ) {
    final $$PoemAuthorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.poemAuthors,
      getReferencedColumn: (t) => t.authorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PoemAuthorsTableFilterComposer(
            $db: $db,
            $table: $db.poemAuthors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AuthorsTableOrderingComposer
    extends Composer<_$AppDatabase, $AuthorsTable> {
  $$AuthorsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get poemCount => $composableBuilder(
    column: $table.poemCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AuthorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AuthorsTable> {
  $$AuthorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get poemCount =>
      $composableBuilder(column: $table.poemCount, builder: (column) => column);

  Expression<T> poemAuthorsRefs<T extends Object>(
    Expression<T> Function($$PoemAuthorsTableAnnotationComposer a) f,
  ) {
    final $$PoemAuthorsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.poemAuthors,
      getReferencedColumn: (t) => t.authorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PoemAuthorsTableAnnotationComposer(
            $db: $db,
            $table: $db.poemAuthors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AuthorsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AuthorsTable,
          Author,
          $$AuthorsTableFilterComposer,
          $$AuthorsTableOrderingComposer,
          $$AuthorsTableAnnotationComposer,
          $$AuthorsTableCreateCompanionBuilder,
          $$AuthorsTableUpdateCompanionBuilder,
          (Author, $$AuthorsTableReferences),
          Author,
          PrefetchHooks Function({bool poemAuthorsRefs})
        > {
  $$AuthorsTableTableManager(_$AppDatabase db, $AuthorsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuthorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuthorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuthorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> poemCount = const Value.absent(),
              }) => AuthorsCompanion(id: id, name: name, poemCount: poemCount),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int poemCount,
              }) => AuthorsCompanion.insert(
                id: id,
                name: name,
                poemCount: poemCount,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AuthorsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({poemAuthorsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (poemAuthorsRefs) db.poemAuthors],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (poemAuthorsRefs)
                    await $_getPrefetchedData<
                      Author,
                      $AuthorsTable,
                      PoemAuthor
                    >(
                      currentTable: table,
                      referencedTable: $$AuthorsTableReferences
                          ._poemAuthorsRefsTable(db),
                      managerFromTypedResult: (p0) => $$AuthorsTableReferences(
                        db,
                        table,
                        p0,
                      ).poemAuthorsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.authorId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$AuthorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AuthorsTable,
      Author,
      $$AuthorsTableFilterComposer,
      $$AuthorsTableOrderingComposer,
      $$AuthorsTableAnnotationComposer,
      $$AuthorsTableCreateCompanionBuilder,
      $$AuthorsTableUpdateCompanionBuilder,
      (Author, $$AuthorsTableReferences),
      Author,
      PrefetchHooks Function({bool poemAuthorsRefs})
    >;
typedef $$PoemAuthorsTableCreateCompanionBuilder =
    PoemAuthorsCompanion Function({
      required int poemId,
      required int authorId,
      Value<int> rowid,
    });
typedef $$PoemAuthorsTableUpdateCompanionBuilder =
    PoemAuthorsCompanion Function({
      Value<int> poemId,
      Value<int> authorId,
      Value<int> rowid,
    });

final class $$PoemAuthorsTableReferences
    extends BaseReferences<_$AppDatabase, $PoemAuthorsTable, PoemAuthor> {
  $$PoemAuthorsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PoemsTable _poemIdTable(_$AppDatabase db) => db.poems.createAlias(
    $_aliasNameGenerator(db.poemAuthors.poemId, db.poems.id),
  );

  $$PoemsTableProcessedTableManager get poemId {
    final $_column = $_itemColumn<int>('poem_id')!;

    final manager = $$PoemsTableTableManager(
      $_db,
      $_db.poems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_poemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AuthorsTable _authorIdTable(_$AppDatabase db) =>
      db.authors.createAlias(
        $_aliasNameGenerator(db.poemAuthors.authorId, db.authors.id),
      );

  $$AuthorsTableProcessedTableManager get authorId {
    final $_column = $_itemColumn<int>('author_id')!;

    final manager = $$AuthorsTableTableManager(
      $_db,
      $_db.authors,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_authorIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PoemAuthorsTableFilterComposer
    extends Composer<_$AppDatabase, $PoemAuthorsTable> {
  $$PoemAuthorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$PoemsTableFilterComposer get poemId {
    final $$PoemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.poemId,
      referencedTable: $db.poems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PoemsTableFilterComposer(
            $db: $db,
            $table: $db.poems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AuthorsTableFilterComposer get authorId {
    final $$AuthorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authorId,
      referencedTable: $db.authors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuthorsTableFilterComposer(
            $db: $db,
            $table: $db.authors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PoemAuthorsTableOrderingComposer
    extends Composer<_$AppDatabase, $PoemAuthorsTable> {
  $$PoemAuthorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$PoemsTableOrderingComposer get poemId {
    final $$PoemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.poemId,
      referencedTable: $db.poems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PoemsTableOrderingComposer(
            $db: $db,
            $table: $db.poems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AuthorsTableOrderingComposer get authorId {
    final $$AuthorsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authorId,
      referencedTable: $db.authors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuthorsTableOrderingComposer(
            $db: $db,
            $table: $db.authors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PoemAuthorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PoemAuthorsTable> {
  $$PoemAuthorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$PoemsTableAnnotationComposer get poemId {
    final $$PoemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.poemId,
      referencedTable: $db.poems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PoemsTableAnnotationComposer(
            $db: $db,
            $table: $db.poems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AuthorsTableAnnotationComposer get authorId {
    final $$AuthorsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authorId,
      referencedTable: $db.authors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuthorsTableAnnotationComposer(
            $db: $db,
            $table: $db.authors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PoemAuthorsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PoemAuthorsTable,
          PoemAuthor,
          $$PoemAuthorsTableFilterComposer,
          $$PoemAuthorsTableOrderingComposer,
          $$PoemAuthorsTableAnnotationComposer,
          $$PoemAuthorsTableCreateCompanionBuilder,
          $$PoemAuthorsTableUpdateCompanionBuilder,
          (PoemAuthor, $$PoemAuthorsTableReferences),
          PoemAuthor,
          PrefetchHooks Function({bool poemId, bool authorId})
        > {
  $$PoemAuthorsTableTableManager(_$AppDatabase db, $PoemAuthorsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PoemAuthorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PoemAuthorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PoemAuthorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> poemId = const Value.absent(),
                Value<int> authorId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PoemAuthorsCompanion(
                poemId: poemId,
                authorId: authorId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int poemId,
                required int authorId,
                Value<int> rowid = const Value.absent(),
              }) => PoemAuthorsCompanion.insert(
                poemId: poemId,
                authorId: authorId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PoemAuthorsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({poemId = false, authorId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (poemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.poemId,
                                referencedTable: $$PoemAuthorsTableReferences
                                    ._poemIdTable(db),
                                referencedColumn: $$PoemAuthorsTableReferences
                                    ._poemIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (authorId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.authorId,
                                referencedTable: $$PoemAuthorsTableReferences
                                    ._authorIdTable(db),
                                referencedColumn: $$PoemAuthorsTableReferences
                                    ._authorIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PoemAuthorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PoemAuthorsTable,
      PoemAuthor,
      $$PoemAuthorsTableFilterComposer,
      $$PoemAuthorsTableOrderingComposer,
      $$PoemAuthorsTableAnnotationComposer,
      $$PoemAuthorsTableCreateCompanionBuilder,
      $$PoemAuthorsTableUpdateCompanionBuilder,
      (PoemAuthor, $$PoemAuthorsTableReferences),
      PoemAuthor,
      PrefetchHooks Function({bool poemId, bool authorId})
    >;
typedef $$MetadataTableCreateCompanionBuilder =
    MetadataCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$MetadataTableUpdateCompanionBuilder =
    MetadataCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$MetadataTableFilterComposer
    extends Composer<_$AppDatabase, $MetadataTable> {
  $$MetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MetadataTableOrderingComposer
    extends Composer<_$AppDatabase, $MetadataTable> {
  $$MetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MetadataTableAnnotationComposer
    extends Composer<_$AppDatabase, $MetadataTable> {
  $$MetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$MetadataTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MetadataTable,
          MetadataData,
          $$MetadataTableFilterComposer,
          $$MetadataTableOrderingComposer,
          $$MetadataTableAnnotationComposer,
          $$MetadataTableCreateCompanionBuilder,
          $$MetadataTableUpdateCompanionBuilder,
          (
            MetadataData,
            BaseReferences<_$AppDatabase, $MetadataTable, MetadataData>,
          ),
          MetadataData,
          PrefetchHooks Function()
        > {
  $$MetadataTableTableManager(_$AppDatabase db, $MetadataTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MetadataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MetadataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MetadataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MetadataCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => MetadataCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MetadataTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MetadataTable,
      MetadataData,
      $$MetadataTableFilterComposer,
      $$MetadataTableOrderingComposer,
      $$MetadataTableAnnotationComposer,
      $$MetadataTableCreateCompanionBuilder,
      $$MetadataTableUpdateCompanionBuilder,
      (
        MetadataData,
        BaseReferences<_$AppDatabase, $MetadataTable, MetadataData>,
      ),
      MetadataData,
      PrefetchHooks Function()
    >;
typedef $$PoemPassagesTableCreateCompanionBuilder =
    PoemPassagesCompanion Function({
      Value<int> id,
      required int poemId,
      required int startToken,
      required int endToken,
      required String searchText,
    });
typedef $$PoemPassagesTableUpdateCompanionBuilder =
    PoemPassagesCompanion Function({
      Value<int> id,
      Value<int> poemId,
      Value<int> startToken,
      Value<int> endToken,
      Value<String> searchText,
    });

final class $$PoemPassagesTableReferences
    extends BaseReferences<_$AppDatabase, $PoemPassagesTable, PoemPassage> {
  $$PoemPassagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PoemsTable _poemIdTable(_$AppDatabase db) => db.poems.createAlias(
    $_aliasNameGenerator(db.poemPassages.poemId, db.poems.id),
  );

  $$PoemsTableProcessedTableManager get poemId {
    final $_column = $_itemColumn<int>('poem_id')!;

    final manager = $$PoemsTableTableManager(
      $_db,
      $_db.poems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_poemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PoemPassagesTableFilterComposer
    extends Composer<_$AppDatabase, $PoemPassagesTable> {
  $$PoemPassagesTableFilterComposer({
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

  ColumnFilters<int> get startToken => $composableBuilder(
    column: $table.startToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endToken => $composableBuilder(
    column: $table.endToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => ColumnFilters(column),
  );

  $$PoemsTableFilterComposer get poemId {
    final $$PoemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.poemId,
      referencedTable: $db.poems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PoemsTableFilterComposer(
            $db: $db,
            $table: $db.poems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PoemPassagesTableOrderingComposer
    extends Composer<_$AppDatabase, $PoemPassagesTable> {
  $$PoemPassagesTableOrderingComposer({
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

  ColumnOrderings<int> get startToken => $composableBuilder(
    column: $table.startToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endToken => $composableBuilder(
    column: $table.endToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => ColumnOrderings(column),
  );

  $$PoemsTableOrderingComposer get poemId {
    final $$PoemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.poemId,
      referencedTable: $db.poems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PoemsTableOrderingComposer(
            $db: $db,
            $table: $db.poems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PoemPassagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PoemPassagesTable> {
  $$PoemPassagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get startToken => $composableBuilder(
    column: $table.startToken,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endToken =>
      $composableBuilder(column: $table.endToken, builder: (column) => column);

  GeneratedColumn<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => column,
  );

  $$PoemsTableAnnotationComposer get poemId {
    final $$PoemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.poemId,
      referencedTable: $db.poems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PoemsTableAnnotationComposer(
            $db: $db,
            $table: $db.poems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PoemPassagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PoemPassagesTable,
          PoemPassage,
          $$PoemPassagesTableFilterComposer,
          $$PoemPassagesTableOrderingComposer,
          $$PoemPassagesTableAnnotationComposer,
          $$PoemPassagesTableCreateCompanionBuilder,
          $$PoemPassagesTableUpdateCompanionBuilder,
          (PoemPassage, $$PoemPassagesTableReferences),
          PoemPassage,
          PrefetchHooks Function({bool poemId})
        > {
  $$PoemPassagesTableTableManager(_$AppDatabase db, $PoemPassagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PoemPassagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PoemPassagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PoemPassagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> poemId = const Value.absent(),
                Value<int> startToken = const Value.absent(),
                Value<int> endToken = const Value.absent(),
                Value<String> searchText = const Value.absent(),
              }) => PoemPassagesCompanion(
                id: id,
                poemId: poemId,
                startToken: startToken,
                endToken: endToken,
                searchText: searchText,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int poemId,
                required int startToken,
                required int endToken,
                required String searchText,
              }) => PoemPassagesCompanion.insert(
                id: id,
                poemId: poemId,
                startToken: startToken,
                endToken: endToken,
                searchText: searchText,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PoemPassagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({poemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (poemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.poemId,
                                referencedTable: $$PoemPassagesTableReferences
                                    ._poemIdTable(db),
                                referencedColumn: $$PoemPassagesTableReferences
                                    ._poemIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PoemPassagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PoemPassagesTable,
      PoemPassage,
      $$PoemPassagesTableFilterComposer,
      $$PoemPassagesTableOrderingComposer,
      $$PoemPassagesTableAnnotationComposer,
      $$PoemPassagesTableCreateCompanionBuilder,
      $$PoemPassagesTableUpdateCompanionBuilder,
      (PoemPassage, $$PoemPassagesTableReferences),
      PoemPassage,
      PrefetchHooks Function({bool poemId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PoemsTableTableManager get poems =>
      $$PoemsTableTableManager(_db, _db.poems);
  $$AuthorsTableTableManager get authors =>
      $$AuthorsTableTableManager(_db, _db.authors);
  $$PoemAuthorsTableTableManager get poemAuthors =>
      $$PoemAuthorsTableTableManager(_db, _db.poemAuthors);
  $$MetadataTableTableManager get metadata =>
      $$MetadataTableTableManager(_db, _db.metadata);
  $$PoemPassagesTableTableManager get poemPassages =>
      $$PoemPassagesTableTableManager(_db, _db.poemPassages);
}
