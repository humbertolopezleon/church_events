import 'package:mi_evento_core/mi_evento_core.dart';

import 'database.dart';
import 'repository.dart';
import 'table_import.dart';

/// Exportar e importar la lista de eventos (Mis eventos) en CSV. Solo los datos del evento; las
/// personas, hospedajes y equipos se importan dentro de cada evento.
class EventExchange implements TableImporter {
  EventExchange(this.db);
  final AppDatabase db;

  static const headers = [
    'nombre',
    'inicio',
    'fin',
    'lugar',
    'organizador',
    'hospedaje',
    'equipos'
  ];

  @override
  String get title => 'Importar eventos';
  @override
  String get help =>
      'Columnas: nombre, inicio y fin (AAAA-MM-DD), lugar, organizador, hospedaje y equipos (Sí/No). '
      'Un evento con el mismo nombre y fechas que otro ya existente se omite.';

  static bool? _yesNo(String raw) {
    final n = normalizeText(raw);
    if (n.isEmpty) return true;
    if (n == 'si' || n == 's' || n == 'true' || n == '1') return true;
    if (n == 'no' || n == 'n' || n == 'false' || n == '0') return false;
    return null;
  }

  static final _date = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  Future<TableImportSummary> _run(String csvText, {required bool write}) async {
    final repo = Repository(db);
    final rows = readCsvTable(
        parseCsv(csvText),
        const {
          'nombre': ['evento'],
          'inicio': ['desde'],
          'fin': ['hasta'],
          'lugar': [],
          'organizador': [],
          'hospedaje': [],
          'equipos': [],
        },
        normalizeText);
    final out = TableImportSummary();
    if (rows.isEmpty) {
      out.warnings.add('El archivo está vacío o no tiene filas.');
      return out;
    }
    for (final col in ['nombre', 'inicio', 'fin']) {
      if (!rows.first.$2.containsKey(col)) {
        out.warnings.add('Faltan columnas: el archivo debe tener «$col».');
        return out;
      }
    }
    final existing =
        await (db.select(db.events)..where((e) => e.deletedAt.isNull())).get();
    String key(String n, String a, String b) => '${normalizeText(n)}|$a|$b';
    final have = {
      for (final e in existing) key(e.name, e.startDate, e.endDate)
    };
    var created = 0, skipped = 0;
    for (final (line, r) in rows) {
      final name = r['nombre'] ?? '';
      final a = r['inicio'] ?? '', b = r['fin'] ?? '';
      final lodging = _yesNo(r['hospedaje'] ?? '');
      final teams = _yesNo(r['equipos'] ?? '');
      if (name.isEmpty) {
        out.warnings.add('Fila $line: falta el nombre del evento.');
        continue;
      }
      if (!_date.hasMatch(a) || !_date.hasMatch(b)) {
        out.warnings.add(
            'Fila $line: las fechas de «$name» deben ser AAAA-MM-DD (inicio «$a», fin «$b»).');
        continue;
      }
      if (b.compareTo(a) < 0) {
        out.warnings
            .add('Fila $line: el fin de «$name» es anterior a su inicio.');
        continue;
      }
      if (lodging == null || teams == null) {
        out.warnings.add('Fila $line: hospedaje y equipos deben ser Sí o No.');
        continue;
      }
      if (!have.add(key(name, a, b))) {
        skipped++;
        continue;
      }
      created++;
      if (write) {
        await repo.createEvent(
            name: name,
            startDate: a,
            endDate: b,
            venue: r['lugar'] ?? '',
            organizer: r['organizador'] ?? '',
            offersLodging: lodging,
            offersTeams: teams);
      }
    }
    out.work = created;
    out.lines.add('Eventos nuevos: $created');
    if (skipped > 0) out.lines.add('Omitidos (ya existen): $skipped');
    return out;
  }

  @override
  Future<TableImportSummary> preview(String csvText) =>
      _run(csvText, write: false);
  @override
  Future<TableImportSummary> apply(String csvText) async =>
      db.transaction(() => _run(csvText, write: true));
}
