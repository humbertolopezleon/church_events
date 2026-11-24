import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento_core/mi_evento_core.dart';
import 'package:printing/printing.dart';

import '../auth/auth_service.dart';
import '../data/database.dart';
import '../data/repos_b.dart';
import '../data/repository.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import '../data/list_filters.dart';
import '../export/csv_export.dart';
import 'auth_screens.dart' show ErrorBox;
import 'lodging_pdf.dart';
import 'lodging_suggest_screen.dart';
import 'widgets/data_table_view.dart';
import 'widgets/list_toolbar.dart';

String kindLabel(String kind) =>
    kind == 'shelter' ? 'Albergue' : 'Casa particular';

class _Occupancy extends StatelessWidget {
  const _Occupancy(this.occupied, this.capacity);
  final int occupied, capacity;
  @override
  Widget build(BuildContext context) {
    final over = occupied > capacity;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: LinearProgressIndicator(
          minHeight: 12,
          value:
              capacity == 0 ? 0 : (occupied / capacity).clamp(0, 1).toDouble(),
          backgroundColor: Brand.azulSuave,
          color: over ? Brand.error : Brand.azul,
        ),
      ),
      const SizedBox(height: 4),
      Text(
          over
              ? '$occupied de $capacity ocupadas · sobrecupo de ${occupied - capacity}'
              : '$occupied de $capacity ocupadas',
          style: TextStyle(
              fontSize: 14,
              color: over ? Brand.error : Brand.gris,
              fontWeight: over ? FontWeight.w700 : FontWeight.w400)),
    ]);
  }
}

class LodgingsScreen extends ConsumerStatefulWidget {
  const LodgingsScreen({super.key});
  @override
  ConsumerState<LodgingsScreen> createState() => _LodgingsScreenState();
}

class _LodgingsScreenState extends ConsumerState<LodgingsScreen> {
  final query = TextEditingController();
  LodgingAccepts? accepts;
  bool onlyFree = false;

  Future<void> _export(String eventName, List<LodgingView> shown) =>
      saveCsv(context, ref, name: csvFileName('hospedajes', eventName), rows: [
        [
          'nombre',
          'tipo',
          'acepta',
          'capacidad',
          'ocupadas',
          'libres',
          'anfitrion',
          'telefono',
          'indicaciones',
          'cercania'
        ],
        for (final l in shown)
          [
            l.row.name,
            kindLabel(l.row.kind),
            lodgingAcceptsLabel(lodgingAcceptsFromDb(l.row.accepts)),
            '${l.row.capacity}',
            '${l.occupied}',
            '${l.free}',
            l.row.hostName ?? '',
            l.row.contactPhone ?? '',
            l.row.directions,
            l.row.distanceNote,
          ],
      ]);

