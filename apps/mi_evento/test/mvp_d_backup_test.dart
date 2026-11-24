import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_evento/backup/backup_service.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/meal_repo.dart';
import 'package:mi_evento/data/repos_b.dart';
import 'package:mi_evento/data/repository.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

/// Un «dispositivo»: base en memoria con sus repositorios.
class Dev {
  Dev() : db = AppDatabase(NativeDatabase.memory()) {
    repo = Repository(db);
    social = SocialRepo(db);
    lodging = LodgingRepo(db);
    teams = TeamRepo(db);
    meals = MealRepo(db);
    backup = BackupService(db);
  }
  final AppDatabase db;
  late Repository repo;
  late SocialRepo social;
  late LodgingRepo lodging;
  late TeamRepo teams;
  late MealRepo meals;
  late BackupService backup;
}

/// Un evento completo: iglesia, 4 asistentes (pareja, grupo, hospedaje, equipo) y una sesión con marcas.
Future<String> fullEvent(Dev d) async {
  final ev = await d.repo.createEvent(
      name: 'Retiro de Jóvenes',
      startDate: '2026-12-12',
      endDate: '2026-12-14');
  final ig = await d.repo.createChurch(
      name: 'Bautista Ebenezer',
      province: 'Matanzas',
      municipality: 'Cárdenas');
  final ps = <AttendeeRow>[];
  for (final (n, s, a) in [
    ('Juan', Sex.male, 34),
    ('María', Sex.female, 27),
    ('Pedro', Sex.male, 40),
    ('Ana', Sex.female, 19)
  ]) {
    ps.add(await d.repo.addAttendee(
        eventId: ev,
        firstName: n,
        lastName1: 'Pérez',
        sex: s,
        age: a,
        churchId: ig.id,
        phone: '5 123 4567',
        needsLodging: true,
        notes: 'ñandú "x"'));
  }
  await d.social.setSpouse(ps[0].id, ps[1].id);
  final g = await d.social.createGroup(ev, 'Jóvenes de Colón');
  await d.social.setGroups(ps[2].id, {g.id});
  final l = await d.lodging.save(
      eventId: ev,
      name: 'Casa de Teresa',
      kind: 'private_home',
      capacity: 4,
      accepts: LodgingAccepts.couples);
  await d.lodging.assign(l.id, [ps[0].id, ps[1].id]);
  await d.teams.createMany(ev, 2);
  final tm = await d.db.select(d.db.teams).get();
  await d.teams.setTeam([ps[0].id, ps[2].id], tm[0].id);
  await d.meals.ensureDefaultTypes(ev);
  final t = (await d.meals.types(ev)).firstWhere((x) => x.name == 'Almuerzo');
  final s = await d.meals
      .createSession(ev, t.id, 'Almuerzo del sábado', operatorName: 'Ruth');
  await d.meals.mark(s.id, ps[0].id, operatorName: 'Ruth');
  await d.meals.mark(s.id, ps[1].id, operatorName: 'Ruth');
  await d.meals.closeSession(s.id);
  return ev;
}

