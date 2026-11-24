import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import '../data/attendee_exchange.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import 'auth_screens.dart' show ErrorBox;

/// Importación de asistentes desde un CSV: vista previa de lo que pasaría y confirmación.
Future<void> importAttendeesCsv(
    BuildContext context, WidgetRef ref, Uint8List bytes) async {
  final eventId = ref.read(currentEventIdProvider)!;
  final parse = parseAttendeesCsv(decodeCsvBytes(bytes));
  final done = await showDialog<ImportReport>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ImportDialog(eventId: eventId, parse: parse),
  );
  if (done == null || !context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      key: const Key('csvi-resultado'),
      icon: const Icon(Icons.check_circle, color: Brand.exito, size: 40),
      title: const Text('Importación terminada'),
      content: SingleChildScrollView(
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nuevas personas: ${done.created}'),
              Text('Personas actualizadas: ${done.updated}'),
              if (done.skipped > 0)
                Text('Omitidas por posible duplicado: ${done.skipped}'),
              if (done.churchesCreated > 0)
                Text('Iglesias nuevas en el catálogo: ${done.churchesCreated}'),
              if (done.teamsAutoAssigned > 0)
                Text(
                    'Con equipo asignado automáticamente: ${done.teamsAutoAssigned}'),
              if (done.groupsCreated > 0)
                Text('Grupos nuevos: ${done.groupsCreated}'),
              for (final w in done.warnings.take(8))
                Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(w,
                        style: const TextStyle(color: Brand.avisoTexto))),
            ]),
      ),
      actions: [
        FilledButton(
            key: const Key('csvi-cerrar'),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Listo')),
      ],
    ),
  );
}

class _ImportDialog extends ConsumerStatefulWidget {
  const _ImportDialog({required this.eventId, required this.parse});
  final String eventId;
  final AttendeeCsvParse parse;
  @override
  ConsumerState<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends ConsumerState<_ImportDialog> {
  ImportPlan? plan;
  bool includeDuplicates = false;

  /// Nulo hasta que la persona elige (así no se importa con el estado equivocado sin darse cuenta).
  /// 'pre' = preinscritos · 'conf' = confirmados · 'file' = según la columna «estado».
  String? statusMode;
  bool keepAssignments = false;
  bool busy = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _plan();
  }

  Future<void> _plan() async {
    try {
      final p = await ref.read(attendeeExchangeProvider).plan(
          widget.eventId, widget.parse,
          includeDuplicates: includeDuplicates);
      if (mounted) setState(() => plan = p);
    } catch (e) {
      if (mounted) {
        setState(
            () => error = 'No se pudo revisar el archivo. Detalle técnico: $e');
      }
    }
  }

