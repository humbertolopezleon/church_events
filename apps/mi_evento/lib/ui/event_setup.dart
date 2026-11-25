import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'widgets/labeled_field.dart';

import '../auth/auth_service.dart';
import '../data/database.dart';
import '../data/repos_b.dart';
import '../data/repository.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import 'auth_screens.dart' show ErrorBox;
import 'lodgings_screen.dart' show openLodgingForm;
import 'teams_screen.dart' show LimitsDialog, showCreateTeamsDialog;

/// Qué falta definir antes de abrir las inscripciones.
class SetupStatus {
  const SetupStatus({required this.needsLodgings, required this.needsTeams});
  final bool needsLodgings;
  final bool needsTeams;
  bool get complete => !needsLodgings && !needsTeams;
}

/// Falta definir hospedajes si el evento los ofrece y no hay ninguno; igual con los equipos.
SetupStatus setupStatusOf(Event? e, int lodgingCount, int teamCount) =>
    SetupStatus(
      needsLodgings: (e?.offersLodging ?? false) && lodgingCount == 0,
      needsTeams: (e?.offersTeams ?? false) && teamCount == 0,
    );

/// Configuración del evento (primer momento de la app). Mientras el evento no esté configurado
/// es la única pantalla; al terminar se abren las inscripciones y el resto de actividades.
/// El administrador puede volver aquí cuando quiera desde «Configuración».
class EventConfigScreen extends ConsumerStatefulWidget {
  const EventConfigScreen({super.key});
  @override
  ConsumerState<EventConfigScreen> createState() => _EventConfigScreenState();
}

class _EventConfigScreenState extends ConsumerState<EventConfigScreen> {
  final name = TextEditingController();
  final venue = TextEditingController();
  final organizer = TextEditingController();
  DateTime start = DateTime.now();
  DateTime end = DateTime.now();
  bool lodging = true;
  bool teams = true;
  bool loaded = false;
  bool dirty = false;
  bool saved =
      false; // «Datos guardados» (en la pantalla, no como aviso flotante que tape el botón)
  String? error;

