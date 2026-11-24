import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:mi_evento_core/mi_evento_core.dart';

import '../data/database.dart';
import '../data/meal_repo.dart' show SessionView;
import '../theme/app_theme.dart';

class MealRow {
  const MealRow(
      {required this.regNumber,
      required this.name,
      required this.sex,
      required this.age,
      required this.church,
      required this.team,
      this.time,
      this.by = ''});
  final int regNumber;
  final String name, sex, church, team, by;
  final int age;
  final DateTime? time; // hora local en que pasó; null = no pasó
}

class TeamLine {
  const TeamLine(this.name, this.colorHex, this.passed, this.total);
  final String name;
  final String? colorHex;
  final int passed, total;
}

/// Todo lo necesario para exportar una sesión de control. Se arma una sola vez y de aquí salen
/// el Excel, el CSV y la imagen: así los tres siempre coinciden.
class MealReport {
  MealReport({
    required this.eventName,
    required this.eventDates,
    required this.sessionName,
    required this.typeName,
    required this.openedAt,
    required this.closedAt,
    required this.blockedRepeats,
    required this.passed,
    required this.notPassed,
    required this.teams,
    required this.buckets,
  });

  final String eventName, eventDates, sessionName, typeName;
  final DateTime? openedAt, closedAt;
  final int blockedRepeats;
  final List<MealRow> passed, notPassed;
  final List<TeamLine> teams;
  final List<(DateTime, int)> buckets;

  int get total => passed.length + notPassed.length;
  int get percent => total == 0 ? 0 : (passed.length * 100 / total).round();
  String get fileBase => '${_slug(eventName)}-${_slug(sessionName)}';
}

String _slug(String s) {
  final n = normalizeText(s).replaceAll(' ', '-');
  return n.isEmpty ? 'sesion' : n;
}

/// Arma el informe a partir de los datos de la sesión. Cada persona cuenta UNA vez aunque tenga
/// varias marcas (repetidas a propósito): se toma la primera hora.
MealReport buildMealReport({
  required Event event,
  required SessionView session,
  required List<AttendeeRow> people,
  required Map<String, String> churchNames,
  required Map<String, TeamRow> teams,
  required List<ControlRecord> records,
}) {
  final first = <String, ControlRecord>{};
  for (final r in records) {
    final cur = first[r.attendeeId];
    if (cur == null || r.markedAt.isBefore(cur.markedAt)) {
      first[r.attendeeId] = r;
    }
  }
  MealRow row(AttendeeRow a) {
    final r = first[a.id];
    return MealRow(
      regNumber: a.regNumber,
      name: [a.firstName, a.lastName1, a.lastName2]
          .where((e) => e.isNotEmpty)
          .join(' '),
      sex: a.sex == 'M' ? 'Hombre' : 'Mujer',
      age: a.age,
      church: churchNames[a.churchId] ?? '',
      team: teams[a.teamId]?.name ?? '',
      time: r?.markedAt.toLocal(),
      by: r?.operatorName ?? '',
    );
  }

  final all = [...people]..sort((a, b) => a.regNumber.compareTo(b.regNumber));
  final passed = [
    for (final a in all)
      if (first.containsKey(a.id)) row(a)
  ]..sort((a, b) => a.time!.compareTo(b.time!));
  final not = [
    for (final a in all)
      if (!first.containsKey(a.id)) row(a)
  ];
  final lines = <TeamLine>[];
  for (final t in teams.values) {
    final members = all.where((a) => a.teamId == t.id).toList();
    lines.add(TeamLine(t.name, t.color,
        members.where((a) => first.containsKey(a.id)).length, members.length));
  }
  final noTeam = all
      .where((a) => a.teamId == null || !teams.containsKey(a.teamId))
      .toList();
  if (noTeam.isNotEmpty && teams.isNotEmpty) {
    lines.add(TeamLine('Sin equipo', null,
        noTeam.where((a) => first.containsKey(a.id)).length, noTeam.length));
  }
  return MealReport(
    eventName: event.name,
    eventDates: 'del ${event.startDate} al ${event.endDate}',
    sessionName: session.row.name,
    typeName: session.typeName,
    openedAt: session.row.openedAt?.toLocal(),
    closedAt: session.row.closedAt?.toLocal(),
    blockedRepeats: session.row.blockedRepeats,
    passed: passed,
    notPassed: not,
    teams: lines,
    buckets: arrivalBuckets([for (final r in passed) r.time!]),
  );
}

/// CSV con TODAS las personas (pasó sí/no) para abrir en cualquier programa.
String mealCsv(MealReport r) => buildCsv([
      [
        'Nº',
        'Nombre',
        'Sexo',
        'Edad',
        'Iglesia',
        'Equipo',
        'Pasó',
        'Hora',
        'Marcado por'
      ],
      for (final p in [
        ...r.passed,
        ...r.notPassed
      ]..sort((a, b) => a.regNumber.compareTo(b.regNumber)))
        [
          '${p.regNumber}',
          p.name,
          p.sex,
          '${p.age}',
          p.church,
          p.team,
          p.time == null ? 'No' : 'Sí',
          p.time == null ? '' : hhmm(p.time!),
          p.by
        ],
    ]);

