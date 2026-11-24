import 'dart:typed_data';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:mi_evento_core/mi_evento_core.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/database.dart';
import '../data/repository.dart' show AttendeeView;

/// Una fila del listado de asistentes para exportar.
class ListRow {
  const ListRow({
    required this.regNumber,
    required this.name,
    required this.sex,
    required this.age,
    required this.church,
    required this.province,
    required this.municipality,
    required this.team,
    required this.lodging,
    required this.needsLodging,
    required this.notes,
    this.phone,
  });
  final int regNumber, age;
  final String name, sex, church, province, municipality, team, lodging, notes;
  final bool needsLodging;
  final String? phone;
}

/// Todo lo necesario para exportar los reportes de un evento. Se arma una sola vez: Excel, CSV y PDF coinciden.
class ReportData {
  ReportData(this.eventName, this.eventDates, this.sections, this.rows,
      this.includePhone, this.generatedAt);
  final String eventName, eventDates;
  final List<ReportSection> sections;
  final List<ListRow> rows;
  final bool includePhone;
  final DateTime generatedAt;
  int get total => rows.length;
}

/// El teléfono NO se incluye salvo que se pida ([includePhone]): es el dato más sensible del listado.
ReportData buildReportData({
  required Event event,
  required List<AttendeeView> people,
  required List<AgeRange> ranges,
  required Map<String, String> lodgingNames,
  required Map<String, String> teamNames,
  bool includePhone = false,
  DateTime? now,
}) {
  final sorted = [...people]
    ..sort((a, b) => a.a.regNumber.compareTo(b.a.regNumber));
  final rows = [
    for (final v in sorted)
      ListRow(
        regNumber: v.a.regNumber,
        name: v.fullName,
        sex: v.isMale ? 'Hombre' : 'Mujer',
        age: v.a.age,
        church: v.churchName ?? '',
        province: v.a.province,
        municipality: v.a.municipality,
        team: teamNames[v.a.teamId] ?? '',
        lodging: lodgingNames[v.a.lodgingId] ?? '',
        needsLodging: v.a.needsLodging,
        notes: v.a.notes,
        phone: includePhone ? (v.a.phone ?? '') : null,
      ),
  ];
  final sections = buildReportSections([
    for (final v in sorted)
      ReportPerson(
        isMale: v.isMale,
        age: v.a.age,
        church: v.churchName,
        team: teamNames[v.a.teamId],
        lodging: lodgingNames[v.a.lodgingId],
        needsLodging: v.a.needsLodging,
      ),
  ], ranges);
  return ReportData(event.name, 'del ${event.startDate} al ${event.endDate}',
      sections, rows, includePhone, now ?? DateTime.now());
}

const _head = [
  'Nº',
  'Nombre',
  'Sexo',
  'Edad',
  'Iglesia',
  'Provincia',
  'Municipio',
  'Equipo',
  'Hospedaje',
  'Necesita hospedaje',
  'Observaciones'
];

List<String> _cells(ListRow r, bool phone) => [
      '${r.regNumber}',
      r.name,
      r.sex,
      '${r.age}',
      r.church,
      r.province,
      r.municipality,
      r.team,
      r.lodging,
      r.needsLodging ? 'Sí' : 'No',
      r.notes,
      if (phone) r.phone ?? '',
    ];

List<String> _headers(bool phone) => [..._head, if (phone) 'Teléfono'];

String attendeesCsv(ReportData d) => buildCsv([
      _headers(d.includePhone),
      for (final r in d.rows) _cells(r, d.includePhone)
    ]);

Uint8List reportXlsx(ReportData d) {
  List<List<Object?>> summary() {
    final out = <List<Object?>>[
      ['Reporte', 'Valor'],
      ['Evento', d.eventName],
      ['Fechas', d.eventDates],
      ['Inscritos', d.total],
    ];
    for (final s in d.sections) {
      out.add(['', '']);
      out.add([s.title, 'Personas']);
      for (final r in s.rows) {
        out.add([r.label, r.count]);
      }
    }
    return out;
  }

  return buildXlsx([
    XlsxSheet('Resumen', summary()),
    XlsxSheet('Asistentes', [
      _headers(d.includePhone),
      for (final r in d.rows)
        [
          r.regNumber,
          r.name,
          r.sex,
          r.age,
          r.church,
          r.province,
          r.municipality,
          r.team,
          r.lodging,
          r.needsLodging ? 'Sí' : 'No',
          r.notes,
          if (d.includePhone) r.phone ?? ''
        ],
    ]),
  ]);
}

