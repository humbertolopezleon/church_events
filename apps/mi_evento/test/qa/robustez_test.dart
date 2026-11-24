// QA · Robustez e interfaz: rendimiento con 1000 inscritos (tiempos medidos), letra grande,
// ventana baja, datos raros sin spinners infinitos y datos que sobreviven al cerrar la app.
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento/backup/backup_service.dart';
import 'package:mi_evento/data/attendee_exchange.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/repository.dart';
import 'package:mi_evento/data/team_pieces.dart';
import 'package:mi_evento/export/report_export.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import '../helpers.dart';
import 'qa_support.dart';
import 'qa_ui_support.dart';

const _head =
    'id;numero;nombre;apellido1;apellido2;sexo;edad;iglesia;provincia;municipio;telefono;necesita_hospedaje;hospedaje;equipo;pareja_numero;grupos;observaciones';

/// 1000 filas de CSV con semilla fija (60 matrimonios).
String csv1000() {
  final people = qaPeople(1000, seed: 77, couples: 60);
  final b = StringBuffer('$_head\n');
  for (final (i, p) in people.indexed) {
    final sp = p.spouseIdx == null ? '' : '${p.spouseIdx! + 1}';
    b.writeln(
        ';${i + 1};${p.first};${p.last1};${p.last2};${p.sex == Sex.male ? 'Hombre' : 'Mujer'};${p.age};${qaChurches[p.churchIdx].$1};;;${p.phone ?? ''};${p.needsLodging ? 'Sí' : 'No'};;;$sp;;');
  }
  return b.toString();
}

