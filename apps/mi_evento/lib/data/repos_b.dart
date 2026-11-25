import 'package:drift/drift.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'database.dart';
import 'repository.dart';

extension AttendeeRowCore on AttendeeRow {
  /// Versión de dominio (sin dependencias de base de datos) para las reglas de equipos y hospedaje.
  Attendee toCore() => Attendee(
        id: id,
        firstName: firstName,
        lastName1: lastName1,
        lastName2: lastName2,
        sex: sex == 'M' ? Sex.male : Sex.female,
        age: age,
        churchId: churchId,
        teamId: teamId,
      );

  PersonRef toPersonRef(String? spouseId) => PersonRef(
        id: id,
        name: '$firstName $lastName1',
        sex: sex == 'M' ? Sex.male : Sex.female,
        spouseId: spouseId,
        churchId: churchId,
      );
}

extension EventLimits on Event {
  BalanceLimits get balanceLimits => BalanceLimits(
      maxSizeDiff: maxSizeDiff, maxSexDiff: maxSexDiff, maxAgeDiff: maxAgeDiff);
}

/// Grupo con la cantidad de integrantes.
class GroupView {
  const GroupView(this.group, this.memberCount);
  final AttendeeGroup group;
  final int memberCount;
}

/// Quiénes hay en un hospedaje: matrimonios (los dos cónyuges dentro) o personas solas. Los
/// hospedajes «mixtos» no mezclan ambos.
OccupantMix occupantMixOfRows(Iterable<AttendeeRow> occupants) {
  final list = occupants.toList();
  if (list.isEmpty) return OccupantMix.none;
  final perCouple = <String, int>{};
  for (final r in list) {
    if (r.coupleId != null) {
      perCouple[r.coupleId!] = (perCouple[r.coupleId!] ?? 0) + 1;
    }
  }
  final coupled = list
      .where((r) => r.coupleId != null && (perCouple[r.coupleId!] ?? 0) >= 2)
      .length;
  if (coupled == 0) return OccupantMix.singles;
  return coupled == list.length ? OccupantMix.couples : OccupantMix.mixed;
}

class LodgingView {
  const LodgingView(this.row, this.occupied);
  final LodgingRow row;
  final int occupied;
  int get free => row.capacity - occupied;
  LodgingSlot get slot => LodgingSlot(
        name: row.name,
        accepts: lodgingAcceptsFromDb(row.accepts),
        capacity: row.capacity,
        occupied: occupied,
      );
}

/// Matrimonios y grupos de asistentes.
class SocialRepo {
  SocialRepo(this.db);
  final AppDatabase db;

  Future<AttendeeRow?> spouseOf(String attendeeId) async {
    final a = await (db.select(db.attendees)
          ..where((x) => x.id.equals(attendeeId)))
        .getSingleOrNull();
    if (a?.coupleId == null) return null;
    final c = await (db.select(db.couples)
          ..where((x) => x.id.equals(a!.coupleId!) & x.deletedAt.isNull()))
        .getSingleOrNull();
    if (c == null) return null;
    final otherId = c.attendeeAId == attendeeId ? c.attendeeBId : c.attendeeAId;
    return (db.select(db.attendees)..where((x) => x.id.equals(otherId)))
        .getSingleOrNull();
  }

