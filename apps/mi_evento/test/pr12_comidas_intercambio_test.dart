import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show Size;
import 'package:mi_evento/backup/file_picker.dart';
import 'package:mi_evento/export/file_saver.dart';
import 'package:mi_evento/providers.dart';
import 'helpers.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/meal_exchange.dart';
import 'package:mi_evento/data/meal_repo.dart';
import 'package:mi_evento/data/repository.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

void main() {
  late AppDatabase db;
  late Repository repo;
  late MealRepo meals;
  late String ev, ev2;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = Repository(db);
    meals = MealRepo(db);
    ev = await repo.createEvent(
        name: 'A', startDate: '2026-11-27', endDate: '2026-11-29');
    ev2 = await repo.createEvent(
        name: 'B', startDate: '2027-03-05', endDate: '2027-03-06');
    await meals.ensureDefaultTypes(ev);
    await meals.ensureDefaultTypes(ev2);
  });
  tearDown(() => db.close());

  String csv(List<List<String>> rows) => buildCsvDelimited(rows);

  test('fechas y horas: formatos aceptados y rechazados', () {
    expect(parseDay('2026-11-28'), DateTime(2026, 11, 28));
    expect(parseDay('28/11/2026'), DateTime(2026, 11, 28));
    expect(parseDay('31/02/2026'), isNull);
    expect(parseDay('mañana'), isNull);
    expect(parseDayTime('2026-11-28 13:05'), DateTime(2026, 11, 28, 13, 5));
    expect(parseDayTime('2026-11-28'), DateTime(2026, 11, 28));
    expect(parseDayTime('2026-11-28 25:00'), isNull);
  });

  group('sesiones', () {
    test('exportar → importar en otro evento: fuera de fechas queda sin fecha',
        () async {
      final almuerzo =
          (await meals.types(ev)).firstWhere((t) => t.name == 'Almuerzo');
      await meals.createSession(ev, almuerzo.id, 'Almuerzo sábado',
          date: DateTime(2026, 11, 28));
      await meals.createSession(ev, almuerzo.id, 'Almuerzo sin día');
      final rows = await MealSessionsExchange(db, ev).export();
      expect(rows.first, ['sesion', 'tipo', 'fecha']);
      expect(rows[1], ['Almuerzo sábado', 'Almuerzo', '2026-11-28']);
      expect(rows[2], ['Almuerzo sin día', 'Almuerzo', '']);

      final imp = MealSessionsExchange(db, ev2);
      final pre = await imp.preview(csv(rows));
      expect(pre.work, 2);
      expect(pre.lines.join('|'), contains('sin fecha'));
      await imp.apply(csv(rows));
      final got = await (db.select(db.controlSessions)
            ..where((s) => s.eventId.equals(ev2)))
          .get();
      expect(got.map((s) => s.name).toSet(),
          {'Almuerzo sábado', 'Almuerzo sin día'});
      expect(got.every((s) => s.scheduledAt == null), isTrue);
      // Repetir: ya existen, no hay nada que importar.
      final again = await imp.preview(csv(rows));
      expect(again.work, 0);
      expect(again.lines.join('|'), contains('Ya existían'));
    });

    test('una fecha dentro del evento se conserva; un tipo nuevo se crea',
        () async {
      final imp = MealSessionsExchange(db, ev);
      final text = csv([
        ['sesion', 'tipo', 'fecha'],
        ['Merienda del viernes', 'Merienda', '27/11/2026'],
      ]);
      final pre = await imp.preview(text);
      expect(pre.lines.join('|'), contains('Merienda'));
      await imp.apply(text);
      final s = await (db.select(db.controlSessions)
            ..where((s) => s.eventId.equals(ev)))
          .getSingle();
      expect(s.scheduledAt, DateTime(2026, 11, 27));
      expect((await meals.types(ev)).map((t) => t.name), contains('Merienda'));
    });

    test('filas con problemas avisan y no se importan; faltan columnas',
        () async {
      final imp = MealSessionsExchange(db, ev);
      final pre = await imp.preview(csv([
        ['sesion', 'tipo', 'fecha'],
        ['', 'Almuerzo', ''],
        ['Sin tipo', '', ''],
        ['Fecha rara', 'Almuerzo', 'pronto'],
        ['Repetida', 'Almuerzo', ''],
        ['repetida', 'Almuerzo', ''],
        ['Buena', 'Cena', ''],
      ]));
      expect(pre.warnings.length, 4);
      expect(pre.work, 2);
      final bad = await imp.preview(csv([
        ['nombre'],
        ['x']
      ]));
      expect(bad.warnings.single, contains('Faltan columnas'));
      expect(bad.work, 0);
    });
  });

  group('quién pasó', () {
    Future<(ControlSession, List<AttendeeRow>)> base() async {
      final people = [
        for (final n in ['Ana', 'Beto', 'Cira'])
          await repo.addAttendee(
              eventId: ev,
              firstName: n,
              lastName1: 'Pérez',
              sex: Sex.male,
              age: 30)
      ];
      final t = (await meals.types(ev)).first;
      final s = await meals.createSession(ev, t.id, 'Desayuno viernes');
      return (s, people);
    }

    test('exportar y volver a importar no duplica; importar en blanco copia',
        () async {
      final (s, people) = await base();
      await meals.mark(s.id, people[0].id, operatorName: 'Ruth');
      await meals.mark(s.id, people[1].id, operatorName: 'Ruth');
      final undone = await meals.mark(s.id, people[2].id, operatorName: 'Ruth');
      await meals.undo(undone.record.id); // deshecha: no se exporta
      final rep = await meals.mark(s.id, people[0].id,
          operatorName: 'Ruth', repeat: true);
      // En la vida real un repetido llega unos segundos después, no en el mismo instante.
      await (db.update(db.controlRecords)
            ..where((r) => r.id.equals(rep.record.id)))
          .write(ControlRecordsCompanion(
              markedAt:
                  Value(rep.record.markedAt.add(const Duration(seconds: 7)))));

      final rows = await MealRecordsExchange(db, ev).export();
      expect(rows.first.first, 'sesion');
      expect(rows.length, 4); // títulos + 3 marcas activas
      expect(rows.where((r) => r.last == 'Sí').length, 1);
      expect(rows[1][2], '${people[0].regNumber}');

      // Mismo evento: todo está ya marcado.
      final same = MealRecordsExchange(db, ev);
      final pre = await same.preview(csv(rows));
      expect(pre.work, 0);
      expect(pre.lines.join('|'), contains('Ya estaban marcadas'));

      // Otro dispositivo (base vacía de marcas): se copian las 3.
      await (db.delete(db.controlRecords)).go();
      final res = await same.apply(csv(rows));
      expect(res.lines.first, 'Marcas nuevas: 3');
      final got = await db.select(db.controlRecords).get();
      expect(got.length, 3);
      expect(got.where((r) => r.repeatOverride).length, 1);
      expect(got.every((r) => r.operatorName == 'Ruth'), isTrue);
    });

    test(
        'avisos: sesión inexistente, número desconocido, preinscrito, hora mala',
        () async {
      final (_, people) = await base();
      final pre = await repo.addAttendee(
          eventId: ev,
          firstName: 'Pre',
          lastName1: 'Inscrito',
          sex: Sex.female,
          age: 20,
          preregistered: true);
      final r = MealRecordsExchange(db, ev);
      final out = await r.preview(csv([
        ['sesion', 'numero', 'hora'],
        ['No existe', '${people[0].regNumber}', ''],
        ['Desayuno viernes', '999', ''],
        ['Desayuno viernes', '${pre.regNumber}', ''],
        ['Desayuno viernes', '${people[0].regNumber}', 'ayer'],
        ['Desayuno viernes', '${people[1].regNumber}', '2026-11-27 07:30'],
      ]));
      expect(out.warnings.length, 4);
      expect(out.work, 1);
      final bad = await r.preview(csv([
        ['sesion'],
        ['x']
      ]));
      expect(bad.warnings.single, contains('Faltan columnas'));
    });

    test('una marca de otra persona distinta hora cuenta como repetida',
        () async {
      final (s, people) = await base();
      final r = MealRecordsExchange(db, ev);
      await r.apply(csv([
        ['sesion', 'numero', 'hora'],
        ['Desayuno viernes', '${people[0].regNumber}', '2026-11-27 07:30'],
        ['Desayuno viernes', '${people[0].regNumber}', '2026-11-27 08:10'],
      ]));
      final got = await (db.select(db.controlRecords)
            ..where((x) => x.sessionId.equals(s.id))
            ..orderBy([(x) => OrderingTerm.asc(x.markedAt)]))
          .get();
      expect(got.map((x) => x.repeatOverride), [false, true]);
    });
  });

  testWidgets(
      'pantalla de Comidas: exportar, importar sesiones, plantillas y columnas desde el menú ⋮',
      (t) async {
    final saver = MemoryFileSaver();
    final picker = MemoryFilePick();
    final c = await pumpApp(t, const Size(1200, 2400), overrides: [
      fileSaverProvider.overrideWithValue(saver),
      filePickProvider.overrideWithValue(picker),
    ]);
    await t.runAsync(() async {
      final e = await c.repo.createEvent(
          name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
      final m = MealRepo(c.db);
      await m.ensureDefaultTypes(e);
      final ty = (await m.types(e)).first;
      await m.createSession(e, ty.id, 'Desayuno sábado',
          date: DateTime(2026, 12, 13));
    });
    await login(t, 'admin', 'secreto1');
    await t.tap(find.text('Retiro'));
    await settle(t);
    await t.tap(find.text('Comidas').first);
    await settle(t);

    await tapKey(t, 'cm-ses-exportar');
    await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)));
    await t.pump();
    final ses = utf8.decode(saver.saved['sesiones-comidas-retiro.csv']!);
    expect(ses, contains('Desayuno sábado;Desayuno;2026-12-13'));
    await tapKey(t, 'cm-exportar');
    await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)));
    await t.pump();
    expect(saver.saved.containsKey('quien-paso-retiro.csv'), isTrue);
    await tapKey(t, 'cm-plantilla-sesiones');
    await tapKey(t, 'cm-plantilla-registros');
    expect(saver.saved.containsKey('plantilla-sesiones-comidas.csv'), isTrue);
    expect(saver.saved.containsKey('plantilla-quien-paso.csv'), isTrue);

    picker.file = PickedFile(
        'sesiones.csv',
        utf8.encode(csv([
          ['sesion', 'tipo', 'fecha'],
          ['Cena sábado', 'Cena', '2026-12-13'],
          ['Desayuno sábado', 'Desayuno', ''],
        ])));
    await tapKey(t, 'cm-ses-importar');
    expect(find.text('Sesiones nuevas: 1'), findsOneWidget);
    expect(find.textContaining('Ya existían (se omiten): 1'), findsOneWidget);
    await tapKey(t, 'ti-importar');
    await t.tap(find.text('Aceptar'));
    await settle(t);
    final names = await t.runAsync(() async => [
          for (final x in await c.db.select(c.db.controlSessions).get()) x.name
        ]);
    expect(names!.toSet(), {'Desayuno sábado', 'Cena sábado'});
  });
}
