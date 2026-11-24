import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:mi_evento_core/mi_evento_core.dart'
    show normalizeText, parseCsv;

import '../data/database.dart';
import '../data/repos_b.dart';

import '../data/list_filters.dart';
import '../data/repository.dart';
import '../export/csv_export.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import 'attendee_form.dart';
import 'widgets/data_table_view.dart';
import 'widgets/list_toolbar.dart';

/// Lista de asistentes: búsqueda (nombre en cualquier orden, iglesia o número), filtros y exportación a CSV.
class AttendeesScreen extends ConsumerStatefulWidget {
  const AttendeesScreen({super.key});
  @override
  ConsumerState<AttendeesScreen> createState() => _AttendeesScreenState();
}

class _AttendeesScreenState extends ConsumerState<AttendeesScreen> {
  final query = TextEditingController();
  String? sex, churchId, lodgingId, teamId;
  LodgingStatus? lodgingStatus;
  TeamStatus? teamStatus;
  bool? preregistered;

  AttendeeFilter get _filter => AttendeeFilter(
      sex: sex,
      churchId: churchId,
      lodging: lodgingStatus,
      team: teamStatus,
      lodgingId: lodgingId,
      teamId: teamId,
      preregistered: preregistered);

  Future<void> _export(String eventId, List<AttendeeView> shown) async {
    final ev = ref.read(eventProvider(eventId)).valueOrNull;
    final text = await ref
        .read(attendeeExchangeProvider)
        .exportCsv(eventId, onlyIds: {for (final v in shown) v.a.id});
    if (!mounted) return;
    await saveCsv(context, ref,
        name: csvFileName('asistentes', ev?.name), rows: parseCsv(text));
  }

