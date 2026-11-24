import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/repository.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

void main() {
  test(
      'migración v1 → v7 conserva los datos, habilita el inicio de sesión, los topes de equipos y el control de comidas y la opción de equipos y la fase del evento y la preinscripción',
      () async {
    final dir = await Directory.systemTemp.createTemp('mievento_mig');
    final file = File('${dir.path}/db.sqlite');
    addTearDown(() => dir.delete(recursive: true));

    // 1) Crear la base con el esquema actual y dejarla como estaba en v1.
    var db = AppDatabase(NativeDatabase(file));
    final repo = Repository(db);
    final ev = await repo.createEvent(
        name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
    await repo.addAttendee(
        eventId: ev,
        firstName: 'Juan',
        lastName1: 'Pérez',
        sex: Sex.male,
        age: 34);
    await db.customStatement('DROP TABLE app_users');
    await db.customStatement('ALTER TABLE app_meta DROP COLUMN recovery_hash');
    await db.customStatement('ALTER TABLE attendees DROP COLUMN created_by');
    for (final c in ['max_size_diff', 'max_sex_diff', 'max_age_diff']) {
      await db.customStatement('ALTER TABLE events DROP COLUMN $c');
    }
    await db.customStatement(
        'ALTER TABLE control_sessions DROP COLUMN blocked_repeats');
    await db.customStatement('ALTER TABLE events DROP COLUMN offers_teams');
    await db.customStatement('ALTER TABLE events DROP COLUMN setup_done');
    await db.customStatement('ALTER TABLE attendees DROP COLUMN status');
    await db.customStatement('ALTER TABLE attendees DROP COLUMN confirmed_at');
    await db.customStatement('ALTER TABLE churches DROP COLUMN community');
    await db.customStatement('UPDATE app_meta SET schema_version = 1');
    await db.customStatement('PRAGMA user_version = 1');
    await db.close();

    // 2) Reabrir: debe migrar.
    db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final people = await db.select(db.attendees).get();
    expect(people, hasLength(1));
    expect(people.single.firstName, 'Juan');
    expect(people.single.createdBy, isNull);
    expect((await db.select(db.appMeta).getSingle()).schemaVersion, 7);
    expect(await db.select(db.controlSessions).get(),
        isEmpty); // la tabla nueva columna existe y se puede consultar
    final e = await db.select(db.events).getSingle();
    expect((e.maxSizeDiff, e.maxSexDiff, e.maxAgeDiff),
        (2, 4, 3.0)); // valores por defecto de la estrategia C
    expect(e.offersTeams,
        isTrue); // los eventos anteriores siguen permitiendo equipos
    expect(await db.select(db.appUsers).get(), isEmpty);
    // v7: lo anterior cuenta como asistencia confirmada.
    expect(people.single.status, 'confirmed');
    expect(people.single.confirmedAt, isNull);
  });
}