/// Excel con tres hojas: Resumen, Pasaron (en orden de llegada) y No pasaron.
Uint8List mealXlsx(MealReport r) {
  List<Object?> person(MealRow p, {bool withTime = true}) => [
        p.regNumber,
        p.name,
        p.sex,
        p.age,
        p.church,
        p.team,
        if (withTime) ...[hhmm(p.time!), p.by]
      ];
  const head = ['Nº', 'Nombre', 'Sexo', 'Edad', 'Iglesia', 'Equipo'];
  return buildXlsx([
    XlsxSheet('Resumen', [
      ['Concepto', 'Valor'],
      ['Evento', r.eventName],
      ['Sesión', r.sessionName],
      ['Fechas del evento', r.eventDates],
      [
        'Abierta',
        r.openedAt == null
            ? ''
            : '${r.openedAt!.day}/${r.openedAt!.month}/${r.openedAt!.year} ${hhmm(r.openedAt!)}'
      ],
      ['Cerrada', r.closedAt == null ? 'Abierta todavía' : hhmm(r.closedAt!)],
      ['Inscritos', r.total],
      ['Pasaron', r.passed.length],
      ['No pasaron', r.notPassed.length],
      ['Porcentaje que pasó', '${r.percent} %'],
      ['Repetidos evitados', r.blockedRepeats],
      ['', ''],
      ['Equipo', 'Pasaron / total'],
      for (final t in r.teams) [t.name, '${t.passed} / ${t.total}'],
      ['', ''],
      ['Llegadas cada 15 min', 'Personas'],
      for (final b in r.buckets) [hhmm(b.$1), b.$2],
    ]),
    XlsxSheet('Pasaron', [
      [...head, 'Hora', 'Marcado por'],
      for (final p in r.passed) person(p),
    ]),
    XlsxSheet('No pasaron', [
      head,
      for (final p in r.notPassed) person(p, withTime: false),
    ]),
  ]);
}

/// Imagen cuadrada-vertical (1080×1350) para compartir por WhatsApp.
/// PRIVACIDAD: solo lleva cifras y nombres de equipos; nunca nombres de personas ni teléfonos.
Future<Uint8List> mealSummaryPng(MealReport r) async {
  const w = 1080.0, h = 1350.0;
  final rec = ui.PictureRecorder();
  final c = ui.Canvas(rec, const ui.Rect.fromLTWH(0, 0, w, h));
  final paint = ui.Paint();

  void text(String s, double x, double y,
      {double size = 36,
      ui.Color color = Brand.tinta,
      String family = 'Atkinson',
      bool head = false,
      double width = w - 120,
      ui.TextAlign align = ui.TextAlign.left}) {
    final b = ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: align,
        fontFamily: family,
        fontSize: size,
        fontWeight: head ? ui.FontWeight.w800 : ui.FontWeight.w400,
        maxLines: 2,
        ellipsis: '…'))
      ..pushStyle(ui.TextStyle(
          color: color,
          fontFamily: family,
          fontSize: size,
          fontWeight: head ? ui.FontWeight.w800 : ui.FontWeight.w400,
          fontVariations:
              head ? [const ui.FontVariation('wght', 800)] : const []))
      ..addText(s);
    final p = b.build()..layout(ui.ParagraphConstraints(width: width));
    c.drawParagraph(p, ui.Offset(x, y));
  }

  paint.color = Brand.fondo;
  c.drawRect(const ui.Rect.fromLTWH(0, 0, w, h), paint);
  paint.color = Brand.azul;
  c.drawRect(const ui.Rect.fromLTWH(0, 0, w, 250), paint);
  text(r.eventName, 60, 52,
      size: 54,
      color: const ui.Color(0xFFFFFFFF),
      family: 'Nunito',
      head: true);
  text(r.sessionName, 60, 132, size: 40, color: const ui.Color(0xFFFFFFFF));
  text(r.eventDates, 60, 190, size: 28, color: const ui.Color(0xFFD7E3F4));

  text('${r.percent}%', 60, 290,
      size: 250, family: 'Nunito', head: true, color: Brand.azul);
  text('${r.passed.length}', 560, 330,
      size: 120, family: 'Nunito', head: true, color: Brand.exito);
  text('pasaron de ${r.total} inscritos', 560, 470,
      size: 34, color: Brand.gris, width: 460);
  text('${r.notPassed.length} no pasaron', 560, 520,
      size: 34, color: const ui.Color(0xFF8F4512), width: 460);

  text('Por equipo', 60, 650, size: 34, family: 'Nunito', head: true);
  var y = 705.0;
  for (final t in r.teams.take(7)) {
    text(t.name, 60, y, size: 30, width: 560);
    text('${t.passed}/${t.total}', w - 220, y,
        size: 30, width: 160, align: ui.TextAlign.right);
    paint.color = Brand.azulSuave;
    c.drawRRect(
        ui.RRect.fromRectAndRadius(ui.Rect.fromLTWH(60, y + 44, w - 120, 18),
            const ui.Radius.circular(9)),
        paint);
    final hex = t.colorHex;
    paint.color = hex != null && hex.length == 7
        ? ui.Color(int.parse('FF${hex.substring(1)}', radix: 16))
        : Brand.azul;
    final frac = t.total == 0 ? 0.0 : t.passed / t.total;
    if (frac > 0) {
      c.drawRRect(
          ui.RRect.fromRectAndRadius(
              ui.Rect.fromLTWH(60, y + 44, (w - 120) * frac, 18),
              const ui.Radius.circular(9)),
          paint);
    }
    y += 80;
  }
  final closed = r.closedAt == null
      ? 'Sesión abierta'
      : 'Cerrado a las ${hhmm(r.closedAt!)}';
  text(closed, 60, h - 120, size: 30, color: Brand.gris);
  text('Hecho con Mi Evento', 60, h - 70, size: 28, color: Brand.gris);

  final img = await rec.endRecording().toImage(w.toInt(), h.toInt());
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

/// utf8 de un CSV (con BOM incluido en el texto).
Uint8List csvBytes(MealReport r) => Uint8List.fromList(utf8.encode(mealCsv(r)));
