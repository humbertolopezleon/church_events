import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento/data/attendee_exchange.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/repos_b.dart';
import 'package:mi_evento/data/repository.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'helpers.dart';

Future<List<String>> _people(Repository repo, String ev, int n,
    {bool pre = true}) async {
  final ig = await repo.createChurch(name: 'Bautista', province: 'Matanzas');
  return [
    for (var i = 0; i < n; i++)
      (await repo.addAttendee(
              eventId: ev,
              firstName: 'Persona$i',
              lastName1: 'Apellido',
              sex: i.isEven ? Sex.male : Sex.female,
              age: 20 + i,
              churchId: ig.id,
              preregistered: pre))
          .id
  ];
}

void main() {
  group('datos', () {
    late AppDatabase db;
    late Repository repo;
    late String ev;
    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repo = Repository(db);
      ev = await repo.createEvent(
          name: 'E', startDate: '2026-01-01', endDate: '2026-01-02');
    });
    tearDown(() => db.close());

    test('preinscrito vs confirmado al registrar', () async {
      final pre = await _people(repo, ev, 1);
      final a = (await repo.attendeeById(pre.single))!;
      expect(a.status, 'preregistered');
      expect(a.confirmedAt, isNull);
      final c = await repo.addAttendee(
          eventId: ev,
          firstName: 'Ya',
          lastName1: 'Llegó',
          sex: Sex.male,
          age: 30);
      expect(c.status, 'confirmed');
      expect(c.confirmedAt, isNotNull);
    });

    test(
        'confirmar uno, un subconjunto y todos; es idempotente y se puede deshacer',
        () async {
      final ids = await _people(repo, ev, 5);
      expect(await repo.confirmAttendance([ids[0]]), 1);
      expect(await repo.confirmAttendance([ids[0]]), 0); // ya estaba
      expect(await repo.confirmAttendance([ids[1], ids[2]]), 2);
      var all = await repo.watchAttendees(ev).first;
      expect(all.where((v) => v.isPreregistered), hasLength(2));
      expect(await repo.confirmAttendance(ids), 2); // solo los que faltaban
      all = await repo.watchAttendees(ev).first;
      expect(all.where((v) => v.isPreregistered), isEmpty);
      expect((await repo.attendeeById(ids[0]))!.confirmedAt, isNotNull);
      expect(await repo.unconfirmAttendance([ids[0]]), 1);
      final back = (await repo.attendeeById(ids[0]))!;
      expect((back.status, back.confirmedAt), ('preregistered', null));
      expect(await repo.confirmAttendance([]), 0);
    });

    test(
        'exportar asistentes de un evento e importarlos en otro como preinscripción (sin hospedaje ni equipo)',
        () async {
      final ids = await _people(repo, ev, 3, pre: false);
      final l = await LodgingRepo(db).save(
          eventId: ev,
          name: 'Casa',
          kind: 'shelter',
          capacity: 5,
          accepts: LodgingAccepts.any);
      await LodgingRepo(db).assign(l.id, [ids[0]]);
      final ex = AttendeeExchange(db);
      final csv = await ex.exportCsv(ev);

      final ev2 = await repo.createEvent(
          name: 'E2', startDate: '2027-01-01', endDate: '2027-01-02');
      await LodgingRepo(db).save(
          eventId: ev2,
          name: 'Casa',
          kind: 'shelter',
          capacity: 5,
          accepts: LodgingAccepts.any);
      final plan = await ex.plan(ev2, parseAttendeesCsv(csv));
      final rep = await ex.apply(ev2, plan, asPreregistered: true);
      expect(rep.created, 3);
      final got = await repo.watchAttendees(ev2).first;
      expect(got, hasLength(3));
      expect(got.every((v) => v.isPreregistered), isTrue);
      expect(got.every((v) => v.a.lodgingId == null), isTrue,
          reason: 'el hospedaje del otro evento no se arrastra');
      // sin la opción, entran confirmados y con su hospedaje (comportamiento de siempre)
      final ev3 = await repo.createEvent(
          name: 'E3', startDate: '2027-02-01', endDate: '2027-02-02');
      await LodgingRepo(db).save(
          eventId: ev3,
          name: 'Casa',
          kind: 'shelter',
          capacity: 5,
          accepts: LodgingAccepts.any);
      await ex.apply(ev3, await ex.plan(ev3, parseAttendeesCsv(csv)));
      final got3 = await repo.watchAttendees(ev3).first;
      expect(got3.every((v) => !v.isPreregistered), isTrue);
      expect(got3.where((v) => v.a.lodgingId != null), hasLength(1));
    });
  });

  group('importar con estado', () {
    late AppDatabase db;
    late Repository repo;
    late AttendeeExchange ex;
    late String ev;
    const head = 'nombre;apellido1;sexo;edad;iglesia;hospedaje;equipo;estado';
    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repo = Repository(db);
      ex = AttendeeExchange(db);
      ev = await repo.createEvent(
          name: 'E', startDate: '2026-01-01', endDate: '2026-01-02');
      await LodgingRepo(db).save(
          eventId: ev,
          name: 'Casa',
          kind: 'shelter',
          capacity: 5,
          accepts: LodgingAccepts.any);
    });
    tearDown(() => db.close());

    final csv = parseAttendeesCsv('$head\n'
        'Ana;Uno;Mujer;20;Bautista;Casa;;Preinscrito\n'
        'Beto;Dos;Hombre;30;Bautista;Casa;;Confirmado\n'
        'Caro;Tres;Mujer;40;Bautista;;;\n'
        'Dino;Cuatro;Hombre;25;Bautista;;;Quizás');

    test('un estado que no se entiende se reporta y esa fila no se importa',
        () {
      expect(csv.rows, hasLength(3));
      expect(csv.errors.single.message, contains('estado'));
    });

    Future<Map<String, AttendeeView>> run(
        {bool pre = false, bool file = false, bool keep = false}) async {
      await ex.apply(ev, await ex.plan(ev, csv),
          asPreregistered: pre, useFileStatus: file, keepAssignments: keep);
      return {
        for (final v in await repo.watchAttendees(ev).first) v.a.firstName: v
      };
    }

    test('«según el archivo»: cada fila su estado; las vacías, confirmadas',
        () async {
      final m = await run(file: true);
      expect(m['Ana']!.isPreregistered, isTrue);
      expect(m['Beto']!.isPreregistered, isFalse);
      expect(m['Caro']!.isPreregistered, isFalse);
    });

    test('la elección global manda aunque el archivo traiga otro estado',
        () async {
      final m = await run(pre: true);
      expect(m.values.every((v) => v.isPreregistered), isTrue);
    });

    test('preinscritos: hospedaje solo si se pide conservarlo', () async {
      var m = await run(pre: true);
      expect(m['Beto']!.a.lodgingId, isNull);
      await db.close();
      db = AppDatabase(NativeDatabase.memory());
      repo = Repository(db);
      ex = AttendeeExchange(db);
      ev = await repo.createEvent(
          name: 'E', startDate: '2026-01-01', endDate: '2026-01-02');
      await LodgingRepo(db).save(
          eventId: ev,
          name: 'Casa',
          kind: 'shelter',
          capacity: 5,
          accepts: LodgingAccepts.any);
      m = await run(pre: true, keep: true);
      expect(m['Beto']!.a.lodgingId, isNotNull);
      expect(m['Beto']!.isPreregistered, isTrue);
    });

    test('importar de nuevo no cambia el estado de quien ya está confirmado',
        () async {
      await run(file: true);
      var m = {
        for (final v in await repo.watchAttendees(ev).first) v.a.firstName: v
      };
      await repo.confirmAttendance([m['Ana']!.a.id]);
      // El archivo sigue diciendo «Preinscrito» para Ana (con su id): no la devuelve a preinscrita.
      final again = await ex.exportCsv(ev);
      final edited = again.replaceAll('Preinscrito', 'Preinscrito');
      await ex.apply(ev, await ex.plan(ev, parseAttendeesCsv(edited)),
          asPreregistered: true, useFileStatus: true);
      m = {
        for (final v in await repo.watchAttendees(ev).first) v.a.firstName: v
      };
      expect(m['Ana']!.isPreregistered, isFalse);
      expect(m.length, 3);
    });
  });

  testWidgets('pantalla Confirmar asistencia: uno, varios y todos', (t) async {
    final c = await pumpApp(t, const Size(1200, 2400));
    late String ev;
    await t.runAsync(() async {
      ev = await c.repo.createEvent(
          name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
      await _people(c.repo, ev, 4);
      await c.repo.addAttendee(
          eventId: ev,
          firstName: 'Ya',
          lastName1: 'Llegó',
          sex: Sex.male,
          age: 30);
    });
    await login(t, 'admin', 'secreto1');
    await t.tap(find.text('Retiro'));
    await settle(t);
    await t.tap(find.text('Confirmar asistencia').first);
    await settle(t);
    expect(find.text('4 por confirmar · 1 ya confirmados'), findsOneWidget);

    await tapKey(t, 'ca-confirmar-1'); // uno por uno
    expect(find.text('3 por confirmar · 2 ya confirmados'), findsOneWidget);

    await tapKey(t, 'ca-fila-2'); // un subconjunto
    await tapKey(t, 'ca-fila-3');
    expect(find.text('Confirmar seleccionados (2)'), findsOneWidget);
    await tapKey(t, 'ca-confirmar-sel');
    expect(find.text('1 por confirmar · 4 ya confirmados'), findsOneWidget);

    await tapKey(t, 'ca-confirmar-todos'); // todos
    await tapKey(t, 'ca-dialogo-ok');
    expect(find.byKey(const Key('ca-vacio')), findsOneWidget);
    final rows = (await t.runAsync(() => c.db.select(c.db.attendees).get()))!;
    expect(rows.every((r) => r.status == 'confirmed'), isTrue);
  });

  testWidgets(
      'el Panel cuenta solo confirmados y muestra los preinscritos por confirmar',
      (t) async {
    final c = await pumpApp(t, const Size(1200, 2400));
    await t.runAsync(() async {
      final ev = await c.repo.createEvent(
          name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
      await _people(c.repo, ev, 3); // preinscritas
      await c.repo.addAttendee(
          eventId: ev,
          firstName: 'Ya',
          lastName1: 'Llegó',
          sex: Sex.male,
          age: 30);
    });
    await login(t, 'admin', 'secreto1');
    await t.tap(find.text('Retiro'));
    await settle(t);
    expect(find.text('0 mujeres · 1 hombres'), findsOneWidget);
    expect(find.byKey(const Key('contador-preinscritos')), findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const Key('contador-preinscritos')),
            matching: find.text('3')),
        findsOneWidget);
    await tapKey(t, 'contador-preinscritos');
    expect(find.text('3 por confirmar · 1 ya confirmados'), findsOneWidget);
  });

  testWidgets('el formulario registra como preinscrito y la lista lo marca',
      (t) async {
    final c = await pumpApp(t, const Size(1200, 2400));
    await t.runAsync(() async {
      final ev = await c.repo.createEvent(
          name: 'Retiro',
          startDate: '2026-12-12',
          endDate: '2026-12-14',
          offersTeams: false,
          offersLodging: false);
      await c.repo.createChurch(name: 'Bautista', province: 'Matanzas');
      expect(ev, isNotEmpty);
    });
    await login(t, 'admin', 'secreto1');
    await t.tap(find.text('Retiro'));
    await settle(t);
    await goRegister(t);
    await settle(t);
    await enter(t, 'f-nombre', 'Lucía');
    await enter(t, 'f-apellido1', 'Gómez');
    await pickSex(t, woman: true);
    await enter(t, 'f-edad', '25');
    await enter(t, 'f-iglesia', 'Bautista');
    await settle(t);
    await tapKey(t, 'f-preinscripcion');
    await t.tap(find.byType(ListTile).first);
    await settle(t);
    await tapKey(t, 'f-guardar');
    final rows = (await t.runAsync(() => c.db.select(c.db.attendees).get()))!;
    expect(rows, hasLength(1));
    expect(rows.single.status, 'preregistered');
  });
}
