import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../backup/backup_service.dart';
import '../data/attendee_exchange.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import 'auth_screens.dart' show ErrorBox;
import 'csv_import.dart';
import 'import_flow.dart';
import 'notifications.dart';

String ago(DateTime t, [DateTime? now]) {
  final d = (now ?? DateTime.now()).difference(t);
  if (d.inMinutes < 1) return 'hace un momento';
  if (d.inMinutes < 60) return 'hace ${d.inMinutes} min';
  if (d.inHours < 24) return 'hace ${d.inHours} h';
  return 'hace ${d.inDays} ${d.inDays == 1 ? 'día' : 'días'}';
}

/// Copias de seguridad: guardar (con contraseña opcional), abrir una copia y copias automáticas.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});
  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool busy = false;
  String? error;
  late Future<List<StoredBackup>> stored = ref.read(autoBackupProvider).list();

  String get eventId => ref.read(currentEventIdProvider)!;

  Future<void> _save() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final svc = ref.read(backupServiceProvider);
      final bytes = await svc.export(eventId);
      final ev = await ref.read(repositoryProvider).watchEvent(eventId).first;
      final name = BackupService.fileName(ev.name, DateTime.now());
      final ok = await ref
          .read(fileSaverProvider)
          .save(name, bytes, mimeType: 'text/csv');
      if (ok) await ref.read(autoBackupProvider).markBackup(DateTime.now());
      if (mounted) {
        ScaffoldMessenger.of(context)
            .notice(ok ? 'Copia guardada.' : 'Guardado cancelado.');
      }
    } catch (e) {
      if (mounted) {
        setState(
            () => error = 'No se pudo guardar la copia. Detalle técnico: $e');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _open() async {
    final f = await ref.read(filePickProvider).pick();
    if (f == null || !mounted) return;
    await importFromBytes(context, ref, f.bytes);
  }

  Future<void> _csvExport({required bool template}) async {
    try {
      final ex = ref.read(attendeeExchangeProvider);
      final ev = await ref.read(repositoryProvider).watchEvent(eventId).first;
      final text =
          template ? AttendeeExchange.template() : await ex.exportCsv(eventId);
      final base = ev.name.trim().isEmpty ? 'evento' : ev.name.trim();
      final name = template
          ? 'plantilla-asistentes.csv'
          : 'asistentes-${base.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')}.csv';
      final ok = await ref.read(fileSaverProvider).save(
          name, Uint8List.fromList(utf8.encode(text)),
          mimeType: 'text/csv');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .notice(ok ? 'Archivo CSV guardado.' : 'Guardado cancelado.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = 'No se pudo crear el CSV. Detalle técnico: $e');
      }
    }
  }

  Future<void> _csvImport() async {
    final f = await ref.read(filePickProvider).pick();
    if (f == null || !mounted) return;
    await importAttendeesCsv(context, ref, f.bytes);
  }

  Future<void> _restore(StoredBackup b) async {
    final bytes = await File(b.path).readAsBytes();
    if (!mounted) return;
    await importFromBytes(context, ref, bytes);
  }

  @override
  Widget build(BuildContext context) {
    final meta = ref.watch(appMetaProvider).valueOrNull;
    final last = meta?.lastBackupAt?.toLocal();
    final auto = ref.watch(autoBackupProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Copias de seguridad')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          key: const Key('bk-estado'),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: last == null ? Brand.avisoSuave : Brand.exitoSuave,
              borderRadius: BorderRadius.circular(12),
              border: last == null
                  ? Border.all(color: Brand.aviso, width: 2)
                  : null),
          child: Row(children: [
            Icon(
                last == null
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline,
                color: last == null ? Brand.avisoTexto : Brand.exito),
            const SizedBox(width: 10),
            Expanded(
                child: Text(
                    last == null
                        ? 'Todavía no hay ninguna copia. Guarda una para no perder los datos si falla el dispositivo.'
                        : 'Última copia: ${ago(last)}',
                    style: const TextStyle(fontSize: 16))),
          ]),
        ),
        if (auto.lastError != null) ...[
          const SizedBox(height: 8),
          ErrorBox('La última copia automática falló: ${auto.lastError}')
        ],
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Guardar una copia de este evento', style: headStyle(20)),
              const SizedBox(height: 6),
              const Text(
                  'Crea un archivo CSV con todo el evento. Puedes compartirlo por WhatsApp, Bluetooth o USB y abrirlo en otro dispositivo (también se ve en Excel).',
                  style: TextStyle(color: Brand.gris)),
              if (error != null) ...[
                const SizedBox(height: 8),
                ErrorBox(error!)
              ],
              const SizedBox(height: 12),
              FilledButton.icon(
                  key: const Key('bk-guardar'),
                  onPressed: busy ? null : _save,
                  icon: const Icon(Icons.save_alt),
                  label: const Text('Guardar copia')),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Abrir una copia', style: headStyle(20)),
              const SizedBox(height: 6),
              const Text(
                  'Elige un archivo CSV de copia de seguridad. Se fusiona con lo que ya hay: lo nuevo se añade y, si algo está en los dos sitios, se queda lo más reciente.',
                  style: TextStyle(color: Brand.gris)),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                  key: const Key('bk-abrir'),
                  onPressed: _open,
                  icon: const Icon(Icons.folder_open_outlined),
                  label: const Text('Abrir copia…')),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Intercambio con Excel (CSV)', style: headStyle(20)),
              const SizedBox(height: 6),
              const Text(
                  'Un solo archivo sirve para sacar los asistentes, completarlos en Excel (o seguir inscribiendo desde allí) e importarlos de nuevo. Cada fila es una persona; hospedaje, equipo, iglesia y grupos se escriben por su nombre.',
                  style: TextStyle(color: Brand.gris)),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                FilledButton.icon(
                    key: const Key('csv-exportar'),
                    onPressed: () => _csvExport(template: false),
                    icon: const Icon(Icons.table_view_outlined),
                    label: const Text('Exportar asistentes')),
                OutlinedButton.icon(
                    key: const Key('csv-plantilla'),
                    onPressed: () => _csvExport(template: true),
                    icon: const Icon(Icons.note_add_outlined),
                    label: const Text('Plantilla vacía')),
                OutlinedButton.icon(
                    key: const Key('csv-importar'),
                    onPressed: _csvImport,
                    icon: const Icon(Icons.upload_file_outlined),
                    label: const Text('Importar CSV…')),
              ]),
              const SizedBox(height: 8),
              ExpansionTile(
                key: const Key('csv-ayuda'),
                tilePadding: EdgeInsets.zero,
                title: const Text('Cómo llenarlo en Excel'),
                children: const [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                        '• Obligatorias: nombre, apellido1, sexo (Hombre/Mujer), edad e iglesia.\n'
                        '• Para personas nuevas deja id y numero vacíos: el sistema les pone el siguiente número.\n'
                        '• Para corregir a alguien ya registrado, conserva su id (o su numero y nombre).\n'
                        '• necesita_hospedaje: Sí o No. hospedaje y equipo: el nombre exacto tal como está en el evento; si no existe, se avisa y queda sin asignar. Vacío = no cambia.\n'
                        '• estado (opcional): Preinscrito o Confirmado. Al importar eliges cómo entran las personas nuevas; «Según el archivo» usa esta columna fila por fila. A quien ya está registrado nunca se le cambia el estado.\n'
                        '• pareja_numero: el número del cónyuge. grupos: varios separados con «|».\n'
                        '• Al guardar en Excel elige «CSV UTF-8 (delimitado por comas)» o «CSV (delimitado por comas)»; ambos se leen bien.',
                        style: TextStyle(color: Brand.gris)),
                  ),
                  SizedBox(height: 8),
                ],
              ),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Copias automáticas', style: headStyle(20)),
              const SizedBox(height: 6),
              const Text(
                  'La app guarda una sola al cerrar una comida y cada 20 registros. Se conservan las últimas 10 en este dispositivo.',
                  style: TextStyle(color: Brand.gris)),
              const SizedBox(height: 8),
              FutureBuilder<List<StoredBackup>>(
                future: stored,
                builder: (context, snap) {
                  final list = snap.data ?? const <StoredBackup>[];
                  if (list.isEmpty) {
                    return const Text('Todavía no hay copias automáticas.',
                        key: Key('bk-sin-auto'),
                        style: TextStyle(color: Brand.gris));
                  }
                  return Column(children: [
                    for (final b in list)
                      ListTile(
                        key: Key('bk-auto-${b.name}'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(b.name, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                            '${ago(b.modified)} · ${(b.size / 1024).ceil()} KB'),
                        trailing: TextButton(
                            onPressed: () => _restore(b),
                            child: const Text('Abrir')),
                      ),
                  ]);
                },
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
