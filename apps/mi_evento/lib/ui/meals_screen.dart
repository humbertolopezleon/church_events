import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'event_dates.dart' show isoDate;
import 'widgets/labeled_field.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import '../data/database.dart';
import '../data/meal_repo.dart';
import '../data/repository.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import 'auth_screens.dart' show ErrorBox;
import 'meal_summary_screen.dart';
import 'quick_register_dialog.dart';

/// Control de comidas y otros registros por persona. Pensado para usarse de pie, con prisa:
/// escribir un nombre o número, Enter (o tocar «Marcar»), y el contador sube en vivo.
class MealsScreen extends ConsumerStatefulWidget {
  const MealsScreen({super.key});
  @override
  ConsumerState<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends ConsumerState<MealsScreen> {
  final query = TextEditingController();
  final focus = FocusNode();
  ({
    String name,
    String text,
    String recordId
  })? lastOk; // confirmación de la última marca
  String? error;

  String get eventId => ref.read(currentEventIdProvider)!;

  @override
  void initState() {
    super.initState();
    ref.read(mealRepoProvider).ensureDefaultTypes(eventId);
  }

  SessionView? _current(List<SessionView> all) {
    if (all.isEmpty) return null;
    final id = ref.watch(currentSessionIdProvider);
    return all.where((s) => s.row.id == id).firstOrNull ??
        all.where((s) => !s.closed).firstOrNull ??
        all.first;
  }

  String get _operator => ref.read(currentUserProvider)?.displayName ?? '';

  Future<void> _mark(SessionView s, AttendeeView v) async {
    setState(() => error = null);
    try {
      final r = await ref
          .read(mealRepoProvider)
          .mark(s.row.id, v.a.id, operatorName: _operator);
      if (!mounted) return;
      if (r.already) {
        await _alreadyDialog(s, v, r.record);
      } else {
        setState(() => lastOk = (
              name: v.fullName,
              text: canDoText(s.typeName),
              recordId: r.record.id
            ));
        query.clear();
      }
    } on DataException catch (e) {
      if (mounted) setState(() => error = e.message);
    }
    if (mounted) focus.requestFocus();
  }

  /// Registra a una persona que no estaba inscrita y la marca en esta sesión de una vez.
  Future<void> _register(SessionView s) async {
    final row = await showDialog<AttendeeRow>(
        context: context,
        builder: (_) =>
            QuickRegisterDialog(eventId: eventId, initialText: query.text));
    if (row == null || !mounted) return;
    try {
      final r = await ref
          .read(mealRepoProvider)
          .mark(s.row.id, row.id, operatorName: _operator);
      if (!mounted) return;
      setState(() {
        lastOk = (
          name: [row.firstName, row.lastName1, row.lastName2]
              .where((e) => e.isNotEmpty)
              .join(' '),
          text: 'Registrado y marcado (n.º ${row.regNumber})',
          recordId: r.record.id
        );
        query.clear();
      });
    } on DataException catch (e) {
      if (mounted) setState(() => error = e.message);
    }
    if (mounted) focus.requestFocus();
  }

  Future<void> _alreadyDialog(
      SessionView s, AttendeeView v, ControlRecord rec) async {
    final team =
        (ref.read(teamsProvider(eventId)).valueOrNull ?? const <TeamRow>[])
            .where((t) => t.id == v.a.teamId)
            .firstOrNull;
    final again = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        key: const Key('cm-ya-paso'),
        backgroundColor: Brand.avisoSuave,
        shape: const RoundedRectangleBorder(
            side: BorderSide(color: Brand.aviso, width: 4),
            borderRadius: BorderRadius.all(Radius.circular(20))),
        icon: const Icon(Icons.warning_amber_rounded,
            color: Brand.avisoTexto, size: 48),
        title: const Text('YA PASÓ POR ESTA SESIÓN',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 16,
                color: Brand.avisoTexto,
                fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: 420,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
                '${v.fullName} ${alreadyDoneText(s.typeName)} a las ${hhmm(rec.markedAt.toLocal())}',
                textAlign: TextAlign.center,
                style: headStyle(26)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                _kv('Marcado por',
                    rec.operatorName.isEmpty ? '—' : rec.operatorName),
                _kv('Iglesia', v.churchName ?? '—'),
                if (ref.read(eventProvider(eventId)).valueOrNull?.offersTeams ??
                    true)
                  _kv('Equipo', team?.name ?? 'Sin equipo'),
              ]),
            ),
          ]),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsOverflowAlignment: OverflowBarAlignment.center,
        actions: [
          FilledButton(
              key: const Key('cm-entendido'),
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Entendido, no marcar')),
          OutlinedButton(
              key: const Key('cm-repetir'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: Brand.avisoTexto,
                  side: const BorderSide(color: Color(0xFFC98A00))),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Marcar otra vez de todas formas')),
        ],
      ),
    );
    final repo = ref.read(mealRepoProvider);
    if (again == true) {
      final r = await repo.mark(s.row.id, v.a.id,
          operatorName: _operator, repeat: true);
      if (mounted) {
        setState(() => lastOk = (
              name: v.fullName,
              text: 'Marcado otra vez',
              recordId: r.record.id
            ));
        query.clear();
      }
    } else {
      await repo.registerBlocked(s.row.id);
    }
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(k, style: const TextStyle(color: Brand.gris)),
          Flexible(
              child: Text(v,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w700))),
        ]),
      );

  Future<void> _close(SessionView s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Cerrar «${s.row.name}»?'),
        content: const Text(
            'Ya no se podrá marcar a nadie, pero puedes reabrirla. Verás el resumen para exportarlo.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              key: const Key('cm-cerrar-ok'),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cerrar y ver resumen')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref.read(mealRepoProvider).closeSession(s.row.id);
    ref.read(autoBackupProvider).noteChange(eventId,
        force: true); // al cerrar una comida siempre hay copia
    if (mounted) {
      await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => MealSummaryScreen(sessionId: s.row.id)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(sessionsProvider(eventId)).valueOrNull ??
        const <SessionView>[];
    final s = _current(sessions);
    final views = ref.watch(confirmedAttendeesProvider(eventId)).valueOrNull ??
        const <AttendeeView>[];
    ref.watch(teamsProvider(
        eventId)); // mantiene los equipos cargados para el aviso de «ya pasó»

    return Scaffold(
      appBar: AppBar(title: const Text('Control de comidas')),
      body: s == null ? _empty() : _body(s, sessions, views),
    );
  }

  Widget _empty() => Center(
        // Se desplaza si la pantalla es baja o la letra grande (antes desbordaba 173 px).
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Todavía no hay sesiones de control',
                key: const Key('cm-vacio'),
                textAlign: TextAlign.center,
                style: headStyle(24)),
            const SizedBox(height: 8),
            const Text(
                'Una sesión es, por ejemplo, «Almuerzo del sábado». Créala y empieza a marcar quién pasa.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Brand.gris)),
            const SizedBox(height: 16),
            FilledButton.icon(
                key: const Key('cm-nueva'),
                onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => NewSessionDialog(eventId: eventId)),
                icon: const Icon(Icons.add),
                label: const Text('Crear sesión')),
          ]),
        ),
      );

  Widget _body(
      SessionView s, List<SessionView> sessions, List<AttendeeView> views) {
    final records = ref.watch(recordsProvider(s.row.id)).valueOrNull ??
        const <ControlRecord>[];
    final passedIds = {for (final r in records) r.attendeeId};
    final stats = computeMealStats([
      for (final v in views)
        MealPerson(id: v.a.id, sexIsMale: v.isMale, teamId: v.a.teamId)
    ], passedIds);
    final byId = {for (final v in views) v.a.id: v};
    final firstTime = <String, ControlRecord>{};
    for (final r in records.reversed) {
      firstTime.putIfAbsent(
          r.attendeeId, () => r); // la más antigua de cada persona
    }
    final results = query.text.trim().isEmpty
        ? const <AttendeeView>[]
        : Repository.search(views, query.text).take(6).toList();
    // QA-WIN-05: un preinscrito no se marca, pero se avisa en vez de decir «Nadie con ese nombre».
    final pending = query.text.trim().isEmpty || results.isNotEmpty
        ? const <AttendeeView>[]
        : Repository.search(
            [
              for (final v
                  in ref.watch(attendeesProvider(eventId)).valueOrNull ??
                      const <AttendeeView>[])
                if (v.isPreregistered) v
            ],
            query.text,
          ).take(6).toList();

    return ListView(padding: const EdgeInsets.all(16), children: [
      Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 320,
              child: LabeledField(
                  label: 'Sesión',
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('ses-${s.row.id}'),
                    initialValue: s.row.id,
                    isExpanded: true,
                    decoration: const InputDecoration(),
                    items: [
                      for (final x in sessions)
                        DropdownMenuItem(
                            value: x.row.id,
                            child: Text(
                                '${x.row.name}${x.row.scheduledAt == null ? '' : ' · ${x.row.scheduledAt!.toLocal().day}/${x.row.scheduledAt!.toLocal().month}'}${x.closed ? ' (cerrada)' : ''}',
                                overflow: TextOverflow.ellipsis))
                    ],
                    onChanged: (v) => setState(() {
                      ref.read(currentSessionIdProvider.notifier).state = v;
                      lastOk = null;
                    }),
                  )),
            ),
            OutlinedButton.icon(
                key: const Key('cm-nueva'),
                onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => NewSessionDialog(eventId: eventId)),
                icon: const Icon(Icons.add),
                label: const Text('Nueva sesión')),
            OutlinedButton.icon(
                key: const Key('cm-tipos'),
                onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => TypesDialog(eventId: eventId)),
                icon: const Icon(Icons.tune),
                label: const Text('Tipos de control')),
            if (s.closed) ...[
              FilledButton.icon(
                  key: const Key('cm-resumen'),
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) =>
                              MealSummaryScreen(sessionId: s.row.id))),
                  icon: const Icon(Icons.summarize_outlined),
                  label: const Text('Ver resumen')),
              OutlinedButton(
                  key: const Key('cm-reabrir'),
                  onPressed: () =>
                      ref.read(mealRepoProvider).reopenSession(s.row.id),
                  child: const Text('Reabrir')),
            ] else
              OutlinedButton(
                  key: const Key('cm-cerrar'),
                  onPressed: () => _close(s),
                  child: const Text('Cerrar esta comida')),
          ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
            child: _Counter('Inscritos', '${stats.total}', null, null,
                key: const Key('cm-inscritos'))),
        const SizedBox(width: 8),
        Expanded(
            child: _Counter('Pasaron', '${stats.passed}', Brand.exitoSuave,
                const Color(0xFF14592F),
                key: const Key('cm-pasaron'))),
        const SizedBox(width: 8),
        Expanded(
          child: InkWell(
            key: const Key('cm-faltan'),
            borderRadius: BorderRadius.circular(16),
            onTap: () => showDialog<void>(
                context: context,
                builder: (_) =>
                    _PendingDialog(views: views, passedIds: passedIds)),
            child: _Counter('Faltan ›', '${stats.pending}', Brand.naranjaSuave,
                const Color(0xFF8F4512),
                key: const Key('cm-faltan-n')),
          ),
        ),
      ]),
      const SizedBox(height: 12),
      if (s.closed)
        Container(
          key: const Key('cm-cerrada'),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Brand.avisoSuave,
              border: Border.all(color: Brand.aviso, width: 2),
              borderRadius: BorderRadius.circular(12)),
          child: const Row(children: [
            Icon(Icons.lock_outline, color: Brand.avisoTexto),
            SizedBox(width: 10),
            Expanded(
                child: Text(
                    'Esta sesión está cerrada. Reábrela para marcar a más personas.'))
          ]),
        )
      else ...[
        if (lastOk != null)
          Container(
            key: const Key('cm-ok'),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
            decoration: BoxDecoration(
                color: Brand.exitoSuave,
                borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.check_circle, color: Brand.exito, size: 30),
              const SizedBox(width: 10),
              Expanded(
                  child: Text('${lastOk!.text}: ${lastOk!.name}',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700))),
              TextButton(
                  key: const Key('cm-deshacer'),
                  onPressed: () async {
                    await ref.read(mealRepoProvider).undo(lastOk!.recordId);
                    if (mounted) setState(() => lastOk = null);
                  },
                  child: const Text('Deshacer')),
            ]),
          ),
        TextField(
          key: const Key('cm-buscar'),
          controller: query,
          focusNode: focus,
          autofocus: true,
          onChanged: (_) => setState(() => lastOk = null),
          onSubmitted: (_) {
            // Enter marca a la primera persona de la lista (si ya pasó, se muestra el aviso)
            if (results.isNotEmpty) _mark(s, results.first);
          },
          decoration: InputDecoration(
            hintText: 'Escribe un nombre o el número de inscripción',
            helperText: 'Enter marca a la primera persona de la lista',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: query.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Limpiar',
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(query.clear)),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
              key: const Key('cm-registrar'),
              onPressed: () => _register(s),
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Registrar persona nueva')),
        ),
        if (error != null) ...[const SizedBox(height: 8), ErrorBox(error!)],
        if (query.text.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          if (results.isEmpty && pending.isNotEmpty)
            Card(
                key: const Key('cm-preinscrito'),
                color: Brand.avisoSuave,
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                        '${pending.map((v) => '${v.fullName} (n.º ${v.a.regNumber})').join(', ')} '
                        '${pending.length == 1 ? 'está preinscrito/a' : 'están preinscritos'}: '
                        'confirma primero su asistencia en «Confirmar asistencia».',
                        style: const TextStyle(fontSize: 16))))
          else if (results.isEmpty)
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                              'Nadie con ese nombre. ¿Falta registrarlo?',
                              style:
                                  TextStyle(color: Brand.gris, fontSize: 16)),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                              key: const Key('cm-registrar-vacio'),
                              onPressed: () => _register(s),
                              icon: const Icon(Icons.person_add_alt_1_outlined),
                              label: const Text('Registrar a esta persona')),
                        ])))
          else
            Card(
              child: Column(children: [
                for (final v in results)
                  ListTile(
                    key: Key('cm-res-${v.a.regNumber}'),
                    minTileHeight: 60,
                    title: Text(v.fullName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 17)),
                    subtitle: Text(
                        'Nº ${v.a.regNumber} · ${v.churchName ?? ''} · ${v.a.age} años'),
                    trailing: passedAlready(v, passedIds)
                        ? Text(
                            'pasó ${hhmm(firstTime[v.a.id]!.markedAt.toLocal())}',
                            style: const TextStyle(color: Brand.gris))
                        : FilledButton(
                            key: Key('cm-marcar-${v.a.regNumber}'),
                            style: FilledButton.styleFrom(
                                backgroundColor: Brand.naranja,
                                foregroundColor: Brand.tinta,
                                minimumSize: const Size(96, 44)),
                            onPressed: () => _mark(s, v),
                            child: const Text('Marcar')),
                    onTap:
                        passedAlready(v, passedIds) ? () => _mark(s, v) : null,
                  ),
              ]),
            ),
        ],
      ],
      const SizedBox(height: 16),
      Text('Últimos en pasar', style: headStyle(20)),
      const SizedBox(height: 6),
      if (records.isEmpty)
        const Text('Aún no ha pasado nadie.',
            style: TextStyle(color: Brand.gris)),
      for (final r in records.take(5))
        if (byId[r.attendeeId] != null)
          Card(
            child: ListTile(
              key: Key('cm-ultimo-${byId[r.attendeeId]!.a.regNumber}'),
              title: Text(byId[r.attendeeId]!.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(
                  '${hhmm(r.markedAt.toLocal())}${r.operatorName.isEmpty ? '' : ' · ${r.operatorName}'}${r.repeatOverride ? ' · repetido' : ''}${byId[r.attendeeId]!.a.registeredAtControl ? ' · registrado en el control' : ''}'),
              trailing: s.closed
                  ? null
                  : TextButton(
                      key: Key(
                          'cm-ultimo-deshacer-${byId[r.attendeeId]!.a.regNumber}'),
                      onPressed: () => ref.read(mealRepoProvider).undo(r.id),
                      child: const Text('Deshacer')),
            ),
          ),
    ]);
  }

  bool passedAlready(AttendeeView v, Set<String> passed) =>
      passed.contains(v.a.id);
}

