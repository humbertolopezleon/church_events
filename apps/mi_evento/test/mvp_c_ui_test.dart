import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento/data/meal_repo.dart';
import 'package:mi_evento/data/repos_b.dart';
import 'package:mi_evento/export/file_saver.dart';
import 'package:mi_evento/providers.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'helpers.dart';

const _pc = Size(1200, 2400);

class C {
  C(this.c, this.ev, this.saver);
  final Ctx c;
  final String ev;
  final MemoryFileSaver saver;
  late MealRepo meals = MealRepo(c.db);
}

/// Evento con Juan (nº1), María (nº2) y Pedro (nº3); abre «Comidas».
Future<C> _open(WidgetTester t,
    {bool operator = false,
    Size size = _pc,
    bool withTeams = false,
    List<String> extraTypes = const []}) async {
  final saver = MemoryFileSaver();
  final c = await pumpApp(t, size,
      operator: operator,
      overrides: [fileSaverProvider.overrideWithValue(saver)]);
  late String ev;
  await t.runAsync(() async {
    ev = await c.repo.createEvent(
        name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
    final ig = await c.repo
        .createChurch(name: 'Bautista Ebenezer', province: 'Matanzas');
    for (final (n, s, a) in [
      ('Juan', Sex.male, 34),
      ('María', Sex.female, 27),
      ('Pedro', Sex.male, 40)
    ]) {
      await c.repo.addAttendee(
          eventId: ev,
          firstName: n,
          lastName1: 'Pérez',
          sex: s,
          age: a,
          churchId: ig.id);
    }
  });
  if (extraTypes.isNotEmpty) {
    // Se preparan ANTES de abrir la pantalla: escribir en la base desde la prueba mientras las
    // consultas en vivo de la pantalla se actualizan deja la prueba esperando.
    final meals = MealRepo(c.db);
    await t.runAsync(() => meals.ensureDefaultTypes(ev));
    for (final n in extraTypes) {
      await t.runAsync(() => meals.createType(ev, n));
    }
  }
  if (withTeams) {
    final tr = TeamRepo(c.db);
    await t.runAsync(() => tr.createMany(ev, 2));
    final teams = (await t.runAsync(() => c.db.select(c.db.teams).get()))!;
    final rows = (await t.runAsync(() => c.db.select(c.db.attendees).get()))!;
    await t.runAsync(() => tr.setTeam([rows[0].id, rows[1].id], teams[0].id));
    await t.runAsync(() => tr.setTeam([rows[2].id], teams[1].id));
  }
  await login(
      t, operator ? 'ruth' : 'admin', operator ? 'ruth123' : 'secreto1');
  await t.tap(find.text('Retiro'));
  await settle(t);
  await t.tap(find.text('Comidas').first);
  await settle(t);
  return C(c, ev, saver);
}

Future<void> _newSession(WidgetTester t) async {
  await tapKey(t, 'cm-nueva');
  await tapKey(t, 'ns-crear');
}

Future<void> _search(WidgetTester t, String text) async {
  await t.enterText(find.byKey(const Key('cm-buscar')), text);
  await settle(t);
}

/// Valor grande de una tarjeta de contador: la 2.ª etiqueta de texto (la 1.ª es el título).
String _n(WidgetTester t, String key) => t
    .widget<Text>(find
        .descendant(of: find.byKey(Key(key)), matching: find.byType(Text))
        .at(1))
    .data!;

void main() {
  testWidgets(
      'sin sesiones: invita a crear; el nombre se sugiere con el día y los contadores arrancan en cero',
      (t) async {
    await _open(t);
    expect(find.byKey(const Key('cm-vacio')), findsOneWidget);
    await tapKey(t, 'cm-nueva');
    final sugerido = suggestSessionName('Almuerzo', DateTime.now());
    expect(
        t
            .widget<TextField>(find.byKey(const Key('ns-nombre')))
            .controller!
            .text,
        sugerido);
    await tapKey(t, 'ns-crear');
    expect(find.byKey(const Key('cm-vacio')), findsNothing);
    expect(_n(t, 'cm-inscritos'), '3');
    expect(_n(t, 'cm-pasaron'), '0');
    expect(_n(t, 'cm-faltan-n'), '3');
  });

  testWidgets(
      'marcar por nombre sin tildes: confirma, cuenta y se puede deshacer',
      (t) async {
    await _open(t);
    await _newSession(t);
    await _search(t, 'maria');
    await tapKey(t, 'cm-marcar-2');
    expect(find.text('Puede almorzar: María Pérez'), findsOneWidget);
    expect(_n(t, 'cm-pasaron'), '1');
    expect(_n(t, 'cm-faltan-n'), '2');
    expect(
        t
            .widget<TextField>(find.byKey(const Key('cm-buscar')))
            .controller!
            .text,
        isEmpty); // listo para el siguiente
    expect(find.byKey(const Key('cm-ultimo-2')), findsOneWidget);

    await tapKey(t, 'cm-deshacer');
    expect(_n(t, 'cm-pasaron'), '0');
    expect(find.byKey(const Key('cm-ok')), findsNothing);
  });

  testWidgets(
      'marcar por número de inscripción y con Enter (marca al primero de la lista)',
      (t) async {
    await _open(t);
    await _newSession(t);
    await _search(t, '3');
    expect(find.byKey(const Key('cm-res-3')), findsOneWidget);
    expect(find.byKey(const Key('cm-res-1')), findsNothing);
    await t.testTextInput.receiveAction(TextInputAction.done);
    await settle(t);
    expect(find.text('Puede almorzar: Pedro Pérez'), findsOneWidget);
    expect(_n(t, 'cm-pasaron'), '1');
  });

  testWidgets(
      '«ya pasó»: avisa con hora y operador; «Entendido» no marca y cuenta el repetido evitado',
      (t) async {
    final x = await _open(t);
    await _newSession(t);
    await _search(t, 'juan');
    await tapKey(t, 'cm-marcar-1');
    await _search(t, 'juan');
    expect(find.textContaining('pasó '),
        findsWidgets); // en la lista ya se ve que pasó
    await t.tap(find.byKey(const Key('cm-res-1')));
    await settle(t);
    expect(find.byKey(const Key('cm-ya-paso')), findsOneWidget);
    expect(find.textContaining('YA PASÓ'), findsOneWidget);
    expect(find.textContaining('Juan Pérez ya almorzó a las'), findsOneWidget);
    expect(find.text('Ana Admin'), findsOneWidget); // quién lo marcó
    expect(find.text('Bautista Ebenezer'), findsWidgets);

    await tapKey(t, 'cm-entendido');
    expect(_n(t, 'cm-pasaron'), '1');
    final s =
        (await t.runAsync(() => x.meals.watchSessions(x.ev).first))!.single;
    expect(s.row.blockedRepeats, 1);
    expect(
        (await t.runAsync(() => x.meals.watchRecords(s.row.id).first))!.length,
        1);
  });

  testWidgets(
      '«Marcar otra vez de todas formas»: se registra como repetido y NO aumenta a los que pasaron',
      (t) async {
    final x = await _open(t);
    await _newSession(t);
    await _search(t, 'juan');
    await tapKey(t, 'cm-marcar-1');
    await _search(t, 'juan');
    await t.tap(find.byKey(const Key('cm-res-1')));
    await settle(t);
    await tapKey(t, 'cm-repetir');
    expect(find.text('Marcado otra vez: Juan Pérez'), findsOneWidget);
    expect(_n(t, 'cm-pasaron'), '1'); // sigue siendo una persona
    final s =
        (await t.runAsync(() => x.meals.watchSessions(x.ev).first))!.single;
    final recs =
        (await t.runAsync(() => x.meals.watchRecords(s.row.id).first))!;
    expect(recs.length, 2);
    expect(recs.where((r) => r.repeatOverride).length, 1);
  });

  testWidgets(
      'el operador queda registrado con el nombre del usuario con sesión',
      (t) async {
    final x = await _open(t, operator: true);
    await _newSession(t);
    await _search(t, 'pedro');
    await tapKey(t, 'cm-marcar-3');
    final s =
        (await t.runAsync(() => x.meals.watchSessions(x.ev).first))!.single;
    final r =
        (await t.runAsync(() => x.meals.watchRecords(s.row.id).first))!.single;
    expect(r.operatorName, 'Ruth M.');
  });

  testWidgets('pendientes: lista a quienes faltan y se puede filtrar',
      (t) async {
    await _open(t);
    await _newSession(t);
    await _search(t, 'juan');
    await tapKey(t, 'cm-marcar-1');
    await tapKey(t, 'cm-faltan');
    expect(find.text('Faltan (2)'), findsOneWidget);
    expect(find.byKey(const Key('pend-2')), findsOneWidget);
    expect(find.byKey(const Key('pend-3')), findsOneWidget);
    expect(find.byKey(const Key('pend-1')), findsNothing); // Juan ya pasó
    await t.enterText(find.byKey(const Key('pend-buscar')), 'pedro');
    await settle(t);
    expect(find.byKey(const Key('pend-2')), findsNothing);
    expect(find.byKey(const Key('pend-3')), findsOneWidget);
  });

  testWidgets('cerrar la sesión: resumen, bloqueo de marcas, reabrir',
      (t) async {
    final x = await _open(t, withTeams: true);
    await _newSession(t);
    for (final (q, n) in [('juan', 1), ('maria', 2)]) {
      await _search(t, q);
      await tapKey(t, 'cm-marcar-$n');
    }
    await tapKey(t, 'cm-cerrar');
    await tapKey(t, 'cm-cerrar-ok');
    // resumen
    expect(_n(t, 'res-inscritos'), '3');
    expect(_n(t, 'res-pasaron'), '2');
    expect(_n(t, 'res-no-pasaron'), '1');
    expect(find.text('2 / 2'), findsOneWidget); // equipo Rojo: Juan y María
    expect(find.text('0 / 1'), findsOneWidget); // equipo Azul: Pedro no pasó
    await pageBack(t);
    await settle(t);
    // la sesión cerrada ya no deja marcar
    expect(find.byKey(const Key('cm-cerrada')), findsOneWidget);
    expect(find.byKey(const Key('cm-buscar')), findsNothing);
    await tapKey(t, 'cm-reabrir');
    expect(find.byKey(const Key('cm-buscar')), findsOneWidget);
    final s =
        (await t.runAsync(() => x.meals.watchSessions(x.ev).first))!.single;
    expect(s.closed, isFalse);
  });

  testWidgets(
      'exportar: Excel, CSV e imagen se entregan con el nombre correcto y el contenido esperado',
      (t) async {
    final x = await _open(t, withTeams: true);
    await _newSession(t);
    for (final (q, n) in [('juan', 1), ('maria', 2)]) {
      await _search(t, q);
      await tapKey(t, 'cm-marcar-$n');
    }
    await tapKey(t, 'cm-cerrar');
    await tapKey(t, 'cm-cerrar-ok');

    await tapKey(t, 'ex-csv');
    await tapKey(t, 'ex-excel');
    await tapKey(t, 'ex-imagen');
    for (var i = 0; i < 6; i++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 150)));
      await t.pump();
    }
    final names = x.saver.saved.keys.toList()..sort();
    expect(names.length, 3, reason: names.toString());
    expect(names.every((n) => n.startsWith('retiro-')), isTrue);
    final csv = names.firstWhere((n) => n.endsWith('.csv'));
    final xlsx = names.firstWhere((n) => n.endsWith('.xlsx'));
    final png = names.firstWhere((n) => n.endsWith('.png'));
    final text = utf8.decode(x.saver.saved[csv]!);
    expect(text, contains('Juan Pérez'));
    expect(text, contains('Pedro Pérez;Hombre;40;Bautista Ebenezer;Azul;No'));
    final a = ZipDecoder().decodeBytes(x.saver.saved[xlsx]!);
    expect(a.findFile('xl/worksheets/sheet3.xml'), isNotNull);
    expect(x.saver.saved[png]!.take(4).toList(), [137, 80, 78, 71]);
    expect(find.text('Listo. Archivo exportado.'), findsWidgets);
  });

  testWidgets(
      'tipos de control: añadir, repetido y eliminar solo si no tienen sesiones',
      (t) async {
    await _open(t);
    await _newSession(t); // crea una sesión de «Almuerzo»
    await tapKey(t, 'cm-tipos');
    expect(find.byKey(const Key('tp-Desayuno')), findsOneWidget);
    expect(find.byKey(const Key('tp-Almuerzo')), findsOneWidget);
    expect(find.byKey(const Key('tp-Cena')), findsOneWidget);
    await enter(t, 'tp-nombre', 'Entrega de materiales');
    await tapKey(t, 'tp-agregar');
    expect(find.byKey(const Key('tp-Entrega de materiales')), findsOneWidget);
    await enter(t, 'tp-nombre', 'entrega de MATERIALES');
    await tapKey(t, 'tp-agregar');
    expect(find.textContaining('Ya existe el tipo'), findsOneWidget);
    await tapKey(t, 'tp-eliminar-Almuerzo');
    expect(find.textContaining('ya tiene sesiones'), findsOneWidget);
    await tapKey(t, 'tp-eliminar-Entrega de materiales');
    expect(find.byKey(const Key('tp-Entrega de materiales')), findsNothing);
  });

  testWidgets('un tipo que no es comida usa textos neutros', (t) async {
    await _open(t, extraTypes: ['Entrega de materiales']);
    await tapKey(t, 'cm-nueva');
    await tapKey(t, 'ns-tipo');
    await t.tap(find.text('Entrega de materiales').last);
    await settle(t);
    expect(
        t
            .widget<TextField>(find.byKey(const Key('ns-nombre')))
            .controller!
            .text,
        startsWith('Entrega de materiales del '));
    await tapKey(t, 'ns-crear');
    await _search(t, 'juan');
    await tapKey(t, 'cm-marcar-1');
    expect(find.text('Puede pasar: Juan Pérez'), findsOneWidget);
  });

  testWidgets('sesión con nombre repetido se rechaza', (t) async {
    await _open(t);
    await _newSession(t);
    await tapKey(t, 'cm-nueva');
    await tapKey(t, 'ns-crear');
    expect(find.textContaining('Ya existe una sesión'), findsOneWidget);
  });

  testWidgets('en móvil (390 px) también se puede marcar', (t) async {
    await _open(t, size: const Size(390, 1400));
    await _newSession(t);
    await _search(t, 'pedro');
    await tapKey(t, 'cm-marcar-3');
    expect(_n(t, 'cm-pasaron'), '1');
  });
}
