import 'package:drift/drift.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'database.dart';
import 'repository.dart' show DataException;

/// Sesión con el nombre de su tipo («Almuerzo»).
class SessionView {
  const SessionView(this.row, this.typeName);
  final ControlSession row;
  final String typeName;
  bool get closed => row.closedAt != null;
}

/// Resultado de marcar: [already] = ya tenía registro activo y no se creó otro.
class MarkResult {
  const MarkResult.created(this.record) : already = false;
  const MarkResult.already(this.record) : already = true;
  final ControlRecord record;
  final bool already;
}

/// Control de comidas y otros registros por persona: tipos, sesiones y marcas.
class MealRepo {
  MealRepo(this.db);
  final AppDatabase db;

  static const defaultTypes = ['Desayuno', 'Almuerzo', 'Cena'];

  // ── Tipos ──

  Stream<List<ControlType>> watchTypes(String eventId) =>
      (db.select(db.controlTypes)
            ..where((t) => t.eventId.equals(eventId) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .watch();

  Future<List<ControlType>> types(String eventId) => (db.select(db.controlTypes)
        ..where((t) => t.eventId.equals(eventId) & t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
      .get();

  /// Crea Desayuno, Almuerzo y Cena la primera vez. No hace nada si el evento ya tiene tipos.
  Future<void> ensureDefaultTypes(String eventId) async {
    if ((await types(eventId)).isNotEmpty) return;
    for (final n in defaultTypes) {
      await createType(eventId, n);
    }
  }

  Future<ControlType> createType(String eventId, String name) async {
    final n = name.trim();
    if (n.isEmpty) throw DataException('Falta el nombre del tipo de control.');
    final all = await types(eventId);
    if (all.any((t) => normalizeText(t.name) == normalizeText(n))) {
      throw DataException('Ya existe el tipo «$n».');
    }
    final now = DateTime.now().toUtc();
    final id = newUuidV7();
    await db.into(db.controlTypes).insert(ControlTypesCompanion.insert(
          id: id,
          createdAt: now,
          updatedAt: now,
          originDeviceId: await db.deviceId(),
          eventId: eventId,
          name: n,
          sortOrder: Value(all.length),
        ));
    return (db.select(db.controlTypes)..where((t) => t.id.equals(id)))
        .getSingle();
  }

  /// Solo se puede borrar un tipo que no tenga sesiones.
  Future<void> deleteType(String typeId) async {
    final used = await (db.select(db.controlSessions)
          ..where((s) => s.controlTypeId.equals(typeId) & s.deletedAt.isNull()))
        .get();
    if (used.isNotEmpty) {
      throw DataException('Ese tipo ya tiene sesiones; no se puede eliminar.');
    }
    final now = DateTime.now().toUtc();
    await (db.update(db.controlTypes)..where((t) => t.id.equals(typeId))).write(
        ControlTypesCompanion(deletedAt: Value(now), updatedAt: Value(now)));
  }

  // ── Sesiones ──

  Stream<List<SessionView>> watchSessions(String eventId) {
    final q = db.select(db.controlSessions).join([
      innerJoin(db.controlTypes,
          db.controlTypes.id.equalsExp(db.controlSessions.controlTypeId)),
    ])
      ..where(db.controlSessions.eventId.equals(eventId) &
          db.controlSessions.deletedAt.isNull())
      ..orderBy([OrderingTerm.desc(db.controlSessions.openedAt)]);
    return q.watch().map((rows) => [
          for (final r in rows)
            SessionView(r.readTable(db.controlSessions),
                r.readTable(db.controlTypes).name),
        ]);
  }

  Future<ControlSession> createSession(
      String eventId, String typeId, String name,
      {String operatorName = ''}) async {
    final n = name.trim();
    if (n.isEmpty) throw DataException('Falta el nombre de la sesión.');
    final existing = await (db.select(db.controlSessions)
          ..where((s) => s.eventId.equals(eventId) & s.deletedAt.isNull()))
        .get();
    if (existing.any((s) => normalizeText(s.name) == normalizeText(n))) {
      throw DataException('Ya existe una sesión llamada «$n».');
    }
    final now = DateTime.now().toUtc();
    final id = newUuidV7();
    await db.into(db.controlSessions).insert(ControlSessionsCompanion.insert(
          id: id,
          createdAt: now,
          updatedAt: now,
          originDeviceId: await db.deviceId(),
          eventId: eventId,
          controlTypeId: typeId,
          name: n,
          openedAt: Value(now),
          operatorName: Value(operatorName),
        ));
    return (db.select(db.controlSessions)..where((s) => s.id.equals(id)))
        .getSingle();
  }

  Future<void> closeSession(String id) =>
      _setClosed(id, DateTime.now().toUtc());
  Future<void> reopenSession(String id) => _setClosed(id, null);

  Future<void> _setClosed(String id, DateTime? at) =>
      (db.update(db.controlSessions)..where((s) => s.id.equals(id))).write(
          ControlSessionsCompanion(
              closedAt: Value(at), updatedAt: Value(DateTime.now().toUtc())));

  Future<void> deleteSession(String id, {required bool isAdmin}) async {
    if (!isAdmin) {
      throw DataException('Solo el administrador puede eliminar sesiones.');
    }
    final now = DateTime.now().toUtc();
    await (db.update(db.controlSessions)..where((s) => s.id.equals(id))).write(
        ControlSessionsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
  }

  // ── Marcas ──

  /// Registros ACTIVOS (no deshechos) de la sesión, en vivo, del más reciente al más antiguo.
  Stream<List<ControlRecord>> watchRecords(String sessionId) =>
      (db.select(db.controlRecords)
            ..where((r) =>
                r.sessionId.equals(sessionId) &
                r.undoneAt.isNull() &
                r.deletedAt.isNull())
            ..orderBy([(r) => OrderingTerm.desc(r.markedAt)]))
          .watch();

  /// Marca que [attendeeId] pasó. Si ya tenía registro activo NO crea otro y devuelve
  /// [MarkResult.already] con el existente; con [repeat] = true crea uno nuevo igualmente
  /// (el usuario decidió continuar tras el aviso).
  Future<MarkResult> mark(String sessionId, String attendeeId,
      {required String operatorName, bool repeat = false}) async {
    return db.transaction(() async {
      final s = await (db.select(db.controlSessions)
            ..where((x) => x.id.equals(sessionId)))
          .getSingle();
      if (s.closedAt != null) {
        throw DataException('Esta sesión está cerrada. Reábrela para marcar.');
      }
      final a = await (db.select(db.attendees)
            ..where((x) => x.id.equals(attendeeId) & x.deletedAt.isNull()))
          .getSingleOrNull();
      if (a == null) throw DataException('Esa persona ya no está inscrita.');
      if (a.status == 'preregistered') {
        throw DataException(
            'Esa persona está preinscrita: confirma primero su asistencia.');
      }
      final active = await (db.select(db.controlRecords)
            ..where((r) =>
                r.sessionId.equals(sessionId) &
                r.attendeeId.equals(attendeeId) &
                r.undoneAt.isNull() &
                r.deletedAt.isNull())
            ..orderBy([(r) => OrderingTerm.asc(r.markedAt)]))
          .get();
      if (active.isNotEmpty && !repeat) return MarkResult.already(active.first);
      final now = DateTime.now().toUtc();
      final id = newUuidV7();
      await db.into(db.controlRecords).insert(ControlRecordsCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            originDeviceId: await db.deviceId(),
            sessionId: sessionId,
            attendeeId: attendeeId,
            markedAt: now,
            operatorName: Value(operatorName),
            repeatOverride: Value(active.isNotEmpty),
          ));
      return MarkResult.created(await (db.select(db.controlRecords)
            ..where((r) => r.id.equals(id)))
          .getSingle());
    });
  }

  /// Deshace una marca (queda guardada con la hora en que se deshizo).
  Future<void> undo(String recordId) async {
    final now = DateTime.now().toUtc();
    await (db.update(db.controlRecords)..where((r) => r.id.equals(recordId)))
        .write(ControlRecordsCompanion(
            undoneAt: Value(now), updatedAt: Value(now)));
  }

  /// Cuenta un aviso de «ya pasó» en que NO se volvió a marcar.
  Future<void> registerBlocked(String sessionId) async {
    final s = await (db.select(db.controlSessions)
          ..where((x) => x.id.equals(sessionId)))
        .getSingle();
    await (db.update(db.controlSessions)..where((x) => x.id.equals(sessionId)))
        .write(ControlSessionsCompanion(
            blockedRepeats: Value(s.blockedRepeats + 1),
            updatedAt: Value(DateTime.now().toUtc())));
  }
}