  String _d(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _load(Event e) {
    name.text = e.name;
    venue.text = e.venue;
    organizer.text = e.organizer;
    start = DateTime.tryParse(e.startDate) ?? start;
    end = DateTime.tryParse(e.endDate) ?? end;
    lodging = e.offersLodging;
    teams = e.offersTeams;
    loaded = true;
  }

  String get _rangeText => _d(start) == _d(end)
      ? 'Un solo día: ${_d(start)}'
      : '${_d(start)}  →  ${_d(end)}';

  Future<void> _pickRange() async {
    final r = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: start, end: end),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Fechas del evento',
      saveText: 'Aceptar',
    );
    if (r != null) {
      setState(() {
        start = r.start;
        end = r.end;
        dirty = true;
      });
    }
  }

  Future<void> _saveData(String eventId) async {
    try {
      await ref.read(repositoryProvider).updateEvent(eventId,
          name: name.text,
          startDate: _d(start),
          endDate: _d(end),
          venue: venue.text,
          organizer: organizer.text,
          offersLodging: lodging,
          offersTeams: teams);
      if (!mounted) return;
      setState(() {
        dirty = false;
        saved = true;
        error = null;
      });
    } on DataException catch (e) {
      if (mounted) setState(() => error = e.message);
    }
  }

  Future<void> _finish(String eventId, SetupStatus status) async {
    if (dirty) {
      setState(() => error =
          'Hay cambios sin guardar en los datos del evento. Pulsa «Guardar datos» primero.');
      return;
    }
    if (!status.complete) {
      final what = [
        if (status.needsLodgings) 'los hospedajes',
        if (status.needsTeams) 'los equipos',
      ].join(' y ');
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Faltan $what'),
          content: const Text(
              'Si abres las inscripciones ahora, las personas se inscribirán sin ese dato y habrá que asignarlo después. ¿Abrir las inscripciones de todas formas?'),
          actions: [
            TextButton(
                key: const Key('cfg-seguir'),
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Seguir configurando')),
            FilledButton(
                key: const Key('cfg-terminar-igual'),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Abrir de todas formas')),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    await ref.read(repositoryProvider).setSetupDone(eventId, true);
    if (!mounted) return;
    ref.read(currentPageProvider.notifier).state = 'panel';
  }

  @override
  Widget build(BuildContext context) {
    final eventId = ref.watch(currentEventIdProvider)!;
    final e = ref.watch(eventProvider(eventId)).valueOrNull;
    final counts = ref.watch(setupCountsProvider(eventId)).valueOrNull ??
        const SetupCounts(0, 0, 0);
    final me = ref.watch(currentUserProvider);
    final admin = me?.isAdmin ?? false;
    if (e == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!loaded) _load(e);
    final configuring = !e.setupDone;
    final status = setupStatusOf(
        e.copyWith(offersLodging: lodging, offersTeams: teams),
        counts.lodgings,
        counts.teams);
    final limits = e.balanceLimits;

    Widget section(String title, IconData icon, List<Widget> children) => Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(icon, color: Brand.azul),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800))),
              ]),
              const SizedBox(height: 8),
              ...children,
            ]),
          ),
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración del evento'),
        actions: [
          if (configuring)
            TextButton.icon(
              key: const Key('cfg-mis-eventos'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              onPressed: () =>
                  ref.read(currentEventIdProvider.notifier).state = null,
              icon: const Icon(Icons.event_outlined),
              label: const Text('Mis eventos'),
            ),
        ],
      ),
      // El botón para terminar queda siempre a la vista, aunque la pantalla sea baja.
      bottomNavigationBar: configuring && admin
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  key: const Key('cfg-terminar'),
                  style: FilledButton.styleFrom(
                      backgroundColor: Brand.naranja,
                      foregroundColor: Brand.tinta,
                      minimumSize: const Size.fromHeight(60)),
                  onPressed: () => _finish(eventId, status),
                  icon: const Icon(Icons.check),
                  label: const Text(
                      'Terminar configuración y abrir inscripciones'),
                ),
              ),
            )
          : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(padding: const EdgeInsets.all(16), children: [
            if (configuring)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                    admin
                        ? 'Paso 1 de 2: deja el evento listo. Después abrirás las inscripciones y el resto de las actividades.'
                        : 'El administrador está configurando este evento. Cuando lo termine podrás inscribir y usar el resto de las actividades.',
                    key: const Key('cfg-intro'),
                    style: const TextStyle(fontSize: 16, color: Brand.gris)),
              ),
            if (admin) ...[
              section('Datos del evento', Icons.event_note_outlined, [
                LabeledField(
                    label: 'Nombre',
                    child: TextField(
                        key: const Key('cfg-nombre'),
                        controller: name,
                        onChanged: (_) => setState(() {
                              dirty = true;
                              saved = false;
                            }),
                        decoration: const InputDecoration())),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('cfg-fechas'),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      alignment: Alignment.centerLeft),
                  onPressed: _pickRange,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text('Fechas: $_rangeText'),
                ),
                const SizedBox(height: 12),
                LabeledField(
                    label: 'Lugar',
                    child: TextField(
                        controller: venue,
                        onChanged: (_) => setState(() {
                              dirty = true;
                              saved = false;
                            }),
                        decoration: const InputDecoration())),
                const SizedBox(height: 12),
                LabeledField(
                    label: 'Organizador',
                    child: TextField(
                        controller: organizer,
                        onChanged: (_) => setState(() {
                              dirty = true;
                              saved = false;
                            }),
                        decoration: const InputDecoration())),
                SwitchListTile(
                    key: const Key('cfg-hospedaje'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ofrece hospedaje'),
                    value: lodging,
                    onChanged: (v) => setState(() {
                          lodging = v;
                          dirty = true;
                        })),
                SwitchListTile(
                    key: const Key('cfg-equipos'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Se dividirá en equipos'),
                    value: teams,
                    onChanged: (v) => setState(() {
                          teams = v;
                          dirty = true;
                        })),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  ErrorBox(error!)
                ],
                const SizedBox(height: 8),
                Row(children: [
                  FilledButton(
                      key: const Key('cfg-guardar-datos'),
                      onPressed: dirty ? () => _saveData(eventId) : null,
                      child: const Text('Guardar datos')),
                  const SizedBox(width: 12),
                  if (saved && !dirty)
                    const Text('Datos guardados',
                        key: Key('cfg-guardado'),
                        style: TextStyle(
                            color: Brand.exito, fontWeight: FontWeight.w700)),
                ]),
              ]),
              if (lodging) ...[
                const SizedBox(height: 12),
                section('Hospedajes', Icons.house_outlined, [
                  Text(
                      counts.lodgings == 0
                          ? 'Falta definirlos'
                          : '${counts.lodgings} ${counts.lodgings == 1 ? 'hospedaje' : 'hospedajes'} · ${counts.places} plazas',
                      key: const Key('cfg-hospedajes-estado'),
                      style: TextStyle(
                          color: counts.lodgings == 0
                              ? Brand.avisoTexto
                              : Brand.exito,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                      key: const Key('cfg-hospedajes'),
                      onPressed: () => openLodgingForm(context, eventId),
                      icon: const Icon(Icons.add),
                      label: Text(counts.lodgings == 0
                          ? 'Definir hospedajes'
                          : 'Agregar otro hospedaje')),
                ]),
              ],
              if (teams) ...[
                const SizedBox(height: 12),
                section('Equipos', Icons.groups_outlined, [
                  Text(
                      counts.teams == 0
                          ? 'Falta definirlos'
                          : '${counts.teams} ${counts.teams == 1 ? 'equipo' : 'equipos'}',
                      key: const Key('cfg-equipos-estado'),
                      style: TextStyle(
                          color: counts.teams == 0
                              ? Brand.avisoTexto
                              : Brand.exito,
                          fontWeight: FontWeight.w700)),
                  if (counts.teams > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                        'Criterios de balance: tamaño ±${limits.maxSizeDiff} · hombres–mujeres ≤ ${limits.maxSexDiff} · edad media ±${limits.maxAgeDiff} años',
                        key: const Key('cfg-criterios'),
                        style: const TextStyle(color: Brand.gris)),
                  ],
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    FilledButton.icon(
                        key: const Key('cfg-equipos-definir'),
                        onPressed: () => showCreateTeamsDialog(
                            context, ref, eventId,
                            askCriteria: counts.teams == 0),
                        icon: const Icon(Icons.add),
                        label: Text(counts.teams == 0
                            ? 'Definir equipos'
                            : 'Agregar más equipos')),
                    if (counts.teams > 0)
                      OutlinedButton.icon(
                          key: const Key('cfg-cambiar-criterios'),
                          onPressed: () => showDialog<void>(
                              context: context,
                              builder: (_) => LimitsDialog(
                                  eventId: eventId, limits: limits)),
                          icon: const Icon(Icons.tune),
                          label: const Text('Cambiar criterios')),
                  ]),
                ]),
              ],
              const SizedBox(height: 16),
              if (!configuring)
                OutlinedButton(
                    key: const Key('cfg-volver'),
                    onPressed: () =>
                        ref.read(currentPageProvider.notifier).state = 'panel',
                    child: const Text('Volver al panel')),
            ] else
              const Text('Solo el administrador puede configurar el evento.',
                  style: TextStyle(color: Brand.gris)),
          ]),
        ),
      ),
    );
  }
}
