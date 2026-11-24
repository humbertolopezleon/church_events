import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento/data/repos_b.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'helpers.dart';

const _pc = Size(1200, 2200); // alto grande: el formulario cabe sin desplazarse

/// Abre el evento «Retiro» ya creado y va a la pestaña indicada de la barra lateral.
Future<Ctx> _open(WidgetTester t,
    {bool operator = false, bool seed = false}) async {
  final c = await pumpApp(t, _pc, operator: operator);
  await t.runAsync(() async {
    // Estas pruebas no usan equipos.
    await c.repo.createEvent(
        name: 'Retiro',
        startDate: '2026-12-12',
        endDate: '2026-12-14',
        offersTeams: false);
    // Un hospedaje ya definido: así el registro no pide preparar el evento.
    final evId = (await c.db.select(c.db.events).getSingle()).id;
    await LodgingRepo(c.db).save(
        eventId: evId,
        name: 'Casa base',
        kind: 'shelter',
        capacity: 50,
        accepts: LodgingAccepts.men);
    if (seed) {
      final ev = (await c.db.select(c.db.events).getSingle()).id;
      final ig = await c.repo.createChurch(
          name: 'Bautista Ebenezer',
          province: 'Matanzas',
          municipality: 'Cárdenas');
      await c.repo.addAttendee(
          eventId: ev,
          firstName: 'Juan',
          lastName1: 'Pérez',
          lastName2: 'García',
          sex: Sex.male,
          age: 34,
          churchId: ig.id);
      await c.repo.addAttendee(
          eventId: ev,
          firstName: 'María',
          lastName1: 'Rodríguez',
          lastName2: 'Leyva',
          sex: Sex.female,
          age: 27,
          churchId: ig.id,
          needsLodging: true);
      await c.repo.addAttendee(
          eventId: ev,
          firstName: 'Ana Lucía',
          lastName1: 'Martínez',
          sex: Sex.female,
          age: 12,
          churchId: ig.id);
    }
  });
  await login(
      t, operator ? 'ruth' : 'admin', operator ? 'ruth123' : 'secreto1');
  await t.tap(find.text('Retiro'));
  await settle(t);
  return c;
}

Future<void> _goTo(WidgetTester t, String label) async {
  await t.tap(find.text(label).first);
  await settle(t);
}

