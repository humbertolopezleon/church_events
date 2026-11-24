import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import '../data/repos_b.dart';
import '../data/repository.dart';
import '../data/team_pieces.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import 'auth_screens.dart' show ErrorBox;
import 'proposal_card.dart';
import 'teams_screen.dart' show teamColor;

/// Generación automática de equipos (estrategia C). Calcula una PROPUESTA; no cambia nada
/// hasta pulsar «Aceptar», y después se puede deshacer.
class TeamGenerateScreen extends ConsumerStatefulWidget {
  const TeamGenerateScreen({super.key});
  @override
  ConsumerState<TeamGenerateScreen> createState() => _TeamGenerateScreenState();
}

class _TeamGenerateScreenState extends ConsumerState<TeamGenerateScreen> {
  bool includeAssigned = false;
  TeamPlan? plan;
  int pieceCount = 0;
  bool discarded = false;
  bool busy = false;
  String? error;

  Future<void> _compute() async {
    try {
      final eventId = ref.read(currentEventIdProvider)!;
      final event = ref.read(eventProvider(eventId)).valueOrNull;
      final teams = ref.read(teamsProvider(eventId)).valueOrNull ?? const [];
      final people = [
        for (final v in ref.read(attendeesProvider(eventId)).valueOrNull ??
            const <AttendeeView>[])
          v.a
      ];
      final social = ref.read(socialRepoProvider);
      final spouses = await social.spouseMap(eventId);
      final together = await social.togetherSets(eventId);
      if (!mounted) return;
      final built = buildTeamPieces(people,
          spouses: spouses,
          together: together,
          includeAssigned: includeAssigned);
      final stats = [
        for (final t in teams)
          TeamStats.of(t.id, t.name,
              built.fixed.where((p) => p.teamId == t.id).map((p) => p.toCore()))
      ];
      final result = generateTeams(
          teams: stats,
          pieces: built.pieces,
          limits: event?.balanceLimits ?? const BalanceLimits());
      setState(() {
        plan = result;
        pieceCount = built.pieces.length;
        discarded = false;
        error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() => error = 'No se pudo calcular. Detalle técnico: $e');
      }
    }
  }

  Future<void> _accept() async {
    final p = plan;
    if (p == null || p.assignments.isEmpty) return;
    setState(() => busy = true);
    try {
      final previous =
          await ref.read(teamRepoProvider).applyPlan(p.assignments);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final repo = ref.read(teamRepoProvider);
      messenger.showSnackBar(SnackBar(
        duration: const Duration(seconds: 12),
        content: Text('Equipos asignados a ${p.assignments.length} personas.'),
        action: SnackBarAction(
            label: 'Deshacer', onPressed: () => repo.restoreTeams(previous)),
      ));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => error = 'No se pudo asignar. Detalle técnico: $e');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventId = ref.watch(currentEventIdProvider)!;
    final teams = ref.watch(teamsProvider(eventId)).valueOrNull ?? const [];
    final people = ref.watch(attendeesProvider(eventId)).valueOrNull ??
        const <AttendeeView>[];
    final pending = people.where((v) => v.a.teamId == null).length;
    final count = includeAssigned ? people.length : pending;
    final colors = {for (final t in teams) t.id: teamColor(t.color)};

    return Scaffold(
      appBar: AppBar(title: const Text('Generar equipos')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Reparto automático',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text(
                  'Reparte a las personas en los equipos cuidando el tamaño, la mezcla de hombres y mujeres y la edad media (los criterios de balance del evento). Los matrimonios y los grupos «mantener juntos» no se separan.',
                  style: TextStyle(color: Brand.gris)),
              const SizedBox(height: 4),
              const Text(
                  'Es solo una propuesta: no cambia nada hasta que pulses «Aceptar», y luego puedes deshacerlo.',
                  style: TextStyle(color: Brand.gris)),
              SwitchListTile(
                  key: const Key('gen-todos'),
                  contentPadding: EdgeInsets.zero,
                  title:
                      const Text('Incluir también a quienes ya tienen equipo'),
                  subtitle: const Text(
                      'Los puede cambiar de equipo. Apagado, solo se reparte a quien no tiene.'),
                  value: includeAssigned,
                  onChanged: (v) => setState(() {
                        includeAssigned = v;
                        plan = null;
                      })),
              Text(
                  teams.isEmpty
                      ? 'Primero crea los equipos.'
                      : '$count ${count == 1 ? 'persona por repartir' : 'personas por repartir'} en ${teams.length} equipos.',
                  key: const Key('gen-resumen'),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              FilledButton.icon(
                  key: const Key('gen-calcular'),
                  onPressed: teams.isEmpty || count == 0 ? null : _compute,
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: const Text('Calcular propuesta')),
            ]),
          ),
        ),
        if (error != null) ...[const SizedBox(height: 12), ErrorBox(error!)],
        if (plan != null && !discarded) ...[
          const SizedBox(height: 16),
          ProposalCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                  'Se asignarán ${plan!.assignments.length} personas ($pieceCount ${pieceCount == 1 ? 'pieza' : 'piezas'}, contando matrimonios y grupos como una).',
                  key: const Key('gen-detalle'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              for (var i = 0; i < plan!.after.length; i++)
                _TeamRow(
                    before: plan!.before[i],
                    after: plan!.after[i],
                    color: colors[plan!.after[i].teamId] ?? Brand.gris),
              const SizedBox(height: 8),
              if (plan!.isBalanced)
                const Row(children: [
                  Icon(Icons.check_circle, color: Brand.exito),
                  SizedBox(width: 8),
                  Expanded(
                      child: Text('Cumple los criterios de balance del evento.',
                          key: Key('gen-balanceado'))),
                ])
              else
                for (final i in plan!.issues)
                  Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(i.message,
                          key: const Key('gen-aviso'),
                          style: const TextStyle(color: Brand.avisoTexto))),
              for (final n in plan!.notes)
                Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(n,
                        style: const TextStyle(color: Brand.avisoTexto))),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                FilledButton(
                    key: const Key('gen-aceptar'),
                    onPressed:
                        busy || plan!.assignments.isEmpty ? null : _accept,
                    child: const Text('Aceptar')),
                OutlinedButton(
                    key: const Key('gen-recalcular'),
                    onPressed: _compute,
                    child: const Text('Calcular de nuevo')),
                TextButton(
                    key: const Key('gen-descartar'),
                    onPressed: () => setState(() => discarded = true),
                    child: const Text('Descartar')),
              ]),
              const SizedBox(height: 4),
              const Text(
                  'Después de aceptar puedes ajustar a mano (trasladar, intercambiar) o deshacer todo.',
                  style: TextStyle(color: Brand.gris, fontSize: 14)),
            ]),
          ),
        ],
        if (plan != null && discarded)
          const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text('Propuesta descartada. No se cambió nada.',
                  key: Key('gen-descartada'),
                  style: TextStyle(color: Brand.gris))),
      ]),
    );
  }
}

class _TeamRow extends StatelessWidget {
  const _TeamRow(
      {required this.before, required this.after, required this.color});
  final TeamStats before, after;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border(left: BorderSide(color: color, width: 6))),
          child: Row(children: [
            Expanded(
                child: Text(after.teamName,
                    style: const TextStyle(fontWeight: FontWeight.w800))),
            Text(
                '${before.size} → ${after.size} · ${after.men} H / ${after.women} M · edad media ${after.avgAge.toStringAsFixed(1)}',
                style: const TextStyle(color: Brand.gris, fontSize: 14)),
          ]),
        ),
      );
}