  /// Vincula (o desvincula, con [spouseId] nulo) a [attendeeId] como matrimonio.
  /// Un asistente solo puede tener un cónyuge, y ambos deben ser del mismo evento.
  Future<void> setSpouse(String attendeeId, String? spouseId) async {
    await db.transaction(() async {
      final a = await (db.select(db.attendees)
            ..where((x) => x.id.equals(attendeeId)))
          .getSingle();
      final current = await spouseOf(attendeeId);
      if (current?.id == spouseId) return; // sin cambios
      final now = DateTime.now().toUtc();

      Future<void> unlink(AttendeeRow x) async {
        if (x.coupleId == null) return;
        await (db.update(db.couples)..where((c) => c.id.equals(x.coupleId!)))
            .write(
                CouplesCompanion(deletedAt: Value(now), updatedAt: Value(now)));
        await (db.update(db.attendees)
              ..where((r) => r.coupleId.equals(x.coupleId!)))
            .write(AttendeesCompanion(
                coupleId: const Value(null), updatedAt: Value(now)));
      }

      if (spouseId != null) {
        if (spouseId == attendeeId) {
          throw DataException('Una persona no puede ser su propio cónyuge.');
        }
        final s = await (db.select(db.attendees)
              ..where((x) => x.id.equals(spouseId)))
            .getSingle();
        if (s.eventId != a.eventId) {
          throw DataException(
              'Los dos deben estar inscritos en el mismo evento.');
        }
        if (s.sex == a.sex) {
          throw DataException(
              'Un matrimonio es entre un hombre y una mujer: ${a.firstName} ${a.lastName1} y ${s.firstName} ${s.lastName1} son del mismo sexo.');
        }
        final other = await spouseOf(spouseId);
        if (other != null && other.id != attendeeId) {
          throw DataException(
              '${s.firstName} ${s.lastName1} ya está vinculado/a con ${other.firstName} ${other.lastName1}.');
        }
      }
      await unlink(a);
      if (spouseId == null) return;
      final s = await (db.select(db.attendees)
            ..where((x) => x.id.equals(spouseId)))
          .getSingle();
      await unlink(s);
      final id = newUuidV7();
      await db.into(db.couples).insert(CouplesCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            originDeviceId: await db.deviceId(),
            eventId: a.eventId,
            attendeeAId: attendeeId,
            attendeeBId: spouseId,
          ));
      await (db.update(db.attendees)
            ..where((r) => r.id.isIn([attendeeId, spouseId])))
          .write(
              AttendeesCompanion(coupleId: Value(id), updatedAt: Value(now)));
    });
  }

  /// id de cónyuge de cada asistente del evento (para reglas de hospedaje).
  Future<Map<String, String>> spouseMap(String eventId) async {
    final cs = await (db.select(db.couples)
          ..where((c) => c.eventId.equals(eventId) & c.deletedAt.isNull()))
        .get();
    return {
      for (final c in cs) ...{
        c.attendeeAId: c.attendeeBId,
        c.attendeeBId: c.attendeeAId
      }
    };
  }

  // ── Grupos ──

  Stream<List<GroupView>> watchGroups(String eventId) {
    final count = db.groupMembers.id.count();
    final q = db.select(db.attendeeGroups).join([
      leftOuterJoin(
          db.groupMembers,
          db.groupMembers.groupId.equalsExp(db.attendeeGroups.id) &
              db.groupMembers.deletedAt.isNull()),
    ])
      ..addColumns([count])
      ..where(db.attendeeGroups.eventId.equals(eventId) &
          db.attendeeGroups.deletedAt.isNull())
      ..groupBy([db.attendeeGroups.id])
      ..orderBy([OrderingTerm.asc(db.attendeeGroups.name)]);
    return q.watch().map((rows) => [
          for (final r in rows)
            GroupView(r.readTable(db.attendeeGroups), r.read(count) ?? 0)
        ]);
  }

  Future<AttendeeGroup> createGroup(String eventId, String name,
      {String reason = 'preference', bool keepTogether = true}) async {
    final n = name.trim();
    if (n.isEmpty) throw DataException('Falta el nombre del grupo.');
    final exists = await (db.select(db.attendeeGroups)
          ..where((g) => g.eventId.equals(eventId) & g.deletedAt.isNull()))
        .get();
    if (exists.any((g) => normalizeText(g.name) == normalizeText(n))) {
      throw DataException('Ya existe un grupo llamado «$n».');
    }
    final now = DateTime.now().toUtc();
    final id = newUuidV7();
    await db.into(db.attendeeGroups).insert(AttendeeGroupsCompanion.insert(
          id: id,
          createdAt: now,
          updatedAt: now,
          originDeviceId: await db.deviceId(),
          eventId: eventId,
          name: n,
          reason: Value(reason),
          keepTogether: Value(keepTogether),
        ));
    return (db.select(db.attendeeGroups)..where((g) => g.id.equals(id)))
        .getSingle();
  }

  Future<Set<String>> groupIdsOf(String attendeeId) async => (await (db
              .select(db.groupMembers)
            ..where(
                (m) => m.attendeeId.equals(attendeeId) & m.deletedAt.isNull()))
          .get())
      .map((m) => m.groupId)
      .toSet();

  /// Deja a [attendeeId] exactamente en los grupos [groupIds].
  Future<void> setGroups(String attendeeId, Set<String> groupIds) async {
    await db.transaction(() async {
      final now = DateTime.now().toUtc();
      final current = await (db.select(db.groupMembers)
            ..where(
                (m) => m.attendeeId.equals(attendeeId) & m.deletedAt.isNull()))
          .get();
      for (final m in current.where((m) => !groupIds.contains(m.groupId))) {
        await (db.update(db.groupMembers)..where((x) => x.id.equals(m.id)))
            .write(GroupMembersCompanion(
                deletedAt: Value(now), updatedAt: Value(now)));
      }
      final have = current.map((m) => m.groupId).toSet();
      final dev = await db.deviceId();
      for (final g in groupIds.difference(have)) {
        await db.into(db.groupMembers).insert(GroupMembersCompanion.insert(
            id: newUuidV7(),
            createdAt: now,
            updatedAt: now,
            originDeviceId: dev,
            groupId: g,
            attendeeId: attendeeId));
      }
    });
  }

  /// Conjuntos de personas que deben ir juntas: los integrantes de cada grupo «mantener juntos».
  Future<List<Set<String>>> togetherSets(String eventId) async {
    final groups = await (db.select(db.attendeeGroups)
          ..where((g) =>
              g.eventId.equals(eventId) &
              g.deletedAt.isNull() &
              g.keepTogether.equals(true)))
        .get();
    if (groups.isEmpty) return const [];
    final ms = await (db.select(db.groupMembers)
          ..where((m) =>
              m.groupId.isIn(groups.map((g) => g.id)) & m.deletedAt.isNull()))
        .get();
    final by = <String, Set<String>>{};
    for (final m in ms) {
      (by[m.groupId] ??= {}).add(m.attendeeId);
    }
    return [
      for (final s in by.values)
        if (s.length > 1) s
    ];
  }

  Future<List<AttendeeRow>> groupMembers(String groupId) async {
    final ms = await (db.select(db.groupMembers)
          ..where((m) => m.groupId.equals(groupId) & m.deletedAt.isNull()))
        .get();
    if (ms.isEmpty) return const [];
    return (db.select(db.attendees)
          ..where((a) =>
              a.id.isIn(ms.map((m) => m.attendeeId)) & a.deletedAt.isNull())
          ..orderBy([(a) => OrderingTerm.asc(a.regNumber)]))
        .get();
  }
}