void main() {
  testWidgets(
      'registro: validaciones en español, iglesia nueva y pantalla de éxito',
      (t) async {
    final c = await _open(t);
    expect(find.byKey(const Key('panel-vacio')), findsOneWidget);
    await _goTo(t, 'Registrar');

    await tapKey(t, 'f-guardar');
    expect(find.textContaining('Falta el nombre'), findsOneWidget);

    await enter(t, 'f-nombre', 'María');
    await tapKey(t, 'f-guardar');
    expect(find.textContaining('Falta el primer apellido'), findsOneWidget);

    await enter(t, 'f-apellido1', 'Rodríguez');
    await enter(t, 'f-apellido2', 'Leyva');
    await tapKey(t, 'f-guardar');
    expect(find.textContaining('Falta el sexo'), findsOneWidget);

    await pickSex(t, woman: true);
    await tapKey(t, 'f-guardar');
    expect(find.textContaining('Falta la edad'), findsOneWidget);

    await enter(t, 'f-edad', '150');
    await tapKey(t, 'f-guardar');
    expect(find.textContaining('entre 1 y 110'), findsOneWidget);

    await enter(t, 'f-edad', '27');
    await tapKey(t, 'f-guardar');
    expect(find.textContaining('Falta la iglesia'), findsOneWidget);

    // iglesia que no existe: se ofrece registrarla
    await enter(t, 'f-iglesia', 'Metodista de Colón');
    await settle(t);
    await tapKey(t, 'f-guardar');
    expect(find.textContaining('Elige la iglesia de la lista'), findsOneWidget);
    await tapKey(t, 'iglesia-nueva');
    expect(find.text('Iglesia nueva'), findsOneWidget);
    await t.tap(find.byKey(const Key('ni-provincia')));
    await settle(t);
    await t.tap(find.text('Matanzas').last);
    await settle(t);
    await pickMunicipio(t, 'Colón');
    await tapKey(t, 'ni-guardar');
    expect(find.text('Iglesia nueva'), findsNothing);
    expect(find.byIcon(Icons.check_circle),
        findsOneWidget); // iglesia seleccionada
    expect(
        find.descendant(
            of: find.byKey(const Key('f-municipio')),
            matching: find.text('Colón')),
        findsOneWidget); // municipio tomado de la iglesia (solo lectura)

    await tapKey(t, 'f-hospedaje');
    await tapKey(t, 'f-guardar');
    expect(find.textContaining('¡Bienvenida, María!'), findsOneWidget);
    expect(find.text('Quedó registrado/a como asistente nº 1'), findsOneWidget);
    expect(find.textContaining('Necesita hospedaje'), findsOneWidget);

    final row =
        (await t.runAsync(() => c.db.select(c.db.attendees).getSingle()))!;
    expect(row.sex, 'F');
    expect(row.needsLodging, isTrue);
    expect(row.municipality, 'Colón');
    expect(row.createdBy, isNotNull); // quién lo registró

    await tapKey(t, 'exito-otra');
    expect(find.text('Nuevo asistente'), findsWidgets);
    expect(
        t.widget<TextField>(find.byKey(const Key('f-nombre'))).controller!.text,
        isEmpty);
  });

  testWidgets(
      'aviso de duplicado: aparece, se puede descartar, y no bloquea guardar',
      (t) async {
    await _open(t, seed: true);
    await _goTo(t, 'Registrar');
    await enter(t, 'f-nombre', 'JUAN');
    await enter(t, 'f-apellido1', 'perez');
    await settle(t);
    expect(find.byKey(const Key('dup-aviso')), findsOneWidget);
    expect(find.textContaining('Juan Pérez García'), findsOneWidget);

    // la edad no cuenta: mismo nombre y apellidos es el aviso
    await enter(t, 'f-edad', '19');
    await settle(t);
    expect(find.byKey(const Key('dup-aviso')), findsOneWidget);
    await tapKey(t, 'dup-otra');
    expect(find.byKey(const Key('dup-aviso')), findsNothing);
  });

  testWidgets(
      'guardar con el mismo nombre y apellidos pregunta antes de guardar',
      (t) async {
    final c = await _open(t, seed: true);
    await _goTo(t, 'Registrar');
    await enter(t, 'f-nombre', 'Juan');
    await enter(t, 'f-apellido1', 'Pérez');
    await enter(t, 'f-apellido2', 'García');
    await pickSex(t, woman: false);
    await enter(t, 'f-edad', '8');
    await enter(t, 'f-iglesia', 'Bautista');
    await settle(t);
    await tapKey(t, 'iglesia-bautista ebenezer');
    await tapKey(t, 'f-guardar');
    expect(find.byKey(const Key('dup-confirmar')), findsOneWidget);
    // Cancelar: no se guardó nada
    await tapKey(t, 'dup-cancelar');
    var rows = (await t.runAsync(() => c.db.select(c.db.attendees).get()))!;
    expect(rows, hasLength(3));
    // Guardar igual: ahora sí
    await tapKey(t, 'f-guardar');
    await tapKey(t, 'dup-guardar-igual');
    rows = (await t.runAsync(() => c.db.select(c.db.attendees).get()))!;
    expect(rows, hasLength(4));
  });

  testWidgets(
      '«Guardar y registrar otro» deja el formulario limpio y numera seguido',
      (t) async {
    final c = await _open(t, seed: true);
    await _goTo(t, 'Registrar');
    await enter(t, 'f-nombre', 'Pedro');
    await enter(t, 'f-apellido1', 'Gómez');
    await enter(t, 'f-edad', '40');
    await pickSex(t, woman: false);
    await enter(t, 'f-iglesia', 'Bautista');
    await settle(t);
    await tapKey(t, 'iglesia-bautista ebenezer');
    await tapKey(t, 'f-guardar-otro');
    expect(find.textContaining('nº 4'), findsOneWidget); // seguía el 3
    expect(
        t.widget<TextField>(find.byKey(const Key('f-nombre'))).controller!.text,
        isEmpty);
    expect(
        (await t.runAsync(() => c.db.select(c.db.attendees).get()))!.length, 4);
  });

  testWidgets(
      'lista: búsqueda por nombre sin tildes, por número y sin resultados',
      (t) async {
    await _open(t, seed: true);
    await _goTo(t, 'Asistentes');
    expect(find.byKey(const Key('lista-conteo')), findsOneWidget);
    expect(find.text('3 inscritos'), findsOneWidget);
    expect(find.byKey(const Key('asistente-1')), findsOneWidget);

    await t.enterText(find.byKey(const Key('buscar')), 'rodriguez');
    await settle(t);
    expect(find.byKey(const Key('asistente-2')), findsOneWidget);
    expect(find.byKey(const Key('asistente-1')), findsNothing);
    expect(find.text('1 de 3'), findsOneWidget);

    await t.enterText(find.byKey(const Key('buscar')), '3');
    await settle(t);
    expect(find.byKey(const Key('asistente-3')), findsOneWidget);

    await t.enterText(find.byKey(const Key('buscar')), 'zzz');
    await settle(t);
    expect(find.textContaining('¿Falta registrarlo?'), findsOneWidget);
  });

  testWidgets('el panel muestra totales por sexo y hospedaje', (t) async {
    await _open(t, seed: true);
    expect(find.text('3'), findsWidgets);
    expect(find.text('2 mujeres · 1 hombres'), findsOneWidget);
    expect(find.text('Sin asignar: 1'), findsOneWidget);
  });

  testWidgets('administrador edita y elimina; el cambio se ve en la lista',
      (t) async {
    final c = await _open(t, seed: true);
    await _goTo(t, 'Asistentes');
    await tapKey(t, 'asistente-1');
    expect(find.text('Ficha del asistente'), findsOneWidget);
    expect(find.byKey(const Key('dup-aviso')),
        findsNothing); // no se avisa a sí mismo
    expect(
        t.widget<TextField>(find.byKey(const Key('f-nombre'))).controller!.text,
        'Juan');

    await enter(t, 'f-edad', '35');
    await tapKey(t, 'f-guardar');
    // escritorio: columna Edad de la tabla
    expect(find.text('35'), findsOneWidget);
    expect(find.text('34'), findsNothing);

    await tapKey(t, 'asistente-3');
    await tapKey(t, 'f-eliminar');
    await tapKey(t, 'f-confirmar-eliminar');
    expect(find.text('2 inscritos'), findsOneWidget);
    expect(
        (await t.runAsync(() => c.db.select(c.db.attendees).get()))!
            .where((a) => a.deletedAt != null)
            .length,
        1);
  });

  testWidgets(
      'el operador puede registrar y editar pero NO ve el botón de eliminar',
      (t) async {
    await _open(t, operator: true, seed: true);
    await _goTo(t, 'Asistentes');
    await tapKey(t, 'asistente-2');
    expect(find.text('Ficha del asistente'), findsOneWidget);
    expect(find.byKey(const Key('f-eliminar')), findsNothing);
    expect(find.byKey(const Key('f-guardar')), findsOneWidget);
  });
}
