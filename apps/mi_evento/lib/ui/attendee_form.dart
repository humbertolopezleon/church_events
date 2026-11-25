import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'widgets/labeled_field.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import '../auth/auth_service.dart';
import '../data/database.dart';
import '../data/list_filters.dart';
import '../data/repos_b.dart';
import '../data/repository.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import 'auth_screens.dart' show ErrorBox;
import 'new_spouse_dialog.dart';
import 'proposal_card.dart';
import 'social_section.dart';
import 'widgets/input_formats.dart';

/// Registro y edición de asistentes (misma pantalla).
/// [attendeeId] == null → registro nuevo (pestaña «Registrar»); si no, edición de esa ficha.
class AttendeeFormScreen extends ConsumerStatefulWidget {
  const AttendeeFormScreen({super.key, this.attendeeId});
  final String? attendeeId;
  @override
  ConsumerState<AttendeeFormScreen> createState() => _AttendeeFormScreenState();
}

class _AttendeeFormScreenState extends ConsumerState<AttendeeFormScreen> {
  final first = TextEditingController();
  final last1 = TextEditingController();
  final last2 = TextEditingController();
  final age = TextEditingController();
  final phone = TextEditingController();
  final notes = TextEditingController();
  final churchText = TextEditingController();
  final municipality = TextEditingController();
  final firstFocus = FocusNode();

  Sex? sex;
  String? province;
  bool needsLodging = false;
  // Preinscripción: se anota antes del evento y la asistencia se confirma el día. Solo al registrar.
  bool preregister = false;

  /// Aviso de «Guardar y registrar otro»: va dentro del formulario (un SnackBar tapaba el botón).
  String? lastSavedMsg;
  // Al editar: estado de asistencia actual de la persona.
  bool _isPreregistered = false;
  ChurchRow? church;
  bool churchPickerOpen = false;
  AttendeeRow? spouse;
  SpouseDraft?
      spouseDraft; // cónyuge nuevo que se inscribe junto con esta ficha
  Set<String> groupIds = {};
  String? lodgingId; // hospedaje elegido (o aceptado de la sugerencia)
  String? _origLodgingId; // para guardar solo lo que cambió al editar
  // Matrimonio con hospedajes incompatibles/separados (QA-BUG-003): propuesta de mover a los dos.
  bool _coupleMoveDismissed = false;
  // Búsqueda y filtros de la lista de hospedajes disponibles.
  final hospSearch = TextEditingController();
  int hospMinSlots = 0; // filtro «plazas necesarias» del selector de hospedaje
  bool hospOnlyFit =
      false; // solo los que aceptan a esta persona (según su sexo / cónyuge)
  bool lodgingDeferred =
      false; // «dejar para después» (p. ej. se asignará con su grupo)
  String?
      teamName; // equipo actual (solo lectura: se cambia desde la vista de equipos)
  String? savedTeamName, savedLodgingName, savedSpouseName;
  int? savedSpouseNumber;

  List<AttendeeRow> dupes = const [];
  String? dismissedDupFor;
  String? error;
  bool busy = false;
  bool loaded = false;
  AttendeeRow? savedRow; // pantalla de éxito tras guardar

  bool get editing => widget.attendeeId != null;
  String get eventId => ref.read(currentEventIdProvider)!;
  Repository get repo => ref.read(repositoryProvider);

  @override
  void initState() {
    super.initState();
    if (editing) _load();
  }

  Future<void> _load() async {
    final r = await repo.attendeeById(widget.attendeeId!);
    if (r == null || !mounted) return;
    ChurchRow? c;
    if (r.churchId != null) {
      c = await (ref
              .read(databaseProvider)
              .select(ref.read(databaseProvider).churches)
            ..where((x) => x.id.equals(r.churchId!)))
          .getSingleOrNull();
    }
    final team = r.teamId == null
        ? null
        : await (ref
                .read(databaseProvider)
                .select(ref.read(databaseProvider).teams)
              ..where((x) => x.id.equals(r.teamId!)))
            .getSingleOrNull();
    final sp = await ref.read(socialRepoProvider).spouseOf(r.id);
    final gids = await ref.read(socialRepoProvider).groupIdsOf(r.id);
    if (!mounted) return;
    setState(() {
      spouse = sp;
      groupIds = gids;
      first.text = r.firstName;
      last1.text = r.lastName1;
      last2.text = r.lastName2;
      age.text = '${r.age}';
      phone.text = r.phone ?? '';
      notes.text = r.notes;
      municipality.text = r.municipality;
      province = r.province.isEmpty ? null : r.province;
      sex = r.sex == 'M' ? Sex.male : Sex.female;
      needsLodging = r.needsLodging;
      _isPreregistered = r.status == 'preregistered';
      lodgingId = _origLodgingId = r.lodgingId;
      teamName = team?.name;
      church = c;
      churchText.text = c?.name ?? '';
      loaded = true;
    });
  }

  void _reset() {
    for (final c in [
      first,
      last1,
      last2,
      age,
      phone,
      notes,
      churchText,
      municipality,
      hospSearch
    ]) {
      c.clear();
    }
    setState(() {
      sex = null;
      province = null;
      needsLodging = false;
      lodgingId = null;
      lodgingDeferred = false;
      hospOnlyFit = false;
      hospMinSlots = 0;
      _coupleMoveDismissed = false;
      savedTeamName = savedLodgingName = null;
      spouse = null;
      spouseDraft = null;
      savedSpouseName = null;
      savedSpouseNumber = null;
      groupIds = {};
      church = null;
      dupes = const [];
      dismissedDupFor = null;
      error = null;
      savedRow = null;
      churchPickerOpen = false;
    });
    firstFocus.requestFocus();
  }

  // Mismo nombre y apellidos (la edad no cuenta: puede estar mal escrita en uno de los dos).
  String get _dupKey =>
      '${dedupeKey(first.text, last1.text)}|${normalizeText(last2.text)}';

  Future<List<AttendeeRow>> _findDupes() => repo.possibleDuplicates(eventId,
      firstName: first.text,
      lastName1: last1.text,
      lastName2: last2.text,
      excludeId: widget.attendeeId);

  Future<void> _checkDup() async {
    final found = await _findDupes();
    if (mounted) setState(() => dupes = found);
  }

