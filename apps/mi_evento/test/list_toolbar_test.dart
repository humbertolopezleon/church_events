import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento/backup/file_picker.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/list_filters.dart';
import 'package:mi_evento/data/repos_b.dart';
import 'package:mi_evento/data/repository.dart';
import 'package:mi_evento/export/file_saver.dart';
import 'package:mi_evento/providers.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'helpers.dart';

const _pc = Size(1200, 2400);

Future<(Ctx, MemoryFileSaver, String)> _open(WidgetTester t,
    {bool withPreregistered = false}) async {
  final saver = MemoryFileSaver();
  final c = await pumpApp(t, _pc, overrides: [
    fileSaverProvider.overrideWithValue(saver),
    filePickProvider.overrideWithValue(MemoryFilePick()),
  ]);
  late String ev;
  await t.runAsync(() async {
    ev = await c.repo.createEvent(
        name: 'Retiro Jóvenes', startDate: '2026-12-12', endDate: '2026-12-14');
    final ig = await c.repo.createChurch(
        name: 'Bautista', province: 'Matanzas', municipality: 'Cárdenas');
    final ig2 = await c.repo.createChurch(
        name: 'Metodista', province: 'Matanzas', municipality: 'Colón');
    for (final (n, s, a, ch) in [
      ('Juan', Sex.male, 34, ig),
      ('María', Sex.female, 27, ig),
      ('Pedro', Sex.male, 40, ig2),
    ]) {
      await c.repo.addAttendee(
          eventId: ev,
          firstName: n,
          lastName1: 'Pérez',
          sex: s,
          age: a,
          churchId: ch.id,
          needsLodging: n != 'Pedro');
    }
    final tr = TeamRepo(c.db);
    await tr.createMany(ev, 2);
    final teams = await c.db.select(c.db.teams).get();
    final rows = await c.db.select(c.db.attendees).get();
    await tr.setTeam([rows[0].id, rows[1].id], teams[0].id);
    final lod = LodgingRepo(c.db);
    final l = await lod.save(
        eventId: ev,
        name: 'Casa de Teresa',
        kind: 'private_home',
        capacity: 1,
        accepts: LodgingAccepts.women,
        hostName: 'Teresa');
    await lod.assign(l.id, [rows[1].id]);
    await lod.save(
        eventId: ev,
        name: 'Albergue Norte',
        kind: 'shelter',
        capacity: 10,
        accepts: LodgingAccepts.men);
    if (withPreregistered) {
      for (final n in ['Lidia', 'Mario']) {
        await c.repo.addAttendee(
            eventId: ev,
            firstName: n,
            lastName1: 'Preinscrito',
            sex: n == 'Lidia' ? Sex.female : Sex.male,
            age: 30,
            preregistered: true);
      }
    }
  });
  await login(t, 'admin', 'secreto1');
  await t.tap(find.text('Retiro Jóvenes'));
  await settle(t);
  return (c, saver, ev);
}

Future<void> _goTo(WidgetTester t, String label) async {
  await t.tap(find.text(label).first);
  await settle(t);
}

List<List<String>> _csv(MemoryFileSaver s, String prefix) {
  final name = s.saved.keys.firstWhere((n) => n.startsWith(prefix));
  return parseCsv(utf8.decode(s.saved[name]!));
}