/// PDF imprimible: portada con los totales y, debajo, el listado de asistentes.
Future<Uint8List> reportPdf(ReportData d, {AssetBundle? bundle}) async {
  final b = bundle ?? rootBundle;
  final regular = pw.Font.ttf(
      await b.load('assets/fonts/AtkinsonHyperlegible-Regular.ttf'));
  final bold =
      pw.Font.ttf(await b.load('assets/fonts/AtkinsonHyperlegible-Bold.ttf'));
  final blue = PdfColor.fromHex('#1D4E89');
  final grey = PdfColor.fromHex('#4A5565');
  String two(int n) => n.toString().padLeft(2, '0');
  final printed =
      '${two(d.generatedAt.day)}/${two(d.generatedAt.month)}/${d.generatedAt.year}';

  pw.Widget table(ReportSection s) =>
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(s.title,
            style: pw.TextStyle(font: bold, fontSize: 13, color: blue)),
        pw.SizedBox(height: 3),
        if (s.rows.isEmpty)
          pw.Text('Sin datos', style: pw.TextStyle(fontSize: 10, color: grey))
        else
          pw.TableHelper.fromTextArray(
            headers: ['', 'Personas', '%'],
            data: [
              for (final r in s.rows)
                [
                  r.label,
                  '${r.count}',
                  d.total == 0 ? '0' : '${(r.count * 100 / d.total).round()}'
                ]
            ],
            headerStyle:
                pw.TextStyle(font: bold, fontSize: 9, color: PdfColors.white),
            headerDecoration: pw.BoxDecoration(color: blue),
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellPadding:
                const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            border: pw.TableBorder.all(
                color: PdfColor.fromHex('#B8C0CC'), width: 0.4),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FixedColumnWidth(50),
              2: const pw.FixedColumnWidth(30)
            },
          ),
        pw.SizedBox(height: 12),
      ]);

  final doc =
      pw.Document(title: 'Reportes de ${d.eventName}', author: 'Mi Evento');
  doc.addPage(pw.MultiPage(
    // El límite por defecto (20 páginas) fallaba desde ~600 inscritos (QA-BUG-009).
    maxPages: 2000,
    pageTheme: pw.PageTheme(
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32)),
    footer: (c) =>
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      pw.Text('${d.eventName} · impreso el $printed',
          style: pw.TextStyle(fontSize: 9, color: grey)),
      pw.Text('Página ${c.pageNumber} de ${c.pagesCount}',
          style: pw.TextStyle(fontSize: 9, color: grey)),
    ]),
    build: (c) => [
      pw.Text(d.eventName,
          style: pw.TextStyle(font: bold, fontSize: 24, color: blue)),
      pw.Text('${d.eventDates} · ${d.total} inscritos',
          style: pw.TextStyle(fontSize: 12, color: grey)),
      pw.SizedBox(height: 14),
      pw.Wrap(spacing: 24, runSpacing: 0, children: [
        for (final s in d.sections) pw.SizedBox(width: 235, child: table(s))
      ]),
      pw.NewPage(),
      pw.Text('Listado de asistentes',
          style: pw.TextStyle(font: bold, fontSize: 16, color: blue)),
      pw.SizedBox(height: 6),
      if (d.rows.isEmpty)
        pw.Text('Todavía no hay asistentes.',
            style: pw.TextStyle(fontSize: 11, color: grey))
      else
        pw.TableHelper.fromTextArray(
          headers: [
            'Nº',
            'Nombre',
            'Sexo',
            'Edad',
            'Iglesia',
            'Equipo',
            'Hospedaje',
            if (d.includePhone) 'Teléfono'
          ],
          data: [
            for (final r in d.rows)
              [
                '${r.regNumber}',
                r.name,
                r.sex == 'Hombre' ? 'H' : 'M',
                '${r.age}',
                r.church,
                r.team,
                r.lodging,
                if (d.includePhone) r.phone ?? ''
              ]
          ],
          headerStyle:
              pw.TextStyle(font: bold, fontSize: 9, color: PdfColors.white),
          headerDecoration: pw.BoxDecoration(color: blue),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellPadding:
              const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          border: pw.TableBorder.all(
              color: PdfColor.fromHex('#B8C0CC'), width: 0.4),
          oddRowDecoration:
              pw.BoxDecoration(color: PdfColor.fromHex('#F5F7FA')),
          columnWidths: {
            0: const pw.FixedColumnWidth(26),
            1: const pw.FlexColumnWidth(3),
            2: const pw.FixedColumnWidth(28),
            3: const pw.FixedColumnWidth(28),
            4: const pw.FlexColumnWidth(2.2),
            5: const pw.FlexColumnWidth(1.2),
            6: const pw.FlexColumnWidth(2)
          },
        ),
    ],
  ));
  return doc.save();
}