  /// Vista de escritorio: tabla con columnas ordenables (el móvil sigue con tarjetas).
  Widget _table(List<LodgingView> list) => DataTableView<LodgingView>(
        items: list,
        onTap: (l) => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => LodgingDetailScreen(lodgingId: l.row.id))),
        columns: [
          TableCol(
              'Nombre',
              (l) => Text(l.row.name,
                  key: Key('hosp-${l.row.name}'),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              sortValue: (l) => normalizeText(l.row.name)),
          TableCol('Tipo', (l) => Text(kindLabel(l.row.kind)),
              sortValue: (l) => l.row.kind),
          TableCol(
              'Acepta',
              (l) => Text(
                  lodgingAcceptsLabel(lodgingAcceptsFromDb(l.row.accepts))),
              sortValue: (l) => l.row.accepts),
          TableCol('Capacidad', (l) => Text('${l.row.capacity}'),
              numeric: true, sortValue: (l) => l.row.capacity),
          TableCol(
              'Ocupadas',
              (l) => Text('${l.occupied}',
                  style: TextStyle(
                      color: l.occupied > l.row.capacity ? Brand.error : null,
                      fontWeight: l.occupied > l.row.capacity
                          ? FontWeight.w700
                          : null)),
              numeric: true,
              sortValue: (l) => l.occupied),
          TableCol('Libres', (l) => Text('${l.free < 0 ? 0 : l.free}'),
              numeric: true, sortValue: (l) => l.free),
          TableCol('Anfitrión', (l) => Text(l.row.hostName ?? '—'),
              sortValue: (l) => normalizeText(l.row.hostName ?? '')),
          TableCol(
              'Cercanía',
              (l) => Text(l.row.distanceNote.isEmpty ? '—' : l.row.distanceNote,
                  overflow: TextOverflow.ellipsis)),
          TableCol('', (l) => _LodgingMenu(l)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final eventId = ref.watch(currentEventIdProvider)!;
    final event = ref.watch(eventProvider(eventId)).valueOrNull;
    final lodgings = ref.watch(lodgingsProvider(eventId)).valueOrNull ??
        const <LodgingView>[];
    final people = ref.watch(attendeesProvider(eventId)).valueOrNull ??
        const <AttendeeView>[];
    final pending =
        people.where((p) => p.a.needsLodging && p.a.lodgingId == null).length;
    final places = lodgings.fold<int>(0, (s, l) => s + l.row.capacity);
    final shown = filterLodgings(lodgings, query.text,
        accepts: accepts, onlyFree: onlyFree);

    return Scaffold(
      appBar: AppBar(title: const Text('Hospedajes')),
      floatingActionButton: (event?.offersLodging ?? true)
          ? FloatingActionButton.extended(
              key: const Key('hosp-nuevo'),
              onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => LodgingFormDialog(eventId: eventId)),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo hospedaje'),
            )
          : null,
      body: event != null && !event.offersLodging
          ? const Center(
              child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Este evento no ofrece hospedaje.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Brand.gris)),
            ))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                  Text(
                      '${lodgings.length} ${lodgings.length == 1 ? 'hospedaje' : 'hospedajes'} · $places plazas · $pending ${pending == 1 ? 'persona' : 'personas'} sin hospedaje',
                      key: const Key('hosp-resumen'),
                      style: const TextStyle(color: Brand.gris)),
                  const SizedBox(height: 12),
                  if (lodgings.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ListToolbar(
                        controller: query,
                        hint: 'Buscar por nombre, anfitrión o zona…',
                        searchKey: const Key('hosp-buscar'),
                        exportKey: const Key('hosp-exportar'),
                        countKey: const Key('hosp-conteo'),
                        onChanged: () => setState(() {}),
                        activeFilters:
                            (accepts != null ? 1 : 0) + (onlyFree ? 1 : 0),
                        count: shown.length == lodgings.length
                            ? '${lodgings.length} hospedajes'
                            : '${shown.length} de ${lodgings.length}',
                        onExport: shown.isEmpty
                            ? null
                            : () => _export(event?.name ?? '', shown),
                        filters: [
                          FilterDropdown<LodgingAccepts>(
                              key: const Key('hosp-filtro-acepta'),
                              label: 'Acepta',
                              value: accepts,
                              options: {
                                for (final a in LodgingAccepts.values)
                                  a: lodgingAcceptsLabel(a)
                              },
                              onChanged: (v) => setState(() => accepts = v)),
                          FilterChip(
                              key: const Key('hosp-filtro-libres'),
                              label: const Text('Solo con plazas libres'),
                              selected: onlyFree,
                              onSelected: (v) => setState(() => onlyFree = v)),
                        ],
                      ),
                    ),
                  if (lodgings.isNotEmpty && pending > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                            key: const Key('hosp-sugerir'),
                            onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                    builder: (_) =>
                                        const LodgingSuggestScreen())),
                            icon: const Icon(Icons.auto_awesome_outlined),
                            label: const Text('Sugerir hospedaje')),
                      ),
                    ),
                  if (lodgings.isEmpty)
                    const Card(
                        child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                                'Todavía no hay hospedajes. Toca «Nuevo hospedaje» para registrar el primero (un albergue o la casa de un anfitrión).',
                                style: TextStyle(
                                    fontSize: 16, color: Brand.gris)))),
                  if (useTables(context))
                    _table(shown)
                  else
                    Wrap(spacing: 12, runSpacing: 12, children: [
                      for (final l in shown)
                        SizedBox(
                          width: 420,
                          child: Card(
                            child: InkWell(
                              key: Key('hosp-${l.row.name}'),
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                      builder: (_) => LodgingDetailScreen(
                                          lodgingId: l.row.id))),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Expanded(
                                            flex: 3,
                                            child: Text(l.row.name,
                                                style: const TextStyle(
                                                    fontSize: 19,
                                                    fontWeight:
                                                        FontWeight.w800))),
                                        const SizedBox(width: 8),
                                        Flexible(
                                            flex: 2,
                                            child: Text(kindLabel(l.row.kind),
                                                textAlign: TextAlign.end,
                                                style: const TextStyle(
                                                    color: Brand.gris))),
                                        _LodgingMenu(l),
                                      ]),
                                      const SizedBox(height: 4),
                                      Text(
                                          '${lodgingAcceptsLabel(lodgingAcceptsFromDb(l.row.accepts))}${l.row.distanceNote.isEmpty ? '' : ' · ${l.row.distanceNote}'}',
                                          style: const TextStyle(
                                              color: Brand.gris)),
                                      const SizedBox(height: 10),
                                      _Occupancy(l.occupied, l.row.capacity),
                                    ]),
                              ),
                            ),
                          ),
                        ),
                    ]),
                ]),
    );
  }
}

