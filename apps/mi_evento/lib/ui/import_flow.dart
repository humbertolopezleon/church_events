import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import '../backup/backup_service.dart';
import '../providers.dart';
import '../theme/app_theme.dart';

/// Flujo común para abrir una copia de seguridad (CSV): muestra qué
/// contiene, pide confirmación, importa y muestra el resultado. Devuelve el informe o null si se canceló.
Future<ImportReport?> importFromBytes(
    BuildContext context, WidgetRef ref, Uint8List bytes) async {
  Bundle? bundle;
  String? error;
  try {
    bundle = decodeBundle(bytes);
  } on BundleException catch (e) {
    error = e.message;
  }
  if (!context.mounted) return null;
  if (bundle == null) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('imp-error'),
        icon: const Icon(Icons.error_outline, color: Brand.error, size: 36),
        title: const Text('No se pudo abrir la copia'),
        content: Text(error ?? 'El archivo no es válido.'),
        actions: [
          FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendido'))
        ],
      ),
    );
    return null;
  }
  final m = bundle.manifest;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      key: const Key('imp-vista-previa'),
      title: const Text('Abrir esta copia'),
      content: SingleChildScrollView(
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.eventName, style: headStyle(22)),
              const SizedBox(height: 4),
              Text('Guardada el ${_date(m.exportedAt.toLocal())}',
                  style: const TextStyle(color: Brand.gris)),
              const SizedBox(height: 10),
              Text(
                  '${m.counts['attendees'] ?? 0} asistentes · ${m.counts['lodgings'] ?? 0} hospedajes · ${m.counts['teams'] ?? 0} equipos · ${m.counts['controlSessions'] ?? 0} sesiones de control',
                  key: const Key('imp-contenido')),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Brand.azulSuave,
                    borderRadius: BorderRadius.circular(12)),
                child: const Text(
                    'Se fusiona con lo que ya hay en este dispositivo: lo nuevo se añade y, si algo está en los dos sitios, se queda la versión más reciente. No se borra nada.'),
              ),
            ]),
      ),
      actions: [
        TextButton(
            key: const Key('imp-cancelar'),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar')),
        FilledButton(
            key: const Key('imp-confirmar'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Abrir copia')),
      ],
    ),
  );
  if (ok != true || !context.mounted) return null;
  try {
    final rep = await ref.read(backupServiceProvider).import(bundle);
    if (!context.mounted) return rep;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('imp-resultado'),
        icon: const Icon(Icons.check_circle_outline,
            color: Brand.exito, size: 36),
        title: const Text('Copia abierta'),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('«${rep.eventName}» ya está en Mis eventos.',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                  '${rep.inserted} nuevos · ${rep.updated} actualizados · ${rep.skipped} sin cambios',
                  key: const Key('imp-cifras')),
              if (rep.renumbered > 0)
                Text(
                    '${rep.renumbered} ${rep.renumbered == 1 ? 'asistente cambió' : 'asistentes cambiaron'} de número de inscripción porque coincidían con otros.',
                    style: const TextStyle(color: Brand.avisoTexto)),
              if (rep.churchesMerged > 0)
                Text(
                    '${rep.churchesMerged} ${rep.churchesMerged == 1 ? 'iglesia se unió' : 'iglesias se unieron'} con las que ya existían.',
                    style: const TextStyle(color: Brand.gris)),
            ]),
        actions: [
          FilledButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Listo'))
        ],
      ),
    );
    return rep;
  } catch (e) {
    if (context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          key: const Key('imp-fallo'),
          icon: const Icon(Icons.error_outline, color: Brand.error, size: 36),
          title: const Text('No se pudo importar'),
          content: Text('No se cambió nada. Detalle técnico: $e'),
          actions: [
            FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Entendido'))
          ],
        ),
      );
    }
    return null;
  }
}

String _date(DateTime t) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(t.day)}/${two(t.month)}/${t.year} a las ${two(t.hour)}:${two(t.minute)}';
}
