// QA · Equipos: balance automático al inscribir (estrategia C), cónyuge, cambios posteriores,
// «Generar equipos» (propuesta, aceptar, deshacer, descartar) e intercambios.
// Capa de datos real (SQLite en memoria) con 120 personas inscritas EN ORDEN, una por una.
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/repos_b.dart';
import 'package:mi_evento/data/repository.dart';
import 'package:mi_evento/data/team_pieces.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'qa_support.dart';

/// Lo mismo que hace la pantalla «Generar equipos».
Future<TeamPlan> _generate(QaEvent q, {required bool includeAssigned}) async {
  final people = await q.people();
  final teams = await q.teamRows();
  final ev = await (q.db.select(q.db.events)
        ..where((e) => e.id.equals(q.eventId)))
      .getSingle();
  final built = buildTeamPieces(people,
      spouses: await q.social.spouseMap(q.eventId),
      together: await q.social.togetherSets(q.eventId),
      includeAssigned: includeAssigned);
  final stats = [
    for (final t in teams)
      TeamStats.of(t.id, t.name,
          built.fixed.where((p) => p.teamId == t.id).map((p) => p.toCore()))
  ];
  return generateTeams(
      teams: stats, pieces: built.pieces, limits: ev.balanceLimits);
}

int _maxMinDiff(List<TeamStats> s) =>
    s.map((t) => t.size).reduce((a, b) => a > b ? a : b) -
    s.map((t) => t.size).reduce((a, b) => a < b ? a : b);

double _ageSpread(List<TeamStats> s) {
  final a = s.where((t) => t.size > 0).map((t) => t.avgAge);
  return a.reduce((x, y) => x > y ? x : y) - a.reduce((x, y) => x < y ? x : y);
}

int _maxSex(List<TeamStats> s) =>
    s.map((t) => t.sexDiff).reduce((a, b) => a > b ? a : b);