/// La asignación se rechazó por incompatibilidad (sexo o matrimonio) con el hospedaje.
class LodgingIncompatibleException extends DataException {
  LodgingIncompatibleException(this.problems)
      : super('${problems.join(' ')} Para hospedarlos ahí hay que editar '
            'el hospedaje (para quién es) o elegir otro.');
  final List<String> problems;
}

/// Hospedajes: alta, asignación manual y ocupación.
class LodgingRepo {
  LodgingRepo(this.db);
  final AppDatabase db;

  Stream<List<LodgingView>> watchLodgings(String eventId) {
    final count = db.attendees.id.count();
    final q = db.select(db.lodgings).join([
      leftOuterJoin(
          db.attendees,
          db.attendees.lodgingId.equalsExp(db.lodgings.id) &
              db.attendees.deletedAt.isNull()),
    ])
      ..addColumns([count])
      ..where(
          db.lodgings.eventId.equals(eventId) & db.lodgings.deletedAt.isNull())
      ..groupBy([db.lodgings.id])
      ..orderBy([OrderingTerm.asc(db.lodgings.name)]);
    return q.watch().map((rows) => [
          for (final r in rows)
            LodgingView(r.readTable(db.lodgings), r.read(count) ?? 0)
        ]);
  }

  Future<LodgingRow> save({
    String? id,
    required String eventId,
    required String name,
    required String kind, // 'shelter' | 'private_home'
    required int capacity,
    required LodgingAccepts accepts,
    String? contactPhone,
    String directions = '',
    String? hostName,
    String distanceNote = '',
  }) async {
    if (name.trim().isEmpty) {
      throw DataException('Falta el nombre del hospedaje.');
    }
    if (capacity < 1 || capacity > 500) {
      throw DataException('La capacidad debe estar entre 1 y 500 plazas.');
    }
    final all = await (db.select(db.lodgings)
          ..where((l) => l.eventId.equals(eventId) & l.deletedAt.isNull()))
        .get();
    if (all.any(
        (l) => l.id != id && normalizeText(l.name) == normalizeText(name))) {
      throw DataException('Ya existe un hospedaje llamado «${name.trim()}».');
    }
    String? blank(String? s) =>
        (s == null || s.trim().isEmpty) ? null : s.trim();
    final now = DateTime.now().toUtc();
    if (id == null) {
      final nid = newUuidV7();
      await db.into(db.lodgings).insert(LodgingsCompanion.insert(
            id: nid,
            createdAt: now,
            updatedAt: now,
            originDeviceId: await db.deviceId(),
            eventId: eventId,
            name: name.trim(),
            kind: kind,
            capacity: capacity,
            accepts: lodgingAcceptsToDb(accepts),
            contactPhone: Value(blank(contactPhone)),
            directions: Value(directions.trim()),
            hostName: Value(blank(hostName)),
            distanceNote: Value(distanceNote.trim()),
          ));
      return (db.select(db.lodgings)..where((l) => l.id.equals(nid)))
          .getSingle();
    }
    await (db.update(db.lodgings)..where((l) => l.id.equals(id)))
        .write(LodgingsCompanion(
      name: Value(name.trim()),
      kind: Value(kind),
      capacity: Value(capacity),
      accepts: Value(lodgingAcceptsToDb(accepts)),
      contactPhone: Value(blank(contactPhone)),
      directions: Value(directions.trim()),
      hostName: Value(blank(hostName)),
      distanceNote: Value(distanceNote.trim()),
      updatedAt: Value(now),
    ));
    return (db.select(db.lodgings)..where((l) => l.id.equals(id))).getSingle();
  }

