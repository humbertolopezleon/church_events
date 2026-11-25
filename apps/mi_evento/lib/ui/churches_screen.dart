import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import '../data/church_exchange.dart';
import '../data/database.dart';
import '../data/repository.dart';
import '../export/csv_export.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import 'attendee_form.dart' show ChurchDialog;
import 'table_import_flow.dart';
import 'widgets/data_table_view.dart';
import 'widgets/highlight_text.dart';
import 'widgets/list_toolbar.dart';
import 'widgets/app_fab.dart';
import 'widgets/app_header.dart';
import 'widgets/filter_spec.dart';
import 'widgets/plural.dart';

/// Gestión de las iglesias registradas en el sistema (solo administrador): buscar, filtrar,
/// crear, editar, eliminar (si no tienen asistentes), exportar e importar CSV.
class ChurchesScreen extends ConsumerStatefulWidget {
  const ChurchesScreen({super.key});
  @override
  ConsumerState<ChurchesScreen> createState() => _ChurchesScreenState();
}

class _ChurchesScreenState extends ConsumerState<ChurchesScreen> {
  final query = TextEditingController();
  String? province, municipality;
  Map<String, int> counts = const {};

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  Future<void> _loadCounts() async {
    final c = await ref.read(repositoryProvider).churchAttendeeCounts();
    if (mounted) setState(() => counts = c);
  }

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  List<ChurchRow> _filter(List<ChurchRow> all) {
    final q = normalizeText(query.text);
    final words = q.isEmpty ? const <String>[] : q.split(' ');
    return [
      for (final c in all)
        if ((province == null || c.province == province) &&
            (municipality == null || c.municipality == municipality) &&
            words.every(normalizeText(c.name).contains))
          c
    ];
  }

  Future<void> _export(List<ChurchRow> shown) => saveCsv(context, ref,
      name: csvFileName('iglesias'), rows: ChurchExchange.toRows(shown));

  Future<void> _import() async {
    final done = await runTableImport(
        context, ref, ChurchExchange(ref.read(databaseProvider)));
    if (done) await _loadCounts();
  }

  Future<void> _edit([ChurchRow? c]) async {
    await showDialog<ChurchRow>(
        context: context, builder: (_) => ChurchDialog(church: c));
    await _loadCounts();
  }

