import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String isoDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Primer día que se puede elegir para un evento: hoy, salvo que el evento ya tenga una fecha de
/// inicio anterior (al editarlo se respeta, para no obligar a cambiarla).
DateTime earliestEventDate({DateTime? current}) {
  final today = dateOnly(DateTime.now());
  if (current == null) return today;
  final c = dateOnly(current);
  return c.isBefore(today) ? c : today;
}

/// Elegir las fechas de un evento: «Inicio» y «Fin» sobre un mismo calendario, con el botón
/// **Hoy** para volver al día actual. No deja elegir días anteriores a [earliest] (por defecto, hoy).
/// Para un evento de un solo día basta con aceptar con el mismo inicio y fin.
Future<DateTimeRange?> pickEventDates(BuildContext context,
    {required DateTime start,
    required DateTime end,
    String title = 'Fechas del evento',
    DateTime? earliest}) {
  return showDialog<DateTimeRange>(
    context: context,
    builder: (_) => _EventDatesDialog(
        start: dateOnly(start),
        end: dateOnly(end),
        title: title,
        earliest: dateOnly(earliest ?? DateTime.now())),
  );
}

class _EventDatesDialog extends StatefulWidget {
  const _EventDatesDialog(
      {required this.start,
      required this.end,
      required this.title,
      required this.earliest});
  final DateTime start, end, earliest;
  final String title;
  @override
  State<_EventDatesDialog> createState() => _EventDatesDialogState();
}

class _EventDatesDialogState extends State<_EventDatesDialog> {
  late DateTime start =
      widget.start.isBefore(widget.earliest) ? widget.earliest : widget.start;
  late DateTime end = widget.end.isBefore(start) ? start : widget.end;
  bool editingEnd = false;
  int _rebuild = 0; // fuerza al calendario a mostrar otro mes (botón «Hoy»)

  void _setActive(DateTime d) => setState(() {
        if (editingEnd) {
          end = d;
        } else {
          start = d;
          if (end.isBefore(start)) end = start;
          editingEnd = true; // tras el inicio se pide el fin
        }
        _rebuild++;
      });

  void _today() {
    final today = dateOnly(DateTime.now());
    if (today.isBefore(widget.earliest)) return;
    setState(() {
      if (editingEnd) {
        end = today;
        if (start.isAfter(end)) start = today;
      } else {
        start = today;
        if (end.isBefore(start)) end = today;
      }
      _rebuild++;
    });
  }

  Widget _tab(String label, DateTime d, bool end) {
    final selected = editingEnd == end;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: '$label ${isoDate(d)}',
        child: InkWell(
          key: Key(end ? 'fechas-fin' : 'fechas-inicio'),
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() {
            editingEnd = end;
            _rebuild++;
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
                color: selected ? Brand.azul.withValues(alpha: 0.1) : null,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: selected ? Brand.azul : Brand.gris, width: 2)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: bodyStyle(14, color: Brand.gris)),
              FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(isoDate(d),
                      style: bodyStyle(17, weight: FontWeight.w700))),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final first = editingEnd ? start : widget.earliest;
    final active = editingEnd ? end : start;
    return AlertDialog(
      key: const Key('fechas-dialogo'),
      title: Text(widget.title),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              _tab('Inicio', start, false),
              const SizedBox(width: 8),
              _tab('Fin', end, true),
            ]),
            const SizedBox(height: 8),
            // Las celdas del calendario son de tamaño fijo: con la letra al 130 % cortaban los
            // números, así que aquí la escala se limita (el resto del diálogo sí crece).
            MediaQuery(
              data: MediaQuery.of(context).copyWith(
                  textScaler: MediaQuery.textScalerOf(context)
                      .clamp(maxScaleFactor: 1.0)),
              child: CalendarDatePicker(
                key: ValueKey('cal-$editingEnd-$_rebuild'),
                initialDate: active.isBefore(first) ? first : active,
                firstDate: first,
                lastDate: DateTime(2100),
                onDateChanged: _setActive,
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                  key: const Key('fechas-hoy'),
                  onPressed: _today,
                  icon: const Icon(Icons.today),
                  label: const Text('Hoy')),
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(
            key: const Key('fechas-aceptar'),
            onPressed: () =>
                Navigator.pop(context, DateTimeRange(start: start, end: end)),
            child: const Text('Aceptar')),
      ],
    );
  }
}
