import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento/backup/file_picker.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/repos_b.dart';
import 'package:mi_evento/data/repository.dart';
import 'package:mi_evento/data/team_definition_exchange.dart';
import 'package:mi_evento/providers.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'helpers.dart';

void main() {
  group('definición de equipos (datos)', () {
    late AppDatabase db;
    late Repository repo;
    late TeamRepo teams;
    late String ev;
    late String church;
    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repo = Repository(db);
      teams = TeamRepo(db);
      ev = await repo.createEvent(
          name: 'E', startDate: '2026-01-01', endDate: '2026-01-02');
      church = (await repo.createChurch(name: 'B', province: 'Matanzas')).id;
    });
    tearDown(() => db.close());

    Future<AttendeeRow> person(String n) => repo.addAttendee(
        eventId: ev,
        firstName: n,
        lastName1: 'X',
        sex: Sex.female,
        age: 30,
        churchId: church);
    Future<List<TeamRow>> teamRows() => (db.select(db.teams)
          ..where((t) => t.eventId.equals(ev) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    Future<AttendeeRow> fresh(String id) =>
        (db.select(db.attendees)..where((a) => a.id.equals(id))).getSingle();
    String csv(List<List<String>> body) => buildCsvDelimited([
          ['equipo', 'color', 'capitan_numero'],
          ...body
        ]);

    test('exporta nombre, color (de la paleta o código), capitán e integrantes',
        () async {
      await teams.createMany(ev, 2); // Rojo, Azul
      final [rojo, azul] = await teamRows();
      final ana = await person('Ana');
      await teams.setTeam([ana.id], rojo.id);
      await teams.update(rojo.id,
          name: 'Rojo', color: rojo.color, captainId: ana.id);
      await teams.update(azul.id, name: 'Azul', color: '#123abc');
      final rows = await TeamDefinitionExchange(db, ev).export();
      expect(rows.first, TeamDefinitionExchange.headers);
      expect(rows[1], ['Rojo', 'Rojo', '${ana.regNumber}', 'Ana X', '1']);
      expect(rows[2], ['Azul', '#123abc', '', '', '0']);
    });

    test('crea y actualiza equipos con color; avisa de lo que no entiende',
        () async {
      await teams.createMany(ev, 1); // Rojo
      final imp = TeamDefinitionExchange(db, ev);
      final text = csv([
        ['Rojo', 'verde', ''], // existe: cambia de color
        ['Los Leones', '#c8453b', ''], // nuevo, con código
        ['Sin color', '', ''],
        ['Mala', 'fucsia', ''],
        ['Fantasma', '', '999'],
        ['Los Leones', 'azul', ''], // repetido
        ['', 'azul', ''],
      ]);
      final prev = await imp.preview(text);
      expect(prev.work, 3);
      expect(prev.warnings, hasLength(4));
      expect(prev.decisions, isEmpty);
      await imp.apply(text);
      final t = await teamRows();
      expect([for (final x in t) x.name], ['Rojo', 'Los Leones', 'Sin color']);
      expect(t[0].color, '#2E8B57');
      expect(t[1].color, '#C8453B');
      expect(t[2].color, isNull);
    });

    test('capitán que ya es del equipo: se nombra sin pedir permiso', () async {
      await teams.createMany(ev, 1);
      final rojo = (await teamRows()).single;
      final ana = await person('Ana');
      await teams.setTeam([ana.id], rojo.id);
      final text = csv([
        ['Rojo', '', '${ana.regNumber}']
      ]);
      final prev = await TeamDefinitionExchange(db, ev).preview(text);
      expect(prev.decisions, isEmpty);
      await TeamDefinitionExchange(db, ev).apply(text);
      expect((await teamRows()).single.captainId, ana.id);
    });

    group('capitán que no es del equipo', () {
      late TeamRow rojo, azul;
      late AttendeeRow ana, beto, carla;
      late String text;
      setUp(() async {
        await teams.createMany(ev, 2);
        [rojo, azul] = await teamRows();
        ana = await person('Ana');
        beto = await person('Beto');
        carla = await person('Carla');
        await teams.setTeam([ana.id, carla.id], rojo.id);
        await teams.setTeam([beto.id], azul.id);
        await teams.update(azul.id,
            name: 'Azul', color: azul.color, captainId: beto.id);
        text = csv([
          ['Rojo', '', '${beto.regNumber}']
        ]);
      });

      test('la revisión ofrece mover, no cambiar o elegir a otro integrante',
          () async {
        final prev = await TeamDefinitionExchange(db, ev).preview(text);
        expect(prev.decisions, hasLength(1));
        final d = prev.decisions.single;
        expect(d.message, contains('Azul'));
        expect(d.options.length, 4);
        expect(d.options[0], contains('Moverlo'));
        expect(d.options[1], contains('No cambiar'));
        expect(d.options.skip(2), everyElement(contains('otro integrante')));
        // La revisión no escribe nada.
        expect((await fresh(beto.id)).teamId, azul.id);
      });

      test('por defecto (aprobado): se mueve al equipo y es su capitán',
          () async {
        final imp = TeamDefinitionExchange(db, ev);
        final prev = await imp.preview(text);
        await imp.apply(text, choices: {prev.decisions.single.id: 0});
        expect((await fresh(beto.id)).teamId, rojo.id);
        final t = await teamRows();
        expect(t[0].captainId, beto.id);
        expect(t[1].captainId, isNull,
            reason: 'Azul pierde a su capitán al irse');
      });

      test('si no se aprueba: nadie se mueve y el capitán no cambia', () async {
        final imp = TeamDefinitionExchange(db, ev);
        final prev = await imp.preview(text);
        await imp.apply(text, choices: {prev.decisions.single.id: 1});
        expect((await fresh(beto.id)).teamId, azul.id);
        final t = await teamRows();
        expect(t[0].captainId, isNull);
        expect(t[1].captainId, beto.id);
      });

      test('o se elige a otro integrante del equipo como capitán', () async {
        final imp = TeamDefinitionExchange(db, ev);
        final prev = await imp.preview(text);
        final d = prev.decisions.single;
        final i = d.options.indexWhere((o) => o.contains('Carla'));
        expect(i, greaterThan(1));
        await imp.apply(text, choices: {d.id: i});
        expect((await fresh(beto.id)).teamId, azul.id);
        expect((await teamRows())[0].captainId, carla.id);
      });

      test('persona sin equipo, o equipo nuevo: también se pide permiso',
          () async {
        final dani = await person('Dani');
        final t2 = csv([
          ['Verde nuevo', '', '${dani.regNumber}']
        ]);
        final imp = TeamDefinitionExchange(db, ev);
        final prev = await imp.preview(t2);
        expect(prev.decisions.single.options, hasLength(2));
        expect(prev.decisions.single.message, contains('no tiene equipo'));
        await imp.apply(t2);
        final nuevo = (await teamRows()).last;
        expect(nuevo.name, 'Verde nuevo');
        expect(nuevo.captainId, dani.id);
        expect((await fresh(dani.id)).teamId, nuevo.id);
      });
    });

    test('exportar → importar en el mismo evento no cambia nada', () async {
      await teams.createMany(ev, 2);
      final [rojo, azul] = await teamRows();
      final ana = await person('Ana');
      await teams.setTeam([ana.id], rojo.id);
      await teams.update(rojo.id,
          name: 'Rojo', color: rojo.color, captainId: ana.id);
      await teams.update(azul.id, name: 'Azul', color: '#123ABC');
      final before = [
        for (final t in await teamRows()) [t.name, t.color, t.captainId]
      ];
      final text =
          buildCsvDelimited(await TeamDefinitionExchange(db, ev).export());
      final imp = TeamDefinitionExchange(db, ev);
      final prev = await imp.preview(text);
      expect(prev.decisions, isEmpty);
      expect(prev.warnings, isEmpty);
      await imp.apply(text);
      expect([
        for (final t in await teamRows()) [t.name, t.color, t.captainId]
      ], before);
      expect((await fresh(ana.id)).teamId, rojo.id);
    });
  });

  testWidgets(
      'Equipos (pantalla): importar equipos muestra la decisión del capitán y respeta la elección',
      (t) async {
    final picker = MemoryFilePick();
    final c = await pumpApp(t, const Size(1200, 2400), overrides: [
      filePickProvider.overrideWithValue(picker),
    ]);
    late String ev, betoId, azulId;
    late int betoNumber;
    await t.runAsync(() async {
      ev = await c.repo.createEvent(
          name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
      final ch = await c.repo.createChurch(
          name: 'Bautista', province: 'Matanzas', municipality: 'Cárdenas');
      final beto = await c.repo.addAttendee(
          eventId: ev,
          firstName: 'Beto',
          lastName1: 'X',
          sex: Sex.male,
          age: 30,
          churchId: ch.id,
          preregistered: true);
      betoId = beto.id;
      betoNumber = beto.regNumber;
      final tr = TeamRepo(c.db);
      await tr.createMany(ev, 2); // Rojo, Azul
      azulId = (await tr.watchTeams(ev).first)[1].id;
      await tr.setTeam([betoId], azulId);
    });
    await login(t, 'admin', 'secreto1');
    await t.tap(find.text('Retiro'));
    await settle(t);
    await t.tap(find.text('Equipos').first);
    await settle(t);
    picker.file = PickedFile(
        'e.csv',
        Uint8List.fromList(utf8.encode(buildCsvDelimited([
          ['equipo', 'color', 'capitan_numero'],
          ['Rojo', 'Verde', '$betoNumber'],
        ]))));
    await tapKey(t, 'eq-def-importar');
    expect(find.byKey(const Key('ti-revision')), findsOneWidget);
    expect(find.textContaining('Beto X'), findsWidgets);
    expect(find.byKey(Key('ti-decision-cap-2')), findsOneWidget);
    // «No cambiar el capitán»: nadie se mueve.
    await t.tap(find.byKey(const Key('ti-decision-cap-2-1')));
    await t.pump();
    await tapKey(t, 'ti-importar');
    await t.tap(find.text('Aceptar'));
    await settle(t);
    await t.runAsync(() async {
      final beto = await (c.db.select(c.db.attendees)
            ..where((a) => a.id.equals(betoId)))
          .getSingle();
      expect(beto.teamId, azulId);
      final rojo = (await TeamRepo(c.db).watchTeams(ev).first).first;
      expect(rojo.color, '#2E8B57');
      expect(rojo.captainId, isNull);
    });
  });
}
