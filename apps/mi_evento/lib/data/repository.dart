import 'package:drift/drift.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'database.dart';
import 'repos_b.dart'
    show LodgingIncompatibleException, LodgingRepo, SocialRepo;

/// Error de datos con mensaje listo para el usuario (en español).
class DataException implements Exception {
  DataException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Asistente junto con el nombre de su iglesia (para listas).
class AttendeeView {
  const AttendeeView(this.a, this.churchName);
  final AttendeeRow a;
  final String? churchName;

  String get fullName => [a.firstName, a.lastName1, a.lastName2]
      .where((e) => e.trim().isNotEmpty)
      .join(' ');
  String get initials =>
      '${a.firstName.isEmpty ? '' : a.firstName[0]}${a.lastName1.isEmpty ? '' : a.lastName1[0]}'
          .toUpperCase();
  bool get isMale => a.sex == 'M';

  /// Preinscrito: se anotó antes del evento y su asistencia aún no se ha confirmado.
  bool get isPreregistered => a.status == 'preregistered';
}

/// Acceso a datos. Toda escritura pone id UUID v7, marcas de tiempo y dispositivo de origen.
class Repository {
  Repository(this.db);
  final AppDatabase db;

  // ───────────────────────── Eventos ─────────────────────────

  /// Cambia los datos del evento (nombre, fechas, lugar, organizador y si lleva hospedaje/equipos).
  Future<void> updateEvent(
    String id, {
    required String name,
    required String startDate,
    required String endDate,
    String venue = '',
    String organizer = '',
    required bool offersLodging,
    required bool offersTeams,
  }) async {
    if (name.trim().isEmpty) throw DataException('Falta el nombre del evento.');
    if (endDate.compareTo(startDate) < 0) {
      throw DataException(
          'La fecha de fin no puede ser anterior a la de inicio.');
    }
    await (db.update(db.events)..where((e) => e.id.equals(id))).write(
        EventsCompanion(
            name: Value(name.trim()),
            startDate: Value(startDate),
            endDate: Value(endDate),
            venue: Value(venue.trim()),
            organizer: Value(organizer.trim()),
            offersLodging: Value(offersLodging),
            offersTeams: Value(offersTeams),
            updatedAt: Value(DateTime.now().toUtc())));
  }

  /// Termina la configuración y abre las inscripciones (o la reabre con [done] falso).
  Future<void> setSetupDone(String id, bool done) async {
    await (db.update(db.events)..where((e) => e.id.equals(id))).write(
        EventsCompanion(
            setupDone: Value(done), updatedAt: Value(DateTime.now().toUtc())));
  }

  Future<String> createEvent({
    required String name,
    required String startDate,
    required String endDate,
    String venue = '',
    String organizer = '',
    bool offersLodging = true,
    bool offersTeams = true,
    bool setupDone = true, // la pantalla «Crear evento» lo pasa en falso
  }) async {
    final now = DateTime.now().toUtc();
    final dev = await db.deviceId();
    final id = newUuidV7();
    await db.transaction(() async {
      await db.into(db.events).insert(EventsCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            originDeviceId: dev,
            name: name.trim(),
            startDate: startDate,
            endDate: endDate,
            venue: Value(venue.trim()),
            organizer: Value(organizer.trim()),
            offersLodging: Value(offersLodging),
            offersTeams: Value(offersTeams),
            setupDone: Value(setupDone),
          ));
      // Rangos de edad por defecto, editables luego por evento.
      var order = 0;
      for (final r in AgeRange.defaults) {
        await db.into(db.ageRanges).insert(AgeRangesCompanion.insert(
              id: newUuidV7(),
              createdAt: now,
              updatedAt: now,
              originDeviceId: dev,
              eventId: id,
              label: r.label,
              minAge: r.minAge,
              maxAge: Value(r.maxAge),
              sortOrder: Value(order++),
            ));
      }
    });
    return id;
  }

