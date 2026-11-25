import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers.dart';

/// «Registrar» ya no está en la navegación: se entra desde Asistentes (botón o Ctrl+N) y desde el Panel.
void main() {
  Future<Ctx> open(WidgetTester t, Size size) async {
    final c = await pumpApp(t, size);
    await t.runAsync(() => c.repo.createEvent(
        name: 'Retiro',
        startDate: '2026-12-12',
        endDate: '2026-12-14',
        offersTeams: false));
    await login(t, 'admin', 'secreto1');
    await t.tap(find.text('Retiro'));
    await settle(t);
    return c;
  }

  testWidgets('escritorio: sin «Registrar» en el menú; botón en Asistentes',
      (t) async {
    await open(t, const Size(1200, 2400));
    expect(find.text('Registrar'), findsNothing);
    await t.tap(find.text('Asistentes').first);
    await settle(t);
    // Sin asistentes no hay botón flotante: la invitación del estado vacío registra.
    expect(find.byKey(const Key('asis-registrar')), findsNothing);
    await tapKey(t, 'asis-vacio-registrar');
    expect(find.text('Nuevo asistente'), findsOneWidget);
  });

  testWidgets('Ctrl+N abre el registro desde Asistentes', (t) async {
    await open(t, const Size(1200, 2400));
    await t.tap(find.text('Asistentes').first);
    await settle(t);
    await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.keyN);
    await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(t);
    expect(find.text('Nuevo asistente'), findsOneWidget);
  });

  testWidgets('el Panel vacío sigue ofreciendo registrar al primero',
      (t) async {
    await open(t, const Size(1200, 2400));
    await tapKey(t, 'panel-registrar');
    expect(find.text('Nuevo asistente'), findsOneWidget);
  });

  testWidgets('móvil: «Asistentes» está en la barra inferior y registra',
      (t) async {
    await open(t, const Size(400, 900));
    expect(find.text('Registrar'), findsNothing);
    await goRegister(t);
    expect(find.text('Nuevo asistente'), findsOneWidget);
  });
}