class LodgingFormDialog extends ConsumerStatefulWidget {
  const LodgingFormDialog({super.key, required this.eventId, this.lodging});
  final String eventId;
  final LodgingRow? lodging;
  @override
  ConsumerState<LodgingFormDialog> createState() => _LodgingFormDialogState();
}

class _LodgingFormDialogState extends ConsumerState<LodgingFormDialog> {
  late final name = TextEditingController(text: widget.lodging?.name);
  late final capacity =
      TextEditingController(text: widget.lodging?.capacity.toString());
  late final host = TextEditingController(text: widget.lodging?.hostName);
  late final phone = TextEditingController(text: widget.lodging?.contactPhone);
  late final directions =
      TextEditingController(text: widget.lodging?.directions);
  late final near = TextEditingController(text: widget.lodging?.distanceNote);
  late String kind = widget.lodging?.kind ?? 'shelter';
  late LodgingAccepts accepts = widget.lodging == null
      ? LodgingAccepts.men
      : lodgingAcceptsFromDb(widget.lodging!.accepts);
  String? error;

  Future<void> _save() async {
    final c = int.tryParse(capacity.text.trim());
    if (c == null) {
      setState(() => error = 'Falta la capacidad (número de plazas).');
      return;
    }
    try {
      await ref.read(lodgingRepoProvider).save(
          id: widget.lodging?.id,
          eventId: widget.eventId,
          name: name.text,
          kind: kind,
          capacity: c,
          accepts: accepts,
          contactPhone: phone.text,
          directions: directions.text,
          hostName: host.text,
          distanceNote: near.text);
      // Si al cambiar «acepta» alguien ya hospedado dejó de ser compatible, se avisa y se lista
      // (no se quita ni se borra a nadie: se decide en la ficha del hospedaje).
      if (widget.lodging != null) {
        final bad = await ref
            .read(lodgingRepoProvider)
            .incompatibleOccupants(widget.lodging!.id);
        if (bad.isNotEmpty && mounted) {
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: Brand.avisoSuave,
              title: const Text('Hay personas que ya no encajan'),
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '«${name.text.trim()}» ahora es «${lodgingAcceptsLabel(accepts)}». Siguen hospedadas (no se borró nada):',
                        key: const Key('hf-incompatibles')),
                    const SizedBox(height: 6),
                    for (final a in bad.take(12))
                      Text('• ${a.firstName} ${a.lastName1}'),
                    if (bad.length > 12) Text('… y ${bad.length - 12} más'),
                    const SizedBox(height: 6),
                    const Text(
                        'Quítalas desde la ficha del hospedaje o muévelas a otro.'),
                  ]),
              actions: [
                FilledButton(
                    key: const Key('hf-incompatibles-ok'),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Entendido')),
              ],
            ),
          );
        }
      }
      if (mounted) Navigator.pop(context, true);
    } on DataException catch (e) {
      setState(() => error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(
            widget.lodging == null ? 'Nuevo hospedaje' : 'Editar hospedaje'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 440,
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                      key: const Key('lf-nombre'),
                      controller: name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                          labelText: 'Nombre',
                          helperText:
                              'Un albergue o la casa de quien se ofrece')),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'shelter', label: Text('Albergue')),
                      ButtonSegment(
                          value: 'private_home',
                          label: Text('Casa particular')),
                    ],
                    selected: {kind},
                    onSelectionChanged: (s) => setState(() => kind = s.first),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                      key: const Key('lf-capacidad'),
                      controller: capacity,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Capacidad (plazas)')),
                  const SizedBox(height: 12),
                  const Text('Acepta',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  SegmentedButton<LodgingAccepts>(
                    segments: [
                      for (final a in LodgingAccepts.values)
                        ButtonSegment(
                            value: a,
                            label: Text(lodgingAcceptsLabel(a)),
                            icon: null)
                    ],
                    selected: {accepts},
                    onSelectionChanged: (s) =>
                        setState(() => accepts = s.first),
                  ),
                  const SizedBox(height: 12),
                  if (kind == 'private_home') ...[
                    TextField(
                        key: const Key('lf-anfitrion'),
                        controller: host,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                            labelText: 'Anfitrión (opcional)')),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                      key: const Key('lf-telefono'),
                      controller: phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                          labelText: 'Teléfono de contacto (opcional)')),
                  const SizedBox(height: 12),
                  TextField(
                      key: const Key('lf-direccion'),
                      controller: directions,
                      maxLines: 2,
                      decoration: const InputDecoration(
                          labelText: 'Dirección o cómo llegar')),
                  const SizedBox(height: 12),
                  TextField(
                      key: const Key('lf-cerca'),
                      controller: near,
                      decoration: const InputDecoration(
                          labelText: 'Cercanía (opcional)',
                          helperText: 'Ej.: a 300 m del templo')),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    ErrorBox(error!)
                  ],
                ]),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              key: const Key('lf-guardar'),
              onPressed: _save,
              child: const Text('Guardar')),
        ],
      );
}