  /// Borra de verdad (no solo lógico) el evento y TODO lo suyo: asistentes, hospedajes, equipos,
  /// sesiones y marcas. Es irreversible; las iglesias del catálogo se conservan. Solo administrador.
  /// Cuenta cuántas personas se borraron.
  Future<int> deleteEventPermanently(String eventId,
      {required bool isAdmin}) async {
    if (!isAdmin) {
      throw DataException('Solo el administrador puede eliminar un evento.');
    }
    return db.transaction(() async {
      final sessions = (await (db.select(db.controlSessions)
                ..where((s) => s.eventId.equals(eventId)))
              .get())
          .map((s) => s.id)
          .toList();
      final groups = (await (db.select(db.attendeeGroups)
                ..where((g) => g.eventId.equals(eventId)))
              .get())
          .map((g) => g.id)
          .toList();
      await (db.delete(db.controlRecords)
            ..where((r) => r.sessionId.isIn(sessions)))
          .go();
      await (db.delete(db.controlSessions)
            ..where((s) => s.eventId.equals(eventId)))
          .go();
      await (db.delete(db.controlTypes)
            ..where((t) => t.eventId.equals(eventId)))
          .go();
      await (db.delete(db.groupMembers)..where((m) => m.groupId.isIn(groups)))
          .go();
      await (db.delete(db.attendeeGroups)
            ..where((g) => g.eventId.equals(eventId)))
          .go();
      await (db.delete(db.couples)..where((c) => c.eventId.equals(eventId)))
          .go();
      final people = await (db.delete(db.attendees)
            ..where((a) => a.eventId.equals(eventId)))
          .go();
      await (db.delete(db.lodgings)..where((l) => l.eventId.equals(eventId)))
          .go();
      await (db.delete(db.teams)..where((t) => t.eventId.equals(eventId))).go();
      await (db.delete(db.ageRanges)..where((r) => r.eventId.equals(eventId)))
          .go();
      await (db.delete(db.events)..where((e) => e.id.equals(eventId))).go();
      return people;
    });
  }

  Stream<List<Event>> watchEvents() => (db.select(db.events)
        ..where((e) => e.deletedAt.isNull())
        ..orderBy([(e) => OrderingTerm.desc(e.createdAt)]))
      .watch();

  Stream<Event> watchEvent(String id) =>
      (db.select(db.events)..where((e) => e.id.equals(id))).watchSingle();

  Future<List<AgeRange>> ageRanges(String eventId) async {
    final rows = await (db.select(db.ageRanges)
          ..where((r) => r.eventId.equals(eventId) & r.deletedAt.isNull())
          ..orderBy([(r) => OrderingTerm.asc(r.sortOrder)]))
        .get();
    return [for (final r in rows) AgeRange(r.label, r.minAge, r.maxAge)];
  }

  /// «Recordar más tarde» del aviso de contraseña inicial: lo oculta hasta el día siguiente.
  Future<void> snoozePasswordReminder([DateTime? now]) => (db.update(db.appMeta)
        ..where((m) => m.key.equals(1)))
      .write(AppMetaCompanion(
          passwordReminderHiddenAt: Value((now ?? DateTime.now()).toUtc())));

  // ───────────────────────── Iglesias (catálogo) ─────────────────────────

  Stream<List<ChurchRow>> watchChurches() => (db.select(db.churches)
        ..where((c) => c.deletedAt.isNull())
        ..orderBy([(c) => OrderingTerm.asc(c.nameNormalized)]))
      .watch();

