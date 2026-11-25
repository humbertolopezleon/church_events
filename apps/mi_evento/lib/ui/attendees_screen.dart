import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:material_ui/material_ui.dart';

import 'package:mi_evento_core/mi_evento_core.dart'
    show normalizeText, parseCsv;

import '../data/database.dart';
import '../data/repos_b.dart';

import '../data/list_filters.dart';
import '../data/repository.dart';
import '../data/attendee_exchange.dart';
import '../export/csv_export.dart';
import 'csv_spec_ui.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import 'attendee_form.dart';
import 'widgets/data_table_view.dart';
import 'widgets/highlight_text.dart';
import 'widgets/list_toolbar.dart';
import 'csv_import.dart';
import 'teams_screen.dart' show teamColor;
import 'widgets/app_fab.dart';
import 'widgets/app_header.dart';
import 'widgets/filter_spec.dart';
import 'widgets/plural.dart';

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

  @override
  void initState() {
    super.initState();
    final preset = ref.read(attendeesPresetLodgingProvider);
    if (preset != null) {
      lodgingStatus = preset;
      Future.microtask(
          () => ref.read(attendeesPresetLodgingProvider.notifier).state = null);
    }
  }

  AttendeeFilter get _filter => AttendeeFilter(
      sex: sex,
      churchId: churchId,
      lodging: lodgingStatus,
      team: teamStatus,
      lodgingId: lodgingId,
      teamId: teamId,
      preregistered: preregistered);

  void _edit(AttendeeView v) =>
      Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => AttendeeFormScreen(attendeeId: v.a.id)));

  Future<void> _setAttendance(
      String eventId, AttendeeView v, bool confirm) async {
    final repo = ref.read(repositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (confirm) {
        await repo.confirmAttendance([v.a.id]);
      } else {
        await repo.unconfirmAttendance([v.a.id]);
      }
      ref.read(autoBackupProvider).noteChange(eventId);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
            content: Text(confirm
                ? 'Asistencia de ${v.fullName} confirmada.'
                : 'Asistencia de ${v.fullName} desconfirmada.')));
    } on DataException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /// Menú ⋮ de cada persona: ver/editar y confirmar o desconfirmar su asistencia.
  Widget _menu(String eventId, AttendeeView v) => PopupMenuButton<String>(
        key: Key('asis-menu-${v.a.regNumber}'),
        tooltip: 'Acciones',
        onSelected: (a) {
          switch (a) {
            case 'editar':
              _edit(v);
            case 'confirmar':
              _setAttendance(eventId, v, true);
            case 'desconfirmar':
              _setAttendance(eventId, v, false);
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(
              key: Key('asis-editar'),
              value: 'editar',
              child: Text('Ver / editar')),
          if (v.isPreregistered)
            const PopupMenuItem(
                key: Key('asis-confirmar'),
                value: 'confirmar',
                child: Text('Confirmar asistencia'))
          else
            const PopupMenuItem(
                key: Key('asis-desconfirmar'),
                value: 'desconfirmar',
                child: Text('Desconfirmar asistencia')),
        ],
      );

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
  Widget _table(String eventId, List<AttendeeView> list,
      List<LodgingView> lodgings, List<TeamRow> teams) {
    final lodgingName = {for (final l in lodgings) l.row.id: l.row.name};
    final teamName = {for (final t in teams) t.id: t.name};
    final offersTeams =
        ref.read(eventProvider(eventId)).valueOrNull?.offersTeams ?? true;
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
            (v) => HighlightText(v.fullName, query.text,
                key: Key('asistente-${v.a.regNumber}'),
                style: const TextStyle(fontWeight: FontWeight.w700)),
            sortValue: (v) => normalizeText(v.fullName)),
        TableCol('Sexo', (v) => txt(v.isMale ? 'Hombre' : 'Mujer'),
            sortValue: (v) => v.a.sex),
        TableCol('Edad', (v) => txt('${v.a.age}'),
            numeric: true, sortValue: (v) => v.a.age),
        TableCol(
            'Iglesia', (v) => HighlightText(v.churchName ?? '—', query.text),
            sortValue: (v) => normalizeText(v.churchName ?? '')),
        TableCol(
            'Hospedaje',
            (v) => txt(v.a.lodgingId != null
                ? (lodgingName[v.a.lodgingId] ?? '—')
                : v.a.needsLodging
                    ? 'Sin asignar'
                    : '—'),
            sortValue: (v) => normalizeText(lodgingName[v.a.lodgingId] ?? '~')),
        if (offersTeams)
          TableCol('Equipo', (v) => txt(teamName[v.a.teamId] ?? '—'),
              sortValue: (v) => normalizeText(teamName[v.a.teamId] ?? '~')),
        TableCol(
            'Asistencia',
            (v) => v.isPreregistered
                ? Chip(
                    key: Key('preinscrito-${v.a.regNumber}'),
                    label: const Text('Preinscrito'),
                    visualDensity: VisualDensity.compact)
                : v.a.registeredAtControl
                    ? Chip(
                        key: Key('reg-control-${v.a.regNumber}'),
                        label: const Text('Registrado en comidas'),
                        visualDensity: VisualDensity.compact)
                    : const Text('Confirmada'),
            sortValue: (v) => v.isPreregistered ? 0 : 1),
        TableCol('', (v) => _menu(eventId, v)),
      ],
    );
  }

  Future<void> _importFile() async {
    final f = await ref.read(filePickProvider).pick();
    if (f == null || !mounted) return;
    await importAttendeesCsv(context, ref, f.bytes);
  }

  /// Tarjeta de una persona: nombre, «Nº · iglesia», «edad · hospedaje» (etiqueta ámbar si falta asignarlo),
  /// chip de preinscrito, cuadrado del color del equipo y menú ⋮.
  Widget _card(String eventId, AttendeeView v, bool offersLodging,
      Map<String, String> lodgingName, Map<String, TeamRow> teamById) {
    final team = v.a.teamId == null ? null : teamById[v.a.teamId];
    final meta = bodyStyle(14, color: Brand.gris);
    Widget lodging() {
      if (v.a.lodgingId != null) {
        return Text('· ${lodgingName[v.a.lodgingId] ?? 'Con hospedaje'}',
            maxLines: 1, overflow: TextOverflow.ellipsis, style: meta);
      }
      if (v.a.needsLodging) {
        return Container(
          key: Key('sin-hospedaje-${v.a.regNumber}'),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
              color: Brand.avisoSuave, borderRadius: BorderRadius.circular(8)),
          child: Text('Sin hospedaje',
              style: bodyStyle(14,
                  color: Brand.avisoTexto, weight: FontWeight.w700)),
        );
      }
      return offersLodging
          ? Text('· No necesita hospedaje',
              maxLines: 1, overflow: TextOverflow.ellipsis, style: meta)
          : const SizedBox.shrink();
    }

    return Card(
      child: InkWell(
        key: Key('asistente-${v.a.regNumber}'),
        borderRadius: BorderRadius.circular(16),
        onTap: () => _edit(v),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
          child: Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HighlightText(v.fullName, query.text,
                        style: bodyStyle(17, weight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                        'Nº ${v.a.regNumber}${v.churchName == null ? '' : ' · ${v.churchName}'}',
                        key: Key('asis-numero-${v.a.regNumber}'),
                        style: meta),
                    const SizedBox(height: 2),
                    Row(children: [
                      Text(plural(v.a.age, 'año', 'años'), style: meta),
                      const SizedBox(width: 6),
                      Flexible(child: lodging()),
                    ]),
                    if (v.isPreregistered)
                      Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Chip(
                              key: Key('preinscrito-${v.a.regNumber}'),
                              label: const Text('Preinscrito'),
                              visualDensity: VisualDensity.compact))
                    else if (v.a.registeredAtControl)
                      Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Chip(
                              key: Key('reg-control-${v.a.regNumber}'),
                              label: const Text('Registrado en comidas'),
                              visualDensity: VisualDensity.compact)),
                  ]),
            ),
            if (team != null)
              Semantics(
                label: 'Equipo ${team.name}',
                child: Container(
                  key: Key('equipo-color-${v.a.regNumber}'),
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                      color: teamColor(team.color),
                      borderRadius: BorderRadius.circular(3)),
                ),
              ),
            _menu(eventId, v),
          ]),
        ),
      ),
    );
  }

  /// Sin asistentes: se oculta buscador, filtros y botón flotante, y se invita a registrar o
  /// traer una lista en CSV.
  Widget _empty(String eventId) => Scaffold(
        appBar: AppHeader(
          title: 'Asistentes',
          subtitle: 'Nadie inscrito todavía',
          importKey: const Key('asis-importar'),
          onImport: _importFile,
          onExport: () {},
          onTemplate: () => saveCsvTemplate(context, ref, attendeeCsvSpec),
          onColumns: () => showCsvColumnsHelp(context, ref),
          templateKey: const Key('asis-plantilla'),
          columnsKey: const Key('asis-columnas'),
          exportEnabled: false,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                      color: Brand.azulSuave, shape: BoxShape.circle),
                  child: const Icon(Icons.person_add_alt_1,
                      size: 44, color: Brand.azul),
                ),
                const SizedBox(height: 20),
                Text('Todavía no hay asistentes',
                    key: const Key('asis-vacio'),
                    textAlign: TextAlign.center,
                    style: headStyle(24, color: Brand.tinta)),
                const SizedBox(height: 8),
                Text(
                    'Registra a la primera persona o trae una lista que ya tengas en un archivo CSV.',
                    textAlign: TextAlign.center,
                    style: bodyStyle(18, color: Brand.gris)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                      key: const Key('asis-vacio-registrar'),
                      onPressed: () => openRegister(context),
                      child: const Text('Registrar primera persona')),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                      key: const Key('asis-vacio-importar'),
                      onPressed: _importFile,
                      child: const Text('Importar lista desde CSV')),
                ),
                const SizedBox(height: 8),
                TextButton(
                    key: const Key('asis-vacio-ayuda'),
                    onPressed: () => showCsvColumnsHelp(context, ref),
                    child: const Text('¿Qué columnas debe tener el CSV?')),
              ]),
            ),
          ),
        ),
      );

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
    final offersLodging =
        ref.watch(eventProvider(eventId)).valueOrNull?.offersLodging ?? true;
    final lodgingName = {for (final l in lodgings) l.row.id: l.row.name};
    final teamById = {for (final t in teams) t.id: t};
    final list =
        _filter.apply(Repository.search(all, query.text, includeChurch: false));
    final filtering = query.text.isNotEmpty || !_filter.isEmpty;
    if (all.isEmpty) {
      return CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyN, control: true): () =>
              openRegister(context),
        },
        child: Focus(autofocus: true, child: _empty(eventId)),
      );
    }
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () =>
            openRegister(context),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppHeader(
            title: 'Asistentes',
            subtitle: plural(all.length, 'inscrito', 'inscritos',
                zero: 'Nadie inscrito todavía'),
            importKey: const Key('asis-importar'),
            onImport: () async {
              final f = await ref.read(filePickProvider).pick();
              if (f == null || !context.mounted) return;
              await importAttendeesCsv(context, ref, f.bytes);
            },
            onExport: () => _export(eventId, list),
            exportEnabled: list.isNotEmpty,
            onTemplate: () => saveCsvTemplate(context, ref, attendeeCsvSpec),
            onColumns: () => showCsvColumnsHelp(context, ref),
            templateKey: const Key('asis-plantilla'),
            columnsKey: const Key('asis-columnas'),
          ),
          floatingActionButton: AppFab(
            key: const Key('asis-registrar'),
            tooltip: 'Registrar persona (Ctrl+N)',
            accent: true,
            onPressed: () => openRegister(context),
            icon: Icons.add,
            label: 'Registrar',
          ),
          body: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: ListToolbar(
                controller: query,
                hint: 'Nombre o número',
                onChanged: () => setState(() {}),
                count: filtering
                    ? '${list.length} de ${all.length} · más recientes primero'
                    : 'Más recientes primero',
                resultCount: () => _filter
                    .apply(Repository.search(all, query.text,
                        includeChurch: false))
                    .length,
                resultLabel: (n) => n == 0
                    ? 'Nadie coincide con estos filtros'
                    : 'Ver ${plural(n, 'asistente', 'asistentes')}',
                filters: () => [
                  ChoiceFilter<bool>(
                      key: const Key('filtro-asistencia'),
                      label: 'Asistencia',
                      value: preregistered,
                      options: const {
                        false: 'Confirmados',
                        true: 'Por confirmar'
                      },
                      onChanged: (v) => setState(() => preregistered = v)),
                  ChoiceFilter<String>(
                      key: const Key('filtro-sexo'),
                      label: 'Sexo',
                      value: sex,
                      options: const {'M': 'Hombres', 'F': 'Mujeres'},
                      onChanged: (v) => setState(() => sex = v)),
                  ChoiceFilter<LodgingStatus>(
                      key: const Key('filtro-hospedaje-estado'),
                      label: 'Hospedaje',
                      value: lodgingStatus,
                      options: const {
                        LodgingStatus.assigned: 'Con hospedaje',
                        LodgingStatus.pending: 'Necesita y no tiene',
                        LodgingStatus.notNeeded: 'No necesita',
                      },
                      onChanged: (v) => setState(() => lodgingStatus = v)),
                  ChoiceFilter<String>(
                      key: const Key('filtro-iglesia'),
                      label: 'Iglesia',
                      allLabel: 'Todas',
                      wide: true,
                      value: churchId,
                      options: {
                        for (final e
                            in churches.entries.toList()
                              ..sort((a, b) => a.value.compareTo(b.value)))
                          e.key: e.value
                      },
                      onChanged: (v) => setState(() => churchId = v)),
                  if (lodgings.isNotEmpty)
                    ChoiceFilter<String>(
                        key: const Key('filtro-hospedaje'),
                        label: 'En el hospedaje',
                        wide: true,
                        value: lodgingId,
                        options: {
                          for (final l in lodgings) l.row.id: l.row.name
                        },
                        onChanged: (v) => setState(() => lodgingId = v)),
                  if (teams.isNotEmpty)
                    ChoiceFilter<String>(
                        key: const Key('filtro-equipo'),
                        label: 'Equipo',
                        wide: true,
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
                            style: const TextStyle(
                                fontSize: 18, color: Brand.gris)),
                      ),
                    )
                  : useTables(context)
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                          child: _table(eventId, list, lodgings, teams))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                          itemCount: list.length,
                          itemBuilder: (_, i) {
                            final v = list[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _card(eventId, v, offersLodging,
                                  lodgingName, teamById),
                            );
                          },
                        ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Abre el formulario de registro de una persona nueva (botón «Registrar persona» y Ctrl+N).
Future<void> openRegister(BuildContext context) => Navigator.of(context)
    .push(MaterialPageRoute<void>(builder: (_) => const AttendeeFormScreen()));

/// Qué columnas espera el importador de asistentes (las reales de `attendeeCsvHeaders`).
Future<void> showCsvColumnsHelp(BuildContext context, WidgetRef ref) =>
    showCsvSpecDialog(context, ref, attendeeCsvSpec,
        dialogKey: const Key('asis-ayuda-csv'),
        templateKey: const Key('asis-ayuda-plantilla'));