Future<Map<String, int>> counts(Dev d) async => {
      'events': (await d.db.select(d.db.events).get()).length,
      'attendees': (await d.db.select(d.db.attendees).get()).length,
      'couples': (await d.db.select(d.db.couples).get()).length,
      'groups': (await d.db.select(d.db.attendeeGroups).get()).length,
      'members': (await d.db.select(d.db.groupMembers).get()).length,
      'lodgings': (await d.db.select(d.db.lodgings).get()).length,
      'teams': (await d.db.select(d.db.teams).get()).length,
      'sessions': (await d.db.select(d.db.controlSessions).get()).length,
      'records': (await d.db.select(d.db.controlRecords).get()).length,
      'types': (await d.db.select(d.db.controlTypes).get()).length,
      'ranges': (await d.db.select(d.db.ageRanges).get()).length,
      'churches': (await d.db.select(d.db.churches).get()).length,
    };

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Dev a, b;
  setUp(() {
    a = Dev();
    b = Dev();
  });
  tearDown(() async {
    await a.db.close();
    await b.db.close();
  });

  group('exportar e importar', () {
    test('un evento completo viaja de un dispositivo a otro sin perder nada',
        () async {
      final ev = await fullEvent(a);
      final bytes = await a.backup.export(ev);
      final rep = await b.backup.import(decodeBundle(bytes));
      expect(await counts(b), await counts(a));
      expect(rep.inserted, greaterThan(20));
      expect((rep.updated, rep.skipped, rep.renumbered), (0, 0, 0));
      // contenido real, no solo conteos
      final juan = (await b.db.select(b.db.attendees).get())
          .firstWhere((x) => x.firstName == 'Juan');
      expect(juan.phone, '5 123 4567');
      expect(juan.notes, 'ñandú "x"');
      expect((await b.social.spouseOf(juan.id))!.firstName, 'María');
      expect(juan.lodgingId, isNotNull);
      expect(juan.teamId, isNotNull);
      final recs = await b.db.select(b.db.controlRecords).get();
      expect(recs.map((r) => r.operatorName).toSet(), {'Ruth'});
      expect((await b.db.select(b.db.controlSessions).getSingle()).closedAt,
          isNotNull);
      expect(
          await b.repo.ageRanges(ev),
          AgeRange.defaults
              .map((r) =>
                  isA<AgeRange>().having((x) => x.label, 'label', r.label))
              .toList());
    });

    test(
        'el archivo no incluye usuarios, contraseñas ni datos de la instalación',
        () async {
      final ev = await fullEvent(a);
      final tables = await a.backup.collect(ev);
      expect(tables.keys, isNot(contains('appUsers')));
      expect(tables.keys, isNot(contains('appMeta')));
      expect(tables.toString().contains('pbkdf2'), isFalse);
    });

    test('importar dos veces es seguro: la segunda vez no cambia nada',
        () async {
      final ev = await fullEvent(a);
      final bundle = decodeBundle(await a.backup.export(ev));
      await b.backup.import(bundle);
      final before = await counts(b);
      final again = await b.backup.import(bundle);
      expect(await counts(b), before);
      expect((again.inserted, again.updated), (0, 0));
      expect(again.skipped, greaterThan(20));
      expect(again.changedAnything, isFalse);
    });

    test('el respaldo es un CSV legible y sin contraseña: se importa tal cual',
        () async {
      final ev = await fullEvent(a);
      final bytes = await a.backup.export(ev);
      expect(String.fromCharCodes(bytes).contains('Juan'), isTrue);
      await b.backup.import(decodeBundle(bytes));
      expect((await counts(b))['attendees'], 4);
    });

    test('el nombre de archivo lleva evento y fecha, sin tildes', () {
      expect(
          BackupService.fileName(
              'Retiro de Jóvenes', DateTime(2026, 12, 5, 9, 7)),
          'retiro-de-jovenes-2026-12-05-090700.csv');
      expect(
          BackupService.fileName('!!!', DateTime(2026, 1, 1))
              .startsWith('evento-'),
          isTrue);
    });
  });

  group('fusión entre dispositivos (gana el cambio más reciente)', () {
    test('un cambio posterior en el otro dispositivo reemplaza al local',
        () async {
      final ev = await fullEvent(a);
      await b.backup.import(decodeBundle(await a.backup.export(ev)));
      final ana = (await a.db.select(a.db.attendees).get())
          .firstWhere((x) => x.firstName == 'Ana');
      await Future<void>.delayed(const Duration(
          milliseconds: 1100)); // las marcas de tiempo se guardan en segundos
      await a.repo.updateAttendee(ana.id,
          firstName: 'Ana',
          lastName1: 'Pérez',
          sex: Sex.female,
          age: 20,
          churchId: ana.churchId,
          notes: 'cambió en A');
      final rep =
          await b.backup.import(decodeBundle(await a.backup.export(ev)));
      expect(rep.updated, 1);
      expect(
          (await b.db.select(b.db.attendees).get())
              .firstWhere((x) => x.firstName == 'Ana')
              .notes,
          'cambió en A');
    });

    test('un cambio local más reciente NO se pisa con una copia vieja',
        () async {
      final ev = await fullEvent(a);
      final old = decodeBundle(await a.backup.export(ev));
      await b.backup.import(old);
      final ana = (await b.db.select(b.db.attendees).get())
          .firstWhere((x) => x.firstName == 'Ana');
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      await b.repo.updateAttendee(ana.id,
          firstName: 'Ana',
          lastName1: 'Pérez',
          sex: Sex.female,
          age: 19,
          churchId: ana.churchId,
          notes: 'cambio local');
      final rep = await b.backup.import(old);
      expect(rep.updated, 0);
      expect(
          (await b.db.select(b.db.attendees).get())
              .firstWhere((x) => x.firstName == 'Ana')
              .notes,
          'cambio local');
    });

    test('las personas eliminadas (borrado lógico) viajan como eliminadas',
        () async {
      final ev = await fullEvent(a);
      await b.backup.import(decodeBundle(await a.backup.export(ev)));
      final pedro = (await a.db.select(a.db.attendees).get())
          .firstWhere((x) => x.firstName == 'Pedro');
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      await a.repo.deleteAttendee(pedro.id, isAdmin: true);
      await b.backup.import(decodeBundle(await a.backup.export(ev)));
      expect(await b.repo.watchAttendees(ev).first, hasLength(3));
    });

    test(
        'la misma iglesia creada en dos dispositivos con ids distintos se une (no duplica ni falla)',
        () async {
      final evA = await fullEvent(a);
      // En B existe «Bautista Ebenezer» con OTRO id, y un evento distinto que la usa
      final evB = await b.repo.createEvent(
          name: 'Otro', startDate: '2026-01-01', endDate: '2026-01-02');
      final igB = await b.repo.createChurch(
          name: 'Bautista  Ebenezer',
          province: 'Matanzas',
          municipality: 'cardenas');
      await b.repo.addAttendee(
          eventId: evB,
          firstName: 'Luis',
          lastName1: 'X',
          sex: Sex.male,
          age: 30,
          churchId: igB.id);
      final rep =
          await b.backup.import(decodeBundle(await a.backup.export(evA)));
      expect(rep.churchesMerged, 1);
      expect(await b.db.select(b.db.churches).get(), hasLength(1));
      final juan = (await b.db.select(b.db.attendees).get())
          .firstWhere((x) => x.firstName == 'Juan');
      expect(juan.churchId, igB.id); // reasignada a la que ya existía
    });

    test(
        'el mismo evento con inscripciones hechas por separado: se renumeran en vez de chocar',
        () async {
      final ev = await fullEvent(a);
      final bundle = decodeBundle(await a.backup.export(ev));
      await b.backup.import(bundle); // B ya tiene las 4 (nº 1 a 4)
      // A inscribe a alguien nuevo (nº 5) y B inscribe a otra persona distinta (también nº 5)
      await a.repo.addAttendee(
          eventId: ev,
          firstName: 'DeA',
          lastName1: 'X',
          sex: Sex.male,
          age: 22);
      await b.repo.addAttendee(
          eventId: ev,
          firstName: 'DeB',
          lastName1: 'X',
          sex: Sex.male,
          age: 23);
      final rep =
          await b.backup.import(decodeBundle(await a.backup.export(ev)));
      expect(rep.renumbered, 1);
      final all = await b.repo.watchAttendees(ev).first;
      expect(all, hasLength(6));
      expect(all.map((v) => v.a.regNumber).toSet().length,
          6); // ningún número repetido
    });

    test('si algo falla a medias, no queda nada importado (todo o nada)',
        () async {
      final ev = await fullEvent(a);
      final bundle = decodeBundle(await a.backup.export(ev));
      bundle.tables['controlRecords']!
          .add({'id': 'roto'}); // fila inválida al final
      await expectLater(b.backup.import(bundle), throwsA(anything));
      expect((await counts(b))['attendees'], 0);
      expect((await counts(b))['events'], 0);
    });
  });

  group('eliminar un evento', () {
    test(
        'borra de verdad el evento y todo lo suyo; no toca otros eventos ni el catálogo',
        () async {
      final ev = await fullEvent(a);
      final other = await a.repo.createEvent(
          name: 'Otro', startDate: '2026-01-01', endDate: '2026-01-02');
      await a.repo.addAttendee(
          eventId: other,
          firstName: 'Z',
          lastName1: 'Z',
          sex: Sex.male,
          age: 20);
      expect(() => a.repo.deleteEventPermanently(ev, isAdmin: false),
          throwsA(isA<DataException>()));
      final n = await a.repo.deleteEventPermanently(ev, isAdmin: true);
      expect(n, 4);
      final c = await counts(a);
      expect((
        c['events'],
        c['attendees'],
        c['sessions'],
        c['records'],
        c['teams'],
        c['lodgings'],
        c['couples'],
        c['groups']
      ), (
        1,
        1,
        0,
        0,
        0,
        0,
        0,
        0
      ));
      expect(c['churches'], 1); // el catálogo se conserva
    });
  });

  group('copias automáticas', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('mievento_copias'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('guarda una copia válida y apunta la fecha de la última copia',
        () async {
      final ev = await fullEvent(a);
      final auto = AutoBackup(a.db, directory: () async => dir);
      final s = await auto.backupNow(ev, now: DateTime(2026, 12, 12, 18, 30));
      expect(s, isNotNull);
      expect(s!.name, 'retiro-de-jovenes-2026-12-12-183000.csv');
      expect(decodeBundle(File(s.path).readAsBytesSync()).manifest.eventName,
          'Retiro de Jóvenes');
      final meta = await (a.db.select(a.db.appMeta)).getSingle();
      expect(meta.lastBackupAt, isNotNull);
      expect(auto.lastError, isNull);
    });

    test('se conservan solo las últimas N copias', () async {
      final ev = await fullEvent(a);
      final auto = AutoBackup(a.db, directory: () async => dir, keep: 3);
      for (var i = 0; i < 6; i++) {
        final f = await auto.backupNow(ev, now: DateTime(2026, 12, 12, 10, i));
        File(f!.path).setLastModifiedSync(
            DateTime(2026, 12, 12, 10, i)); // orden estable
      }
      final left = await auto.list();
      expect(left, hasLength(3));
      expect(left.map((x) => x.name), [
        'retiro-de-jovenes-2026-12-12-100500.csv',
        'retiro-de-jovenes-2026-12-12-100400.csv',
        'retiro-de-jovenes-2026-12-12-100300.csv'
      ]);
    });

    test('la rotación de un evento no borra las copias de otro', () async {
      final ev = await fullEvent(a);
      final other = await a.repo.createEvent(
          name: 'Congreso', startDate: '2026-01-01', endDate: '2026-01-02');
      final auto = AutoBackup(a.db, directory: () async => dir, keep: 1);
      await auto.backupNow(other, now: DateTime(2026, 1, 1, 8));
      for (var i = 0; i < 3; i++) {
        final f = await auto.backupNow(ev, now: DateTime(2026, 12, 12, 10, i));
        File(f!.path).setLastModifiedSync(DateTime(2026, 12, 12, 10, i));
      }
      final names = (await auto.list()).map((x) => x.name).toList();
      expect(names.where((n) => n.startsWith('retiro')), hasLength(1));
      expect(names.where((n) => n.startsWith('congreso')), hasLength(1));
    });

    test('guarda sola cada N cambios y siempre al forzarla (cierre de sesión)',
        () async {
      final ev = await fullEvent(a);
      final auto = AutoBackup(a.db, directory: () async => dir, every: 3);
      await auto.noteChange(ev);
      await auto.noteChange(ev);
      expect(await auto.list(), isEmpty);
      await auto.noteChange(ev); // el 3.º
      expect(await auto.list(), hasLength(1));
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      await auto.noteChange(ev, force: true);
      expect(await auto.list(), hasLength(2));
    });

    test('un fallo al guardar no rompe la app: se anota para avisar', () async {
      final ev = await fullEvent(a);
      final auto = AutoBackup(a.db,
          directory: () async => Directory('/no/existe/esta/carpeta'));
      expect(await auto.backupNow(ev), isNull);
      expect(auto.lastError, isNotNull);
    });
  });
}