  /// Alta en el catálogo. Evita duplicados por escritura: mismo nombre normalizado en la misma
  /// provincia y municipio. Si ya existe lanza un error que nombra la existente.
  Future<ChurchRow> createChurch(
      {required String name,
      String province = '',
      String municipality = '',
      String community = '',
      bool requireLocation = false}) async {
    final n = name.trim();
    if (n.isEmpty) throw DataException('Falta el nombre de la iglesia.');
    // Al registrar a mano se exige dónde está (la persona hereda provincia y municipio de la iglesia).
    if (requireLocation && province.trim().isEmpty) {
      throw DataException('Falta la provincia de la iglesia.');
    }
    if (requireLocation && municipality.trim().isEmpty) {
      throw DataException('Falta el municipio de la iglesia.');
    }
    final norm = normalizeText(n);
    final same = await (db.select(db.churches)
          ..where((c) =>
              c.nameNormalized.equals(norm) &
              c.province.equals(province.trim()) &
              c.deletedAt.isNull()))
        .get();
    final muniNorm = normalizeText(municipality);
    final dup = same
        .where((c) => normalizeText(c.municipality) == muniNorm)
        .firstOrNull;
    if (dup != null) {
      throw DataException(
          'Ya existe «${dup.name}» en el catálogo para esa provincia y municipio.');
    }
    final now = DateTime.now().toUtc();
    final id = newUuidV7();
    await db.into(db.churches).insert(ChurchesCompanion.insert(
          id: id,
          createdAt: now,
          updatedAt: now,
          originDeviceId: await db.deviceId(),
          name: n,
          nameNormalized: norm,
          province: Value(province.trim()),
          municipality: Value(normalizeMunicipality(municipality)),
          community: Value(normalizeCommunity(community)),
        ));
    return (db.select(db.churches)..where((c) => c.id.equals(id))).getSingle();
  }

  /// Cambia nombre y ubicación de una iglesia (los tres obligatorios). La provincia y el municipio
  /// de sus asistentes salen de la iglesia, así que también se actualizan en ellos.
  Future<ChurchRow> updateChurch(String id,
      {required String name,
      required String province,
      required String municipality,
      String community = ''}) async {
    final n = name.trim();
    if (n.isEmpty) throw DataException('Falta el nombre de la iglesia.');
    if (province.trim().isEmpty) {
      throw DataException('Falta la provincia de la iglesia.');
    }
    if (municipality.trim().isEmpty) {
      throw DataException('Falta el municipio de la iglesia.');
    }
    return db.transaction(() async {
      final norm = normalizeText(n);
      final muni = normalizeMunicipality(municipality);
      final same = await (db.select(db.churches)
            ..where((c) =>
                c.id.equals(id).not() &
                c.nameNormalized.equals(norm) &
                c.province.equals(province.trim()) &
                c.deletedAt.isNull()))
          .get();
      final dup = same
          .where((c) => normalizeText(c.municipality) == normalizeText(muni))
          .firstOrNull;
      if (dup != null) {
        throw DataException(
            'Ya existe «${dup.name}» en el catálogo para esa provincia y municipio.');
      }
      final now = DateTime.now().toUtc();
      await (db.update(db.churches)..where((c) => c.id.equals(id))).write(
          ChurchesCompanion(
              name: Value(n),
              nameNormalized: Value(norm),
              province: Value(province.trim()),
              municipality: Value(muni),
              community: Value(normalizeCommunity(community)),
              updatedAt: Value(now)));
      await (db.update(db.attendees)..where((a) => a.churchId.equals(id)))
          .write(AttendeesCompanion(
              province: Value(province.trim()),
              municipality: Value(muni),
              updatedAt: Value(now)));
      return (db.select(db.churches)..where((c) => c.id.equals(id)))
          .getSingle();
    });
  }

  /// Cuántos asistentes (de cualquier evento) tiene cada iglesia.
  Future<Map<String, int>> churchAttendeeCounts() async {
    final c = db.attendees.id.count();
    final q = db.selectOnly(db.attendees)
      ..addColumns([db.attendees.churchId, c])
      ..where(
          db.attendees.deletedAt.isNull() & db.attendees.churchId.isNotNull())
      ..groupBy([db.attendees.churchId]);
    return {
      for (final r in await q.get()) r.read(db.attendees.churchId)!: r.read(c)!
    };
  }

