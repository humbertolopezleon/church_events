// QA · Hospedaje con 120 personas: sugerencia aceptada, compatibilidad por sexo, matrimonios,
// grupos, déficit de plazas, avisos al forzar, «dejar para después» y listas imprimibles (PDF).
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/repos_b.dart';
import 'package:mi_evento/data/repository.dart';
import 'package:mi_evento/ui/lodging_pdf.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'qa_support.dart';

/// Ocupantes por hospedaje: id → personas.
Map<String, List<AttendeeRow>> _byLodging(List<AttendeeRow> all) {
  final m = <String, List<AttendeeRow>>{};
  for (final a in all) {
    if (a.lodgingId != null) (m[a.lodgingId!] ??= []).add(a);
  }
  return m;
}

/// Lo que hace el formulario al ofrecer hospedaje a UNA persona recién inscrita.
/// Si su cónyuge ya está alojado donde no pueden estar juntos, el formulario PROPONE mover a los
/// dos a un hospedaje de matrimonios (QA-BUG-003) y aquí se acepta esa propuesta.
Future<String?> _formSuggest(QaEvent q, AttendeeRow row) async {
  final all = await q.people();
  final sp = await q.social.spouseMap(q.eventId);
  final spId = sp[row.id];
  final spRow = spId == null ? null : all.firstWhere((a) => a.id == spId);
  final spLodging = spRow?.lodgingId;
  final lods = await q.lodgingViews();
  List<LodgingCandidate> candidates({Set<String> excluding = const {}}) => [
        for (final l in lods)
          LodgingCandidate(
            id: l.row.id,
            name: l.row.name,
            accepts: lodgingAcceptsFromDb(l.row.accepts),
            capacity: l.row.capacity,
            occupied: l.occupied - (excluding.contains(l.row.id) ? 1 : 0),
            kind: l.row.kind == 'shelter'
                ? LodgingKindRef.shelter
                : LodgingKindRef.privateHome,
            occupantChurchIds: {
              for (final p in all)
                if (p.lodgingId == l.row.id && p.churchId != null) p.churchId!
            },
            distanceNote: l.row.distanceNote,
          )
      ];
  final ref = PersonRef(
      id: row.id,
      name: '${row.firstName} ${row.lastName1}',
      sex: row.sex == 'M' ? Sex.male : Sex.female,
      spouseId: spId,
      churchId: row.churchId,
      spouseLodgingId: spLodging);
  if (spRow != null && spLodging != null && spRow.needsLodging) {
    final move = proposeCoupleMove(
        a: ref,
        b: spRow.toPersonRef(row.id),
        aLodgingId: null,
        bLodgingId: spLodging,
        lodgings: candidates(excluding: {spLodging}));
    if (move != null) {
      final id = move.legs.first.lodgingId;
      await q.lodgings.assign(id, [row.id, spRow.id]);
      return id;
    }
  }
  final proposals = suggestLodging([ref], candidates(), maxProposals: 1);
  if (proposals.isEmpty || proposals.first.legs.isEmpty) return null;
  final id = proposals.first.legs.first.lodgingId;
  await q.lodgings.assign(id, [row.id]);
  return id;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  setUp(() => db = qaDb());
  tearDown(() => db.close());

  Future<QaEvent> evento120({double scale = 1.0}) async {
    final q = await qaEvent(db, teams: 6);
    await qaInscribeAll(q, qaPeople(120));
    await qaLodgings(q, scale: scale);
    return q;
  }

  group('sugerencia aceptada para todas las personas (120 inscritos)', () {
    test(
        'QA-HOS-001 · a TODA persona que necesita hospedaje se le asigna uno con la sugerencia',
        () async {
      final q = await evento120();
      final needs = (await q.people()).where((p) => p.needsLodging).length;
      final prop = await qaSuggestAndAccept(q);
      final all = await q.people();
      metric(
          'HOS-001 120 inscritos, $needs necesitan hospedaje; propuesta: ${prop!.placedCount} ubicadas, ${prop.unplaced.length} sin lugar, completa=${prop.isComplete}');
      expect(prop.isComplete, isTrue, reason: prop.notes.join(' / '));
      expect(all.where((p) => p.needsLodging && p.lodgingId == null), isEmpty);
      expect(all.where((p) => !p.needsLodging && p.lodgingId != null), isEmpty,
          reason: 'a quien no necesita no se le asigna');
    });

    test(
        'QA-HOS-002 · ninguna sobrecapacidad: ocupación ≤ plazas en cada hospedaje',
        () async {
      final q = await evento120();
      await qaSuggestAndAccept(q);
      final lods = await q.lodgingViews();
      for (final l in lods) {
        expect(l.occupied, lessThanOrEqualTo(l.row.capacity),
            reason: l.row.name);
      }
      metric(
          'HOS-002 ocupación: ${lods.map((l) => '${l.row.name} ${l.occupied}/${l.row.capacity}').join(' | ')}');
    });

    test(
        'QA-HOS-003 · compatibilidad por sexo: los albergues de hombres/mujeres solo tienen a su sexo',
        () async {
      final q = await evento120();
      await qaSuggestAndAccept(q);
      final lods = await q.lodgingViews();
      final occ = _byLodging(await q.people());
      for (final l in lods) {
        final people = occ[l.row.id] ?? const [];
        if (l.row.accepts == 'men') {
          expect(people.every((p) => p.sex == 'M'), isTrue, reason: l.row.name);
        } else if (l.row.accepts == 'women') {
          expect(people.every((p) => p.sex == 'F'), isTrue, reason: l.row.name);
        }
      }
    });

    test(
        'QA-HOS-004 · matrimonios juntos: cada pareja queda en el mismo hospedaje de matrimonios',
        () async {
      final q = await evento120();
      await qaSuggestAndAccept(q);
      final all = {for (final a in await q.people()) a.id: a};
      final lods = {for (final l in await q.lodgingViews()) l.row.id: l.row};
      final sp = await q.social.spouseMap(q.eventId);
      expect(sp.length, 30);
      for (final e in sp.entries) {
        final a = all[e.key]!, b = all[e.value]!;
        expect(a.lodgingId, isNotNull);
        expect(a.lodgingId, b.lodgingId,
            reason: '${a.firstName} y ${b.firstName}');
        expect(lods[a.lodgingId]!.accepts, 'couples');
      }
      // Y en un hospedaje de matrimonios solo hay matrimonios completos.
      final occ = _byLodging(all.values.toList());
      for (final l in lods.values.where((l) => l.accepts == 'couples')) {
        for (final p in occ[l.id] ?? const <AttendeeRow>[]) {
          expect(sp[p.id], isNotNull, reason: 'persona sola en ${l.name}');
        }
      }
    });

    test(
        'QA-HOS-005 · con las plazas justas (sin holgura) también se logra, o se informa el déficit',
        () async {
      final q = await qaEvent(db, teams: 6);
      await qaInscribeAll(q, qaPeople(120));
      final all = await q.people();
      final need = all.where((p) => p.needsLodging).toList();
      final sp = await q.social.spouseMap(q.eventId);
      final parejas = need.where((p) => sp.containsKey(p.id)).length;
      final hombres =
          need.where((p) => !sp.containsKey(p.id) && p.sex == 'M').length;
      final mujeres =
          need.where((p) => !sp.containsKey(p.id) && p.sex == 'F').length;
      await q.lodgings.save(
          eventId: q.eventId,
          name: 'Hombres',
          kind: 'shelter',
          capacity: hombres,
          accepts: LodgingAccepts.men);
      await q.lodgings.save(
          eventId: q.eventId,
          name: 'Mujeres',
          kind: 'shelter',
          capacity: mujeres,
          accepts: LodgingAccepts.women);
      await q.lodgings.save(
          eventId: q.eventId,
          name: 'Matrimonios',
          kind: 'private_home',
          capacity: parejas,
          accepts: LodgingAccepts.couples);
      final prop = await qaSuggestAndAccept(q);
      metric(
          'HOS-005 plazas justas: hombres $hombres, mujeres $mujeres, en matrimonio $parejas → completa=${prop!.isComplete}, sin lugar ${prop.unplaced.length}');
      expect(prop.isComplete, isTrue, reason: prop.notes.join(' / '));
      final lods = await q.lodgingViews();
      expect(lods.every((l) => l.occupied == l.row.capacity), isTrue);
    });
  });

  group('faltan plazas', () {
    test(
        'QA-HOS-010 · con muy pocas plazas la propuesta informa cuántas faltan y no asigna de más',
        () async {
      final q = await evento120(scale: 0.4);
      final prop = await qaSuggestAndAccept(q);
      final all = await q.people();
      final sinLugar = all.where((p) => p.needsLodging && p.lodgingId == null);
      metric(
          'HOS-010 déficit (plazas al 40 %): propuesta incompleta=${!prop!.isComplete}, sin lugar ${prop.unplaced.length}; notas: ${prop.notes.take(3).join(' / ')}');
      expect(prop.isComplete, isFalse);
      expect(prop.unplaced, isNotEmpty);
      expect(sinLugar.length, prop.unplaced.length);
      expect(prop.notes.join(' '), contains('Faltan'));
      final lods = await q.lodgingViews();
      for (final l in lods) {
        expect(l.occupied, lessThanOrEqualTo(l.row.capacity));
      }
    });

    test(
        'QA-HOS-011 · sin ningún hospedaje compatible la propuesta lo dice en español',
        () async {
      final q = await qaEvent(db, teams: 2);
      await qaInscribeAll(q, qaPeople(20));
      await q.lodgings.save(
          eventId: q.eventId,
          name: 'Solo mujeres',
          kind: 'shelter',
          capacity: 50,
          accepts: LodgingAccepts.women);
      final prop = await qaSuggestAndAccept(q);
      expect(
          prop!.notes.join(' '),
          anyOf(contains('No hay ningún hospedaje compatible'),
              contains('Faltan')));
      final all = await q.people();
      expect(
          all.where(
              (p) => p.needsLodging && p.sex == 'M' && p.lodgingId != null),
          isEmpty);
    });

    test('QA-HOS-012 · sin hospedajes creados no hay propuestas y no falla',
        () async {
      final q = await qaEvent(db, teams: 2);
      await qaInscribeAll(q, qaPeople(20));
      final prop = await qaSuggestAndAccept(q);
      expect(prop == null || prop.legs.isEmpty, isTrue);
    });
  });

  group('asignación manual y avisos', () {
    test(
        'QA-HOS-020 · un hombre en un hospedaje de mujeres: la compatibilidad BLOQUEA (solo se logra editando el hospedaje)',
        () async {
      final q = await evento120();
      final all = await q.people();
      final hombre = all.firstWhere((p) => p.sex == 'M' && !p.needsLodging);
      final mujeres =
          (await q.lodgingViews()).firstWhere((l) => l.row.accepts == 'women');
      final warns =
          checkLodgingAssignment(mujeres.slot, [hombre.toPersonRef(null)]);
      expect(warns.map((w) => w.kind), contains(WarningKind.compatibility));
      expect(warns.first.message, contains('solo acepta mujeres'));
      await expectLater(q.lodgings.assign(mujeres.row.id, [hombre.id]),
          throwsA(isA<LodgingIncompatibleException>()));
      expect((await q.repo.attendeeById(hombre.id))!.lodgingId, isNull);
      // La única salida: editar el hospedaje (para quién es).
      await q.lodgings.save(
          id: mujeres.row.id,
          eventId: q.eventId,
          name: mujeres.row.name,
          kind: mujeres.row.kind,
          capacity: mujeres.row.capacity,
          accepts: LodgingAccepts.any);
      await q.lodgings.assign(mujeres.row.id, [hombre.id]);
      expect((await q.repo.attendeeById(hombre.id))!.lodgingId, mujeres.row.id);
    });

    test(
        'QA-HOS-021 · pasarse de la capacidad avisa con cifras y deja continuar',
        () async {
      final q = await qaEvent(db, teams: 2);
      await qaInscribeAll(q, qaPeople(30));
      final l = await q.lodgings.save(
          eventId: q.eventId,
          name: 'Casa chica',
          kind: 'private_home',
          capacity: 2,
          accepts: LodgingAccepts.men);
      final men =
          (await q.people()).where((p) => p.sex == 'M').take(3).toList();
      final lv = (await q.lodgingViews()).single;
      final warns = checkLodgingAssignment(
          lv.slot, [for (final m in men) m.toPersonRef(null)]);
      expect(warns.single.kind, WarningKind.capacity);
      expect(warns.single.message,
          contains('quedaría con 3 personas y solo tiene 2 plazas'));
      await q.lodgings.assign(l.id, men.map((m) => m.id));
      final after = (await q.lodgingViews()).single;
      expect(after.occupied, 3);
      expect(after.free, -1); // sobrecapacidad decidida por el usuario, visible
    });

    test(
        'QA-HOS-022 · un matrimonio separado en hospedaje de matrimonios avisa de la persona sin cónyuge',
        () async {
      final q = await evento120();
      final sp = await q.social.spouseMap(q.eventId);
      final all = {for (final a in await q.people()) a.id: a};
      final husband = all[sp.keys.first]!;
      final casa = (await q.lodgingViews())
          .firstWhere((l) => l.row.accepts == 'couples');
      final warns = checkLodgingAssignment(
          casa.slot, [husband.toPersonRef(sp[husband.id])]);
      expect(warns.single.message, contains('sin su cónyuge'));
    });

    test(
        'QA-HOS-023 · asignar a un grupo entero (5 personas) a un hospedaje y ver su ocupación',
        () async {
      final q = await evento120();
      final sets = await q.social.togetherSets(q.eventId);
      expect(sets, isNotEmpty);
      final grupo = sets.first;
      final albergue = await q.lodgings.save(
          eventId: q.eventId,
          name: 'Albergue abierto',
          kind: 'shelter',
          capacity: grupo.length + 2,
          accepts: LodgingAccepts.any);
      await q.lodgings.assign(albergue.id, grupo);
      final occ = await q.lodgings.occupants(albergue.id);
      expect(occ.map((o) => o.id).toSet(), grupo);
    });

    test(
        'QA-HOS-024 · «dejar para después»: quien necesita y no tiene hospedaje queda pendiente y se cuenta en el reporte',
        () async {
      final q = await evento120();
      final pend = (await q.people())
          .where((p) => p.needsLodging && p.lodgingId == null);
      expect(pend.length, greaterThan(50)); // nadie tiene hospedaje todavía
      final people = await q.people();
      final sections = buildReportSections([
        for (final p in people)
          ReportPerson(
              isMale: p.sex == 'M',
              age: p.age,
              needsLodging: p.needsLodging,
              lodging: null)
      ], AgeRange.defaults);
      final h = sections.firstWhere((s) => s.title == 'Por hospedaje');
      expect(
          h.rows.firstWhere((r) => r.label == 'Necesitan y sin asignar').count,
          pend.length);
      expect(h.total, 120);
    });

    test(
        'QA-HOS-025 · borrar un hospedaje deja sin asignar a sus ocupantes y devuelve cuántos',
        () async {
      final q = await evento120();
      await qaSuggestAndAccept(q);
      final lods = await q.lodgingViews();
      final con = lods.firstWhere((l) => l.occupied > 0);
      final pendAntes = (await q.people())
          .where((p) => p.needsLodging && p.lodgingId == null)
          .length;
      final n = await q.lodgings.delete(con.row.id);
      expect(n, con.occupied);
      final pend = (await q.people())
          .where((p) => p.needsLodging && p.lodgingId == null);
      expect(pend.length, pendAntes + n);
    });

    test(
        'QA-HOS-026 · validaciones del hospedaje en español: nombre, capacidad 0/501, repetido',
        () async {
      final q = await qaEvent(db, teams: 0);
      Future<void> bad(String? name, int cap, String texto) => expectLater(
          q.lodgings.save(
              eventId: q.eventId,
              name: name ?? '',
              kind: 'shelter',
              capacity: cap,
              accepts: LodgingAccepts.men),
          throwsA(isA<DataException>()
              .having((e) => e.message, 'm', contains(texto))));
      await bad('   ', 5, 'Falta el nombre');
      await bad('Casa', 0, 'entre 1 y 500');
      await bad('Casa', 501, 'entre 1 y 500');
      await q.lodgings.save(
          eventId: q.eventId,
          name: 'Casa Ñandú',
          kind: 'shelter',
          capacity: 500,
          accepts: LodgingAccepts.men);
      await bad('casa nandu', 5, 'Ya existe'); // sin tildes ni mayúsculas
    });

    test(
        'QA-HOS-027 · registrar a las parejas UNA POR UNA con la sugerencia del formulario deja a los dos en el mismo hospedaje',
        () async {
      final q = await qaEvent(db, teams: 6);
      await qaLodgings(q);
      final people = qaPeople(120);
      for (final p in people) {
        final row = await qaInscribe(q, p);
        if (p.needsLodging) await _formSuggest(q, row);
      }
      final all = {for (final a in await q.people()) a.id: a};
      final lods = {for (final l in await q.lodgingViews()) l.row.id: l.row};
      final sp = await q.social.spouseMap(q.eventId);
      var juntos = 0, sin = 0, separadosOEnOtro = 0;
      for (final e in sp.entries.where((e) => e.key.compareTo(e.value) < 0)) {
        final a = all[e.key]!, b = all[e.value]!;
        if (a.lodgingId == null || b.lodgingId == null) {
          sin++;
        } else if (a.lodgingId == b.lodgingId &&
            lods[a.lodgingId]!.accepts == 'couples') {
          juntos++;
        } else {
          separadosOEnOtro++;
        }
      }
      final pend =
          all.values.where((p) => p.needsLodging && p.lodgingId == null).length;
      metric(
          'HOS-027 inscripción una a una con sugerencia del formulario: matrimonios juntos $juntos, con alguien sin hospedaje $sin, separados/en albergue de un solo sexo $separadosOEnOtro; personas pendientes $pend');
      expect(sin + separadosOEnOtro, 0, reason: 'matrimonios mal alojados');
    });
  });

  group('listas imprimibles (PDF real)', () {
    test(
        'QA-HOS-030 · un PDF válido por cada hospedaje con gente, con y sin teléfono',
        () async {
      final q = await evento120();
      await qaSuggestAndAccept(q);
      final lods = await q.lodgingViews();
      final churches = {
        for (final c in await db.select(db.churches).get()) c.id: c.name
      };
      var generados = 0;
      for (final l in lods.where((l) => l.occupied > 0)) {
        final occ = await q.lodgings.occupants(l.row.id);
        for (final phone in [false, true]) {
          final pdf = await buildLodgingPdf(
              eventName: 'Congreso QA 2026',
              eventDates: 'del 2026-12-11 al 2026-12-13',
              lodging: l.row,
              occupants: occ,
              churchNames: churches,
              includePhone: phone,
              bundle: rootBundle,
              now: DateTime(2026, 12, 11));
          expect(String.fromCharCodes(pdf.take(5)), '%PDF-',
              reason: l.row.name);
          generados++;
        }
      }
      expect(generados, greaterThanOrEqualTo(10));
    });

    test(
        'QA-HOS-031 · el PDF de un albergue de 24 personas con nombres con ñ y tildes se genera sin error',
        () async {
      final q = await evento120();
      await qaSuggestAndAccept(q);
      final lods = await q.lodgingViews();
      final big = lods.reduce((a, b) => a.occupied >= b.occupied ? a : b);
      final occ = await q.lodgings.occupants(big.row.id);
      final pdf = await buildLodgingPdf(
          eventName: 'Congreso de la Niñez Ñandú',
          eventDates: 'del 2026-12-11 al 2026-12-13',
          lodging: big.row,
          occupants: occ,
          churchNames: {
            for (final c in await db.select(db.churches).get()) c.id: c.name
          },
          bundle: rootBundle);
      expect(pdf.length, greaterThan(5000));
    });
  });

  group('integridad al borrar a una persona', () {
    test(
        'QA-HOS-040 · al borrar a un asistente se libera su plaza de hospedaje y no cuenta en equipos',
        () async {
      final q = await evento120();
      await qaSuggestAndAccept(q);
      final antes =
          (await q.lodgingViews()).fold<int>(0, (a, l) => a + l.occupied);
      final con = (await q.people())
          .firstWhere((p) => p.lodgingId != null && p.teamId != null);
      await q.repo.deleteAttendee(con.id, isAdmin: true);
      final despues =
          (await q.lodgingViews()).fold<int>(0, (a, l) => a + l.occupied);
      expect(despues, antes - 1);
      final stats = await qaTeamStats(q);
      expect(stats.fold<int>(0, (a, t) => a + t.size), 119);
    });

    test(
        'QA-HOS-041 · al borrar a una persona casada su cónyuge queda sin pareja (según PLAN.md: se limpia pareja, equipo y hospedaje)',
        () async {
      final q = await evento120();
      final sp = await q.social.spouseMap(q.eventId);
      final husbandId = sp.keys.first;
      final wifeId = sp[husbandId]!;
      await q.repo.deleteAttendee(husbandId, isAdmin: true);
      final esposo = await q.social.spouseOf(wifeId);
      expect(esposo, isNull,
          reason: 'la esposa sigue vinculada a alguien ya eliminado');
      final borrado = (await q.repo.attendeeById(husbandId))!;
      expect(borrado.teamId, isNull);
      expect(borrado.lodgingId, isNull);
    });

    test(
        'QA-HOS-041b · borrar al capitán lo quita del equipo (que queda sin capitán), libera el hospedaje y lo saca de sus grupos; devuelve el equipo para avisar',
        () async {
      final q = await qaEvent(db, teams: 2);
      await qaInscribeAll(q, qaPeople(6, couples: 0));
      final p = (await q.repo.attendeeById(q.ids.first))!;
      await q.teams.update(p.teamId!,
          name: (await q.teamRows()).firstWhere((t) => t.id == p.teamId).name,
          captainId: p.id);
      final g = await q.social.createGroup(q.eventId, 'Prueba');
      await q.social.setGroups(p.id, {g.id});
      final aviso = await q.repo.deleteAttendee(p.id, isAdmin: true);
      expect(aviso, isNotNull);
      final equipo = (await q.teamRows()).firstWhere((t) => t.id == p.teamId);
      expect(equipo.captainId, isNull);
      expect(await q.social.groupIdsOf(p.id), isEmpty);
      // Borrar a quien no es capitán no avisa de nada.
      expect(await q.repo.deleteAttendee(q.ids[1], isAdmin: true), isNull);
    });

    test(
        'QA-HOS-042 · solo el administrador borra: un operador recibe un mensaje en español',
        () async {
      final q = await qaEvent(db, teams: 2);
      await qaInscribeAll(q, qaPeople(4));
      await expectLater(
          q.repo.deleteAttendee(q.ids.first, isAdmin: false),
          throwsA(isA<DataException>().having(
              (e) => e.message, 'm', contains('Solo el administrador'))));
    });
  });
}
