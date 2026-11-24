import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento_core/mi_evento_core.dart' show normalizeText;

import '../data/list_filters.dart';
import '../data/repository.dart';
import '../export/csv_export.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import 'widgets/data_table_view.dart';
import 'widgets/highlight_text.dart';
import 'widgets/list_toolbar.dart';

/// Asistencia el día del evento: confirmar a los preinscritos (uno, un subconjunto o todos los que
/// se ven) y desconfirmar a quien se confirmó por error. En escritorio es una tabla con filtros.
class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});
  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  final query = TextEditingController();
  final selected = <String>{};

  /// true = por confirmar (preinscritos) · false = confirmados · null = todos.
  bool? showPre = true;
  String? sex, churchId;
  LodgingStatus? lodgingStatus;
  TeamStatus? teamStatus;

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  AttendeeFilter get _filter => AttendeeFilter(
      sex: sex,
      churchId: churchId,
      lodging: lodgingStatus,
      team: teamStatus,
      preregistered: showPre);

  void _snack(String text, {SnackBarAction? action}) =>
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(text), action: action));

  Future<void> _confirm(String eventId, Iterable<String> ids) async {
    final list = ids.toList();
    if (list.isEmpty) return;
    final repo = ref.read(repositoryProvider);
    final n = await repo.confirmAttendance(list);
    ref.read(autoBackupProvider).noteChange(eventId);
    if (!mounted) return;
    setState(() => selected.removeAll(list));
    _snack(
        n == 1
            ? 'Asistencia confirmada (1 persona).'
            : 'Asistencia confirmada ($n personas).',
        action: SnackBarAction(
            label: 'Deshacer',
            onPressed: () async {
              try {
                await repo.unconfirmAttendance(list);
              } on DataException catch (e) {
                if (mounted) _snack(e.message);
              }
            }));
  }

  /// Desconfirma (vuelve a preinscrito), previa confirmación. Si alguien ya tiene comidas marcadas
  /// el sistema lo bloquea y lo dice.
  Future<void> _unconfirm(String eventId, List<AttendeeView> who) async {
    if (who.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('ca-dialogo-desconfirmar'),
        title: const Text('Desconfirmar asistencia'),
        content: Text(who.length == 1
            ? '${who.first.fullName} volverá a quedar como preinscrito/a y dejará de contar en los totales.'
            : '${who.length} personas volverán a quedar como preinscritas y dejarán de contar en los totales.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              key: const Key('ca-desconfirmar-ok'),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Desconfirmar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final n = await ref
          .read(repositoryProvider)
          .unconfirmAttendance(who.map((v) => v.a.id));
      ref.read(autoBackupProvider).noteChange(eventId);
      if (!mounted) return;
      setState(() => selected.removeAll(who.map((v) => v.a.id)));
      _snack(n == 1
          ? 'Asistencia desconfirmada (1 persona).'
          : 'Asistencia desconfirmada ($n personas).');
    } on DataException catch (e) {
      if (mounted) _snack(e.message);
    }
  }

  Future<void> _confirmAll(String eventId, List<AttendeeView> shown) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('ca-dialogo-todos'),
        title: const Text('Confirmar a todos'),
        content: Text(
            'Se confirmará la asistencia de ${shown.length} ${shown.length == 1 ? 'persona' : 'personas'}.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              key: const Key('ca-dialogo-ok'),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmar')),
        ],
      ),
    );
    if (ok == true) await _confirm(eventId, shown.map((v) => v.a.id));
  }

  /// Exporta a CSV lo que deja la búsqueda y los filtros.
  Future<void> _export(String eventId, List<AttendeeView> shown) {
    final event = ref.read(eventProvider(eventId)).valueOrNull;
    return saveCsv(context, ref,
        name: csvFileName('por-confirmar', event?.name ?? ''),
        rows: [
          ['numero', 'nombre', 'sexo', 'edad', 'iglesia', 'estado'],
          for (final v in shown)
            [
              '${v.a.regNumber}',
              v.fullName,
              v.isMale ? 'Hombre' : 'Mujer',
              '${v.a.age}',
              v.churchName ?? '',
              v.isPreregistered ? 'Preinscrito' : 'Confirmado',
            ],
        ]);
  }

  Widget _rowAction(String eventId, AttendeeView v) => v.isPreregistered
      ? OutlinedButton(
          key: Key('ca-confirmar-${v.a.regNumber}'),
          onPressed: () => _confirm(eventId, [v.a.id]),
          child: const Text('Confirmar'))
      : TextButton(
          key: Key('ca-desconfirmar-${v.a.regNumber}'),
          onPressed: () => _unconfirm(eventId, [v]),
          child: const Text('Desconfirmar'));

  Widget _table(String eventId, List<AttendeeView> shown) {
    final q = query.text;
    return DataTableView<AttendeeView>(
      items: shown,
      initialSort: 1,
      columns: [
        TableCol(
            '',
            (v) => Checkbox(
                key: Key('ca-fila-${v.a.regNumber}'),
                value: selected.contains(v.a.id),
                onChanged: (x) => setState(() => x == true
                    ? selected.add(v.a.id)
                    : selected.remove(v.a.id)))),
        TableCol('Nº', (v) => Text('${v.a.regNumber}'),
            numeric: true, sortValue: (v) => v.a.regNumber),
        TableCol(
            'Nombre',
            (v) => HighlightText(v.fullName, q,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            sortValue: (v) => normalizeText(v.fullName)),
        TableCol('Sexo', (v) => Text(v.isMale ? 'Hombre' : 'Mujer'),
            sortValue: (v) => v.a.sex),
        TableCol('Edad', (v) => Text('${v.a.age}'),
            numeric: true, sortValue: (v) => v.a.age),
        TableCol('Iglesia', (v) => HighlightText(v.churchName ?? '—', q),
            sortValue: (v) => normalizeText(v.churchName ?? '')),
        TableCol(
            'Estado',
            (v) => v.isPreregistered
                ? const Chip(
                    label: Text('Preinscrito'),
                    visualDensity: VisualDensity.compact)
                : const Text('Confirmado'),
            sortValue: (v) => v.isPreregistered ? 0 : 1),
        TableCol('', (v) => _rowAction(eventId, v)),
      ],
    );
  }

  Widget _cards(String eventId, List<AttendeeView> shown) {
    final q = query.text;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: shown.length,
      itemBuilder: (_, i) {
        final v = shown[i];
        return Card(
          child: CheckboxListTile(
            key: Key('ca-fila-${v.a.regNumber}'),
            value: selected.contains(v.a.id),
            onChanged: (x) => setState(() =>
                x == true ? selected.add(v.a.id) : selected.remove(v.a.id)),
            controlAffinity: ListTileControlAffinity.leading,
            title: HighlightText(v.fullName, q,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
            subtitle: Text(
                'Nº ${v.a.regNumber} · ${v.isMale ? 'Hombre' : 'Mujer'} · ${v.a.age} años${v.churchName == null ? '' : ' · ${v.churchName}'}${v.isPreregistered ? '' : ' · Confirmado'}'),
            secondary: _rowAction(eventId, v),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventId = ref.watch(currentEventIdProvider)!;
    final all = ref.watch(attendeesProvider(eventId)).valueOrNull ??
        const <AttendeeView>[];
    final pendingCount = all.where((v) => v.isPreregistered).length;
    final confirmedCount = all.length - pendingCount;
    final shown = _filter.apply(Repository.search(all, query.text));
    final shownIds = {for (final v in shown) v.a.id};
    selected.retainAll({for (final v in all) v.a.id});
    final sel = selected.where(shownIds.contains).toSet();
    final selPending = [
      for (final v in shown)
        if (sel.contains(v.a.id) && v.isPreregistered) v
    ];
    final selConfirmed = [
      for (final v in shown)
        if (sel.contains(v.a.id) && !v.isPreregistered) v
    ];
    final shownPending = [
      for (final v in shown)
        if (v.isPreregistered) v
    ];
    final allSelected = shown.isNotEmpty && sel.length == shown.length;
    final churches = <String, String>{
      for (final v in all)
        if (v.a.churchId != null && v.churchName != null)
          v.a.churchId!: v.churchName!
    };
    // Sin observar hospedajes/equipos (así esta pantalla es ligera): los filtros aparecen si
    // alguien los usa.
    final hasLodging =
        all.any((v) => v.a.needsLodging || v.a.lodgingId != null);
    final hasTeams = all.any((v) => v.a.teamId != null);
    final filtering = query.text.isNotEmpty ||
        sex != null ||
        churchId != null ||
        lodgingStatus != null ||
        teamStatus != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar asistencia')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: ListToolbar(
            controller: query,
            hint: 'Buscar por nombre, iglesia o número…',
            searchKey: const Key('ca-buscar'),
            countKey: const Key('ca-conteo'),
            exportKey: const Key('ca-exportar'),
            onExport: shown.isEmpty ? null : () => _export(eventId, shown),
            onChanged: () => setState(() {}),
            activeFilters: [
              if (showPre != true) showPre,
              sex,
              churchId,
              lodgingStatus,
              teamStatus
            ].where((f) => f != null).length,
            count:
                '$pendingCount por confirmar · $confirmedCount ya confirmados${filtering ? ' · ${shown.length} coinciden' : ''}',
            filters: [
              FilterDropdown<String>(
                  key: const Key('ca-filtro-estado'),
                  label: 'Mostrar',
                  value: showPre == null
                      ? 'todos'
                      : showPre!
                          ? null
                          : 'confirmados',
                  options: const {
                    'confirmados': 'Confirmados',
                    'todos': 'Todos (preinscritos y confirmados)'
                  },
                  onChanged: (v) => setState(() {
                        showPre = v == 'todos'
                            ? null
                            : v == 'confirmados'
                                ? false
                                : true;
                      })),
              FilterDropdown<String>(
                  key: const Key('ca-filtro-sexo'),
                  label: 'Sexo',
                  value: sex,
                  options: const {'M': 'Hombres', 'F': 'Mujeres'},
                  onChanged: (v) => setState(() => sex = v)),
              FilterDropdown<String>(
                  key: const Key('ca-filtro-iglesia'),
                  label: 'Iglesia',
                  value: churchId,
                  options: churches,
                  onChanged: (v) => setState(() => churchId = v)),
              if (hasLodging)
                FilterDropdown<LodgingStatus>(
                    key: const Key('ca-filtro-hospedaje'),
                    label: 'Hospedaje',
                    value: lodgingStatus,
                    options: const {
                      LodgingStatus.assigned: 'Con hospedaje',
                      LodgingStatus.pending: 'Necesita y no tiene',
                      LodgingStatus.notNeeded: 'No necesita',
                    },
                    onChanged: (v) => setState(() => lodgingStatus = v)),
              if (hasTeams)
                FilterDropdown<TeamStatus>(
                    key: const Key('ca-filtro-equipo'),
                    label: 'Equipo',
                    value: teamStatus,
                    options: const {
                      TeamStatus.assigned: 'Con equipo',
                      TeamStatus.none: 'Sin equipo',
                    },
                    onChanged: (v) => setState(() => teamStatus = v)),
            ],
          ),
        ),
        if (shown.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilterChip(
                      key: const Key('ca-sel-todos'),
                      label: Text(allSelected
                          ? 'Quitar selección'
                          : 'Seleccionar todos (${shown.length})'),
                      selected: allSelected,
                      onSelected: (v) => setState(() =>
                          v ? selected.addAll(shownIds) : selected.clear())),
                  if (shownPending.isNotEmpty) ...[
                    FilledButton.icon(
                        key: const Key('ca-confirmar-sel'),
                        onPressed: selPending.isEmpty
                            ? null
                            : () => _confirm(
                                eventId, selPending.map((v) => v.a.id)),
                        icon: const Icon(Icons.check),
                        label: Text(
                            'Confirmar seleccionados (${selPending.length})')),
                    OutlinedButton.icon(
                        key: const Key('ca-confirmar-todos'),
                        onPressed: () => _confirmAll(eventId, shownPending),
                        icon: const Icon(Icons.done_all),
                        label: Text(!filtering
                            ? 'Confirmar a todos'
                            : 'Confirmar a los que se ven')),
                  ],
                  if (selConfirmed.isNotEmpty)
                    OutlinedButton.icon(
                        key: const Key('ca-desconfirmar-sel'),
                        onPressed: () => _unconfirm(eventId, selConfirmed),
                        icon: const Icon(Icons.undo),
                        label: Text(
                            'Desconfirmar seleccionados (${selConfirmed.length})')),
                ]),
          ),
        Expanded(
          child: shown.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                        all.isEmpty
                            ? 'Todavía no hay nadie inscrito.'
                            : filtering
                                ? 'Nadie coincide con la búsqueda y los filtros.'
                                : showPre == true
                                    ? 'No hay preinscritos por confirmar. Todos los inscritos ya están confirmados.'
                                    : 'No hay nadie en esta lista.',
                        key: const Key('ca-vacio'),
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(fontSize: 18, color: Brand.gris)),
                  ),
                )
              : useTables(context)
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: _table(eventId, shown))
                  : _cards(eventId, shown),
        ),
      ]),
    );
  }
}
