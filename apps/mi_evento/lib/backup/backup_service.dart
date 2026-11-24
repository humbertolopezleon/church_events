import 'dart:io';

import 'package:drift/drift.dart';
import 'package:mi_evento_core/mi_evento_core.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/database.dart';

/// Qué pasó al importar una copia (para mostrarlo al usuario).
class ImportReport {
  ImportReport(this.eventId, this.eventName);
  final String eventId;
  final String eventName;
  int inserted = 0; // filas nuevas
  int updated = 0; // filas locales reemplazadas por otras más recientes
  int skipped = 0; // filas iguales o más viejas que las locales
  int renumbered = 0; // asistentes cuyo nº de inscripción chocaba y se renumeró
  int churchesMerged = 0; // iglesias que ya existían con otro id y se unieron

  int get total => inserted + updated + skipped;
  bool get changedAnything => inserted + updated > 0;
}

/// Copias de un evento: exportar a un único CSV e importar (con fusión por id).
/// NO incluye usuarios ni contraseñas: cada dispositivo tiene los suyos.
class BackupService {
  BackupService(this.db);
  final AppDatabase db;

  /// Todas las filas del evento (incluidas las borradas lógicamente, para que el borrado también viaje).
  Future<Map<String, List<Map<String, Object?>>>> collect(
      String eventId) async {
    List<Map<String, Object?>> j<T>(Iterable<Insertable<T>> rows) =>
        [for (final r in rows) (r as DataClass).toJson()];
    final sessions = await (db.select(db.controlSessions)
          ..where((s) => s.eventId.equals(eventId)))
        .get();
    final groups = await (db.select(db.attendeeGroups)
          ..where((g) => g.eventId.equals(eventId)))
        .get();
    final attendees = await (db.select(db.attendees)
          ..where((a) => a.eventId.equals(eventId)))
        .get();
    final churchIds = {
      for (final a in attendees)
        if (a.churchId != null) a.churchId!
    };
    return {
      'events': j(await (db.select(db.events)
            ..where((e) => e.id.equals(eventId)))
          .get()),
      'ageRanges': j(await (db.select(db.ageRanges)
            ..where((r) => r.eventId.equals(eventId)))
          .get()),
      'churches': j(churchIds.isEmpty
          ? <ChurchRow>[]
          : await (db.select(db.churches)..where((c) => c.id.isIn(churchIds)))
              .get()),
      'teams': j(await (db.select(db.teams)
            ..where((t) => t.eventId.equals(eventId)))
          .get()),
      'lodgings': j(await (db.select(db.lodgings)
            ..where((l) => l.eventId.equals(eventId)))
          .get()),
      'attendees': j(attendees),
      'couples': j(await (db.select(db.couples)
            ..where((c) => c.eventId.equals(eventId)))
          .get()),
      'groups': j(groups),
      'groupMembers': j(groups.isEmpty
          ? <GroupMember>[]
          : await (db.select(db.groupMembers)
                ..where((m) => m.groupId.isIn(groups.map((g) => g.id))))
              .get()),
      'controlTypes': j(await (db.select(db.controlTypes)
            ..where((t) => t.eventId.equals(eventId)))
          .get()),
      'controlSessions': j(sessions),
      'controlRecords': j(sessions.isEmpty
          ? <ControlRecord>[]
          : await (db.select(db.controlRecords)
                ..where((r) => r.sessionId.isIn(sessions.map((s) => s.id))))
              .get()),
    };
  }

  /// Arma el CSV de respaldo de un evento (un solo archivo; ver `encodeBundle`).
  Future<Uint8List> export(String eventId, {DateTime? now}) async {
    final tables = await collect(eventId);
    final ev = await (db.select(db.events)..where((e) => e.id.equals(eventId)))
        .getSingle();
    return encodeBundle(
      tables: tables,
      dbSchemaVersion: db.schemaVersion,
      deviceId: await db.deviceId(),
      eventId: eventId,
      eventName: ev.name,
      now: now,
    );
  }

