// GENERATED CODE - DO NOT MODIFY BY HAND

// coverage:ignore-file
// ignore_for_file: type=lint

part of 'study_database.dart';

// ignore_for_file: type=lint
class $StudyCardsTable extends StudyCards
    with TableInfo<$StudyCardsTable, StudyCard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StudyCardsTable(this.attachedDatabase, [this._alias]);
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
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<int> state = GeneratedColumn<int>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stepMeta = const VerificationMeta('step');
  @override
  late final GeneratedColumn<int> step = GeneratedColumn<int>(
    'step',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stabilityMeta = const VerificationMeta(
    'stability',
  );
  @override
  late final GeneratedColumn<double> stability = GeneratedColumn<double>(
    'stability',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<double> difficulty = GeneratedColumn<double>(
    'difficulty',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueMillisMeta = const VerificationMeta(
    'dueMillis',
  );
  @override
  late final GeneratedColumn<int> dueMillis = GeneratedColumn<int>(
    'due_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastReviewMillisMeta = const VerificationMeta(
    'lastReviewMillis',
  );
  @override
  late final GeneratedColumn<int> lastReviewMillis = GeneratedColumn<int>(
    'last_review_millis',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    poemKey,
    state,
    step,
    stability,
    difficulty,
    dueMillis,
    lastReviewMillis,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'study_cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<StudyCard> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('poem_key')) {
      context.handle(
        _poemKeyMeta,
        poemKey.isAcceptableOrUnknown(data['poem_key']!, _poemKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_poemKeyMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('step')) {
      context.handle(
        _stepMeta,
        step.isAcceptableOrUnknown(data['step']!, _stepMeta),
      );
    }
    if (data.containsKey('stability')) {
      context.handle(
        _stabilityMeta,
        stability.isAcceptableOrUnknown(data['stability']!, _stabilityMeta),
      );
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    }
    if (data.containsKey('due_millis')) {
      context.handle(
        _dueMillisMeta,
        dueMillis.isAcceptableOrUnknown(data['due_millis']!, _dueMillisMeta),
      );
    } else if (isInserting) {
      context.missing(_dueMillisMeta);
    }
    if (data.containsKey('last_review_millis')) {
      context.handle(
        _lastReviewMillisMeta,
        lastReviewMillis.isAcceptableOrUnknown(
          data['last_review_millis']!,
          _lastReviewMillisMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StudyCard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudyCard(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      poemKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}poem_key'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}state'],
      )!,
      step: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}step'],
      ),
      stability: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stability'],
      ),
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}difficulty'],
      ),
      dueMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_millis'],
      )!,
      lastReviewMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_review_millis'],
      ),
    );
  }

  @override
  $StudyCardsTable createAlias(String alias) {
    return $StudyCardsTable(attachedDatabase, alias);
  }
}

class StudyCard extends DataClass implements Insertable<StudyCard> {
  final int id;

  /// Stable poem identity from the corpus builder, not a local row id.
  final String poemKey;

  /// FSRS `State` value.
  final int state;
  final int? step;
  final double? stability;
  final double? difficulty;

  /// UTC epoch milliseconds. Integers keep due-ordering exact.
  final int dueMillis;
  final int? lastReviewMillis;
  const StudyCard({
    required this.id,
    required this.poemKey,
    required this.state,
    this.step,
    this.stability,
    this.difficulty,
    required this.dueMillis,
    this.lastReviewMillis,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['poem_key'] = Variable<String>(poemKey);
    map['state'] = Variable<int>(state);
    if (!nullToAbsent || step != null) {
      map['step'] = Variable<int>(step);
    }
    if (!nullToAbsent || stability != null) {
      map['stability'] = Variable<double>(stability);
    }
    if (!nullToAbsent || difficulty != null) {
      map['difficulty'] = Variable<double>(difficulty);
    }
    map['due_millis'] = Variable<int>(dueMillis);
    if (!nullToAbsent || lastReviewMillis != null) {
      map['last_review_millis'] = Variable<int>(lastReviewMillis);
    }
    return map;
  }

  StudyCardsCompanion toCompanion(bool nullToAbsent) {
    return StudyCardsCompanion(
      id: Value(id),
      poemKey: Value(poemKey),
      state: Value(state),
      step: step == null && nullToAbsent ? const Value.absent() : Value(step),
      stability: stability == null && nullToAbsent
          ? const Value.absent()
          : Value(stability),
      difficulty: difficulty == null && nullToAbsent
          ? const Value.absent()
          : Value(difficulty),
      dueMillis: Value(dueMillis),
      lastReviewMillis: lastReviewMillis == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewMillis),
    );
  }

