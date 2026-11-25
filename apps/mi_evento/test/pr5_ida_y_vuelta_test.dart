// Fase 4 · Ida y vuelta sin pérdida y compatibilidad con Excel: lo que la app exporta, guardado
// como lo guardaría Excel (UTF-8 con o sin BOM, ANSI, coma, tabulador, «Texto Unicode»), se vuelve
// a importar en una base nueva y da exactamente lo mismo.
import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_evento/data/church_exchange.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/lodging_exchange.dart';
import 'package:mi_evento/data/repos_b.dart';
import 'package:mi_evento/data/repository.dart';
import 'package:mi_evento/data/table_import.dart';
import 'package:mi_evento/data/team_definition_exchange.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

/// Texto difícil, todo representable en Windows-1252 (para poder guardarlo también en ANSI).
const _dificil = [
  'Iglesia «Ñandú» Álvarez, S.A.; sede 2',
  'Güell & Ibáñez – “Los Leones” (5€) …',
  'Con "comillas" y ¿signos? ¡sí!',
  'Línea 1\nLínea 2',
  "O'Farrill y Núñez",
  '=SUMA(A1:A2)',
  '+53 5 123 4567',
  '@usuario',
  '-guion',
  '  espacios  ',
];

/// Codifica en Windows-1252 (lo inverso de `decodeWindows1252`).
List<int> _cp1252(String s) {
  const high = {
    0x20AC: 0x80, 0x201A: 0x82, 0x0192: 0x83, 0x201E: 0x84, 0x2026: 0x85, //
    0x2020: 0x86, 0x2021: 0x87, 0x02C6: 0x88, 0x2030: 0x89, 0x0160: 0x8A,
    0x2039: 0x8B, 0x0152: 0x8C, 0x017D: 0x8E, 0x2018: 0x91, 0x2019: 0x92,
    0x201C: 0x93, 0x201D: 0x94, 0x2022: 0x95, 0x2013: 0x96, 0x2014: 0x97,
    0x02DC: 0x98, 0x2122: 0x99, 0x0161: 0x9A, 0x203A: 0x9B, 0x0153: 0x9C,
    0x017E: 0x9E, 0x0178: 0x9F,
  };
  return [
    for (final u in s.runes)
      if (high.containsKey(u))
        high[u]!
      else if (u < 256)
        u
      else
        throw StateError('«${String.fromCharCode(u)}» no cabe en ANSI')
  ];
}

/// Las formas en que Excel (u otro programa) puede devolvernos el archivo.
final _variantes = <String, Uint8List Function(List<List<String>>)>{
  'UTF-8 con BOM y «sep=;» (lo que exporta la app)': (r) =>
      Uint8List.fromList(utf8.encode(buildCsvDelimited(r))),
  'UTF-8 sin BOM ni «sep=»': (r) => Uint8List.fromList(
      utf8.encode(buildCsvDelimited(r, excelHint: false).substring(1))),
  'ANSI (Windows-1252) con «;» · «CSV» de Excel en español': (r) =>
      Uint8List.fromList(
          _cp1252(buildCsvDelimited(r, excelHint: false).substring(1))),
  'UTF-8 con coma': (r) => Uint8List.fromList(
      utf8.encode(buildCsvDelimited(r, delimiter: ',', excelHint: false))),
  'ANSI con coma': (r) => Uint8List.fromList(_cp1252(
      buildCsvDelimited(r, delimiter: ',', excelHint: false).substring(1))),
  'UTF-8 con tabulador': (r) => Uint8List.fromList(
      utf8.encode(buildCsvDelimited(r, delimiter: '\t', excelHint: false))),
  'UTF-16 con tabulador · «Texto Unicode» de Excel': (r) {
    final t =
        buildCsvDelimited(r, delimiter: '\t', excelHint: false).substring(1);
    return Uint8List.fromList([
      0xFF,
      0xFE,
      for (final u in t.codeUnits) ...[u & 0xFF, u >> 8]
    ]);
  },
};

