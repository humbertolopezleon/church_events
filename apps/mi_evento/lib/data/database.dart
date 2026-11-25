import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:mi_evento_core/mi_evento_core.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  Events,
  Churches,
  AgeRanges,
  Attendees,
  Couples,
  AttendeeGroups,
  GroupMembers,
  Lodgings,
  Teams,
  ControlTypes,
  ControlSessions,
  ControlRecords,
  AppMeta,
  AppUsers,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Base de datos real: un único archivo SQLite en la carpeta de documentos de la app
  /// (Android: almacenamiento privado; Windows: Documentos\MiEvento).
  static Future<AppDatabase> openDefault() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'MiEvento'));
    await dir.create(recursive: true);
    return AppDatabase(NativeDatabase.createInBackground(
        File(p.join(dir.path, 'mievento.db'))));
  }

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await into(appMeta).insert(AppMetaCompanion.insert(
              key: const Value(1), deviceId: newUuidV7(), schemaVersion: 9));
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // v2: inicio de sesión y autoría de registros.
            await m.createTable(appUsers);
            await m.addColumn(appMeta, appMeta.recoveryHash);
            await m.addColumn(attendees, attendees.createdBy);
          }
          if (from < 3) {
            // v3: topes de balance de equipos por evento.
            await m.addColumn(events, events.maxSizeDiff);
            await m.addColumn(events, events.maxSexDiff);
            await m.addColumn(events, events.maxAgeDiff);
          }
          if (from < 4) {
            // v4: contador de repetidos evitados por sesión de control.
            await m.addColumn(controlSessions, controlSessions.blockedRepeats);
          }
          if (from < 5) {
            // v5: el evento declara si lleva equipos (antes siempre los permitía).
            await m.addColumn(events, events.offersTeams);
          }
          if (from < 6) {
            // v6: fase del evento (configuración → inscripciones).
            await m.addColumn(events, events.setupDone);
          }
          if (from < 7) {
            // v7: preinscripción/confirmación de asistencia y comunidad de la iglesia.
            await m.addColumn(attendees, attendees.status);
            await m.addColumn(attendees, attendees.confirmedAt);
            await m.addColumn(churches, churches.community);
          }
          if (from >= 2 && from < 8) {
            // v8: contraseña temporal con cambio obligatorio (si la tabla de usuarios ya existía;
            // en una base v1 la crea el paso v2 con la columna incluida).
            await m.addColumn(appUsers, appUsers.mustChangePassword);
          }
          if (from < 9) {
            // v9: «Recordar más tarde» del aviso de contraseña inicial.
            await m.addColumn(appMeta, appMeta.passwordReminderHiddenAt);
          }
          await (update(appMeta)..where((t) => t.key.equals(1)))
              .write(AppMetaCompanion(schemaVersion: Value(to)));
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          await customStatement('PRAGMA journal_mode = WAL');
        },
      );

  Future<String> deviceId() async =>
      (await (select(appMeta)..where((t) => t.key.equals(1))).getSingle())
          .deviceId;
}
