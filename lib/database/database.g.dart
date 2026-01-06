// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ScoresTable extends Scores with TableInfo<$ScoresTable, ScoreEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _composerMeta = const VerificationMeta(
    'composer',
  );
  @override
  late final GeneratedColumn<String> composer = GeneratedColumn<String>(
    'composer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bpmMeta = const VerificationMeta('bpm');
  @override
  late final GeneratedColumn<int> bpm = GeneratedColumn<int>(
    'bpm',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(120),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    composer,
    bpm,
    createdAt,
    version,
    syncStatus,
    serverId,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scores';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScoreEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('composer')) {
      context.handle(
        _composerMeta,
        composer.isAcceptableOrUnknown(data['composer']!, _composerMeta),
      );
    } else if (isInserting) {
      context.missing(_composerMeta);
    }
    if (data.containsKey('bpm')) {
      context.handle(
        _bpmMeta,
        bpm.isAcceptableOrUnknown(data['bpm']!, _bpmMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScoreEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScoreEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      composer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}composer'],
      )!,
      bpm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bpm'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $ScoresTable createAlias(String alias) {
    return $ScoresTable(attachedDatabase, alias);
  }
}

class ScoreEntity extends DataClass implements Insertable<ScoreEntity> {
  final String id;
  final String title;
  final String composer;
  final int bpm;
  final DateTime createdAt;
  final int version;
  final String syncStatus;
  final int? serverId;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  const ScoreEntity({
    required this.id,
    required this.title,
    required this.composer,
    required this.bpm,
    required this.createdAt,
    required this.version,
    required this.syncStatus,
    this.serverId,
    this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['composer'] = Variable<String>(composer);
    map['bpm'] = Variable<int>(bpm);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['version'] = Variable<int>(version);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  ScoresCompanion toCompanion(bool nullToAbsent) {
    return ScoresCompanion(
      id: Value(id),
      title: Value(title),
      composer: Value(composer),
      bpm: Value(bpm),
      createdAt: Value(createdAt),
      version: Value(version),
      syncStatus: Value(syncStatus),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory ScoreEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScoreEntity(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      composer: serializer.fromJson<String>(json['composer']),
      bpm: serializer.fromJson<int>(json['bpm']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      version: serializer.fromJson<int>(json['version']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'composer': serializer.toJson<String>(composer),
      'bpm': serializer.toJson<int>(bpm),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'version': serializer.toJson<int>(version),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'serverId': serializer.toJson<int?>(serverId),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  ScoreEntity copyWith({
    String? id,
    String? title,
    String? composer,
    int? bpm,
    DateTime? createdAt,
    int? version,
    String? syncStatus,
    Value<int?> serverId = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => ScoreEntity(
    id: id ?? this.id,
    title: title ?? this.title,
    composer: composer ?? this.composer,
    bpm: bpm ?? this.bpm,
    createdAt: createdAt ?? this.createdAt,
    version: version ?? this.version,
    syncStatus: syncStatus ?? this.syncStatus,
    serverId: serverId.present ? serverId.value : this.serverId,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  ScoreEntity copyWithCompanion(ScoresCompanion data) {
    return ScoreEntity(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      composer: data.composer.present ? data.composer.value : this.composer,
      bpm: data.bpm.present ? data.bpm.value : this.bpm,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      version: data.version.present ? data.version.value : this.version,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScoreEntity(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('composer: $composer, ')
          ..write('bpm: $bpm, ')
          ..write('createdAt: $createdAt, ')
          ..write('version: $version, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverId: $serverId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    composer,
    bpm,
    createdAt,
    version,
    syncStatus,
    serverId,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScoreEntity &&
          other.id == this.id &&
          other.title == this.title &&
          other.composer == this.composer &&
          other.bpm == this.bpm &&
          other.createdAt == this.createdAt &&
          other.version == this.version &&
          other.syncStatus == this.syncStatus &&
          other.serverId == this.serverId &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class ScoresCompanion extends UpdateCompanion<ScoreEntity> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> composer;
  final Value<int> bpm;
  final Value<DateTime> createdAt;
  final Value<int> version;
  final Value<String> syncStatus;
  final Value<int?> serverId;
  final Value<DateTime?> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const ScoresCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.composer = const Value.absent(),
    this.bpm = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.version = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.serverId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScoresCompanion.insert({
    required String id,
    required String title,
    required String composer,
    this.bpm = const Value.absent(),
    required DateTime createdAt,
    this.version = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.serverId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       composer = Value(composer),
       createdAt = Value(createdAt);
  static Insertable<ScoreEntity> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? composer,
    Expression<int>? bpm,
    Expression<DateTime>? createdAt,
    Expression<int>? version,
    Expression<String>? syncStatus,
    Expression<int>? serverId,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (composer != null) 'composer': composer,
      if (bpm != null) 'bpm': bpm,
      if (createdAt != null) 'created_at': createdAt,
      if (version != null) 'version': version,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (serverId != null) 'server_id': serverId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScoresCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? composer,
    Value<int>? bpm,
    Value<DateTime>? createdAt,
    Value<int>? version,
    Value<String>? syncStatus,
    Value<int?>? serverId,
    Value<DateTime?>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return ScoresCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      composer: composer ?? this.composer,
      bpm: bpm ?? this.bpm,
      createdAt: createdAt ?? this.createdAt,
      version: version ?? this.version,
      syncStatus: syncStatus ?? this.syncStatus,
      serverId: serverId ?? this.serverId,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (composer.present) {
      map['composer'] = Variable<String>(composer.value);
    }
    if (bpm.present) {
      map['bpm'] = Variable<int>(bpm.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScoresCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('composer: $composer, ')
          ..write('bpm: $bpm, ')
          ..write('createdAt: $createdAt, ')
          ..write('version: $version, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverId: $serverId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InstrumentScoresTable extends InstrumentScores
    with TableInfo<$InstrumentScoresTable, InstrumentScoreEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InstrumentScoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreIdMeta = const VerificationMeta(
    'scoreId',
  );
  @override
  late final GeneratedColumn<String> scoreId = GeneratedColumn<String>(
    'score_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES scores (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _instrumentTypeMeta = const VerificationMeta(
    'instrumentType',
  );
  @override
  late final GeneratedColumn<String> instrumentType = GeneratedColumn<String>(
    'instrument_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customInstrumentMeta = const VerificationMeta(
    'customInstrument',
  );
  @override
  late final GeneratedColumn<String> customInstrument = GeneratedColumn<String>(
    'custom_instrument',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pdfPathMeta = const VerificationMeta(
    'pdfPath',
  );
  @override
  late final GeneratedColumn<String> pdfPath = GeneratedColumn<String>(
    'pdf_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbnailMeta = const VerificationMeta(
    'thumbnail',
  );
  @override
  late final GeneratedColumn<String> thumbnail = GeneratedColumn<String>(
    'thumbnail',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pdfSyncStatusMeta = const VerificationMeta(
    'pdfSyncStatus',
  );
  @override
  late final GeneratedColumn<String> pdfSyncStatus = GeneratedColumn<String>(
    'pdf_sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _pdfHashMeta = const VerificationMeta(
    'pdfHash',
  );
  @override
  late final GeneratedColumn<String> pdfHash = GeneratedColumn<String>(
    'pdf_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _annotationsJsonMeta = const VerificationMeta(
    'annotationsJson',
  );
  @override
  late final GeneratedColumn<String> annotationsJson = GeneratedColumn<String>(
    'annotations_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scoreId,
    instrumentType,
    customInstrument,
    pdfPath,
    thumbnail,
    createdAt,
    orderIndex,
    version,
    syncStatus,
    serverId,
    pdfSyncStatus,
    pdfHash,
    updatedAt,
    deletedAt,
    annotationsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'instrument_scores';
  @override
  VerificationContext validateIntegrity(
    Insertable<InstrumentScoreEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('score_id')) {
      context.handle(
        _scoreIdMeta,
        scoreId.isAcceptableOrUnknown(data['score_id']!, _scoreIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreIdMeta);
    }
    if (data.containsKey('instrument_type')) {
      context.handle(
        _instrumentTypeMeta,
        instrumentType.isAcceptableOrUnknown(
          data['instrument_type']!,
          _instrumentTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_instrumentTypeMeta);
    }
    if (data.containsKey('custom_instrument')) {
      context.handle(
        _customInstrumentMeta,
        customInstrument.isAcceptableOrUnknown(
          data['custom_instrument']!,
          _customInstrumentMeta,
        ),
      );
    }
    if (data.containsKey('pdf_path')) {
      context.handle(
        _pdfPathMeta,
        pdfPath.isAcceptableOrUnknown(data['pdf_path']!, _pdfPathMeta),
      );
    }
    if (data.containsKey('thumbnail')) {
      context.handle(
        _thumbnailMeta,
        thumbnail.isAcceptableOrUnknown(data['thumbnail']!, _thumbnailMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('pdf_sync_status')) {
      context.handle(
        _pdfSyncStatusMeta,
        pdfSyncStatus.isAcceptableOrUnknown(
          data['pdf_sync_status']!,
          _pdfSyncStatusMeta,
        ),
      );
    }
    if (data.containsKey('pdf_hash')) {
      context.handle(
        _pdfHashMeta,
        pdfHash.isAcceptableOrUnknown(data['pdf_hash']!, _pdfHashMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('annotations_json')) {
      context.handle(
        _annotationsJsonMeta,
        annotationsJson.isAcceptableOrUnknown(
          data['annotations_json']!,
          _annotationsJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InstrumentScoreEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InstrumentScoreEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      scoreId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}score_id'],
      )!,
      instrumentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instrument_type'],
      )!,
      customInstrument: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_instrument'],
      ),
      pdfPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pdf_path'],
      ),
      thumbnail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      pdfSyncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pdf_sync_status'],
      )!,
      pdfHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pdf_hash'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      annotationsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}annotations_json'],
      )!,
    );
  }

  @override
  $InstrumentScoresTable createAlias(String alias) {
    return $InstrumentScoresTable(attachedDatabase, alias);
  }
}

class InstrumentScoreEntity extends DataClass
    implements Insertable<InstrumentScoreEntity> {
  final String id;
  final String scoreId;
  final String instrumentType;
  final String? customInstrument;
  final String? pdfPath;
  final String? thumbnail;
  final DateTime createdAt;
  final int orderIndex;
  final int version;
  final String syncStatus;
  final int? serverId;
  final String pdfSyncStatus;
  final String? pdfHash;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String annotationsJson;
  const InstrumentScoreEntity({
    required this.id,
    required this.scoreId,
    required this.instrumentType,
    this.customInstrument,
    this.pdfPath,
    this.thumbnail,
    required this.createdAt,
    required this.orderIndex,
    required this.version,
    required this.syncStatus,
    this.serverId,
    required this.pdfSyncStatus,
    this.pdfHash,
    this.updatedAt,
    this.deletedAt,
    required this.annotationsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['score_id'] = Variable<String>(scoreId);
    map['instrument_type'] = Variable<String>(instrumentType);
    if (!nullToAbsent || customInstrument != null) {
      map['custom_instrument'] = Variable<String>(customInstrument);
    }
    if (!nullToAbsent || pdfPath != null) {
      map['pdf_path'] = Variable<String>(pdfPath);
    }
    if (!nullToAbsent || thumbnail != null) {
      map['thumbnail'] = Variable<String>(thumbnail);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['order_index'] = Variable<int>(orderIndex);
    map['version'] = Variable<int>(version);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['pdf_sync_status'] = Variable<String>(pdfSyncStatus);
    if (!nullToAbsent || pdfHash != null) {
      map['pdf_hash'] = Variable<String>(pdfHash);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['annotations_json'] = Variable<String>(annotationsJson);
    return map;
  }

  InstrumentScoresCompanion toCompanion(bool nullToAbsent) {
    return InstrumentScoresCompanion(
      id: Value(id),
      scoreId: Value(scoreId),
      instrumentType: Value(instrumentType),
      customInstrument: customInstrument == null && nullToAbsent
          ? const Value.absent()
          : Value(customInstrument),
      pdfPath: pdfPath == null && nullToAbsent
          ? const Value.absent()
          : Value(pdfPath),
      thumbnail: thumbnail == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnail),
      createdAt: Value(createdAt),
      orderIndex: Value(orderIndex),
      version: Value(version),
      syncStatus: Value(syncStatus),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      pdfSyncStatus: Value(pdfSyncStatus),
      pdfHash: pdfHash == null && nullToAbsent
          ? const Value.absent()
          : Value(pdfHash),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      annotationsJson: Value(annotationsJson),
    );
  }

  factory InstrumentScoreEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InstrumentScoreEntity(
      id: serializer.fromJson<String>(json['id']),
      scoreId: serializer.fromJson<String>(json['scoreId']),
      instrumentType: serializer.fromJson<String>(json['instrumentType']),
      customInstrument: serializer.fromJson<String?>(json['customInstrument']),
      pdfPath: serializer.fromJson<String?>(json['pdfPath']),
      thumbnail: serializer.fromJson<String?>(json['thumbnail']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      version: serializer.fromJson<int>(json['version']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      pdfSyncStatus: serializer.fromJson<String>(json['pdfSyncStatus']),
      pdfHash: serializer.fromJson<String?>(json['pdfHash']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      annotationsJson: serializer.fromJson<String>(json['annotationsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'scoreId': serializer.toJson<String>(scoreId),
      'instrumentType': serializer.toJson<String>(instrumentType),
      'customInstrument': serializer.toJson<String?>(customInstrument),
      'pdfPath': serializer.toJson<String?>(pdfPath),
      'thumbnail': serializer.toJson<String?>(thumbnail),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'version': serializer.toJson<int>(version),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'serverId': serializer.toJson<int?>(serverId),
      'pdfSyncStatus': serializer.toJson<String>(pdfSyncStatus),
      'pdfHash': serializer.toJson<String?>(pdfHash),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'annotationsJson': serializer.toJson<String>(annotationsJson),
    };
  }

  InstrumentScoreEntity copyWith({
    String? id,
    String? scoreId,
    String? instrumentType,
    Value<String?> customInstrument = const Value.absent(),
    Value<String?> pdfPath = const Value.absent(),
    Value<String?> thumbnail = const Value.absent(),
    DateTime? createdAt,
    int? orderIndex,
    int? version,
    String? syncStatus,
    Value<int?> serverId = const Value.absent(),
    String? pdfSyncStatus,
    Value<String?> pdfHash = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
    String? annotationsJson,
  }) => InstrumentScoreEntity(
    id: id ?? this.id,
    scoreId: scoreId ?? this.scoreId,
    instrumentType: instrumentType ?? this.instrumentType,
    customInstrument: customInstrument.present
        ? customInstrument.value
        : this.customInstrument,
    pdfPath: pdfPath.present ? pdfPath.value : this.pdfPath,
    thumbnail: thumbnail.present ? thumbnail.value : this.thumbnail,
    createdAt: createdAt ?? this.createdAt,
    orderIndex: orderIndex ?? this.orderIndex,
    version: version ?? this.version,
    syncStatus: syncStatus ?? this.syncStatus,
    serverId: serverId.present ? serverId.value : this.serverId,
    pdfSyncStatus: pdfSyncStatus ?? this.pdfSyncStatus,
    pdfHash: pdfHash.present ? pdfHash.value : this.pdfHash,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    annotationsJson: annotationsJson ?? this.annotationsJson,
  );
  InstrumentScoreEntity copyWithCompanion(InstrumentScoresCompanion data) {
    return InstrumentScoreEntity(
      id: data.id.present ? data.id.value : this.id,
      scoreId: data.scoreId.present ? data.scoreId.value : this.scoreId,
      instrumentType: data.instrumentType.present
          ? data.instrumentType.value
          : this.instrumentType,
      customInstrument: data.customInstrument.present
          ? data.customInstrument.value
          : this.customInstrument,
      pdfPath: data.pdfPath.present ? data.pdfPath.value : this.pdfPath,
      thumbnail: data.thumbnail.present ? data.thumbnail.value : this.thumbnail,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      version: data.version.present ? data.version.value : this.version,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      pdfSyncStatus: data.pdfSyncStatus.present
          ? data.pdfSyncStatus.value
          : this.pdfSyncStatus,
      pdfHash: data.pdfHash.present ? data.pdfHash.value : this.pdfHash,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      annotationsJson: data.annotationsJson.present
          ? data.annotationsJson.value
          : this.annotationsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InstrumentScoreEntity(')
          ..write('id: $id, ')
          ..write('scoreId: $scoreId, ')
          ..write('instrumentType: $instrumentType, ')
          ..write('customInstrument: $customInstrument, ')
          ..write('pdfPath: $pdfPath, ')
          ..write('thumbnail: $thumbnail, ')
          ..write('createdAt: $createdAt, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('version: $version, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverId: $serverId, ')
          ..write('pdfSyncStatus: $pdfSyncStatus, ')
          ..write('pdfHash: $pdfHash, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('annotationsJson: $annotationsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    scoreId,
    instrumentType,
    customInstrument,
    pdfPath,
    thumbnail,
    createdAt,
    orderIndex,
    version,
    syncStatus,
    serverId,
    pdfSyncStatus,
    pdfHash,
    updatedAt,
    deletedAt,
    annotationsJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InstrumentScoreEntity &&
          other.id == this.id &&
          other.scoreId == this.scoreId &&
          other.instrumentType == this.instrumentType &&
          other.customInstrument == this.customInstrument &&
          other.pdfPath == this.pdfPath &&
          other.thumbnail == this.thumbnail &&
          other.createdAt == this.createdAt &&
          other.orderIndex == this.orderIndex &&
          other.version == this.version &&
          other.syncStatus == this.syncStatus &&
          other.serverId == this.serverId &&
          other.pdfSyncStatus == this.pdfSyncStatus &&
          other.pdfHash == this.pdfHash &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.annotationsJson == this.annotationsJson);
}

class InstrumentScoresCompanion extends UpdateCompanion<InstrumentScoreEntity> {
  final Value<String> id;
  final Value<String> scoreId;
  final Value<String> instrumentType;
  final Value<String?> customInstrument;
  final Value<String?> pdfPath;
  final Value<String?> thumbnail;
  final Value<DateTime> createdAt;
  final Value<int> orderIndex;
  final Value<int> version;
  final Value<String> syncStatus;
  final Value<int?> serverId;
  final Value<String> pdfSyncStatus;
  final Value<String?> pdfHash;
  final Value<DateTime?> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> annotationsJson;
  final Value<int> rowid;
  const InstrumentScoresCompanion({
    this.id = const Value.absent(),
    this.scoreId = const Value.absent(),
    this.instrumentType = const Value.absent(),
    this.customInstrument = const Value.absent(),
    this.pdfPath = const Value.absent(),
    this.thumbnail = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.version = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.serverId = const Value.absent(),
    this.pdfSyncStatus = const Value.absent(),
    this.pdfHash = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.annotationsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InstrumentScoresCompanion.insert({
    required String id,
    required String scoreId,
    required String instrumentType,
    this.customInstrument = const Value.absent(),
    this.pdfPath = const Value.absent(),
    this.thumbnail = const Value.absent(),
    required DateTime createdAt,
    this.orderIndex = const Value.absent(),
    this.version = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.serverId = const Value.absent(),
    this.pdfSyncStatus = const Value.absent(),
    this.pdfHash = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.annotationsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       scoreId = Value(scoreId),
       instrumentType = Value(instrumentType),
       createdAt = Value(createdAt);
  static Insertable<InstrumentScoreEntity> custom({
    Expression<String>? id,
    Expression<String>? scoreId,
    Expression<String>? instrumentType,
    Expression<String>? customInstrument,
    Expression<String>? pdfPath,
    Expression<String>? thumbnail,
    Expression<DateTime>? createdAt,
    Expression<int>? orderIndex,
    Expression<int>? version,
    Expression<String>? syncStatus,
    Expression<int>? serverId,
    Expression<String>? pdfSyncStatus,
    Expression<String>? pdfHash,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? annotationsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scoreId != null) 'score_id': scoreId,
      if (instrumentType != null) 'instrument_type': instrumentType,
      if (customInstrument != null) 'custom_instrument': customInstrument,
      if (pdfPath != null) 'pdf_path': pdfPath,
      if (thumbnail != null) 'thumbnail': thumbnail,
      if (createdAt != null) 'created_at': createdAt,
      if (orderIndex != null) 'order_index': orderIndex,
      if (version != null) 'version': version,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (serverId != null) 'server_id': serverId,
      if (pdfSyncStatus != null) 'pdf_sync_status': pdfSyncStatus,
      if (pdfHash != null) 'pdf_hash': pdfHash,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (annotationsJson != null) 'annotations_json': annotationsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InstrumentScoresCompanion copyWith({
    Value<String>? id,
    Value<String>? scoreId,
    Value<String>? instrumentType,
    Value<String?>? customInstrument,
    Value<String?>? pdfPath,
    Value<String?>? thumbnail,
    Value<DateTime>? createdAt,
    Value<int>? orderIndex,
    Value<int>? version,
    Value<String>? syncStatus,
    Value<int?>? serverId,
    Value<String>? pdfSyncStatus,
    Value<String?>? pdfHash,
    Value<DateTime?>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? annotationsJson,
    Value<int>? rowid,
  }) {
    return InstrumentScoresCompanion(
      id: id ?? this.id,
      scoreId: scoreId ?? this.scoreId,
      instrumentType: instrumentType ?? this.instrumentType,
      customInstrument: customInstrument ?? this.customInstrument,
      pdfPath: pdfPath ?? this.pdfPath,
      thumbnail: thumbnail ?? this.thumbnail,
      createdAt: createdAt ?? this.createdAt,
      orderIndex: orderIndex ?? this.orderIndex,
      version: version ?? this.version,
      syncStatus: syncStatus ?? this.syncStatus,
      serverId: serverId ?? this.serverId,
      pdfSyncStatus: pdfSyncStatus ?? this.pdfSyncStatus,
      pdfHash: pdfHash ?? this.pdfHash,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      annotationsJson: annotationsJson ?? this.annotationsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (scoreId.present) {
      map['score_id'] = Variable<String>(scoreId.value);
    }
    if (instrumentType.present) {
      map['instrument_type'] = Variable<String>(instrumentType.value);
    }
    if (customInstrument.present) {
      map['custom_instrument'] = Variable<String>(customInstrument.value);
    }
    if (pdfPath.present) {
      map['pdf_path'] = Variable<String>(pdfPath.value);
    }
    if (thumbnail.present) {
      map['thumbnail'] = Variable<String>(thumbnail.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (pdfSyncStatus.present) {
      map['pdf_sync_status'] = Variable<String>(pdfSyncStatus.value);
    }
    if (pdfHash.present) {
      map['pdf_hash'] = Variable<String>(pdfHash.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (annotationsJson.present) {
      map['annotations_json'] = Variable<String>(annotationsJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InstrumentScoresCompanion(')
          ..write('id: $id, ')
          ..write('scoreId: $scoreId, ')
          ..write('instrumentType: $instrumentType, ')
          ..write('customInstrument: $customInstrument, ')
          ..write('pdfPath: $pdfPath, ')
          ..write('thumbnail: $thumbnail, ')
          ..write('createdAt: $createdAt, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('version: $version, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverId: $serverId, ')
          ..write('pdfSyncStatus: $pdfSyncStatus, ')
          ..write('pdfHash: $pdfHash, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('annotationsJson: $annotationsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AnnotationsTable extends Annotations
    with TableInfo<$AnnotationsTable, AnnotationEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnnotationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _instrumentScoreIdMeta = const VerificationMeta(
    'instrumentScoreId',
  );
  @override
  late final GeneratedColumn<String> instrumentScoreId =
      GeneratedColumn<String>(
        'instrument_score_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES instrument_scores (id) ON DELETE CASCADE',
        ),
      );
  static const VerificationMeta _annotationTypeMeta = const VerificationMeta(
    'annotationType',
  );
  @override
  late final GeneratedColumn<String> annotationType = GeneratedColumn<String>(
    'annotation_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _strokeWidthMeta = const VerificationMeta(
    'strokeWidth',
  );
  @override
  late final GeneratedColumn<double> strokeWidth = GeneratedColumn<double>(
    'stroke_width',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pointsMeta = const VerificationMeta('points');
  @override
  late final GeneratedColumn<String> points = GeneratedColumn<String>(
    'points',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _textContentMeta = const VerificationMeta(
    'textContent',
  );
  @override
  late final GeneratedColumn<String> textContent = GeneratedColumn<String>(
    'text_content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _posXMeta = const VerificationMeta('posX');
  @override
  late final GeneratedColumn<double> posX = GeneratedColumn<double>(
    'pos_x',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _posYMeta = const VerificationMeta('posY');
  @override
  late final GeneratedColumn<double> posY = GeneratedColumn<double>(
    'pos_y',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pageNumberMeta = const VerificationMeta(
    'pageNumber',
  );
  @override
  late final GeneratedColumn<int> pageNumber = GeneratedColumn<int>(
    'page_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    instrumentScoreId,
    annotationType,
    color,
    strokeWidth,
    points,
    textContent,
    posX,
    posY,
    pageNumber,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'annotations';
  @override
  VerificationContext validateIntegrity(
    Insertable<AnnotationEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('instrument_score_id')) {
      context.handle(
        _instrumentScoreIdMeta,
        instrumentScoreId.isAcceptableOrUnknown(
          data['instrument_score_id']!,
          _instrumentScoreIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_instrumentScoreIdMeta);
    }
    if (data.containsKey('annotation_type')) {
      context.handle(
        _annotationTypeMeta,
        annotationType.isAcceptableOrUnknown(
          data['annotation_type']!,
          _annotationTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_annotationTypeMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('stroke_width')) {
      context.handle(
        _strokeWidthMeta,
        strokeWidth.isAcceptableOrUnknown(
          data['stroke_width']!,
          _strokeWidthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_strokeWidthMeta);
    }
    if (data.containsKey('points')) {
      context.handle(
        _pointsMeta,
        points.isAcceptableOrUnknown(data['points']!, _pointsMeta),
      );
    }
    if (data.containsKey('text_content')) {
      context.handle(
        _textContentMeta,
        textContent.isAcceptableOrUnknown(
          data['text_content']!,
          _textContentMeta,
        ),
      );
    }
    if (data.containsKey('pos_x')) {
      context.handle(
        _posXMeta,
        posX.isAcceptableOrUnknown(data['pos_x']!, _posXMeta),
      );
    }
    if (data.containsKey('pos_y')) {
      context.handle(
        _posYMeta,
        posY.isAcceptableOrUnknown(data['pos_y']!, _posYMeta),
      );
    }
    if (data.containsKey('page_number')) {
      context.handle(
        _pageNumberMeta,
        pageNumber.isAcceptableOrUnknown(data['page_number']!, _pageNumberMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AnnotationEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnnotationEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      instrumentScoreId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instrument_score_id'],
      )!,
      annotationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}annotation_type'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      )!,
      strokeWidth: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stroke_width'],
      )!,
      points: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}points'],
      ),
      textContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_content'],
      ),
      posX: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pos_x'],
      ),
      posY: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pos_y'],
      ),
      pageNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_number'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $AnnotationsTable createAlias(String alias) {
    return $AnnotationsTable(attachedDatabase, alias);
  }
}

class AnnotationEntity extends DataClass
    implements Insertable<AnnotationEntity> {
  final String id;
  final String instrumentScoreId;
  final String annotationType;
  final String color;
  final double strokeWidth;
  final String? points;
  final String? textContent;
  final double? posX;
  final double? posY;
  final int pageNumber;
  final DateTime? updatedAt;
  const AnnotationEntity({
    required this.id,
    required this.instrumentScoreId,
    required this.annotationType,
    required this.color,
    required this.strokeWidth,
    this.points,
    this.textContent,
    this.posX,
    this.posY,
    required this.pageNumber,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['instrument_score_id'] = Variable<String>(instrumentScoreId);
    map['annotation_type'] = Variable<String>(annotationType);
    map['color'] = Variable<String>(color);
    map['stroke_width'] = Variable<double>(strokeWidth);
    if (!nullToAbsent || points != null) {
      map['points'] = Variable<String>(points);
    }
    if (!nullToAbsent || textContent != null) {
      map['text_content'] = Variable<String>(textContent);
    }
    if (!nullToAbsent || posX != null) {
      map['pos_x'] = Variable<double>(posX);
    }
    if (!nullToAbsent || posY != null) {
      map['pos_y'] = Variable<double>(posY);
    }
    map['page_number'] = Variable<int>(pageNumber);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  AnnotationsCompanion toCompanion(bool nullToAbsent) {
    return AnnotationsCompanion(
      id: Value(id),
      instrumentScoreId: Value(instrumentScoreId),
      annotationType: Value(annotationType),
      color: Value(color),
      strokeWidth: Value(strokeWidth),
      points: points == null && nullToAbsent
          ? const Value.absent()
          : Value(points),
      textContent: textContent == null && nullToAbsent
          ? const Value.absent()
          : Value(textContent),
      posX: posX == null && nullToAbsent ? const Value.absent() : Value(posX),
      posY: posY == null && nullToAbsent ? const Value.absent() : Value(posY),
      pageNumber: Value(pageNumber),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory AnnotationEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnnotationEntity(
      id: serializer.fromJson<String>(json['id']),
      instrumentScoreId: serializer.fromJson<String>(json['instrumentScoreId']),
      annotationType: serializer.fromJson<String>(json['annotationType']),
      color: serializer.fromJson<String>(json['color']),
      strokeWidth: serializer.fromJson<double>(json['strokeWidth']),
      points: serializer.fromJson<String?>(json['points']),
      textContent: serializer.fromJson<String?>(json['textContent']),
      posX: serializer.fromJson<double?>(json['posX']),
      posY: serializer.fromJson<double?>(json['posY']),
      pageNumber: serializer.fromJson<int>(json['pageNumber']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'instrumentScoreId': serializer.toJson<String>(instrumentScoreId),
      'annotationType': serializer.toJson<String>(annotationType),
      'color': serializer.toJson<String>(color),
      'strokeWidth': serializer.toJson<double>(strokeWidth),
      'points': serializer.toJson<String?>(points),
      'textContent': serializer.toJson<String?>(textContent),
      'posX': serializer.toJson<double?>(posX),
      'posY': serializer.toJson<double?>(posY),
      'pageNumber': serializer.toJson<int>(pageNumber),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  AnnotationEntity copyWith({
    String? id,
    String? instrumentScoreId,
    String? annotationType,
    String? color,
    double? strokeWidth,
    Value<String?> points = const Value.absent(),
    Value<String?> textContent = const Value.absent(),
    Value<double?> posX = const Value.absent(),
    Value<double?> posY = const Value.absent(),
    int? pageNumber,
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => AnnotationEntity(
    id: id ?? this.id,
    instrumentScoreId: instrumentScoreId ?? this.instrumentScoreId,
    annotationType: annotationType ?? this.annotationType,
    color: color ?? this.color,
    strokeWidth: strokeWidth ?? this.strokeWidth,
    points: points.present ? points.value : this.points,
    textContent: textContent.present ? textContent.value : this.textContent,
    posX: posX.present ? posX.value : this.posX,
    posY: posY.present ? posY.value : this.posY,
    pageNumber: pageNumber ?? this.pageNumber,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  AnnotationEntity copyWithCompanion(AnnotationsCompanion data) {
    return AnnotationEntity(
      id: data.id.present ? data.id.value : this.id,
      instrumentScoreId: data.instrumentScoreId.present
          ? data.instrumentScoreId.value
          : this.instrumentScoreId,
      annotationType: data.annotationType.present
          ? data.annotationType.value
          : this.annotationType,
      color: data.color.present ? data.color.value : this.color,
      strokeWidth: data.strokeWidth.present
          ? data.strokeWidth.value
          : this.strokeWidth,
      points: data.points.present ? data.points.value : this.points,
      textContent: data.textContent.present
          ? data.textContent.value
          : this.textContent,
      posX: data.posX.present ? data.posX.value : this.posX,
      posY: data.posY.present ? data.posY.value : this.posY,
      pageNumber: data.pageNumber.present
          ? data.pageNumber.value
          : this.pageNumber,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnnotationEntity(')
          ..write('id: $id, ')
          ..write('instrumentScoreId: $instrumentScoreId, ')
          ..write('annotationType: $annotationType, ')
          ..write('color: $color, ')
          ..write('strokeWidth: $strokeWidth, ')
          ..write('points: $points, ')
          ..write('textContent: $textContent, ')
          ..write('posX: $posX, ')
          ..write('posY: $posY, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    instrumentScoreId,
    annotationType,
    color,
    strokeWidth,
    points,
    textContent,
    posX,
    posY,
    pageNumber,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnnotationEntity &&
          other.id == this.id &&
          other.instrumentScoreId == this.instrumentScoreId &&
          other.annotationType == this.annotationType &&
          other.color == this.color &&
          other.strokeWidth == this.strokeWidth &&
          other.points == this.points &&
          other.textContent == this.textContent &&
          other.posX == this.posX &&
          other.posY == this.posY &&
          other.pageNumber == this.pageNumber &&
          other.updatedAt == this.updatedAt);
}

class AnnotationsCompanion extends UpdateCompanion<AnnotationEntity> {
  final Value<String> id;
  final Value<String> instrumentScoreId;
  final Value<String> annotationType;
  final Value<String> color;
  final Value<double> strokeWidth;
  final Value<String?> points;
  final Value<String?> textContent;
  final Value<double?> posX;
  final Value<double?> posY;
  final Value<int> pageNumber;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const AnnotationsCompanion({
    this.id = const Value.absent(),
    this.instrumentScoreId = const Value.absent(),
    this.annotationType = const Value.absent(),
    this.color = const Value.absent(),
    this.strokeWidth = const Value.absent(),
    this.points = const Value.absent(),
    this.textContent = const Value.absent(),
    this.posX = const Value.absent(),
    this.posY = const Value.absent(),
    this.pageNumber = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AnnotationsCompanion.insert({
    required String id,
    required String instrumentScoreId,
    required String annotationType,
    required String color,
    required double strokeWidth,
    this.points = const Value.absent(),
    this.textContent = const Value.absent(),
    this.posX = const Value.absent(),
    this.posY = const Value.absent(),
    this.pageNumber = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       instrumentScoreId = Value(instrumentScoreId),
       annotationType = Value(annotationType),
       color = Value(color),
       strokeWidth = Value(strokeWidth);
  static Insertable<AnnotationEntity> custom({
    Expression<String>? id,
    Expression<String>? instrumentScoreId,
    Expression<String>? annotationType,
    Expression<String>? color,
    Expression<double>? strokeWidth,
    Expression<String>? points,
    Expression<String>? textContent,
    Expression<double>? posX,
    Expression<double>? posY,
    Expression<int>? pageNumber,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (instrumentScoreId != null) 'instrument_score_id': instrumentScoreId,
      if (annotationType != null) 'annotation_type': annotationType,
      if (color != null) 'color': color,
      if (strokeWidth != null) 'stroke_width': strokeWidth,
      if (points != null) 'points': points,
      if (textContent != null) 'text_content': textContent,
      if (posX != null) 'pos_x': posX,
      if (posY != null) 'pos_y': posY,
      if (pageNumber != null) 'page_number': pageNumber,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AnnotationsCompanion copyWith({
    Value<String>? id,
    Value<String>? instrumentScoreId,
    Value<String>? annotationType,
    Value<String>? color,
    Value<double>? strokeWidth,
    Value<String?>? points,
    Value<String?>? textContent,
    Value<double?>? posX,
    Value<double?>? posY,
    Value<int>? pageNumber,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return AnnotationsCompanion(
      id: id ?? this.id,
      instrumentScoreId: instrumentScoreId ?? this.instrumentScoreId,
      annotationType: annotationType ?? this.annotationType,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      points: points ?? this.points,
      textContent: textContent ?? this.textContent,
      posX: posX ?? this.posX,
      posY: posY ?? this.posY,
      pageNumber: pageNumber ?? this.pageNumber,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (instrumentScoreId.present) {
      map['instrument_score_id'] = Variable<String>(instrumentScoreId.value);
    }
    if (annotationType.present) {
      map['annotation_type'] = Variable<String>(annotationType.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (strokeWidth.present) {
      map['stroke_width'] = Variable<double>(strokeWidth.value);
    }
    if (points.present) {
      map['points'] = Variable<String>(points.value);
    }
    if (textContent.present) {
      map['text_content'] = Variable<String>(textContent.value);
    }
    if (posX.present) {
      map['pos_x'] = Variable<double>(posX.value);
    }
    if (posY.present) {
      map['pos_y'] = Variable<double>(posY.value);
    }
    if (pageNumber.present) {
      map['page_number'] = Variable<int>(pageNumber.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnnotationsCompanion(')
          ..write('id: $id, ')
          ..write('instrumentScoreId: $instrumentScoreId, ')
          ..write('annotationType: $annotationType, ')
          ..write('color: $color, ')
          ..write('strokeWidth: $strokeWidth, ')
          ..write('points: $points, ')
          ..write('textContent: $textContent, ')
          ..write('posX: $posX, ')
          ..write('posY: $posY, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SetlistsTable extends Setlists
    with TableInfo<$SetlistsTable, SetlistEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SetlistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    createdAt,
    version,
    syncStatus,
    serverId,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'setlists';
  @override
  VerificationContext validateIntegrity(
    Insertable<SetlistEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SetlistEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SetlistEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $SetlistsTable createAlias(String alias) {
    return $SetlistsTable(attachedDatabase, alias);
  }
}

class SetlistEntity extends DataClass implements Insertable<SetlistEntity> {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final int version;
  final String syncStatus;
  final int? serverId;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  const SetlistEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.version,
    required this.syncStatus,
    this.serverId,
    this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['version'] = Variable<int>(version);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  SetlistsCompanion toCompanion(bool nullToAbsent) {
    return SetlistsCompanion(
      id: Value(id),
      name: Value(name),
      description: Value(description),
      createdAt: Value(createdAt),
      version: Value(version),
      syncStatus: Value(syncStatus),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory SetlistEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SetlistEntity(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      version: serializer.fromJson<int>(json['version']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'version': serializer.toJson<int>(version),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'serverId': serializer.toJson<int?>(serverId),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  SetlistEntity copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    int? version,
    String? syncStatus,
    Value<int?> serverId = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => SetlistEntity(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    createdAt: createdAt ?? this.createdAt,
    version: version ?? this.version,
    syncStatus: syncStatus ?? this.syncStatus,
    serverId: serverId.present ? serverId.value : this.serverId,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  SetlistEntity copyWithCompanion(SetlistsCompanion data) {
    return SetlistEntity(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      version: data.version.present ? data.version.value : this.version,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SetlistEntity(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('version: $version, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverId: $serverId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    createdAt,
    version,
    syncStatus,
    serverId,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SetlistEntity &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.createdAt == this.createdAt &&
          other.version == this.version &&
          other.syncStatus == this.syncStatus &&
          other.serverId == this.serverId &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class SetlistsCompanion extends UpdateCompanion<SetlistEntity> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> description;
  final Value<DateTime> createdAt;
  final Value<int> version;
  final Value<String> syncStatus;
  final Value<int?> serverId;
  final Value<DateTime?> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const SetlistsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.version = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.serverId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SetlistsCompanion.insert({
    required String id,
    required String name,
    required String description,
    required DateTime createdAt,
    this.version = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.serverId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       description = Value(description),
       createdAt = Value(createdAt);
  static Insertable<SetlistEntity> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<DateTime>? createdAt,
    Expression<int>? version,
    Expression<String>? syncStatus,
    Expression<int>? serverId,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (version != null) 'version': version,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (serverId != null) 'server_id': serverId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SetlistsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? description,
    Value<DateTime>? createdAt,
    Value<int>? version,
    Value<String>? syncStatus,
    Value<int?>? serverId,
    Value<DateTime?>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return SetlistsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      version: version ?? this.version,
      syncStatus: syncStatus ?? this.syncStatus,
      serverId: serverId ?? this.serverId,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SetlistsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('version: $version, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverId: $serverId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SetlistScoresTable extends SetlistScores
    with TableInfo<$SetlistScoresTable, SetlistScoreEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SetlistScoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _setlistIdMeta = const VerificationMeta(
    'setlistId',
  );
  @override
  late final GeneratedColumn<String> setlistId = GeneratedColumn<String>(
    'setlist_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES setlists (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _scoreIdMeta = const VerificationMeta(
    'scoreId',
  );
  @override
  late final GeneratedColumn<String> scoreId = GeneratedColumn<String>(
    'score_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES scores (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    setlistId,
    scoreId,
    orderIndex,
    version,
    syncStatus,
    serverId,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'setlist_scores';
  @override
  VerificationContext validateIntegrity(
    Insertable<SetlistScoreEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('setlist_id')) {
      context.handle(
        _setlistIdMeta,
        setlistId.isAcceptableOrUnknown(data['setlist_id']!, _setlistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_setlistIdMeta);
    }
    if (data.containsKey('score_id')) {
      context.handle(
        _scoreIdMeta,
        scoreId.isAcceptableOrUnknown(data['score_id']!, _scoreIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreIdMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {setlistId, scoreId};
  @override
  SetlistScoreEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SetlistScoreEntity(
      setlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}setlist_id'],
      )!,
      scoreId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}score_id'],
      )!,
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $SetlistScoresTable createAlias(String alias) {
    return $SetlistScoresTable(attachedDatabase, alias);
  }
}

class SetlistScoreEntity extends DataClass
    implements Insertable<SetlistScoreEntity> {
  final String setlistId;
  final String scoreId;
  final int orderIndex;
  final int version;
  final String syncStatus;
  final int? serverId;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  const SetlistScoreEntity({
    required this.setlistId,
    required this.scoreId,
    required this.orderIndex,
    required this.version,
    required this.syncStatus,
    this.serverId,
    this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['setlist_id'] = Variable<String>(setlistId);
    map['score_id'] = Variable<String>(scoreId);
    map['order_index'] = Variable<int>(orderIndex);
    map['version'] = Variable<int>(version);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  SetlistScoresCompanion toCompanion(bool nullToAbsent) {
    return SetlistScoresCompanion(
      setlistId: Value(setlistId),
      scoreId: Value(scoreId),
      orderIndex: Value(orderIndex),
      version: Value(version),
      syncStatus: Value(syncStatus),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory SetlistScoreEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SetlistScoreEntity(
      setlistId: serializer.fromJson<String>(json['setlistId']),
      scoreId: serializer.fromJson<String>(json['scoreId']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      version: serializer.fromJson<int>(json['version']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'setlistId': serializer.toJson<String>(setlistId),
      'scoreId': serializer.toJson<String>(scoreId),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'version': serializer.toJson<int>(version),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'serverId': serializer.toJson<int?>(serverId),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  SetlistScoreEntity copyWith({
    String? setlistId,
    String? scoreId,
    int? orderIndex,
    int? version,
    String? syncStatus,
    Value<int?> serverId = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => SetlistScoreEntity(
    setlistId: setlistId ?? this.setlistId,
    scoreId: scoreId ?? this.scoreId,
    orderIndex: orderIndex ?? this.orderIndex,
    version: version ?? this.version,
    syncStatus: syncStatus ?? this.syncStatus,
    serverId: serverId.present ? serverId.value : this.serverId,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  SetlistScoreEntity copyWithCompanion(SetlistScoresCompanion data) {
    return SetlistScoreEntity(
      setlistId: data.setlistId.present ? data.setlistId.value : this.setlistId,
      scoreId: data.scoreId.present ? data.scoreId.value : this.scoreId,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      version: data.version.present ? data.version.value : this.version,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SetlistScoreEntity(')
          ..write('setlistId: $setlistId, ')
          ..write('scoreId: $scoreId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('version: $version, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverId: $serverId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    setlistId,
    scoreId,
    orderIndex,
    version,
    syncStatus,
    serverId,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SetlistScoreEntity &&
          other.setlistId == this.setlistId &&
          other.scoreId == this.scoreId &&
          other.orderIndex == this.orderIndex &&
          other.version == this.version &&
          other.syncStatus == this.syncStatus &&
          other.serverId == this.serverId &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class SetlistScoresCompanion extends UpdateCompanion<SetlistScoreEntity> {
  final Value<String> setlistId;
  final Value<String> scoreId;
  final Value<int> orderIndex;
  final Value<int> version;
  final Value<String> syncStatus;
  final Value<int?> serverId;
  final Value<DateTime?> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const SetlistScoresCompanion({
    this.setlistId = const Value.absent(),
    this.scoreId = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.version = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.serverId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SetlistScoresCompanion.insert({
    required String setlistId,
    required String scoreId,
    required int orderIndex,
    this.version = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.serverId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : setlistId = Value(setlistId),
       scoreId = Value(scoreId),
       orderIndex = Value(orderIndex);
  static Insertable<SetlistScoreEntity> custom({
    Expression<String>? setlistId,
    Expression<String>? scoreId,
    Expression<int>? orderIndex,
    Expression<int>? version,
    Expression<String>? syncStatus,
    Expression<int>? serverId,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (setlistId != null) 'setlist_id': setlistId,
      if (scoreId != null) 'score_id': scoreId,
      if (orderIndex != null) 'order_index': orderIndex,
      if (version != null) 'version': version,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (serverId != null) 'server_id': serverId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SetlistScoresCompanion copyWith({
    Value<String>? setlistId,
    Value<String>? scoreId,
    Value<int>? orderIndex,
    Value<int>? version,
    Value<String>? syncStatus,
    Value<int?>? serverId,
    Value<DateTime?>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return SetlistScoresCompanion(
      setlistId: setlistId ?? this.setlistId,
      scoreId: scoreId ?? this.scoreId,
      orderIndex: orderIndex ?? this.orderIndex,
      version: version ?? this.version,
      syncStatus: syncStatus ?? this.syncStatus,
      serverId: serverId ?? this.serverId,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (setlistId.present) {
      map['setlist_id'] = Variable<String>(setlistId.value);
    }
    if (scoreId.present) {
      map['score_id'] = Variable<String>(scoreId.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SetlistScoresCompanion(')
          ..write('setlistId: $setlistId, ')
          ..write('scoreId: $scoreId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('version: $version, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverId: $serverId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppStateTable extends AppState
    with TableInfo<$AppStateTable, AppStateEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppStateTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'app_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppStateEntity> instance, {
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
  AppStateEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppStateEntity(
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
  $AppStateTable createAlias(String alias) {
    return $AppStateTable(attachedDatabase, alias);
  }
}

class AppStateEntity extends DataClass implements Insertable<AppStateEntity> {
  final String key;
  final String value;
  const AppStateEntity({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppStateCompanion toCompanion(bool nullToAbsent) {
    return AppStateCompanion(key: Value(key), value: Value(value));
  }

  factory AppStateEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppStateEntity(
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

  AppStateEntity copyWith({String? key, String? value}) =>
      AppStateEntity(key: key ?? this.key, value: value ?? this.value);
  AppStateEntity copyWithCompanion(AppStateCompanion data) {
    return AppStateEntity(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppStateEntity(')
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
      (other is AppStateEntity &&
          other.key == this.key &&
          other.value == this.value);
}

class AppStateCompanion extends UpdateCompanion<AppStateEntity> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppStateCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppStateCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppStateEntity> custom({
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

  AppStateCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppStateCompanion(
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
    return (StringBuffer('AppStateCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStateTable extends SyncState
    with TableInfo<$SyncStateTable, SyncStateEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStateEntity> instance, {
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncStateEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateEntity(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $SyncStateTable createAlias(String alias) {
    return $SyncStateTable(attachedDatabase, alias);
  }
}

class SyncStateEntity extends DataClass implements Insertable<SyncStateEntity> {
  final String key;
  final String value;
  final DateTime? updatedAt;
  const SyncStateEntity({
    required this.key,
    required this.value,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  SyncStateCompanion toCompanion(bool nullToAbsent) {
    return SyncStateCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory SyncStateEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateEntity(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  SyncStateEntity copyWith({
    String? key,
    String? value,
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => SyncStateEntity(
    key: key ?? this.key,
    value: value ?? this.value,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  SyncStateEntity copyWithCompanion(SyncStateCompanion data) {
    return SyncStateEntity(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateEntity(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateEntity &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class SyncStateCompanion extends UpdateCompanion<SyncStateEntity> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const SyncStateCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStateCompanion.insert({
    required String key,
    required String value,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SyncStateEntity> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStateCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return SyncStateCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TeamsTable extends Teams with TableInfo<$TeamsTable, TeamEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TeamsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    name,
    description,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'teams';
  @override
  VerificationContext validateIntegrity(
    Insertable<TeamEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serverIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TeamEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TeamEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $TeamsTable createAlias(String alias) {
    return $TeamsTable(attachedDatabase, alias);
  }
}

class TeamEntity extends DataClass implements Insertable<TeamEntity> {
  final String id;
  final int serverId;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime? updatedAt;
  const TeamEntity({
    required this.id,
    required this.serverId,
    required this.name,
    this.description,
    required this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['server_id'] = Variable<int>(serverId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  TeamsCompanion toCompanion(bool nullToAbsent) {
    return TeamsCompanion(
      id: Value(id),
      serverId: Value(serverId),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory TeamEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TeamEntity(
      id: serializer.fromJson<String>(json['id']),
      serverId: serializer.fromJson<int>(json['serverId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'serverId': serializer.toJson<int>(serverId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  TeamEntity copyWith({
    String? id,
    int? serverId,
    String? name,
    Value<String?> description = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => TeamEntity(
    id: id ?? this.id,
    serverId: serverId ?? this.serverId,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  TeamEntity copyWithCompanion(TeamsCompanion data) {
    return TeamEntity(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TeamEntity(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, serverId, name, description, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TeamEntity &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.name == this.name &&
          other.description == this.description &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TeamsCompanion extends UpdateCompanion<TeamEntity> {
  final Value<String> id;
  final Value<int> serverId;
  final Value<String> name;
  final Value<String?> description;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const TeamsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TeamsCompanion.insert({
    required String id,
    required int serverId,
    required String name,
    this.description = const Value.absent(),
    required DateTime createdAt,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       serverId = Value(serverId),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<TeamEntity> custom({
    Expression<String>? id,
    Expression<int>? serverId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TeamsCompanion copyWith({
    Value<String>? id,
    Value<int>? serverId,
    Value<String>? name,
    Value<String?>? description,
    Value<DateTime>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return TeamsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TeamsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TeamMembersTable extends TeamMembers
    with TableInfo<$TeamMembersTable, TeamMemberEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TeamMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _teamIdMeta = const VerificationMeta('teamId');
  @override
  late final GeneratedColumn<String> teamId = GeneratedColumn<String>(
    'team_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES teams (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('member'),
  );
  static const VerificationMeta _joinedAtMeta = const VerificationMeta(
    'joinedAt',
  );
  @override
  late final GeneratedColumn<DateTime> joinedAt = GeneratedColumn<DateTime>(
    'joined_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    teamId,
    userId,
    username,
    displayName,
    role,
    joinedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'team_members';
  @override
  VerificationContext validateIntegrity(
    Insertable<TeamMemberEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('team_id')) {
      context.handle(
        _teamIdMeta,
        teamId.isAcceptableOrUnknown(data['team_id']!, _teamIdMeta),
      );
    } else if (isInserting) {
      context.missing(_teamIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    }
    if (data.containsKey('joined_at')) {
      context.handle(
        _joinedAtMeta,
        joinedAt.isAcceptableOrUnknown(data['joined_at']!, _joinedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_joinedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TeamMemberEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TeamMemberEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      teamId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}team_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      ),
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      joinedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}joined_at'],
      )!,
    );
  }

  @override
  $TeamMembersTable createAlias(String alias) {
    return $TeamMembersTable(attachedDatabase, alias);
  }
}

class TeamMemberEntity extends DataClass
    implements Insertable<TeamMemberEntity> {
  final String id;
  final String teamId;
  final int userId;
  final String username;
  final String? displayName;
  final String role;
  final DateTime joinedAt;
  const TeamMemberEntity({
    required this.id,
    required this.teamId,
    required this.userId,
    required this.username,
    this.displayName,
    required this.role,
    required this.joinedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['team_id'] = Variable<String>(teamId);
    map['user_id'] = Variable<int>(userId);
    map['username'] = Variable<String>(username);
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    map['role'] = Variable<String>(role);
    map['joined_at'] = Variable<DateTime>(joinedAt);
    return map;
  }

  TeamMembersCompanion toCompanion(bool nullToAbsent) {
    return TeamMembersCompanion(
      id: Value(id),
      teamId: Value(teamId),
      userId: Value(userId),
      username: Value(username),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      role: Value(role),
      joinedAt: Value(joinedAt),
    );
  }

  factory TeamMemberEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TeamMemberEntity(
      id: serializer.fromJson<String>(json['id']),
      teamId: serializer.fromJson<String>(json['teamId']),
      userId: serializer.fromJson<int>(json['userId']),
      username: serializer.fromJson<String>(json['username']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      role: serializer.fromJson<String>(json['role']),
      joinedAt: serializer.fromJson<DateTime>(json['joinedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'teamId': serializer.toJson<String>(teamId),
      'userId': serializer.toJson<int>(userId),
      'username': serializer.toJson<String>(username),
      'displayName': serializer.toJson<String?>(displayName),
      'role': serializer.toJson<String>(role),
      'joinedAt': serializer.toJson<DateTime>(joinedAt),
    };
  }

  TeamMemberEntity copyWith({
    String? id,
    String? teamId,
    int? userId,
    String? username,
    Value<String?> displayName = const Value.absent(),
    String? role,
    DateTime? joinedAt,
  }) => TeamMemberEntity(
    id: id ?? this.id,
    teamId: teamId ?? this.teamId,
    userId: userId ?? this.userId,
    username: username ?? this.username,
    displayName: displayName.present ? displayName.value : this.displayName,
    role: role ?? this.role,
    joinedAt: joinedAt ?? this.joinedAt,
  );
  TeamMemberEntity copyWithCompanion(TeamMembersCompanion data) {
    return TeamMemberEntity(
      id: data.id.present ? data.id.value : this.id,
      teamId: data.teamId.present ? data.teamId.value : this.teamId,
      userId: data.userId.present ? data.userId.value : this.userId,
      username: data.username.present ? data.username.value : this.username,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      role: data.role.present ? data.role.value : this.role,
      joinedAt: data.joinedAt.present ? data.joinedAt.value : this.joinedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TeamMemberEntity(')
          ..write('id: $id, ')
          ..write('teamId: $teamId, ')
          ..write('userId: $userId, ')
          ..write('username: $username, ')
          ..write('displayName: $displayName, ')
          ..write('role: $role, ')
          ..write('joinedAt: $joinedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, teamId, userId, username, displayName, role, joinedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TeamMemberEntity &&
          other.id == this.id &&
          other.teamId == this.teamId &&
          other.userId == this.userId &&
          other.username == this.username &&
          other.displayName == this.displayName &&
          other.role == this.role &&
          other.joinedAt == this.joinedAt);
}

class TeamMembersCompanion extends UpdateCompanion<TeamMemberEntity> {
  final Value<String> id;
  final Value<String> teamId;
  final Value<int> userId;
  final Value<String> username;
  final Value<String?> displayName;
  final Value<String> role;
  final Value<DateTime> joinedAt;
  final Value<int> rowid;
  const TeamMembersCompanion({
    this.id = const Value.absent(),
    this.teamId = const Value.absent(),
    this.userId = const Value.absent(),
    this.username = const Value.absent(),
    this.displayName = const Value.absent(),
    this.role = const Value.absent(),
    this.joinedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TeamMembersCompanion.insert({
    required String id,
    required String teamId,
    required int userId,
    required String username,
    this.displayName = const Value.absent(),
    this.role = const Value.absent(),
    required DateTime joinedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       teamId = Value(teamId),
       userId = Value(userId),
       username = Value(username),
       joinedAt = Value(joinedAt);
  static Insertable<TeamMemberEntity> custom({
    Expression<String>? id,
    Expression<String>? teamId,
    Expression<int>? userId,
    Expression<String>? username,
    Expression<String>? displayName,
    Expression<String>? role,
    Expression<DateTime>? joinedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (teamId != null) 'team_id': teamId,
      if (userId != null) 'user_id': userId,
      if (username != null) 'username': username,
      if (displayName != null) 'display_name': displayName,
      if (role != null) 'role': role,
      if (joinedAt != null) 'joined_at': joinedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TeamMembersCompanion copyWith({
    Value<String>? id,
    Value<String>? teamId,
    Value<int>? userId,
    Value<String>? username,
    Value<String?>? displayName,
    Value<String>? role,
    Value<DateTime>? joinedAt,
    Value<int>? rowid,
  }) {
    return TeamMembersCompanion(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (teamId.present) {
      map['team_id'] = Variable<String>(teamId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (joinedAt.present) {
      map['joined_at'] = Variable<DateTime>(joinedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TeamMembersCompanion(')
          ..write('id: $id, ')
          ..write('teamId: $teamId, ')
          ..write('userId: $userId, ')
          ..write('username: $username, ')
          ..write('displayName: $displayName, ')
          ..write('role: $role, ')
          ..write('joinedAt: $joinedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TeamScoresTable extends TeamScores
    with TableInfo<$TeamScoresTable, TeamScoreEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TeamScoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _teamIdMeta = const VerificationMeta('teamId');
  @override
  late final GeneratedColumn<int> teamId = GeneratedColumn<int>(
    'team_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  static const VerificationMeta _composerMeta = const VerificationMeta(
    'composer',
  );
  @override
  late final GeneratedColumn<String> composer = GeneratedColumn<String>(
    'composer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bpmMeta = const VerificationMeta('bpm');
  @override
  late final GeneratedColumn<int> bpm = GeneratedColumn<int>(
    'bpm',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(120),
  );
  static const VerificationMeta _createdByIdMeta = const VerificationMeta(
    'createdById',
  );
  @override
  late final GeneratedColumn<int> createdById = GeneratedColumn<int>(
    'created_by_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceScoreIdMeta = const VerificationMeta(
    'sourceScoreId',
  );
  @override
  late final GeneratedColumn<int> sourceScoreId = GeneratedColumn<int>(
    'source_score_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    teamId,
    title,
    composer,
    bpm,
    createdById,
    sourceScoreId,
    version,
    syncStatus,
    serverId,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'team_scores';
  @override
  VerificationContext validateIntegrity(
    Insertable<TeamScoreEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('team_id')) {
      context.handle(
        _teamIdMeta,
        teamId.isAcceptableOrUnknown(data['team_id']!, _teamIdMeta),
      );
    } else if (isInserting) {
      context.missing(_teamIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('composer')) {
      context.handle(
        _composerMeta,
        composer.isAcceptableOrUnknown(data['composer']!, _composerMeta),
      );
    } else if (isInserting) {
      context.missing(_composerMeta);
    }
    if (data.containsKey('bpm')) {
      context.handle(
        _bpmMeta,
        bpm.isAcceptableOrUnknown(data['bpm']!, _bpmMeta),
      );
    }
    if (data.containsKey('created_by_id')) {
      context.handle(
        _createdByIdMeta,
        createdById.isAcceptableOrUnknown(
          data['created_by_id']!,
          _createdByIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdByIdMeta);
    }
    if (data.containsKey('source_score_id')) {
      context.handle(
        _sourceScoreIdMeta,
        sourceScoreId.isAcceptableOrUnknown(
          data['source_score_id']!,
          _sourceScoreIdMeta,
        ),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TeamScoreEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TeamScoreEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      teamId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}team_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      composer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}composer'],
      )!,
      bpm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bpm'],
      )!,
      createdById: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_by_id'],
      )!,
      sourceScoreId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_score_id'],
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $TeamScoresTable createAlias(String alias) {
    return $TeamScoresTable(attachedDatabase, alias);
  }
}

class TeamScoreEntity extends DataClass implements Insertable<TeamScoreEntity> {
  final String id;
  final int teamId;
  final String title;
  final String composer;
  final int bpm;
  final int createdById;
  final int? sourceScoreId;
  final int version;
  final String syncStatus;
  final int? serverId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  const TeamScoreEntity({
    required this.id,
    required this.teamId,
    required this.title,
    required this.composer,
    required this.bpm,
    required this.createdById,
    this.sourceScoreId,
    required this.version,
    required this.syncStatus,
    this.serverId,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['team_id'] = Variable<int>(teamId);
    map['title'] = Variable<String>(title);
    map['composer'] = Variable<String>(composer);
    map['bpm'] = Variable<int>(bpm);
    map['created_by_id'] = Variable<int>(createdById);
    if (!nullToAbsent || sourceScoreId != null) {
      map['source_score_id'] = Variable<int>(sourceScoreId);
    }
    map['version'] = Variable<int>(version);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  TeamScoresCompanion toCompanion(bool nullToAbsent) {
    return TeamScoresCompanion(
      id: Value(id),
      teamId: Value(teamId),
      title: Value(title),
      composer: Value(composer),
      bpm: Value(bpm),
      createdById: Value(createdById),
      sourceScoreId: sourceScoreId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceScoreId),
      version: Value(version),
      syncStatus: Value(syncStatus),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory TeamScoreEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TeamScoreEntity(
      id: serializer.fromJson<String>(json['id']),
      teamId: serializer.fromJson<int>(json['teamId']),
      title: serializer.fromJson<String>(json['title']),
      composer: serializer.fromJson<String>(json['composer']),
      bpm: serializer.fromJson<int>(json['bpm']),
      createdById: serializer.fromJson<int>(json['createdById']),
      sourceScoreId: serializer.fromJson<int?>(json['sourceScoreId']),
      version: serializer.fromJson<int>(json['version']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'teamId': serializer.toJson<int>(teamId),
      'title': serializer.toJson<String>(title),
      'composer': serializer.toJson<String>(composer),
      'bpm': serializer.toJson<int>(bpm),
      'createdById': serializer.toJson<int>(createdById),
      'sourceScoreId': serializer.toJson<int?>(sourceScoreId),
      'version': serializer.toJson<int>(version),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'serverId': serializer.toJson<int?>(serverId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  TeamScoreEntity copyWith({
    String? id,
    int? teamId,
    String? title,
    String? composer,
    int? bpm,
    int? createdById,
    Value<int?> sourceScoreId = const Value.absent(),
    int? version,
    String? syncStatus,
    Value<int?> serverId = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> updatedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => TeamScoreEntity(
    id: id ?? this.id,
    teamId: teamId ?? this.teamId,
    title: title ?? this.title,
    composer: composer ?? this.composer,
    bpm: bpm ?? this.bpm,
    createdById: createdById ?? this.createdById,
    sourceScoreId: sourceScoreId.present
        ? sourceScoreId.value
        : this.sourceScoreId,
    version: version ?? this.version,
    syncStatus: syncStatus ?? this.syncStatus,
    serverId: serverId.present ? serverId.value : this.serverId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  TeamScoreEntity copyWithCompanion(TeamScoresCompanion data) {
    return TeamScoreEntity(
      id: data.id.present ? data.id.value : this.id,
      teamId: data.teamId.present ? data.teamId.value : this.teamId,
      title: data.title.present ? data.title.value : this.title,
      composer: data.composer.present ? data.composer.value : this.composer,
      bpm: data.bpm.present ? data.bpm.value : this.bpm,
      createdById: data.createdById.present
          ? data.createdById.value
          : this.createdById,
      sourceScoreId: data.sourceScoreId.present
          ? data.sourceScoreId.value
          : this.sourceScoreId,
      version: data.version.present ? data.version.value : this.version,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TeamScoreEntity(')
          ..write('id: $id, ')
          ..write('teamId: $teamId, ')
          ..write('title: $title, ')
          ..write('composer: $composer, ')
          ..write('bpm: $bpm, ')
          ..write('createdById: $createdById, ')
          ..write('sourceScoreId: $sourceScoreId, ')
          ..write('version: $version, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverId: $serverId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    teamId,
    title,
    composer,
    bpm,
    createdById,
    sourceScoreId,
    version,
    syncStatus,
    serverId,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TeamScoreEntity &&
          other.id == this.id &&
          other.teamId == this.teamId &&
          other.title == this.title &&
          other.composer == this.composer &&
          other.bpm == this.bpm &&
          other.createdById == this.createdById &&
          other.sourceScoreId == this.sourceScoreId &&
          other.version == this.version &&
          other.syncStatus == this.syncStatus &&
          other.serverId == this.serverId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class TeamScoresCompanion extends UpdateCompanion<TeamScoreEntity> {
  final Value<String> id;
  final Value<int> teamId;
  final Value<String> title;
  final Value<String> composer;
  final Value<int> bpm;
  final Value<int> createdById;
  final Value<int?> sourceScoreId;
  final Value<int> version;
  final Value<String> syncStatus;
  final Value<int?> serverId;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const TeamScoresCompanion({
    this.id = const Value.absent(),
    this.teamId = const Value.absent(),
    this.title = const Value.absent(),
    this.composer = const Value.absent(),
    this.bpm = const Value.absent(),
    this.createdById = const Value.absent(),
    this.sourceScoreId = const Value.absent(),
    this.version = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.serverId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TeamScoresCompanion.insert({
    required String id,
    required int teamId,
    required String title,
    required String composer,
    this.bpm = const Value.absent(),
    required int createdById,
    this.sourceScoreId = const Value.absent(),
    this.version = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.serverId = const Value.absent(),
    required DateTime createdAt,
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       teamId = Value(teamId),
       title = Value(title),
       composer = Value(composer),
       createdById = Value(createdById),
       createdAt = Value(createdAt);
  static Insertable<TeamScoreEntity> custom({
    Expression<String>? id,
    Expression<int>? teamId,
    Expression<String>? title,
    Expression<String>? composer,
    Expression<int>? bpm,
    Expression<int>? createdById,
    Expression<int>? sourceScoreId,
    Expression<int>? version,
    Expression<String>? syncStatus,
    Expression<int>? serverId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (teamId != null) 'team_id': teamId,
      if (title != null) 'title': title,
      if (composer != null) 'composer': composer,
      if (bpm != null) 'bpm': bpm,
      if (createdById != null) 'created_by_id': createdById,
      if (sourceScoreId != null) 'source_score_id': sourceScoreId,
      if (version != null) 'version': version,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (serverId != null) 'server_id': serverId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TeamScoresCompanion copyWith({
    Value<String>? id,
    Value<int>? teamId,
    Value<String>? title,
    Value<String>? composer,
    Value<int>? bpm,
    Value<int>? createdById,
    Value<int?>? sourceScoreId,
    Value<int>? version,
    Value<String>? syncStatus,
    Value<int?>? serverId,
    Value<DateTime>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return TeamScoresCompanion(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      title: title ?? this.title,
      composer: composer ?? this.composer,
      bpm: bpm ?? this.bpm,
      createdById: createdById ?? this.createdById,
      sourceScoreId: sourceScoreId ?? this.sourceScoreId,
      version: version ?? this.version,
      syncStatus: syncStatus ?? this.syncStatus,
      serverId: serverId ?? this.serverId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (teamId.present) {
      map['team_id'] = Variable<int>(teamId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (composer.present) {
      map['composer'] = Variable<String>(composer.value);
    }
    if (bpm.present) {
      map['bpm'] = Variable<int>(bpm.value);
    }
    if (createdById.present) {
      map['created_by_id'] = Variable<int>(createdById.value);
    }
    if (sourceScoreId.present) {
      map['source_score_id'] = Variable<int>(sourceScoreId.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TeamScoresCompanion(')
          ..write('id: $id, ')
          ..write('teamId: $teamId, ')
          ..write('title: $title, ')
          ..write('composer: $composer, ')
          ..write('bpm: $bpm, ')
          ..write('createdById: $createdById, ')
          ..write('sourceScoreId: $sourceScoreId, ')
          ..write('version: $version, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverId: $serverId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TeamInstrumentScoresTable extends TeamInstrumentScores
    with TableInfo<$TeamInstrumentScoresTable, TeamInstrumentScoreEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TeamInstrumentScoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _teamScoreIdMeta = const VerificationMeta(
    'teamScoreId',
  );
  @override
  late final GeneratedColumn<String> teamScoreId = GeneratedColumn<String>(
    'team_score_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES team_scores (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _instrumentTypeMeta = const VerificationMeta(
    'instrumentType',
  );
  @override
  late final GeneratedColumn<String> instrumentType = GeneratedColumn<String>(
    'instrument_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customInstrumentMeta = const VerificationMeta(
    'customInstrument',
  );
  @override
  late final GeneratedColumn<String> customInstrument = GeneratedColumn<String>(
    'custom_instrument',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pdfPathMeta = const VerificationMeta(
    'pdfPath',
  );
  @override
  late final GeneratedColumn<String> pdfPath = GeneratedColumn<String>(
    'pdf_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbnailMeta = const VerificationMeta(
    'thumbnail',
  );
  @override
  late final GeneratedColumn<String> thumbnail = GeneratedColumn<String>(
    'thumbnail',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _pdfHashMeta = const VerificationMeta(
    'pdfHash',
  );
  @override
  late final GeneratedColumn<String> pdfHash = GeneratedColumn<String>(
    'pdf_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pdfSyncStatusMeta = const VerificationMeta(
    'pdfSyncStatus',
  );
  @override
  late final GeneratedColumn<String> pdfSyncStatus = GeneratedColumn<String>(
    'pdf_sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _annotationsJsonMeta = const VerificationMeta(
    'annotationsJson',
  );
  @override
  late final GeneratedColumn<String> annotationsJson = GeneratedColumn<String>(
    'annotations_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _sourceInstrumentScoreIdMeta =
      const VerificationMeta('sourceInstrumentScoreId');
  @override
  late final GeneratedColumn<int> sourceInstrumentScoreId =
      GeneratedColumn<int>(
        'source_instrument_score_id',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    teamScoreId,
    instrumentType,
    customInstrument,
    pdfPath,
    thumbnail,
    orderIndex,
    pdfHash,
    pdfSyncStatus,
    annotationsJson,
    sourceInstrumentScoreId,
    version,
    syncStatus,
    serverId,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'team_instrument_scores';
  @override
  VerificationContext validateIntegrity(
    Insertable<TeamInstrumentScoreEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('team_score_id')) {
      context.handle(
        _teamScoreIdMeta,
        teamScoreId.isAcceptableOrUnknown(
          data['team_score_id']!,
          _teamScoreIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_teamScoreIdMeta);
    }
    if (data.containsKey('instrument_type')) {
      context.handle(
        _instrumentTypeMeta,
        instrumentType.isAcceptableOrUnknown(
          data['instrument_type']!,
          _instrumentTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_instrumentTypeMeta);
    }
    if (data.containsKey('custom_instrument')) {
      context.handle(
        _customInstrumentMeta,
        customInstrument.isAcceptableOrUnknown(
          data['custom_instrument']!,
          _customInstrumentMeta,
        ),
      );
    }
    if (data.containsKey('pdf_path')) {
      context.handle(
        _pdfPathMeta,
        pdfPath.isAcceptableOrUnknown(data['pdf_path']!, _pdfPathMeta),
      );
    }
    if (data.containsKey('thumbnail')) {
      context.handle(
        _thumbnailMeta,
        thumbnail.isAcceptableOrUnknown(data['thumbnail']!, _thumbnailMeta),
      );
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    }
    if (data.containsKey('pdf_hash')) {
      context.handle(
        _pdfHashMeta,
        pdfHash.isAcceptableOrUnknown(data['pdf_hash']!, _pdfHashMeta),
      );
    }
    if (data.containsKey('pdf_sync_status')) {
      context.handle(
        _pdfSyncStatusMeta,
        pdfSyncStatus.isAcceptableOrUnknown(
          data['pdf_sync_status']!,
          _pdfSyncStatusMeta,
        ),
      );
    }
    if (data.containsKey('annotations_json')) {
      context.handle(
        _annotationsJsonMeta,
        annotationsJson.isAcceptableOrUnknown(
          data['annotations_json']!,
          _annotationsJsonMeta,
        ),
      );
    }
    if (data.containsKey('source_instrument_score_id')) {
      context.handle(
        _sourceInstrumentScoreIdMeta,
        sourceInstrumentScoreId.isAcceptableOrUnknown(
          data['source_instrument_score_id']!,
          _sourceInstrumentScoreIdMeta,
        ),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TeamInstrumentScoreEntity map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TeamInstrumentScoreEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      teamScoreId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}team_score_id'],
      )!,
      instrumentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instrument_type'],
      )!,
      customInstrument: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_instrument'],
      ),
      pdfPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pdf_path'],
      ),
      thumbnail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail'],
      ),
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      pdfHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pdf_hash'],
      ),
      pdfSyncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pdf_sync_status'],
      )!,
      annotationsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}annotations_json'],
      )!,
      sourceInstrumentScoreId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_instrument_score_id'],
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $TeamInstrumentScoresTable createAlias(String alias) {
    return $TeamInstrumentScoresTable(attachedDatabase, alias);
  }
}

class TeamInstrumentScoreEntity extends DataClass
    implements Insertable<TeamInstrumentScoreEntity> {
  final String id;
  final String teamScoreId;
  final String instrumentType;
  final String? customInstrument;
  final String? pdfPath;
  final String? thumbnail;
  final int orderIndex;
  final String? pdfHash;
  final String pdfSyncStatus;
  final String annotationsJson;
  final int? sourceInstrumentScoreId;
  final int version;
  final String syncStatus;
  final int? serverId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  const TeamInstrumentScoreEntity({
    required this.id,
    required this.teamScoreId,
    required this.instrumentType,
    this.customInstrument,
    this.pdfPath,
    this.thumbnail,
    required this.orderIndex,
    this.pdfHash,
    required this.pdfSyncStatus,
    required this.annotationsJson,
    this.sourceInstrumentScoreId,
    required this.version,
    required this.syncStatus,
    this.serverId,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['team_score_id'] = Variable<String>(teamScoreId);
    map['instrument_type'] = Variable<String>(instrumentType);
    if (!nullToAbsent || customInstrument != null) {
      map['custom_instrument'] = Variable<String>(customInstrument);
    }
    if (!nullToAbsent || pdfPath != null) {
      map['pdf_path'] = Variable<String>(pdfPath);
    }
    if (!nullToAbsent || thumbnail != null) {
      map['thumbnail'] = Variable<String>(thumbnail);
    }
    map['order_index'] = Variable<int>(orderIndex);
    if (!nullToAbsent || pdfHash != null) {
      map['pdf_hash'] = Variable<String>(pdfHash);
    }
    map['pdf_sync_status'] = Variable<String>(pdfSyncStatus);
    map['annotations_json'] = Variable<String>(annotationsJson);
    if (!nullToAbsent || sourceInstrumentScoreId != null) {
      map['source_instrument_score_id'] = Variable<int>(
        sourceInstrumentScoreId,
      );
    }
    map['version'] = Variable<int>(version);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  TeamInstrumentScoresCompanion toCompanion(bool nullToAbsent) {
    return TeamInstrumentScoresCompanion(
      id: Value(id),
      teamScoreId: Value(teamScoreId),
      instrumentType: Value(instrumentType),
      customInstrument: customInstrument == null && nullToAbsent
          ? const Value.absent()
          : Value(customInstrument),
      pdfPath: pdfPath == null && nullToAbsent
          ? const Value.absent()
          : Value(pdfPath),
      thumbnail: thumbnail == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnail),
      orderIndex: Value(orderIndex),
      pdfHash: pdfHash == null && nullToAbsent
          ? const Value.absent()
          : Value(pdfHash),
      pdfSyncStatus: Value(pdfSyncStatus),
      annotationsJson: Value(annotationsJson),
      sourceInstrumentScoreId: sourceInstrumentScoreId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceInstrumentScoreId),
      version: Value(version),
      syncStatus: Value(syncStatus),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory TeamInstrumentScoreEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TeamInstrumentScoreEntity(
      id: serializer.fromJson<String>(json['id']),
      teamScoreId: serializer.fromJson<String>(json['teamScoreId']),
      instrumentType: serializer.fromJson<String>(json['instrumentType']),
      customInstrument: serializer.fromJson<String?>(json['customInstrument']),
      pdfPath: serializer.fromJson<String?>(json['pdfPath']),
      thumbnail: serializer.fromJson<String?>(json['thumbnail']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      pdfHash: serializer.fromJson<String?>(json['pdfHash']),
      pdfSyncStatus: serializer.fromJson<String>(json['pdfSyncStatus']),
      annotationsJson: serializer.fromJson<String>(json['annotationsJson']),
      sourceInstrumentScoreId: serializer.fromJson<int?>(
        json['sourceInstrumentScoreId'],
      ),
      version: serializer.fromJson<int>(json['version']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'teamScoreId': serializer.toJson<String>(teamScoreId),
      'instrumentType': serializer.toJson<String>(instrumentType),
      'customInstrument': serializer.toJson<String?>(customInstrument),
      'pdfPath': serializer.toJson<String?>(pdfPath),
      'thumbnail': serializer.toJson<String?>(thumbnail),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'pdfHash': serializer.toJson<String?>(pdfHash),
      'pdfSyncStatus': serializer.toJson<String>(pdfSyncStatus),
      'annotationsJson': serializer.toJson<String>(annotationsJson),
      'sourceInstrumentScoreId': serializer.toJson<int?>(
        sourceInstrumentScoreId,
      ),
      'version': serializer.toJson<int>(version),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'serverId': serializer.toJson<int?>(serverId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  TeamInstrumentScoreEntity copyWith({
    String? id,
    String? teamScoreId,
    String? instrumentType,
    Value<String?> customInstrument = const Value.absent(),
    Value<String?> pdfPath = const Value.absent(),
    Value<String?> thumbnail = const Value.absent(),
    int? orderIndex,
    Value<String?> pdfHash = const Value.absent(),
    String? pdfSyncStatus,
    String? annotationsJson,
    Value<int?> sourceInstrumentScoreId = const Value.absent(),
    int? version,
    String? syncStatus,
    Value<int?> serverId = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> updatedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => TeamInstrumentScoreEntity(
    id: id ?? this.id,
    teamScoreId: teamScoreId ?? this.teamScoreId,
    instrumentType: instrumentType ?? this.instrumentType,
    customInstrument: customInstrument.present
        ? customInstrument.value
        : this.customInstrument,
    pdfPath: pdfPath.present ? pdfPath.value : this.pdfPath,
    thumbnail: thumbnail.present ? thumbnail.value : this.thumbnail,
    orderIndex: orderIndex ?? this.orderIndex,
    pdfHash: pdfHash.present ? pdfHash.value : this.pdfHash,
    pdfSyncStatus: pdfSyncStatus ?? this.pdfSyncStatus,
    annotationsJson: annotationsJson ?? this.annotationsJson,
    sourceInstrumentScoreId: sourceInstrumentScoreId.present
        ? sourceInstrumentScoreId.value
        : this.sourceInstrumentScoreId,
    version: version ?? this.version,
    syncStatus: syncStatus ?? this.syncStatus,
    serverId: serverId.present ? serverId.value : this.serverId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  TeamInstrumentScoreEntity copyWithCompanion(
    TeamInstrumentScoresCompanion data,
  ) {
    return TeamInstrumentScoreEntity(
      id: data.id.present ? data.id.value : this.id,
      teamScoreId: data.teamScoreId.present
          ? data.teamScoreId.value
          : this.teamScoreId,
      instrumentType: data.instrumentType.present
          ? data.instrumentType.value
          : this.instrumentType,
      customInstrument: data.customInstrument.present
          ? data.customInstrument.value
          : this.customInstrument,
      pdfPath: data.pdfPath.present ? data.pdfPath.value : this.pdfPath,
      thumbnail: data.thumbnail.present ? data.thumbnail.value : this.thumbnail,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      pdfHash: data.pdfHash.present ? data.pdfHash.value : this.pdfHash,
      pdfSyncStatus: data.pdfSyncStatus.present
          ? data.pdfSyncStatus.value
          : this.pdfSyncStatus,
      annotationsJson: data.annotationsJson.present
          ? data.annotationsJson.value
          : this.annotationsJson,
      sourceInstrumentScoreId: data.sourceInstrumentScoreId.present
          ? data.sourceInstrumentScoreId.value
          : this.sourceInstrumentScoreId,
      version: data.version.present ? data.version.value : this.version,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TeamInstrumentScoreEntity(')
          ..write('id: $id, ')
          ..write('teamScoreId: $teamScoreId, ')
          ..write('instrumentType: $instrumentType, ')
          ..write('customInstrument: $customInstrument, ')
          ..write('pdfPath: $pdfPath, ')
          ..write('thumbnail: $thumbnail, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('pdfHash: $pdfHash, ')
          ..write('pdfSyncStatus: $pdfSyncStatus, ')
          ..write('annotationsJson: $annotationsJson, ')
          ..write('sourceInstrumentScoreId: $sourceInstrumentScoreId, ')
          ..write('version: $version, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverId: $serverId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    teamScoreId,
    instrumentType,
    customInstrument,
    pdfPath,
    thumbnail,
    orderIndex,
    pdfHash,
    pdfSyncStatus,
    annotationsJson,
    sourceInstrumentScoreId,
    version,
    syncStatus,
    serverId,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TeamInstrumentScoreEntity &&
          other.id == this.id &&
          other.teamScoreId == this.teamScoreId &&
          other.instrumentType == this.instrumentType &&
          other.customInstrument == this.customInstrument &&
          other.pdfPath == this.pdfPath &&
          other.thumbnail == this.thumbnail &&
          other.orderIndex == this.orderIndex &&
          other.pdfHash == this.pdfHash &&
          other.pdfSyncStatus == this.pdfSyncStatus &&
          other.annotationsJson == this.annotationsJson &&
          other.sourceInstrumentScoreId == this.sourceInstrumentScoreId &&
          other.version == this.version &&
          other.syncStatus == this.syncStatus &&
          other.serverId == this.serverId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class TeamInstrumentScoresCompanion
    extends UpdateCompanion<TeamInstrumentScoreEntity> {
  final Value<String> id;
  final Value<String> teamScoreId;
  final Value<String> instrumentType;
  final Value<String?> customInstrument;
  final Value<String?> pdfPath;
  final Value<String?> thumbnail;
  final Value<int> orderIndex;
  final Value<String?> pdfHash;
  final Value<String> pdfSyncStatus;
  final Value<String> annotationsJson;
  final Value<int?> sourceInstrumentScoreId;
  final Value<int> version;
  final Value<String> syncStatus;
  final Value<int?> serverId;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const TeamInstrumentScoresCompanion({
    this.id = const Value.absent(),
    this.teamScoreId = const Value.absent(),
    this.instrumentType = const Value.absent(),
    this.customInstrument = const Value.absent(),
    this.pdfPath = const Value.absent(),
    this.thumbnail = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.pdfHash = const Value.absent(),
    this.pdfSyncStatus = const Value.absent(),
    this.annotationsJson = const Value.absent(),
    this.sourceInstrumentScoreId = const Value.absent(),
    this.version = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.serverId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TeamInstrumentScoresCompanion.insert({
    required String id,
    required String teamScoreId,
    required String instrumentType,
    this.customInstrument = const Value.absent(),
    this.pdfPath = const Value.absent(),
    this.thumbnail = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.pdfHash = const Value.absent(),
    this.pdfSyncStatus = const Value.absent(),
    this.annotationsJson = const Value.absent(),
    this.sourceInstrumentScoreId = const Value.absent(),
    this.version = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.serverId = const Value.absent(),
    required DateTime createdAt,
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       teamScoreId = Value(teamScoreId),
       instrumentType = Value(instrumentType),
       createdAt = Value(createdAt);
  static Insertable<TeamInstrumentScoreEntity> custom({
    Expression<String>? id,
    Expression<String>? teamScoreId,
    Expression<String>? instrumentType,
    Expression<String>? customInstrument,
    Expression<String>? pdfPath,
    Expression<String>? thumbnail,
    Expression<int>? orderIndex,
    Expression<String>? pdfHash,
    Expression<String>? pdfSyncStatus,
    Expression<String>? annotationsJson,
    Expression<int>? sourceInstrumentScoreId,
    Expression<int>? version,
    Expression<String>? syncStatus,
    Expression<int>? serverId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (teamScoreId != null) 'team_score_id': teamScoreId,
      if (instrumentType != null) 'instrument_type': instrumentType,
      if (customInstrument != null) 'custom_instrument': customInstrument,
      if (pdfPath != null) 'pdf_path': pdfPath,
      if (thumbnail != null) 'thumbnail': thumbnail,
      if (orderIndex != null) 'order_index': orderIndex,
      if (pdfHash != null) 'pdf_hash': pdfHash,
      if (pdfSyncStatus != null) 'pdf_sync_status': pdfSyncStatus,
      if (annotationsJson != null) 'annotations_json': annotationsJson,
      if (sourceInstrumentScoreId != null)
        'source_instrument_score_id': sourceInstrumentScoreId,
      if (version != null) 'version': version,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (serverId != null) 'server_id': serverId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TeamInstrumentScoresCompanion copyWith({
    Value<String>? id,
    Value<String>? teamScoreId,
    Value<String>? instrumentType,
    Value<String?>? customInstrument,
    Value<String?>? pdfPath,
    Value<String?>? thumbnail,
    Value<int>? orderIndex,
    Value<String?>? pdfHash,
    Value<String>? pdfSyncStatus,
    Value<String>? annotationsJson,
    Value<int?>? sourceInstrumentScoreId,
    Value<int>? version,
    Value<String>? syncStatus,
    Value<int?>? serverId,
    Value<DateTime>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return TeamInstrumentScoresCompanion(
      id: id ?? this.id,
      teamScoreId: teamScoreId ?? this.teamScoreId,
      instrumentType: instrumentType ?? this.instrumentType,
      customInstrument: customInstrument ?? this.customInstrument,
      pdfPath: pdfPath ?? this.pdfPath,
      thumbnail: thumbnail ?? this.thumbnail,
      orderIndex: orderIndex ?? this.orderIndex,
      pdfHash: pdfHash ?? this.pdfHash,
      pdfSyncStatus: pdfSyncStatus ?? this.pdfSyncStatus,
      annotationsJson: annotationsJson ?? this.annotationsJson,
      sourceInstrumentScoreId:
          sourceInstrumentScoreId ?? this.sourceInstrumentScoreId,
      version: version ?? this.version,
      syncStatus: syncStatus ?? this.syncStatus,
      serverId: serverId ?? this.serverId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (teamScoreId.present) {
      map['team_score_id'] = Variable<String>(teamScoreId.value);
    }
    if (instrumentType.present) {
      map['instrument_type'] = Variable<String>(instrumentType.value);
    }
    if (customInstrument.present) {
      map['custom_instrument'] = Variable<String>(customInstrument.value);
    }
    if (pdfPath.present) {
      map['pdf_path'] = Variable<String>(pdfPath.value);
    }
    if (thumbnail.present) {
      map['thumbnail'] = Variable<String>(thumbnail.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (pdfHash.present) {
      map['pdf_hash'] = Variable<String>(pdfHash.value);
    }
    if (pdfSyncStatus.present) {
      map['pdf_sync_status'] = Variable<String>(pdfSyncStatus.value);
    }
    if (annotationsJson.present) {
      map['annotations_json'] = Variable<String>(annotationsJson.value);
    }
    if (sourceInstrumentScoreId.present) {
      map['source_instrument_score_id'] = Variable<int>(
        sourceInstrumentScoreId.value,
      );
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TeamInstrumentScoresCompanion(')
          ..write('id: $id, ')
          ..write('teamScoreId: $teamScoreId, ')
          ..write('instrumentType: $instrumentType, ')
          ..write('customInstrument: $customInstrument, ')
          ..write('pdfPath: $pdfPath, ')
          ..write('thumbnail: $thumbnail, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('pdfHash: $pdfHash, ')
          ..write('pdfSyncStatus: $pdfSyncStatus, ')
          ..write('annotationsJson: $annotationsJson, ')
          ..write('sourceInstrumentScoreId: $sourceInstrumentScoreId, ')
          ..write('version: $version, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverId: $serverId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TeamSetlistsTable extends TeamSetlists
    with TableInfo<$TeamSetlistsTable, TeamSetlistEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TeamSetlistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _teamIdMeta = const VerificationMeta('teamId');
  @override
  late final GeneratedColumn<int> teamId = GeneratedColumn<int>(
    'team_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdByIdMeta = const VerificationMeta(
    'createdById',
  );
  @override
  late final GeneratedColumn<int> createdById = GeneratedColumn<int>(
    'created_by_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceSetlistIdMeta = const VerificationMeta(
    'sourceSetlistId',
  );
  @override
  late final GeneratedColumn<int> sourceSetlistId = GeneratedColumn<int>(
    'source_setlist_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    teamId,
    name,
    description,
    createdById,
    sourceSetlistId,
    version,
    syncStatus,
    serverId,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'team_setlists';
  @override
  VerificationContext validateIntegrity(
    Insertable<TeamSetlistEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('team_id')) {
      context.handle(
        _teamIdMeta,
        teamId.isAcceptableOrUnknown(data['team_id']!, _teamIdMeta),
      );
    } else if (isInserting) {
      context.missing(_teamIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('created_by_id')) {
      context.handle(
        _createdByIdMeta,
        createdById.isAcceptableOrUnknown(
          data['created_by_id']!,
          _createdByIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdByIdMeta);
    }
    if (data.containsKey('source_setlist_id')) {
      context.handle(
        _sourceSetlistIdMeta,
        sourceSetlistId.isAcceptableOrUnknown(
          data['source_setlist_id']!,
          _sourceSetlistIdMeta,
        ),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TeamSetlistEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TeamSetlistEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      teamId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}team_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      createdById: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_by_id'],
      )!,
      sourceSetlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_setlist_id'],
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $TeamSetlistsTable createAlias(String alias) {
    return $TeamSetlistsTable(attachedDatabase, alias);
  }
}

class TeamSetlistEntity extends DataClass
    implements Insertable<TeamSetlistEntity> {
  final String id;
  final int teamId;
  final String name;
  final String? description;
  final int createdById;
  final int? sourceSetlistId;
  final int version;
  final String syncStatus;
  final int? serverId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  const TeamSetlistEntity({
    required this.id,
    required this.teamId,
    required this.name,
    this.description,
    required this.createdById,
    this.sourceSetlistId,
    required this.version,
    required this.syncStatus,
    this.serverId,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['team_id'] = Variable<int>(teamId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['created_by_id'] = Variable<int>(createdById);
    if (!nullToAbsent || sourceSetlistId != null) {
      map['source_setlist_id'] = Variable<int>(sourceSetlistId);
    }
    map['version'] = Variable<int>(version);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  TeamSetlistsCompanion toCompanion(bool nullToAbsent) {
    return TeamSetlistsCompanion(
      id: Value(id),
      teamId: Value(teamId),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createdById: Value(createdById),
      sourceSetlistId: sourceSetlistId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceSetlistId),
      version: Value(version),
      syncStatus: Value(syncStatus),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory TeamSetlistEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TeamSetlistEntity(
      id: serializer.fromJson<String>(json['id']),
      teamId: serializer.fromJson<int>(json['teamId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      createdById: serializer.fromJson<int>(json['createdById']),
      sourceSetlistId: serializer.fromJson<int?>(json['sourceSetlistId']),
      version: serializer.fromJson<int>(json['version']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'teamId': serializer.toJson<int>(teamId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'createdById': serializer.toJson<int>(createdById),
      'sourceSetlistId': serializer.toJson<int?>(sourceSetlistId),
      'version': serializer.toJson<int>(version),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'serverId': serializer.toJson<int?>(serverId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  TeamSetlistEntity copyWith({
    String? id,
    int? teamId,
    String? name,
    Value<String?> description = const Value.absent(),
    int? createdById,
    Value<int?> sourceSetlistId = const Value.absent(),
    int? version,
    String? syncStatus,
    Value<int?> serverId = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> updatedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => TeamSetlistEntity(
    id: id ?? this.id,
    teamId: teamId ?? this.teamId,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    createdById: createdById ?? this.createdById,
    sourceSetlistId: sourceSetlistId.present
        ? sourceSetlistId.value
        : this.sourceSetlistId,
    version: version ?? this.version,
    syncStatus: syncStatus ?? this.syncStatus,
    serverId: serverId.present ? serverId.value : this.serverId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  TeamSetlistEntity copyWithCompanion(TeamSetlistsCompanion data) {
    return TeamSetlistEntity(
      id: data.id.present ? data.id.value : this.id,
      teamId: data.teamId.present ? data.teamId.value : this.teamId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      createdById: data.createdById.present
          ? data.createdById.value
          : this.createdById,
      sourceSetlistId: data.sourceSetlistId.present
          ? data.sourceSetlistId.value
          : this.sourceSetlistId,
      version: data.version.present ? data.version.value : this.version,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TeamSetlistEntity(')
          ..write('id: $id, ')
          ..write('teamId: $teamId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdById: $createdById, ')
          ..write('sourceSetlistId: $sourceSetlistId, ')
          ..write('version: $version, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverId: $serverId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    teamId,
    name,
    description,
    createdById,
    sourceSetlistId,
    version,
    syncStatus,
    serverId,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TeamSetlistEntity &&
          other.id == this.id &&
          other.teamId == this.teamId &&
          other.name == this.name &&
          other.description == this.description &&
          other.createdById == this.createdById &&
          other.sourceSetlistId == this.sourceSetlistId &&
          other.version == this.version &&
          other.syncStatus == this.syncStatus &&
          other.serverId == this.serverId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class TeamSetlistsCompanion extends UpdateCompanion<TeamSetlistEntity> {
  final Value<String> id;
  final Value<int> teamId;
  final Value<String> name;
  final Value<String?> description;
  final Value<int> createdById;
  final Value<int?> sourceSetlistId;
  final Value<int> version;
  final Value<String> syncStatus;
  final Value<int?> serverId;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const TeamSetlistsCompanion({
    this.id = const Value.absent(),
    this.teamId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.createdById = const Value.absent(),
    this.sourceSetlistId = const Value.absent(),
    this.version = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.serverId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TeamSetlistsCompanion.insert({
    required String id,
    required int teamId,
    required String name,
    this.description = const Value.absent(),
    required int createdById,
    this.sourceSetlistId = const Value.absent(),
    this.version = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.serverId = const Value.absent(),
    required DateTime createdAt,
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       teamId = Value(teamId),
       name = Value(name),
       createdById = Value(createdById),
       createdAt = Value(createdAt);
  static Insertable<TeamSetlistEntity> custom({
    Expression<String>? id,
    Expression<int>? teamId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<int>? createdById,
    Expression<int>? sourceSetlistId,
    Expression<int>? version,
    Expression<String>? syncStatus,
    Expression<int>? serverId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (teamId != null) 'team_id': teamId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (createdById != null) 'created_by_id': createdById,
      if (sourceSetlistId != null) 'source_setlist_id': sourceSetlistId,
      if (version != null) 'version': version,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (serverId != null) 'server_id': serverId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TeamSetlistsCompanion copyWith({
    Value<String>? id,
    Value<int>? teamId,
    Value<String>? name,
    Value<String?>? description,
    Value<int>? createdById,
    Value<int?>? sourceSetlistId,
    Value<int>? version,
    Value<String>? syncStatus,
    Value<int?>? serverId,
    Value<DateTime>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return TeamSetlistsCompanion(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      name: name ?? this.name,
      description: description ?? this.description,
      createdById: createdById ?? this.createdById,
      sourceSetlistId: sourceSetlistId ?? this.sourceSetlistId,
      version: version ?? this.version,
      syncStatus: syncStatus ?? this.syncStatus,
      serverId: serverId ?? this.serverId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (teamId.present) {
      map['team_id'] = Variable<int>(teamId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdById.present) {
      map['created_by_id'] = Variable<int>(createdById.value);
    }
    if (sourceSetlistId.present) {
      map['source_setlist_id'] = Variable<int>(sourceSetlistId.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TeamSetlistsCompanion(')
          ..write('id: $id, ')
          ..write('teamId: $teamId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdById: $createdById, ')
          ..write('sourceSetlistId: $sourceSetlistId, ')
          ..write('version: $version, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverId: $serverId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TeamSetlistScoresTable extends TeamSetlistScores
    with TableInfo<$TeamSetlistScoresTable, TeamSetlistScoreEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TeamSetlistScoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _teamSetlistIdMeta = const VerificationMeta(
    'teamSetlistId',
  );
  @override
  late final GeneratedColumn<String> teamSetlistId = GeneratedColumn<String>(
    'team_setlist_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES team_setlists (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _teamScoreIdMeta = const VerificationMeta(
    'teamScoreId',
  );
  @override
  late final GeneratedColumn<String> teamScoreId = GeneratedColumn<String>(
    'team_score_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES team_scores (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    teamSetlistId,
    teamScoreId,
    orderIndex,
    version,
    syncStatus,
    serverId,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'team_setlist_scores';
  @override
  VerificationContext validateIntegrity(
    Insertable<TeamSetlistScoreEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('team_setlist_id')) {
      context.handle(
        _teamSetlistIdMeta,
        teamSetlistId.isAcceptableOrUnknown(
          data['team_setlist_id']!,
          _teamSetlistIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_teamSetlistIdMeta);
    }
    if (data.containsKey('team_score_id')) {
      context.handle(
        _teamScoreIdMeta,
        teamScoreId.isAcceptableOrUnknown(
          data['team_score_id']!,
          _teamScoreIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_teamScoreIdMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TeamSetlistScoreEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TeamSetlistScoreEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      teamSetlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}team_setlist_id'],
      )!,
      teamScoreId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}team_score_id'],
      )!,
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $TeamSetlistScoresTable createAlias(String alias) {
    return $TeamSetlistScoresTable(attachedDatabase, alias);
  }
}

class TeamSetlistScoreEntity extends DataClass
    implements Insertable<TeamSetlistScoreEntity> {
  final String id;
  final String teamSetlistId;
  final String teamScoreId;
  final int orderIndex;
  final int version;
  final String syncStatus;
  final int? serverId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  const TeamSetlistScoreEntity({
    required this.id,
    required this.teamSetlistId,
    required this.teamScoreId,
    required this.orderIndex,
    required this.version,
    required this.syncStatus,
    this.serverId,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['team_setlist_id'] = Variable<String>(teamSetlistId);
    map['team_score_id'] = Variable<String>(teamScoreId);
    map['order_index'] = Variable<int>(orderIndex);
    map['version'] = Variable<int>(version);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  TeamSetlistScoresCompanion toCompanion(bool nullToAbsent) {
    return TeamSetlistScoresCompanion(
      id: Value(id),
      teamSetlistId: Value(teamSetlistId),
      teamScoreId: Value(teamScoreId),
      orderIndex: Value(orderIndex),
      version: Value(version),
      syncStatus: Value(syncStatus),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory TeamSetlistScoreEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TeamSetlistScoreEntity(
      id: serializer.fromJson<String>(json['id']),
      teamSetlistId: serializer.fromJson<String>(json['teamSetlistId']),
      teamScoreId: serializer.fromJson<String>(json['teamScoreId']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      version: serializer.fromJson<int>(json['version']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'teamSetlistId': serializer.toJson<String>(teamSetlistId),
      'teamScoreId': serializer.toJson<String>(teamScoreId),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'version': serializer.toJson<int>(version),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'serverId': serializer.toJson<int?>(serverId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  TeamSetlistScoreEntity copyWith({
    String? id,
    String? teamSetlistId,
    String? teamScoreId,
    int? orderIndex,
    int? version,
    String? syncStatus,
    Value<int?> serverId = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> updatedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => TeamSetlistScoreEntity(
    id: id ?? this.id,
    teamSetlistId: teamSetlistId ?? this.teamSetlistId,
    teamScoreId: teamScoreId ?? this.teamScoreId,
    orderIndex: orderIndex ?? this.orderIndex,
    version: version ?? this.version,
    syncStatus: syncStatus ?? this.syncStatus,
    serverId: serverId.present ? serverId.value : this.serverId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  TeamSetlistScoreEntity copyWithCompanion(TeamSetlistScoresCompanion data) {
    return TeamSetlistScoreEntity(
      id: data.id.present ? data.id.value : this.id,
      teamSetlistId: data.teamSetlistId.present
          ? data.teamSetlistId.value
          : this.teamSetlistId,
      teamScoreId: data.teamScoreId.present
          ? data.teamScoreId.value
          : this.teamScoreId,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      version: data.version.present ? data.version.value : this.version,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TeamSetlistScoreEntity(')
          ..write('id: $id, ')
          ..write('teamSetlistId: $teamSetlistId, ')
          ..write('teamScoreId: $teamScoreId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('version: $version, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverId: $serverId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    teamSetlistId,
    teamScoreId,
    orderIndex,
    version,
    syncStatus,
    serverId,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TeamSetlistScoreEntity &&
          other.id == this.id &&
          other.teamSetlistId == this.teamSetlistId &&
          other.teamScoreId == this.teamScoreId &&
          other.orderIndex == this.orderIndex &&
          other.version == this.version &&
          other.syncStatus == this.syncStatus &&
          other.serverId == this.serverId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class TeamSetlistScoresCompanion
    extends UpdateCompanion<TeamSetlistScoreEntity> {
  final Value<String> id;
  final Value<String> teamSetlistId;
  final Value<String> teamScoreId;
  final Value<int> orderIndex;
  final Value<int> version;
  final Value<String> syncStatus;
  final Value<int?> serverId;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const TeamSetlistScoresCompanion({
    this.id = const Value.absent(),
    this.teamSetlistId = const Value.absent(),
    this.teamScoreId = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.version = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.serverId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TeamSetlistScoresCompanion.insert({
    required String id,
    required String teamSetlistId,
    required String teamScoreId,
    this.orderIndex = const Value.absent(),
    this.version = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.serverId = const Value.absent(),
    required DateTime createdAt,
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       teamSetlistId = Value(teamSetlistId),
       teamScoreId = Value(teamScoreId),
       createdAt = Value(createdAt);
  static Insertable<TeamSetlistScoreEntity> custom({
    Expression<String>? id,
    Expression<String>? teamSetlistId,
    Expression<String>? teamScoreId,
    Expression<int>? orderIndex,
    Expression<int>? version,
    Expression<String>? syncStatus,
    Expression<int>? serverId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (teamSetlistId != null) 'team_setlist_id': teamSetlistId,
      if (teamScoreId != null) 'team_score_id': teamScoreId,
      if (orderIndex != null) 'order_index': orderIndex,
      if (version != null) 'version': version,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (serverId != null) 'server_id': serverId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TeamSetlistScoresCompanion copyWith({
    Value<String>? id,
    Value<String>? teamSetlistId,
    Value<String>? teamScoreId,
    Value<int>? orderIndex,
    Value<int>? version,
    Value<String>? syncStatus,
    Value<int?>? serverId,
    Value<DateTime>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return TeamSetlistScoresCompanion(
      id: id ?? this.id,
      teamSetlistId: teamSetlistId ?? this.teamSetlistId,
      teamScoreId: teamScoreId ?? this.teamScoreId,
      orderIndex: orderIndex ?? this.orderIndex,
      version: version ?? this.version,
      syncStatus: syncStatus ?? this.syncStatus,
      serverId: serverId ?? this.serverId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (teamSetlistId.present) {
      map['team_setlist_id'] = Variable<String>(teamSetlistId.value);
    }
    if (teamScoreId.present) {
      map['team_score_id'] = Variable<String>(teamScoreId.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TeamSetlistScoresCompanion(')
          ..write('id: $id, ')
          ..write('teamSetlistId: $teamSetlistId, ')
          ..write('teamScoreId: $teamScoreId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('version: $version, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverId: $serverId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TeamSyncStateTable extends TeamSyncState
    with TableInfo<$TeamSyncStateTable, TeamSyncStateEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TeamSyncStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _teamIdMeta = const VerificationMeta('teamId');
  @override
  late final GeneratedColumn<int> teamId = GeneratedColumn<int>(
    'team_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _teamLibraryVersionMeta =
      const VerificationMeta('teamLibraryVersion');
  @override
  late final GeneratedColumn<int> teamLibraryVersion = GeneratedColumn<int>(
    'team_library_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastSyncAtMeta = const VerificationMeta(
    'lastSyncAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAt = GeneratedColumn<DateTime>(
    'last_sync_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    teamId,
    teamLibraryVersion,
    lastSyncAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'team_sync_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<TeamSyncStateEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('team_id')) {
      context.handle(
        _teamIdMeta,
        teamId.isAcceptableOrUnknown(data['team_id']!, _teamIdMeta),
      );
    }
    if (data.containsKey('team_library_version')) {
      context.handle(
        _teamLibraryVersionMeta,
        teamLibraryVersion.isAcceptableOrUnknown(
          data['team_library_version']!,
          _teamLibraryVersionMeta,
        ),
      );
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
        _lastSyncAtMeta,
        lastSyncAt.isAcceptableOrUnknown(
          data['last_sync_at']!,
          _lastSyncAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {teamId};
  @override
  TeamSyncStateEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TeamSyncStateEntity(
      teamId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}team_id'],
      )!,
      teamLibraryVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}team_library_version'],
      )!,
      lastSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_at'],
      ),
    );
  }

  @override
  $TeamSyncStateTable createAlias(String alias) {
    return $TeamSyncStateTable(attachedDatabase, alias);
  }
}

class TeamSyncStateEntity extends DataClass
    implements Insertable<TeamSyncStateEntity> {
  final int teamId;
  final int teamLibraryVersion;
  final DateTime? lastSyncAt;
  const TeamSyncStateEntity({
    required this.teamId,
    required this.teamLibraryVersion,
    this.lastSyncAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['team_id'] = Variable<int>(teamId);
    map['team_library_version'] = Variable<int>(teamLibraryVersion);
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt);
    }
    return map;
  }

  TeamSyncStateCompanion toCompanion(bool nullToAbsent) {
    return TeamSyncStateCompanion(
      teamId: Value(teamId),
      teamLibraryVersion: Value(teamLibraryVersion),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
    );
  }

  factory TeamSyncStateEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TeamSyncStateEntity(
      teamId: serializer.fromJson<int>(json['teamId']),
      teamLibraryVersion: serializer.fromJson<int>(json['teamLibraryVersion']),
      lastSyncAt: serializer.fromJson<DateTime?>(json['lastSyncAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'teamId': serializer.toJson<int>(teamId),
      'teamLibraryVersion': serializer.toJson<int>(teamLibraryVersion),
      'lastSyncAt': serializer.toJson<DateTime?>(lastSyncAt),
    };
  }

  TeamSyncStateEntity copyWith({
    int? teamId,
    int? teamLibraryVersion,
    Value<DateTime?> lastSyncAt = const Value.absent(),
  }) => TeamSyncStateEntity(
    teamId: teamId ?? this.teamId,
    teamLibraryVersion: teamLibraryVersion ?? this.teamLibraryVersion,
    lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
  );
  TeamSyncStateEntity copyWithCompanion(TeamSyncStateCompanion data) {
    return TeamSyncStateEntity(
      teamId: data.teamId.present ? data.teamId.value : this.teamId,
      teamLibraryVersion: data.teamLibraryVersion.present
          ? data.teamLibraryVersion.value
          : this.teamLibraryVersion,
      lastSyncAt: data.lastSyncAt.present
          ? data.lastSyncAt.value
          : this.lastSyncAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TeamSyncStateEntity(')
          ..write('teamId: $teamId, ')
          ..write('teamLibraryVersion: $teamLibraryVersion, ')
          ..write('lastSyncAt: $lastSyncAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(teamId, teamLibraryVersion, lastSyncAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TeamSyncStateEntity &&
          other.teamId == this.teamId &&
          other.teamLibraryVersion == this.teamLibraryVersion &&
          other.lastSyncAt == this.lastSyncAt);
}

class TeamSyncStateCompanion extends UpdateCompanion<TeamSyncStateEntity> {
  final Value<int> teamId;
  final Value<int> teamLibraryVersion;
  final Value<DateTime?> lastSyncAt;
  const TeamSyncStateCompanion({
    this.teamId = const Value.absent(),
    this.teamLibraryVersion = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
  });
  TeamSyncStateCompanion.insert({
    this.teamId = const Value.absent(),
    this.teamLibraryVersion = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
  });
  static Insertable<TeamSyncStateEntity> custom({
    Expression<int>? teamId,
    Expression<int>? teamLibraryVersion,
    Expression<DateTime>? lastSyncAt,
  }) {
    return RawValuesInsertable({
      if (teamId != null) 'team_id': teamId,
      if (teamLibraryVersion != null)
        'team_library_version': teamLibraryVersion,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
    });
  }

  TeamSyncStateCompanion copyWith({
    Value<int>? teamId,
    Value<int>? teamLibraryVersion,
    Value<DateTime?>? lastSyncAt,
  }) {
    return TeamSyncStateCompanion(
      teamId: teamId ?? this.teamId,
      teamLibraryVersion: teamLibraryVersion ?? this.teamLibraryVersion,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (teamId.present) {
      map['team_id'] = Variable<int>(teamId.value);
    }
    if (teamLibraryVersion.present) {
      map['team_library_version'] = Variable<int>(teamLibraryVersion.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TeamSyncStateCompanion(')
          ..write('teamId: $teamId, ')
          ..write('teamLibraryVersion: $teamLibraryVersion, ')
          ..write('lastSyncAt: $lastSyncAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ScoresTable scores = $ScoresTable(this);
  late final $InstrumentScoresTable instrumentScores = $InstrumentScoresTable(
    this,
  );
  late final $AnnotationsTable annotations = $AnnotationsTable(this);
  late final $SetlistsTable setlists = $SetlistsTable(this);
  late final $SetlistScoresTable setlistScores = $SetlistScoresTable(this);
  late final $AppStateTable appState = $AppStateTable(this);
  late final $SyncStateTable syncState = $SyncStateTable(this);
  late final $TeamsTable teams = $TeamsTable(this);
  late final $TeamMembersTable teamMembers = $TeamMembersTable(this);
  late final $TeamScoresTable teamScores = $TeamScoresTable(this);
  late final $TeamInstrumentScoresTable teamInstrumentScores =
      $TeamInstrumentScoresTable(this);
  late final $TeamSetlistsTable teamSetlists = $TeamSetlistsTable(this);
  late final $TeamSetlistScoresTable teamSetlistScores =
      $TeamSetlistScoresTable(this);
  late final $TeamSyncStateTable teamSyncState = $TeamSyncStateTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    scores,
    instrumentScores,
    annotations,
    setlists,
    setlistScores,
    appState,
    syncState,
    teams,
    teamMembers,
    teamScores,
    teamInstrumentScores,
    teamSetlists,
    teamSetlistScores,
    teamSyncState,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'scores',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('instrument_scores', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'instrument_scores',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('annotations', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'setlists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('setlist_scores', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'scores',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('setlist_scores', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'teams',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('team_members', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'team_scores',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('team_instrument_scores', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'team_setlists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('team_setlist_scores', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'team_scores',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('team_setlist_scores', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ScoresTableCreateCompanionBuilder =
    ScoresCompanion Function({
      required String id,
      required String title,
      required String composer,
      Value<int> bpm,
      required DateTime createdAt,
      Value<int> version,
      Value<String> syncStatus,
      Value<int?> serverId,
      Value<DateTime?> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$ScoresTableUpdateCompanionBuilder =
    ScoresCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> composer,
      Value<int> bpm,
      Value<DateTime> createdAt,
      Value<int> version,
      Value<String> syncStatus,
      Value<int?> serverId,
      Value<DateTime?> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

final class $$ScoresTableReferences
    extends BaseReferences<_$AppDatabase, $ScoresTable, ScoreEntity> {
  $$ScoresTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $InstrumentScoresTable,
    List<InstrumentScoreEntity>
  >
  _instrumentScoresRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.instrumentScores,
    aliasName: $_aliasNameGenerator(db.scores.id, db.instrumentScores.scoreId),
  );

  $$InstrumentScoresTableProcessedTableManager get instrumentScoresRefs {
    final manager = $$InstrumentScoresTableTableManager(
      $_db,
      $_db.instrumentScores,
    ).filter((f) => f.scoreId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _instrumentScoresRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SetlistScoresTable, List<SetlistScoreEntity>>
  _setlistScoresRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.setlistScores,
    aliasName: $_aliasNameGenerator(db.scores.id, db.setlistScores.scoreId),
  );

  $$SetlistScoresTableProcessedTableManager get setlistScoresRefs {
    final manager = $$SetlistScoresTableTableManager(
      $_db,
      $_db.setlistScores,
    ).filter((f) => f.scoreId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_setlistScoresRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ScoresTableFilterComposer
    extends Composer<_$AppDatabase, $ScoresTable> {
  $$ScoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get composer => $composableBuilder(
    column: $table.composer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bpm => $composableBuilder(
    column: $table.bpm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> instrumentScoresRefs(
    Expression<bool> Function($$InstrumentScoresTableFilterComposer f) f,
  ) {
    final $$InstrumentScoresTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.instrumentScores,
      getReferencedColumn: (t) => t.scoreId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InstrumentScoresTableFilterComposer(
            $db: $db,
            $table: $db.instrumentScores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> setlistScoresRefs(
    Expression<bool> Function($$SetlistScoresTableFilterComposer f) f,
  ) {
    final $$SetlistScoresTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.setlistScores,
      getReferencedColumn: (t) => t.scoreId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetlistScoresTableFilterComposer(
            $db: $db,
            $table: $db.setlistScores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ScoresTableOrderingComposer
    extends Composer<_$AppDatabase, $ScoresTable> {
  $$ScoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get composer => $composableBuilder(
    column: $table.composer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bpm => $composableBuilder(
    column: $table.bpm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ScoresTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScoresTable> {
  $$ScoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get composer =>
      $composableBuilder(column: $table.composer, builder: (column) => column);

  GeneratedColumn<int> get bpm =>
      $composableBuilder(column: $table.bpm, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> instrumentScoresRefs<T extends Object>(
    Expression<T> Function($$InstrumentScoresTableAnnotationComposer a) f,
  ) {
    final $$InstrumentScoresTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.instrumentScores,
      getReferencedColumn: (t) => t.scoreId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InstrumentScoresTableAnnotationComposer(
            $db: $db,
            $table: $db.instrumentScores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> setlistScoresRefs<T extends Object>(
    Expression<T> Function($$SetlistScoresTableAnnotationComposer a) f,
  ) {
    final $$SetlistScoresTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.setlistScores,
      getReferencedColumn: (t) => t.scoreId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetlistScoresTableAnnotationComposer(
            $db: $db,
            $table: $db.setlistScores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ScoresTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScoresTable,
          ScoreEntity,
          $$ScoresTableFilterComposer,
          $$ScoresTableOrderingComposer,
          $$ScoresTableAnnotationComposer,
          $$ScoresTableCreateCompanionBuilder,
          $$ScoresTableUpdateCompanionBuilder,
          (ScoreEntity, $$ScoresTableReferences),
          ScoreEntity,
          PrefetchHooks Function({
            bool instrumentScoresRefs,
            bool setlistScoresRefs,
          })
        > {
  $$ScoresTableTableManager(_$AppDatabase db, $ScoresTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScoresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScoresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> composer = const Value.absent(),
                Value<int> bpm = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScoresCompanion(
                id: id,
                title: title,
                composer: composer,
                bpm: bpm,
                createdAt: createdAt,
                version: version,
                syncStatus: syncStatus,
                serverId: serverId,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String composer,
                Value<int> bpm = const Value.absent(),
                required DateTime createdAt,
                Value<int> version = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScoresCompanion.insert(
                id: id,
                title: title,
                composer: composer,
                bpm: bpm,
                createdAt: createdAt,
                version: version,
                syncStatus: syncStatus,
                serverId: serverId,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$ScoresTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({instrumentScoresRefs = false, setlistScoresRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (instrumentScoresRefs) db.instrumentScores,
                    if (setlistScoresRefs) db.setlistScores,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (instrumentScoresRefs)
                        await $_getPrefetchedData<
                          ScoreEntity,
                          $ScoresTable,
                          InstrumentScoreEntity
                        >(
                          currentTable: table,
                          referencedTable: $$ScoresTableReferences
                              ._instrumentScoresRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ScoresTableReferences(
                                db,
                                table,
                                p0,
                              ).instrumentScoresRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.scoreId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (setlistScoresRefs)
                        await $_getPrefetchedData<
                          ScoreEntity,
                          $ScoresTable,
                          SetlistScoreEntity
                        >(
                          currentTable: table,
                          referencedTable: $$ScoresTableReferences
                              ._setlistScoresRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ScoresTableReferences(
                                db,
                                table,
                                p0,
                              ).setlistScoresRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.scoreId == item.id,
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

typedef $$ScoresTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScoresTable,
      ScoreEntity,
      $$ScoresTableFilterComposer,
      $$ScoresTableOrderingComposer,
      $$ScoresTableAnnotationComposer,
      $$ScoresTableCreateCompanionBuilder,
      $$ScoresTableUpdateCompanionBuilder,
      (ScoreEntity, $$ScoresTableReferences),
      ScoreEntity,
      PrefetchHooks Function({
        bool instrumentScoresRefs,
        bool setlistScoresRefs,
      })
    >;
typedef $$InstrumentScoresTableCreateCompanionBuilder =
    InstrumentScoresCompanion Function({
      required String id,
      required String scoreId,
      required String instrumentType,
      Value<String?> customInstrument,
      Value<String?> pdfPath,
      Value<String?> thumbnail,
      required DateTime createdAt,
      Value<int> orderIndex,
      Value<int> version,
      Value<String> syncStatus,
      Value<int?> serverId,
      Value<String> pdfSyncStatus,
      Value<String?> pdfHash,
      Value<DateTime?> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> annotationsJson,
      Value<int> rowid,
    });
typedef $$InstrumentScoresTableUpdateCompanionBuilder =
    InstrumentScoresCompanion Function({
      Value<String> id,
      Value<String> scoreId,
      Value<String> instrumentType,
      Value<String?> customInstrument,
      Value<String?> pdfPath,
      Value<String?> thumbnail,
      Value<DateTime> createdAt,
      Value<int> orderIndex,
      Value<int> version,
      Value<String> syncStatus,
      Value<int?> serverId,
      Value<String> pdfSyncStatus,
      Value<String?> pdfHash,
      Value<DateTime?> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> annotationsJson,
      Value<int> rowid,
    });

final class $$InstrumentScoresTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $InstrumentScoresTable,
          InstrumentScoreEntity
        > {
  $$InstrumentScoresTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ScoresTable _scoreIdTable(_$AppDatabase db) => db.scores.createAlias(
    $_aliasNameGenerator(db.instrumentScores.scoreId, db.scores.id),
  );

  $$ScoresTableProcessedTableManager get scoreId {
    final $_column = $_itemColumn<String>('score_id')!;

    final manager = $$ScoresTableTableManager(
      $_db,
      $_db.scores,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_scoreIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$AnnotationsTable, List<AnnotationEntity>>
  _annotationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.annotations,
    aliasName: $_aliasNameGenerator(
      db.instrumentScores.id,
      db.annotations.instrumentScoreId,
    ),
  );

  $$AnnotationsTableProcessedTableManager get annotationsRefs {
    final manager = $$AnnotationsTableTableManager($_db, $_db.annotations)
        .filter(
          (f) => f.instrumentScoreId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(_annotationsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$InstrumentScoresTableFilterComposer
    extends Composer<_$AppDatabase, $InstrumentScoresTable> {
  $$InstrumentScoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get instrumentType => $composableBuilder(
    column: $table.instrumentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customInstrument => $composableBuilder(
    column: $table.customInstrument,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pdfPath => $composableBuilder(
    column: $table.pdfPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnail => $composableBuilder(
    column: $table.thumbnail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pdfSyncStatus => $composableBuilder(
    column: $table.pdfSyncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pdfHash => $composableBuilder(
    column: $table.pdfHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get annotationsJson => $composableBuilder(
    column: $table.annotationsJson,
    builder: (column) => ColumnFilters(column),
  );

  $$ScoresTableFilterComposer get scoreId {
    final $$ScoresTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scoreId,
      referencedTable: $db.scores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoresTableFilterComposer(
            $db: $db,
            $table: $db.scores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> annotationsRefs(
    Expression<bool> Function($$AnnotationsTableFilterComposer f) f,
  ) {
    final $$AnnotationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.annotations,
      getReferencedColumn: (t) => t.instrumentScoreId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnnotationsTableFilterComposer(
            $db: $db,
            $table: $db.annotations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$InstrumentScoresTableOrderingComposer
    extends Composer<_$AppDatabase, $InstrumentScoresTable> {
  $$InstrumentScoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get instrumentType => $composableBuilder(
    column: $table.instrumentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customInstrument => $composableBuilder(
    column: $table.customInstrument,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pdfPath => $composableBuilder(
    column: $table.pdfPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnail => $composableBuilder(
    column: $table.thumbnail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pdfSyncStatus => $composableBuilder(
    column: $table.pdfSyncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pdfHash => $composableBuilder(
    column: $table.pdfHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get annotationsJson => $composableBuilder(
    column: $table.annotationsJson,
    builder: (column) => ColumnOrderings(column),
  );

  $$ScoresTableOrderingComposer get scoreId {
    final $$ScoresTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scoreId,
      referencedTable: $db.scores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoresTableOrderingComposer(
            $db: $db,
            $table: $db.scores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InstrumentScoresTableAnnotationComposer
    extends Composer<_$AppDatabase, $InstrumentScoresTable> {
  $$InstrumentScoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get instrumentType => $composableBuilder(
    column: $table.instrumentType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customInstrument => $composableBuilder(
    column: $table.customInstrument,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pdfPath =>
      $composableBuilder(column: $table.pdfPath, builder: (column) => column);

  GeneratedColumn<String> get thumbnail =>
      $composableBuilder(column: $table.thumbnail, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get pdfSyncStatus => $composableBuilder(
    column: $table.pdfSyncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pdfHash =>
      $composableBuilder(column: $table.pdfHash, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get annotationsJson => $composableBuilder(
    column: $table.annotationsJson,
    builder: (column) => column,
  );

  $$ScoresTableAnnotationComposer get scoreId {
    final $$ScoresTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scoreId,
      referencedTable: $db.scores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoresTableAnnotationComposer(
            $db: $db,
            $table: $db.scores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> annotationsRefs<T extends Object>(
    Expression<T> Function($$AnnotationsTableAnnotationComposer a) f,
  ) {
    final $$AnnotationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.annotations,
      getReferencedColumn: (t) => t.instrumentScoreId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnnotationsTableAnnotationComposer(
            $db: $db,
            $table: $db.annotations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$InstrumentScoresTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InstrumentScoresTable,
          InstrumentScoreEntity,
          $$InstrumentScoresTableFilterComposer,
          $$InstrumentScoresTableOrderingComposer,
          $$InstrumentScoresTableAnnotationComposer,
          $$InstrumentScoresTableCreateCompanionBuilder,
          $$InstrumentScoresTableUpdateCompanionBuilder,
          (InstrumentScoreEntity, $$InstrumentScoresTableReferences),
          InstrumentScoreEntity,
          PrefetchHooks Function({bool scoreId, bool annotationsRefs})
        > {
  $$InstrumentScoresTableTableManager(
    _$AppDatabase db,
    $InstrumentScoresTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InstrumentScoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InstrumentScoresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InstrumentScoresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> scoreId = const Value.absent(),
                Value<String> instrumentType = const Value.absent(),
                Value<String?> customInstrument = const Value.absent(),
                Value<String?> pdfPath = const Value.absent(),
                Value<String?> thumbnail = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> pdfSyncStatus = const Value.absent(),
                Value<String?> pdfHash = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> annotationsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InstrumentScoresCompanion(
                id: id,
                scoreId: scoreId,
                instrumentType: instrumentType,
                customInstrument: customInstrument,
                pdfPath: pdfPath,
                thumbnail: thumbnail,
                createdAt: createdAt,
                orderIndex: orderIndex,
                version: version,
                syncStatus: syncStatus,
                serverId: serverId,
                pdfSyncStatus: pdfSyncStatus,
                pdfHash: pdfHash,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                annotationsJson: annotationsJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String scoreId,
                required String instrumentType,
                Value<String?> customInstrument = const Value.absent(),
                Value<String?> pdfPath = const Value.absent(),
                Value<String?> thumbnail = const Value.absent(),
                required DateTime createdAt,
                Value<int> orderIndex = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> pdfSyncStatus = const Value.absent(),
                Value<String?> pdfHash = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> annotationsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InstrumentScoresCompanion.insert(
                id: id,
                scoreId: scoreId,
                instrumentType: instrumentType,
                customInstrument: customInstrument,
                pdfPath: pdfPath,
                thumbnail: thumbnail,
                createdAt: createdAt,
                orderIndex: orderIndex,
                version: version,
                syncStatus: syncStatus,
                serverId: serverId,
                pdfSyncStatus: pdfSyncStatus,
                pdfHash: pdfHash,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                annotationsJson: annotationsJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$InstrumentScoresTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({scoreId = false, annotationsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (annotationsRefs) db.annotations],
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
                    if (scoreId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.scoreId,
                                referencedTable:
                                    $$InstrumentScoresTableReferences
                                        ._scoreIdTable(db),
                                referencedColumn:
                                    $$InstrumentScoresTableReferences
                                        ._scoreIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (annotationsRefs)
                    await $_getPrefetchedData<
                      InstrumentScoreEntity,
                      $InstrumentScoresTable,
                      AnnotationEntity
                    >(
                      currentTable: table,
                      referencedTable: $$InstrumentScoresTableReferences
                          ._annotationsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$InstrumentScoresTableReferences(
                            db,
                            table,
                            p0,
                          ).annotationsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.instrumentScoreId == item.id,
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

typedef $$InstrumentScoresTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InstrumentScoresTable,
      InstrumentScoreEntity,
      $$InstrumentScoresTableFilterComposer,
      $$InstrumentScoresTableOrderingComposer,
      $$InstrumentScoresTableAnnotationComposer,
      $$InstrumentScoresTableCreateCompanionBuilder,
      $$InstrumentScoresTableUpdateCompanionBuilder,
      (InstrumentScoreEntity, $$InstrumentScoresTableReferences),
      InstrumentScoreEntity,
      PrefetchHooks Function({bool scoreId, bool annotationsRefs})
    >;
typedef $$AnnotationsTableCreateCompanionBuilder =
    AnnotationsCompanion Function({
      required String id,
      required String instrumentScoreId,
      required String annotationType,
      required String color,
      required double strokeWidth,
      Value<String?> points,
      Value<String?> textContent,
      Value<double?> posX,
      Value<double?> posY,
      Value<int> pageNumber,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$AnnotationsTableUpdateCompanionBuilder =
    AnnotationsCompanion Function({
      Value<String> id,
      Value<String> instrumentScoreId,
      Value<String> annotationType,
      Value<String> color,
      Value<double> strokeWidth,
      Value<String?> points,
      Value<String?> textContent,
      Value<double?> posX,
      Value<double?> posY,
      Value<int> pageNumber,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

final class $$AnnotationsTableReferences
    extends BaseReferences<_$AppDatabase, $AnnotationsTable, AnnotationEntity> {
  $$AnnotationsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $InstrumentScoresTable _instrumentScoreIdTable(_$AppDatabase db) =>
      db.instrumentScores.createAlias(
        $_aliasNameGenerator(
          db.annotations.instrumentScoreId,
          db.instrumentScores.id,
        ),
      );

  $$InstrumentScoresTableProcessedTableManager get instrumentScoreId {
    final $_column = $_itemColumn<String>('instrument_score_id')!;

    final manager = $$InstrumentScoresTableTableManager(
      $_db,
      $_db.instrumentScores,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_instrumentScoreIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AnnotationsTableFilterComposer
    extends Composer<_$AppDatabase, $AnnotationsTable> {
  $$AnnotationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get annotationType => $composableBuilder(
    column: $table.annotationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get strokeWidth => $composableBuilder(
    column: $table.strokeWidth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get points => $composableBuilder(
    column: $table.points,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textContent => $composableBuilder(
    column: $table.textContent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get posX => $composableBuilder(
    column: $table.posX,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get posY => $composableBuilder(
    column: $table.posY,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$InstrumentScoresTableFilterComposer get instrumentScoreId {
    final $$InstrumentScoresTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.instrumentScoreId,
      referencedTable: $db.instrumentScores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InstrumentScoresTableFilterComposer(
            $db: $db,
            $table: $db.instrumentScores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnnotationsTableOrderingComposer
    extends Composer<_$AppDatabase, $AnnotationsTable> {
  $$AnnotationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get annotationType => $composableBuilder(
    column: $table.annotationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get strokeWidth => $composableBuilder(
    column: $table.strokeWidth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get points => $composableBuilder(
    column: $table.points,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textContent => $composableBuilder(
    column: $table.textContent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get posX => $composableBuilder(
    column: $table.posX,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get posY => $composableBuilder(
    column: $table.posY,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$InstrumentScoresTableOrderingComposer get instrumentScoreId {
    final $$InstrumentScoresTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.instrumentScoreId,
      referencedTable: $db.instrumentScores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InstrumentScoresTableOrderingComposer(
            $db: $db,
            $table: $db.instrumentScores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnnotationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AnnotationsTable> {
  $$AnnotationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get annotationType => $composableBuilder(
    column: $table.annotationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<double> get strokeWidth => $composableBuilder(
    column: $table.strokeWidth,
    builder: (column) => column,
  );

  GeneratedColumn<String> get points =>
      $composableBuilder(column: $table.points, builder: (column) => column);

  GeneratedColumn<String> get textContent => $composableBuilder(
    column: $table.textContent,
    builder: (column) => column,
  );

  GeneratedColumn<double> get posX =>
      $composableBuilder(column: $table.posX, builder: (column) => column);

  GeneratedColumn<double> get posY =>
      $composableBuilder(column: $table.posY, builder: (column) => column);

  GeneratedColumn<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$InstrumentScoresTableAnnotationComposer get instrumentScoreId {
    final $$InstrumentScoresTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.instrumentScoreId,
      referencedTable: $db.instrumentScores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InstrumentScoresTableAnnotationComposer(
            $db: $db,
            $table: $db.instrumentScores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnnotationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AnnotationsTable,
          AnnotationEntity,
          $$AnnotationsTableFilterComposer,
          $$AnnotationsTableOrderingComposer,
          $$AnnotationsTableAnnotationComposer,
          $$AnnotationsTableCreateCompanionBuilder,
          $$AnnotationsTableUpdateCompanionBuilder,
          (AnnotationEntity, $$AnnotationsTableReferences),
          AnnotationEntity,
          PrefetchHooks Function({bool instrumentScoreId})
        > {
  $$AnnotationsTableTableManager(_$AppDatabase db, $AnnotationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnnotationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnnotationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnnotationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> instrumentScoreId = const Value.absent(),
                Value<String> annotationType = const Value.absent(),
                Value<String> color = const Value.absent(),
                Value<double> strokeWidth = const Value.absent(),
                Value<String?> points = const Value.absent(),
                Value<String?> textContent = const Value.absent(),
                Value<double?> posX = const Value.absent(),
                Value<double?> posY = const Value.absent(),
                Value<int> pageNumber = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AnnotationsCompanion(
                id: id,
                instrumentScoreId: instrumentScoreId,
                annotationType: annotationType,
                color: color,
                strokeWidth: strokeWidth,
                points: points,
                textContent: textContent,
                posX: posX,
                posY: posY,
                pageNumber: pageNumber,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String instrumentScoreId,
                required String annotationType,
                required String color,
                required double strokeWidth,
                Value<String?> points = const Value.absent(),
                Value<String?> textContent = const Value.absent(),
                Value<double?> posX = const Value.absent(),
                Value<double?> posY = const Value.absent(),
                Value<int> pageNumber = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AnnotationsCompanion.insert(
                id: id,
                instrumentScoreId: instrumentScoreId,
                annotationType: annotationType,
                color: color,
                strokeWidth: strokeWidth,
                points: points,
                textContent: textContent,
                posX: posX,
                posY: posY,
                pageNumber: pageNumber,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AnnotationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({instrumentScoreId = false}) {
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
                    if (instrumentScoreId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.instrumentScoreId,
                                referencedTable: $$AnnotationsTableReferences
                                    ._instrumentScoreIdTable(db),
                                referencedColumn: $$AnnotationsTableReferences
                                    ._instrumentScoreIdTable(db)
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

typedef $$AnnotationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AnnotationsTable,
      AnnotationEntity,
      $$AnnotationsTableFilterComposer,
      $$AnnotationsTableOrderingComposer,
      $$AnnotationsTableAnnotationComposer,
      $$AnnotationsTableCreateCompanionBuilder,
      $$AnnotationsTableUpdateCompanionBuilder,
      (AnnotationEntity, $$AnnotationsTableReferences),
      AnnotationEntity,
      PrefetchHooks Function({bool instrumentScoreId})
    >;
typedef $$SetlistsTableCreateCompanionBuilder =
    SetlistsCompanion Function({
      required String id,
      required String name,
      required String description,
      required DateTime createdAt,
      Value<int> version,
      Value<String> syncStatus,
      Value<int?> serverId,
      Value<DateTime?> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$SetlistsTableUpdateCompanionBuilder =
    SetlistsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> description,
      Value<DateTime> createdAt,
      Value<int> version,
      Value<String> syncStatus,
      Value<int?> serverId,
      Value<DateTime?> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

final class $$SetlistsTableReferences
    extends BaseReferences<_$AppDatabase, $SetlistsTable, SetlistEntity> {
  $$SetlistsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SetlistScoresTable, List<SetlistScoreEntity>>
  _setlistScoresRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.setlistScores,
    aliasName: $_aliasNameGenerator(db.setlists.id, db.setlistScores.setlistId),
  );

  $$SetlistScoresTableProcessedTableManager get setlistScoresRefs {
    final manager = $$SetlistScoresTableTableManager(
      $_db,
      $_db.setlistScores,
    ).filter((f) => f.setlistId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_setlistScoresRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SetlistsTableFilterComposer
    extends Composer<_$AppDatabase, $SetlistsTable> {
  $$SetlistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> setlistScoresRefs(
    Expression<bool> Function($$SetlistScoresTableFilterComposer f) f,
  ) {
    final $$SetlistScoresTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.setlistScores,
      getReferencedColumn: (t) => t.setlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetlistScoresTableFilterComposer(
            $db: $db,
            $table: $db.setlistScores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SetlistsTableOrderingComposer
    extends Composer<_$AppDatabase, $SetlistsTable> {
  $$SetlistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SetlistsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SetlistsTable> {
  $$SetlistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> setlistScoresRefs<T extends Object>(
    Expression<T> Function($$SetlistScoresTableAnnotationComposer a) f,
  ) {
    final $$SetlistScoresTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.setlistScores,
      getReferencedColumn: (t) => t.setlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetlistScoresTableAnnotationComposer(
            $db: $db,
            $table: $db.setlistScores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SetlistsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SetlistsTable,
          SetlistEntity,
          $$SetlistsTableFilterComposer,
          $$SetlistsTableOrderingComposer,
          $$SetlistsTableAnnotationComposer,
          $$SetlistsTableCreateCompanionBuilder,
          $$SetlistsTableUpdateCompanionBuilder,
          (SetlistEntity, $$SetlistsTableReferences),
          SetlistEntity,
          PrefetchHooks Function({bool setlistScoresRefs})
        > {
  $$SetlistsTableTableManager(_$AppDatabase db, $SetlistsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SetlistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SetlistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SetlistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SetlistsCompanion(
                id: id,
                name: name,
                description: description,
                createdAt: createdAt,
                version: version,
                syncStatus: syncStatus,
                serverId: serverId,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String description,
                required DateTime createdAt,
                Value<int> version = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SetlistsCompanion.insert(
                id: id,
                name: name,
                description: description,
                createdAt: createdAt,
                version: version,
                syncStatus: syncStatus,
                serverId: serverId,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SetlistsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({setlistScoresRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (setlistScoresRefs) db.setlistScores,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (setlistScoresRefs)
                    await $_getPrefetchedData<
                      SetlistEntity,
                      $SetlistsTable,
                      SetlistScoreEntity
                    >(
                      currentTable: table,
                      referencedTable: $$SetlistsTableReferences
                          ._setlistScoresRefsTable(db),
                      managerFromTypedResult: (p0) => $$SetlistsTableReferences(
                        db,
                        table,
                        p0,
                      ).setlistScoresRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.setlistId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SetlistsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SetlistsTable,
      SetlistEntity,
      $$SetlistsTableFilterComposer,
      $$SetlistsTableOrderingComposer,
      $$SetlistsTableAnnotationComposer,
      $$SetlistsTableCreateCompanionBuilder,
      $$SetlistsTableUpdateCompanionBuilder,
      (SetlistEntity, $$SetlistsTableReferences),
      SetlistEntity,
      PrefetchHooks Function({bool setlistScoresRefs})
    >;
typedef $$SetlistScoresTableCreateCompanionBuilder =
    SetlistScoresCompanion Function({
      required String setlistId,
      required String scoreId,
      required int orderIndex,
      Value<int> version,
      Value<String> syncStatus,
      Value<int?> serverId,
      Value<DateTime?> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$SetlistScoresTableUpdateCompanionBuilder =
    SetlistScoresCompanion Function({
      Value<String> setlistId,
      Value<String> scoreId,
      Value<int> orderIndex,
      Value<int> version,
      Value<String> syncStatus,
      Value<int?> serverId,
      Value<DateTime?> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

final class $$SetlistScoresTableReferences
    extends
        BaseReferences<_$AppDatabase, $SetlistScoresTable, SetlistScoreEntity> {
  $$SetlistScoresTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SetlistsTable _setlistIdTable(_$AppDatabase db) =>
      db.setlists.createAlias(
        $_aliasNameGenerator(db.setlistScores.setlistId, db.setlists.id),
      );

  $$SetlistsTableProcessedTableManager get setlistId {
    final $_column = $_itemColumn<String>('setlist_id')!;

    final manager = $$SetlistsTableTableManager(
      $_db,
      $_db.setlists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_setlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ScoresTable _scoreIdTable(_$AppDatabase db) => db.scores.createAlias(
    $_aliasNameGenerator(db.setlistScores.scoreId, db.scores.id),
  );

  $$ScoresTableProcessedTableManager get scoreId {
    final $_column = $_itemColumn<String>('score_id')!;

    final manager = $$ScoresTableTableManager(
      $_db,
      $_db.scores,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_scoreIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SetlistScoresTableFilterComposer
    extends Composer<_$AppDatabase, $SetlistScoresTable> {
  $$SetlistScoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SetlistsTableFilterComposer get setlistId {
    final $$SetlistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.setlistId,
      referencedTable: $db.setlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetlistsTableFilterComposer(
            $db: $db,
            $table: $db.setlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ScoresTableFilterComposer get scoreId {
    final $$ScoresTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scoreId,
      referencedTable: $db.scores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoresTableFilterComposer(
            $db: $db,
            $table: $db.scores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SetlistScoresTableOrderingComposer
    extends Composer<_$AppDatabase, $SetlistScoresTable> {
  $$SetlistScoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SetlistsTableOrderingComposer get setlistId {
    final $$SetlistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.setlistId,
      referencedTable: $db.setlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetlistsTableOrderingComposer(
            $db: $db,
            $table: $db.setlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ScoresTableOrderingComposer get scoreId {
    final $$ScoresTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scoreId,
      referencedTable: $db.scores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoresTableOrderingComposer(
            $db: $db,
            $table: $db.scores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SetlistScoresTableAnnotationComposer
    extends Composer<_$AppDatabase, $SetlistScoresTable> {
  $$SetlistScoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$SetlistsTableAnnotationComposer get setlistId {
    final $$SetlistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.setlistId,
      referencedTable: $db.setlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetlistsTableAnnotationComposer(
            $db: $db,
            $table: $db.setlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ScoresTableAnnotationComposer get scoreId {
    final $$ScoresTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scoreId,
      referencedTable: $db.scores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoresTableAnnotationComposer(
            $db: $db,
            $table: $db.scores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SetlistScoresTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SetlistScoresTable,
          SetlistScoreEntity,
          $$SetlistScoresTableFilterComposer,
          $$SetlistScoresTableOrderingComposer,
          $$SetlistScoresTableAnnotationComposer,
          $$SetlistScoresTableCreateCompanionBuilder,
          $$SetlistScoresTableUpdateCompanionBuilder,
          (SetlistScoreEntity, $$SetlistScoresTableReferences),
          SetlistScoreEntity,
          PrefetchHooks Function({bool setlistId, bool scoreId})
        > {
  $$SetlistScoresTableTableManager(_$AppDatabase db, $SetlistScoresTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SetlistScoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SetlistScoresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SetlistScoresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> setlistId = const Value.absent(),
                Value<String> scoreId = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SetlistScoresCompanion(
                setlistId: setlistId,
                scoreId: scoreId,
                orderIndex: orderIndex,
                version: version,
                syncStatus: syncStatus,
                serverId: serverId,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String setlistId,
                required String scoreId,
                required int orderIndex,
                Value<int> version = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SetlistScoresCompanion.insert(
                setlistId: setlistId,
                scoreId: scoreId,
                orderIndex: orderIndex,
                version: version,
                syncStatus: syncStatus,
                serverId: serverId,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SetlistScoresTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({setlistId = false, scoreId = false}) {
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
                    if (setlistId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.setlistId,
                                referencedTable: $$SetlistScoresTableReferences
                                    ._setlistIdTable(db),
                                referencedColumn: $$SetlistScoresTableReferences
                                    ._setlistIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (scoreId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.scoreId,
                                referencedTable: $$SetlistScoresTableReferences
                                    ._scoreIdTable(db),
                                referencedColumn: $$SetlistScoresTableReferences
                                    ._scoreIdTable(db)
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

typedef $$SetlistScoresTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SetlistScoresTable,
      SetlistScoreEntity,
      $$SetlistScoresTableFilterComposer,
      $$SetlistScoresTableOrderingComposer,
      $$SetlistScoresTableAnnotationComposer,
      $$SetlistScoresTableCreateCompanionBuilder,
      $$SetlistScoresTableUpdateCompanionBuilder,
      (SetlistScoreEntity, $$SetlistScoresTableReferences),
      SetlistScoreEntity,
      PrefetchHooks Function({bool setlistId, bool scoreId})
    >;
typedef $$AppStateTableCreateCompanionBuilder =
    AppStateCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppStateTableUpdateCompanionBuilder =
    AppStateCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppStateTableFilterComposer
    extends Composer<_$AppDatabase, $AppStateTable> {
  $$AppStateTableFilterComposer({
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

class $$AppStateTableOrderingComposer
    extends Composer<_$AppDatabase, $AppStateTable> {
  $$AppStateTableOrderingComposer({
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

class $$AppStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppStateTable> {
  $$AppStateTableAnnotationComposer({
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

class $$AppStateTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppStateTable,
          AppStateEntity,
          $$AppStateTableFilterComposer,
          $$AppStateTableOrderingComposer,
          $$AppStateTableAnnotationComposer,
          $$AppStateTableCreateCompanionBuilder,
          $$AppStateTableUpdateCompanionBuilder,
          (
            AppStateEntity,
            BaseReferences<_$AppDatabase, $AppStateTable, AppStateEntity>,
          ),
          AppStateEntity,
          PrefetchHooks Function()
        > {
  $$AppStateTableTableManager(_$AppDatabase db, $AppStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppStateCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppStateCompanion.insert(
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

typedef $$AppStateTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppStateTable,
      AppStateEntity,
      $$AppStateTableFilterComposer,
      $$AppStateTableOrderingComposer,
      $$AppStateTableAnnotationComposer,
      $$AppStateTableCreateCompanionBuilder,
      $$AppStateTableUpdateCompanionBuilder,
      (
        AppStateEntity,
        BaseReferences<_$AppDatabase, $AppStateTable, AppStateEntity>,
      ),
      AppStateEntity,
      PrefetchHooks Function()
    >;
typedef $$SyncStateTableCreateCompanionBuilder =
    SyncStateCompanion Function({
      required String key,
      required String value,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$SyncStateTableUpdateCompanionBuilder =
    SyncStateCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

class $$SyncStateTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableFilterComposer({
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

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStateTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableOrderingComposer({
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

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableAnnotationComposer({
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

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SyncStateTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncStateTable,
          SyncStateEntity,
          $$SyncStateTableFilterComposer,
          $$SyncStateTableOrderingComposer,
          $$SyncStateTableAnnotationComposer,
          $$SyncStateTableCreateCompanionBuilder,
          $$SyncStateTableUpdateCompanionBuilder,
          (
            SyncStateEntity,
            BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateEntity>,
          ),
          SyncStateEntity,
          PrefetchHooks Function()
        > {
  $$SyncStateTableTableManager(_$AppDatabase db, $SyncStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStateCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStateCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStateTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncStateTable,
      SyncStateEntity,
      $$SyncStateTableFilterComposer,
      $$SyncStateTableOrderingComposer,
      $$SyncStateTableAnnotationComposer,
      $$SyncStateTableCreateCompanionBuilder,
      $$SyncStateTableUpdateCompanionBuilder,
      (
        SyncStateEntity,
        BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateEntity>,
      ),
      SyncStateEntity,
      PrefetchHooks Function()
    >;
typedef $$TeamsTableCreateCompanionBuilder =
    TeamsCompanion Function({
      required String id,
      required int serverId,
      required String name,
      Value<String?> description,
      required DateTime createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$TeamsTableUpdateCompanionBuilder =
    TeamsCompanion Function({
      Value<String> id,
      Value<int> serverId,
      Value<String> name,
      Value<String?> description,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

final class $$TeamsTableReferences
    extends BaseReferences<_$AppDatabase, $TeamsTable, TeamEntity> {
  $$TeamsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TeamMembersTable, List<TeamMemberEntity>>
  _teamMembersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.teamMembers,
    aliasName: $_aliasNameGenerator(db.teams.id, db.teamMembers.teamId),
  );

  $$TeamMembersTableProcessedTableManager get teamMembersRefs {
    final manager = $$TeamMembersTableTableManager(
      $_db,
      $_db.teamMembers,
    ).filter((f) => f.teamId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_teamMembersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TeamsTableFilterComposer extends Composer<_$AppDatabase, $TeamsTable> {
  $$TeamsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> teamMembersRefs(
    Expression<bool> Function($$TeamMembersTableFilterComposer f) f,
  ) {
    final $$TeamMembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.teamMembers,
      getReferencedColumn: (t) => t.teamId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamMembersTableFilterComposer(
            $db: $db,
            $table: $db.teamMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TeamsTableOrderingComposer
    extends Composer<_$AppDatabase, $TeamsTable> {
  $$TeamsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TeamsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TeamsTable> {
  $$TeamsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> teamMembersRefs<T extends Object>(
    Expression<T> Function($$TeamMembersTableAnnotationComposer a) f,
  ) {
    final $$TeamMembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.teamMembers,
      getReferencedColumn: (t) => t.teamId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamMembersTableAnnotationComposer(
            $db: $db,
            $table: $db.teamMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TeamsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TeamsTable,
          TeamEntity,
          $$TeamsTableFilterComposer,
          $$TeamsTableOrderingComposer,
          $$TeamsTableAnnotationComposer,
          $$TeamsTableCreateCompanionBuilder,
          $$TeamsTableUpdateCompanionBuilder,
          (TeamEntity, $$TeamsTableReferences),
          TeamEntity,
          PrefetchHooks Function({bool teamMembersRefs})
        > {
  $$TeamsTableTableManager(_$AppDatabase db, $TeamsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TeamsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TeamsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TeamsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> serverId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TeamsCompanion(
                id: id,
                serverId: serverId,
                name: name,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int serverId,
                required String name,
                Value<String?> description = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TeamsCompanion.insert(
                id: id,
                serverId: serverId,
                name: name,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TeamsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({teamMembersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (teamMembersRefs) db.teamMembers],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (teamMembersRefs)
                    await $_getPrefetchedData<
                      TeamEntity,
                      $TeamsTable,
                      TeamMemberEntity
                    >(
                      currentTable: table,
                      referencedTable: $$TeamsTableReferences
                          ._teamMembersRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TeamsTableReferences(db, table, p0).teamMembersRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.teamId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TeamsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TeamsTable,
      TeamEntity,
      $$TeamsTableFilterComposer,
      $$TeamsTableOrderingComposer,
      $$TeamsTableAnnotationComposer,
      $$TeamsTableCreateCompanionBuilder,
      $$TeamsTableUpdateCompanionBuilder,
      (TeamEntity, $$TeamsTableReferences),
      TeamEntity,
      PrefetchHooks Function({bool teamMembersRefs})
    >;
typedef $$TeamMembersTableCreateCompanionBuilder =
    TeamMembersCompanion Function({
      required String id,
      required String teamId,
      required int userId,
      required String username,
      Value<String?> displayName,
      Value<String> role,
      required DateTime joinedAt,
      Value<int> rowid,
    });
typedef $$TeamMembersTableUpdateCompanionBuilder =
    TeamMembersCompanion Function({
      Value<String> id,
      Value<String> teamId,
      Value<int> userId,
      Value<String> username,
      Value<String?> displayName,
      Value<String> role,
      Value<DateTime> joinedAt,
      Value<int> rowid,
    });

final class $$TeamMembersTableReferences
    extends BaseReferences<_$AppDatabase, $TeamMembersTable, TeamMemberEntity> {
  $$TeamMembersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TeamsTable _teamIdTable(_$AppDatabase db) => db.teams.createAlias(
    $_aliasNameGenerator(db.teamMembers.teamId, db.teams.id),
  );

  $$TeamsTableProcessedTableManager get teamId {
    final $_column = $_itemColumn<String>('team_id')!;

    final manager = $$TeamsTableTableManager(
      $_db,
      $_db.teams,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_teamIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TeamMembersTableFilterComposer
    extends Composer<_$AppDatabase, $TeamMembersTable> {
  $$TeamMembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get joinedAt => $composableBuilder(
    column: $table.joinedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TeamsTableFilterComposer get teamId {
    final $$TeamsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teamId,
      referencedTable: $db.teams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamsTableFilterComposer(
            $db: $db,
            $table: $db.teams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TeamMembersTableOrderingComposer
    extends Composer<_$AppDatabase, $TeamMembersTable> {
  $$TeamMembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get joinedAt => $composableBuilder(
    column: $table.joinedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TeamsTableOrderingComposer get teamId {
    final $$TeamsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teamId,
      referencedTable: $db.teams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamsTableOrderingComposer(
            $db: $db,
            $table: $db.teams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TeamMembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $TeamMembersTable> {
  $$TeamMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<DateTime> get joinedAt =>
      $composableBuilder(column: $table.joinedAt, builder: (column) => column);

  $$TeamsTableAnnotationComposer get teamId {
    final $$TeamsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teamId,
      referencedTable: $db.teams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamsTableAnnotationComposer(
            $db: $db,
            $table: $db.teams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TeamMembersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TeamMembersTable,
          TeamMemberEntity,
          $$TeamMembersTableFilterComposer,
          $$TeamMembersTableOrderingComposer,
          $$TeamMembersTableAnnotationComposer,
          $$TeamMembersTableCreateCompanionBuilder,
          $$TeamMembersTableUpdateCompanionBuilder,
          (TeamMemberEntity, $$TeamMembersTableReferences),
          TeamMemberEntity,
          PrefetchHooks Function({bool teamId})
        > {
  $$TeamMembersTableTableManager(_$AppDatabase db, $TeamMembersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TeamMembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TeamMembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TeamMembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> teamId = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<DateTime> joinedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TeamMembersCompanion(
                id: id,
                teamId: teamId,
                userId: userId,
                username: username,
                displayName: displayName,
                role: role,
                joinedAt: joinedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String teamId,
                required int userId,
                required String username,
                Value<String?> displayName = const Value.absent(),
                Value<String> role = const Value.absent(),
                required DateTime joinedAt,
                Value<int> rowid = const Value.absent(),
              }) => TeamMembersCompanion.insert(
                id: id,
                teamId: teamId,
                userId: userId,
                username: username,
                displayName: displayName,
                role: role,
                joinedAt: joinedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TeamMembersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({teamId = false}) {
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
                    if (teamId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.teamId,
                                referencedTable: $$TeamMembersTableReferences
                                    ._teamIdTable(db),
                                referencedColumn: $$TeamMembersTableReferences
                                    ._teamIdTable(db)
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

typedef $$TeamMembersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TeamMembersTable,
      TeamMemberEntity,
      $$TeamMembersTableFilterComposer,
      $$TeamMembersTableOrderingComposer,
      $$TeamMembersTableAnnotationComposer,
      $$TeamMembersTableCreateCompanionBuilder,
      $$TeamMembersTableUpdateCompanionBuilder,
      (TeamMemberEntity, $$TeamMembersTableReferences),
      TeamMemberEntity,
      PrefetchHooks Function({bool teamId})
    >;
typedef $$TeamScoresTableCreateCompanionBuilder =
    TeamScoresCompanion Function({
      required String id,
      required int teamId,
      required String title,
      required String composer,
      Value<int> bpm,
      required int createdById,
      Value<int?> sourceScoreId,
      Value<int> version,
      Value<String> syncStatus,
      Value<int?> serverId,
      required DateTime createdAt,
      Value<DateTime?> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$TeamScoresTableUpdateCompanionBuilder =
    TeamScoresCompanion Function({
      Value<String> id,
      Value<int> teamId,
      Value<String> title,
      Value<String> composer,
      Value<int> bpm,
      Value<int> createdById,
      Value<int?> sourceScoreId,
      Value<int> version,
      Value<String> syncStatus,
      Value<int?> serverId,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

final class $$TeamScoresTableReferences
    extends BaseReferences<_$AppDatabase, $TeamScoresTable, TeamScoreEntity> {
  $$TeamScoresTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $TeamInstrumentScoresTable,
    List<TeamInstrumentScoreEntity>
  >
  _teamInstrumentScoresRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.teamInstrumentScores,
        aliasName: $_aliasNameGenerator(
          db.teamScores.id,
          db.teamInstrumentScores.teamScoreId,
        ),
      );

  $$TeamInstrumentScoresTableProcessedTableManager
  get teamInstrumentScoresRefs {
    final manager = $$TeamInstrumentScoresTableTableManager(
      $_db,
      $_db.teamInstrumentScores,
    ).filter((f) => f.teamScoreId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _teamInstrumentScoresRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $TeamSetlistScoresTable,
    List<TeamSetlistScoreEntity>
  >
  _teamSetlistScoresRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.teamSetlistScores,
        aliasName: $_aliasNameGenerator(
          db.teamScores.id,
          db.teamSetlistScores.teamScoreId,
        ),
      );

  $$TeamSetlistScoresTableProcessedTableManager get teamSetlistScoresRefs {
    final manager = $$TeamSetlistScoresTableTableManager(
      $_db,
      $_db.teamSetlistScores,
    ).filter((f) => f.teamScoreId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _teamSetlistScoresRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TeamScoresTableFilterComposer
    extends Composer<_$AppDatabase, $TeamScoresTable> {
  $$TeamScoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get teamId => $composableBuilder(
    column: $table.teamId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get composer => $composableBuilder(
    column: $table.composer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bpm => $composableBuilder(
    column: $table.bpm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdById => $composableBuilder(
    column: $table.createdById,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sourceScoreId => $composableBuilder(
    column: $table.sourceScoreId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> teamInstrumentScoresRefs(
    Expression<bool> Function($$TeamInstrumentScoresTableFilterComposer f) f,
  ) {
    final $$TeamInstrumentScoresTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.teamInstrumentScores,
      getReferencedColumn: (t) => t.teamScoreId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamInstrumentScoresTableFilterComposer(
            $db: $db,
            $table: $db.teamInstrumentScores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> teamSetlistScoresRefs(
    Expression<bool> Function($$TeamSetlistScoresTableFilterComposer f) f,
  ) {
    final $$TeamSetlistScoresTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.teamSetlistScores,
      getReferencedColumn: (t) => t.teamScoreId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamSetlistScoresTableFilterComposer(
            $db: $db,
            $table: $db.teamSetlistScores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TeamScoresTableOrderingComposer
    extends Composer<_$AppDatabase, $TeamScoresTable> {
  $$TeamScoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get teamId => $composableBuilder(
    column: $table.teamId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get composer => $composableBuilder(
    column: $table.composer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bpm => $composableBuilder(
    column: $table.bpm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdById => $composableBuilder(
    column: $table.createdById,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sourceScoreId => $composableBuilder(
    column: $table.sourceScoreId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TeamScoresTableAnnotationComposer
    extends Composer<_$AppDatabase, $TeamScoresTable> {
  $$TeamScoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get teamId =>
      $composableBuilder(column: $table.teamId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get composer =>
      $composableBuilder(column: $table.composer, builder: (column) => column);

  GeneratedColumn<int> get bpm =>
      $composableBuilder(column: $table.bpm, builder: (column) => column);

  GeneratedColumn<int> get createdById => $composableBuilder(
    column: $table.createdById,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sourceScoreId => $composableBuilder(
    column: $table.sourceScoreId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> teamInstrumentScoresRefs<T extends Object>(
    Expression<T> Function($$TeamInstrumentScoresTableAnnotationComposer a) f,
  ) {
    final $$TeamInstrumentScoresTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.teamInstrumentScores,
          getReferencedColumn: (t) => t.teamScoreId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TeamInstrumentScoresTableAnnotationComposer(
                $db: $db,
                $table: $db.teamInstrumentScores,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> teamSetlistScoresRefs<T extends Object>(
    Expression<T> Function($$TeamSetlistScoresTableAnnotationComposer a) f,
  ) {
    final $$TeamSetlistScoresTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.teamSetlistScores,
          getReferencedColumn: (t) => t.teamScoreId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TeamSetlistScoresTableAnnotationComposer(
                $db: $db,
                $table: $db.teamSetlistScores,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$TeamScoresTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TeamScoresTable,
          TeamScoreEntity,
          $$TeamScoresTableFilterComposer,
          $$TeamScoresTableOrderingComposer,
          $$TeamScoresTableAnnotationComposer,
          $$TeamScoresTableCreateCompanionBuilder,
          $$TeamScoresTableUpdateCompanionBuilder,
          (TeamScoreEntity, $$TeamScoresTableReferences),
          TeamScoreEntity,
          PrefetchHooks Function({
            bool teamInstrumentScoresRefs,
            bool teamSetlistScoresRefs,
          })
        > {
  $$TeamScoresTableTableManager(_$AppDatabase db, $TeamScoresTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TeamScoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TeamScoresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TeamScoresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> teamId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> composer = const Value.absent(),
                Value<int> bpm = const Value.absent(),
                Value<int> createdById = const Value.absent(),
                Value<int?> sourceScoreId = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TeamScoresCompanion(
                id: id,
                teamId: teamId,
                title: title,
                composer: composer,
                bpm: bpm,
                createdById: createdById,
                sourceScoreId: sourceScoreId,
                version: version,
                syncStatus: syncStatus,
                serverId: serverId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int teamId,
                required String title,
                required String composer,
                Value<int> bpm = const Value.absent(),
                required int createdById,
                Value<int?> sourceScoreId = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TeamScoresCompanion.insert(
                id: id,
                teamId: teamId,
                title: title,
                composer: composer,
                bpm: bpm,
                createdById: createdById,
                sourceScoreId: sourceScoreId,
                version: version,
                syncStatus: syncStatus,
                serverId: serverId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TeamScoresTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                teamInstrumentScoresRefs = false,
                teamSetlistScoresRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (teamInstrumentScoresRefs) db.teamInstrumentScores,
                    if (teamSetlistScoresRefs) db.teamSetlistScores,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (teamInstrumentScoresRefs)
                        await $_getPrefetchedData<
                          TeamScoreEntity,
                          $TeamScoresTable,
                          TeamInstrumentScoreEntity
                        >(
                          currentTable: table,
                          referencedTable: $$TeamScoresTableReferences
                              ._teamInstrumentScoresRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TeamScoresTableReferences(
                                db,
                                table,
                                p0,
                              ).teamInstrumentScoresRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.teamScoreId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (teamSetlistScoresRefs)
                        await $_getPrefetchedData<
                          TeamScoreEntity,
                          $TeamScoresTable,
                          TeamSetlistScoreEntity
                        >(
                          currentTable: table,
                          referencedTable: $$TeamScoresTableReferences
                              ._teamSetlistScoresRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TeamScoresTableReferences(
                                db,
                                table,
                                p0,
                              ).teamSetlistScoresRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.teamScoreId == item.id,
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

typedef $$TeamScoresTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TeamScoresTable,
      TeamScoreEntity,
      $$TeamScoresTableFilterComposer,
      $$TeamScoresTableOrderingComposer,
      $$TeamScoresTableAnnotationComposer,
      $$TeamScoresTableCreateCompanionBuilder,
      $$TeamScoresTableUpdateCompanionBuilder,
      (TeamScoreEntity, $$TeamScoresTableReferences),
      TeamScoreEntity,
      PrefetchHooks Function({
        bool teamInstrumentScoresRefs,
        bool teamSetlistScoresRefs,
      })
    >;
typedef $$TeamInstrumentScoresTableCreateCompanionBuilder =
    TeamInstrumentScoresCompanion Function({
      required String id,
      required String teamScoreId,
      required String instrumentType,
      Value<String?> customInstrument,
      Value<String?> pdfPath,
      Value<String?> thumbnail,
      Value<int> orderIndex,
      Value<String?> pdfHash,
      Value<String> pdfSyncStatus,
      Value<String> annotationsJson,
      Value<int?> sourceInstrumentScoreId,
      Value<int> version,
      Value<String> syncStatus,
      Value<int?> serverId,
      required DateTime createdAt,
      Value<DateTime?> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$TeamInstrumentScoresTableUpdateCompanionBuilder =
    TeamInstrumentScoresCompanion Function({
      Value<String> id,
      Value<String> teamScoreId,
      Value<String> instrumentType,
      Value<String?> customInstrument,
      Value<String?> pdfPath,
      Value<String?> thumbnail,
      Value<int> orderIndex,
      Value<String?> pdfHash,
      Value<String> pdfSyncStatus,
      Value<String> annotationsJson,
      Value<int?> sourceInstrumentScoreId,
      Value<int> version,
      Value<String> syncStatus,
      Value<int?> serverId,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

final class $$TeamInstrumentScoresTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TeamInstrumentScoresTable,
          TeamInstrumentScoreEntity
        > {
  $$TeamInstrumentScoresTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TeamScoresTable _teamScoreIdTable(_$AppDatabase db) =>
      db.teamScores.createAlias(
        $_aliasNameGenerator(
          db.teamInstrumentScores.teamScoreId,
          db.teamScores.id,
        ),
      );

  $$TeamScoresTableProcessedTableManager get teamScoreId {
    final $_column = $_itemColumn<String>('team_score_id')!;

    final manager = $$TeamScoresTableTableManager(
      $_db,
      $_db.teamScores,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_teamScoreIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TeamInstrumentScoresTableFilterComposer
    extends Composer<_$AppDatabase, $TeamInstrumentScoresTable> {
  $$TeamInstrumentScoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get instrumentType => $composableBuilder(
    column: $table.instrumentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customInstrument => $composableBuilder(
    column: $table.customInstrument,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pdfPath => $composableBuilder(
    column: $table.pdfPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnail => $composableBuilder(
    column: $table.thumbnail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pdfHash => $composableBuilder(
    column: $table.pdfHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pdfSyncStatus => $composableBuilder(
    column: $table.pdfSyncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get annotationsJson => $composableBuilder(
    column: $table.annotationsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sourceInstrumentScoreId => $composableBuilder(
    column: $table.sourceInstrumentScoreId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TeamScoresTableFilterComposer get teamScoreId {
    final $$TeamScoresTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teamScoreId,
      referencedTable: $db.teamScores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamScoresTableFilterComposer(
            $db: $db,
            $table: $db.teamScores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TeamInstrumentScoresTableOrderingComposer
    extends Composer<_$AppDatabase, $TeamInstrumentScoresTable> {
  $$TeamInstrumentScoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get instrumentType => $composableBuilder(
    column: $table.instrumentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customInstrument => $composableBuilder(
    column: $table.customInstrument,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pdfPath => $composableBuilder(
    column: $table.pdfPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnail => $composableBuilder(
    column: $table.thumbnail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pdfHash => $composableBuilder(
    column: $table.pdfHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pdfSyncStatus => $composableBuilder(
    column: $table.pdfSyncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get annotationsJson => $composableBuilder(
    column: $table.annotationsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sourceInstrumentScoreId => $composableBuilder(
    column: $table.sourceInstrumentScoreId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TeamScoresTableOrderingComposer get teamScoreId {
    final $$TeamScoresTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teamScoreId,
      referencedTable: $db.teamScores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamScoresTableOrderingComposer(
            $db: $db,
            $table: $db.teamScores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TeamInstrumentScoresTableAnnotationComposer
    extends Composer<_$AppDatabase, $TeamInstrumentScoresTable> {
  $$TeamInstrumentScoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get instrumentType => $composableBuilder(
    column: $table.instrumentType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customInstrument => $composableBuilder(
    column: $table.customInstrument,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pdfPath =>
      $composableBuilder(column: $table.pdfPath, builder: (column) => column);

  GeneratedColumn<String> get thumbnail =>
      $composableBuilder(column: $table.thumbnail, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pdfHash =>
      $composableBuilder(column: $table.pdfHash, builder: (column) => column);

  GeneratedColumn<String> get pdfSyncStatus => $composableBuilder(
    column: $table.pdfSyncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get annotationsJson => $composableBuilder(
    column: $table.annotationsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sourceInstrumentScoreId => $composableBuilder(
    column: $table.sourceInstrumentScoreId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$TeamScoresTableAnnotationComposer get teamScoreId {
    final $$TeamScoresTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teamScoreId,
      referencedTable: $db.teamScores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamScoresTableAnnotationComposer(
            $db: $db,
            $table: $db.teamScores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TeamInstrumentScoresTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TeamInstrumentScoresTable,
          TeamInstrumentScoreEntity,
          $$TeamInstrumentScoresTableFilterComposer,
          $$TeamInstrumentScoresTableOrderingComposer,
          $$TeamInstrumentScoresTableAnnotationComposer,
          $$TeamInstrumentScoresTableCreateCompanionBuilder,
          $$TeamInstrumentScoresTableUpdateCompanionBuilder,
          (TeamInstrumentScoreEntity, $$TeamInstrumentScoresTableReferences),
          TeamInstrumentScoreEntity,
          PrefetchHooks Function({bool teamScoreId})
        > {
  $$TeamInstrumentScoresTableTableManager(
    _$AppDatabase db,
    $TeamInstrumentScoresTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TeamInstrumentScoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TeamInstrumentScoresTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TeamInstrumentScoresTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> teamScoreId = const Value.absent(),
                Value<String> instrumentType = const Value.absent(),
                Value<String?> customInstrument = const Value.absent(),
                Value<String?> pdfPath = const Value.absent(),
                Value<String?> thumbnail = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<String?> pdfHash = const Value.absent(),
                Value<String> pdfSyncStatus = const Value.absent(),
                Value<String> annotationsJson = const Value.absent(),
                Value<int?> sourceInstrumentScoreId = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TeamInstrumentScoresCompanion(
                id: id,
                teamScoreId: teamScoreId,
                instrumentType: instrumentType,
                customInstrument: customInstrument,
                pdfPath: pdfPath,
                thumbnail: thumbnail,
                orderIndex: orderIndex,
                pdfHash: pdfHash,
                pdfSyncStatus: pdfSyncStatus,
                annotationsJson: annotationsJson,
                sourceInstrumentScoreId: sourceInstrumentScoreId,
                version: version,
                syncStatus: syncStatus,
                serverId: serverId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String teamScoreId,
                required String instrumentType,
                Value<String?> customInstrument = const Value.absent(),
                Value<String?> pdfPath = const Value.absent(),
                Value<String?> thumbnail = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<String?> pdfHash = const Value.absent(),
                Value<String> pdfSyncStatus = const Value.absent(),
                Value<String> annotationsJson = const Value.absent(),
                Value<int?> sourceInstrumentScoreId = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TeamInstrumentScoresCompanion.insert(
                id: id,
                teamScoreId: teamScoreId,
                instrumentType: instrumentType,
                customInstrument: customInstrument,
                pdfPath: pdfPath,
                thumbnail: thumbnail,
                orderIndex: orderIndex,
                pdfHash: pdfHash,
                pdfSyncStatus: pdfSyncStatus,
                annotationsJson: annotationsJson,
                sourceInstrumentScoreId: sourceInstrumentScoreId,
                version: version,
                syncStatus: syncStatus,
                serverId: serverId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TeamInstrumentScoresTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({teamScoreId = false}) {
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
                    if (teamScoreId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.teamScoreId,
                                referencedTable:
                                    $$TeamInstrumentScoresTableReferences
                                        ._teamScoreIdTable(db),
                                referencedColumn:
                                    $$TeamInstrumentScoresTableReferences
                                        ._teamScoreIdTable(db)
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

typedef $$TeamInstrumentScoresTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TeamInstrumentScoresTable,
      TeamInstrumentScoreEntity,
      $$TeamInstrumentScoresTableFilterComposer,
      $$TeamInstrumentScoresTableOrderingComposer,
      $$TeamInstrumentScoresTableAnnotationComposer,
      $$TeamInstrumentScoresTableCreateCompanionBuilder,
      $$TeamInstrumentScoresTableUpdateCompanionBuilder,
      (TeamInstrumentScoreEntity, $$TeamInstrumentScoresTableReferences),
      TeamInstrumentScoreEntity,
      PrefetchHooks Function({bool teamScoreId})
    >;
typedef $$TeamSetlistsTableCreateCompanionBuilder =
    TeamSetlistsCompanion Function({
      required String id,
      required int teamId,
      required String name,
      Value<String?> description,
      required int createdById,
      Value<int?> sourceSetlistId,
      Value<int> version,
      Value<String> syncStatus,
      Value<int?> serverId,
      required DateTime createdAt,
      Value<DateTime?> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$TeamSetlistsTableUpdateCompanionBuilder =
    TeamSetlistsCompanion Function({
      Value<String> id,
      Value<int> teamId,
      Value<String> name,
      Value<String?> description,
      Value<int> createdById,
      Value<int?> sourceSetlistId,
      Value<int> version,
      Value<String> syncStatus,
      Value<int?> serverId,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

final class $$TeamSetlistsTableReferences
    extends
        BaseReferences<_$AppDatabase, $TeamSetlistsTable, TeamSetlistEntity> {
  $$TeamSetlistsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $TeamSetlistScoresTable,
    List<TeamSetlistScoreEntity>
  >
  _teamSetlistScoresRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.teamSetlistScores,
        aliasName: $_aliasNameGenerator(
          db.teamSetlists.id,
          db.teamSetlistScores.teamSetlistId,
        ),
      );

  $$TeamSetlistScoresTableProcessedTableManager get teamSetlistScoresRefs {
    final manager = $$TeamSetlistScoresTableTableManager(
      $_db,
      $_db.teamSetlistScores,
    ).filter((f) => f.teamSetlistId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _teamSetlistScoresRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TeamSetlistsTableFilterComposer
    extends Composer<_$AppDatabase, $TeamSetlistsTable> {
  $$TeamSetlistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get teamId => $composableBuilder(
    column: $table.teamId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdById => $composableBuilder(
    column: $table.createdById,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sourceSetlistId => $composableBuilder(
    column: $table.sourceSetlistId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> teamSetlistScoresRefs(
    Expression<bool> Function($$TeamSetlistScoresTableFilterComposer f) f,
  ) {
    final $$TeamSetlistScoresTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.teamSetlistScores,
      getReferencedColumn: (t) => t.teamSetlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamSetlistScoresTableFilterComposer(
            $db: $db,
            $table: $db.teamSetlistScores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TeamSetlistsTableOrderingComposer
    extends Composer<_$AppDatabase, $TeamSetlistsTable> {
  $$TeamSetlistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get teamId => $composableBuilder(
    column: $table.teamId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdById => $composableBuilder(
    column: $table.createdById,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sourceSetlistId => $composableBuilder(
    column: $table.sourceSetlistId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TeamSetlistsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TeamSetlistsTable> {
  $$TeamSetlistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get teamId =>
      $composableBuilder(column: $table.teamId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdById => $composableBuilder(
    column: $table.createdById,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sourceSetlistId => $composableBuilder(
    column: $table.sourceSetlistId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> teamSetlistScoresRefs<T extends Object>(
    Expression<T> Function($$TeamSetlistScoresTableAnnotationComposer a) f,
  ) {
    final $$TeamSetlistScoresTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.teamSetlistScores,
          getReferencedColumn: (t) => t.teamSetlistId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TeamSetlistScoresTableAnnotationComposer(
                $db: $db,
                $table: $db.teamSetlistScores,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$TeamSetlistsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TeamSetlistsTable,
          TeamSetlistEntity,
          $$TeamSetlistsTableFilterComposer,
          $$TeamSetlistsTableOrderingComposer,
          $$TeamSetlistsTableAnnotationComposer,
          $$TeamSetlistsTableCreateCompanionBuilder,
          $$TeamSetlistsTableUpdateCompanionBuilder,
          (TeamSetlistEntity, $$TeamSetlistsTableReferences),
          TeamSetlistEntity,
          PrefetchHooks Function({bool teamSetlistScoresRefs})
        > {
  $$TeamSetlistsTableTableManager(_$AppDatabase db, $TeamSetlistsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TeamSetlistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TeamSetlistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TeamSetlistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> teamId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> createdById = const Value.absent(),
                Value<int?> sourceSetlistId = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TeamSetlistsCompanion(
                id: id,
                teamId: teamId,
                name: name,
                description: description,
                createdById: createdById,
                sourceSetlistId: sourceSetlistId,
                version: version,
                syncStatus: syncStatus,
                serverId: serverId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int teamId,
                required String name,
                Value<String?> description = const Value.absent(),
                required int createdById,
                Value<int?> sourceSetlistId = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TeamSetlistsCompanion.insert(
                id: id,
                teamId: teamId,
                name: name,
                description: description,
                createdById: createdById,
                sourceSetlistId: sourceSetlistId,
                version: version,
                syncStatus: syncStatus,
                serverId: serverId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TeamSetlistsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({teamSetlistScoresRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (teamSetlistScoresRefs) db.teamSetlistScores,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (teamSetlistScoresRefs)
                    await $_getPrefetchedData<
                      TeamSetlistEntity,
                      $TeamSetlistsTable,
                      TeamSetlistScoreEntity
                    >(
                      currentTable: table,
                      referencedTable: $$TeamSetlistsTableReferences
                          ._teamSetlistScoresRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TeamSetlistsTableReferences(
                            db,
                            table,
                            p0,
                          ).teamSetlistScoresRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.teamSetlistId == item.id,
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

typedef $$TeamSetlistsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TeamSetlistsTable,
      TeamSetlistEntity,
      $$TeamSetlistsTableFilterComposer,
      $$TeamSetlistsTableOrderingComposer,
      $$TeamSetlistsTableAnnotationComposer,
      $$TeamSetlistsTableCreateCompanionBuilder,
      $$TeamSetlistsTableUpdateCompanionBuilder,
      (TeamSetlistEntity, $$TeamSetlistsTableReferences),
      TeamSetlistEntity,
      PrefetchHooks Function({bool teamSetlistScoresRefs})
    >;
typedef $$TeamSetlistScoresTableCreateCompanionBuilder =
    TeamSetlistScoresCompanion Function({
      required String id,
      required String teamSetlistId,
      required String teamScoreId,
      Value<int> orderIndex,
      Value<int> version,
      Value<String> syncStatus,
      Value<int?> serverId,
      required DateTime createdAt,
      Value<DateTime?> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$TeamSetlistScoresTableUpdateCompanionBuilder =
    TeamSetlistScoresCompanion Function({
      Value<String> id,
      Value<String> teamSetlistId,
      Value<String> teamScoreId,
      Value<int> orderIndex,
      Value<int> version,
      Value<String> syncStatus,
      Value<int?> serverId,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

final class $$TeamSetlistScoresTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TeamSetlistScoresTable,
          TeamSetlistScoreEntity
        > {
  $$TeamSetlistScoresTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TeamSetlistsTable _teamSetlistIdTable(_$AppDatabase db) =>
      db.teamSetlists.createAlias(
        $_aliasNameGenerator(
          db.teamSetlistScores.teamSetlistId,
          db.teamSetlists.id,
        ),
      );

  $$TeamSetlistsTableProcessedTableManager get teamSetlistId {
    final $_column = $_itemColumn<String>('team_setlist_id')!;

    final manager = $$TeamSetlistsTableTableManager(
      $_db,
      $_db.teamSetlists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_teamSetlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TeamScoresTable _teamScoreIdTable(_$AppDatabase db) =>
      db.teamScores.createAlias(
        $_aliasNameGenerator(
          db.teamSetlistScores.teamScoreId,
          db.teamScores.id,
        ),
      );

  $$TeamScoresTableProcessedTableManager get teamScoreId {
    final $_column = $_itemColumn<String>('team_score_id')!;

    final manager = $$TeamScoresTableTableManager(
      $_db,
      $_db.teamScores,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_teamScoreIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TeamSetlistScoresTableFilterComposer
    extends Composer<_$AppDatabase, $TeamSetlistScoresTable> {
  $$TeamSetlistScoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TeamSetlistsTableFilterComposer get teamSetlistId {
    final $$TeamSetlistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teamSetlistId,
      referencedTable: $db.teamSetlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamSetlistsTableFilterComposer(
            $db: $db,
            $table: $db.teamSetlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TeamScoresTableFilterComposer get teamScoreId {
    final $$TeamScoresTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teamScoreId,
      referencedTable: $db.teamScores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamScoresTableFilterComposer(
            $db: $db,
            $table: $db.teamScores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TeamSetlistScoresTableOrderingComposer
    extends Composer<_$AppDatabase, $TeamSetlistScoresTable> {
  $$TeamSetlistScoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TeamSetlistsTableOrderingComposer get teamSetlistId {
    final $$TeamSetlistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teamSetlistId,
      referencedTable: $db.teamSetlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamSetlistsTableOrderingComposer(
            $db: $db,
            $table: $db.teamSetlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TeamScoresTableOrderingComposer get teamScoreId {
    final $$TeamScoresTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teamScoreId,
      referencedTable: $db.teamScores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamScoresTableOrderingComposer(
            $db: $db,
            $table: $db.teamScores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TeamSetlistScoresTableAnnotationComposer
    extends Composer<_$AppDatabase, $TeamSetlistScoresTable> {
  $$TeamSetlistScoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$TeamSetlistsTableAnnotationComposer get teamSetlistId {
    final $$TeamSetlistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teamSetlistId,
      referencedTable: $db.teamSetlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamSetlistsTableAnnotationComposer(
            $db: $db,
            $table: $db.teamSetlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TeamScoresTableAnnotationComposer get teamScoreId {
    final $$TeamScoresTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teamScoreId,
      referencedTable: $db.teamScores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamScoresTableAnnotationComposer(
            $db: $db,
            $table: $db.teamScores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TeamSetlistScoresTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TeamSetlistScoresTable,
          TeamSetlistScoreEntity,
          $$TeamSetlistScoresTableFilterComposer,
          $$TeamSetlistScoresTableOrderingComposer,
          $$TeamSetlistScoresTableAnnotationComposer,
          $$TeamSetlistScoresTableCreateCompanionBuilder,
          $$TeamSetlistScoresTableUpdateCompanionBuilder,
          (TeamSetlistScoreEntity, $$TeamSetlistScoresTableReferences),
          TeamSetlistScoreEntity,
          PrefetchHooks Function({bool teamSetlistId, bool teamScoreId})
        > {
  $$TeamSetlistScoresTableTableManager(
    _$AppDatabase db,
    $TeamSetlistScoresTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TeamSetlistScoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TeamSetlistScoresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TeamSetlistScoresTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> teamSetlistId = const Value.absent(),
                Value<String> teamScoreId = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TeamSetlistScoresCompanion(
                id: id,
                teamSetlistId: teamSetlistId,
                teamScoreId: teamScoreId,
                orderIndex: orderIndex,
                version: version,
                syncStatus: syncStatus,
                serverId: serverId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String teamSetlistId,
                required String teamScoreId,
                Value<int> orderIndex = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TeamSetlistScoresCompanion.insert(
                id: id,
                teamSetlistId: teamSetlistId,
                teamScoreId: teamScoreId,
                orderIndex: orderIndex,
                version: version,
                syncStatus: syncStatus,
                serverId: serverId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TeamSetlistScoresTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({teamSetlistId = false, teamScoreId = false}) {
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
                        if (teamSetlistId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.teamSetlistId,
                                    referencedTable:
                                        $$TeamSetlistScoresTableReferences
                                            ._teamSetlistIdTable(db),
                                    referencedColumn:
                                        $$TeamSetlistScoresTableReferences
                                            ._teamSetlistIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (teamScoreId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.teamScoreId,
                                    referencedTable:
                                        $$TeamSetlistScoresTableReferences
                                            ._teamScoreIdTable(db),
                                    referencedColumn:
                                        $$TeamSetlistScoresTableReferences
                                            ._teamScoreIdTable(db)
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

typedef $$TeamSetlistScoresTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TeamSetlistScoresTable,
      TeamSetlistScoreEntity,
      $$TeamSetlistScoresTableFilterComposer,
      $$TeamSetlistScoresTableOrderingComposer,
      $$TeamSetlistScoresTableAnnotationComposer,
      $$TeamSetlistScoresTableCreateCompanionBuilder,
      $$TeamSetlistScoresTableUpdateCompanionBuilder,
      (TeamSetlistScoreEntity, $$TeamSetlistScoresTableReferences),
      TeamSetlistScoreEntity,
      PrefetchHooks Function({bool teamSetlistId, bool teamScoreId})
    >;
typedef $$TeamSyncStateTableCreateCompanionBuilder =
    TeamSyncStateCompanion Function({
      Value<int> teamId,
      Value<int> teamLibraryVersion,
      Value<DateTime?> lastSyncAt,
    });
typedef $$TeamSyncStateTableUpdateCompanionBuilder =
    TeamSyncStateCompanion Function({
      Value<int> teamId,
      Value<int> teamLibraryVersion,
      Value<DateTime?> lastSyncAt,
    });

class $$TeamSyncStateTableFilterComposer
    extends Composer<_$AppDatabase, $TeamSyncStateTable> {
  $$TeamSyncStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get teamId => $composableBuilder(
    column: $table.teamId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get teamLibraryVersion => $composableBuilder(
    column: $table.teamLibraryVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TeamSyncStateTableOrderingComposer
    extends Composer<_$AppDatabase, $TeamSyncStateTable> {
  $$TeamSyncStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get teamId => $composableBuilder(
    column: $table.teamId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get teamLibraryVersion => $composableBuilder(
    column: $table.teamLibraryVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TeamSyncStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $TeamSyncStateTable> {
  $$TeamSyncStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get teamId =>
      $composableBuilder(column: $table.teamId, builder: (column) => column);

  GeneratedColumn<int> get teamLibraryVersion => $composableBuilder(
    column: $table.teamLibraryVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => column,
  );
}

class $$TeamSyncStateTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TeamSyncStateTable,
          TeamSyncStateEntity,
          $$TeamSyncStateTableFilterComposer,
          $$TeamSyncStateTableOrderingComposer,
          $$TeamSyncStateTableAnnotationComposer,
          $$TeamSyncStateTableCreateCompanionBuilder,
          $$TeamSyncStateTableUpdateCompanionBuilder,
          (
            TeamSyncStateEntity,
            BaseReferences<
              _$AppDatabase,
              $TeamSyncStateTable,
              TeamSyncStateEntity
            >,
          ),
          TeamSyncStateEntity,
          PrefetchHooks Function()
        > {
  $$TeamSyncStateTableTableManager(_$AppDatabase db, $TeamSyncStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TeamSyncStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TeamSyncStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TeamSyncStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> teamId = const Value.absent(),
                Value<int> teamLibraryVersion = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
              }) => TeamSyncStateCompanion(
                teamId: teamId,
                teamLibraryVersion: teamLibraryVersion,
                lastSyncAt: lastSyncAt,
              ),
          createCompanionCallback:
              ({
                Value<int> teamId = const Value.absent(),
                Value<int> teamLibraryVersion = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
              }) => TeamSyncStateCompanion.insert(
                teamId: teamId,
                teamLibraryVersion: teamLibraryVersion,
                lastSyncAt: lastSyncAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TeamSyncStateTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TeamSyncStateTable,
      TeamSyncStateEntity,
      $$TeamSyncStateTableFilterComposer,
      $$TeamSyncStateTableOrderingComposer,
      $$TeamSyncStateTableAnnotationComposer,
      $$TeamSyncStateTableCreateCompanionBuilder,
      $$TeamSyncStateTableUpdateCompanionBuilder,
      (
        TeamSyncStateEntity,
        BaseReferences<_$AppDatabase, $TeamSyncStateTable, TeamSyncStateEntity>,
      ),
      TeamSyncStateEntity,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ScoresTableTableManager get scores =>
      $$ScoresTableTableManager(_db, _db.scores);
  $$InstrumentScoresTableTableManager get instrumentScores =>
      $$InstrumentScoresTableTableManager(_db, _db.instrumentScores);
  $$AnnotationsTableTableManager get annotations =>
      $$AnnotationsTableTableManager(_db, _db.annotations);
  $$SetlistsTableTableManager get setlists =>
      $$SetlistsTableTableManager(_db, _db.setlists);
  $$SetlistScoresTableTableManager get setlistScores =>
      $$SetlistScoresTableTableManager(_db, _db.setlistScores);
  $$AppStateTableTableManager get appState =>
      $$AppStateTableTableManager(_db, _db.appState);
  $$SyncStateTableTableManager get syncState =>
      $$SyncStateTableTableManager(_db, _db.syncState);
  $$TeamsTableTableManager get teams =>
      $$TeamsTableTableManager(_db, _db.teams);
  $$TeamMembersTableTableManager get teamMembers =>
      $$TeamMembersTableTableManager(_db, _db.teamMembers);
  $$TeamScoresTableTableManager get teamScores =>
      $$TeamScoresTableTableManager(_db, _db.teamScores);
  $$TeamInstrumentScoresTableTableManager get teamInstrumentScores =>
      $$TeamInstrumentScoresTableTableManager(_db, _db.teamInstrumentScores);
  $$TeamSetlistsTableTableManager get teamSetlists =>
      $$TeamSetlistsTableTableManager(_db, _db.teamSetlists);
  $$TeamSetlistScoresTableTableManager get teamSetlistScores =>
      $$TeamSetlistScoresTableTableManager(_db, _db.teamSetlistScores);
  $$TeamSyncStateTableTableManager get teamSyncState =>
      $$TeamSyncStateTableTableManager(_db, _db.teamSyncState);
}
