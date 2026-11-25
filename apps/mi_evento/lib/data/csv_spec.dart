/// Una columna de un CSV importable: nombre exacto del encabezado y para qué sirve.
class CsvColumn {
  const CsvColumn(this.name, this.description, {this.required = false});
  final String name;
  final String description;
  final bool required;
}

/// Qué columnas tiene (y espera) el CSV de una vista. De aquí salen la ayuda «Columnas del CSV»
/// y la plantilla vacía, para que ambas coincidan siempre con lo que exporta e importa la app.
class CsvSpec {
  const CsvSpec(
      {required this.title,
      required this.fileName,
      required this.columns,
      this.note});

  /// Título del diálogo de ayuda (p. ej. «Columnas del CSV de hospedajes»).
  final String title;

  /// Nombre del archivo de la plantilla vacía (p. ej. `plantilla-hospedajes.csv`).
  final String fileName;
  final List<CsvColumn> columns;
  final String? note;

  List<String> get headers => [for (final c in columns) c.name];
  Iterable<CsvColumn> get requiredColumns => columns.where((c) => c.required);
  Iterable<CsvColumn> get optionalColumns => columns.where((c) => !c.required);

  /// Plantilla vacía: solo la fila de títulos.
  List<List<String>> get templateRows => [headers];
}

const csvSeparatorNote =
    'Separador «;» (o coma), con encabezados en la primera fila. Excel lo guarda bien.';