  Future<void> _delete(ChurchRow c) async {
    final n = counts[c.id] ?? 0;
    if (n > 0) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          key: const Key('ig-no-eliminar'),
          title: const Text('No se puede eliminar'),
          content: Text(
              '«${c.name}» tiene $n ${n == 1 ? 'asistente' : 'asistentes'}. Cámbialos de iglesia (desde su ficha) y vuelve a intentarlo.'),
          actions: [
            FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Entendido'))
          ],
        ),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar esta iglesia?'),
        content: Text('«${c.name}» dejará de aparecer en el catálogo.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              key: const Key('ig-confirmar-eliminar'),
              style: FilledButton.styleFrom(backgroundColor: Brand.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(repositoryProvider).deleteChurch(c.id);
    } on DataException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Widget _menu(ChurchRow c) => PopupMenuButton<String>(
        key: Key('ig-menu-${c.name}'),
        tooltip: 'Acciones',
        onSelected: (v) => v == 'editar' ? _edit(c) : _delete(c),
        itemBuilder: (_) => const [
          PopupMenuItem(
              key: Key('ig-editar'), value: 'editar', child: Text('Editar…')),
          PopupMenuItem(
              key: Key('ig-eliminar'),
              value: 'eliminar',
              child: Text('Eliminar…')),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(churchesProvider).valueOrNull ?? const <ChurchRow>[];
    final shown = _filter(all);
    final provinces = {
      for (final c in all)
        if (c.province.isNotEmpty) c.province
    }.toList()
      ..sort();
    List<String> munisFor() => {
          for (final c in all)
            if (c.municipality.isNotEmpty &&
                (province == null || c.province == province))
              c.municipality
        }.toList()
          ..sort();
    final q = query.text;
    return Scaffold(
      appBar: AppHeader(
        title: 'Iglesias',
        subtitle:
            plural(all.length, 'iglesia', 'iglesias', zero: 'Sin iglesias'),
        importKey: const Key('ig-importar'),
        exportKey: const Key('ig-exportar'),
        onImport: _import,
        onExport: () => _export(shown),
        exportEnabled: shown.isNotEmpty,
      ),
      floatingActionButton: AppFab(
        key: const Key('ig-nueva'),
        onPressed: () => _edit(),
        icon: Icons.add,
        label: 'Nueva iglesia',
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: ListToolbar(
            controller: query,
            hint: 'Nombre de la iglesia',
            searchKey: const Key('ig-buscar'),
            countKey: const Key('ig-conteo'),
            onChanged: () => setState(() {}),
            count: shown.length == all.length
                ? 'Orden alfabético'
                : '${shown.length} de ${all.length} · orden alfabético',
            resultCount: () => _filter(all).length,
            resultLabel: (n) => n == 0
                ? 'Ninguna iglesia coincide'
                : 'Ver ${plural(n, 'iglesia', 'iglesias')}',
            filters: () => [
              ChoiceFilter<String>(
                  key: const Key('ig-filtro-provincia'),
                  label: 'Provincia',
                  allLabel: 'Todas',
                  wide: true,
                  value: province,
                  options: {for (final p in provinces) p: p},
                  onChanged: (v) => setState(() {
                        province = v;
                        municipality = null;
                      })),
              ChoiceFilter<String>(
                  key: ValueKey('ig-filtro-municipio-$province'),
                  label: 'Municipio',
                  wide: true,
                  value: municipality,
                  options: {for (final m in munisFor()) m: m},
                  onChanged: (v) => setState(() => municipality = v)),
            ],
          ),
        ),
        Expanded(
          child: shown.isEmpty
              ? Center(
                  child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                      all.isEmpty
                          ? 'Todavía no hay iglesias. Toca «Nueva iglesia» o importa un CSV.'
                          : 'Ninguna iglesia coincide con la búsqueda y los filtros.',
                      key: const Key('ig-vacio'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, color: Brand.gris)),
                ))
              : useTables(context)
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      child: DataTableView<ChurchRow>(
                        items: shown,
                        onTap: _edit,
                        columns: [
                          TableCol(
                              'Nombre',
                              (c) => HighlightText(c.name, q,
                                  key: Key('ig-${c.name}'),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              sortValue: (c) => c.nameNormalized),
                          TableCol('Provincia', (c) => Text(c.province),
                              sortValue: (c) => normalizeText(c.province)),
                          TableCol('Municipio', (c) => Text(c.municipality),
                              sortValue: (c) => normalizeText(c.municipality)),
                          TableCol(
                              'Comunidad',
                              (c) =>
                                  Text(c.community.isEmpty ? '—' : c.community),
                              sortValue: (c) => normalizeText(c.community)),
                          TableCol(
                              'Asistentes', (c) => Text('${counts[c.id] ?? 0}'),
                              numeric: true,
                              sortValue: (c) => counts[c.id] ?? 0),
                          TableCol('', _menu),
                        ],
                      ))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      itemCount: shown.length,
                      itemBuilder: (_, i) {
                        final c = shown[i];
                        final n = counts[c.id] ?? 0;
                        return Card(
                          child: InkWell(
                            key: Key('ig-${c.name}'),
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _edit(c),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
                              child: Row(children: [
                                Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        HighlightText(c.name, q,
                                            style: bodyStyle(17,
                                                weight: FontWeight.w700)),
                                        const SizedBox(height: 2),
                                        Text('${c.municipality}, ${c.province}',
                                            style: bodyStyle(14,
                                                color: Brand.gris)),
                                        const SizedBox(height: 2),
                                        Text(
                                            plural(
                                                n, 'asistente', 'asistentes'),
                                            key: Key('ig-asistentes-${c.name}'),
                                            style: bodyStyle(14,
                                                color: Brand.gris)),
                                      ]),
                                ),
                                _menu(c),
                              ]),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ]),
    );
  }
}
