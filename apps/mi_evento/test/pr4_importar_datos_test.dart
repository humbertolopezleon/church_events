import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_evento/data/attendance_exchange.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/event_exchange.dart';
import 'package:mi_evento/data/lodging_exchange.dart';
import 'package:mi_evento/data/repos_b.dart';
import 'package:mi_evento/data/repository.dart';
import 'package:mi_evento/data/team_exchange.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

void main() {
  late AppDatabase db;
  late Repository repo;
  late String ev, church;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = Repository(db);
    ev = await repo.createEvent(
        name: 'E', startDate: '2026-01-01', endDate: '2026-01-02');
    church = (await repo.createChurch(name: 'B', province: 'Matanzas')).id;
  });
  tearDown(() => db.close());

  Future<AttendeeRow> person(String n, Sex s) => repo.addAttendee(
      eventId: ev,
      firstName: n,
      lastName1: 'X',
      sex: s,
      age: 30,
      churchId: church);

  group('hospedajes: exportar → importar', () {
    test('ida y vuelta: lo exportado se importa sin cambios', () async {
      final lr = LodgingRepo(db);
      await lr.save(
          eventId: ev,
          name: 'Casa Norte',
          kind: 'private_home',
          capacity: 4,
          accepts: LodgingAccepts.women,
          hostName: 'Teresa',
          contactPhone: '555-1',
          directions: 'Calle 1',
          distanceNote: 'A 5 min');
      final exported = [
        LodgingExchange.headers,
        [
          'Casa Norte',
          'Casa particular',
          'Solo mujeres',
          '4',
          '0',
          '4',
          'Teresa',
          '555-1',
          'Calle 1',
          'A 5 min'
        ],
      ];
      final ex = LodgingExchange(db, ev);
      final csv = buildCsvDelimited(exported);
      final pre = await ex.preview(csv);
      expect(pre.warnings, isEmpty);
      expect(pre.work, 1); // existe: se «actualiza» con los mismos datos
      await ex.apply(csv);
      final rows = await db.select(db.lodgings).get();
      expect(rows, hasLength(1));
      expect(rows.single.accepts, 'women');
    });

    test('crea nuevos, valida filas y avisa de ocupantes que dejan de encajar',
        () async {
      final lr = LodgingRepo(db);
      final l = await lr.save(
          eventId: ev,
          name: 'Mixta',
          kind: 'shelter',
          capacity: 4,
          accepts: LodgingAccepts.any);
      final h = await person('Juan', Sex.male);
      await lr.assign(l.id, [h.id]);
      final csv = buildCsvDelimited([
        LodgingExchange.headers,
        ['Mixta', '', 'Solo mujeres', '4', '', '', '', '', '', ''],
        ['Nueva', 'Albergue', '', '10', '', '', '', '', '', ''],
        ['Mala', 'Albergue', 'Solo robots', '3', '', '', '', '', '', ''],
        ['SinCap', 'Albergue', '', 'abc', '', '', '', '', '', ''],
      ]);
      final ex = LodgingExchange(db, ev);
      final pre = await ex.preview(csv);
      expect(pre.work, 2);
      expect(pre.warnings, hasLength(2));
      final done = await ex.apply(csv);
      expect(done.lines.join(' '), contains('ya no encaja'));
      final rows = await db.select(db.lodgings).get();
      expect(rows.map((x) => x.name).toSet(), {'Mixta', 'Nueva'});
      // Nadie se quitó: Juan sigue en «Mixta».
      expect((await repo.attendeeById(h.id))!.lodgingId, l.id);
    });
  });

  group('equipos: exportar → importar', () {
    test('asigna por número, crea equipos que faltan y «Sin equipo» limpia',
        () async {
      final a = await person('Ana', Sex.female);
      final b = await person('Beto', Sex.male);
      final c = await person('Carla', Sex.female);
      final tr = TeamRepo(db);
      await tr.createMany(ev, 1);
      final t1 = (await db.select(db.teams).get()).single;
      await tr.setTeam([c.id], t1.id);
      final csv = buildCsvDelimited([
        TeamExchange.headers,
        [t1.name, '${a.regNumber}', 'Ana X', 'Mujer', '30', 'B'],
        ['Los Halcones', '${b.regNumber}', 'Beto X', 'Hombre', '30', 'B'],
        ['Sin equipo', '${c.regNumber}', 'Carla X', 'Mujer', '30', 'B'],
        ['Fantasma', '99', '', '', '', ''],
      ]);
      final ex = TeamExchange(db, ev);
      final pre = await ex.preview(csv);
      expect(pre.warnings, hasLength(1));
      expect(pre.work, 3);
      await ex.apply(csv);
      final teams = await db.select(db.teams).get();
      expect(teams.map((t) => t.name), containsAll([t1.name, 'Los Halcones']));
      expect((await repo.attendeeById(a.id))!.teamId, t1.id);
      final halcones = teams.firstWhere((t) => t.name == 'Los Halcones');
      expect((await repo.attendeeById(b.id))!.teamId, halcones.id);
      expect((await repo.attendeeById(c.id))!.teamId, isNull);
    });
  });

  group('eventos y confirmaciones', () {
    test('eventos: crea, omite repetidos y valida fechas', () async {
      final ex = EventExchange(db);
      final csv = buildCsvDelimited([
        EventExchange.headers,
        ['E', '2026-01-01', '2026-01-02', '', '', 'Sí', 'Sí'], // ya existe
        ['Nuevo', '2027-02-01', '2027-02-03', 'Templo', 'Ana', 'No', 'Sí'],
        ['Mal', '1/2/2027', '2027-02-03', '', '', '', ''],
        ['Al revés', '2027-02-03', '2027-02-01', '', '', '', ''],
      ]);
      final pre = await ex.preview(csv);
      expect(pre.work, 1);
      expect(pre.warnings, hasLength(2));
      await ex.apply(csv);
      final evs = await db.select(db.events).get();
      expect(evs.map((e) => e.name).toSet(), {'E', 'Nuevo'});
      expect(evs.firstWhere((e) => e.name == 'Nuevo').offersLodging, isFalse);
    });

    test(
        'confirmar asistencia desde CSV: por número y respetando la columna estado',
        () async {
      final a = await repo.addAttendee(
          eventId: ev,
          firstName: 'Ana',
          lastName1: 'X',
          sex: Sex.female,
          age: 30,
          preregistered: true);
      final b = await repo.addAttendee(
          eventId: ev,
          firstName: 'Beto',
          lastName1: 'Y',
          sex: Sex.male,
          age: 30,
          preregistered: true);
      final ex = AttendanceExchange(db, ev);
      final csv = buildCsvDelimited([
        ['numero', 'nombre', 'estado'],
        ['${a.regNumber}', 'Ana X', 'Confirmado'],
        ['${b.regNumber}', 'Beto Y', 'Preinscrito'],
        ['99', 'Nadie', 'Confirmado'],
      ]);
      final pre = await ex.preview(csv);
      expect(pre.work, 1);
      expect(pre.warnings, hasLength(1));
      await ex.apply(csv);
      expect((await repo.attendeeById(a.id))!.status, 'confirmed');
      expect((await repo.attendeeById(b.id))!.status, 'preregistered');
    });
  });
}