/// Confirma y elimina (borrado lógico) un hospedaje. Quienes estaban hospedados NO se borran:
/// quedan «sin hospedaje» y vuelven a la lista de pendientes. Devuelve si se eliminó.
Future<bool> confirmDeleteLodging(
    BuildContext context, WidgetRef ref, LodgingView lv) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('¿Eliminar este hospedaje?'),
      content: Text(lv.occupied == 0
          ? '«${lv.row.name}» dejará de aparecer.'
          : '«${lv.row.name}» dejará de aparecer y ${lv.occupied} ${lv.occupied == 1 ? 'persona quedará' : 'personas quedarán'} sin hospedaje (no se borran: pasan a pendientes de hospedaje).'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar')),
        FilledButton(
            key: const Key('hd-confirmar-eliminar'),
            style: FilledButton.styleFrom(backgroundColor: Brand.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar')),
      ],
    ),
  );
  if (ok != true) return false;
  await ref.read(lodgingRepoProvider).delete(lv.row.id);
  return true;
}

/// Menú ⋮ de un hospedaje en la lista: ver, editar y (solo administrador) eliminar.
class _LodgingMenu extends ConsumerWidget {
  const _LodgingMenu(this.lv);
  final LodgingView lv;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(currentUserProvider)?.isAdmin ?? false;
    return PopupMenuButton<String>(
      key: Key('hosp-menu-${lv.row.name}'),
      tooltip: 'Acciones',
      onSelected: (v) async {
        switch (v) {
          case 'ver':
            await Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => LodgingDetailScreen(lodgingId: lv.row.id)));
          case 'editar':
            await showDialog<void>(
                context: context,
                builder: (_) => LodgingFormDialog(
                    eventId: lv.row.eventId, lodging: lv.row));
          case 'eliminar':
            await confirmDeleteLodging(context, ref, lv);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
            key: Key('hosp-ver'), value: 'ver', child: Text('Ver ficha')),
        const PopupMenuItem(
            key: Key('hosp-editar'), value: 'editar', child: Text('Editar…')),
        if (isAdmin)
          const PopupMenuItem(
              key: Key('hosp-eliminar'),
              value: 'eliminar',
              child: Text('Eliminar…')),
      ],
    );
  }
}

