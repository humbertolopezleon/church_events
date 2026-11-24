import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/meal_repo.dart';
import 'package:mi_evento/data/repository.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

void main() {
  late AppDatabase db;
  late Repository repo;
  late MealRepo meals;
  late String ev;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = Repository(db);
    meals = MealRepo(db);
    ev = await repo.createEvent(
        name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
  });
  tearDown(() => db.close());

  Future<AttendeeRow> person(String n) => repo.addAttendee(
      eventId: ev, firstName: n, lastName1: 'X', sex: Sex.male, age: 20);
  Future<(ControlSession, AttendeeRow)> setup() async {
    await meals.ensureDefaultTypes(ev);
    final t = (await meals.types(ev)).firstWhere((x) => x.name == 'Almuerzo');
    return (
      await meals.createSession(ev, t.id, 'Almuerzo del sábado',
          operatorName: 'Ruth'),
      await person('Juan')
    );
  }

  group('tipos', () {
    test('se crean Desayuno, Almuerzo y Cena una sola vez', () async {
      await meals.ensureDefaultTypes(ev);
      await meals.ensureDefaultTypes(ev);
      expect((await meals.types(ev)).map((t) => t.name),
          ['Desayuno', 'Almuerzo', 'Cena']);
    });
    test('tipos personalizados: únicos y con nombre', () async {
      await meals.createType(ev, 'Entrega de materiales');
      expect(() => meals.createType(ev, ' entrega de MATERIALES '),
          throwsA(isA<DataException>()));
      expect(() => meals.createType(ev, ' '), throwsA(isA<DataException>()));
    });
    test('un tipo con sesiones no se puede eliminar; uno sin sesiones sí',
        () async {
      final (s, _) = await setup();
      final used =
          (await meals.types(ev)).firstWhere((t) => t.id == s.controlTypeId);
      expect(() => meals.deleteType(used.id), throwsA(isA<DataException>()));
      final free = await meals.createType(ev, 'Taller');
      await meals.deleteType(free.id);
      expect((await meals.types(ev)).any((t) => t.id == free.id), isFalse);
    });
  });

  group('sesiones', () {
    test('crear, nombre único, abrir/cerrar/reabrir', () async {
      final (s, _) = await setup();
      expect(s.closedAt, isNull);
      expect(s.openedAt, isNotNull);
      expect(
          () => meals.createSession(ev, s.controlTypeId,
              'almuerzo del SABADO'.replaceAll('SABADO', 'sábado')),
          throwsA(isA<DataException>()));
      expect(() => meals.createSession(ev, s.controlTypeId, ' '),
          throwsA(isA<DataException>()));
      await meals.closeSession(s.id);
      expect((await meals.watchSessions(ev).first).single.closed, isTrue);
      await meals.reopenSession(s.id);
      expect((await meals.watchSessions(ev).first).single.closed, isFalse);
      expect((await meals.watchSessions(ev).first).single.typeName, 'Almuerzo');
    });
    test('solo el administrador elimina una sesión', () async {
      final (s, _) = await setup();
      expect(() => meals.deleteSession(s.id, isAdmin: false),
          throwsA(isA<DataException>()));
      await meals.deleteSession(s.id, isAdmin: true);
      expect(await meals.watchSessions(ev).first, isEmpty);
    });
  });

  group('marcar', () {
    test('marca una persona con operador y hora', () async {
      final (s, a) = await setup();
      final r = await meals.mark(s.id, a.id, operatorName: 'Ruth');
      expect(r.already, isFalse);
      expect(r.record.operatorName, 'Ruth');
      expect(r.record.repeatOverride, isFalse);
      expect((await meals.watchRecords(s.id).first).length, 1);
    });
    test('marcar de nuevo NO crea otro registro: avisa con el original',
        () async {
      final (s, a) = await setup();
      final first = await meals.mark(s.id, a.id, operatorName: 'Ruth');
      final again = await meals.mark(s.id, a.id, operatorName: 'Luis');
      expect(again.already, isTrue);
      expect(again.record.id, first.record.id);
      expect(again.record.operatorName, 'Ruth'); // quién lo marcó antes
      expect((await meals.watchRecords(s.id).first).length, 1);
    });
    test(
        '«marcar otra vez de todas formas» crea un registro marcado como repetido',
        () async {
      final (s, a) = await setup();
      await meals.mark(s.id, a.id, operatorName: 'Ruth');
      final r =
          await meals.mark(s.id, a.id, operatorName: 'Ruth', repeat: true);
      expect(r.already, isFalse);
      expect(r.record.repeatOverride, isTrue);
      expect((await meals.watchRecords(s.id).first).length, 2);
    });
    test('deshacer permite marcar otra vez sin aviso', () async {
      final (s, a) = await setup();
      final r = await meals.mark(s.id, a.id, operatorName: 'Ruth');
      await meals.undo(r.record.id);
      expect(await meals.watchRecords(s.id).first, isEmpty);
      expect((await meals.mark(s.id, a.id, operatorName: 'Ruth')).already,
          isFalse);
      // el registro deshecho se conserva (con la hora en que se deshizo)
      expect(
          (await db.select(db.controlRecords).get())
              .where((x) => x.undoneAt != null)
              .length,
          1);
    });
    test('una sesión cerrada no deja marcar; al reabrir sí', () async {
      final (s, a) = await setup();
      await meals.closeSession(s.id);
      expect(() => meals.mark(s.id, a.id, operatorName: 'Ruth'),
          throwsA(isA<DataException>()));
      await meals.reopenSession(s.id);
      expect((await meals.mark(s.id, a.id, operatorName: 'Ruth')).already,
          isFalse);
    });
    test('una persona eliminada no se puede marcar', () async {
      final (s, a) = await setup();
      await repo.deleteAttendee(a.id, isAdmin: true);
      expect(() => meals.mark(s.id, a.id, operatorName: 'Ruth'),
          throwsA(isA<DataException>()));
    });
    test(
        'cada sesión es independiente: pasar en el desayuno no cuenta en el almuerzo',
        () async {
      final (almuerzo, a) = await setup();
      final desayuno = await meals.createSession(
          ev,
          (await meals.types(ev)).firstWhere((t) => t.name == 'Desayuno').id,
          'Desayuno del sábado');
      await meals.mark(desayuno.id, a.id, operatorName: 'Ruth');
      expect(
          (await meals.mark(almuerzo.id, a.id, operatorName: 'Ruth')).already,
          isFalse);
    });
    test('los avisos evitados se cuentan por sesión', () async {
      final (s, _) = await setup();
      await meals.registerBlocked(s.id);
      await meals.registerBlocked(s.id);
      expect(
          (await meals.watchSessions(ev).first).single.row.blockedRepeats, 2);
    });
  });

  test('rendimiento: 1000 marcas seguidas y estadísticas', () async {
    final (s, _) = await setup();
    final ids = <String>[];
    for (var i = 0; i < 1000; i++) {
      ids.add((await person('P$i')).id);
    }
    final sw = Stopwatch()..start();
    for (final id in ids) {
      await meals.mark(s.id, id, operatorName: 'Ruth');
    }
    final recs = await meals.watchRecords(s.id).first;
    expect(recs.length, 1000);
    expect(sw.elapsed.inSeconds, lessThan(30));
  });
}
