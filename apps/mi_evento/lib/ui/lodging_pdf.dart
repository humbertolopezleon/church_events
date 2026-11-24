import 'dart:typed_data';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:mi_evento_core/mi_evento_core.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/database.dart';

/// Hoja imprimible de un hospedaje para entregar al anfitrión.
/// El teléfono NO se incluye salvo que se pida (privacidad: el anfitrión no lo necesita).
Future<Uint8List> buildLodgingPdf({
  required String eventName,
  required String eventDates,
  required LodgingRow lodging,
  required List<AttendeeRow> occupants,
  required Map<String, String> churchNames,
  bool includePhone = false,
  AssetBundle? bundle,
  DateTime? now,
}) async {
  final b = bundle ?? rootBundle;
  final regular = pw.Font.ttf(
      await b.load('assets/fonts/AtkinsonHyperlegible-Regular.ttf'));
  final bold =
      pw.Font.ttf(await b.load('assets/fonts/AtkinsonHyperlegible-Bold.ttf'));
  final theme = pw.ThemeData.withFont(base: regular, bold: bold);
  final date = now ?? DateTime.now();
  final printed =
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  final sorted = [...occupants]..sort((a, c) {
      final k =
          normalizeText(a.lastName1).compareTo(normalizeText(c.lastName1));
      return k != 0
          ? k
          : normalizeText(a.firstName).compareTo(normalizeText(c.firstName));
    });

  final blue = PdfColor.fromHex('#1D4E89');
  final softBlue = PdfColor.fromHex('#E6EEF8');
  final grey = PdfColor.fromHex('#4A5565');

  String fullName(AttendeeRow a) => [a.firstName, a.lastName1, a.lastName2]
      .where((e) => e.isNotEmpty)
      .join(' ');

  final headers = [
    '#',
    'Nombre',
    'Sexo',
    'Edad',
    'Iglesia',
    if (includePhone) 'Teléfono',
    'Observaciones'
  ];
  final rows = [
    for (var i = 0; i < sorted.length; i++)
      [
        '${i + 1}',
        fullName(sorted[i]),
        sorted[i].sex == 'M' ? 'H' : 'M',
        '${sorted[i].age}',
        churchNames[sorted[i].churchId] ?? '',
        if (includePhone) sorted[i].phone ?? '',
        sorted[i].notes,
      ],
  ];

  final doc =
      pw.Document(title: 'Lista de ${lodging.name}', author: 'Mi Evento');
  doc.addPage(pw.MultiPage(
    maxPages: 2000, // sin el límite de 20 páginas (QA-BUG-009)
    pageTheme: pw.PageTheme(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36)),
    footer: (ctx) =>
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      pw.Text(
          'Lista de uso exclusivo del anfitrión. Por favor no la compartas ni la dejes a la vista.',
          style: pw.TextStyle(fontSize: 9, color: grey)),
      pw.Text('Página ${ctx.pageNumber} de ${ctx.pagesCount}',
          style: pw.TextStyle(fontSize: 9, color: grey)),
    ]),
    build: (ctx) => [
      pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(lodging.name,
                        style: pw.TextStyle(
                            font: bold, fontSize: 24, color: blue)),
                    pw.SizedBox(height: 2),
                    pw.Text('$eventName · $eventDates',
                        style: pw.TextStyle(fontSize: 12, color: grey)),
                  ]),
            ),
            pw.Text('Impreso: $printed',
                style: pw.TextStyle(fontSize: 10, color: grey)),
          ]),
      pw.SizedBox(height: 12),
      pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
            color: softBlue, borderRadius: pw.BorderRadius.circular(6)),
        child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                  '${lodging.kind == 'shelter' ? 'Albergue' : 'Casa particular'} · Capacidad: ${lodging.capacity} · '
                  'Ocupadas: ${sorted.length} · ${lodgingAcceptsLabel(lodgingAcceptsFromDb(lodging.accepts))}',
                  style: pw.TextStyle(font: bold, fontSize: 11)),
              if (lodging.directions.isNotEmpty)
                pw.Text('Cómo llegar: ${lodging.directions}',
                    style: const pw.TextStyle(fontSize: 11)),
              if (lodging.hostName != null)
                pw.Text('Anfitrión: ${lodging.hostName}',
                    style: const pw.TextStyle(fontSize: 11)),
              if (lodging.contactPhone != null)
                pw.Text('Contacto: ${lodging.contactPhone}',
                    style: const pw.TextStyle(fontSize: 11)),
            ]),
      ),
      pw.SizedBox(height: 14),
      if (rows.isEmpty)
        pw.Text('Nadie asignado todavía.',
            style: pw.TextStyle(fontSize: 13, color: grey))
      else
        pw.TableHelper.fromTextArray(
          headers: headers,
          data: rows,
          headerStyle:
              pw.TextStyle(font: bold, fontSize: 11, color: PdfColors.white),
          headerDecoration: pw.BoxDecoration(color: blue),
          cellStyle: const pw.TextStyle(fontSize: 11),
          cellPadding:
              const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
          border: pw.TableBorder.all(
              color: PdfColor.fromHex('#B8C0CC'), width: 0.5),
          oddRowDecoration:
              pw.BoxDecoration(color: PdfColor.fromHex('#F5F7FA')),
          columnWidths: {
            0: const pw.FixedColumnWidth(24),
            1: const pw.FlexColumnWidth(3),
            2: const pw.FixedColumnWidth(34),
            3: const pw.FixedColumnWidth(34),
            4: const pw.FlexColumnWidth(2.2),
          },
        ),
    ],
  ));
  return doc.save();
}