  /// Borra el hospedaje (lógico) y deja sin asignar a quienes estaban en él. Devuelve cuántos.
  Future<int> delete(String id) async => db.transaction(() async {
        final now = DateTime.now().toUtc();
        final n = await (db.update(db.attendees)
              ..where((a) => a.lodgingId.equals(id)))
            .write(AttendeesCompanion(
                lodgingId: const Value(null), updatedAt: Value(now)));
        await (db.update(db.lodgings)..where((l) => l.id.equals(id))).write(
            LodgingsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
        return n;
      });

  /// Asigna personas al hospedaje. La compatibilidad es un BLOQUEO duro (no hay «asignar de todas
  /// formas»): un hombre no entra en un hospedaje de mujeres ni al revés, y uno de matrimonios solo
  /// recibe a quien queda junto a su cónyuge (en esta misma llamada o ya dentro). «Sin preferencia»
  /// acepta a todos. Todo o nada: si alguien no es compatible no se asigna a NADIE y se lanza
  /// [LodgingIncompatibleException]. La única salida es editar el hospedaje (para quién es).
  /// La capacidad NO bloquea (es un aviso que muestra la pantalla antes).
  Future<void> assign(String lodgingId, Iterable<String> attendeeIds) async {
    final ids = attendeeIds.toSet().toList();
    if (ids.isEmpty) return;
    await db.transaction(() async {
      final problems = await compatibilityProblems(lodgingId, ids);
      if (problems.isNotEmpty) {
        throw LodgingIncompatibleException(problems);
      }
      await (db.update(db.attendees)..where((a) => a.id.isIn(ids))).write(
          AttendeesCompanion(
              lodgingId: Value(lodgingId),
              updatedAt: Value(DateTime.now().toUtc())));
    });
  }

  /// Motivos por los que [attendeeIds] NO pueden ir a [lodgingId] (vacío = compatible). No escribe.
  Future<List<String>> compatibilityProblems(
      String lodgingId, Iterable<String> attendeeIds) async {
    final ids = attendeeIds.toSet();
    final l = await (db.select(db.lodgings)
          ..where((x) => x.id.equals(lodgingId) & x.deletedAt.isNull()))
        .getSingleOrNull();
    if (l == null) throw DataException('Ese hospedaje ya no existe.');
    final people = await (db.select(db.attendees)
          ..where((a) => a.id.isIn(ids) & a.deletedAt.isNull()))
        .get();
    final there = await (db.select(db.attendees)
          ..where((a) =>
              a.lodgingId.equals(lodgingId) &
              a.deletedAt.isNull() &
              a.id.isIn(ids).not()))
        .get();
    final spouses = await SocialRepo(db).spouseMap(l.eventId);
    final slot = LodgingSlot(
        name: l.name,
        accepts: lodgingAcceptsFromDb(l.accepts),
        capacity: l.capacity,
        occupied: there.length);
    return [
      for (final w in lodgingBlockers(
          slot, [for (final p in people) p.toPersonRef(spouses[p.id])],
          alreadyThere: [for (final p in there) p.toPersonRef(spouses[p.id])]))
        w.message
    ];
  }

  /// Ocupantes actuales que ya NO son compatibles con el hospedaje (p. ej. porque se editó para
  /// quién es). No se borra ni se mueve a nadie: solo se listan para que la persona decida.
  Future<List<AttendeeRow>> incompatibleOccupants(String lodgingId) async {
    final l = await (db.select(db.lodgings)
          ..where((x) => x.id.equals(lodgingId) & x.deletedAt.isNull()))
        .getSingleOrNull();
    if (l == null) return const [];
    final occ = await occupants(lodgingId);
    final spouses = await SocialRepo(db).spouseMap(l.eventId);
    final refs = {for (final p in occ) p.id: p.toPersonRef(spouses[p.id])};
    final slot = LodgingSlot(
        name: l.name,
        accepts: lodgingAcceptsFromDb(l.accepts),
        capacity: l.capacity,
        occupied: occ.length);
    return [
      for (final p in occ)
        if (lodgingBlockers(slot, [
          refs[p.id]!
        ], alreadyThere: [
          for (final o in occ)
            if (o.id != p.id) refs[o.id]!
        ]).isNotEmpty)
          p
    ];
  }

  Future<void> unassign(Iterable<String> attendeeIds) async {
    await (db.update(db.attendees)..where((a) => a.id.isIn(attendeeIds))).write(
        AttendeesCompanion(
            lodgingId: const Value(null),
            updatedAt: Value(DateTime.now().toUtc())));
  }

  Future<List<AttendeeRow>> occupants(String lodgingId) =>
      (db.select(db.attendees)
            ..where((a) => a.lodgingId.equals(lodgingId) & a.deletedAt.isNull())
            ..orderBy([
              (a) => OrderingTerm.asc(a.lastName1),
              (a) => OrderingTerm.asc(a.firstName)
            ]))
          .get();
}

const teamPalette = <(String, String)>[
  ('Rojo', '#C8453B'),
  ('Azul', '#2F6DB5'),
  ('Verde', '#2E8B57'),
  ('Amarillo', '#D9A400'),
  ('Morado', '#7A4FA3'),
  ('Naranja', '#D9702B'),
  ('Turquesa', '#0F8B8D'),
  ('Rosa', '#C2548A'),
];

/// Equipos: alta, capitán, traslados e intercambios manuales.
class TeamRepo {
  TeamRepo(this.db);
  final AppDatabase db;

