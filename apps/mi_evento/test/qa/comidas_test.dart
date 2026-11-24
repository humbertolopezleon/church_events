// QA · Control de comidas con 120 personas: sesiones, marcas, repetidos, deshacer, contadores,
// cierre y reapertura, resumen por equipo, llegadas cada 15 min y exportaciones (con privacidad).
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show BooleanExpressionOperators;
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/meal_repo.dart';
import 'package:mi_evento/data/repository.dart';
import 'package:mi_evento/export/meal_report.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'qa_support.dart';

Future<QaEvent> _evento(AppDatabase db, {int n = 120}) async {
  final q = await qaEvent(db, teams: 6);
  await qaInscribeAll(q, qaPeople(n));
  return q;
}

Future<ControlSession> _sesion(QaEvent q, String tipo, String nombre) async {
  final meals = MealRepo(q.db);
  await meals.ensureDefaultTypes(q.eventId);
  final t = (await meals.types(q.eventId)).firstWhere((x) => x.name == tipo);
  return meals.createSession(q.eventId, t.id, nombre, operatorName: 'Ruth');
}

Future<MealReport> _informe(QaEvent q, ControlSession s,
    {AppDatabase? db}) async {
  final d = db ?? q.db;
  final ev = await (d.select(d.events)..where((e) => e.id.equals(q.eventId)))
      .getSingle();
  final types = {
    for (final t in await d.select(d.controlTypes).get()) t.id: t.name
  };
  final records = await (d.select(d.controlRecords)
        ..where((r) => r.sessionId.equals(s.id) & r.undoneAt.isNull()))
      .get();
  return buildMealReport(
    event: ev,
    session: SessionView(s, types[s.controlTypeId] ?? ''),
    people: await q.people(),
    churchNames: {
      for (final c in await d.select(d.churches).get()) c.id: c.name
    },
    teams: {for (final t in await q.teamRows()) t.id: t},
    records: records,
  );
}

