import 'csv_spec.dart';

/// Resultado de revisar (o aplicar) la importación de una tabla CSV.
class TableImportSummary {
  TableImportSummary(
      {List<String>? lines, List<String>? warnings, this.work = 0})
      : lines = lines ?? [],
        warnings = warnings ?? [];

  /// Resumen en frases cortas («Nuevas: 3», «Actualizadas: 1»…).
  final List<String> lines;

  /// Avisos por fila («Fila 7: …»); esas filas no se aplican.
  final List<String> warnings;

  /// Cuántas filas se aplicarán (0 = no hay nada que importar).
  int work;
}

/// Una importación de CSV para una vista: primero se REVISA (sin escribir) y luego se APLICA.
abstract class TableImporter {
  String get title;

  /// Columnas que entiende (para la ayuda del diálogo).
  String get help;

  /// Columnas del CSV (ayuda y plantilla vacía). `null` si la vista no la ofrece.
  CsvSpec? get spec => null;
  Future<TableImportSummary> preview(String csvText);
  Future<TableImportSummary> apply(String csvText);
}

/// Lee una tabla CSV con encabezados: devuelve filas como mapas {encabezado normalizado → valor}
/// (con el número de línea). Los sinónimos se resuelven con [aliases] (canónico → alternativas).
List<(int, Map<String, String>)> readCsvTable(List<List<String>> table,
    Map<String, List<String>> aliases, String Function(String) norm) {
  if (table.isEmpty) return const [];
  final canon = <String, String>{};
  aliases.forEach((k, alts) {
    canon[norm(k)] = k;
    for (final a in alts) {
      canon[norm(a)] = k;
    }
  });
  final header = [for (final h in table.first) canon[norm(h)] ?? norm(h)];
  return [
    for (var i = 1; i < table.length; i++)
      (
        i + 1,
        {
          for (var j = 0; j < header.length; j++)
            header[j]: j < table[i].length ? table[i][j].trim() : ''
        }
      )
  ];
}
