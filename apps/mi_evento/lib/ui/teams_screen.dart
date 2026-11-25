import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import '../auth/auth_service.dart';
import '../data/database.dart';
import '../data/list_filters.dart';
import '../export/csv_export.dart';
import '../data/repos_b.dart';
import '../data/repository.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import 'auth_screens.dart' show ErrorBox;
import 'widgets/data_table_view.dart';
import 'widgets/list_toolbar.dart';
import 'people_pickers.dart';
import 'team_generate_screen.dart';
import 'widgets/input_formats.dart';
import '../data/team_exchange.dart';
import 'table_import_flow.dart';
import 'widgets/app_header.dart';
import 'widgets/plural.dart';

Color teamColor(String? hex) {
  if (hex == null || hex.length != 7) return Brand.gris;
  return Color(int.parse('FF${hex.substring(1)}', radix: 16));
}

String _n(double v) => v.toStringAsFixed(1);

/// Resultado de simular un cambio de equipo antes de confirmarlo.
class MovePreview {
  MovePreview(this.before, this.after, this.issues, this.affected);
  final List<TeamStats> before;
  final List<TeamStats> after;
  final List<BalanceIssue> issues;
  final Set<String> affected;
}

/// Simula mover personas (id → equipo destino, null = sin equipo). No modifica nada.
MovePreview previewMoves({
  required List<TeamRow> teams,
  required List<AttendeeRow> people,
  required Map<String, String?> moves,
  required BalanceLimits limits,
}) {
  TeamStats stats(List<AttendeeRow> ps, TeamRow t) => TeamStats.of(
      t.id, t.name, ps.where((p) => p.teamId == t.id).map((p) => p.toCore()));
  final before = [for (final t in teams) stats(people, t)];
  final fixed = [
    for (final p in people)
      moves.containsKey(p.id) ? _withTeam(p, moves[p.id]) : p,
  ];
  final after = [for (final t in teams) stats(fixed, t)];
  final affected = <String>{};
  for (final id in moves.keys) {
    final from = people.firstWhere((p) => p.id == id).teamId;
    final to = moves[id];
    if (from != null) affected.add(from);
    if (to != null) affected.add(to);
  }
  return MovePreview(before, after, evaluateBalance(after, limits), affected);
}

AttendeeRow _withTeam(AttendeeRow p, String? teamId) =>
    p.copyWith(teamId: Value(teamId));

/// Texto de búsqueda de la pantalla de equipos (nombre del equipo o de un miembro).
final teamQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// CSV de los equipos: una fila por persona («Sin equipo» incluido). Con búsqueda solo salen los
/// equipos mostrados.
Future<void> _exportTeams(BuildContext context, WidgetRef ref,
    {required List<TeamRow> teams,
    required List<AttendeeView> people,
    required String eventName,
    required String query}) {
  final names = {for (final t in teams) t.id: t.name};
  final q = query.trim();
  final rows = <List<String>>[];
  for (final v in people) {
    final team = v.a.teamId == null ? null : names[v.a.teamId];
    if (v.a.teamId != null && team == null) continue;
    if (v.a.teamId == null && q.isNotEmpty) continue;
    rows.add([
      team ?? 'Sin equipo',
      '${v.a.regNumber}',
      v.fullName,
      v.isMale ? 'Hombre' : 'Mujer',
      '${v.a.age}',
      v.churchName ?? '',
    ]);
  }
  rows.sort((a, b) => a[0] == b[0]
      ? int.parse(a[1]).compareTo(int.parse(b[1]))
      : a[0].compareTo(b[0]));
  return saveCsv(context, ref, name: csvFileName('equipos', eventName), rows: [
    ['equipo', 'numero', 'nombre', 'sexo', 'edad', 'iglesia'],
    ...rows
  ]);
}

/// Búsqueda y exportación a CSV de los equipos (una fila por persona; «Sin equipo» incluido).
class _TeamsToolbar extends ConsumerStatefulWidget {
  const _TeamsToolbar({required this.teams, required this.total});
  final List<TeamRow> teams; // los que deja el filtro
  final int total;
  @override
  ConsumerState<_TeamsToolbar> createState() => _TeamsToolbarState();
}

