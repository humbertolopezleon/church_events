import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'widgets/labeled_field.dart';

import '../data/database.dart';
import '../data/event_copy.dart';
import '../data/repository.dart' show DataException;
import '../providers.dart';
import '../theme/app_theme.dart';
import 'auth_screens.dart' show ErrorBox;

String _d(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Duplicar un evento con toda o parte de su información.
class DuplicateEventDialog extends ConsumerStatefulWidget {
  const DuplicateEventDialog({super.key, required this.event});
  final Event event;
  @override
  ConsumerState<DuplicateEventDialog> createState() =>
      _DuplicateEventDialogState();
}

class _DuplicateEventDialogState extends ConsumerState<DuplicateEventDialog> {
  late final name = TextEditingController(text: '${widget.event.name} (copia)');
  late DateTime start =
      DateTime.tryParse(widget.event.startDate) ?? DateTime.now();
  late DateTime end = DateTime.tryParse(widget.event.endDate) ?? start;
  bool people = true,
      preregister = true,
      teams = true,
      lodgings = true,
      groups = true;
  bool busy = false;
  String? error;

  Future<void> _pickRange() async {
    final r = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: start, end: end),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Fechas del evento nuevo',
      saveText: 'Aceptar',
    );
    if (r != null) {
      setState(() {
        start = r.start;
        end = r.end;
      });
    }
  }

  Future<void> _save() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final copier = EventCopy(ref.read(databaseProvider));
      final id = await copier.duplicateEvent(
        widget.event.id,
        name: name.text,
        startDate: _d(start),
        endDate: _d(end),
        options: DuplicateOptions(
            people: people,
            preregister: preregister,
            teams: teams,
            lodgings: lodgings,
            groups: groups),
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      ref.read(currentEventIdProvider.notifier).state = id;
      if (copier.lastUnassignedForCompatibility > 0) {
        messenger.showSnackBar(SnackBar(
            content: Text(
                '${copier.lastUnassignedForCompatibility} ${copier.lastUnassignedForCompatibility == 1 ? 'persona quedó' : 'personas quedaron'} sin hospedaje en la copia porque no encajaban con el hospedaje (sexo o matrimonio).')));
      }
    } on DataException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => error = 'No se pudo duplicar. Detalle técnico: $e');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget _check(String key, String title, bool v, ValueChanged<bool> on,
          {String? subtitle, bool enabled = true}) =>
      CheckboxListTile(
          key: Key(key),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          value: v,
          title: Text(title),
          subtitle: subtitle == null ? null : Text(subtitle),
          onChanged: enabled && !busy ? (x) => on(x ?? false) : null);

  @override
  Widget build(BuildContext context) => AlertDialog(
        key: const Key('dup-dialogo'),
        title: const Text('Duplicar evento'),
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
                          key: const Key('dup-nombre'),
                          controller: name,
                          decoration: const InputDecoration())),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const Key('dup-fechas'),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        alignment: Alignment.centerLeft),
                    onPressed: _pickRange,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(_d(start) == _d(end)
                        ? 'Fechas: un solo día ${_d(start)}'
                        : 'Fechas: ${_d(start)}  →  ${_d(end)}'),
                  ),
                  const SizedBox(height: 12),
                  const Text('Qué se copia',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const Text(
                      'Siempre: datos del evento, rangos de edad y tipos de control (comidas…).',
                      style: TextStyle(color: Brand.gris)),
                  _check('dup-personas', 'Participantes', people,
                      (v) => setState(() => people = v)),
                  _check('dup-preinscribir', 'Dejarlos como preinscritos',
                      preregister, (v) => setState(() => preregister = v),
                      subtitle: 'La asistencia se confirma el día del evento.',
                      enabled: people),
                  _check('dup-grupos', 'Grupos', groups,
                      (v) => setState(() => groups = v),
                      enabled: people),
                  _check('dup-equipos', 'Equipos', teams,
                      (v) => setState(() => teams = v),
                      subtitle: people
                          ? 'Con los participantes, cada uno conserva su equipo.'
                          : null),
                  _check('dup-hospedajes', 'Hospedajes', lodgings,
                      (v) => setState(() => lodgings = v),
                      subtitle: people
                          ? 'Con los participantes, cada uno conserva su hospedaje.'
                          : null),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    ErrorBox(error!)
                  ],
                ]),
          ),
        ),
        actions: [
          TextButton(
              onPressed: busy ? null : () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              key: const Key('dup-guardar'),
              onPressed: busy ? null : _save,
              child: Text(busy ? 'Duplicando…' : 'Duplicar')),
        ],
      );
}

/// Pasar los participantes de un evento a otro que ya existe.
class CopyPeopleDialog extends ConsumerStatefulWidget {
  const CopyPeopleDialog({super.key, required this.event});
  final Event event;
  @override
  ConsumerState<CopyPeopleDialog> createState() => _CopyPeopleDialogState();
}

class _CopyPeopleDialogState extends ConsumerState<CopyPeopleDialog> {
  String? target;
  bool preregister = true;
  bool busy = false;
  String? error;

  Future<void> _go() async {
    if (target == null) {
      setState(
          () => error = 'Elige el evento al que pasar a los participantes.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final rep = await EventCopy(ref.read(databaseProvider))
          .copyPeople(widget.event.id, target!, preregister: preregister);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '${rep.copied} ${rep.copied == 1 ? 'persona pasada' : 'personas pasadas'}'
              '${rep.skipped > 0 ? ' · ${rep.skipped} ya estaban' : ''}.')));
    } on DataException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => error = 'No se pudo copiar. Detalle técnico: $e');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final others = [
      for (final e
          in ref.watch(eventsListProvider).valueOrNull ?? const <Event>[])
        if (e.id != widget.event.id) e
    ];
    return AlertDialog(
      key: const Key('pasar-dialogo'),
      title: const Text('Pasar participantes a otro evento'),
      content: SizedBox(
        width: 460,
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Desde «${widget.event.name}». Los que ya están en el destino (mismo nombre, apellido y edad) se omiten; los matrimonios se conservan.',
                  style: const TextStyle(color: Brand.gris)),
              const SizedBox(height: 12),
              LabeledField(
                  label: 'Evento destino',
                  child: DropdownButtonFormField<String>(
                    key: const Key('pasar-destino'),
                    isExpanded: true,
                    decoration: const InputDecoration(),
                    items: [
                      for (final e in others)
                        DropdownMenuItem(
                            value: e.id,
                            child:
                                Text(e.name, overflow: TextOverflow.ellipsis))
                    ],
                    onChanged: busy ? null : (v) => setState(() => target = v),
                  )),
              CheckboxListTile(
                  key: const Key('pasar-preinscribir'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: preregister,
                  title: const Text('Dejarlos como preinscritos'),
                  onChanged: busy
                      ? null
                      : (v) => setState(() => preregister = v ?? false)),
              if (error != null) ...[
                const SizedBox(height: 8),
                ErrorBox(error!)
              ],
            ]),
      ),
      actions: [
        TextButton(
            onPressed: busy ? null : () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(
            key: const Key('pasar-ok'),
            onPressed: busy ? null : _go,
            child: Text(busy ? 'Pasando…' : 'Pasar')),
      ],
    );
  }
}
