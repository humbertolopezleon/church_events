// QA-BUG-003 · matrimonio inscrito en dos fichas: si el esposo ya está en un hospedaje donde no
// pueden estar juntos, al vincular a la esposa se avisa y se PROPONE moverlos a los dos a un
// hospedaje de matrimonios (propuesta con borde discontinuo: se acepta, se cambia o se descarta).
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/repos_b.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'helpers.dart';

const _pc = Size(1200, 2600);

class _Datos {
  _Datos(this.c, this.husband, this.shelter, this.house);
  final Ctx c;
  final AttendeeRow husband;
  final LodgingRow shelter, house;
}

/// Esposo ya inscrito y alojado en un albergue de hombres; hay una casa de matrimonios.
/// Se abre el formulario de una persona nueva (la esposa) con el hospedaje pedido.
Future<_Datos> _open(WidgetTester t, {int houseCapacity = 4}) async {
  final c = await pumpApp(t, _pc);
  late String ev;
  late AttendeeRow husband;
  late LodgingRow shelter, house;
  await t.runAsync(() async {
    ev = await c.repo.createEvent(
        name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
    final ig = await c.repo.createChurch(
        name: 'Bautista Ebenezer',
        province: 'Matanzas',
        municipality: 'Cárdenas');
    husband = await c.repo.addAttendee(
        eventId: ev,
        firstName: 'Humberto',
        lastName1: 'López',
        sex: Sex.male,
        age: 35,
        churchId: ig.id,
        needsLodging: true);
  });
  await t.runAsync(() async {
    final lr = LodgingRepo(c.db);
    shelter = await lr.save(
        eventId: ev,
        name: 'Albergue de hombres',
        kind: 'shelter',
        capacity: 10,
        accepts: LodgingAccepts.men);
    house = await lr.save(
        eventId: ev,
        name: 'Casa de matrimonios',
        kind: 'private_home',
        capacity: houseCapacity,
        accepts: LodgingAccepts.couples);
  });
  await t.runAsync(() => LodgingRepo(c.db).assign(shelter.id, [husband.id]));
  await login(t, 'admin', 'secreto1');
  await t.tap(find.text('Retiro'));
  await settle(t);
  await goRegister(t);
  await settle(t);
  await enter(t, 'f-nombre', 'Jany');
  await enter(t, 'f-apellido1', 'Gil');
  await pickSex(t, woman: true);
  await enter(t, 'f-edad', '33');
  await enter(t, 'f-iglesia', 'Bautista');
  await tapKey(t, 'iglesia-bautista ebenezer');
  await tapKey(t, 'f-hospedaje');
  return _Datos(c, husband, shelter, house);
}

Future<void> _vincular(WidgetTester t) async {
  await tapKey(t, 'social-vincular');
  await t.enterText(find.byKey(const Key('pp-buscar')), 'humberto');
  await settle(t);
  await tapKey(t, 'pp-1');
}

Future<Map<String, AttendeeRow>> _rows(WidgetTester t, Ctx c) async => {
      for (final r
          in (await t.runAsync(() => c.db.select(c.db.attendees).get()))!)
        r.firstName: r
    };

void main() {
  testWidgets(
      'al vincular a la esposa: avisa y propone mover a los dos; al aceptar y guardar quedan juntos',
      (t) async {
    final d = await _open(t);
    expect(find.byKey(const Key('f-hosp-pareja')), findsNothing);
    await _vincular(t);
    expect(find.byKey(const Key('f-hosp-pareja')), findsOneWidget);
    expect(find.textContaining('ya está hospedado/a en «Albergue de hombres»'),
        findsOneWidget);
    expect(
        find.textContaining('mover a los dos cónyuges a «Casa de matrimonios»'),
        findsOneWidget);
    // Es una PROPUESTA: todavía nadie se ha movido.
    expect((await _rows(t, d.c))['Humberto']!.lodgingId, d.shelter.id);

    await tapKey(t, 'f-hosp-pareja-mover');
    expect(find.byKey(const Key('f-hosp-pareja-ok')), findsOneWidget);
    expect((await _rows(t, d.c))['Humberto']!.lodgingId, d.shelter.id);

    await tapKey(t, 'f-guardar');
    final r = await _rows(t, d.c);
    expect(r['Jany']!.lodgingId, d.house.id);
    expect(r['Humberto']!.lodgingId, d.house.id);
    expect(r['Jany']!.coupleId, r['Humberto']!.coupleId);
    final occ =
        await t.runAsync(() => LodgingRepo(d.c.db).occupants(d.shelter.id));
    expect(occ, isEmpty); // la plaza del albergue quedó libre
  });

  testWidgets('«Dejarlos como están» descarta la propuesta y no cambia a nadie',
      (t) async {
    final d = await _open(t);
    await _vincular(t);
    await tapKey(t, 'f-hosp-pareja-dejar');
    expect(find.byKey(const Key('f-hosp-pareja')), findsNothing);
    await tapKey(t, 'f-guardar');
    final r = await _rows(t, d.c);
    expect(r['Humberto']!.lodgingId, d.shelter.id);
    expect(r['Jany']!.lodgingId, isNull);
    expect(r['Jany']!.coupleId, isNotNull);
  });

  testWidgets(
      'si tras aceptar se elige otro hospedaje a mano, el esposo NO se mueve',
      (t) async {
    final d = await _open(t);
    await _vincular(t);
    await tapKey(t, 'f-hosp-pareja-mover');
    await tapKey(t, 'f-hosp-sel');
    await t.tap(find.textContaining('Albergue de hombres').last);
    await settle(t);
    await tapKey(t, 'f-guardar');
    final r = await _rows(t, d.c);
    expect(r['Humberto']!.lodgingId, d.shelter.id);
  });

  testWidgets(
      'sin una casa de matrimonios con 2 plazas libres no hay propuesta de mover (solo los avisos de siempre)',
      (t) async {
    final d = await _open(t, houseCapacity: 1);
    await _vincular(t);
    expect(find.byKey(const Key('f-hosp-pareja')), findsNothing);
    await tapKey(t, 'f-guardar');
    expect((await _rows(t, d.c))['Humberto']!.lodgingId, d.shelter.id);
  });

  testWidgets(
      'elegir a mano un hospedaje de matrimonios: el cónyuge se mueve con ella/él y se dice claro',
      (t) async {
    final d = await _open(t);
    await _vincular(t);
    await tapKey(t, 'f-hosp-sel');
    await t.tap(find.textContaining('Casa de matrimonios').last);
    await settle(t);
    expect(find.byKey(const Key('f-hosp-pareja-ok')), findsOneWidget);
    expect(find.textContaining('Humberto también pasará'), findsOneWidget);
    expect(find.byKey(const Key('f-hosp-aviso')), findsNothing);
    await tapKey(t, 'f-guardar');
    final r = await _rows(t, d.c);
    expect(r['Jany']!.lodgingId, d.house.id);
    expect(r['Humberto']!.lodgingId, d.house.id);
  });

  testWidgets(
      'elegir el albergue de hombres para la esposa: sale deshabilitado (no compatible), no hay propuesta ni movimiento',
      (t) async {
    final d = await _open(t);
    await _vincular(t);
    await tapKey(t, 'f-hosp-sel');
    expect(find.textContaining('no compatible'), findsWidgets);
    await t
        .tap(find.textContaining('Albergue de hombres').last); // deshabilitado
    await settle(t);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(t);
    expect(find.byKey(const Key('f-hosp-pareja-ok')), findsNothing);
    expect((await _rows(t, d.c))['Humberto']!.lodgingId, d.shelter.id);
    await tapKey(t, 'f-guardar');
    expect((await _rows(t, d.c))['Jany']!.lodgingId, isNull);
  });
}
