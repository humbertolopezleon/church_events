import 'package:drift/drift.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'database.dart';
import 'repos_b.dart';
import 'repository.dart';

/// Qué se lleva un evento duplicado. Las configuraciones (rangos de edad, tipos de control) siempre
/// se copian; lo demás es opcional. Equipos y hospedajes de cada persona solo se conservan si se
/// copian las personas Y esa estructura.
class DuplicateOptions {
  const DuplicateOptions(
      {this.people = true,
      this.teams = true,
      this.lodgings = true,
      this.groups = true,
      this.preregister = true});
  final bool people;
  final bool teams;
  final bool lodgings;
  final bool groups;

  /// Las personas copiadas quedan como preinscritas (la asistencia se confirma el día del evento).
  final bool preregister;
}

/// Resultado de copiar personas.
class CopyReport {
  CopyReport({this.copied = 0, this.skipped = 0, this.couples = 0});
  int copied, skipped, couples;
}

/// Duplicar un evento y pasar participantes de un evento a otro. Todo con ids nuevos.
class EventCopy {
  EventCopy(this.db);
  final AppDatabase db;

  /// Crea un evento nuevo a partir de [sourceId]. Devuelve su id.
  Future<String> duplicateEvent(
    String sourceId, {
    required String name,
    required String startDate,
    required String endDate,
    DuplicateOptions options = const DuplicateOptions(),
  }) async {
    if (name.trim().isEmpty) throw DataException('Falta el nombre del evento.');
    if (endDate.compareTo(startDate) < 0) {
      throw DataException(
          'La fecha de fin no puede ser anterior a la de inicio.');
    }
    final dev = await db.deviceId();
    final now = DateTime.now().toUtc();
    return db.transaction(() async {
      final src = await (db.select(db.events)
            ..where((e) => e.id.equals(sourceId) & e.deletedAt.isNull()))
          .getSingle();
      final newId = newUuidV7();
      await db.into(db.events).insert(src.copyWith(
          id: newId,
          name: name.trim(),
          startDate: startDate,
          endDate: endDate,
          createdAt: now,
          updatedAt: now,
          originDeviceId: dev,
          deletedAt: const Value(null)));

      Future<List<T>> alive<T extends DataClass, Tbl extends Table>(
          TableInfo<Tbl, T> t, Expression<bool> Function(Tbl) where) async {
        return (db.select(t)..where(where)).get();
      }

      for (final r in await alive(db.ageRanges,
          (t) => t.eventId.equals(sourceId) & t.deletedAt.isNull())) {
        await db.into(db.ageRanges).insert(r.copyWith(
            id: newUuidV7(),
            eventId: newId,
            createdAt: now,
            updatedAt: now,
            originDeviceId: dev));
      }
      for (final r in await alive(db.controlTypes,
          (t) => t.eventId.equals(sourceId) & t.deletedAt.isNull())) {
        await db.into(db.controlTypes).insert(r.copyWith(
            id: newUuidV7(),
            eventId: newId,
            createdAt: now,
            updatedAt: now,
            originDeviceId: dev));
      }

      final lodgingMap = <String, String>{};
      if (options.lodgings) {
        for (final r in await alive(db.lodgings,
            (t) => t.eventId.equals(sourceId) & t.deletedAt.isNull())) {
          final id = lodgingMap[r.id] = newUuidV7();
          await db.into(db.lodgings).insert(r.copyWith(
              id: id,
              eventId: newId,
              createdAt: now,
              updatedAt: now,
              originDeviceId: dev));
        }
      }
      final teamMap = <String, String>{};
      final teamRows = options.teams
          ? await alive(db.teams,
              (t) => t.eventId.equals(sourceId) & t.deletedAt.isNull())
          : const <TeamRow>[];
      for (final r in teamRows) {
        teamMap[r.id] = newUuidV7();
      }

      final people = options.people
          ? await (db.select(db.attendees)
                ..where(
                    (a) => a.eventId.equals(sourceId) & a.deletedAt.isNull())
                ..orderBy([(a) => OrderingTerm.asc(a.regNumber)]))
              .get()
          : const <AttendeeRow>[];
      final personMap = {for (final a in people) a.id: newUuidV7()};

      // Los equipos se insertan ya con el capitán remapeado (solo si esa persona se copió).
      for (final r in teamRows) {
        await db.into(db.teams).insert(r.copyWith(
            id: teamMap[r.id]!,
            eventId: newId,
            captainId: Value(personMap[r.captainId]),
            createdAt: now,
            updatedAt: now,
            originDeviceId: dev));
      }
      for (final a in people) {
        await db.into(db.attendees).insert(a.copyWith(
            id: personMap[a.id]!,
            eventId: newId,
            coupleId: const Value(null),
            teamId: Value(teamMap[a.teamId]),
            lodgingId: Value(lodgingMap[a.lodgingId]),
            status: options.preregister ? 'preregistered' : a.status,
            confirmedAt:
                options.preregister ? const Value(null) : Value(a.confirmedAt),
            createdAt: now,
            updatedAt: now,
            originDeviceId: dev));
      }
      if (people.isNotEmpty) {
        await _copyCouples(sourceId, personMap);
        if (options.groups) {
          await _copyGroups(sourceId, newId, personMap, now, dev);
        }
      }
      return newId;
    });
  }

