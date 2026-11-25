// QA · Pantallas de Hospedajes y Equipos con 120 personas (interfaz real, ancho de PC).
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import '../helpers.dart';
import 'qa_support.dart';
import 'qa_ui_support.dart';

void main() {
  testWidgets(
      'QA-HOS-050 · «Sugerir hospedaje» con 120 inscritos: la propuesta cubre a todos, se acepta y nadie queda sin lugar ni sobre la capacidad',
      (t) async {
    final a = await qaOpen(t, qaPc, goTo: 'Hospedajes', prepare: (q) async {
      await qaInscribeAll(q, qaPeople(120));
      await qaLodgings(q);
    });
    await tapKey(t, 'hosp-sugerir');
    await tapKey(t, 'sg-buscar');
    expect(find.text('PROPUESTA 1'), findsOneWidget);
    // Todavía no se guardó nada.
    final antes = await qaRows(t, a.q.people);
    expect(antes.where((p) => p.lodgingId != null), isEmpty);
    await tapKey(t, 'sg-aceptar-0');
    expect(find.byKey(const Key('sg-fin')), findsOneWidget);
    final despues = await qaRows(t, a.q.people);
    expect(
        despues.where((p) => p.needsLodging && p.lodgingId == null), isEmpty);
    final lods = await qaRows(t, a.q.lodgingViews);
    for (final l in lods) {
      expect(l.occupied, lessThanOrEqualTo(l.row.capacity), reason: l.row.name);
    }
    expect(t.takeException(), isNull);
  });

  testWidgets(
      'QA-HOS-051 · con pocas plazas la pantalla avisa cuántas faltan y «Asignar a quienes caben» deja al resto pendiente',
      (t) async {
    final a = await qaOpen(t, qaPc, goTo: 'Hospedajes', prepare: (q) async {
      await qaInscribeAll(q, qaPeople(120));
      await qaLodgings(q, scale: 0.4);
    });
    await tapKey(t, 'hosp-sugerir');
    await tapKey(t, 'sg-buscar');
    expect(find.textContaining('Faltan'), findsWidgets);
    await tapKey(t, 'sg-aceptar-0');
    await tapKey(t, 'sg-confirmar-parcial');
    final despues = await qaRows(t, a.q.people);
    final sin =
        despues.where((p) => p.needsLodging && p.lodgingId == null).length;
    expect(sin, greaterThan(20));
    final lods = await qaRows(t, a.q.lodgingViews);
    expect(lods.every((l) => l.occupied <= l.row.capacity), isTrue);
    expect(t.takeException(), isNull);
  });

  testWidgets(
      'QA-EQP-050 · «Generar equipos» con 120 personas sin equipo: propuesta equilibrada, Descartar no cambia nada, Aceptar asigna a todos y «Deshacer» lo revierte',
      (t) async {
    final a =
        await qaOpen(t, qaPc, goTo: 'Equipos', teams: 6, prepare: (q) async {
      await qaInscribeAll(q, qaPeople(120));
      await q.teams.setTeam((await q.people()).map((p) => p.id), null);
    });
    await tapKey(t, 'eq-generar');
    expect(find.textContaining('120 personas por repartir'), findsOneWidget);
    await tapKey(t, 'gen-calcular');
    expect(find.text('PROPUESTA'), findsOneWidget);
    await tapKey(t, 'gen-descartar');
    expect(find.byKey(const Key('gen-descartada')), findsOneWidget);
    expect(
        (await qaRows(t, a.q.people)).where((p) => p.teamId != null), isEmpty);
    // Se vuelve a calcular y se acepta.
    await pageBack(t);
    await settle(t);
    await tapKey(t, 'eq-generar');
    await tapKey(t, 'gen-calcular');
    expect(find.byKey(const Key('gen-balanceado')), findsOneWidget);
    await tapKey(t, 'gen-aceptar');
    final s = await qaRows(t, () => qaTeamStats(a.q));
    expect(s.fold<int>(0, (x, e) => x + e.size), 120);
    expect(evaluateBalance(s), isEmpty);
    await t.tap(find.text('Deshacer'));
    await settle(t);
    expect(
        (await qaRows(t, a.q.people)).where((p) => p.teamId != null), isEmpty);
    expect(t.takeException(), isNull);
  });
}