Future<List<String>> _desbordes(WidgetTester t) async {
  final out = <String>[];
  Object? e;
  while ((e = t.takeException()) != null) {
    out.add('$e'.split('\n').first);
  }
  return out;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
      'rendimiento con 1000 inscritos (tiempos medidos en el entorno de pruebas)',
      () {
    test(
        'QA-ROB-001 · abrir lista, buscar, exportar/importar CSV, generar equipos, copia CSV, reportes y alta nº 1001',
        () async {
      final db = qaDb();
      addTearDown(db.close);
      final q = await qaEvent(db, teams: 20, groups: const []);
      final ex = AttendeeExchange(db);
      final sw = Stopwatch();
      int ms() {
        final v = sw.elapsedMilliseconds;
        sw
          ..reset()
          ..start();
        return v;
      }

      sw.start();
      final plan = await ex.plan(q.eventId, parseAttendeesCsv(csv1000()));
      final tPlan = ms();
      final rep = await ex.apply(q.eventId, plan);
      final tImport = ms();
      expect(rep.created, 1000);
      // Desde QA-BUG-006 el CSV reparte equipos solo (como el formulario): se mide el balance.
      final trasImportar = await qaTeamStats(q);
      metric(
          'ROB-001 equipos tras importar 1000 por CSV (automático): ${evaluateBalance(trasImportar).length} topes superados; ${qaTeamSummary(trasImportar).split(' | ').take(2).join(' | ')} …');

      final lista = await q.repo.watchAttendees(q.eventId).first;
      final tLista = ms();
      expect(lista.length, 1000);

      for (final txt in ['peña', 'nuñez', 'maria jose', '500', 'bautista']) {
        Repository.search(lista, txt);
      }
      final tBuscar = ms();

      final csv = await ex.exportCsv(q.eventId);
      final tExport = ms();
      expect(parseCsv(csv).length, 1001);

      // Generar equipos para los 1000 (propuesta) y aceptarla.
      final people = await q.people();
      final teams = await q.teamRows();
      final built = buildTeamPieces(people,
          spouses: await q.social.spouseMap(q.eventId),
          together: const [],
          includeAssigned: true); // reorganizar a todos
      final plantilla = generateTeams(
          teams: [for (final t in teams) TeamStats.of(t.id, t.name, const [])],
          pieces: built.pieces);
      final tGenerar = ms();
      await q.teams.applyPlan(plantilla.assignments);
      final tAplicar = ms();
      expect(plantilla.assignments.length, 1000);
      final stats = await qaTeamStats(q);
      expect(evaluateBalance(stats), isEmpty, reason: qaTeamSummary(stats));

      final bytes = await BackupService(db).export(q.eventId);
      final tCopia = ms();
      final db2 = qaDb();
      addTearDown(db2.close);
      await BackupService(db2).import(decodeBundle(bytes));
      final tAbrir = ms();
      expect((await db2.select(db2.attendees).get()).length, 1000);

      final ch = {
        for (final c in await db.select(db.churches).get()) c.id: c.name
      };
      final datos = buildReportData(
          event: await (db.select(db.events)).getSingle(),
          people: [
            for (final p in await q.people()) AttendeeView(p, ch[p.churchId])
          ],
          ranges: AgeRange.defaults,
          lodgingNames: const {},
          teamNames: {for (final t in teams) t.id: t.name});
      attendeesCsv(datos);
      reportXlsx(datos);
      final tRepCsvXlsx = ms();
      final datos400 = buildReportData(
          event: await (db.select(db.events)).getSingle(),
          people: [
            for (final p in (await q.people()).take(400))
              AttendeeView(p, ch[p.churchId])
          ],
          ranges: AgeRange.defaults,
          lodgingNames: const {},
          teamNames: {for (final t in teams) t.id: t.name});
      ms();
      final pdf = await reportPdf(datos400, bundle: rootBundle);
      final tPdf = ms();
      expect(String.fromCharCodes(pdf.take(5)), '%PDF-');

      // Alta nº 1001 con equipo automático (lo que tarda «Guardar» con 1000 ya inscritos).
      final extra = qaPeople(1010, seed: 123)
          .where((p) => p.spouseIdx == null)
          .take(10)
          .toList();
      for (final p in extra) {
        p.groups = const {};
        await qaInscribe(q, p);
      }
      final tAlta = ms() / extra.length;

      metric(
          'ROB-001 1000 inscritos → revisar CSV $tPlan ms · importar CSV $tImport ms · abrir lista $tLista ms · 5 búsquedas $tBuscar ms · exportar CSV $tExport ms · '
          'generar equipos (20) $tGenerar ms · aplicar $tAplicar ms · copia CSV $tCopia ms (${(bytes.length / 1024).toStringAsFixed(0)} KB) · abrir copia $tAbrir ms · '
          'reportes CSV+Excel $tRepCsvXlsx ms · PDF de 400 personas $tPdf ms · alta nº 1001 con equipo automático ${tAlta.toStringAsFixed(0)} ms (promedio)');
      for (final v in [
        tPlan,
        tImport,
        tLista,
        tBuscar,
        tExport,
        tGenerar,
        tAplicar,
        tCopia,
        tAbrir,
        tRepCsvXlsx,
        tPdf
      ]) {
        expect(v, lessThan(30000));
      }
      expect(tAlta, lessThan(2000));
    });
  });

  test(
      'QA-ROB-002 · el PDF de reportes con 1000 inscritos se genera y tiene todas las páginas necesarias',
      () async {
    final db = qaDb();
    addTearDown(db.close);
    final q = await qaEvent(db, teams: 20, groups: const []);
    final ex = AttendeeExchange(db);
    await ex.apply(
        q.eventId, await ex.plan(q.eventId, parseAttendeesCsv(csv1000())));
    final ch = {
      for (final c in await db.select(db.churches).get()) c.id: c.name
    };
    final datos = buildReportData(
        event: await (db.select(db.events)).getSingle(),
        people: [
          for (final p in await q.people()) AttendeeView(p, ch[p.churchId])
        ],
        ranges: AgeRange.defaults,
        lodgingNames: const {},
        teamNames: const {});
    final sw = Stopwatch()..start();
    final pdf = await reportPdf(datos, bundle: rootBundle);
    expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
    // Páginas: cada una declara «/Type /Page» (el árbol «/Pages» no cuenta).
    final paginas =
        RegExp(r'/Type\s*/Page[^s]').allMatches(latin1.decode(pdf)).length;
    metric(
        'ROB-002 PDF de reportes con ${datos.total} inscritos: ${sw.elapsedMilliseconds} ms, ${(pdf.length / 1024).round()} KB, $paginas páginas');
    expect(paginas, greaterThan(20));
    // Con 1000 personas hacen falta unas 35-45 páginas de listado más el resumen.
    expect(paginas, lessThan(200));
  });

  group('interfaz con muchos datos y condiciones difíciles', () {
    /// Evento de 120 personas con hospedajes, equipos, comidas y grupos.
    Future<void> prep(QaEvent q) async {
      await qaInscribeAll(q, qaPeople(120));
      await qaLodgings(q);
      await qaSuggestAndAccept(q);
    }

    Future<List<String>> recorrer(
        WidgetTester t, List<String> pantallas) async {
      final problemas = <String>[];
      for (final p in pantallas) {
        final hayMas = find.text('Más').evaluate().isNotEmpty;
        if (!hayMas && !await qaScrollMenuTo(t, p)) {
          problemas.add('$p: no se encuentra en el menú');
          continue;
        }
        await qaGoTo(t, p);
        await settle(t);
        for (final d in await _desbordes(t)) {
          problemas.add('$p: $d');
        }
        if (find.byType(CircularProgressIndicator).evaluate().isNotEmpty) {
          problemas.add('$p: indicador de carga que no termina');
        }
      }
      return problemas;
    }

    const pantallas = [
      'Panel',
      'Registrar',
      'Asistentes',
      'Hospedajes',
      'Equipos',
      'Comidas',
      'Reportes'
    ];

    testWidgets(
        'QA-ROB-010 · 1000 inscritos en la lista: se abre, cuenta bien y la búsqueda filtra, sin desbordes',
        (t) async {
      final a = await qaOpen(t, qaPc,
          goTo: 'Asistentes', teams: 0, offersTeams: false, prepare: (q) async {
        await AttendeeExchange(q.db).apply(
            q.eventId,
            await AttendeeExchange(q.db)
                .plan(q.eventId, parseAttendeesCsv(csv1000())));
      });
      expect(find.text('1000 inscritos'), findsOneWidget);
      final sw = Stopwatch()..start();
      await t.enterText(find.byKey(const Key('buscar')), 'peña');
      await settle(t);
      metric(
          'ROB-010 búsqueda en pantalla con 1000 inscritos: ${sw.elapsedMilliseconds} ms (incluye esperas de la prueba)');
      expect(find.textContaining(' de 1000'), findsOneWidget);
      expect(find.byKey(const Key('lista-conteo')), findsOneWidget);
      expect(await _desbordes(t), isEmpty);
      expect((await qaRows(t, a.q.people)).length, 1000);
    });

    for (final (tam, escala, omitir) in [
      (const Size(400, 900), 1.0, false),
      (const Size(400, 900), 1.3, false),
      (const Size(360, 640), 1.0, false),
      (const Size(360, 640), 1.5, false),
    ]) {
      testWidgets(
          'QA-ROB-011 · móvil ${tam.width.toInt()}×${tam.height.toInt()} con letra al ${(escala * 100).round()} %: ninguna pantalla se desborda ni queda cargando${omitir ? ' [Defecto QA-BUG-010]' : ''}',
          (t) async {
        await qaOpen(t, tam, goTo: 'Panel', prepare: prep);
        t.platformDispatcher.textScaleFactorTestValue = escala;
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        await t.pump();
        final problemas = await recorrer(t, pantallas);
        metric(
            'ROB-011 móvil ${tam.width.toInt()}×${tam.height.toInt()} letra ${(escala * 100).round()} %: ${problemas.length} problemas ${problemas.take(6)}');
        expect(problemas, isEmpty);
      }, skip: omitir);
    }

    for (final (nombre, ancho, alto, omitir) in [
      ('portátil 1366×768 al 125 %', 1093.0, 614.0, false),
      ('portátil 1366×768 al 150 %', 911.0, 512.0, false),
    ]) {
      testWidgets(
          'QA-ROB-012 · ventana de $nombre (${ancho.toInt()}×${alto.toInt()} lógicos) con 120 personas: ninguna pantalla se desborda ni queda cargando, y todas se alcanzan desde el menú${omitir ? ' [Defecto QA-BUG-011]' : ''}',
          (t) async {
        await qaOpen(t, Size(ancho, alto), goTo: 'Panel', prepare: prep);
        final problemas = await recorrer(t, pantallas);
        metric(
            'ROB-012 $nombre: ${problemas.length} problemas ${problemas.take(6)}');
        expect(problemas, isEmpty);
      }, skip: omitir);
    }

    testWidgets(
        'QA-ROB-013 · datos raros en la base (edad 0, sexo desconocido, nombre vacío, equipo y hospedaje borrados): todas las pantallas responden sin spinner infinito ni errores',
        (t) async {
      await qaOpen(t, qaPc, goTo: 'Panel', prepare: (q) async {
        await qaInscribeAll(q, qaPeople(30));
        await qaLodgings(q);
        await qaSuggestAndAccept(q);
        final ps = await q.people();
        final db = q.db;
        Future<void> raro(String id, AttendeesCompanion c) =>
            (db.update(db.attendees)..where((x) => x.id.equals(id))).write(c);
        await raro(ps[0].id, const AttendeesCompanion(age: Value(0)));
        await raro(ps[1].id, const AttendeesCompanion(sex: Value('X')));
        await raro(ps[2].id, const AttendeesCompanion(firstName: Value('')));
        await raro(ps[3].id, const AttendeesCompanion(age: Value(999)));
        await raro(ps[4].id, AttendeesCompanion(notes: Value('x' * 5000)));
        // Un equipo y un hospedaje borrados (lógico) con gente asignada.
        await q.teams.delete(q.teamIds[0]);
        await (db.update(db.lodgings)
              ..where((l) => l.eventId.equals(q.eventId)))
            .write(LodgingsCompanion(deletedAt: Value(DateTime.now().toUtc())));
        await q.repo.updateEvent(q.eventId,
            name: 'Congreso QA 2026',
            startDate: '2026-12-13',
            endDate: '2026-12-13',
            offersLodging: true,
            offersTeams: true);
      });
      final problemas = await recorrer(t, pantallas);
      metric(
          'ROB-013 datos raros: ${problemas.length} problemas ${problemas.take(6)}');
      expect(problemas, isEmpty);
    });
  });

  group('persistencia', () {
    test(
        'QA-ROB-020 · los datos sobreviven a cerrar y volver a abrir la base (archivo real en carpeta temporal)',
        () async {
      final dir = Directory.systemTemp.createTempSync('qa_persistencia');
      addTearDown(() {
        if (dir.existsSync()) dir.deleteSync(recursive: true);
      });
      final file = File('${dir.path}/mievento.db');
      var db = AppDatabase(NativeDatabase(file));
      final q = await qaEvent(db, teams: 4);
      await qaInscribeAll(q, qaPeople(40));
      final idDispositivo = await db.deviceId();
      await db.close(); // «se cierra la app» (o se apaga el equipo)
      db = AppDatabase(NativeDatabase(file));
      addTearDown(db.close);
      expect((await db.select(db.attendees).get()).length, 40);
      expect(await db.deviceId(), idDispositivo);
      final stats = await qaTeamStats(
          QaEvent(db, q.eventId, q.churchIds, q.groupIds, q.teamIds));
      expect(stats.fold<int>(0, (a, t) => a + t.size), 40);
      // Y se puede seguir inscribiendo con el número siguiente.
      final q2 = QaEvent(db, q.eventId, q.churchIds, q.groupIds, q.teamIds);
      final r = await qaInscribe(
          q2, qaPeople(60, seed: 5).firstWhere((p) => p.spouseIdx == null));
      expect(r.regNumber, 41);
    });
  });
}