void main() {
  late AppDatabase db;
  setUp(() => db = qaDb());
  tearDown(() => db.close());

  group('equipo automático al inscribir (120 personas, una por una)', () {
    test(
        'QA-EQP-001 · con 120 inscritos seguidos y 6 equipos se cumplen los topes de tamaño y de hombres–mujeres',
        () async {
      final q = await qaEvent(db, teams: 6);
      final people = qaPeople(120);
      await qaInscribeAll(q, people);
      final s = await qaTeamStats(q);
      metric('EQP-001 120 personas / 6 equipos: ${qaTeamSummary(s)}');
      metric(
          'EQP-001 diferencias: tamaño ${_maxMinDiff(s)} (tope 2), H–M máx. ${_maxSex(s)} (tope 4), edad media ${_ageSpread(s).toStringAsFixed(2)} (tope 3)');
      expect(s.fold<int>(0, (a, t) => a + t.size), 120);
      expect(_maxMinDiff(s), lessThanOrEqualTo(2));
      expect(_maxSex(s), lessThanOrEqualTo(4));
    });

    test(
        'QA-EQP-001b · 120 personas con 2, 3, 4, 6 y 8 equipos y 6 conjuntos de datos distintos: se cumplen los topes salvo casos inevitables (datos o esposas tardías) y nunca por mucho',
        () async {
      // Antes de la corrección (QA-BUG-001): 17 de 30 superaban algún tope, con H–M hasta 15 y
      // edad hasta 14 años. Ahora quedan unas pocas, todas por causas que el equipo automático
      // no puede evitar sin mover a gente ya asignada:
      //  · sexo: si hay muchas más mujeres que hombres (o al revés) en total, con pocos equipos es
      //    matemáticamente imposible cumplir el tope (cada equipo debe cargar con la diferencia);
      //  · tamaño: la esposa que llega tarde entra sí o sí al equipo del esposo (+1 de golpe).
      final fallos = <String>[];
      final inexplicables = <String>[];
      for (final teams in [2, 3, 4, 6, 8]) {
        for (var k = 1; k <= 6; k++) {
          final d = qaDb();
          final q = await qaEvent(d, teams: teams);
          await qaInscribeAll(q, qaPeople(120, seed: k * 101));
          final s = await qaTeamStats(q);
          await d.close();
          if (evaluateBalance(s).isNotEmpty) {
            final texto =
                '$teams equipos, datos ${k * 101}: tamaño ${_maxMinDiff(s)}, H–M ${_maxSex(s)}, edad ${_ageSpread(s).toStringAsFixed(1)}';
            fallos.add(texto);
            final hombres = s.fold<int>(0, (a, t) => a + t.men);
            final mujeres = s.fold<int>(0, (a, t) => a + t.women);
            final minimoSexo = ((hombres - mujeres).abs() / teams).ceil();
            if (_maxMinDiff(s) > 3 ||
                _maxSex(s) > (minimoSexo > 4 ? minimoSexo : 4) + 1 ||
                _ageSpread(s) > 4) {
              inexplicables.add(texto);
            }
          }
        }
      }
      metric(
          'EQP-001b ${fallos.length} de 30 combinaciones superan algún tope: ${fallos.join(' | ')}');
      expect(inexplicables, isEmpty);
      expect(fallos.length, lessThanOrEqualTo(7));
    });

    test(
        'QA-EQP-001c · en 6 combinaciones (2 y 6 equipos, 3 conjuntos de datos) el tamaño nunca pasa de 3 (tope 2 más esposas tardías); se informan sexo y edad',
        () async {
      for (final teams in [2, 6]) {
        for (final seed in [101, 303, 505]) {
          final d = qaDb();
          final q = await qaEvent(d, teams: teams);
          await qaInscribeAll(q, qaPeople(120, seed: seed));
          final s = await qaTeamStats(q);
          await d.close();
          metric(
              'EQP-001c $teams equipos, datos $seed: tamaño ${_maxMinDiff(s)} (tope 2), H–M ${_maxSex(s)} (tope 4), edad ${_ageSpread(s).toStringAsFixed(1)} (tope 3)');
          expect(_maxMinDiff(s), lessThanOrEqualTo(3));
        }
      }
    });

    test(
        'QA-EQP-002 · todas las personas quedan con equipo y ninguno queda vacío',
        () async {
      final q = await qaEvent(db, teams: 6);
      await qaInscribeAll(q, qaPeople(120));
      final all = await q.people();
      expect(all.where((p) => p.teamId == null), isEmpty);
      final s = await qaTeamStats(q);
      expect(s.every((t) => t.size >= 19), isTrue, reason: qaTeamSummary(s));
    });

    test(
        'QA-EQP-003 · equipos sin gente al inicio: las 6 primeras personas (sin pareja) caen en 6 equipos distintos',
        () async {
      final q = await qaEvent(db, teams: 6);
      final solos = qaPeople(120).where((p) => p.spouseIdx == null).take(6);
      final first = [for (final p in solos) await qaInscribe(q, p)];
      final rows = [
        for (final r in first)
          (await (db.select(db.attendees)..where((a) => a.id.equals(r.id)))
                  .getSingle())
              .teamId
      ];
      expect(rows.toSet().length, 6, reason: 'equipos: $rows');
    });

    test(
        'QA-EQP-003b · al inicio el reparto se mantiene dentro del tope de tamaño aunque haya equipos vacíos (24 personas sin pareja)',
        () async {
      final q = await qaEvent(db, teams: 6);
      final solos = qaPeople(120).where((p) => p.spouseIdx == null).take(24);
      var vacios = 0;
      var i = 0;
      for (final p in solos) {
        await qaInscribe(q, p);
        i++;
        final s = await qaTeamStats(q);
        expect(_maxMinDiff(s), lessThanOrEqualTo(2),
            reason: 'tras $i personas');
        if (i == 6) vacios = s.where((t) => t.size == 0).length;
      }
      metric(
          'EQP-003b tras las 6 primeras personas sin pareja quedan $vacios equipos vacíos (de 6)');
    });

    test(
        'QA-EQP-004 · durante la inscripción (desde la nº 12) el tamaño no pasa de 3 de diferencia (2 + un matrimonio)',
        () async {
      final q = await qaEvent(db, teams: 6);
      final people = qaPeople(120);
      var worstSize = 0;
      var worstSex = 0;
      var worstAge = 0.0;
      var stepsOverSize = 0;
      for (var i = 0; i < people.length; i++) {
        await qaInscribe(q, people[i]);
        if (i >= 11) {
          final s = await qaTeamStats(q);
          worstSize = worstSize > _maxMinDiff(s) ? worstSize : _maxMinDiff(s);
          worstSex = worstSex > _maxSex(s) ? worstSex : _maxSex(s);
          final a = _ageSpread(s);
          if (a > worstAge) worstAge = a;
          if (_maxMinDiff(s) > 2) stepsOverSize++;
        }
      }
      metric(
          'EQP-004 peor momento (desde la inscripción nº 12): tamaño $worstSize (pasos por encima del tope 2: $stepsOverSize de 109), H–M $worstSex, edad ${worstAge.toStringAsFixed(2)}');
      // Un matrimonio entra completo al equipo del cónyuge: puede sumar 2 de golpe.
      expect(worstSize, lessThanOrEqualTo(3));
    });

    test(
        'QA-EQP-005 · regla del cónyuge: cada matrimonio queda en el MISMO equipo',
        () async {
      final q = await qaEvent(db, teams: 6);
      final people = qaPeople(120);
      await qaInscribeAll(q, people);
      final all = {for (final a in await q.people()) a.id: a};
      final sp = await q.social.spouseMap(q.eventId);
      expect(sp.length, 30); // 15 matrimonios
      for (final e in sp.entries) {
        expect(all[e.key]!.teamId, all[e.value]!.teamId,
            reason: 'matrimonio separado: ${all[e.key]!.firstName}');
      }
    });

    test(
        'QA-EQP-006 · el matrimonio cuya esposa llega 10 inscripciones después también queda junto',
        () async {
      final q = await qaEvent(db, teams: 6);
      final people = qaPeople(120);
      final late = [
        for (var i = 0; i < people.length; i++)
          if (people[i].spouseIdx != null && i - people[i].spouseIdx! > 1) i
      ];
      expect(late, isNotEmpty);
      await qaInscribeAll(q, people);
      final all = {for (final a in await q.people()) a.id: a};
      for (final i in late) {
        final w = all[q.ids[i]]!;
        final h = all[q.ids[people[i].spouseIdx!]]!;
        expect(w.teamId, h.teamId);
      }
    });

    for (final n in [2, 3, 4, 8, 10]) {
      test(
          'QA-EQP-007.$n · 100 personas en $n equipos: el tamaño no pasa de 4 (tope 2 más esposas tardías); sexo y edad se informan',
          () async {
        final q = await qaEvent(db, teams: n);
        await qaInscribeAll(q, qaPeople(100, seed: 7 + n, couples: 12));
        final s = await qaTeamStats(q);
        metric(
            'EQP-007.$n 100 personas / $n equipos: tamaño ${_maxMinDiff(s)}, H–M ${_maxSex(s)}, edad ${_ageSpread(s).toStringAsFixed(2)} | ${qaTeamSummary(s)}');
        expect(s.fold<int>(0, (a, t) => a + t.size), 100);
        // La esposa que llega tarde entra al equipo del esposo sin poder elegir: puede sumar 1-2.
        expect(_maxMinDiff(s), lessThanOrEqualTo(4), reason: qaTeamSummary(s));
      });
    }

    test(
        'QA-EQP-007b · 100 personas en 4, 8 y 10 equipos: la edad media entre equipos no pasa de 3 años',
        () async {
      for (final n in [4, 8, 10]) {
        final d = qaDb();
        final q = await qaEvent(d, teams: n);
        await qaInscribeAll(q, qaPeople(100, seed: 7 + n, couples: 12));
        final s = await qaTeamStats(q);
        await d.close();
        expect(_ageSpread(s), lessThanOrEqualTo(3),
            reason: '$n equipos: ${qaTeamSummary(s)}');
      }
    });

    test(
        'QA-EQP-008 · el resultado es repetible: mismos datos y mismo orden dan los mismos equipos',
        () async {
      Future<List<String>> run() async {
        final d = qaDb();
        final q = await qaEvent(d, teams: 6);
        await qaInscribeAll(q, qaPeople(60));
        final teams = await q.teamRows();
        final names = {for (final t in teams) t.id: t.name};
        final rows = await q.people();
        rows.sort((a, b) => a.regNumber.compareTo(b.regNumber));
        final r = [for (final a in rows) '${a.regNumber}:${names[a.teamId]}'];
        await d.close();
        return r;
      }

      expect(await run(), await run());
    });

    test(
        'QA-EQP-009 · evento sin equipos, o con equipos aún sin crear: no se asigna nada y no falla',
        () async {
      final q1 = await qaEvent(db, teams: 0, offersTeams: false);
      final r1 = await qaInscribe(q1, qaPeople(5).first);
      expect(r1.teamId, isNull);
      final q2 = await qaEvent(db, name: 'Otro', teams: 0, offersTeams: true);
      final r2 = await qaInscribe(q2, qaPeople(5, seed: 9).first);
      expect(r2.teamId, isNull);
    });

    test(
        'QA-EQP-010 · con topes más estrictos (tamaño ±1, H–M 2, edad 2) y 120 personas: sexo y edad se cumplen y el tamaño queda a lo sumo en 2 (parejas tardías)',
        () async {
      final q = await qaEvent(db, teams: 6);
      await q.teams.setLimits(q.eventId,
          const BalanceLimits(maxSizeDiff: 1, maxSexDiff: 2, maxAgeDiff: 2));
      await qaInscribeAll(q, qaPeople(120));
      final s = await qaTeamStats(q);
      metric(
          'EQP-010 topes 1/2/2: tamaño ${_maxMinDiff(s)}, H–M ${_maxSex(s)}, edad ${_ageSpread(s).toStringAsFixed(2)}');
      expect(_maxMinDiff(s), lessThanOrEqualTo(2));
      expect(_maxSex(s), lessThanOrEqualTo(2));
      expect(_ageSpread(s), lessThanOrEqualTo(2));
    });

    test(
        'QA-EQP-011 · las personas de un grupo «mantener juntos» se reparten por separado al inscribirse (documentado)',
        () async {
      // Observación de diseño: el equipo automático al inscribir ignora los grupos; solo
      // «Generar equipos» los mantiene juntos. Se comprueba y se informa.
      final q = await qaEvent(db, teams: 6);
      await qaInscribeAll(q, qaPeople(120));
      final sets = await q.social.togetherSets(q.eventId);
      final all = {for (final a in await q.people()) a.id: a};
      var split = 0;
      for (final s in sets) {
        if (s.map((id) => all[id]!.teamId).toSet().length > 1) split++;
      }
      metric(
          'EQP-011 grupos «mantener juntos»: ${sets.length}; repartidos en varios equipos por la inscripción: $split');
      expect(sets, isNotEmpty);
      expect(split, greaterThan(0));
    });
  });

  group('cambios posteriores desde la vista de Equipos', () {
    test('QA-EQP-020 · cambiar de equipo a una persona actualiza los conteos',
        () async {
      final q = await qaEvent(db, teams: 6);
      await qaInscribeAll(q, qaPeople(60));
      final before = await qaTeamStats(q);
      final one =
          (await q.people()).firstWhere((p) => p.teamId == q.teamIds[0]);
      await q.teams.setTeam([one.id], q.teamIds[1]);
      final after = await qaTeamStats(q);
      expect(after[0].size, before[0].size - 1);
      expect(after[1].size, before[1].size + 1);
    });

    test(
        'QA-EQP-021 · al pasar de equipo al capitán, su equipo queda sin capitán',
        () async {
      final q = await qaEvent(db, teams: 6);
      await qaInscribeAll(q, qaPeople(60));
      final cap =
          (await q.people()).firstWhere((p) => p.teamId == q.teamIds[0]);
      final t = await (db.select(db.teams)
            ..where((x) => x.id.equals(q.teamIds[0])))
          .getSingle();
      await q.teams
          .update(t.id, name: t.name, color: t.color, captainId: cap.id);
      await q.teams.setTeam([cap.id], q.teamIds[1]);
      final t2 = await (db.select(db.teams)
            ..where((x) => x.id.equals(q.teamIds[0])))
          .getSingle();
      expect(t2.captainId, isNull);
    });

    test('QA-EQP-022 · intercambiar a dos personas de equipos distintos',
        () async {
      final q = await qaEvent(db, teams: 6);
      await qaInscribeAll(q, qaPeople(60));
      final all = await q.people();
      final a = all.firstWhere((p) => p.teamId == q.teamIds[0]);
      final b = all.firstWhere((p) => p.teamId == q.teamIds[1]);
      await q.teams.swap(a.id, b.id);
      final a2 = (await q.repo.attendeeById(a.id))!;
      final b2 = (await q.repo.attendeeById(b.id))!;
      expect(a2.teamId, q.teamIds[1]);
      expect(b2.teamId, q.teamIds[0]);
    });

    test(
        'QA-EQP-023 · intercambiar en el mismo equipo o con alguien sin equipo da un mensaje en español',
        () async {
      final q = await qaEvent(db, teams: 2);
      await qaInscribeAll(q, qaPeople(10));
      final all = await q.people();
      final same = all.where((p) => p.teamId == q.teamIds[0]).take(2).toList();
      await expectLater(
          q.teams.swap(same[0].id, same[1].id),
          throwsA(isA<DataException>()
              .having((e) => e.message, 'mensaje', contains('mismo equipo'))));
      await q.teams.setTeam([same[0].id], null);
      await expectLater(
          q.teams.swap(same[0].id, same[1].id),
          throwsA(isA<DataException>().having((e) => e.message, 'mensaje',
              contains('deben estar en un equipo'))));
    });

    test(
        'QA-EQP-024 · nombre de equipo repetido y capitán ajeno se rechazan en español',
        () async {
      final q = await qaEvent(db, teams: 3);
      await qaInscribeAll(q, qaPeople(12));
      final teams = await q.teamRows();
      await expectLater(
          q.teams.update(teams[0].id, name: teams[1].name),
          throwsA(isA<DataException>()
              .having((e) => e.message, 'm', contains('Ya existe un equipo'))));
      final other =
          (await q.people()).firstWhere((p) => p.teamId == teams[1].id);
      await expectLater(
          q.teams.update(teams[0].id, name: teams[0].name, captainId: other.id),
          throwsA(isA<DataException>().having(
              (e) => e.message, 'm', contains('integrante del equipo'))));
      await expectLater(q.teams.update(teams[0].id, name: '   '),
          throwsA(isA<DataException>()));
    });

    test('QA-EQP-025 · borrar un equipo deja sin equipo a su gente', () async {
      final q = await qaEvent(db, teams: 6);
      await qaInscribeAll(q, qaPeople(60));
      final n = await q.teams.delete(q.teamIds[0]);
      expect(n, greaterThan(0));
      final sin = (await q.people()).where((p) => p.teamId == null).length;
      expect(sin, n);
    });

    test('QA-EQP-026 · el número de equipos a crear debe estar entre 1 y 40',
        () async {
      final q = await qaEvent(db, teams: 0);
      await expectLater(
          q.teams.createMany(q.eventId, 0), throwsA(isA<DataException>()));
      await expectLater(
          q.teams.createMany(q.eventId, 41), throwsA(isA<DataException>()));
      await q.teams.createMany(q.eventId, 12);
      final t = await q.teamRows();
      expect(t.map((e) => e.name).toSet().length, 12); // sin nombres repetidos
    });
  });

  group('Generar equipos', () {
    test(
        'QA-EQP-030 · generar para quien no tiene equipo: propuesta que cumple los topes y se aplica',
        () async {
      final q = await qaEvent(db, teams: 6);
      await qaInscribeAll(q, qaPeople(120));
      // Se quita el equipo a todos (como un evento al que se llegó sin equipos).
      await q.teams.setTeam((await q.people()).map((p) => p.id), null);
      final plan = await _generate(q, includeAssigned: false);
      expect(plan.assignments.length, 120);
      metric(
          'EQP-030 Generar equipos (120): ${qaTeamSummary(plan.after)} | topes superados: ${plan.issues.length}');
      expect(plan.isBalanced, isTrue,
          reason: plan.issues.map((i) => i.message).join(' / '));
      await q.teams.applyPlan(plan.assignments);
      final s = await qaTeamStats(q);
      expect(_maxMinDiff(s), lessThanOrEqualTo(2));
      expect(_maxSex(s), lessThanOrEqualTo(4));
      expect(_ageSpread(s), lessThanOrEqualTo(3));
    });

    test('QA-EQP-031 · la propuesta no cambia nada hasta aceptarla', () async {
      final q = await qaEvent(db, teams: 4);
      await qaInscribeAll(q, qaPeople(40));
      await q.teams.setTeam((await q.people()).map((p) => p.id), null);
      await _generate(q, includeAssigned: false); // calcular = descartar
      expect((await q.people()).where((p) => p.teamId != null), isEmpty);
    });

    test(
        'QA-EQP-032 · deshacer tras aceptar devuelve a cada persona a su equipo anterior',
        () async {
      final q = await qaEvent(db, teams: 6);
      await qaInscribeAll(q, qaPeople(60));
      final antes = {for (final p in await q.people()) p.id: p.teamId};
      final plan = await _generate(q, includeAssigned: true);
      final previous = await q.teams.applyPlan(plan.assignments);
      expect(previous.length, 60);
      await q.teams.restoreTeams(previous);
      final despues = {for (final p in await q.people()) p.id: p.teamId};
      expect(despues, antes);
    });

    test(
        'QA-EQP-033 · generar para solo los sin equipo respeta a quienes ya tienen equipo',
        () async {
      final q = await qaEvent(db, teams: 6);
      await qaInscribeAll(q, qaPeople(60));
      final all = await q.people();
      final sinEquipo = all.take(10).map((p) => p.id).toList();
      await q.teams.setTeam(sinEquipo, null);
      final fijos = {
        for (final p in all.skip(10)) p.id: p.teamId,
      };
      final plan = await _generate(q, includeAssigned: false);
      expect(plan.assignments.keys.toSet().containsAll(sinEquipo), isTrue);
      expect(plan.assignments.keys.where(fijos.containsKey), isEmpty,
          reason: 'no debe tocar a quienes ya tienen equipo');
    });

    test(
        'QA-EQP-034 · «Generar equipos» mantiene juntos a los matrimonios y a los grupos «mantener juntos»',
        () async {
      final q = await qaEvent(db, teams: 6);
      await qaInscribeAll(q, qaPeople(120));
      await q.teams.setTeam((await q.people()).map((p) => p.id), null);
      final plan = await _generate(q, includeAssigned: false);
      await q.teams.applyPlan(plan.assignments);
      final all = {for (final a in await q.people()) a.id: a};
      for (final s in await q.social.togetherSets(q.eventId)) {
        expect(s.map((id) => all[id]!.teamId).toSet().length, 1);
      }
      final sp = await q.social.spouseMap(q.eventId);
      for (final e in sp.entries) {
        expect(all[e.key]!.teamId, all[e.value]!.teamId);
      }
    });

    test(
        'QA-EQP-035 · sin equipos creados la propuesta avisa en español, no falla',
        () async {
      final q = await qaEvent(db, teams: 0);
      await qaInscribeAll(q, qaPeople(5));
      final plan = await _generate(q, includeAssigned: false);
      expect(plan.assignments, isEmpty);
      expect(plan.notes.join(' '), contains('crea al menos uno'));
    });

    test(
        'QA-EQP-036 · un grupo «mantener juntos» muy grande puede romper el tope de tamaño: la propuesta lo avisa',
        () async {
      final q = await qaEvent(db, teams: 4, groups: ['Excursión']);
      final ppl = qaPeople(40);
      for (var i = 0; i < 40; i++) {
        ppl[i].groups = i < 14 ? {'Excursión'} : const {};
        ppl[i].spouseIdx = null; // sin matrimonios para aislar el efecto
      }
      await qaInscribeAll(q, ppl);
      await q.teams.setTeam((await q.people()).map((p) => p.id), null);
      final plan = await _generate(q, includeAssigned: false);
      metric(
          'EQP-036 grupo de 14 en 4 equipos (40 personas): topes superados ${plan.issues.length} → ${plan.issues.map((i) => i.message).join(' / ')}');
      expect(plan.issues, isNotEmpty);
      expect(plan.issues.first.message, contains('Tamaño'));
    });
  });
}
