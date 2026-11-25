import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import '../data/repos_b.dart';
import '../data/repository.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import 'auth_screens.dart' show ErrorBox;
import 'proposal_card.dart';
import 'notifications.dart';

/// Un tramo editable de la propuesta (el usuario puede cambiar el hospedaje).
class _Leg {
  _Leg(this.lodgingId, this.people, this.reason);
  String lodgingId;
  final List<PersonRef> people;
  final String reason;
}

/// Sugerencia de hospedaje: calcula propuestas y las muestra para Aceptar / Modificar /
/// Descartar. No escribe nada hasta que se pulsa «Aceptar».
class LodgingSuggestScreen extends ConsumerStatefulWidget {
  const LodgingSuggestScreen({super.key});
  @override
  ConsumerState<LodgingSuggestScreen> createState() =>
      _LodgingSuggestScreenState();
}

class _LodgingSuggestScreenState extends ConsumerState<LodgingSuggestScreen> {
  bool keepTogether = true;
  bool preferChurch = true;
  bool splitCouples =
      false; // último recurso: separar matrimonios si no hay hospedaje para ellos
  Set<String>? chosen; // nulo = todas las pendientes
  Map<String, String> spouses = {};
  List<LodgingProposal>? proposals;
  final dismissed = <int>{};
  final editing = <int>{};
  final legsByProposal = <int, List<_Leg>>{};
  Object? error;
  bool busy = false;

  List<AttendeeView> _pending(List<AttendeeView> all) =>
      all.where((p) => p.a.needsLodging && p.a.lodgingId == null).toList()
        ..sort((a, b) => a.a.regNumber.compareTo(b.a.regNumber));

  Future<void> _compute() async {
    try {
      final eventId = ref.read(currentEventIdProvider)!;
      final all = ref.read(attendeesProvider(eventId)).valueOrNull ??
          const <AttendeeView>[];
      final lodgings = ref.read(lodgingsProvider(eventId)).valueOrNull ??
          const <LodgingView>[];
      final sp = await ref.read(socialRepoProvider).spouseMap(eventId);
      if (!mounted) return;
      final byId = {for (final p in all) p.a.id: p};
      final target = (chosen ?? _pending(all).map((p) => p.a.id).toSet())
          .map((id) => byId[id])
          .whereType<AttendeeView>()
          .toList();
      // Cónyuge fuera de la selección pero ya hospedado: se propone su mismo sitio.
      final refs = [
        for (final v in target)
          () {
            final spId = sp[v.a.id];
            final spLodging = spId == null ? null : byId[spId]?.a.lodgingId;
            final r = v.a.toPersonRef(spId);
            return spLodging == null || target.any((t) => t.a.id == spId)
                ? r
                : PersonRef(
                    id: r.id,
                    name: r.name,
                    sex: r.sex,
                    spouseId: r.spouseId,
                    churchId: r.churchId,
                    spouseLodgingId: spLodging);
          }()
      ];
      final candidates = [
        for (final l in lodgings)
          LodgingCandidate(
            id: l.row.id,
            name: l.row.name,
            accepts: lodgingAcceptsFromDb(l.row.accepts),
            capacity: l.row.capacity,
            occupied: l.occupied,
            kind: l.row.kind == 'shelter'
                ? LodgingKindRef.shelter
                : LodgingKindRef.privateHome,
            occupantChurchIds: {
              for (final p in all)
                if (p.a.lodgingId == l.row.id && p.a.churchId != null)
                  p.a.churchId!
            },
            distanceNote: l.row.distanceNote,
            occupantMix: occupantMixOfRows([
              for (final p in all)
                if (p.a.lodgingId == l.row.id) p.a
            ]),
          )
      ];
      final result = suggestLodging(refs, candidates,
          options: SuggestOptions(
              keepTogether: keepTogether,
              preferHostChurch: preferChurch,
              splitCouples: splitCouples));
      setState(() {
        spouses = sp;
        proposals = result;
        dismissed.clear();
        editing.clear();
        legsByProposal.clear();
        for (final e in result.indexed) {
          legsByProposal[e.$1] = [
            for (final l in e.$2.legs) _Leg(l.lodgingId, l.people, l.reason)
          ];
        }
        error = null;
      });
    } catch (e) {
      if (mounted) setState(() => error = e);
    }
  }

