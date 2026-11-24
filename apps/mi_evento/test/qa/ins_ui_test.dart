// QA · Inscripción por la interfaz real (ancho de PC 1200×2400 y de móvil 400×900).
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import '../helpers.dart';
import 'qa_support.dart';
import 'qa_ui_support.dart';

Future<List<AttendeeRow>> _rows(WidgetTester t, QaApp a) => qaRows(
    t,
    () => a.q
        .people()
        .then((l) => l..sort((x, y) => x.regNumber.compareTo(y.regNumber))));

void main() {
  group('validaciones del formulario (PC)', () {
    testWidgets(
        'QA-INS-001/002 · cada dato obligatorio da su mensaje en español, no se guarda nada hasta completarlo, y las edades límite 1 y 110 sí se guardan',
        (t) async {
      final a = await qaOpen(t, qaPc);
      await tapKey(t, 'f-guardar');
      expect(find.textContaining('Falta el nombre'), findsOneWidget);

      await enter(t, 'f-nombre', '     '); // solo espacios
      await tapKey(t, 'f-guardar');
      expect(find.textContaining('Falta el nombre'), findsOneWidget);

      await enter(t, 'f-nombre', 'Lázara');
      await enter(t, 'f-apellido1', '   ');
      await tapKey(t, 'f-guardar');
      expect(find.textContaining('Falta el primer apellido'), findsOneWidget);

      await enter(t, 'f-apellido1', 'Núñez');
      await tapKey(t, 'f-guardar');
      expect(find.textContaining('Falta el sexo'), findsOneWidget);

      await pickSex(t, woman: true);
      for (final (txt, msg) in [
        ('', 'Falta la edad'),
        ('abc', 'Falta la edad'),
        ('0', 'entre 1 y 110'),
        ('111', 'entre 1 y 110'),
        ('-5', 'entre 1 y 110'),
        ('999999', 'entre 1 y 110'),
      ]) {
        await enter(t, 'f-edad', txt);
        await tapKey(t, 'f-guardar');
        expect(find.textContaining(msg), findsOneWidget, reason: 'edad «$txt»');
      }
      await enter(t, 'f-edad', '25');
      await tapKey(t, 'f-guardar');
      expect(find.textContaining('Falta la iglesia'), findsOneWidget);
      expect((await _rows(t, a)), isEmpty);
      // Edades límite válidas: 1 y 110 se guardan (QA-INS-002).
      await enter(t, 'f-edad', '1');
      await enter(t, 'f-iglesia', 'Bautista');
      await settle(t);
      await tapKey(t, 'iglesia-bautista ebenezer');
      await tapKey(t, 'f-guardar-otro');
      await qaFill(t, first: 'Abuela', last1: 'Báez', woman: true, age: '110');
      await tapKey(t, 'f-guardar');
      expect(find.byKey(const Key('exito-numero')), findsOneWidget);
      expect((await _rows(t, a)).map((r) => r.age), [1, 110]);
    });
  });

  group('datos especiales (tildes, ñ, apóstrofes, nombres largos)', () {
    testWidgets(
        'QA-INS-003 · tildes, ñ y apóstrofe se guardan tal cual, se encuentran sin tildes y no hay desbordes (PC)',
        (t) async {
      final a = await qaOpen(t, qaPc);
      final casos = [
        ('Ángel', 'Muñoz', 'Piñeiro', false),
        ('Ñuri', "O'Farrill", 'Quiñones', true),
        ('María José', 'de la Peña', 'Ibáñez', true),
      ];
      for (final (i, c) in casos.indexed) {
        await qaFill(t,
            first: c.$1,
            last1: c.$2,
            last2: c.$3,
            woman: c.$4,
            age: '${30 + i}');
        await tapKey(t, i == casos.length - 1 ? 'f-guardar' : 'f-guardar-otro');
      }
      expect(t.takeException(), isNull);
      final rows = await _rows(t, a);
      expect(rows.map((r) => r.firstName), ['Ángel', 'Ñuri', 'María José']);
      expect(rows[1].lastName1, "O'Farrill");
      // Lista: búsqueda sin tildes ni mayúsculas
      await qaGoTo(t, 'Asistentes');
      await t.enterText(find.byKey(const Key('buscar')), "nuri o'farrill");
      await settle(t);
      expect(find.byKey(const Key('asistente-2')), findsOneWidget);
      await t.enterText(find.byKey(const Key('buscar')), 'MUÑOZ');
      await settle(t);
      expect(find.byKey(const Key('asistente-1')), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets(
        'QA-INS-005 · teléfono y observaciones se guardan, y al editar reaparecen igual',
        (t) async {
      final a = await qaOpen(t, qaPc);
      await qaFill(t,
          first: 'Rosa',
          last1: 'Leyva',
          woman: true,
          age: '41',
          phone: '+53 5 123 4567',
          notes: 'Alérgica a la penicilina\nNecesita planta baja');
      await tapKey(t, 'f-guardar');
      final r = (await _rows(t, a)).single;
      expect(r.phone, '+53 5 123 4567');
      expect(r.notes, 'Alérgica a la penicilina\nNecesita planta baja');
      await qaGoTo(t, 'Asistentes');
      await tapKey(t, 'asistente-1');
      expect(
          t
              .widget<TextField>(find.byKey(const Key('f-telefono')))
              .controller!
              .text,
          '+53 5 123 4567');
      expect(
          t
              .widget<TextField>(find.byKey(const Key('f-observaciones')))
              .controller!
              .text,
          contains('planta baja'));
      // Observación: el teléfono no se valida (acepta cualquier texto).
      await enter(t, 'f-telefono', 'no tiene');
      await tapKey(t, 'f-guardar');
      expect((await _rows(t, a)).single.phone, 'no tiene');
    });
  });

  group('duplicados, otro registro y numeración', () {
    testWidgets(
        'QA-INS-010 · posible duplicado: avisa con el nombre existente, se descarta con «es otra persona», se guarda igual; tildes y mayúsculas coinciden y otro apellido no',
        (t) async {
      final a = await qaOpen(t, qaPc, prepare: (q) async {
        await qaInscribe(
            q,
            QaPerson(
                first: 'José',
                last1: 'Núñez',
                last2: 'García',
                sex: Sex.male,
                age: 34,
                churchIdx: 0,
                needsLodging: false));
      });
      await enter(t, 'f-nombre', 'Jose');
      await enter(t, 'f-apellido1', 'Rodríguez');
      await settle(t);
      expect(find.byKey(const Key('dup-aviso')), findsNothing);
      await enter(t, 'f-nombre', 'JOSÉ');
      await enter(t, 'f-apellido1', 'nunez'); // sin tilde y en minúsculas
      await settle(t);
      expect(find.byKey(const Key('dup-aviso')), findsOneWidget);
      expect(find.textContaining('José Núñez García'), findsOneWidget);
      await tapKey(t, 'dup-otra'); // «es otra persona»
      expect(find.byKey(const Key('dup-aviso')), findsNothing);
      await pickSex(t, woman: false);
      await enter(t, 'f-edad', '34');
      await enter(t, 'f-iglesia', 'Bautista');
      await settle(t);
      await tapKey(t, 'iglesia-bautista ebenezer');
      await tapKey(t, 'f-guardar');
      final rows = await _rows(t, a);
      expect(rows.length, 2); // el aviso nunca bloquea
      expect(rows.last.regNumber, 2);
    });

    testWidgets(
        'QA-INS-012/013 · «Guardar y registrar otro» limpia todo el formulario y numera seguido; un doble toque no registra a nadie dos veces',
        (t) async {
      final a = await qaOpen(t, qaPc);
      for (var i = 1; i <= 3; i++) {
        await qaFill(t,
            first: 'Persona$i',
            last1: 'Prueba',
            woman: i.isEven,
            age: '${20 + i}',
            phone: '5 000 000$i',
            notes: 'obs $i');
        await tapKey(t, 'f-guardar-otro');
        for (final k in [
          'f-nombre',
          'f-apellido1',
          'f-edad',
          'f-telefono',
          'f-observaciones'
        ]) {
          expect(
              t.widget<TextField>(find.byKey(Key(k))).controller!.text, isEmpty,
              reason: 'campo $k sin limpiar tras el registro $i');
        }
        expect(find.byKey(const Key('dup-aviso')), findsNothing);
      }
      expect((await _rows(t, a)).map((r) => r.regNumber), [1, 2, 3]);
      // QA-INS-013: doble toque (con un fotograma entre toques, como un dedo) no duplica.
      await qaFill(t, first: 'Doble', last1: 'Toque', woman: false, age: '30');
      await t.ensureVisible(find.byKey(const Key('f-guardar-otro')));
      await t.tap(find.byKey(const Key('f-guardar-otro')));
      await t.pump(const Duration(milliseconds: 40));
      if (find.byKey(const Key('f-guardar-otro')).evaluate().isNotEmpty) {
        await t.tap(find.byKey(const Key('f-guardar-otro')),
            warnIfMissed: false);
      }
      await settle(t);
      await qaFill(t, first: 'Doble', last1: 'Guardar', woman: true, age: '31');
      await t.ensureVisible(find.byKey(const Key('f-guardar')));
      await t.tap(find.byKey(const Key('f-guardar')));
      await t.pump(const Duration(milliseconds: 40));
      if (find.byKey(const Key('f-guardar')).evaluate().isNotEmpty) {
        await t.tap(find.byKey(const Key('f-guardar')), warnIfMissed: false);
      }
      await settle(t);
      expect((await _rows(t, a)).length, 5,
          reason: 'se registró de más con un doble toque');
    });
  });

  testWidgets(
      'QA-INS-014 · dos toques en «Guardar» dentro del MISMO fotograma (un dedo no los da, pero un teclado o un ratón con rebote sí) registran a la persona una sola vez [Defecto QA-BUG-013]',
      (t) async {
    final a = await qaOpen(t, qaPc);
    await qaFill(t,
        first: 'Doble', last1: 'Fotograma', woman: false, age: '30');
    await t.ensureVisible(find.byKey(const Key('f-guardar')));
    await t.tap(find.byKey(const Key('f-guardar')));
    await t.tap(find.byKey(const Key('f-guardar')), warnIfMissed: false);
    await settle(t);
    expect((await _rows(t, a)).length, 1);
  });

  group('matrimonio, grupos, iglesia nueva y equipo/hospedaje al inscribir',
      () {
    testWidgets(
        'QA-INS-020 · vincular matrimonio y grupo desde el formulario: la esposa queda en el equipo del esposo y se muestra a qué equipo fue',
        (t) async {
      final a = await qaOpen(t, qaPc, teams: 3, prepare: (q) async {
        await qaInscribe(
            q,
            QaPerson(
                first: 'Raúl',
                last1: 'Acosta',
                last2: 'Leyva',
                sex: Sex.male,
                age: 45,
                churchIdx: 0,
                needsLodging: false));
        for (final p in qaPeople(8, seed: 5, couples: 0)) {
          p.groups = const {};
          await qaInscribe(q, p);
        }
      });
      expect(find.byKey(const Key('f-equipo')),
          findsNothing); // el equipo no se elige
      await qaFill(t, first: 'Elena', last1: 'Acosta', woman: true, age: '43');
      await tapKey(t, 'social-vincular');
      await t.enterText(find.byKey(const Key('pp-buscar')), 'raul');
      await settle(t);
      await tapKey(t, 'pp-1');
      expect(find.byKey(const Key('social-conyuge')), findsOneWidget);
      await tapKey(t, 'social-grupos');
      await tapKey(t, 'gp-Jóvenes Ebenezer');
      await tapKey(t, 'gp-listo');
      await tapKey(t, 'f-guardar');
      final rows = await _rows(t, a);
      final raul = rows.firstWhere((r) => r.firstName == 'Raúl');
      final elena = rows.firstWhere((r) => r.firstName == 'Elena');
      expect(elena.coupleId, isNotNull);
      expect(elena.coupleId, raul.coupleId);
      expect(elena.teamId, raul.teamId);
      final team = (await qaRows(t, a.q.teamRows))
          .firstWhere((x) => x.id == elena.teamId);
      expect(find.text('Equipo: ${team.name}'), findsOneWidget);
      final gid = a.q.groupIds['Jóvenes Ebenezer']!;
      final members = await qaRows(t, () => a.q.social.groupMembers(gid));
      expect(members.map((m) => m.firstName), contains('Elena'));
    });

    testWidgets(
        'QA-INS-021 · iglesia nueva: se añade al catálogo desde el formulario; repetir una existente da un mensaje en español',
        (t) async {
      final a = await qaOpen(t, qaPc);
      await enter(t, 'f-iglesia', 'Misionera del Sur');
      await settle(t);
      await tapKey(t, 'iglesia-nueva');
      await t.tap(find.byKey(const Key('ni-provincia')));
      await settle(t);
      await t.tap(find.text('Cienfuegos').last);
      await settle(t);
      await pickMunicipio(t, 'Cumanayagua');
      await tapKey(t, 'ni-guardar');
      expect(find.text('Iglesia nueva'), findsNothing);
      final n =
          (await qaRows(t, () => a.ctx.db.select(a.ctx.db.churches).get()))
              .length;
      expect(n, qaChurches.length + 1);
      // Se repite una existente (mismo nombre, provincia y municipio): no se duplica.
      await t.tap(find.byKey(const Key('f-iglesia')));
      await enter(t, 'f-iglesia', 'Bautista Eben');
      await settle(t);
      await tapKey(t, 'iglesia-nueva');
      await t.enterText(
          find.byKey(const Key('ni-nombre')), 'bautista ebenezer');
      await t.tap(find.byKey(const Key('ni-provincia')));
      await settle(t);
      await t.tap(find.text('Matanzas').last);
      await settle(t);
      await pickMunicipio(t, 'Cárdenas');
      await tapKey(t, 'ni-guardar');
      expect(
          find.textContaining('Ya existe «Bautista Ebenezer»'), findsOneWidget);
    });

    testWidgets(
        'QA-INS-023 · evento sin equipos ni hospedaje: se inscribe sin pedir ni mostrar nada de eso',
        (t) async {
      final a = await qaOpen(t, qaPc, offersTeams: false, offersLodging: false);
      expect(find.byKey(const Key('f-hospedaje')), findsNothing);
      await qaFill(t, first: 'Sin', last1: 'Extras', woman: false, age: '28');
      await tapKey(t, 'f-guardar');
      expect(find.byKey(const Key('exito-numero')), findsOneWidget);
      expect(find.byKey(const Key('exito-equipo')), findsNothing);
      expect((await _rows(t, a)).single.teamId, isNull);
    });
  });

  group('móvil (400×900)', () {
    testWidgets(
        'QA-INS-030/004 · inscripción completa en móvil: errores, éxito, «registrar a otra persona», nombre de 100 letras y lista, sin desbordes',
        (t) async {
      final a = await qaOpen(t, qaMovil, teams: 3);
      await tapKey(t, 'f-guardar');
      expect(find.textContaining('Falta el nombre'), findsOneWidget);
      await qaFill(t,
          first: 'Yaneisy',
          last1: 'Hernández',
          last2: 'Cabrera',
          woman: true,
          age: '19',
          phone: '5 222 3333');
      await tapKey(t, 'f-guardar');
      expect(find.textContaining('¡Bienvenida, Yaneisy!'), findsOneWidget);
      await tapKey(t, 'exito-otra');
      await qaFill(t,
          first: 'Dayron',
          last1: 'Sánchez',
          woman: false,
          age: '23',
          church: 1);
      await tapKey(t, 'f-guardar');
      expect(find.textContaining('¡Bienvenido, Dayron!'), findsOneWidget);
      // QA-INS-004: nombre y apellidos de ~100 letras no desbordan (éxito ni lista).
      await tapKey(t, 'exito-otra');
      await qaFill(t,
          first: ('Alejandrina ' * 8).trim(),
          last1: 'Fernández-Echevarría ' * 4,
          last2: 'de las Mercedes ' * 5,
          woman: true,
          age: '33');
      await tapKey(t, 'f-guardar');
      expect(find.byKey(const Key('exito-numero')), findsOneWidget);
      expect(t.takeException(), isNull,
          reason: 'desborde en la pantalla de éxito');
      await qaGoTo(t, 'Asistentes');
      expect(find.byKey(const Key('lista-conteo')), findsOneWidget);
      expect(t.takeException(), isNull, reason: 'desborde en la lista');
      final rows = await _rows(t, a);
      expect(rows.length, 3);
      expect(rows.last.firstName.length, greaterThan(90));
    });
  });

  group('ráfaga', () {
    testWidgets(
        'QA-INS-040 · 20 inscripciones seguidas por la interfaz: números 1–20 sin saltos, todas con equipo y reparto equilibrado',
        (t) async {
      final a = await qaOpen(t, qaPc, teams: 4);
      final people = qaPeople(20, seed: 99, couples: 0);
      final sw = Stopwatch()..start();
      for (final (i, p) in people.indexed) {
        await qaFill(t,
            first: p.first,
            last1: p.last1,
            last2: p.last2,
            woman: p.sex == Sex.female,
            age: '${p.age}',
            church: p.churchIdx,
            quick: true);
        await qaTap(t, i == people.length - 1 ? 'f-guardar' : 'f-guardar-otro');
      }
      sw.stop();
      await settle(t);
      final rows = await _rows(t, a);
      expect(rows.map((r) => r.regNumber), [for (var i = 1; i <= 20; i++) i]);
      expect(rows.every((r) => r.teamId != null), isTrue);
      final s = await qaRows(t, () => qaTeamStats(a.q));
      metric(
          'INS-040 ráfaga de 20 inscripciones por la interfaz: ${(sw.elapsedMilliseconds / 1000).toStringAsFixed(1)} s de prueba en total; equipos: ${qaTeamSummary(s)}');
      final sizes = s.map((x) => x.size);
      expect(
          sizes.reduce((x, y) => x > y ? x : y) -
              sizes.reduce((x, y) => x < y ? x : y),
          lessThanOrEqualTo(2));
      expect(t.takeException(), isNull);
    });
  });
}
