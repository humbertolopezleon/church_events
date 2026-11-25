import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/repos_b.dart';
import 'package:mi_evento/data/repository.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'helpers.dart';

/// Fase 2: Asistentes (búsqueda sin campos filtrables, tarjeta nueva y estado vacío).
void main() {
  group('regla de búsqueda', () {
    AttendeeView view(int n, String name, String church) => AttendeeView(
        AttendeeRow(
          id: 'id$n',
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
          originDeviceId: 'd',
          eventId: 'e',
          regNumber: n,
          firstName: name,
          lastName1: 'Pérez',
          lastName2: '',
          sex: 'M',
          age: 30,
          province: '',
          municipality: '',
          needsLodging: false,
          notes: '',
          dedupeKey: name,
          status: 'confirmed',
        ),
        church);

    test(
        'no encuentra por iglesia (tiene su propio filtro); sí por nombre y número',
        () {
      final all = [view(1, 'Juan', 'Bautista'), view(2, 'Ana', 'Metodista')];
      expect(Repository.search(all, 'bautista', includeChurch: false), isEmpty);
      expect(
          Repository.search(all, 'juan', includeChurch: false), hasLength(1));
      expect(
          Repository.search(all, 'perez', includeChurch: false), hasLength(2));
      expect(
          Repository.search(all, '2', includeChurch: false).single.a.regNumber,
          2);
      // Las pantallas sin filtro de iglesia (pickers, comidas) siguen buscando por iglesia.
      expect(Repository.search(all, 'bautista'), hasLength(1));
    });
  });

  testWidgets(
      'sin asistentes: estado vacío sin buscador, filtros ni botón flotante; ayuda con las columnas reales',
      (t) async {
    final c = await pumpApp(t, const Size(390, 844));
    await t.runAsync(() => c.repo.createEvent(
        name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14'));
    await login(t, 'admin', 'secreto1');
    await t.tap(find.text('Retiro'));
    await settle(t);
    await t.tap(find.text('Asistentes').first);
    await settle(t);
    expect(find.text('Todavía no hay asistentes'), findsOneWidget);
    expect(find.textContaining('trae una lista que ya tengas'), findsOneWidget);
    expect(find.byKey(const Key('buscar')), findsNothing);
    expect(find.byKey(const Key('filtros-toggle')), findsNothing);
    expect(find.byKey(const Key('asis-registrar')), findsNothing);
    expect(find.text('Registrar primera persona'), findsOneWidget);
    expect(find.text('Importar lista desde CSV'), findsOneWidget);
    // Ayuda: menciona TODAS las columnas del importador real.
    await tapKey(t, 'asis-vacio-ayuda');
    final dialog = find.byKey(const Key('asis-ayuda-csv'));
    expect(dialog, findsOneWidget);
    final shown = t
        .widgetList<Text>(
            find.descendant(of: dialog, matching: find.byType(Text)))
        .map((w) => w.data ?? '')
        .join('\n');
    for (final h in attendeeCsvHeaders) {
      expect(shown, contains('• $h:'), reason: 'falta la columna «$h»');
    }
    expect(shown, contains('Obligatorias'));
    // «Registrar primera persona» abre el formulario.
    await t.tap(find.text('Entendido'));
    await settle(t);
    await tapKey(t, 'asis-vacio-registrar');
    expect(find.text('Nuevo asistente'), findsOneWidget);
  });

  testWidgets(
      'tarjeta: etiqueta ámbar sin hospedaje, color del equipo y chip de preinscrito',
      (t) async {
    final c = await pumpApp(t, const Size(390, 844));
    await t.runAsync(() async {
      final ev = await c.repo.createEvent(
          name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
      final ch = await c.repo.createChurch(
          name: 'Bautista', province: 'Matanzas', municipality: 'Cárdenas');
      Future<AttendeeRow> add(String n,
              {bool lodging = false, bool pre = false}) =>
          c.repo.addAttendee(
              eventId: ev,
              firstName: n,
              lastName1: 'Prueba',
              sex: Sex.female,
              age: 31,
              churchId: ch.id,
              needsLodging: lodging,
              preregistered: pre);
      final sin = await add('Sin', lodging: true, pre: true);
      final con = await add('Con', lodging: true);
      await add('Nada');
      final l = await LodgingRepo(c.db).save(
          eventId: ev,
          name: 'Casa Norte',
          kind: 'private_home',
          capacity: 4,
          accepts: LodgingAccepts.any);
      await LodgingRepo(c.db).assign(l.id, [con.id]);
      await TeamRepo(c.db).createMany(ev, 1);
      final team = (await c.db.select(c.db.teams).get()).single;
      await TeamRepo(c.db).setTeam([sin.id], team.id);
    });
    await login(t, 'admin', 'secreto1');
    await t.tap(find.text('Retiro'));
    await settle(t);
    await t.tap(find.text('Asistentes').first);
    await settle(t);
    expect(find.byKey(const Key('sin-hospedaje-1')),
        findsOneWidget); // «Sin» (nº 1)
    expect(find.byKey(const Key('sin-hospedaje-2')), findsNothing); // «Con»
    expect(find.text('· Casa Norte'), findsOneWidget);
    expect(find.text('· No necesita hospedaje'), findsOneWidget);
    expect(find.byKey(const Key('equipo-color-1')), findsOneWidget);
    expect(find.byKey(const Key('equipo-color-2')), findsNothing);
    expect(find.byKey(const Key('preinscrito-1')), findsOneWidget);
    expect(find.text('31 años'), findsWidgets);
    // Sin avatar; con el número y la iglesia.
    expect(find.byType(CircleAvatar), findsNothing);
    expect(t.widget<Text>(find.byKey(const Key('asis-numero-1'))).data,
        'Nº 1 · Bautista');
    // El buscador ya no encuentra por iglesia.
    await t.enterText(find.byKey(const Key('buscar')), 'bautista');
    await settle(t);
    expect(find.byKey(const Key('asistente-1')), findsNothing);
    expect(find.textContaining('¿Falta registrarlo?'), findsOneWidget);
  });

  testWidgets('con letra al 130 % la tarjeta y el estado vacío no se desbordan',
      (t) async {
    t.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    final c = await pumpApp(t, const Size(390, 844));
    await t.runAsync(() async {
      final ev = await c.repo.createEvent(
          name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
      await c.repo.addAttendee(
          eventId: ev,
          firstName: 'María de los Ángeles',
          lastName1: 'Fernández',
          lastName2: 'de la Caridad',
          sex: Sex.female,
          age: 31,
          needsLodging: true,
          preregistered: true);
    });
    await login(t, 'admin', 'secreto1');
    await t.tap(find.text('Retiro'));
    await settle(t);
    await t.tap(find.text('Asistentes').first);
    await settle(t);
    expect(find.byKey(const Key('sin-hospedaje-1')), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
