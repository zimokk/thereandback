// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SelectedQuestRowsTable extends SelectedQuestRows
    with TableInfo<$SelectedQuestRowsTable, SelectedQuestRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SelectedQuestRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _journeyIdMeta = const VerificationMeta(
    'journeyId',
  );
  @override
  late final GeneratedColumn<String> journeyId = GeneratedColumn<String>(
    'journey_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [ownerId, journeyId, startedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'selected_quest_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<SelectedQuestRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('journey_id')) {
      context.handle(
        _journeyIdMeta,
        journeyId.isAcceptableOrUnknown(data['journey_id']!, _journeyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_journeyIdMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ownerId};
  @override
  SelectedQuestRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SelectedQuestRow(
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      journeyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}journey_id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
    );
  }

  @override
  $SelectedQuestRowsTable createAlias(String alias) {
    return $SelectedQuestRowsTable(attachedDatabase, alias);
  }
}

class SelectedQuestRow extends DataClass
    implements Insertable<SelectedQuestRow> {
  final String ownerId;
  final String journeyId;
  final DateTime startedAt;
  const SelectedQuestRow({
    required this.ownerId,
    required this.journeyId,
    required this.startedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['owner_id'] = Variable<String>(ownerId);
    map['journey_id'] = Variable<String>(journeyId);
    map['started_at'] = Variable<DateTime>(startedAt);
    return map;
  }

  SelectedQuestRowsCompanion toCompanion(bool nullToAbsent) {
    return SelectedQuestRowsCompanion(
      ownerId: Value(ownerId),
      journeyId: Value(journeyId),
      startedAt: Value(startedAt),
    );
  }

  factory SelectedQuestRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SelectedQuestRow(
      ownerId: serializer.fromJson<String>(json['ownerId']),
      journeyId: serializer.fromJson<String>(json['journeyId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ownerId': serializer.toJson<String>(ownerId),
      'journeyId': serializer.toJson<String>(journeyId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
    };
  }

  SelectedQuestRow copyWith({
    String? ownerId,
    String? journeyId,
    DateTime? startedAt,
  }) => SelectedQuestRow(
    ownerId: ownerId ?? this.ownerId,
    journeyId: journeyId ?? this.journeyId,
    startedAt: startedAt ?? this.startedAt,
  );
  SelectedQuestRow copyWithCompanion(SelectedQuestRowsCompanion data) {
    return SelectedQuestRow(
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      journeyId: data.journeyId.present ? data.journeyId.value : this.journeyId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SelectedQuestRow(')
          ..write('ownerId: $ownerId, ')
          ..write('journeyId: $journeyId, ')
          ..write('startedAt: $startedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(ownerId, journeyId, startedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SelectedQuestRow &&
          other.ownerId == this.ownerId &&
          other.journeyId == this.journeyId &&
          other.startedAt == this.startedAt);
}

class SelectedQuestRowsCompanion extends UpdateCompanion<SelectedQuestRow> {
  final Value<String> ownerId;
  final Value<String> journeyId;
  final Value<DateTime> startedAt;
  final Value<int> rowid;
  const SelectedQuestRowsCompanion({
    this.ownerId = const Value.absent(),
    this.journeyId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SelectedQuestRowsCompanion.insert({
    required String ownerId,
    required String journeyId,
    required DateTime startedAt,
    this.rowid = const Value.absent(),
  }) : ownerId = Value(ownerId),
       journeyId = Value(journeyId),
       startedAt = Value(startedAt);
  static Insertable<SelectedQuestRow> custom({
    Expression<String>? ownerId,
    Expression<String>? journeyId,
    Expression<DateTime>? startedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ownerId != null) 'owner_id': ownerId,
      if (journeyId != null) 'journey_id': journeyId,
      if (startedAt != null) 'started_at': startedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SelectedQuestRowsCompanion copyWith({
    Value<String>? ownerId,
    Value<String>? journeyId,
    Value<DateTime>? startedAt,
    Value<int>? rowid,
  }) {
    return SelectedQuestRowsCompanion(
      ownerId: ownerId ?? this.ownerId,
      journeyId: journeyId ?? this.journeyId,
      startedAt: startedAt ?? this.startedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (journeyId.present) {
      map['journey_id'] = Variable<String>(journeyId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SelectedQuestRowsCompanion(')
          ..write('ownerId: $ownerId, ')
          ..write('journeyId: $journeyId, ')
          ..write('startedAt: $startedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StepIntervalRecordsTable extends StepIntervalRecords
    with TableInfo<$StepIntervalRecordsTable, StepIntervalRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StepIntervalRecordsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _journeyIdMeta = const VerificationMeta(
    'journeyId',
  );
  @override
  late final GeneratedColumn<String> journeyId = GeneratedColumn<String>(
    'journey_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intervalStartMeta = const VerificationMeta(
    'intervalStart',
  );
  @override
  late final GeneratedColumn<DateTime> intervalStart =
      GeneratedColumn<DateTime>(
        'interval_start',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _intervalEndMeta = const VerificationMeta(
    'intervalEnd',
  );
  @override
  late final GeneratedColumn<DateTime> intervalEnd = GeneratedColumn<DateTime>(
    'interval_end',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stepsMeta = const VerificationMeta('steps');
  @override
  late final GeneratedColumn<int> steps = GeneratedColumn<int>(
    'steps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _walkingDistanceMetersMeta =
      const VerificationMeta('walkingDistanceMeters');
  @override
  late final GeneratedColumn<int> walkingDistanceMeters = GeneratedColumn<int>(
    'walking_distance_meters',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resolvedMetersMeta = const VerificationMeta(
    'resolvedMeters',
  );
  @override
  late final GeneratedColumn<int> resolvedMeters = GeneratedColumn<int>(
    'resolved_meters',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _flaggedPaceMeta = const VerificationMeta(
    'flaggedPace',
  );
  @override
  late final GeneratedColumn<bool> flaggedPace = GeneratedColumn<bool>(
    'flagged_pace',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("flagged_pace" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ownerId,
    journeyId,
    intervalStart,
    intervalEnd,
    steps,
    walkingDistanceMeters,
    resolvedMeters,
    flaggedPace,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'step_interval_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<StepIntervalRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('journey_id')) {
      context.handle(
        _journeyIdMeta,
        journeyId.isAcceptableOrUnknown(data['journey_id']!, _journeyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_journeyIdMeta);
    }
    if (data.containsKey('interval_start')) {
      context.handle(
        _intervalStartMeta,
        intervalStart.isAcceptableOrUnknown(
          data['interval_start']!,
          _intervalStartMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_intervalStartMeta);
    }
    if (data.containsKey('interval_end')) {
      context.handle(
        _intervalEndMeta,
        intervalEnd.isAcceptableOrUnknown(
          data['interval_end']!,
          _intervalEndMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_intervalEndMeta);
    }
    if (data.containsKey('steps')) {
      context.handle(
        _stepsMeta,
        steps.isAcceptableOrUnknown(data['steps']!, _stepsMeta),
      );
    } else if (isInserting) {
      context.missing(_stepsMeta);
    }
    if (data.containsKey('walking_distance_meters')) {
      context.handle(
        _walkingDistanceMetersMeta,
        walkingDistanceMeters.isAcceptableOrUnknown(
          data['walking_distance_meters']!,
          _walkingDistanceMetersMeta,
        ),
      );
    }
    if (data.containsKey('resolved_meters')) {
      context.handle(
        _resolvedMetersMeta,
        resolvedMeters.isAcceptableOrUnknown(
          data['resolved_meters']!,
          _resolvedMetersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_resolvedMetersMeta);
    }
    if (data.containsKey('flagged_pace')) {
      context.handle(
        _flaggedPaceMeta,
        flaggedPace.isAcceptableOrUnknown(
          data['flagged_pace']!,
          _flaggedPaceMeta,
        ),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {ownerId, journeyId, intervalStart},
  ];
  @override
  StepIntervalRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StepIntervalRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      journeyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}journey_id'],
      )!,
      intervalStart: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}interval_start'],
      )!,
      intervalEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}interval_end'],
      )!,
      steps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}steps'],
      )!,
      walkingDistanceMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}walking_distance_meters'],
      ),
      resolvedMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}resolved_meters'],
      )!,
      flaggedPace: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}flagged_pace'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $StepIntervalRecordsTable createAlias(String alias) {
    return $StepIntervalRecordsTable(attachedDatabase, alias);
  }
}

class StepIntervalRecord extends DataClass
    implements Insertable<StepIntervalRecord> {
  final int id;
  final String ownerId;
  final String journeyId;
  final DateTime intervalStart;
  final DateTime intervalEnd;
  final int steps;
  final int? walkingDistanceMeters;
  final int resolvedMeters;
  final bool flaggedPace;
  final DateTime syncedAt;
  const StepIntervalRecord({
    required this.id,
    required this.ownerId,
    required this.journeyId,
    required this.intervalStart,
    required this.intervalEnd,
    required this.steps,
    this.walkingDistanceMeters,
    required this.resolvedMeters,
    required this.flaggedPace,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['owner_id'] = Variable<String>(ownerId);
    map['journey_id'] = Variable<String>(journeyId);
    map['interval_start'] = Variable<DateTime>(intervalStart);
    map['interval_end'] = Variable<DateTime>(intervalEnd);
    map['steps'] = Variable<int>(steps);
    if (!nullToAbsent || walkingDistanceMeters != null) {
      map['walking_distance_meters'] = Variable<int>(walkingDistanceMeters);
    }
    map['resolved_meters'] = Variable<int>(resolvedMeters);
    map['flagged_pace'] = Variable<bool>(flaggedPace);
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  StepIntervalRecordsCompanion toCompanion(bool nullToAbsent) {
    return StepIntervalRecordsCompanion(
      id: Value(id),
      ownerId: Value(ownerId),
      journeyId: Value(journeyId),
      intervalStart: Value(intervalStart),
      intervalEnd: Value(intervalEnd),
      steps: Value(steps),
      walkingDistanceMeters: walkingDistanceMeters == null && nullToAbsent
          ? const Value.absent()
          : Value(walkingDistanceMeters),
      resolvedMeters: Value(resolvedMeters),
      flaggedPace: Value(flaggedPace),
      syncedAt: Value(syncedAt),
    );
  }

  factory StepIntervalRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StepIntervalRecord(
      id: serializer.fromJson<int>(json['id']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      journeyId: serializer.fromJson<String>(json['journeyId']),
      intervalStart: serializer.fromJson<DateTime>(json['intervalStart']),
      intervalEnd: serializer.fromJson<DateTime>(json['intervalEnd']),
      steps: serializer.fromJson<int>(json['steps']),
      walkingDistanceMeters: serializer.fromJson<int?>(
        json['walkingDistanceMeters'],
      ),
      resolvedMeters: serializer.fromJson<int>(json['resolvedMeters']),
      flaggedPace: serializer.fromJson<bool>(json['flaggedPace']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ownerId': serializer.toJson<String>(ownerId),
      'journeyId': serializer.toJson<String>(journeyId),
      'intervalStart': serializer.toJson<DateTime>(intervalStart),
      'intervalEnd': serializer.toJson<DateTime>(intervalEnd),
      'steps': serializer.toJson<int>(steps),
      'walkingDistanceMeters': serializer.toJson<int?>(walkingDistanceMeters),
      'resolvedMeters': serializer.toJson<int>(resolvedMeters),
      'flaggedPace': serializer.toJson<bool>(flaggedPace),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  StepIntervalRecord copyWith({
    int? id,
    String? ownerId,
    String? journeyId,
    DateTime? intervalStart,
    DateTime? intervalEnd,
    int? steps,
    Value<int?> walkingDistanceMeters = const Value.absent(),
    int? resolvedMeters,
    bool? flaggedPace,
    DateTime? syncedAt,
  }) => StepIntervalRecord(
    id: id ?? this.id,
    ownerId: ownerId ?? this.ownerId,
    journeyId: journeyId ?? this.journeyId,
    intervalStart: intervalStart ?? this.intervalStart,
    intervalEnd: intervalEnd ?? this.intervalEnd,
    steps: steps ?? this.steps,
    walkingDistanceMeters: walkingDistanceMeters.present
        ? walkingDistanceMeters.value
        : this.walkingDistanceMeters,
    resolvedMeters: resolvedMeters ?? this.resolvedMeters,
    flaggedPace: flaggedPace ?? this.flaggedPace,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  StepIntervalRecord copyWithCompanion(StepIntervalRecordsCompanion data) {
    return StepIntervalRecord(
      id: data.id.present ? data.id.value : this.id,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      journeyId: data.journeyId.present ? data.journeyId.value : this.journeyId,
      intervalStart: data.intervalStart.present
          ? data.intervalStart.value
          : this.intervalStart,
      intervalEnd: data.intervalEnd.present
          ? data.intervalEnd.value
          : this.intervalEnd,
      steps: data.steps.present ? data.steps.value : this.steps,
      walkingDistanceMeters: data.walkingDistanceMeters.present
          ? data.walkingDistanceMeters.value
          : this.walkingDistanceMeters,
      resolvedMeters: data.resolvedMeters.present
          ? data.resolvedMeters.value
          : this.resolvedMeters,
      flaggedPace: data.flaggedPace.present
          ? data.flaggedPace.value
          : this.flaggedPace,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StepIntervalRecord(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('journeyId: $journeyId, ')
          ..write('intervalStart: $intervalStart, ')
          ..write('intervalEnd: $intervalEnd, ')
          ..write('steps: $steps, ')
          ..write('walkingDistanceMeters: $walkingDistanceMeters, ')
          ..write('resolvedMeters: $resolvedMeters, ')
          ..write('flaggedPace: $flaggedPace, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ownerId,
    journeyId,
    intervalStart,
    intervalEnd,
    steps,
    walkingDistanceMeters,
    resolvedMeters,
    flaggedPace,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StepIntervalRecord &&
          other.id == this.id &&
          other.ownerId == this.ownerId &&
          other.journeyId == this.journeyId &&
          other.intervalStart == this.intervalStart &&
          other.intervalEnd == this.intervalEnd &&
          other.steps == this.steps &&
          other.walkingDistanceMeters == this.walkingDistanceMeters &&
          other.resolvedMeters == this.resolvedMeters &&
          other.flaggedPace == this.flaggedPace &&
          other.syncedAt == this.syncedAt);
}

class StepIntervalRecordsCompanion extends UpdateCompanion<StepIntervalRecord> {
  final Value<int> id;
  final Value<String> ownerId;
  final Value<String> journeyId;
  final Value<DateTime> intervalStart;
  final Value<DateTime> intervalEnd;
  final Value<int> steps;
  final Value<int?> walkingDistanceMeters;
  final Value<int> resolvedMeters;
  final Value<bool> flaggedPace;
  final Value<DateTime> syncedAt;
  const StepIntervalRecordsCompanion({
    this.id = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.journeyId = const Value.absent(),
    this.intervalStart = const Value.absent(),
    this.intervalEnd = const Value.absent(),
    this.steps = const Value.absent(),
    this.walkingDistanceMeters = const Value.absent(),
    this.resolvedMeters = const Value.absent(),
    this.flaggedPace = const Value.absent(),
    this.syncedAt = const Value.absent(),
  });
  StepIntervalRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String ownerId,
    required String journeyId,
    required DateTime intervalStart,
    required DateTime intervalEnd,
    required int steps,
    this.walkingDistanceMeters = const Value.absent(),
    required int resolvedMeters,
    this.flaggedPace = const Value.absent(),
    required DateTime syncedAt,
  }) : ownerId = Value(ownerId),
       journeyId = Value(journeyId),
       intervalStart = Value(intervalStart),
       intervalEnd = Value(intervalEnd),
       steps = Value(steps),
       resolvedMeters = Value(resolvedMeters),
       syncedAt = Value(syncedAt);
  static Insertable<StepIntervalRecord> custom({
    Expression<int>? id,
    Expression<String>? ownerId,
    Expression<String>? journeyId,
    Expression<DateTime>? intervalStart,
    Expression<DateTime>? intervalEnd,
    Expression<int>? steps,
    Expression<int>? walkingDistanceMeters,
    Expression<int>? resolvedMeters,
    Expression<bool>? flaggedPace,
    Expression<DateTime>? syncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerId != null) 'owner_id': ownerId,
      if (journeyId != null) 'journey_id': journeyId,
      if (intervalStart != null) 'interval_start': intervalStart,
      if (intervalEnd != null) 'interval_end': intervalEnd,
      if (steps != null) 'steps': steps,
      if (walkingDistanceMeters != null)
        'walking_distance_meters': walkingDistanceMeters,
      if (resolvedMeters != null) 'resolved_meters': resolvedMeters,
      if (flaggedPace != null) 'flagged_pace': flaggedPace,
      if (syncedAt != null) 'synced_at': syncedAt,
    });
  }

  StepIntervalRecordsCompanion copyWith({
    Value<int>? id,
    Value<String>? ownerId,
    Value<String>? journeyId,
    Value<DateTime>? intervalStart,
    Value<DateTime>? intervalEnd,
    Value<int>? steps,
    Value<int?>? walkingDistanceMeters,
    Value<int>? resolvedMeters,
    Value<bool>? flaggedPace,
    Value<DateTime>? syncedAt,
  }) {
    return StepIntervalRecordsCompanion(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      journeyId: journeyId ?? this.journeyId,
      intervalStart: intervalStart ?? this.intervalStart,
      intervalEnd: intervalEnd ?? this.intervalEnd,
      steps: steps ?? this.steps,
      walkingDistanceMeters:
          walkingDistanceMeters ?? this.walkingDistanceMeters,
      resolvedMeters: resolvedMeters ?? this.resolvedMeters,
      flaggedPace: flaggedPace ?? this.flaggedPace,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (journeyId.present) {
      map['journey_id'] = Variable<String>(journeyId.value);
    }
    if (intervalStart.present) {
      map['interval_start'] = Variable<DateTime>(intervalStart.value);
    }
    if (intervalEnd.present) {
      map['interval_end'] = Variable<DateTime>(intervalEnd.value);
    }
    if (steps.present) {
      map['steps'] = Variable<int>(steps.value);
    }
    if (walkingDistanceMeters.present) {
      map['walking_distance_meters'] = Variable<int>(
        walkingDistanceMeters.value,
      );
    }
    if (resolvedMeters.present) {
      map['resolved_meters'] = Variable<int>(resolvedMeters.value);
    }
    if (flaggedPace.present) {
      map['flagged_pace'] = Variable<bool>(flaggedPace.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StepIntervalRecordsCompanion(')
          ..write('id: $id, ')
          ..write('ownerId: $ownerId, ')
          ..write('journeyId: $journeyId, ')
          ..write('intervalStart: $intervalStart, ')
          ..write('intervalEnd: $intervalEnd, ')
          ..write('steps: $steps, ')
          ..write('walkingDistanceMeters: $walkingDistanceMeters, ')
          ..write('resolvedMeters: $resolvedMeters, ')
          ..write('flaggedPace: $flaggedPace, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }
}

class $LockScreenPreferenceRowsTable extends LockScreenPreferenceRows
    with TableInfo<$LockScreenPreferenceRowsTable, LockScreenPreferenceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LockScreenPreferenceRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [ownerId, enabled];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lock_screen_preference_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<LockScreenPreferenceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    } else if (isInserting) {
      context.missing(_enabledMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ownerId};
  @override
  LockScreenPreferenceRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LockScreenPreferenceRow(
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
    );
  }

  @override
  $LockScreenPreferenceRowsTable createAlias(String alias) {
    return $LockScreenPreferenceRowsTable(attachedDatabase, alias);
  }
}

class LockScreenPreferenceRow extends DataClass
    implements Insertable<LockScreenPreferenceRow> {
  final String ownerId;
  final bool enabled;
  const LockScreenPreferenceRow({required this.ownerId, required this.enabled});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['owner_id'] = Variable<String>(ownerId);
    map['enabled'] = Variable<bool>(enabled);
    return map;
  }

  LockScreenPreferenceRowsCompanion toCompanion(bool nullToAbsent) {
    return LockScreenPreferenceRowsCompanion(
      ownerId: Value(ownerId),
      enabled: Value(enabled),
    );
  }

  factory LockScreenPreferenceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LockScreenPreferenceRow(
      ownerId: serializer.fromJson<String>(json['ownerId']),
      enabled: serializer.fromJson<bool>(json['enabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ownerId': serializer.toJson<String>(ownerId),
      'enabled': serializer.toJson<bool>(enabled),
    };
  }

  LockScreenPreferenceRow copyWith({String? ownerId, bool? enabled}) =>
      LockScreenPreferenceRow(
        ownerId: ownerId ?? this.ownerId,
        enabled: enabled ?? this.enabled,
      );
  LockScreenPreferenceRow copyWithCompanion(
    LockScreenPreferenceRowsCompanion data,
  ) {
    return LockScreenPreferenceRow(
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LockScreenPreferenceRow(')
          ..write('ownerId: $ownerId, ')
          ..write('enabled: $enabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(ownerId, enabled);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LockScreenPreferenceRow &&
          other.ownerId == this.ownerId &&
          other.enabled == this.enabled);
}

class LockScreenPreferenceRowsCompanion
    extends UpdateCompanion<LockScreenPreferenceRow> {
  final Value<String> ownerId;
  final Value<bool> enabled;
  final Value<int> rowid;
  const LockScreenPreferenceRowsCompanion({
    this.ownerId = const Value.absent(),
    this.enabled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LockScreenPreferenceRowsCompanion.insert({
    required String ownerId,
    required bool enabled,
    this.rowid = const Value.absent(),
  }) : ownerId = Value(ownerId),
       enabled = Value(enabled);
  static Insertable<LockScreenPreferenceRow> custom({
    Expression<String>? ownerId,
    Expression<bool>? enabled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ownerId != null) 'owner_id': ownerId,
      if (enabled != null) 'enabled': enabled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LockScreenPreferenceRowsCompanion copyWith({
    Value<String>? ownerId,
    Value<bool>? enabled,
    Value<int>? rowid,
  }) {
    return LockScreenPreferenceRowsCompanion(
      ownerId: ownerId ?? this.ownerId,
      enabled: enabled ?? this.enabled,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LockScreenPreferenceRowsCompanion(')
          ..write('ownerId: $ownerId, ')
          ..write('enabled: $enabled, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserPreferenceRowsTable extends UserPreferenceRows
    with TableInfo<$UserPreferenceRowsTable, UserPreferenceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserPreferenceRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localeCodeMeta = const VerificationMeta(
    'localeCode',
  );
  @override
  late final GeneratedColumn<String> localeCode = GeneratedColumn<String>(
    'locale_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _themeOverrideMeta = const VerificationMeta(
    'themeOverride',
  );
  @override
  late final GeneratedColumn<String> themeOverride = GeneratedColumn<String>(
    'theme_override',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _backgroundMusicEnabledMeta =
      const VerificationMeta('backgroundMusicEnabled');
  @override
  late final GeneratedColumn<bool> backgroundMusicEnabled =
      GeneratedColumn<bool>(
        'background_music_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("background_music_enabled" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _showFriendsOnMapMeta = const VerificationMeta(
    'showFriendsOnMap',
  );
  @override
  late final GeneratedColumn<bool> showFriendsOnMap = GeneratedColumn<bool>(
    'show_friends_on_map',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_friends_on_map" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    ownerId,
    localeCode,
    themeOverride,
    backgroundMusicEnabled,
    showFriendsOnMap,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_preference_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserPreferenceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('locale_code')) {
      context.handle(
        _localeCodeMeta,
        localeCode.isAcceptableOrUnknown(
          data['locale_code']!,
          _localeCodeMeta,
        ),
      );
    }
    if (data.containsKey('theme_override')) {
      context.handle(
        _themeOverrideMeta,
        themeOverride.isAcceptableOrUnknown(
          data['theme_override']!,
          _themeOverrideMeta,
        ),
      );
    }
    if (data.containsKey('background_music_enabled')) {
      context.handle(
        _backgroundMusicEnabledMeta,
        backgroundMusicEnabled.isAcceptableOrUnknown(
          data['background_music_enabled']!,
          _backgroundMusicEnabledMeta,
        ),
      );
    }
    if (data.containsKey('show_friends_on_map')) {
      context.handle(
        _showFriendsOnMapMeta,
        showFriendsOnMap.isAcceptableOrUnknown(
          data['show_friends_on_map']!,
          _showFriendsOnMapMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ownerId};
  @override
  UserPreferenceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserPreferenceRow(
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      localeCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}locale_code'],
      ),
      themeOverride: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_override'],
      ),
      backgroundMusicEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}background_music_enabled'],
      )!,
      showFriendsOnMap: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_friends_on_map'],
      )!,
    );
  }

  @override
  $UserPreferenceRowsTable createAlias(String alias) {
    return $UserPreferenceRowsTable(attachedDatabase, alias);
  }
}

class UserPreferenceRow extends DataClass
    implements Insertable<UserPreferenceRow> {
  final String ownerId;
  final String? localeCode;
  final String? themeOverride;
  final bool backgroundMusicEnabled;
  final bool showFriendsOnMap;
  const UserPreferenceRow({
    required this.ownerId,
    this.localeCode,
    this.themeOverride,
    required this.backgroundMusicEnabled,
    required this.showFriendsOnMap,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['owner_id'] = Variable<String>(ownerId);
    if (!nullToAbsent || localeCode != null) {
      map['locale_code'] = Variable<String>(localeCode);
    }
    if (!nullToAbsent || themeOverride != null) {
      map['theme_override'] = Variable<String>(themeOverride);
    }
    map['background_music_enabled'] = Variable<bool>(backgroundMusicEnabled);
    map['show_friends_on_map'] = Variable<bool>(showFriendsOnMap);
    return map;
  }

  UserPreferenceRowsCompanion toCompanion(bool nullToAbsent) {
    return UserPreferenceRowsCompanion(
      ownerId: Value(ownerId),
      localeCode: localeCode == null && nullToAbsent
          ? const Value.absent()
          : Value(localeCode),
      themeOverride: themeOverride == null && nullToAbsent
          ? const Value.absent()
          : Value(themeOverride),
      backgroundMusicEnabled: Value(backgroundMusicEnabled),
      showFriendsOnMap: Value(showFriendsOnMap),
    );
  }

  factory UserPreferenceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserPreferenceRow(
      ownerId: serializer.fromJson<String>(json['ownerId']),
      localeCode: serializer.fromJson<String?>(json['localeCode']),
      themeOverride: serializer.fromJson<String?>(json['themeOverride']),
      backgroundMusicEnabled: serializer.fromJson<bool>(
        json['backgroundMusicEnabled'],
      ),
      showFriendsOnMap: serializer.fromJson<bool>(json['showFriendsOnMap']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ownerId': serializer.toJson<String>(ownerId),
      'localeCode': serializer.toJson<String?>(localeCode),
      'themeOverride': serializer.toJson<String?>(themeOverride),
      'backgroundMusicEnabled': serializer.toJson<bool>(
        backgroundMusicEnabled,
      ),
      'showFriendsOnMap': serializer.toJson<bool>(showFriendsOnMap),
    };
  }

  UserPreferenceRow copyWith({
    String? ownerId,
    Value<String?> localeCode = const Value.absent(),
    Value<String?> themeOverride = const Value.absent(),
    bool? backgroundMusicEnabled,
    bool? showFriendsOnMap,
  }) => UserPreferenceRow(
    ownerId: ownerId ?? this.ownerId,
    localeCode: localeCode.present ? localeCode.value : this.localeCode,
    themeOverride: themeOverride.present
        ? themeOverride.value
        : this.themeOverride,
    backgroundMusicEnabled:
        backgroundMusicEnabled ?? this.backgroundMusicEnabled,
    showFriendsOnMap: showFriendsOnMap ?? this.showFriendsOnMap,
  );
  UserPreferenceRow copyWithCompanion(UserPreferenceRowsCompanion data) {
    return UserPreferenceRow(
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      localeCode: data.localeCode.present
          ? data.localeCode.value
          : this.localeCode,
      themeOverride: data.themeOverride.present
          ? data.themeOverride.value
          : this.themeOverride,
      backgroundMusicEnabled: data.backgroundMusicEnabled.present
          ? data.backgroundMusicEnabled.value
          : this.backgroundMusicEnabled,
      showFriendsOnMap: data.showFriendsOnMap.present
          ? data.showFriendsOnMap.value
          : this.showFriendsOnMap,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserPreferenceRow(')
          ..write('ownerId: $ownerId, ')
          ..write('localeCode: $localeCode, ')
          ..write('themeOverride: $themeOverride, ')
          ..write('backgroundMusicEnabled: $backgroundMusicEnabled, ')
          ..write('showFriendsOnMap: $showFriendsOnMap')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    ownerId,
    localeCode,
    themeOverride,
    backgroundMusicEnabled,
    showFriendsOnMap,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserPreferenceRow &&
          other.ownerId == this.ownerId &&
          other.localeCode == this.localeCode &&
          other.themeOverride == this.themeOverride &&
          other.backgroundMusicEnabled == this.backgroundMusicEnabled &&
          other.showFriendsOnMap == this.showFriendsOnMap);
}

class UserPreferenceRowsCompanion extends UpdateCompanion<UserPreferenceRow> {
  final Value<String> ownerId;
  final Value<String?> localeCode;
  final Value<String?> themeOverride;
  final Value<bool> backgroundMusicEnabled;
  final Value<bool> showFriendsOnMap;
  final Value<int> rowid;
  const UserPreferenceRowsCompanion({
    this.ownerId = const Value.absent(),
    this.localeCode = const Value.absent(),
    this.themeOverride = const Value.absent(),
    this.backgroundMusicEnabled = const Value.absent(),
    this.showFriendsOnMap = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserPreferenceRowsCompanion.insert({
    required String ownerId,
    this.localeCode = const Value.absent(),
    this.themeOverride = const Value.absent(),
    this.backgroundMusicEnabled = const Value.absent(),
    this.showFriendsOnMap = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : ownerId = Value(ownerId);
  static Insertable<UserPreferenceRow> custom({
    Expression<String>? ownerId,
    Expression<String>? localeCode,
    Expression<String>? themeOverride,
    Expression<bool>? backgroundMusicEnabled,
    Expression<bool>? showFriendsOnMap,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ownerId != null) 'owner_id': ownerId,
      if (localeCode != null) 'locale_code': localeCode,
      if (themeOverride != null) 'theme_override': themeOverride,
      if (backgroundMusicEnabled != null)
        'background_music_enabled': backgroundMusicEnabled,
      if (showFriendsOnMap != null) 'show_friends_on_map': showFriendsOnMap,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserPreferenceRowsCompanion copyWith({
    Value<String>? ownerId,
    Value<String?>? localeCode,
    Value<String?>? themeOverride,
    Value<bool>? backgroundMusicEnabled,
    Value<bool>? showFriendsOnMap,
    Value<int>? rowid,
  }) {
    return UserPreferenceRowsCompanion(
      ownerId: ownerId ?? this.ownerId,
      localeCode: localeCode ?? this.localeCode,
      themeOverride: themeOverride ?? this.themeOverride,
      backgroundMusicEnabled:
          backgroundMusicEnabled ?? this.backgroundMusicEnabled,
      showFriendsOnMap: showFriendsOnMap ?? this.showFriendsOnMap,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (localeCode.present) {
      map['locale_code'] = Variable<String>(localeCode.value);
    }
    if (themeOverride.present) {
      map['theme_override'] = Variable<String>(themeOverride.value);
    }
    if (backgroundMusicEnabled.present) {
      map['background_music_enabled'] = Variable<bool>(
        backgroundMusicEnabled.value,
      );
    }
    if (showFriendsOnMap.present) {
      map['show_friends_on_map'] = Variable<bool>(showFriendsOnMap.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserPreferenceRowsCompanion(')
          ..write('ownerId: $ownerId, ')
          ..write('localeCode: $localeCode, ')
          ..write('themeOverride: $themeOverride, ')
          ..write('backgroundMusicEnabled: $backgroundMusicEnabled, ')
          ..write('showFriendsOnMap: $showFriendsOnMap, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AchievementUnlockRowsTable extends AchievementUnlockRows
    with TableInfo<$AchievementUnlockRowsTable, AchievementUnlockRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AchievementUnlockRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _achievementIdMeta = const VerificationMeta(
    'achievementId',
  );
  @override
  late final GeneratedColumn<String> achievementId = GeneratedColumn<String>(
    'achievement_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unlockedLocalDateMeta = const VerificationMeta(
    'unlockedLocalDate',
  );
  @override
  late final GeneratedColumn<DateTime> unlockedLocalDate =
      GeneratedColumn<DateTime>(
        'unlocked_local_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    ownerId,
    achievementId,
    unlockedLocalDate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'achievement_unlock_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<AchievementUnlockRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('achievement_id')) {
      context.handle(
        _achievementIdMeta,
        achievementId.isAcceptableOrUnknown(
          data['achievement_id']!,
          _achievementIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_achievementIdMeta);
    }
    if (data.containsKey('unlocked_local_date')) {
      context.handle(
        _unlockedLocalDateMeta,
        unlockedLocalDate.isAcceptableOrUnknown(
          data['unlocked_local_date']!,
          _unlockedLocalDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_unlockedLocalDateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    ownerId,
    achievementId,
    unlockedLocalDate,
  };
  @override
  AchievementUnlockRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AchievementUnlockRow(
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      achievementId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}achievement_id'],
      )!,
      unlockedLocalDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}unlocked_local_date'],
      )!,
    );
  }

  @override
  $AchievementUnlockRowsTable createAlias(String alias) {
    return $AchievementUnlockRowsTable(attachedDatabase, alias);
  }
}

class AchievementUnlockRow extends DataClass
    implements Insertable<AchievementUnlockRow> {
  final String ownerId;
  final String achievementId;
  final DateTime unlockedLocalDate;
  const AchievementUnlockRow({
    required this.ownerId,
    required this.achievementId,
    required this.unlockedLocalDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['owner_id'] = Variable<String>(ownerId);
    map['achievement_id'] = Variable<String>(achievementId);
    map['unlocked_local_date'] = Variable<DateTime>(unlockedLocalDate);
    return map;
  }

  AchievementUnlockRowsCompanion toCompanion(bool nullToAbsent) {
    return AchievementUnlockRowsCompanion(
      ownerId: Value(ownerId),
      achievementId: Value(achievementId),
      unlockedLocalDate: Value(unlockedLocalDate),
    );
  }

  factory AchievementUnlockRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AchievementUnlockRow(
      ownerId: serializer.fromJson<String>(json['ownerId']),
      achievementId: serializer.fromJson<String>(json['achievementId']),
      unlockedLocalDate: serializer.fromJson<DateTime>(
        json['unlockedLocalDate'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ownerId': serializer.toJson<String>(ownerId),
      'achievementId': serializer.toJson<String>(achievementId),
      'unlockedLocalDate': serializer.toJson<DateTime>(unlockedLocalDate),
    };
  }

  AchievementUnlockRow copyWith({
    String? ownerId,
    String? achievementId,
    DateTime? unlockedLocalDate,
  }) => AchievementUnlockRow(
    ownerId: ownerId ?? this.ownerId,
    achievementId: achievementId ?? this.achievementId,
    unlockedLocalDate: unlockedLocalDate ?? this.unlockedLocalDate,
  );
  AchievementUnlockRow copyWithCompanion(AchievementUnlockRowsCompanion data) {
    return AchievementUnlockRow(
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      achievementId: data.achievementId.present
          ? data.achievementId.value
          : this.achievementId,
      unlockedLocalDate: data.unlockedLocalDate.present
          ? data.unlockedLocalDate.value
          : this.unlockedLocalDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AchievementUnlockRow(')
          ..write('ownerId: $ownerId, ')
          ..write('achievementId: $achievementId, ')
          ..write('unlockedLocalDate: $unlockedLocalDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(ownerId, achievementId, unlockedLocalDate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AchievementUnlockRow &&
          other.ownerId == this.ownerId &&
          other.achievementId == this.achievementId &&
          other.unlockedLocalDate == this.unlockedLocalDate);
}

class AchievementUnlockRowsCompanion
    extends UpdateCompanion<AchievementUnlockRow> {
  final Value<String> ownerId;
  final Value<String> achievementId;
  final Value<DateTime> unlockedLocalDate;
  final Value<int> rowid;
  const AchievementUnlockRowsCompanion({
    this.ownerId = const Value.absent(),
    this.achievementId = const Value.absent(),
    this.unlockedLocalDate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AchievementUnlockRowsCompanion.insert({
    required String ownerId,
    required String achievementId,
    required DateTime unlockedLocalDate,
    this.rowid = const Value.absent(),
  }) : ownerId = Value(ownerId),
       achievementId = Value(achievementId),
       unlockedLocalDate = Value(unlockedLocalDate);
  static Insertable<AchievementUnlockRow> custom({
    Expression<String>? ownerId,
    Expression<String>? achievementId,
    Expression<DateTime>? unlockedLocalDate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ownerId != null) 'owner_id': ownerId,
      if (achievementId != null) 'achievement_id': achievementId,
      if (unlockedLocalDate != null) 'unlocked_local_date': unlockedLocalDate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AchievementUnlockRowsCompanion copyWith({
    Value<String>? ownerId,
    Value<String>? achievementId,
    Value<DateTime>? unlockedLocalDate,
    Value<int>? rowid,
  }) {
    return AchievementUnlockRowsCompanion(
      ownerId: ownerId ?? this.ownerId,
      achievementId: achievementId ?? this.achievementId,
      unlockedLocalDate: unlockedLocalDate ?? this.unlockedLocalDate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (achievementId.present) {
      map['achievement_id'] = Variable<String>(achievementId.value);
    }
    if (unlockedLocalDate.present) {
      map['unlocked_local_date'] = Variable<DateTime>(unlockedLocalDate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AchievementUnlockRowsCompanion(')
          ..write('ownerId: $ownerId, ')
          ..write('achievementId: $achievementId, ')
          ..write('unlockedLocalDate: $unlockedLocalDate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SelectedQuestRowsTable selectedQuestRows =
      $SelectedQuestRowsTable(this);
  late final $StepIntervalRecordsTable stepIntervalRecords =
      $StepIntervalRecordsTable(this);
  late final $LockScreenPreferenceRowsTable lockScreenPreferenceRows =
      $LockScreenPreferenceRowsTable(this);
  late final $AchievementUnlockRowsTable achievementUnlockRows =
      $AchievementUnlockRowsTable(this);
  late final $UserPreferenceRowsTable userPreferenceRows =
      $UserPreferenceRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    selectedQuestRows,
    stepIntervalRecords,
    lockScreenPreferenceRows,
    achievementUnlockRows,
    userPreferenceRows,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$SelectedQuestRowsTableCreateCompanionBuilder =
    SelectedQuestRowsCompanion Function({
      required String ownerId,
      required String journeyId,
      required DateTime startedAt,
      Value<int> rowid,
    });
typedef $$SelectedQuestRowsTableUpdateCompanionBuilder =
    SelectedQuestRowsCompanion Function({
      Value<String> ownerId,
      Value<String> journeyId,
      Value<DateTime> startedAt,
      Value<int> rowid,
    });

class $$SelectedQuestRowsTableFilterComposer
    extends Composer<_$AppDatabase, $SelectedQuestRowsTable> {
  $$SelectedQuestRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get journeyId => $composableBuilder(
    column: $table.journeyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SelectedQuestRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $SelectedQuestRowsTable> {
  $$SelectedQuestRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get journeyId => $composableBuilder(
    column: $table.journeyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SelectedQuestRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SelectedQuestRowsTable> {
  $$SelectedQuestRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get journeyId =>
      $composableBuilder(column: $table.journeyId, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);
}

class $$SelectedQuestRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SelectedQuestRowsTable,
          SelectedQuestRow,
          $$SelectedQuestRowsTableFilterComposer,
          $$SelectedQuestRowsTableOrderingComposer,
          $$SelectedQuestRowsTableAnnotationComposer,
          $$SelectedQuestRowsTableCreateCompanionBuilder,
          $$SelectedQuestRowsTableUpdateCompanionBuilder,
          (
            SelectedQuestRow,
            BaseReferences<
              _$AppDatabase,
              $SelectedQuestRowsTable,
              SelectedQuestRow
            >,
          ),
          SelectedQuestRow,
          PrefetchHooks Function()
        > {
  $$SelectedQuestRowsTableTableManager(
    _$AppDatabase db,
    $SelectedQuestRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SelectedQuestRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SelectedQuestRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SelectedQuestRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> ownerId = const Value.absent(),
                Value<String> journeyId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SelectedQuestRowsCompanion(
                ownerId: ownerId,
                journeyId: journeyId,
                startedAt: startedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String ownerId,
                required String journeyId,
                required DateTime startedAt,
                Value<int> rowid = const Value.absent(),
              }) => SelectedQuestRowsCompanion.insert(
                ownerId: ownerId,
                journeyId: journeyId,
                startedAt: startedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SelectedQuestRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SelectedQuestRowsTable,
      SelectedQuestRow,
      $$SelectedQuestRowsTableFilterComposer,
      $$SelectedQuestRowsTableOrderingComposer,
      $$SelectedQuestRowsTableAnnotationComposer,
      $$SelectedQuestRowsTableCreateCompanionBuilder,
      $$SelectedQuestRowsTableUpdateCompanionBuilder,
      (
        SelectedQuestRow,
        BaseReferences<
          _$AppDatabase,
          $SelectedQuestRowsTable,
          SelectedQuestRow
        >,
      ),
      SelectedQuestRow,
      PrefetchHooks Function()
    >;
typedef $$StepIntervalRecordsTableCreateCompanionBuilder =
    StepIntervalRecordsCompanion Function({
      Value<int> id,
      required String ownerId,
      required String journeyId,
      required DateTime intervalStart,
      required DateTime intervalEnd,
      required int steps,
      Value<int?> walkingDistanceMeters,
      required int resolvedMeters,
      Value<bool> flaggedPace,
      required DateTime syncedAt,
    });
typedef $$StepIntervalRecordsTableUpdateCompanionBuilder =
    StepIntervalRecordsCompanion Function({
      Value<int> id,
      Value<String> ownerId,
      Value<String> journeyId,
      Value<DateTime> intervalStart,
      Value<DateTime> intervalEnd,
      Value<int> steps,
      Value<int?> walkingDistanceMeters,
      Value<int> resolvedMeters,
      Value<bool> flaggedPace,
      Value<DateTime> syncedAt,
    });

class $$StepIntervalRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $StepIntervalRecordsTable> {
  $$StepIntervalRecordsTableFilterComposer({
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

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get journeyId => $composableBuilder(
    column: $table.journeyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get intervalStart => $composableBuilder(
    column: $table.intervalStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get intervalEnd => $composableBuilder(
    column: $table.intervalEnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get steps => $composableBuilder(
    column: $table.steps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get walkingDistanceMeters => $composableBuilder(
    column: $table.walkingDistanceMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get resolvedMeters => $composableBuilder(
    column: $table.resolvedMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get flaggedPace => $composableBuilder(
    column: $table.flaggedPace,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StepIntervalRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $StepIntervalRecordsTable> {
  $$StepIntervalRecordsTableOrderingComposer({
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

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get journeyId => $composableBuilder(
    column: $table.journeyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get intervalStart => $composableBuilder(
    column: $table.intervalStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get intervalEnd => $composableBuilder(
    column: $table.intervalEnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get steps => $composableBuilder(
    column: $table.steps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get walkingDistanceMeters => $composableBuilder(
    column: $table.walkingDistanceMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get resolvedMeters => $composableBuilder(
    column: $table.resolvedMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get flaggedPace => $composableBuilder(
    column: $table.flaggedPace,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StepIntervalRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StepIntervalRecordsTable> {
  $$StepIntervalRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get journeyId =>
      $composableBuilder(column: $table.journeyId, builder: (column) => column);

  GeneratedColumn<DateTime> get intervalStart => $composableBuilder(
    column: $table.intervalStart,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get intervalEnd => $composableBuilder(
    column: $table.intervalEnd,
    builder: (column) => column,
  );

  GeneratedColumn<int> get steps =>
      $composableBuilder(column: $table.steps, builder: (column) => column);

  GeneratedColumn<int> get walkingDistanceMeters => $composableBuilder(
    column: $table.walkingDistanceMeters,
    builder: (column) => column,
  );

  GeneratedColumn<int> get resolvedMeters => $composableBuilder(
    column: $table.resolvedMeters,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get flaggedPace => $composableBuilder(
    column: $table.flaggedPace,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$StepIntervalRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StepIntervalRecordsTable,
          StepIntervalRecord,
          $$StepIntervalRecordsTableFilterComposer,
          $$StepIntervalRecordsTableOrderingComposer,
          $$StepIntervalRecordsTableAnnotationComposer,
          $$StepIntervalRecordsTableCreateCompanionBuilder,
          $$StepIntervalRecordsTableUpdateCompanionBuilder,
          (
            StepIntervalRecord,
            BaseReferences<
              _$AppDatabase,
              $StepIntervalRecordsTable,
              StepIntervalRecord
            >,
          ),
          StepIntervalRecord,
          PrefetchHooks Function()
        > {
  $$StepIntervalRecordsTableTableManager(
    _$AppDatabase db,
    $StepIntervalRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StepIntervalRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StepIntervalRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$StepIntervalRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<String> journeyId = const Value.absent(),
                Value<DateTime> intervalStart = const Value.absent(),
                Value<DateTime> intervalEnd = const Value.absent(),
                Value<int> steps = const Value.absent(),
                Value<int?> walkingDistanceMeters = const Value.absent(),
                Value<int> resolvedMeters = const Value.absent(),
                Value<bool> flaggedPace = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
              }) => StepIntervalRecordsCompanion(
                id: id,
                ownerId: ownerId,
                journeyId: journeyId,
                intervalStart: intervalStart,
                intervalEnd: intervalEnd,
                steps: steps,
                walkingDistanceMeters: walkingDistanceMeters,
                resolvedMeters: resolvedMeters,
                flaggedPace: flaggedPace,
                syncedAt: syncedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String ownerId,
                required String journeyId,
                required DateTime intervalStart,
                required DateTime intervalEnd,
                required int steps,
                Value<int?> walkingDistanceMeters = const Value.absent(),
                required int resolvedMeters,
                Value<bool> flaggedPace = const Value.absent(),
                required DateTime syncedAt,
              }) => StepIntervalRecordsCompanion.insert(
                id: id,
                ownerId: ownerId,
                journeyId: journeyId,
                intervalStart: intervalStart,
                intervalEnd: intervalEnd,
                steps: steps,
                walkingDistanceMeters: walkingDistanceMeters,
                resolvedMeters: resolvedMeters,
                flaggedPace: flaggedPace,
                syncedAt: syncedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StepIntervalRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StepIntervalRecordsTable,
      StepIntervalRecord,
      $$StepIntervalRecordsTableFilterComposer,
      $$StepIntervalRecordsTableOrderingComposer,
      $$StepIntervalRecordsTableAnnotationComposer,
      $$StepIntervalRecordsTableCreateCompanionBuilder,
      $$StepIntervalRecordsTableUpdateCompanionBuilder,
      (
        StepIntervalRecord,
        BaseReferences<
          _$AppDatabase,
          $StepIntervalRecordsTable,
          StepIntervalRecord
        >,
      ),
      StepIntervalRecord,
      PrefetchHooks Function()
    >;
typedef $$LockScreenPreferenceRowsTableCreateCompanionBuilder =
    LockScreenPreferenceRowsCompanion Function({
      required String ownerId,
      required bool enabled,
      Value<int> rowid,
    });
typedef $$LockScreenPreferenceRowsTableUpdateCompanionBuilder =
    LockScreenPreferenceRowsCompanion Function({
      Value<String> ownerId,
      Value<bool> enabled,
      Value<int> rowid,
    });

class $$LockScreenPreferenceRowsTableFilterComposer
    extends Composer<_$AppDatabase, $LockScreenPreferenceRowsTable> {
  $$LockScreenPreferenceRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LockScreenPreferenceRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $LockScreenPreferenceRowsTable> {
  $$LockScreenPreferenceRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LockScreenPreferenceRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LockScreenPreferenceRowsTable> {
  $$LockScreenPreferenceRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);
}

class $$LockScreenPreferenceRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LockScreenPreferenceRowsTable,
          LockScreenPreferenceRow,
          $$LockScreenPreferenceRowsTableFilterComposer,
          $$LockScreenPreferenceRowsTableOrderingComposer,
          $$LockScreenPreferenceRowsTableAnnotationComposer,
          $$LockScreenPreferenceRowsTableCreateCompanionBuilder,
          $$LockScreenPreferenceRowsTableUpdateCompanionBuilder,
          (
            LockScreenPreferenceRow,
            BaseReferences<
              _$AppDatabase,
              $LockScreenPreferenceRowsTable,
              LockScreenPreferenceRow
            >,
          ),
          LockScreenPreferenceRow,
          PrefetchHooks Function()
        > {
  $$LockScreenPreferenceRowsTableTableManager(
    _$AppDatabase db,
    $LockScreenPreferenceRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LockScreenPreferenceRowsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LockScreenPreferenceRowsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LockScreenPreferenceRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> ownerId = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LockScreenPreferenceRowsCompanion(
                ownerId: ownerId,
                enabled: enabled,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String ownerId,
                required bool enabled,
                Value<int> rowid = const Value.absent(),
              }) => LockScreenPreferenceRowsCompanion.insert(
                ownerId: ownerId,
                enabled: enabled,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LockScreenPreferenceRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LockScreenPreferenceRowsTable,
      LockScreenPreferenceRow,
      $$LockScreenPreferenceRowsTableFilterComposer,
      $$LockScreenPreferenceRowsTableOrderingComposer,
      $$LockScreenPreferenceRowsTableAnnotationComposer,
      $$LockScreenPreferenceRowsTableCreateCompanionBuilder,
      $$LockScreenPreferenceRowsTableUpdateCompanionBuilder,
      (
        LockScreenPreferenceRow,
        BaseReferences<
          _$AppDatabase,
          $LockScreenPreferenceRowsTable,
          LockScreenPreferenceRow
        >,
      ),
      LockScreenPreferenceRow,
      PrefetchHooks Function()
    >;
typedef $$AchievementUnlockRowsTableCreateCompanionBuilder =
    AchievementUnlockRowsCompanion Function({
      required String ownerId,
      required String achievementId,
      required DateTime unlockedLocalDate,
      Value<int> rowid,
    });
typedef $$AchievementUnlockRowsTableUpdateCompanionBuilder =
    AchievementUnlockRowsCompanion Function({
      Value<String> ownerId,
      Value<String> achievementId,
      Value<DateTime> unlockedLocalDate,
      Value<int> rowid,
    });

class $$AchievementUnlockRowsTableFilterComposer
    extends Composer<_$AppDatabase, $AchievementUnlockRowsTable> {
  $$AchievementUnlockRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get achievementId => $composableBuilder(
    column: $table.achievementId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get unlockedLocalDate => $composableBuilder(
    column: $table.unlockedLocalDate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AchievementUnlockRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $AchievementUnlockRowsTable> {
  $$AchievementUnlockRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get achievementId => $composableBuilder(
    column: $table.achievementId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get unlockedLocalDate => $composableBuilder(
    column: $table.unlockedLocalDate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AchievementUnlockRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AchievementUnlockRowsTable> {
  $$AchievementUnlockRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get achievementId => $composableBuilder(
    column: $table.achievementId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get unlockedLocalDate => $composableBuilder(
    column: $table.unlockedLocalDate,
    builder: (column) => column,
  );
}

class $$AchievementUnlockRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AchievementUnlockRowsTable,
          AchievementUnlockRow,
          $$AchievementUnlockRowsTableFilterComposer,
          $$AchievementUnlockRowsTableOrderingComposer,
          $$AchievementUnlockRowsTableAnnotationComposer,
          $$AchievementUnlockRowsTableCreateCompanionBuilder,
          $$AchievementUnlockRowsTableUpdateCompanionBuilder,
          (
            AchievementUnlockRow,
            BaseReferences<
              _$AppDatabase,
              $AchievementUnlockRowsTable,
              AchievementUnlockRow
            >,
          ),
          AchievementUnlockRow,
          PrefetchHooks Function()
        > {
  $$AchievementUnlockRowsTableTableManager(
    _$AppDatabase db,
    $AchievementUnlockRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AchievementUnlockRowsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$AchievementUnlockRowsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AchievementUnlockRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> ownerId = const Value.absent(),
                Value<String> achievementId = const Value.absent(),
                Value<DateTime> unlockedLocalDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AchievementUnlockRowsCompanion(
                ownerId: ownerId,
                achievementId: achievementId,
                unlockedLocalDate: unlockedLocalDate,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String ownerId,
                required String achievementId,
                required DateTime unlockedLocalDate,
                Value<int> rowid = const Value.absent(),
              }) => AchievementUnlockRowsCompanion.insert(
                ownerId: ownerId,
                achievementId: achievementId,
                unlockedLocalDate: unlockedLocalDate,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AchievementUnlockRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AchievementUnlockRowsTable,
      AchievementUnlockRow,
      $$AchievementUnlockRowsTableFilterComposer,
      $$AchievementUnlockRowsTableOrderingComposer,
      $$AchievementUnlockRowsTableAnnotationComposer,
      $$AchievementUnlockRowsTableCreateCompanionBuilder,
      $$AchievementUnlockRowsTableUpdateCompanionBuilder,
      (
        AchievementUnlockRow,
        BaseReferences<
          _$AppDatabase,
          $AchievementUnlockRowsTable,
          AchievementUnlockRow
        >,
      ),
      AchievementUnlockRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SelectedQuestRowsTableTableManager get selectedQuestRows =>
      $$SelectedQuestRowsTableTableManager(_db, _db.selectedQuestRows);
  $$StepIntervalRecordsTableTableManager get stepIntervalRecords =>
      $$StepIntervalRecordsTableTableManager(_db, _db.stepIntervalRecords);
  $$LockScreenPreferenceRowsTableTableManager get lockScreenPreferenceRows =>
      $$LockScreenPreferenceRowsTableTableManager(
        _db,
        _db.lockScreenPreferenceRows,
      );
  $$AchievementUnlockRowsTableTableManager get achievementUnlockRows =>
      $$AchievementUnlockRowsTableTableManager(_db, _db.achievementUnlockRows);
}
