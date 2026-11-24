import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Una hoja: nombre y filas. Las celdas son texto o número; la PRIMERA fila se muestra como encabezado.
class XlsxSheet {
  const XlsxSheet(this.name, this.rows);
  final String name;
  final List<List<Object?>> rows;
}

String _esc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    // caracteres de control no permitidos en XML 1.0
    .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');

String _col(int i) {
  var n = i + 1;
  var s = '';
  while (n > 0) {
    final r = (n - 1) % 26;
    s = String.fromCharCode(65 + r) + s;
    n = (n - 1) ~/ 26;
  }
  return s;
}

/// Nombre de hoja válido en Excel: sin `[]:*?/\`, máx. 31 caracteres, no vacío ni repetido.
String sheetName(String raw, Set<String> used) {
  var n = raw.replaceAll(RegExp(r'[\[\]:*?/\\]'), ' ').trim();
  if (n.isEmpty) n = 'Hoja';
  if (n.length > 31) n = n.substring(0, 31).trim();
  var candidate = n, i = 2;
  while (used.contains(candidate.toLowerCase())) {
    final suffix = ' ($i)';
    candidate = (n.length + suffix.length > 31
            ? n.substring(0, 31 - suffix.length)
            : n) +
        suffix;
    i++;
  }
  used.add(candidate.toLowerCase());
  return candidate;
}

/// Genera un archivo .xlsx (Office Open XML) mínimo y válido, sin dependencias de Excel.
/// Texto como cadenas en línea, números como números, encabezado en negrita con fondo,
/// primera fila fija y ancho de columna según el contenido.
Uint8List buildXlsx(List<XlsxSheet> sheets) {
  if (sheets.isEmpty) throw ArgumentError('Se necesita al menos una hoja.');
  final used = <String>{};
  final names = [for (final s in sheets) sheetName(s.name, used)];
  final a = Archive();
  void add(String path, String content) {
    final bytes = utf8.encode(content);
    a.addFile(ArchiveFile(path, bytes.length, bytes));
  }

  const header = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n';
  add(
      '[Content_Types].xml',
      '$header<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
          '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
          '<Default Extension="xml" ContentType="application/xml"/>'
          '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
          '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
          '${[
        for (var i = 0; i < sheets.length; i++)
          '<Override PartName="/xl/worksheets/sheet${i + 1}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
      ].join()}'
          '</Types>');
  add(
      '_rels/.rels',
      '$header<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
          '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
          '</Relationships>');
  add(
      'xl/workbook.xml',
      '$header<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
          '<sheets>${[
        for (var i = 0; i < sheets.length; i++)
          '<sheet name="${_esc(names[i])}" sheetId="${i + 1}" r:id="rId${i + 1}"/>'
      ].join()}</sheets>'
          '</workbook>');
  add(
      'xl/_rels/workbook.xml.rels',
      '$header<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
          '${[
        for (var i = 0; i < sheets.length; i++)
          '<Relationship Id="rId${i + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet${i + 1}.xml"/>'
      ].join()}'
          '<Relationship Id="rId${sheets.length + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
          '</Relationships>');
  add(
      'xl/styles.xml',
      '$header<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
          '<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font><font><b/><sz val="11"/><color rgb="FFFFFFFF"/><name val="Calibri"/></font></fonts>'
          '<fills count="3"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill>'
          '<fill><patternFill patternType="solid"><fgColor rgb="FF1D4E89"/><bgColor indexed="64"/></patternFill></fill></fills>'
          '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>'
          '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
          '<cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
          '<xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1"/></cellXfs>'
          '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>'
          '</styleSheet>');

  for (var si = 0; si < sheets.length; si++) {
    final rows = sheets[si].rows;
    final widths = <int, int>{};
    final sb = StringBuffer(
        '$header<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">');
    for (final r in rows) {
      for (var c = 0; c < r.length; c++) {
        final len = (r[c]?.toString() ?? '').length;
        if (len > (widths[c] ?? 0)) widths[c] = len;
      }
    }
    if (rows.isNotEmpty) {
      sb.write(
          '<sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews>');
    }
    if (widths.isNotEmpty) {
      sb.write('<cols>');
      for (final e in widths.entries) {
        final w = (e.value + 2).clamp(8, 60);
        sb.write(
            '<col min="${e.key + 1}" max="${e.key + 1}" width="$w" customWidth="1"/>');
      }
      sb.write('</cols>');
    }
    sb.write('<sheetData>');
    for (var r = 0; r < rows.length; r++) {
      sb.write('<row r="${r + 1}">');
      for (var c = 0; c < rows[r].length; c++) {
        final v = rows[r][c];
        if (v == null || (v is String && v.isEmpty)) continue;
        final ref = '${_col(c)}${r + 1}';
        final style = r == 0 ? ' s="1"' : '';
        if (v is num && v.isFinite) {
          sb.write('<c r="$ref"$style><v>$v</v></c>');
        } else {
          sb.write(
              '<c r="$ref"$style t="inlineStr"><is><t xml:space="preserve">${_esc(v.toString())}</t></is></c>');
        }
      }
      sb.write('</row>');
    }
    sb.write('</sheetData></worksheet>');
    add('xl/worksheets/sheet${si + 1}.xml', sb.toString());
  }
  return Uint8List.fromList(ZipEncoder().encode(a));
}
