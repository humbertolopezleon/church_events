import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/event_copy.dart';
import 'package:mi_evento/data/meal_repo.dart';
import 'package:mi_evento/data/repos_b.dart';
import 'package:mi_evento/data/repository.dart';
import 'package:mi_evento/providers.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'helpers.dart';

void main() {
  late AppDatabase db;
  late Repository repo;
  late String ev;
  late List<AttendeeRow> people;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = Repository(db);
    ev = await repo.createEvent(
        name: 'Congreso 2026', startDate: '2026-12-12', endDate: '2026-12-14');
    final ig = await repo.createChurch(name: 'Bautista', province: 'Matanzas');
    people = [
      for (final (n, s) in [
        ('Juan', Sex.male),
        ('Rosa', Sex.female),
        ('Pedro', Sex.male),
      ])
        await repo.addAttendee(
            eventId: ev,
            firstName: n,
            lastName1: 'Leyva',
            sex: s,
            age: 30,
            churchId: ig.id,
            needsLodging: true)
    ];
    final social = SocialRepo(db);
    await social.setSpouse(people[0].id, people[1].id);
    await social.createGroup(ev, 'Jóvenes');
    final g = (await db.select(db.attendeeGroups).get()).single;
    await social.setGroups(people[2].id, {g.id});
    final tr = TeamRepo(db);
    await tr.createMany(ev, 2);
    final teams = await db.select(db.teams).get();
    await tr.setTeam([people[0].id, people[1].id], teams[0].id);
    final lr = LodgingRepo(db);
    final l = await lr.save(
        eventId: ev,
        name: 'Casa',
        kind: 'private_home',
        capacity: 4,
        accepts: LodgingAccepts.any);
    await lr.assign(l.id, [people[0].id, people[1].id]);
    await MealRepo(db).createType(ev, 'Almuerzo');
  });
  tearDown(() => db.close());

  test(
      'duplicar con todo: ids nuevos, preinscritos, equipos, hospedajes, parejas y grupos',
      () async {
    final id = await EventCopy(db).duplicateEvent(ev,
        name: 'Congreso 2027', startDate: '2027-12-12', endDate: '2027-12-14');
    expect(id, isNot(ev));
    final e =
        await (db.select(db.events)..where((x) => x.id.equals(id))).getSingle();
    expect((e.name, e.startDate), ('Congreso 2027', '2027-12-12'));
    final got = await repo.watchAttendees(id).first;
    expect(got, hasLength(3));
    expect(got.every((v) => v.isPreregistered), isTrue);
    expect(got.map((v) => v.a.regNumber).toSet(), {1, 2, 3});
    expect(
        got
            .map((v) => v.a.id)
            .toSet()
            .intersection(people.map((p) => p.id).toSet()),
        isEmpty);
    // equipo y hospedaje de la copia son los NUEVOS, no los del original
    final newTeams = await db.select(db.teams).get();
    expect(newTeams.where((t) => t.eventId == id), hasLength(2));
    final juan = got.firstWhere((v) => v.a.firstName == 'Juan').a;
    expect(newTeams.firstWhere((t) => t.id == juan.teamId).eventId, id);
    final lod = await db.select(db.lodgings).get();
    expect(lod.firstWhere((l) => l.id == juan.lodgingId).eventId, id);
    // pareja y grupo
    final spouses = await SocialRepo(db).spouseMap(id);
    final rosa = got.firstWhere((v) => v.a.firstName == 'Rosa').a;
    expect(spouses[juan.id], rosa.id);
    final groups = (await db.select(db.attendeeGroups).get())
        .where((g) => g.eventId == id);
    expect(groups, hasLength(1));
    // tipos de control siempre; el original no se tocó
    expect(
        (await db.select(db.controlTypes).get()).where((t) => t.eventId == id),
        hasLength(1));
    expect(
        (await repo.watchAttendees(ev).first).every((v) => !v.isPreregistered),
        isTrue);
  });

  test('duplicar solo la estructura (sin participantes) y sin preinscribir',
      () async {
    final id = await EventCopy(db).duplicateEvent(ev,
        name: 'Plantilla',
        startDate: '2027-01-01',
        endDate: '2027-01-02',
        options: const DuplicateOptions(people: false, lodgings: false));
    expect(await repo.watchAttendees(id).first, isEmpty);
    expect((await db.select(db.teams).get()).where((t) => t.eventId == id),
        hasLength(2));
    expect((await db.select(db.lodgings).get()).where((l) => l.eventId == id),
        isEmpty);
    final id2 = await EventCopy(db).duplicateEvent(ev,
        name: 'Igual',
        startDate: '2027-01-01',
        endDate: '2027-01-02',
        options: const DuplicateOptions(preregister: false, teams: false));
    final got = await repo.watchAttendees(id2).first;
    expect(got.every((v) => !v.isPreregistered), isTrue);
    expect(got.every((v) => v.a.teamId == null), isTrue);
    expect(got.where((v) => v.a.lodgingId != null), hasLength(2));
  });

  test('duplicar valida nombre y fechas', () async {
    expect(
        () => EventCopy(db).duplicateEvent(ev,
            name: ' ', startDate: '2027-01-01', endDate: '2027-01-02'),
        throwsA(isA<DataException>()));
    expect(
        () => EventCopy(db).duplicateEvent(ev,
            name: 'X', startDate: '2027-01-05', endDate: '2027-01-02'),
        throwsA(isA<DataException>()));
  });

  test(
      'pasar participantes a un evento existente: omite repetidos y conserva matrimonios',
      () async {
    final ev2 = await repo.createEvent(
        name: 'Otro', startDate: '2027-02-01', endDate: '2027-02-02');
    await repo.addAttendee(
        eventId: ev2,
        firstName: 'Pedro',
        lastName1: 'Leyva',
        sex: Sex.male,
        age: 30);
    final rep = await EventCopy(db).copyPeople(ev, ev2);
    expect((rep.copied, rep.skipped, rep.couples), (2, 1, 1));
    final got = await repo.watchAttendees(ev2).first;
    expect(got, hasLength(3));
    expect(got.where((v) => v.isPreregistered), hasLength(2));
    expect(
        got.every((v) => v.a.teamId == null && v.a.lodgingId == null), isTrue);
    expect(
        () => EventCopy(db).copyPeople(ev, ev), throwsA(isA<DataException>()));
  });

  test('reportes y comidas cuentan solo a los confirmados', () async {
    await repo.addAttendee(
        eventId: ev,
        firstName: 'Pre',
        lastName1: 'Inscrito',
        sex: Sex.male,
        age: 20,
        preregistered: true);
    final c =
        ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(c.dispose);
    await c.read(attendeesProvider(ev).future);
    final conf = c.read(confirmedAttendeesProvider(ev)).value!;
    expect(conf, hasLength(3));
    expect(conf.any((v) => v.isPreregistered), isFalse);

    final meal = MealRepo(db);
    final t = (await db.select(db.controlTypes).get()).single;
    final s = await meal.createSession(ev, t.id, 'Almuerzo sábado',
        operatorName: 'Ana');
    final pre = (await db.select(db.attendees).get())
        .firstWhere((a) => a.firstName == 'Pre');
    await expectLater(meal.mark(s.id, pre.id, operatorName: 'Ana'),
        throwsA(isA<DataException>()));
    await Repository(db).confirmAttendance([pre.id]);
    final r = await meal.mark(s.id, pre.id, operatorName: 'Ana');
    expect(r, isNotNull);
  });

  testWidgets('menú del evento: Duplicar evento crea la copia y la abre',
      (t) async {
    final c = await pumpApp(t, const Size(1200, 2400));
    await t.runAsync(() async {
      await c.repo.createEvent(
          name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
    });
    await login(t, 'admin', 'secreto1');
    await t.tap(find.byKey(const Key('evento-menu-Retiro')));
    await settle(t);
    await t.tap(find.text('Duplicar evento…'));
    await settle(t);
    expect(find.byKey(const Key('dup-dialogo')), findsOneWidget);
    await tapKey(t, 'dup-guardar');
    final evs = (await t.runAsync(() => c.db.select(c.db.events).get()))!;
    expect(evs.map((e) => e.name), containsAll(['Retiro', 'Retiro (copia)']));
  });
}
