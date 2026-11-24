import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/repos_b.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'helpers.dart';

const _pc = Size(1200, 2600);

/// Evento ya configurado con 2 equipos y un hospedaje de matrimonios. Datos ANTES de abrir la UI.
Future<Ctx> _open(WidgetTester t,
    {bool withLodging = true, bool janyExists = false}) async {
  final c = await pumpApp(t, _pc);
  late String ev;
  await t.runAsync(() async {
    ev = await c.repo.createEvent(
        name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
    final ig = await c.repo.createChurch(
        name: 'Bautista Ebenezer',
        province: 'Matanzas',
        municipality: 'Cárdenas');
    if (janyExists) {
      await c.repo.addAttendee(
          eventId: ev,
          firstName: 'Jany',
          lastName1: 'Gil',
          sex: Sex.female,
          age: 33,
          churchId: ig.id);
    }
  });
  await t.runAsync(() => TeamRepo(c.db).createMany(ev, 2));
  if (withLodging) {
    await t.runAsync(() => LodgingRepo(c.db).save(
        eventId: ev,
        name: 'Casa de Teresa',
        kind: 'private_home',
        capacity: 4,
        accepts: LodgingAccepts.couples));
  }
  await login(t, 'admin', 'secreto1');
  await t.tap(find.text('Retiro'));
  await settle(t);
  await goRegister(t);
  await settle(t);
  return c;
}

Future<void> _fillHusband(WidgetTester t, {bool lodging = true}) async {
  await enter(t, 'f-nombre', 'Humberto');
  await enter(t, 'f-apellido1', 'López');
  await pickSex(t, woman: false);
  await enter(t, 'f-edad', '35');
  await enter(t, 'f-iglesia', 'Bautista');
  await tapKey(t, 'iglesia-bautista ebenezer');
  if (lodging) await tapKey(t, 'f-hospedaje');
}

Future<void> _newSpouse(WidgetTester t,
    {String name = 'Jany', String last = 'Gil', String age = '33'}) async {
  await tapKey(t, 'social-conyuge-nuevo-btn');
  await enter(t, 'ns-nombre', name);
  await enter(t, 'ns-apellido1', last);
  await enter(t, 'ns-edad', age);
  await tapKey(t, 'ns-aceptar');
}

Future<List<AttendeeRow>> _all(WidgetTester t, Ctx c) async =>
    (await t.runAsync(() => c.db.select(c.db.attendees).get()))!;

void main() {
  testWidgets(
      'inscribir al cónyuge desde la ficha: ambos quedan inscritos, en el mismo equipo y con el mismo hospedaje',
      (t) async {
    final c = await _open(t);
    await _fillHusband(t);
    await _newSpouse(t);
    expect(find.byKey(const Key('social-conyuge-nuevo')), findsOneWidget);
    // Una propuesta para los DOS, con el hospedaje de matrimonios (2 plazas).
    expect(find.byKey(const Key('f-hosp-sugerencia')), findsOneWidget);
    expect(find.textContaining('Para los dos cónyuges (2 plazas)'),
        findsOneWidget);
    expect(await _all(t, c), isEmpty); // todavía no se guardó nada

    await tapKey(t, 'f-hosp-usar');
    await tapKey(t, 'f-guardar');
    expect(find.byKey(const Key('exito-conyuge')), findsOneWidget);
    expect(find.textContaining('Jany Gil'), findsWidgets);

    final rows = await _all(t, c);
    expect(rows, hasLength(2));
    final h = rows.firstWhere((r) => r.firstName == 'Humberto');
    final j = rows.firstWhere((r) => r.firstName == 'Jany');
    expect(j.sex, 'F'); // el contrario, sin poder cambiarlo
    expect(j.age, 33);
    expect(j.coupleId, isNotNull);
    expect(j.coupleId, h.coupleId);
    expect(j.churchId, h.churchId); // misma iglesia
    expect(j.province, h.province);
    expect(j.municipality, h.municipality);
    expect(h.lodgingId, isNotNull);
    expect(j.lodgingId, h.lodgingId); // mismo hospedaje
    expect(j.needsLodging, isTrue);
    expect(h.teamId, isNotNull);
    expect(j.teamId, h.teamId); // mismo equipo
    expect(j.regNumber, h.regNumber + 1);
  });

  testWidgets('el sexo del cónyuge es el contrario y no se puede cambiar',
      (t) async {
    await _open(t);
    await _fillHusband(t, lodging: false);
    await tapKey(t, 'social-conyuge-nuevo-btn');
    expect(find.text('Sexo: Mujer'), findsOneWidget);
    expect(find.byKey(const Key('ns-sexo')), findsOneWidget);
    // No hay botones ni menús para cambiarlo.
    expect(
        find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(DropdownButton<Sex>)),
        findsNothing);
  });

  testWidgets('para una mujer, el cónyuge nuevo es hombre', (t) async {
    final c = await _open(t);
    await enter(t, 'f-nombre', 'Jany');
    await enter(t, 'f-apellido1', 'Gil');
    await pickSex(t, woman: true);
    await enter(t, 'f-edad', '33');
    await enter(t, 'f-iglesia', 'Bautista');
    await tapKey(t, 'iglesia-bautista ebenezer');
    await _newSpouse(t, name: 'Humberto', last: 'López', age: '35');
    await tapKey(t, 'f-guardar');
    final rows = await _all(t, c);
    expect(rows.firstWhere((r) => r.firstName == 'Humberto').sex, 'M');
  });

  testWidgets(
      'sin elegir el sexo, se explica por qué no se puede inscribir al cónyuge',
      (t) async {
    await _open(t);
    expect(find.byKey(const Key('social-conyuge-sinsexo')), findsOneWidget);
    expect(
        t
            .widget<ButtonStyleButton>(
                find.byKey(const Key('social-conyuge-nuevo-btn')))
            .onPressed,
        isNull);
  });

  testWidgets('cancelar el formulario del cónyuge no crea a nadie', (t) async {
    final c = await _open(t);
    await _fillHusband(t, lodging: false);
    await tapKey(t, 'social-conyuge-nuevo-btn');
    await enter(t, 'ns-nombre', 'Jany');
    await t.tap(find.text('Cancelar'));
    await settle(t);
    expect(find.byKey(const Key('social-conyuge-nuevo')), findsNothing);
    await tapKey(t, 'f-guardar');
    expect(await _all(t, c), hasLength(1));
  });

  testWidgets(
      '«Quitar» al cónyuge nuevo antes de guardar: solo se inscribe la primera persona',
      (t) async {
    final c = await _open(t);
    await _fillHusband(t, lodging: false);
    await _newSpouse(t);
    await tapKey(t, 'social-quitar-conyuge-nuevo');
    await tapKey(t, 'f-guardar');
    final rows = await _all(t, c);
    expect(rows, hasLength(1));
    expect(rows.single.coupleId, isNull);
  });

  testWidgets('el formulario corto pide nombre, apellido y edad válidos',
      (t) async {
    await _open(t);
    await _fillHusband(t, lodging: false);
    await tapKey(t, 'social-conyuge-nuevo-btn');
    await tapKey(t, 'ns-aceptar');
    expect(
        find.textContaining('Falta el nombre de su cónyuge'), findsOneWidget);
    await enter(t, 'ns-nombre', 'Jany');
    await tapKey(t, 'ns-aceptar');
    expect(find.textContaining('Falta el primer apellido'), findsOneWidget);
    await enter(t, 'ns-apellido1', 'Gil');
    await tapKey(t, 'ns-aceptar');
    expect(find.textContaining('Falta la edad'), findsOneWidget);
    await enter(t, 'ns-edad', '150');
    await tapKey(t, 'ns-aceptar');
    expect(find.textContaining('entre 1 y 110'), findsOneWidget);
  });

  testWidgets(
      'si el cónyuge ya estaba inscrito, avisa y permite vincular a esa persona (sin duplicar)',
      (t) async {
    final c = await _open(t, janyExists: true); // Jany ya está inscrita
    await _fillHusband(t, lodging: false);
    await _newSpouse(t);
    expect(find.byKey(const Key('ns-duplicado')), findsOneWidget);
    await tapKey(t, 'ns-es-esa');
    expect(find.byKey(const Key('social-conyuge')), findsOneWidget);
    await tapKey(t, 'f-guardar');
    final rows = await _all(t, c);
    expect(rows, hasLength(2)); // no se creó otra Jany
    expect(rows.every((r) => r.coupleId != null), isTrue);
  });

  testWidgets(
      'dejar el hospedaje para después: ninguno de los dos queda asignado',
      (t) async {
    final c = await _open(t);
    await _fillHusband(t);
    await _newSpouse(t);
    await tapKey(t, 'f-hosp-dejar');
    await tapKey(t, 'f-guardar');
    final rows = await _all(t, c);
    expect(rows, hasLength(2));
    expect(rows.every((r) => r.lodgingId == null), isTrue);
    expect(rows.every((r) => r.needsLodging), isTrue);
    expect(rows.every((r) => r.teamId != null),
        isTrue); // el equipo sí es automático
  });

  testWidgets(
      'si no hay hospedaje de matrimonios con 2 plazas, se explica y no se asigna a nadie',
      (t) async {
    final c = await _open(t, withLodging: false);
    await _fillHusband(t, lodging: false);
    await _newSpouse(t);
    await tapKey(t, 'f-guardar');
    expect((await _all(t, c)), hasLength(2));
  });

  testWidgets(
      'matrimonio nuevo + hospedaje elegido a mano en uno incompatible: avisa por los dos y deja guardar',
      (t) async {
    final c = await pumpApp(t, _pc);
    late String ev;
    await t.runAsync(() async {
      ev = await c.repo.createEvent(
          name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
      await c.repo.createChurch(
          name: 'Bautista Ebenezer',
          province: 'Matanzas',
          municipality: 'Cárdenas');
    });
    await t.runAsync(() => LodgingRepo(c.db).save(
        eventId: ev,
        name: 'Casa solo hombres',
        kind: 'private_home',
        capacity: 4,
        accepts: LodgingAccepts.men));
    await login(t, 'admin', 'secreto1');
    await t.tap(find.text('Retiro'));
    await settle(t);
    await goRegister(t);
    await settle(t);
    await _fillHusband(t);
    await _newSpouse(t);
    await t.ensureVisible(find.byKey(const Key('f-hosp-sel')));
    await t.tap(find.byKey(const Key('f-hosp-sel')));
    await settle(t);
    await t.tap(find.textContaining('Casa solo hombres').last);
    await settle(t);
    expect(find.byKey(const Key('f-hosp-aviso')), findsWidgets);
    await tapKey(t, 'f-guardar');
    expect(await _all(t, c), hasLength(2));
  });
}
