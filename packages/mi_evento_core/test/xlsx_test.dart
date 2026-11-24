import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:mi_evento_core/mi_evento_core.dart';
import 'package:test/test.dart';

String entry(Archive a, String path) =>
    utf8.decode(a.findFile(path)!.content as List<int>);

void main() {
  final bytes = buildXlsx([
    const XlsxSheet('Resumen', [
      ['Concepto', 'Valor'],
      ['Inscritos', 248],
      ['Porcentaje', 93.5],
      ['Nota', 'Pérez & "Hijos" <ok>'],
    ]),
    const XlsxSheet('Pasaron', [
      ['Nº', 'Nombre'],
      [1, 'Juan Pérez'],
    ]),
  ]);

  test('es un ZIP con las partes obligatorias de un .xlsx', () {
    final a = ZipDecoder().decodeBytes(bytes);
    for (final p in [
      '[Content_Types].xml',
      '_rels/.rels',
      'xl/workbook.xml',
      'xl/_rels/workbook.xml.rels',
      'xl/styles.xml',
      'xl/worksheets/sheet1.xml',
      'xl/worksheets/sheet2.xml'
    ]) {
      expect(a.findFile(p), isNotNull, reason: p);
    }
  });

  test('números como números y texto escapado (& < > ")', () {
    final a = ZipDecoder().decodeBytes(bytes);
    final s1 = entry(a, 'xl/worksheets/sheet1.xml');
    expect(s1, contains('<v>248</v>'));
    expect(s1, contains('<v>93.5</v>'));
    expect(s1, contains('Pérez &amp; &quot;Hijos&quot; &lt;ok&gt;'));
    expect(s1, contains('Concepto'));
  });

  test('encabezado con estilo, primera fila fija y anchos', () {
    final s1 =
        entry(ZipDecoder().decodeBytes(bytes), 'xl/worksheets/sheet1.xml');
    expect(s1, contains('<c r="A1" s="1" t="inlineStr">'));
    expect(s1, contains('state="frozen"'));
    expect(s1, contains('<cols>'));
  });

  test('nombres de hoja válidos: caracteres prohibidos, 31 máx. y repetidos',
      () {
    final used = <String>{};
    expect(
        sheetName('Pasaron/No pasaron: [x]', used), 'Pasaron No pasaron   x');
    expect(sheetName('A' * 40, used).length, 31);
    expect(sheetName('resumen', used), 'resumen');
    expect(
        sheetName('Resumen', used), 'Resumen (2)'); // sin distinguir mayúsculas
    expect(sheetName('  ', used), 'Hoja');
  });

  test('columnas más allá de la Z (AA, AB…) y celdas vacías', () {
    final b = buildXlsx([
      XlsxSheet(
          'x', [List<Object?>.generate(28, (i) => i == 27 ? 'fin' : null)])
    ]);
    final s = entry(ZipDecoder().decodeBytes(b), 'xl/worksheets/sheet1.xml');
    expect(s, contains('r="AB1"'));
    expect(s, isNot(contains('r="A1"'))); // las celdas vacías no se escriben
  });

  test('caracteres de control no rompen el XML; sin hojas es un error', () {
    final b = buildXlsx([
      const XlsxSheet('x', [
        ['a\u0001b']
      ])
    ]);
    expect(entry(ZipDecoder().decodeBytes(b), 'xl/worksheets/sheet1.xml'),
        contains('>ab<'));
    expect(() => buildXlsx(const []), throwsArgumentError);
  });

  test('hoja grande (1500 filas × 8 columnas) se genera rápido', () {
    final rows = [
      for (var i = 0; i < 1500; i++)
        [for (var j = 0; j < 8; j++) j == 0 ? i : 'dato $i-$j']
    ];
    final sw = Stopwatch()..start();
    final b = buildXlsx([XlsxSheet('Datos', rows)]);
    expect(b.length, greaterThan(1000));
    expect(sw.elapsedMilliseconds, lessThan(3000));
  });
}