  /// Pasa personas de [fromEventId] a [toEventId] (ya existente), con ids y números nuevos.
  /// Se omiten las que ya están en el destino (mismo nombre, primer apellido y edad). Los matrimonios
  /// se conservan cuando ambos se copian. No lleva equipo ni hospedaje (son de otro evento).
  /// [onlyIds]: copiar solo a esas personas.
  Future<CopyReport> copyPeople(
    String fromEventId,
    String toEventId, {
    Set<String>? onlyIds,
    bool preregister = true,
  }) async {
    if (fromEventId == toEventId) {
      throw DataException('Elige un evento distinto al actual.');
    }
    final repo = Repository(db);
    final rep = CopyReport();
    await db.transaction(() async {
      final src = await (db.select(db.attendees)
            ..where((a) => a.eventId.equals(fromEventId) & a.deletedAt.isNull())
            ..orderBy([(a) => OrderingTerm.asc(a.regNumber)]))
          .get();
      final existing = {
        for (final a in await (db.select(db.attendees)
              ..where(
                  (a) => a.eventId.equals(toEventId) & a.deletedAt.isNull()))
            .get())
          '${a.dedupeKey}|${a.age}'
      };
      final map = <String, String>{};
      for (final a in src) {
        if (onlyIds != null && !onlyIds.contains(a.id)) continue;
        if (!existing.add('${a.dedupeKey}|${a.age}')) {
          rep.skipped++;
          continue;
        }
        final row = await repo.addAttendee(
            eventId: toEventId,
            firstName: a.firstName,
            lastName1: a.lastName1,
            lastName2: a.lastName2,
            sex: a.sex == 'M' ? Sex.male : Sex.female,
            age: a.age,
            churchId: a.churchId,
            phone: a.phone,
            province: a.province,
            municipality: a.municipality,
            needsLodging: a.needsLodging,
            notes: a.notes,
            preregistered: preregister);
        map[a.id] = row.id;
        rep.copied++;
      }
      rep.couples = await _copyCouples(fromEventId, map);
    });
    return rep;
  }

  /// Vincula en el destino a quienes eran matrimonio en el origen (si ambos se copiaron).
  Future<int> _copyCouples(String fromEventId, Map<String, String> map) async {
    final social = SocialRepo(db);
    var n = 0;
    for (final c in await (db.select(db.couples)
          ..where((c) => c.eventId.equals(fromEventId) & c.deletedAt.isNull()))
        .get()) {
      final a = map[c.attendeeAId], b = map[c.attendeeBId];
      if (a != null && b != null) {
        await social.setSpouse(a, b);
        n++;
      }
    }
    return n;
  }

  Future<void> _copyGroups(String sourceId, String newId,
      Map<String, String> personMap, DateTime now, String dev) async {
    final groups = await (db.select(db.attendeeGroups)
          ..where((g) => g.eventId.equals(sourceId) & g.deletedAt.isNull()))
        .get();
    for (final g in groups) {
      final members = await (db.select(db.groupMembers)
            ..where((m) => m.groupId.equals(g.id) & m.deletedAt.isNull()))
          .get();
      final mapped = [
        for (final m in members)
          if (personMap[m.attendeeId] != null) personMap[m.attendeeId]!
      ];
      if (mapped.isEmpty) continue;
      final gid = newUuidV7();
      await db.into(db.attendeeGroups).insert(g.copyWith(
          id: gid,
          eventId: newId,
          createdAt: now,
          updatedAt: now,
          originDeviceId: dev));
      for (final id in mapped) {
        await db.into(db.groupMembers).insert(GroupMembersCompanion.insert(
            id: newUuidV7(),
            createdAt: now,
            updatedAt: now,
            originDeviceId: dev,
            groupId: gid,
            attendeeId: id));
      }
    }
  }
}
