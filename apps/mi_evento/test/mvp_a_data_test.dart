import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/repository.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

void main() {
  late AppDatabase db;
  late Repository repo;
  late String ev;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = Repository(db);
    ev = await repo.createEvent(
        name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
  });
  tearDown(() => db.close());

  Future<AttendeeRow> add(String n, String a1, int age,
          {Sex sex = Sex.male, String? church}) =>
      repo.addAttendee(
          eventId: ev,
          firstName: n,
          lastName1: a1,
          sex: sex,
          age: age,
          churchId: church);

  group('catálogo de iglesias', () {
    test('evita duplicados por escritura (tildes, mayúsculas, guiones)',
        () async {
      await repo.createChurch(
          name: 'Bautista Ebenezer',
          province: 'Matanzas',
          municipality: 'Cárdenas');
      expect(
          () => repo.createChurch(
              name: '  bautista  EBENEZER ',
              province: 'Matanzas',
              municipality: 'cardenas'),
          throwsA(isA<DataException>()));
      // mismo nombre en otro municipio es otra iglesia
      final otra = await repo.createChurch(
          name: 'Bautista Ebenezer',
          province: 'Matanzas',
          municipality: 'Colón');
      expect(otra.municipality, 'Colón');
      expect(
          () => repo.createChurch(name: '  '), throwsA(isA<DataException>()));
    });

    test(
        'filtrado tolerante: parte del nombre, sin tildes, palabras en cualquier orden',
        () async {
      await repo.createChurch(name: 'Bautista Ebenezer', province: 'Matanzas');
      await repo.createChurch(
          name: 'Pentecostal Eben-Ezer', province: 'Matanzas');
      await repo.createChurch(name: 'Metodista de Colón', province: 'Matanzas');
      final all = await repo.watchChurches().first;
      expect(Repository.filterChurches(all, 'ebe').map((c) => c.name),
          containsAll(['Bautista Ebenezer', 'Pentecostal Eben-Ezer']));
      expect(Repository.filterChurches(all, 'colon').single.name,
          'Metodista de Colón');
      expect(Repository.filterChurches(all, 'colón metodista').single.name,
          'Metodista de Colón');
      expect(Repository.filterChurches(all, ''), isEmpty);
      expect(Repository.filterChurches(all, 'zzz'), isEmpty);
    });
  });

  group('asistentes', () {
    test('valida nombre, apellido y edad', () async {
      expect(() => add('', 'X', 20), throwsA(isA<DataException>()));
      expect(() => add('A', ' ', 20), throwsA(isA<DataException>()));
      expect(() => add('A', 'X', 0), throwsA(isA<DataException>()));
      expect(() => add('A', 'X', 111), throwsA(isA<DataException>()));
      expect((await add('A', 'X', 1)).age, 1);
    });

    test('guarda teléfono vacío como nulo, provincia, municipio y autor',
        () async {
      final r = await repo.addAttendee(
          eventId: ev,
          firstName: 'A',
          lastName1: 'X',
          sex: Sex.female,
          age: 20,
          phone: '  ',
          province: 'Matanzas',
          municipality: 'Perico',
          createdBy: 'u1');
      expect(r.phone, isNull);
      expect(r.province, 'Matanzas');
      expect(r.municipality, 'Perico');
      expect(r.createdBy, 'u1');
      expect(r.sex, 'F');
    });

    test('búsqueda por número, por palabras sueltas, sin tildes y por iglesia',
        () async {
      final c = await repo.createChurch(
          name: 'Metodista de Colón', province: 'Matanzas');
      await add('María', 'Rodríguez', 27, sex: Sex.female, church: c.id);
      await add('Juan', 'Pérez', 34);
      await add('Ana Lucía', 'Martínez', 12);
      final all = await repo.watchAttendees(ev).first;
      expect(all.map((v) => v.a.regNumber), [3, 2, 1]); // más recientes primero
      expect(Repository.search(all, '2').single.fullName, 'Juan Pérez');
      expect(Repository.search(all, 'rodriguez maria').single.a.regNumber, 1);
      expect(Repository.search(all, 'perez').single.a.regNumber, 2);
      expect(
          Repository.search(all, 'colon').single.a.regNumber, 1); // por iglesia
      expect(Repository.search(all, 'lucia mar').single.a.regNumber, 3);
      expect(Repository.search(all, '').length, 3);
      expect(Repository.search(all, 'nadie'), isEmpty);
      expect(all.last.churchName, 'Metodista de Colón');
    });

    test('editar actualiza los datos y la clave de duplicados', () async {
      final r = await add('Juan', 'Pérez', 34);
      await repo.updateAttendee(r.id,
          firstName: 'Juana',
          lastName1: 'Pérez',
          sex: Sex.female,
          age: 35,
          notes: 'llega el sábado');
      final u = (await repo.attendeeById(r.id))!;
      expect(u.firstName, 'Juana');
      expect(u.sex, 'F');
      expect(u.notes, 'llega el sábado');
      expect(u.dedupeKey, dedupeKey('Juana', 'Pérez'));
      expect(u.updatedAt.isAfter(r.updatedAt) || u.updatedAt == r.updatedAt,
          isTrue);
    });

    test(
        'duplicados: avisa, no se avisa a sí mismo al editar y respeta la edad',
        () async {
      final a = await add('Juan', 'Pérez', 34);
      expect(
          await repo.possibleDuplicates(ev,
              firstName: 'juan', lastName1: 'perez', age: 34),
          hasLength(1));
      expect(
          await repo.possibleDuplicates(ev,
              firstName: 'Juan', lastName1: 'Pérez', age: 34, excludeId: a.id),
          isEmpty);
      expect(
          await repo.possibleDuplicates(ev,
              firstName: 'Juan', lastName1: 'Pérez', age: 12),
          isEmpty);
      expect(
          await repo.possibleDuplicates(ev, firstName: '', lastName1: 'Pérez'),
          isEmpty);
    });

    test(
        'borrado lógico: solo administrador, desaparece de listas y conteo, el número no se reutiliza',
        () async {
      final a = await add('Juan', 'Pérez', 34);
      expect(() => repo.deleteAttendee(a.id, isAdmin: false),
          throwsA(isA<DataException>()));
      await repo.deleteAttendee(a.id, isAdmin: true);
      expect(await repo.watchAttendees(ev).first, isEmpty);
      expect(await repo.watchAttendeeCount(ev).first, 0);
      expect((await db.select(db.attendees).get()).single.deletedAt,
          isNotNull); // se conserva
      expect(
          await repo.possibleDuplicates(ev,
              firstName: 'Juan', lastName1: 'Pérez'),
          isEmpty);
      expect((await add('Otro', 'Y', 20)).regNumber, 2);
    });
  });
}