class _TeamsToolbarState extends ConsumerState<_TeamsToolbar> {
  late final c = TextEditingController(text: ref.read(teamQueryProvider));

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListToolbar(
        controller: c,
        hint: 'Equipo o persona',
        searchKey: const Key('eq-buscar'),
        countKey: const Key('eq-conteo'),
        onChanged: () => ref.read(teamQueryProvider.notifier).state = c.text,
        count: widget.teams.length == widget.total
            ? ''
            : '${widget.teams.length} de ${widget.total}',
      );
}

/// Escritorio: resumen de todos los equipos en una tabla ordenable (los integrantes se mueven
/// en las tarjetas de abajo, que admiten arrastrar y soltar).
class _TeamsTable extends StatelessWidget {
  const _TeamsTable(
      {required this.teams, required this.stats, required this.views});
  final List<TeamRow> teams;
  final List<TeamStats> stats;
  final List<AttendeeView> views;

  @override
  Widget build(BuildContext context) {
    TeamStats st(TeamRow t) => stats.firstWhere((s) => s.teamId == t.id);
    String captain(TeamRow t) => t.captainId == null
        ? '—'
        : (views.where((v) => v.a.id == t.captainId).firstOrNull?.fullName ??
            '—');
    return SizedBox(
      key: const Key('eq-tabla'),
      height: (teams.length * 56.0 + 64).clamp(120, 420).toDouble(),
      child: DataTableView<TeamRow>(
        items: teams,
        columns: [
          TableCol(
              'Equipo',
              (t) => Text(t.name,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              sortValue: (t) => normalizeText(t.name)),
          TableCol('Integrantes', (t) => Text('${st(t).size}'),
              numeric: true, sortValue: (t) => st(t).size),
          TableCol('Hombres', (t) => Text('${st(t).men}'),
              numeric: true, sortValue: (t) => st(t).men),
          TableCol('Mujeres', (t) => Text('${st(t).women}'),
              numeric: true, sortValue: (t) => st(t).women),
          TableCol(
              'Edad media',
              (t) =>
                  Text(st(t).size == 0 ? '—' : st(t).avgAge.toStringAsFixed(1)),
              numeric: true,
              sortValue: (t) => st(t).avgAge),
          TableCol('Capitán', (t) => Text(captain(t)),
              sortValue: (t) => normalizeText(captain(t))),
        ],
      ),
    );
  }
}

class TeamsScreen extends ConsumerWidget {
  const TeamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventId = ref.watch(currentEventIdProvider)!;
    final event = ref.watch(eventProvider(eventId)).valueOrNull;
    final teams =
        ref.watch(teamsProvider(eventId)).valueOrNull ?? const <TeamRow>[];
    final views = ref.watch(attendeesProvider(eventId)).valueOrNull ??
        const <AttendeeView>[];
    final ranges =
        ref.watch(ageRangesProvider(eventId)).valueOrNull ?? AgeRange.defaults;
    ref.watch(groupsProvider(
        eventId)); // mantiene los grupos cargados para «Asignar un grupo»
    final limits = event?.balanceLimits ?? const BalanceLimits();
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final people = [for (final v in views) v.a];
    final stats = [
      for (final t in teams)
        TeamStats.of(t.id, t.name,
            people.where((p) => p.teamId == t.id).map((p) => p.toCore()))
    ];
    final issues = evaluateBalance(stats, limits);
    final unassigned = views.where((v) => v.a.teamId == null).toList();
    final shownTeams = filterTeams(teams, views, ref.watch(teamQueryProvider));