  /// Nombre de archivo: `retiro-de-jovenes-2026-12-12-183015.csv` (con segundos: dos copias
  /// seguidas no se pisan, y el orden alfabético es el cronológico).
  static String fileName(String eventName, DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    final slug = normalizeText(eventName).replaceAll(' ', '-');
    return '${slug.isEmpty ? 'evento' : slug}-${t.year}-${two(t.month)}-${two(t.day)}-${two(t.hour)}${two(t.minute)}${two(t.second)}.$backupFileExtension';
  }

  /// Fusiona la copia con los datos locales. Regla: gana la fila con `updatedAt` más reciente; en
  /// empate se conserva la local. Se hace todo o nada (transacción).
  Future<ImportReport> import(Bundle b) async {
    final rep = ImportReport(b.manifest.eventId, b.manifest.eventName);
    // Las celdas del CSV son texto: se convierten a su tipo según el esquema de cada tabla.
    List<Map<String, Object?>> t(String n) => [
          for (final r in b.tables[n] ?? const <Map<String, String>>[])
            _typed(_tableByName[n]!(db), r)
        ];

    await db.transaction(() async {
      // Iglesias: dos dispositivos pueden haber creado la «misma» con ids distintos (índice único).
      final churchMap = <String, String>{};
      final localChurches = await db.select(db.churches).get();
      final byKey = {
        for (final c in localChurches)
          '${c.nameNormalized}|${c.province}|${normalizeText(c.municipality)}':
              c.id
      };
      final byId = {for (final c in localChurches) c.id: c};
      for (final j in t('churches')) {
        final inc = ChurchRow.fromJson(j);
        if (byId.containsKey(inc.id)) {
          _count(
              rep,
              await _put(db.churches, inc,
                  incomingWins(byId[inc.id]!.updatedAt, inc.updatedAt)));
        } else if (byKey.containsKey(
            '${inc.nameNormalized}|${inc.province}|${normalizeText(inc.municipality)}')) {
          churchMap[inc.id] = byKey[
              '${inc.nameNormalized}|${inc.province}|${normalizeText(inc.municipality)}']!;
          rep.churchesMerged++;
        } else {
          await db.into(db.churches).insert(inc);
          rep.inserted++;
        }
      }

      Future<void> merge<TT extends Table, D extends DataClass>(
        TableInfo<TT, D> table,
        String name,
        D Function(Map<String, dynamic>) fromJson,
        String Function(D) idOf,
        DateTime Function(D) updatedOf,
      ) async {
        final local = {
          for (final r in await db.select(table).get()) idOf(r): updatedOf(r)
        };
        for (final j in t(name)) {
          final inc = fromJson(j);
          final ex = local[idOf(inc)];
          if (ex == null) {
            await db.into(table).insert(inc as Insertable<D>);
            rep.inserted++;
          } else {
            _count(
                rep, await _put(table, inc, incomingWins(ex, updatedOf(inc))));
          }
        }
      }

      // Copias de versiones anteriores no traen las columnas nuevas: se completan con su valor
      // por defecto en vez de fallar.
      await merge(
          db.events, 'events', Event.fromJson, (r) => r.id, (r) => r.updatedAt);
      await merge(db.ageRanges, 'ageRanges', AgeRangeRow.fromJson, (r) => r.id,
          (r) => r.updatedAt);
      await merge(
          db.teams, 'teams', TeamRow.fromJson, (r) => r.id, (r) => r.updatedAt);
      await merge(db.lodgings, 'lodgings', LodgingRow.fromJson, (r) => r.id,
          (r) => r.updatedAt);

      // Asistentes: reasigna iglesias unidas y evita chocar con el nº de inscripción de otra persona.
      final local = await db.select(db.attendees).get();
      final localById = {for (final a in local) a.id: a};
      final regTaken = {
        for (final a in local) '${a.eventId}|${a.regNumber}': a.id
      };
      final maxReg = <String, int>{};
      for (final a in local) {
        if (a.regNumber > (maxReg[a.eventId] ?? 0)) {
          maxReg[a.eventId] = a.regNumber;
        }
      }
      for (final j in t('attendees')) {
        var inc = AttendeeRow.fromJson(j);
        if (inc.churchId != null && churchMap.containsKey(inc.churchId)) {
          inc = inc.copyWith(churchId: Value(churchMap[inc.churchId]));
        }
        final ex = localById[inc.id];
        if (ex == null) {
          final holder = regTaken['${inc.eventId}|${inc.regNumber}'];
          if (holder != null && holder != inc.id) {
            final next = (maxReg[inc.eventId] ?? 0) + 1;
            inc = inc.copyWith(regNumber: next);
            rep.renumbered++;
          }
          regTaken['${inc.eventId}|${inc.regNumber}'] = inc.id;
          if (inc.regNumber > (maxReg[inc.eventId] ?? 0)) {
            maxReg[inc.eventId] = inc.regNumber;
          }
          await db.into(db.attendees).insert(inc);
          rep.inserted++;
        } else {
          _count(
              rep,
              await _put(db.attendees, inc,
                  incomingWins(ex.updatedAt, inc.updatedAt)));
        }
      }

      await merge(db.couples, 'couples', Couple.fromJson, (r) => r.id,
          (r) => r.updatedAt);
      await merge(db.attendeeGroups, 'groups', AttendeeGroup.fromJson,
          (r) => r.id, (r) => r.updatedAt);
      await merge(db.groupMembers, 'groupMembers', GroupMember.fromJson,
          (r) => r.id, (r) => r.updatedAt);
      await merge(db.controlTypes, 'controlTypes', ControlType.fromJson,
          (r) => r.id, (r) => r.updatedAt);
      await merge(db.controlSessions, 'controlSessions',
          ControlSession.fromJson, (r) => r.id, (r) => r.updatedAt);
      await merge(db.controlRecords, 'controlRecords', ControlRecord.fromJson,
          (r) => r.id, (r) => r.updatedAt);
    });
    return rep;
  }

