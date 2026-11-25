import 'package:material_ui/material_ui.dart';

import '../../theme/app_theme.dart';
import '../shortcuts.dart';
import 'filter_spec.dart';

/// Barra común de las listas: buscador con lupa, botón «Filtros» (con el número de filtros activos
/// en un círculo naranja) que abre una hoja desde abajo, chips de los filtros activos y la línea de
/// resultados. Importar y exportar CSV van en el menú ⋮ de la cabecera ([AppHeader]).
///
/// Con [inline] (listas de 2 filtros o menos, p. ej. Hospedajes) los filtros van directamente en
/// pantalla, sin hoja.
class ListToolbar extends StatelessWidget {
  const ListToolbar({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.count,
    this.filters,
    this.resultCount,
    this.resultLabel,
    this.inline = false,
    this.searchKey = const Key('buscar'),
    this.countKey = const Key('lista-conteo'),
  });

  final TextEditingController controller;

  /// Ejemplo corto que no se corte (sin «Buscar por…»).
  final String hint;
  final VoidCallback onChanged;

  /// Línea de resultados («12 de 248 · más recientes primero»).
  final String count;

  /// Filtros con su estado actual (se vuelve a llamar tras cada cambio).
  final List<FilterSpec> Function()? filters;

  /// Resultados con los filtros actuales (para «Ver N …» en la hoja).
  final int Function()? resultCount;
  final String Function(int)? resultLabel;
  final bool inline;
  final Key searchKey, countKey;

  @override
  Widget build(BuildContext context) {
    final specs = filters?.call() ?? const <FilterSpec>[];
    final active = [
      for (final f in specs)
        if (f.active) f
    ];
    final useSheet = specs.isNotEmpty && !inline;
    // Con letra grande el botón «Filtros» baja bajo el buscador para que nada se corte.
    final large = MediaQuery.textScalerOf(context).scale(16) > 18.4;
    void openSheet() => showFilterSheet(context,
        filters: filters!,
        resultCount: resultCount ?? () => 0,
        resultLabel: resultLabel ?? ((n) => 'Ver resultados'));
    // Ctrl+Mayús+F abre la hoja de filtros (igual que el botón «Filtros»).
    Widget filtersButton() => ScreenShortcutsScope(
        handlers: {ScreenAction.filters: openSheet},
        child: _FiltersButton(count: active.length, onPressed: openSheet));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: _SearchField(
            fieldKey: searchKey,
            controller: controller,
            onChanged: (_) => onChanged(),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Borrar búsqueda',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        controller.clear();
                        onChanged();
                      }),
            ),
          ),
        ),
        if (useSheet && !large) ...[
          const SizedBox(width: 8),
          filtersButton(),
        ],
      ]),
      if (useSheet && large) ...[
        const SizedBox(height: 8),
        Align(alignment: Alignment.centerLeft, child: filtersButton()),
      ],
      if (inline && specs.isNotEmpty) ...[
        const SizedBox(height: 8),
        InlineFilters(filters: specs),
      ],
      if (useSheet && active.isNotEmpty) ...[
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Wrap(spacing: 8, runSpacing: 6, children: [
              for (final f in active) _ActiveChip(f),
            ]),
          ),
          TextButton(
              key: const Key('filtros-limpiar'),
              onPressed: () {
                for (final f in active) {
                  f.clear();
                }
              },
              child: const Text('Limpiar')),
        ]),
      ],
      if (count.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(count,
              key: countKey, style: bodyStyle(15, color: Brand.gris)),
        ),
    ]);
  }
}

/// Campo de búsqueda con su propio foco: Ctrl+F y «/» lo enfocan.
class _SearchField extends StatefulWidget {
  const _SearchField(
      {required this.fieldKey,
      required this.controller,
      required this.onChanged,
      required this.textInputAction,
      required this.decoration});
  final Key fieldKey;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final TextInputAction textInputAction;
  final InputDecoration decoration;
  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final focus = FocusNode();

  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScreenShortcutsScope(
        handlers: {
          ScreenAction.search: () {
            focus.requestFocus();
            // Deja el texto que hubiera seleccionado para escribir encima.
            widget.controller.selection = TextSelection(
                baseOffset: 0, extentOffset: widget.controller.text.length);
          },
        },
        child: TextField(
          key: widget.fieldKey,
          focusNode: focus,
          controller: widget.controller,
          onChanged: widget.onChanged,
          textInputAction: widget.textInputAction,
          decoration: widget.decoration,
        ),
      );
}

class _FiltersButton extends StatelessWidget {
  const _FiltersButton({required this.count, required this.onPressed});
  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: count == 0
            ? 'Filtros'
            : 'Filtros, ${count == 1 ? '1 activo' : '$count activos'}',
        excludeSemantics: true,
        onTap: onPressed,
        child: OutlinedButton(
          key: const Key('filtros-toggle'),
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
              minimumSize: const Size(64, 56),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              side: const BorderSide(color: Brand.azul, width: 1.5)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.tune, size: 20),
            const SizedBox(width: 6),
            const Text('Filtros'),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Container(
                key: const Key('filtros-contador'),
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                    color: Brand.naranja, shape: BoxShape.circle),
                child: Text('$count',
                    style: bodyStyle(14,
                        color: Brand.tinta, weight: FontWeight.w700)),
              ),
            ],
          ]),
        ),
      );
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip(this.f);
  final FilterSpec f;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Quitar filtro ${f.activeText}',
        excludeSemantics: true,
        onTap: f.clear,
        child: Material(
          color: Brand.azulSuave,
          shape: const StadiumBorder(side: BorderSide(color: Brand.azul)),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: f.clear,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.only(left: 14, right: 8),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Flexible(
                    child: Text(f.activeText ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: bodyStyle(15,
                            color: Brand.azul, weight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.close, size: 18, color: Brand.azul),
                ]),
              ),
            ),
          ),
        ),
      );
}
