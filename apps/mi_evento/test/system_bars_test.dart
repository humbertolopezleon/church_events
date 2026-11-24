import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'helpers.dart';

/// Un móvil con la barra de navegación del sistema dibujada encima de la app (como en Android
/// moderno): ningún botón principal debe quedar debajo de ella.
const _phone = Size(400, 800);
const _bar = 60.0; // alto de la barra del sistema

void _withSystemBar(WidgetTester t) {
  t.view.padding = const FakeViewPadding(bottom: _bar);
  t.view.viewPadding = const FakeViewPadding(bottom: _bar);
}

void _expectAboveBar(WidgetTester t, String key) {
  final bottom = t.getBottomLeft(find.byKey(Key(key))).dy;
  expect(bottom, lessThanOrEqualTo(_phone.height - _bar + 0.5),
      reason:
          '«$key» queda tapado por la barra del sistema (borde inferior en $bottom)');
}

void main() {
  testWidgets(
      'ficha del asistente (pantalla que se abre encima): «Guardar cambios» se alcanza sobre la barra del sistema',
      (t) async {
    final c = await pumpApp(t, _phone);
    await t.runAsync(() async {
      final ev = await c.repo.createEvent(
          name: 'Retiro',
          startDate: '2026-12-12',
          endDate: '2026-12-14',
          offersLodging: false,
          offersTeams: false);
      await c.repo.addAttendee(
          eventId: ev,
          firstName: 'Ana',
          lastName1: 'Pérez',
          sex: Sex.female,
          age: 30);
    });
    await login(t, 'admin', 'secreto1');
    await t.tap(find.text('Retiro'));
    await settle(t);
    _withSystemBar(t);
    await t.pump();
    await t.tap(find.text('Asistentes'));
    await settle(t);
    await tapKey(t, 'asistente-1');
    // Se baja hasta el final de la ficha: ahí el botón quedaba bajo la barra.
    await t.drag(
        find.byType(SingleChildScrollView).first, const Offset(0, -5000));
    await t.pump();
    _expectAboveBar(t, 'f-guardar');
  });

  testWidgets(
      'configuración del evento: «Terminar» queda sobre la barra del sistema',
      (t) async {
    await pumpApp(t, _phone);
    await login(t, 'admin', 'secreto1');
    await t.tap(find.text('Crear evento'));
    await settle(t);
    await t.enterText(find.byKey(const Key('ev-nombre')), 'Congreso');
    await t.tap(find.byKey(const Key('ev-crear')));
    await settle(t);
    _withSystemBar(t);
    await t.pump();
    _expectAboveBar(t, 'cfg-terminar');
  });

  testWidgets('lista de eventos: el botón «Crear evento» no queda tapado',
      (t) async {
    await pumpApp(t, _phone);
    await login(t, 'admin', 'secreto1');
    _withSystemBar(t);
    await t.pump();
    _expectAboveBar(t, 'ev-crear-fab');
  });

  testWidgets('con el teclado abierto no se suma otra franja vacía', (t) async {
    await pumpApp(t, _phone);
    // Teclado de 300 de alto que ya cubre la barra del sistema (60).
    t.view.padding = const FakeViewPadding();
    t.view.viewPadding = const FakeViewPadding(bottom: _bar);
    t.view.viewInsets = const FakeViewPadding(bottom: 300);
    await t.pump();
    final box = t.getRect(find.byType(Scaffold).first);
    expect(box.bottom, closeTo(800, 0.5));
    addTearDown(t.view.resetViewInsets);
  });
}
