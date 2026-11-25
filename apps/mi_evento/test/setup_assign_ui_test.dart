import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento/data/repos_b.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'package:mi_evento/ui/event_dates.dart';

import 'helpers.dart';

const _pc = Size(1200, 2400);

Future<void> _newEvent(WidgetTester t,
    {bool lodging = true, bool teams = true}) async {
  await t.tap(find.text('Crear evento'));
  await settle(t);
  await t.enterText(find.byKey(const Key('ev-nombre')), 'Congreso');
  if (!lodging) await tapKey(t, 'ev-hospedaje');
  if (!teams) await tapKey(t, 'ev-equipos');
  await t.tap(find.byKey(const Key('ev-crear')));
  await settle(t);
}

void main() {
  group('fechas del evento', () {
    testWidgets('«Hoy» + Aceptar = un solo día (el de hoy)', (t) async {
      await pumpApp(t, _pc);
      await login(t, 'admin', 'secreto1');
      await t.tap(find.text('Crear evento'));
      await settle(t);
      await tapKey(t, 'ev-fechas');
      expect(find.byKey(const Key('fechas-dialogo')), findsOneWidget);
      await t.tap(find.byKey(const Key('fechas-hoy')));
      await t.pump();
      await t.tap(find.byKey(const Key('fechas-aceptar')));
      await settle(t);
      expect(find.textContaining('Un solo día'), findsOneWidget);
      expect(find.textContaining(isoDate(DateTime.now())), findsOneWidget);
    });

    testWidgets('inicio y fin sobre el mismo calendario: muestra inicio → fin',
        (t) async {
      await pumpApp(t, _pc);
      await login(t, 'admin', 'secreto1');
      await t.tap(find.text('Crear evento'));
      await settle(t);
      await tapKey(t, 'ev-fechas');
      final today = DateTime.now();
      final end = DateTime(today.year, today.month, today.day + 2);
      await t.tap(find.byKey(const Key('fechas-hoy')));
      await t.pump();
      await t.tap(find.byKey(const Key('fechas-fin')));
      await t.pump();
      if (end.month != today.month) {
        await t.tap(find.byIcon(Icons.chevron_right));
        await t.pump();
      }
      await t.tap(find.text('${end.day}').first);
      await t.pump();
      await t.tap(find.byKey(const Key('fechas-aceptar')));
      await settle(t);
      expect(find.textContaining('→'), findsOneWidget);
      expect(find.textContaining('Un solo día'), findsNothing);
    });

    testWidgets('no se pueden elegir días anteriores a hoy', (t) async {
      final today = DateTime.now();
      if (today.day == 1) return; // sin días anteriores visibles en este mes
      await pumpApp(t, _pc);
      await login(t, 'admin', 'secreto1');
      await t.tap(find.text('Crear evento'));
      await settle(t);
      await tapKey(t, 'ev-fechas');
      // Ayer está deshabilitado: tocarlo no cambia el inicio.
      await t.tap(find.text('${today.day - 1}').first);
      await t.pump();
      await t.tap(find.byKey(const Key('fechas-aceptar')));
      await settle(t);
      expect(find.textContaining(isoDate(today)), findsOneWidget);
    });

    test('earliestEventDate: hoy, o la fecha de inicio ya pasada del evento',
        () {
      final today = dateOnly(DateTime.now());
      expect(earliestEventDate(), today);
      expect(earliestEventDate(current: today.add(const Duration(days: 5))),
          today);
      final past = today.subtract(const Duration(days: 9));
      expect(earliestEventDate(current: past), past);
    });
  });

  group('configuración del evento (primer momento)', () {
    testWidgets(
        'al crear solo se ve la configuración; terminar sin definir pide confirmar y abre las inscripciones',
        (t) async {
      await pumpApp(t, _pc);
      await login(t, 'admin', 'secreto1');
      await _newEvent(t);
      expect(find.byKey(const Key('cfg-intro')), findsOneWidget);
      expect(find.text('Asistentes'), findsNothing); // aún no hay inscripciones
      expect(find.byKey(const Key('cfg-hospedajes-estado')), findsOneWidget);
      expect(find.byKey(const Key('cfg-equipos-estado')), findsOneWidget);

      await tapKey(t, 'cfg-terminar');
      expect(find.textContaining('Faltan los hospedajes y los equipos'),
          findsOneWidget);
      await tapKey(t, 'cfg-seguir'); // sigue configurando
      expect(find.byKey(const Key('cfg-intro')), findsOneWidget);

      await tapKey(t, 'cfg-terminar');
      await tapKey(t, 'cfg-terminar-igual');
      expect(find.byKey(const Key('panel-vacio')), findsOneWidget);
      expect(find.text('Asistentes'), findsWidgets);
    });

    testWidgets(
        'al definir los equipos se confirman los criterios de balance propuestos (y se pueden cambiar)',
        (t) async {
      await pumpApp(t, _pc);
      await login(t, 'admin', 'secreto1');
      await _newEvent(t, lodging: false);
      await tapKey(t, 'cfg-equipos-definir');
      // Propuesta del sistema ya escrita: tamaño 2, sexo 4, edad 3.
      expect(
          t
              .widget<TextField>(find.byKey(const Key('eq-tope-tamano')))
              .controller!
              .text,
          '2');
      expect(
          t
              .widget<TextField>(find.byKey(const Key('eq-tope-sexo')))
              .controller!
              .text,
          '4');
      await enter(t, 'eq-tope-tamano', '1'); // cambia uno
      await tapKey(t, 'eq-crear-ok');
      expect(find.text('4 equipos'), findsOneWidget);
      expect(find.textContaining('tamaño ±1'), findsOneWidget);
      expect(find.textContaining('hombres–mujeres ≤ 4'), findsOneWidget);

      // Con todo definido, terminar no pregunta nada.
      await tapKey(t, 'cfg-terminar');
      expect(find.byKey(const Key('cfg-terminar-igual')), findsNothing);
      expect(find.byKey(const Key('panel-vacio')), findsOneWidget);
    });

    testWidgets('evento sin hospedaje ni equipos: se termina directo',
        (t) async {
      await pumpApp(t, _pc);
      await login(t, 'admin', 'secreto1');
      await _newEvent(t, lodging: false, teams: false);
      expect(find.byKey(const Key('cfg-hospedajes')), findsNothing);
      expect(find.byKey(const Key('cfg-equipos-definir')), findsNothing);
      await tapKey(t, 'cfg-terminar');
      expect(find.byKey(const Key('panel-vacio')), findsOneWidget);
    });

    testWidgets(
        'cambios sin guardar en los datos impiden terminar; guardados, sí',
        (t) async {
      await pumpApp(t, _pc);
      await login(t, 'admin', 'secreto1');
      await _newEvent(t, lodging: false, teams: false);
      await enter(t, 'cfg-nombre', 'Congreso Nacional');
      await tapKey(t, 'cfg-terminar');
      expect(find.textContaining('cambios sin guardar'), findsOneWidget);
      await tapKey(t, 'cfg-guardar-datos');
      await tapKey(t, 'cfg-terminar');
      expect(find.text('Congreso Nacional'), findsWidgets);
      expect(find.byKey(const Key('panel-vacio')), findsOneWidget);
    });

    testWidgets('el administrador vuelve a la configuración desde el menú',
        (t) async {
      await pumpApp(t, _pc);
      await login(t, 'admin', 'secreto1');
      await _newEvent(t, lodging: false, teams: false);
      await tapKey(t, 'cfg-terminar');
      await t.tap(find.text('Configuración').first);
      await settle(t);
      expect(find.byKey(const Key('cfg-volver')), findsOneWidget);
      expect(find.byKey(const Key('cfg-terminar')), findsNothing);
    });

    testWidgets('un operador no configura: espera al administrador', (t) async {
      final c = await pumpApp(t, _pc, operator: true);
      await t.runAsync(() => c.repo.createEvent(
          name: 'Retiro',
          startDate: '2026-12-12',
          endDate: '2026-12-14',
          setupDone: false));
      await login(t, 'ruth', 'ruth123');
      await t.tap(find.text('Retiro'));
      await settle(t);
      expect(find.textContaining('administrador está configurando'),
          findsOneWidget);
      expect(find.byKey(const Key('cfg-terminar')), findsNothing);
    });
  });

  group('equipo automático y hospedaje al inscribir (segundo momento)', () {
    /// Evento ya configurado: 2 equipos, un hospedaje de mujeres y una iglesia. Datos ANTES de la UI.
    Future<Ctx> open(WidgetTester t) async {
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
      await t.runAsync(() => TeamRepo(c.db).createMany(ev, 2));
      await t.runAsync(() => LodgingRepo(c.db).save(
          eventId: ev,
          name: 'Casa de Ana',
          kind: 'private_home',
          capacity: 3,
          accepts: LodgingAccepts.women));
      await login(t, 'admin', 'secreto1');
      await t.tap(find.text('Retiro'));
      await settle(t);
      await goRegister(t);
      await settle(t);
      return c;
    }

    Future<void> fill(WidgetTester t,
        {String name = 'María', bool woman = true, String age = '27'}) async {
      await enter(t, 'f-nombre', name);
      await enter(t, 'f-apellido1', 'Pérez');
      await pickSex(t, woman: woman);
      await enter(t, 'f-edad', age);
      await enter(t, 'f-iglesia', 'Bautista');
      await tapKey(t, 'iglesia-bautista ebenezer');
    }

    Future<Map<String, AttendeeRowLite>> rows(WidgetTester t, Ctx c) async => {
          for (final r
              in (await t.runAsync(() => c.db.select(c.db.attendees).get()))!)
            r.firstName: AttendeeRowLite(r.teamId, r.lodgingId)
        };

    testWidgets(
        'el equipo lo pone el sistema: no se elige en el formulario y se muestra al guardar',
        (t) async {
      final c = await open(t);
      // No hay selector ni sugerencia de equipo en la inscripción.
      expect(find.byKey(const Key('f-equipo')), findsNothing);
      expect(find.byKey(const Key('f-equipo-sugerencia')), findsNothing);
      await fill(t);
      await tapKey(t, 'f-guardar');
      expect(find.byKey(const Key('exito-equipo')), findsOneWidget);
      expect((await rows(t, c))['María']!.team, isNotNull);
    });

    testWidgets(
        'personas seguidas se reparten entre equipos para mantener el balance',
        (t) async {
      final c = await open(t);
      await fill(t);
      await tapKey(t, 'f-guardar-otro');
      await fill(t, name: 'Juan', woman: false, age: '30');
      await tapKey(t, 'f-guardar');
      final r = await rows(t, c);
      expect(r['María']!.team, isNotNull);
      expect(r['Juan']!.team, isNotNull);
      expect(r['María']!.team,
          isNot(r['Juan']!.team)); // dos equipos → uno en cada uno
    });

    testWidgets('el hospedaje sugerido se puede tomar y queda asignado',
        (t) async {
      final c = await open(t);
      await fill(t);
      await tapKey(t, 'f-hospedaje');
      expect(find.byKey(const Key('f-hosp-sugerencia')), findsOneWidget);
      await tapKey(t, 'f-hosp-usar');
      await tapKey(t, 'f-guardar');
      expect(find.text('Hospedaje: Casa de Ana'), findsOneWidget);
      expect((await rows(t, c))['María']!.lodging, isNotNull);
    });

    testWidgets('el hospedaje sugerido se puede dejar para después', (t) async {
      final c = await open(t);
      await fill(t);
      await tapKey(t, 'f-hospedaje');
      await tapKey(t, 'f-hosp-dejar');
      expect(find.byKey(const Key('f-hosp-despues')), findsOneWidget);
      await tapKey(t, 'f-guardar');
      expect(find.text('Necesita hospedaje · sin asignar'), findsOneWidget);
      expect((await rows(t, c))['María']!.lodging, isNull);
    });

    testWidgets('sin aceptar nada: queda sin hospedaje (decide quien inscribe)',
        (t) async {
      final c = await open(t);
      await fill(t);
      await tapKey(t, 'f-hospedaje');
      await tapKey(t, 'f-guardar');
      expect((await rows(t, c))['María']!.lodging, isNull);
      expect((await rows(t, c))['María']!.team,
          isNotNull); // el equipo sí es automático
    });

    testWidgets(
        'un hospedaje incompatible sale deshabilitado: no se puede elegir y se guarda sin hospedaje',
        (t) async {
      final c = await open(t);
      await fill(t, name: 'Juan', woman: false, age: '30');
      await tapKey(t, 'f-hospedaje');
      expect(find.byKey(const Key('f-hosp-sin-lugar')), findsOneWidget);
      await t.ensureVisible(find.byKey(const Key('f-hosp-sel')));
      await t.tap(find.byKey(const Key('f-hosp-sel')));
      await settle(t);
      expect(find.textContaining('no compatible'), findsWidgets);
      await t.tap(find.textContaining('Casa de Ana').last); // deshabilitado
      await settle(t);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await settle(t);
      expect(find.byKey(const Key('f-hosp-aviso')), findsNothing);
      await tapKey(t, 'f-guardar');
      expect((await rows(t, c))['Juan']!.lodging, isNull);
    });
  });
}

class AttendeeRowLite {
  AttendeeRowLite(this.team, this.lodging);
  final String? team, lodging;
}