  Future<void> _accept(int i, List<LodgingView> lodgings) async {
    final prop = proposals![i];
    final legs = legsByProposal[i]!;
    if (prop.unplaced.isNotEmpty) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Esta propuesta está incompleta'),
          content: Text(
              'Se asignarán ${legs.fold<int>(0, (a, l) => a + l.people.length)} personas y '
              '${prop.unplaced.length} quedarán sin hospedaje. ¿Continuar?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Volver')),
            FilledButton(
                key: const Key('sg-confirmar-parcial'),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Asignar a quienes caben')),
          ],
        ),
      );
      if (ok != true) return;
    }
    // Compatibilidad = bloqueo duro (también si la persona cambió el hospedaje de una propuesta).
    final repo = ref.read(lodgingRepoProvider);
    final blockers = <String>[];
    for (final l in legs) {
      blockers.addAll(await repo.compatibilityProblems(
          l.lodgingId, l.people.map((p) => p.id)));
    }
    if (!mounted) return;
    if (blockers.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Brand.avisoSuave,
          title: const Text('No se puede asignar así'),
          content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final b in blockers)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      key: const Key('sg-bloqueo'),
                      child: Text(b)),
                const Text(
                    'Elige otro hospedaje o edita este para cambiar a quién acepta.',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ]),
          actions: [
            FilledButton(
                key: const Key('sg-bloqueo-ok'),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Entendido')),
          ],
        ),
      );
      return;
    }
    // Si el usuario cambió algo y hay avisos de capacidad, también se pide confirmación.
    final warns = _warnings(i, lodgings);
    if (warns.isNotEmpty && editing.contains(i)) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Brand.avisoSuave,
          title: const Text('Atención'),
          content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final w in warns)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(w)),
                const Text('Puedes continuar si es necesario.',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Revisar')),
            FilledButton(
                key: const Key('sg-continuar'),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Asignar de todas formas')),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => busy = true);
    try {
      final repo = ref.read(lodgingRepoProvider);
      for (final l in legs) {
        await repo.assign(l.lodgingId, l.people.map((p) => p.id));
      }
      if (!mounted) return;
      setState(() {
        dismissed.add(i);
        busy = false;
      });
      ScaffoldMessenger.of(context)
          .notice('Asignado. Puedes ver o cambiar cada hospedaje en su ficha.');
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e;
          busy = false;
        });
      }
    }
  }

  List<String> _warnings(int i, List<LodgingView> lodgings) {
    final out = <String>[];
    for (final l in legsByProposal[i]!) {
      final lv = lodgings.where((x) => x.row.id == l.lodgingId).firstOrNull;
      if (lv == null) continue;
      out.addAll(checkLodgingAssignment(lv.slot, l.people)
          .where((w) => w.kind == WarningKind.capacity)
          .map((w) => w.message));
    }
    return out;
  }

  Future<void> _pickPeople(List<AttendeeView> all) async {
    final res = await showDialog<Set<String>>(
      context: context,
      builder: (_) => _PeoplePicker(
          people: _pending(all),
          spouses: spouses.isEmpty ? const {} : spouses,
          initial: chosen ?? _pending(all).map((p) => p.a.id).toSet()),
    );
    if (res != null) {
      setState(() {
        chosen = res;
        proposals = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventId = ref.watch(currentEventIdProvider)!;
    final all = ref.watch(attendeesProvider(eventId)).valueOrNull ??
        const <AttendeeView>[];
    final lodgings = ref.watch(lodgingsProvider(eventId)).valueOrNull ??
        const <LodgingView>[];
    final pending = _pending(all);
    final count = chosen?.length ?? pending.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Sugerir hospedaje')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('¿A quién quieres hospedar?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                  chosen == null
                      ? 'Todas las personas que necesitan hospedaje y aún no tienen: ${pending.length}.'
                      : 'Seleccionadas: $count.',
                  key: const Key('sg-resumen'),
                  style: const TextStyle(color: Brand.gris)),
              const SizedBox(height: 4),
              const Text(
                  'Es solo una sugerencia: no se guarda nada hasta que tú pulses «Aceptar».',
                  style: TextStyle(color: Brand.gris)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                OutlinedButton.icon(
                    key: const Key('sg-elegir'),
                    onPressed: pending.isEmpty ? null : () => _pickPeople(all),
                    icon: const Icon(Icons.checklist),
                    label: const Text('Elegir personas…')),
                if (chosen != null)
                  TextButton(
                      key: const Key('sg-todas'),
                      onPressed: () => setState(() {
                            chosen = null;
                            proposals = null;
                          }),
                      child: const Text('Volver a todas')),
              ]),
              SwitchListTile(
                  key: const Key('sg-juntos'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Mantenerlos juntos si es posible'),
                  value: keepTogether,
                  onChanged: (v) => setState(() {
                        keepTogether = v;
                        proposals = null;
                      })),
              SwitchListTile(
                  key: const Key('sg-iglesia'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Preferir hospedajes de su misma iglesia'),
                  value: preferChurch,
                  onChanged: (v) => setState(() {
                        preferChurch = v;
                        proposals = null;
                      })),
              SwitchListTile(
                  key: const Key('sg-separar'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                      'Si no hay hospedaje para matrimonios, alojarlos por separado'),
                  subtitle: const Text(
                      'Solo a los que no quepan juntos: el esposo con hombres y la esposa con mujeres.'),
                  value: splitCouples,
                  onChanged: (v) => setState(() {
                        splitCouples = v;
                        proposals = null;
                      })),
              const SizedBox(height: 8),
              FilledButton.icon(
                  key: const Key('sg-buscar'),
                  onPressed: count == 0 || lodgings.isEmpty ? null : _compute,
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: const Text('Buscar sugerencias')),
              if (lodgings.isEmpty)
                const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Primero registra al menos un hospedaje.',
                        style: TextStyle(color: Brand.gris))),
              if (lodgings.isNotEmpty && count == 0)
                const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                        'No hay personas pendientes de hospedaje (marca «necesita hospedaje» al registrar).',
                        style: TextStyle(color: Brand.gris))),
            ]),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          ErrorBox(
              'No se pudo preparar la sugerencia. Detalle técnico: $error'),
        ],
        if (proposals != null) ...[
          const SizedBox(height: 16),
          if (proposals!.isEmpty)
            const Text('No hay propuestas.',
                style: TextStyle(color: Brand.gris)),
          for (final e in proposals!.indexed)
            if (!dismissed.contains(e.$1))
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _proposalCard(e.$1, e.$2, lodgings),
              ),
          if (proposals!.isNotEmpty && dismissed.length == proposals!.length)
            const Text('Listo. No quedan propuestas por revisar.',
                key: Key('sg-fin'), style: TextStyle(color: Brand.gris)),
        ],
      ]),
    );
  }

  Widget _proposalCard(
      int i, LodgingProposal prop, List<LodgingView> lodgings) {
    final legs = legsByProposal[i]!;
    final isEditing = editing.contains(i);
    final warns = isEditing ? _warnings(i, lodgings) : const <String>[];
    return ProposalCard(
      label: 'PROPUESTA ${i + 1}',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final l in legs) ...[
          _legView(i, l, lodgings, isEditing),
          const SizedBox(height: 10),
        ],
        if (prop.unplaced.isNotEmpty)
          Container(
            key: Key('sg-sin-lugar-$i'),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Brand.avisoSuave,
                borderRadius: BorderRadius.circular(10)),
            child: Text(
                'Sin lugar (${prop.unplaced.length}): ${prop.unplaced.map((p) => p.name).join(', ')}',
                style: const TextStyle(color: Brand.avisoTexto)),
          ),
        for (final n in prop.notes)
          Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(n, style: const TextStyle(color: Brand.avisoTexto))),
        for (final w in warns)
          Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(w, style: const TextStyle(color: Brand.error))),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton(
              key: Key('sg-aceptar-$i'),
              onPressed:
                  busy || legs.isEmpty ? null : () => _accept(i, lodgings),
              child: const Text('Aceptar')),
          OutlinedButton(
              key: Key('sg-modificar-$i'),
              onPressed: () => setState(
                  () => isEditing ? editing.remove(i) : editing.add(i)),
              child: Text(isEditing ? 'Listo con los cambios' : 'Modificar')),
          TextButton(
              key: Key('sg-descartar-$i'),
              onPressed: () => setState(() => dismissed.add(i)),
              child: const Text('Descartar')),
        ]),
      ]),
    );
  }

  Widget _legView(int i, _Leg l, List<LodgingView> lodgings, bool isEditing) {
    final lv = lodgings.where((x) => x.row.id == l.lodgingId).firstOrNull;
    final names = l.people.map((p) => p.name).join(', ');
    final before = lv?.occupied ?? 0;
    final cap = lv?.row.capacity ?? 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (isEditing)
          DropdownButton<String>(
            key: Key('sg-cambiar-$i-${l.people.first.id}'),
            isExpanded: true,
            value: lodgings.any((x) => x.row.id == l.lodgingId)
                ? l.lodgingId
                : null,
            items: [
              for (final x in lodgings)
                DropdownMenuItem(
                    value: x.row.id,
                    enabled: x.row.id == l.lodgingId ||
                        lodgingBlockers(x.slot, l.people).isEmpty,
                    child: Text(
                        '${x.row.name} · ${lodgingAcceptsLabel(lodgingAcceptsFromDb(x.row.accepts))} · ${x.free < 0 ? 0 : x.free} libres${x.row.id != l.lodgingId && lodgingBlockers(x.slot, l.people).isNotEmpty ? ' · no compatible' : ''}',
                        overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (v) => setState(() => l.lodgingId = v ?? l.lodgingId),
          )
        else
          Text(lv?.row.name ?? 'Hospedaje',
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(
            '${l.people.length} ${l.people.length == 1 ? 'persona' : 'personas'}: $names'),
        const SizedBox(height: 2),
        Text('Ocupación: $before → ${before + l.people.length} de $cap plazas',
            style: const TextStyle(color: Brand.gris)),
        if (!isEditing)
          Text(l.reason, style: const TextStyle(color: Brand.gris)),
      ]),
    );
  }
}