  Future<void> _apply() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final rep = await ref.read(attendeeExchangeProvider).apply(
          widget.eventId, plan!,
          createdBy: ref.read(currentUserProvider)?.id,
          asPreregistered: statusMode == 'pre',
          useFileStatus: statusMode == 'file',
          keepAssignments: keepAssignments);
      ref.read(autoBackupProvider).noteChange(widget.eventId);
      if (mounted) Navigator.pop(context, rep);
    } catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = 'No se importó nada (todo o nada). Detalle técnico: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = plan;
    return AlertDialog(
      key: const Key('csvi-dialogo'),
      title: const Text('Importar asistentes'),
      content: SizedBox(
        width: 520,
        child: p == null
            ? SizedBox(
                height: 80,
                child: Center(
                    child: error == null
                        ? const CircularProgressIndicator()
                        : ErrorBox(error!)))
            : SingleChildScrollView(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${p.creates} ${p.creates == 1 ? 'persona nueva' : 'personas nuevas'} · ${p.updates} ${p.updates == 1 ? 'se actualiza' : 'se actualizan'}${p.duplicates > 0 ? ' · ${p.duplicates} posibles duplicados' : ''}${p.errors.isNotEmpty ? ' · ${p.errors.length} filas con errores' : ''}',
                          key: const Key('csvi-resumen'),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      const Text(
                          'No se cambia nada hasta que pulses «Importar». Si algo falla, no se importa nada.',
                          style: TextStyle(color: Brand.gris)),
                      if (p.creates > 0) ...[
                        const SizedBox(height: 10),
                        Text(
                            '¿Cómo entra ${p.creates == 1 ? 'la persona nueva' : 'las ${p.creates} personas nuevas'}?',
                            key: const Key('csvi-estado-titulo'),
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        SegmentedButton<String>(
                          key: const Key('csvi-estado'),
                          emptySelectionAllowed: true,
                          showSelectedIcon: false,
                          segments: [
                            const ButtonSegment(
                                value: 'pre',
                                label: Text('Preinscritos',
                                    key: Key('csvi-preinscritos')),
                                icon: Icon(Icons.event_available_outlined)),
                            const ButtonSegment(
                                value: 'conf',
                                label: Text('Confirmados',
                                    key: Key('csvi-confirmados')),
                                icon: Icon(Icons.how_to_reg_outlined)),
                            if (p.hasStatusColumn)
                              const ButtonSegment(
                                  value: 'file',
                                  label: Text('Según el archivo',
                                      key: Key('csvi-segun-archivo')),
                                  icon: Icon(Icons.table_chart_outlined)),
                          ],
                          selected: {if (statusMode != null) statusMode!},
                          onSelectionChanged: busy
                              ? null
                              : (v) =>
                                  setState(() => statusMode = v.firstOrNull),
                        ),
                        const SizedBox(height: 4),
                        Text(
                            switch (statusMode) {
                              null => 'Elige una opción para poder importar.',
                              'pre' =>
                                'Preinscritos: su asistencia se confirma el día del evento.',
                              'conf' =>
                                'Confirmados: ya cuentan como asistentes (totales, comidas, reportes).',
                              _ =>
                                'Según la columna «estado»: ${p.createsConfirmed} confirmadas · ${p.createsPreregistered} preinscritas. Las filas sin estado entran como confirmadas.',
                            },
                            key: const Key('csvi-estado-ayuda'),
                            style: const TextStyle(color: Brand.gris)),
                        if (statusMode == 'pre' || statusMode == 'file')
                          CheckboxListTile(
                            key: const Key('csvi-conservar'),
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            value: keepAssignments,
                            onChanged: busy
                                ? null
                                : (v) => setState(
                                    () => keepAssignments = v ?? false),
                            title: const Text(
                                'Conservar el hospedaje y el equipo del archivo'),
                            subtitle: const Text(
                                'Para los preinscritos. Solo se usan los que existan en este evento con ese nombre; los confirmados siempre los conservan.'),
                          ),
                      ],
                      if (p.duplicates > 0 || includeDuplicates)
                        CheckboxListTile(
                          key: const Key('csvi-duplicados'),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: includeDuplicates,
                          onChanged: busy
                              ? null
                              : (v) {
                                  setState(() {
                                    includeDuplicates = v ?? false;
                                    plan = null;
                                  });
                                  _plan();
                                },
                          title: const Text(
                              'Importar también los posibles duplicados'),
                          subtitle: const Text(
                              'Mismo nombre, primer apellido y edad que alguien ya registrado.'),
                        ),
                      if (p.errors.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        const Text('Filas que no se importan:',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        for (final e in p.errors.take(10))
                          Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(e.toString(),
                                  key: const Key('csvi-error'),
                                  style: const TextStyle(color: Brand.error))),
                        if (p.errors.length > 10)
                          Text('…y ${p.errors.length - 10} más.',
                              style: const TextStyle(color: Brand.gris)),
                      ],
                      if (p.warnings.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        const Text('Avisos:',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        for (final w in p.warnings.take(8))
                          Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(w,
                                  style: const TextStyle(
                                      color: Brand.avisoTexto))),
                        if (p.warnings.length > 8)
                          Text('…y ${p.warnings.length - 8} más.',
                              style: const TextStyle(color: Brand.gris)),
                      ],
                      if (error != null) ...[
                        const SizedBox(height: 10),
                        ErrorBox(error!)
                      ],
                    ]),
              ),
      ),
      actions: [
        TextButton(
            key: const Key('csvi-cancelar'),
            onPressed: busy ? null : () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(
            key: const Key('csvi-importar'),
            onPressed: busy ||
                    p == null ||
                    !p.hasWork ||
                    (p.creates > 0 && statusMode == null)
                ? null
                : _apply,
            child: Text(busy ? 'Importando…' : 'Importar')),
      ],
    );
  }
}
