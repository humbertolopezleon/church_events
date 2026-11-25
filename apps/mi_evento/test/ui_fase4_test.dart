import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers.dart';

/// Fase 4: «Nuevo hospedaje» a pantalla completa.
void main() {
  testWidgets(
      'nuevo hospedaje: pantalla completa, orden de campos, −/+ con mínimo 1, anfitrión solo en casa particular',
      (t) async {
    final c = await pumpApp(t, const Size(390, 844));
    await t.runAsync(() => c.repo.createEvent(
        name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14'));
    await login(t, 'admin', 'secreto1');
    await t.tap(find.text('Retiro'));
    await settle(t);
    await t.tap(find.text('Más'));
    await settle(t);
    await t.tap(find.text('Hospedajes').first);
    await settle(t);
    await tapKey(t, 'hosp-nuevo');
    // Pantalla completa (no un diálogo) con X y barra inferior.
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byKey(const Key('lf-cerrar')), findsOneWidget);
    expect(find.text('Guardar hospedaje'), findsOneWidget);
    expect(find.byKey(const Key('lf-cancelar')), findsOneWidget);
    // Tipo primero, y el anfitrión solo con «Casa particular».
    expect(
        t.getTopLeft(find.text('Tipo', findRichText: true)).dy <
            t.getTopLeft(find.text('Nombre', findRichText: true)).dy,
        isTrue);
    expect(find.byKey(const Key('lf-anfitrion')), findsNothing);
    await t.tap(find.text('Casa particular'));
    await t.pump();
    expect(find.byKey(const Key('lf-anfitrion')), findsOneWidget);
    expect(
        find.textContaining('Cómo llegar', findRichText: true), findsOneWidget);
    // Capacidad: «+» arranca en 1, «−» no baja de 1.
    await tapKey(t, 'lf-mas');
    expect(
        t
            .widget<TextField>(find.byKey(const Key('lf-capacidad')))
            .controller!
            .text,
        '1');
    await tapKey(t, 'lf-mas');
    expect(
        t
            .widget<TextField>(find.byKey(const Key('lf-capacidad')))
            .controller!
            .text,
        '2');
    await tapKey(t, 'lf-menos');
    await tapKey(t, 'lf-menos');
    expect(
        t
            .widget<TextField>(find.byKey(const Key('lf-capacidad')))
            .controller!
            .text,
        '1');
    // «Acepta» en cuadrícula, con áreas de 56 dp.
    expect(t.getSize(find.byKey(const Key('lf-acepta-women'))).height, 56);
    await tapKey(t, 'lf-acepta-women');
    // Errores junto al campo.
    await tapKey(t, 'lf-guardar');
    await settle(t);
    expect(find.text('Falta el nombre del hospedaje.'), findsOneWidget);
    await enter(t, 'lf-nombre', 'Casa de Ana');
    await enter(t, 'lf-cerca', 'Frente al parque');
    await tapKey(t, 'lf-guardar');
    // Vuelve a la lista con la tarjeta nueva y «Solo mujeres».
    expect(find.byKey(const Key('hosp-Casa de Ana')), findsOneWidget);
    expect(find.textContaining('Acepta: Solo mujeres'), findsOneWidget);
    expect(find.byKey(const Key('hosp-tipo-Casa de Ana')), findsOneWidget);
    expect(find.text('1 plaza libre'), findsOneWidget);
  });

  testWidgets('cerrar con la X o Cancelar no guarda nada', (t) async {
    final c = await pumpApp(t, const Size(390, 844));
    await t.runAsync(() => c.repo.createEvent(
        name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14'));
    await login(t, 'admin', 'secreto1');
    await t.tap(find.text('Retiro'));
    await settle(t);
    await t.tap(find.text('Más'));
    await settle(t);
    await t.tap(find.text('Hospedajes').first);
    await settle(t);
    await tapKey(t, 'hosp-nuevo');
    await enter(t, 'lf-nombre', 'Borrador');
    await tapKey(t, 'lf-cerrar');
    expect(find.byKey(const Key('hosp-Borrador')), findsNothing);
    expect(find.textContaining('Todavía no hay hospedajes'), findsOneWidget);
  });
}