class _Counter extends StatelessWidget {
  const _Counter(this.label, this.value, this.bg, this.fg, {super.key});
  final String label, value;
  final Color? bg, fg;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
            color: bg ?? Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Brand.borde)),
        child: Column(children: [
          Text(label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: fg ?? Brand.gris)),
          Text(value, style: headStyle(40, color: fg)),
        ]),
      );
}

class _PendingDialog extends StatefulWidget {
  const _PendingDialog({required this.views, required this.passedIds});
  final List<AttendeeView> views;
  final Set<String> passedIds;
  @override
  State<_PendingDialog> createState() => _PendingDialogState();
}

class _PendingDialogState extends State<_PendingDialog> {
  final q = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final pending =
        widget.views.where((v) => !widget.passedIds.contains(v.a.id)).toList();
    final list = Repository.search(pending, q.text);
    return AlertDialog(
      key: const Key('cm-pendientes'),
      title: Text('Faltan (${pending.length})'),
      content: SizedBox(
        width: 440,
        height: 440,
        child: Column(children: [
          TextField(
              key: const Key('pend-buscar'),
              controller: q,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                  hintText: 'Buscar entre quienes faltan…',
                  prefixIcon: Icon(Icons.search))),
          const SizedBox(height: 8),
          Expanded(
            child: list.isEmpty
                ? const Center(
                    child: Text('Nadie falta con ese filtro.',
                        style: TextStyle(color: Brand.gris)))
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) => ListTile(
                      key: Key('pend-${list[i].a.regNumber}'),
                      dense: true,
                      title: Text(list[i].fullName),
                      subtitle: Text(
                          'Nº ${list[i].a.regNumber}${list[i].churchName == null ? '' : ' · ${list[i].churchName}'}'),
                    ),
                  ),
          ),
        ]),
      ),
      actions: [
        FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'))
      ],
    );
  }
}