  /// Antes de guardar: si ya hay alguien con el mismo nombre y apellidos y no se dijo «Es otra
  /// persona», pregunta. Devuelve true si se puede seguir guardando.
  Future<bool> _confirmDuplicate() async {
    final found = await _findDupes();
    if (!mounted) return false;
    if (found.isEmpty || dismissedDupFor == _dupKey) return true;
    final d = found.first;
    final name = [d.firstName, d.lastName1, d.lastName2]
        .where((e) => e.isNotEmpty)
        .join(' ');
    final r = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('dup-confirmar'),
        icon: const Icon(Icons.warning_amber_rounded,
            color: Brand.avisoTexto, size: 36),
        title: const Text('¿Ya está registrado?'),
        content: Text(
            'Ya hay ${found.length == 1 ? 'una persona' : '${found.length} personas'} con ese nombre y apellidos: $name, ${d.age} años, nº ${d.regNumber}. '
            '¿Es otra persona y quieres guardarla igual?'),
        actions: [
          TextButton(
              key: const Key('dup-cancelar'),
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: const Text('Cancelar')),
          OutlinedButton(
              key: const Key('dup-ver-ficha'),
              onPressed: () => Navigator.pop(ctx, 'ver'),
              child: const Text('Ver ese registro')),
          FilledButton(
              key: const Key('dup-guardar-igual'),
              onPressed: () => Navigator.pop(ctx, 'save'),
              child: const Text('Es otra persona, guardar')),
        ],
      ),
    );
    if (r == 'save') {
      setState(() => dismissedDupFor = _dupKey);
      return true;
    }
    if (r == 'ver' && mounted) {
      await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => AttendeeFormScreen(attendeeId: d.id)));
    }
    return false;
  }

  String? _validate() {
    if (first.text.trim().isEmpty) {
      return 'Falta el nombre. Escríbelo para poder guardar.';
    }
    if (last1.text.trim().isEmpty) return 'Falta el primer apellido.';
    if (sex == null) return 'Falta el sexo: elige Hombre o Mujer.';
    final a = int.tryParse(age.text.trim());
    if (a == null) return 'Falta la edad.';
    if (a < 1 || a > 110) return 'La edad debe estar entre 1 y 110 años.';
    if (church == null) {
      return churchText.text.trim().isEmpty
          ? 'Falta la iglesia. Búscala por su nombre o regístrala si es nueva.'
          : 'Elige la iglesia de la lista o regístrala como nueva.';
    }
    // Matrimonio solo entre un hombre y una mujer.
    final mateSex = spouseDraft?.sex ??
        (spouse == null ? null : (spouse!.sex == 'M' ? Sex.male : Sex.female));
    if (mateSex != null && mateSex == sex) {
      return 'Un matrimonio es entre un hombre y una mujer: la pareja elegida es del mismo sexo.';
    }
    // Hospedaje incompatible = no se guarda (la única salida: otro hospedaje o editarlo).
    if (needsLodging && lodgingId != null) {
      final lodgings =
          ref.read(lodgingsProvider(eventId)).valueOrNull ?? const [];
      final chosen = lodgings.where((l) => l.row.id == lodgingId).firstOrNull;
      if (chosen != null) {
        final b = _blockersFor(chosen);
        if (b.isNotEmpty) {
          return 'No se puede guardar con ese hospedaje. ${b.map((w) => w.message).join(' ')} Elige otro hospedaje o edita este para cambiar a quién acepta.';
        }
      }
    }
    return null;
  }

  /// Incompatibilidades (sexo / matrimonio) de esta persona (y su cónyuge si se hospedan juntos)
  /// con el hospedaje [l]. Vacío = compatible. Se evalúa para [l] aunque no sea el elegido: en uno
  /// de matrimonios el cónyuge viaja con esta persona.
  List<AssignmentWarning> _blockersFor(LodgingView l) {
    final accepts = lodgingAcceptsFromDb(l.row.accepts);
    final sp = spouse;
    final moves = sp != null &&
        sp.needsLodging &&
        l.row.id != sp.lodgingId &&
        acceptsCouples(accepts);
    final mateRefs = spouseDraft != null
        ? _mateRefs()
        : (sp != null && ((sp.needsLodging && sp.lodgingId == null) || moves)
            ? [sp.toPersonRef(widget.attendeeId ?? 'nuevo')]
            : const <PersonRef>[]);
    final there = sp != null && sp.lodgingId == l.row.id
        ? [sp.toPersonRef(widget.attendeeId ?? 'nuevo')]
        : const <PersonRef>[];
    return lodgingBlockers(
        LodgingSlot(
            name: l.row.name,
            accepts: accepts,
            capacity: l.row.capacity,
            occupied: 0),
        [_selfRef(), ...mateRefs],
        alreadyThere: there);
  }

  Future<void> _save({required bool another}) async {
    if (busy) {
      return; // un segundo toque en el mismo instante no guarda dos veces (QA-BUG-013)
    }
    final v = _validate();
    if (v != null) {
      setState(() => error = v);
      return;
    }
    if (!await _confirmDuplicate()) return;
    if (!mounted) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final a = int.parse(age.text.trim());
      final db = ref.read(databaseProvider);
      final social = ref.read(socialRepoProvider);
      if (editing) {
        await db.transaction(() async {
          await repo.updateAttendee(widget.attendeeId!,
              firstName: first.text,
              lastName1: last1.text,
              lastName2: last2.text,
              sex: sex!,
              age: a,
              churchId: church!.id,
              phone: phone.text,
              province: church!.province,
              municipality: church!.municipality,
              needsLodging: needsLodging,
              notes: notes.text);
          final newSpouse = spouseDraft == null ? null : await _createSpouse();
          await social.setSpouse(
              widget.attendeeId!, newSpouse?.id ?? spouse?.id);
          await social.setGroups(widget.attendeeId!, groupIds);
          final lid = needsLodging ? lodgingId : null;
          final lr = ref.read(lodgingRepoProvider);
          // La pareja va junta (el mismo hospedaje y, si es nueva, el mismo equipo): en UNA sola
          // asignación, porque un hospedaje de matrimonios exige al cónyuge a la vez.
          final mates = _mateIds(newSpouse);
          if (lid == null) {
            if (_origLodgingId != null) {
              await lr.unassign([widget.attendeeId!]);
            }
          } else {
            await lr.assign(lid, [
              if (lid != _origLodgingId) widget.attendeeId!,
              ...mates,
            ]);
          }
          if (newSpouse != null) {
            await ref.read(teamRepoProvider).autoAssign(newSpouse.id);
          }
        });
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Cambios guardados.')));
        return;
      }
      late AttendeeRow row;
      await db.transaction(() async {
        row = await repo.addAttendee(
            eventId: eventId,
            firstName: first.text,
            lastName1: last1.text,
            lastName2: last2.text,
            sex: sex!,
            age: a,
            churchId: church!.id,
            phone: phone.text,
            province: church!.province,
            municipality: church!.municipality,
            needsLodging: needsLodging,
            notes: notes.text,
            preregistered: preregister,
            createdBy: ref.read(currentUserProvider)?.id);
        final newSpouse = spouseDraft == null ? null : await _createSpouse();
        await social.setSpouse(row.id, newSpouse?.id ?? spouse?.id);
        await social.setGroups(row.id, groupIds);
        // El equipo lo pone el sistema (el que mejor conserva el balance); se cambia luego
        // desde la vista de equipos. El cónyuge nuevo cae en el mismo equipo.
        savedTeamName =
            (await ref.read(teamRepoProvider).autoAssign(row.id))?.name;
        if (newSpouse != null) {
          await ref.read(teamRepoProvider).autoAssign(newSpouse.id);
          savedSpouseName = [
            newSpouse.firstName,
            newSpouse.lastName1,
            newSpouse.lastName2
          ].where((e) => e.isNotEmpty).join(' ');
          savedSpouseNumber = newSpouse.regNumber;
        }
        if (needsLodging && lodgingId != null) {
          await ref
              .read(lodgingRepoProvider)
              .assign(lodgingId!, [row.id, ..._mateIds(newSpouse)]);
        }
      });
      final lodgNow =
          ref.read(lodgingsProvider(eventId)).valueOrNull ?? const [];
      savedLodgingName = needsLodging
          ? lodgNow.where((l) => l.row.id == lodgingId).firstOrNull?.row.name
          : null;
      ref
          .read(autoBackupProvider)
          .noteChange(eventId); // copia automática cada 20 registros
      if (!mounted) return;
      if (another) {
        final name = row.firstName;
        final was = preregister;
        _reset();
        setState(() {
          preregister =
              false; // QA-WIN-01: la siguiente persona vuelve a inscribirse normal
          lastSavedMsg =
              'Listo. $name quedó ${was ? 'preinscrito/a' : 'registrado/a'} como asistente nº ${row.regNumber}.';
        });
      } else {
        setState(() => savedRow = row);
      }
    } on DataException catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar este asistente?'),
        content: Text(
            '${first.text} ${last1.text} dejará de aparecer en las listas y los conteos.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              key: const Key('f-confirmar-eliminar'),
              style: FilledButton.styleFrom(backgroundColor: Brand.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final lostCaptainOf = await repo.deleteAttendee(widget.attendeeId!,
          isAdmin: ref.read(currentUserProvider)?.isAdmin ?? false);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(lostCaptainOf == null
              ? 'Asistente eliminado.'
              : 'Asistente eliminado. Era capitán de «$lostCaptainOf»: ese equipo se quedó sin capitán.')));
    } on DataException catch (e) {
      setState(() => error = e.message);
    }
  }

  Future<void> _newChurch(String suggested) async {
    final c = await showDialog<ChurchRow>(
        context: context,
        builder: (_) =>
            ChurchDialog(initialName: suggested, initialProvince: province));
    if (c == null || !mounted) return;
    _pickChurch(c);
  }

  /// Elige la iglesia escrita si coincide exactamente o si es la única sugerida (uso con teclado).
  void _autoPickChurch(List<ChurchRow> churches) {
    if (church != null || !mounted) return;
    final text = churchText.text.trim();
    if (text.isEmpty) return;
    final exact = churches
        .where((c) => normalizeText(c.name) == normalizeText(text))
        .toList();
    final matches =
        exact.isNotEmpty ? exact : Repository.filterChurches(churches, text);
    if (matches.length == 1) _pickChurch(matches.single);
  }

  void _pickChurch(ChurchRow c) {
    setState(() {
      church = c;
      churchText.text = c.name;
      churchPickerOpen = false;
      if (c.province.isNotEmpty) province = c.province;
      if (c.municipality.isNotEmpty) municipality.text = c.municipality;
    });
  }

  @override
  Widget build(BuildContext context) {
    final event = ref.watch(eventProvider(eventId)).valueOrNull;
    final offersLodging = event?.offersLodging ?? true;
    final me = ref.watch(currentUserProvider);
    final allPeople = ref.watch(attendeesProvider(eventId)).valueOrNull ??
        const <AttendeeView>[];
    final lodgingViews = ref.watch(lodgingsProvider(eventId)).valueOrNull ??
        const <LodgingView>[];

    if (savedRow != null) return _success(savedRow!, offersLodging);
    if (editing && !loaded) {
      return Scaffold(
          appBar: AppBar(title: const Text('Ficha del asistente')),
          body: const Center(child: CircularProgressIndicator()));
    }

    final churches =
        ref.watch(churchesProvider).valueOrNull ?? const <ChurchRow>[];
    final suggestions = churchPickerOpen && church == null
        ? Repository.filterChurches(churches, churchText.text)
        : const <ChurchRow>[];
    final exact = churches
        .any((c) => normalizeText(c.name) == normalizeText(churchText.text));
    final showDup = dupes.isNotEmpty && dismissedDupFor != _dupKey;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Ficha del asistente' : 'Nuevo asistente'),
        actions: [
          if (editing && (me?.isAdmin ?? false))
            ExcludeFocus(
              child: IconButton(
                  key: const Key('f-eliminar'),
                  tooltip: 'Eliminar',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _delete),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: FocusTraversalGroup(
              policy: OrderedTraversalPolicy(),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (lastSavedMsg != null) ...[
                      Container(
                        key: const Key('f-ok-otro'),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Brand.exitoSuave,
                            borderRadius: BorderRadius.circular(10)),
                        child: Row(children: [
                          const Icon(Icons.check_circle, color: Brand.exito),
                          const SizedBox(width: 8),
                          Expanded(child: Text(lastSavedMsg!)),
                        ]),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _tabOrder(
                        1,
                        LabeledField(
                            label: 'Nombre *',
                            child: TextField(
                              key: const Key('f-nombre'),
                              controller: first,
                              focusNode: firstFocus,
                              autofocus: !editing,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              onChanged: (_) => _checkDup(),
                              decoration: const InputDecoration(),
                            ))),
                    const SizedBox(height: 12),
                    LayoutBuilder(builder: (context, c) {
                      final apellidos = [
                        _tabOrder(
                            2,
                            LabeledField(
                                label: 'Primer apellido *',
                                child: TextField(
                                    key: const Key('f-apellido1'),
                                    controller: last1,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    textInputAction: TextInputAction.next,
                                    onChanged: (_) => _checkDup(),
                                    decoration: const InputDecoration()))),
                        _tabOrder(
                            3,
                            LabeledField(
                                label: 'Segundo apellido',
                                optional: true,
                                child: TextField(
                                    key: const Key('f-apellido2'),
                                    controller: last2,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    textInputAction: TextInputAction.next,
                                    decoration: const InputDecoration()))),
                      ];
                      return Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(child: apellidos[0]),
                            const SizedBox(width: 10),
                            Expanded(child: apellidos[1])
                          ]);
                    }),
                    if (showDup) ...[
                      const SizedBox(height: 12),
                      ExcludeFocus(child: _dupWarning())
                    ],
                    const SizedBox(height: 16),
                    _tabOrder(
                        4,
                        LabeledField(
                            label: 'Sexo *',
                            child: DropdownButtonFormField<Sex>(
                              key: const Key('f-sexo'),
                              initialValue: sex,
                              isExpanded: true,
                              decoration: const InputDecoration(),
                              items: const [
                                DropdownMenuItem(
                                    value: Sex.male, child: Text('M (Hombre)')),
                                DropdownMenuItem(
                                    value: Sex.female,
                                    child: Text('F (Mujer)')),
                              ],
                              onChanged: (v) => setState(() => sex = v),
                            ))),
                    const SizedBox(height: 16),
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      SizedBox(
                        width: 110,
                        child: _tabOrder(
                            5,
                            LabeledField(
                                label: 'Edad *',
                                child: TextField(
                                    key: const Key('f-edad'),
                                    controller: age,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: digitsOnly(3),
                                    textInputAction: TextInputAction.next,
                                    onChanged: (_) {
                                      _checkDup();
                                      setState(() {});
                                    },
                                    decoration: const InputDecoration()))),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _tabOrder(
                              6,
                              LabeledField(
                                  label: 'Teléfono',
                                  optional: true,
                                  child: TextField(
                                      key: const Key('f-telefono'),
                                      controller: phone,
                                      keyboardType: TextInputType.phone,
                                      inputFormatters: phoneChars(),
                                      decoration: const InputDecoration())))),
                    ]),
                    const SizedBox(height: 16),
                    _tabOrder(
                      7,
                      // Al salir del campo con Tab (o con Enter) se elige la iglesia si coincide
                      // exactamente o es la única sugerida: así se completa solo con el teclado.
                      Focus(
                        canRequestFocus: false,
                        skipTraversal: true,
                        onFocusChange: (has) {
                          if (!has) _autoPickChurch(churches);
                        },
                        child: LabeledField(
                            label: 'Iglesia *',
                            child: TextField(
                              key: const Key('f-iglesia'),
                              controller: churchText,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) => _autoPickChurch(churches),
                              onChanged: (_) => setState(() {
                                church =
                                    null; // al escribir se deshace la selección anterior
                                churchPickerOpen = true;
                              }),
                              decoration: InputDecoration(
                                suffixIcon: church != null
                                    ? const Icon(Icons.check_circle,
                                        color: Brand.exito)
                                    : null,
                              ),
                            )),
                      ),
                    ),
                    if (suggestions.isNotEmpty ||
                        (churchPickerOpen &&
                            church == null &&
                            churchText.text.trim().isNotEmpty))
                      Padding(
                          padding: const EdgeInsets.only(top: 6),
                          // Material (no Container con color): así el ListTile pinta bien su fondo y el toque.
                          // Fuera del orden de Tab: se elige con el ratón/dedo o con Enter en el campo.
                          child: ExcludeFocus(
                              child: Material(
                            color: Colors.white,
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: Brand.borde)),
                            child: Column(children: [
                              for (final c in suggestions)
                                ListTile(
                                  key: Key('iglesia-${c.nameNormalized}'),
                                  minTileHeight: 56,
                                  title: Text(c.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700)),
                                  subtitle: Text([
                                    c.community,
                                    c.municipality,
                                    c.province
                                  ].where((e) => e.isNotEmpty).join(', ')),
                                  onTap: () => _pickChurch(c),
                                ),
                              if (!exact)
                                ListTile(
                                  key: const Key('iglesia-nueva'),
                                  minTileHeight: 56,
                                  tileColor: const Color(0xFFF3F7FC),
                                  title: Text(
                                      '+ Registrar «${churchText.text.trim()}» como iglesia nueva',
                                      style: const TextStyle(
                                          color: Brand.azul,
                                          fontWeight: FontWeight.w700)),
                                  subtitle: const Text(
                                      'Pide nombre, provincia y municipio, y queda en el catálogo'),
                                  onTap: () =>
                                      _newChurch(churchText.text.trim()),
                                ),
                            ]),
                          ))),
                    const SizedBox(height: 16),
                    // Provincia y municipio son los de la iglesia: no se escriben aquí.
                    ExcludeFocus(
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                                child: LabeledField(
                                    label: 'Provincia (de la iglesia)',
                                    child: InputDecorator(
                                        key: const Key('f-provincia'),
                                        decoration: const InputDecoration(),
                                        child: Text(
                                            church?.province.isNotEmpty == true
                                                ? church!.province
                                                : '—',
                                            style: const TextStyle(
                                                color: Brand.gris))))),
                            const SizedBox(width: 10),
                            Expanded(
                                child: LabeledField(
                                    label: 'Municipio (de la iglesia)',
                                    child: InputDecorator(
                                        key: const Key('f-municipio'),
                                        decoration: const InputDecoration(),
                                        child: Text(
                                            church?.municipality.isNotEmpty ==
                                                    true
                                                ? church!.municipality
                                                : '—',
                                            style: const TextStyle(
                                                color: Brand.gris))))),
                          ]),
                    ),
                    const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text('* obligatorio',
                            style: TextStyle(fontSize: 14, color: Brand.gris))),
                    const SizedBox(height: 16),
                    if (!editing)
                      Card(
                        child: SwitchListTile(
                          key: const Key('f-preinscripcion'),
                          secondary: const Icon(Icons.event_available_outlined,
                              color: Brand.azul),
                          title: const Text('Preinscripción',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: const Text(
                              'Se anota antes del evento; la asistencia se confirma el día'),
                          value: preregister,
                          onChanged: (v) => setState(() => preregister = v),
                        ),
                      )
                    else if (_isPreregistered)
                      Card(
                        color: Brand.avisoSuave,
                        child: ListTile(
                          key: const Key('f-preinscrito'),
                          leading: const Icon(Icons.event_available_outlined,
                              color: Brand.avisoTexto),
                          title: const Text(
                              'Preinscrito: asistencia sin confirmar',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          trailing: FilledButton(
                              key: const Key('f-confirmar-asistencia'),
                              onPressed: () async {
                                await repo
                                    .confirmAttendance([widget.attendeeId!]);
                                if (!mounted) return;
                                setState(() => _isPreregistered = false);
                              },
                              child: const Text('Confirmar')),
                        ),
                      )
                    else if (editing)
                      Card(
                        child: ListTile(
                          key: const Key('f-confirmado'),
                          leading: const Icon(Icons.check_circle_outline,
                              color: Brand.exito),
                          title: const Text('Asistencia confirmada',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          trailing: OutlinedButton(
                              key: const Key('f-desconfirmar-asistencia'),
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                try {
                                  await repo.unconfirmAttendance(
                                      [widget.attendeeId!]);
                                  if (!mounted) return;
                                  setState(() => _isPreregistered = true);
                                } on DataException catch (e) {
                                  messenger.showSnackBar(
                                      SnackBar(content: Text(e.message)));
                                }
                              },
                              child: const Text('Desconfirmar')),
                        ),
                      ),
                    if (offersLodging) ...[
                      const SizedBox(height: 16),
                      Card(
                        child: SwitchListTile(
                          key: const Key('f-hospedaje'),
                          secondary: const Icon(Icons.house_outlined,
                              color: Brand.azul),
                          title: const Text('Necesita hospedaje',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(lodgingViews.isEmpty
                              ? 'Aún no hay hospedajes definidos'
                              : 'Elige uno ahora o asígnalo después'),
                          value: needsLodging,
                          onChanged: (v) => setState(() {
                            needsLodging = v;
                            if (!v) lodgingId = null;
                          }),
                        ),
                      ),
                      if (needsLodging && lodgingViews.isNotEmpty)
                        _lodgingAssign(lodgingViews, allPeople),
                    ],
                    if (editing && teamName != null) ...[
                      const SizedBox(height: 12),
                      Row(children: [
                        const Icon(Icons.groups_outlined, color: Brand.azul),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(
                                'Equipo: $teamName (se cambia desde la vista de Equipos)',
                                key: const Key('f-equipo-actual'),
                                style: const TextStyle(color: Brand.gris))),
                      ]),
                    ],
                    const SizedBox(height: 16),
                    SocialSection(
                      eventId: eventId,
                      selfId: widget.attendeeId,
                      spouse: spouse,
                      spouseDraft: spouseDraft,
                      groupIds: groupIds,
                      selfSex: sex,
                      selfLastName: last1.text,
                      onSpouse: (s) => setState(() {
                        spouse = s;
                        _coupleMoveDismissed = false;
                        if (s != null) spouseDraft = null;
                      }),
                      onSpouseDraft: (d) => setState(() {
                        spouseDraft = d;
                        if (d != null) spouse = null;
                      }),
                      onGroups: (g) => setState(() => groupIds = g),
                    ),
                    const SizedBox(height: 16),
                    LabeledField(
                        label: 'Observaciones',
                        optional: true,
                        child: TextField(
                            key: const Key('f-observaciones'),
                            controller: notes,
                            maxLines: 3,
                            decoration: const InputDecoration(
                                helperText:
                                    'Evita datos médicos innecesarios.'))),
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      ErrorBox(error!)
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const Key('f-guardar'),
                      onPressed: busy ? null : () => _save(another: false),
                      child: Text(
                          editing ? 'Guardar cambios' : 'Guardar asistente'),
                    ),
                    if (!editing) ...[
                      const SizedBox(height: 8),
                      TextButton(
                          key: const Key('f-guardar-otro'),
                          onPressed: busy ? null : () => _save(another: true),
                          child: const Text('Guardar y registrar otro')),
                    ],
                  ]),
            ),
          ),
        ),
      ),
    );
  }

  /// Inscribe al cónyuge nuevo con la iglesia y el lugar de esta persona (mismo hospedaje pedido).
  Future<AttendeeRow> _createSpouse() {
    final d = spouseDraft!;
    return repo.addAttendee(
        eventId: eventId,
        firstName: d.firstName,
        lastName1: d.lastName1,
        lastName2: d.lastName2,
        sex: d.sex,
        age: d.age,
        churchId: church!.id,
        province: church!.province,
        municipality: church!.municipality,
        needsLodging: needsLodging,
        preregistered: preregister,
        createdBy: ref.read(currentUserProvider)?.id);
  }

  /// Se aceptó mover a los dos cónyuges a un hospedaje de matrimonios (y sigue elegido).
  bool _chosenCouples =
      false; // el hospedaje elegido acepta matrimonios (se calcula al dibujar)

  /// Con cónyuge vinculado y un hospedaje de matrimonios elegido, la pareja va junta: el cónyuge
  /// se mueve con esta persona (nunca queda uno en matrimonios y el otro en otro lado).
  bool get _moveSpouseActive =>
      spouse != null &&
      spouse!.needsLodging &&
      lodgingId != null &&
      lodgingId != spouse!.lodgingId &&
      _chosenCouples;

  /// Cónyuge ya inscrito que se asigna con esta persona: el que necesita hospedaje y aún no lo
  /// tiene, o el que ya tiene uno pero se aceptó moverlo junto a ella/él.
  AttendeeRow? get _existingMate => spouse != null &&
          ((spouse!.needsLodging && spouse!.lodgingId == null) ||
              _moveSpouseActive)
      ? spouse
      : null;

  List<String> _mateIds(AttendeeRow? created) => [
        if (created != null)
          created.id
        else if (_existingMate != null)
          _existingMate!.id
      ];

  /// La pareja que se hospeda junta: este (si es el caso) más su cónyuge nuevo o sin hospedaje.
  List<PersonRef> _mateRefs() {
    final d = spouseDraft;
    if (d != null) {
      return [
        PersonRef(
            id: 'nuevo-conyuge',
            name: d.firstName,
            sex: d.sex,
            spouseId: widget.attendeeId ?? 'nuevo',
            churchId: church?.id)
      ];
    }
    final m = _existingMate;
    return m == null ? const [] : [m.toPersonRef(widget.attendeeId ?? 'nuevo')];
  }

  PersonRef _selfRef() => PersonRef(
        id: widget.attendeeId ?? 'nuevo',
        name: first.text.trim().isEmpty ? 'Esta persona' : first.text.trim(),
        sex: sex ?? Sex.male,
        spouseId: spouseDraft != null ? 'nuevo-conyuge' : spouse?.id,
        churchId: church?.id,
        spouseLodgingId: spouse?.lodgingId,
      );

  /// Hospedaje: sugerencia (propuesta) + lista para elegir a mano. Nada se guarda hasta «Guardar».
  Widget _lodgingAssign(List<LodgingView> lodgings, List<AttendeeView> all) {
    // Sin contar a esta persona (si ya estaba hospedada, su plaza cuenta como libre).
    LodgingCandidate cand(LodgingView l) {
      final mine = widget.attendeeId != null &&
          all.any(
              (p) => p.a.id == widget.attendeeId && p.a.lodgingId == l.row.id);
      return LodgingCandidate(
        id: l.row.id,
        name: l.row.name,
        accepts: lodgingAcceptsFromDb(l.row.accepts),
        capacity: l.row.capacity,
        occupied: l.occupied - (mine ? 1 : 0),
        kind: l.row.kind == 'shelter'
            ? LodgingKindRef.shelter
            : LodgingKindRef.privateHome,
        occupantChurchIds: {
          for (final p in all)
            if (p.a.lodgingId == l.row.id && p.a.churchId != null) p.a.churchId!
        },
        distanceNote: l.row.distanceNote,
      );
    }

    final ready = sex != null;
    final proposals = ready
        ? suggestLodging(
            [_selfRef(), ..._mateRefs()], [for (final l in lodgings) cand(l)],
            maxProposals: 1)
        : const <LodgingProposal>[];
    final best = proposals.isEmpty ? null : proposals.first;
    final leg = best == null || best.legs.isEmpty ? null : best.legs.first;
    final chosen = lodgings.where((l) => l.row.id == lodgingId).firstOrNull;
    // Matrimonio ya vinculado cuyo cónyuge tiene un hospedaje que no sirve para los dos.
    LodgingProposal? move;
    String? moveFrom;
    final sp = spouse;
    if (ready && sp != null && sp.lodgingId != null && needsLodging) {
      final ownLodging = widget.attendeeId == null ? null : _origLodgingId;
      LodgingCandidate moveCand(LodgingView l) {
        final c = cand(l);
        final spouseHere = sp.lodgingId == l.row.id ? 1 : 0;
        return LodgingCandidate(
            id: c.id,
            name: c.name,
            accepts: c.accepts,
            capacity: c.capacity,
            occupied: c.occupied - spouseHere,
            kind: c.kind,
            occupantChurchIds: c.occupantChurchIds,
            distanceNote: c.distanceNote);
      }

      move = proposeCoupleMove(
          a: _selfRef(),
          b: sp.toPersonRef(widget.attendeeId ?? 'nuevo'),
          aLodgingId: ownLodging,
          bLodgingId: sp.lodgingId,
          lodgings: [for (final l in lodgings) moveCand(l)]);
      moveFrom =
          lodgings.where((l) => l.row.id == sp.lodgingId).firstOrNull?.row.name;
    }
    _chosenCouples = chosen != null &&
        acceptsCouples(lodgingAcceptsFromDb(chosen.row.accepts));
    final sp2 = spouse;
    final splitWarn = chosen != null &&
            ready &&
            sp2 != null &&
            sp2.needsLodging &&
            !_chosenCouples &&
            sp2.lodgingId != chosen.row.id
        ? 'Ojo: esto separa al matrimonio. ${sp2.firstName} está ${sp2.lodgingId == null ? 'sin hospedaje' : 'en otro hospedaje'}, y «${chosen.row.name}» no es de matrimonios. Si quieren estar juntos, elige un hospedaje de matrimonios.'
        : null;
    final warns = chosen == null || !ready
        ? const <AssignmentWarning>[]
        : [
            ...checkLodgingAssignment(
                    LodgingSlot(
                        name: chosen.row.name,
                        accepts: lodgingAcceptsFromDb(chosen.row.accepts),
                        capacity: chosen.row.capacity,
                        occupied: cand(chosen).occupied),
                    [_selfRef(), ..._mateRefs()])
                .where((w) => w.kind == WarningKind.capacity),
            ..._blockersFor(chosen),
          ];
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (!ready)
          const Text('Elige el sexo para ver una sugerencia de hospedaje.',
              key: Key('f-hosp-sinsexo'), style: TextStyle(color: Brand.gris))
        else if (lodgingDeferred && lodgingId == null)
          Row(children: [
            const Icon(Icons.schedule, color: Brand.gris),
            const SizedBox(width: 8),
            const Expanded(
                child: Text('El hospedaje se asignará después.',
                    key: Key('f-hosp-despues'),
                    style: TextStyle(color: Brand.gris))),
            TextButton(
                key: const Key('f-hosp-ver-sugerencia'),
                onPressed: () => setState(() => lodgingDeferred = false),
                child: const Text('Ver sugerencia')),
          ])
        else if (move != null &&
            !_coupleMoveDismissed &&
            lodgingId != move.legs.first.lodgingId)
          ProposalCard(
            key: const Key('f-hosp-pareja'),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                  'Aviso: ${spouse!.firstName} ya está hospedado/a en «${moveFrom ?? 'otro hospedaje'}» y ahí no pueden estar juntos.',
                  key: const Key('f-hosp-pareja-aviso'),
                  style: const TextStyle(
                      color: Brand.avisoTexto, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                  'Sugerencia: mover a los dos cónyuges a «${move.legs.first.lodgingName}» (2 plazas). ${move.legs.first.reason} Ocupación: ${move.legs.first.occupiedBefore} → ${move.legs.first.occupiedAfter} de ${move.legs.first.capacity}.',
                  key: const Key('f-hosp-pareja-sugerencia'),
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                FilledButton(
                    key: const Key('f-hosp-pareja-mover'),
                    style:
                        FilledButton.styleFrom(minimumSize: const Size(64, 44)),
                    onPressed: () => setState(() {
                          lodgingId = move!.legs.first.lodgingId;
                          lodgingDeferred = false;
                        }),
                    child: const Text('Mover a los dos')),
                OutlinedButton(
                    key: const Key('f-hosp-pareja-dejar'),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(64, 44)),
                    onPressed: () =>
                        setState(() => _coupleMoveDismissed = true),
                    child: const Text('Dejarlos como están')),
              ]),
              const SizedBox(height: 4),
              const Text(
                  'También puedes elegir otro hospedaje en la lista de abajo.',
                  style: TextStyle(color: Brand.gris)),
            ]),
          )
        else if (_moveSpouseActive)
          Row(children: [
            const Icon(Icons.swap_horiz, color: Brand.azul),
            const SizedBox(width: 8),
            Expanded(
                child: Text(
                    'Al guardar, ${spouse!.firstName} también pasará a «${chosen?.row.name ?? ''}»: el matrimonio va junto.',
                    key: const Key('f-hosp-pareja-ok'),
                    style: const TextStyle(color: Brand.gris))),
          ])
        else if (leg != null && leg.lodgingId != lodgingId)
          ProposalCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Sugerencia: ${leg.lodgingName}',
                  key: const Key('f-hosp-sugerencia'),
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800)),
              Text(
                  '${leg.people.length > 1 ? 'Para los dos cónyuges (${leg.people.length} plazas). ' : ''}${leg.reason} Ocupación: ${leg.occupiedBefore} → ${leg.occupiedAfter} de ${leg.capacity}.',
                  style: const TextStyle(color: Brand.gris)),
              if (groupIds.isNotEmpty) ...[
                const SizedBox(height: 6),
                const Text(
                    'Pertenece a un grupo: puedes dejarlo para después y asignar el hospedaje al grupo completo.',
                    key: Key('f-hosp-nota-grupo'),
                    style: TextStyle(color: Brand.avisoTexto)),
              ],
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                FilledButton(
                    key: const Key('f-hosp-usar'),
                    style:
                        FilledButton.styleFrom(minimumSize: const Size(64, 44)),
                    onPressed: () => setState(() {
                          lodgingId = leg.lodgingId;
                          lodgingDeferred = false;
                        }),
                    child: const Text('Usar esta sugerencia')),
                OutlinedButton(
                    key: const Key('f-hosp-dejar'),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(64, 44)),
                    onPressed: () => setState(() {
                          lodgingId = null;
                          lodgingDeferred = true;
                        }),
                    child: const Text('Dejar para después')),
              ]),
            ]),
          )
        else if (leg == null)
          Container(
            key: const Key('f-hosp-sin-lugar'),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Brand.avisoSuave,
                borderRadius: BorderRadius.circular(10)),
            child: Text(
                best?.notes.isNotEmpty ?? false
                    ? best!.notes.first
                    : 'No hay un hospedaje compatible con plazas libres.',
                style: const TextStyle(color: Brand.avisoTexto)),
          ),
        const SizedBox(height: 8),
        // Buscar y filtrar la lista de hospedajes (por nombre/anfitrión/zona, plazas y sexo).
        LabeledField(
            label: 'Buscar hospedaje',
            child: TextField(
              key: const Key('f-hosp-buscar'),
              controller: hospSearch,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Nombre, anfitrión o zona…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: hospSearch.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpiar',
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(hospSearch.clear)),
              ),
            )),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 4, children: [
          FilterChip(
              key: const Key('f-hosp-filtro-sexo'),
              label: Text(ready
                  ? 'Solo los que aceptan ${sex == Sex.male ? 'hombres' : 'mujeres'}'
                  : 'Solo compatibles con su sexo'),
              selected: hospOnlyFit,
              onSelected:
                  ready ? (v) => setState(() => hospOnlyFit = v) : null),
          // Cantidad: solo hospedajes con al menos N plazas libres (p. ej. 2 para un matrimonio).
          DropdownButton<int>(
            key: const Key('f-hosp-minplazas'),
            value: hospMinSlots,
            underline: const SizedBox.shrink(),
            items: [
              const DropdownMenuItem(
                  value: 0, child: Text('Cualquier cantidad de plazas')),
              for (var n = 1; n <= 6; n++)
                DropdownMenuItem(
                    value: n, child: Text('$n o más plazas libres')),
            ],
            onChanged: (v) => setState(() => hospMinSlots = v ?? 0),
          ),
        ]),
        const SizedBox(height: 6),
        Builder(builder: (context) {
          // Solo hospedajes con plazas libres (siempre, sin filtro). El hospedaje ya elegido se
          // muestra aunque esté lleno.
          final options = [
            for (final l in filterLodgings(lodgings, hospSearch.text))
              if (l.row.id == lodgingId ||
                  (cand(l).free > 0 &&
                      (hospMinSlots == 0 || cand(l).free >= hospMinSlots) &&
                      (!hospOnlyFit || !ready || _blockersFor(l).isEmpty)))
                l
          ];
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KeyedSubtree(
                    key: ValueKey('hs-$lodgingId-${options.length}'),
                    child: LabeledField(
                        label: 'Hospedaje',
                        child: DropdownButtonFormField<String?>(
                          key: const Key('f-hosp-sel'),
                          initialValue: chosen?.row.id,
                          isExpanded: true,
                          decoration: InputDecoration(
                              helperText: options.length == lodgings.length
                                  ? null
                                  : '${options.length} de ${lodgings.length} hospedajes'),
                          items: [
                            const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Sin asignar por ahora')),
                            for (final l in options)
                              DropdownMenuItem<String?>(
                                  value: l.row.id,
                                  // Incompatible = no se puede elegir (salvo que ya sea el elegido).
                                  enabled: !ready ||
                                      l.row.id == lodgingId ||
                                      _blockersFor(l).isEmpty,
                                  child: Text(
                                      '${l.row.name} · ${lodgingAcceptsLabel(lodgingAcceptsFromDb(l.row.accepts))} · ${cand(l).free} libres${ready && l.row.id != lodgingId && _blockersFor(l).isNotEmpty ? ' · no compatible' : ''}',
                                      overflow: TextOverflow.ellipsis)),
                          ],
                          onChanged: (v) => setState(() => lodgingId = v),
                        ))),
                if (options.isEmpty)
                  const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                          'Ningún hospedaje coincide con la búsqueda y los filtros.',
                          key: Key('f-hosp-sin-resultados'),
                          style: TextStyle(color: Brand.avisoTexto))),
              ]);
        }),
        if (splitWarn != null)
          Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(splitWarn,
                  key: const Key('f-hosp-separa'),
                  style: const TextStyle(color: Brand.error))),
        for (final w in warns)
          Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(w.message,
                  key: const Key('f-hosp-aviso'),
                  style: const TextStyle(color: Brand.error))),
      ]),
    );
  }

  Widget _dupWarning() => Container(
        key: const Key('dup-aviso'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Brand.avisoSuave,
            border: Border.all(color: Brand.aviso, width: 2),
            borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.warning_amber_rounded,
                color: Brand.avisoTexto, size: 28),
            SizedBox(width: 10),
            Text('¿Ya está registrado?',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 6),
          for (final d in dupes.take(3))
            Text(
                'Hay un ${[
                  d.firstName,
                  d.lastName1,
                  d.lastName2
                ].where((e) => e.isNotEmpty).join(' ')}, ${d.age} años, nº ${d.regNumber}.',
                style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 6),
          Wrap(spacing: 8, children: [
            OutlinedButton(
              key: const Key('dup-ver'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(64, 44),
                  side: const BorderSide(color: Color(0xFFC98A00))),
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) =>
                          AttendeeFormScreen(attendeeId: dupes.first.id))),
              child: const Text('Ver ese registro',
                  style: TextStyle(color: Brand.avisoTexto)),
            ),
            TextButton(
                key: const Key('dup-otra'),
                onPressed: () => setState(() => dismissedDupFor = _dupKey),
                child: const Text('Es otra persona',
                    style: TextStyle(
                        color: Brand.avisoTexto,
                        decoration: TextDecoration.underline))),
          ]),
        ]),
      );

  Widget _success(AttendeeRow r, bool offersLodging) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const CircleAvatar(
                          radius: 56,
                          backgroundColor: Brand.exitoSuave,
                          child:
                              Icon(Icons.check, size: 64, color: Brand.exito)),
                      const SizedBox(height: 16),
                      Text(
                          r.sex == 'F'
                              ? '¡Bienvenida, ${r.firstName}!'
                              : '¡Bienvenido, ${r.firstName}!',
                          textAlign: TextAlign.center,
                          style: headStyle(28)),
                      const SizedBox(height: 6),
                      Text(
                          'Quedó registrado/a como asistente nº ${r.regNumber}',
                          key: const Key('exito-numero'),
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(fontSize: 17, color: Brand.gris)),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    [r.firstName, r.lastName1, r.lastName2]
                                        .where((e) => e.isNotEmpty)
                                        .join(' '),
                                    style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w700)),
                                Text(
                                    '${r.sex == 'M' ? 'Hombre' : 'Mujer'} · ${r.age} años',
                                    style: const TextStyle(color: Brand.gris)),
                                if (savedSpouseName != null) ...[
                                  const Divider(height: 24),
                                  Row(children: [
                                    const Icon(Icons.favorite_border,
                                        color: Brand.azul, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text(
                                            'Cónyuge inscrito/a: $savedSpouseName (nº $savedSpouseNumber)',
                                            key: const Key('exito-conyuge')))
                                  ]),
                                ],
                                if (savedTeamName != null) ...[
                                  const Divider(height: 24),
                                  Row(children: [
                                    const Icon(Icons.groups_outlined,
                                        color: Brand.azul, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text('Equipo: $savedTeamName',
                                            key: const Key('exito-equipo')))
                                  ]),
                                ],
                                if (offersLodging && r.needsLodging) ...[
                                  const Divider(height: 24),
                                  Row(children: [
                                    const Icon(Icons.house_outlined,
                                        color: Brand.azul, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text(
                                            savedLodgingName == null
                                                ? 'Necesita hospedaje · sin asignar'
                                                : 'Hospedaje: $savedLodgingName',
                                            key: const Key('exito-hospedaje')))
                                  ]),
                                ],
                              ]),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        key: const Key('exito-otra'),
                        style: FilledButton.styleFrom(
                            backgroundColor: Brand.naranja,
                            foregroundColor: Brand.tinta),
                        onPressed: _reset,
                        icon: const Icon(Icons.add),
                        label: const Text('Registrar a otra persona'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        key: const Key('exito-volver'),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Terminar y volver a la lista'),
                      ),
                    ]),
              ),
            ),
          ),
        ),
      );
}

