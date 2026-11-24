import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/repository.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

void main() {
  late AppDatabase db;
  late Repository repo;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = Repository(db);
  });
  tearDown(() => db.close());

  test('crear evento: id UUID v7, rangos por defecto y dispositivo de origen',
      () async {
    final id = await repo.createEvent(
        name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
    expect(isUuid(id), isTrue);
    final ranges = await repo.ageRanges(id);
    expect(
        ranges.map((r) => r.label), ['0–11', '12–17', '18–25', '26–40', '41+']);
    final dev = await db.deviceId();
    final ev = await (db.select(db.events)).getSingle();
    expect(ev.originDeviceId, dev);
    expect(ev.deletedAt, isNull);
  });

  test('número de inscripción correlativo por evento', () async {
    final e1 = await repo.createEvent(
        name: 'A', startDate: '2026-01-01', endDate: '2026-01-02');
    final e2 = await repo.createEvent(
        name: 'B', startDate: '2026-01-01', endDate: '2026-01-02');
    for (var i = 0; i < 3; i++) {
      await repo.addAttendee(
          eventId: e1,
          firstName: 'P$i',
          lastName1: 'X',
          sex: Sex.male,
          age: 20);
    }
    await repo.addAttendee(
        eventId: e2, firstName: 'Z', lastName1: 'X', sex: Sex.female, age: 30);
    final regs = (await db.select(db.attendees).get())
        .where((a) => a.eventId == e1)
        .map((a) => a.regNumber)
        .toList()
      ..sort();
    expect(regs, [1, 2, 3]);
    expect(
        (await db.select(db.attendees).get())
            .firstWhere((a) => a.eventId == e2)
            .regNumber,
        1);
  });

  test('detección de duplicados desde la base', () async {
    final e = await repo.createEvent(
        name: 'A', startDate: '2026-01-01', endDate: '2026-01-02');
    await repo.addAttendee(
        eventId: e,
        firstName: 'Juan',
        lastName1: 'Pérez',
        sex: Sex.male,
        age: 34);
    expect(
        await repo.possibleDuplicates(e,
            firstName: 'juan', lastName1: 'PEREZ', age: 34),
        hasLength(1));
    expect(
        await repo.possibleDuplicates(e,
            firstName: 'Juan', lastName1: 'Pérez', age: 12),
        isEmpty);
  });

  test(
      'claves foráneas activas: no se puede crear asistente de un evento inexistente',
      () async {
    expect(
        () => repo.addAttendee(
            eventId: 'no-existe',
            firstName: 'A',
            lastName1: 'B',
            sex: Sex.male,
            age: 20),
        throwsA(anything));
  });

  test('el conteo de inscritos se actualiza en vivo', () async {
    final e = await repo.createEvent(
        name: 'A', startDate: '2026-01-01', endDate: '2026-01-02');
    final stream = repo.watchAttendeeCount(e);
    final expectation = expectLater(stream, emitsInOrder([0, 1]));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await repo.addAttendee(
        eventId: e, firstName: 'A', lastName1: 'B', sex: Sex.male, age: 20);
    await expectation;
  });
}
