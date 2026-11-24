import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/repository.dart';
import '../export/csv_export.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import 'widgets/list_toolbar.dart';

/// Confirmación de asistencia el día del evento: de los preinscritos, uno por uno, un subconjunto
/// marcado o todos a la vez (los que se ven según la búsqueda).
class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});
  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  final query = TextEditingController();
  final selected = <String>{};

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  Future<void> _confirm(String eventId, Iterable<String> ids) async {
    final list = ids.toList();
    if (list.isEmpty) return;
    final repo = ref.read(repositoryProvider);
    final n = await repo.confirmAttendance(list);
    ref.read(autoBackupProvider).noteChange(eventId);
    if (!mounted) return;
    setState(() => selected.removeAll(list));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(n == 1
            ? 'Asistencia confirmada (1 persona).'
            : 'Asistencia confirmada ($n personas).'),
        action: SnackBarAction(
            label: 'Deshacer', onPressed: () => repo.unconfirmAttendance(list)),
      ));
  }

  Future<void> _confirmAll(String eventId, List<AttendeeView> shown) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('ca-dialogo-todos'),
        title: const Text('Confirmar a todos'),
        content: Text(
            'Se confirmará la asistencia de ${shown.length} ${shown.length == 1 ? 'persona' : 'personas'}.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              key: const Key('ca-dialogo-ok'),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmar')),
        ],
      ),
    );
    if (ok == true) await _confirm(eventId, shown.map((v) => v.a.id));
  }

  /// Exporta a CSV los preinscritos que deja la búsqueda (con su hospedaje y equipo no: solo identidad).
  Future<void> _export(String eventId, List<AttendeeView> shown) {
    final event = ref.read(eventProvider(eventId)).valueOrNull;
    return saveCsv(context, ref,
        name: csvFileName('por-confirmar', event?.name ?? ''),
        rows: [
          ['numero', 'nombre', 'sexo', 'edad', 'iglesia', 'estado'],
          for (final v in shown)
            [
              '${v.a.regNumber}',
              v.fullName,
              v.isMale ? 'Hombre' : 'Mujer',
              '${v.a.age}',
              v.churchName ?? '',
              'Preinscrito',
            ],
        ]);
  }

  @override
  Widget build(BuildContext context) {
    final eventId = ref.watch(currentEventIdProvider)!;
    final all = ref.watch(attendeesProvider(eventId)).valueOrNull ??
        const <AttendeeView>[];
    final pending = [
      for (final v in all)
        if (v.isPreregistered) v
    ];
    final confirmed = all.length - pending.length;
    final shown = Repository.search(pending, query.text);
    final shownIds = {for (final v in shown) v.a.id};
    selected.retainAll({for (final v in pending) v.a.id});
    final sel = selected.where(shownIds.contains).toSet();
    final allSelected = shown.isNotEmpty && sel.length == shown.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar asistencia')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: ListToolbar(
            controller: query,
            hint: 'Buscar a un preinscrito por nombre, iglesia o número…',
            searchKey: const Key('ca-buscar'),
            countKey: const Key('ca-conteo'),
            exportKey: const Key('ca-exportar'),
            onExport: shown.isEmpty ? null : () => _export(eventId, shown),
            onChanged: () => setState(() {}),
            count:
                '${pending.length} por confirmar · $confirmed ya confirmados${query.text.isEmpty ? '' : ' · ${shown.length} coinciden'}',
          ),
        ),
        if (shown.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilterChip(
                      key: const Key('ca-sel-todos'),
                      label: Text(allSelected
                          ? 'Quitar selección'
                          : 'Seleccionar todos (${shown.length})'),
                      selected: allSelected,
                      onSelected: (v) => setState(() =>
                          v ? selected.addAll(shownIds) : selected.clear())),
                  FilledButton.icon(
                      key: const Key('ca-confirmar-sel'),
                      onPressed:
                          sel.isEmpty ? null : () => _confirm(eventId, sel),
                      icon: const Icon(Icons.check),
                      label: Text('Confirmar seleccionados (${sel.length})')),
                  OutlinedButton.icon(
                      key: const Key('ca-confirmar-todos'),
                      onPressed: () => _confirmAll(eventId, shown),
                      icon: const Icon(Icons.done_all),
                      label: Text(query.text.isEmpty
                          ? 'Confirmar a todos'
                          : 'Confirmar a los que se ven')),
                ]),
          ),
        Expanded(
          child: shown.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                        pending.isEmpty
                            ? (all.isEmpty
                                ? 'Todavía no hay nadie inscrito.'
                                : 'No hay preinscritos por confirmar. Todos los inscritos ya están confirmados.')
                            : 'Ningún preinscrito coincide con la búsqueda.',
                        key: const Key('ca-vacio'),
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(fontSize: 18, color: Brand.gris)),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: shown.length,
                  itemBuilder: (_, i) {
                    final v = shown[i];
                    final on = selected.contains(v.a.id);
                    return Card(
                      child: CheckboxListTile(
                        key: Key('ca-fila-${v.a.regNumber}'),
                        value: on,
                        onChanged: (x) => setState(() => x == true
                            ? selected.add(v.a.id)
                            : selected.remove(v.a.id)),
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(v.fullName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 17)),
                        subtitle: Text(
                            'Nº ${v.a.regNumber} · ${v.isMale ? 'Hombre' : 'Mujer'} · ${v.a.age} años${v.churchName == null ? '' : ' · ${v.churchName}'}'),
                        secondary: OutlinedButton(
                            key: Key('ca-confirmar-${v.a.regNumber}'),
                            onPressed: () => _confirm(eventId, [v.a.id]),
                            child: const Text('Confirmar')),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