    return Scaffold(
      appBar: AppHeader(
        title: 'Equipos',
        subtitle:
            plural(teams.length, 'equipo', 'equipos', zero: 'Sin equipos'),
        importKey: const Key('eq-importar'),
        exportKey: const Key('eq-exportar'),
        onImport: () => runTableImport(
            context, ref, TeamExchange(ref.read(databaseProvider), eventId)),
        onExport: () => _exportTeams(context, ref,
            teams: shownTeams,
            people: views,
            eventName: event?.name ?? '',
            query: ref.read(teamQueryProvider)),
        exportEnabled: shownTeams.isNotEmpty,
      ),
      body: event != null && !event.offersTeams && teams.isEmpty
          ? const Center(
              child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Este evento no se divide en equipos.',
                  key: Key('eq-no-aplica'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Brand.gris)),
            ))
          : teams.isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('Todavía no hay equipos',
                          key: const Key('eq-vacio'), style: headStyle(24)),
                      const SizedBox(height: 8),
                      const Text(
                          'Crea los equipos del evento y luego asigna a las personas a mano.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Brand.gris)),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                          key: const Key('eq-crear'),
                          onPressed: () => _createDialog(context, ref, eventId),
                          icon: const Icon(Icons.add),
                          label: const Text('Crear equipos')),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                          key: const Key('eq-importar-vacio'),
                          onPressed: () => runTableImport(
                              context,
                              ref,
                              TeamExchange(
                                  ref.read(databaseProvider), eventId)),
                          icon: const Icon(Icons.upload_file_outlined),
                          label: const Text('Importar equipos (CSV)')),
                    ]),
                  ),
                )
              : ListView(padding: const EdgeInsets.all(16), children: [
                  Text(
                      '${teams.length} equipos · ${views.length} personas · ${unassigned.length} sin equipo',
                      key: const Key('eq-resumen'),
                      style: const TextStyle(color: Brand.gris)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    OutlinedButton.icon(
                        key: const Key('eq-nuevo'),
                        onPressed: () =>
                            ref.read(teamRepoProvider).createMany(eventId, 1),
                        icon: const Icon(Icons.add),
                        label: const Text('Nuevo equipo')),
                    FilledButton.icon(
                        key: const Key('eq-generar'),
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                                builder: (_) => const TeamGenerateScreen())),
                        icon: const Icon(Icons.auto_awesome_outlined),
                        label: const Text('Generar equipos')),
                    OutlinedButton.icon(
                        key: const Key('eq-intercambiar'),
                        onPressed: () =>
                            _swapFlow(context, ref, teams, views, limits),
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text('Intercambiar')),
                    OutlinedButton.icon(
                        key: const Key('eq-topes'),
                        onPressed: () => showDialog<void>(
                            context: context,
                            builder: (_) =>
                                LimitsDialog(eventId: eventId, limits: limits)),
                        icon: const Icon(Icons.tune),
                        label: const Text('Criterios de balance')),
                  ]),
                  const SizedBox(height: 12),
                  _TeamsToolbar(teams: shownTeams, total: teams.length),
                  const SizedBox(height: 12),
                  _BalanceBanner(
                      issues: issues,
                      teamCount: teams.length,
                      hasPeople: people.any((p) => p.teamId != null)),
                  const SizedBox(height: 12),
                  if (useTables(context) && shownTeams.isNotEmpty) ...[
                    _TeamsTable(teams: shownTeams, stats: stats, views: views),
                    const SizedBox(height: 12),
                  ],
                  Wrap(spacing: 12, runSpacing: 12, children: [
                    for (final t in shownTeams)
                      _TeamCard(
                        team: t,
                        members:
                            views.where((v) => v.a.teamId == t.id).toList(),
                        stats: stats.firstWhere((s) => s.teamId == t.id),
                        ranges: ranges,
                        wide: wide,
                        onDrop: (id) => _move(
                            context, ref, teams, people, {id: t.id}, limits),
                        onTransfer: (v) =>
                            _transfer(context, ref, teams, people, v, limits),
                      ),
                  ]),
                  const SizedBox(height: 16),
                  _Unassigned(
                    people: unassigned,
                    onAssign: (v) =>
                        _transfer(context, ref, teams, people, v, limits),
                    onGroup: () => _assignGroup(
                        context, ref, teams, people, limits, eventId),
                  ),
                ]),
    );
  }

  Future<void> _createDialog(
          BuildContext context, WidgetRef ref, String eventId) =>
      showCreateTeamsDialog(context, ref, eventId);
}

