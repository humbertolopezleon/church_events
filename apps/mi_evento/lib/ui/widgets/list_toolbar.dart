import 'package:material_ui/material_ui.dart';

import '../../theme/app_theme.dart';

/// Barra común de las listas: búsqueda, filtros, conteo y «Exportar CSV» (de lo que se ve).
/// Los filtros se pueden plegar: en ventanas bajas (< 720 px) arrancan plegados para dejar sitio a la lista.
class ListToolbar extends StatefulWidget {
  const ListToolbar({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.count,
    this.filters = const [],
    this.activeFilters = 0,
    this.onExport,
    this.onImport,
    this.importKey = const Key('importar-csv'),
    this.searchKey = const Key('buscar'),
    this.exportKey = const Key('exportar-csv'),
    this.countKey = const Key('lista-conteo'),
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onChanged;

  /// Texto del conteo («120 inscritos», «12 de 120»).
  final String count;
  final List<Widget> filters;

  /// Cuántos filtros están activos (se muestra en el botón «Filtros»).
  final int activeFilters;
  final VoidCallback? onExport;

  /// Importar CSV (donde se exporta, también se importa).
  final VoidCallback? onImport;
  final Key importKey;
  final Key searchKey, exportKey, countKey;

  @override
  State<ListToolbar> createState() => _ListToolbarState();
}

class _ListToolbarState extends State<ListToolbar> {
  bool? _open;

  @override
  Widget build(BuildContext context) {
    // En el móvil los filtros empiezan plegados (si no, ocupan toda la pantalla y tapan la lista);
    // en escritorio, desplegados si hay altura.
    final size = MediaQuery.sizeOf(context);
    final open = _open ??
        ((size.width >= 900 && size.height >= 720) || widget.activeFilters > 0);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(
        key: widget.searchKey,
        controller: widget.controller,
        onChanged: (_) => widget.onChanged(),
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: widget.controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Limpiar',
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    widget.controller.clear();
                    widget.onChanged();
                  }),
        ),
      ),
      if (open && widget.filters.isNotEmpty) ...[
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: widget.filters),
      ],
      const SizedBox(height: 4),
      Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Text(widget.count,
                key: widget.countKey,
                style: const TextStyle(color: Brand.gris)),
            Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (widget.filters.isNotEmpty)
                    TextButton.icon(
                        key: const Key('filtros-toggle'),
                        onPressed: () => setState(() => _open = !open),
                        icon:
                            Icon(open ? Icons.expand_less : Icons.filter_list),
                        label: Text(widget.activeFilters > 0
                            ? 'Filtros (${widget.activeFilters})'
                            : 'Filtros')),
                  if (widget.onImport != null)
                    OutlinedButton.icon(
                        key: widget.importKey,
                        onPressed: widget.onImport,
                        icon: const Icon(Icons.upload_file_outlined),
                        label: const Text('Importar CSV')),
                  if (widget.onExport != null)
                    OutlinedButton.icon(
                        key: widget.exportKey,
                        onPressed: widget.onExport,
                        icon: const Icon(Icons.table_view_outlined),
                        label: const Text('Exportar CSV')),
                ]),
          ]),
    ]);
  }
}

/// Filtro desplegable compacto: «Sexo: Todos». [value] null = sin filtrar.
class FilterDropdown<T> extends StatelessWidget {
  const FilterDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final String label;
  final T? value;

  /// Opciones (valor → texto). La opción «Todos» la pone este widget.
  final Map<T, String> options;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 150, maxWidth: 240),
        child: DropdownButtonFormField<T?>(
          isExpanded: true,
          initialValue: value,
          decoration: InputDecoration(labelText: label, isDense: true),
          items: [
            DropdownMenuItem<T?>(value: null, child: const Text('Todos')),
            for (final e in options.entries)
              DropdownMenuItem<T?>(
                  value: e.key,
                  child: Text(e.value, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: onChanged,
        ),
      );
}
