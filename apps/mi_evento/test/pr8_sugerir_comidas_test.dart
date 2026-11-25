// «Sugerir hospedaje»: buscador y marcar/desmarcar todos. Control de comidas: fecha de la sesión
// dentro del evento y estadística de cuántas veces repiten.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/meal_repo.dart';
import 'package:mi_evento/data/repos_b.dart';
import 'package:mi_evento/data/repository.dart';
import 'package:mi_evento/export/meal_report.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'helpers.dart';

const _pc = Size(1200, 2400);

void main() {
  group('Sugerir hospedaje: elegir personas', () {
    Future<void> open(WidgetTester t) async {
      final c = await pumpApp(t, _pc);
      await t.runAsync(() async {
        final ev = await c.repo.createEvent(
            name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
        for (final (n, a, sex) in [
          ('Ana', 'Pérez', Sex.female),
          ('Beto', 'Gómez', Sex.male),
          ('Carla', 'Núñez', Sex.female),
          ('Dani', 'Pérez', Sex.male),
        ]) {
          await c.repo.addAttendee(
              eventId: ev,
              firstName: n,
              lastName1: a,
              sex: sex,
              age: 30,
              needsLodging: true);
        }
        await LodgingRepo(c.db).save(
            eventId: ev,
            name: 'Casa',
            kind: 'shelter',
            capacity: 9,
            accepts: LodgingAccepts.any);
      });
      await login(t, 'admin', 'secreto1');
      await t.tap(find.text('Retiro'));
      await settle(t);
      await t.tap(find.text('Hospedajes').first);
      await settle(t);
      await tapKey(t, 'hosp-sugerir');
      await tapKey(t, 'sg-elegir');
    }

    String count(WidgetTester t) =>
        t.widget<Text>(find.byKey(const Key('sgp-conteo'))).data!;

    testWidgets('buscar por nombre sin tildes y por número', (t) async {
      await open(t);
      expect(count(t), '4 de 4 marcadas');
      await enter(t, 'sgp-buscar', 'nunez');
      expect(find.text('Carla Núñez'), findsOneWidget);
      expect(find.text('Ana Pérez'), findsNothing);
      expect(count(t), '1 de 4 · 4 marcadas');
      await enter(t, 'sgp-buscar', 'perez');
      expect(find.text('Ana Pérez'), findsOneWidget);
      expect(find.text('Dani Pérez'), findsOneWidget);
      expect(find.text('Beto Gómez'), findsNothing);
      await enter(t, 'sgp-buscar', '2'); // número de inscripción
      expect(find.text('Beto Gómez'), findsOneWidget);
      await enter(t, 'sgp-buscar', 'zzz');
      expect(find.byKey(const Key('sgp-vacio')), findsOneWidget);
    });

    testWidgets('«Desmarcar todos» y «Marcar todos» actúan sobre lo que se ve',
        (t) async {
      await open(t);
      await tapKey(t, 'sgp-desmarcar-todos');
      expect(count(t),
          '0 de 4 marcadas'.replaceAll('0', 'O').replaceAll('O', '0'));
      // «Usar» queda deshabilitado sin nadie marcado.
      expect(t.widget<FilledButton>(find.byKey(const Key('sgp-ok'))).onPressed,
          isNull);
      // Con búsqueda: solo marca a los que se ven.
      await enter(t, 'sgp-buscar', 'perez');
      await tapKey(t, 'sgp-marcar-todos');
      expect(count(t), '2 de 4 · 2 marcadas');
      await enter(t, 'sgp-buscar', '');
      expect(count(t), '2 de 4 marcadas');
      await tapKey(t, 'sgp-marcar-todos');
      expect(count(t), '4 de 4 marcadas');
      // Con búsqueda activa, «Desmarcar todos» solo quita a los que se ven.
      await enter(t, 'sgp-buscar', 'gomez');
      await tapKey(t, 'sgp-desmarcar-todos');
      await enter(t, 'sgp-buscar', '');
      expect(count(t), '3 de 4 marcadas');
      await tapKey(t, 'sgp-ok');
      expect(find.text('Seleccionadas: 3.'), findsOneWidget);
    });
  });

  group('Control de comidas', () {
    late AppDatabase db;
    late String ev;
    late MealRepo meals;
    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      ev = await Repository(db).createEvent(
          name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
      meals = MealRepo(db);
      await meals.ensureDefaultTypes(ev);
    });
    tearDown(() => db.close());

    test('la fecha de la sesión debe estar dentro del evento', () async {
      final t = (await meals.types(ev)).first;
      final ok = await meals.createSession(ev, t.id, 'Sábado',
          date: DateTime(2026, 12, 12));
      expect(ok.scheduledAt!.toLocal().day, 12);
      await meals.createSession(ev, t.id, 'Último día',
          date: DateTime(2026, 12, 14));
      for (final d in [DateTime(2026, 12, 11), DateTime(2026, 12, 15)]) {
        expect(() => meals.createSession(ev, t.id, 'Fuera ${d.day}', date: d),
            throwsA(isA<DataException>()),
            reason: '${d.day}');
      }
      // Sin fecha sigue funcionando (sesiones de antes).
      final sin = await meals.createSession(ev, t.id, 'Sin fecha');
      expect(sin.scheduledAt, isNull);
    });

    test('estadística de repetidos: cuántas personas pasaron 2, 3… veces',
        () async {
      final repo = Repository(db);
      final people = [
        for (final n in ['A', 'B', 'C', 'D', 'E'])
          await repo.addAttendee(
              eventId: ev, firstName: n, lastName1: 'X', sex: Sex.male, age: 30)
      ];
      final t = (await meals.types(ev)).first;
      final s = await meals.createSession(ev, t.id, 'Almuerzo');
      for (final p in people.take(4)) {
        await meals.mark(s.id, p.id, operatorName: 'Ruth');
      }
      await meals.mark(s.id, people[0].id, operatorName: 'Ruth', repeat: true);
      await meals.mark(s.id, people[1].id, operatorName: 'Ruth', repeat: true);
      await meals.mark(s.id, people[1].id, operatorName: 'Ruth', repeat: true);
      await meals.mark(s.id, people[2].id, operatorName: 'Ruth', repeat: true);
      final event = await db.select(db.events).getSingle();
      final sv = (await meals.watchSessions(ev).first).single;
      final r = buildMealReport(
        event: event,
        session: sv,
        people: await db.select(db.attendees).get(),
        churchNames: const {},
        teams: const {},
        records: await meals.watchRecords(s.id).first,
      );
      // A: 2 veces · B: 3 veces · C: 2 veces · D: 1 vez · E: no pasó.
      expect(r.repeatCounts, {2: 2, 3: 1});
      expect(r.repeaters, 3);
      expect(r.extraPasses, 4);
      expect(r.passed.length, 4, reason: 'cada persona cuenta una sola vez');
      final byName = {for (final p in r.passed) p.name: p.times};
      expect(byName, {'A X': 2, 'B X': 3, 'C X': 2, 'D X': 1});
      final csv = mealCsv(r);
      expect(csv, contains(';Veces'));
      final cols = csv
          .split('\r\n')
          .where((l) => l.startsWith('2;B X'))
          .single
          .split(';');
      expect(cols[9], '3', reason: 'columna «Veces»');
    });
  });

  group('Control de comidas (pantallas)', () {
    Future<Ctx> openMeals(WidgetTester t) async {
      final c = await pumpApp(t, _pc);
      await t.runAsync(() async {
        final ev = await c.repo.createEvent(
            name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
        for (final n in ['Ana', 'Beto', 'Carla']) {
          await c.repo.addAttendee(
              eventId: ev,
              firstName: n,
              lastName1: 'X',
              sex: Sex.female,
              age: 30);
        }
        await MealRepo(c.db).ensureDefaultTypes(ev);
      });
      await login(t, 'admin', 'secreto1');
      await t.tap(find.text('Retiro'));
      await settle(t);
      await t.tap(find.text('Comidas').first);
      await settle(t);
      return c;
    }

    String nombre(WidgetTester t) => t
        .widget<TextField>(find.byKey(const Key('ns-nombre')))
        .controller!
        .text;

    testWidgets(
        'nueva sesión: la fecha sugerida es el primer día del evento y se puede cambiar dentro del rango',
        (t) async {
      final c = await openMeals(t);
      await tapKey(t, 'cm-nueva');
      expect(find.textContaining('sábado 2026-12-12'), findsOneWidget);
      expect(nombre(t), 'Almuerzo del sábado');
      await tapKey(t, 'ns-fecha');
      // El calendario solo deja elegir del 12 al 14: el 11 y el 15 no existen o están deshabilitados.
      await t.tap(find.text('14'));
      await t.pump();
      await t.tap(find.text('ACEPTAR'));
      await settle(t);
      expect(find.textContaining('lunes 2026-12-14'), findsOneWidget);
      expect(nombre(t), 'Almuerzo del lunes');
      await tapKey(t, 'ns-crear');
      final s = (await t
          .runAsync(() => c.db.select(c.db.controlSessions).getSingle()))!;
      expect(s.scheduledAt!.toLocal().day, 14);
      expect(s.name, 'Almuerzo del lunes');
    });

    testWidgets('el resumen muestra cuántas veces repitieron', (t) async {
      // Los datos se preparan ANTES de abrir pantallas con streams vivos.
      final c = await pumpApp(t, _pc);
      await t.runAsync(() async {
        final ev = await c.repo.createEvent(
            name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
        final people = [
          for (final n in ['Ana', 'Beto', 'Carla'])
            await c.repo.addAttendee(
                eventId: ev,
                firstName: n,
                lastName1: 'X',
                sex: Sex.female,
                age: 30)
        ];
        final meals = MealRepo(c.db);
        await meals.ensureDefaultTypes(ev);
        final tp = (await meals.types(ev)).first;
        final s = await meals.createSession(ev, tp.id, 'Almuerzo del sábado');
        for (final p in people) {
          await meals.mark(s.id, p.id, operatorName: 'Ruth');
        }
        await meals.mark(s.id, people[0].id,
            operatorName: 'Ruth', repeat: true);
        await meals.mark(s.id, people[1].id,
            operatorName: 'Ruth', repeat: true);
        await meals.mark(s.id, people[1].id,
            operatorName: 'Ruth', repeat: true);
      });
      await login(t, 'admin', 'secreto1');
      await t.tap(find.text('Retiro'));
      await settle(t);
      await t.tap(find.text('Comidas').first);
      await settle(t);
      await tapKey(t, 'cm-cerrar');
      await tapKey(t, 'cm-cerrar-ok');
      expect(find.byKey(const Key('res-repeticiones')), findsOneWidget);
      expect(find.byKey(const Key('res-rep-2')), findsOneWidget);
      expect(find.byKey(const Key('res-rep-3')), findsOneWidget);
      expect(find.byKey(const Key('res-repitieron')), findsOneWidget);
    });
  });
}