void main() {
  late AppDatabase src, dst;
  late String evSrc, evDst;
  setUp(() async {
    src = AppDatabase(NativeDatabase.memory());
    dst = AppDatabase(NativeDatabase.memory());
    evSrc = await Repository(src).createEvent(
        name: 'Origen', startDate: '2026-01-01', endDate: '2026-01-02');
    evDst = await Repository(dst).createEvent(
        name: 'Destino', startDate: '2027-01-01', endDate: '2027-01-02');
  });
  tearDown(() async {
    await src.close();
    await dst.close();
  });

  Future<List<List<String>>> churchRows(AppDatabase db) async {
    final all = await (db.select(db.churches)
          ..where((c) => c.deletedAt.isNull()))
        .get();
    final rows = ChurchExchange.toRows(all);
    return [rows.first, ...rows.skip(1).toList()..sort(_byFirst)];
  }

  Future<void> importar(
      TableImporter imp, Uint8List bytes, String variante) async {
    final text = decodeCsvBytes(bytes);
    final prev = await imp.preview(text);
    expect(prev.warnings, isEmpty, reason: variante);
    expect(prev.work, greaterThan(0), reason: variante);
    await imp.apply(text);
  }

  group('iglesias', () {
    for (final v in _variantes.entries) {
      test(v.key, () async {
        final repo = Repository(src);
        for (var i = 0; i < _dificil.length; i++) {
          await repo.createChurch(
              name: 'Bautista ${_dificil[i]}',
              province: 'Matanzas',
              municipality: 'Cárdenas',
              community: _dificil[(i + 3) % _dificil.length]);
        }
        final origen = await churchRows(src);
        await importar(ChurchExchange(dst), v.value(origen), v.key);
        expect(await churchRows(dst), origen, reason: v.key);
      });
    }
  });

  group('hospedajes', () {
    for (final v in _variantes.entries) {
      test(v.key, () async {
        final lr = LodgingRepo(src);
        for (var i = 0; i < _dificil.length; i++) {
          await lr.save(
              eventId: evSrc,
              name: 'Hospedaje ${i + 1} ${_dificil[i]}',
              kind: i.isEven ? 'shelter' : 'private_home',
              capacity: 1 + i,
              accepts: LodgingAccepts.values[i % LodgingAccepts.values.length],
              hostName: i.isEven ? null : _dificil[(i + 1) % _dificil.length],
              contactPhone: '+53 5 123 45$i$i',
              directions: _dificil[(i + 2) % _dificil.length],
              distanceNote: _dificil[(i + 4) % _dificil.length]);
        }
        final origen = await LodgingExchange(src, evSrc).export();
        await importar(LodgingExchange(dst, evDst), v.value(origen), v.key);
        expect(await LodgingExchange(dst, evDst).export(), origen,
            reason: v.key);
      });
    }
  });

  group('equipos (definición)', () {
    for (final v in _variantes.entries) {
      test(v.key, () async {
        final tr = TeamRepo(src);
        for (var i = 0; i < _dificil.length; i++) {
          await tr.create(evSrc,
              name: 'Equipo ${_dificil[i]}',
              color: i.isEven
                  ? teamPalette[i % teamPalette.length].$2
                  : '#12AB34');
        }
        final origen = await TeamDefinitionExchange(src, evSrc).export();
        await importar(
            TeamDefinitionExchange(dst, evDst), v.value(origen), v.key);
        expect(await TeamDefinitionExchange(dst, evDst).export(), origen,
            reason: v.key);
      });
    }
  });

  test(
      'un archivo de Excel con filas vacías al final y espacios sobrantes se importa igual',
      () async {
    final text = '\u{FEFF}sep=;\r\nnombre;provincia;municipio;comunidad\r\n'
        '  Bautista Centro  ;Matanzas;Cárdenas; \r\n;;;\r\n;;;\r\n';
    final imp = ChurchExchange(dst);
    final prev = await imp.preview(text);
    expect(prev.warnings, isEmpty);
    expect(prev.work, 1);
    await imp.apply(text);
    final rows = await churchRows(dst);
    expect(rows[1], ['Bautista Centro', 'Matanzas', 'Cárdenas', '']);
  });
}

int _byFirst(List<String> a, List<String> b) => a.first.compareTo(b.first);