class NewSessionDialog extends ConsumerStatefulWidget {
  const NewSessionDialog({super.key, required this.eventId});
  final String eventId;
  @override
  ConsumerState<NewSessionDialog> createState() => _NewSessionDialogState();
}

class _NewSessionDialogState extends ConsumerState<NewSessionDialog> {
  final name = TextEditingController();
  String? typeId;
  String? typeName;
  String? error;
  String _auto = '';
  DateTime? date; // día de la sesión; por defecto, el primer día del evento

  DateTime? _eventDay(String iso) {
    final d = DateTime.tryParse(iso);
    return d == null ? null : DateTime(d.year, d.month, d.day);
  }

  void _pickType(ControlType t) {
    typeId = t.id;
    typeName = t.name;
    _suggestName();
  }

  /// El nombre se sugiere solo mientras la persona no lo haya cambiado a mano.
  void _suggestName() {
    final wasAuto = name.text.isEmpty || name.text == _auto;
    _auto = suggestSessionName(typeName ?? '', date ?? DateTime.now());
    if (wasAuto) name.text = _auto;
  }

  Future<void> _pickDate(Event ev) async {
    final first = _eventDay(ev.startDate), last = _eventDay(ev.endDate);
    if (first == null || last == null) return;
    final cur = date ?? first;
    final r = await showDatePicker(
      context: context,
      initialDate:
          cur.isBefore(first) ? first : (cur.isAfter(last) ? last : cur),
      firstDate: first,
      lastDate: last,
      helpText: 'Fecha de la sesión',
    );
    if (r != null) {
      setState(() {
        date = r;
        _suggestName();
      });
    }
  }

