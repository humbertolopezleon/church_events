// QA · Los archivos de qa-datasets/ (datos de prueba entregados) se pueden importar de verdad.
// Solo LEE los archivos del repositorio; no escribe nada. Si la carpeta no está, se omite.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mi_evento/backup/backup_service.dart' show BackupService;
import 'package:mi_evento/data/attendee_exchange.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'qa_support.dart';

final _dir = Directory('../../qa-datasets');
bool get _hay =>
    _dir.existsSync() && File('${_dir.path}/asistentes_120.csv').existsSync();
Uint8List _bytes(String n) => File('${_dir.path}/$n').readAsBytesSync();

Future<QaEvent> _destino(AppDatabase db, {Uint8List? con120}) async {
  final q = await qaEvent(db, teams: 6, groups: const []);
  await qaLodgings(q);
  if (con120 != null) {
    final ex = AttendeeExchange(db);
    await ex.apply(q.eventId,
        await ex.plan(q.eventId, parseAttendeesCsv(decodeCsvBytes(con120))));
  }
  return q;
}

void main() {
  late AppDatabase db;
  setUp(() => db = qaDb());
  tearDown(() => db.close());
  final omitir = _hay
      ? null
      : 'No está la carpeta qa-datasets/ (se genera con qa/generate_qa_dataset_test.dart).';

  test(
      'QA-DAT-001 · asistentes_120.csv se importa completo a un evento vacío: 120 personas, con equipo, hospedaje, parejas y grupos',
      () async {
    final q = await _destino(db);
    final ex = AttendeeExchange(db);
    final parse =
        parseAttendeesCsv(decodeCsvBytes(_bytes('asistentes_120.csv')));
    expect(parse.errors, isEmpty);
    final plan = await ex.plan(q.eventId, parse);
    expect((plan.creates, plan.duplicates, plan.warnings.length), (120, 0, 0));
    final rep = await ex.apply(q.eventId, plan);
    expect(rep.created, 120);
    final filas = await qaFilas(q);
    expect(filas.where((f) => f.equipo.isEmpty), isEmpty);
    expect(filas.where((f) => f.necesita && f.hosp.isEmpty), isEmpty);
    expect(filas.where((f) => f.pareja != null).length, 30);
    expect(filas.where((f) => f.grupos.isNotEmpty).length, 25);
    expect(filas.map((f) => f.numero), [for (var i = 1; i <= 120; i++) i]);
  }, skip: omitir);

  test('QA-DAT-002 · plantilla_vacia.csv: no tiene filas ni errores', () {
    final p = parseAttendeesCsv(decodeCsvBytes(_bytes('plantilla_vacia.csv')));
    expect((p.rows.length, p.errors.length), (0, 0));
  }, skip: omitir);

  test(
      'QA-DAT-003 · importar_nuevos_30.csv sobre las 120: 30 nuevas, sin errores ni duplicados, números 121–150',
      () async {
    final q = await _destino(db, con120: _bytes('asistentes_120.csv'));
    final ex = AttendeeExchange(db);
    final plan = await ex.plan(q.eventId,
        parseAttendeesCsv(decodeCsvBytes(_bytes('importar_nuevos_30.csv'))));
    expect((plan.creates, plan.duplicates, plan.errors.length), (30, 0, 0));
    await ex.apply(q.eventId, plan);
    final nums = (await q.people()).map((p) => p.regNumber).toList()..sort();
    expect(nums, [for (var i = 1; i <= 150; i++) i]);
  }, skip: omitir);

  test(
      'QA-DAT-004 · importar_con_errores.csv sobre las 120: 8 nuevas, 2 duplicados omitidos y 11 filas con error, cada una con su motivo',
      () async {
    final q = await _destino(db, con120: _bytes('asistentes_120.csv'));
    final ex = AttendeeExchange(db);
    final parse =
        parseAttendeesCsv(decodeCsvBytes(_bytes('importar_con_errores.csv')));
    expect(parse.errors.map((e) => e.line),
        [4, 5, 6, 7, 8, 9, 10, 11, 12, 14, 16]);
    expect(parse.errors.every((e) => e.message.isNotEmpty), isTrue);
    final plan = await ex.plan(q.eventId, parse);
    expect((plan.creates, plan.duplicates), (8, 2));
    expect(plan.warnings.where((w) => w.contains('Hotel Fantasma')).length, 1);
    expect(
        plan.warnings.where((w) => w.contains('Equipo Inventado')).length, 1);
    final rep = await ex.apply(q.eventId, plan);
    expect(rep.created, 8);
    expect(rep.warnings.single, contains('pareja'));
    expect((await q.people()).length, 128);
  }, skip: omitir);

  test(
      'QA-DAT-005 · importar_ansi.csv (Windows-1252) se lee con tildes y ñ y se importa: 8 personas',
      () async {
    final bytes = _bytes('importar_ansi.csv');
    final q = await _destino(db);
    final texto = decodeCsvBytes(bytes);
    expect(texto, contains('María Ángeles'));
    expect(texto, contains('Ñico'));
    final ex = AttendeeExchange(db);
    final rep = await ex.apply(
        q.eventId, await ex.plan(q.eventId, parseAttendeesCsv(texto)));
    expect(rep.created, 8);
  }, skip: omitir);

  test('QA-DAT-006 · el respaldo CSV se abre en una base vacía y trae todo',
      () async {
    final b = decodeBundle(_bytes('respaldo_evento_qa.csv'));
    expect(b.manifest.counts['attendees'], 120);
    expect(b.manifest.counts['controlRecords'], 150);
    final rep = await BackupService(db).import(b);
    expect(rep.inserted, greaterThan(300));
    expect((await db.select(db.attendees).get()).length, 120);
  }, skip: omitir);
}
