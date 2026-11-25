import 'package:drift/drift.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'csv_spec.dart';
import 'database.dart';
import 'repos_b.dart';
import 'table_import.dart';

/// Exportar e importar los hospedajes de un evento en CSV. Las columnas son las del CSV que ya
/// exporta la vista (ocupadas y libres se ignoran al importar: se calculan).
class LodgingExchange implements TableImporter {
  LodgingExchange(this.db, this.eventId);
  final AppDatabase db;
  final String eventId;

  static const headers = [
    'nombre',
    'tipo',
    'acepta',
    'capacidad',
    'ocupadas',
    'libres',
    'anfitrion',
    'telefono',
    'indicaciones',
    'cercania'
  ];

  static const csvSpec = CsvSpec(
      title: 'Columnas del CSV de hospedajes',
      fileName: 'plantilla-hospedajes.csv',
      columns: [
        CsvColumn('nombre', 'nombre del hospedaje (si ya existe, se actualiza)',
            required: true),
        CsvColumn('tipo', 'Albergue o Casa particular'),
        CsvColumn('acepta',
            'Solo hombres, Solo mujeres, Matrimonios o Sin preferencia'),
        CsvColumn('capacidad', 'número de plazas (al menos 1)', required: true),
        CsvColumn(
            'ocupadas', 'solo informativa: se calcula, se ignora al importar'),
        CsvColumn(
            'libres', 'solo informativa: se calcula, se ignora al importar'),
        CsvColumn('anfitrion', 'nombre del anfitrión'),
        CsvColumn('telefono', 'teléfono de contacto'),
        CsvColumn('indicaciones', 'cómo llegar'),
        CsvColumn('cercania', 'distancia o zona'),
      ],
      note: csvSeparatorNote);

  @override
  CsvSpec get spec => csvSpec;

  @override
  String get title => 'Importar hospedajes';
  @override
  String get help =>
      'Columnas: nombre, tipo (Albergue o Casa particular), acepta (Solo hombres, Solo mujeres, '
      'Matrimonios o Sin preferencia), capacidad, anfitrion, telefono, indicaciones y cercania. '
      'Si el hospedaje ya existe (mismo nombre) se actualiza.';

  static String kindLabel(String kind) =>
      kind == 'shelter' ? 'Albergue' : 'Casa particular';

  static LodgingAccepts? _accepts(String raw) {
    final n = normalizeText(raw);
    if (n.isEmpty) return LodgingAccepts.any;
    for (final a in LodgingAccepts.values) {
      if (normalizeText(lodgingAcceptsLabel(a)) == n || a.name == n) return a;
    }
    return null;
  }

  Future<TableImportSummary> _run(String csvText, {required bool write}) async {
    final repo = LodgingRepo(db);
    final rows = readCsvTable(
        parseCsv(csvText),
        const {
          'nombre': ['hospedaje', 'name'],
          'tipo': [],
          'acepta': [],
          'capacidad': ['plazas'],
          'anfitrion': ['anfitrión'],
          'telefono': ['teléfono', 'contacto'],
          'indicaciones': ['direccion', 'dirección'],
          'cercania': ['cercanía'],
        },
        normalizeText);
    final out = TableImportSummary();
    if (rows.isEmpty) {
      out.warnings.add('El archivo está vacío o no tiene filas.');
      return out;
    }
    if (!rows.first.$2.containsKey('nombre') ||
        !rows.first.$2.containsKey('capacidad')) {
      out.warnings.add(
          'Faltan columnas: el archivo debe tener al menos «nombre» y «capacidad».');
      return out;
    }
    final existing = await (db.select(db.lodgings)
          ..where((l) => l.eventId.equals(eventId) & l.deletedAt.isNull()))
        .get();
    final byName = {for (final l in existing) normalizeText(l.name): l};
    final seen = <String>{};
    var created = 0, updated = 0;
    final touched = <String>[];
    for (final (line, r) in rows) {
      final name = r['nombre'] ?? '';
      final cap = int.tryParse(r['capacidad'] ?? '');
      final accepts = _accepts(r['acepta'] ?? '');
      final kindRaw = normalizeText(r['tipo'] ?? '');
      if (name.isEmpty) {
        out.warnings.add('Fila $line: falta el nombre del hospedaje.');
        continue;
      }
      if (cap == null || cap < 1 || cap > 500) {
        out.warnings.add(
            'Fila $line: la capacidad de «$name» debe ser un número entre 1 y 500.');
        continue;
      }
      if (accepts == null) {
        out.warnings.add(
            'Fila $line: «${r['acepta']}» no es un valor de «acepta» (Solo hombres, Solo mujeres, Matrimonios o Sin preferencia).');
        continue;
      }
      if (kindRaw.isNotEmpty &&
          kindRaw != 'albergue' &&
          kindRaw != 'casa particular') {
        out.warnings.add(
            'Fila $line: el tipo «${r['tipo']}» debe ser Albergue o Casa particular.');
        continue;
      }
      if (!seen.add(normalizeText(name))) {
        out.warnings.add('Fila $line: «$name» está repetido en el archivo.');
        continue;
      }
      final cur = byName[normalizeText(name)];
      final kind = kindRaw.isEmpty
          ? (cur?.kind ?? 'shelter')
          : (kindRaw == 'albergue' ? 'shelter' : 'private_home');
      if (cur == null) {
        created++;
      } else {
        updated++;
      }
      if (write) {
        final l = await repo.save(
            id: cur?.id,
            eventId: eventId,
            name: name,
            kind: kind,
            capacity: cap,
            accepts: accepts,
            hostName: r['anfitrion'],
            contactPhone: r['telefono'],
            directions: r['indicaciones'] ?? '',
            distanceNote: r['cercania'] ?? '');
        touched.add(l.id);
      }
    }
    out.work = created + updated;
    out.lines
      ..add('Hospedajes nuevos: $created')
      ..add('Hospedajes actualizados: $updated');
    if (write) {
      var bad = 0;
      for (final id in touched) {
        bad += (await repo.incompatibleOccupants(id)).length;
      }
      if (bad > 0) {
        out.lines.add(
            'Atención: $bad ${bad == 1 ? 'persona hospedada ya no encaja' : 'personas hospedadas ya no encajan'} con «acepta» (no se quitó a nadie; revísalas en la ficha de cada hospedaje).');
      }
    }
    return out;
  }

  @override
  Future<TableImportSummary> preview(String csvText) =>
      _run(csvText, write: false);
  @override
  Future<TableImportSummary> apply(String csvText) async =>
      db.transaction(() => _run(csvText, write: true));
}
