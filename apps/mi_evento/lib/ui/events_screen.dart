import 'package:material_ui/material_ui.dart';
import 'event_dates.dart';
import 'widgets/labeled_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_service.dart';
import '../data/database.dart';
import '../data/repository.dart' show DataException;
import '../export/csv_export.dart';
import 'package:mi_evento_core/mi_evento_core.dart' show normalizeText;
import '../providers.dart';
import '../theme/app_theme.dart';
import 'app_shell.dart' show signOut;
import 'auth_screens.dart' show ErrorBox;
import 'default_password_banner.dart';
import 'event_copy_dialogs.dart';
import 'import_flow.dart';
import 'widgets/data_table_view.dart';
import 'widgets/list_toolbar.dart';
import '../data/event_exchange.dart';
import 'table_import_flow.dart';
import 'widgets/app_fab.dart';
import 'widgets/app_header.dart';
import 'widgets/plural.dart';

/// Texto de búsqueda de «Mis eventos».
final eventQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// Lista de eventos en vivo (para el menú de exportar de la cabecera).
final eventsListProvider = StreamProvider<List<Event>>(
    (ref) => ref.watch(repositoryProvider).watchEvents());

/// CSV de los eventos mostrados.
Future<void> _exportEvents(
        BuildContext context, WidgetRef ref, List<Event> shown) =>
    saveCsv(context, ref, name: 'eventos.csv', rows: [
      [
        'nombre',
        'inicio',
        'fin',
        'lugar',
        'organizador',
        'hospedaje',
        'equipos'
      ],
      for (final e in shown)
        [
          e.name,
          e.startDate,
          e.endDate,
          e.venue,
          e.organizer,
          e.offersLodging ? 'Sí' : 'No',
          e.offersTeams ? 'Sí' : 'No',
        ],
    ]);

List<Event> filterEvents(List<Event> all, String query) {
  final q = normalizeText(query);
  if (q.isEmpty) return all;
  return [
    for (final e in all)
      if (normalizeText('${e.name} ${e.venue} ${e.organizer}').contains(q)) e
  ];
}

class _EventsToolbar extends ConsumerStatefulWidget {
  const _EventsToolbar({required this.shown, required this.total});
  final List<Event> shown;
  final int total;
  @override
  ConsumerState<_EventsToolbar> createState() => _EventsToolbarState();
}

class _EventsToolbarState extends ConsumerState<_EventsToolbar> {
  late final c = TextEditingController(text: ref.read(eventQueryProvider));

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: ListToolbar(
          controller: c,
          hint: 'Nombre, lugar u organizador',
          searchKey: const Key('ev-buscar'),
          countKey: const Key('ev-conteo'),
          onChanged: () => ref.read(eventQueryProvider.notifier).state = c.text,
          count: widget.shown.length == widget.total
              ? ''
              : '${widget.shown.length} de ${widget.total}',
        ),
      );
}

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final f = await ref.read(filePickProvider).pick();
    if (f == null || !context.mounted) return;
    await importFromBytes(context, ref, f.bytes);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(repositoryProvider);
    final admin = ref.watch(currentUserProvider)?.isAdmin ?? false;
    final narrow = MediaQuery.sizeOf(context).width < 480;
    final eventsAll =
        ref.watch(eventsListProvider).valueOrNull ?? const <Event>[];
    final eventsShown = filterEvents(eventsAll, ref.watch(eventQueryProvider));
    return Scaffold(
      appBar: AppHeader(
        title: 'Mis eventos',
        subtitle:
            plural(eventsAll.length, 'evento', 'eventos', zero: 'Sin eventos'),
        importKey: const Key('ev-importar'),
        exportKey: const Key('ev-exportar'),
        onImport: () => runTableImport(
            context, ref, EventExchange(ref.read(databaseProvider))),
        onExport: () => _exportEvents(context, ref, eventsShown),
        exportEnabled: eventsShown.isNotEmpty,
        actions: [
          // En pantallas estrechas (360 px) los botones son solo icono, con su ayuda al mantener.
          if (admin && narrow)
            IconButton(
                key: const Key('ev-abrir-copia'),
                tooltip: 'Abrir una copia',
                color: Colors.white,
                onPressed: () => _open(context, ref),
                icon: const Icon(Icons.folder_open_outlined))
          else if (admin)
            TextButton.icon(
              key: const Key('ev-abrir-copia'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              onPressed: () => _open(context, ref),
              icon: const Icon(Icons.folder_open_outlined),
              label: const Text('Abrir una copia'),
            ),
          if (narrow)
            IconButton(
                key: const Key('ev-cerrar-sesion'),
                tooltip: 'Salir',
                color: Colors.white,
                onPressed: () => signOut(ref),
                icon: const Icon(Icons.logout))
          else
            TextButton.icon(
              key: const Key('ev-cerrar-sesion'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              onPressed: () => signOut(ref),
              icon: const Icon(Icons.logout),
              label: const Text('Salir'),
            ),
        ],
      ),
      floatingActionButton: AppFab(
        key: const Key('ev-crear-fab'),
        onPressed: () => showDialog<void>(
            context: context, builder: (_) => const _NewEventDialog()),
        icon: Icons.add,
        label: 'Crear evento',
      ),
      body: Column(children: [
        const DefaultPasswordBanner(),
        Expanded(
            child: StreamBuilder<List<Event>>(
          stream: repo.watchEvents(),
          builder: (context, snap) {
            final list = snap.data ?? const <Event>[];
            if (list.isEmpty) {
              return Center(
                  child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text(
                      'Todavía no hay eventos.\nToca «Crear evento» para empezar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Brand.gris)),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const Key('ev-importar-vacio'),
                    onPressed: () => runTableImport(context, ref,
                        EventExchange(ref.read(databaseProvider))),
                    icon: const Icon(Icons.upload_file_outlined),
                    label: const Text('Importar eventos (CSV)'),
                  ),
                  if (admin) ...[
                    const SizedBox(height: 16),
                    const Text('¿Ya tienes una copia de otro dispositivo?',
                        style: TextStyle(color: Brand.gris)),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      key: const Key('ev-abrir-copia-vacio'),
                      onPressed: () => _open(context, ref),
                      icon: const Icon(Icons.folder_open_outlined),
                      label: const Text('Abrir una copia (CSV)'),
                    ),
                  ],
                ]),
              ));
            }
            final shown = filterEvents(list, ref.watch(eventQueryProvider));
            return Column(children: [
              _EventsToolbar(shown: shown, total: list.length),
              Expanded(
                  child: useTables(context)
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          child: _eventsTable(context, ref, shown, admin))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: shown.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final e = shown[i];
                            return Card(
                              child: ListTile(
                                key: Key('evento-${e.name}'),
                                minVerticalPadding: 14,
                                title: Text(e.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 20)),
                                subtitle: Text(
                                    '${e.startDate} → ${e.endDate}${e.venue.isEmpty ? '' : ' · ${e.venue}'}'),
                                trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (admin) _eventMenu(context, ref, e),
                                      const Icon(Icons.chevron_right),
                                    ]),
                                onTap: () => ref
                                    .read(currentEventIdProvider.notifier)
                                    .state = e.id,
                              ),
                            );
                          },
                        ))
            ]);
          },
        )),
      ]),
    );
  }
}

