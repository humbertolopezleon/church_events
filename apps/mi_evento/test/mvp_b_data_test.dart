import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/repos_b.dart';
import 'package:mi_evento/data/repository.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

void main() {
  late AppDatabase db;
  late Repository repo;
  late SocialRepo social;
  late LodgingRepo lodging;
  late TeamRepo teams;
  late String ev;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = Repository(db);
    social = SocialRepo(db);
    lodging = LodgingRepo(db);
    teams = TeamRepo(db);
    ev = await repo.createEvent(
        name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
  });
  tearDown(() => db.close());

  Future<AttendeeRow> add(String n, Sex s, int age, {String? event}) =>
      repo.addAttendee(
          eventId: event ?? ev, firstName: n, lastName1: 'X', sex: s, age: age);

  group('matrimonios', () {
    test('vincular, consultar el cónyuge y desvincular', () async {
      final a = await add('Juan', Sex.male, 34),
          b = await add('Ana', Sex.female, 30);
      await social.setSpouse(a.id, b.id);
      expect((await social.spouseOf(a.id))!.id, b.id);
      expect((await social.spouseOf(b.id))!.id, a.id); // simétrico
      expect(await social.spouseMap(ev), {a.id: b.id, b.id: a.id});
      await social.setSpouse(a.id, null);
      expect(await social.spouseOf(a.id), isNull);
      expect(await social.spouseOf(b.id), isNull);
      expect((await repo.attendeeById(b.id))!.coupleId, isNull);
    });
    test('no se puede con uno mismo, con otro evento, ni con alguien ya casado',
        () async {
      final a = await add('Juan', Sex.male, 34),
          b = await add('Ana', Sex.female, 30),
          c = await add('Eva', Sex.female, 28);
      expect(() => social.setSpouse(a.id, a.id), throwsA(isA<DataException>()));
      final ev2 = await repo.createEvent(
          name: 'Otro', startDate: '2026-01-01', endDate: '2026-01-02');
      final x = await add('Lia', Sex.female, 20, event: ev2);
      expect(() => social.setSpouse(a.id, x.id), throwsA(isA<DataException>()));
      await social.setSpouse(a.id, b.id);
      expect(() => social.setSpouse(c.id, b.id),
          throwsA(isA<DataException>())); // b ya tiene cónyuge
    });
    test('cambiar de cónyuge libera al anterior', () async {
      final a = await add('Juan', Sex.male, 34),
          b = await add('Ana', Sex.female, 30),
          c = await add('Eva', Sex.female, 28);
      await social.setSpouse(a.id, b.id);
      await social.setSpouse(a.id, c.id);
      expect((await social.spouseOf(a.id))!.id, c.id);
      expect(await social.spouseOf(b.id), isNull);
    });
  });

  group('grupos', () {
    test('crear, nombres únicos y miembros', () async {
      final g =
          await social.createGroup(ev, 'Jóvenes de Colón', reason: 'church');
      expect(() => social.createGroup(ev, '  jovenes de colon '),
          throwsA(isA<DataException>()));
      expect(() => social.createGroup(ev, ' '), throwsA(isA<DataException>()));
      final a = await add('Juan', Sex.male, 20),
          b = await add('Ana', Sex.female, 21);
      await social.setGroups(a.id, {g.id});
      await social.setGroups(b.id, {g.id});
      expect((await social.groupMembers(g.id)).map((r) => r.firstName),
          ['Juan', 'Ana']);
      expect((await social.watchGroups(ev).first).single.memberCount, 2);
      await social.setGroups(a.id, {}); // sale del grupo
      expect((await social.groupMembers(g.id)).single.firstName, 'Ana');
      expect(await social.groupIdsOf(b.id), {g.id});
    });
    test('un grupo vacío aparece con 0 integrantes', () async {
      await social.createGroup(ev, 'Vacío');
      expect((await social.watchGroups(ev).first).single.memberCount, 0);
    });
  });

  group('hospedajes', () {
    Future<LodgingRow> casa(
            {int cap = 4,
            LodgingAccepts a = LodgingAccepts.men,
            String name = 'Casa de Ramón'}) =>
        lodging.save(
            eventId: ev,
            name: name,
            kind: 'private_home',
            capacity: cap,
            accepts: a);

    test('validaciones: nombre, capacidad y nombre repetido', () async {
      expect(() => casa(name: ' '), throwsA(isA<DataException>()));
      expect(() => casa(cap: 0), throwsA(isA<DataException>()));
      expect(() => casa(cap: 501), throwsA(isA<DataException>()));
      await casa();
      expect(() => casa(name: 'casa de ramon'), throwsA(isA<DataException>()));
    });
    test('editar conserva el id y permite el mismo nombre', () async {
      final l = await casa();
      final u = await lodging.save(
          id: l.id,
          eventId: ev,
          name: 'Casa de Ramón',
          kind: 'private_home',
          capacity: 6,
          accepts: LodgingAccepts.couples,
          hostName: 'Ramón',
          contactPhone: ' ');
      expect(u.id, l.id);
      expect(u.capacity, 6);
      expect(u.accepts, 'couples');
      expect(u.contactPhone, isNull);
    });
    test('asignar, ocupación en vivo y quitar', () async {
      final l = await casa();
      final a = await add('Juan', Sex.male, 30),
          b = await add('Pedro', Sex.male, 31);
      await lodging.assign(l.id, [a.id, b.id]);
      var v = (await lodging.watchLodgings(ev).first).single;
      expect((v.occupied, v.free), (2, 2));
      expect((await lodging.occupants(l.id)).length, 2);
      await lodging.unassign([a.id]);
      v = (await lodging.watchLodgings(ev).first).single;
      expect(v.occupied, 1);
    });
    test('asignar más que la capacidad NO se bloquea (es un aviso de pantalla)',
        () async {
      final l = await casa(cap: 1);
      final a = await add('Juan', Sex.male, 30),
          b = await add('Pedro', Sex.male, 31);
      await lodging.assign(l.id, [a.id, b.id]);
      final v = (await lodging.watchLodgings(ev).first).single;
      expect(v.free, -1);
      expect(checkLodgingAssignment(v.slot, const [], alreadyThere: const []),
          isEmpty);
    });
    test('borrar el hospedaje deja a la gente sin asignar y no se cuenta',
        () async {
      final l = await casa();
      final a = await add('Juan', Sex.male, 30);
      await lodging.assign(l.id, [a.id]);
      expect(await lodging.delete(l.id), 1);
      expect((await repo.attendeeById(a.id))!.lodgingId, isNull);
      expect(await lodging.watchLodgings(ev).first, isEmpty);
    });
    test('personas eliminadas no cuentan en la ocupación', () async {
      final l = await casa();
      final a = await add('Juan', Sex.male, 30);
      await lodging.assign(l.id, [a.id]);
      await repo.deleteAttendee(a.id, isAdmin: true);
      expect((await lodging.watchLodgings(ev).first).single.occupied, 0);
    });
  });

  group('equipos', () {
    test('crear N con nombres y colores por defecto, y seguir numerando',
        () async {
      await teams.createMany(ev, 4);
      var t = await teams.watchTeams(ev).first;
      expect(t.map((x) => x.name), ['Rojo', 'Azul', 'Verde', 'Amarillo']);
      expect(t.first.color, '#C8453B');
      await teams.createMany(ev, 6);
      t = await teams.watchTeams(ev).first;
      expect(t.length, 10);
      expect(t[8].name, 'Equipo 9');
      expect(t[8].color, isNull);
      expect(() => teams.createMany(ev, 0), throwsA(isA<DataException>()));
      expect(() => teams.createMany(ev, 41), throwsA(isA<DataException>()));
    });
    test(
        'capitán: solo un integrante; al trasladarlo el equipo queda sin capitán',
        () async {
      await teams.createMany(ev, 2);
      final [rojo, azul] = await teams.watchTeams(ev).first;
      final a = await add('Juan', Sex.male, 30),
          b = await add('Pedro', Sex.male, 31);
      await teams.setTeam([a.id], rojo.id);
      expect(() => teams.update(rojo.id, name: 'Rojo', captainId: b.id),
          throwsA(isA<DataException>()));
      await teams.update(rojo.id,
          name: 'Rojo', color: rojo.color, captainId: a.id);
      expect((await teams.watchTeams(ev).first).first.captainId, a.id);
      await teams.setTeam([a.id], azul.id);
      expect((await teams.watchTeams(ev).first).first.captainId, isNull);
    });
    test('nombre repetido o vacío se rechaza al editar', () async {
      await teams.createMany(ev, 2);
      final [rojo, _] = await teams.watchTeams(ev).first;
      expect(() => teams.update(rojo.id, name: 'azul'),
          throwsA(isA<DataException>()));
      expect(() => teams.update(rojo.id, name: ' '),
          throwsA(isA<DataException>()));
    });
    test('asignar un grupo completo y quitar de equipo', () async {
      await teams.createMany(ev, 1);
      final t = (await teams.watchTeams(ev).first).single;
      final ps = [
        await add('A', Sex.male, 20),
        await add('B', Sex.female, 21),
        await add('C', Sex.male, 22)
      ];
      await teams.setTeam(ps.map((p) => p.id), t.id);
      expect(
          (await db.select(db.attendees).get()).every((a) => a.teamId == t.id),
          isTrue);
      await teams.setTeam([ps[0].id], null);
      expect((await repo.attendeeById(ps[0].id))!.teamId, isNull);
    });
    test('intercambio entre equipos y sus errores', () async {
      await teams.createMany(ev, 2);
      final [rojo, azul] = await teams.watchTeams(ev).first;
      final a = await add('A', Sex.male, 20),
          b = await add('B', Sex.female, 21),
          c = await add('C', Sex.male, 22),
          solo = await add('S', Sex.male, 30);
      await teams.setTeam([a.id, c.id], rojo.id);
      await teams.setTeam([b.id], azul.id);
      await teams.swap(a.id, b.id);
      expect((await repo.attendeeById(a.id))!.teamId, azul.id);
      expect((await repo.attendeeById(b.id))!.teamId, rojo.id);
      expect(() => teams.swap(a.id, solo.id),
          throwsA(isA<DataException>())); // sin equipo
      expect(() => teams.swap(b.id, c.id),
          throwsA(isA<DataException>())); // mismo equipo
    });
    test('borrar un equipo deja a sus integrantes sin equipo', () async {
      await teams.createMany(ev, 1);
      final t = (await teams.watchTeams(ev).first).single;
      final a = await add('A', Sex.male, 20);
      await teams.setTeam([a.id], t.id);
      expect(await teams.delete(t.id), 1);
      expect((await repo.attendeeById(a.id))!.teamId, isNull);
      expect(await teams.watchTeams(ev).first, isEmpty);
    });
    test('topes de balance por evento: por defecto y editables', () async {
      var e = await (db.select(db.events)).getSingle();
      expect((
        e.balanceLimits.maxSizeDiff,
        e.balanceLimits.maxSexDiff,
        e.balanceLimits.maxAgeDiff
      ), (
        2,
        4,
        3.0
      ));
      await teams.setLimits(ev,
          const BalanceLimits(maxSizeDiff: 5, maxSexDiff: 8, maxAgeDiff: 6.5));
      e = await (db.select(db.events)).getSingle();
      expect(e.balanceLimits.maxAgeDiff, 6.5);
      expect(() => teams.setLimits(ev, const BalanceLimits(maxSizeDiff: -1)),
          throwsA(isA<DataException>()));
    });
    test('el aviso de desbalance usa los datos reales (criterio C)', () async {
      await teams.createMany(ev, 2);
      final [rojo, azul] = await teams.watchTeams(ev).first;
      final rows = <AttendeeRow>[];
      for (var i = 0; i < 6; i++) {
        rows.add(await add('H$i', Sex.male, 25));
      }
      await teams.setTeam(rows.take(6).map((r) => r.id),
          rojo.id); // 6 hombres en Rojo, Azul vacío
      final all =
          (await db.select(db.attendees).get()).map((r) => r.toCore()).toList();
      final names = {rojo.id: 'Rojo', azul.id: 'Azul'};
      final issues =
          evaluateBalance(statsAfterMove(names, all, rows[0].id, rojo.id));
      expect(issues.map((i) => i.criterion),
          containsAll([BalanceCriterion.size, BalanceCriterion.sex]));
    });
  });
}