  /// Vista de escritorio: tabla con columnas ordenables (el móvil sigue con tarjetas).
  Widget _table(List<AttendeeView> list, List<LodgingView> lodgings,
      List<TeamRow> teams) {
    final lodgingName = {for (final l in lodgings) l.row.id: l.row.name};
    final teamName = {for (final t in teams) t.id: t.name};
    Widget txt(String s) => Text(s, overflow: TextOverflow.ellipsis);
    return DataTableView<AttendeeView>(
      items: list,
      onTap: (v) => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => AttendeeFormScreen(attendeeId: v.a.id))),
      columns: [
        TableCol('Nº', (v) => txt('${v.a.regNumber}'),
            numeric: true, sortValue: (v) => v.a.regNumber),
        TableCol(
            'Nombre',
            (v) => Text(v.fullName,
                key: Key('asistente-${v.a.regNumber}'),
                style: const TextStyle(fontWeight: FontWeight.w700)),
            sortValue: (v) => normalizeText(v.fullName)),
        TableCol('Sexo', (v) => txt(v.isMale ? 'Hombre' : 'Mujer'),
            sortValue: (v) => v.a.sex),
        TableCol('Edad', (v) => txt('${v.a.age}'),
            numeric: true, sortValue: (v) => v.a.age),
        TableCol('Iglesia', (v) => txt(v.churchName ?? '—'),
            sortValue: (v) => normalizeText(v.churchName ?? '')),
        TableCol(
            'Hospedaje',
            (v) => txt(v.a.lodgingId != null
                ? (lodgingName[v.a.lodgingId] ?? '—')
                : v.a.needsLodging
                    ? 'Sin asignar'
                    : '—'),
            sortValue: (v) => normalizeText(lodgingName[v.a.lodgingId] ?? '~')),
        TableCol('Equipo', (v) => txt(teamName[v.a.teamId] ?? '—'),
            sortValue: (v) => normalizeText(teamName[v.a.teamId] ?? '~')),
        TableCol(
            'Asistencia',
            (v) => v.isPreregistered
                ? Chip(
                    key: Key('preinscrito-${v.a.regNumber}'),
                    label: const Text('Preinscrito'),
                    visualDensity: VisualDensity.compact)
                : const Text('Confirmada'),
            sortValue: (v) => v.isPreregistered ? 0 : 1),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventId = ref.watch(currentEventIdProvider)!;
    final all = ref.watch(attendeesProvider(eventId)).valueOrNull ??
        const <AttendeeView>[];
    final churches = <String, String>{
      for (final v in all)
        if (v.a.churchId != null && v.churchName != null)
          v.a.churchId!: v.churchName!
    };
    final lodgings =
        ref.watch(lodgingsProvider(eventId)).valueOrNull ?? const [];
    final teams = ref.watch(teamsProvider(eventId)).valueOrNull ?? const [];
    final list = _filter.apply(Repository.search(all, query.text));
    final filtering = query.text.isNotEmpty || !_filter.isEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('Asistentes')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: ListToolbar(
            controller: query,
            hint: 'Buscar por nombre, iglesia o número…',
            onChanged: () => setState(() {}),
            activeFilters: [
              sex,
              churchId,
              lodgingId,
              teamId,
              lodgingStatus,
              teamStatus,
              preregistered
            ].where((f) => f != null).length,
            count: filtering
                ? '${list.length} de ${all.length}'
                : '${all.length} inscritos',
            onExport: list.isEmpty ? null : () => _export(eventId, list),
            filters: [
              FilterDropdown<bool>(
                  key: const Key('filtro-asistencia'),
                  label: 'Asistencia',
                  value: preregistered,
                  options: const {false: 'Confirmados', true: 'Preinscritos'},
                  onChanged: (v) => setState(() => preregistered = v)),
              FilterDropdown<String>(
                  key: const Key('filtro-sexo'),
                  label: 'Sexo',
                  value: sex,
                  options: const {'M': 'Hombres', 'F': 'Mujeres'},
                  onChanged: (v) => setState(() => sex = v)),
              FilterDropdown<String>(
                  key: const Key('filtro-iglesia'),
                  label: 'Iglesia',
                  value: churchId,
                  options: {
                    for (final e
                        in churches.entries.toList()
                          ..sort((a, b) => a.value.compareTo(b.value)))
                      e.key: e.value
                  },
                  onChanged: (v) => setState(() => churchId = v)),
              FilterDropdown<LodgingStatus>(
                  key: const Key('filtro-hospedaje-estado'),
                  label: 'Hospedaje',
                  value: lodgingStatus,
                  options: const {
                    LodgingStatus.assigned: 'Con hospedaje',
                    LodgingStatus.pending: 'Necesita y no tiene',
                    LodgingStatus.notNeeded: 'No necesita',
                  },
                  onChanged: (v) => setState(() => lodgingStatus = v)),
              if (lodgings.isNotEmpty)
                FilterDropdown<String>(
                    key: const Key('filtro-hospedaje'),
                    label: 'En el hospedaje',
                    value: lodgingId,
                    options: {for (final l in lodgings) l.row.id: l.row.name},
                    onChanged: (v) => setState(() => lodgingId = v)),
              if (teams.isNotEmpty)
                FilterDropdown<String>(
                    key: const Key('filtro-equipo'),
                    label: 'Equipo',
                    value: teamId,
                    options: {for (final t in teams) t.id: t.name},
                    onChanged: (v) => setState(() => teamId = v)),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                        all.isEmpty
                            ? 'Todavía no hay nadie inscrito.'
                            : filtering
                                ? 'Nadie coincide con la búsqueda y los filtros. ¿Falta registrarlo?'
                                : 'Nadie coincide. ¿Falta registrarlo?',
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(fontSize: 18, color: Brand.gris)),
                  ),
                )
              : useTables(context)
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: _table(list, lodgings, teams))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final v = list[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Card(
                            child: ListTile(
                              key: Key('asistente-${v.a.regNumber}'),
                              minVerticalPadding: 10,
                              leading: CircleAvatar(
                                  backgroundColor: Brand.naranjaSuave,
                                  foregroundColor: const Color(0xFF8F4512),
                                  child: Text(v.initials,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700))),
                              title: Text(v.fullName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 17)),
                              subtitle: Text(
                                  'Nº ${v.a.regNumber} · ${v.isMale ? 'Hombre' : 'Mujer'} · ${v.a.age} años${v.churchName == null ? '' : ' · ${v.churchName}'}'),
                              trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (v.isPreregistered)
                                      Chip(
                                          key: Key(
                                              'preinscrito-${v.a.regNumber}'),
                                          label: const Text('Preinscrito'),
                                          visualDensity: VisualDensity.compact),
                                    if (v.a.needsLodging)
                                      const Padding(
                                          padding: EdgeInsets.only(left: 6),
                                          child: Icon(Icons.house_outlined,
                                              color: Brand.azul)),
                                  ]),
                              onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                      builder: (_) => AttendeeFormScreen(
                                          attendeeId: v.a.id))),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ]),
    );
  }
}
