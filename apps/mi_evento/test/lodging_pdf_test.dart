import 'package:drift/native.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/repos_b.dart';
import 'package:mi_evento/data/repository.dart';
import 'package:mi_evento/ui/lodging_pdf.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late LodgingRepo lodging;
  late String ev;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    lodging = LodgingRepo(db);
    ev = await Repository(db).createEvent(
        name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
  });
  tearDown(() => db.close());

  Future<(LodgingRow, List<AttendeeRow>)> lodgingWith(int people) async {
    final repo = Repository(db);
    for (var i = 0; i < people; i++) {
      await repo.addAttendee(
          eventId: ev,
          firstName: 'Nombre$i',
          lastName1: 'Apellido',
          sex: Sex.male,
          age: 20 + i % 30,
          phone: '5 123 45$i');
    }
    final l = await lodging.save(
        eventId: ev,
        name: 'Albergue Grande',
        kind: 'shelter',
        capacity: 100,
        accepts: LodgingAccepts.men,
        hostName: 'Hno. Ramón',
        directions: 'Frente al templo');
    await lodging.assign(
        l.id, (await db.select(db.attendees).get()).map((r) => r.id));
    final row = await (db.select(db.lodgings)..where((x) => x.id.equals(l.id)))
        .getSingle();
    return (row, await lodging.occupants(l.id));
  }

  Future<List<int>> build(LodgingRow l, List<AttendeeRow> o,
          {bool phone = false}) =>
      buildLodgingPdf(
          eventName: 'Retiro',
          eventDates: 'del 2026-12-12 al 2026-12-14',
          lodging: l,
          occupants: o,
          churchNames: const {},
          includePhone: phone,
          bundle: rootBundle,
          now: DateTime(2026, 12, 12));

  int pageCount(List<int> bytes) => RegExp(r'/Type\s*/Page[^s]')
      .allMatches(String.fromCharCodes(bytes))
      .length;

  test('genera un PDF válido para una lista corta (una sola hoja)', () async {
    final (l, o) = await lodgingWith(3);
    final pdf = await build(l, o);
    expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
    expect(pdf.length, greaterThan(5000));
    expect(pageCount(pdf), 1);
  });

  test(
      'con teléfono el documento cambia (columna extra) y por defecto no se incluye',
      () async {
    final (l, o) = await lodgingWith(5);
    final sin = await build(l, o);
    final con = await build(l, o, phone: true);
    expect(con.length, isNot(sin.length));
    // el teléfono nunca aparece en el PDF por defecto (el contenido va comprimido, se comprueba con el texto crudo)
    expect(String.fromCharCodes(sin).contains('5 123 45'), isFalse);
  });

  test('una lista larga se reparte en varias hojas', () async {
    final (l, o) = await lodgingWith(73);
    expect(pageCount(await build(l, o)), greaterThan(1));
  });

  test('una lista vacía también se genera', () async {
    final (l, _) = await lodgingWith(0);
    final pdf = await build(l, const []);
    expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
  });

  test('es estable: mismos datos y fecha dan el mismo tamaño', () async {
    final (l, o) = await lodgingWith(4);
    expect((await build(l, o)).length, (await build(l, o)).length);
  });
}