/// Alta de iglesia (nueva) o edición de una existente ([church]).
class ChurchDialog extends ConsumerStatefulWidget {
  const ChurchDialog(
      {super.key, this.initialName = '', this.initialProvince, this.church});
  final String initialName;
  final String? initialProvince;
  final ChurchRow? church;
  @override
  ConsumerState<ChurchDialog> createState() => _ChurchDialogState();
}

class _ChurchDialogState extends ConsumerState<ChurchDialog> {
  late final name =
      TextEditingController(text: widget.church?.name ?? widget.initialName);
  late final community =
      TextEditingController(text: widget.church?.community ?? '');
  late String? province = widget.church != null
      ? (widget.church!.province.isEmpty ? null : widget.church!.province)
      : widget.initialProvince;
  late String? municipality =
      widget.church == null || widget.church!.municipality.isEmpty
          ? null
          : widget.church!.municipality;
  String? error;

  /// Municipios de la provincia elegida: el catálogo completo más los que ya traigan las iglesias
  /// registradas (por si alguna se escribió distinto antes).
  List<String> _municipalities(List<ChurchRow> churches) {
    final out = <String>[...suggestedMunicipalities(province ?? '')];
    final known = out.map(normalizeText).toSet();
    for (final c in churches) {
      if (c.province == province &&
          c.municipality.isNotEmpty &&
          known.add(normalizeText(c.municipality))) {
        out.add(c.municipality);
      }
    }
    return out..sort((a, b) => normalizeText(a).compareTo(normalizeText(b)));
  }

