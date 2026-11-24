// QA · Control de comidas por la interfaz con 120 personas (PC y móvil).
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento/data/meal_repo.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import '../helpers.dart';
import 'qa_support.dart';
import 'qa_ui_support.dart';

String _n(WidgetTester t, String key) => t
    .widget<Text>(find
        .descendant(of: find.byKey(Key(key)), matching: find.byType(Text))
        .at(1))
    .data!;

Future<void> _buscar(WidgetTester t, String s) async {
  await t.enterText(find.byKey(const Key('cm-buscar')), s);
  await settle(t);
}

/// Evento de 120 personas y una sesión de almuerzo con [marcadas] personas ya marcadas.
Future<void> Function(QaEvent) _preparar(int marcadas) => (q) async {
      await qaInscribeAll(q, qaPeople(120));
      final meals = MealRepo(q.db);
      await meals.ensureDefaultTypes(q.eventId);
      final tipo = (await meals.types(q.eventId))
          .firstWhere((x) => x.name == 'Almuerzo');
      final s = await meals.createSession(
          q.eventId, tipo.id, 'Almuerzo del sábado',
          operatorName: 'Ruth');
      for (final id in q.ids.take(marcadas)) {
        await meals.mark(s.id, id, operatorName: 'Ruth');
      }
    };

void main() {
  testWidgets(
      'QA-WIN-05 · un preinscrito no se marca pero la búsqueda avisa que confirme primero su asistencia',
      (t) async {
    await qaOpen(t, qaPc, goTo: 'Comidas', prepare: (q) async {
      await _preparar(5)(q);
      final ig = await q.repo.createChurch(name: 'Pre', province: 'Matanzas');
      await q.repo.addAttendee(
          eventId: q.eventId,
          firstName: 'Zacarías',
          lastName1: 'Preinscrito',
          sex: Sex.male,
          age: 40,
          churchId: ig.id,
          preregistered: true);
    });
    if (find.byKey(const Key('cm-buscar')).evaluate().isEmpty) {
      await t.tap(find.textContaining('Almuerzo del sábado').first);
      await settle(t);
    }
    await _buscar(t, 'zacarias');
    expect(find.byKey(const Key('cm-preinscrito')), findsOneWidget);
    expect(
        find.textContaining('confirma primero su asistencia'), findsOneWidget);
    expect(find.textContaining('Nadie con ese nombre'), findsNothing);
  });

  testWidgets(
      'QA-COM-030 · PC con 120 personas y 100 ya marcadas: contadores en vivo, marcar por número con Enter y por nombre sin tildes, «ya pasó», deshacer, pendientes, cierre, exportar y reabrir',
      (t) async {
    final a = await qaOpen(t, qaPc, goTo: 'Comidas', prepare: _preparar(100));
    // Elige la sesión ya creada (la lista de sesiones) si hace falta.
    if (find.byKey(const Key('cm-buscar')).evaluate().isEmpty) {
      await t.tap(find.textContaining('Almuerzo del sábado').first);
      await settle(t);
    }
    expect(_n(t, 'cm-inscritos'), '120');
    expect(_n(t, 'cm-pasaron'), '100');
    expect(_n(t, 'cm-faltan-n'), '20');

    // Por número + Enter (la persona nº 105 aún no ha pasado).
    await _buscar(t, '105');
    expect(find.byKey(const Key('cm-res-105')), findsOneWidget);
    await t.testTextInput.receiveAction(TextInputAction.done);
    await settle(t);
    expect(_n(t, 'cm-pasaron'), '101');

    // Por nombre sin tildes y en mayúsculas (la nº 110).
    final p110 =
        (await qaRows(t, a.q.people)).firstWhere((p) => p.regNumber == 110);
    await _buscar(
        t,
        '${normalizeText(p110.firstName)} ${normalizeText(p110.lastName1)}'
            .toUpperCase());
    await tapKey(t, 'cm-marcar-110');
    expect(_n(t, 'cm-pasaron'), '102');

    // Deshacer lo último (la nº 110).
    await tapKey(t, 'cm-deshacer');
    expect(_n(t, 'cm-pasaron'), '101');

    // «Ya pasó» con la nº 105.
    await _buscar(t, '105');
    await t.tap(find.byKey(const Key('cm-res-105')));
    await settle(t);
    expect(find.byKey(const Key('cm-ya-paso')), findsOneWidget);
    await tapKey(t, 'cm-entendido');
    expect(_n(t, 'cm-pasaron'), '101');

    // Pendientes: 120 − 101 = 19.
    await tapKey(t, 'cm-faltan');
    expect(find.text('Faltan (19)'), findsOneWidget);
    await t.tapAt(const Offset(5, 5)); // cierra la lista tocando fuera
    await settle(t);

    // Cierre, resumen y exportaciones.
    await tapKey(t, 'cm-cerrar');
    await tapKey(t, 'cm-cerrar-ok');
    expect(_n(t, 'res-inscritos'), '120');
    expect(_n(t, 'res-pasaron'), '101');
    expect(_n(t, 'res-no-pasaron'), '19');
    await tapKey(t, 'ex-csv');
    await tapKey(t, 'ex-excel');
    await tapKey(t, 'ex-imagen');
    for (var i = 0; i < 8; i++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 150)));
      await t.pump();
    }
    final nombres = a.saver.saved.keys.toList();
    expect(nombres.length, 3, reason: '$nombres');
    final csv = utf8
        .decode(a.saver.saved[nombres.firstWhere((n) => n.endsWith('.csv'))]!);
    expect(RegExp(';Sí;').allMatches(csv).length, 101);
    expect(RegExp(';No;').allMatches(csv).length, 19);
    // La imagen solo lleva cifras: ningún apellido de los inscritos aparece en sus bytes.
    final png = a.saver.saved[nombres.firstWhere((n) => n.endsWith('.png'))]!;
    expect(png.take(4).toList(), [137, 80, 78, 71]);
    await t.pageBack();
    await settle(t);
    await tapKey(t, 'cm-reabrir');
    expect(find.byKey(const Key('cm-buscar')), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets(
      'QA-COM-031 · móvil con 120 personas: se marca por número y por nombre, los contadores caben y no hay desbordes (letra al 130 %)',
      (t) async {
    final a = await qaOpen(t, qaMovil, goTo: 'Comidas', prepare: _preparar(60));
    t.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    await t.pump();
    if (find.byKey(const Key('cm-buscar')).evaluate().isEmpty) {
      await t.tap(find.textContaining('Almuerzo del sábado').first);
      await settle(t);
    }
    expect(_n(t, 'cm-inscritos'), '120');
    expect(_n(t, 'cm-pasaron'), '60');
    await _buscar(t, '61');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await settle(t);
    expect(_n(t, 'cm-pasaron'), '61');
    expect(_n(t, 'cm-faltan-n'), '59');
    expect(t.takeException(), isNull);
    final meals = await qaRows(t, () => MealRepo(a.ctx.db).types(a.q.eventId));
    expect(meals.length, 3);
  });
}
