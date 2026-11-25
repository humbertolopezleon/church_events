import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/csv_spec.dart';
import '../export/csv_export.dart';
import '../theme/app_theme.dart';

/// Guarda la plantilla vacía (solo los encabezados) del CSV de una vista.
Future<void> saveCsvTemplate(
        BuildContext context, WidgetRef ref, CsvSpec spec) =>
    saveCsv(context, ref, name: spec.fileName, rows: spec.templateRows);

/// Diálogo «Columnas del CSV»: obligatorias, opcionales y botón para guardar la plantilla vacía.
/// Es el mismo para Asistentes, Iglesias, Hospedajes y Equipos.
Future<void> showCsvSpecDialog(
    BuildContext context, WidgetRef ref, CsvSpec spec,
    {Key dialogKey = const Key('csv-columnas'),
    Key templateKey = const Key('csv-columnas-plantilla')}) {
  Widget list(Iterable<CsvColumn> cols) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final c in cols) Text('• ${c.name}: ${c.description}')]);
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      key: dialogKey,
      title: Text(spec.title),
      content: SingleChildScrollView(
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Obligatorias',
                  style: bodyStyle(16, weight: FontWeight.w700)),
              list(spec.requiredColumns),
              if (spec.optionalColumns.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Opcionales',
                    style: bodyStyle(16, weight: FontWeight.w700)),
                list(spec.optionalColumns),
              ],
              if (spec.note != null) ...[
                const SizedBox(height: 12),
                Text(spec.note!, style: bodyStyle(15, color: Brand.gris)),
              ],
            ]),
      ),
      actions: [
        TextButton(
            key: templateKey,
            onPressed: () => saveCsvTemplate(ctx, ref, spec),
            child: const Text('Guardar plantilla vacía')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido')),
      ],
    ),
  );
}

/// Botones del estado vacío: «Descargar plantilla» y «Ver columnas».
class CsvHelpButtons extends ConsumerWidget {
  const CsvHelpButtons({super.key, required this.spec, required this.prefix});
  final CsvSpec spec;

  /// Prefijo de las claves de prueba (p. ej. `hosp` → `hosp-vacio-plantilla`, `hosp-vacio-columnas`).
  final String prefix;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      Wrap(spacing: 8, children: [
        TextButton.icon(
            key: Key('$prefix-vacio-plantilla'),
            onPressed: () => saveCsvTemplate(context, ref, spec),
            icon: const Icon(Icons.download_outlined),
            label: const Text('Descargar plantilla')),
        TextButton.icon(
            key: Key('$prefix-vacio-columnas'),
            onPressed: () => showCsvSpecDialog(context, ref, spec),
            icon: const Icon(Icons.help_outline),
            label: const Text('Ver columnas')),
      ]);
}
