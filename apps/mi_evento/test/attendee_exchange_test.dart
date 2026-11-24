import 'package:drift/drift.dart' show OrderingTerm;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_evento/data/attendee_exchange.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/repos_b.dart';
import 'package:mi_evento/data/repository.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

void main() {
  late AppDatabase db;
  late Repository repo;
  late AttendeeExchange ex;
  late String ev;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = Repository(db);
    ex = AttendeeExchange(db);
    ev = await repo.createEvent(
        name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
  });
  tearDown(() => db.close());

  Future<List<AttendeeRow>> all([String? event]) => (db.select(db.attendees)
        ..where((a) => a.eventId.equals(event ?? ev))
        ..orderBy([(a) => OrderingTerm.asc(a.regNumber)]))
      .get();

  Future<ImportReport> importText(String text,
      {String? event, bool dup = false}) async {
    final e = event ?? ev;
    final plan =
        await ex.plan(e, parseAttendeesCsv(text), includeDuplicates: dup);
    return ex.apply(e, plan);
  }

  /// Evento con iglesia, hospedaje, equipos, una pareja y un grupo.
  Future<void> seed() async {
    final church = await repo.createChurch(
        name: 'Bautista Ebenezer',
        province: 'Matanzas',
        municipality: 'Cárdenas');
    Future<AttendeeRow> add(String n, Sex s, int age,
            {bool lodging = false, String last2 = ''}) =>
        repo.addAttendee(
            eventId: ev,
            firstName: n,
            lastName1: 'Pérez',
            lastName2: last2,
            sex: s,
            age: age,
            churchId: church.id,
            phone: '555-1',
            needsLodging: lodging,
            notes: 'Dice "hola"; ok');
    final juan = await add('Juan', Sex.male, 34);
    final ana = await add('Ana', Sex.female, 30, lodging: true, last2: 'Gómez');
    final luis = await add('Luis', Sex.male, 19);
    await SocialRepo(db).setSpouse(juan.id, ana.id);
    final l = await LodgingRepo(db).save(
        eventId: ev,
        name: 'Casa de Teresa',
        kind: 'private_home',
        capacity: 4,
        accepts: LodgingAccepts.couples);
    await LodgingRepo(db).assign(l.id, [juan.id, ana.id]);
    await TeamRepo(db).createMany(ev, 2);
    final t = (await db.select(db.teams).get()).first;
    await TeamRepo(db).setTeam([luis.id], t.id);
    final g = await SocialRepo(db).createGroup(ev, 'Jóvenes');
    await SocialRepo(db).setGroups(luis.id, {g.id});
  }

  group('exportar', () {
    test('las columnas son las del sistema y los nombres se escriben legibles',
        () async {
      await seed();
      final t = parseCsv(await ex.exportCsv(ev));
      expect(t.first, attendeeCsvHeaders);
      expect(t, hasLength(4));
      final ana = t.firstWhere((r) => r[2] == 'Ana');
      expect(ana[3], 'Pérez');
      expect(ana[4], 'Gómez');
      expect(ana[5], 'Mujer');
      expect(ana[7], 'Bautista Ebenezer');
      expect(ana[11], 'Sí');
      expect(ana[12], 'Casa de Teresa');
      expect(ana[14], '1'); // pareja: número de Juan
      expect(t.firstWhere((r) => r[2] == 'Luis')[15], 'Jóvenes');
      expect(t.firstWhere((r) => r[2] == 'Luis')[13], isNotEmpty); // equipo
      expect(ana[16], 'Dice "hola"; ok');
      expect(ana.last, 'Confirmado'); // comillas y «;» sobreviven
    });

    test('la plantilla es solo la fila de títulos y se puede leer', () {
      final t = parseCsv(AttendeeExchange.template());
      expect(t, [attendeeCsvHeaders]);
    });

    test('lo exportado lleva BOM (Excel respeta las tildes)', () async {
      await seed();
      expect((await ex.exportCsv(ev)).codeUnitAt(0), 0xFEFF);
    });
  });

  group('importar', () {
    test('exportar → importar en el mismo evento actualiza sin duplicar nada',
        () async {
      await seed();
      final text = await ex.exportCsv(ev);
      final plan = await ex.plan(ev, parseAttendeesCsv(text));
      expect(plan.updates, 3);
      expect(plan.creates, 0);
      final rep = await ex.apply(ev, plan);
      expect(rep.updated, 3);
      expect(await all(), hasLength(3));
      final ana = (await all()).firstWhere((a) => a.firstName == 'Ana');
      expect(ana.lodgingId, isNotNull);
      expect(ana.coupleId, isNotNull); // la pareja sigue
    });

    test('exportar de un evento e importar en otro conserva todo por nombre',
        () async {
      await seed();
      final text = await ex.exportCsv(ev);
      final ev2 = await repo.createEvent(
          name: 'Otro', startDate: '2027-01-01', endDate: '2027-01-02');
      // El evento nuevo ya tiene sus hospedajes y equipos con los mismos nombres.
      await LodgingRepo(db).save(
          eventId: ev2,
          name: 'Casa de Teresa',
          kind: 'private_home',
          capacity: 4,
          accepts: LodgingAccepts.couples);
      await TeamRepo(db).createMany(ev2, 2);
      final rep = await importText(text, event: ev2);
      expect(rep.created, 3);
      final people = await all(ev2);
      expect(people.map((a) => a.firstName), ['Juan', 'Ana', 'Luis']);
      expect(people[0].lodgingId, isNotNull);
      expect(people[1].lodgingId, people[0].lodgingId);
      expect(people[1].coupleId, isNotNull);
      expect(people[1].lastName2, 'Gómez');
      expect(people[2].teamId, isNotNull);
      expect(rep.churchesCreated, 0); // la iglesia ya existía en el catálogo
      expect(rep.groupsCreated, 1); // «Jóvenes» se crea en el evento nuevo
    });

    test('seguir registrando desde Excel: filas nuevas sin id ni número',
        () async {
      await seed();
      final rep = await importText('${attendeeCsvHeaders.join(';')}\n'
          ';;Rosa;Cruz;;Mujer;22;Iglesia Nueva;Matanzas;Colón;;Sí;;;;;\n'
          ';;Pedro;Cruz;;H;45;Bautista Ebenezer;;;;;;;;;');
      expect(rep.created, 2);
      expect(rep.churchesCreated, 1);
      final people = await all();
      expect(people, hasLength(5));
      expect(people.map((a) => a.regNumber),
          [1, 2, 3, 4, 5]); // numeración seguida
      final rosa = people.firstWhere((a) => a.firstName == 'Rosa');
      expect(rosa.needsLodging, isTrue);
      expect(rosa.municipality, 'Colón');
      expect(rosa.churchId, isNotNull);
    });

    test('columnas mínimas, en otro orden', () async {
      final rep = await importText(
          'Iglesia;Edad;Sexo;Primer apellido;Nombre\nCentral;30;Mujer;López;Eva');
      expect(rep.created, 1);
      expect((await all()).single.firstName, 'Eva');
    });

    test('posibles duplicados se omiten, salvo que se pida incluirlos',
        () async {
      await seed();
      const row = ';;Juan;Pérez;;Hombre;34;Bautista Ebenezer;;;;;;;;;';
      final text = '${attendeeCsvHeaders.join(';')}\n$row';
      final plan = await ex.plan(ev, parseAttendeesCsv(text));
      expect(plan.duplicates, 1);
      expect(plan.hasWork, isFalse);
      expect((await importText(text)).skipped, 1);
      expect(await all(), hasLength(3));
      expect((await importText(text, dup: true)).created, 1);
      expect(await all(), hasLength(4));
    });

    test('repetida dentro del mismo archivo: solo entra una', () async {
      final text = '${attendeeCsvHeaders.join(';')}\n'
          ';;Eva;López;;Mujer;30;Central;;;;;;;;;\n'
          ';;eva;LOPEZ;;Mujer;30;Central;;;;;;;;;';
      final rep = await importText(text);
      expect(rep.created, 1);
      expect(rep.skipped, 1);
    });

    test(
        'hospedaje o equipo que no existen: aviso y la persona se importa sin eso',
        () async {
      final text = '${attendeeCsvHeaders.join(';')}\n'
          ';;Eva;López;;Mujer;30;Central;;;;;Casa Fantasma;Equipo X;;;';
      final plan = await ex.plan(ev, parseAttendeesCsv(text));
      expect(plan.warnings.join(' '), contains('Casa Fantasma'));
      expect(plan.warnings.join(' '), contains('Equipo X'));
      await ex.apply(ev, plan);
      final eva = (await all()).single;
      expect(eva.lodgingId, isNull);
      expect(eva.teamId, isNull);
    });

    test('pareja por número entre filas nuevas del mismo archivo', () async {
      final text = '${attendeeCsvHeaders.join(';')}\n'
          ';1;Luis;Gil;;Hombre;30;Central;;;;;;;2;;\n'
          ';2;Eva;Gil;;Mujer;28;Central;;;;;;;1;;';
      final rep = await importText(text);
      expect(rep.created, 2);
      final people = await all();
      expect(people.every((a) => a.coupleId != null), isTrue);
      expect(people[0].coupleId, people[1].coupleId);
    });

    test('pareja inexistente: aviso, no error', () async {
      final text = '${attendeeCsvHeaders.join(';')}\n'
          ';;Luis;Gil;;Hombre;30;Central;;;;;;;99;;';
      final rep = await importText(text);
      expect(rep.created, 1);
      expect(rep.warnings.single, contains('99'));
    });

    test(
        'un número ya usado por otra persona: se crea como nueva con otro número',
        () async {
      await seed();
      final text = '${attendeeCsvHeaders.join(';')}\n'
          ';1;Mario;Rey;;Hombre;40;Central;;;;;;;;;'; // el 1 es Juan
      final plan = await ex.plan(ev, parseAttendeesCsv(text));
      expect(plan.items.single.action, PlanAction.create);
      expect(plan.items.single.note, contains('ya es de Juan'));
      await ex.apply(ev, plan);
      expect((await all()).last.regNumber, 4);
    });

    test(
        'con filas con errores, las buenas se importan y las malas se reportan',
        () async {
      final text = '${attendeeCsvHeaders.join(';')}\n'
          ';;Eva;López;;Mujer;30;Central;;;;;;;;;\n'
          ';;;López;;Mujer;30;Central;;;;;;;;;';
      final plan = await ex.plan(ev, parseAttendeesCsv(text));
      expect(plan.errors, hasLength(1));
      expect(plan.errors.single.line, 3);
      await ex.apply(ev, plan);
      expect(await all(), hasLength(1));
    });

    test('un cambio en Excel actualiza a la persona (por id)', () async {
      await seed();
      final text = (await ex.exportCsv(ev))
          .replaceFirst(';Luis;', ';Luisito;')
          .replaceFirst(';19;', ';20;');
      await importText(text);
      final luis = (await all()).firstWhere((a) => a.regNumber == 3);
      expect(luis.firstName, 'Luisito');
      expect(luis.age, 20);
      expect(await all(), hasLength(3));
    });
  });
}
