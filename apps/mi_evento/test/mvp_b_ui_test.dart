import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' show OrderingTerm;
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/repos_b.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'helpers.dart';

const _pc = Size(1200, 2400);

/// Prepara datos ejecutando cada operación en su PROPIO runAsync. Drift marca la zona de una
/// transacción y una consulta posterior en la misma zona puede quedarse esperando (solo en pruebas).
Future<void> seed(WidgetTester t, List<Future<void> Function()> ops) async {
  for (final op in ops) {
    await t.runAsync(op);
  }
}

/// Lee los equipos con una consulta directa (no con `.first` sobre un stream de Drift:
/// en pruebas deja pendiente una cancelación y la siguiente transacción se queda esperando).
Future<List<TeamRow>> teamsOf(B b) => (b.c.db.select(b.c.db.teams)
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
    .get();

/// Crea [n] equipos y reparte a las personas (nº de inscripción → índice de equipo).
/// Cada operación va en su propio runAsync: en pruebas, Drift puede quedarse esperando si se
/// encadenan varias transacciones en la misma zona asíncrona.
Future<List<TeamRow>> setupTeams(WidgetTester t, B b,
    {int n = 2,
    bool allToFirst = false,
    Map<int, int> assign = const {}}) async {
  await t.runAsync(() => b.teams.createMany(b.ev, n));
  final tm = (await t.runAsync(() => teamsOf(b)))!;
  final rows = (await t.runAsync(() => b.c.db.select(b.c.db.attendees).get()))!;
  if (allToFirst) {
    await t.runAsync(() => b.teams.setTeam(rows.map((r) => r.id), tm.first.id));
  }
  for (final e in assign.entries) {
    await t.runAsync(() => b.teams.setTeam(
        [rows.firstWhere((r) => r.regNumber == e.key).id], tm[e.value].id));
  }
  return tm;
}

class B {
  B(this.c, this.ev);
  final Ctx c;
  final String ev;
  late SocialRepo social = SocialRepo(c.db);
  late LodgingRepo lodging = LodgingRepo(c.db);
  late TeamRepo teams = TeamRepo(c.db);
}

/// Evento «Retiro» con Juan (nº1, hombre), María (nº2, mujer, necesita hospedaje) y Pedro (nº3, hombre).
Future<B> _open(WidgetTester t,
    {bool operator = false, int extraMen = 0}) async {
  final c = await pumpApp(t, _pc, operator: operator);
  late String ev;
  await t.runAsync(() async {
    ev = await c.repo.createEvent(
        name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
    final ig = await c.repo.createChurch(
        name: 'Bautista Ebenezer',
        province: 'Matanzas',
        municipality: 'Cárdenas');
    Future<void> add(String n, Sex s, int age, {bool lodging = false}) =>
        c.repo.addAttendee(
            eventId: ev,
            firstName: n,
            lastName1: 'Pérez',
            sex: s,
            age: age,
            churchId: ig.id,
            needsLodging: lodging);
    await add('Juan', Sex.male, 34);
    await add('María', Sex.female, 27, lodging: true);
    await add('Pedro', Sex.male, 40);
    for (var i = 0; i < extraMen; i++) {
      await add('Hombre$i', Sex.male, 25);
    }
  });
  await login(
      t, operator ? 'ruth' : 'admin', operator ? 'ruth123' : 'secreto1');
  await t.tap(find.text('Retiro'));
  await settle(t);
  // El Panel observa hospedajes y equipos; las pruebas que escriben datos después de abrir el
  // evento lo hacen desde una pantalla sin esos flujos vivos (si no, Drift se cuelga en pruebas):
  // «Confirmar asistencia» solo observa a los asistentes (Asistentes también observa hospedajes y equipos).
  await t.tap(find.text('Confirmar asistencia').first);
  await settle(t);
  return B(c, ev);
}

Future<void> _goTo(WidgetTester t, String label) async {
  await t.tap(find.text(label).first);
  await settle(t);
}

void main() {
  testWidgets(
      'matrimonio: se vincula desde el formulario y se ve desde ambos lados',
      (t) async {
    final b = await _open(t);
    await _goTo(t, 'Asistentes');
    await tapKey(t, 'asistente-1');
    await tapKey(t, 'social-vincular');
    await t.enterText(find.byKey(const Key('pp-buscar')), 'maria');
    await settle(t);
    await tapKey(t, 'pp-2');
    expect(find.byKey(const Key('social-conyuge')), findsOneWidget);
    expect(find.text('Matrimonio con María Pérez'), findsOneWidget);
    await tapKey(t, 'f-guardar');

    await tapKey(t, 'asistente-2');
    expect(find.text('Matrimonio con Juan Pérez'), findsOneWidget);
    // quien ya está casado no se ofrece para vincular a otra persona
    await tapKey(t, 'social-quitar-conyuge');
    await tapKey(t, 'f-guardar');
    final rows =
        (await t.runAsync(() => b.c.db.select(b.c.db.attendees).get()))!;
    final juan = rows.firstWhere((r) => r.regNumber == 1);
    expect(await t.runAsync(() => b.social.spouseOf(juan.id)), isNull);
  });

  testWidgets('el selector de matrimonio no ofrece a quien ya está casado',
      (t) async {
    final b = await _open(t);
    await t.runAsync(() async {
      final rows = await b.c.db.select(b.c.db.attendees).get();
      await b.social.setSpouse(rows.firstWhere((r) => r.regNumber == 1).id,
          rows.firstWhere((r) => r.regNumber == 2).id);
    });
    await _goTo(t, 'Asistentes');
    await tapKey(t, 'asistente-3'); // Pedro, soltero
    await tapKey(t, 'social-vincular');
    expect(find.byKey(const Key('pp-1')), findsNothing);
    expect(find.byKey(const Key('pp-2')), findsNothing);
    expect(find.byKey(const Key('pp-3')), findsNothing); // ni a sí mismo
  });

  testWidgets('grupos: crear uno nuevo desde el formulario y asignarlo',
      (t) async {
    final b = await _open(t);
    await _goTo(t, 'Asistentes');
    await tapKey(t, 'asistente-1');
    await tapKey(t, 'social-grupos');
    await enter(t, 'gp-nuevo-nombre', 'Jóvenes de Colón');
    await tapKey(t, 'gp-crear');
    await enter(t, 'gp-nuevo-nombre', 'jovenes de colon'); // repetido
    await tapKey(t, 'gp-crear');
    expect(find.textContaining('Ya existe un grupo'), findsOneWidget);
    await tapKey(t, 'gp-listo');
    expect(
        find.byKey(const Key('social-grupo-Jóvenes de Colón')), findsOneWidget);
    await tapKey(t, 'f-guardar');
    final g =
        (await t.runAsync(() => b.social.watchGroups(b.ev).first))!.single;
    expect(g.memberCount, 1);
  });

  testWidgets('hospedaje: alta con validaciones y aparece en la lista',
      (t) async {
    await _open(t);
    await _goTo(t, 'Hospedajes');
    expect(find.textContaining('Todavía no hay hospedajes'), findsOneWidget);
    await tapKey(t, 'hosp-nuevo');
    await tapKey(t, 'lf-guardar');
    expect(find.textContaining('Falta la capacidad'), findsOneWidget);
    await enter(t, 'lf-capacidad', '3');
    await tapKey(t, 'lf-guardar');
    expect(
        find.textContaining('Falta el nombre del hospedaje'), findsOneWidget);
    await enter(t, 'lf-nombre', 'Casa de Ramón');
    await t.tap(find.text('Casa particular'));
    await t.pump();
    await enter(t, 'lf-cerca', 'A 300 m del templo');
    await tapKey(t, 'lf-guardar');
    expect(find.byKey(const Key('hosp-Casa de Ramón')), findsOneWidget);
    // escritorio: tabla con Capacidad/Ocupadas/Libres
    expect(find.text('Capacidad'), findsOneWidget);
    expect(find.textContaining('A 300 m del templo'), findsOneWidget);
    expect(find.textContaining('1 persona sin hospedaje'),
        findsOneWidget); // María lo necesita
  });

  testWidgets(
      'hospedaje: asignar a una mujer a «solo hombres» avisa y deja continuar',
      (t) async {
    final b = await _open(t);
    await t.runAsync(() => b.lodging.save(
        eventId: b.ev,
        name: 'Casa de Ramón',
        kind: 'private_home',
        capacity: 3,
        accepts: LodgingAccepts.men));
    await _goTo(t, 'Hospedajes');
    await tapKey(t, 'hosp-Casa de Ramón');
    await tapKey(t, 'hd-asignar');
    await tapKey(t, 'as-2'); // María (necesita hospedaje)
    expect(find.text('1 seleccionada · plazas libres: 3'), findsOneWidget);
    await tapKey(t, 'as-confirmar');
    expect(find.byKey(const Key('hd-aviso')), findsOneWidget);
    expect(find.textContaining('solo acepta hombres'), findsOneWidget);

    await tapKey(t, 'hd-revisar'); // revisar: no se asigna
    expect(find.byKey(const Key('hd-persona-2')), findsNothing);

    await tapKey(t, 'hd-asignar');
    await tapKey(t, 'as-2');
    await tapKey(t, 'as-confirmar');
    await tapKey(t, 'hd-continuar');
    expect(find.byKey(const Key('hd-persona-2')), findsOneWidget);
    expect(find.text('1 de 3 ocupadas'), findsOneWidget);

    await tapKey(t, 'hd-quitar-2');
    expect(find.byKey(const Key('hd-persona-2')), findsNothing);
  });

  testWidgets('hospedaje: pasarse de la capacidad avisa con los números',
      (t) async {
    final b = await _open(t);
    await t.runAsync(() => b.lodging.save(
        eventId: b.ev,
        name: 'Cuarto',
        kind: 'shelter',
        capacity: 1,
        accepts: LodgingAccepts.men));
    await _goTo(t, 'Hospedajes');
    await tapKey(t, 'hosp-Cuarto');
    await tapKey(t, 'hd-asignar');
    await tapKey(t, 'as-solo-pendientes'); // mostrar a todos
    await tapKey(t, 'as-1');
    await tapKey(t, 'as-3');
    await tapKey(t, 'as-confirmar');
    expect(find.textContaining('quedaría con 2 personas y solo tiene 1 plazas'),
        findsOneWidget);
    await tapKey(t, 'hd-continuar');
    expect(find.textContaining('sobrecupo de 1'), findsOneWidget);
  });

  testWidgets(
      'hospedaje «matrimonios»: marcar a uno arrastra a su cónyuge y no avisa',
      (t) async {
    final b = await _open(t);
    // Dos bloques separados: en pruebas, Drift se queda esperando si tras setSpouse se consulta en la misma zona.
    await t.runAsync(() async {
      final rows = await b.c.db.select(b.c.db.attendees).get();
      await b.social.setSpouse(rows.firstWhere((r) => r.regNumber == 1).id,
          rows.firstWhere((r) => r.regNumber == 2).id);
    });
    await t.runAsync(() => b.lodging.save(
        eventId: b.ev,
        name: 'Casa de Teresa',
        kind: 'private_home',
        capacity: 4,
        accepts: LodgingAccepts.couples));
    await _goTo(t, 'Hospedajes');
    await tapKey(t, 'hosp-Casa de Teresa');
    await tapKey(t, 'hd-asignar');
    await tapKey(t, 'as-solo-pendientes');
    await tapKey(t, 'as-1'); // Juan → también marca a María
    expect(find.text('2 seleccionadas · plazas libres: 4'), findsOneWidget);
    await tapKey(t, 'as-confirmar');
    expect(find.byKey(const Key('hd-aviso')), findsNothing);
    expect(find.byKey(const Key('hd-persona-1')), findsOneWidget);
    expect(find.byKey(const Key('hd-persona-2')), findsOneWidget);
  });

  testWidgets(
      'hospedaje: un grupo completo se asigna de una vez; imprimir ofrece PDF e impresora',
      (t) async {
    final b = await _open(t);
    await t.runAsync(() async {
      final rows = await b.c.db.select(b.c.db.attendees).get();
      final g = await b.social.createGroup(b.ev, 'Asamblea Jovellanos');
      for (final r in rows.where((r) => r.regNumber != 2)) {
        await b.social.setGroups(r.id, {g.id});
      }
      await b.lodging.save(
          eventId: b.ev,
          name: 'Albergue',
          kind: 'shelter',
          capacity: 10,
          accepts: LodgingAccepts.men);
    });
    await _goTo(t, 'Hospedajes');
    await tapKey(t, 'hosp-Albergue');
    await tapKey(t, 'hd-asignar');
    await tapKey(t, 'as-solo-pendientes');
    await tapKey(t, 'as-grupo');
    await tapKey(t, 'as-grupo-Asamblea Jovellanos');
    expect(find.text('2 seleccionadas · plazas libres: 10'), findsOneWidget);
    await tapKey(t, 'as-confirmar');
    expect(find.byKey(const Key('hd-persona-1')), findsOneWidget);
    expect(find.byKey(const Key('hd-persona-3')), findsOneWidget);

    await tapKey(t, 'hd-imprimir');
    expect(find.text('Lista de Albergue'), findsOneWidget);
    expect(find.byKey(const Key('pr-pdf')), findsOneWidget);
    expect(find.byKey(const Key('pr-imprimir')), findsOneWidget);
    expect(
        t.widget<CheckboxListTile>(find.byKey(const Key('pr-telefono'))).value,
        isFalse); // teléfono desactivado por defecto
  });

  testWidgets(
      'equipos: crear, asignar con vista previa y aviso de desbalance (criterio C)',
      (t) async {
    final b = await _open(t, extraMen: 4); // 6 hombres y 1 mujer
    await _goTo(t, 'Equipos');
    expect(find.byKey(const Key('eq-vacio')), findsOneWidget);
    await tapKey(t, 'eq-crear');
    await tapKey(t, 'eq-crear-ok');
    expect(find.byKey(const Key('equipo-Rojo')), findsOneWidget);
    expect(find.byKey(const Key('equipo-Azul')), findsOneWidget);
    expect(find.textContaining('7 sin equipo'), findsOneWidget);

    // primera asignación: Pedro (nº3) a Rojo → ya hay desbalance de tamaño? 1 vs 0 no (tope 2)
    await tapKey(t, 'asignar-3');
    await tapKey(t, 'tr-Rojo');
    expect(find.byKey(const Key('mv-ok')), findsOneWidget);
    expect(find.text('0H·0M  →  1H·0M (40.0)'), findsOneWidget);
    await tapKey(t, 'mv-confirmar');
    expect(find.byKey(const Key('equipo-Rojo-n')), findsOneWidget);
    expect(t.widget<Text>(find.byKey(const Key('equipo-Rojo-n'))).data, '1');

    // seguir llevando hombres a Rojo hasta pasar el tope de sexo (4) y de tamaño (2)
    for (final n in [1, 4, 5, 6]) {
      await tapKey(t, 'asignar-$n');
      await tapKey(t, 'tr-Rojo');
      if (find.byKey(const Key('mv-aviso')).evaluate().isNotEmpty) {
        expect(
            find.descendant(
                of: find.byType(AlertDialog),
                matching: find.textContaining('Tamaño: Rojo')),
            findsOneWidget);
        expect(find.textContaining('Puedes continuar si es necesario'),
            findsOneWidget);
        expect(find.text('Trasladar de todas formas'), findsOneWidget);
      }
      await tapKey(t, 'mv-confirmar');
    }
    expect(find.byKey(const Key('eq-aviso')), findsOneWidget);
    expect(
        find.textContaining(
            'Sexo: Rojo tiene 5 hombres y 0 mujeres (diferencia 5, máximo 4)'),
        findsOneWidget);
    expect(
        (await t.runAsync(() => b.c.db.select(b.c.db.attendees).get()))!
            .where((a) => a.teamId != null)
            .length,
        5);
  });

  testWidgets(
      'equipos: cancelar el traslado no cambia nada; trasladar y quitar capitán',
      (t) async {
    final b = await _open(t);
    await setupTeams(t, b, allToFirst: true);
    await _goTo(t, 'Equipos');
    await tapKey(t, 'trasladar-2');
    await tapKey(t, 'tr-Azul');
    await tapKey(t, 'mv-cancelar');
    final teamsNow = (await t.runAsync(() => teamsOf(b)))!;
    final rowsNow =
        (await t.runAsync(() => b.c.db.select(b.c.db.attendees).get()))!;
    expect(rowsNow.every((a) => a.teamId == teamsNow.first.id),
        isTrue); // nada cambió al cancelar
    await tapKey(t, 'trasladar-2');
    await tapKey(t, 'tr-Azul');
    await tapKey(t, 'mv-confirmar');
    expect(t.widget<Text>(find.byKey(const Key('equipo-Azul-n'))).data, '1');
    expect(t.widget<Text>(find.byKey(const Key('equipo-Rojo-n'))).data, '2');
  });

  testWidgets(
      'equipos: editar nombre, color y capitán; el nombre repetido se rechaza',
      (t) async {
    final b = await _open(t);
    await setupTeams(t, b, assign: {1: 0});
    await _goTo(t, 'Equipos');
    await tapKey(t, 'equipo-Rojo-menu');
    await t.tap(find.text('Editar nombre, color y capitán'));
    await settle(t);
    await enter(t, 'te-nombre', 'azul');
    await tapKey(t, 'te-guardar');
    expect(find.textContaining('Ya existe un equipo'), findsOneWidget);
    await enter(t, 'te-nombre', 'Los Leones');
    await tapKey(t, 'te-capitan');
    await t.tap(find.text('Juan Pérez').last);
    await settle(t);
    await tapKey(t, 'te-guardar');
    expect(find.byKey(const Key('equipo-Los Leones')), findsOneWidget);
    expect(find.textContaining('Capitán: Juan Pérez'), findsOneWidget);
  });

  testWidgets('equipos: intercambiar a dos personas con vista previa',
      (t) async {
    final b = await _open(t);
    final tm = await setupTeams(t, b, assign: {1: 0, 2: 1});
    await _goTo(t, 'Equipos');
    await tapKey(t, 'eq-intercambiar');
    await tapKey(t, 'pp-1');
    await tapKey(t, 'pp-2'); // solo se ofrecen personas de OTRO equipo
    expect(find.text('Confirmar intercambio'), findsOneWidget);
    expect(find.byKey(const Key('prev-Rojo')), findsOneWidget);
    await tapKey(t, 'mv-confirmar');
    final after =
        (await t.runAsync(() => b.c.db.select(b.c.db.attendees).get()))!;
    expect(after.firstWhere((r) => r.regNumber == 1).teamId, tm[1].id);
    expect(after.firstWhere((r) => r.regNumber == 2).teamId, tm[0].id);
  });

  testWidgets(
      'equipos: los topes de balance se editan por evento y cambian los avisos',
      (t) async {
    final b = await _open(t, extraMen: 3);
    await setupTeams(t, b, allToFirst: true);
    await _goTo(t, 'Equipos');
    expect(find.byKey(const Key('eq-aviso')), findsOneWidget);
    await tapKey(t, 'eq-topes');
    await enter(t, 'lim-tamano', '10');
    await enter(t, 'lim-sexo', '10');
    await enter(t, 'lim-edad', '40');
    await tapKey(t, 'lim-guardar');
    expect(find.byKey(const Key('eq-balanceados')), findsOneWidget);
    expect(find.byKey(const Key('eq-aviso')), findsNothing);
  });

  testWidgets(
      'arrastrar a una persona de un equipo a otro (PC) abre la confirmación',
      (t) async {
    final b = await _open(t);
    await setupTeams(t, b, allToFirst: true);
    await _goTo(t, 'Equipos');
    final from = t.getCenter(find.byKey(const Key('miembro-1')));
    final to = t.getCenter(find.byKey(const Key('equipo-Azul')));
    final g = await t.startGesture(from);
    await t.pump(const Duration(milliseconds: 100));
    await g.moveTo(to, timeStamp: const Duration(milliseconds: 300));
    await t.pump(const Duration(milliseconds: 100));
    await g.up();
    await settle(t);
    expect(find.text('Confirmar traslado'), findsOneWidget);
    await tapKey(t, 'mv-confirmar');
    expect(t.widget<Text>(find.byKey(const Key('equipo-Azul-n'))).data, '1');
  });

  testWidgets(
      'el operador registra y asigna, pero no puede eliminar hospedajes ni equipos',
      (t) async {
    final b = await _open(t, operator: true);
    await t.runAsync(() => b.lodging.save(
        eventId: b.ev,
        name: 'Albergue',
        kind: 'shelter',
        capacity: 5,
        accepts: LodgingAccepts.men));
    await t.runAsync(() => b.teams.createMany(b.ev, 1));
    await _goTo(t, 'Hospedajes');
    await tapKey(t, 'hosp-Albergue');
    expect(find.byKey(const Key('hd-eliminar')), findsNothing);
    expect(find.byKey(const Key('hd-asignar')), findsOneWidget);
    await t.pageBack();
    await settle(t);
    await _goTo(t, 'Equipos');
    await tapKey(t, 'equipo-Rojo-menu');
    expect(find.text('Eliminar equipo'), findsNothing);
    expect(find.text('Editar nombre, color y capitán'), findsOneWidget);
  });
}