void main() {
  test('AttendeeFilter combina sexo, iglesia, hospedaje y equipo', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = Repository(db);
    final ev = await repo.createEvent(
        name: 'E', startDate: '2026-01-01', endDate: '2026-01-02');
    final ig = await repo.createChurch(name: 'Bautista', province: 'Matanzas');
    for (final (n, s, needs) in [
      ('A', Sex.male, true),
      ('B', Sex.female, true),
      ('C', Sex.female, false),
    ]) {
      await repo.addAttendee(
          eventId: ev,
          firstName: n,
          lastName1: 'X',
          sex: s,
          age: 20,
          churchId: ig.id,
          needsLodging: needs);
    }
    final all = await repo.watchAttendees(ev).first;
    expect(const AttendeeFilter().apply(all), hasLength(3));
    expect(const AttendeeFilter(sex: 'F').apply(all), hasLength(2));
    expect(const AttendeeFilter(lodging: LodgingStatus.pending).apply(all),
        hasLength(2)); // necesitan y no tienen
    expect(
        const AttendeeFilter(lodging: LodgingStatus.notNeeded)
            .apply(all)
            .single
            .a
            .firstName,
        'C');
    expect(const AttendeeFilter(team: TeamStatus.assigned).apply(all), isEmpty);
    expect(
        AttendeeFilter(
                sex: 'F', churchId: ig.id, lodging: LodgingStatus.pending)
            .apply(all)
            .single
            .a
            .firstName,
        'B');
  });

  testWidgets(
      'Asistentes: buscar, filtrar por sexo y exportar solo lo filtrado',
      (t) async {
    final (_, saver, _) = await _open(t);
    await _goTo(t, 'Asistentes');
    expect(find.text('3 inscritos'), findsOneWidget);
    await t.enterText(find.byKey(const Key('buscar')), 'perez');
    await settle(t);
    await tapKey(t, 'filtro-sexo');
    await t.tap(find.text('Mujeres').last);
    await settle(t);
    expect(find.text('1 de 3'), findsOneWidget);
    await tapKey(t, 'exportar-csv');
    final rows = _csv(saver, 'asistentes-retiro-jovenes');
    expect(rows.length, 2); // títulos + María
    expect(rows[1], contains('María'));
  });

  testWidgets('Hospedajes: buscar, filtrar por a quién acepta y exportar',
      (t) async {
    final (_, saver, _) = await _open(t);
    await _goTo(t, 'Hospedajes');
    expect(find.text('2 hospedajes'), findsOneWidget);
    await t.enterText(find.byKey(const Key('hosp-buscar')), 'teresa');
    await settle(t);
    expect(find.text('1 de 2'), findsOneWidget);
    await t.enterText(find.byKey(const Key('hosp-buscar')), '');
    await tapKey(t, 'hosp-filtro-libres'); // Casa de Teresa está llena
    expect(find.text('1 de 2'), findsOneWidget);
    await tapKey(t, 'hosp-exportar');
    final rows = _csv(saver, 'hospedajes');
    expect(rows.length, 2);
    expect(rows[1].first, 'Albergue Norte');
  });

  testWidgets('Equipos: buscar por persona y exportar una fila por persona',
      (t) async {
    final (_, saver, _) = await _open(t);
    await _goTo(t, 'Equipos');
    await tapKey(t, 'eq-exportar');
    final rows = _csv(saver, 'equipos');
    expect(rows.first.first, 'equipo');
    expect(rows.length, 4); // títulos + 3 personas (Pedro «Sin equipo»)
    expect(rows.where((r) => r.first == 'Sin equipo'), hasLength(1));
    await t.enterText(find.byKey(const Key('eq-buscar')), 'zzz');
    await settle(t);
    expect(find.text('0 de 2'), findsOneWidget);
  });

  testWidgets('Mis eventos: buscar y exportar', (t) async {
    final c = await pumpApp(t, _pc, overrides: [
      fileSaverProvider.overrideWithValue(MemoryFileSaver()),
    ]);
    await t.runAsync(() async {
      await c.repo.createEvent(
          name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
      await c.repo.createEvent(
          name: 'Congreso', startDate: '2027-01-01', endDate: '2027-01-03');
    });
    await login(t, 'admin', 'secreto1');
    expect(find.text('2 eventos'), findsOneWidget);
    await t.enterText(find.byKey(const Key('ev-buscar')), 'congre');
    await settle(t);
    expect(find.text('1 de 2'), findsOneWidget);
    expect(find.byKey(const Key('evento-Retiro')), findsNothing);
  });

  testWidgets('Equipos (escritorio): tabla resumen ordenable con los totales',
      (t) async {
    await _open(t);
    await _goTo(t, 'Equipos');
    expect(find.byKey(const Key('eq-tabla')), findsOneWidget);
    expect(find.text('Edad media'), findsOneWidget);
    expect(find.text('Capitán'), findsOneWidget);
  });

  testWidgets('Confirmar asistencia: buscar y exportar los preinscritos',
      (t) async {
    final (_, saver, _) = await _open(t, withPreregistered: true);
    await _goTo(t, 'Confirmar asistencia');
    await tapKey(t, 'ca-exportar');
    var rows = _csv(saver, 'por-confirmar');
    expect(rows.first.first, 'numero');
    expect(rows.length, 3); // títulos + 2 preinscritos
    await t.enterText(find.byKey(const Key('ca-buscar')), 'lidia');
    await settle(t);
    await tapKey(t, 'ca-exportar');
    rows = _csv(saver, 'por-confirmar');
    expect(rows.length, 2);
    expect(rows[1][1], contains('Lidia'));
  });

  testWidgets('Usuarios: buscar y exportar sin contraseñas', (t) async {
    final (_, saver, _) = await _open(t);
    await _goTo(t, 'Usuarios');
    await tapKey(t, 'usr-exportar');
    final rows = _csv(saver, 'usuarios');
    expect(rows.first, ['usuario', 'nombre', 'rol', 'estado']);
    expect(rows.length, 2); // títulos + el administrador
    expect(rows.expand((r) => r).any((c) => c.contains('secreto')), isFalse);
    await t.enterText(find.byKey(const Key('usr-buscar')), 'zzz');
    await settle(t);
    expect(find.text('0 de 1'), findsOneWidget);
  });
}