  factory StudyCard.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudyCard(
      id: serializer.fromJson<int>(json['id']),
      poemKey: serializer.fromJson<String>(json['poemKey']),
      state: serializer.fromJson<int>(json['state']),
      step: serializer.fromJson<int?>(json['step']),
      stability: serializer.fromJson<double?>(json['stability']),
      difficulty: serializer.fromJson<double?>(json['difficulty']),
      dueMillis: serializer.fromJson<int>(json['dueMillis']),
      lastReviewMillis: serializer.fromJson<int?>(json['lastReviewMillis']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'poemKey': serializer.toJson<String>(poemKey),
      'state': serializer.toJson<int>(state),
      'step': serializer.toJson<int?>(step),
      'stability': serializer.toJson<double?>(stability),
      'difficulty': serializer.toJson<double?>(difficulty),
      'dueMillis': serializer.toJson<int>(dueMillis),
      'lastReviewMillis': serializer.toJson<int?>(lastReviewMillis),
    };
  }

  StudyCard copyWith({
    int? id,
    String? poemKey,
    int? state,
    Value<int?> step = const Value.absent(),
    Value<double?> stability = const Value.absent(),
    Value<double?> difficulty = const Value.absent(),
    int? dueMillis,
    Value<int?> lastReviewMillis = const Value.absent(),
  }) => StudyCard(
    id: id ?? this.id,
    poemKey: poemKey ?? this.poemKey,
    state: state ?? this.state,
    step: step.present ? step.value : this.step,
    stability: stability.present ? stability.value : this.stability,
    difficulty: difficulty.present ? difficulty.value : this.difficulty,
    dueMillis: dueMillis ?? this.dueMillis,
    lastReviewMillis: lastReviewMillis.present
        ? lastReviewMillis.value
        : this.lastReviewMillis,
  );
  StudyCard copyWithCompanion(StudyCardsCompanion data) {
    return StudyCard(
      id: data.id.present ? data.id.value : this.id,
      poemKey: data.poemKey.present ? data.poemKey.value : this.poemKey,
      state: data.state.present ? data.state.value : this.state,
      step: data.step.present ? data.step.value : this.step,
      stability: data.stability.present ? data.stability.value : this.stability,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      dueMillis: data.dueMillis.present ? data.dueMillis.value : this.dueMillis,
      lastReviewMillis: data.lastReviewMillis.present
          ? data.lastReviewMillis.value
          : this.lastReviewMillis,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StudyCard(')
          ..write('id: $id, ')
          ..write('poemKey: $poemKey, ')
          ..write('state: $state, ')
          ..write('step: $step, ')
          ..write('stability: $stability, ')
          ..write('difficulty: $difficulty, ')
          ..write('dueMillis: $dueMillis, ')
          ..write('lastReviewMillis: $lastReviewMillis')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    poemKey,
    state,
    step,
    stability,
    difficulty,
    dueMillis,
    lastReviewMillis,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudyCard &&
          other.id == this.id &&
          other.poemKey == this.poemKey &&
          other.state == this.state &&
          other.step == this.step &&
          other.stability == this.stability &&
          other.difficulty == this.difficulty &&
          other.dueMillis == this.dueMillis &&
          other.lastReviewMillis == this.lastReviewMillis);
}

class StudyCardsCompanion extends UpdateCompanion<StudyCard> {
  final Value<int> id;
  final Value<String> poemKey;
  final Value<int> state;
  final Value<int?> step;
  final Value<double?> stability;
  final Value<double?> difficulty;
  final Value<int> dueMillis;
  final Value<int?> lastReviewMillis;
  const StudyCardsCompanion({
    this.id = const Value.absent(),
    this.poemKey = const Value.absent(),
    this.state = const Value.absent(),
    this.step = const Value.absent(),
    this.stability = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.dueMillis = const Value.absent(),
    this.lastReviewMillis = const Value.absent(),
  });
  StudyCardsCompanion.insert({
    this.id = const Value.absent(),
    required String poemKey,
    required int state,
    this.step = const Value.absent(),
    this.stability = const Value.absent(),
    this.difficulty = const Value.absent(),
    required int dueMillis,
    this.lastReviewMillis = const Value.absent(),
  }) : poemKey = Value(poemKey),
       state = Value(state),
       dueMillis = Value(dueMillis);
  static Insertable<StudyCard> custom({
    Expression<int>? id,
    Expression<String>? poemKey,
    Expression<int>? state,
    Expression<int>? step,
    Expression<double>? stability,
    Expression<double>? difficulty,
    Expression<int>? dueMillis,
    Expression<int>? lastReviewMillis,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (poemKey != null) 'poem_key': poemKey,
      if (state != null) 'state': state,
      if (step != null) 'step': step,
      if (stability != null) 'stability': stability,
      if (difficulty != null) 'difficulty': difficulty,
      if (dueMillis != null) 'due_millis': dueMillis,
      if (lastReviewMillis != null) 'last_review_millis': lastReviewMillis,
    });
  }

  StudyCardsCompanion copyWith({
    Value<int>? id,
    Value<String>? poemKey,
    Value<int>? state,
    Value<int?>? step,
    Value<double?>? stability,
    Value<double?>? difficulty,
    Value<int>? dueMillis,
    Value<int?>? lastReviewMillis,
  }) {
    return StudyCardsCompanion(
      id: id ?? this.id,
      poemKey: poemKey ?? this.poemKey,
      state: state ?? this.state,
      step: step ?? this.step,
      stability: stability ?? this.stability,
      difficulty: difficulty ?? this.difficulty,
      dueMillis: dueMillis ?? this.dueMillis,
      lastReviewMillis: lastReviewMillis ?? this.lastReviewMillis,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (poemKey.present) {
      map['poem_key'] = Variable<String>(poemKey.value);
    }
    if (state.present) {
      map['state'] = Variable<int>(state.value);
    }
    if (step.present) {
      map['step'] = Variable<int>(step.value);
    }
    if (stability.present) {
      map['stability'] = Variable<double>(stability.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<double>(difficulty.value);
    }
    if (dueMillis.present) {
      map['due_millis'] = Variable<int>(dueMillis.value);
    }
    if (lastReviewMillis.present) {
      map['last_review_millis'] = Variable<int>(lastReviewMillis.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudyCardsCompanion(')
          ..write('id: $id, ')
          ..write('poemKey: $poemKey, ')
          ..write('state: $state, ')
          ..write('step: $step, ')
          ..write('stability: $stability, ')
          ..write('difficulty: $difficulty, ')
          ..write('dueMillis: $dueMillis, ')
          ..write('lastReviewMillis: $lastReviewMillis')
          ..write(')'))
        .toString();
  }
}

class $StudyReviewLogsTable extends StudyReviewLogs
    with TableInfo<$StudyReviewLogsTable, StudyReviewLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StudyReviewLogsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<int> cardId = GeneratedColumn<int>(
    'card_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES study_cards (id)',
    ),
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reviewMillisMeta = const VerificationMeta(
    'reviewMillis',
  );
  @override
  late final GeneratedColumn<int> reviewMillis = GeneratedColumn<int>(
    'review_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reviewDurationMillisMeta =
      const VerificationMeta('reviewDurationMillis');
  @override
  late final GeneratedColumn<int> reviewDurationMillis = GeneratedColumn<int>(
    'review_duration_millis',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cardId,
    rating,
    reviewMillis,
    reviewDurationMillis,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'study_review_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<StudyReviewLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('review_millis')) {
      context.handle(
        _reviewMillisMeta,
        reviewMillis.isAcceptableOrUnknown(
          data['review_millis']!,
          _reviewMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reviewMillisMeta);
    }
    if (data.containsKey('review_duration_millis')) {
      context.handle(
        _reviewDurationMillisMeta,
        reviewDurationMillis.isAcceptableOrUnknown(
          data['review_duration_millis']!,
          _reviewDurationMillisMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StudyReviewLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudyReviewLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}card_id'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating'],
      )!,
      reviewMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}review_millis'],
      )!,
      reviewDurationMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}review_duration_millis'],
      ),
    );
  }