/// Pide cuántos equipos crear y los crea (nombres y colores por defecto, editables luego).
/// Con [askCriteria] (la primera vez) muestra además los criterios de balance que propone el
/// sistema para que quien configura el evento los confirme o los cambie.
Future<void> showCreateTeamsDialog(
    BuildContext context, WidgetRef ref, String eventId,
    {bool askCriteria = true}) async {
  final limits = ref.read(eventProvider(eventId)).valueOrNull?.balanceLimits ??
      const BalanceLimits();
  final c = TextEditingController(text: '4');
  final size = TextEditingController(text: '${limits.maxSizeDiff}');
  final sex = TextEditingController(text: '${limits.maxSexDiff}');
  final age = TextEditingController(text: '${limits.maxAgeDiff}');
  String? error;
  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => AlertDialog(
        title: const Text('Crear equipos'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 460,
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                      key: const Key('eq-cantidad'),
                      controller: c,
                      keyboardType: TextInputType.number,
                      inputFormatters: digitsOnly(),
                      decoration: const InputDecoration(
                          labelText: 'Cuántos equipos',
                          helperText:
                              'Se crean con nombre y color; luego puedes cambiarlos')),
                  if (askCriteria) ...[
                    const SizedBox(height: 16),
                    const Text('Criterios de balance',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    const Text(
                        'Esta es la propuesta del sistema para que los equipos queden parejos. Confírmala tal cual o cámbiala. Si se superan, solo se avisa; nunca se bloquea.',
                        style: TextStyle(color: Brand.gris)),
                    const SizedBox(height: 10),
                    TextField(
                        key: const Key('eq-tope-tamano'),
                        controller: size,
                        keyboardType: TextInputType.number,
                        inputFormatters: digitsOnly(),
                        decoration: const InputDecoration(
                            labelText:
                                'Tamaño: diferencia máxima de personas')),
                    const SizedBox(height: 10),
                    TextField(
                        key: const Key('eq-tope-sexo'),
                        controller: sex,
                        keyboardType: TextInputType.number,
                        inputFormatters: digitsOnly(),
                        decoration: const InputDecoration(
                            labelText:
                                'Sexo: diferencia máxima hombres–mujeres por equipo')),
                    const SizedBox(height: 10),
                    TextField(
                        key: const Key('eq-tope-edad'),
                        controller: age,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: decimalOnly(),
                        decoration: const InputDecoration(
                            labelText:
                                'Edad: diferencia máxima de edad media (años)')),
                  ],
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    ErrorBox(error!)
                  ],
                ]),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
            key: const Key('eq-crear-ok'),
            onPressed: () async {
              try {
                BalanceLimits? chosen;
                if (askCriteria) {
                  final s = int.tryParse(size.text.trim()),
                      x = int.tryParse(sex.text.trim()),
                      a = double.tryParse(age.text.trim().replaceAll(',', '.'));
                  if (s == null || x == null || a == null) {
                    set(() => error = 'Escribe un número en cada criterio.');
                    return;
                  }
                  chosen = BalanceLimits(
                      maxSizeDiff: s, maxSexDiff: x, maxAgeDiff: a);
                }
                final repo = ref.read(teamRepoProvider);
                await repo.createMany(
                    eventId, int.tryParse(c.text.trim()) ?? 0);
                if (chosen != null) await repo.setLimits(eventId, chosen);
                if (ctx.mounted) Navigator.pop(ctx);
              } on DataException catch (e) {
                set(() => error = e.message);
              }
            },
            child: Text(askCriteria ? 'Confirmar y crear' : 'Crear'),
          ),
        ],
      ),
    ),
  );
}