class LodgingDetailScreen extends ConsumerWidget {
  const LodgingDetailScreen({super.key, required this.lodgingId});
  final String lodgingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventId = ref.watch(currentEventIdProvider)!;
    final all = ref.watch(lodgingsProvider(eventId)).valueOrNull ??
        const <LodgingView>[];
    final lv = all.where((l) => l.row.id == lodgingId).firstOrNull;
    if (lv == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Hospedaje')),
          body: const Center(child: CircularProgressIndicator()));
    }
    final people = ref.watch(attendeesProvider(eventId)).valueOrNull ??
        const <AttendeeView>[];
    final occupants = people.where((p) => p.a.lodgingId == lodgingId).toList()
      ..sort((a, b) =>
          normalizeText(a.a.lastName1).compareTo(normalizeText(b.a.lastName1)));
    final me = ref.watch(currentUserProvider);
    final l = lv.row;

    return Scaffold(
      appBar: AppBar(title: Text(l.name), actions: [
        IconButton(
            key: const Key('hd-imprimir'),
            tooltip: 'Imprimir lista',
            icon: const Icon(Icons.print_outlined),
            onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => _PrintDialog(
                    lodging: l,
                    occupants: occupants.map((o) => o.a).toList()))),
        IconButton(
            key: const Key('hd-editar'),
            tooltip: 'Editar',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => showDialog<void>(
                context: context,
                builder: (_) =>
                    LodgingFormDialog(eventId: eventId, lodging: l))),
        if (me?.isAdmin ?? false)
          IconButton(
              key: const Key('hd-eliminar'),
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _delete(context, ref, lv)),
      ]),
      body: FutureBuilder<List<AttendeeRow>>(
          future:
              ref.read(lodgingRepoProvider).incompatibleOccupants(lodgingId),
          builder: (context, snap) {
            final bad = {
              for (final a in snap.data ?? const <AttendeeRow>[]) a.id
            };
            return ListView(padding: const EdgeInsets.all(16), children: [
              if (bad.isNotEmpty)
                Card(
                  key: const Key('hd-incompatibles'),
                  color: Brand.avisoSuave,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${bad.length} ${bad.length == 1 ? 'persona ya no es compatible' : 'personas ya no son compatibles'} con «${lodgingAcceptsLabel(lodgingAcceptsFromDb(l.accepts))}»',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Brand.avisoTexto)),
                          const SizedBox(height: 4),
                          const Text(
                              'Siguen aquí (no se borró nada), pero no se podrían volver a asignar. Quítalas de este hospedaje, muévelas a otro o edita el hospedaje para cambiar a quién acepta.'),
                        ]),
                  ),
                ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            '${kindLabel(l.kind)} · ${lodgingAcceptsLabel(lodgingAcceptsFromDb(l.accepts))}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        if (l.hostName != null)
                          Text('Anfitrión: ${l.hostName}'),
                        if (l.contactPhone != null)
                          Text('Contacto: ${l.contactPhone}'),
                        if (l.directions.isNotEmpty)
                          Text('Cómo llegar: ${l.directions}'),
                        if (l.distanceNote.isNotEmpty)
                          Text(l.distanceNote,
                              style: const TextStyle(color: Brand.gris)),
                        const SizedBox(height: 12),
                        _Occupancy(lv.occupied, l.capacity),
                      ]),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                  key: const Key('hd-asignar'),
                  onPressed: () => _assign(context, ref, lv, people),
                  icon: const Icon(Icons.person_add_alt_outlined),
                  label: const Text('Asignar personas')),
              const SizedBox(height: 16),
              Text('Hospedados (${occupants.length})',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              if (occupants.isEmpty)
                const Text('Nadie asignado todavía.',
                    style: TextStyle(color: Brand.gris)),
              for (final o in occupants)
                Card(
                  child: ListTile(
                    key: Key('hd-persona-${o.a.regNumber}'),
                    title: Text(o.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                        '${o.isMale ? 'Hombre' : 'Mujer'} · ${o.a.age} años${o.a.coupleId != null ? ' · matrimonio' : ''}${o.churchName == null ? '' : ' · ${o.churchName}'}${bad.contains(o.a.id) ? ' · NO COMPATIBLE con este hospedaje' : ''}',
                        style: bad.contains(o.a.id)
                            ? const TextStyle(color: Brand.error)
                            : null),
                    trailing: IconButton(
                        key: Key('hd-quitar-${o.a.regNumber}'),
                        tooltip: 'Quitar de este hospedaje',
                        icon: const Icon(Icons.close),
                        onPressed: () =>
                            ref.read(lodgingRepoProvider).unassign([o.a.id])),
                  ),
                ),
            ]);
          }),
    );
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, LodgingView lv) async {
    if (await confirmDeleteLodging(context, ref, lv) && context.mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _assign(BuildContext context, WidgetRef ref, LodgingView lv,
      List<AttendeeView> people) async {
    final spouses =
        await ref.read(socialRepoProvider).spouseMap(lv.row.eventId);
    if (!context.mounted) return;
    final chosen = await showDialog<List<AttendeeView>>(
      context: context,
      builder: (_) =>
          _AssignDialog(lodging: lv, people: people, spouses: spouses),
    );
    if (chosen == null || chosen.isEmpty || !context.mounted) return;
    final here = people
        .where((p) => p.a.lodgingId == lv.row.id)
        .map((p) => p.a.toPersonRef(spouses[p.a.id]))
        .toList();
    final chosenRefs =
        chosen.map((p) => p.a.toPersonRef(spouses[p.a.id])).toList();
    // Compatibilidad = BLOQUEO (sin «asignar de todas formas»): hay que editar el hospedaje.
    final blockers = lodgingBlockers(lv.slot, chosenRefs, alreadyThere: here);
    if (blockers.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Brand.avisoSuave,
          icon: const Icon(Icons.block, color: Brand.error, size: 36),
          title: const Text('No se puede asignar'),
          content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final w in blockers)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(w.message, key: const Key('hd-bloqueo'))),
                const Text(
                    'Para hospedarlos aquí, edita el hospedaje y cambia a quién acepta; o elige otro.',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ]),
          actions: [
            FilledButton(
                key: const Key('hd-bloqueo-ok'),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Entendido')),
          ],
        ),
      );
      return;
    }
    // La capacidad sí es un aviso: la persona decide.
    final warnings =
        checkLodgingAssignment(lv.slot, chosenRefs, alreadyThere: here);
    if (warnings.isNotEmpty) {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Brand.avisoSuave,
          icon: const Icon(Icons.warning_amber_rounded,
              color: Brand.avisoTexto, size: 36),
          title: const Text('Atención'),
          content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final w in warnings)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(w.message, key: const Key('hd-aviso'))),
                const Text('Puedes continuar si es necesario.',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ]),
          actions: [
            TextButton(
                key: const Key('hd-revisar'),
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Revisar')),
            FilledButton(
                key: const Key('hd-continuar'),
                style: FilledButton.styleFrom(
                    backgroundColor: Brand.aviso, foregroundColor: Brand.tinta),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Asignar de todas formas')),
          ],
        ),
      );
      if (go != true) return;
    }
    try {
      await ref
          .read(lodgingRepoProvider)
          .assign(lv.row.id, chosen.map((p) => p.a.id));
    } on DataException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

