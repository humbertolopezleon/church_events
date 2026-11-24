import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_evento/data/attendee_exchange.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/event_copy.dart';
import 'package:mi_evento/data/repos_b.dart';
import 'package:mi_evento/data/repository.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

/// La compatibilidad de un hospedaje (sexo / matrimonio) es un BLOQUEO en la capa de datos.
void main() {
  late AppDatabase db;
  late Repository repo;
  late LodgingRepo lodgings;
  late SocialRepo social;
  late String ev, churchId;

  Future<AttendeeRow> person(String name, Sex sex, {int age = 30}) =>
      repo.addAttendee(
          eventId: ev,
          firstName: name,
          lastName1: 'Prueba',
          sex: sex,
          age: age,
          churchId: churchId);
  Future<LodgingRow> lodging(String name, LodgingAccepts a, {int cap = 6}) =>
      lodgings.save(
          eventId: ev, name: name, kind: 'shelter', capacity: cap, accepts: a);
  Future<String?> lodgingOf(String id) async =>
      (await repo.attendeeById(id))!.lodgingId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = Repository(db);
    lodgings = LodgingRepo(db);
    social = SocialRepo(db);
    ev = await repo.createEvent(
        name: 'E', startDate: '2026-01-01', endDate: '2026-01-02');
    churchId =
        (await repo.createChurch(name: 'Bautista', province: 'Matanzas')).id;
  });
  tearDown(() => db.close());

  group('LodgingRepo.assign bloquea', () {
    test('un hombre no entra en un hospedaje de mujeres (y no se escribe nada)',
        () async {
      final w = await lodging('Casa M', LodgingAccepts.women);
      final h = await person('Juan', Sex.male);
      final m = await person('Ana', Sex.female);
      await expectLater(lodgings.assign(w.id, [m.id, h.id]),
          throwsA(isA<LodgingIncompatibleException>()));
      // Todo o nada: ni siquiera la mujer (compatible) quedó asignada.
      expect(await lodgingOf(m.id), isNull);
      expect(await lodgingOf(h.id), isNull);
      await lodgings.assign(w.id, [m.id]);
      expect(await lodgingOf(m.id), w.id);
    });

    test('una mujer no entra en un hospedaje de hombres', () async {
      final h = await lodging('Casa H', LodgingAccepts.men);
      final m = await person('Ana', Sex.female);
      await expectLater(lodgings.assign(h.id, [m.id]),
          throwsA(isA<LodgingIncompatibleException>()));
      expect(await lodgingOf(m.id), isNull);
    });

    test('«sin preferencia» acepta hombres, mujeres y solteros', () async {
      final a = await lodging('Casa Abierta', LodgingAccepts.any);
      final h = await person('Juan', Sex.male);
      final m = await person('Ana', Sex.female);
      await lodgings.assign(a.id, [h.id, m.id]);
      expect(await lodgingOf(h.id), a.id);
      expect(await lodgingOf(m.id), a.id);
    });

    test('matrimonios: un soltero se rechaza; el matrimonio entra junto',
        () async {
      final c = await lodging('Cabaña', LodgingAccepts.couples);
      final h = await person('Juan', Sex.male);
      final m = await person('Ana', Sex.female);
      final solo = await person('Pedro', Sex.male);
      await expectLater(lodgings.assign(c.id, [solo.id]),
          throwsA(isA<LodgingIncompatibleException>()));
      await social.setSpouse(h.id, m.id);
      // Un solo cónyuge, con el otro fuera: no.
      await expectLater(lodgings.assign(c.id, [h.id]),
          throwsA(isA<LodgingIncompatibleException>()));
      await lodgings.assign(c.id, [h.id, m.id]);
      expect(await lodgingOf(h.id), c.id);
      expect(await lodgingOf(m.id), c.id);
    });

    test('matrimonios: si el cónyuge ya está dentro, el otro puede entrar solo',
        () async {
      final c = await lodging('Cabaña', LodgingAccepts.couples);
      final h = await person('Juan', Sex.male);
      final m = await person('Ana', Sex.female);
      await social.setSpouse(h.id, m.id);
      await lodgings.assign(c.id, [h.id, m.id]);
      await lodgings.unassign([m.id]);
      // El esposo sigue allí; ella vuelve sola y se acepta porque él ya está dentro.
      await lodgings.assign(c.id, [m.id]);
      expect(await lodgingOf(m.id), c.id);
    });

    test('la capacidad NO bloquea (sigue siendo un aviso de la pantalla)',
        () async {
      final a = await lodging('Chica', LodgingAccepts.men, cap: 1);
      final p1 = await person('Juan', Sex.male);
      final p2 = await person('Luis', Sex.male);
      await lodgings.assign(a.id, [p1.id, p2.id]);
      expect(await lodgingOf(p2.id), a.id);
    });

    test('compatibilityProblems no escribe y explica el motivo', () async {
      final w = await lodging('Casa M', LodgingAccepts.women);
      final h = await person('Juan', Sex.male);
      final problems = await lodgings.compatibilityProblems(w.id, [h.id]);
      expect(problems.single, contains('solo acepta mujeres'));
      expect(await lodgingOf(h.id), isNull);
    });
  });

  group('editar el hospedaje (única salida)', () {
    test('cambiar «acepta» permite lo que antes se bloqueaba', () async {
      final l = await lodging('Casa', LodgingAccepts.women);
      final h = await person('Juan', Sex.male);
      await expectLater(lodgings.assign(l.id, [h.id]),
          throwsA(isA<LodgingIncompatibleException>()));
      await lodgings.save(
          id: l.id,
          eventId: ev,
          name: 'Casa',
          kind: 'shelter',
          capacity: 6,
          accepts: LodgingAccepts.any);
      await lodgings.assign(l.id, [h.id]);
      expect(await lodgingOf(h.id), l.id);
    });

    test('ocupantes que quedan incompatibles: se listan, NO se borran',
        () async {
      final l = await lodging('Casa', LodgingAccepts.any);
      final h = await person('Juan', Sex.male);
      final m = await person('Ana', Sex.female);
      await lodgings.assign(l.id, [h.id, m.id]);
      expect(await lodgings.incompatibleOccupants(l.id), isEmpty);
      await lodgings.save(
          id: l.id,
          eventId: ev,
          name: 'Casa',
          kind: 'shelter',
          capacity: 6,
          accepts: LodgingAccepts.women);
      final bad = await lodgings.incompatibleOccupants(l.id);
      expect(bad.map((a) => a.id), [h.id]);
      // Sigue hospedado: no se borró ni movió nada.
      expect(await lodgingOf(h.id), l.id);
      expect(await lodgingOf(m.id), l.id);
    });

    test('matrimonios: separar a la pareja deja al que queda como incompatible',
        () async {
      final l = await lodging('Cabaña', LodgingAccepts.couples);
      final h = await person('Juan', Sex.male);
      final m = await person('Ana', Sex.female);
      await social.setSpouse(h.id, m.id);
      await lodgings.assign(l.id, [h.id, m.id]);
      expect(await lodgings.incompatibleOccupants(l.id), isEmpty);
      await lodgings.unassign([m.id]);
      expect((await lodgings.incompatibleOccupants(l.id)).map((a) => a.id),
          [h.id]);
    });
  });

  test(
      'cambiar el sexo de alguien hospedado en un hospedaje de un solo sexo se rechaza',
      () async {
    final l = await lodging('Casa H', LodgingAccepts.men);
    final h = await person('Juan', Sex.male);
    await lodgings.assign(l.id, [h.id]);
    await expectLater(
        repo.updateAttendee(h.id,
            firstName: 'Juan',
            lastName1: 'Prueba',
            sex: Sex.female,
            age: 30,
            churchId: churchId),
        throwsA(isA<LodgingIncompatibleException>()));
    // Se revirtió: sigue siendo hombre.
    expect((await repo.attendeeById(h.id))!.sex, 'M');
  });

  group('importación CSV', () {
    Future<ImportReport> import(String csv) async {
      final ex = AttendeeExchange(db);
      final plan = await ex.plan(ev, parseAttendeesCsv(csv));
      return ex.apply(ev, plan, asPreregistered: false);
    }

    test(
        'la fila incompatible queda sin hospedaje y con aviso; la compatible entra',
        () async {
      final l = await lodging('Casa Mujeres', LodgingAccepts.women);
      List<String> row(String first, String sex) {
        final v = {
          'nombre': first,
          'apellido1': 'Importado',
          'sexo': sex,
          'edad': '30',
          'iglesia': 'Bautista',
          'hospedaje': 'Casa Mujeres',
        };
        return [for (final c in attendeeCsvHeaders) v[c] ?? ''];
      }

      final rep = await import(buildCsvDelimited([
        List<String>.of(attendeeCsvHeaders),
        row('Ana', 'F'),
        row('Juan', 'M'),
      ]));
      expect(rep.created, 2);
      expect(
          rep.warnings.where((w) => w.contains('sin hospedaje')), hasLength(1));
      final occupants = await lodgings.occupants(l.id);
      expect(occupants.map((a) => a.firstName), ['Ana']);
    });
  });

  test('duplicar evento: quien no encaja queda sin hospedaje en la copia',
      () async {
    // Dato «viejo» incompatible (de antes del bloqueo), escrito directo.
    final l = await lodging('Casa H', LodgingAccepts.men);
    final h = await person('Juan', Sex.male);
    final m = await person('Ana', Sex.female);
    await lodgings.assign(l.id, [h.id]);
    await (db.update(db.attendees)..where((a) => a.id.equals(m.id)))
        .write(AttendeesCompanion(lodgingId: Value(l.id)));
    final copier = EventCopy(db);
    final newId = await copier.duplicateEvent(ev,
        name: 'Copia',
        startDate: '2027-01-01',
        endDate: '2027-01-02',
        options: const DuplicateOptions(people: true, lodgings: true));
    expect(copier.lastUnassignedForCompatibility, 1);
    final copy = await (db.select(db.attendees)
          ..where((a) => a.eventId.equals(newId)))
        .get();
    expect(copy.firstWhere((a) => a.firstName == 'Juan').lodgingId, isNotNull);
    expect(copy.firstWhere((a) => a.firstName == 'Ana').lodgingId, isNull);
  });
}