  @override
  $StudyReviewLogsTable createAlias(String alias) {
    return $StudyReviewLogsTable(attachedDatabase, alias);
  }
}

class StudyReviewLog extends DataClass implements Insertable<StudyReviewLog> {
  final int id;
  final int cardId;

  /// FSRS `Rating` value.
  final int rating;

  /// UTC epoch milliseconds.
  final int reviewMillis;
  final int? reviewDurationMillis;
  const StudyReviewLog({
    required this.id,
    required this.cardId,
    required this.rating,
    required this.reviewMillis,
    this.reviewDurationMillis,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['card_id'] = Variable<int>(cardId);
    map['rating'] = Variable<int>(rating);
    map['review_millis'] = Variable<int>(reviewMillis);
    if (!nullToAbsent || reviewDurationMillis != null) {
      map['review_duration_millis'] = Variable<int>(reviewDurationMillis);
    }
    return map;
  }

  StudyReviewLogsCompanion toCompanion(bool nullToAbsent) {
    return StudyReviewLogsCompanion(
      id: Value(id),
      cardId: Value(cardId),
      rating: Value(rating),
      reviewMillis: Value(reviewMillis),
      reviewDurationMillis: reviewDurationMillis == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewDurationMillis),
    );
  }

  factory StudyReviewLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudyReviewLog(
      id: serializer.fromJson<int>(json['id']),
      cardId: serializer.fromJson<int>(json['cardId']),
      rating: serializer.fromJson<int>(json['rating']),
      reviewMillis: serializer.fromJson<int>(json['reviewMillis']),
      reviewDurationMillis: serializer.fromJson<int?>(
        json['reviewDurationMillis'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cardId': serializer.toJson<int>(cardId),
      'rating': serializer.toJson<int>(rating),
      'reviewMillis': serializer.toJson<int>(reviewMillis),
      'reviewDurationMillis': serializer.toJson<int?>(reviewDurationMillis),
    };
  }

  StudyReviewLog copyWith({
    int? id,
    int? cardId,
    int? rating,
    int? reviewMillis,
    Value<int?> reviewDurationMillis = const Value.absent(),
  }) => StudyReviewLog(
    id: id ?? this.id,
    cardId: cardId ?? this.cardId,
    rating: rating ?? this.rating,
    reviewMillis: reviewMillis ?? this.reviewMillis,
    reviewDurationMillis: reviewDurationMillis.present
        ? reviewDurationMillis.value
        : this.reviewDurationMillis,
  );
  StudyReviewLog copyWithCompanion(StudyReviewLogsCompanion data) {
    return StudyReviewLog(
      id: data.id.present ? data.id.value : this.id,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      rating: data.rating.present ? data.rating.value : this.rating,
      reviewMillis: data.reviewMillis.present
          ? data.reviewMillis.value
          : this.reviewMillis,
      reviewDurationMillis: data.reviewDurationMillis.present
          ? data.reviewDurationMillis.value
          : this.reviewDurationMillis,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StudyReviewLog(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('rating: $rating, ')
          ..write('reviewMillis: $reviewMillis, ')
          ..write('reviewDurationMillis: $reviewDurationMillis')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, cardId, rating, reviewMillis, reviewDurationMillis);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudyReviewLog &&
          other.id == this.id &&
          other.cardId == this.cardId &&
          other.rating == this.rating &&
          other.reviewMillis == this.reviewMillis &&
          other.reviewDurationMillis == this.reviewDurationMillis);
}

class StudyReviewLogsCompanion extends UpdateCompanion<StudyReviewLog> {
  final Value<int> id;
  final Value<int> cardId;
  final Value<int> rating;
  final Value<int> reviewMillis;
  final Value<int?> reviewDurationMillis;
  const StudyReviewLogsCompanion({
    this.id = const Value.absent(),
    this.cardId = const Value.absent(),
    this.rating = const Value.absent(),
    this.reviewMillis = const Value.absent(),
    this.reviewDurationMillis = const Value.absent(),
  });
  StudyReviewLogsCompanion.insert({
    this.id = const Value.absent(),
    required int cardId,
    required int rating,
    required int reviewMillis,
    this.reviewDurationMillis = const Value.absent(),
  }) : cardId = Value(cardId),
       rating = Value(rating),
       reviewMillis = Value(reviewMillis);
  static Insertable<StudyReviewLog> custom({
    Expression<int>? id,
    Expression<int>? cardId,
    Expression<int>? rating,
    Expression<int>? reviewMillis,
    Expression<int>? reviewDurationMillis,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cardId != null) 'card_id': cardId,
      if (rating != null) 'rating': rating,
      if (reviewMillis != null) 'review_millis': reviewMillis,
      if (reviewDurationMillis != null)
        'review_duration_millis': reviewDurationMillis,
    });
  }