  Future<void> _create(List<ControlType> types) async {
    final t = typeId ?? (types.isEmpty ? null : types.first.id);
    if (t == null) {
      setState(() => error = 'Falta elegir el tipo de control.');
      return;
    }
    try {
      final s = await ref.read(mealRepoProvider).createSession(
          widget.eventId, t, name.text,
          operatorName: ref.read(currentUserProvider)?.displayName ?? '',
          date: date);
      ref.read(currentSessionIdProvider.notifier).state = s.id;
      if (mounted) Navigator.pop(context);
    } on DataException catch (e) {
      setState(() => error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final types = ref.watch(controlTypesProvider(widget.eventId)).valueOrNull ??
        const <ControlType>[];
    final event = ref.watch(eventProvider(widget.eventId)).valueOrNull;
    if (date == null && event != null) {
      date = _eventDay(event.startDate);
    }
    if (typeId == null && types.isNotEmpty) {
      final t = types.firstWhere((x) => x.name == 'Almuerzo',
          orElse: () => types.first);
      _pickType(t);
    }
    return AlertDialog(
      title: const Text('Nueva sesión de control'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            LabeledField(
                label: 'Tipo de control',
                child: DropdownButtonFormField<String>(
                  key: const Key('ns-tipo'),
                  initialValue: typeId,
                  isExpanded: true,
                  decoration: const InputDecoration(),
                  items: [
                    for (final t in types)
                      DropdownMenuItem(value: t.id, child: Text(t.name))
                  ],
                  onChanged: (v) => setState(
                      () => _pickType(types.firstWhere((t) => t.id == v))),
                )),
            const SizedBox(height: 12),
            if (event != null && date != null)
              LabeledField(
                  label: 'Fecha de la sesión',
                  child: OutlinedButton.icon(
                    key: const Key('ns-fecha'),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        alignment: Alignment.centerLeft),
                    onPressed: () => _pickDate(event),
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text('${weekdayEs(date!)} ${isoDate(date!)}'),
                  )),
            const SizedBox(height: 12),
            LabeledField(
                label: 'Nombre de la sesión',
                child: TextField(
                    key: const Key('ns-nombre'),
                    controller: name,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                        helperText: 'Ej.: Almuerzo del sábado'))),
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
            key: const Key('ns-crear'),
            onPressed: () => _create(types),
            child: const Text('Crear sesión')),
      ],
    );
  }
}

