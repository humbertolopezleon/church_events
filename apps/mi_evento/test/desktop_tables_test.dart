import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento/data/repos_b.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'helpers.dart';

Future<Ctx> _open(WidgetTester t, Size size) async {
  final c = await pumpApp(t, size);
  await t.runAsync(() async {
    final ev = await c.repo.createEvent(
        name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
    final ig = await c.repo.createChurch(
        name: 'Bautista', province: 'Matanzas', municipality: 'Cárdenas');
    for (final (n, s, a) in [
      ('Zoe', Sex.female, 30),
      ('Ana', Sex.female, 20)
    ]) {
      await c.repo.addAttendee(
          eventId: ev,
          firstName: n,
          lastName1: 'Leyva',
          sex: s,
          age: a,
          churchId: ig.id);
    }
    await LodgingRepo(c.db).save(
        eventId: ev,
        name: 'Casa Norte',
        kind: 'private_home',
        capacity: 3,
        accepts: LodgingAccepts.any);
  });
  await login(t, 'admin', 'secreto1');
  return c;
}

void main() {
  testWidgets(
      'escritorio: Mis eventos, Asistentes y Hospedajes son tablas ordenables',
      (t) async {
    await _open(t, const Size(1300, 900));
    expect(find.byType(DataTable), findsOneWidget); // Mis eventos
    await t.tap(find.text('Retiro'));
    await settle(t);
    await t.tap(find.text('Asistentes').first);
    await settle(t);
    expect(find.byType(DataTable), findsOneWidget);
    for (final h in [
      'Nº',
      'Nombre',
      'Iglesia',
      'Hospedaje',
      'Equipo',
      'Asistencia'
    ]) {
      expect(find.text(h), findsWidgets, reason: h);
    }
    // ordenar por Nombre: Ana antes que Zoe
    await t.tap(find.text('Nombre'));
    await settle(t);
    final names = t
        .widgetList<Text>(find.textContaining('Leyva'))
        .map((w) => w.data)
        .toList();
    expect(names.first, startsWith('Ana'));
    await t.tap(find.text('Nombre'));
    await settle(t);
    expect(t.widgetList<Text>(find.textContaining('Leyva')).first.data,
        startsWith('Zoe'));
    // abrir la ficha desde la tabla
    await t.tap(find.byKey(const Key('asistente-1')));
    await settle(t);
    expect(find.text('Ficha del asistente'), findsOneWidget);
    await t.pageBack();
    await settle(t);

    await t.tap(find.text('Hospedajes').first);
    await settle(t);
    expect(find.byType(DataTable), findsOneWidget);
    expect(find.byKey(const Key('hosp-Casa Norte')), findsOneWidget);
    expect(find.text('Capacidad'), findsOneWidget);
  });

  testWidgets('móvil estrecho: siguen las tarjetas, sin tabla', (t) async {
    await _open(t, const Size(400, 900));
    expect(find.byType(DataTable), findsNothing);
    await t.tap(find.text('Retiro'));
    await settle(t);
    expect(find.byKey(const Key('evento-Retiro')), findsNothing);
  });
}
