// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $EventsTable extends Events with TableInfo<$EventsTable, Event> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _originDeviceIdMeta =
      const VerificationMeta('originDeviceId');
  @override
  late final GeneratedColumn<String> originDeviceId = GeneratedColumn<String>(
      'origin_device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startDateMeta =
      const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
      'start_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _endDateMeta =
      const VerificationMeta('endDate');
  @override
  late final GeneratedColumn<String> endDate = GeneratedColumn<String>(
      'end_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _venueMeta = const VerificationMeta('venue');
  @override
  late final GeneratedColumn<String> venue = GeneratedColumn<String>(
      'venue', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _organizerMeta =
      const VerificationMeta('organizer');
  @override
  late final GeneratedColumn<String> organizer = GeneratedColumn<String>(
      'organizer', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _offersLodgingMeta =
      const VerificationMeta('offersLodging');
  @override
  late final GeneratedColumn<bool> offersLodging = GeneratedColumn<bool>(
      'offers_lodging', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("offers_lodging" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _offersTeamsMeta =
      const VerificationMeta('offersTeams');
  @override
  late final GeneratedColumn<bool> offersTeams = GeneratedColumn<bool>(
      'offers_teams', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("offers_teams" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _setupDoneMeta =
      const VerificationMeta('setupDone');
  @override
  late final GeneratedColumn<bool> setupDone = GeneratedColumn<bool>(
      'setup_done', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("setup_done" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _maxSizeDiffMeta =
      const VerificationMeta('maxSizeDiff');
  @override
  late final GeneratedColumn<int> maxSizeDiff = GeneratedColumn<int>(
      'max_size_diff', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(2));
  static const VerificationMeta _maxSexDiffMeta =
      const VerificationMeta('maxSexDiff');
  @override
  late final GeneratedColumn<int> maxSexDiff = GeneratedColumn<int>(
      'max_sex_diff', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(4));
  static const VerificationMeta _maxAgeDiffMeta =
      const VerificationMeta('maxAgeDiff');
  @override
  late final GeneratedColumn<double> maxAgeDiff = GeneratedColumn<double>(
      'max_age_diff', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(3.0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        createdAt,
        updatedAt,
        deletedAt,
        originDeviceId,
        name,
        startDate,
        endDate,
        venue,
        organizer,
        offersLodging,
        offersTeams,
        setupDone,
        notes,
        maxSizeDiff,
        maxSexDiff,
        maxAgeDiff
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'events';
  @override
  VerificationContext validateIntegrity(Insertable<Event> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('origin_device_id')) {
      context.handle(
          _originDeviceIdMeta,
          originDeviceId.isAcceptableOrUnknown(
              data['origin_device_id']!, _originDeviceIdMeta));
    } else if (isInserting) {
      context.missing(_originDeviceIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(_startDateMeta,
          startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta));
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(_endDateMeta,
          endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta));
    } else if (isInserting) {
      context.missing(_endDateMeta);
    }
    if (data.containsKey('venue')) {
      context.handle(
          _venueMeta, venue.isAcceptableOrUnknown(data['venue']!, _venueMeta));
    }
    if (data.containsKey('organizer')) {
      context.handle(_organizerMeta,
          organizer.isAcceptableOrUnknown(data['organizer']!, _organizerMeta));
    }
    if (data.containsKey('offers_lodging')) {
      context.handle(
          _offersLodgingMeta,
          offersLodging.isAcceptableOrUnknown(
              data['offers_lodging']!, _offersLodgingMeta));
    }
    if (data.containsKey('offers_teams')) {
      context.handle(
          _offersTeamsMeta,
          offersTeams.isAcceptableOrUnknown(
              data['offers_teams']!, _offersTeamsMeta));
    }
    if (data.containsKey('setup_done')) {
      context.handle(_setupDoneMeta,
          setupDone.isAcceptableOrUnknown(data['setup_done']!, _setupDoneMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('max_size_diff')) {
      context.handle(
          _maxSizeDiffMeta,
          maxSizeDiff.isAcceptableOrUnknown(
              data['max_size_diff']!, _maxSizeDiffMeta));
    }
    if (data.containsKey('max_sex_diff')) {
      context.handle(
          _maxSexDiffMeta,
          maxSexDiff.isAcceptableOrUnknown(
              data['max_sex_diff']!, _maxSexDiffMeta));
    }
    if (data.containsKey('max_age_diff')) {
      context.handle(
          _maxAgeDiffMeta,
          maxAgeDiff.isAcceptableOrUnknown(
              data['max_age_diff']!, _maxAgeDiffMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Event map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Event(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      originDeviceId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}origin_device_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      startDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}start_date'])!,
      endDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}end_date'])!,
      venue: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}venue'])!,
      organizer: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}organizer'])!,
      offersLodging: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}offers_lodging'])!,
      offersTeams: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}offers_teams'])!,
      setupDone: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}setup_done'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
      maxSizeDiff: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}max_size_diff'])!,
      maxSexDiff: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}max_sex_diff'])!,
      maxAgeDiff: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}max_age_diff'])!,
    );
  }

  @override
  $EventsTable createAlias(String alias) {
    return $EventsTable(attachedDatabase, alias);
  }
}

class Event extends DataClass implements Insertable<Event> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String originDeviceId;
  final String name;
  final String startDate;
  final String endDate;
  final String venue;
  final String organizer;
  final bool offersLodging;
  final bool offersTeams;
  final bool setupDone;
  final String notes;
  final int maxSizeDiff;
  final int maxSexDiff;
  final double maxAgeDiff;
  const Event(
      {required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.originDeviceId,
      required this.name,
      required this.startDate,
      required this.endDate,
      required this.venue,
      required this.organizer,
      required this.offersLodging,
      required this.offersTeams,
      required this.setupDone,
      required this.notes,
      required this.maxSizeDiff,
      required this.maxSexDiff,
      required this.maxAgeDiff});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['origin_device_id'] = Variable<String>(originDeviceId);
    map['name'] = Variable<String>(name);
    map['start_date'] = Variable<String>(startDate);
    map['end_date'] = Variable<String>(endDate);
    map['venue'] = Variable<String>(venue);
    map['organizer'] = Variable<String>(organizer);
    map['offers_lodging'] = Variable<bool>(offersLodging);
    map['offers_teams'] = Variable<bool>(offersTeams);
    map['setup_done'] = Variable<bool>(setupDone);
    map['notes'] = Variable<String>(notes);
    map['max_size_diff'] = Variable<int>(maxSizeDiff);
    map['max_sex_diff'] = Variable<int>(maxSexDiff);
    map['max_age_diff'] = Variable<double>(maxAgeDiff);
    return map;
  }

  EventsCompanion toCompanion(bool nullToAbsent) {
    return EventsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      originDeviceId: Value(originDeviceId),
      name: Value(name),
      startDate: Value(startDate),
      endDate: Value(endDate),
      venue: Value(venue),
      organizer: Value(organizer),
      offersLodging: Value(offersLodging),
      offersTeams: Value(offersTeams),
      setupDone: Value(setupDone),
      notes: Value(notes),
      maxSizeDiff: Value(maxSizeDiff),
      maxSexDiff: Value(maxSexDiff),
      maxAgeDiff: Value(maxAgeDiff),
    );
  }

  factory Event.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Event(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      originDeviceId: serializer.fromJson<String>(json['originDeviceId']),
      name: serializer.fromJson<String>(json['name']),
      startDate: serializer.fromJson<String>(json['startDate']),
      endDate: serializer.fromJson<String>(json['endDate']),
      venue: serializer.fromJson<String>(json['venue']),
      organizer: serializer.fromJson<String>(json['organizer']),
      offersLodging: serializer.fromJson<bool>(json['offersLodging']),
      offersTeams: serializer.fromJson<bool>(json['offersTeams']),
      setupDone: serializer.fromJson<bool>(json['setupDone']),
      notes: serializer.fromJson<String>(json['notes']),
      maxSizeDiff: serializer.fromJson<int>(json['maxSizeDiff']),
      maxSexDiff: serializer.fromJson<int>(json['maxSexDiff']),
      maxAgeDiff: serializer.fromJson<double>(json['maxAgeDiff']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'originDeviceId': serializer.toJson<String>(originDeviceId),
      'name': serializer.toJson<String>(name),
      'startDate': serializer.toJson<String>(startDate),
      'endDate': serializer.toJson<String>(endDate),
      'venue': serializer.toJson<String>(venue),
      'organizer': serializer.toJson<String>(organizer),
      'offersLodging': serializer.toJson<bool>(offersLodging),
      'offersTeams': serializer.toJson<bool>(offersTeams),
      'setupDone': serializer.toJson<bool>(setupDone),
      'notes': serializer.toJson<String>(notes),
      'maxSizeDiff': serializer.toJson<int>(maxSizeDiff),
      'maxSexDiff': serializer.toJson<int>(maxSexDiff),
      'maxAgeDiff': serializer.toJson<double>(maxAgeDiff),
    };
  }

  Event copyWith(
          {String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          String? originDeviceId,
          String? name,
          String? startDate,
          String? endDate,
          String? venue,
          String? organizer,
          bool? offersLodging,
          bool? offersTeams,
          bool? setupDone,
          String? notes,
          int? maxSizeDiff,
          int? maxSexDiff,
          double? maxAgeDiff}) =>
      Event(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        originDeviceId: originDeviceId ?? this.originDeviceId,
        name: name ?? this.name,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        venue: venue ?? this.venue,
        organizer: organizer ?? this.organizer,
        offersLodging: offersLodging ?? this.offersLodging,
        offersTeams: offersTeams ?? this.offersTeams,
        setupDone: setupDone ?? this.setupDone,
        notes: notes ?? this.notes,
        maxSizeDiff: maxSizeDiff ?? this.maxSizeDiff,
        maxSexDiff: maxSexDiff ?? this.maxSexDiff,
        maxAgeDiff: maxAgeDiff ?? this.maxAgeDiff,
      );
  Event copyWithCompanion(EventsCompanion data) {
    return Event(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      originDeviceId: data.originDeviceId.present
          ? data.originDeviceId.value
          : this.originDeviceId,
      name: data.name.present ? data.name.value : this.name,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      venue: data.venue.present ? data.venue.value : this.venue,
      organizer: data.organizer.present ? data.organizer.value : this.organizer,
      offersLodging: data.offersLodging.present
          ? data.offersLodging.value
          : this.offersLodging,
      offersTeams:
          data.offersTeams.present ? data.offersTeams.value : this.offersTeams,
      setupDone: data.setupDone.present ? data.setupDone.value : this.setupDone,
      notes: data.notes.present ? data.notes.value : this.notes,
      maxSizeDiff:
          data.maxSizeDiff.present ? data.maxSizeDiff.value : this.maxSizeDiff,
      maxSexDiff:
          data.maxSexDiff.present ? data.maxSexDiff.value : this.maxSexDiff,
      maxAgeDiff:
          data.maxAgeDiff.present ? data.maxAgeDiff.value : this.maxAgeDiff,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Event(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('name: $name, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('venue: $venue, ')
          ..write('organizer: $organizer, ')
          ..write('offersLodging: $offersLodging, ')
          ..write('offersTeams: $offersTeams, ')
          ..write('setupDone: $setupDone, ')
          ..write('notes: $notes, ')
          ..write('maxSizeDiff: $maxSizeDiff, ')
          ..write('maxSexDiff: $maxSexDiff, ')
          ..write('maxAgeDiff: $maxAgeDiff')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      createdAt,
      updatedAt,
      deletedAt,
      originDeviceId,
      name,
      startDate,
      endDate,
      venue,
      organizer,
      offersLodging,
      offersTeams,
      setupDone,
      notes,
      maxSizeDiff,
      maxSexDiff,
      maxAgeDiff);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Event &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.originDeviceId == this.originDeviceId &&
          other.name == this.name &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.venue == this.venue &&
          other.organizer == this.organizer &&
          other.offersLodging == this.offersLodging &&
          other.offersTeams == this.offersTeams &&
          other.setupDone == this.setupDone &&
          other.notes == this.notes &&
          other.maxSizeDiff == this.maxSizeDiff &&
          other.maxSexDiff == this.maxSexDiff &&
          other.maxAgeDiff == this.maxAgeDiff);
}

class EventsCompanion extends UpdateCompanion<Event> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> originDeviceId;
  final Value<String> name;
  final Value<String> startDate;
  final Value<String> endDate;
  final Value<String> venue;
  final Value<String> organizer;
  final Value<bool> offersLodging;
  final Value<bool> offersTeams;
  final Value<bool> setupDone;
  final Value<String> notes;
  final Value<int> maxSizeDiff;
  final Value<int> maxSexDiff;
  final Value<double> maxAgeDiff;
  final Value<int> rowid;
  const EventsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.originDeviceId = const Value.absent(),
    this.name = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.venue = const Value.absent(),
    this.organizer = const Value.absent(),
    this.offersLodging = const Value.absent(),
    this.offersTeams = const Value.absent(),
    this.setupDone = const Value.absent(),
    this.notes = const Value.absent(),
    this.maxSizeDiff = const Value.absent(),
    this.maxSexDiff = const Value.absent(),
    this.maxAgeDiff = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String originDeviceId,
    required String name,
    required String startDate,
    required String endDate,
    this.venue = const Value.absent(),
    this.organizer = const Value.absent(),
    this.offersLodging = const Value.absent(),
    this.offersTeams = const Value.absent(),
    this.setupDone = const Value.absent(),
    this.notes = const Value.absent(),
    this.maxSizeDiff = const Value.absent(),
    this.maxSexDiff = const Value.absent(),
    this.maxAgeDiff = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        originDeviceId = Value(originDeviceId),
        name = Value(name),
        startDate = Value(startDate),
        endDate = Value(endDate);
  static Insertable<Event> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? originDeviceId,
    Expression<String>? name,
    Expression<String>? startDate,
    Expression<String>? endDate,
    Expression<String>? venue,
    Expression<String>? organizer,
    Expression<bool>? offersLodging,
    Expression<bool>? offersTeams,
    Expression<bool>? setupDone,
    Expression<String>? notes,
    Expression<int>? maxSizeDiff,
    Expression<int>? maxSexDiff,
    Expression<double>? maxAgeDiff,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (originDeviceId != null) 'origin_device_id': originDeviceId,
      if (name != null) 'name': name,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (venue != null) 'venue': venue,
      if (organizer != null) 'organizer': organizer,
      if (offersLodging != null) 'offers_lodging': offersLodging,
      if (offersTeams != null) 'offers_teams': offersTeams,
      if (setupDone != null) 'setup_done': setupDone,
      if (notes != null) 'notes': notes,
      if (maxSizeDiff != null) 'max_size_diff': maxSizeDiff,
      if (maxSexDiff != null) 'max_sex_diff': maxSexDiff,
      if (maxAgeDiff != null) 'max_age_diff': maxAgeDiff,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventsCompanion copyWith(
      {Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? originDeviceId,
      Value<String>? name,
      Value<String>? startDate,
      Value<String>? endDate,
      Value<String>? venue,
      Value<String>? organizer,
      Value<bool>? offersLodging,
      Value<bool>? offersTeams,
      Value<bool>? setupDone,
      Value<String>? notes,
      Value<int>? maxSizeDiff,
      Value<int>? maxSexDiff,
      Value<double>? maxAgeDiff,
      Value<int>? rowid}) {
    return EventsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      venue: venue ?? this.venue,
      organizer: organizer ?? this.organizer,
      offersLodging: offersLodging ?? this.offersLodging,
      offersTeams: offersTeams ?? this.offersTeams,
      setupDone: setupDone ?? this.setupDone,
      notes: notes ?? this.notes,
      maxSizeDiff: maxSizeDiff ?? this.maxSizeDiff,
      maxSexDiff: maxSexDiff ?? this.maxSexDiff,
      maxAgeDiff: maxAgeDiff ?? this.maxAgeDiff,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
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
    if (originDeviceId.present) {
      map['origin_device_id'] = Variable<String>(originDeviceId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(endDate.value);
    }
    if (venue.present) {
      map['venue'] = Variable<String>(venue.value);
    }
    if (organizer.present) {
      map['organizer'] = Variable<String>(organizer.value);
    }
    if (offersLodging.present) {
      map['offers_lodging'] = Variable<bool>(offersLodging.value);
    }
    if (offersTeams.present) {
      map['offers_teams'] = Variable<bool>(offersTeams.value);
    }
    if (setupDone.present) {
      map['setup_done'] = Variable<bool>(setupDone.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (maxSizeDiff.present) {
      map['max_size_diff'] = Variable<int>(maxSizeDiff.value);
    }
    if (maxSexDiff.present) {
      map['max_sex_diff'] = Variable<int>(maxSexDiff.value);
    }
    if (maxAgeDiff.present) {
      map['max_age_diff'] = Variable<double>(maxAgeDiff.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('name: $name, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('venue: $venue, ')
          ..write('organizer: $organizer, ')
          ..write('offersLodging: $offersLodging, ')
          ..write('offersTeams: $offersTeams, ')
          ..write('setupDone: $setupDone, ')
          ..write('notes: $notes, ')
          ..write('maxSizeDiff: $maxSizeDiff, ')
          ..write('maxSexDiff: $maxSexDiff, ')
          ..write('maxAgeDiff: $maxAgeDiff, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChurchesTable extends Churches
    with TableInfo<$ChurchesTable, ChurchRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChurchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _originDeviceIdMeta =
      const VerificationMeta('originDeviceId');
  @override
  late final GeneratedColumn<String> originDeviceId = GeneratedColumn<String>(
      'origin_device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameNormalizedMeta =
      const VerificationMeta('nameNormalized');
  @override
  late final GeneratedColumn<String> nameNormalized = GeneratedColumn<String>(
      'name_normalized', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _provinceMeta =
      const VerificationMeta('province');
  @override
  late final GeneratedColumn<String> province = GeneratedColumn<String>(
      'province', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _municipalityMeta =
      const VerificationMeta('municipality');
  @override
  late final GeneratedColumn<String> municipality = GeneratedColumn<String>(
      'municipality', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _denominationMeta =
      const VerificationMeta('denomination');
  @override
  late final GeneratedColumn<String> denomination = GeneratedColumn<String>(
      'denomination', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _communityMeta =
      const VerificationMeta('community');
  @override
  late final GeneratedColumn<String> community = GeneratedColumn<String>(
      'community', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        createdAt,
        updatedAt,
        deletedAt,
        originDeviceId,
        name,
        nameNormalized,
        province,
        municipality,
        denomination,
        community
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'churches';
  @override
  VerificationContext validateIntegrity(Insertable<ChurchRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('origin_device_id')) {
      context.handle(
          _originDeviceIdMeta,
          originDeviceId.isAcceptableOrUnknown(
              data['origin_device_id']!, _originDeviceIdMeta));
    } else if (isInserting) {
      context.missing(_originDeviceIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('name_normalized')) {
      context.handle(
          _nameNormalizedMeta,
          nameNormalized.isAcceptableOrUnknown(
              data['name_normalized']!, _nameNormalizedMeta));
    } else if (isInserting) {
      context.missing(_nameNormalizedMeta);
    }
    if (data.containsKey('province')) {
      context.handle(_provinceMeta,
          province.isAcceptableOrUnknown(data['province']!, _provinceMeta));
    }
    if (data.containsKey('municipality')) {
      context.handle(
          _municipalityMeta,
          municipality.isAcceptableOrUnknown(
              data['municipality']!, _municipalityMeta));
    }
    if (data.containsKey('denomination')) {
      context.handle(
          _denominationMeta,
          denomination.isAcceptableOrUnknown(
              data['denomination']!, _denominationMeta));
    }
    if (data.containsKey('community')) {
      context.handle(_communityMeta,
          community.isAcceptableOrUnknown(data['community']!, _communityMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {nameNormalized, province, municipality},
      ];
  @override
  ChurchRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChurchRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      originDeviceId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}origin_device_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      nameNormalized: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}name_normalized'])!,
      province: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}province'])!,
      municipality: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}municipality'])!,
      denomination: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}denomination']),
      community: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}community'])!,
    );
  }

  @override
  $ChurchesTable createAlias(String alias) {
    return $ChurchesTable(attachedDatabase, alias);
  }
}

class ChurchRow extends DataClass implements Insertable<ChurchRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String originDeviceId;
  final String name;
  final String nameNormalized;
  final String province;
  final String municipality;
  final String? denomination;
  final String community;
  const ChurchRow(
      {required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.originDeviceId,
      required this.name,
      required this.nameNormalized,
      required this.province,
      required this.municipality,
      this.denomination,
      required this.community});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['origin_device_id'] = Variable<String>(originDeviceId);
    map['name'] = Variable<String>(name);
    map['name_normalized'] = Variable<String>(nameNormalized);
    map['province'] = Variable<String>(province);
    map['municipality'] = Variable<String>(municipality);
    if (!nullToAbsent || denomination != null) {
      map['denomination'] = Variable<String>(denomination);
    }
    map['community'] = Variable<String>(community);
    return map;
  }

  ChurchesCompanion toCompanion(bool nullToAbsent) {
    return ChurchesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      originDeviceId: Value(originDeviceId),
      name: Value(name),
      nameNormalized: Value(nameNormalized),
      province: Value(province),
      municipality: Value(municipality),
      denomination: denomination == null && nullToAbsent
          ? const Value.absent()
          : Value(denomination),
      community: Value(community),
    );
  }

  factory ChurchRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChurchRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      originDeviceId: serializer.fromJson<String>(json['originDeviceId']),
      name: serializer.fromJson<String>(json['name']),
      nameNormalized: serializer.fromJson<String>(json['nameNormalized']),
      province: serializer.fromJson<String>(json['province']),
      municipality: serializer.fromJson<String>(json['municipality']),
      denomination: serializer.fromJson<String?>(json['denomination']),
      community: serializer.fromJson<String>(json['community']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'originDeviceId': serializer.toJson<String>(originDeviceId),
      'name': serializer.toJson<String>(name),
      'nameNormalized': serializer.toJson<String>(nameNormalized),
      'province': serializer.toJson<String>(province),
      'municipality': serializer.toJson<String>(municipality),
      'denomination': serializer.toJson<String?>(denomination),
      'community': serializer.toJson<String>(community),
    };
  }

  ChurchRow copyWith(
          {String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          String? originDeviceId,
          String? name,
          String? nameNormalized,
          String? province,
          String? municipality,
          Value<String?> denomination = const Value.absent(),
          String? community}) =>
      ChurchRow(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        originDeviceId: originDeviceId ?? this.originDeviceId,
        name: name ?? this.name,
        nameNormalized: nameNormalized ?? this.nameNormalized,
        province: province ?? this.province,
        municipality: municipality ?? this.municipality,
        denomination:
            denomination.present ? denomination.value : this.denomination,
        community: community ?? this.community,
      );
  ChurchRow copyWithCompanion(ChurchesCompanion data) {
    return ChurchRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      originDeviceId: data.originDeviceId.present
          ? data.originDeviceId.value
          : this.originDeviceId,
      name: data.name.present ? data.name.value : this.name,
      nameNormalized: data.nameNormalized.present
          ? data.nameNormalized.value
          : this.nameNormalized,
      province: data.province.present ? data.province.value : this.province,
      municipality: data.municipality.present
          ? data.municipality.value
          : this.municipality,
      denomination: data.denomination.present
          ? data.denomination.value
          : this.denomination,
      community: data.community.present ? data.community.value : this.community,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChurchRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('name: $name, ')
          ..write('nameNormalized: $nameNormalized, ')
          ..write('province: $province, ')
          ..write('municipality: $municipality, ')
          ..write('denomination: $denomination, ')
          ..write('community: $community')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      createdAt,
      updatedAt,
      deletedAt,
      originDeviceId,
      name,
      nameNormalized,
      province,
      municipality,
      denomination,
      community);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChurchRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.originDeviceId == this.originDeviceId &&
          other.name == this.name &&
          other.nameNormalized == this.nameNormalized &&
          other.province == this.province &&
          other.municipality == this.municipality &&
          other.denomination == this.denomination &&
          other.community == this.community);
}

class ChurchesCompanion extends UpdateCompanion<ChurchRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> originDeviceId;
  final Value<String> name;
  final Value<String> nameNormalized;
  final Value<String> province;
  final Value<String> municipality;
  final Value<String?> denomination;
  final Value<String> community;
  final Value<int> rowid;
  const ChurchesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.originDeviceId = const Value.absent(),
    this.name = const Value.absent(),
    this.nameNormalized = const Value.absent(),
    this.province = const Value.absent(),
    this.municipality = const Value.absent(),
    this.denomination = const Value.absent(),
    this.community = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChurchesCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String originDeviceId,
    required String name,
    required String nameNormalized,
    this.province = const Value.absent(),
    this.municipality = const Value.absent(),
    this.denomination = const Value.absent(),
    this.community = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        originDeviceId = Value(originDeviceId),
        name = Value(name),
        nameNormalized = Value(nameNormalized);
  static Insertable<ChurchRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? originDeviceId,
    Expression<String>? name,
    Expression<String>? nameNormalized,
    Expression<String>? province,
    Expression<String>? municipality,
    Expression<String>? denomination,
    Expression<String>? community,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (originDeviceId != null) 'origin_device_id': originDeviceId,
      if (name != null) 'name': name,
      if (nameNormalized != null) 'name_normalized': nameNormalized,
      if (province != null) 'province': province,
      if (municipality != null) 'municipality': municipality,
      if (denomination != null) 'denomination': denomination,
      if (community != null) 'community': community,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChurchesCompanion copyWith(
      {Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? originDeviceId,
      Value<String>? name,
      Value<String>? nameNormalized,
      Value<String>? province,
      Value<String>? municipality,
      Value<String?>? denomination,
      Value<String>? community,
      Value<int>? rowid}) {
    return ChurchesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      name: name ?? this.name,
      nameNormalized: nameNormalized ?? this.nameNormalized,
      province: province ?? this.province,
      municipality: municipality ?? this.municipality,
      denomination: denomination ?? this.denomination,
      community: community ?? this.community,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
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
    if (originDeviceId.present) {
      map['origin_device_id'] = Variable<String>(originDeviceId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (nameNormalized.present) {
      map['name_normalized'] = Variable<String>(nameNormalized.value);
    }
    if (province.present) {
      map['province'] = Variable<String>(province.value);
    }
    if (municipality.present) {
      map['municipality'] = Variable<String>(municipality.value);
    }
    if (denomination.present) {
      map['denomination'] = Variable<String>(denomination.value);
    }
    if (community.present) {
      map['community'] = Variable<String>(community.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChurchesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('name: $name, ')
          ..write('nameNormalized: $nameNormalized, ')
          ..write('province: $province, ')
          ..write('municipality: $municipality, ')
          ..write('denomination: $denomination, ')
          ..write('community: $community, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AgeRangesTable extends AgeRanges
    with TableInfo<$AgeRangesTable, AgeRangeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AgeRangesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _originDeviceIdMeta =
      const VerificationMeta('originDeviceId');
  @override
  late final GeneratedColumn<String> originDeviceId = GeneratedColumn<String>(
      'origin_device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _eventIdMeta =
      const VerificationMeta('eventId');
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
      'event_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES events (id)'));
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
      'label', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _minAgeMeta = const VerificationMeta('minAge');
  @override
  late final GeneratedColumn<int> minAge = GeneratedColumn<int>(
      'min_age', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _maxAgeMeta = const VerificationMeta('maxAge');
  @override
  late final GeneratedColumn<int> maxAge = GeneratedColumn<int>(
      'max_age', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        createdAt,
        updatedAt,
        deletedAt,
        originDeviceId,
        eventId,
        label,
        minAge,
        maxAge,
        sortOrder
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'age_ranges';
  @override
  VerificationContext validateIntegrity(Insertable<AgeRangeRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('origin_device_id')) {
      context.handle(
          _originDeviceIdMeta,
          originDeviceId.isAcceptableOrUnknown(
              data['origin_device_id']!, _originDeviceIdMeta));
    } else if (isInserting) {
      context.missing(_originDeviceIdMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(_eventIdMeta,
          eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta));
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
          _labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('min_age')) {
      context.handle(_minAgeMeta,
          minAge.isAcceptableOrUnknown(data['min_age']!, _minAgeMeta));
    } else if (isInserting) {
      context.missing(_minAgeMeta);
    }
    if (data.containsKey('max_age')) {
      context.handle(_maxAgeMeta,
          maxAge.isAcceptableOrUnknown(data['max_age']!, _maxAgeMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AgeRangeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AgeRangeRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      originDeviceId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}origin_device_id'])!,
      eventId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_id'])!,
      label: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}label'])!,
      minAge: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}min_age'])!,
      maxAge: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}max_age']),
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $AgeRangesTable createAlias(String alias) {
    return $AgeRangesTable(attachedDatabase, alias);
  }
}

class AgeRangeRow extends DataClass implements Insertable<AgeRangeRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String originDeviceId;
  final String eventId;
  final String label;
  final int minAge;
  final int? maxAge;
  final int sortOrder;
  const AgeRangeRow(
      {required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.originDeviceId,
      required this.eventId,
      required this.label,
      required this.minAge,
      this.maxAge,
      required this.sortOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['origin_device_id'] = Variable<String>(originDeviceId);
    map['event_id'] = Variable<String>(eventId);
    map['label'] = Variable<String>(label);
    map['min_age'] = Variable<int>(minAge);
    if (!nullToAbsent || maxAge != null) {
      map['max_age'] = Variable<int>(maxAge);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  AgeRangesCompanion toCompanion(bool nullToAbsent) {
    return AgeRangesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      originDeviceId: Value(originDeviceId),
      eventId: Value(eventId),
      label: Value(label),
      minAge: Value(minAge),
      maxAge:
          maxAge == null && nullToAbsent ? const Value.absent() : Value(maxAge),
      sortOrder: Value(sortOrder),
    );
  }

  factory AgeRangeRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AgeRangeRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      originDeviceId: serializer.fromJson<String>(json['originDeviceId']),
      eventId: serializer.fromJson<String>(json['eventId']),
      label: serializer.fromJson<String>(json['label']),
      minAge: serializer.fromJson<int>(json['minAge']),
      maxAge: serializer.fromJson<int?>(json['maxAge']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'originDeviceId': serializer.toJson<String>(originDeviceId),
      'eventId': serializer.toJson<String>(eventId),
      'label': serializer.toJson<String>(label),
      'minAge': serializer.toJson<int>(minAge),
      'maxAge': serializer.toJson<int?>(maxAge),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  AgeRangeRow copyWith(
          {String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          String? originDeviceId,
          String? eventId,
          String? label,
          int? minAge,
          Value<int?> maxAge = const Value.absent(),
          int? sortOrder}) =>
      AgeRangeRow(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        originDeviceId: originDeviceId ?? this.originDeviceId,
        eventId: eventId ?? this.eventId,
        label: label ?? this.label,
        minAge: minAge ?? this.minAge,
        maxAge: maxAge.present ? maxAge.value : this.maxAge,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  AgeRangeRow copyWithCompanion(AgeRangesCompanion data) {
    return AgeRangeRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      originDeviceId: data.originDeviceId.present
          ? data.originDeviceId.value
          : this.originDeviceId,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      label: data.label.present ? data.label.value : this.label,
      minAge: data.minAge.present ? data.minAge.value : this.minAge,
      maxAge: data.maxAge.present ? data.maxAge.value : this.maxAge,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AgeRangeRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('eventId: $eventId, ')
          ..write('label: $label, ')
          ..write('minAge: $minAge, ')
          ..write('maxAge: $maxAge, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, createdAt, updatedAt, deletedAt,
      originDeviceId, eventId, label, minAge, maxAge, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AgeRangeRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.originDeviceId == this.originDeviceId &&
          other.eventId == this.eventId &&
          other.label == this.label &&
          other.minAge == this.minAge &&
          other.maxAge == this.maxAge &&
          other.sortOrder == this.sortOrder);
}

class AgeRangesCompanion extends UpdateCompanion<AgeRangeRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> originDeviceId;
  final Value<String> eventId;
  final Value<String> label;
  final Value<int> minAge;
  final Value<int?> maxAge;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const AgeRangesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.originDeviceId = const Value.absent(),
    this.eventId = const Value.absent(),
    this.label = const Value.absent(),
    this.minAge = const Value.absent(),
    this.maxAge = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AgeRangesCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String originDeviceId,
    required String eventId,
    required String label,
    required int minAge,
    this.maxAge = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        originDeviceId = Value(originDeviceId),
        eventId = Value(eventId),
        label = Value(label),
        minAge = Value(minAge);
  static Insertable<AgeRangeRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? originDeviceId,
    Expression<String>? eventId,
    Expression<String>? label,
    Expression<int>? minAge,
    Expression<int>? maxAge,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (originDeviceId != null) 'origin_device_id': originDeviceId,
      if (eventId != null) 'event_id': eventId,
      if (label != null) 'label': label,
      if (minAge != null) 'min_age': minAge,
      if (maxAge != null) 'max_age': maxAge,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AgeRangesCompanion copyWith(
      {Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? originDeviceId,
      Value<String>? eventId,
      Value<String>? label,
      Value<int>? minAge,
      Value<int?>? maxAge,
      Value<int>? sortOrder,
      Value<int>? rowid}) {
    return AgeRangesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      eventId: eventId ?? this.eventId,
      label: label ?? this.label,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
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
    if (originDeviceId.present) {
      map['origin_device_id'] = Variable<String>(originDeviceId.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (minAge.present) {
      map['min_age'] = Variable<int>(minAge.value);
    }
    if (maxAge.present) {
      map['max_age'] = Variable<int>(maxAge.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AgeRangesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('eventId: $eventId, ')
          ..write('label: $label, ')
          ..write('minAge: $minAge, ')
          ..write('maxAge: $maxAge, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttendeesTable extends Attendees
    with TableInfo<$AttendeesTable, AttendeeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttendeesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _originDeviceIdMeta =
      const VerificationMeta('originDeviceId');
  @override
  late final GeneratedColumn<String> originDeviceId = GeneratedColumn<String>(
      'origin_device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _eventIdMeta =
      const VerificationMeta('eventId');
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
      'event_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES events (id)'));
  static const VerificationMeta _regNumberMeta =
      const VerificationMeta('regNumber');
  @override
  late final GeneratedColumn<int> regNumber = GeneratedColumn<int>(
      'reg_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _firstNameMeta =
      const VerificationMeta('firstName');
  @override
  late final GeneratedColumn<String> firstName = GeneratedColumn<String>(
      'first_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastName1Meta =
      const VerificationMeta('lastName1');
  @override
  late final GeneratedColumn<String> lastName1 = GeneratedColumn<String>(
      'last_name1', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastName2Meta =
      const VerificationMeta('lastName2');
  @override
  late final GeneratedColumn<String> lastName2 = GeneratedColumn<String>(
      'last_name2', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _sexMeta = const VerificationMeta('sex');
  @override
  late final GeneratedColumn<String> sex = GeneratedColumn<String>(
      'sex', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ageMeta = const VerificationMeta('age');
  @override
  late final GeneratedColumn<int> age = GeneratedColumn<int>(
      'age', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _churchIdMeta =
      const VerificationMeta('churchId');
  @override
  late final GeneratedColumn<String> churchId = GeneratedColumn<String>(
      'church_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES churches (id)'));
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _provinceMeta =
      const VerificationMeta('province');
  @override
  late final GeneratedColumn<String> province = GeneratedColumn<String>(
      'province', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _municipalityMeta =
      const VerificationMeta('municipality');
  @override
  late final GeneratedColumn<String> municipality = GeneratedColumn<String>(
      'municipality', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _needsLodgingMeta =
      const VerificationMeta('needsLodging');
  @override
  late final GeneratedColumn<bool> needsLodging = GeneratedColumn<bool>(
      'needs_lodging', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("needs_lodging" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _coupleIdMeta =
      const VerificationMeta('coupleId');
  @override
  late final GeneratedColumn<String> coupleId = GeneratedColumn<String>(
      'couple_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _teamIdMeta = const VerificationMeta('teamId');
  @override
  late final GeneratedColumn<String> teamId = GeneratedColumn<String>(
      'team_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lodgingIdMeta =
      const VerificationMeta('lodgingId');
  @override
  late final GeneratedColumn<String> lodgingId = GeneratedColumn<String>(
      'lodging_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dedupeKeyMeta =
      const VerificationMeta('dedupeKey');
  @override
  late final GeneratedColumn<String> dedupeKey = GeneratedColumn<String>(
      'dedupe_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdByMeta =
      const VerificationMeta('createdBy');
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
      'created_by', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('confirmed'));
  static const VerificationMeta _confirmedAtMeta =
      const VerificationMeta('confirmedAt');
  @override
  late final GeneratedColumn<DateTime> confirmedAt = GeneratedColumn<DateTime>(
      'confirmed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        createdAt,
        updatedAt,
        deletedAt,
        originDeviceId,
        eventId,
        regNumber,
        firstName,
        lastName1,
        lastName2,
        sex,
        age,
        churchId,
        phone,
        province,
        municipality,
        needsLodging,
        notes,
        coupleId,
        teamId,
        lodgingId,
        dedupeKey,
        createdBy,
        status,
        confirmedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attendees';
  @override
  VerificationContext validateIntegrity(Insertable<AttendeeRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('origin_device_id')) {
      context.handle(
          _originDeviceIdMeta,
          originDeviceId.isAcceptableOrUnknown(
              data['origin_device_id']!, _originDeviceIdMeta));
    } else if (isInserting) {
      context.missing(_originDeviceIdMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(_eventIdMeta,
          eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta));
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('reg_number')) {
      context.handle(_regNumberMeta,
          regNumber.isAcceptableOrUnknown(data['reg_number']!, _regNumberMeta));
    } else if (isInserting) {
      context.missing(_regNumberMeta);
    }
    if (data.containsKey('first_name')) {
      context.handle(_firstNameMeta,
          firstName.isAcceptableOrUnknown(data['first_name']!, _firstNameMeta));
    } else if (isInserting) {
      context.missing(_firstNameMeta);
    }
    if (data.containsKey('last_name1')) {
      context.handle(_lastName1Meta,
          lastName1.isAcceptableOrUnknown(data['last_name1']!, _lastName1Meta));
    } else if (isInserting) {
      context.missing(_lastName1Meta);
    }
    if (data.containsKey('last_name2')) {
      context.handle(_lastName2Meta,
          lastName2.isAcceptableOrUnknown(data['last_name2']!, _lastName2Meta));
    }
    if (data.containsKey('sex')) {
      context.handle(
          _sexMeta, sex.isAcceptableOrUnknown(data['sex']!, _sexMeta));
    } else if (isInserting) {
      context.missing(_sexMeta);
    }
    if (data.containsKey('age')) {
      context.handle(
          _ageMeta, age.isAcceptableOrUnknown(data['age']!, _ageMeta));
    } else if (isInserting) {
      context.missing(_ageMeta);
    }
    if (data.containsKey('church_id')) {
      context.handle(_churchIdMeta,
          churchId.isAcceptableOrUnknown(data['church_id']!, _churchIdMeta));
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    }
    if (data.containsKey('province')) {
      context.handle(_provinceMeta,
          province.isAcceptableOrUnknown(data['province']!, _provinceMeta));
    }
    if (data.containsKey('municipality')) {
      context.handle(
          _municipalityMeta,
          municipality.isAcceptableOrUnknown(
              data['municipality']!, _municipalityMeta));
    }
    if (data.containsKey('needs_lodging')) {
      context.handle(
          _needsLodgingMeta,
          needsLodging.isAcceptableOrUnknown(
              data['needs_lodging']!, _needsLodgingMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('couple_id')) {
      context.handle(_coupleIdMeta,
          coupleId.isAcceptableOrUnknown(data['couple_id']!, _coupleIdMeta));
    }
    if (data.containsKey('team_id')) {
      context.handle(_teamIdMeta,
          teamId.isAcceptableOrUnknown(data['team_id']!, _teamIdMeta));
    }
    if (data.containsKey('lodging_id')) {
      context.handle(_lodgingIdMeta,
          lodgingId.isAcceptableOrUnknown(data['lodging_id']!, _lodgingIdMeta));
    }
    if (data.containsKey('dedupe_key')) {
      context.handle(_dedupeKeyMeta,
          dedupeKey.isAcceptableOrUnknown(data['dedupe_key']!, _dedupeKeyMeta));
    } else if (isInserting) {
      context.missing(_dedupeKeyMeta);
    }
    if (data.containsKey('created_by')) {
      context.handle(_createdByMeta,
          createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('confirmed_at')) {
      context.handle(
          _confirmedAtMeta,
          confirmedAt.isAcceptableOrUnknown(
              data['confirmed_at']!, _confirmedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {eventId, regNumber},
      ];
  @override
  AttendeeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttendeeRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      originDeviceId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}origin_device_id'])!,
      eventId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_id'])!,
      regNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}reg_number'])!,
      firstName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}first_name'])!,
      lastName1: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_name1'])!,
      lastName2: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_name2'])!,
      sex: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sex'])!,
      age: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}age'])!,
      churchId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}church_id']),
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone']),
      province: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}province'])!,
      municipality: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}municipality'])!,
      needsLodging: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}needs_lodging'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
      coupleId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}couple_id']),
      teamId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}team_id']),
      lodgingId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lodging_id']),
      dedupeKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}dedupe_key'])!,
      createdBy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_by']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      confirmedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}confirmed_at']),
    );
  }

  @override
  $AttendeesTable createAlias(String alias) {
    return $AttendeesTable(attachedDatabase, alias);
  }
}

class AttendeeRow extends DataClass implements Insertable<AttendeeRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String originDeviceId;
  final String eventId;
  final int regNumber;
  final String firstName;
  final String lastName1;
  final String lastName2;
  final String sex;
  final int age;
  final String? churchId;
  final String? phone;
  final String province;
  final String municipality;
  final bool needsLodging;
  final String notes;
  final String? coupleId;
  final String? teamId;
  final String? lodgingId;
  final String dedupeKey;
  final String? createdBy;
  final String status;
  final DateTime? confirmedAt;
  const AttendeeRow(
      {required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.originDeviceId,
      required this.eventId,
      required this.regNumber,
      required this.firstName,
      required this.lastName1,
      required this.lastName2,
      required this.sex,
      required this.age,
      this.churchId,
      this.phone,
      required this.province,
      required this.municipality,
      required this.needsLodging,
      required this.notes,
      this.coupleId,
      this.teamId,
      this.lodgingId,
      required this.dedupeKey,
      this.createdBy,
      required this.status,
      this.confirmedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['origin_device_id'] = Variable<String>(originDeviceId);
    map['event_id'] = Variable<String>(eventId);
    map['reg_number'] = Variable<int>(regNumber);
    map['first_name'] = Variable<String>(firstName);
    map['last_name1'] = Variable<String>(lastName1);
    map['last_name2'] = Variable<String>(lastName2);
    map['sex'] = Variable<String>(sex);
    map['age'] = Variable<int>(age);
    if (!nullToAbsent || churchId != null) {
      map['church_id'] = Variable<String>(churchId);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    map['province'] = Variable<String>(province);
    map['municipality'] = Variable<String>(municipality);
    map['needs_lodging'] = Variable<bool>(needsLodging);
    map['notes'] = Variable<String>(notes);
    if (!nullToAbsent || coupleId != null) {
      map['couple_id'] = Variable<String>(coupleId);
    }
    if (!nullToAbsent || teamId != null) {
      map['team_id'] = Variable<String>(teamId);
    }
    if (!nullToAbsent || lodgingId != null) {
      map['lodging_id'] = Variable<String>(lodgingId);
    }
    map['dedupe_key'] = Variable<String>(dedupeKey);
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || confirmedAt != null) {
      map['confirmed_at'] = Variable<DateTime>(confirmedAt);
    }
    return map;
  }

  AttendeesCompanion toCompanion(bool nullToAbsent) {
    return AttendeesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      originDeviceId: Value(originDeviceId),
      eventId: Value(eventId),
      regNumber: Value(regNumber),
      firstName: Value(firstName),
      lastName1: Value(lastName1),
      lastName2: Value(lastName2),
      sex: Value(sex),
      age: Value(age),
      churchId: churchId == null && nullToAbsent
          ? const Value.absent()
          : Value(churchId),
      phone:
          phone == null && nullToAbsent ? const Value.absent() : Value(phone),
      province: Value(province),
      municipality: Value(municipality),
      needsLodging: Value(needsLodging),
      notes: Value(notes),
      coupleId: coupleId == null && nullToAbsent
          ? const Value.absent()
          : Value(coupleId),
      teamId:
          teamId == null && nullToAbsent ? const Value.absent() : Value(teamId),
      lodgingId: lodgingId == null && nullToAbsent
          ? const Value.absent()
          : Value(lodgingId),
      dedupeKey: Value(dedupeKey),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      status: Value(status),
      confirmedAt: confirmedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(confirmedAt),
    );
  }

  factory AttendeeRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttendeeRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      originDeviceId: serializer.fromJson<String>(json['originDeviceId']),
      eventId: serializer.fromJson<String>(json['eventId']),
      regNumber: serializer.fromJson<int>(json['regNumber']),
      firstName: serializer.fromJson<String>(json['firstName']),
      lastName1: serializer.fromJson<String>(json['lastName1']),
      lastName2: serializer.fromJson<String>(json['lastName2']),
      sex: serializer.fromJson<String>(json['sex']),
      age: serializer.fromJson<int>(json['age']),
      churchId: serializer.fromJson<String?>(json['churchId']),
      phone: serializer.fromJson<String?>(json['phone']),
      province: serializer.fromJson<String>(json['province']),
      municipality: serializer.fromJson<String>(json['municipality']),
      needsLodging: serializer.fromJson<bool>(json['needsLodging']),
      notes: serializer.fromJson<String>(json['notes']),
      coupleId: serializer.fromJson<String?>(json['coupleId']),
      teamId: serializer.fromJson<String?>(json['teamId']),
      lodgingId: serializer.fromJson<String?>(json['lodgingId']),
      dedupeKey: serializer.fromJson<String>(json['dedupeKey']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      status: serializer.fromJson<String>(json['status']),
      confirmedAt: serializer.fromJson<DateTime?>(json['confirmedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'originDeviceId': serializer.toJson<String>(originDeviceId),
      'eventId': serializer.toJson<String>(eventId),
      'regNumber': serializer.toJson<int>(regNumber),
      'firstName': serializer.toJson<String>(firstName),
      'lastName1': serializer.toJson<String>(lastName1),
      'lastName2': serializer.toJson<String>(lastName2),
      'sex': serializer.toJson<String>(sex),
      'age': serializer.toJson<int>(age),
      'churchId': serializer.toJson<String?>(churchId),
      'phone': serializer.toJson<String?>(phone),
      'province': serializer.toJson<String>(province),
      'municipality': serializer.toJson<String>(municipality),
      'needsLodging': serializer.toJson<bool>(needsLodging),
      'notes': serializer.toJson<String>(notes),
      'coupleId': serializer.toJson<String?>(coupleId),
      'teamId': serializer.toJson<String?>(teamId),
      'lodgingId': serializer.toJson<String?>(lodgingId),
      'dedupeKey': serializer.toJson<String>(dedupeKey),
      'createdBy': serializer.toJson<String?>(createdBy),
      'status': serializer.toJson<String>(status),
      'confirmedAt': serializer.toJson<DateTime?>(confirmedAt),
    };
  }

  AttendeeRow copyWith(
          {String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          String? originDeviceId,
          String? eventId,
          int? regNumber,
          String? firstName,
          String? lastName1,
          String? lastName2,
          String? sex,
          int? age,
          Value<String?> churchId = const Value.absent(),
          Value<String?> phone = const Value.absent(),
          String? province,
          String? municipality,
          bool? needsLodging,
          String? notes,
          Value<String?> coupleId = const Value.absent(),
          Value<String?> teamId = const Value.absent(),
          Value<String?> lodgingId = const Value.absent(),
          String? dedupeKey,
          Value<String?> createdBy = const Value.absent(),
          String? status,
          Value<DateTime?> confirmedAt = const Value.absent()}) =>
      AttendeeRow(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        originDeviceId: originDeviceId ?? this.originDeviceId,
        eventId: eventId ?? this.eventId,
        regNumber: regNumber ?? this.regNumber,
        firstName: firstName ?? this.firstName,
        lastName1: lastName1 ?? this.lastName1,
        lastName2: lastName2 ?? this.lastName2,
        sex: sex ?? this.sex,
        age: age ?? this.age,
        churchId: churchId.present ? churchId.value : this.churchId,
        phone: phone.present ? phone.value : this.phone,
        province: province ?? this.province,
        municipality: municipality ?? this.municipality,
        needsLodging: needsLodging ?? this.needsLodging,
        notes: notes ?? this.notes,
        coupleId: coupleId.present ? coupleId.value : this.coupleId,
        teamId: teamId.present ? teamId.value : this.teamId,
        lodgingId: lodgingId.present ? lodgingId.value : this.lodgingId,
        dedupeKey: dedupeKey ?? this.dedupeKey,
        createdBy: createdBy.present ? createdBy.value : this.createdBy,
        status: status ?? this.status,
        confirmedAt: confirmedAt.present ? confirmedAt.value : this.confirmedAt,
      );
  AttendeeRow copyWithCompanion(AttendeesCompanion data) {
    return AttendeeRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      originDeviceId: data.originDeviceId.present
          ? data.originDeviceId.value
          : this.originDeviceId,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      regNumber: data.regNumber.present ? data.regNumber.value : this.regNumber,
      firstName: data.firstName.present ? data.firstName.value : this.firstName,
      lastName1: data.lastName1.present ? data.lastName1.value : this.lastName1,
      lastName2: data.lastName2.present ? data.lastName2.value : this.lastName2,
      sex: data.sex.present ? data.sex.value : this.sex,
      age: data.age.present ? data.age.value : this.age,
      churchId: data.churchId.present ? data.churchId.value : this.churchId,
      phone: data.phone.present ? data.phone.value : this.phone,
      province: data.province.present ? data.province.value : this.province,
      municipality: data.municipality.present
          ? data.municipality.value
          : this.municipality,
      needsLodging: data.needsLodging.present
          ? data.needsLodging.value
          : this.needsLodging,
      notes: data.notes.present ? data.notes.value : this.notes,
      coupleId: data.coupleId.present ? data.coupleId.value : this.coupleId,
      teamId: data.teamId.present ? data.teamId.value : this.teamId,
      lodgingId: data.lodgingId.present ? data.lodgingId.value : this.lodgingId,
      dedupeKey: data.dedupeKey.present ? data.dedupeKey.value : this.dedupeKey,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      status: data.status.present ? data.status.value : this.status,
      confirmedAt:
          data.confirmedAt.present ? data.confirmedAt.value : this.confirmedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttendeeRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('eventId: $eventId, ')
          ..write('regNumber: $regNumber, ')
          ..write('firstName: $firstName, ')
          ..write('lastName1: $lastName1, ')
          ..write('lastName2: $lastName2, ')
          ..write('sex: $sex, ')
          ..write('age: $age, ')
          ..write('churchId: $churchId, ')
          ..write('phone: $phone, ')
          ..write('province: $province, ')
          ..write('municipality: $municipality, ')
          ..write('needsLodging: $needsLodging, ')
          ..write('notes: $notes, ')
          ..write('coupleId: $coupleId, ')
          ..write('teamId: $teamId, ')
          ..write('lodgingId: $lodgingId, ')
          ..write('dedupeKey: $dedupeKey, ')
          ..write('createdBy: $createdBy, ')
          ..write('status: $status, ')
          ..write('confirmedAt: $confirmedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        createdAt,
        updatedAt,
        deletedAt,
        originDeviceId,
        eventId,
        regNumber,
        firstName,
        lastName1,
        lastName2,
        sex,
        age,
        churchId,
        phone,
        province,
        municipality,
        needsLodging,
        notes,
        coupleId,
        teamId,
        lodgingId,
        dedupeKey,
        createdBy,
        status,
        confirmedAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttendeeRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.originDeviceId == this.originDeviceId &&
          other.eventId == this.eventId &&
          other.regNumber == this.regNumber &&
          other.firstName == this.firstName &&
          other.lastName1 == this.lastName1 &&
          other.lastName2 == this.lastName2 &&
          other.sex == this.sex &&
          other.age == this.age &&
          other.churchId == this.churchId &&
          other.phone == this.phone &&
          other.province == this.province &&
          other.municipality == this.municipality &&
          other.needsLodging == this.needsLodging &&
          other.notes == this.notes &&
          other.coupleId == this.coupleId &&
          other.teamId == this.teamId &&
          other.lodgingId == this.lodgingId &&
          other.dedupeKey == this.dedupeKey &&
          other.createdBy == this.createdBy &&
          other.status == this.status &&
          other.confirmedAt == this.confirmedAt);
}

class AttendeesCompanion extends UpdateCompanion<AttendeeRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> originDeviceId;
  final Value<String> eventId;
  final Value<int> regNumber;
  final Value<String> firstName;
  final Value<String> lastName1;
  final Value<String> lastName2;
  final Value<String> sex;
  final Value<int> age;
  final Value<String?> churchId;
  final Value<String?> phone;
  final Value<String> province;
  final Value<String> municipality;
  final Value<bool> needsLodging;
  final Value<String> notes;
  final Value<String?> coupleId;
  final Value<String?> teamId;
  final Value<String?> lodgingId;
  final Value<String> dedupeKey;
  final Value<String?> createdBy;
  final Value<String> status;
  final Value<DateTime?> confirmedAt;
  final Value<int> rowid;
  const AttendeesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.originDeviceId = const Value.absent(),
    this.eventId = const Value.absent(),
    this.regNumber = const Value.absent(),
    this.firstName = const Value.absent(),
    this.lastName1 = const Value.absent(),
    this.lastName2 = const Value.absent(),
    this.sex = const Value.absent(),
    this.age = const Value.absent(),
    this.churchId = const Value.absent(),
    this.phone = const Value.absent(),
    this.province = const Value.absent(),
    this.municipality = const Value.absent(),
    this.needsLodging = const Value.absent(),
    this.notes = const Value.absent(),
    this.coupleId = const Value.absent(),
    this.teamId = const Value.absent(),
    this.lodgingId = const Value.absent(),
    this.dedupeKey = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.status = const Value.absent(),
    this.confirmedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttendeesCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String originDeviceId,
    required String eventId,
    required int regNumber,
    required String firstName,
    required String lastName1,
    this.lastName2 = const Value.absent(),
    required String sex,
    required int age,
    this.churchId = const Value.absent(),
    this.phone = const Value.absent(),
    this.province = const Value.absent(),
    this.municipality = const Value.absent(),
    this.needsLodging = const Value.absent(),
    this.notes = const Value.absent(),
    this.coupleId = const Value.absent(),
    this.teamId = const Value.absent(),
    this.lodgingId = const Value.absent(),
    required String dedupeKey,
    this.createdBy = const Value.absent(),
    this.status = const Value.absent(),
    this.confirmedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        originDeviceId = Value(originDeviceId),
        eventId = Value(eventId),
        regNumber = Value(regNumber),
        firstName = Value(firstName),
        lastName1 = Value(lastName1),
        sex = Value(sex),
        age = Value(age),
        dedupeKey = Value(dedupeKey);
  static Insertable<AttendeeRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? originDeviceId,
    Expression<String>? eventId,
    Expression<int>? regNumber,
    Expression<String>? firstName,
    Expression<String>? lastName1,
    Expression<String>? lastName2,
    Expression<String>? sex,
    Expression<int>? age,
    Expression<String>? churchId,
    Expression<String>? phone,
    Expression<String>? province,
    Expression<String>? municipality,
    Expression<bool>? needsLodging,
    Expression<String>? notes,
    Expression<String>? coupleId,
    Expression<String>? teamId,
    Expression<String>? lodgingId,
    Expression<String>? dedupeKey,
    Expression<String>? createdBy,
    Expression<String>? status,
    Expression<DateTime>? confirmedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (originDeviceId != null) 'origin_device_id': originDeviceId,
      if (eventId != null) 'event_id': eventId,
      if (regNumber != null) 'reg_number': regNumber,
      if (firstName != null) 'first_name': firstName,
      if (lastName1 != null) 'last_name1': lastName1,
      if (lastName2 != null) 'last_name2': lastName2,
      if (sex != null) 'sex': sex,
      if (age != null) 'age': age,
      if (churchId != null) 'church_id': churchId,
      if (phone != null) 'phone': phone,
      if (province != null) 'province': province,
      if (municipality != null) 'municipality': municipality,
      if (needsLodging != null) 'needs_lodging': needsLodging,
      if (notes != null) 'notes': notes,
      if (coupleId != null) 'couple_id': coupleId,
      if (teamId != null) 'team_id': teamId,
      if (lodgingId != null) 'lodging_id': lodgingId,
      if (dedupeKey != null) 'dedupe_key': dedupeKey,
      if (createdBy != null) 'created_by': createdBy,
      if (status != null) 'status': status,
      if (confirmedAt != null) 'confirmed_at': confirmedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttendeesCompanion copyWith(
      {Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? originDeviceId,
      Value<String>? eventId,
      Value<int>? regNumber,
      Value<String>? firstName,
      Value<String>? lastName1,
      Value<String>? lastName2,
      Value<String>? sex,
      Value<int>? age,
      Value<String?>? churchId,
      Value<String?>? phone,
      Value<String>? province,
      Value<String>? municipality,
      Value<bool>? needsLodging,
      Value<String>? notes,
      Value<String?>? coupleId,
      Value<String?>? teamId,
      Value<String?>? lodgingId,
      Value<String>? dedupeKey,
      Value<String?>? createdBy,
      Value<String>? status,
      Value<DateTime?>? confirmedAt,
      Value<int>? rowid}) {
    return AttendeesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      eventId: eventId ?? this.eventId,
      regNumber: regNumber ?? this.regNumber,
      firstName: firstName ?? this.firstName,
      lastName1: lastName1 ?? this.lastName1,
      lastName2: lastName2 ?? this.lastName2,
      sex: sex ?? this.sex,
      age: age ?? this.age,
      churchId: churchId ?? this.churchId,
      phone: phone ?? this.phone,
      province: province ?? this.province,
      municipality: municipality ?? this.municipality,
      needsLodging: needsLodging ?? this.needsLodging,
      notes: notes ?? this.notes,
      coupleId: coupleId ?? this.coupleId,
      teamId: teamId ?? this.teamId,
      lodgingId: lodgingId ?? this.lodgingId,
      dedupeKey: dedupeKey ?? this.dedupeKey,
      createdBy: createdBy ?? this.createdBy,
      status: status ?? this.status,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
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
    if (originDeviceId.present) {
      map['origin_device_id'] = Variable<String>(originDeviceId.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (regNumber.present) {
      map['reg_number'] = Variable<int>(regNumber.value);
    }
    if (firstName.present) {
      map['first_name'] = Variable<String>(firstName.value);
    }
    if (lastName1.present) {
      map['last_name1'] = Variable<String>(lastName1.value);
    }
    if (lastName2.present) {
      map['last_name2'] = Variable<String>(lastName2.value);
    }
    if (sex.present) {
      map['sex'] = Variable<String>(sex.value);
    }
    if (age.present) {
      map['age'] = Variable<int>(age.value);
    }
    if (churchId.present) {
      map['church_id'] = Variable<String>(churchId.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (province.present) {
      map['province'] = Variable<String>(province.value);
    }
    if (municipality.present) {
      map['municipality'] = Variable<String>(municipality.value);
    }
    if (needsLodging.present) {
      map['needs_lodging'] = Variable<bool>(needsLodging.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (coupleId.present) {
      map['couple_id'] = Variable<String>(coupleId.value);
    }
    if (teamId.present) {
      map['team_id'] = Variable<String>(teamId.value);
    }
    if (lodgingId.present) {
      map['lodging_id'] = Variable<String>(lodgingId.value);
    }
    if (dedupeKey.present) {
      map['dedupe_key'] = Variable<String>(dedupeKey.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (confirmedAt.present) {
      map['confirmed_at'] = Variable<DateTime>(confirmedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttendeesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('eventId: $eventId, ')
          ..write('regNumber: $regNumber, ')
          ..write('firstName: $firstName, ')
          ..write('lastName1: $lastName1, ')
          ..write('lastName2: $lastName2, ')
          ..write('sex: $sex, ')
          ..write('age: $age, ')
          ..write('churchId: $churchId, ')
          ..write('phone: $phone, ')
          ..write('province: $province, ')
          ..write('municipality: $municipality, ')
          ..write('needsLodging: $needsLodging, ')
          ..write('notes: $notes, ')
          ..write('coupleId: $coupleId, ')
          ..write('teamId: $teamId, ')
          ..write('lodgingId: $lodgingId, ')
          ..write('dedupeKey: $dedupeKey, ')
          ..write('createdBy: $createdBy, ')
          ..write('status: $status, ')
          ..write('confirmedAt: $confirmedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CouplesTable extends Couples with TableInfo<$CouplesTable, Couple> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CouplesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _originDeviceIdMeta =
      const VerificationMeta('originDeviceId');
  @override
  late final GeneratedColumn<String> originDeviceId = GeneratedColumn<String>(
      'origin_device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _eventIdMeta =
      const VerificationMeta('eventId');
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
      'event_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES events (id)'));
  static const VerificationMeta _attendeeAIdMeta =
      const VerificationMeta('attendeeAId');
  @override
  late final GeneratedColumn<String> attendeeAId = GeneratedColumn<String>(
      'attendee_a_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES attendees (id)'));
  static const VerificationMeta _attendeeBIdMeta =
      const VerificationMeta('attendeeBId');
  @override
  late final GeneratedColumn<String> attendeeBId = GeneratedColumn<String>(
      'attendee_b_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES attendees (id)'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        createdAt,
        updatedAt,
        deletedAt,
        originDeviceId,
        eventId,
        attendeeAId,
        attendeeBId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'couples';
  @override
  VerificationContext validateIntegrity(Insertable<Couple> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('origin_device_id')) {
      context.handle(
          _originDeviceIdMeta,
          originDeviceId.isAcceptableOrUnknown(
              data['origin_device_id']!, _originDeviceIdMeta));
    } else if (isInserting) {
      context.missing(_originDeviceIdMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(_eventIdMeta,
          eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta));
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('attendee_a_id')) {
      context.handle(
          _attendeeAIdMeta,
          attendeeAId.isAcceptableOrUnknown(
              data['attendee_a_id']!, _attendeeAIdMeta));
    } else if (isInserting) {
      context.missing(_attendeeAIdMeta);
    }
    if (data.containsKey('attendee_b_id')) {
      context.handle(
          _attendeeBIdMeta,
          attendeeBId.isAcceptableOrUnknown(
              data['attendee_b_id']!, _attendeeBIdMeta));
    } else if (isInserting) {
      context.missing(_attendeeBIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Couple map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Couple(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      originDeviceId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}origin_device_id'])!,
      eventId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_id'])!,
      attendeeAId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}attendee_a_id'])!,
      attendeeBId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}attendee_b_id'])!,
    );
  }

  @override
  $CouplesTable createAlias(String alias) {
    return $CouplesTable(attachedDatabase, alias);
  }
}

class Couple extends DataClass implements Insertable<Couple> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String originDeviceId;
  final String eventId;
  final String attendeeAId;
  final String attendeeBId;
  const Couple(
      {required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.originDeviceId,
      required this.eventId,
      required this.attendeeAId,
      required this.attendeeBId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['origin_device_id'] = Variable<String>(originDeviceId);
    map['event_id'] = Variable<String>(eventId);
    map['attendee_a_id'] = Variable<String>(attendeeAId);
    map['attendee_b_id'] = Variable<String>(attendeeBId);
    return map;
  }

  CouplesCompanion toCompanion(bool nullToAbsent) {
    return CouplesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      originDeviceId: Value(originDeviceId),
      eventId: Value(eventId),
      attendeeAId: Value(attendeeAId),
      attendeeBId: Value(attendeeBId),
    );
  }

  factory Couple.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Couple(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      originDeviceId: serializer.fromJson<String>(json['originDeviceId']),
      eventId: serializer.fromJson<String>(json['eventId']),
      attendeeAId: serializer.fromJson<String>(json['attendeeAId']),
      attendeeBId: serializer.fromJson<String>(json['attendeeBId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'originDeviceId': serializer.toJson<String>(originDeviceId),
      'eventId': serializer.toJson<String>(eventId),
      'attendeeAId': serializer.toJson<String>(attendeeAId),
      'attendeeBId': serializer.toJson<String>(attendeeBId),
    };
  }

  Couple copyWith(
          {String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          String? originDeviceId,
          String? eventId,
          String? attendeeAId,
          String? attendeeBId}) =>
      Couple(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        originDeviceId: originDeviceId ?? this.originDeviceId,
        eventId: eventId ?? this.eventId,
        attendeeAId: attendeeAId ?? this.attendeeAId,
        attendeeBId: attendeeBId ?? this.attendeeBId,
      );
  Couple copyWithCompanion(CouplesCompanion data) {
    return Couple(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      originDeviceId: data.originDeviceId.present
          ? data.originDeviceId.value
          : this.originDeviceId,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      attendeeAId:
          data.attendeeAId.present ? data.attendeeAId.value : this.attendeeAId,
      attendeeBId:
          data.attendeeBId.present ? data.attendeeBId.value : this.attendeeBId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Couple(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('eventId: $eventId, ')
          ..write('attendeeAId: $attendeeAId, ')
          ..write('attendeeBId: $attendeeBId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, createdAt, updatedAt, deletedAt,
      originDeviceId, eventId, attendeeAId, attendeeBId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Couple &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.originDeviceId == this.originDeviceId &&
          other.eventId == this.eventId &&
          other.attendeeAId == this.attendeeAId &&
          other.attendeeBId == this.attendeeBId);
}

class CouplesCompanion extends UpdateCompanion<Couple> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> originDeviceId;
  final Value<String> eventId;
  final Value<String> attendeeAId;
  final Value<String> attendeeBId;
  final Value<int> rowid;
  const CouplesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.originDeviceId = const Value.absent(),
    this.eventId = const Value.absent(),
    this.attendeeAId = const Value.absent(),
    this.attendeeBId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CouplesCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String originDeviceId,
    required String eventId,
    required String attendeeAId,
    required String attendeeBId,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        originDeviceId = Value(originDeviceId),
        eventId = Value(eventId),
        attendeeAId = Value(attendeeAId),
        attendeeBId = Value(attendeeBId);
  static Insertable<Couple> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? originDeviceId,
    Expression<String>? eventId,
    Expression<String>? attendeeAId,
    Expression<String>? attendeeBId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (originDeviceId != null) 'origin_device_id': originDeviceId,
      if (eventId != null) 'event_id': eventId,
      if (attendeeAId != null) 'attendee_a_id': attendeeAId,
      if (attendeeBId != null) 'attendee_b_id': attendeeBId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CouplesCompanion copyWith(
      {Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? originDeviceId,
      Value<String>? eventId,
      Value<String>? attendeeAId,
      Value<String>? attendeeBId,
      Value<int>? rowid}) {
    return CouplesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      eventId: eventId ?? this.eventId,
      attendeeAId: attendeeAId ?? this.attendeeAId,
      attendeeBId: attendeeBId ?? this.attendeeBId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
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
    if (originDeviceId.present) {
      map['origin_device_id'] = Variable<String>(originDeviceId.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (attendeeAId.present) {
      map['attendee_a_id'] = Variable<String>(attendeeAId.value);
    }
    if (attendeeBId.present) {
      map['attendee_b_id'] = Variable<String>(attendeeBId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CouplesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('eventId: $eventId, ')
          ..write('attendeeAId: $attendeeAId, ')
          ..write('attendeeBId: $attendeeBId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttendeeGroupsTable extends AttendeeGroups
    with TableInfo<$AttendeeGroupsTable, AttendeeGroup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttendeeGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _originDeviceIdMeta =
      const VerificationMeta('originDeviceId');
  @override
  late final GeneratedColumn<String> originDeviceId = GeneratedColumn<String>(
      'origin_device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _eventIdMeta =
      const VerificationMeta('eventId');
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
      'event_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES events (id)'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
      'reason', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('preference'));
  static const VerificationMeta _keepTogetherMeta =
      const VerificationMeta('keepTogether');
  @override
  late final GeneratedColumn<bool> keepTogether = GeneratedColumn<bool>(
      'keep_together', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("keep_together" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        createdAt,
        updatedAt,
        deletedAt,
        originDeviceId,
        eventId,
        name,
        reason,
        keepTogether
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attendee_groups';
  @override
  VerificationContext validateIntegrity(Insertable<AttendeeGroup> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('origin_device_id')) {
      context.handle(
          _originDeviceIdMeta,
          originDeviceId.isAcceptableOrUnknown(
              data['origin_device_id']!, _originDeviceIdMeta));
    } else if (isInserting) {
      context.missing(_originDeviceIdMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(_eventIdMeta,
          eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta));
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(_reasonMeta,
          reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta));
    }
    if (data.containsKey('keep_together')) {
      context.handle(
          _keepTogetherMeta,
          keepTogether.isAcceptableOrUnknown(
              data['keep_together']!, _keepTogetherMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttendeeGroup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttendeeGroup(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      originDeviceId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}origin_device_id'])!,
      eventId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      reason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reason'])!,
      keepTogether: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}keep_together'])!,
    );
  }

  @override
  $AttendeeGroupsTable createAlias(String alias) {
    return $AttendeeGroupsTable(attachedDatabase, alias);
  }
}

class AttendeeGroup extends DataClass implements Insertable<AttendeeGroup> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String originDeviceId;
  final String eventId;
  final String name;
  final String reason;
  final bool keepTogether;
  const AttendeeGroup(
      {required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.originDeviceId,
      required this.eventId,
      required this.name,
      required this.reason,
      required this.keepTogether});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['origin_device_id'] = Variable<String>(originDeviceId);
    map['event_id'] = Variable<String>(eventId);
    map['name'] = Variable<String>(name);
    map['reason'] = Variable<String>(reason);
    map['keep_together'] = Variable<bool>(keepTogether);
    return map;
  }

  AttendeeGroupsCompanion toCompanion(bool nullToAbsent) {
    return AttendeeGroupsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      originDeviceId: Value(originDeviceId),
      eventId: Value(eventId),
      name: Value(name),
      reason: Value(reason),
      keepTogether: Value(keepTogether),
    );
  }

  factory AttendeeGroup.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttendeeGroup(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      originDeviceId: serializer.fromJson<String>(json['originDeviceId']),
      eventId: serializer.fromJson<String>(json['eventId']),
      name: serializer.fromJson<String>(json['name']),
      reason: serializer.fromJson<String>(json['reason']),
      keepTogether: serializer.fromJson<bool>(json['keepTogether']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'originDeviceId': serializer.toJson<String>(originDeviceId),
      'eventId': serializer.toJson<String>(eventId),
      'name': serializer.toJson<String>(name),
      'reason': serializer.toJson<String>(reason),
      'keepTogether': serializer.toJson<bool>(keepTogether),
    };
  }

  AttendeeGroup copyWith(
          {String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          String? originDeviceId,
          String? eventId,
          String? name,
          String? reason,
          bool? keepTogether}) =>
      AttendeeGroup(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        originDeviceId: originDeviceId ?? this.originDeviceId,
        eventId: eventId ?? this.eventId,
        name: name ?? this.name,
        reason: reason ?? this.reason,
        keepTogether: keepTogether ?? this.keepTogether,
      );
  AttendeeGroup copyWithCompanion(AttendeeGroupsCompanion data) {
    return AttendeeGroup(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      originDeviceId: data.originDeviceId.present
          ? data.originDeviceId.value
          : this.originDeviceId,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      name: data.name.present ? data.name.value : this.name,
      reason: data.reason.present ? data.reason.value : this.reason,
      keepTogether: data.keepTogether.present
          ? data.keepTogether.value
          : this.keepTogether,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttendeeGroup(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('eventId: $eventId, ')
          ..write('name: $name, ')
          ..write('reason: $reason, ')
          ..write('keepTogether: $keepTogether')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, createdAt, updatedAt, deletedAt,
      originDeviceId, eventId, name, reason, keepTogether);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttendeeGroup &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.originDeviceId == this.originDeviceId &&
          other.eventId == this.eventId &&
          other.name == this.name &&
          other.reason == this.reason &&
          other.keepTogether == this.keepTogether);
}

class AttendeeGroupsCompanion extends UpdateCompanion<AttendeeGroup> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> originDeviceId;
  final Value<String> eventId;
  final Value<String> name;
  final Value<String> reason;
  final Value<bool> keepTogether;
  final Value<int> rowid;
  const AttendeeGroupsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.originDeviceId = const Value.absent(),
    this.eventId = const Value.absent(),
    this.name = const Value.absent(),
    this.reason = const Value.absent(),
    this.keepTogether = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttendeeGroupsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String originDeviceId,
    required String eventId,
    required String name,
    this.reason = const Value.absent(),
    this.keepTogether = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        originDeviceId = Value(originDeviceId),
        eventId = Value(eventId),
        name = Value(name);
  static Insertable<AttendeeGroup> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? originDeviceId,
    Expression<String>? eventId,
    Expression<String>? name,
    Expression<String>? reason,
    Expression<bool>? keepTogether,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (originDeviceId != null) 'origin_device_id': originDeviceId,
      if (eventId != null) 'event_id': eventId,
      if (name != null) 'name': name,
      if (reason != null) 'reason': reason,
      if (keepTogether != null) 'keep_together': keepTogether,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttendeeGroupsCompanion copyWith(
      {Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? originDeviceId,
      Value<String>? eventId,
      Value<String>? name,
      Value<String>? reason,
      Value<bool>? keepTogether,
      Value<int>? rowid}) {
    return AttendeeGroupsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      eventId: eventId ?? this.eventId,
      name: name ?? this.name,
      reason: reason ?? this.reason,
      keepTogether: keepTogether ?? this.keepTogether,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
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
    if (originDeviceId.present) {
      map['origin_device_id'] = Variable<String>(originDeviceId.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (keepTogether.present) {
      map['keep_together'] = Variable<bool>(keepTogether.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttendeeGroupsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('eventId: $eventId, ')
          ..write('name: $name, ')
          ..write('reason: $reason, ')
          ..write('keepTogether: $keepTogether, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GroupMembersTable extends GroupMembers
    with TableInfo<$GroupMembersTable, GroupMember> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _originDeviceIdMeta =
      const VerificationMeta('originDeviceId');
  @override
  late final GeneratedColumn<String> originDeviceId = GeneratedColumn<String>(
      'origin_device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES attendee_groups (id)'));
  static const VerificationMeta _attendeeIdMeta =
      const VerificationMeta('attendeeId');
  @override
  late final GeneratedColumn<String> attendeeId = GeneratedColumn<String>(
      'attendee_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES attendees (id)'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        createdAt,
        updatedAt,
        deletedAt,
        originDeviceId,
        groupId,
        attendeeId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'group_members';
  @override
  VerificationContext validateIntegrity(Insertable<GroupMember> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('origin_device_id')) {
      context.handle(
          _originDeviceIdMeta,
          originDeviceId.isAcceptableOrUnknown(
              data['origin_device_id']!, _originDeviceIdMeta));
    } else if (isInserting) {
      context.missing(_originDeviceIdMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('attendee_id')) {
      context.handle(
          _attendeeIdMeta,
          attendeeId.isAcceptableOrUnknown(
              data['attendee_id']!, _attendeeIdMeta));
    } else if (isInserting) {
      context.missing(_attendeeIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GroupMember map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupMember(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      originDeviceId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}origin_device_id'])!,
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id'])!,
      attendeeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}attendee_id'])!,
    );
  }

  @override
  $GroupMembersTable createAlias(String alias) {
    return $GroupMembersTable(attachedDatabase, alias);
  }
}

class GroupMember extends DataClass implements Insertable<GroupMember> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String originDeviceId;
  final String groupId;
  final String attendeeId;
  const GroupMember(
      {required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.originDeviceId,
      required this.groupId,
      required this.attendeeId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['origin_device_id'] = Variable<String>(originDeviceId);
    map['group_id'] = Variable<String>(groupId);
    map['attendee_id'] = Variable<String>(attendeeId);
    return map;
  }

  GroupMembersCompanion toCompanion(bool nullToAbsent) {
    return GroupMembersCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      originDeviceId: Value(originDeviceId),
      groupId: Value(groupId),
      attendeeId: Value(attendeeId),
    );
  }

  factory GroupMember.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupMember(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      originDeviceId: serializer.fromJson<String>(json['originDeviceId']),
      groupId: serializer.fromJson<String>(json['groupId']),
      attendeeId: serializer.fromJson<String>(json['attendeeId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'originDeviceId': serializer.toJson<String>(originDeviceId),
      'groupId': serializer.toJson<String>(groupId),
      'attendeeId': serializer.toJson<String>(attendeeId),
    };
  }

  GroupMember copyWith(
          {String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          String? originDeviceId,
          String? groupId,
          String? attendeeId}) =>
      GroupMember(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        originDeviceId: originDeviceId ?? this.originDeviceId,
        groupId: groupId ?? this.groupId,
        attendeeId: attendeeId ?? this.attendeeId,
      );
  GroupMember copyWithCompanion(GroupMembersCompanion data) {
    return GroupMember(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      originDeviceId: data.originDeviceId.present
          ? data.originDeviceId.value
          : this.originDeviceId,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      attendeeId:
          data.attendeeId.present ? data.attendeeId.value : this.attendeeId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroupMember(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('groupId: $groupId, ')
          ..write('attendeeId: $attendeeId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, createdAt, updatedAt, deletedAt, originDeviceId, groupId, attendeeId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupMember &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.originDeviceId == this.originDeviceId &&
          other.groupId == this.groupId &&
          other.attendeeId == this.attendeeId);
}

class GroupMembersCompanion extends UpdateCompanion<GroupMember> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> originDeviceId;
  final Value<String> groupId;
  final Value<String> attendeeId;
  final Value<int> rowid;
  const GroupMembersCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.originDeviceId = const Value.absent(),
    this.groupId = const Value.absent(),
    this.attendeeId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroupMembersCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String originDeviceId,
    required String groupId,
    required String attendeeId,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        originDeviceId = Value(originDeviceId),
        groupId = Value(groupId),
        attendeeId = Value(attendeeId);
  static Insertable<GroupMember> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? originDeviceId,
    Expression<String>? groupId,
    Expression<String>? attendeeId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (originDeviceId != null) 'origin_device_id': originDeviceId,
      if (groupId != null) 'group_id': groupId,
      if (attendeeId != null) 'attendee_id': attendeeId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupMembersCompanion copyWith(
      {Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? originDeviceId,
      Value<String>? groupId,
      Value<String>? attendeeId,
      Value<int>? rowid}) {
    return GroupMembersCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      groupId: groupId ?? this.groupId,
      attendeeId: attendeeId ?? this.attendeeId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
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
    if (originDeviceId.present) {
      map['origin_device_id'] = Variable<String>(originDeviceId.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (attendeeId.present) {
      map['attendee_id'] = Variable<String>(attendeeId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupMembersCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('groupId: $groupId, ')
          ..write('attendeeId: $attendeeId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LodgingsTable extends Lodgings
    with TableInfo<$LodgingsTable, LodgingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LodgingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _originDeviceIdMeta =
      const VerificationMeta('originDeviceId');
  @override
  late final GeneratedColumn<String> originDeviceId = GeneratedColumn<String>(
      'origin_device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _eventIdMeta =
      const VerificationMeta('eventId');
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
      'event_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES events (id)'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contactPhoneMeta =
      const VerificationMeta('contactPhone');
  @override
  late final GeneratedColumn<String> contactPhone = GeneratedColumn<String>(
      'contact_phone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _directionsMeta =
      const VerificationMeta('directions');
  @override
  late final GeneratedColumn<String> directions = GeneratedColumn<String>(
      'directions', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _capacityMeta =
      const VerificationMeta('capacity');
  @override
  late final GeneratedColumn<int> capacity = GeneratedColumn<int>(
      'capacity', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _acceptsMeta =
      const VerificationMeta('accepts');
  @override
  late final GeneratedColumn<String> accepts = GeneratedColumn<String>(
      'accepts', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _hostNameMeta =
      const VerificationMeta('hostName');
  @override
  late final GeneratedColumn<String> hostName = GeneratedColumn<String>(
      'host_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _distanceNoteMeta =
      const VerificationMeta('distanceNote');
  @override
  late final GeneratedColumn<String> distanceNote = GeneratedColumn<String>(
      'distance_note', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        createdAt,
        updatedAt,
        deletedAt,
        originDeviceId,
        eventId,
        name,
        kind,
        contactPhone,
        directions,
        capacity,
        accepts,
        hostName,
        distanceNote
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lodgings';
  @override
  VerificationContext validateIntegrity(Insertable<LodgingRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('origin_device_id')) {
      context.handle(
          _originDeviceIdMeta,
          originDeviceId.isAcceptableOrUnknown(
              data['origin_device_id']!, _originDeviceIdMeta));
    } else if (isInserting) {
      context.missing(_originDeviceIdMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(_eventIdMeta,
          eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta));
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('contact_phone')) {
      context.handle(
          _contactPhoneMeta,
          contactPhone.isAcceptableOrUnknown(
              data['contact_phone']!, _contactPhoneMeta));
    }
    if (data.containsKey('directions')) {
      context.handle(
          _directionsMeta,
          directions.isAcceptableOrUnknown(
              data['directions']!, _directionsMeta));
    }
    if (data.containsKey('capacity')) {
      context.handle(_capacityMeta,
          capacity.isAcceptableOrUnknown(data['capacity']!, _capacityMeta));
    } else if (isInserting) {
      context.missing(_capacityMeta);
    }
    if (data.containsKey('accepts')) {
      context.handle(_acceptsMeta,
          accepts.isAcceptableOrUnknown(data['accepts']!, _acceptsMeta));
    } else if (isInserting) {
      context.missing(_acceptsMeta);
    }
    if (data.containsKey('host_name')) {
      context.handle(_hostNameMeta,
          hostName.isAcceptableOrUnknown(data['host_name']!, _hostNameMeta));
    }
    if (data.containsKey('distance_note')) {
      context.handle(
          _distanceNoteMeta,
          distanceNote.isAcceptableOrUnknown(
              data['distance_note']!, _distanceNoteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LodgingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LodgingRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      originDeviceId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}origin_device_id'])!,
      eventId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      contactPhone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}contact_phone']),
      directions: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}directions'])!,
      capacity: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}capacity'])!,
      accepts: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}accepts'])!,
      hostName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}host_name']),
      distanceNote: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}distance_note'])!,
    );
  }

  @override
  $LodgingsTable createAlias(String alias) {
    return $LodgingsTable(attachedDatabase, alias);
  }
}

class LodgingRow extends DataClass implements Insertable<LodgingRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String originDeviceId;
  final String eventId;
  final String name;
  final String kind;
  final String? contactPhone;
  final String directions;
  final int capacity;
  final String accepts;
  final String? hostName;
  final String distanceNote;
  const LodgingRow(
      {required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.originDeviceId,
      required this.eventId,
      required this.name,
      required this.kind,
      this.contactPhone,
      required this.directions,
      required this.capacity,
      required this.accepts,
      this.hostName,
      required this.distanceNote});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['origin_device_id'] = Variable<String>(originDeviceId);
    map['event_id'] = Variable<String>(eventId);
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || contactPhone != null) {
      map['contact_phone'] = Variable<String>(contactPhone);
    }
    map['directions'] = Variable<String>(directions);
    map['capacity'] = Variable<int>(capacity);
    map['accepts'] = Variable<String>(accepts);
    if (!nullToAbsent || hostName != null) {
      map['host_name'] = Variable<String>(hostName);
    }
    map['distance_note'] = Variable<String>(distanceNote);
    return map;
  }

  LodgingsCompanion toCompanion(bool nullToAbsent) {
    return LodgingsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      originDeviceId: Value(originDeviceId),
      eventId: Value(eventId),
      name: Value(name),
      kind: Value(kind),
      contactPhone: contactPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(contactPhone),
      directions: Value(directions),
      capacity: Value(capacity),
      accepts: Value(accepts),
      hostName: hostName == null && nullToAbsent
          ? const Value.absent()
          : Value(hostName),
      distanceNote: Value(distanceNote),
    );
  }

  factory LodgingRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LodgingRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      originDeviceId: serializer.fromJson<String>(json['originDeviceId']),
      eventId: serializer.fromJson<String>(json['eventId']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
      contactPhone: serializer.fromJson<String?>(json['contactPhone']),
      directions: serializer.fromJson<String>(json['directions']),
      capacity: serializer.fromJson<int>(json['capacity']),
      accepts: serializer.fromJson<String>(json['accepts']),
      hostName: serializer.fromJson<String?>(json['hostName']),
      distanceNote: serializer.fromJson<String>(json['distanceNote']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'originDeviceId': serializer.toJson<String>(originDeviceId),
      'eventId': serializer.toJson<String>(eventId),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(kind),
      'contactPhone': serializer.toJson<String?>(contactPhone),
      'directions': serializer.toJson<String>(directions),
      'capacity': serializer.toJson<int>(capacity),
      'accepts': serializer.toJson<String>(accepts),
      'hostName': serializer.toJson<String?>(hostName),
      'distanceNote': serializer.toJson<String>(distanceNote),
    };
  }

  LodgingRow copyWith(
          {String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          String? originDeviceId,
          String? eventId,
          String? name,
          String? kind,
          Value<String?> contactPhone = const Value.absent(),
          String? directions,
          int? capacity,
          String? accepts,
          Value<String?> hostName = const Value.absent(),
          String? distanceNote}) =>
      LodgingRow(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        originDeviceId: originDeviceId ?? this.originDeviceId,
        eventId: eventId ?? this.eventId,
        name: name ?? this.name,
        kind: kind ?? this.kind,
        contactPhone:
            contactPhone.present ? contactPhone.value : this.contactPhone,
        directions: directions ?? this.directions,
        capacity: capacity ?? this.capacity,
        accepts: accepts ?? this.accepts,
        hostName: hostName.present ? hostName.value : this.hostName,
        distanceNote: distanceNote ?? this.distanceNote,
      );
  LodgingRow copyWithCompanion(LodgingsCompanion data) {
    return LodgingRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      originDeviceId: data.originDeviceId.present
          ? data.originDeviceId.value
          : this.originDeviceId,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      contactPhone: data.contactPhone.present
          ? data.contactPhone.value
          : this.contactPhone,
      directions:
          data.directions.present ? data.directions.value : this.directions,
      capacity: data.capacity.present ? data.capacity.value : this.capacity,
      accepts: data.accepts.present ? data.accepts.value : this.accepts,
      hostName: data.hostName.present ? data.hostName.value : this.hostName,
      distanceNote: data.distanceNote.present
          ? data.distanceNote.value
          : this.distanceNote,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LodgingRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('eventId: $eventId, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('contactPhone: $contactPhone, ')
          ..write('directions: $directions, ')
          ..write('capacity: $capacity, ')
          ..write('accepts: $accepts, ')
          ..write('hostName: $hostName, ')
          ..write('distanceNote: $distanceNote')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      createdAt,
      updatedAt,
      deletedAt,
      originDeviceId,
      eventId,
      name,
      kind,
      contactPhone,
      directions,
      capacity,
      accepts,
      hostName,
      distanceNote);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LodgingRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.originDeviceId == this.originDeviceId &&
          other.eventId == this.eventId &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.contactPhone == this.contactPhone &&
          other.directions == this.directions &&
          other.capacity == this.capacity &&
          other.accepts == this.accepts &&
          other.hostName == this.hostName &&
          other.distanceNote == this.distanceNote);
}

class LodgingsCompanion extends UpdateCompanion<LodgingRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> originDeviceId;
  final Value<String> eventId;
  final Value<String> name;
  final Value<String> kind;
  final Value<String?> contactPhone;
  final Value<String> directions;
  final Value<int> capacity;
  final Value<String> accepts;
  final Value<String?> hostName;
  final Value<String> distanceNote;
  final Value<int> rowid;
  const LodgingsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.originDeviceId = const Value.absent(),
    this.eventId = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.contactPhone = const Value.absent(),
    this.directions = const Value.absent(),
    this.capacity = const Value.absent(),
    this.accepts = const Value.absent(),
    this.hostName = const Value.absent(),
    this.distanceNote = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LodgingsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String originDeviceId,
    required String eventId,
    required String name,
    required String kind,
    this.contactPhone = const Value.absent(),
    this.directions = const Value.absent(),
    required int capacity,
    required String accepts,
    this.hostName = const Value.absent(),
    this.distanceNote = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        originDeviceId = Value(originDeviceId),
        eventId = Value(eventId),
        name = Value(name),
        kind = Value(kind),
        capacity = Value(capacity),
        accepts = Value(accepts);
  static Insertable<LodgingRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? originDeviceId,
    Expression<String>? eventId,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<String>? contactPhone,
    Expression<String>? directions,
    Expression<int>? capacity,
    Expression<String>? accepts,
    Expression<String>? hostName,
    Expression<String>? distanceNote,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (originDeviceId != null) 'origin_device_id': originDeviceId,
      if (eventId != null) 'event_id': eventId,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (contactPhone != null) 'contact_phone': contactPhone,
      if (directions != null) 'directions': directions,
      if (capacity != null) 'capacity': capacity,
      if (accepts != null) 'accepts': accepts,
      if (hostName != null) 'host_name': hostName,
      if (distanceNote != null) 'distance_note': distanceNote,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LodgingsCompanion copyWith(
      {Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? originDeviceId,
      Value<String>? eventId,
      Value<String>? name,
      Value<String>? kind,
      Value<String?>? contactPhone,
      Value<String>? directions,
      Value<int>? capacity,
      Value<String>? accepts,
      Value<String?>? hostName,
      Value<String>? distanceNote,
      Value<int>? rowid}) {
    return LodgingsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      eventId: eventId ?? this.eventId,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      contactPhone: contactPhone ?? this.contactPhone,
      directions: directions ?? this.directions,
      capacity: capacity ?? this.capacity,
      accepts: accepts ?? this.accepts,
      hostName: hostName ?? this.hostName,
      distanceNote: distanceNote ?? this.distanceNote,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
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
    if (originDeviceId.present) {
      map['origin_device_id'] = Variable<String>(originDeviceId.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (contactPhone.present) {
      map['contact_phone'] = Variable<String>(contactPhone.value);
    }
    if (directions.present) {
      map['directions'] = Variable<String>(directions.value);
    }
    if (capacity.present) {
      map['capacity'] = Variable<int>(capacity.value);
    }
    if (accepts.present) {
      map['accepts'] = Variable<String>(accepts.value);
    }
    if (hostName.present) {
      map['host_name'] = Variable<String>(hostName.value);
    }
    if (distanceNote.present) {
      map['distance_note'] = Variable<String>(distanceNote.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LodgingsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('eventId: $eventId, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('contactPhone: $contactPhone, ')
          ..write('directions: $directions, ')
          ..write('capacity: $capacity, ')
          ..write('accepts: $accepts, ')
          ..write('hostName: $hostName, ')
          ..write('distanceNote: $distanceNote, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TeamsTable extends Teams with TableInfo<$TeamsTable, TeamRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TeamsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _originDeviceIdMeta =
      const VerificationMeta('originDeviceId');
  @override
  late final GeneratedColumn<String> originDeviceId = GeneratedColumn<String>(
      'origin_device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _eventIdMeta =
      const VerificationMeta('eventId');
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
      'event_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES events (id)'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
      'color', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _captainIdMeta =
      const VerificationMeta('captainId');
  @override
  late final GeneratedColumn<String> captainId = GeneratedColumn<String>(
      'captain_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        createdAt,
        updatedAt,
        deletedAt,
        originDeviceId,
        eventId,
        name,
        color,
        captainId,
        sortOrder
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'teams';
  @override
  VerificationContext validateIntegrity(Insertable<TeamRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('origin_device_id')) {
      context.handle(
          _originDeviceIdMeta,
          originDeviceId.isAcceptableOrUnknown(
              data['origin_device_id']!, _originDeviceIdMeta));
    } else if (isInserting) {
      context.missing(_originDeviceIdMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(_eventIdMeta,
          eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta));
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    if (data.containsKey('captain_id')) {
      context.handle(_captainIdMeta,
          captainId.isAcceptableOrUnknown(data['captain_id']!, _captainIdMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TeamRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TeamRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      originDeviceId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}origin_device_id'])!,
      eventId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color']),
      captainId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}captain_id']),
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $TeamsTable createAlias(String alias) {
    return $TeamsTable(attachedDatabase, alias);
  }
}

class TeamRow extends DataClass implements Insertable<TeamRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String originDeviceId;
  final String eventId;
  final String name;
  final String? color;
  final String? captainId;
  final int sortOrder;
  const TeamRow(
      {required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.originDeviceId,
      required this.eventId,
      required this.name,
      this.color,
      this.captainId,
      required this.sortOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['origin_device_id'] = Variable<String>(originDeviceId);
    map['event_id'] = Variable<String>(eventId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    if (!nullToAbsent || captainId != null) {
      map['captain_id'] = Variable<String>(captainId);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  TeamsCompanion toCompanion(bool nullToAbsent) {
    return TeamsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      originDeviceId: Value(originDeviceId),
      eventId: Value(eventId),
      name: Value(name),
      color:
          color == null && nullToAbsent ? const Value.absent() : Value(color),
      captainId: captainId == null && nullToAbsent
          ? const Value.absent()
          : Value(captainId),
      sortOrder: Value(sortOrder),
    );
  }

  factory TeamRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TeamRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      originDeviceId: serializer.fromJson<String>(json['originDeviceId']),
      eventId: serializer.fromJson<String>(json['eventId']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<String?>(json['color']),
      captainId: serializer.fromJson<String?>(json['captainId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'originDeviceId': serializer.toJson<String>(originDeviceId),
      'eventId': serializer.toJson<String>(eventId),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<String?>(color),
      'captainId': serializer.toJson<String?>(captainId),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  TeamRow copyWith(
          {String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          String? originDeviceId,
          String? eventId,
          String? name,
          Value<String?> color = const Value.absent(),
          Value<String?> captainId = const Value.absent(),
          int? sortOrder}) =>
      TeamRow(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        originDeviceId: originDeviceId ?? this.originDeviceId,
        eventId: eventId ?? this.eventId,
        name: name ?? this.name,
        color: color.present ? color.value : this.color,
        captainId: captainId.present ? captainId.value : this.captainId,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  TeamRow copyWithCompanion(TeamsCompanion data) {
    return TeamRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      originDeviceId: data.originDeviceId.present
          ? data.originDeviceId.value
          : this.originDeviceId,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      captainId: data.captainId.present ? data.captainId.value : this.captainId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TeamRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('eventId: $eventId, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('captainId: $captainId, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, createdAt, updatedAt, deletedAt,
      originDeviceId, eventId, name, color, captainId, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TeamRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.originDeviceId == this.originDeviceId &&
          other.eventId == this.eventId &&
          other.name == this.name &&
          other.color == this.color &&
          other.captainId == this.captainId &&
          other.sortOrder == this.sortOrder);
}

class TeamsCompanion extends UpdateCompanion<TeamRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> originDeviceId;
  final Value<String> eventId;
  final Value<String> name;
  final Value<String?> color;
  final Value<String?> captainId;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const TeamsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.originDeviceId = const Value.absent(),
    this.eventId = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.captainId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TeamsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String originDeviceId,
    required String eventId,
    required String name,
    this.color = const Value.absent(),
    this.captainId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        originDeviceId = Value(originDeviceId),
        eventId = Value(eventId),
        name = Value(name);
  static Insertable<TeamRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? originDeviceId,
    Expression<String>? eventId,
    Expression<String>? name,
    Expression<String>? color,
    Expression<String>? captainId,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (originDeviceId != null) 'origin_device_id': originDeviceId,
      if (eventId != null) 'event_id': eventId,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (captainId != null) 'captain_id': captainId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TeamsCompanion copyWith(
      {Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? originDeviceId,
      Value<String>? eventId,
      Value<String>? name,
      Value<String?>? color,
      Value<String?>? captainId,
      Value<int>? sortOrder,
      Value<int>? rowid}) {
    return TeamsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      eventId: eventId ?? this.eventId,
      name: name ?? this.name,
      color: color ?? this.color,
      captainId: captainId ?? this.captainId,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
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
    if (originDeviceId.present) {
      map['origin_device_id'] = Variable<String>(originDeviceId.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (captainId.present) {
      map['captain_id'] = Variable<String>(captainId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
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
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('eventId: $eventId, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('captainId: $captainId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ControlTypesTable extends ControlTypes
    with TableInfo<$ControlTypesTable, ControlType> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ControlTypesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _originDeviceIdMeta =
      const VerificationMeta('originDeviceId');
  @override
  late final GeneratedColumn<String> originDeviceId = GeneratedColumn<String>(
      'origin_device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _eventIdMeta =
      const VerificationMeta('eventId');
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
      'event_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES events (id)'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        createdAt,
        updatedAt,
        deletedAt,
        originDeviceId,
        eventId,
        name,
        sortOrder
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'control_types';
  @override
  VerificationContext validateIntegrity(Insertable<ControlType> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('origin_device_id')) {
      context.handle(
          _originDeviceIdMeta,
          originDeviceId.isAcceptableOrUnknown(
              data['origin_device_id']!, _originDeviceIdMeta));
    } else if (isInserting) {
      context.missing(_originDeviceIdMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(_eventIdMeta,
          eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta));
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ControlType map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ControlType(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      originDeviceId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}origin_device_id'])!,
      eventId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $ControlTypesTable createAlias(String alias) {
    return $ControlTypesTable(attachedDatabase, alias);
  }
}

class ControlType extends DataClass implements Insertable<ControlType> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String originDeviceId;
  final String eventId;
  final String name;
  final int sortOrder;
  const ControlType(
      {required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.originDeviceId,
      required this.eventId,
      required this.name,
      required this.sortOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['origin_device_id'] = Variable<String>(originDeviceId);
    map['event_id'] = Variable<String>(eventId);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  ControlTypesCompanion toCompanion(bool nullToAbsent) {
    return ControlTypesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      originDeviceId: Value(originDeviceId),
      eventId: Value(eventId),
      name: Value(name),
      sortOrder: Value(sortOrder),
    );
  }

  factory ControlType.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ControlType(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      originDeviceId: serializer.fromJson<String>(json['originDeviceId']),
      eventId: serializer.fromJson<String>(json['eventId']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'originDeviceId': serializer.toJson<String>(originDeviceId),
      'eventId': serializer.toJson<String>(eventId),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  ControlType copyWith(
          {String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          String? originDeviceId,
          String? eventId,
          String? name,
          int? sortOrder}) =>
      ControlType(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        originDeviceId: originDeviceId ?? this.originDeviceId,
        eventId: eventId ?? this.eventId,
        name: name ?? this.name,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  ControlType copyWithCompanion(ControlTypesCompanion data) {
    return ControlType(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      originDeviceId: data.originDeviceId.present
          ? data.originDeviceId.value
          : this.originDeviceId,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ControlType(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('eventId: $eventId, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, createdAt, updatedAt, deletedAt,
      originDeviceId, eventId, name, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ControlType &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.originDeviceId == this.originDeviceId &&
          other.eventId == this.eventId &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder);
}

class ControlTypesCompanion extends UpdateCompanion<ControlType> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> originDeviceId;
  final Value<String> eventId;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const ControlTypesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.originDeviceId = const Value.absent(),
    this.eventId = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ControlTypesCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String originDeviceId,
    required String eventId,
    required String name,
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        originDeviceId = Value(originDeviceId),
        eventId = Value(eventId),
        name = Value(name);
  static Insertable<ControlType> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? originDeviceId,
    Expression<String>? eventId,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (originDeviceId != null) 'origin_device_id': originDeviceId,
      if (eventId != null) 'event_id': eventId,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ControlTypesCompanion copyWith(
      {Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? originDeviceId,
      Value<String>? eventId,
      Value<String>? name,
      Value<int>? sortOrder,
      Value<int>? rowid}) {
    return ControlTypesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      eventId: eventId ?? this.eventId,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
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
    if (originDeviceId.present) {
      map['origin_device_id'] = Variable<String>(originDeviceId.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ControlTypesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('eventId: $eventId, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ControlSessionsTable extends ControlSessions
    with TableInfo<$ControlSessionsTable, ControlSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ControlSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _originDeviceIdMeta =
      const VerificationMeta('originDeviceId');
  @override
  late final GeneratedColumn<String> originDeviceId = GeneratedColumn<String>(
      'origin_device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _eventIdMeta =
      const VerificationMeta('eventId');
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
      'event_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES events (id)'));
  static const VerificationMeta _controlTypeIdMeta =
      const VerificationMeta('controlTypeId');
  @override
  late final GeneratedColumn<String> controlTypeId = GeneratedColumn<String>(
      'control_type_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES control_types (id)'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _scheduledAtMeta =
      const VerificationMeta('scheduledAt');
  @override
  late final GeneratedColumn<DateTime> scheduledAt = GeneratedColumn<DateTime>(
      'scheduled_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _openedAtMeta =
      const VerificationMeta('openedAt');
  @override
  late final GeneratedColumn<DateTime> openedAt = GeneratedColumn<DateTime>(
      'opened_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _closedAtMeta =
      const VerificationMeta('closedAt');
  @override
  late final GeneratedColumn<DateTime> closedAt = GeneratedColumn<DateTime>(
      'closed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _operatorNameMeta =
      const VerificationMeta('operatorName');
  @override
  late final GeneratedColumn<String> operatorName = GeneratedColumn<String>(
      'operator_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _blockedRepeatsMeta =
      const VerificationMeta('blockedRepeats');
  @override
  late final GeneratedColumn<int> blockedRepeats = GeneratedColumn<int>(
      'blocked_repeats', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        createdAt,
        updatedAt,
        deletedAt,
        originDeviceId,
        eventId,
        controlTypeId,
        name,
        scheduledAt,
        openedAt,
        closedAt,
        operatorName,
        blockedRepeats
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'control_sessions';
  @override
  VerificationContext validateIntegrity(Insertable<ControlSession> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('origin_device_id')) {
      context.handle(
          _originDeviceIdMeta,
          originDeviceId.isAcceptableOrUnknown(
              data['origin_device_id']!, _originDeviceIdMeta));
    } else if (isInserting) {
      context.missing(_originDeviceIdMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(_eventIdMeta,
          eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta));
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('control_type_id')) {
      context.handle(
          _controlTypeIdMeta,
          controlTypeId.isAcceptableOrUnknown(
              data['control_type_id']!, _controlTypeIdMeta));
    } else if (isInserting) {
      context.missing(_controlTypeIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('scheduled_at')) {
      context.handle(
          _scheduledAtMeta,
          scheduledAt.isAcceptableOrUnknown(
              data['scheduled_at']!, _scheduledAtMeta));
    }
    if (data.containsKey('opened_at')) {
      context.handle(_openedAtMeta,
          openedAt.isAcceptableOrUnknown(data['opened_at']!, _openedAtMeta));
    }
    if (data.containsKey('closed_at')) {
      context.handle(_closedAtMeta,
          closedAt.isAcceptableOrUnknown(data['closed_at']!, _closedAtMeta));
    }
    if (data.containsKey('operator_name')) {
      context.handle(
          _operatorNameMeta,
          operatorName.isAcceptableOrUnknown(
              data['operator_name']!, _operatorNameMeta));
    }
    if (data.containsKey('blocked_repeats')) {
      context.handle(
          _blockedRepeatsMeta,
          blockedRepeats.isAcceptableOrUnknown(
              data['blocked_repeats']!, _blockedRepeatsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ControlSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ControlSession(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      originDeviceId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}origin_device_id'])!,
      eventId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_id'])!,
      controlTypeId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}control_type_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      scheduledAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}scheduled_at']),
      openedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}opened_at']),
      closedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}closed_at']),
      operatorName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operator_name'])!,
      blockedRepeats: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}blocked_repeats'])!,
    );
  }

  @override
  $ControlSessionsTable createAlias(String alias) {
    return $ControlSessionsTable(attachedDatabase, alias);
  }
}

class ControlSession extends DataClass implements Insertable<ControlSession> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String originDeviceId;
  final String eventId;
  final String controlTypeId;
  final String name;
  final DateTime? scheduledAt;
  final DateTime? openedAt;
  final DateTime? closedAt;
  final String operatorName;

  /// Veces que se avisó «ya pasó» y no se marcó de nuevo (para el resumen de cierre).
  final int blockedRepeats;
  const ControlSession(
      {required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.originDeviceId,
      required this.eventId,
      required this.controlTypeId,
      required this.name,
      this.scheduledAt,
      this.openedAt,
      this.closedAt,
      required this.operatorName,
      required this.blockedRepeats});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['origin_device_id'] = Variable<String>(originDeviceId);
    map['event_id'] = Variable<String>(eventId);
    map['control_type_id'] = Variable<String>(controlTypeId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || scheduledAt != null) {
      map['scheduled_at'] = Variable<DateTime>(scheduledAt);
    }
    if (!nullToAbsent || openedAt != null) {
      map['opened_at'] = Variable<DateTime>(openedAt);
    }
    if (!nullToAbsent || closedAt != null) {
      map['closed_at'] = Variable<DateTime>(closedAt);
    }
    map['operator_name'] = Variable<String>(operatorName);
    map['blocked_repeats'] = Variable<int>(blockedRepeats);
    return map;
  }

  ControlSessionsCompanion toCompanion(bool nullToAbsent) {
    return ControlSessionsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      originDeviceId: Value(originDeviceId),
      eventId: Value(eventId),
      controlTypeId: Value(controlTypeId),
      name: Value(name),
      scheduledAt: scheduledAt == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduledAt),
      openedAt: openedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(openedAt),
      closedAt: closedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(closedAt),
      operatorName: Value(operatorName),
      blockedRepeats: Value(blockedRepeats),
    );
  }

  factory ControlSession.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ControlSession(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      originDeviceId: serializer.fromJson<String>(json['originDeviceId']),
      eventId: serializer.fromJson<String>(json['eventId']),
      controlTypeId: serializer.fromJson<String>(json['controlTypeId']),
      name: serializer.fromJson<String>(json['name']),
      scheduledAt: serializer.fromJson<DateTime?>(json['scheduledAt']),
      openedAt: serializer.fromJson<DateTime?>(json['openedAt']),
      closedAt: serializer.fromJson<DateTime?>(json['closedAt']),
      operatorName: serializer.fromJson<String>(json['operatorName']),
      blockedRepeats: serializer.fromJson<int>(json['blockedRepeats']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'originDeviceId': serializer.toJson<String>(originDeviceId),
      'eventId': serializer.toJson<String>(eventId),
      'controlTypeId': serializer.toJson<String>(controlTypeId),
      'name': serializer.toJson<String>(name),
      'scheduledAt': serializer.toJson<DateTime?>(scheduledAt),
      'openedAt': serializer.toJson<DateTime?>(openedAt),
      'closedAt': serializer.toJson<DateTime?>(closedAt),
      'operatorName': serializer.toJson<String>(operatorName),
      'blockedRepeats': serializer.toJson<int>(blockedRepeats),
    };
  }

  ControlSession copyWith(
          {String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          String? originDeviceId,
          String? eventId,
          String? controlTypeId,
          String? name,
          Value<DateTime?> scheduledAt = const Value.absent(),
          Value<DateTime?> openedAt = const Value.absent(),
          Value<DateTime?> closedAt = const Value.absent(),
          String? operatorName,
          int? blockedRepeats}) =>
      ControlSession(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        originDeviceId: originDeviceId ?? this.originDeviceId,
        eventId: eventId ?? this.eventId,
        controlTypeId: controlTypeId ?? this.controlTypeId,
        name: name ?? this.name,
        scheduledAt: scheduledAt.present ? scheduledAt.value : this.scheduledAt,
        openedAt: openedAt.present ? openedAt.value : this.openedAt,
        closedAt: closedAt.present ? closedAt.value : this.closedAt,
        operatorName: operatorName ?? this.operatorName,
        blockedRepeats: blockedRepeats ?? this.blockedRepeats,
      );
  ControlSession copyWithCompanion(ControlSessionsCompanion data) {
    return ControlSession(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      originDeviceId: data.originDeviceId.present
          ? data.originDeviceId.value
          : this.originDeviceId,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      controlTypeId: data.controlTypeId.present
          ? data.controlTypeId.value
          : this.controlTypeId,
      name: data.name.present ? data.name.value : this.name,
      scheduledAt:
          data.scheduledAt.present ? data.scheduledAt.value : this.scheduledAt,
      openedAt: data.openedAt.present ? data.openedAt.value : this.openedAt,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
      operatorName: data.operatorName.present
          ? data.operatorName.value
          : this.operatorName,
      blockedRepeats: data.blockedRepeats.present
          ? data.blockedRepeats.value
          : this.blockedRepeats,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ControlSession(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('eventId: $eventId, ')
          ..write('controlTypeId: $controlTypeId, ')
          ..write('name: $name, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('openedAt: $openedAt, ')
          ..write('closedAt: $closedAt, ')
          ..write('operatorName: $operatorName, ')
          ..write('blockedRepeats: $blockedRepeats')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      createdAt,
      updatedAt,
      deletedAt,
      originDeviceId,
      eventId,
      controlTypeId,
      name,
      scheduledAt,
      openedAt,
      closedAt,
      operatorName,
      blockedRepeats);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ControlSession &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.originDeviceId == this.originDeviceId &&
          other.eventId == this.eventId &&
          other.controlTypeId == this.controlTypeId &&
          other.name == this.name &&
          other.scheduledAt == this.scheduledAt &&
          other.openedAt == this.openedAt &&
          other.closedAt == this.closedAt &&
          other.operatorName == this.operatorName &&
          other.blockedRepeats == this.blockedRepeats);
}

class ControlSessionsCompanion extends UpdateCompanion<ControlSession> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> originDeviceId;
  final Value<String> eventId;
  final Value<String> controlTypeId;
  final Value<String> name;
  final Value<DateTime?> scheduledAt;
  final Value<DateTime?> openedAt;
  final Value<DateTime?> closedAt;
  final Value<String> operatorName;
  final Value<int> blockedRepeats;
  final Value<int> rowid;
  const ControlSessionsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.originDeviceId = const Value.absent(),
    this.eventId = const Value.absent(),
    this.controlTypeId = const Value.absent(),
    this.name = const Value.absent(),
    this.scheduledAt = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.operatorName = const Value.absent(),
    this.blockedRepeats = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ControlSessionsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String originDeviceId,
    required String eventId,
    required String controlTypeId,
    required String name,
    this.scheduledAt = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.operatorName = const Value.absent(),
    this.blockedRepeats = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        originDeviceId = Value(originDeviceId),
        eventId = Value(eventId),
        controlTypeId = Value(controlTypeId),
        name = Value(name);
  static Insertable<ControlSession> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? originDeviceId,
    Expression<String>? eventId,
    Expression<String>? controlTypeId,
    Expression<String>? name,
    Expression<DateTime>? scheduledAt,
    Expression<DateTime>? openedAt,
    Expression<DateTime>? closedAt,
    Expression<String>? operatorName,
    Expression<int>? blockedRepeats,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (originDeviceId != null) 'origin_device_id': originDeviceId,
      if (eventId != null) 'event_id': eventId,
      if (controlTypeId != null) 'control_type_id': controlTypeId,
      if (name != null) 'name': name,
      if (scheduledAt != null) 'scheduled_at': scheduledAt,
      if (openedAt != null) 'opened_at': openedAt,
      if (closedAt != null) 'closed_at': closedAt,
      if (operatorName != null) 'operator_name': operatorName,
      if (blockedRepeats != null) 'blocked_repeats': blockedRepeats,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ControlSessionsCompanion copyWith(
      {Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? originDeviceId,
      Value<String>? eventId,
      Value<String>? controlTypeId,
      Value<String>? name,
      Value<DateTime?>? scheduledAt,
      Value<DateTime?>? openedAt,
      Value<DateTime?>? closedAt,
      Value<String>? operatorName,
      Value<int>? blockedRepeats,
      Value<int>? rowid}) {
    return ControlSessionsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      eventId: eventId ?? this.eventId,
      controlTypeId: controlTypeId ?? this.controlTypeId,
      name: name ?? this.name,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      openedAt: openedAt ?? this.openedAt,
      closedAt: closedAt ?? this.closedAt,
      operatorName: operatorName ?? this.operatorName,
      blockedRepeats: blockedRepeats ?? this.blockedRepeats,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
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
    if (originDeviceId.present) {
      map['origin_device_id'] = Variable<String>(originDeviceId.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (controlTypeId.present) {
      map['control_type_id'] = Variable<String>(controlTypeId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (scheduledAt.present) {
      map['scheduled_at'] = Variable<DateTime>(scheduledAt.value);
    }
    if (openedAt.present) {
      map['opened_at'] = Variable<DateTime>(openedAt.value);
    }
    if (closedAt.present) {
      map['closed_at'] = Variable<DateTime>(closedAt.value);
    }
    if (operatorName.present) {
      map['operator_name'] = Variable<String>(operatorName.value);
    }
    if (blockedRepeats.present) {
      map['blocked_repeats'] = Variable<int>(blockedRepeats.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ControlSessionsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('eventId: $eventId, ')
          ..write('controlTypeId: $controlTypeId, ')
          ..write('name: $name, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('openedAt: $openedAt, ')
          ..write('closedAt: $closedAt, ')
          ..write('operatorName: $operatorName, ')
          ..write('blockedRepeats: $blockedRepeats, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ControlRecordsTable extends ControlRecords
    with TableInfo<$ControlRecordsTable, ControlRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ControlRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _originDeviceIdMeta =
      const VerificationMeta('originDeviceId');
  @override
  late final GeneratedColumn<String> originDeviceId = GeneratedColumn<String>(
      'origin_device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES control_sessions (id)'));
  static const VerificationMeta _attendeeIdMeta =
      const VerificationMeta('attendeeId');
  @override
  late final GeneratedColumn<String> attendeeId = GeneratedColumn<String>(
      'attendee_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES attendees (id)'));
  static const VerificationMeta _markedAtMeta =
      const VerificationMeta('markedAt');
  @override
  late final GeneratedColumn<DateTime> markedAt = GeneratedColumn<DateTime>(
      'marked_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _operatorNameMeta =
      const VerificationMeta('operatorName');
  @override
  late final GeneratedColumn<String> operatorName = GeneratedColumn<String>(
      'operator_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _undoneAtMeta =
      const VerificationMeta('undoneAt');
  @override
  late final GeneratedColumn<DateTime> undoneAt = GeneratedColumn<DateTime>(
      'undone_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _repeatOverrideMeta =
      const VerificationMeta('repeatOverride');
  @override
  late final GeneratedColumn<bool> repeatOverride = GeneratedColumn<bool>(
      'repeat_override', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("repeat_override" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        createdAt,
        updatedAt,
        deletedAt,
        originDeviceId,
        sessionId,
        attendeeId,
        markedAt,
        operatorName,
        undoneAt,
        repeatOverride
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'control_records';
  @override
  VerificationContext validateIntegrity(Insertable<ControlRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('origin_device_id')) {
      context.handle(
          _originDeviceIdMeta,
          originDeviceId.isAcceptableOrUnknown(
              data['origin_device_id']!, _originDeviceIdMeta));
    } else if (isInserting) {
      context.missing(_originDeviceIdMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('attendee_id')) {
      context.handle(
          _attendeeIdMeta,
          attendeeId.isAcceptableOrUnknown(
              data['attendee_id']!, _attendeeIdMeta));
    } else if (isInserting) {
      context.missing(_attendeeIdMeta);
    }
    if (data.containsKey('marked_at')) {
      context.handle(_markedAtMeta,
          markedAt.isAcceptableOrUnknown(data['marked_at']!, _markedAtMeta));
    } else if (isInserting) {
      context.missing(_markedAtMeta);
    }
    if (data.containsKey('operator_name')) {
      context.handle(
          _operatorNameMeta,
          operatorName.isAcceptableOrUnknown(
              data['operator_name']!, _operatorNameMeta));
    }
    if (data.containsKey('undone_at')) {
      context.handle(_undoneAtMeta,
          undoneAt.isAcceptableOrUnknown(data['undone_at']!, _undoneAtMeta));
    }
    if (data.containsKey('repeat_override')) {
      context.handle(
          _repeatOverrideMeta,
          repeatOverride.isAcceptableOrUnknown(
              data['repeat_override']!, _repeatOverrideMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ControlRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ControlRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      originDeviceId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}origin_device_id'])!,
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id'])!,
      attendeeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}attendee_id'])!,
      markedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}marked_at'])!,
      operatorName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operator_name'])!,
      undoneAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}undone_at']),
      repeatOverride: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}repeat_override'])!,
    );
  }

  @override
  $ControlRecordsTable createAlias(String alias) {
    return $ControlRecordsTable(attachedDatabase, alias);
  }
}

class ControlRecord extends DataClass implements Insertable<ControlRecord> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String originDeviceId;
  final String sessionId;
  final String attendeeId;
  final DateTime markedAt;
  final String operatorName;
  final DateTime? undoneAt;
  final bool repeatOverride;
  const ControlRecord(
      {required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.originDeviceId,
      required this.sessionId,
      required this.attendeeId,
      required this.markedAt,
      required this.operatorName,
      this.undoneAt,
      required this.repeatOverride});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['origin_device_id'] = Variable<String>(originDeviceId);
    map['session_id'] = Variable<String>(sessionId);
    map['attendee_id'] = Variable<String>(attendeeId);
    map['marked_at'] = Variable<DateTime>(markedAt);
    map['operator_name'] = Variable<String>(operatorName);
    if (!nullToAbsent || undoneAt != null) {
      map['undone_at'] = Variable<DateTime>(undoneAt);
    }
    map['repeat_override'] = Variable<bool>(repeatOverride);
    return map;
  }

  ControlRecordsCompanion toCompanion(bool nullToAbsent) {
    return ControlRecordsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      originDeviceId: Value(originDeviceId),
      sessionId: Value(sessionId),
      attendeeId: Value(attendeeId),
      markedAt: Value(markedAt),
      operatorName: Value(operatorName),
      undoneAt: undoneAt == null && nullToAbsent
          ? const Value.absent()
          : Value(undoneAt),
      repeatOverride: Value(repeatOverride),
    );
  }

  factory ControlRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ControlRecord(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      originDeviceId: serializer.fromJson<String>(json['originDeviceId']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      attendeeId: serializer.fromJson<String>(json['attendeeId']),
      markedAt: serializer.fromJson<DateTime>(json['markedAt']),
      operatorName: serializer.fromJson<String>(json['operatorName']),
      undoneAt: serializer.fromJson<DateTime?>(json['undoneAt']),
      repeatOverride: serializer.fromJson<bool>(json['repeatOverride']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'originDeviceId': serializer.toJson<String>(originDeviceId),
      'sessionId': serializer.toJson<String>(sessionId),
      'attendeeId': serializer.toJson<String>(attendeeId),
      'markedAt': serializer.toJson<DateTime>(markedAt),
      'operatorName': serializer.toJson<String>(operatorName),
      'undoneAt': serializer.toJson<DateTime?>(undoneAt),
      'repeatOverride': serializer.toJson<bool>(repeatOverride),
    };
  }

  ControlRecord copyWith(
          {String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          String? originDeviceId,
          String? sessionId,
          String? attendeeId,
          DateTime? markedAt,
          String? operatorName,
          Value<DateTime?> undoneAt = const Value.absent(),
          bool? repeatOverride}) =>
      ControlRecord(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        originDeviceId: originDeviceId ?? this.originDeviceId,
        sessionId: sessionId ?? this.sessionId,
        attendeeId: attendeeId ?? this.attendeeId,
        markedAt: markedAt ?? this.markedAt,
        operatorName: operatorName ?? this.operatorName,
        undoneAt: undoneAt.present ? undoneAt.value : this.undoneAt,
        repeatOverride: repeatOverride ?? this.repeatOverride,
      );
  ControlRecord copyWithCompanion(ControlRecordsCompanion data) {
    return ControlRecord(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      originDeviceId: data.originDeviceId.present
          ? data.originDeviceId.value
          : this.originDeviceId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      attendeeId:
          data.attendeeId.present ? data.attendeeId.value : this.attendeeId,
      markedAt: data.markedAt.present ? data.markedAt.value : this.markedAt,
      operatorName: data.operatorName.present
          ? data.operatorName.value
          : this.operatorName,
      undoneAt: data.undoneAt.present ? data.undoneAt.value : this.undoneAt,
      repeatOverride: data.repeatOverride.present
          ? data.repeatOverride.value
          : this.repeatOverride,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ControlRecord(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('sessionId: $sessionId, ')
          ..write('attendeeId: $attendeeId, ')
          ..write('markedAt: $markedAt, ')
          ..write('operatorName: $operatorName, ')
          ..write('undoneAt: $undoneAt, ')
          ..write('repeatOverride: $repeatOverride')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      createdAt,
      updatedAt,
      deletedAt,
      originDeviceId,
      sessionId,
      attendeeId,
      markedAt,
      operatorName,
      undoneAt,
      repeatOverride);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ControlRecord &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.originDeviceId == this.originDeviceId &&
          other.sessionId == this.sessionId &&
          other.attendeeId == this.attendeeId &&
          other.markedAt == this.markedAt &&
          other.operatorName == this.operatorName &&
          other.undoneAt == this.undoneAt &&
          other.repeatOverride == this.repeatOverride);
}

class ControlRecordsCompanion extends UpdateCompanion<ControlRecord> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> originDeviceId;
  final Value<String> sessionId;
  final Value<String> attendeeId;
  final Value<DateTime> markedAt;
  final Value<String> operatorName;
  final Value<DateTime?> undoneAt;
  final Value<bool> repeatOverride;
  final Value<int> rowid;
  const ControlRecordsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.originDeviceId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.attendeeId = const Value.absent(),
    this.markedAt = const Value.absent(),
    this.operatorName = const Value.absent(),
    this.undoneAt = const Value.absent(),
    this.repeatOverride = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ControlRecordsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String originDeviceId,
    required String sessionId,
    required String attendeeId,
    required DateTime markedAt,
    this.operatorName = const Value.absent(),
    this.undoneAt = const Value.absent(),
    this.repeatOverride = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        originDeviceId = Value(originDeviceId),
        sessionId = Value(sessionId),
        attendeeId = Value(attendeeId),
        markedAt = Value(markedAt);
  static Insertable<ControlRecord> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? originDeviceId,
    Expression<String>? sessionId,
    Expression<String>? attendeeId,
    Expression<DateTime>? markedAt,
    Expression<String>? operatorName,
    Expression<DateTime>? undoneAt,
    Expression<bool>? repeatOverride,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (originDeviceId != null) 'origin_device_id': originDeviceId,
      if (sessionId != null) 'session_id': sessionId,
      if (attendeeId != null) 'attendee_id': attendeeId,
      if (markedAt != null) 'marked_at': markedAt,
      if (operatorName != null) 'operator_name': operatorName,
      if (undoneAt != null) 'undone_at': undoneAt,
      if (repeatOverride != null) 'repeat_override': repeatOverride,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ControlRecordsCompanion copyWith(
      {Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? originDeviceId,
      Value<String>? sessionId,
      Value<String>? attendeeId,
      Value<DateTime>? markedAt,
      Value<String>? operatorName,
      Value<DateTime?>? undoneAt,
      Value<bool>? repeatOverride,
      Value<int>? rowid}) {
    return ControlRecordsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      sessionId: sessionId ?? this.sessionId,
      attendeeId: attendeeId ?? this.attendeeId,
      markedAt: markedAt ?? this.markedAt,
      operatorName: operatorName ?? this.operatorName,
      undoneAt: undoneAt ?? this.undoneAt,
      repeatOverride: repeatOverride ?? this.repeatOverride,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
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
    if (originDeviceId.present) {
      map['origin_device_id'] = Variable<String>(originDeviceId.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (attendeeId.present) {
      map['attendee_id'] = Variable<String>(attendeeId.value);
    }
    if (markedAt.present) {
      map['marked_at'] = Variable<DateTime>(markedAt.value);
    }
    if (operatorName.present) {
      map['operator_name'] = Variable<String>(operatorName.value);
    }
    if (undoneAt.present) {
      map['undone_at'] = Variable<DateTime>(undoneAt.value);
    }
    if (repeatOverride.present) {
      map['repeat_override'] = Variable<bool>(repeatOverride.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ControlRecordsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('sessionId: $sessionId, ')
          ..write('attendeeId: $attendeeId, ')
          ..write('markedAt: $markedAt, ')
          ..write('operatorName: $operatorName, ')
          ..write('undoneAt: $undoneAt, ')
          ..write('repeatOverride: $repeatOverride, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppMetaTable extends AppMeta with TableInfo<$AppMetaTable, AppMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<int> key = GeneratedColumn<int>(
      'key', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deviceLabelMeta =
      const VerificationMeta('deviceLabel');
  @override
  late final GeneratedColumn<String> deviceLabel = GeneratedColumn<String>(
      'device_label', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _schemaVersionMeta =
      const VerificationMeta('schemaVersion');
  @override
  late final GeneratedColumn<int> schemaVersion = GeneratedColumn<int>(
      'schema_version', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _lastBackupAtMeta =
      const VerificationMeta('lastBackupAt');
  @override
  late final GeneratedColumn<DateTime> lastBackupAt = GeneratedColumn<DateTime>(
      'last_backup_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _recoveryHashMeta =
      const VerificationMeta('recoveryHash');
  @override
  late final GeneratedColumn<String> recoveryHash = GeneratedColumn<String>(
      'recovery_hash', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [key, deviceId, deviceLabel, schemaVersion, lastBackupAt, recoveryHash];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_meta';
  @override
  VerificationContext validateIntegrity(Insertable<AppMetaData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    }
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('device_label')) {
      context.handle(
          _deviceLabelMeta,
          deviceLabel.isAcceptableOrUnknown(
              data['device_label']!, _deviceLabelMeta));
    }
    if (data.containsKey('schema_version')) {
      context.handle(
          _schemaVersionMeta,
          schemaVersion.isAcceptableOrUnknown(
              data['schema_version']!, _schemaVersionMeta));
    } else if (isInserting) {
      context.missing(_schemaVersionMeta);
    }
    if (data.containsKey('last_backup_at')) {
      context.handle(
          _lastBackupAtMeta,
          lastBackupAt.isAcceptableOrUnknown(
              data['last_backup_at']!, _lastBackupAtMeta));
    }
    if (data.containsKey('recovery_hash')) {
      context.handle(
          _recoveryHashMeta,
          recoveryHash.isAcceptableOrUnknown(
              data['recovery_hash']!, _recoveryHashMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppMetaData(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}key'])!,
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
      deviceLabel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_label'])!,
      schemaVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}schema_version'])!,
      lastBackupAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_backup_at']),
      recoveryHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}recovery_hash']),
    );
  }

  @override
  $AppMetaTable createAlias(String alias) {
    return $AppMetaTable(attachedDatabase, alias);
  }
}

class AppMetaData extends DataClass implements Insertable<AppMetaData> {
  final int key;
  final String deviceId;
  final String deviceLabel;
  final int schemaVersion;
  final DateTime? lastBackupAt;

  /// Hash del código de recuperación del administrador (un solo uso).
  final String? recoveryHash;
  const AppMetaData(
      {required this.key,
      required this.deviceId,
      required this.deviceLabel,
      required this.schemaVersion,
      this.lastBackupAt,
      this.recoveryHash});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<int>(key);
    map['device_id'] = Variable<String>(deviceId);
    map['device_label'] = Variable<String>(deviceLabel);
    map['schema_version'] = Variable<int>(schemaVersion);
    if (!nullToAbsent || lastBackupAt != null) {
      map['last_backup_at'] = Variable<DateTime>(lastBackupAt);
    }
    if (!nullToAbsent || recoveryHash != null) {
      map['recovery_hash'] = Variable<String>(recoveryHash);
    }
    return map;
  }

  AppMetaCompanion toCompanion(bool nullToAbsent) {
    return AppMetaCompanion(
      key: Value(key),
      deviceId: Value(deviceId),
      deviceLabel: Value(deviceLabel),
      schemaVersion: Value(schemaVersion),
      lastBackupAt: lastBackupAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastBackupAt),
      recoveryHash: recoveryHash == null && nullToAbsent
          ? const Value.absent()
          : Value(recoveryHash),
    );
  }

  factory AppMetaData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppMetaData(
      key: serializer.fromJson<int>(json['key']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      deviceLabel: serializer.fromJson<String>(json['deviceLabel']),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
      lastBackupAt: serializer.fromJson<DateTime?>(json['lastBackupAt']),
      recoveryHash: serializer.fromJson<String?>(json['recoveryHash']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<int>(key),
      'deviceId': serializer.toJson<String>(deviceId),
      'deviceLabel': serializer.toJson<String>(deviceLabel),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
      'lastBackupAt': serializer.toJson<DateTime?>(lastBackupAt),
      'recoveryHash': serializer.toJson<String?>(recoveryHash),
    };
  }

  AppMetaData copyWith(
          {int? key,
          String? deviceId,
          String? deviceLabel,
          int? schemaVersion,
          Value<DateTime?> lastBackupAt = const Value.absent(),
          Value<String?> recoveryHash = const Value.absent()}) =>
      AppMetaData(
        key: key ?? this.key,
        deviceId: deviceId ?? this.deviceId,
        deviceLabel: deviceLabel ?? this.deviceLabel,
        schemaVersion: schemaVersion ?? this.schemaVersion,
        lastBackupAt:
            lastBackupAt.present ? lastBackupAt.value : this.lastBackupAt,
        recoveryHash:
            recoveryHash.present ? recoveryHash.value : this.recoveryHash,
      );
  AppMetaData copyWithCompanion(AppMetaCompanion data) {
    return AppMetaData(
      key: data.key.present ? data.key.value : this.key,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      deviceLabel:
          data.deviceLabel.present ? data.deviceLabel.value : this.deviceLabel,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
      lastBackupAt: data.lastBackupAt.present
          ? data.lastBackupAt.value
          : this.lastBackupAt,
      recoveryHash: data.recoveryHash.present
          ? data.recoveryHash.value
          : this.recoveryHash,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaData(')
          ..write('key: $key, ')
          ..write('deviceId: $deviceId, ')
          ..write('deviceLabel: $deviceLabel, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('lastBackupAt: $lastBackupAt, ')
          ..write('recoveryHash: $recoveryHash')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      key, deviceId, deviceLabel, schemaVersion, lastBackupAt, recoveryHash);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppMetaData &&
          other.key == this.key &&
          other.deviceId == this.deviceId &&
          other.deviceLabel == this.deviceLabel &&
          other.schemaVersion == this.schemaVersion &&
          other.lastBackupAt == this.lastBackupAt &&
          other.recoveryHash == this.recoveryHash);
}

class AppMetaCompanion extends UpdateCompanion<AppMetaData> {
  final Value<int> key;
  final Value<String> deviceId;
  final Value<String> deviceLabel;
  final Value<int> schemaVersion;
  final Value<DateTime?> lastBackupAt;
  final Value<String?> recoveryHash;
  const AppMetaCompanion({
    this.key = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.deviceLabel = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.lastBackupAt = const Value.absent(),
    this.recoveryHash = const Value.absent(),
  });
  AppMetaCompanion.insert({
    this.key = const Value.absent(),
    required String deviceId,
    this.deviceLabel = const Value.absent(),
    required int schemaVersion,
    this.lastBackupAt = const Value.absent(),
    this.recoveryHash = const Value.absent(),
  })  : deviceId = Value(deviceId),
        schemaVersion = Value(schemaVersion);
  static Insertable<AppMetaData> custom({
    Expression<int>? key,
    Expression<String>? deviceId,
    Expression<String>? deviceLabel,
    Expression<int>? schemaVersion,
    Expression<DateTime>? lastBackupAt,
    Expression<String>? recoveryHash,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (deviceId != null) 'device_id': deviceId,
      if (deviceLabel != null) 'device_label': deviceLabel,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (lastBackupAt != null) 'last_backup_at': lastBackupAt,
      if (recoveryHash != null) 'recovery_hash': recoveryHash,
    });
  }

  AppMetaCompanion copyWith(
      {Value<int>? key,
      Value<String>? deviceId,
      Value<String>? deviceLabel,
      Value<int>? schemaVersion,
      Value<DateTime?>? lastBackupAt,
      Value<String?>? recoveryHash}) {
    return AppMetaCompanion(
      key: key ?? this.key,
      deviceId: deviceId ?? this.deviceId,
      deviceLabel: deviceLabel ?? this.deviceLabel,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      lastBackupAt: lastBackupAt ?? this.lastBackupAt,
      recoveryHash: recoveryHash ?? this.recoveryHash,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<int>(key.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (deviceLabel.present) {
      map['device_label'] = Variable<String>(deviceLabel.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (lastBackupAt.present) {
      map['last_backup_at'] = Variable<DateTime>(lastBackupAt.value);
    }
    if (recoveryHash.present) {
      map['recovery_hash'] = Variable<String>(recoveryHash.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaCompanion(')
          ..write('key: $key, ')
          ..write('deviceId: $deviceId, ')
          ..write('deviceLabel: $deviceLabel, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('lastBackupAt: $lastBackupAt, ')
          ..write('recoveryHash: $recoveryHash')
          ..write(')'))
        .toString();
  }
}

class $AppUsersTable extends AppUsers with TableInfo<$AppUsersTable, AppUser> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppUsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _originDeviceIdMeta =
      const VerificationMeta('originDeviceId');
  @override
  late final GeneratedColumn<String> originDeviceId = GeneratedColumn<String>(
      'origin_device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _usernameMeta =
      const VerificationMeta('username');
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
      'username', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _passwordHashMeta =
      const VerificationMeta('passwordHash');
  @override
  late final GeneratedColumn<String> passwordHash = GeneratedColumn<String>(
      'password_hash', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
      'active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _failedAttemptsMeta =
      const VerificationMeta('failedAttempts');
  @override
  late final GeneratedColumn<int> failedAttempts = GeneratedColumn<int>(
      'failed_attempts', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lockedUntilMeta =
      const VerificationMeta('lockedUntil');
  @override
  late final GeneratedColumn<DateTime> lockedUntil = GeneratedColumn<DateTime>(
      'locked_until', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _lastLoginAtMeta =
      const VerificationMeta('lastLoginAt');
  @override
  late final GeneratedColumn<DateTime> lastLoginAt = GeneratedColumn<DateTime>(
      'last_login_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        createdAt,
        updatedAt,
        deletedAt,
        originDeviceId,
        username,
        displayName,
        role,
        passwordHash,
        active,
        failedAttempts,
        lockedUntil,
        lastLoginAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_users';
  @override
  VerificationContext validateIntegrity(Insertable<AppUser> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('origin_device_id')) {
      context.handle(
          _originDeviceIdMeta,
          originDeviceId.isAcceptableOrUnknown(
              data['origin_device_id']!, _originDeviceIdMeta));
    } else if (isInserting) {
      context.missing(_originDeviceIdMeta);
    }
    if (data.containsKey('username')) {
      context.handle(_usernameMeta,
          username.isAcceptableOrUnknown(data['username']!, _usernameMeta));
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('password_hash')) {
      context.handle(
          _passwordHashMeta,
          passwordHash.isAcceptableOrUnknown(
              data['password_hash']!, _passwordHashMeta));
    } else if (isInserting) {
      context.missing(_passwordHashMeta);
    }
    if (data.containsKey('active')) {
      context.handle(_activeMeta,
          active.isAcceptableOrUnknown(data['active']!, _activeMeta));
    }
    if (data.containsKey('failed_attempts')) {
      context.handle(
          _failedAttemptsMeta,
          failedAttempts.isAcceptableOrUnknown(
              data['failed_attempts']!, _failedAttemptsMeta));
    }
    if (data.containsKey('locked_until')) {
      context.handle(
          _lockedUntilMeta,
          lockedUntil.isAcceptableOrUnknown(
              data['locked_until']!, _lockedUntilMeta));
    }
    if (data.containsKey('last_login_at')) {
      context.handle(
          _lastLoginAtMeta,
          lastLoginAt.isAcceptableOrUnknown(
              data['last_login_at']!, _lastLoginAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppUser map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppUser(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      originDeviceId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}origin_device_id'])!,
      username: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}username'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      passwordHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}password_hash'])!,
      active: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}active'])!,
      failedAttempts: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}failed_attempts'])!,
      lockedUntil: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}locked_until']),
      lastLoginAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_login_at']),
    );
  }

  @override
  $AppUsersTable createAlias(String alias) {
    return $AppUsersTable(attachedDatabase, alias);
  }
}

class AppUser extends DataClass implements Insertable<AppUser> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String originDeviceId;
  final String username;
  final String displayName;
  final String role;
  final String passwordHash;
  final bool active;
  final int failedAttempts;
  final DateTime? lockedUntil;
  final DateTime? lastLoginAt;
  const AppUser(
      {required this.id,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.originDeviceId,
      required this.username,
      required this.displayName,
      required this.role,
      required this.passwordHash,
      required this.active,
      required this.failedAttempts,
      this.lockedUntil,
      this.lastLoginAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['origin_device_id'] = Variable<String>(originDeviceId);
    map['username'] = Variable<String>(username);
    map['display_name'] = Variable<String>(displayName);
    map['role'] = Variable<String>(role);
    map['password_hash'] = Variable<String>(passwordHash);
    map['active'] = Variable<bool>(active);
    map['failed_attempts'] = Variable<int>(failedAttempts);
    if (!nullToAbsent || lockedUntil != null) {
      map['locked_until'] = Variable<DateTime>(lockedUntil);
    }
    if (!nullToAbsent || lastLoginAt != null) {
      map['last_login_at'] = Variable<DateTime>(lastLoginAt);
    }
    return map;
  }

  AppUsersCompanion toCompanion(bool nullToAbsent) {
    return AppUsersCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      originDeviceId: Value(originDeviceId),
      username: Value(username),
      displayName: Value(displayName),
      role: Value(role),
      passwordHash: Value(passwordHash),
      active: Value(active),
      failedAttempts: Value(failedAttempts),
      lockedUntil: lockedUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(lockedUntil),
      lastLoginAt: lastLoginAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastLoginAt),
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppUser(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      originDeviceId: serializer.fromJson<String>(json['originDeviceId']),
      username: serializer.fromJson<String>(json['username']),
      displayName: serializer.fromJson<String>(json['displayName']),
      role: serializer.fromJson<String>(json['role']),
      passwordHash: serializer.fromJson<String>(json['passwordHash']),
      active: serializer.fromJson<bool>(json['active']),
      failedAttempts: serializer.fromJson<int>(json['failedAttempts']),
      lockedUntil: serializer.fromJson<DateTime?>(json['lockedUntil']),
      lastLoginAt: serializer.fromJson<DateTime?>(json['lastLoginAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'originDeviceId': serializer.toJson<String>(originDeviceId),
      'username': serializer.toJson<String>(username),
      'displayName': serializer.toJson<String>(displayName),
      'role': serializer.toJson<String>(role),
      'passwordHash': serializer.toJson<String>(passwordHash),
      'active': serializer.toJson<bool>(active),
      'failedAttempts': serializer.toJson<int>(failedAttempts),
      'lockedUntil': serializer.toJson<DateTime?>(lockedUntil),
      'lastLoginAt': serializer.toJson<DateTime?>(lastLoginAt),
    };
  }

  AppUser copyWith(
          {String? id,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          String? originDeviceId,
          String? username,
          String? displayName,
          String? role,
          String? passwordHash,
          bool? active,
          int? failedAttempts,
          Value<DateTime?> lockedUntil = const Value.absent(),
          Value<DateTime?> lastLoginAt = const Value.absent()}) =>
      AppUser(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        originDeviceId: originDeviceId ?? this.originDeviceId,
        username: username ?? this.username,
        displayName: displayName ?? this.displayName,
        role: role ?? this.role,
        passwordHash: passwordHash ?? this.passwordHash,
        active: active ?? this.active,
        failedAttempts: failedAttempts ?? this.failedAttempts,
        lockedUntil: lockedUntil.present ? lockedUntil.value : this.lockedUntil,
        lastLoginAt: lastLoginAt.present ? lastLoginAt.value : this.lastLoginAt,
      );
  AppUser copyWithCompanion(AppUsersCompanion data) {
    return AppUser(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      originDeviceId: data.originDeviceId.present
          ? data.originDeviceId.value
          : this.originDeviceId,
      username: data.username.present ? data.username.value : this.username,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      role: data.role.present ? data.role.value : this.role,
      passwordHash: data.passwordHash.present
          ? data.passwordHash.value
          : this.passwordHash,
      active: data.active.present ? data.active.value : this.active,
      failedAttempts: data.failedAttempts.present
          ? data.failedAttempts.value
          : this.failedAttempts,
      lockedUntil:
          data.lockedUntil.present ? data.lockedUntil.value : this.lockedUntil,
      lastLoginAt:
          data.lastLoginAt.present ? data.lastLoginAt.value : this.lastLoginAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppUser(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('username: $username, ')
          ..write('displayName: $displayName, ')
          ..write('role: $role, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('active: $active, ')
          ..write('failedAttempts: $failedAttempts, ')
          ..write('lockedUntil: $lockedUntil, ')
          ..write('lastLoginAt: $lastLoginAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      createdAt,
      updatedAt,
      deletedAt,
      originDeviceId,
      username,
      displayName,
      role,
      passwordHash,
      active,
      failedAttempts,
      lockedUntil,
      lastLoginAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppUser &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.originDeviceId == this.originDeviceId &&
          other.username == this.username &&
          other.displayName == this.displayName &&
          other.role == this.role &&
          other.passwordHash == this.passwordHash &&
          other.active == this.active &&
          other.failedAttempts == this.failedAttempts &&
          other.lockedUntil == this.lockedUntil &&
          other.lastLoginAt == this.lastLoginAt);
}

class AppUsersCompanion extends UpdateCompanion<AppUser> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> originDeviceId;
  final Value<String> username;
  final Value<String> displayName;
  final Value<String> role;
  final Value<String> passwordHash;
  final Value<bool> active;
  final Value<int> failedAttempts;
  final Value<DateTime?> lockedUntil;
  final Value<DateTime?> lastLoginAt;
  final Value<int> rowid;
  const AppUsersCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.originDeviceId = const Value.absent(),
    this.username = const Value.absent(),
    this.displayName = const Value.absent(),
    this.role = const Value.absent(),
    this.passwordHash = const Value.absent(),
    this.active = const Value.absent(),
    this.failedAttempts = const Value.absent(),
    this.lockedUntil = const Value.absent(),
    this.lastLoginAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppUsersCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String originDeviceId,
    required String username,
    required String displayName,
    required String role,
    required String passwordHash,
    this.active = const Value.absent(),
    this.failedAttempts = const Value.absent(),
    this.lockedUntil = const Value.absent(),
    this.lastLoginAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        originDeviceId = Value(originDeviceId),
        username = Value(username),
        displayName = Value(displayName),
        role = Value(role),
        passwordHash = Value(passwordHash);
  static Insertable<AppUser> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? originDeviceId,
    Expression<String>? username,
    Expression<String>? displayName,
    Expression<String>? role,
    Expression<String>? passwordHash,
    Expression<bool>? active,
    Expression<int>? failedAttempts,
    Expression<DateTime>? lockedUntil,
    Expression<DateTime>? lastLoginAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (originDeviceId != null) 'origin_device_id': originDeviceId,
      if (username != null) 'username': username,
      if (displayName != null) 'display_name': displayName,
      if (role != null) 'role': role,
      if (passwordHash != null) 'password_hash': passwordHash,
      if (active != null) 'active': active,
      if (failedAttempts != null) 'failed_attempts': failedAttempts,
      if (lockedUntil != null) 'locked_until': lockedUntil,
      if (lastLoginAt != null) 'last_login_at': lastLoginAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppUsersCompanion copyWith(
      {Value<String>? id,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<String>? originDeviceId,
      Value<String>? username,
      Value<String>? displayName,
      Value<String>? role,
      Value<String>? passwordHash,
      Value<bool>? active,
      Value<int>? failedAttempts,
      Value<DateTime?>? lockedUntil,
      Value<DateTime?>? lastLoginAt,
      Value<int>? rowid}) {
    return AppUsersCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      originDeviceId: originDeviceId ?? this.originDeviceId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      passwordHash: passwordHash ?? this.passwordHash,
      active: active ?? this.active,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockedUntil: lockedUntil ?? this.lockedUntil,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
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
    if (originDeviceId.present) {
      map['origin_device_id'] = Variable<String>(originDeviceId.value);
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
    if (passwordHash.present) {
      map['password_hash'] = Variable<String>(passwordHash.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (failedAttempts.present) {
      map['failed_attempts'] = Variable<int>(failedAttempts.value);
    }
    if (lockedUntil.present) {
      map['locked_until'] = Variable<DateTime>(lockedUntil.value);
    }
    if (lastLoginAt.present) {
      map['last_login_at'] = Variable<DateTime>(lastLoginAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppUsersCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('originDeviceId: $originDeviceId, ')
          ..write('username: $username, ')
          ..write('displayName: $displayName, ')
          ..write('role: $role, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('active: $active, ')
          ..write('failedAttempts: $failedAttempts, ')
          ..write('lockedUntil: $lockedUntil, ')
          ..write('lastLoginAt: $lastLoginAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $EventsTable events = $EventsTable(this);
  late final $ChurchesTable churches = $ChurchesTable(this);
  late final $AgeRangesTable ageRanges = $AgeRangesTable(this);
  late final $AttendeesTable attendees = $AttendeesTable(this);
  late final $CouplesTable couples = $CouplesTable(this);
  late final $AttendeeGroupsTable attendeeGroups = $AttendeeGroupsTable(this);
  late final $GroupMembersTable groupMembers = $GroupMembersTable(this);
  late final $LodgingsTable lodgings = $LodgingsTable(this);
  late final $TeamsTable teams = $TeamsTable(this);
  late final $ControlTypesTable controlTypes = $ControlTypesTable(this);
  late final $ControlSessionsTable controlSessions =
      $ControlSessionsTable(this);
  late final $ControlRecordsTable controlRecords = $ControlRecordsTable(this);
  late final $AppMetaTable appMeta = $AppMetaTable(this);
  late final $AppUsersTable appUsers = $AppUsersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        events,
        churches,
        ageRanges,
        attendees,
        couples,
        attendeeGroups,
        groupMembers,
        lodgings,
        teams,
        controlTypes,
        controlSessions,
        controlRecords,
        appMeta,
        appUsers
      ];
}

typedef $$EventsTableCreateCompanionBuilder = EventsCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  required String originDeviceId,
  required String name,
  required String startDate,
  required String endDate,
  Value<String> venue,
  Value<String> organizer,
  Value<bool> offersLodging,
  Value<bool> offersTeams,
  Value<bool> setupDone,
  Value<String> notes,
  Value<int> maxSizeDiff,
  Value<int> maxSexDiff,
  Value<double> maxAgeDiff,
  Value<int> rowid,
});
typedef $$EventsTableUpdateCompanionBuilder = EventsCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> originDeviceId,
  Value<String> name,
  Value<String> startDate,
  Value<String> endDate,
  Value<String> venue,
  Value<String> organizer,
  Value<bool> offersLodging,
  Value<bool> offersTeams,
  Value<bool> setupDone,
  Value<String> notes,
  Value<int> maxSizeDiff,
  Value<int> maxSexDiff,
  Value<double> maxAgeDiff,
  Value<int> rowid,
});

final class $$EventsTableReferences
    extends BaseReferences<_$AppDatabase, $EventsTable, Event> {
  $$EventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AgeRangesTable, List<AgeRangeRow>>
      _ageRangesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.ageRanges,
              aliasName: 'events__id__age_ranges__event_id');

  $$AgeRangesTableProcessedTableManager get ageRangesRefs {
    final manager = $$AgeRangesTableTableManager($_db, $_db.ageRanges)
        .filter((f) => f.eventId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ageRangesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$AttendeesTable, List<AttendeeRow>>
      _attendeesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.attendees,
              aliasName: 'events__id__attendees__event_id');

  $$AttendeesTableProcessedTableManager get attendeesRefs {
    final manager = $$AttendeesTableTableManager($_db, $_db.attendees)
        .filter((f) => f.eventId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_attendeesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$CouplesTable, List<Couple>> _couplesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.couples,
          aliasName: 'events__id__couples__event_id');

  $$CouplesTableProcessedTableManager get couplesRefs {
    final manager = $$CouplesTableTableManager($_db, $_db.couples)
        .filter((f) => f.eventId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_couplesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$AttendeeGroupsTable, List<AttendeeGroup>>
      _attendeeGroupsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.attendeeGroups,
              aliasName: 'events__id__attendee_groups__event_id');

  $$AttendeeGroupsTableProcessedTableManager get attendeeGroupsRefs {
    final manager = $$AttendeeGroupsTableTableManager($_db, $_db.attendeeGroups)
        .filter((f) => f.eventId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_attendeeGroupsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$LodgingsTable, List<LodgingRow>>
      _lodgingsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.lodgings,
              aliasName: 'events__id__lodgings__event_id');

  $$LodgingsTableProcessedTableManager get lodgingsRefs {
    final manager = $$LodgingsTableTableManager($_db, $_db.lodgings)
        .filter((f) => f.eventId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_lodgingsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TeamsTable, List<TeamRow>> _teamsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.teams,
          aliasName: 'events__id__teams__event_id');

  $$TeamsTableProcessedTableManager get teamsRefs {
    final manager = $$TeamsTableTableManager($_db, $_db.teams)
        .filter((f) => f.eventId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_teamsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ControlTypesTable, List<ControlType>>
      _controlTypesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.controlTypes,
              aliasName: 'events__id__control_types__event_id');

  $$ControlTypesTableProcessedTableManager get controlTypesRefs {
    final manager = $$ControlTypesTableTableManager($_db, $_db.controlTypes)
        .filter((f) => f.eventId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_controlTypesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ControlSessionsTable, List<ControlSession>>
      _controlSessionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.controlSessions,
              aliasName: 'events__id__control_sessions__event_id');

  $$ControlSessionsTableProcessedTableManager get controlSessionsRefs {
    final manager =
        $$ControlSessionsTableTableManager($_db, $_db.controlSessions)
            .filter((f) => f.eventId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_controlSessionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$EventsTableFilterComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get originDeviceId => $composableBuilder(
      column: $table.originDeviceId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get venue => $composableBuilder(
      column: $table.venue, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get organizer => $composableBuilder(
      column: $table.organizer, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get offersLodging => $composableBuilder(
      column: $table.offersLodging, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get offersTeams => $composableBuilder(
      column: $table.offersTeams, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get setupDone => $composableBuilder(
      column: $table.setupDone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxSizeDiff => $composableBuilder(
      column: $table.maxSizeDiff, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxSexDiff => $composableBuilder(
      column: $table.maxSexDiff, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get maxAgeDiff => $composableBuilder(
      column: $table.maxAgeDiff, builder: (column) => ColumnFilters(column));

  Expression<bool> ageRangesRefs(
      Expression<bool> Function($$AgeRangesTableFilterComposer f) f) {
    final $$AgeRangesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.ageRanges,
        getReferencedColumn: (t) => t.eventId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AgeRangesTableFilterComposer(
              $db: $db,
              $table: $db.ageRanges,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> attendeesRefs(
      Expression<bool> Function($$AttendeesTableFilterComposer f) f) {
    final $$AttendeesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.attendees,
        getReferencedColumn: (t) => t.eventId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AttendeesTableFilterComposer(
              $db: $db,
              $table: $db.attendees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> couplesRefs(
      Expression<bool> Function($$CouplesTableFilterComposer f) f) {
    final $$CouplesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.couples,
        getReferencedColumn: (t) => t.eventId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CouplesTableFilterComposer(
              $db: $db,
              $table: $db.couples,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> attendeeGroupsRefs(
      Expression<bool> Function($$AttendeeGroupsTableFilterComposer f) f) {
    final $$AttendeeGroupsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.attendeeGroups,
        getReferencedColumn: (t) => t.eventId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AttendeeGroupsTableFilterComposer(
              $db: $db,
              $table: $db.attendeeGroups,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> lodgingsRefs(
      Expression<bool> Function($$LodgingsTableFilterComposer f) f) {
    final $$LodgingsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.lodgings,
        getReferencedColumn: (t) => t.eventId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LodgingsTableFilterComposer(
              $db: $db,
              $table: $db.lodgings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> teamsRefs(
      Expression<bool> Function($$TeamsTableFilterComposer f) f) {
    final $$TeamsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.teams,
        getReferencedColumn: (t) => t.eventId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TeamsTableFilterComposer(
              $db: $db,
              $table: $db.teams,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> controlTypesRefs(
      Expression<bool> Function($$ControlTypesTableFilterComposer f) f) {
    final $$ControlTypesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.controlTypes,
        getReferencedColumn: (t) => t.eventId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ControlTypesTableFilterComposer(
              $db: $db,
              $table: $db.controlTypes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> controlSessionsRefs(
      Expression<bool> Function($$ControlSessionsTableFilterComposer f) f) {
    final $$ControlSessionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.controlSessions,
        getReferencedColumn: (t) => t.eventId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ControlSessionsTableFilterComposer(
              $db: $db,
              $table: $db.controlSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$EventsTableOrderingComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get originDeviceId => $composableBuilder(
      column: $table.originDeviceId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get venue => $composableBuilder(
      column: $table.venue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get organizer => $composableBuilder(
      column: $table.organizer, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get offersLodging => $composableBuilder(
      column: $table.offersLodging,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get offersTeams => $composableBuilder(
      column: $table.offersTeams, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get setupDone => $composableBuilder(
      column: $table.setupDone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxSizeDiff => $composableBuilder(
      column: $table.maxSizeDiff, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxSexDiff => $composableBuilder(
      column: $table.maxSexDiff, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get maxAgeDiff => $composableBuilder(
      column: $table.maxAgeDiff, builder: (column) => ColumnOrderings(column));
}

class $$EventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get originDeviceId => $composableBuilder(
      column: $table.originDeviceId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get venue =>
      $composableBuilder(column: $table.venue, builder: (column) => column);

  GeneratedColumn<String> get organizer =>
      $composableBuilder(column: $table.organizer, builder: (column) => column);

  GeneratedColumn<bool> get offersLodging => $composableBuilder(
      column: $table.offersLodging, builder: (column) => column);

  GeneratedColumn<bool> get offersTeams => $composableBuilder(
      column: $table.offersTeams, builder: (column) => column);

  GeneratedColumn<bool> get setupDone =>
      $composableBuilder(column: $table.setupDone, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get maxSizeDiff => $composableBuilder(
      column: $table.maxSizeDiff, builder: (column) => column);

  GeneratedColumn<int> get maxSexDiff => $composableBuilder(
      column: $table.maxSexDiff, builder: (column) => column);

  GeneratedColumn<double> get maxAgeDiff => $composableBuilder(
      column: $table.maxAgeDiff, builder: (column) => column);

  Expression<T> ageRangesRefs<T extends Object>(
      Expression<T> Function($$AgeRangesTableAnnotationComposer a) f) {
    final $$AgeRangesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.ageRanges,
        getReferencedColumn: (t) => t.eventId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AgeRangesTableAnnotationComposer(
              $db: $db,
              $table: $db.ageRanges,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> attendeesRefs<T extends Object>(
      Expression<T> Function($$AttendeesTableAnnotationComposer a) f) {
    final $$AttendeesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.attendees,
        getReferencedColumn: (t) => t.eventId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AttendeesTableAnnotationComposer(
              $db: $db,
              $table: $db.attendees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> couplesRefs<T extends Object>(
      Expression<T> Function($$CouplesTableAnnotationComposer a) f) {
    final $$CouplesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.couples,
        getReferencedColumn: (t) => t.eventId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CouplesTableAnnotationComposer(
              $db: $db,
              $table: $db.couples,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> attendeeGroupsRefs<T extends Object>(
      Expression<T> Function($$AttendeeGroupsTableAnnotationComposer a) f) {
    final $$AttendeeGroupsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.attendeeGroups,
        getReferencedColumn: (t) => t.eventId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AttendeeGroupsTableAnnotationComposer(
              $db: $db,
              $table: $db.attendeeGroups,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> lodgingsRefs<T extends Object>(
      Expression<T> Function($$LodgingsTableAnnotationComposer a) f) {
    final $$LodgingsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.lodgings,
        getReferencedColumn: (t) => t.eventId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LodgingsTableAnnotationComposer(
              $db: $db,
              $table: $db.lodgings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> teamsRefs<T extends Object>(
      Expression<T> Function($$TeamsTableAnnotationComposer a) f) {
    final $$TeamsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.teams,
        getReferencedColumn: (t) => t.eventId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TeamsTableAnnotationComposer(
              $db: $db,
              $table: $db.teams,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> controlTypesRefs<T extends Object>(
      Expression<T> Function($$ControlTypesTableAnnotationComposer a) f) {
    final $$ControlTypesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.controlTypes,
        getReferencedColumn: (t) => t.eventId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ControlTypesTableAnnotationComposer(
              $db: $db,
              $table: $db.controlTypes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> controlSessionsRefs<T extends Object>(
      Expression<T> Function($$ControlSessionsTableAnnotationComposer a) f) {
    final $$ControlSessionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.controlSessions,
        getReferencedColumn: (t) => t.eventId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ControlSessionsTableAnnotationComposer(
              $db: $db,
              $table: $db.controlSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$EventsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EventsTable,
    Event,
    $$EventsTableFilterComposer,
    $$EventsTableOrderingComposer,
    $$EventsTableAnnotationComposer,
    $$EventsTableCreateCompanionBuilder,
    $$EventsTableUpdateCompanionBuilder,
    (Event, $$EventsTableReferences),
    Event,
    PrefetchHooks Function(
        {bool ageRangesRefs,
        bool attendeesRefs,
        bool couplesRefs,
        bool attendeeGroupsRefs,
        bool lodgingsRefs,
        bool teamsRefs,
        bool controlTypesRefs,
        bool controlSessionsRefs})> {
  $$EventsTableTableManager(_$AppDatabase db, $EventsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> originDeviceId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> startDate = const Value.absent(),
            Value<String> endDate = const Value.absent(),
            Value<String> venue = const Value.absent(),
            Value<String> organizer = const Value.absent(),
            Value<bool> offersLodging = const Value.absent(),
            Value<bool> offersTeams = const Value.absent(),
            Value<bool> setupDone = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<int> maxSizeDiff = const Value.absent(),
            Value<int> maxSexDiff = const Value.absent(),
            Value<double> maxAgeDiff = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EventsCompanion(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            originDeviceId: originDeviceId,
            name: name,
            startDate: startDate,
            endDate: endDate,
            venue: venue,
            organizer: organizer,
            offersLodging: offersLodging,
            offersTeams: offersTeams,
            setupDone: setupDone,
            notes: notes,
            maxSizeDiff: maxSizeDiff,
            maxSexDiff: maxSexDiff,
            maxAgeDiff: maxAgeDiff,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            required String originDeviceId,
            required String name,
            required String startDate,
            required String endDate,
            Value<String> venue = const Value.absent(),
            Value<String> organizer = const Value.absent(),
            Value<bool> offersLodging = const Value.absent(),
            Value<bool> offersTeams = const Value.absent(),
            Value<bool> setupDone = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<int> maxSizeDiff = const Value.absent(),
            Value<int> maxSexDiff = const Value.absent(),
            Value<double> maxAgeDiff = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EventsCompanion.insert(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            originDeviceId: originDeviceId,
            name: name,
            startDate: startDate,
            endDate: endDate,
            venue: venue,
            organizer: organizer,
            offersLodging: offersLodging,
            offersTeams: offersTeams,
            setupDone: setupDone,
            notes: notes,
            maxSizeDiff: maxSizeDiff,
            maxSexDiff: maxSexDiff,
            maxAgeDiff: maxAgeDiff,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$EventsTable, Event>(table),
                    $$EventsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {ageRangesRefs = false,
              attendeesRefs = false,
              couplesRefs = false,
              attendeeGroupsRefs = false,
              lodgingsRefs = false,
              teamsRefs = false,
              controlTypesRefs = false,
              controlSessionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (ageRangesRefs) db.ageRanges,
                if (attendeesRefs) db.attendees,
                if (couplesRefs) db.couples,
                if (attendeeGroupsRefs) db.attendeeGroups,
                if (lodgingsRefs) db.lodgings,
                if (teamsRefs) db.teams,
                if (controlTypesRefs) db.controlTypes,
                if (controlSessionsRefs) db.controlSessions
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (ageRangesRefs)
                    await $_getPrefetchedDataByColumns<Event, $EventsTable,
                            AgeRangeRow, $AgeRangesTable>(
                        currentTable: table,
                        referencedTable:
                            $$EventsTableReferences._ageRangesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$EventsTableReferences(db, table, p0)
                                .ageRangesRefs,
                        currentColumn: 'id',
                        referencedColumn: 'event_id',
                        typedResults: items),
                  if (attendeesRefs)
                    await $_getPrefetchedDataByColumns<Event, $EventsTable,
                            AttendeeRow, $AttendeesTable>(
                        currentTable: table,
                        referencedTable:
                            $$EventsTableReferences._attendeesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$EventsTableReferences(db, table, p0)
                                .attendeesRefs,
                        currentColumn: 'id',
                        referencedColumn: 'event_id',
                        typedResults: items),
                  if (couplesRefs)
                    await $_getPrefetchedDataByColumns<Event, $EventsTable,
                            Couple, $CouplesTable>(
                        currentTable: table,
                        referencedTable:
                            $$EventsTableReferences._couplesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$EventsTableReferences(db, table, p0).couplesRefs,
                        currentColumn: 'id',
                        referencedColumn: 'event_id',
                        typedResults: items),
                  if (attendeeGroupsRefs)
                    await $_getPrefetchedDataByColumns<Event, $EventsTable,
                            AttendeeGroup, $AttendeeGroupsTable>(
                        currentTable: table,
                        referencedTable: $$EventsTableReferences
                            ._attendeeGroupsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$EventsTableReferences(db, table, p0)
                                .attendeeGroupsRefs,
                        currentColumn: 'id',
                        referencedColumn: 'event_id',
                        typedResults: items),
                  if (lodgingsRefs)
                    await $_getPrefetchedDataByColumns<Event, $EventsTable,
                            LodgingRow, $LodgingsTable>(
                        currentTable: table,
                        referencedTable:
                            $$EventsTableReferences._lodgingsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$EventsTableReferences(db, table, p0).lodgingsRefs,
                        currentColumn: 'id',
                        referencedColumn: 'event_id',
                        typedResults: items),
                  if (teamsRefs)
                    await $_getPrefetchedDataByColumns<Event, $EventsTable,
                            TeamRow, $TeamsTable>(
                        currentTable: table,
                        referencedTable:
                            $$EventsTableReferences._teamsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$EventsTableReferences(db, table, p0).teamsRefs,
                        currentColumn: 'id',
                        referencedColumn: 'event_id',
                        typedResults: items),
                  if (controlTypesRefs)
                    await $_getPrefetchedDataByColumns<Event, $EventsTable,
                            ControlType, $ControlTypesTable>(
                        currentTable: table,
                        referencedTable:
                            $$EventsTableReferences._controlTypesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$EventsTableReferences(db, table, p0)
                                .controlTypesRefs,
                        currentColumn: 'id',
                        referencedColumn: 'event_id',
                        typedResults: items),
                  if (controlSessionsRefs)
                    await $_getPrefetchedDataByColumns<Event, $EventsTable,
                            ControlSession, $ControlSessionsTable>(
                        currentTable: table,
                        referencedTable: $$EventsTableReferences
                            ._controlSessionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$EventsTableReferences(db, table, p0)
                                .controlSessionsRefs,
                        currentColumn: 'id',
                        referencedColumn: 'event_id',
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$EventsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EventsTable,
    Event,
    $$EventsTableFilterComposer,
    $$EventsTableOrderingComposer,
    $$EventsTableAnnotationComposer,
    $$EventsTableCreateCompanionBuilder,
    $$EventsTableUpdateCompanionBuilder,
    (Event, $$EventsTableReferences),
    Event,
    PrefetchHooks Function(
        {bool ageRangesRefs,
        bool attendeesRefs,
        bool couplesRefs,
        bool attendeeGroupsRefs,
        bool lodgingsRefs,
        bool teamsRefs,
        bool controlTypesRefs,
        bool controlSessionsRefs})>;
typedef $$ChurchesTableCreateCompanionBuilder = ChurchesCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  required String originDeviceId,
  required String name,
  required String nameNormalized,
  Value<String> province,
  Value<String> municipality,
  Value<String?> denomination,
  Value<String> community,
  Value<int> rowid,
});
typedef $$ChurchesTableUpdateCompanionBuilder = ChurchesCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> originDeviceId,
  Value<String> name,
  Value<String> nameNormalized,
  Value<String> province,
  Value<String> municipality,
  Value<String?> denomination,
  Value<String> community,
  Value<int> rowid,
});

final class $$ChurchesTableReferences
    extends BaseReferences<_$AppDatabase, $ChurchesTable, ChurchRow> {
  $$ChurchesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AttendeesTable, List<AttendeeRow>>
      _attendeesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.attendees,
              aliasName: 'churches__id__attendees__church_id');

  $$AttendeesTableProcessedTableManager get attendeesRefs {
    final manager = $$AttendeesTableTableManager($_db, $_db.attendees)
        .filter((f) => f.churchId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_attendeesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ChurchesTableFilterComposer
    extends Composer<_$AppDatabase, $ChurchesTable> {
  $$ChurchesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get originDeviceId => $composableBuilder(
      column: $table.originDeviceId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nameNormalized => $composableBuilder(
      column: $table.nameNormalized,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get province => $composableBuilder(
      column: $table.province, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get municipality => $composableBuilder(
      column: $table.municipality, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get denomination => $composableBuilder(
      column: $table.denomination, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get community => $composableBuilder(
      column: $table.community, builder: (column) => ColumnFilters(column));

  Expression<bool> attendeesRefs(
      Expression<bool> Function($$AttendeesTableFilterComposer f) f) {
    final $$AttendeesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.attendees,
        getReferencedColumn: (t) => t.churchId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AttendeesTableFilterComposer(
              $db: $db,
              $table: $db.attendees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ChurchesTableOrderingComposer
    extends Composer<_$AppDatabase, $ChurchesTable> {
  $$ChurchesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get originDeviceId => $composableBuilder(
      column: $table.originDeviceId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nameNormalized => $composableBuilder(
      column: $table.nameNormalized,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get province => $composableBuilder(
      column: $table.province, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get municipality => $composableBuilder(
      column: $table.municipality,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get denomination => $composableBuilder(
      column: $table.denomination,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get community => $composableBuilder(
      column: $table.community, builder: (column) => ColumnOrderings(column));
}

class $$ChurchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChurchesTable> {
  $$ChurchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get originDeviceId => $composableBuilder(
      column: $table.originDeviceId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get nameNormalized => $composableBuilder(
      column: $table.nameNormalized, builder: (column) => column);

  GeneratedColumn<String> get province =>
      $composableBuilder(column: $table.province, builder: (column) => column);

  GeneratedColumn<String> get municipality => $composableBuilder(
      column: $table.municipality, builder: (column) => column);

  GeneratedColumn<String> get denomination => $composableBuilder(
      column: $table.denomination, builder: (column) => column);

  GeneratedColumn<String> get community =>
      $composableBuilder(column: $table.community, builder: (column) => column);

  Expression<T> attendeesRefs<T extends Object>(
      Expression<T> Function($$AttendeesTableAnnotationComposer a) f) {
    final $$AttendeesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.attendees,
        getReferencedColumn: (t) => t.churchId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AttendeesTableAnnotationComposer(
              $db: $db,
              $table: $db.attendees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ChurchesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ChurchesTable,
    ChurchRow,
    $$ChurchesTableFilterComposer,
    $$ChurchesTableOrderingComposer,
    $$ChurchesTableAnnotationComposer,
    $$ChurchesTableCreateCompanionBuilder,
    $$ChurchesTableUpdateCompanionBuilder,
    (ChurchRow, $$ChurchesTableReferences),
    ChurchRow,
    PrefetchHooks Function({bool attendeesRefs})> {
  $$ChurchesTableTableManager(_$AppDatabase db, $ChurchesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChurchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChurchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChurchesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> originDeviceId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> nameNormalized = const Value.absent(),
            Value<String> province = const Value.absent(),
            Value<String> municipality = const Value.absent(),
            Value<String?> denomination = const Value.absent(),
            Value<String> community = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChurchesCompanion(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            originDeviceId: originDeviceId,
            name: name,
            nameNormalized: nameNormalized,
            province: province,
            municipality: municipality,
            denomination: denomination,
            community: community,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            required String originDeviceId,
            required String name,
            required String nameNormalized,
            Value<String> province = const Value.absent(),
            Value<String> municipality = const Value.absent(),
            Value<String?> denomination = const Value.absent(),
            Value<String> community = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChurchesCompanion.insert(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            originDeviceId: originDeviceId,
            name: name,
            nameNormalized: nameNormalized,
            province: province,
            municipality: municipality,
            denomination: denomination,
            community: community,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$ChurchesTable, ChurchRow>(table),
                    $$ChurchesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({attendeesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (attendeesRefs) db.attendees],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (attendeesRefs)
                    await $_getPrefetchedDataByColumns<ChurchRow,
                            $ChurchesTable, AttendeeRow, $AttendeesTable>(
                        currentTable: table,
                        referencedTable:
                            $$ChurchesTableReferences._attendeesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ChurchesTableReferences(db, table, p0)
                                .attendeesRefs,
                        currentColumn: 'id',
                        referencedColumn: 'church_id',
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ChurchesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ChurchesTable,
    ChurchRow,
    $$ChurchesTableFilterComposer,
    $$ChurchesTableOrderingComposer,
    $$ChurchesTableAnnotationComposer,
    $$ChurchesTableCreateCompanionBuilder,
    $$ChurchesTableUpdateCompanionBuilder,
    (ChurchRow, $$ChurchesTableReferences),
    ChurchRow,
    PrefetchHooks Function({bool attendeesRefs})>;
typedef $$AgeRangesTableCreateCompanionBuilder = AgeRangesCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  required String originDeviceId,
  required String eventId,
  required String label,
  required int minAge,
  Value<int?> maxAge,
  Value<int> sortOrder,
  Value<int> rowid,
});
typedef $$AgeRangesTableUpdateCompanionBuilder = AgeRangesCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> originDeviceId,
  Value<String> eventId,
  Value<String> label,
  Value<int> minAge,
  Value<int?> maxAge,
  Value<int> sortOrder,
  Value<int> rowid,
});

final class $$AgeRangesTableReferences
    extends BaseReferences<_$AppDatabase, $AgeRangesTable, AgeRangeRow> {
  $$AgeRangesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EventsTable _eventIdTable(_$AppDatabase db) =>
      db.events.createAlias('age_ranges__event_id__events__id');

  $$EventsTableProcessedTableManager get eventId {
    final $_column = $_itemColumn<String>('event_id')!;

    final manager = $$EventsTableTableManager($_db, $_db.events)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$AgeRangesTableFilterComposer
    extends Composer<_$AppDatabase, $AgeRangesTable> {
  $$AgeRangesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get originDeviceId => $composableBuilder(
      column: $table.originDeviceId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minAge => $composableBuilder(
      column: $table.minAge, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxAge => $composableBuilder(
      column: $table.maxAge, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  $$EventsTableFilterComposer get eventId {
    final $$EventsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.eventId,
        referencedTable: $db.events,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventsTableFilterComposer(
              $db: $db,
              $table: $db.events,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AgeRangesTableOrderingComposer
    extends Composer<_$AppDatabase, $AgeRangesTable> {
  $$AgeRangesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get originDeviceId => $composableBuilder(
      column: $table.originDeviceId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minAge => $composableBuilder(
      column: $table.minAge, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxAge => $composableBuilder(
      column: $table.maxAge, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  $$EventsTableOrderingComposer get eventId {
    final $$EventsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.eventId,
        referencedTable: $db.events,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventsTableOrderingComposer(
              $db: $db,
              $table: $db.events,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AgeRangesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AgeRangesTable> {
  $$AgeRangesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get originDeviceId => $composableBuilder(
      column: $table.originDeviceId, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<int> get minAge =>
      $composableBuilder(column: $table.minAge, builder: (column) => column);

  GeneratedColumn<int> get maxAge =>
      $composableBuilder(column: $table.maxAge, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$EventsTableAnnotationComposer get eventId {
    final $$EventsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.eventId,
        referencedTable: $db.events,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventsTableAnnotationComposer(
              $db: $db,
              $table: $db.events,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AgeRangesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AgeRangesTable,
    AgeRangeRow,
    $$AgeRangesTableFilterComposer,
    $$AgeRangesTableOrderingComposer,
    $$AgeRangesTableAnnotationComposer,
    $$AgeRangesTableCreateCompanionBuilder,
    $$AgeRangesTableUpdateCompanionBuilder,
    (AgeRangeRow, $$AgeRangesTableReferences),
    AgeRangeRow,
    PrefetchHooks Function({bool eventId})> {
  $$AgeRangesTableTableManager(_$AppDatabase db, $AgeRangesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AgeRangesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AgeRangesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AgeRangesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> originDeviceId = const Value.absent(),
            Value<String> eventId = const Value.absent(),
            Value<String> label = const Value.absent(),
            Value<int> minAge = const Value.absent(),
            Value<int?> maxAge = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AgeRangesCompanion(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            originDeviceId: originDeviceId,
            eventId: eventId,
            label: label,
            minAge: minAge,
            maxAge: maxAge,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            required String originDeviceId,
            required String eventId,
            required String label,
            required int minAge,
            Value<int?> maxAge = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AgeRangesCompanion.insert(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            originDeviceId: originDeviceId,
            eventId: eventId,
            label: label,
            minAge: minAge,
            maxAge: maxAge,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$AgeRangesTable, AgeRangeRow>(table),
                    $$AgeRangesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({eventId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (eventId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.eventId,
                    referencedTable:
                        $$AgeRangesTableReferences._eventIdTable(db),
                    referencedColumn:
                        $$AgeRangesTableReferences._eventIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$AgeRangesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AgeRangesTable,
    AgeRangeRow,
    $$AgeRangesTableFilterComposer,
    $$AgeRangesTableOrderingComposer,
    $$AgeRangesTableAnnotationComposer,
    $$AgeRangesTableCreateCompanionBuilder,
    $$AgeRangesTableUpdateCompanionBuilder,
    (AgeRangeRow, $$AgeRangesTableReferences),
    AgeRangeRow,
    PrefetchHooks Function({bool eventId})>;
typedef $$AttendeesTableCreateCompanionBuilder = AttendeesCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  required String originDeviceId,
  required String eventId,
  required int regNumber,
  required String firstName,
  required String lastName1,
  Value<String> lastName2,
  required String sex,
  required int age,
  Value<String?> churchId,
  Value<String?> phone,
  Value<String> province,
  Value<String> municipality,
  Value<bool> needsLodging,
  Value<String> notes,
  Value<String?> coupleId,
  Value<String?> teamId,
  Value<String?> lodgingId,
  required String dedupeKey,
  Value<String?> createdBy,
  Value<String> status,
  Value<DateTime?> confirmedAt,
  Value<int> rowid,
});
typedef $$AttendeesTableUpdateCompanionBuilder = AttendeesCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> originDeviceId,
  Value<String> eventId,
  Value<int> regNumber,
  Value<String> firstName,
  Value<String> lastName1,
  Value<String> lastName2,
  Value<String> sex,
  Value<int> age,
  Value<String?> churchId,
  Value<String?> phone,
  Value<String> province,
  Value<String> municipality,
  Value<bool> needsLodging,
  Value<String> notes,
  Value<String?> coupleId,
  Value<String?> teamId,
  Value<String?> lodgingId,
  Value<String> dedupeKey,
  Value<String?> createdBy,
  Value<String> status,
  Value<DateTime?> confirmedAt,
  Value<int> rowid,
});

final class $$AttendeesTableReferences
    extends BaseReferences<_$AppDatabase, $AttendeesTable, AttendeeRow> {
  $$AttendeesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EventsTable _eventIdTable(_$AppDatabase db) =>
      db.events.createAlias('attendees__event_id__events__id');

  $$EventsTableProcessedTableManager get eventId {
    final $_column = $_itemColumn<String>('event_id')!;

    final manager = $$EventsTableTableManager($_db, $_db.events)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ChurchesTable _churchIdTable(_$AppDatabase db) =>
      db.churches.createAlias('attendees__church_id__churches__id');

  $$ChurchesTableProcessedTableManager? get churchId {
    final $_column = $_itemColumn<String>('church_id');
    if ($_column == null) return null;
    final manager = $$ChurchesTableTableManager($_db, $_db.churches)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_churchIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$GroupMembersTable, List<GroupMember>>
      _groupMembersRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.groupMembers,
              aliasName: 'attendees__id__group_members__attendee_id');

  $$GroupMembersTableProcessedTableManager get groupMembersRefs {
    final manager = $$GroupMembersTableTableManager($_db, $_db.groupMembers)
        .filter((f) => f.attendeeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_groupMembersRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ControlRecordsTable, List<ControlRecord>>
      _controlRecordsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.controlRecords,
              aliasName: 'attendees__id__control_records__attendee_id');

  $$ControlRecordsTableProcessedTableManager get controlRecordsRefs {
    final manager = $$ControlRecordsTableTableManager($_db, $_db.controlRecords)
        .filter((f) => f.attendeeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_controlRecordsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$AttendeesTableFilterComposer
    extends Composer<_$AppDatabase, $AttendeesTable> {
  $$AttendeesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get originDeviceId => $composableBuilder(
      column: $table.originDeviceId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get regNumber => $composableBuilder(
      column: $table.regNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get firstName => $composableBuilder(
      column: $table.firstName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastName1 => $composableBuilder(
      column: $table.lastName1, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastName2 => $composableBuilder(
      column: $table.lastName2, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sex => $composableBuilder(
      column: $table.sex, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get age => $composableBuilder(
      column: $table.age, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get province => $composableBuilder(
      column: $table.province, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get municipality => $composableBuilder(
      column: $table.municipality, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get needsLodging => $composableBuilder(
      column: $table.needsLodging, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coupleId => $composableBuilder(
      column: $table.coupleId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get teamId => $composableBuilder(
      column: $table.teamId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lodgingId => $composableBuilder(
      column: $table.lodgingId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dedupeKey => $composableBuilder(
      column: $table.dedupeKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdBy => $composableBuilder(
      column: $table.createdBy, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get confirmedAt => $composableBuilder(
      column: $table.confirmedAt, builder: (column) => ColumnFilters(column));

  $$EventsTableFilterComposer get eventId {
    final $$EventsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.eventId,
        referencedTable: $db.events,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventsTableFilterComposer(
              $db: $db,
              $table: $db.events,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ChurchesTableFilterComposer get churchId {
    final $$ChurchesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.churchId,
        referencedTable: $db.churches,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChurchesTableFilterComposer(
              $db: $db,
              $table: $db.churches,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> groupMembersRefs(
      Expression<bool> Function($$GroupMembersTableFilterComposer f) f) {
    final $$GroupMembersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.groupMembers,
        getReferencedColumn: (t) => t.attendeeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GroupMembersTableFilterComposer(
              $db: $db,
              $table: $db.groupMembers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> controlRecordsRefs(
      Expression<bool> Function($$ControlRecordsTableFilterComposer f) f) {
    final $$ControlRecordsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.controlRecords,
        getReferencedColumn: (t) => t.attendeeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ControlRecordsTableFilterComposer(
              $db: $db,
              $table: $db.controlRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AttendeesTableOrderingComposer
    extends Composer<_$AppDatabase, $AttendeesTable> {
  $$AttendeesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get originDeviceId => $composableBuilder(
      column: $table.originDeviceId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get regNumber => $composableBuilder(
      column: $table.regNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get firstName => $composableBuilder(
      column: $table.firstName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastName1 => $composableBuilder(
      column: $table.lastName1, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastName2 => $composableBuilder(
      column: $table.lastName2, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sex => $composableBuilder(
      column: $table.sex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get age => $composableBuilder(
      column: $table.age, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get province => $composableBuilder(
      column: $table.province, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get municipality => $composableBuilder(
      column: $table.municipality,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get needsLodging => $composableBuilder(
      column: $table.needsLodging,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coupleId => $composableBuilder(
      column: $table.coupleId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get teamId => $composableBuilder(
      column: $table.teamId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lodgingId => $composableBuilder(
      column: $table.lodgingId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dedupeKey => $composableBuilder(
      column: $table.dedupeKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdBy => $composableBuilder(
      column: $table.createdBy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get confirmedAt => $composableBuilder(
      column: $table.confirmedAt, builder: (column) => ColumnOrderings(column));

  $$EventsTableOrderingComposer get eventId {
    final $$EventsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.eventId,
        referencedTable: $db.events,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventsTableOrderingComposer(
              $db: $db,
              $table: $db.events,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ChurchesTableOrderingComposer get churchId {
    final $$ChurchesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.churchId,
        referencedTable: $db.churches,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChurchesTableOrderingComposer(
              $db: $db,
              $table: $db.churches,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AttendeesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttendeesTable> {
  $$AttendeesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get originDeviceId => $composableBuilder(
      column: $table.originDeviceId, builder: (column) => column);

  GeneratedColumn<int> get regNumber =>
      $composableBuilder(column: $table.regNumber, builder: (column) => column);

  GeneratedColumn<String> get firstName =>
      $composableBuilder(column: $table.firstName, builder: (column) => column);

  GeneratedColumn<String> get lastName1 =>
      $composableBuilder(column: $table.lastName1, builder: (column) => column);

  GeneratedColumn<String> get lastName2 =>
      $composableBuilder(column: $table.lastName2, builder: (column) => column);

  GeneratedColumn<String> get sex =>
      $composableBuilder(column: $table.sex, builder: (column) => column);

  GeneratedColumn<int> get age =>
      $composableBuilder(column: $table.age, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get province =>
      $composableBuilder(column: $table.province, builder: (column) => column);

  GeneratedColumn<String> get municipality => $composableBuilder(
      column: $table.municipality, builder: (column) => column);

  GeneratedColumn<bool> get needsLodging => $composableBuilder(
      column: $table.needsLodging, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get coupleId =>
      $composableBuilder(column: $table.coupleId, builder: (column) => column);

  GeneratedColumn<String> get teamId =>
      $composableBuilder(column: $table.teamId, builder: (column) => column);

  GeneratedColumn<String> get lodgingId =>
      $composableBuilder(column: $table.lodgingId, builder: (column) => column);

  GeneratedColumn<String> get dedupeKey =>
      $composableBuilder(column: $table.dedupeKey, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get confirmedAt => $composableBuilder(
      column: $table.confirmedAt, builder: (column) => column);

  $$EventsTableAnnotationComposer get eventId {
    final $$EventsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.eventId,
        referencedTable: $db.events,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventsTableAnnotationComposer(
              $db: $db,
              $table: $db.events,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ChurchesTableAnnotationComposer get churchId {
    final $$ChurchesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.churchId,
        referencedTable: $db.churches,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChurchesTableAnnotationComposer(
              $db: $db,
              $table: $db.churches,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> groupMembersRefs<T extends Object>(
      Expression<T> Function($$GroupMembersTableAnnotationComposer a) f) {
    final $$GroupMembersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.groupMembers,
        getReferencedColumn: (t) => t.attendeeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GroupMembersTableAnnotationComposer(
              $db: $db,
              $table: $db.groupMembers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> controlRecordsRefs<T extends Object>(
      Expression<T> Function($$ControlRecordsTableAnnotationComposer a) f) {
    final $$ControlRecordsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.controlRecords,
        getReferencedColumn: (t) => t.attendeeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ControlRecordsTableAnnotationComposer(
              $db: $db,
              $table: $db.controlRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AttendeesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AttendeesTable,
    AttendeeRow,
    $$AttendeesTableFilterComposer,
    $$AttendeesTableOrderingComposer,
    $$AttendeesTableAnnotationComposer,
    $$AttendeesTableCreateCompanionBuilder,
    $$AttendeesTableUpdateCompanionBuilder,
    (AttendeeRow, $$AttendeesTableReferences),
    AttendeeRow,
    PrefetchHooks Function(
        {bool eventId,
        bool churchId,
        bool groupMembersRefs,
        bool controlRecordsRefs})> {
  $$AttendeesTableTableManager(_$AppDatabase db, $AttendeesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttendeesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttendeesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttendeesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> originDeviceId = const Value.absent(),
            Value<String> eventId = const Value.absent(),
            Value<int> regNumber = const Value.absent(),
            Value<String> firstName = const Value.absent(),
            Value<String> lastName1 = const Value.absent(),
            Value<String> lastName2 = const Value.absent(),
            Value<String> sex = const Value.absent(),
            Value<int> age = const Value.absent(),
            Value<String?> churchId = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<String> province = const Value.absent(),
            Value<String> municipality = const Value.absent(),
            Value<bool> needsLodging = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<String?> coupleId = const Value.absent(),
            Value<String?> teamId = const Value.absent(),
            Value<String?> lodgingId = const Value.absent(),
            Value<String> dedupeKey = const Value.absent(),
            Value<String?> createdBy = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime?> confirmedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AttendeesCompanion(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            originDeviceId: originDeviceId,
            eventId: eventId,
            regNumber: regNumber,
            firstName: firstName,
            lastName1: lastName1,
            lastName2: lastName2,
            sex: sex,
            age: age,
            churchId: churchId,
            phone: phone,
            province: province,
            municipality: municipality,
            needsLodging: needsLodging,
            notes: notes,
            coupleId: coupleId,
            teamId: teamId,
            lodgingId: lodgingId,
            dedupeKey: dedupeKey,
            createdBy: createdBy,
            status: status,
            confirmedAt: confirmedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            required String originDeviceId,
            required String eventId,
            required int regNumber,
            required String firstName,
            required String lastName1,
            Value<String> lastName2 = const Value.absent(),
            required String sex,
            required int age,
            Value<String?> churchId = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<String> province = const Value.absent(),
            Value<String> municipality = const Value.absent(),
            Value<bool> needsLodging = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<String?> coupleId = const Value.absent(),
            Value<String?> teamId = const Value.absent(),
            Value<String?> lodgingId = const Value.absent(),
            required String dedupeKey,
            Value<String?> createdBy = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime?> confirmedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AttendeesCompanion.insert(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            originDeviceId: originDeviceId,
            eventId: eventId,
            regNumber: regNumber,
            firstName: firstName,
            lastName1: lastName1,
            lastName2: lastName2,
            sex: sex,
            age: age,
            churchId: churchId,
            phone: phone,
            province: province,
            municipality: municipality,
            needsLodging: needsLodging,
            notes: notes,
            coupleId: coupleId,
            teamId: teamId,
            lodgingId: lodgingId,
            dedupeKey: dedupeKey,
            createdBy: createdBy,
            status: status,
            confirmedAt: confirmedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$AttendeesTable, AttendeeRow>(table),
                    $$AttendeesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {eventId = false,
              churchId = false,
              groupMembersRefs = false,
              controlRecordsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (groupMembersRefs) db.groupMembers,
                if (controlRecordsRefs) db.controlRecords
              ],
              addJoins: <
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
                      dynamic>>(state) {
                if (eventId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.eventId,
                    referencedTable:
                        $$AttendeesTableReferences._eventIdTable(db),
                    referencedColumn:
                        $$AttendeesTableReferences._eventIdTable(db).id,
                  ) as T;
                }
                if (churchId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.churchId,
                    referencedTable:
                        $$AttendeesTableReferences._churchIdTable(db),
                    referencedColumn:
                        $$AttendeesTableReferences._churchIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (groupMembersRefs)
                    await $_getPrefetchedDataByColumns<AttendeeRow,
                            $AttendeesTable, GroupMember, $GroupMembersTable>(
                        currentTable: table,
                        referencedTable: $$AttendeesTableReferences
                            ._groupMembersRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AttendeesTableReferences(db, table, p0)
                                .groupMembersRefs,
                        currentColumn: 'id',
                        referencedColumn: 'attendee_id',
                        typedResults: items),
                  if (controlRecordsRefs)
                    await $_getPrefetchedDataByColumns<
                            AttendeeRow,
                            $AttendeesTable,
                            ControlRecord,
                            $ControlRecordsTable>(
                        currentTable: table,
                        referencedTable: $$AttendeesTableReferences
                            ._controlRecordsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AttendeesTableReferences(db, table, p0)
                                .controlRecordsRefs,
                        currentColumn: 'id',
                        referencedColumn: 'attendee_id',
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$AttendeesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AttendeesTable,
    AttendeeRow,
    $$AttendeesTableFilterComposer,
    $$AttendeesTableOrderingComposer,
    $$AttendeesTableAnnotationComposer,
    $$AttendeesTableCreateCompanionBuilder,
    $$AttendeesTableUpdateCompanionBuilder,
    (AttendeeRow, $$AttendeesTableReferences),
    AttendeeRow,
    PrefetchHooks Function(
        {bool eventId,
        bool churchId,
        bool groupMembersRefs,
        bool controlRecordsRefs})>;
typedef $$CouplesTableCreateCompanionBuilder = CouplesCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  required String originDeviceId,
  required String eventId,
  required String attendeeAId,
  required String attendeeBId,
  Value<int> rowid,
});
typedef $$CouplesTableUpdateCompanionBuilder = CouplesCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> originDeviceId,
  Value<String> eventId,
  Value<String> attendeeAId,
  Value<String> attendeeBId,
  Value<int> rowid,
});

final class $$CouplesTableReferences
    extends BaseReferences<_$AppDatabase, $CouplesTable, Couple> {
  $$CouplesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EventsTable _eventIdTable(_$AppDatabase db) =>
      db.events.createAlias('couples__event_id__events__id');

  $$EventsTableProcessedTableManager get eventId {
    final $_column = $_itemColumn<String>('event_id')!;

    final manager = $$EventsTableTableManager($_db, $_db.events)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $AttendeesTable _attendeeAIdTable(_$AppDatabase db) =>
      db.attendees.createAlias('couples__attendee_a_id__attendees__id');

  $$AttendeesTableProcessedTableManager get attendeeAId {
    final $_column = $_itemColumn<String>('attendee_a_id')!;

    final manager = $$AttendeesTableTableManager($_db, $_db.attendees)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_attendeeAIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $AttendeesTable _attendeeBIdTable(_$AppDatabase db) =>
      db.attendees.createAlias('couples__attendee_b_id__attendees__id');

  $$AttendeesTableProcessedTableManager get attendeeBId {
    final $_column = $_itemColumn<String>('attendee_b_id')!;

    final manager = $$AttendeesTableTableManager($_db, $_db.attendees)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_attendeeBIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$CouplesTableFilterComposer
    extends Composer<_$AppDatabase, $CouplesTable> {
  $$CouplesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get originDeviceId => $composableBuilder(
      column: $table.originDeviceId,
      builder: (column) => ColumnFilters(column));

  $$EventsTableFilterComposer get eventId {
    final $$EventsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.eventId,
        referencedTable: $db.events,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventsTableFilterComposer(
              $db: $db,
              $table: $db.events,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AttendeesTableFilterComposer get attendeeAId {
    final $$AttendeesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.attendeeAId,
        referencedTable: $db.attendees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AttendeesTableFilterComposer(
              $db: $db,
              $table: $db.attendees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AttendeesTableFilterComposer get attendeeBId {
    final $$AttendeesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.attendeeBId,
        referencedTable: $db.attendees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AttendeesTableFilterComposer(
              $db: $db,
              $table: $db.attendees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CouplesTableOrderingComposer
    extends Composer<_$AppDatabase, $CouplesTable> {
  $$CouplesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get originDeviceId => $composableBuilder(
      column: $table.originDeviceId,
      builder: (column) => ColumnOrderings(column));

  $$EventsTableOrderingComposer get eventId {
    final $$EventsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.eventId,
        referencedTable: $db.events,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventsTableOrderingComposer(
              $db: $db,
              $table: $db.events,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AttendeesTableOrderingComposer get attendeeAId {
    final $$AttendeesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.attendeeAId,
        referencedTable: $db.attendees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AttendeesTableOrderingComposer(
              $db: $db,
              $table: $db.attendees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AttendeesTableOrderingComposer get attendeeBId {
    final $$AttendeesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.attendeeBId,
        referencedTable: $db.attendees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AttendeesTableOrderingComposer(
              $db: $db,
              $table: $db.attendees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CouplesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CouplesTable> {
  $$CouplesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get originDeviceId => $composableBuilder(
      column: $table.originDeviceId, builder: (column) => column);

  $$EventsTableAnnotationComposer get eventId {
    final $$EventsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.eventId,
        referencedTable: $db.events,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventsTableAnnotationComposer(
              $db: $db,
              $table: $db.events,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AttendeesTableAnnotationComposer get attendeeAId {
    final $$AttendeesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.attendeeAId,
        referencedTable: $db.attendees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AttendeesTableAnnotationComposer(
              $db: $db,
              $table: $db.attendees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AttendeesTableAnnotationComposer get attendeeBId {
    final $$AttendeesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.attendeeBId,
        referencedTable: $db.attendees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AttendeesTableAnnotationComposer(
              $db: $db,
              $table: $db.attendees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CouplesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CouplesTable,
    Couple,
    $$CouplesTableFilterComposer,
    $$CouplesTableOrderingComposer,
    $$CouplesTableAnnotationComposer,
    $$CouplesTableCreateCompanionBuilder,
    $$CouplesTableUpdateCompanionBuilder,
    (Couple, $$CouplesTableReferences),
    Couple,
    PrefetchHooks Function(
        {bool eventId, bool attendeeAId, bool attendeeBId})> {
  $$CouplesTableTableManager(_$AppDatabase db, $CouplesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CouplesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CouplesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CouplesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> originDeviceId = const Value.absent(),
            Value<String> eventId = const Value.absent(),
            Value<String> attendeeAId = const Value.absent(),
            Value<String> attendeeBId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CouplesCompanion(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            originDeviceId: originDeviceId,
            eventId: eventId,
            attendeeAId: attendeeAId,
            attendeeBId: attendeeBId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            required String originDeviceId,
            required String eventId,
            required String attendeeAId,
            required String attendeeBId,
            Value<int> rowid = const Value.absent(),
          }) =>
              CouplesCompanion.insert(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            originDeviceId: originDeviceId,
            eventId: eventId,
            attendeeAId: attendeeAId,
            attendeeBId: attendeeBId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$CouplesTable, Couple>(table),
                    $$CouplesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {eventId = false, attendeeAId = false, attendeeBId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (eventId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.eventId,
                    referencedTable: $$CouplesTableReferences._eventIdTable(db),
                    referencedColumn:
                        $$CouplesTableReferences._eventIdTable(db).id,
                  ) as T;
                }
                if (attendeeAId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.attendeeAId,
                    referencedTable:
                        $$CouplesTableReferences._attendeeAIdTable(db),
                    referencedColumn:
                        $$CouplesTableReferences._attendeeAIdTable(db).id,
                  ) as T;
                }
                if (attendeeBId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.attendeeBId,
                    referencedTable:
                        $$CouplesTableReferences._attendeeBIdTable(db),
                    referencedColumn:
                        $$CouplesTableReferences._attendeeBIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$CouplesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CouplesTable,
    Couple,
    $$CouplesTableFilterComposer,
    $$CouplesTableOrderingComposer,
    $$CouplesTableAnnotationComposer,
    $$CouplesTableCreateCompanionBuilder,
    $$CouplesTableUpdateCompanionBuilder,
    (Couple, $$CouplesTableReferences),
    Couple,
    PrefetchHooks Function({bool eventId, bool attendeeAId, bool attendeeBId})>;
typedef $$AttendeeGroupsTableCreateCompanionBuilder = AttendeeGroupsCompanion
    Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  required String originDeviceId,
  required String eventId,
  required String name,
  Value<String> reason,
  Value<bool> keepTogether,
  Value<int> rowid,
});
typedef $$AttendeeGroupsTableUpdateCompanionBuilder = AttendeeGroupsCompanion
    Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> originDeviceId,
  Value<String> eventId,
  Value<String> name,
  Value<String> reason,
  Value<bool> keepTogether,
  Value<int> rowid,
});

final class $$AttendeeGroupsTableReferences
    extends BaseReferences<_$AppDatabase, $AttendeeGroupsTable, AttendeeGroup> {
  $$AttendeeGroupsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $EventsTable _eventIdTable(_$AppDatabase db) =>
      db.events.createAlias('attendee_groups__event_id__events__id');

  $$EventsTableProcessedTableManager get eventId {
    final $_column = $_itemColumn<String>('event_id')!;

    final manager = $$EventsTableTableManager($_db, $_db.events)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$GroupMembersTable, List<GroupMember>>
      _groupMembersRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.groupMembers,
              aliasName: 'attendee_groups__id__group_members__group_id');

  $$GroupMembersTableProcessedTableManager get groupMembersRefs {
    final manager = $$GroupMembersTableTableManager($_db, $_db.groupMembers)
        .filter((f) => f.groupId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_groupMembersRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$AttendeeGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $AttendeeGroupsTable> {
  $$AttendeeGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get originDeviceId => $composableBuilder(
      column: $table.originDeviceId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get keepTogether => $composableBuilder(
      column: $table.keepTogether, builder: (column) => ColumnFilters(column));

  $$EventsTableFilterComposer get eventId {
    final $$EventsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.eventId,
        referencedTable: $db.events,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventsTableFilterComposer(
              $db: $db,
              $table: $db.events,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> groupMembersRefs(
      Expression<bool> Function($$GroupMembersTableFilterComposer f) f) {
    final $$GroupMembersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.groupMembers,
        getReferencedColumn: (t) => t.groupId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GroupMembersTableFilterComposer(
              $db: $db,
              $table: $db.groupMembers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AttendeeGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttendeeGroupsTable> {
  $$AttendeeGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get originDeviceId => $composableBuilder(
      column: $table.originDeviceId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get keepTogether => $composableBuilder(
      column: $table.keepTogether,
      builder: (column) => ColumnOrderings(column));

  $$EventsTableOrderingComposer get eventId {
    final $$EventsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.eventId,
        referencedTable: $db.events,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventsTableOrderingComposer(
              $db: $db,
              $table: $db.events,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AttendeeGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttendeeGroupsTable> {
  $$AttendeeGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get originDeviceId => $composableBuilder(
      column: $table.originDeviceId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<bool> get keepTogether => $composableBuilder(
      column: $table.keepTogether, builder: (column) => column);

  $$EventsTableAnnotationComposer get eventId {
    final $$EventsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.eventId,
        referencedTable: $db.events,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventsTableAnnotationComposer(
              $db: $db,
              $table: $db.events,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> groupMembersRefs<T extends Object>(
      Expression<T> Function($$GroupMembersTableAnnotationComposer a) f) {
    final $$GroupMembersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.groupMembers,
        getReferencedColumn: (t) => t.groupId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GroupMembersTableAnnotationComposer(
              $db: $db,
              $table: $db.groupMembers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AttendeeGroupsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AttendeeGroupsTable,
    AttendeeGroup,
    $$AttendeeGroupsTableFilterComposer,
    $$AttendeeGroupsTableOrderingComposer,
    $$AttendeeGroupsTableAnnotationComposer,
    $$AttendeeGroupsTableCreateCompanionBuilder,
    $$AttendeeGroupsTableUpdateCompanionBuilder,
    (AttendeeGroup, $$AttendeeGroupsTableReferences),
    AttendeeGroup,
    PrefetchHooks Function({bool eventId, bool groupMembersRefs})> {
  $$AttendeeGroupsTableTableManager(
      _$AppDatabase db, $AttendeeGroupsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttendeeGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttendeeGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttendeeGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> originDeviceId = const Value.absent(),
            Value<String> eventId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> reason = const Value.absent(),
            Value<bool> keepTogether = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AttendeeGroupsCompanion(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            originDeviceId: originDeviceId,
            eventId: eventId,
            name: name,
            reason: reason,
            keepTogether: keepTogether,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            required String originDeviceId,
            required String eventId,
            required String name,
            Value<String> reason = const Value.absent(),
            Value<bool> keepTogether = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AttendeeGroupsCompanion.insert(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            originDeviceId: originDeviceId,
            eventId: eventId,
            name: name,
            reason: reason,
            keepTogether: keepTogether,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$AttendeeGroupsTable, AttendeeGroup>(table),
                    $$AttendeeGroupsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({eventId = false, groupMembersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (groupMembersRefs) db.groupMembers],
              addJoins: <
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
                      dynamic>>(state) {
                if (eventId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.eventId,
                    referencedTable:
                        $$AttendeeGroupsTableReferences._eventIdTable(db),
                    referencedColumn:
                        $$AttendeeGroupsTableReferences._eventIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (groupMembersRefs)
                    await $_getPrefetchedDataByColumns<
                            AttendeeGroup,
                            $AttendeeGroupsTable,
                            GroupMember,
                            $GroupMembersTable>(
                        currentTable: table,
                        referencedTable: $$AttendeeGroupsTableReferences
                            ._groupMembersRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AttendeeGroupsTableReferences(db, table, p0)
                                .groupMembersRefs,
                        currentColumn: 'id',
                        referencedColumn: 'group_id',
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$AttendeeGroupsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AttendeeGroupsTable,
    AttendeeGroup,
    $$AttendeeGroupsTableFilterComposer,
    $$AttendeeGroupsTableOrderingComposer,
    $$AttendeeGroupsTableAnnotationComposer,
    $$AttendeeGroupsTableCreateCompanionBuilder,
    $$AttendeeGroupsTableUpdateCompanionBuilder,
    (AttendeeGroup, $$AttendeeGroupsTableReferences),
    AttendeeGroup,
    PrefetchHooks Function({bool eventId, bool groupMembersRefs})>;
typedef $$GroupMembersTableCreateCompanionBuilder = GroupMembersCompanion
    Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  required String originDeviceId,
  required String groupId,
  required String attendeeId,
  Value<int> rowid,
});
typedef $$GroupMembersTableUpdateCompanionBuilder = GroupMembersCompanion
    Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> originDeviceId,
  Value<String> groupId,
  Value<String> attendeeId,
  Value<int> rowid,
});

final class $$GroupMembersTableReferences
    extends BaseReferences<_$AppDatabase, $GroupMembersTable, GroupMember> {
  $$GroupMembersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AttendeeGroupsTable _groupIdTable(_$AppDatabase db) =>
      db.attendeeGroups
          .createAlias('group_members__group_id__attendee_groups__id');

  $$AttendeeGroupsTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<String>('group_id')!;

    final manager = $$AttendeeGroupsTableTableManager($_db, $_db.attendeeGroups)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $AttendeesTable _attendeeIdTable(_$AppDatabase db) =>
      db.attendees.createAlias('group_members__attendee_id__attendees__id');

  $$AttendeesTableProcessedTableManager get attendeeId {
    final $_column = $_itemColumn<String>('attendee_id')!;

    final manager = $$AttendeesTableTableManager($_db, $_db.attendees)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_attendeeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$GroupMembersTableFilterComposer
    extends Composer<_$AppDatabase, $GroupMembersTable> {
  $$GroupMembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get originDeviceId => $composableBuilder(
      column: $table.originDeviceId,
      builder: (column) => ColumnFilters(column));

  $$AttendeeGroupsTableFilterComposer get groupId {
    final $$AttendeeGroupsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.groupId,
        referencedTable: $db.attendeeGroups,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AttendeeGroupsTableFilterComposer(
              $db: $db,
              $table: $db.attendeeGroups,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AttendeesTableFilterComposer get attendeeId {
    final $$AttendeesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.attendeeId,
        referencedTable: $db.attendees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AttendeesTableFilterComposer(
              $db: $db,
              $table: $db.attendees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GroupMembersTableOrderingComposer
    extends Composer<_$AppDatabase, $GroupMembersTable> {
  $$GroupMembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get originDeviceId => $composableBuilder(
      column: $table.originDeviceId,
      builder: (column) => ColumnOrderings(column));

  $$AttendeeGroupsTableOrderingComposer get groupId {
    final $$AttendeeGroupsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.groupId,
        referencedTable: $db.attendeeGroups,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AttendeeGroupsTableOrderingComposer(
              $db: $db,
              $table: $db.attendeeGroups,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AttendeesTableOrderingComposer get attendeeId {
    final $$AttendeesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.attendeeId,
        referencedTable: $db.attendees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AttendeesTableOrderingComposer(
              $db: $db,
              $table: $db.attendees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GroupMembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $GroupMembersTable> {
  $$GroupMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get originDeviceId => $composableBuilder(
      column: $table.originDeviceId, builder: (column) => column);

  $$AttendeeGroupsTableAnnotationComposer get groupId {
    final $$AttendeeGroupsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.groupId,
        referencedTable: $db.attendeeGroups,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AttendeeGroupsTableAnnotationComposer(
              $db: $db,
              $table: $db.attendeeGroups,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AttendeesTableAnnotationComposer get attendeeId {
    final $$AttendeesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.attendeeId,
        referencedTable: $db.attendees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AttendeesTableAnnotationComposer(
              $db: $db,
              $table: $db.attendees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GroupMembersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GroupMembersTable,
    GroupMember,
    $$GroupMembersTableFilterComposer,
    $$GroupMembersTableOrderingComposer,
    $$GroupMembersTableAnnotationComposer,
    $$GroupMembersTableCreateCompanionBuilder,
    $$GroupMembersTableUpdateCompanionBuilder,
    (GroupMember, $$GroupMembersTableReferences),
    GroupMember,
    PrefetchHooks Function({bool groupId, bool attendeeId})> {
  $$GroupMembersTableTableManager(_$AppDatabase db, $GroupMembersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupMembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupMembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupMembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> originDeviceId = const Value.absent(),
            Value<String> groupId = const Value.absent(),
            Value<String> attendeeId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GroupMembersCompanion(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            originDeviceId: originDeviceId,
            groupId: groupId,
            attendeeId: attendeeId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            required String originDeviceId,
            required String groupId,
            required String attendeeId,
            Value<int> rowid = const Value.absent(),
          }) =>
              GroupMembersCompanion.insert(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            originDeviceId: originDeviceId,
            groupId: groupId,
            attendeeId: attendeeId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$GroupMembersTable, GroupMember>(table),
                    $$GroupMembersTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({groupId = false, attendeeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (groupId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.groupId,
                    referencedTable:
                        $$GroupMembersTableReferences._groupIdTable(db),
                    referencedColumn:
                        $$GroupMembersTableReferences._groupIdTable(db).id,
                  ) as T;
                }
                if (attendeeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.attendeeId,
                    referencedTable:
                        $$GroupMembersTableReferences._attendeeIdTable(db),
                    referencedColumn:
                        $$GroupMembersTableReferences._attendeeIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$GroupMembersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GroupMembersTable,
    GroupMember,
    $$GroupMembersTableFilterComposer,
    $$GroupMembersTableOrderingComposer,
    $$GroupMembersTableAnnotationComposer,
    $$GroupMembersTableCreateCompanionBuilder,
    $$GroupMembersTableUpdateCompanionBuilder,
    (GroupMember, $$GroupMembersTableReferences),
    GroupMember,
    PrefetchHooks Function({bool groupId, bool attendeeId})>;
typedef $$LodgingsTableCreateCompanionBuilder = LodgingsCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  required String originDeviceId,
  required String eventId,
  required String name,
  required String kind,
  Value<String?> contactPhone,
  Value<String> directions,
  required int capacity,
  required String accepts,
  Value<String?> hostName,
  Value<String> distanceNote,
  Value<int> rowid,
});
typedef $$LodgingsTableUpdateCompanionBuilder = LodgingsCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> originDeviceId,
  Value<String> eventId,
  Value<String> name,
  Value<String> kind,
  Value<String?> contactPhone,
  Value<String> directions,
  Value<int> capacity,
  Value<String> accepts,
  Value<String?> hostName,
  Value<String> distanceNote,
  Value<int> rowid,
});

final class $$LodgingsTableReferences
    extends BaseReferences<_$AppDatabase, $LodgingsTable, LodgingRow> {
  $$LodgingsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EventsTable _eventIdTable(_$AppDatabase db) =>
      db.events.createAlias('lodgings__event_id__events__id');

  $$EventsTableProcessedTableManager get eventId {
    final $_column = $_itemColumn<String>('event_id')!;

    final manager = $$EventsTableTableManager($_db, $_db.events)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$LodgingsTableFilterComposer
    extends Composer<_$AppDatabase, $LodgingsTable> {
  $$LodgingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get originDeviceId => $composableBuilder(
      column: $table.originDeviceId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contactPhone => $composableBuilder(
      column: $table.contactPhone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get directions => $composableBuilder(
      column: $table.directions, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get capacity => $composableBuilder(
      column: $table.capacity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get accepts => $composableBuilder(
      column: $table.accepts, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hostName => $composableBuilder(
      column: $table.hostName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get distanceNote => $composableBuilder(
      column: $table.distanceNote, builder: (column) => ColumnFilters(column));

  $$EventsTableFilterComposer get eventId {
    final $$EventsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.eventId,
        referencedTable: $db.events,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventsTableFilterComposer(
              $db: $db,
              $table: $db.events,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LodgingsTableOrderingComposer
    extends Composer<_$AppDatabase, $LodgingsTable> {
  $$LodgingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get originDeviceId => $composableBuilder(
      column: $table.originDeviceId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contactPhone => $composableBuilder(
      column: $table.contactPhone,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get directions => $composableBuilder(
      column: $table.directions, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get capacity => $composableBuilder(
      column: $table.capacity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get accepts => $composableBuilder(
      column: $table.accepts, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hostName => $composableBuilder(
      column: $table.hostName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get distanceNote => $composableBuilder(
      column: $table.distanceNote,
      builder: (column) => ColumnOrderings(column));

  $$EventsTableOrderingComposer get eventId {
    final $$EventsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.eventId,
        referencedTable: $db.events,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventsTableOrderingComposer(
              $db: $db,
              $table: $db.events,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LodgingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LodgingsTable> {
  $$LodgingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get originDeviceId => $composableBuilder(
      column: $table.originDeviceId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get contactPhone => $composableBuilder(
      column: $table.contactPhone, builder: (column) => column);

  GeneratedColumn<String> get directions => $composableBuilder(
      column: $table.directions, builder: (column) => column);

  GeneratedColumn<int> get capacity =>
      $composableBuilder(column: $table.capacity, builder: (column) => column);

  GeneratedColumn<String> get accepts =>
      $composableBuilder(column: $table.accepts, builder: (column) => column);

  GeneratedColumn<String> get hostName =>
      $composableBuilder(column: $table.hostName, builder: (column) => column);

  GeneratedColumn<String> get distanceNote => $composableBuilder(
      column: $table.distanceNote, builder: (column) => column);

  $$EventsTableAnnotationComposer get eventId {
    final $$EventsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.eventId,
        referencedTable: $db.events,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventsTableAnnotationComposer(
              $db: $db,
              $table: $db.events,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LodgingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LodgingsTable,
    LodgingRow,
    $$LodgingsTableFilterComposer,
    $$LodgingsTableOrderingComposer,
    $$LodgingsTableAnnotationComposer,
    $$LodgingsTableCreateCompanionBuilder,
    $$LodgingsTableUpdateCompanionBuilder,
    (LodgingRow, $$LodgingsTableReferences),
    LodgingRow,
    PrefetchHooks Function({bool eventId})> {
  $$LodgingsTableTableManager(_$AppDatabase db, $LodgingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LodgingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LodgingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LodgingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> originDeviceId = const Value.absent(),
            Value<String> eventId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<String?> contactPhone = const Value.absent(),
            Value<String> directions = const Value.absent(),
            Value<int> capacity = const Value.absent(),
            Value<String> accepts = const Value.absent(),
            Value<String?> hostName = const Value.absent(),
            Value<String> distanceNote = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LodgingsCompanion(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            originDeviceId: originDeviceId,
            eventId: eventId,
            name: name,
            kind: kind,
            contactPhone: contactPhone,
            directions: directions,
            capacity: capacity,
            accepts: accepts,
            hostName: hostName,
            distanceNote: distanceNote,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            required String originDeviceId,
            required String eventId,
            required String name,
            required String kind,
            Value<String?> contactPhone = const Value.absent(),
            Value<String> directions = const Value.absent(),
            required int capacity,
            required String accepts,
            Value<String?> hostName = const Value.absent(),
            Value<String> distanceNote = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LodgingsCompanion.insert(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            originDeviceId: originDeviceId,
            eventId: eventId,
            name: name,
            kind: kind,
            contactPhone: contactPhone,
            directions: directions,
            capacity: capacity,
            accepts: accepts,
            hostName: hostName,
            distanceNote: distanceNote,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$LodgingsTable, LodgingRow>(table),
                    $$LodgingsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({eventId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (eventId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.eventId,
                    referencedTable:
                        $$LodgingsTableReferences._eventIdTable(db),
                    referencedColumn:
                        $$LodgingsTableReferences._eventIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$LodgingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LodgingsTable,
    LodgingRow,
    $$LodgingsTableFilterComposer,
    $$LodgingsTableOrderingComposer,
    $$LodgingsTableAnnotationComposer,
    $$LodgingsTableCreateCompanionBuilder,
    $$LodgingsTableUpdateCompanionBuilder,
    (LodgingRow, $$LodgingsTableReferences),
    LodgingRow,
    PrefetchHooks Function({bool eventId})>;
typedef $$TeamsTableCreateCompanionBuilder = TeamsCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  required String originDeviceId,
  required String eventId,
  required String name,
  Value<String?> color,
  Value<String?> captainId,
  Value<int> sortOrder,
  Value<int> rowid,
});
typedef $$TeamsTableUpdateCompanionBuilder = TeamsCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> originDeviceId,
  Value<String> eventId,
  Value<String> name,
  Value<String?> color,
  Value<String?> captainId,
  Value<int> sortOrder,
  Value<int> rowid,
});

final class $$TeamsTableReferences
    extends BaseReferences<_$AppDatabase, $TeamsTable, TeamRow> {
  $$TeamsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EventsTable _eventIdTable(_$AppDatabase db) =>
      db.events.createAlias('teams__event_id__events__id');

  $$EventsTableProcessedTableManager get eventId {
    final $_column = $_itemColumn<String>('event_id')!;

    final manager = $$EventsTableTableManager($_db, $_db.events)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
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
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get originDeviceId => $composableBuilder(
      column: $table.originDeviceId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get captainId => $composableBuilder(
      column: $table.captainId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  $$EventsTableFilterComposer get eventId {
    final $$EventsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.eventId,
        referencedTable: $db.events,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventsTableFilterComposer(
              $db: $db,
              $table: $db.events,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
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
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get originDeviceId => $composableBuilder(
      column: $table.originDeviceId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get captainId => $composableBuilder(
      column: $table.captainId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  $$EventsTableOrderingComposer get eventId {
    final $$EventsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.eventId,
        referencedTable: $db.events,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventsTableOrderingComposer(
              $db: $db,
              $table: $db.events,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
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

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get originDeviceId => $composableBuilder(
      column: $table.originDeviceId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get captainId =>
      $composableBuilder(column: $table.captainId, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$EventsTableAnnotationComposer get eventId {
    final $$EventsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.eventId,
        referencedTable: $db.events,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventsTableAnnotationComposer(
              $db: $db,
              $table: $db.events,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TeamsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TeamsTable,
    TeamRow,
    $$TeamsTableFilterComposer,
    $$TeamsTableOrderingComposer,
    $$TeamsTableAnnotationComposer,
    $$TeamsTableCreateCompanionBuilder,
    $$TeamsTableUpdateCompanionBuilder,
    (TeamRow, $$TeamsTableReferences),
    TeamRow,
    PrefetchHooks Function({bool eventId})> {
  $$TeamsTableTableManager(_$AppDatabase db, $TeamsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TeamsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TeamsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TeamsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> originDeviceId = const Value.absent(),
            Value<String> eventId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> color = const Value.absent(),
            Value<String?> captainId = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TeamsCompanion(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            originDeviceId: originDeviceId,
            eventId: eventId,
            name: name,
            color: color,
            captainId: captainId,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            required String originDeviceId,
            required String eventId,
            required String name,
            Value<String?> color = const Value.absent(),
            Value<String?> captainId = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TeamsCompanion.insert(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            originDeviceId: originDeviceId,
            eventId: eventId,
            name: name,
            color: color,
            captainId: captainId,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$TeamsTable, TeamRow>(table),
                    $$TeamsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({eventId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (eventId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.eventId,
                    referencedTable: $$TeamsTableReferences._eventIdTable(db),
                    referencedColumn:
                        $$TeamsTableReferences._eventIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$TeamsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TeamsTable,
    TeamRow,
    $$TeamsTableFilterComposer,
    $$TeamsTableOrderingComposer,
    $$TeamsTableAnnotationComposer,
    $$TeamsTableCreateCompanionBuilder,
    $$TeamsTableUpdateCompanionBuilder,
    (TeamRow, $$TeamsTableReferences),
    TeamRow,
    PrefetchHooks Function({bool eventId})>;
typedef $$ControlTypesTableCreateCompanionBuilder = ControlTypesCompanion
    Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  required String originDeviceId,
  required String eventId,
  required String name,
  Value<int> sortOrder,
  Value<int> rowid,
});
typedef $$ControlTypesTableUpdateCompanionBuilder = ControlTypesCompanion
    Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> originDeviceId,
  Value<String> eventId,
  Value<String> name,
  Value<int> sortOrder,
  Value<int> rowid,
});

final class $$ControlTypesTableReferences
    extends BaseReferences<_$AppDatabase, $ControlTypesTable, ControlType> {
  $$ControlTypesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EventsTable _eventIdTable(_$AppDatabase db) =>
      db.events.createAlias('control_types__event_id__events__id');

  $$EventsTableProcessedTableManager get eventId {
    final $_column = $_itemColumn<String>('event_id')!;

    final manager = $$EventsTableTableManager($_db, $_db.events)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$ControlSessionsTable, List<ControlSession>>
      _controlSessionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.controlSessions,
              aliasName:
                  'control_types__id__control_sessions__control_type_id');

  $$ControlSessionsTableProcessedTableManager get controlSessionsRefs {
    final manager =
        $$ControlSessionsTableTableManager($_db, $_db.controlSessions).filter(
            (f) => f.controlTypeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_controlSessionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ControlTypesTableFilterComposer
    extends Composer<_$AppDatabase, $ControlTypesTable> {
  $$ControlTypesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get originDeviceId => $composableBuilder(
      column: $table.originDeviceId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  $$EventsTableFilterComposer get eventId {
    final $$EventsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.eventId,
        referencedTable: $db.events,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventsTableFilterComposer(
              $db: $db,
              $table: $db.events,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> controlSessionsRefs(
      Expression<bool> Function($$ControlSessionsTableFilterComposer f) f) {
    final $$ControlSessionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.controlSessions,
        getReferencedColumn: (t) => t.controlTypeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ControlSessionsTableFilterComposer(
              $db: $db,
              $table: $db.controlSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ControlTypesTableOrderingComposer
    extends Composer<_$AppDatabase, $ControlTypesTable> {
  $$ControlTypesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get originDeviceId => $composableBuilder(
      column: $table.originDeviceId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  $$EventsTableOrderingComposer get eventId {
    final $$EventsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.eventId,
        referencedTable: $db.events,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventsTableOrderingComposer(
              $db: $db,
              $table: $db.events,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ControlTypesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ControlTypesTable> {
  $$ControlTypesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get originDeviceId => $composableBuilder(
      column: $table.originDeviceId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$EventsTableAnnotationComposer get eventId {
    final $$EventsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.eventId,
        referencedTable: $db.events,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventsTableAnnotationComposer(
              $db: $db,
              $table: $db.events,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> controlSessionsRefs<T extends Object>(
      Expression<T> Function($$ControlSessionsTableAnnotationComposer a) f) {
    final $$ControlSessionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.controlSessions,
        getReferencedColumn: (t) => t.controlTypeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ControlSessionsTableAnnotationComposer(
              $db: $db,
              $table: $db.controlSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ControlTypesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ControlTypesTable,
    ControlType,
    $$ControlTypesTableFilterComposer,
    $$ControlTypesTableOrderingComposer,
    $$ControlTypesTableAnnotationComposer,
    $$ControlTypesTableCreateCompanionBuilder,
    $$ControlTypesTableUpdateCompanionBuilder,
    (ControlType, $$ControlTypesTableReferences),
    ControlType,
    PrefetchHooks Function({bool eventId, bool controlSessionsRefs})> {
  $$ControlTypesTableTableManager(_$AppDatabase db, $ControlTypesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ControlTypesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ControlTypesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ControlTypesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> originDeviceId = const Value.absent(),
            Value<String> eventId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ControlTypesCompanion(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            originDeviceId: originDeviceId,
            eventId: eventId,
            name: name,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            required String originDeviceId,
            required String eventId,
            required String name,
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ControlTypesCompanion.insert(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            originDeviceId: originDeviceId,
            eventId: eventId,
            name: name,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$ControlTypesTable, ControlType>(table),
                    $$ControlTypesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {eventId = false, controlSessionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (controlSessionsRefs) db.controlSessions
              ],
              addJoins: <
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
                      dynamic>>(state) {
                if (eventId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.eventId,
                    referencedTable:
                        $$ControlTypesTableReferences._eventIdTable(db),
                    referencedColumn:
                        $$ControlTypesTableReferences._eventIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (controlSessionsRefs)
                    await $_getPrefetchedDataByColumns<
                            ControlType,
                            $ControlTypesTable,
                            ControlSession,
                            $ControlSessionsTable>(
                        currentTable: table,
                        referencedTable: $$ControlTypesTableReferences
                            ._controlSessionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ControlTypesTableReferences(db, table, p0)
                                .controlSessionsRefs,
                        currentColumn: 'id',
                        referencedColumn: 'control_type_id',
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ControlTypesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ControlTypesTable,
    ControlType,
    $$ControlTypesTableFilterComposer,
    $$ControlTypesTableOrderingComposer,
    $$ControlTypesTableAnnotationComposer,
    $$ControlTypesTableCreateCompanionBuilder,
    $$ControlTypesTableUpdateCompanionBuilder,
    (ControlType, $$ControlTypesTableReferences),
    ControlType,
    PrefetchHooks Function({bool eventId, bool controlSessionsRefs})>;
typedef $$ControlSessionsTableCreateCompanionBuilder = ControlSessionsCompanion
    Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  required String originDeviceId,
  required String eventId,
  required String controlTypeId,
  required String name,
  Value<DateTime?> scheduledAt,
  Value<DateTime?> openedAt,
  Value<DateTime?> closedAt,
  Value<String> operatorName,
  Value<int> blockedRepeats,
  Value<int> rowid,
});
typedef $$ControlSessionsTableUpdateCompanionBuilder = ControlSessionsCompanion
    Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> originDeviceId,
  Value<String> eventId,
  Value<String> controlTypeId,
  Value<String> name,
  Value<DateTime?> scheduledAt,
  Value<DateTime?> openedAt,
  Value<DateTime?> closedAt,
  Value<String> operatorName,
  Value<int> blockedRepeats,
  Value<int> rowid,
});

final class $$ControlSessionsTableReferences extends BaseReferences<
    _$AppDatabase, $ControlSessionsTable, ControlSession> {
  $$ControlSessionsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $EventsTable _eventIdTable(_$AppDatabase db) =>
      db.events.createAlias('control_sessions__event_id__events__id');

  $$EventsTableProcessedTableManager get eventId {
    final $_column = $_itemColumn<String>('event_id')!;

    final manager = $$EventsTableTableManager($_db, $_db.events)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ControlTypesTable _controlTypeIdTable(_$AppDatabase db) =>
      db.controlTypes
          .createAlias('control_sessions__control_type_id__control_types__id');

  $$ControlTypesTableProcessedTableManager get controlTypeId {
    final $_column = $_itemColumn<String>('control_type_id')!;

    final manager = $$ControlTypesTableTableManager($_db, $_db.controlTypes)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_controlTypeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$ControlRecordsTable, List<ControlRecord>>
      _controlRecordsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.controlRecords,
              aliasName: 'control_sessions__id__control_records__session_id');

  $$ControlRecordsTableProcessedTableManager get controlRecordsRefs {
    final manager = $$ControlRecordsTableTableManager($_db, $_db.controlRecords)
        .filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_controlRecordsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ControlSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $ControlSessionsTable> {
  $$ControlSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get originDeviceId => $composableBuilder(
      column: $table.originDeviceId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get scheduledAt => $composableBuilder(
      column: $table.scheduledAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get openedAt => $composableBuilder(
      column: $table.openedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get closedAt => $composableBuilder(
      column: $table.closedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get operatorName => $composableBuilder(
      column: $table.operatorName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get blockedRepeats => $composableBuilder(
      column: $table.blockedRepeats,
      builder: (column) => ColumnFilters(column));

  $$EventsTableFilterComposer get eventId {
    final $$EventsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.eventId,
        referencedTable: $db.events,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventsTableFilterComposer(
              $db: $db,
              $table: $db.events,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ControlTypesTableFilterComposer get controlTypeId {
    final $$ControlTypesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.controlTypeId,
        referencedTable: $db.controlTypes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ControlTypesTableFilterComposer(
              $db: $db,
              $table: $db.controlTypes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> controlRecordsRefs(
      Expression<bool> Function($$ControlRecordsTableFilterComposer f) f) {
    final $$ControlRecordsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.controlRecords,
        getReferencedColumn: (t) => t.sessionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ControlRecordsTableFilterComposer(
              $db: $db,
              $table: $db.controlRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ControlSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ControlSessionsTable> {
  $$ControlSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get originDeviceId => $composableBuilder(
      column: $table.originDeviceId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get scheduledAt => $composableBuilder(
      column: $table.scheduledAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get openedAt => $composableBuilder(
      column: $table.openedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get closedAt => $composableBuilder(
      column: $table.closedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get operatorName => $composableBuilder(
      column: $table.operatorName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get blockedRepeats => $composableBuilder(
      column: $table.blockedRepeats,
      builder: (column) => ColumnOrderings(column));

  $$EventsTableOrderingComposer get eventId {
    final $$EventsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.eventId,
        referencedTable: $db.events,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventsTableOrderingComposer(
              $db: $db,
              $table: $db.events,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ControlTypesTableOrderingComposer get controlTypeId {
    final $$ControlTypesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.controlTypeId,
        referencedTable: $db.controlTypes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ControlTypesTableOrderingComposer(
              $db: $db,
              $table: $db.controlTypes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ControlSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ControlSessionsTable> {
  $$ControlSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get originDeviceId => $composableBuilder(
      column: $table.originDeviceId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledAt => $composableBuilder(
      column: $table.scheduledAt, builder: (column) => column);

  GeneratedColumn<DateTime> get openedAt =>
      $composableBuilder(column: $table.openedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get closedAt =>
      $composableBuilder(column: $table.closedAt, builder: (column) => column);

  GeneratedColumn<String> get operatorName => $composableBuilder(
      column: $table.operatorName, builder: (column) => column);

  GeneratedColumn<int> get blockedRepeats => $composableBuilder(
      column: $table.blockedRepeats, builder: (column) => column);

  $$EventsTableAnnotationComposer get eventId {
    final $$EventsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.eventId,
        referencedTable: $db.events,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EventsTableAnnotationComposer(
              $db: $db,
              $table: $db.events,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ControlTypesTableAnnotationComposer get controlTypeId {
    final $$ControlTypesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.controlTypeId,
        referencedTable: $db.controlTypes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ControlTypesTableAnnotationComposer(
              $db: $db,
              $table: $db.controlTypes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> controlRecordsRefs<T extends Object>(
      Expression<T> Function($$ControlRecordsTableAnnotationComposer a) f) {
    final $$ControlRecordsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.controlRecords,
        getReferencedColumn: (t) => t.sessionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ControlRecordsTableAnnotationComposer(
              $db: $db,
              $table: $db.controlRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ControlSessionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ControlSessionsTable,
    ControlSession,
    $$ControlSessionsTableFilterComposer,
    $$ControlSessionsTableOrderingComposer,
    $$ControlSessionsTableAnnotationComposer,
    $$ControlSessionsTableCreateCompanionBuilder,
    $$ControlSessionsTableUpdateCompanionBuilder,
    (ControlSession, $$ControlSessionsTableReferences),
    ControlSession,
    PrefetchHooks Function(
        {bool eventId, bool controlTypeId, bool controlRecordsRefs})> {
  $$ControlSessionsTableTableManager(
      _$AppDatabase db, $ControlSessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ControlSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ControlSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ControlSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> originDeviceId = const Value.absent(),
            Value<String> eventId = const Value.absent(),
            Value<String> controlTypeId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<DateTime?> scheduledAt = const Value.absent(),
            Value<DateTime?> openedAt = const Value.absent(),
            Value<DateTime?> closedAt = const Value.absent(),
            Value<String> operatorName = const Value.absent(),
            Value<int> blockedRepeats = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ControlSessionsCompanion(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            originDeviceId: originDeviceId,
            eventId: eventId,
            controlTypeId: controlTypeId,
            name: name,
            scheduledAt: scheduledAt,
            openedAt: openedAt,
            closedAt: closedAt,
            operatorName: operatorName,
            blockedRepeats: blockedRepeats,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            required String originDeviceId,
            required String eventId,
            required String controlTypeId,
            required String name,
            Value<DateTime?> scheduledAt = const Value.absent(),
            Value<DateTime?> openedAt = const Value.absent(),
            Value<DateTime?> closedAt = const Value.absent(),
            Value<String> operatorName = const Value.absent(),
            Value<int> blockedRepeats = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ControlSessionsCompanion.insert(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            originDeviceId: originDeviceId,
            eventId: eventId,
            controlTypeId: controlTypeId,
            name: name,
            scheduledAt: scheduledAt,
            openedAt: openedAt,
            closedAt: closedAt,
            operatorName: operatorName,
            blockedRepeats: blockedRepeats,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$ControlSessionsTable, ControlSession>(table),
                    $$ControlSessionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {eventId = false,
              controlTypeId = false,
              controlRecordsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (controlRecordsRefs) db.controlRecords
              ],
              addJoins: <
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
                      dynamic>>(state) {
                if (eventId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.eventId,
                    referencedTable:
                        $$ControlSessionsTableReferences._eventIdTable(db),
                    referencedColumn:
                        $$ControlSessionsTableReferences._eventIdTable(db).id,
                  ) as T;
                }
                if (controlTypeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.controlTypeId,
                    referencedTable: $$ControlSessionsTableReferences
                        ._controlTypeIdTable(db),
                    referencedColumn: $$ControlSessionsTableReferences
                        ._controlTypeIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (controlRecordsRefs)
                    await $_getPrefetchedDataByColumns<
                            ControlSession,
                            $ControlSessionsTable,
                            ControlRecord,
                            $ControlRecordsTable>(
                        currentTable: table,
                        referencedTable: $$ControlSessionsTableReferences
                            ._controlRecordsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ControlSessionsTableReferences(db, table, p0)
                                .controlRecordsRefs,
                        currentColumn: 'id',
                        referencedColumn: 'session_id',
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ControlSessionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ControlSessionsTable,
    ControlSession,
    $$ControlSessionsTableFilterComposer,
    $$ControlSessionsTableOrderingComposer,
    $$ControlSessionsTableAnnotationComposer,
    $$ControlSessionsTableCreateCompanionBuilder,
    $$ControlSessionsTableUpdateCompanionBuilder,
    (ControlSession, $$ControlSessionsTableReferences),
    ControlSession,
    PrefetchHooks Function(
        {bool eventId, bool controlTypeId, bool controlRecordsRefs})>;
typedef $$ControlRecordsTableCreateCompanionBuilder = ControlRecordsCompanion
    Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  required String originDeviceId,
  required String sessionId,
  required String attendeeId,
  required DateTime markedAt,
  Value<String> operatorName,
  Value<DateTime?> undoneAt,
  Value<bool> repeatOverride,
  Value<int> rowid,
});
typedef $$ControlRecordsTableUpdateCompanionBuilder = ControlRecordsCompanion
    Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> originDeviceId,
  Value<String> sessionId,
  Value<String> attendeeId,
  Value<DateTime> markedAt,
  Value<String> operatorName,
  Value<DateTime?> undoneAt,
  Value<bool> repeatOverride,
  Value<int> rowid,
});

final class $$ControlRecordsTableReferences
    extends BaseReferences<_$AppDatabase, $ControlRecordsTable, ControlRecord> {
  $$ControlRecordsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ControlSessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.controlSessions
          .createAlias('control_records__session_id__control_sessions__id');

  $$ControlSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager =
        $$ControlSessionsTableTableManager($_db, $_db.controlSessions)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $AttendeesTable _attendeeIdTable(_$AppDatabase db) =>
      db.attendees.createAlias('control_records__attendee_id__attendees__id');

  $$AttendeesTableProcessedTableManager get attendeeId {
    final $_column = $_itemColumn<String>('attendee_id')!;

    final manager = $$AttendeesTableTableManager($_db, $_db.attendees)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_attendeeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ControlRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $ControlRecordsTable> {
  $$ControlRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get originDeviceId => $composableBuilder(
      column: $table.originDeviceId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get markedAt => $composableBuilder(
      column: $table.markedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get operatorName => $composableBuilder(
      column: $table.operatorName, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get undoneAt => $composableBuilder(
      column: $table.undoneAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get repeatOverride => $composableBuilder(
      column: $table.repeatOverride,
      builder: (column) => ColumnFilters(column));

  $$ControlSessionsTableFilterComposer get sessionId {
    final $$ControlSessionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.controlSessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ControlSessionsTableFilterComposer(
              $db: $db,
              $table: $db.controlSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AttendeesTableFilterComposer get attendeeId {
    final $$AttendeesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.attendeeId,
        referencedTable: $db.attendees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AttendeesTableFilterComposer(
              $db: $db,
              $table: $db.attendees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ControlRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $ControlRecordsTable> {
  $$ControlRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get originDeviceId => $composableBuilder(
      column: $table.originDeviceId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get markedAt => $composableBuilder(
      column: $table.markedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get operatorName => $composableBuilder(
      column: $table.operatorName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get undoneAt => $composableBuilder(
      column: $table.undoneAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get repeatOverride => $composableBuilder(
      column: $table.repeatOverride,
      builder: (column) => ColumnOrderings(column));

  $$ControlSessionsTableOrderingComposer get sessionId {
    final $$ControlSessionsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.controlSessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ControlSessionsTableOrderingComposer(
              $db: $db,
              $table: $db.controlSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AttendeesTableOrderingComposer get attendeeId {
    final $$AttendeesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.attendeeId,
        referencedTable: $db.attendees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AttendeesTableOrderingComposer(
              $db: $db,
              $table: $db.attendees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ControlRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ControlRecordsTable> {
  $$ControlRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get originDeviceId => $composableBuilder(
      column: $table.originDeviceId, builder: (column) => column);

  GeneratedColumn<DateTime> get markedAt =>
      $composableBuilder(column: $table.markedAt, builder: (column) => column);

  GeneratedColumn<String> get operatorName => $composableBuilder(
      column: $table.operatorName, builder: (column) => column);

  GeneratedColumn<DateTime> get undoneAt =>
      $composableBuilder(column: $table.undoneAt, builder: (column) => column);

  GeneratedColumn<bool> get repeatOverride => $composableBuilder(
      column: $table.repeatOverride, builder: (column) => column);

  $$ControlSessionsTableAnnotationComposer get sessionId {
    final $$ControlSessionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.controlSessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ControlSessionsTableAnnotationComposer(
              $db: $db,
              $table: $db.controlSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AttendeesTableAnnotationComposer get attendeeId {
    final $$AttendeesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.attendeeId,
        referencedTable: $db.attendees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AttendeesTableAnnotationComposer(
              $db: $db,
              $table: $db.attendees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ControlRecordsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ControlRecordsTable,
    ControlRecord,
    $$ControlRecordsTableFilterComposer,
    $$ControlRecordsTableOrderingComposer,
    $$ControlRecordsTableAnnotationComposer,
    $$ControlRecordsTableCreateCompanionBuilder,
    $$ControlRecordsTableUpdateCompanionBuilder,
    (ControlRecord, $$ControlRecordsTableReferences),
    ControlRecord,
    PrefetchHooks Function({bool sessionId, bool attendeeId})> {
  $$ControlRecordsTableTableManager(
      _$AppDatabase db, $ControlRecordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ControlRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ControlRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ControlRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> originDeviceId = const Value.absent(),
            Value<String> sessionId = const Value.absent(),
            Value<String> attendeeId = const Value.absent(),
            Value<DateTime> markedAt = const Value.absent(),
            Value<String> operatorName = const Value.absent(),
            Value<DateTime?> undoneAt = const Value.absent(),
            Value<bool> repeatOverride = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ControlRecordsCompanion(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            originDeviceId: originDeviceId,
            sessionId: sessionId,
            attendeeId: attendeeId,
            markedAt: markedAt,
            operatorName: operatorName,
            undoneAt: undoneAt,
            repeatOverride: repeatOverride,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            required String originDeviceId,
            required String sessionId,
            required String attendeeId,
            required DateTime markedAt,
            Value<String> operatorName = const Value.absent(),
            Value<DateTime?> undoneAt = const Value.absent(),
            Value<bool> repeatOverride = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ControlRecordsCompanion.insert(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            originDeviceId: originDeviceId,
            sessionId: sessionId,
            attendeeId: attendeeId,
            markedAt: markedAt,
            operatorName: operatorName,
            undoneAt: undoneAt,
            repeatOverride: repeatOverride,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$ControlRecordsTable, ControlRecord>(table),
                    $$ControlRecordsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({sessionId = false, attendeeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (sessionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.sessionId,
                    referencedTable:
                        $$ControlRecordsTableReferences._sessionIdTable(db),
                    referencedColumn:
                        $$ControlRecordsTableReferences._sessionIdTable(db).id,
                  ) as T;
                }
                if (attendeeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.attendeeId,
                    referencedTable:
                        $$ControlRecordsTableReferences._attendeeIdTable(db),
                    referencedColumn:
                        $$ControlRecordsTableReferences._attendeeIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ControlRecordsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ControlRecordsTable,
    ControlRecord,
    $$ControlRecordsTableFilterComposer,
    $$ControlRecordsTableOrderingComposer,
    $$ControlRecordsTableAnnotationComposer,
    $$ControlRecordsTableCreateCompanionBuilder,
    $$ControlRecordsTableUpdateCompanionBuilder,
    (ControlRecord, $$ControlRecordsTableReferences),
    ControlRecord,
    PrefetchHooks Function({bool sessionId, bool attendeeId})>;
typedef $$AppMetaTableCreateCompanionBuilder = AppMetaCompanion Function({
  Value<int> key,
  required String deviceId,
  Value<String> deviceLabel,
  required int schemaVersion,
  Value<DateTime?> lastBackupAt,
  Value<String?> recoveryHash,
});
typedef $$AppMetaTableUpdateCompanionBuilder = AppMetaCompanion Function({
  Value<int> key,
  Value<String> deviceId,
  Value<String> deviceLabel,
  Value<int> schemaVersion,
  Value<DateTime?> lastBackupAt,
  Value<String?> recoveryHash,
});

class $$AppMetaTableFilterComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceLabel => $composableBuilder(
      column: $table.deviceLabel, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get schemaVersion => $composableBuilder(
      column: $table.schemaVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastBackupAt => $composableBuilder(
      column: $table.lastBackupAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recoveryHash => $composableBuilder(
      column: $table.recoveryHash, builder: (column) => ColumnFilters(column));
}

class $$AppMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceLabel => $composableBuilder(
      column: $table.deviceLabel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
      column: $table.schemaVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastBackupAt => $composableBuilder(
      column: $table.lastBackupAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recoveryHash => $composableBuilder(
      column: $table.recoveryHash,
      builder: (column) => ColumnOrderings(column));
}

class $$AppMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get deviceLabel => $composableBuilder(
      column: $table.deviceLabel, builder: (column) => column);

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
      column: $table.schemaVersion, builder: (column) => column);

  GeneratedColumn<DateTime> get lastBackupAt => $composableBuilder(
      column: $table.lastBackupAt, builder: (column) => column);

  GeneratedColumn<String> get recoveryHash => $composableBuilder(
      column: $table.recoveryHash, builder: (column) => column);
}

class $$AppMetaTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AppMetaTable,
    AppMetaData,
    $$AppMetaTableFilterComposer,
    $$AppMetaTableOrderingComposer,
    $$AppMetaTableAnnotationComposer,
    $$AppMetaTableCreateCompanionBuilder,
    $$AppMetaTableUpdateCompanionBuilder,
    (AppMetaData, BaseReferences<_$AppDatabase, $AppMetaTable, AppMetaData>),
    AppMetaData,
    PrefetchHooks Function()> {
  $$AppMetaTableTableManager(_$AppDatabase db, $AppMetaTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> key = const Value.absent(),
            Value<String> deviceId = const Value.absent(),
            Value<String> deviceLabel = const Value.absent(),
            Value<int> schemaVersion = const Value.absent(),
            Value<DateTime?> lastBackupAt = const Value.absent(),
            Value<String?> recoveryHash = const Value.absent(),
          }) =>
              AppMetaCompanion(
            key: key,
            deviceId: deviceId,
            deviceLabel: deviceLabel,
            schemaVersion: schemaVersion,
            lastBackupAt: lastBackupAt,
            recoveryHash: recoveryHash,
          ),
          createCompanionCallback: ({
            Value<int> key = const Value.absent(),
            required String deviceId,
            Value<String> deviceLabel = const Value.absent(),
            required int schemaVersion,
            Value<DateTime?> lastBackupAt = const Value.absent(),
            Value<String?> recoveryHash = const Value.absent(),
          }) =>
              AppMetaCompanion.insert(
            key: key,
            deviceId: deviceId,
            deviceLabel: deviceLabel,
            schemaVersion: schemaVersion,
            lastBackupAt: lastBackupAt,
            recoveryHash: recoveryHash,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$AppMetaTable, AppMetaData>(table),
                    BaseReferences<_$AppDatabase, $AppMetaTable, AppMetaData>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AppMetaTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AppMetaTable,
    AppMetaData,
    $$AppMetaTableFilterComposer,
    $$AppMetaTableOrderingComposer,
    $$AppMetaTableAnnotationComposer,
    $$AppMetaTableCreateCompanionBuilder,
    $$AppMetaTableUpdateCompanionBuilder,
    (AppMetaData, BaseReferences<_$AppDatabase, $AppMetaTable, AppMetaData>),
    AppMetaData,
    PrefetchHooks Function()>;
typedef $$AppUsersTableCreateCompanionBuilder = AppUsersCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  required String originDeviceId,
  required String username,
  required String displayName,
  required String role,
  required String passwordHash,
  Value<bool> active,
  Value<int> failedAttempts,
  Value<DateTime?> lockedUntil,
  Value<DateTime?> lastLoginAt,
  Value<int> rowid,
});
typedef $$AppUsersTableUpdateCompanionBuilder = AppUsersCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> originDeviceId,
  Value<String> username,
  Value<String> displayName,
  Value<String> role,
  Value<String> passwordHash,
  Value<bool> active,
  Value<int> failedAttempts,
  Value<DateTime?> lockedUntil,
  Value<DateTime?> lastLoginAt,
  Value<int> rowid,
});

class $$AppUsersTableFilterComposer
    extends Composer<_$AppDatabase, $AppUsersTable> {
  $$AppUsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get originDeviceId => $composableBuilder(
      column: $table.originDeviceId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get passwordHash => $composableBuilder(
      column: $table.passwordHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get failedAttempts => $composableBuilder(
      column: $table.failedAttempts,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lockedUntil => $composableBuilder(
      column: $table.lockedUntil, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastLoginAt => $composableBuilder(
      column: $table.lastLoginAt, builder: (column) => ColumnFilters(column));
}

class $$AppUsersTableOrderingComposer
    extends Composer<_$AppDatabase, $AppUsersTable> {
  $$AppUsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get originDeviceId => $composableBuilder(
      column: $table.originDeviceId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get passwordHash => $composableBuilder(
      column: $table.passwordHash,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get failedAttempts => $composableBuilder(
      column: $table.failedAttempts,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lockedUntil => $composableBuilder(
      column: $table.lockedUntil, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastLoginAt => $composableBuilder(
      column: $table.lastLoginAt, builder: (column) => ColumnOrderings(column));
}

class $$AppUsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppUsersTable> {
  $$AppUsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get originDeviceId => $composableBuilder(
      column: $table.originDeviceId, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get passwordHash => $composableBuilder(
      column: $table.passwordHash, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<int> get failedAttempts => $composableBuilder(
      column: $table.failedAttempts, builder: (column) => column);

  GeneratedColumn<DateTime> get lockedUntil => $composableBuilder(
      column: $table.lockedUntil, builder: (column) => column);

  GeneratedColumn<DateTime> get lastLoginAt => $composableBuilder(
      column: $table.lastLoginAt, builder: (column) => column);
}

class $$AppUsersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AppUsersTable,
    AppUser,
    $$AppUsersTableFilterComposer,
    $$AppUsersTableOrderingComposer,
    $$AppUsersTableAnnotationComposer,
    $$AppUsersTableCreateCompanionBuilder,
    $$AppUsersTableUpdateCompanionBuilder,
    (AppUser, BaseReferences<_$AppDatabase, $AppUsersTable, AppUser>),
    AppUser,
    PrefetchHooks Function()> {
  $$AppUsersTableTableManager(_$AppDatabase db, $AppUsersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppUsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppUsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppUsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<String> originDeviceId = const Value.absent(),
            Value<String> username = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<String> passwordHash = const Value.absent(),
            Value<bool> active = const Value.absent(),
            Value<int> failedAttempts = const Value.absent(),
            Value<DateTime?> lockedUntil = const Value.absent(),
            Value<DateTime?> lastLoginAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppUsersCompanion(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            originDeviceId: originDeviceId,
            username: username,
            displayName: displayName,
            role: role,
            passwordHash: passwordHash,
            active: active,
            failedAttempts: failedAttempts,
            lockedUntil: lockedUntil,
            lastLoginAt: lastLoginAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            required String originDeviceId,
            required String username,
            required String displayName,
            required String role,
            required String passwordHash,
            Value<bool> active = const Value.absent(),
            Value<int> failedAttempts = const Value.absent(),
            Value<DateTime?> lockedUntil = const Value.absent(),
            Value<DateTime?> lastLoginAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppUsersCompanion.insert(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            originDeviceId: originDeviceId,
            username: username,
            displayName: displayName,
            role: role,
            passwordHash: passwordHash,
            active: active,
            failedAttempts: failedAttempts,
            lockedUntil: lockedUntil,
            lastLoginAt: lastLoginAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$AppUsersTable, AppUser>(table),
                    BaseReferences<_$AppDatabase, $AppUsersTable, AppUser>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AppUsersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AppUsersTable,
    AppUser,
    $$AppUsersTableFilterComposer,
    $$AppUsersTableOrderingComposer,
    $$AppUsersTableAnnotationComposer,
    $$AppUsersTableCreateCompanionBuilder,
    $$AppUsersTableUpdateCompanionBuilder,
    (AppUser, BaseReferences<_$AppDatabase, $AppUsersTable, AppUser>),
    AppUser,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$EventsTableTableManager get events =>
      $$EventsTableTableManager(_db, _db.events);
  $$ChurchesTableTableManager get churches =>
      $$ChurchesTableTableManager(_db, _db.churches);
  $$AgeRangesTableTableManager get ageRanges =>
      $$AgeRangesTableTableManager(_db, _db.ageRanges);
  $$AttendeesTableTableManager get attendees =>
      $$AttendeesTableTableManager(_db, _db.attendees);
  $$CouplesTableTableManager get couples =>
      $$CouplesTableTableManager(_db, _db.couples);
  $$AttendeeGroupsTableTableManager get attendeeGroups =>
      $$AttendeeGroupsTableTableManager(_db, _db.attendeeGroups);
  $$GroupMembersTableTableManager get groupMembers =>
      $$GroupMembersTableTableManager(_db, _db.groupMembers);
  $$LodgingsTableTableManager get lodgings =>
      $$LodgingsTableTableManager(_db, _db.lodgings);
  $$TeamsTableTableManager get teams =>
      $$TeamsTableTableManager(_db, _db.teams);
  $$ControlTypesTableTableManager get controlTypes =>
      $$ControlTypesTableTableManager(_db, _db.controlTypes);
  $$ControlSessionsTableTableManager get controlSessions =>
      $$ControlSessionsTableTableManager(_db, _db.controlSessions);
  $$ControlRecordsTableTableManager get controlRecords =>
      $$ControlRecordsTableTableManager(_db, _db.controlRecords);
  $$AppMetaTableTableManager get appMeta =>
      $$AppMetaTableTableManager(_db, _db.appMeta);
  $$AppUsersTableTableManager get appUsers =>
      $$AppUsersTableTableManager(_db, _db.appUsers);
}
