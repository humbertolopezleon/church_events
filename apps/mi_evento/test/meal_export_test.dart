import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/meal_repo.dart';
import 'package:mi_evento/data/repos_b.dart';
import 'package:mi_evento/data/repository.dart';
import 'package:mi_evento/export/file_saver.dart';
import 'package:mi_evento/export/meal_report.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

/// Datos reales en una base en memoria: 6 personas, 2 equipos, una sesión con 4 que pasaron
/// (una de ellas marcada dos veces a propósito).
Future<MealReport> sampleReport(AppDatabase db, {String? renameTo}) async {
  final repo = Repository(db), meals = MealRepo(db), teams = TeamRepo(db);
  final ev = await repo.createEvent(
      name: 'Retiro de Jóvenes',
      startDate: '2026-12-12',
      endDate: '2026-12-14');
  final ig =
      await repo.createChurch(name: 'Bautista Ebenezer', province: 'Matanzas');
  final names = renameTo == null
      ? ['Juan', 'María', 'Pedro', 'Ana', 'Luis', 'Eva']
      : List.generate(6, (i) => '$renameTo$i');
  final people = <AttendeeRow>[];
  for (var i = 0; i < 6; i++) {
    people.add(await repo.addAttendee(
        eventId: ev,
        firstName: names[i],
        lastName1: 'Pérez',
        sex: i.isEven ? Sex.male : Sex.female,
        age: 20 + i,
        churchId: ig.id));
  }
  await teams.createMany(ev, 2);
  final tm = await (db.select(db.teams)).get();
  await teams.setTeam(people.take(3).map((p) => p.id), tm[0].id);
  await teams.setTeam(people.skip(3).take(2).map((p) => p.id),
      tm[1].id); // la 6.ª queda sin equipo
  await meals.ensureDefaultTypes(ev);
  final almuerzo =
      (await meals.types(ev)).firstWhere((t) => t.name == 'Almuerzo');
  final s = await meals.createSession(ev, almuerzo.id, 'Almuerzo del sábado',
      operatorName: 'Ruth');
  for (final i in [0, 1, 3, 5]) {
    await meals.mark(s.id, people[i].id, operatorName: 'Ruth');
  }
  await meals.mark(s.id, people[0].id,
      operatorName: 'Ruth', repeat: true); // repetido a propósito
  await meals.registerBlocked(s.id);
  await meals.closeSession(s.id);
  final event = await (db.select(db.events)).getSingle();
  final sv = (await meals.watchSessions(ev).first).single;
  return buildMealReport(
    event: event,
    session: sv,
    people: await (db.select(db.attendees)).get(),
    churchNames: {ig.id: ig.name},
    teams: {for (final t in tm) t.id: t},
    records: await meals.watchRecords(s.id).first,
  );
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases =
      true; // la prueba de privacidad usa dos bases
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('informe', () {
    test('cuenta a cada persona una vez aunque tenga marcas repetidas',
        () async {
      final r = await sampleReport(db);
      expect(r.total, 6);
      expect(r.passed.length, 4);
      expect(r.notPassed.length, 2);
      expect(r.percent, 67);
      expect(r.blockedRepeats, 1);
      expect(r.passed.map((p) => p.name), [
        'Juan Pérez',
        'María Pérez',
        'Ana Pérez',
        'Eva Pérez'
      ]); // en orden de llegada
      expect(r.notPassed.map((p) => p.name), ['Pedro Pérez', 'Luis Pérez']);
    });
    test('por equipo, con «Sin equipo»', () async {
      final r = await sampleReport(db);
      expect(r.teams.map((t) => (t.name, t.passed, t.total)),
          [('Rojo', 2, 3), ('Azul', 1, 2), ('Sin equipo', 1, 1)]);
    });
    test('llegadas y nombre de archivo sin tildes ni espacios', () async {
      final r = await sampleReport(db);
      expect(r.buckets.fold<int>(0, (s, b) => s + b.$2), 4);
      expect(r.fileBase, 'retiro-de-jovenes-almuerzo-del-sabado');
    });
  });

  group('CSV', () {
    test('todas las personas, con Sí/No y hora, y BOM para Excel', () async {
      final report = await sampleReport(db);
      final csv = mealCsv(report);
      final lines = csv.split('\r\n');
      expect(
          csv.startsWith(
              '﻿Nº;Nombre;Sexo;Edad;Iglesia;Equipo;Pasó;Hora;Marcado por'),
          isTrue);
      expect(lines.where((l) => l.contains(';Sí;')).length, 4);
      expect(lines.where((l) => l.contains(';No;')).length, 2);
      expect(lines[1],
          startsWith('1;Juan Pérez;Hombre;20;Bautista Ebenezer;Rojo;Sí;'));
      expect(csvBytes(report).take(3).toList(), [0xEF, 0xBB, 0xBF]);
    });
  });

  group('Excel', () {
    test('tres hojas con los datos correctos', () async {
      final bytes = mealXlsx(await sampleReport(db));
      final a = ZipDecoder().decodeBytes(bytes);
      String sheet(int n) => utf8.decode(
          a.findFile('xl/worksheets/sheet$n.xml')!.content as List<int>);
      final wb =
          utf8.decode(a.findFile('xl/workbook.xml')!.content as List<int>);
      expect(
          wb,
          allOf(contains('name="Resumen"'), contains('name="Pasaron"'),
              contains('name="No pasaron"')));
      expect(
          sheet(1),
          allOf(contains('Retiro de Jóvenes'), contains('<v>6</v>'),
              contains('<v>4</v>'), contains('67 %'), contains('Sin equipo')));
      expect(sheet(2), contains('Juan Pérez'));
      expect(sheet(2),
          isNot(contains('Pedro Pérez'))); // quien no pasó no está en «Pasaron»
      expect(sheet(3), contains('Pedro Pérez'));
    });
  });

  group('imagen para WhatsApp', () {
    testWidgets('PNG de 1080×1350', (t) async {
      final r = (await t.runAsync(() => sampleReport(db)))!;
      final png = (await t.runAsync(() => mealSummaryPng(r)))!;
      expect(
          png.take(8).toList(), [137, 80, 78, 71, 13, 10, 26, 10]); // firma PNG
      final codec = (await t.runAsync(() => ui.instantiateImageCodec(png)))!;
      final f = (await t.runAsync(codec.getNextFrame))!;
      expect((f.image.width, f.image.height), (1080, 1350));
    });

    testWidgets(
        'PRIVACIDAD: la imagen no depende de los nombres de las personas',
        (t) async {
      final a = (await t.runAsync(() => sampleReport(db)))!;
      final db2 = AppDatabase(NativeDatabase.memory());
      addTearDown(db2.close);
      final b = (await t.runAsync(() => sampleReport(db2, renameTo: 'Otro')))!;
      expect(a.passed.first.name,
          isNot(b.passed.first.name)); // los datos personales son distintos
      final pa = (await t.runAsync(() => mealSummaryPng(a)))!;
      final pb = (await t.runAsync(() => mealSummaryPng(b)))!;
      expect(
          pa,
          orderedEquals(
              pb)); // pero las dos imágenes son idénticas: solo llevan cifras
    });
  });

  test('guardado: el sustituto en memoria recibe el archivo con su nombre',
      () async {
    final saver = MemoryFileSaver();
    expect(
        await saver.save('x.csv', Uint8List.fromList([1, 2]),
            mimeType: 'text/csv'),
        isTrue);
    expect(saver.saved['x.csv'], [1, 2]);
  });
}