  Future<bool> _put<TT extends Table, D extends DataClass>(
      TableInfo<TT, D> table, D row, bool wins) async {
    if (!wins) return false;
    await db
        .into(table)
        .insert(row as Insertable<D>, mode: InsertMode.insertOrReplace);
    return true;
  }

  void _count(ImportReport r, bool replaced) =>
      replaced ? r.updated++ : r.skipped++;
}

/// Tabla de la base por el nombre con que viaja en el CSV de respaldo.
final Map<String, TableInfo Function(AppDatabase)> _tableByName = {
  'events': (d) => d.events,
  'ageRanges': (d) => d.ageRanges,
  'churches': (d) => d.churches,
  'teams': (d) => d.teams,
  'lodgings': (d) => d.lodgings,
  'attendees': (d) => d.attendees,
  'couples': (d) => d.couples,
  'groups': (d) => d.attendeeGroups,
  'groupMembers': (d) => d.groupMembers,
  'controlTypes': (d) => d.controlTypes,
  'controlSessions': (d) => d.controlSessions,
  'controlRecords': (d) => d.controlRecords,
};

String _camel(String snake) {
  final p = snake.split('_');
  return p.first +
      p
          .skip(1)
          .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
          .join();
}

/// Convierte una fila de texto del CSV al JSON tipado que espera `fromJson` de drift: números,
/// booleanos y fechas (milisegundos). Vacío = nulo en columnas que lo admiten y '' en las de texto.
Map<String, Object?> _typed(TableInfo table, Map<String, String> row) {
  final out = <String, Object?>{};
  for (final c in table.$columns) {
    final key = _camel(c.name);
    final raw = row[key];
    // Columna ausente: fromJson usa el valor por defecto si lo hay.
    if (raw == null) continue;
    if (raw.isEmpty) {
      if (c.$nullable) {
        out[key] = null;
      } else if (c.type == DriftSqlType.string) {
        out[key] = '';
      }
      continue;
    }
    out[key] = switch (c.type) {
      DriftSqlType.int || DriftSqlType.dateTime => int.parse(raw),
      DriftSqlType.double => double.parse(raw),
      DriftSqlType.bool => raw == 'true' || raw == '1',
      _ => raw,
    };
  }
  return out;
}