extension on TeamsScreen {
  Future<void> _transfer(
      BuildContext context,
      WidgetRef ref,
      List<TeamRow> teams,
      List<AttendeeRow> people,
      AttendeeView v,
      BalanceLimits limits) async {
    final others = teams.where((t) => t.id != v.a.teamId).toList();
    final dest = await showDialog<TeamRow>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(v.a.teamId == null ? 'Asignar a…' : 'Trasladar a…'),
        children: [
          for (final t in others)
            SimpleDialogOption(
              key: Key('tr-${t.name}'),
              onPressed: () => Navigator.pop(ctx, t),
              child: Row(children: [
                Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                        color: teamColor(t.color),
                        borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 10),
                Text(t.name)
              ]),
            ),
        ],
      ),
    );
    if (dest == null || !context.mounted) return;
    await _move(context, ref, teams, people, {v.a.id: dest.id}, limits);
  }

  Future<void> _move(
      BuildContext context,
      WidgetRef ref,
      List<TeamRow> teams,
      List<AttendeeRow> people,
      Map<String, String?> moves,
      BalanceLimits limits,
      {bool swap = false}) async {
    moves = {
      for (final e in moves.entries)
        if (people.firstWhere((p) => p.id == e.key).teamId != e.value)
          e.key: e.value
    };
    if (moves.isEmpty) return;
    final pv = previewMoves(
        teams: teams, people: people, moves: moves, limits: limits);
    final names = [
      for (final id in moves.keys)
        () {
          final p = people.firstWhere((x) => x.id == id);
          return '${p.firstName} ${p.lastName1}';
        }()
    ];
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) =>
          _MoveConfirm(preview: pv, teams: teams, names: names, swap: swap),
    );
    if (ok != true) return;
    final repo = ref.read(teamRepoProvider);
    if (swap) {
      final [a, b] = moves.keys.toList();
      await repo.swap(a, b);
    } else {
      final byTeam = <String?, List<String>>{};
      moves.forEach((id, t) => byTeam.putIfAbsent(t, () => []).add(id));
      for (final e in byTeam.entries) {
        await repo.setTeam(e.value, e.key);
      }
    }
  }

  Future<void> _swapFlow(
      BuildContext context,
      WidgetRef ref,
      List<TeamRow> teams,
      List<AttendeeView> views,
      BalanceLimits limits) async {
    final inTeams = views.where((v) => v.a.teamId != null).toList();
    final a = await pickPerson(context,
        all: inTeams, title: 'Intercambiar: primera persona');
    if (a == null || !context.mounted) return;
    final b = await pickPerson(context,
        all: inTeams,
        title: 'Intercambiar con…',
        where: (v) => v.a.teamId != a.a.teamId);
    if (b == null || !context.mounted) return;
    await _move(context, ref, teams, [for (final v in views) v.a],
        {a.a.id: b.a.teamId, b.a.id: a.a.teamId}, limits,
        swap: true);
  }

  Future<void> _assignGroup(
      BuildContext context,
      WidgetRef ref,
      List<TeamRow> teams,
      List<AttendeeRow> people,
      BalanceLimits limits,
      String eventId) async {
    final groups =
        ref.read(groupsProvider(eventId)).valueOrNull ?? const <GroupView>[];
    final g = await showDialog<GroupView>(
      context: context,
      builder: (ctx) => SimpleDialog(
          title: const Text('Asignar un grupo completo'),
          children: [
            if (groups.isEmpty)
              const Padding(
                  padding: EdgeInsets.all(16), child: Text('No hay grupos.')),
            for (final g in groups)
              SimpleDialogOption(
                  key: Key('eg-${g.group.name}'),
                  onPressed: () => Navigator.pop(ctx, g),
                  child: Text('${g.group.name} (${g.memberCount})')),
          ]),
    );
    if (g == null || !context.mounted) return;
    final dest = await showDialog<TeamRow>(
      context: context,
      builder: (ctx) =>
          SimpleDialog(title: Text('Llevar «${g.group.name}» a…'), children: [
        for (final t in teams)
          SimpleDialogOption(
              key: Key('egt-${t.name}'),
              onPressed: () => Navigator.pop(ctx, t),
              child: Text(t.name)),
      ]),
    );
    if (dest == null || !context.mounted) return;
    final members = await ref.read(socialRepoProvider).groupMembers(g.group.id);
    if (!context.mounted) return;
    await _move(context, ref, teams, people,
        {for (final m in members) m.id: dest.id}, limits);
  }
}

class _BalanceBanner extends StatelessWidget {
  const _BalanceBanner(
      {required this.issues, required this.teamCount, required this.hasPeople});
  final List<BalanceIssue> issues;
  final int teamCount;
  final bool hasPeople;
  @override
  Widget build(BuildContext context) {
    if (!hasPeople) return const SizedBox.shrink();
    if (issues.isEmpty) {
      return Container(
        key: const Key('eq-balanceados'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Brand.exitoSuave, borderRadius: BorderRadius.circular(12)),
        child: const Row(children: [
          Icon(Icons.check_circle_outline, color: Brand.exito),
          SizedBox(width: 10),
          Expanded(child: Text('Equipos balanceados según los topes.'))
        ]),
      );
    }
    return Container(
      key: const Key('eq-aviso'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Brand.avisoSuave,
          border: Border.all(color: Brand.aviso, width: 2),
          borderRadius: BorderRadius.circular(12)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.warning_amber_rounded,
            color: Brand.avisoTexto, size: 26),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Atención: los equipos no están balanceados.',
                style: TextStyle(fontWeight: FontWeight.w800)),
            for (final i in issues)
              Text(i.message, style: const TextStyle(fontSize: 15)),
            const Text('Puedes continuar de todas formas.',
                style: TextStyle(color: Brand.avisoTexto)),
          ]),
        ),
      ]),
    );
  }
}

class _TeamCard extends ConsumerStatefulWidget {
  const _TeamCard(
      {required this.team,
      required this.members,
      required this.stats,
      required this.ranges,
      required this.wide,
      required this.onDrop,
      required this.onTransfer});
  final TeamRow team;
  final List<AttendeeView> members;
  final TeamStats stats;
  final List<AgeRange> ranges;
  final bool wide;
  final void Function(String attendeeId) onDrop;
  final void Function(AttendeeView) onTransfer;
  @override
  ConsumerState<_TeamCard> createState() => _TeamCardState();
}

