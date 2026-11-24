import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import '../data/database.dart';
import '../data/repos_b.dart';
import '../data/repository.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import 'new_spouse_dialog.dart';
import 'people_pickers.dart';

/// Matrimonio y grupos de una persona, dentro del formulario de asistente.
/// Los cambios se aplican al guardar el formulario (no antes).
class SocialSection extends ConsumerWidget {
  const SocialSection({
    super.key,
    required this.eventId,
    required this.selfId,
    required this.spouse,
    required this.groupIds,
    required this.onSpouse,
    required this.onGroups,
    this.spouseDraft,
    this.onSpouseDraft,
    this.selfSex,
    this.selfLastName = '',
  });
  final SpouseDraft? spouseDraft; // cónyuge que se inscribirá al guardar
  final ValueChanged<SpouseDraft?>? onSpouseDraft;
  final Sex? selfSex; // para marcar el sexo contrario en el cónyuge nuevo
  final String selfLastName;
  final String eventId;
  final String? selfId; // null al registrar a alguien nuevo
  final AttendeeRow? spouse;
  final Set<String> groupIds;
  final ValueChanged<AttendeeRow?> onSpouse;
  final ValueChanged<Set<String>> onGroups;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups =
        ref.watch(groupsProvider(eventId)).valueOrNull ?? const <GroupView>[];
    final names = {for (final g in groups) g.group.id: g.group.name};
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Matrimonio y grupos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (spouseDraft != null)
            Row(children: [
              const Icon(Icons.favorite_border, color: Brand.azul),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(
                      'Matrimonio con ${spouseDraft!.fullName} (se inscribirá al guardar)',
                      key: const Key('social-conyuge-nuevo'),
                      style: const TextStyle(fontWeight: FontWeight.w700))),
              TextButton(
                  key: const Key('social-quitar-conyuge-nuevo'),
                  onPressed: () => onSpouseDraft?.call(null),
                  child: const Text('Quitar')),
            ])
          else if (spouse != null)
            Row(children: [
              const Icon(Icons.favorite_border, color: Brand.azul),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(
                      'Matrimonio con ${spouse!.firstName} ${spouse!.lastName1}',
                      key: const Key('social-conyuge'),
                      style: const TextStyle(fontWeight: FontWeight.w700))),
              TextButton(
                  key: const Key('social-quitar-conyuge'),
                  onPressed: () => onSpouse(null),
                  child: const Text('Quitar')),
            ])
          else
            Wrap(spacing: 8, runSpacing: 8, children: [
              OutlinedButton.icon(
                key: const Key('social-vincular'),
                onPressed: () async {
                  final all =
                      ref.read(attendeesProvider(eventId)).valueOrNull ??
                          const <AttendeeView>[];
                  final v = await pickPerson(context,
                      all: all,
                      exclude: {if (selfId != null) selfId!},
                      title: 'Vincular matrimonio',
                      where: (v) =>
                          v.a.coupleId ==
                          null); // quien ya está casado no se ofrece
                  if (v != null) onSpouse(v.a);
                },
                icon: const Icon(Icons.favorite_border),
                label: const Text('Vincular matrimonio'),
              ),
              if (onSpouseDraft != null)
                FilledButton.tonalIcon(
                  key: const Key('social-conyuge-nuevo-btn'),
                  onPressed: selfSex == null
                      ? null
                      : () async {
                          final r = await showDialog<NewSpouseResult>(
                            context: context,
                            builder: (_) => NewSpouseDialog(
                                eventId: eventId,
                                spouseSex:
                                    selfSex == Sex.male ? Sex.female : Sex.male,
                                excludeId: selfId,
                                suggestedLastName: selfLastName),
                          );
                          if (r == null) return;
                          if (r.existing != null) {
                            onSpouse(r.existing);
                          } else {
                            onSpouseDraft!(r.draft);
                          }
                        },
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: const Text('Inscribir a su cónyuge ahora'),
                ),
            ]),
          if (onSpouseDraft != null &&
              selfSex == null &&
              spouse == null &&
              spouseDraft == null)
            const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                    'Elige primero el sexo para poder inscribir a su cónyuge aquí.',
                    key: Key('social-conyuge-sinsexo'),
                    style: TextStyle(color: Brand.gris, fontSize: 14))),
          const SizedBox(height: 10),
          Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final id in groupIds)
                  InputChip(
                    key: Key('social-grupo-${names[id] ?? id}'),
                    label: Text(names[id] ?? 'Grupo'),
                    onDeleted: () => onGroups({...groupIds}..remove(id)),
                  ),
                OutlinedButton.icon(
                  key: const Key('social-grupos'),
                  onPressed: () async {
                    final r = await pickGroups(context,
                        eventId: eventId, selected: groupIds);
                    if (r != null) onGroups(r);
                  },
                  icon: const Icon(Icons.groups_outlined),
                  label: Text(groupIds.isEmpty
                      ? 'Añadir a un grupo'
                      : 'Cambiar grupos'),
                ),
              ]),
        ]),
      ),
    );
  }
}