class TypesDialog extends ConsumerStatefulWidget {
  const TypesDialog({super.key, required this.eventId});
  final String eventId;
  @override
  ConsumerState<TypesDialog> createState() => _TypesDialogState();
}

class _TypesDialogState extends ConsumerState<TypesDialog> {
  final name = TextEditingController();
  String? error;

  Future<void> _add() async {
    try {
      await ref.read(mealRepoProvider).createType(widget.eventId, name.text);
      setState(() {
        name.clear();
        error = null;
      });
    } on DataException catch (e) {
      setState(() => error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final types = ref.watch(controlTypesProvider(widget.eventId)).valueOrNull ??
        const <ControlType>[];
    return AlertDialog(
      title: const Text('Tipos de control'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    'Lo que quieras controlar por persona: comidas, entrega de materiales, asistencia a un taller…',
                    style: TextStyle(color: Brand.gris)),
                const SizedBox(height: 8),
                for (final t in types)
                  ListTile(
                    key: Key('tp-${t.name}'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(t.name),
                    trailing: IconButton(
                      key: Key('tp-eliminar-${t.name}'),
                      tooltip: 'Eliminar',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        try {
                          await ref.read(mealRepoProvider).deleteType(t.id);
                          setState(() => error = null);
                        } on DataException catch (e) {
                          setState(() => error = e.message);
                        }
                      },
                    ),
                  ),
                const Divider(),
                LabeledField(
                    label: 'Tipo nuevo',
                    child: TextField(
                        key: const Key('tp-nombre'),
                        controller: name,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _add(),
                        decoration: const InputDecoration(
                            helperText: 'Ej.: Entrega de materiales'))),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                    key: const Key('tp-agregar'),
                    onPressed: _add,
                    icon: const Icon(Icons.add),
                    label: const Text('Añadir tipo')),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  ErrorBox(error!)
                ],
              ]),
        ),
      ),
      actions: [
        FilledButton(
            onPressed: () => Navigator.pop(context), child: const Text('Listo'))
      ],
    );
  }
}