  StudyReviewLogsCompanion copyWith({
    Value<int>? id,
    Value<int>? cardId,
    Value<int>? rating,
    Value<int>? reviewMillis,
    Value<int?>? reviewDurationMillis,
  }) {
    return StudyReviewLogsCompanion(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      rating: rating ?? this.rating,
      reviewMillis: reviewMillis ?? this.reviewMillis,
      reviewDurationMillis: reviewDurationMillis ?? this.reviewDurationMillis,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<int>(cardId.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (reviewMillis.present) {
      map['review_millis'] = Variable<int>(reviewMillis.value);
    }
    if (reviewDurationMillis.present) {
      map['review_duration_millis'] = Variable<int>(reviewDurationMillis.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudyReviewLogsCompanion(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('rating: $rating, ')
          ..write('reviewMillis: $reviewMillis, ')
          ..write('reviewDurationMillis: $reviewDurationMillis')
          ..write(')'))
        .toString();
  }
}

abstract class _$StudyDatabase extends GeneratedDatabase {
  _$StudyDatabase(QueryExecutor e) : super(e);
  $StudyDatabaseManager get managers => $StudyDatabaseManager(this);
  late final $StudyCardsTable studyCards = $StudyCardsTable(this);
  late final $StudyReviewLogsTable studyReviewLogs = $StudyReviewLogsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    studyCards,
    studyReviewLogs,
  ];
}

typedef $$StudyCardsTableCreateCompanionBuilder =
    StudyCardsCompanion Function({
      Value<int> id,
      required String poemKey,
      required int state,
      Value<int?> step,
      Value<double?> stability,
      Value<double?> difficulty,
      required int dueMillis,
      Value<int?> lastReviewMillis,
    });
typedef $$StudyCardsTableUpdateCompanionBuilder =
    StudyCardsCompanion Function({
      Value<int> id,
      Value<String> poemKey,
      Value<int> state,
      Value<int?> step,
      Value<double?> stability,
      Value<double?> difficulty,
      Value<int> dueMillis,
      Value<int?> lastReviewMillis,
    });

final class $$StudyCardsTableReferences
    extends BaseReferences<_$StudyDatabase, $StudyCardsTable, StudyCard> {
  $$StudyCardsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$StudyReviewLogsTable, List<StudyReviewLog>>
  _studyReviewLogsRefsTable(_$StudyDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.studyReviewLogs,
        aliasName: $_aliasNameGenerator(
          db.studyCards.id,
          db.studyReviewLogs.cardId,
        ),
      );

  $$StudyReviewLogsTableProcessedTableManager get studyReviewLogsRefs {
    final manager = $$StudyReviewLogsTableTableManager(
      $_db,
      $_db.studyReviewLogs,
    ).filter((f) => f.cardId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _studyReviewLogsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$StudyCardsTableFilterComposer
    extends Composer<_$StudyDatabase, $StudyCardsTable> {
  $$StudyCardsTableFilterComposer({
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

  ColumnFilters<String> get poemKey => $composableBuilder(
    column: $table.poemKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get step => $composableBuilder(
    column: $table.step,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get stability => $composableBuilder(
    column: $table.stability,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueMillis => $composableBuilder(
    column: $table.dueMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastReviewMillis => $composableBuilder(
    column: $table.lastReviewMillis,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> studyReviewLogsRefs(
    Expression<bool> Function($$StudyReviewLogsTableFilterComposer f) f,
  ) {
    final $$StudyReviewLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.studyReviewLogs,
      getReferencedColumn: (t) => t.cardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudyReviewLogsTableFilterComposer(
            $db: $db,
            $table: $db.studyReviewLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StudyCardsTableOrderingComposer
    extends Composer<_$StudyDatabase, $StudyCardsTable> {
  $$StudyCardsTableOrderingComposer({
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

  ColumnOrderings<String> get poemKey => $composableBuilder(
    column: $table.poemKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get step => $composableBuilder(
    column: $table.step,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get stability => $composableBuilder(
    column: $table.stability,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueMillis => $composableBuilder(
    column: $table.dueMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastReviewMillis => $composableBuilder(
    column: $table.lastReviewMillis,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StudyCardsTableAnnotationComposer
    extends Composer<_$StudyDatabase, $StudyCardsTable> {
  $$StudyCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get poemKey =>
      $composableBuilder(column: $table.poemKey, builder: (column) => column);

  GeneratedColumn<int> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get step =>
      $composableBuilder(column: $table.step, builder: (column) => column);

  GeneratedColumn<double> get stability =>
      $composableBuilder(column: $table.stability, builder: (column) => column);

  GeneratedColumn<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dueMillis =>
      $composableBuilder(column: $table.dueMillis, builder: (column) => column);

  GeneratedColumn<int> get lastReviewMillis => $composableBuilder(
    column: $table.lastReviewMillis,
    builder: (column) => column,
  );

  Expression<T> studyReviewLogsRefs<T extends Object>(
    Expression<T> Function($$StudyReviewLogsTableAnnotationComposer a) f,
  ) {
    final $$StudyReviewLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.studyReviewLogs,
      getReferencedColumn: (t) => t.cardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudyReviewLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.studyReviewLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StudyCardsTableTableManager
    extends
        RootTableManager<
          _$StudyDatabase,
          $StudyCardsTable,
          StudyCard,
          $$StudyCardsTableFilterComposer,
          $$StudyCardsTableOrderingComposer,
          $$StudyCardsTableAnnotationComposer,
          $$StudyCardsTableCreateCompanionBuilder,
          $$StudyCardsTableUpdateCompanionBuilder,
          (StudyCard, $$StudyCardsTableReferences),
          StudyCard,
          PrefetchHooks Function({bool studyReviewLogsRefs})
        > {
  $$StudyCardsTableTableManager(_$StudyDatabase db, $StudyCardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StudyCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StudyCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StudyCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> poemKey = const Value.absent(),
                Value<int> state = const Value.absent(),
                Value<int?> step = const Value.absent(),
                Value<double?> stability = const Value.absent(),
                Value<double?> difficulty = const Value.absent(),
                Value<int> dueMillis = const Value.absent(),
                Value<int?> lastReviewMillis = const Value.absent(),
              }) => StudyCardsCompanion(
                id: id,
                poemKey: poemKey,
                state: state,
                step: step,
                stability: stability,
                difficulty: difficulty,
                dueMillis: dueMillis,
                lastReviewMillis: lastReviewMillis,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String poemKey,
                required int state,
                Value<int?> step = const Value.absent(),
                Value<double?> stability = const Value.absent(),
                Value<double?> difficulty = const Value.absent(),
                required int dueMillis,
                Value<int?> lastReviewMillis = const Value.absent(),
              }) => StudyCardsCompanion.insert(
                id: id,
                poemKey: poemKey,
                state: state,
                step: step,
                stability: stability,
                difficulty: difficulty,
                dueMillis: dueMillis,
                lastReviewMillis: lastReviewMillis,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$StudyCardsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({studyReviewLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (studyReviewLogsRefs) db.studyReviewLogs,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (studyReviewLogsRefs)
                    await $_getPrefetchedData<
                      StudyCard,
                      $StudyCardsTable,
                      StudyReviewLog
                    >(
                      currentTable: table,
                      referencedTable: $$StudyCardsTableReferences
                          ._studyReviewLogsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$StudyCardsTableReferences(
                            db,
                            table,
                            p0,
                          ).studyReviewLogsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.cardId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$StudyCardsTableProcessedTableManager =
    ProcessedTableManager<
      _$StudyDatabase,
      $StudyCardsTable,
      StudyCard,
      $$StudyCardsTableFilterComposer,
      $$StudyCardsTableOrderingComposer,
      $$StudyCardsTableAnnotationComposer,
      $$StudyCardsTableCreateCompanionBuilder,
      $$StudyCardsTableUpdateCompanionBuilder,
      (StudyCard, $$StudyCardsTableReferences),
      StudyCard,
      PrefetchHooks Function({bool studyReviewLogsRefs})
    >;
typedef $$StudyReviewLogsTableCreateCompanionBuilder =
    StudyReviewLogsCompanion Function({
      Value<int> id,
      required int cardId,
      required int rating,
      required int reviewMillis,
      Value<int?> reviewDurationMillis,
    });
typedef $$StudyReviewLogsTableUpdateCompanionBuilder =
    StudyReviewLogsCompanion Function({
      Value<int> id,
      Value<int> cardId,
      Value<int> rating,
      Value<int> reviewMillis,
      Value<int?> reviewDurationMillis,
    });

final class $$StudyReviewLogsTableReferences
    extends
        BaseReferences<_$StudyDatabase, $StudyReviewLogsTable, StudyReviewLog> {
  $$StudyReviewLogsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $StudyCardsTable _cardIdTable(_$StudyDatabase db) =>
      db.studyCards.createAlias(
        $_aliasNameGenerator(db.studyReviewLogs.cardId, db.studyCards.id),
      );

  $$StudyCardsTableProcessedTableManager get cardId {
    final $_column = $_itemColumn<int>('card_id')!;

    final manager = $$StudyCardsTableTableManager(
      $_db,
      $_db.studyCards,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StudyReviewLogsTableFilterComposer
    extends Composer<_$StudyDatabase, $StudyReviewLogsTable> {
  $$StudyReviewLogsTableFilterComposer({
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

  ColumnFilters<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewMillis => $composableBuilder(
    column: $table.reviewMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewDurationMillis => $composableBuilder(
    column: $table.reviewDurationMillis,
    builder: (column) => ColumnFilters(column),
  );

  $$StudyCardsTableFilterComposer get cardId {
    final $$StudyCardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.studyCards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudyCardsTableFilterComposer(
            $db: $db,
            $table: $db.studyCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StudyReviewLogsTableOrderingComposer
    extends Composer<_$StudyDatabase, $StudyReviewLogsTable> {
  $$StudyReviewLogsTableOrderingComposer({
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

  ColumnOrderings<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewMillis => $composableBuilder(
    column: $table.reviewMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewDurationMillis => $composableBuilder(
    column: $table.reviewDurationMillis,
    builder: (column) => ColumnOrderings(column),
  );

  $$StudyCardsTableOrderingComposer get cardId {
    final $$StudyCardsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.studyCards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudyCardsTableOrderingComposer(
            $db: $db,
            $table: $db.studyCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StudyReviewLogsTableAnnotationComposer
    extends Composer<_$StudyDatabase, $StudyReviewLogsTable> {
  $$StudyReviewLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<int> get reviewMillis => $composableBuilder(
    column: $table.reviewMillis,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reviewDurationMillis => $composableBuilder(
    column: $table.reviewDurationMillis,
    builder: (column) => column,
  );

  $$StudyCardsTableAnnotationComposer get cardId {
    final $$StudyCardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.studyCards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudyCardsTableAnnotationComposer(
            $db: $db,
            $table: $db.studyCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StudyReviewLogsTableTableManager
    extends
        RootTableManager<
          _$StudyDatabase,
          $StudyReviewLogsTable,
          StudyReviewLog,
          $$StudyReviewLogsTableFilterComposer,
          $$StudyReviewLogsTableOrderingComposer,
          $$StudyReviewLogsTableAnnotationComposer,
          $$StudyReviewLogsTableCreateCompanionBuilder,
          $$StudyReviewLogsTableUpdateCompanionBuilder,
          (StudyReviewLog, $$StudyReviewLogsTableReferences),
          StudyReviewLog,
          PrefetchHooks Function({bool cardId})
        > {
  $$StudyReviewLogsTableTableManager(
    _$StudyDatabase db,
    $StudyReviewLogsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StudyReviewLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StudyReviewLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StudyReviewLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> cardId = const Value.absent(),
                Value<int> rating = const Value.absent(),
                Value<int> reviewMillis = const Value.absent(),
                Value<int?> reviewDurationMillis = const Value.absent(),
              }) => StudyReviewLogsCompanion(
                id: id,
                cardId: cardId,
                rating: rating,
                reviewMillis: reviewMillis,
                reviewDurationMillis: reviewDurationMillis,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int cardId,
                required int rating,
                required int reviewMillis,
                Value<int?> reviewDurationMillis = const Value.absent(),
              }) => StudyReviewLogsCompanion.insert(
                id: id,
                cardId: cardId,
                rating: rating,
                reviewMillis: reviewMillis,
                reviewDurationMillis: reviewDurationMillis,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$StudyReviewLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cardId = false}) {
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
                    if (cardId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.cardId,
                                referencedTable:
                                    $$StudyReviewLogsTableReferences
                                        ._cardIdTable(db),
                                referencedColumn:
                                    $$StudyReviewLogsTableReferences
                                        ._cardIdTable(db)
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

typedef $$StudyReviewLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$StudyDatabase,
      $StudyReviewLogsTable,
      StudyReviewLog,
      $$StudyReviewLogsTableFilterComposer,
      $$StudyReviewLogsTableOrderingComposer,
      $$StudyReviewLogsTableAnnotationComposer,
      $$StudyReviewLogsTableCreateCompanionBuilder,
      $$StudyReviewLogsTableUpdateCompanionBuilder,
      (StudyReviewLog, $$StudyReviewLogsTableReferences),
      StudyReviewLog,
      PrefetchHooks Function({bool cardId})
    >;

class $StudyDatabaseManager {
  final _$StudyDatabase _db;
  $StudyDatabaseManager(this._db);
  $$StudyCardsTableTableManager get studyCards =>
      $$StudyCardsTableTableManager(_db, _db.studyCards);
  $$StudyReviewLogsTableTableManager get studyReviewLogs =>
      $$StudyReviewLogsTableTableManager(_db, _db.studyReviewLogs);
}
