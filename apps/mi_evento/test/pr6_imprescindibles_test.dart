// Imprescindibles para el primer evento real (bloque A): Esc en escritorio, Equipos oculto cuando
// el evento no los usa y hospedajes con plazas en la ficha.
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento/data/repos_b.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'helpers.dart';

const _pc = Size(1200, 2400);

void main() {
  testWidgets('Esc vuelve atrás desde una pantalla completa (Nuevo hospedaje)',
      (t) async {
    final c = await pumpApp(t, _pc);
    await t.runAsync(() => c.repo.createEvent(
        name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14'));
    await login(t, 'admin', 'secreto1');
    await t.tap(find.text('Retiro'));
    await settle(t);
    await t.tap(find.text('Hospedajes').first);
    await settle(t);
    await tapKey(t, 'hosp-nuevo');
    expect(find.byKey(const Key('lf-nombre')), findsOneWidget);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(t);
    expect(find.byKey(const Key('lf-nombre')), findsNothing);
    expect(find.byKey(const Key('hosp-nuevo')), findsOneWidget);
    // En la pantalla raíz, Esc no hace nada (no se sale de la app ni se rompe).
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(t);
    expect(find.byKey(const Key('hosp-nuevo')), findsOneWidget);
  });

  testWidgets('Esc cierra un diálogo y cancela (fechas del evento)', (t) async {
    await pumpApp(t, _pc);
    await login(t, 'admin', 'secreto1');
    await t.tap(find.text('Crear evento'));
    await settle(t);
    await tapKey(t, 'ev-fechas');
    expect(find.byKey(const Key('fechas-dialogo')), findsOneWidget);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(t);
    expect(find.byKey(const Key('fechas-dialogo')), findsNothing);
    // El diálogo de crear evento sigue ahí (solo se cerró el de fechas).
    expect(find.byKey(const Key('ev-nombre')), findsOneWidget);
  });

  group('Equipos solo si el evento los usa', () {
    testWidgets('con equipos: aparece en el menú; sin equipos: no', (t) async {
      final c = await pumpApp(t, _pc);
      await t.runAsync(() async {
        await c.repo.createEvent(
            name: 'Con equipos',
            startDate: '2026-12-12',
            endDate: '2026-12-14');
        await c.repo.createEvent(
            name: 'Sin equipos',
            startDate: '2026-12-12',
            endDate: '2026-12-14',
            offersTeams: false);
      });
      await login(t, 'admin', 'secreto1');
      await t.tap(find.text('Con equipos'));
      await settle(t);
      expect(find.text('Equipos'), findsWidgets);
    });

    testWidgets('evento sin equipos: «Equipos» no sale en el menú lateral',
        (t) async {
      final c = await pumpApp(t, _pc);
      await t.runAsync(() => c.repo.createEvent(
          name: 'Sin equipos',
          startDate: '2026-12-12',
          endDate: '2026-12-14',
          offersTeams: false));
      await login(t, 'admin', 'secreto1');
      await t.tap(find.text('Sin equipos'));
      await settle(t);
      expect(find.text('Hospedajes'), findsWidgets); // el menú sí está
      expect(find.text('Equipos'), findsNothing);
    });
  });

  testWidgets('móvil, evento sin equipos: la barra inferior no tiene Equipos',
      (t) async {
    final c = await pumpApp(t, const Size(390, 844));
    await t.runAsync(() => c.repo.createEvent(
        name: 'Sin equipos',
        startDate: '2026-12-12',
        endDate: '2026-12-14',
        offersTeams: false));
    await login(t, 'admin', 'secreto1');
    await t.tap(find.text('Sin equipos'));
    await settle(t);
    expect(find.text('Asistentes'), findsWidgets);
    expect(find.text('Equipos'), findsNothing);
    await t.tap(find.text('Más'));
    await settle(t);
    expect(find.text('Hospedajes'), findsWidgets);
    expect(find.text('Equipos'), findsNothing);
  });

  testWidgets(
      'ficha del asistente: solo se ofrecen hospedajes con plazas (no hay filtro «Con plazas libres»)',
      (t) async {
    final c = await pumpApp(t, _pc);
    await t.runAsync(() async {
      final ev = await c.repo.createEvent(
          name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
      final ch = await c.repo.createChurch(
          name: 'Bautista', province: 'Matanzas', municipality: 'Cárdenas');
      final ana = await c.repo.addAttendee(
          eventId: ev,
          firstName: 'Ana',
          lastName1: 'X',
          sex: Sex.female,
          age: 30,
          churchId: ch.id,
          needsLodging: true);
      await c.repo.addAttendee(
          eventId: ev,
          firstName: 'Bea',
          lastName1: 'Y',
          sex: Sex.female,
          age: 30,
          churchId: ch.id,
          needsLodging: true);
      final lr = LodgingRepo(c.db);
      final lleno = await lr.save(
          eventId: ev,
          name: 'Casa llena',
          kind: 'shelter',
          capacity: 1,
          accepts: LodgingAccepts.any);
      await lr.save(
          eventId: ev,
          name: 'Casa libre',
          kind: 'shelter',
          capacity: 3,
          accepts: LodgingAccepts.any);
      await lr.assign(lleno.id, [ana.id]);
    });
    await login(t, 'admin', 'secreto1');
    await t.tap(find.text('Retiro'));
    await settle(t);
    await t.tap(find.text('Asistentes').first);
    await settle(t);
    await t.tap(find.textContaining('Bea').first);
    await settle(t);
    // Bea necesita hospedaje: el selector ya está a la vista.
    expect(find.byKey(const Key('f-hosp-sel')), findsOneWidget);
    expect(find.byKey(const Key('f-hosp-filtro-libres')), findsNothing);
    // Se muestra 1 de 2: la casa llena no se ofrece.
    expect(find.text('1 de 2 hospedajes'), findsOneWidget);
  });
}