  /// Borrado lógico. Se BLOQUEA si la iglesia tiene asistentes (dice cuántos).
  Future<void> deleteChurch(String id) async {
    final n = (await churchAttendeeCounts())[id] ?? 0;
    if (n > 0) {
      throw DataException(
          'No se puede eliminar: tiene $n ${n == 1 ? 'asistente' : 'asistentes'}. Cámbialos de iglesia primero.');
    }
    final now = DateTime.now().toUtc();
    await (db.update(db.churches)..where((c) => c.id.equals(id)))
        .write(ChurchesCompanion(deletedAt: Value(now), updatedAt: Value(now)));
  }

  /// Iglesias cuyo nombre contiene el texto (sin importar tildes ni mayúsculas).
  static List<ChurchRow> filterChurches(List<ChurchRow> all, String query,
      {int limit = 6}) {
    final q = normalizeText(query);
    if (q.isEmpty) return const [];
    final words = q.split(' ');
    return all
        .where((c) => words.every(c.nameNormalized.contains))
        .take(limit)
        .toList();
  }

  // ───────────────────────── Asistentes ─────────────────────────

  /// Registra un asistente con el siguiente número de inscripción del evento.
  Future<AttendeeRow> addAttendee({
    required String eventId,
    required String firstName,
    required String lastName1,
    String lastName2 = '',
    required Sex sex,
    required int age,
    String? churchId,
    String? phone,
    String province = '',
    String municipality = '',
    bool needsLodging = false,
    String notes = '',
    String? createdBy,
    int? preferredRegNumber,
    bool preregistered = false,
    bool registeredAtControl = false,
  }) async {
    _validate(firstName, lastName1, age);
    final now = DateTime.now().toUtc();
    final dev = await db.deviceId();
    final id = newUuidV7();
    await db.transaction(() async {
      // Número pedido (p. ej. el del CSV): se respeta si está libre en el evento (cuentan también
      // los borrados, porque su número sigue reservado); si no, el siguiente (QA-BUG-008).
      int? regNumber;
      if (preferredRegNumber != null && preferredRegNumber > 0) {
        final taken = await (db.selectOnly(db.attendees)
              ..addColumns([db.attendees.id])
              ..where(db.attendees.eventId.equals(eventId) &
                  db.attendees.regNumber.equals(preferredRegNumber)))
            .get();
        if (taken.isEmpty) regNumber = preferredRegNumber;
      }
      final maxReg = db.attendees.regNumber.max();
      final cur = await (db.selectOnly(db.attendees)
            ..addColumns([maxReg])
            ..where(db.attendees.eventId.equals(eventId)))
          .map((r) => r.read(maxReg))
          .getSingle();
      await db.into(db.attendees).insert(AttendeesCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            originDeviceId: dev,
            eventId: eventId,
            regNumber: regNumber ?? (cur ?? 0) + 1,
            firstName: firstName.trim(),
            lastName1: lastName1.trim(),
            lastName2: Value(lastName2.trim()),
            sex: sex == Sex.male ? 'M' : 'F',
            age: age,
            churchId: Value(churchId),
            phone: Value(_blankToNull(phone)),
            province: Value(province.trim()),
            municipality: Value(municipality.trim()),
            needsLodging: Value(needsLodging),
            notes: Value(notes.trim()),
            dedupeKey: dedupeKey(firstName, lastName1),
            createdBy: Value(createdBy),
            registeredAtControl: Value(registeredAtControl),
            status: Value(preregistered ? 'preregistered' : 'confirmed'),
            confirmedAt: Value(preregistered ? null : now),
          ));
    });
    return (db.select(db.attendees)..where((a) => a.id.equals(id))).getSingle();
  }

  /// Confirma la asistencia de [ids] (preinscritos → confirmados). Devuelve cuántos cambiaron;
  /// los que ya estaban confirmados o no existen se ignoran. Todo o nada.
  Future<int> confirmAttendance(Iterable<String> ids) =>
      _setAttendanceStatus(ids, confirmed: true);

  /// Desconfirma (vuelve a preinscrito): para corregir un error. Se BLOQUEA (todo o nada) si alguna
  /// persona ya tiene comidas marcadas: primero hay que quitar esas marcas en Comidas.
  Future<int> unconfirmAttendance(Iterable<String> ids) async {
    final list = ids.toSet().toList();
    if (list.isEmpty) return 0;
    final blocked = <String, int>{};
    for (var i = 0; i < list.length; i += 500) {
      final chunk = list.sublist(i, (i + 500).clamp(0, list.length));
      final recs = await (db.select(db.controlRecords)
            ..where((r) =>
                r.attendeeId.isIn(chunk) &
                r.undoneAt.isNull() &
                r.deletedAt.isNull()))
          .get();
      for (final r in recs) {
        blocked[r.attendeeId] = (blocked[r.attendeeId] ?? 0) + 1;
      }
    }
    if (blocked.isNotEmpty) {
      final people = await (db.select(db.attendees)
            ..where((a) => a.id.isIn(blocked.keys)))
          .get();
      final names = people
          .take(3)
          .map((p) =>
              '${p.firstName} ${p.lastName1} (${blocked[p.id]} ${blocked[p.id] == 1 ? 'comida' : 'comidas'})')
          .join(', ');
      throw DataException(
          'No se puede desconfirmar: ${people.length == 1 ? 'tiene' : 'tienen'} comidas marcadas: $names${people.length > 3 ? '…' : ''}. Quita primero esas marcas en Comidas.');
    }
    return _setAttendanceStatus(list, confirmed: false);
  }

  Future<int> _setAttendanceStatus(Iterable<String> ids,
      {required bool confirmed}) async {
    final list = ids.toSet().toList();
    if (list.isEmpty) return 0;
    final now = DateTime.now().toUtc();
    final from = confirmed ? 'preregistered' : 'confirmed';
    return db.transaction(() async {
      var n = 0;
      for (var i = 0; i < list.length; i += 500) {
        final chunk = list.sublist(i, (i + 500).clamp(0, list.length));
        n += await (db.update(db.attendees)
              ..where((a) =>
                  a.id.isIn(chunk) &
                  a.status.equals(from) &
                  a.deletedAt.isNull()))
            .write(AttendeesCompanion(
                status: Value(confirmed ? 'confirmed' : 'preregistered'),
                confirmedAt: Value(confirmed ? now : null),
                updatedAt: Value(now)));
      }
      return n;
    });
  }

  Future<void> updateAttendee(
    String id, {
    required String firstName,
    required String lastName1,
    String lastName2 = '',
    required Sex sex,
    required int age,
    String? churchId,
    String? phone,
    String province = '',
    String municipality = '',
    bool needsLodging = false,
    String notes = '',
  }) async {
    _validate(firstName, lastName1, age);
    await db.transaction(() async {
      final before = await attendeeById(id);
      // Cambiar el sexo no puede dejar un matrimonio del mismo sexo.
      if (before != null &&
          before.coupleId != null &&
          before.sex != (sex == Sex.male ? 'M' : 'F')) {
        final mate = await SocialRepo(db).spouseOf(id);
        if (mate != null && mate.sex == (sex == Sex.male ? 'M' : 'F')) {
          throw DataException(
              'No se puede cambiar el sexo: ${mate.firstName} ${mate.lastName1}, su cónyuge, quedaría del mismo sexo. Desvincula primero el matrimonio.');
        }
      }
      await (db.update(db.attendees)..where((a) => a.id.equals(id)))
          .write(AttendeesCompanion(
        firstName: Value(firstName.trim()),
        lastName1: Value(lastName1.trim()),
        lastName2: Value(lastName2.trim()),
        sex: Value(sex == Sex.male ? 'M' : 'F'),
        age: Value(age),
        churchId: Value(churchId),
        phone: Value(_blankToNull(phone)),
        province: Value(province.trim()),
        municipality: Value(municipality.trim()),
        needsLodging: Value(needsLodging),
        notes: Value(notes.trim()),
        dedupeKey: Value(dedupeKey(firstName, lastName1)),
        updatedAt: Value(DateTime.now().toUtc()),
      ));
      // Cambiar el sexo de alguien hospedado no puede dejarlo en un hospedaje que no lo acepta.
      final lid = before?.lodgingId;
      if (before != null &&
          lid != null &&
          before.sex != (sex == Sex.male ? 'M' : 'F')) {
        final problems = await LodgingRepo(db).compatibilityProblems(lid, [id]);
        if (problems.isNotEmpty) throw LodgingIncompatibleException(problems);
      }
    });
  }

  /// Borrado lógico (se conserva para poder fusionar datos entre dispositivos). Solo administrador.
  /// Borra (lógicamente) a un asistente y limpia todo lo que lo mencionaba: su pareja (el cónyuge
  /// queda sin pareja), su equipo, su hospedaje, su cargo de capitán y sus grupos (QA-BUG-004).
  /// Devuelve el nombre del equipo que se queda sin capitán, o nulo si no era capitán.
  Future<String?> deleteAttendee(String id, {required bool isAdmin}) async {
    if (!isAdmin) {
      throw DataException('Solo el administrador puede eliminar asistentes.');
    }
    return db.transaction(() async {
      final now = DateTime.now().toUtc();
      final a = await (db.select(db.attendees)..where((x) => x.id.equals(id)))
          .getSingleOrNull();
      if (a == null) return null;
      if (a.coupleId != null) {
        await (db.update(db.couples)..where((c) => c.id.equals(a.coupleId!)))
            .write(
                CouplesCompanion(deletedAt: Value(now), updatedAt: Value(now)));
        await (db.update(db.attendees)
              ..where((r) => r.coupleId.equals(a.coupleId!)))
            .write(AttendeesCompanion(
                coupleId: const Value(null), updatedAt: Value(now)));
      }
      final captainOf = await (db.select(db.teams)
            ..where((t) => t.captainId.equals(id) & t.deletedAt.isNull()))
          .get();
      if (captainOf.isNotEmpty) {
        await (db.update(db.teams)..where((t) => t.captainId.equals(id))).write(
            TeamsCompanion(
                captainId: const Value(null), updatedAt: Value(now)));
      }
      await (db.update(db.groupMembers)
            ..where((m) => m.attendeeId.equals(id) & m.deletedAt.isNull()))
          .write(GroupMembersCompanion(
              deletedAt: Value(now), updatedAt: Value(now)));
      await (db.update(db.attendees)..where((x) => x.id.equals(id))).write(
          AttendeesCompanion(
              deletedAt: Value(now),
              updatedAt: Value(now),
              coupleId: const Value(null),
              teamId: const Value(null),
              lodgingId: const Value(null)));
      return captainOf.isEmpty ? null : captainOf.first.name;
    });
  }

  Future<AttendeeRow?> attendeeById(String id) =>
      (db.select(db.attendees)..where((a) => a.id.equals(id)))
          .getSingleOrNull();

  /// Asistentes del evento (más recientes primero) con su iglesia, en vivo.
  Stream<List<AttendeeView>> watchAttendees(String eventId) {
    final q = db.select(db.attendees).join([
      leftOuterJoin(
          db.churches, db.churches.id.equalsExp(db.attendees.churchId)),
    ])
      ..where(db.attendees.eventId.equals(eventId) &
          db.attendees.deletedAt.isNull())
      ..orderBy([OrderingTerm.desc(db.attendees.regNumber)]);
    return q.watch().map((rows) => [
          for (final r in rows)
            AttendeeView(r.readTable(db.attendees),
                r.readTableOrNull(db.churches)?.name),
        ]);
  }

  /// Búsqueda por nombre (cualquier orden de palabras, sin tildes) o por número de inscripción.
  /// Búsqueda por nombre y número (y por iglesia si [includeChurch]; las pantallas que ya tienen un
  /// filtro de iglesia la desactivan: la búsqueda solo cubre lo que NO tiene filtro propio).
  static List<AttendeeView> search(List<AttendeeView> all, String query,
      {bool includeChurch = true}) {
    final q = normalizeText(query);
    if (q.isEmpty) return all;
    final n = int.tryParse(q);
    final words = q.split(' ');
    return all.where((v) {
      if (n != null && v.a.regNumber == n) return true;
      final hay = normalizeText(
          '${v.fullName} ${includeChurch ? v.churchName ?? '' : ''}');
      return words.every(hay.contains);
    }).toList();
  }

  Stream<int> watchAttendeeCount(String eventId) {
    final c = db.attendees.id.count();
    return (db.selectOnly(db.attendees)
          ..addColumns([c])
          ..where(db.attendees.eventId.equals(eventId) &
              db.attendees.deletedAt.isNull()))
        .map((r) => r.read(c) ?? 0)
        .watchSingle();
  }

  /// Posibles duplicados (solo aviso). [excludeId] evita avisar de la propia ficha al editar.
  Future<List<AttendeeRow>> possibleDuplicates(String eventId,
      {required String firstName,
      required String lastName1,
      String lastName2 = '',
      int? age,
      String? excludeId}) async {
    if (normalizeText(firstName).isEmpty || normalizeText(lastName1).isEmpty) {
      return const [];
    }
    final key = dedupeKey(firstName, lastName1);
    final rows = await (db.select(db.attendees)
          ..where((a) =>
              a.eventId.equals(eventId) &
              a.dedupeKey.equals(key) &
              a.deletedAt.isNull() &
              a.id.equals(excludeId ?? '').not()))
        .get();
    // Con segundo apellido escrito, coincide con quien tenga el mismo o no tenga ninguno anotado.
    final ln2 = normalizeText(lastName2);
    return rows
        .where((r) => age == null || age <= 0 || r.age == age)
        .where((r) =>
            ln2.isEmpty ||
            r.lastName2.trim().isEmpty ||
            normalizeText(r.lastName2) == ln2)
        .toList();
  }

  void _validate(String firstName, String lastName1, int age) {
    if (firstName.trim().isEmpty) throw DataException('Falta el nombre.');
    if (lastName1.trim().isEmpty) {
      throw DataException('Falta el primer apellido.');
    }
    if (age < 1 || age > 110) {
      throw DataException('La edad debe estar entre 1 y 110 años.');
    }
  }

  String? _blankToNull(String? s) =>
      (s == null || s.trim().isEmpty) ? null : s.trim();
}

/// Municipio sin espacios sobrantes (se conserva la escritura original: es solo informativo).
String normalizeMunicipality(String s) => s.trim();

/// Comunidad: sin espacios de más (varios espacios seguidos pasan a uno).
String normalizeCommunity(String s) => s.trim().replaceAll(RegExp(r'\s+'), ' ');

/// Comunidades ya registradas en un municipio (de las iglesias del catálogo), sin repetir y ordenadas.
/// Insensible a tildes y mayúsculas al comparar provincia y municipio.
List<String> communitiesOf(
    List<ChurchRow> churches, String province, String municipality) {
  final p = normalizeText(province), m = normalizeText(municipality);
  final seen = <String, String>{};
  for (final c in churches) {
    if (c.deletedAt != null || c.community.trim().isEmpty) continue;
    if (normalizeText(c.province) != p || normalizeText(c.municipality) != m) {
      continue;
    }
    seen.putIfAbsent(normalizeText(c.community), () => c.community);
  }
  return seen.values.toList()
    ..sort((a, b) => normalizeText(a).compareTo(normalizeText(b)));
}
