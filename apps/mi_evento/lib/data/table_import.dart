import 'package:mi_evento_core/mi_evento_core.dart' show restoreFormula;

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

  /// Decisiones que el usuario puede cambiar antes de importar (puede no haber ninguna).
  final List<ImportDecision> decisions = [];
}

/// Algo que el importador no debe decidir solo: se muestra en la revisión con varias opciones
/// (la primera es la propuesta) y la elegida llega a `apply` en `choices[id]`.
class ImportDecision {
  ImportDecision(
      {required this.id, required this.message, required this.options})
      : assert(options.length > 1);
  final String id;
  final String message;
  final List<String> options;

  /// Opción elegida (índice en [options]); 0 = la propuesta.
  int selected = 0;
}

/// Una importación de CSV para una vista: primero se REVISA (sin escribir) y luego se APLICA.
abstract class TableImporter {
  String get title;

  /// Columnas que entiende (para la ayuda del diálogo).
  String get help;

  /// Columnas del CSV (ayuda y plantilla vacía). `null` si la vista no la ofrece.
  CsvSpec? get spec => null;
  Future<TableImportSummary> preview(String csvText);
  Future<TableImportSummary> apply(String csvText,
      {Map<String, int> choices = const {}});
}

/// Lee una tabla CSV con encabezados: devuelve filas como mapas {encabezado normalizado → valor}
/// (con el número de línea). Deshace el apóstrofo con que la exportación neutraliza las fórmulas. Los sinónimos se resuelven con [aliases] (canónico → alternativas).
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
            header[j]:
                j < table[i].length ? restoreFormula(table[i][j].trim()) : ''
        }
      )
  ];
}
