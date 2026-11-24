import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import '../data/database.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import 'auth_screens.dart' show ErrorBox;
import 'widgets/input_formats.dart';

/// Cónyuge que todavía no está inscrito: se guarda junto con la ficha de la primera persona
/// (si se cancela, no se crea nadie).
class SpouseDraft {
  const SpouseDraft({
    required this.firstName,
    required this.lastName1,
    this.lastName2 = '',
    required this.age,
    required this.sex,
  });
  final String firstName, lastName1, lastName2;
  final int age;
  final Sex sex;
  String get fullName => [firstName, lastName1, lastName2]
      .where((e) => e.trim().isNotEmpty)
      .join(' ');
}

/// Resultado del diálogo: un cónyuge nuevo o una persona ya inscrita (si era un duplicado).
class NewSpouseResult {
  const NewSpouseResult.draft(this.draft) : existing = null;
  const NewSpouseResult.existing(this.existing) : draft = null;
  final SpouseDraft? draft;
  final AttendeeRow? existing;
}

/// Formulario corto para inscribir al cónyuge desde la ficha. El sexo es el contrario al de la
/// primera persona y no se puede cambiar (es un matrimonio).
class NewSpouseDialog extends ConsumerStatefulWidget {
  const NewSpouseDialog(
      {super.key,
      required this.eventId,
      required this.spouseSex,
      this.excludeId,
      this.suggestedLastName = ''});
  final String eventId;
  final Sex spouseSex;
  final String? excludeId;
  final String suggestedLastName;
  @override
  ConsumerState<NewSpouseDialog> createState() => _NewSpouseDialogState();
}

class _NewSpouseDialogState extends ConsumerState<NewSpouseDialog> {
  final first = TextEditingController();
  late final last1 = TextEditingController();
  final last2 = TextEditingController();
  final age = TextEditingController();
  String? error;
  List<AttendeeRow> dupes = const [];

  SpouseDraft? _validate() {
    if (first.text.trim().isEmpty) {
      setState(() => error = 'Falta el nombre de su cónyuge.');
      return null;
    }
    if (last1.text.trim().isEmpty) {
      setState(() => error = 'Falta el primer apellido de su cónyuge.');
      return null;
    }
    final a = int.tryParse(age.text.trim());
    if (a == null) {
      setState(() => error = 'Falta la edad de su cónyuge.');
      return null;
    }
    if (a < 1 || a > 110) {
      setState(() => error = 'La edad debe estar entre 1 y 110 años.');
      return null;
    }
    return SpouseDraft(
        firstName: first.text.trim(),
        lastName1: last1.text.trim(),
        lastName2: last2.text.trim(),
        age: a,
        sex: widget.spouseSex);
  }

  Future<void> _accept({bool ignoreDupes = false}) async {
    final d = _validate();
    if (d == null) return;
    if (!ignoreDupes) {
      final found = await ref.read(repositoryProvider).possibleDuplicates(
          widget.eventId,
          firstName: d.firstName,
          lastName1: d.lastName1,
          age: d.age,
          excludeId: widget.excludeId);
      // Solo importan los que no están ya casados con otra persona.
      final free = found.where((r) => r.coupleId == null).toList();
      if (free.isNotEmpty && mounted) {
        setState(() {
          dupes = free;
          error = null;
        });
        return;
      }
    }
    if (mounted) Navigator.pop(context, NewSpouseResult.draft(d));
  }

  @override
  Widget build(BuildContext context) {
    final sexo = widget.spouseSex == Sex.male ? 'Hombre' : 'Mujer';
    return AlertDialog(
      key: const Key('ns-dialogo'),
      title: const Text('Inscribir a su cónyuge'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 440,
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    'Se inscribe junto con esta persona, con su misma iglesia y lugar. No se guarda nada hasta que guardes la ficha.',
                    style: TextStyle(color: Brand.gris)),
                const SizedBox(height: 12),
                TextField(
                    key: const Key('ns-nombre'),
                    controller: first,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Nombre')),
                const SizedBox(height: 12),
                TextField(
                    key: const Key('ns-apellido1'),
                    controller: last1,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration:
                        const InputDecoration(labelText: 'Primer apellido')),
                const SizedBox(height: 12),
                TextField(
                    key: const Key('ns-apellido2'),
                    controller: last2,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration:
                        const InputDecoration(labelText: 'Segundo apellido')),
                const SizedBox(height: 12),
                Row(children: [
                  SizedBox(
                    width: 110,
                    child: TextField(
                        key: const Key('ns-edad'),
                        controller: age,
                        keyboardType: TextInputType.number,
                        inputFormatters: digitsOnly(3),
                        decoration: const InputDecoration(labelText: 'Edad')),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      key: const Key('ns-sexo'),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                          color: Brand.azulSuave,
                          borderRadius: BorderRadius.circular(12)),
                      child: Text('Sexo: $sexo',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ]),
                if (dupes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    key: const Key('ns-duplicado'),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Brand.avisoSuave,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Brand.aviso, width: 2)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('¿Ya está inscrito?',
                              style: TextStyle(fontWeight: FontWeight.w800)),
                          for (final d in dupes.take(3))
                            Text('Ya hay ${[
                              d.firstName,
                              d.lastName1,
                              d.lastName2
                            ].where((e) => e.isNotEmpty).join(' ')}, ${d.age} años, nº ${d.regNumber}.'),
                          const SizedBox(height: 6),
                          Wrap(spacing: 8, runSpacing: 4, children: [
                            FilledButton(
                                key: const Key('ns-es-esa'),
                                style: FilledButton.styleFrom(
                                    minimumSize: const Size(64, 44)),
                                onPressed: () => Navigator.pop(context,
                                    NewSpouseResult.existing(dupes.first)),
                                child: const Text('Es esa persona')),
                            TextButton(
                                key: const Key('ns-es-otra'),
                                onPressed: () => _accept(ignoreDupes: true),
                                child: const Text('Es otra persona')),
                          ]),
                        ]),
                  ),
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(
            key: const Key('ns-aceptar'),
            onPressed: _accept,
            child: const Text('Aceptar')),
      ],
    );
  }
}
