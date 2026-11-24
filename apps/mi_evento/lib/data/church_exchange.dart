import 'package:mi_evento_core/mi_evento_core.dart';

import 'database.dart';
import 'repository.dart';
import 'table_import.dart';

/// Exportar e importar el catálogo de iglesias en CSV (nombre, provincia, municipio, comunidad).
class ChurchExchange implements TableImporter {
  ChurchExchange(this.db);
  final AppDatabase db;

  static const headers = ['nombre', 'provincia', 'municipio', 'comunidad'];

  static String? _province(String raw) {
    final n = normalizeText(raw);
    for (final p in cubaProvinces) {
      if (normalizeText(p) == n) return p;
    }
    return null;
  }

  @override
  String get title => 'Importar iglesias';
  @override
  String get help =>
      'Columnas: nombre, provincia, municipio y comunidad (opcional). Si la iglesia ya existe '
      '(mismo nombre, provincia y municipio) solo se actualiza su comunidad.';

  static List<List<String>> toRows(Iterable<ChurchRow> churches) => [
        headers,
        for (final c in churches)
          [c.name, c.province, c.municipality, c.community],
      ];

  Future<TableImportSummary> _run(String csvText, {required bool write}) async {
    final repo = Repository(db);
    final rows = readCsvTable(
        parseCsv(csvText),
        const {
          'nombre': ['iglesia', 'name'],
          'provincia': [],
          'municipio': [],
          'comunidad': ['barrio'],
        },
        normalizeText);
    final out = TableImportSummary();
    if (rows.isEmpty) {
      out.warnings.add('El archivo está vacío o no tiene filas.');
      return out;
    }
    if (!rows.first.$2.containsKey('nombre') ||
        !rows.first.$2.containsKey('provincia')) {
      out.warnings.add(
          'Faltan columnas: el archivo debe tener al menos «nombre» y «provincia».');
      return out;
    }
    final existing = await (db.select(db.churches)
          ..where((c) => c.deletedAt.isNull()))
        .get();
    String key(String name, String prov, String muni) =>
        '${normalizeText(name)}|${normalizeText(prov)}|${normalizeText(muni)}';
    final byKey = {
      for (final c in existing) key(c.name, c.province, c.municipality): c
    };
    final seen = <String>{};
    var created = 0, updated = 0, same = 0;
    for (final (line, r) in rows) {
      final name = r['nombre'] ?? '';
      final prov = _province(r['provincia'] ?? '');
      final muni = normalizeMunicipality(r['municipio'] ?? '');
      final comm = normalizeCommunity(r['comunidad'] ?? '');
      if (name.isEmpty) {
        out.warnings.add('Fila $line: falta el nombre de la iglesia.');
        continue;
      }
      if (prov == null) {
        out.warnings.add(
            'Fila $line: la provincia «${r['provincia'] ?? ''}» no es una provincia de Cuba.');
        continue;
      }
      if (muni.isEmpty) {
        out.warnings.add('Fila $line: falta el municipio.');
        continue;
      }
      final k = key(name, prov, muni);
      if (!seen.add(k)) {
        out.warnings.add('Fila $line: «$name» está repetida en el archivo.');
        continue;
      }
      final cur = byKey[k];
      if (cur == null) {
        created++;
        if (write) {
          await repo.createChurch(
              name: name,
              province: prov,
              municipality: muni,
              community: comm,
              requireLocation: true);
        }
      } else if (comm.isNotEmpty && normalizeCommunity(cur.community) != comm) {
        updated++;
        if (write) {
          await repo.updateChurch(cur.id,
              name: cur.name,
              province: cur.province,
              municipality: cur.municipality,
              community: comm);
        }
      } else {
        same++;
      }
    }
    out.work = created + updated;
    out.lines
      ..add('Iglesias nuevas: $created')
      ..add('Iglesias actualizadas (comunidad): $updated');
    if (same > 0) out.lines.add('Sin cambios: $same');
    return out;
  }

  @override
  Future<TableImportSummary> preview(String csvText) =>
      _run(csvText, write: false);
  @override
  Future<TableImportSummary> apply(String csvText) async =>
      db.transaction(() => _run(csvText, write: true));
}