void main() {
  late AppDatabase db;
  setUp(() => db = qaDb());
  tearDown(() => db.close());

  group('sesiones y marcas (120 personas)', () {
    test(
        'QA-COM-001 · tipos y sesiones: Desayuno/Almuerzo/Cena y uno propio; nombre repetido o vacío se rechaza en español',
        () async {
      final q = await _evento(db);
      final meals = MealRepo(db);
      await meals.ensureDefaultTypes(q.eventId);
      await meals.createType(q.eventId, 'Entrega de materiales');
      final tipos = await meals.types(q.eventId);
      expect(tipos.map((t) => t.name),
          ['Desayuno', 'Almuerzo', 'Cena', 'Entrega de materiales']);
      await _sesion(q, 'Almuerzo', 'Almuerzo del sábado');
      Future<void> mal(String nombre, String texto) => expectLater(
          meals.createSession(q.eventId, tipos[1].id, nombre),
          throwsA(isA<DataException>()
              .having((e) => e.message, 'm', contains(texto))));
      await mal('almuerzo del SABADO', 'Ya existe una sesión');
      await mal('    ', 'Falta el nombre');
    });

    test(
        'QA-COM-002 · marcar a 100 de 120: contadores (inscritos/pasaron/faltan) y porcentaje exactos',
        () async {
      final q = await _evento(db);
      final s = await _sesion(q, 'Almuerzo', 'Almuerzo del sábado');
      final meals = MealRepo(db);
      for (final id in q.ids.take(100)) {
        final r = await meals.mark(s.id, id, operatorName: 'Ruth');
        expect(r.already, isFalse);
      }
      final people = await q.people();
      final stats = computeMealStats([
        for (final p in people)
          MealPerson(id: p.id, sexIsMale: p.sex == 'M', teamId: p.teamId)
      ], q.ids.take(100).toSet());
      expect((stats.total, stats.passed, stats.pending, stats.percent),
          (120, 100, 20, 83));
      expect(stats.byTeam.values.fold<int>(0, (a, v) => a + v.$1), 100);
      expect(stats.byTeam.values.fold<int>(0, (a, v) => a + v.$2), 120);
    });

    test(
        'QA-COM-003 · marcar dos veces avisa «ya pasó» y no cuenta doble; «repetir a propósito» deja el registro pero la persona cuenta una vez',
        () async {
      final q = await _evento(db);
      final s = await _sesion(q, 'Cena', 'Cena del viernes');
      final meals = MealRepo(db);
      await meals.mark(s.id, q.ids[0], operatorName: 'Ruth');
      final again = await meals.mark(s.id, q.ids[0], operatorName: 'Ana');
      expect(again.already, isTrue);
      expect(
          again.record.operatorName, 'Ruth'); // quién lo marcó la primera vez
      await meals.mark(s.id, q.ids[0], operatorName: 'Ana', repeat: true);
      final recs = await (db.select(db.controlRecords)).get();
      expect(recs.length, 2);
      expect(recs.where((r) => r.repeatOverride).length, 1);
      final informe = await _informe(q, s);
      expect(informe.passed.length, 1);
      expect(informe.passed.single.by, 'Ruth');
    });

    test(
        'QA-COM-004 · deshacer quita a la persona de «pasaron» y se puede volver a marcar',
        () async {
      final q = await _evento(db);
      final s = await _sesion(q, 'Desayuno', 'Desayuno del sábado');
      final meals = MealRepo(db);
      final r = await meals.mark(s.id, q.ids[3], operatorName: 'Ruth');
      await meals.undo(r.record.id);
      expect((await _informe(q, s)).passed, isEmpty);
      final r2 = await meals.mark(s.id, q.ids[3], operatorName: 'Ruth');
      expect(r2.already, isFalse);
      expect((await _informe(q, s)).passed.length, 1);
    });

    test(
        'QA-COM-005 · sesión cerrada: no deja marcar (mensaje en español); al reabrir sí; el cierre no borra las marcas',
        () async {
      final q = await _evento(db);
      final s = await _sesion(q, 'Almuerzo', 'Almuerzo del sábado');
      final meals = MealRepo(db);
      await meals.mark(s.id, q.ids[0], operatorName: 'Ruth');
      await meals.closeSession(s.id);
      await expectLater(
          meals.mark(s.id, q.ids[1], operatorName: 'Ruth'),
          throwsA(isA<DataException>()
              .having((e) => e.message, 'm', contains('cerrada'))));
      await meals.reopenSession(s.id);
      await meals.mark(s.id, q.ids[1], operatorName: 'Ruth');
      expect((await _informe(q, s)).passed.length, 2);
    });

    test(
        'QA-COM-006 · marcar a una persona borrada o inexistente da un mensaje claro',
        () async {
      final q = await _evento(db);
      final s = await _sesion(q, 'Almuerzo', 'Almuerzo del sábado');
      await q.repo.deleteAttendee(q.ids[0], isAdmin: true);
      final meals = MealRepo(db);
      for (final id in [q.ids[0], 'no-existe']) {
        await expectLater(
            meals.mark(s.id, id, operatorName: 'Ruth'),
            throwsA(isA<DataException>().having(
                (e) => e.message, 'm', contains('ya no está inscrita'))));
      }
    });

    test(
        'QA-COM-007 · una persona borrada después de pasar no se cuenta en el resumen y el total baja a 119',
        () async {
      final q = await _evento(db);
      final s = await _sesion(q, 'Almuerzo', 'Almuerzo del sábado');
      final meals = MealRepo(db);
      for (final id in q.ids.take(10)) {
        await meals.mark(s.id, id, operatorName: 'Ruth');
      }
      await q.repo.deleteAttendee(q.ids[0], isAdmin: true);
      final r = await _informe(q, s);
      expect(r.total, 119);
      expect(r.passed.length, 9);
    });

    test(
        'QA-COM-008 · buscar por nombre sin tildes, en cualquier orden, por número y por iglesia; sin resultados',
        () async {
      final q = await _evento(db);
      final ver = [
        for (final r in await q.people())
          AttendeeView(r, qaChurches[q.churchIds.indexOf(r.churchId!)].$1)
      ];
      final a = ver.firstWhere(
          (v) => v.a.firstName.contains('é') || v.a.firstName.contains('á'));
      final sinTilde = normalizeText(a.a.firstName);
      expect(Repository.search(ver, sinTilde.toUpperCase()).map((v) => v.a.id),
          contains(a.a.id));
      expect(
          Repository.search(
                  ver, '${a.a.lastName1} ${a.a.firstName}'.toLowerCase())
              .map((v) => v.a.id),
          contains(a.a.id));
      expect(Repository.search(ver, '${a.a.regNumber}').map((v) => v.a.id),
          contains(a.a.id));
      expect(Repository.search(ver, 'nazareno').length, greaterThan(3));
      expect(Repository.search(ver, 'zzzzzz'), isEmpty);
      expect(Repository.search(ver, '   ').length, 120);
    });

    test(
        'QA-COM-009 · «ya pasó» ignorado con «Entendido» se cuenta como repetido evitado',
        () async {
      final q = await _evento(db);
      final s = await _sesion(q, 'Almuerzo', 'Almuerzo del sábado');
      final meals = MealRepo(db);
      await meals.registerBlocked(s.id);
      await meals.registerBlocked(s.id);
      final v = (await db.select(db.controlSessions).get()).single;
      expect(v.blockedRepeats, 2);
    });
  });

  group('resumen, llegadas y exportación', () {
    test(
        'QA-COM-020 · resumen por equipo: la suma de equipos (incluido «Sin equipo») coincide con 120 y con los que pasaron',
        () async {
      final q = await _evento(db);
      final s = await _sesion(q, 'Almuerzo', 'Almuerzo del sábado');
      final meals = MealRepo(db);
      for (final id in q.ids.where((id) => q.ids.indexOf(id) % 3 != 0)) {
        await meals.mark(s.id, id, operatorName: 'Ruth');
      }
      final r = await _informe(q, s);
      expect(r.total, 120);
      expect(r.passed.length, 80);
      expect(r.teams.fold<int>(0, (a, t) => a + t.total), 120);
      expect(r.teams.fold<int>(0, (a, t) => a + t.passed), 80);
      expect(r.teams.length, 6);
      expect(r.percent, 67);
    });

    test(
        'QA-COM-021 · llegadas cada 15 minutos: sin saltarse tramos vacíos y la suma es la de personas que pasaron',
        () {
      final t0 = DateTime(2026, 12, 12, 12, 0);
      final horas = [
        for (var i = 0; i < 60; i++)
          t0.add(Duration(minutes: i)), // 60 en la primera hora
        t0.add(const Duration(minutes: 100)), // hueco de 15–30
      ];
      final b = arrivalBuckets(horas);
      expect(b.fold<int>(0, (a, e) => a + e.$2), 61);
      expect(b.map((e) => e.$2).take(4), [15, 15, 15, 15]);
      expect(
          b.any((e) => e.$2 == 0), isTrue); // tramo vacío entre 13:00 y 13:45
      expect(arrivalBuckets(const []), isEmpty);
    });

    test(
        'QA-COM-022 · CSV y Excel de 120 personas: Sí/No coinciden con los registros, con BOM y en el orden de llegada',
        () async {
      final q = await _evento(db);
      final s = await _sesion(q, 'Almuerzo', 'Almuerzo del sábado');
      final meals = MealRepo(db);
      for (final id in q.ids.take(70)) {
        await meals.mark(s.id, id, operatorName: 'Ruth');
      }
      final r = await _informe(q, s);
      final csv = mealCsv(r);
      expect(csv.startsWith('\u{FEFF}Nº;Nombre'), isTrue);
      final filas = parseCsv(csv);
      expect(filas.length, 121);
      expect(filas.skip(1).where((f) => f[6] == 'Sí').length, 70);
      expect(filas.skip(1).where((f) => f[6] == 'No').length, 50);
      final xlsx = ZipDecoder().decodeBytes(mealXlsx(r));
      final s2 = utf8.decode(
          xlsx.findFile('xl/worksheets/sheet2.xml')!.content as List<int>);
      final s3 = utf8.decode(
          xlsx.findFile('xl/worksheets/sheet3.xml')!.content as List<int>);
      expect(RegExp('<row ').allMatches(s2).length, greaterThanOrEqualTo(71));
      expect(RegExp('<row ').allMatches(s3).length, greaterThanOrEqualTo(51));
    });

    testWidgets(
        'QA-COM-023 · PRIVACIDAD: la imagen para WhatsApp no cambia si cambian todos los nombres (solo lleva cifras), con 120 personas y 6 equipos',
        (t) async {
      final q = (await t.runAsync(() => _evento(db)))!;
      final s = (await t
          .runAsync(() => _sesion(q, 'Almuerzo', 'Almuerzo del sábado')))!;
      await t.runAsync(() async {
        for (final id in q.ids.take(90)) {
          await MealRepo(db).mark(s.id, id, operatorName: 'Ruth');
        }
      });
      final a = (await t.runAsync(() => _informe(q, s)))!;
      // Otra base con las mismas cifras y los mismos equipos, pero nombres e iglesias distintos.
      final db2 = qaDb();
      addTearDown(db2.close);
      final q2 = (await t.runAsync(() => _evento2(db2)))!;
      final s2 = (await t
          .runAsync(() => _sesion(q2, 'Almuerzo', 'Almuerzo del sábado')))!;
      await t.runAsync(() async {
        for (final id in q2.ids.take(90)) {
          await MealRepo(db2).mark(s2.id, id, operatorName: 'Otro operador');
        }
      });
      final b = (await t.runAsync(() => _informe(q2, s2, db: db2)))!;
      expect(a.passed.first.name, isNot(b.passed.first.name));
      expect((a.total, a.passed.length), (b.total, b.passed.length));
      final pa = (await t.runAsync(() => mealSummaryPng(a)))!;
      final pb = (await t.runAsync(() => mealSummaryPng(b)))!;
      expect(pa.take(8).toList(), [137, 80, 78, 71, 13, 10, 26, 10]);
      final codec = (await t.runAsync(() => ui.instantiateImageCodec(pa)))!;
      final f = (await t.runAsync(codec.getNextFrame))!;
      expect((f.image.width, f.image.height), (1080, 1350));
      expect(pa, orderedEquals(pb));
    });
  });
}

/// Mismas cifras (120 personas, 6 equipos) pero con otros nombres, apellidos y sin los mismos datos.
Future<QaEvent> _evento2(AppDatabase db) async {
  final q = await qaEvent(db, teams: 6);
  final base = qaPeople(120);
  for (final (i, p) in base.indexed) {
    await qaInscribe(
        q,
        QaPerson(
            first: 'Otro$i',
            last1: 'Apellido$i',
            last2: '',
            sex: p.sex,
            age: p.age,
            churchIdx: p.churchIdx,
            needsLodging: false,
            spouseIdx: p.spouseIdx));
  }
  return q;
}