class _TeamCardState extends ConsumerState<_TeamCard> {
  bool showAll = false;
  bool over = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.team;
    final s = widget.stats;
    final captain =
        widget.members.where((m) => m.a.id == t.captainId).firstOrNull;
    final dist =
        ageDistribution(widget.members.map((m) => m.a.toCore()), widget.ranges);
    final maxD = dist.values.fold<int>(1, (a, b) => b > a ? b : a);
    final shown = showAll ? widget.members : widget.members.take(6).toList();
    final me = ref.watch(currentUserProvider);

    return DragTarget<String>(
      onWillAcceptWithDetails: (d) {
        setState(() => over = true);
        return true;
      },
      onLeave: (_) => setState(() => over = false),
      onAcceptWithDetails: (d) {
        setState(() => over = false);
        widget.onDrop(d.data);
      },
      builder: (context, _, __) => SizedBox(
        width: 320,
        child: Card(
          key: Key('equipo-${t.name}'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
                color: over ? Brand.azul : Brand.borde, width: over ? 3 : 1),
          ),
          clipBehavior: Clip.antiAlias,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(height: 8, color: teamColor(t.color)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Text(t.name, style: headStyle(22))),
                      Text('${s.size}',
                          key: Key('equipo-${t.name}-n'), style: headStyle(32)),
                      PopupMenuButton<String>(
                        key: Key('equipo-${t.name}-menu'),
                        onSelected: (a) async {
                          if (a == 'edit') {
                            await showDialog<void>(
                                context: context,
                                builder: (_) => _TeamEditDialog(
                                    team: t, members: widget.members));
                          } else if (a == 'del') {
                            await ref.read(teamRepoProvider).delete(t.id);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                              value: 'edit',
                              child: Text('Editar nombre, color y capitán')),
                          if (me?.isAdmin ?? false)
                            const PopupMenuItem(
                                value: 'del', child: Text('Eliminar equipo')),
                        ],
                      ),
                    ]),
                    Text(
                        captain == null
                            ? 'Capitán: sin capitán'
                            : 'Capitán: ${captain.fullName}',
                        style: const TextStyle(color: Brand.gris)),
                    Text(
                        '${s.men} hombres · ${s.women} mujeres${s.size == 0 ? '' : ' · edad media ${_n(s.avgAge)}'}',
                        style:
                            const TextStyle(color: Brand.gris, fontSize: 14)),
                    const SizedBox(height: 8),
                    for (final e in dist.entries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(children: [
                          SizedBox(
                              width: 62,
                              child: Text(e.key,
                                  style: const TextStyle(
                                      fontSize: 12, color: Brand.gris))),
                          Expanded(
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                      minHeight: 8,
                                      value: e.value / maxD,
                                      backgroundColor: Brand.azulSuave,
                                      color: teamColor(t.color)))),
                          SizedBox(
                              width: 26,
                              child: Text('${e.value}',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 12))),
                        ]),
                      ),
                  ]),
            ),
            const Divider(height: 1),
            for (final m in shown) _memberRow(m, t),
            if (widget.members.length > 6)
              TextButton(
                  onPressed: () => setState(() => showAll = !showAll),
                  child: Text(showAll
                      ? 'Ver menos'
                      : 'Ver los ${widget.members.length - 6} restantes')),
            if (widget.members.isEmpty)
              const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Sin integrantes todavía.',
                      style: TextStyle(color: Brand.gris))),
          ]),
        ),
      ),
    );
  }

  Widget _memberRow(AttendeeView m, TeamRow t) {
    final row = ListTile(
      key: Key('miembro-${m.a.regNumber}'),
      dense: true,
      title: Text(m.fullName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
          '${m.isMale ? 'H' : 'M'} · ${m.a.age} años${m.a.id == t.captainId ? ' · capitán' : ''}'),
      trailing: IconButton(
          key: Key('trasladar-${m.a.regNumber}'),
          tooltip: 'Trasladar a otro equipo',
          icon: const Icon(Icons.swap_horiz),
          onPressed: () => widget.onTransfer(m)),
    );
    if (!widget.wide) return row;
    return Draggable<String>(
      data: m.a.id,
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(10),
        child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Brand.azul, borderRadius: BorderRadius.circular(10)),
            child: Text(m.fullName,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700))),
      ),
      childWhenDragging: Opacity(opacity: .35, child: row),
      child: row,
    );
  }
}