/// Menú «más acciones» de un evento (duplicar, pasar participantes, eliminar).
Widget _eventMenu(BuildContext context, WidgetRef ref, Event e) =>
    PopupMenuButton<String>(
      key: Key('evento-menu-${e.name}'),
      tooltip: 'Más acciones',
      onSelected: (v) => showDialog<void>(
          context: context,
          builder: (_) => switch (v) {
                'dup' => DuplicateEventDialog(event: e),
                'move' => CopyPeopleDialog(event: e),
                _ => _DeleteEventDialog(event: e),
              }),
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'dup', child: Text('Duplicar evento…')),
        PopupMenuItem(
            value: 'move', child: Text('Pasar participantes a otro evento…')),
        PopupMenuItem(value: 'del', child: Text('Eliminar evento…')),
      ],
    );

Widget _eventsTable(
        BuildContext context, WidgetRef ref, List<Event> list, bool admin) =>
    DataTableView<Event>(
      items: list,
      onTap: (e) => ref.read(currentEventIdProvider.notifier).state = e.id,
      columns: [
        TableCol(
            'Nombre',
            (e) => Text(e.name,
                key: Key('evento-${e.name}'),
                style: const TextStyle(fontWeight: FontWeight.w800)),
            sortValue: (e) => normalizeText(e.name)),
        TableCol('Inicio', (e) => Text(e.startDate),
            sortValue: (e) => e.startDate),
        TableCol('Fin', (e) => Text(e.endDate), sortValue: (e) => e.endDate),
        TableCol('Lugar', (e) => Text(e.venue.isEmpty ? '—' : e.venue),
            sortValue: (e) => normalizeText(e.venue)),
        TableCol(
            'Organizador', (e) => Text(e.organizer.isEmpty ? '—' : e.organizer),
            sortValue: (e) => normalizeText(e.organizer)),
        if (admin) TableCol('', (e) => _eventMenu(context, ref, e)),
      ],
    );

/// Eliminar un evento para siempre. Pide escribir su nombre: es irreversible.
class _DeleteEventDialog extends ConsumerStatefulWidget {
  const _DeleteEventDialog({required this.event});
  final Event event;
  @override
  ConsumerState<_DeleteEventDialog> createState() => _DeleteEventDialogState();
}

class _DeleteEventDialogState extends ConsumerState<_DeleteEventDialog> {
  final typed = TextEditingController();
  String? error;

  bool get matches =>
      typed.text.trim().toLowerCase() == widget.event.name.trim().toLowerCase();

