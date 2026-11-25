import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'helpers.dart';

/// Regresión (captura de un teléfono real): en Asistentes los filtros desplegados llenaban la
/// pantalla, el botón flotante tapaba «Exportar» y no se veía ni una persona.
void main() {
  testWidgets(
      'móvil: se ve la lista, nada se solapa y se puede editar y confirmar',
      (t) async {
    final c = await pumpApp(
        t, const Size(411, 890)); // como el teléfono de la captura
    await t.runAsync(() async {
      final ev = await c.repo.createEvent(
          name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
      for (final (n, pre) in [
        ('Ana', true),
        ('Beto', false),
        ('Carla', true)
      ]) {
        await c.repo.addAttendee(
            eventId: ev,
            firstName: n,
            lastName1: 'Prueba',
            sex: n == 'Beto' ? Sex.male : Sex.female,
            age: 30,
            preregistered: pre);
      }
    });
    await login(t, 'admin', 'secreto1');
    await t.tap(find.text('Retiro'));
    await settle(t);
    await t.tap(find.text('Asistentes').first);
    await settle(t);

    // Los filtros empiezan plegados: las 3 personas se ven.
    expect(find.byKey(const Key('filtro-sexo')), findsNothing);
    for (final n in [1, 2, 3]) {
      expect(find.byKey(Key('asistente-$n')), findsOneWidget);
      expect(t.getRect(find.byKey(Key('asistente-$n'))).bottom, lessThan(890));
    }
    // El botón flotante no tapa el buscador ni «Filtros» (importar/exportar van en el menú ⋮).
    final fab = t.getRect(find.byKey(const Key('asis-registrar')));
    for (final k in ['buscar', 'filtros-toggle', 'menu-csv']) {
      expect(t.getRect(find.byKey(Key(k))).overlaps(fab), isFalse, reason: k);
    }

    // Confirmar desde el menú de la fila.
    expect(find.byKey(const Key('preinscrito-1')), findsOneWidget);
    await tapKey(t, 'asis-menu-1');
    await tapKey(t, 'asis-confirmar');
    expect(find.byKey(const Key('preinscrito-1')), findsNothing);
    // Desconfirmar.
    await tapKey(t, 'asis-menu-1');
    await tapKey(t, 'asis-desconfirmar');
    expect(find.byKey(const Key('preinscrito-1')), findsOneWidget);
    // Editar desde el menú abre la ficha.
    await tapKey(t, 'asis-menu-2');
    await tapKey(t, 'asis-editar');
    expect(find.text('Ficha del asistente'), findsOneWidget);
  });
}