class _AssignDialog extends ConsumerStatefulWidget {
  const _AssignDialog(
      {required this.lodging, required this.people, required this.spouses});
  final LodgingView lodging;
  final List<AttendeeView> people;
  final Map<String, String> spouses;
  @override
  ConsumerState<_AssignDialog> createState() => _AssignDialogState();
}

class _AssignDialogState extends ConsumerState<_AssignDialog> {
  final q = TextEditingController();
  final sel = <String>{};
  bool onlyPending = true;

  AttendeeView? _byId(String id) =>
      widget.people.where((p) => p.a.id == id).firstOrNull;

  /// Marcar/desmarcar a una persona arrastra a su cónyuge (siempre juntos en un hospedaje).
  void _toggle(AttendeeView v, bool on) {
    final ids = {
      v.a.id,
      if (widget.spouses[v.a.id] != null) widget.spouses[v.a.id]!
    };
    setState(() => on ? sel.addAll(ids) : sel.removeAll(ids));
  }

  /// ¿Esta persona puede entrar en este hospedaje? (sexo; en uno de matrimonios, con cónyuge).
  bool _fits(AttendeeView v) => lodgingFitsPerson(
      lodgingAcceptsFromDb(widget.lodging.row.accepts),
      v.isMale ? Sex.male : Sex.female,
      hasSpouse: widget.spouses[v.a.id] != null);