  Stream<List<TeamRow>> watchTeams(String eventId) => (db.select(db.teams)
        ..where((t) => t.eventId.equals(eventId) & t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
      .watch();

  /// Crea [count] equipos nuevos con nombres y colores por defecto (editables).
  Future<void> createMany(String eventId, int count) async {
    if (count < 1 || count > 40) {
      throw DataException('El número de equipos debe estar entre 1 y 40.');
    }
    await db.transaction(() async {
      final existing = await (db.select(db.teams)
            ..where((t) => t.eventId.equals(eventId) & t.deletedAt.isNull()))
          .get();
      final now = DateTime.now().toUtc();
      final dev = await db.deviceId();
      for (var i = 0; i < count; i++) {
        final n = existing.length + i;
        final (name, color) = n < teamPalette.length
            ? teamPalette[n]
            : ('Equipo ${n + 1}', null as String?);
        await db.into(db.teams).insert(TeamsCompanion.insert(
              id: newUuidV7(),
              createdAt: now,
              updatedAt: now,
              originDeviceId: dev,
              eventId: eventId,
              name: name,
              color: Value(color),
              sortOrder: Value(n),
            ));
      }
    });
  }

  /// Crea un equipo con [name] y [color] (opcional) al final de la lista.
  Future<TeamRow> create(String eventId,
      {required String name, String? color}) async {
    if (name.trim().isEmpty) throw DataException('Falta el nombre del equipo.');
    return db.transaction(() async {
      final existing = await (db.select(db.teams)
            ..where((t) => t.eventId.equals(eventId) & t.deletedAt.isNull()))
          .get();
      if (existing
          .any((o) => normalizeText(o.name) == normalizeText(name.trim()))) {
        throw DataException('Ya existe un equipo llamado «${name.trim()}».');
      }
      final now = DateTime.now().toUtc();
      final order =
          existing.fold<int>(-1, (m, t) => t.sortOrder > m ? t.sortOrder : m);
      final id = newUuidV7();
      await db.into(db.teams).insert(TeamsCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            originDeviceId: await db.deviceId(),
            eventId: eventId,
            name: name.trim(),
            color: Value(color),
            sortOrder: Value(order + 1),
          ));
      return (db.select(db.teams)..where((t) => t.id.equals(id))).getSingle();
    });
  }

  Future<void> update(String id,
      {required String name, String? color, String? captainId}) async {
    if (name.trim().isEmpty) throw DataException('Falta el nombre del equipo.');
    final t =
        await (db.select(db.teams)..where((x) => x.id.equals(id))).getSingle();
    final others = await (db.select(db.teams)
          ..where((x) => x.eventId.equals(t.eventId) & x.deletedAt.isNull()))
        .get();
    if (others.any(
        (o) => o.id != id && normalizeText(o.name) == normalizeText(name))) {
      throw DataException('Ya existe un equipo llamado «${name.trim()}».');
    }
    if (captainId != null) {
      final c = await (db.select(db.attendees)
            ..where((a) => a.id.equals(captainId)))
          .getSingleOrNull();
      if (c == null || c.teamId != id) {
        throw DataException('El capitán debe ser integrante del equipo.');
      }
    }
    await (db.update(db.teams)..where((x) => x.id.equals(id))).write(
        TeamsCompanion(
            name: Value(name.trim()),
            color: Value(color),
            captainId: Value(captainId),
            updatedAt: Value(DateTime.now().toUtc())));
  }

  /// Borra el equipo (lógico) y deja sin equipo a sus integrantes. Devuelve cuántos.
  Future<int> delete(String id) async => db.transaction(() async {
        final now = DateTime.now().toUtc();
        final n = await (db.update(db.attendees)
              ..where((a) => a.teamId.equals(id)))
            .write(AttendeesCompanion(
                teamId: const Value(null), updatedAt: Value(now)));
        await (db.update(db.teams)..where((t) => t.id.equals(id))).write(
            TeamsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
        return n;
      });

  /// Asigna/traslada personas a un equipo (o las deja sin equipo con [teamId] nulo).
  /// Si alguna era capitán de su equipo anterior, ese equipo queda sin capitán.
  Future<void> setTeam(Iterable<String> attendeeIds, String? teamId) async {
    final ids = attendeeIds.toList();
    await db.transaction(() async {
      final now = DateTime.now().toUtc();
      await (db.update(db.teams)..where((t) => t.captainId.isIn(ids))).write(
          TeamsCompanion(captainId: const Value(null), updatedAt: Value(now)));
      await (db.update(db.attendees)..where((a) => a.id.isIn(ids))).write(
          AttendeesCompanion(teamId: Value(teamId), updatedAt: Value(now)));
    });
  }

  /// Pone a la persona en el equipo que mejor conserva el balance del evento (estrategia C; si su
  /// cónyuge ya está en un equipo, ahí). Es automático al inscribir; luego se puede cambiar desde
  /// la vista de equipos. Devuelve el equipo, o nulo si el evento no usa equipos o aún no hay.
  Future<TeamRow?> autoAssign(String attendeeId) async {
    final a = await (db.select(db.attendees)
          ..where((x) => x.id.equals(attendeeId)))
        .getSingle();
    final ev = await (db.select(db.events)
          ..where((e) => e.id.equals(a.eventId)))
        .getSingle();
    if (!ev.offersTeams) return null;
    final teams = await (db.select(db.teams)
          ..where((t) => t.eventId.equals(a.eventId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    if (teams.isEmpty) return null;
    final members = await (db.select(db.attendees)
          ..where((x) =>
              x.eventId.equals(a.eventId) &
              x.deletedAt.isNull() &
              x.teamId.isNotNull() &
              x.id.equals(attendeeId).not()))
        .get();
    final stats = [
      for (final t in teams)
        TeamStats.of(t.id, t.name,
            members.where((m) => m.teamId == t.id).map((m) => m.toCore()))
    ];
    final spouse = await SocialRepo(db).spouseOf(attendeeId);
    final ranked = suggestTeam(
        a.sex == 'M' ? Sex.male : Sex.female, a.age, stats,
        limits: ev.balanceLimits, spouseTeamId: spouse?.teamId);
    final chosen = teams.firstWhere((t) => t.id == ranked.first.teamId);
    await setTeam([attendeeId], chosen.id);
    return chosen;
  }

  /// Lo mismo que [autoAssign] para muchas personas de un evento (p. ej. al importar un CSV),
  /// una tras otra y en el orden dado, pero leyendo la base una sola vez (con 1000 personas
  /// llamar a [autoAssign] 1000 veces tardaba ~5 s). Devuelve cuántas quedaron con equipo.
  Future<int> autoAssignMany(String eventId, List<String> attendeeIds) async {
    if (attendeeIds.isEmpty) return 0;
    final ev = await (db.select(db.events)..where((e) => e.id.equals(eventId)))
        .getSingle();
    if (!ev.offersTeams) return 0;
    final teams = await (db.select(db.teams)
          ..where((t) => t.eventId.equals(eventId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    if (teams.isEmpty) return 0;
    final rows = await (db.select(db.attendees)
          ..where((x) => x.eventId.equals(eventId) & x.deletedAt.isNull()))
        .get();
    final byId = {for (final r in rows) r.id: r};
    // Equipo actual de cada persona (se va actualizando a medida que se asigna).
    final teamOf = {
      for (final r in rows)
        if (r.teamId != null) r.id: r.teamId!
    };
    final spouses = await SocialRepo(db).spouseMap(eventId);
    // Acumuladores por equipo (tamaño, hombres, mujeres, suma de edades), al día en cada paso.
    final acc = {
      for (final t in teams) t.id: [0, 0, 0, 0]
    };
    void count(AttendeeRow r, String teamId, int sign) {
      final c = acc[teamId];
      if (c == null) return;
      c[0] += sign;
      c[r.sex == 'M' ? 1 : 2] += sign;
      c[3] += sign * r.age;
    }

    teamOf.forEach((pid, tid) => count(byId[pid]!, tid, 1));
    final out = <String, String>{};
    for (final id in attendeeIds) {
      final a = byId[id];
      if (a == null) continue;
      final current = teamOf[id];
      if (current != null) {
        count(a, current, -1); // se reubica: no cuenta a sí misma
      }
      final stats = [
        for (final t in teams)
          TeamStats(t.id, t.name, acc[t.id]![0], acc[t.id]![1], acc[t.id]![2],
              acc[t.id]![0] == 0 ? 0 : acc[t.id]![3] / acc[t.id]![0])
      ];
      final spouseTeam = spouses[id] == null ? null : teamOf[spouses[id]!];
      final ranked = suggestTeam(
          a.sex == 'M' ? Sex.male : Sex.female, a.age, stats,
          limits: ev.balanceLimits, spouseTeamId: spouseTeam);
      final chosen = ranked.first.teamId;
      teamOf[id] = chosen;
      count(a, chosen, 1);
      out[id] = chosen;
    }
    final byTeam = <String, List<String>>{};
    out.forEach((p, t) => (byTeam[t] ??= []).add(p));
    for (final e in byTeam.entries) {
      await setTeam(e.value, e.key);
    }
    return out.length;
  }

  /// Aplica una propuesta de equipos (persona → equipo). Devuelve el equipo anterior de cada
  /// persona afectada (nulo = sin equipo) para poder deshacer.
  Future<Map<String, String?>> applyPlan(
      Map<String, String> assignments) async {
    final previous = <String, String?>{};
    await db.transaction(() async {
      final rows = await (db.select(db.attendees)
            ..where((a) => a.id.isIn(assignments.keys)))
          .get();
      for (final r in rows) {
        previous[r.id] = r.teamId;
      }
      final byTeam = <String, List<String>>{};
      assignments.forEach((p, t) => (byTeam[t] ??= []).add(p));
      for (final e in byTeam.entries) {
        await setTeam(e.value, e.key);
      }
    });
    return previous;
  }

  /// Devuelve a cada persona al equipo que tenía ([applyPlan] → «Deshacer»).
  Future<void> restoreTeams(Map<String, String?> previous) async {
    await db.transaction(() async {
      final byTeam = <String?, List<String>>{};
      previous.forEach((p, t) => (byTeam[t] ??= []).add(p));
      for (final e in byTeam.entries) {
        await setTeam(e.value, e.key);
      }
    });
  }

  /// Intercambia de equipo a dos personas.
  Future<void> swap(String aId, String bId) async {
    await db.transaction(() async {
      final a = await (db.select(db.attendees)..where((x) => x.id.equals(aId)))
          .getSingle();
      final b = await (db.select(db.attendees)..where((x) => x.id.equals(bId)))
          .getSingle();
      if (a.teamId == null || b.teamId == null) {
        throw DataException(
            'Las dos personas deben estar en un equipo para intercambiarlas.');
      }
      if (a.teamId == b.teamId) {
        throw DataException('Están en el mismo equipo.');
      }
      await setTeam([aId], b.teamId);
      await setTeam([bId], a.teamId);
    });
  }

  Future<void> setLimits(String eventId, BalanceLimits l) async {
    if (l.maxSizeDiff < 0 || l.maxSexDiff < 0 || l.maxAgeDiff < 0) {
      throw DataException('Los topes no pueden ser negativos.');
    }
    await (db.update(db.events)..where((e) => e.id.equals(eventId))).write(
        EventsCompanion(
            maxSizeDiff: Value(l.maxSizeDiff),
            maxSexDiff: Value(l.maxSexDiff),
            maxAgeDiff: Value(l.maxAgeDiff),
            updatedAt: Value(DateTime.now().toUtc())));
  }
}