class _Unassigned extends StatelessWidget {
  const _Unassigned(
      {required this.people, required this.onAssign, required this.onGroup});
  final List<AttendeeView> people;
  final void Function(AttendeeView) onAssign;
  final VoidCallback onGroup;
  @override
  Widget build(BuildContext context) => Card(
        key: const Key('eq-sin-equipo'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: Text('Sin equipo (${people.length})',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800))),
              OutlinedButton.icon(
                  key: const Key('eq-asignar-grupo'),
                  onPressed: onGroup,
                  icon: const Icon(Icons.groups_outlined),
                  label: const Text('Asignar un grupo')),
            ]),
            const SizedBox(height: 6),
            if (people.isEmpty)
              const Text('Todos los asistentes tienen equipo.',
                  style: TextStyle(color: Brand.gris)),
            for (final v in people.take(30))
              ListTile(
                key: Key('sin-${v.a.regNumber}'),
                dense: true,
                title: Text(v.fullName),
                subtitle:
                    Text('${v.isMale ? 'Hombre' : 'Mujer'} · ${v.a.age} años'),
                trailing: TextButton(
                    key: Key('asignar-${v.a.regNumber}'),
                    onPressed: () => onAssign(v),
                    child: const Text('Asignar')),
              ),
            if (people.length > 30)
              Text(
                  '…y ${people.length - 30} más. Usa «Asignar un grupo» o la lista de asistentes.',
                  style: const TextStyle(color: Brand.gris)),
          ]),
        ),
      );
}

class _MoveConfirm extends StatelessWidget {
  const _MoveConfirm(
      {required this.preview,
      required this.teams,
      required this.names,
      required this.swap});
  final MovePreview preview;
  final List<TeamRow> teams;
  final List<String> names;
  final bool swap;

  @override
  Widget build(BuildContext context) {
    final warn = preview.issues.isNotEmpty;
    String line(TeamStats a, TeamStats b) =>
        '${a.men}H·${a.women}M${a.size == 0 ? '' : ' (${_n(a.avgAge)})'}  →  ${b.men}H·${b.women}M${b.size == 0 ? '' : ' (${_n(b.avgAge)})'}';
    return AlertDialog(
      backgroundColor: warn ? Brand.avisoSuave : null,
      title: Text(swap ? 'Confirmar intercambio' : 'Confirmar traslado'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 440,
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    names.length > 3
                        ? '${names.take(3).join(', ')} y ${names.length - 3} más'
                        : names.join(', '),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 17)),
                const SizedBox(height: 4),
                const Text('Balance por sexo (edad media) · antes y después',
                    style: TextStyle(color: Brand.gris, fontSize: 13)),
                const SizedBox(height: 8),
                for (var i = 0; i < teams.length; i++)
                  if (preview.affected.contains(teams[i].id))
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10)),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                      color: teamColor(teams[i].color),
                                      borderRadius: BorderRadius.circular(3))),
                              const SizedBox(width: 8),
                              Text(teams[i].name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700))
                            ]),
                            Text(line(preview.before[i], preview.after[i]),
                                key: Key('prev-${teams[i].name}')),
                          ]),
                    ),
                if (warn)
                  Column(
                      key: const Key('mv-aviso'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Brand.avisoTexto),
                          SizedBox(width: 8),
                          Text('Atención',
                              style: TextStyle(fontWeight: FontWeight.w800))
                        ]),
                        for (final i in preview.issues) Text(i.message),
                        const SizedBox(height: 4),
                        const Text('Puedes continuar si es necesario.',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ])
                else
                  const Row(key: Key('mv-ok'), children: [
                    Icon(Icons.check_circle_outline, color: Brand.exito),
                    SizedBox(width: 8),
                    Expanded(
                        child:
                            Text('El balance se mantiene dentro de los topes.'))
                  ]),
              ]),
        ),
      ),
      actions: [
        TextButton(
            key: const Key('mv-cancelar'),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar')),
        FilledButton(
          key: const Key('mv-confirmar'),
          style: warn
              ? FilledButton.styleFrom(
                  backgroundColor: Brand.aviso, foregroundColor: Brand.tinta)
              : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(warn
              ? (swap
                  ? 'Intercambiar de todas formas'
                  : 'Trasladar de todas formas')
              : (swap ? 'Intercambiar' : 'Trasladar')),
        ),
      ],
    );
  }
}