  @override
  Widget build(BuildContext context) => AlertDialog(
        key: const Key('ev-eliminar'),
        icon: const Icon(Icons.warning_amber_rounded,
            color: Brand.error, size: 40),
        title: const Text('Eliminar este evento para siempre'),
        content: SingleChildScrollView(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Se borrarán «${widget.event.name}» y todo lo suyo: asistentes, hospedajes, equipos y registros de comidas. No se puede deshacer.'),
                const SizedBox(height: 8),
                const Text(
                    'Antes de eliminarlo, guarda una copia desde «Copias de seguridad» si quieres conservarlo.',
                    style: TextStyle(color: Brand.gris)),
                const SizedBox(height: 12),
                LabeledField(
                    label: 'Para confirmar, escribe el nombre del evento',
                    child: TextField(
                      key: const Key('ev-eliminar-nombre'),
                      controller: typed,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(),
                    )),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  ErrorBox(error!)
                ],
              ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
            key: const Key('ev-eliminar-ok'),
            style: FilledButton.styleFrom(backgroundColor: Brand.error),
            onPressed: !matches
                ? null
                : () async {
                    try {
                      final n = await ref
                          .read(repositoryProvider)
                          .deleteEventPermanently(widget.event.id,
                              isAdmin: ref.read(currentUserProvider)?.isAdmin ??
                                  false);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              'Evento eliminado ($n ${n == 1 ? 'persona borrada' : 'personas borradas'}).')));
                    } on DataException catch (e) {
                      setState(() => error = e.message);
                    }
                  },
            child: const Text('Eliminar para siempre'),
          ),
        ],
      );
}

class _NewEventDialog extends ConsumerStatefulWidget {
  const _NewEventDialog();
  @override
  ConsumerState<_NewEventDialog> createState() => _NewEventDialogState();
}

class _NewEventDialogState extends ConsumerState<_NewEventDialog> {
  final name = TextEditingController();
  final venue = TextEditingController();
  final organizer = TextEditingController();
  DateTime start = DateTime.now();
  DateTime end = DateTime.now();
  bool lodging = true;
  bool teams = true;
  String? error;

  String _d(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Un solo calendario: se toca el primer día y luego el último. Para un evento de un solo
  /// día basta tocar el mismo día dos veces.
  Future<void> _pickRange() async {
    final r = await pickEventDates(context, start: start, end: end);
    if (r != null) {
      setState(() {
        start = r.start;
        end = r.end;
      });
    }
  }

  String get _rangeText => _d(start) == _d(end)
      ? 'Un solo día: ${_d(start)}'
      : '${_d(start)}  →  ${_d(end)}';

  Future<void> _save() async {
    if (name.text.trim().isEmpty) {
      setState(() => error = 'Falta el nombre. Escríbelo para poder guardar.');
      return;
    }
    if (dateOnly(start).isBefore(dateOnly(DateTime.now()))) {
      setState(() => error = 'La fecha de inicio no puede ser anterior a hoy.');
      return;
    }
    if (end.isBefore(start)) {
      setState(() =>
          error = 'La fecha de fin no puede ser anterior a la de inicio.');
      return;
    }
    final id = await ref.read(repositoryProvider).createEvent(
        name: name.text,
        startDate: _d(start),
        endDate: _d(end),
        venue: venue.text,
        organizer: organizer.text,
        offersLodging: lodging,
        offersTeams: teams,
        setupDone:
            false); // primero se configura; luego se abren las inscripciones
    if (!mounted) return;
    Navigator.pop(context);
    ref.read(currentEventIdProvider.notifier).state = id;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Crear evento'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 460,
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LabeledField(
                      label: 'Nombre',
                      child: TextField(
                          key: const Key('ev-nombre'),
                          controller: name,
                          decoration: const InputDecoration())),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const Key('ev-fechas'),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        alignment: Alignment.centerLeft),
                    onPressed: _pickRange,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text('Fechas: $_rangeText'),
                  ),
                  const SizedBox(height: 12),
                  LabeledField(
                      label: 'Lugar',
                      child: TextField(
                          controller: venue,
                          decoration: const InputDecoration())),
                  const SizedBox(height: 12),
                  LabeledField(
                      label: 'Organizador',
                      child: TextField(
                          controller: organizer,
                          decoration: const InputDecoration())),
                  SwitchListTile(
                      key: const Key('ev-hospedaje'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Ofrece hospedaje'),
                      value: lodging,
                      onChanged: (v) => setState(() => lodging = v)),
                  SwitchListTile(
                      key: const Key('ev-equipos'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Se dividirá en equipos'),
                      value: teams,
                      onChanged: (v) => setState(() => teams = v)),
                  if (error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: const Color(0xFFFCE8E6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Brand.error, width: 2)),
                      child: Row(children: [
                        const Icon(Icons.error_outline, color: Brand.error),
                        const SizedBox(width: 10),
                        Expanded(child: Text(error!)),
                      ]),
                    ),
                ]),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              key: const Key('ev-crear'),
              onPressed: _save,
              child: const Text('Crear evento')),
        ],
      );
}
