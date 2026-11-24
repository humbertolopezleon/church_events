import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento/data/repos_b.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'helpers.dart';

const _pc = Size(1200, 2400);

/// Evento con 6 personas, 2 equipos (uno ya con Pedro dentro). Todo se prepara ANTES de abrir la UI.
Future<Ctx> _open(WidgetTester t) async {
  final c = await pumpApp(t, _pc);
  late String ev;
  await t.runAsync(() async {
    ev = await c.repo.createEvent(
        name: 'Retiro',
        startDate: '2026-12-12',
        endDate: '2026-12-14',
        offersLodging: false);
    for (final (n, s, a) in [
      ('Juan', Sex.male, 30),
      ('María', Sex.female, 28),
      ('Pedro', Sex.male, 31),
      ('Ana', Sex.female, 29),
      ('Luis', Sex.male, 27),
      ('Rosa', Sex.female, 26),
    ]) {
      await c.repo.addAttendee(
          eventId: ev, firstName: n, lastName1: 'Pérez', sex: s, age: a);
    }
  });
  await t.runAsync(() => TeamRepo(c.db).createMany(ev, 2));
  final teams = (await t.runAsync(() => c.db.select(c.db.teams).get()))!;
  final pedro = (await t.runAsync(() => c.db.select(c.db.attendees).get()))!
      .firstWhere((r) => r.firstName == 'Pedro');
  await t.runAsync(() => TeamRepo(c.db).setTeam([pedro.id], teams.first.id));
  await login(t, 'admin', 'secreto1');
  await t.tap(find.text('Retiro'));
  await settle(t);
  await t.tap(find.text('Equipos').first);
  await settle(t);
  return c;
}

Future<Map<String, String?>> _teams(WidgetTester t, Ctx c) async => {
      for (final r
          in (await t.runAsync(() => c.db.select(c.db.attendees).get()))!)
        r.firstName: r.teamId
    };

void main() {
  testWidgets(
      'generar equipos: propuesta con borde de propuesta; Aceptar asigna solo a quien no tenía equipo',
      (t) async {
    final c = await _open(t);
    final before = await _teams(t, c);
    await tapKey(t, 'eq-generar');
    expect(find.textContaining('5 personas por repartir'), findsOneWidget);
    await tapKey(t, 'gen-calcular');
    expect(find.text('PROPUESTA'), findsOneWidget);
    expect(find.byKey(const Key('gen-detalle')), findsOneWidget);
    // Calcular no cambia nada.
    expect(await _teams(t, c), before);

    await tapKey(t, 'gen-aceptar');
    final after = await _teams(t, c);
    expect(
        after['Pedro'], before['Pedro']); // no se tocó a quien ya tenía equipo
    expect(after.values.every((e) => e != null), isTrue);
    final sizes = <String?, int>{};
    for (final e in after.values) {
      sizes[e] = (sizes[e] ?? 0) + 1;
    }
    expect(sizes.values.toList()..sort(), [3, 3]);
  });

  testWidgets('generar equipos: Descartar no cambia nada', (t) async {
    final c = await _open(t);
    final before = await _teams(t, c);
    await tapKey(t, 'eq-generar');
    await tapKey(t, 'gen-calcular');
    await tapKey(t, 'gen-descartar');
    expect(find.byKey(const Key('gen-descartada')), findsOneWidget);
    expect(await _teams(t, c), before);
  });

  testWidgets('generar equipos: «Deshacer» devuelve todo como estaba',
      (t) async {
    final c = await _open(t);
    final before = await _teams(t, c);
    await tapKey(t, 'eq-generar');
    await tapKey(t, 'gen-calcular');
    await tapKey(t, 'gen-aceptar');
    expect(await _teams(t, c), isNot(before));
    await t.tap(find.text('Deshacer'));
    await settle(t);
    expect(await _teams(t, c), before);
  });
}
