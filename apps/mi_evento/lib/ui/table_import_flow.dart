import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento_core/mi_evento_core.dart' show decodeCsvBytes;

import '../data/table_import.dart';
import '../providers.dart';
import '../theme/app_theme.dart';

/// Importar un CSV a una vista: elegir archivo → revisar qué haría (sin escribir) → confirmar →
/// aplicar → resultado. Es el mismo recorrido para iglesias, hospedajes, equipos, etc.
/// Devuelve `true` si se importó algo.
Future<bool> runTableImport(
    BuildContext context, WidgetRef ref, TableImporter importer) async {
  final file = await ref.read(filePickProvider).pick();
  if (file == null || !context.mounted) return false;
  final text = decodeCsvBytes(file.bytes);
  TableImportSummary preview;
  try {
    preview = await importer.preview(text);
  } catch (e) {
    if (context.mounted) {
      await _message(context, 'No se pudo leer el archivo',
          'Detalle técnico: $e', const Key('ti-error'));
    }
    return false;
  }
  if (!context.mounted) return false;
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      key: const Key('ti-revision'),
      title: Text(importer.title),
      content: SingleChildScrollView(
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(importer.help, style: const TextStyle(color: Brand.gris)),
              const SizedBox(height: 12),
              for (final l in preview.lines) Text(l),
              if (preview.warnings.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                    '${preview.warnings.length} ${preview.warnings.length == 1 ? 'fila no se importará' : 'filas no se importarán'}:',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                for (final w in preview.warnings.take(8))
                  Text('• $w', style: const TextStyle(color: Brand.error)),
                if (preview.warnings.length > 8)
                  Text('… y ${preview.warnings.length - 8} más'),
              ],
              if (preview.work == 0)
                const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text('No hay nada que importar.',
                        key: Key('ti-nada'),
                        style: TextStyle(fontWeight: FontWeight.w700))),
            ]),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar')),
        FilledButton(
            key: const Key('ti-importar'),
            onPressed:
                preview.work == 0 ? null : () => Navigator.pop(ctx, true),
            child: const Text('Importar')),
      ],
    ),
  );
  if (go != true || !context.mounted) return false;
  try {
    final done = await importer.apply(text);
    if (!context.mounted) return true;
    await _message(context, 'Importación terminada', done.lines.join('\n'),
        const Key('ti-resultado'));
    return true;
  } catch (e) {
    if (context.mounted) {
      await _message(
          context, 'No se pudo importar', '$e', const Key('ti-error'));
    }
    return false;
  }
}

Future<void> _message(
        BuildContext context, String title, String body, Key key) =>
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: key,
        title: Text(title),
        content: SingleChildScrollView(child: SelectableText(body)),
        actions: [
          FilledButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Aceptar'))
        ],
      ),
    );
