// QA · Reportes (Excel / CSV / PDF): las sumas coinciden con los datos reales (120 y 1000 personas).
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/repository.dart';
import 'package:mi_evento/export/report_export.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'qa_support.dart';

Future<ReportData> _datos(QaEvent q, {bool phone = false}) async {
  final ev = await (q.db.select(q.db.events)
        ..where((e) => e.id.equals(q.eventId)))
      .getSingle();
  final ch = {
    for (final c in await q.db.select(q.db.churches).get()) c.id: c.name
  };
  final people = await q.people();
  return buildReportData(
    event: ev,
    people: [for (final p in people) AttendeeView(p, ch[p.churchId])],
    ranges: await q.repo.ageRanges(q.eventId),
    lodgingNames: {
      for (final l in await q.lodgingViews()) l.row.id: l.row.name
    },
    teamNames: {for (final t in await q.teamRows()) t.id: t.name},
    includePhone: phone,
    now: DateTime(2026, 12, 12),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  setUp(() => db = qaDb());
  tearDown(() => db.close());

  Future<QaEvent> evento120() async {
    final q = await qaEvent(db, teams: 6);
    await qaInscribeAll(q, qaPeople(120));
    await qaLodgings(q);
    await qaSuggestAndAccept(q);
    return q;
  }

  test(
      'QA-REP-001 · las cinco secciones suman 120 y cada cifra coincide con un conteo directo de los datos',
      () async {
    final q = await evento120();
    final d = await _datos(q);
    for (final s in d.sections) {
      expect(s.total, 120, reason: s.title);
    }
    final people = await q.people();
    int n(String t, String label) => d.sections
        .firstWhere((s) => s.title == t)
        .rows
        .firstWhere((r) => r.label == label)
        .count;
    expect(n('Por sexo', 'Hombres'), people.where((p) => p.sex == 'M').length);
    expect(n('Por sexo', 'Mujeres'), people.where((p) => p.sex == 'F').length);
    final rangos = AgeRange.defaults;
    for (final r in rangos) {
      expect(n('Por rango de edad', r.label),
          people.where((p) => AgeRange.of(p.age, rangos) == r).length,
          reason: r.label);
    }
    expect(
        d.sections
            .firstWhere((s) => s.title == 'Por rango de edad')
            .rows
            .fold<int>(0, (a, r) => a + r.count),
        120);
    final lugar = d.sections.firstWhere((s) => s.title == 'Por hospedaje');
    expect(lugar.rows.fold<int>(0, (a, r) => a + r.count), 120);
    expect(
        lugar.rows.where((r) => r.label == 'Necesitan y sin asignar'), isEmpty,
        reason: 'todos tienen hospedaje');
    expect(n('Por hospedaje', 'No necesitan hospedaje'),
        people.where((p) => !p.needsLodging).length);
    expect(
        d.sections
            .firstWhere((s) => s.title == 'Por equipo')
            .rows
            .where((r) => r.label == 'Sin equipo'),
        isEmpty);
    expect(d.sections.firstWhere((s) => s.title == 'Por iglesia').rows.length,
        qaChurches.length);
  });

  test(
      'QA-REP-002 · el CSV del listado trae las 120 filas, sin teléfono por defecto y con teléfono si se pide',
      () async {
    final q = await evento120();
    final sin = attendeesCsv(await _datos(q));
    final con = attendeesCsv(await _datos(q, phone: true));
    expect(sin.startsWith('\u{FEFF}Nº;Nombre'), isTrue);
    expect(parseCsvComa(sin).length, 121);
    expect(sin.contains('Teléfono'), isFalse);
    final conTel = (await q.people()).where((p) => p.phone != null).toList();
    expect(conTel, isNotEmpty);
    for (final p in conTel) {
      expect(sin.contains(p.phone!), isFalse,
          reason: 'el teléfono no debe salir sin pedirlo');
      expect(con.contains(p.phone!), isTrue);
    }
    expect(con.split('\r\n').first, endsWith('Teléfono'));
  });

  test(
      'QA-REP-003 · el Excel trae «Resumen» y «Asistentes» con las mismas cifras que las secciones y 120 filas de personas',
      () async {
    final q = await evento120();
    final d = await _datos(q);
    final a = ZipDecoder().decodeBytes(reportXlsx(d));
    String hoja(int n) => utf8
        .decode(a.findFile('xl/worksheets/sheet$n.xml')!.content as List<int>);
    final wb = utf8.decode(a.findFile('xl/workbook.xml')!.content as List<int>);
    expect(wb, allOf(contains('Resumen'), contains('Asistentes')));
    expect(RegExp('<row ').allMatches(hoja(2)).length, 121);
    expect(hoja(1), contains('<v>120</v>'));
    for (final s in d.sections) {
      expect(hoja(1), contains(s.title));
    }
  });

  test(
      'QA-REP-004 · el PDF de reportes con 120 personas se genera, y con 300 se reparte en más hojas',
      () async {
    final q = await evento120();
    final pdf = await reportPdf(await _datos(q), bundle: rootBundle);
    expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
    final pages120 = RegExp(r'/Type\s*/Page[^s]')
        .allMatches(String.fromCharCodes(pdf))
        .length;
    final db2 = qaDb();
    addTearDown(db2.close);
    final q2 = await qaEvent(db2, teams: 10);
    await qaInscribeAll(q2, qaPeople(300, seed: 8, couples: 20));
    final pdf2 = await reportPdf(await _datos(q2), bundle: rootBundle);
    final pages300 = RegExp(r'/Type\s*/Page[^s]')
        .allMatches(String.fromCharCodes(pdf2))
        .length;
    expect(pages300, greaterThan(pages120));
  });

  test(
      'QA-REP-005 · reportes de un evento sin personas: todo en cero y sin fallar',
      () async {
    final q = await qaEvent(db, teams: 2);
    final d = await _datos(q);
    expect(d.total, 0);
    expect(d.sections.every((s) => s.total == 0), isTrue);
    expect(attendeesCsv(d).split('\r\n').length, 2); // título + salto final
    expect(reportXlsx(d), isNotEmpty);
    final pdf = await reportPdf(d, bundle: rootBundle);
    expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
  });
}

/// Lee un CSV con «,» como separador.
List<List<String>> parseCsvComa(String s) => parseCsv(s);
