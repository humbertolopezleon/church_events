import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers.dart';
import 'qa/qa_support.dart';

/// Fase 5: con la letra del sistema al 130 % nada se desborda en las pantallas principales,
/// y los botones que solo tienen icono llevan etiqueta.
void main() {
  testWidgets(
      'letra al 130 %: Asistentes, Hospedajes, Iglesias, Equipos y el formulario no se desbordan',
      (t) async {
    t.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    final c = await pumpApp(t, const Size(390, 844), defaultAdmin: true);
    await t.runAsync(() async {
      final q = await qaEvent(c.db, teams: 3);
      await qaInscribeAll(q, qaPeople(12, couples: 1));
      await qaLodgings(q, scale: 0.5);
    });
    await t.enterText(find.byKey(const Key('login-usuario')), 'admin');
    await t.enterText(find.byKey(const Key('login-clave')), 'admin');
    await t.ensureVisible(find.byKey(const Key('login-entrar')));
    await t.tap(find.byKey(const Key('login-entrar')));
    await settle(t);
    await t.tap(find.textContaining('Congreso').first);
    await settle(t);

    Future<void> go(String label) async {
      if (find.text(label).evaluate().isEmpty) {
        await t.tap(find.text('Más').first);
        await settle(t);
      }
      await t.tap(find.text(label).first);
      await settle(t);
      expect(t.takeException(), isNull, reason: 'desborde en «$label»');
    }

    await go('Asistentes');
    // El botón «Filtros» baja bajo el buscador con letra grande.
    expect(
        t.getTopLeft(find.byKey(const Key('filtros-toggle'))).dy >
            t.getBottomLeft(find.byKey(const Key('buscar'))).dy,
        isTrue);
    await go('Hospedajes');
    await tapKey(t, 'hosp-nuevo');
    expect(t.takeException(), isNull, reason: 'desborde en Nuevo hospedaje');
    await tapKey(t, 'lf-cerrar');
    await go('Equipos');
    await go('Iglesias');
    // Todo botón de solo icono tiene tooltip (etiqueta de accesibilidad).
    final sinEtiqueta = t.widgetList<IconButton>(find.byType(IconButton)).where(
        (b) =>
            b.tooltip == null &&
            b.icon is Icon &&
            (b.icon as Icon).semanticLabel == null);
    expect(sinEtiqueta, isEmpty);
    expect(find.byTooltip('Más opciones: importar y exportar CSV'),
        findsOneWidget);
  });
}
