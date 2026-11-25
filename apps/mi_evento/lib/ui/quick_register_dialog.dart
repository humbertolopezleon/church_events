import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import '../data/database.dart';
import '../data/repository.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import 'auth_screens.dart' show ErrorBox;
import 'widgets/labeled_field.dart';

/// Registro rápido de una persona desde el control de comidas: lo mínimo (nombre, apellido, sexo,
/// edad y, si se quiere, iglesia). Queda confirmada y **marcada como «registrada en el control»**
/// para poder identificarla y completar su ficha después. Devuelve la persona creada.
class QuickRegisterDialog extends ConsumerStatefulWidget {
  const QuickRegisterDialog(
      {super.key, required this.eventId, this.initialText = ''});
  final String eventId;

  /// Lo que se estaba buscando: se usa para adelantar nombre y apellido.
  final String initialText;
  @override
  ConsumerState<QuickRegisterDialog> createState() =>
      _QuickRegisterDialogState();
}

class _QuickRegisterDialogState extends ConsumerState<QuickRegisterDialog> {
  final first = TextEditingController();
  final last1 = TextEditingController();
  final last2 = TextEditingController();
  final age = TextEditingController();
  Sex? sex;
  String? churchId;
  String? error;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    // «Ana Pérez» → nombre «Ana», apellido «Pérez». Un número (nº de inscripción) no se usa.
    final words = widget.initialText
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && int.tryParse(w) == null)
        .toList();
    if (words.isNotEmpty) first.text = words.first;
    if (words.length > 1) last1.text = words[1];
    if (words.length > 2) last2.text = words.sublist(2).join(' ');
  }

  @override
  void dispose() {
    for (final c in [first, last1, last2, age]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<bool> _confirmDuplicate(List<AttendeeRow> found) async {
    final d = found.first;
    final name = [d.firstName, d.lastName1, d.lastName2]
        .where((e) => e.isNotEmpty)
        .join(' ');
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('qr-duplicado'),
        icon: const Icon(Icons.warning_amber_rounded,
            color: Brand.avisoTexto, size: 36),
        title: const Text('¿Ya está registrado?'),
        content: Text(
            'Ya hay ${found.length == 1 ? 'una persona' : '${found.length} personas'} con ese nombre y apellidos: $name, ${d.age} años, nº ${d.regNumber}. '
            'Si es la misma, cancela y búscala en la lista para marcarla. ¿Es otra persona?'),
        actions: [
          TextButton(
              key: const Key('qr-dup-cancelar'),
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              key: const Key('qr-dup-guardar'),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Es otra persona, registrar')),
        ],
      ),
    );
    return r == true;
  }

  Future<void> _save() async {
    final a = int.tryParse(age.text.trim());
    if (sex == null) {
      setState(() => error = 'Falta elegir si es hombre o mujer.');
      return;
    }
    if (a == null) {
      setState(() => error = 'Falta la edad (un número).');
      return;
    }
    final repo = ref.read(repositoryProvider);
    try {
      final dupes = await repo.possibleDuplicates(widget.eventId,
          firstName: first.text, lastName1: last1.text, age: a);
      if (dupes.isNotEmpty && !await _confirmDuplicate(dupes)) return;
      if (!mounted) return;
      setState(() {
        busy = true;
        error = null;
      });
      final row = await repo.addAttendee(
        eventId: widget.eventId,
        firstName: first.text,
        lastName1: last1.text,
        lastName2: last2.text,
        sex: sex!,
        age: a,
        churchId: churchId,
        createdBy: ref.read(currentUserProvider)?.id,
        registeredAtControl: true,
      );
      // Si el evento reparte equipos, entra en el que mejor conserva el balance (como al inscribir).
      final ev = ref.read(eventProvider(widget.eventId)).valueOrNull;
      if (ev?.offersTeams ?? false) {
        await ref.read(teamRepoProvider).autoAssign(row.id);
      }
      if (mounted) Navigator.pop(context, row);
    } on DataException catch (e) {
      if (mounted) {
        setState(() {
          error = e.message;
          busy = false;
        });
      }
    }
  }

  /// Opción grande («Hombre» / «Mujer») con el mismo aspecto que las de «Acepta» del hospedaje.
  Widget _sexOption(Key key, String label, Sex value) {
    final sel = sex == value;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: sel,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        key: key,
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => sex = value),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: sel ? Brand.azulSuave : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: sel ? Brand.azul : Brand.borde, width: sel ? 2 : 1),
          ),
          child: Text(label,
              style: bodyStyle(17,
                  weight: sel ? FontWeight.w700 : FontWeight.w400)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final churches =
        ref.watch(churchesProvider).valueOrNull ?? const <ChurchRow>[];
    return AlertDialog(
      title: const Text('Registrar persona nueva'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                  'Queda confirmada y marcada como «registrada en el control» para completar su ficha después.',
                  style: TextStyle(color: Brand.gris)),
            ),
            const SizedBox(height: 12),
            LabeledField(
                label: 'Nombre',
                child: TextField(
                    key: const Key('qr-nombre'),
                    controller: first,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration())),
            const SizedBox(height: 10),
            LabeledField(
                label: 'Primer apellido',
                child: TextField(
                    key: const Key('qr-apellido1'),
                    controller: last1,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration())),
            const SizedBox(height: 10),
            LabeledField(
                label: 'Segundo apellido (opcional)',
                child: TextField(
                    key: const Key('qr-apellido2'),
                    controller: last2,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration())),
            const SizedBox(height: 10),
            LabeledField(
                label: 'Sexo',
                child: Row(children: [
                  Expanded(
                      child: _sexOption(
                          const Key('qr-hombre'), 'Hombre', Sex.male)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _sexOption(
                          const Key('qr-mujer'), 'Mujer', Sex.female)),
                ])),
            const SizedBox(height: 10),
            LabeledField(
                label: 'Edad',
                child: TextField(
                    key: const Key('qr-edad'),
                    controller: age,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration())),
            const SizedBox(height: 10),
            LabeledField(
                label: 'Iglesia (opcional)',
                child: DropdownButtonFormField<String?>(
                  key: const Key('qr-iglesia'),
                  initialValue: churchId,
                  isExpanded: true,
                  decoration: const InputDecoration(),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('Sin indicar')),
                    for (final c in churches)
                      DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (v) => setState(() => churchId = v),
                )),
            if (error != null) ...[
              const SizedBox(height: 12),
              ErrorBox(error!),
            ],
          ]),
        ),
      ),
      actions: [
        TextButton(
            key: const Key('qr-cancelar'),
            onPressed: busy ? null : () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(
            key: const Key('qr-guardar'),
            onPressed: busy ? null : _save,
            child: const Text('Registrar y marcar')),
      ],
    );
  }
}
