// «¿Descartar los cambios?» al salir de un formulario con cambios sin guardar.
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento/data/repos_b.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'helpers.dart';

const _pc = Size(1200, 2400);

Future<Ctx> _open(WidgetTester t) async {
  final c = await pumpApp(t, _pc);
  await t.runAsync(() async {
    final ev = await c.repo.createEvent(
        name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
    await c.repo.addAttendee(
        eventId: ev,
        firstName: 'Ana',
        lastName1: 'Pérez',
        sex: Sex.female,
        age: 30);
    await LodgingRepo(c.db).save(
        eventId: ev,
        name: 'Casa Norte',
        kind: 'shelter',
        capacity: 3,
        accepts: LodgingAccepts.any);
  });
  await login(t, 'admin', 'secreto1');
  await t.tap(find.text('Retiro'));
  await settle(t);
  return c;
}

Future<int> _lodgingCount(WidgetTester t, Ctx c) async => (await t
    .runAsync(() async => (await c.db.select(c.db.lodgings).get()).length))!;

void main() {
  group('hospedaje', () {
    testWidgets('sin cambios se cierra sin preguntar (X y Cancelar)',
        (t) async {
      final c = await _open(t);
      await t.tap(find.text('Hospedajes').first);
      await settle(t);
      await tapKey(t, 'hosp-nuevo');
      await tapKey(t, 'lf-cerrar');
      expect(find.byKey(const Key('lf-nombre')), findsNothing);
      expect(find.byKey(const Key('descartar-dialogo')), findsNothing);
      await tapKey(t, 'hosp-nuevo');
      await tapKey(t, 'lf-cancelar');
      expect(find.byKey(const Key('lf-nombre')), findsNothing);
      expect(await _lodgingCount(t, c), 1);
    });

    testWidgets(
        'con cambios pregunta: «Seguir editando» conserva lo escrito y «Descartar» sale sin guardar',
        (t) async {
      final c = await _open(t);
      await t.tap(find.text('Hospedajes').first);
      await settle(t);
      await tapKey(t, 'hosp-nuevo');
      await enter(t, 'lf-nombre', 'Casa Sur');
      await tapKey(t, 'lf-cancelar');
      expect(find.byKey(const Key('descartar-dialogo')), findsOneWidget);
      await tapKey(t, 'descartar-seguir');
      expect(find.byKey(const Key('lf-nombre')), findsOneWidget);
      expect(find.text('Casa Sur'), findsOneWidget);
      await tapKey(t, 'lf-cerrar');
      await tapKey(t, 'descartar-ok');
      expect(find.byKey(const Key('lf-nombre')), findsNothing);
      expect(await _lodgingCount(t, c), 1, reason: 'no se guardó nada');
    });

    testWidgets('Esc con cambios también pregunta; Esc sin cambios no',
        (t) async {
      await _open(t);
      await t.tap(find.text('Hospedajes').first);
      await settle(t);
      await tapKey(t, 'hosp-nuevo');
      await enter(t, 'lf-nombre', 'Casa Sur');
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await settle(t);
      expect(find.byKey(const Key('descartar-dialogo')), findsOneWidget);
      await tapKey(t, 'descartar-ok');
      expect(find.byKey(const Key('lf-nombre')), findsNothing);
      await tapKey(t, 'hosp-nuevo');
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await settle(t);
      expect(find.byKey(const Key('lf-nombre')), findsNothing);
      expect(find.byKey(const Key('descartar-dialogo')), findsNothing);
    });

    testWidgets('guardar no pregunta; un cambio devuelto a su valor tampoco',
        (t) async {
      final c = await _open(t);
      await t.tap(find.text('Hospedajes').first);
      await settle(t);
      await tapKey(t, 'hosp-nuevo');
      await enter(t, 'lf-nombre', 'Casa Sur');
      await tapKey(t, 'lf-guardar');
      expect(find.byKey(const Key('descartar-dialogo')), findsNothing);
      expect(find.byKey(const Key('lf-nombre')), findsNothing);
      expect(await _lodgingCount(t, c), 2);
      // Nuevo, escribir y borrar: vuelve a estar igual que al abrir.
      await tapKey(t, 'hosp-nuevo');
      await enter(t, 'lf-nombre', 'x');
      await enter(t, 'lf-nombre', '');
      await tapKey(t, 'lf-cerrar');
      expect(find.byKey(const Key('descartar-dialogo')), findsNothing);
      expect(find.byKey(const Key('lf-nombre')), findsNothing);
    });
  });

  group('asistente', () {
    testWidgets(
        'nuevo: sin cambios sale directo; con cambios pregunta; guardar no pregunta',
        (t) async {
      final c = await _open(t);
      await t.tap(find.text('Asistentes').first);
      await settle(t);
      await tapKey(t, 'asis-registrar');
      expect(find.byKey(const Key('f-nombre')), findsOneWidget);
      await pageBack(t);
      expect(find.byKey(const Key('f-nombre')), findsNothing);
      expect(find.byKey(const Key('descartar-dialogo')), findsNothing);

      await tapKey(t, 'asis-registrar');
      await enter(t, 'f-nombre', 'Beto');
      await pageBack(t);
      expect(find.byKey(const Key('descartar-dialogo')), findsOneWidget);
      await tapKey(t, 'descartar-seguir');
      expect(find.byKey(const Key('f-nombre')), findsOneWidget);
      await pageBack(t);
      await tapKey(t, 'descartar-ok');
      expect(find.byKey(const Key('f-nombre')), findsNothing);
      final n = await t.runAsync(
          () async => (await c.db.select(c.db.attendees).get()).length);
      expect(n, 1, reason: 'Beto no se guardó');
    });

    testWidgets('editar: tocar un campo y salir pregunta; sin tocar, no',
        (t) async {
      await _open(t);
      await t.tap(find.text('Asistentes').first);
      await settle(t);
      await t.tap(find.text('Ana Pérez').first);
      await settle(t);
      expect(find.byKey(const Key('f-nombre')), findsOneWidget);
      await pageBack(t);
      expect(find.byKey(const Key('f-nombre')), findsNothing);
      expect(find.byKey(const Key('descartar-dialogo')), findsNothing);

      await t.tap(find.text('Ana Pérez').first);
      await settle(t);
      await enter(t, 'f-telefono', '555');
      await pageBack(t);
      expect(find.byKey(const Key('descartar-dialogo')), findsOneWidget);
      await tapKey(t, 'descartar-ok');
      expect(find.byKey(const Key('f-nombre')), findsNothing);
    });
  });
}
