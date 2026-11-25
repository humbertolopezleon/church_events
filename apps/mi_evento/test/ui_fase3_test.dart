import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/repos_b.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'helpers.dart';

/// Fase 3: Iglesias (tarjeta de dos líneas) y Hospedajes (aviso de estado, tarjeta con barra).
void main() {
  testWidgets('iglesias: tarjeta con «Municipio, Provincia» y «N asistentes»',
      (t) async {
    final c = await pumpApp(t, const Size(390, 844));
    await t.runAsync(() async {
      final ev = await c.repo.createEvent(
          name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
      final ch = await c.repo.createChurch(
          name: 'Bautista', province: 'Matanzas', municipality: 'Cárdenas');
      await c.repo.createChurch(
          name: 'Metodista', province: 'La Habana', municipality: 'Centro');
      for (final n in ['A', 'B']) {
        await c.repo.addAttendee(
            eventId: ev,
            firstName: n,
            lastName1: 'P',
            sex: Sex.male,
            age: 30,
            churchId: ch.id);
      }
    });
    await login(t, 'admin', 'secreto1');
    await t.tap(find.text('Retiro'));
    await settle(t);
    await t.tap(find.text('Más'));
    await settle(t);
    await t.tap(find.text('Iglesias').first);
    await settle(t);
    expect(find.text('Cárdenas, Matanzas'), findsOneWidget);
    expect(find.text('2 asistentes'), findsOneWidget);
    expect(find.text('Sin asistentes'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets(
      'hospedajes: aviso ámbar abre Asistentes filtrados «sin hospedaje»; verde si todos tienen',
      (t) async {
    final c = await pumpApp(t, const Size(390, 844));
    late String ev;
    late LodgingRow lodging;
    late AttendeeRow a1;
    late AttendeeRow a2;
    await t.runAsync(() async {
      ev = await c.repo.createEvent(
          name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
      Future<AttendeeRow> add(String n) => c.repo.addAttendee(
          eventId: ev,
          firstName: n,
          lastName1: 'Prueba',
          sex: Sex.male,
          age: 30,
          needsLodging: true);
      a1 = await add('Uno');
      a2 = await add('Dos');
      lodging = await LodgingRepo(c.db).save(
          eventId: ev,
          name: 'Casa Norte',
          kind: 'private_home',
          capacity: 4,
          accepts: LodgingAccepts.any);
    });
    await login(t, 'admin', 'secreto1');
    await t.tap(find.text('Retiro'));
    await settle(t);
    await t.tap(find.text('Más'));
    await settle(t);
    await t.tap(find.text('Hospedajes').first);
    await settle(t);
    expect(find.text('2 personas sin hospedaje'), findsOneWidget);
    expect(find.text('1 hospedaje · 4 plazas'), findsOneWidget);
    expect(find.text('4 plazas libres'), findsOneWidget);
    expect(find.text('Ninguna ocupada'), findsOneWidget);
    expect(find.byTooltip('Opciones de Casa Norte'), findsOneWidget);
    await tapKey(t, 'hosp-resumen');
    // Asistentes, ya filtrado a «Necesita y no tiene».
    expect(find.text('Uno Prueba'), findsOneWidget);
    expect(find.byKey(const Key('filtros-contador')), findsOneWidget);
    // Con todos hospedados, el aviso pasa a verde.
    await t.runAsync(() async {
      await LodgingRepo(c.db).assign(lodging.id, [a1.id, a2.id]);
    });
    await t.tap(find.text('Más'));
    await settle(t);
    await t.tap(find.text('Hospedajes').first);
    await settle(t);
    expect(find.text('Todos tienen hospedaje. Quedan 2 plazas libres.'),
        findsOneWidget);
    expect(find.text('2 de 4 ocupadas'), findsOneWidget);
  });
}