  Future<void> _save() async {
    try {
      final repo = ref.read(repositoryProvider);
      final c = widget.church == null
          ? await repo.createChurch(
              name: name.text,
              province: province ?? '',
              municipality: municipality ?? '',
              community: community.text,
              requireLocation: true)
          : await repo.updateChurch(widget.church!.id,
              name: name.text,
              province: province ?? '',
              municipality: municipality ?? '',
              community: community.text);
      if (mounted) Navigator.pop(context, c);
    } on DataException catch (e) {
      setState(() => error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final churches =
        ref.watch(churchesProvider).valueOrNull ?? const <ChurchRow>[];
    final munis = _municipalities(churches);
    final communities = municipality == null
        ? const <String>[]
        : communitiesOf(churches, province ?? '', municipality!);
    return AlertDialog(
      title: Text(widget.church == null ? 'Iglesia nueva' : 'Editar iglesia'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: FocusTraversalGroup(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              LabeledField(
                  label: 'Nombre de la iglesia *',
                  child: TextField(
                      key: const Key('ni-nombre'),
                      controller: name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration())),
              const SizedBox(height: 12),
              LabeledField(
                  label: 'Provincia *',
                  child: DropdownButtonFormField<String>(
                    key: const Key('ni-provincia'),
                    initialValue: province,
                    isExpanded: true,
                    decoration: const InputDecoration(),
                    items: [
                      for (final p in cubaProvinces)
                        DropdownMenuItem(value: p, child: Text(p))
                    ],
                    onChanged: (v) => setState(() {
                      province = v;
                      municipality =
                          null; // los municipios dependen de la provincia
                      community.clear();
                    }),
                  )),
              const SizedBox(height: 12),
              // La clave cambia con la provincia para reconstruir la lista y vaciar la selección.
              LabeledField(
                  label: 'Municipio *',
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('ni-municipio-$province'),
                    initialValue: municipality,
                    isExpanded: true,
                    decoration: InputDecoration(
                        helperText: province == null
                            ? 'Elige primero la provincia'
                            : null),
                    items: [
                      for (final m in munis)
                        DropdownMenuItem(value: m, child: Text(m))
                    ],
                    onChanged: province == null
                        ? null
                        : (v) => setState(() {
                              municipality = v;
                              community.clear();
                            }),
                  )),
              const SizedBox(height: 12),
              // Comunidad: sugiere las del municipio; si no está, se escribe y queda añadida.
              RawAutocomplete<String>(
                key: ValueKey('ni-comunidad-$province-$municipality'),
                textEditingController: community,
                focusNode: _communityFocus,
                optionsBuilder: (v) {
                  final q = normalizeText(v.text);
                  return communities
                      .where((c) => q.isEmpty || normalizeText(c).contains(q));
                },
                onSelected: (v) => setState(() {}),
                fieldViewBuilder: (context, c, f, onSubmit) => LabeledField(
                    label: 'Comunidad',
                    optional: true,
                    child: TextField(
                      key: const Key('ni-comunidad'),
                      controller: c,
                      focusNode: f,
                      enabled: municipality != null,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                          helperText: municipality == null
                              ? 'Elige primero el municipio'
                              : communities.isEmpty
                                  ? 'Aún no hay comunidades en este municipio: escríbela y quedará añadida'
                                  : null),
                    )),
                optionsViewBuilder: (context, onSelected, options) => Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxHeight: 200, maxWidth: 420),
                      child: ListView(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          children: [
                            for (final o in options)
                              ListTile(
                                  key: Key('ni-comunidad-op-$o'),
                                  dense: true,
                                  title: Text(o),
                                  onTap: () => onSelected(o)),
                          ]),
                    ),
                  ),
                ),
              ),
              if (municipality != null &&
                  community.text.trim().isNotEmpty &&
                  !communities.any(
                      (c) => normalizeText(c) == normalizeText(community.text)))
                const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Comunidad nueva: se añadirá al guardar.',
                            key: Key('ni-comunidad-nueva'),
                            style:
                                TextStyle(color: Brand.gris, fontSize: 14)))),
              const SizedBox(height: 8),
              Text(
                  widget.church == null
                      ? 'Quedará en el catálogo para los próximos registros.'
                      : 'Si cambias la provincia o el municipio, también cambian en sus asistentes.',
                  style: TextStyle(color: Brand.gris, fontSize: 14)),
              if (error != null) ...[
                const SizedBox(height: 12),
                ErrorBox(error!)
              ],
            ]),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(
            key: const Key('ni-guardar'),
            onPressed: _save,
            child: Text(widget.church == null
                ? 'Añadir al catálogo'
                : 'Guardar cambios')),
      ],
    );
  }

  final _communityFocus = FocusNode();

  @override
  void dispose() {
    _communityFocus.dispose();
    name.dispose();
    community.dispose();
    super.dispose();
  }
}

/// Orden de Tab del formulario: solo pasa por los campos, en este orden.
Widget _tabOrder(double n, Widget child) =>
    FocusTraversalOrder(order: NumericFocusOrder(n), child: child);
