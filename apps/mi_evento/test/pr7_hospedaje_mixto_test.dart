// Bloque de hospedaje: hospedajes «mixtos» (solteros de un sexo o matrimonios) y matrimonios
// alojados por separado cuando no hay quien los reciba.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento/data/lodging_exchange.dart';
import 'package:mi_evento/data/repos_b.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'helpers.dart';

const _pc = Size(1200, 2400);

void main() {
  testWidgets(
      'Nuevo hospedaje: se puede elegir «Solo mujeres o matrimonios» y se guarda',
      (t) async {
    final c = await pumpApp(t, _pc);
    late String ev;
    await t.runAsync(() async {
      ev = await c.repo.createEvent(
          name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
    });
    await login(t, 'admin', 'secreto1');
    await t.tap(find.text('Retiro'));
    await settle(t);
    await t.tap(find.text('Hospedajes').first);
    await settle(t);
    await tapKey(t, 'hosp-nuevo');
    expect(find.byKey(const Key('lf-acepta-mixto-ayuda')), findsOneWidget);
    await enter(t, 'lf-nombre', 'Casa de Rita');
    await tapKey(t, 'lf-mas'); // 2 plazas
    await tapKey(t, 'lf-acepta-womenOrCouples');
    await tapKey(t, 'lf-guardar');
    await settle(t);
    final rows =
        (await t.runAsync(() => LodgingRepo(c.db).watchLodgings(ev).first))!;
    expect(rows.single.row.accepts, 'women_couples');
    expect(rows.single.row.capacity, 2);
    expect(find.textContaining('Solo mujeres o matrimonios'), findsWidgets);
  });

  testWidgets('CSV: «Solo hombres o matrimonios» se importa y se exporta igual',
      (t) async {
    final c = await pumpApp(t, _pc);
    late String ev;
    await t.runAsync(() async {
      ev = await c.repo.createEvent(
          name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
    });
    final csv = buildCsvDelimited([
      LodgingExchange.headers,
      [
        'Casa Sur',
        'Casa particular',
        'Solo hombres o matrimonios',
        '2',
        '',
        '',
        '',
        ''
      ],
    ]);
    final ex = LodgingExchange(c.db, ev);
    await t.runAsync(() async {
      final prev = await ex.preview(csv);
      expect(prev.warnings, isEmpty);
      await ex.apply(csv);
      final out = await ex.export();
      expect(out[1][2], 'Solo hombres o matrimonios');
    });
  });

  group('matrimonios por separado (pantalla «Sugerir hospedaje»)', () {
    Future<(Ctx, String)> open(WidgetTester t) async {
      final c = await pumpApp(t, _pc);
      late String ev;
      await t.runAsync(() async {
        ev = await c.repo.createEvent(
            name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
        final juan = await c.repo.addAttendee(
            eventId: ev,
            firstName: 'Juan',
            lastName1: 'Pérez',
            sex: Sex.male,
            age: 34,
            needsLodging: true);
        final ana = await c.repo.addAttendee(
            eventId: ev,
            firstName: 'Ana',
            lastName1: 'Gómez',
            sex: Sex.female,
            age: 31,
            needsLodging: true);
        await SocialRepo(c.db).setSpouse(juan.id, ana.id);
        final lr = LodgingRepo(c.db);
        await lr.save(
            eventId: ev,
            name: 'Casa de hombres',
            kind: 'shelter',
            capacity: 3,
            accepts: LodgingAccepts.men);
        await lr.save(
            eventId: ev,
            name: 'Casa de mujeres',
            kind: 'shelter',
            capacity: 3,
            accepts: LodgingAccepts.women);
      });
      await login(t, 'admin', 'secreto1');
      await t.tap(find.text('Retiro'));
      await settle(t);
      await t.tap(find.text('Hospedajes').first);
      await settle(t);
      await tapKey(t, 'hosp-sugerir');
      return (c, ev);
    }

    Future<Map<String, String?>> lodgingOf(WidgetTester t, Ctx c) async {
      final rows = (await t.runAsync(() => c.db.select(c.db.attendees).get()))!;
      final names = (await t.runAsync(() => c.db.select(c.db.lodgings).get()))!;
      return {
        for (final r in rows)
          r.firstName: r.lodgingId == null
              ? null
              : names.firstWhere((l) => l.id == r.lodgingId).name
      };
    }

    testWidgets(
        'por defecto el matrimonio no se separa: no hay propuesta completa',
        (t) async {
      final (c, _) = await open(t);
      expect(find.byKey(const Key('sg-separar')), findsOneWidget);
      await tapKey(t, 'sg-buscar');
      expect(find.textContaining('se alojan por separado'), findsNothing);
      expect(
          find.textContaining(
              'No hay ningún hospedaje compatible para matrimonios'),
          findsOneWidget);
      expect((await lodgingOf(t, c)).values.every((v) => v == null), isTrue);
    });

    testWidgets(
        'con la opción activada: esposo con hombres, esposa con mujeres, y se explica',
        (t) async {
      final (c, _) = await open(t);
      await tapKey(t, 'sg-separar');
      await tapKey(t, 'sg-buscar');
      expect(find.textContaining('se alojan por separado'), findsWidgets);
      expect(find.text('Casa de hombres'), findsWidgets);
      expect(find.text('Casa de mujeres'), findsWidgets);
      // Nada se guarda hasta aceptar.
      expect((await lodgingOf(t, c)).values.every((v) => v == null), isTrue);
      await tapKey(t, 'sg-aceptar-0');
      expect(await lodgingOf(t, c),
          {'Juan': 'Casa de hombres', 'Ana': 'Casa de mujeres'});
    });
  });
}
