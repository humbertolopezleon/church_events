import 'package:material_ui/material_ui.dart';

import '../../theme/app_theme.dart';

/// Ancho a partir del cual las listas se muestran como tabla (escritorio); por debajo, tarjetas.
const tableBreakpoint = 900.0;

bool useTables(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= tableBreakpoint;

/// Columna de [DataTableView]: [sortValue] ordena al tocar el título; [cell] dibuja la celda.
class TableCol<T> {
  const TableCol(this.label, this.cell, {this.sortValue, this.numeric = false});
  final String label;
  final Widget Function(T item) cell;
  final Comparable<Object?> Function(T item)? sortValue;
  final bool numeric;
}

/// Tabla de datos con columnas ordenables, a lo ancho de la ventana (como en una web).
/// Tocar una fila llama a [onTap]; la tabla se desplaza si no cabe.
class DataTableView<T> extends StatefulWidget {
  const DataTableView({
    super.key,
    required this.items,
    required this.columns,
    this.onTap,
    this.initialSort = 0,
  });
  final List<T> items;
  final List<TableCol<T>> columns;
  final void Function(T item)? onTap;
  final int initialSort;

  @override
  State<DataTableView<T>> createState() => _DataTableViewState<T>();
}

class _DataTableViewState<T> extends State<DataTableView<T>> {
  late int sortIndex = widget.initialSort;
  bool ascending = true;

  @override
  Widget build(BuildContext context) {
    final col = widget.columns[sortIndex];
    final items = [...widget.items];
    final key = col.sortValue;
    if (key != null) {
      items.sort((a, b) {
        final r = Comparable.compare(key(a), key(b));
        return ascending ? r : -r;
      });
    }
    return LayoutBuilder(
      builder: (context, c) => Scrollbar(
        child: SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: c.maxWidth),
              child: DataTable(
                showCheckboxColumn: false,
                sortColumnIndex: sortIndex,
                sortAscending: ascending,
                headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.w800, color: Brand.tinta),
                dataRowMinHeight: 48,
                dataRowMaxHeight: 56,
                columns: [
                  for (var i = 0; i < widget.columns.length; i++)
                    DataColumn(
                      label: Text(widget.columns[i].label),
                      numeric: widget.columns[i].numeric,
                      onSort: widget.columns[i].sortValue == null
                          ? null
                          : (idx, asc) => setState(() {
                                sortIndex = idx;
                                ascending = asc;
                              }),
                    ),
                ],
                rows: [
                  for (final it in items)
                    DataRow(
                      onSelectChanged: widget.onTap == null
                          ? null
                          : (_) => widget.onTap!(it),
                      cells: [
                        // QA-WIN-04: los textos largos se parten en vez de ensanchar la tabla
                        // hasta dejar el menú «⋮» fuera de la ventana.
                        for (final c in widget.columns)
                          DataCell(c.label.isEmpty
                              ? c.cell(it)
                              : ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 260),
                                  child: c.cell(it))),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