  Future<void> _addGroup() async {
    final eventId = widget.lodging.row.eventId;
    final groups =
        ref.read(groupsProvider(eventId)).valueOrNull ?? const <GroupView>[];
    final g = await showDialog<GroupView>(
      context: context,
      builder: (ctx) => SimpleDialog(
          title: const Text('Añadir un grupo completo'),
          children: [
            if (groups.isEmpty)
              const Padding(
                  padding: EdgeInsets.all(16), child: Text('No hay grupos.')),
            for (final g in groups)
              SimpleDialogOption(
                  key: Key('as-grupo-${g.group.name}'),
                  onPressed: () => Navigator.pop(ctx, g),
                  child: Text('${g.group.name} (${g.memberCount})')),
          ]),
    );
    if (g == null) return;
    final members = await ref.read(socialRepoProvider).groupMembers(g.group.id);
    setState(() {
      for (final m in members) {
        final v = _byId(m.id);
        if (v != null && _fits(v)) _toggle(v, true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Suscripción activa: así los grupos ya están cargados al pulsar «Añadir un grupo completo».
    ref.watch(groupsProvider(widget.lodging.row.eventId));
    final elig = widget.people
        .where((p) =>
            p.a.lodgingId != widget.lodging.row.id &&
            (!onlyPending || (p.a.needsLodging && p.a.lodgingId == null)))
        .toList();
    final list = Repository.search(elig, q.text).take(40).toList();
    final free = widget.lodging.free;
    return AlertDialog(
      title: const Text('Asignar personas'),
      content: SizedBox(
        width: 460,
        height: 480,
        child: Column(children: [
          TextField(
              key: const Key('as-buscar'),
              controller: q,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                  hintText: 'Buscar por nombre, iglesia o número…',
                  prefixIcon: Icon(Icons.search))),
          SwitchListTile(
              key: const Key('as-solo-pendientes'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Solo quienes necesitan hospedaje y no tienen'),
              value: onlyPending,
              onChanged: (v) => setState(() => onlyPending = v)),
          Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                  key: const Key('as-grupo'),
                  onPressed: _addGroup,
                  icon: const Icon(Icons.groups_outlined),
                  label: const Text('Añadir un grupo completo'))),
          Expanded(
            child: list.isEmpty
                ? const Center(
                    child: Text('Nadie por asignar con ese filtro.',
                        style: TextStyle(color: Brand.gris)))
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final v = list[i];
                      final sp = widget.spouses[v.a.id];
                      final fits = _fits(v);
                      return CheckboxListTile(
                        key: Key('as-${v.a.regNumber}'),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: sel.contains(v.a.id),
                        onChanged:
                            fits ? (on) => _toggle(v, on ?? false) : null,
                        title: Text(v.fullName,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                            '${v.isMale ? 'Hombre' : 'Mujer'} · ${v.a.age} años${sp != null ? ' · con su cónyuge' : ''}${v.a.lodgingId != null ? ' · ya tiene hospedaje' : ''}${fits ? '' : ' · no compatible con «${lodgingAcceptsLabel(lodgingAcceptsFromDb(widget.lodging.row.accepts))}»'}'),
                      );
                    },
                  ),
          ),
          const Divider(),
          Text(
              '${sel.length} ${sel.length == 1 ? 'seleccionada' : 'seleccionadas'} · plazas libres: ${free < 0 ? 0 : free}',
              key: const Key('as-resumen'),
              style: const TextStyle(color: Brand.gris)),
        ]),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(
            key: const Key('as-confirmar'),
            onPressed: sel.isEmpty
                ? null
                : () => Navigator.pop(context, [
                      for (final id in sel)
                        if (_byId(id) != null) _byId(id)!
                    ]),
            child: const Text('Asignar')),
      ],
    );
  }
}

