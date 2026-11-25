import 'package:material_ui/material_ui.dart';

import '../../theme/app_theme.dart';
import 'labeled_field.dart';

/// Un filtro de una lista. Los hay de elección única ([ChoiceFilter]) y de interruptor
/// ([ToggleFilter]). Se vuelven a construir con el estado actual cada vez que cambian.
abstract class FilterSpec {
  const FilterSpec({required this.key, required this.label});
  final Key key;
  final String label;
  bool get active;

  /// Texto del chip de filtro activo («Sexo: Hombres»); nulo si no está activo.
  String? get activeText;
  void clear();
}

class ChoiceFilter<T> extends FilterSpec {
  const ChoiceFilter({
    required super.key,
    required super.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.allLabel = 'Todos',
    this.wide = false,
  });
  final T? value;

  /// Opciones (valor → texto). La opción «todos» ([allLabel]) la pone el propio filtro.
  final Map<T, String> options;
  final ValueChanged<T?> onChanged;

  /// «Todos» o «Todas» según el género de lo que se filtra.
  final String allLabel;

  /// Muchas opciones (Iglesia, Provincia…): selector de ancho completo en vez de chips.
  final bool wide;

  @override
  bool get active => value != null;
  @override
  String? get activeText =>
      active ? '$label: ${options[value] ?? value}' : null;
  @override
  void clear() => onChanged(null);

  // Acceso sin tipo (las hojas dibujan filtros de cualquier tipo de valor).
  void select(Object? v) => onChanged(v as T?);
  Object? get current => value;
  Iterable<MapEntry<Object?, String>> get entries =>
      options.entries.map((e) => MapEntry<Object?, String>(e.key, e.value));
}

class ToggleFilter extends FilterSpec {
  const ToggleFilter({
    required super.key,
    required super.label,
    required this.value,
    required this.onChanged,
  });
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  bool get active => value;
  @override
  String? get activeText => active ? label : null;
  @override
  void clear() => onChanged(false);
}

/// Chip de selección: seleccionado = azul relleno con ✓; el resto, blanco con borde. 44 dp de alto,
/// y anuncia a los lectores de pantalla si está seleccionado.
class SelectChip extends StatelessWidget {
  const SelectChip(
      {super.key,
      required this.label,
      required this.selected,
      required this.onTap,
      this.trailing,
      this.exclusiveGroup = true});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool exclusiveGroup;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        inMutuallyExclusiveGroup: exclusiveGroup,
        label: label,
        excludeSemantics: true,
        onTap: onTap,
        child: Material(
          color: selected ? Brand.azul : Colors.white,
          shape: StadiumBorder(
              side: BorderSide(
                  color: selected ? Brand.azul : const Color(0xFF8A93A3),
                  width: 1.5)),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (selected) ...[
                    const Icon(Icons.check, size: 18, color: Colors.white),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(label,
                        style: bodyStyle(16,
                            color: selected ? Colors.white : Brand.tinta,
                            weight:
                                selected ? FontWeight.w700 : FontWeight.w400)),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 4),
                    trailing!,
                  ],
                ]),
              ),
            ),
          ),
        ),
      );
}

/// Filtros directamente en pantalla (listas con 2 filtros o menos, p. ej. Hospedajes): los de
/// interruptor son un chip con ✓ cuando están activos; los de elección, un chip con menú.
class InlineFilters extends StatelessWidget {
  const InlineFilters({super.key, required this.filters});
  final List<FilterSpec> filters;

  @override
  Widget build(BuildContext context) =>
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final f in filters)
          if (f is ToggleFilter)
            SelectChip(
                key: f.key,
                label: f.label,
                selected: f.value,
                exclusiveGroup: false,
                onTap: () => f.onChanged(!f.value))
          else if (f is ChoiceFilter)
            _ChoiceMenuChip(f),
      ]);
}

class _ChoiceMenuChip extends StatelessWidget {
  const _ChoiceMenuChip(this.f);
  final ChoiceFilter<Object?> f;

  @override
  Widget build(BuildContext context) => PopupMenuButton<Object?>(
        key: f.key,
        tooltip: f.label,
        onSelected: (v) => f.select(v == _all ? null : v),
        itemBuilder: (_) => [
          PopupMenuItem<Object?>(value: _all, child: Text(f.allLabel)),
          for (final e in f.entries)
            PopupMenuItem<Object?>(value: e.key, child: Text(e.value)),
        ],
        child: IgnorePointer(
          child: SelectChip(
              label:
                  '${f.label}: ${f.active ? f.activeText!.substring(f.label.length + 2) : f.allLabel.toLowerCase()}',
              selected: f.active,
              exclusiveGroup: false,
              trailing: Icon(Icons.arrow_drop_down,
                  size: 22, color: f.active ? Colors.white : Brand.tinta),
              onTap: () {}),
        ),
      );
}

const Object _all = Object();

/// Hoja de filtros (desde abajo): chips de selección única para pocas opciones, selector de ancho
/// completo para muchas, «Limpiar todo» y un botón «Ver N …» con el resultado en vivo.
Future<void> showFilterSheet(
  BuildContext context, {
  required List<FilterSpec> Function() filters,
  required int Function() resultCount,
  required String Function(int) resultLabel,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        final list = filters();
        void change(VoidCallback fn) {
          fn();
          setSheet(() {});
        }

        final n = resultCount();
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 0),
              child: Row(children: [
                Expanded(child: Text('Filtros', style: headStyle(22))),
                TextButton(
                    key: const Key('filtros-limpiar-todo'),
                    onPressed: list.any((f) => f.active)
                        ? () => change(() {
                              for (final f in list) {
                                f.clear();
                              }
                            })
                        : null,
                    child: const Text('Limpiar todo')),
              ]),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final f in list) ...[
                        _sheetFilter(f, change),
                        const SizedBox(height: 16),
                      ],
                    ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                    key: const Key('filtros-ver'),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(resultLabel(n))),
              ),
            ),
          ]),
        );
      }),
    );

Widget _sheetFilter(FilterSpec f, void Function(VoidCallback) change) {
  if (f is ToggleFilter) {
    return SelectChip(
        key: f.key,
        label: f.label,
        selected: f.value,
        exclusiveGroup: false,
        onTap: () => change(() => f.onChanged(!f.value)));
  }
  final c = f as ChoiceFilter<Object?>;
  if (c.wide) {
    return LabeledField(
      label: c.label,
      child: DropdownButtonFormField<Object?>(
        key: c.key,
        isExpanded: true,
        initialValue: c.current,
        items: [
          DropdownMenuItem<Object?>(value: null, child: Text(c.allLabel)),
          for (final e in c.entries)
            DropdownMenuItem<Object?>(
                value: e.key,
                child: Text(e.value, overflow: TextOverflow.ellipsis)),
        ],
        onChanged: (v) => change(() => c.select(v)),
      ),
    );
  }
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(c.label, style: bodyStyle(16, weight: FontWeight.w700)),
    const SizedBox(height: 8),
    Wrap(spacing: 8, runSpacing: 8, children: [
      SelectChip(
          key: ValueKey('${c.key}#todos'),
          label: c.allLabel,
          selected: !c.active,
          onTap: () => change(() => c.select(null))),
      for (final e in c.entries)
        SelectChip(
            key: ValueKey('${c.key}#opt-${e.key}'),
            label: e.value,
            selected: c.current == e.key,
            onTap: () => change(() => c.select(e.key))),
    ]),
  ]);
}
