import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/repos_b.dart';
import 'package:mi_evento/data/repository.dart';
import 'package:mi_evento/data/team_pieces.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

void main() {
  late AppDatabase db;
  late Repository repo;
  late SocialRepo social;
  late TeamRepo teams;
  late String ev;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = Repository(db);
    social = SocialRepo(db);
    teams = TeamRepo(db);
    ev = await repo.createEvent(
        name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
  });
  tearDown(() => db.close());

  Future<AttendeeRow> add(String n, Sex s, int age) => repo.addAttendee(
      eventId: ev, firstName: n, lastName1: 'X', sex: s, age: age);
  Future<List<AttendeeRow>> all() => db.select(db.attendees).get();

  group('piezas', () {
    test('un matrimonio es una sola pieza; los demás van sueltos', () async {
      final a = await add('Juan', Sex.male, 34);
      final b = await add('Ana', Sex.female, 30);
      await add('Luis', Sex.male, 20);
      await social.setSpouse(a.id, b.id);
      final r = buildTeamPieces(await all(),
          spouses: await social.spouseMap(ev),
          together: const [],
          includeAssigned: false);
      expect(r.pieces, hasLength(2));
      expect(r.pieces.map((p) => p.size).toList()..sort(), [1, 2]);
      expect(r.pieces.firstWhere((p) => p.size == 2).label,
          contains('Matrimonio'));
    });

    test('un grupo «mantener juntos» es una pieza; uno sin esa marca, no',
        () async {
      final a = await add('A', Sex.male, 20);
      final b = await add('B', Sex.male, 21);
      final c = await add('C', Sex.female, 22);
      final g = await social.createGroup(ev, 'Jóvenes', keepTogether: true);
      final loose = await social.createGroup(ev, 'Amigos', keepTogether: false);
      for (final p in [a, b, c]) {
        await social.setGroups(p.id, {g.id});
      }
      await social.setGroups(a.id, {g.id, loose.id});
      expect(await social.togetherSets(ev), [
        {a.id, b.id, c.id}
      ]);
      final r = buildTeamPieces(await all(),
          spouses: const {},
          together: await social.togetherSets(ev),
          includeAssigned: false);
      expect(r.pieces.single.size, 3);
    });

    test('matrimonio dentro de un grupo: todo el conjunto va junto', () async {
      final a = await add('A', Sex.male, 30);
      final b = await add('B', Sex.female, 30);
      final c = await add('C', Sex.male, 18);
      await social.setSpouse(a.id, b.id);
      final r = buildTeamPieces(await all(),
          spouses: await social.spouseMap(ev),
          together: [
            {b.id, c.id}
          ],
          includeAssigned: false);
      expect(r.pieces.single.size, 3);
    });

    test('solo se reparte a quien no tiene equipo, salvo que se pida todo',
        () async {
      final a = await add('A', Sex.male, 30);
      await add('B', Sex.female, 30);
      await teams.createMany(ev, 1);
      final t = (await db.select(db.teams).get()).single;
      await teams.setTeam([a.id], t.id);
      final some = buildTeamPieces(await all(),
          spouses: const {}, together: const [], includeAssigned: false);
      expect(some.pieces, hasLength(1));
      expect(some.fixed.map((p) => p.id), [a.id]);
      final every = buildTeamPieces(await all(),
          spouses: const {}, together: const [], includeAssigned: true);
      expect(every.pieces, hasLength(2));
      expect(every.fixed, isEmpty);
    });
  });

  group('aplicar y deshacer', () {
    test(
        'applyPlan asigna y restoreTeams devuelve a cada quien a su equipo anterior',
        () async {
      final a = await add('A', Sex.male, 30);
      final b = await add('B', Sex.female, 30);
      await teams.createMany(ev, 2);
      final ts = await db.select(db.teams).get();
      await teams.setTeam([a.id], ts.first.id); // A ya estaba en el primero
      final prev = await teams.applyPlan({a.id: ts.last.id, b.id: ts.first.id});
      expect(prev, {a.id: ts.first.id, b.id: null});
      var rows = {for (final r in await all()) r.id: r.teamId};
      expect(rows, {a.id: ts.last.id, b.id: ts.first.id});
      await teams.restoreTeams(prev);
      rows = {for (final r in await all()) r.id: r.teamId};
      expect(rows, {a.id: ts.first.id, b.id: null});
    });
  });
}