/// Una copia automática guardada en el dispositivo.
class StoredBackup {
  const StoredBackup(this.path, this.size, this.modified);
  final String path;
  final int size;
  final DateTime modified;
  String get name => p.basename(path);
}

/// Copias automáticas en una carpeta del dispositivo, con rotación (se conservan las últimas [keep]).
/// Se hace una al cerrar una sesión de comida y cada [every] cambios de asistentes.
class AutoBackup {
  AutoBackup(this.db,
      {Future<Directory> Function()? directory,
      this.keep = 10,
      this.every = 20})
      : _dir = directory ?? _defaultDir;
  final AppDatabase db;
  final Future<Directory> Function() _dir;
  final int keep;
  final int every;
  final _changes = <String, int>{};

  /// Último error al guardar una copia automática (para avisar en pantalla).
  String? lastError;

  static Future<Directory> _defaultDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final d = Directory(p.join(docs.path, 'MiEvento', 'Copias'));
    await d.create(recursive: true);
    return d;
  }

  /// Anota un cambio; guarda copia cuando se junta [every]. Nunca lanza: un fallo se guarda en [lastError].
  Future<void> noteChange(String eventId, {bool force = false}) async {
    final n = (_changes[eventId] ?? 0) + 1;
    _changes[eventId] = n;
    if (force || n >= every) await backupNow(eventId);
  }

  Future<StoredBackup?> backupNow(String eventId, {DateTime? now}) async {
    try {
      final bytes = await BackupService(db).export(eventId, now: now);
      final ev = await (db.select(db.events)
            ..where((e) => e.id.equals(eventId)))
          .getSingle();
      final dir = await _dir();
      final t = now ?? DateTime.now();
      final f = File(p.join(dir.path, BackupService.fileName(ev.name, t)));
      await f.writeAsBytes(bytes, flush: true);
      _changes[eventId] = 0;
      lastError = null;
      await markBackup(t);
      await _rotate(dir, ev.name);
      return StoredBackup(f.path, bytes.length, t);
    } catch (e) {
      lastError = '$e';
      return null;
    }
  }

  Future<void> markBackup(DateTime at) =>
      (db.update(db.appMeta)..where((m) => m.key.equals(1)))
          .write(AppMetaCompanion(lastBackupAt: Value(at.toUtc())));

  Future<void> _rotate(Directory dir, String eventName) async {
    final prefix =
        BackupService.fileName(eventName, DateTime(2000)).split('-2000').first;
    final mine = [
      for (final e in dir.listSync().whereType<File>())
        if (p.basename(e.path).startsWith('$prefix-2') &&
            e.path.endsWith('.$backupFileExtension'))
          e,
    ]..sort((a, b) => p
        .basename(b.path)
        .compareTo(p.basename(a.path))); // la fecha va en el nombre
    for (final old in mine.skip(keep)) {
      await old.delete();
    }
  }

  Future<List<StoredBackup>> list() async {
    final dir = await _dir();
    final all = [
      for (final f in dir.listSync().whereType<File>())
        if (f.path.endsWith('.$backupFileExtension'))
          StoredBackup(f.path, f.lengthSync(), f.lastModifiedSync()),
    ]..sort((a, b) => b.modified.compareTo(a.modified));
    return all;
  }
}