class _PeoplePicker extends StatefulWidget {
  const _PeoplePicker(
      {required this.people, required this.spouses, required this.initial});
  final List<AttendeeView> people;
  final Map<String, String> spouses;
  final Set<String> initial;
  @override
  State<_PeoplePicker> createState() => _PeoplePickerState();
}

class _PeoplePickerState extends State<_PeoplePicker> {
  late final sel = {...widget.initial};
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  /// Personas que coinciden con la búsqueda (nombre o número, sin tildes ni mayúsculas).
  List<AttendeeView> get _shown {
    final q = normalizeText(search.text);
    if (q.isEmpty) return widget.people;
    return [
      for (final v in widget.people)
        if (normalizeText('${v.fullName} ${v.a.regNumber}').contains(q)) v
    ];
  }

  /// Marcar/desmarcar a una persona arrastra a su cónyuge (siempre juntos en un hospedaje).
  void _toggle(AttendeeView v, bool on) {
    final ids = {
      v.a.id,
      if (widget.spouses[v.a.id] != null) widget.spouses[v.a.id]!
    };
    setState(() => on ? sel.addAll(ids) : sel.removeAll(ids));
  }

  /// «Marcar todos» / «Desmarcar todos» actúan sobre los que se ven (los de la búsqueda).
  void _all(bool on) {
    final ids = <String>{};
    for (final v in _shown) {
      ids.add(v.a.id);
      final sp = widget.spouses[v.a.id];
      if (sp != null) ids.add(sp);
    }
    setState(() => on ? sel.addAll(ids) : sel.removeAll(ids));
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shown;
    final filtering = search.text.trim().isNotEmpty;
    return AlertDialog(
      title: const Text('Elegir personas'),
      content: SizedBox(
        width: 460,
        height: 520,
        child: Column(children: [
          TextField(
            key: const Key('sgp-buscar'),
            controller: search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o número…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpiar',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(search.clear)),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
                filtering
                    ? '${shown.length} de ${widget.people.length} · ${sel.length} marcadas'
                    : '${sel.length} de ${widget.people.length} marcadas',
                key: const Key('sgp-conteo'),
                style: const TextStyle(color: Brand.gris)),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(spacing: 8, children: [
              TextButton(
                  key: const Key('sgp-marcar-todos'),
                  onPressed: shown.isEmpty ? null : () => _all(true),
                  child: const Text('Marcar todos')),
              TextButton(
                  key: const Key('sgp-desmarcar-todos'),
                  onPressed: shown.isEmpty ? null : () => _all(false),
                  child: const Text('Desmarcar todos')),
            ]),
          ),
          Expanded(
            child: shown.isEmpty
                ? const Center(
                    child: Text('Nadie coincide con la búsqueda.',
                        key: Key('sgp-vacio'),
                        style: TextStyle(color: Brand.gris)))
                : ListView(children: [
                    for (final v in shown)
                      CheckboxListTile(
                        key: Key('sgp-${v.a.regNumber}'),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: sel.contains(v.a.id),
                        onChanged: (on) => _toggle(v, on ?? false),
                        title: Text(v.fullName,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                            '${v.isMale ? 'Hombre' : 'Mujer'} · ${v.a.age} años${widget.spouses[v.a.id] != null ? ' · con su cónyuge' : ''}'),
                      ),
                  ]),
          ),
        ]),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(
            key: const Key('sgp-ok'),
            onPressed: sel.isEmpty ? null : () => Navigator.pop(context, sel),
            child: Text('Usar ${sel.length}')),
      ],
    );
  }
}