class _PrintDialog extends ConsumerStatefulWidget {
  const _PrintDialog({required this.lodging, required this.occupants});
  final LodgingRow lodging;
  final List<AttendeeRow> occupants;
  @override
  ConsumerState<_PrintDialog> createState() => _PrintDialogState();
}

class _PrintDialogState extends ConsumerState<_PrintDialog> {
  bool phone = false;
  bool busy = false;

  Future<Uint8List> _bytes() async {
    final eventId = ref.read(currentEventIdProvider)!;
    final event = await ref.read(repositoryProvider).watchEvent(eventId).first;
    final churches = await ref.read(churchesProvider.future);
    return buildLodgingPdf(
      eventName: event.name,
      eventDates: 'del ${event.startDate} al ${event.endDate}',
      lodging: widget.lodging,
      occupants: widget.occupants,
      churchNames: {for (final c in churches) c.id: c.name},
      includePhone: phone,
    );
  }

  Future<void> _run(Future<void> Function(Uint8List) action) async {
    setState(() => busy = true);
    try {
      await action(await _bytes());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('Lista de ${widget.lodging.name}'),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  '${widget.occupants.length} ${widget.occupants.length == 1 ? 'persona' : 'personas'}. Se imprime ordenada por apellido, con cómo llegar y el pie «uso exclusivo del anfitrión».'),
              CheckboxListTile(
                  key: const Key('pr-telefono'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: phone,
                  onChanged: (v) => setState(() => phone = v ?? false),
                  title: const Text('Incluir teléfono de cada persona'),
                  subtitle: const Text('Por defecto no se imprime')),
            ]),
        actions: [
          TextButton(
              onPressed: busy ? null : () => Navigator.pop(context),
              child: const Text('Cerrar')),
          OutlinedButton.icon(
              key: const Key('pr-pdf'),
              onPressed: busy
                  ? null
                  : () => _run((b) => Printing.sharePdf(
                      bytes: b,
                      filename: 'Lista - ${widget.lodging.name}.pdf')),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Guardar como PDF')),
          FilledButton.icon(
              key: const Key('pr-imprimir'),
              onPressed: busy
                  ? null
                  : () => _run((b) => Printing.layoutPdf(
                      onLayout: (_) async => b,
                      name: 'Lista - ${widget.lodging.name}')),
              icon: const Icon(Icons.print_outlined),
              label: const Text('Imprimir')),
        ],
      );
}