class _TeamEditDialog extends ConsumerStatefulWidget {
  const _TeamEditDialog({required this.team, required this.members});
  final TeamRow team;
  final List<AttendeeView> members;
  @override
  ConsumerState<_TeamEditDialog> createState() => _TeamEditDialogState();
}

class _TeamEditDialogState extends ConsumerState<_TeamEditDialog> {
  late final name = TextEditingController(text: widget.team.name);
  late String? color = widget.team.color;
  late String? captain = widget.team.captainId;
  String? error;

  Future<void> _save() async {
    try {
      await ref.read(teamRepoProvider).update(widget.team.id,
          name: name.text, color: color, captainId: captain);
      if (mounted) Navigator.pop(context);
    } on DataException catch (e) {
      setState(() => error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Editar equipo'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 420,
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                      key: const Key('te-nombre'),
                      controller: name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Nombre')),
                  const SizedBox(height: 12),
                  const Text('Color (opcional)',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final (n, hex) in teamPalette)
                      Semantics(
                        label: n,
                        button: true,
                        selected: color == hex,
                        child: InkWell(
                          onTap: () => setState(() => color = hex),
                          child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                  color: teamColor(hex),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: color == hex
                                          ? Brand.tinta
                                          : Colors.transparent,
                                      width: 3))),
                        ),
                      ),
                    TextButton(
                        onPressed: () => setState(() => color = null),
                        child: const Text('Sin color')),
                  ]),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    key: const Key('te-capitan'),
                    initialValue: captain,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Capitán'),
                    items: [
                      const DropdownMenuItem<String?>(
                          value: null, child: Text('Sin capitán')),
                      for (final m in widget.members)
                        DropdownMenuItem<String?>(
                            value: m.a.id, child: Text(m.fullName)),
                    ],
                    onChanged: (v) => setState(() => captain = v),
                  ),
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
              key: const Key('te-guardar'),
              onPressed: _save,
              child: const Text('Guardar')),
        ],
      );
}

class LimitsDialog extends ConsumerStatefulWidget {
  const LimitsDialog({super.key, required this.eventId, required this.limits});
  final String eventId;
  final BalanceLimits limits;
  @override
  ConsumerState<LimitsDialog> createState() => LimitsDialogState();
}

class LimitsDialogState extends ConsumerState<LimitsDialog> {
  late final size = TextEditingController(text: '${widget.limits.maxSizeDiff}');
  late final sex = TextEditingController(text: '${widget.limits.maxSexDiff}');
  late final ageC = TextEditingController(text: '${widget.limits.maxAgeDiff}');
  String? error;

  Future<void> _save() async {
    final s = int.tryParse(size.text.trim()),
        x = int.tryParse(sex.text.trim()),
        a = double.tryParse(ageC.text.trim().replaceAll(',', '.'));
    if (s == null || x == null || a == null) {
      setState(() => error = 'Escribe un número en cada tope.');
      return;
    }
    try {
      await ref.read(teamRepoProvider).setLimits(widget.eventId,
          BalanceLimits(maxSizeDiff: s, maxSexDiff: x, maxAgeDiff: a));
      if (mounted) Navigator.pop(context);
    } on DataException catch (e) {
      setState(() => error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Criterios de balance'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 420,
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                      'Diferencias máximas entre equipos. Si se superan, se avisa (nunca se bloquea).',
                      style: TextStyle(color: Brand.gris)),
                  const SizedBox(height: 12),
                  TextField(
                      key: const Key('lim-tamano'),
                      controller: size,
                      keyboardType: TextInputType.number,
                      inputFormatters: digitsOnly(),
                      decoration: const InputDecoration(
                          labelText: 'Tamaño: diferencia máxima de personas')),
                  const SizedBox(height: 12),
                  TextField(
                      key: const Key('lim-sexo'),
                      controller: sex,
                      keyboardType: TextInputType.number,
                      inputFormatters: digitsOnly(),
                      decoration: const InputDecoration(
                          labelText:
                              'Sexo: diferencia máxima hombres–mujeres por equipo')),
                  const SizedBox(height: 12),
                  TextField(
                      key: const Key('lim-edad'),
                      controller: ageC,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: decimalOnly(),
                      decoration: const InputDecoration(
                          labelText:
                              'Edad: diferencia máxima de edad media (años)')),
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
              key: const Key('lim-guardar'),
              onPressed: _save,
              child: const Text('Guardar')),
        ],
      );
}
