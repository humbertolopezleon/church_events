import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'widgets/labeled_field.dart';

import '../data/repos_b.dart';
import '../data/repository.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import 'auth_screens.dart' show ErrorBox;

/// Elegir una persona con búsqueda. [exclude] oculta a quienes no deben salir (p. ej. uno mismo).
Future<AttendeeView?> pickPerson(
  BuildContext context, {
  required List<AttendeeView> all,
  Set<String> exclude = const {},
  String title = 'Elegir persona',
  bool Function(AttendeeView)? where,
}) {
  return showDialog<AttendeeView>(
    context: context,
    builder: (_) => _PersonPicker(
        all: all
            .where((v) => !exclude.contains(v.a.id) && (where?.call(v) ?? true))
            .toList(),
        title: title),
  );
}

class _PersonPicker extends StatefulWidget {
  const _PersonPicker({required this.all, required this.title});
  final List<AttendeeView> all;
  final String title;
  @override
  State<_PersonPicker> createState() => _PersonPickerState();
}

class _PersonPickerState extends State<_PersonPicker> {
  final q = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final list = Repository.search(widget.all, q.text).take(30).toList();
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 440,
        height: 420,
        child: Column(children: [
          TextField(
            key: const Key('pp-buscar'),
            controller: q,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
                hintText: 'Buscar por nombre, iglesia o número…',
                prefixIcon: Icon(Icons.search)),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: list.isEmpty
                ? const Center(
                    child: Text('Nadie coincide.',
                        style: TextStyle(color: Brand.gris)))
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final v = list[i];
                      return ListTile(
                        key: Key('pp-${v.a.regNumber}'),
                        minTileHeight: 56,
                        title: Text(v.fullName,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                            'Nº ${v.a.regNumber} · ${v.isMale ? 'Hombre' : 'Mujer'} · ${v.a.age} años${v.churchName == null ? '' : ' · ${v.churchName}'}'),
                        onTap: () => Navigator.pop(context, v),
                      );
                    },
                  ),
          ),
        ]),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'))
      ],
    );
  }
}

/// Elegir los grupos de una persona (varios) y crear grupos nuevos al vuelo.
Future<Set<String>?> pickGroups(BuildContext context,
        {required String eventId, required Set<String> selected}) =>
    showDialog<Set<String>>(
        context: context,
        builder: (_) => _GroupPicker(eventId: eventId, selected: selected));

class _GroupPicker extends ConsumerStatefulWidget {
  const _GroupPicker({required this.eventId, required this.selected});
  final String eventId;
  final Set<String> selected;
  @override
  ConsumerState<_GroupPicker> createState() => _GroupPickerState();
}

class _GroupPickerState extends ConsumerState<_GroupPicker> {
  late final Set<String> sel = {...widget.selected};
  final name = TextEditingController();
  String reason = 'preference';
  String? error;

  Future<void> _create() async {
    try {
      final g = await ref
          .read(socialRepoProvider)
          .createGroup(widget.eventId, name.text, reason: reason);
      setState(() {
        sel.add(g.id);
        name.clear();
        error = null;
      });
    } on DataException catch (e) {
      setState(() => error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(groupsProvider(widget.eventId)).valueOrNull ??
        const <GroupView>[];
    return AlertDialog(
      title: const Text('Grupos'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    'Personas que quieren estar juntas (misma iglesia o por preferencia).',
                    style: TextStyle(color: Brand.gris)),
                const SizedBox(height: 8),
                if (groups.isEmpty)
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                          'Todavía no hay grupos. Crea el primero abajo.')),
                for (final g in groups)
                  CheckboxListTile(
                    key: Key('gp-${g.group.name}'),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: sel.contains(g.group.id),
                    onChanged: (v) => setState(() => v == true
                        ? sel.add(g.group.id)
                        : sel.remove(g.group.id)),
                    title: Text(g.group.name),
                    subtitle: Text(
                        '${g.memberCount} ${g.memberCount == 1 ? 'integrante' : 'integrantes'}'),
                  ),
                const Divider(),
                LabeledField(
                    label: 'Nombre del grupo nuevo',
                    child: TextField(
                        key: const Key('gp-nuevo-nombre'),
                        controller: name,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration())),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                        value: 'church', label: Text('Misma iglesia')),
                    ButtonSegment(
                        value: 'preference', label: Text('Preferencia')),
                  ],
                  selected: {reason},
                  onSelectionChanged: (s) => setState(() => reason = s.first),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                    key: const Key('gp-crear'),
                    onPressed: _create,
                    icon: const Icon(Icons.add),
                    label: const Text('Crear grupo')),
                if (error != null) ...[
                  const SizedBox(height: 8),
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
            key: const Key('gp-listo'),
            onPressed: () => Navigator.pop(context, sel),
            child: const Text('Listo')),
      ],
    );
  }
}
