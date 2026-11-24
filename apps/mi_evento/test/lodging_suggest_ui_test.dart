import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento/data/repos_b.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'helpers.dart';

const _pc = Size(1200, 2400);

class _B {
  _B(this.c, this.ev) : lodging = LodgingRepo(c.db);
  final Ctx c;
  final String ev;
  final LodgingRepo lodging;
}

/// Evento con María (mujer, necesita hospedaje) y Juan (hombre, no necesita).
/// Los datos se preparan ANTES de abrir pantallas con streams vivos.
Future<_B> _open(WidgetTester t,
    {LodgingAccepts accepts = LodgingAccepts.women}) async {
  final c = await pumpApp(t, _pc);
  late String ev;
  await t.runAsync(() async {
    ev = await c.repo.createEvent(
        name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
    await c.repo.addAttendee(
        eventId: ev,
        firstName: 'Juan',
        lastName1: 'Pérez',
        sex: Sex.male,
        age: 34);
    await c.repo.addAttendee(
        eventId: ev,
        firstName: 'María',
        lastName1: 'Pérez',
        sex: Sex.female,
        age: 27,
        needsLodging: true);
  });
  final b = _B(c, ev);
  await t.runAsync(() => b.lodging.save(
      eventId: ev,
      name: 'Casa de Ana',
      kind: 'private_home',
      capacity: 3,
      accepts: accepts));
  await login(t, 'admin', 'secreto1');
  await t.tap(find.text('Retiro'));
  await settle(t);
  await t.tap(find.text('Hospedajes').first);
  await settle(t);
  return b;
}

Future<String?> _lodgingOfMaria(WidgetTester t, _B b) async {
  final rows = (await t.runAsync(() => b.c.db.select(b.c.db.attendees).get()))!;
  return rows.firstWhere((r) => r.firstName == 'María').lodgingId;
}

void main() {
  testWidgets('sugerir hospedaje: es una propuesta; solo «Aceptar» asigna',
      (t) async {
    final b = await _open(t);
    await tapKey(t, 'hosp-sugerir');
    expect(find.textContaining('Todas las personas que necesitan'),
        findsOneWidget);
    await tapKey(t, 'sg-buscar');
    expect(find.text('PROPUESTA 1'), findsOneWidget);
    expect(find.text('Casa de Ana'), findsOneWidget);
    expect(find.textContaining('0 → 1 de 3 plazas'), findsOneWidget);
    // Todavía no se guardó nada.
    expect(await _lodgingOfMaria(t, b), isNull);

    await tapKey(t, 'sg-aceptar-0');
    expect(await _lodgingOfMaria(t, b), isNotNull);
    expect(find.byKey(const Key('sg-fin')), findsOneWidget);
  });

  testWidgets('sugerir hospedaje: «Descartar» no asigna nada', (t) async {
    final b = await _open(t);
    await tapKey(t, 'hosp-sugerir');
    await tapKey(t, 'sg-buscar');
    await tapKey(t, 'sg-descartar-0');
    expect(find.byKey(const Key('sg-fin')), findsOneWidget);
    expect(await _lodgingOfMaria(t, b), isNull);
  });

  testWidgets(
      'sugerir hospedaje: sin plazas compatibles se explica y no asigna',
      (t) async {
    // El único hospedaje es «solo hombres»: María no tiene dónde ir.
    final b = await _open(t, accepts: LodgingAccepts.men);
    await tapKey(t, 'hosp-sugerir');
    await tapKey(t, 'sg-buscar');
    expect(find.byKey(const Key('sg-sin-lugar-0')), findsOneWidget);
    expect(find.textContaining('ningún hospedaje compatible'), findsOneWidget);
    expect(await _lodgingOfMaria(t, b), isNull);
  });
}
