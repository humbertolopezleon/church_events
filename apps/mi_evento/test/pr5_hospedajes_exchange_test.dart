import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/lodging_exchange.dart';
import 'package:mi_evento/data/repos_b.dart';
import 'package:mi_evento/data/repository.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

void main() {
  late AppDatabase db;
  late Repository repo;
  late String ev, ev2;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = Repository(db);
    ev = await repo.createEvent(
        name: 'A', startDate: '2026-01-01', endDate: '2026-01-02');
    ev2 = await repo.createEvent(
        name: 'B', startDate: '2027-01-01', endDate: '2027-01-02');
  });
  tearDown(() => db.close());

  Future<List<LodgingRow>> lodgingsOf(String e) => (db.select(db.lodgings)
        ..where((l) => l.eventId.equals(e) & l.deletedAt.isNull())
        ..orderBy([(l) => OrderingTerm.asc(l.name)]))
      .get();

  /// Lo que importa de un hospedaje (sin ids ni fechas).
  List<Object?> key(LodgingRow l) => [
        l.name,
        l.kind,
        l.accepts,
        l.capacity,
        l.hostName,
        l.contactPhone,
        l.directions,
        l.distanceNote
      ];

  test('exportar → importar en OTRO evento da los mismos hospedajes', () async {
    final lr = LodgingRepo(db);
    await lr.save(
        eventId: ev,
        name: 'Albergue «Norte», ala 1',
        kind: 'shelter',
        capacity: 20,
        accepts: LodgingAccepts.men,
        directions: 'Calle 5 e/ 3 y 4;\nfrente al parque',
        distanceNote: '10 min a pie');
    await lr.save(
        eventId: ev,
        name: 'Casa de Teresa',
        kind: 'private_home',
        capacity: 3,
        accepts: LodgingAccepts.couples,
        hostName: 'Teresa Pérez',
        contactPhone: '+53 5 123 4567',
        directions: '=HYPERLINK("http://x")',
        distanceNote: '-cerca');
    await lr.save(
        eventId: ev,
        name: 'Sala sin datos',
        kind: 'shelter',
        capacity: 1,
        accepts: LodgingAccepts.any);
    final borrado = await lr.save(
        eventId: ev,
        name: 'Borrado',
        kind: 'shelter',
        capacity: 9,
        accepts: LodgingAccepts.any);
    await (db.update(db.lodgings)..where((l) => l.id.equals(borrado.id)))
        .write(LodgingsCompanion(deletedAt: Value(DateTime.now())));

    final rows = await LodgingExchange(db, ev).export();
    expect(rows.first, LodgingExchange.headers);
    expect(rows.length, 4, reason: 'títulos + 3 (el borrado no sale)');
    expect(rows.any((r) => r.first == 'Borrado'), isFalse);
    // Sin ocupantes: no hay columnas de ocupadas/libres.
    expect(rows.first, isNot(contains('ocupadas')));
    expect(rows.first, isNot(contains('libres')));

    final csv = buildCsvDelimited(rows);
    final imp = LodgingExchange(db, ev2);
    final prev = await imp.preview(csv);
    expect(prev.warnings, isEmpty);
    expect(prev.work, 3);
    await imp.apply(csv);

    final a = await lodgingsOf(ev), b = await lodgingsOf(ev2);
    expect([for (final l in b) key(l)], [for (final l in a) key(l)]);
    // Importar otra vez es idempotente: actualiza, no duplica.
    await imp.apply(csv);
    expect((await lodgingsOf(ev2)).length, 3);
  });

  test('exporta todos los hospedajes del evento, ordenados por nombre',
      () async {
    final lr = LodgingRepo(db);
    for (final n in ['Zeta', 'alfa', 'Beta']) {
      await lr.save(
          eventId: ev,
          name: n,
          kind: 'shelter',
          capacity: 2,
          accepts: LodgingAccepts.any);
    }
    final rows = await LodgingExchange(db, ev).export();
    expect([for (final r in rows.skip(1)) r.first], ['alfa', 'Beta', 'Zeta']);
  });

  test('150 hospedajes: ida y vuelta sin pérdida', () async {
    final lr = LodgingRepo(db);
    for (var i = 1; i <= 150; i++) {
      await lr.save(
          eventId: ev,
          name: 'Hospedaje ${i.toString().padLeft(3, '0')}',
          kind: i.isEven ? 'shelter' : 'private_home',
          capacity: 1 + i % 12,
          accepts: LodgingAccepts.values[i % LodgingAccepts.values.length],
          hostName: i.isEven ? null : 'Anfitrión $i',
          directions: 'Calle $i, entre A y B',
          distanceNote: '${i % 30} min');
    }
    final csv = buildCsvDelimited(await LodgingExchange(db, ev).export());
    await LodgingExchange(db, ev2).apply(csv);
    expect([for (final l in await lodgingsOf(ev2)) key(l)],
        [for (final l in await lodgingsOf(ev)) key(l)]);
  });

  test('un CSV antiguo con «ocupadas» y «libres» sigue importándose', () async {
    final csv = buildCsvDelimited([
      [
        'nombre',
        'tipo',
        'acepta',
        'capacidad',
        'ocupadas',
        'libres',
        'anfitrion',
        'telefono',
        'indicaciones',
        'cercania'
      ],
      [
        'Casa vieja',
        'Casa particular',
        'Sin preferencia',
        '4',
        '2',
        '2',
        '',
        '',
        '',
        ''
      ],
    ]);
    final r = await LodgingExchange(db, ev).apply(csv);
    expect(r.work, 1);
    expect((await lodgingsOf(ev)).single.capacity, 4);
  });
}
