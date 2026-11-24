// QA · Copias CSV (BackupService): contenido legible, fusión entre dispositivos,
// duplicados, renumeración, borrado lógico, archivos dañados o de formato más nuevo.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_evento/backup/backup_service.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/meal_repo.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'qa_support.dart';

Future<QaEvent> _full(AppDatabase db) async {
  final q = await qaEvent(db, teams: 6);
  await qaInscribeAll(q, qaPeople(120));
  await qaLodgings(q);
  await qaSuggestAndAccept(q);
  return q;
}

Future<ImportReport> _abrir(AppDatabase db, Uint8List bytes) =>
    BackupService(db).import(decodeBundle(bytes));

int _porId(Map<String, dynamic> x, Map<String, dynamic> y) =>
    (x['id'] as String).compareTo(y['id'] as String);

void main() {
  late AppDatabase a;
  setUp(() => a = qaDb());
  tearDown(() => a.close());

  group('contenido', () {
    test(
        'QA-BAK-001 · la copia de 120 personas trae todas las tablas del evento con sus cantidades',
        () async {
      final q = await _full(a);
      final b = decodeBundle(await BackupService(a).export(q.eventId));
      expect(b.manifest.eventName, 'Congreso QA 2026');
      expect(b.manifest.counts['attendees'], 120);
      expect(b.manifest.counts['teams'], 6);
      expect(b.manifest.counts['lodgings'], 11);
      expect(b.manifest.counts['couples'], 15);
      expect(b.manifest.counts['groups'], 5);
      expect(b.manifest.counts['churches'], 9);
      expect(b.manifest.formatVersion, bundleFormatVersion);
    });

    test(
        'QA-BAK-002 · la copia no contiene usuarios, contraseñas ni códigos de recuperación',
        () async {
      final q = await _full(a);
      final b = decodeBundle(await BackupService(a).export(q.eventId));
      expect(b.tables.keys, isNot(contains('appUsers')));
      final texto = jsonEncode(b.tables).toLowerCase();
      for (final w in ['passwordhash', 'recoveryhash', 'lockeduntil']) {
        expect(texto.contains(w), isFalse, reason: w);
      }
    });

    test(
        'QA-BAK-003 · es un único CSV legible (UTF-8 con BOM, columna «tabla»), sin cifrar',
        () async {
      final q = await _full(a);
      final bytes = await BackupService(a).export(q.eventId);
      expect(bytes.take(3), [0xEF, 0xBB, 0xBF]);
      final texto = utf8.decode(bytes);
      expect(texto.startsWith('tabla;'), isTrue);
      expect(texto.contains('Yamil') || texto.contains('Valdés'), isTrue);
      expect(
          BackupService.fileName('Congreso QA', DateTime(2026, 1, 2, 3, 4, 5)),
          'congreso-qa-2026-01-02-030405.csv');
    });

    test(
        'QA-BAK-004 · tildes, ñ, comillas, saltos de línea y emoji en los datos sobreviven a la ida y vuelta',
        () async {
      final q = await qaEvent(a, teams: 0, offersTeams: false);
      await qaInscribeAll(q, qaPeople(5, couples: 0));
      final bytes = await BackupService(a).export(q.eventId);
      final b = qaDb();
      addTearDown(b.close);
      await _abrir(b, bytes);
      final orig = await a.select(a.attendees).get();
      final copia = await b.select(b.attendees).get();
      expect(copia.map((x) => x.toJson()).toList()..sort(_porId),
          orig.map((x) => x.toJson()).toList()..sort(_porId));
    });
  });

  group('abrir una copia en otro dispositivo (base vacía)', () {
    test(
        'QA-BAK-010 · A → B: personas, hospedajes, equipos, parejas, grupos, iglesias y números coinciden',
        () async {
      final q = await _full(a);
      final bytes = await BackupService(a).export(q.eventId);
      final b = qaDb();
      addTearDown(b.close);
      final rep = await _abrir(b, bytes);
      expect(rep.skipped, 0);
      expect(rep.renumbered, 0);
      final qb = QaEvent(b, q.eventId, const [], const {}, const []);
      final fa = await qaFilas(q), fb = await qaFilas(qb);
      expect(fb.length, 120);
      for (var i = 0; i < 120; i++) {
        expect('${fb[i]}', '${fa[i]}', reason: 'persona nº ${i + 1}');
      }
      expect(
          (await qb.lodgingViews())
              .map((l) => '${l.row.name}:${l.occupied}')
              .toList(),
          (await q.lodgingViews())
              .map((l) => '${l.row.name}:${l.occupied}')
              .toList());
      expect((await qb.teamRows()).map((t) => t.name),
          (await q.teamRows()).map((t) => t.name));
      // El dispositivo B conserva su propio identificador.
      expect(await b.deviceId(), isNot(await a.deviceId()));
    });

    test(
        'QA-BAK-011 · abrir la misma copia dos veces no duplica nada (todo «omitido»)',
        () async {
      final q = await _full(a);
      final bytes = await BackupService(a).export(q.eventId);
      final b = qaDb();
      addTearDown(b.close);
      await _abrir(b, bytes);
      final rep = await _abrir(b, bytes);
      expect(rep.inserted, 0);
      expect(rep.updated, 0);
      expect(rep.skipped, greaterThan(150));
      expect((await b.select(b.attendees).get()).length, 120);
      expect((await b.select(b.events).get()).length, 1);
    });

    test(
        'QA-BAK-012 · abrir una copia en la misma base de donde salió no cambia nada',
        () async {
      final q = await _full(a);
      final bytes = await BackupService(a).export(q.eventId);
      final rep = await _abrir(a, bytes);
      expect(rep.changedAnything, isFalse);
    });

    test(
        'QA-BAK-013 · el evento queda abierto y utilizable en B: se puede seguir inscribiendo con el equipo y número siguientes',
        () async {
      final q = await _full(a);
      final b = qaDb();
      addTearDown(b.close);
      await _abrir(b, await BackupService(a).export(q.eventId));
      final qb = QaEvent(b, q.eventId, q.churchIds, q.groupIds, q.teamIds);
      final p =
          qaPeople(130, seed: 31337).firstWhere((x) => x.spouseIdx == null);
      final row = await qaInscribe(qb, p);
      expect(row.regNumber, 121);
      expect((await qb.repo.attendeeById(row.id))!.teamId, isNotNull);
    });
  });

  group('fusión de ida y vuelta entre dos dispositivos', () {
    test(
        'QA-BAK-020 · A inscribe nº 121 y B inscribe otro nº 121: al fusionar se renumera uno y no se pierde a nadie',
        () async {
      final q = await _full(a);
      final b = qaDb();
      addTearDown(b.close);
      await _abrir(b, await BackupService(a).export(q.eventId));
      final qb = QaEvent(b, q.eventId, q.churchIds, q.groupIds, q.teamIds);
      final ppl = qaPeople(140, seed: 555);
      final deA = await qaInscribe(q, ppl[130]);
      final deB = await qaInscribe(qb, ppl[131]);
      expect((deA.regNumber, deB.regNumber), (121, 121));
      final rep = await _abrir(a, await BackupService(b).export(q.eventId));
      expect(rep.renumbered, 1);
      final todos = await q.people();
      expect(todos.length, 122);
      expect(todos.map((p) => p.regNumber).toSet().length, 122,
          reason: 'números repetidos');
      expect(
          todos.map((p) => p.regNumber).reduce((x, y) => x > y ? x : y), 122);
    });

    test(
        'QA-BAK-021 · gana la fila más reciente: un cambio nuevo de B llega a A; un cambio viejo de B no pisa uno nuevo de A',
        () async {
      final q = await _full(a);
      final b = qaDb();
      addTearDown(b.close);
      await _abrir(b, await BackupService(a).export(q.eventId));
      final p1 = (await q.people()).firstWhere((p) => p.regNumber == 1);
      final p2 = (await q.people()).firstWhere((p) => p.regNumber == 2);
      final t0 = DateTime.now().toUtc().add(const Duration(hours: 1));
      Future<void> edad(AppDatabase d, String id, int edad, int minutos) =>
          (d.update(d.attendees)..where((x) => x.id.equals(id))).write(
              AttendeesCompanion(
                  age: Value(edad),
                  updatedAt: Value(t0.add(Duration(minutes: minutos)))));
      await edad(a, p2.id, 40, 1); // A cambia al 2 (más viejo)
      await edad(b, p1.id, 41, 2); // B cambia al 1
      await edad(b, p2.id, 99, 3); // B cambia al 2 DESPUÉS que A: gana B
      await edad(a, p1.id, 50, 4); // A cambia al 1 DESPUÉS que B: gana A
      await _abrir(a, await BackupService(b).export(q.eventId));
      expect((await q.repo.attendeeById(p1.id))!.age, 50,
          reason: 'el cambio de A es más nuevo');
      expect((await q.repo.attendeeById(p2.id))!.age, 99,
          reason: 'el cambio de B es más nuevo');
    });

    test(
        'QA-BAK-025 · las marcas de tiempo se guardan en segundos: dos cambios del mismo segundo en dos dispositivos se resuelven a favor del local (observación)',
        () async {
      final q = await _full(a);
      final b = qaDb();
      addTearDown(b.close);
      await _abrir(b, await BackupService(a).export(q.eventId));
      final p = (await q.people()).first;
      // Segundo exacto (sin fracción) para que el resultado no dependa de la hora de ejecución.
      final t = DateTime.utc(2030, 1, 1, 10, 0, 0);
      await (a.update(a.attendees)..where((x) => x.id.equals(p.id)))
          .write(AttendeesCompanion(age: const Value(33), updatedAt: Value(t)));
      await (b.update(b.attendees)..where((x) => x.id.equals(p.id))).write(
          AttendeesCompanion(
              age: const Value(66),
              updatedAt: Value(t.add(const Duration(milliseconds: 400)))));
      await _abrir(a, await BackupService(b).export(q.eventId));
      // B cambió 0,4 s después, pero ambos caen en el mismo segundo guardado: gana la copia local.
      expect((await q.repo.attendeeById(p.id))!.age, 33);
    });

    test(
        'QA-BAK-022 · el borrado lógico viaja: lo que B borra, A lo ve borrado',
        () async {
      final q = await _full(a);
      final b = qaDb();
      addTearDown(b.close);
      await _abrir(b, await BackupService(a).export(q.eventId));
      final qb = QaEvent(b, q.eventId, q.churchIds, q.groupIds, q.teamIds);
      await Future<void>.delayed(
          const Duration(milliseconds: 1100)); // otro segundo
      await qb.repo.deleteAttendee(q.ids[5], isAdmin: true);
      await _abrir(a, await BackupService(b).export(q.eventId));
      expect((await q.people()).length, 119);
    });

    test(
        'QA-BAK-023 · la misma iglesia creada en dos dispositivos con ids distintos se une, sin duplicarla',
        () async {
      final b = qaDb();
      addTearDown(b.close);
      final qa = await qaEvent(a, teams: 0, offersTeams: false);
      final qb =
          await qaEvent(b, name: 'Otro evento', teams: 0, offersTeams: false);
      await qaInscribeAll(qb, qaPeople(5, couples: 0));
      final rep = await _abrir(a, await BackupService(b).export(qb.eventId));
      expect(rep.churchesMerged, greaterThanOrEqualTo(1));
      expect((await a.select(a.churches).get()).length, qaChurches.length);
      expect((await qa.people()).length, 0);
      expect((await a.select(a.events).get()).length, 2);
    });

    test(
        'QA-BAK-024 · las marcas de comida hechas en B llegan a A tras fusionar, sin duplicarse',
        () async {
      final q = await _full(a);
      final meals = MealRepo(a);
      await meals.ensureDefaultTypes(q.eventId);
      final tipo = (await meals.types(q.eventId))
          .firstWhere((t) => t.name == 'Almuerzo');
      final s =
          await meals.createSession(q.eventId, tipo.id, 'Almuerzo del sábado');
      final b = qaDb();
      addTearDown(b.close);
      await _abrir(b, await BackupService(a).export(q.eventId));
      final mb = MealRepo(b);
      for (final id in q.ids.take(50)) {
        await mb.mark(s.id, id, operatorName: 'Ruth');
      }
      final bytes = await BackupService(b).export(q.eventId);
      final rep = await _abrir(a, bytes);
      expect(rep.inserted, 50);
      expect((await a.select(a.controlRecords).get()).length, 50);
      final rep2 = await _abrir(a, bytes);
      expect(rep2.inserted, 0);
      expect((await a.select(a.controlRecords).get()).length, 50);
    });
  });

  group('archivos dañados, alterados o de otra versión', () {
    late Uint8List bueno;
    setUp(() async {
      final q = await qaEvent(a, teams: 2);
      await qaInscribeAll(q, qaPeople(20));
      bueno = await BackupService(a).export(q.eventId);
    });

    void rechaza(List<int> bytes, String texto) => expect(
        () => decodeBundle(bytes),
        throwsA(isA<BundleException>()
            .having((e) => e.message, 'mensaje', contains(texto))));

    test(
        'QA-BAK-030 · archivo vacío, texto cualquiera o bytes al azar: mensaje en español',
        () {
      rechaza(<int>[], 'copia');
      rechaza(utf8.encode('esto no es una copia'), 'copia');
      rechaza(List<int>.generate(2000, (i) => (i * 37) % 256), 'copia');
    });

    test(
        'QA-BAK-031 · archivo cortado a la mitad: se rechaza, nunca se importa a medias',
        () {
      rechaza(bueno.sublist(0, bueno.length ~/ 2), 'copia');
    });

    test(
        'QA-BAK-032 · datos modificados sin actualizar la suma: «dañada o incompleta»',
        () {
      final data = utf8
          .decode(bueno)
          .replaceFirst('Congreso QA 2026', 'Congreso QA 2027')
          .replaceFirst('Congreso QA 2026', 'Congreso QA 2027');
      // el nombre del evento está en la fila `events` (datos) y en la cabecera (meta)
      rechaza(utf8.encode(data), 'suma de verificación');
    });

    test(
        'QA-BAK-033 · un solo carácter cambiado dentro del archivo: se rechaza',
        () {
      final raro = Uint8List.fromList(bueno);
      // cambia una letra dentro de los datos (después de la cabecera)
      final i = raro.length - 40;
      raro[i] = raro[i] == 0x41 ? 0x42 : 0x41;
      expect(() => decodeBundle(raro), throwsA(isA<BundleException>()));
    });

    test('QA-BAK-034 · formato más nuevo: pide actualizar la app y no importa',
        () {
      final t = utf8.decode(bueno).replaceFirst(
          'formatVersion;$bundleFormatVersion',
          'formatVersion;${bundleFormatVersion + 1}');
      rechaza(utf8.encode(t), 'versión más nueva');
    });

    test(
        'QA-BAK-035 · un CSV cualquiera (p. ej. la lista de asistentes) y una cabecera de otra app se rechazan',
        () {
      rechaza(utf8.encode('nombre;apellido1;sexo\nAna;Pérez;M\n'),
          'no es una copia');
      rechaza(utf8.encode('tabla;clave;valor\nmeta;app;otra-app\n'),
          'no es una copia');
    });

    test(
        'QA-BAK-036 · una copia con una fila corrupta (JSON válido, campo inválido) no deja la base a medias (todo o nada)',
        () async {
      final ok = decodeBundle(bueno);
      final tablas = {
        for (final e in ok.tables.entries)
          e.key: [for (final r in e.value) Map<String, String>.from(r)]
      };
      tablas['attendees']!.last['age'] = 'no-es-numero';
      final b = qaDb();
      addTearDown(b.close);
      Object? error;
      try {
        await BackupService(b).import(Bundle(ok.manifest, tablas));
      } catch (e) {
        error = e;
      }
      expect(error, isNotNull);
      expect(await b.select(b.attendees).get(), isEmpty,
          reason: 'quedó a medias');
      expect(await b.select(b.events).get(), isEmpty);
    });
  });

  group('copias automáticas (en carpeta temporal)', () {
    test(
        'QA-BAK-040 · cada 20 cambios se guarda sola una copia legible; se conservan solo las últimas 2 (rotación)',
        () async {
      final dir = Directory.systemTemp.createTempSync('qa_copias');
      addTearDown(() {
        if (dir.existsSync()) dir.deleteSync(recursive: true);
      });
      final q = await _full(a);
      final auto =
          AutoBackup(a, directory: () async => dir, keep: 2, every: 20);
      for (var i = 0; i < 60; i++) {
        await auto.noteChange(q.eventId);
        if (i % 20 == 19) {
          // El nombre del archivo lleva segundos: se espera para no pisar la copia anterior.
          await Future<void>.delayed(const Duration(milliseconds: 1100));
        }
      }
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.csv'))
          .toList();
      expect(auto.lastError, isNull);
      expect(files.length, 2,
          reason: 'rotación: 3 copias hechas, se guardan solo 2');
      final b = decodeBundle(files.first.readAsBytesSync());
      expect(b.manifest.counts['attendees'], 120);
    });
  });
}
