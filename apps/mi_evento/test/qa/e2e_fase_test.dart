// QA DE PUNTA A PUNTA (datos reales de 216 personas): reglas nuevas + continuar desde Excel.
//
// Cubre: invariantes tras inscribir/hospedar/repartir, preinscripción → confirmación →
// desconfirmación, y el plan «fallo crítico»: sacar CSV, editarlos fuera (Excel ES/EN/Unicode y
// LibreOffice real, si está instalado) y seguir registrando en un equipo NUEVO sin la base original.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_evento/data/attendance_exchange.dart';
import 'package:mi_evento/data/attendee_exchange.dart';
import 'package:mi_evento/data/church_exchange.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/lodging_exchange.dart';
import 'package:mi_evento/data/meal_repo.dart';
import 'package:mi_evento/data/repos_b.dart';
import 'package:mi_evento/data/repository.dart';
import 'package:mi_evento/data/team_exchange.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'qa_support.dart';

const _n = 216;

Future<QaEvent> _fullEvent(AppDatabase db, {int n = _n}) async {
  final q = await qaEvent(db, teams: 8);
  await qaInscribeAll(q, qaPeople(n, couples: 25));
  await qaLodgings(q, scale: 1.8);
  for (var i = 0; i < 3; i++) {
    if (await qaSuggestAndAccept(q) == null) break;
  }
  return q;
}

// ── Lo que «saca» cada vista en CSV (mismas columnas que la app) ──
Future<List<List<String>>> _lodgingRows(QaEvent q) async {
  final views = await q.lodgingViews();
  return [
    LodgingExchange.headers,
    for (final l in views)
      [
        l.row.name,
        LodgingExchange.kindLabel(l.row.kind),
        lodgingAcceptsLabel(lodgingAcceptsFromDb(l.row.accepts)),
        '${l.row.capacity}',
        '${l.occupied}',
        '${l.free}',
        l.row.hostName ?? '',
        l.row.contactPhone ?? '',
        l.row.directions,
        l.row.distanceNote,
      ]
  ];
}

Future<List<List<String>>> _teamRows(QaEvent q) async {
  final teams = {for (final t in await q.teamRows()) t.id: t.name};
  final out = <List<String>>[TeamExchange.headers];
  for (final p in await q.people()) {
    out.add([
      p.teamId == null ? 'Sin equipo' : teams[p.teamId] ?? '',
      '${p.regNumber}',
      '${p.firstName} ${p.lastName1}',
      p.sex == 'M' ? 'Hombre' : 'Mujer',
      '${p.age}',
      '',
    ]);
  }
  return out;
}

// ── «Excel» guarda el archivo a su manera ──
enum Excel { es, en, unicode }

/// Reescribe [csv] como lo haría Excel al guardar: sin la línea sep=, su separador y su codificación,
/// sin ceros iniciales en teléfonos, y con filas/columnas vacías de relleno.
Uint8List excelResave(String csv, Excel kind) {
  final rows = [
    for (final r in parseCsv(csv)) [for (final c in r) c]
  ];
  final header = rows.first;
  final tel = header.indexOf('telefono');
  if (tel >= 0) {
    for (final r in rows.skip(1)) {
      if (r.length > tel && RegExp(r'^\d+$').hasMatch(r[tel])) {
        r[tel] = r[tel].replaceFirst(RegExp(r'^0+'), '');
      }
    }
  }
  // Relleno típico: dos columnas vacías a la derecha y filas vacías al final.
  for (final r in rows) {
    r.addAll(['', '']);
  }
  rows
    ..add(List.filled(header.length, ''))
    ..add(List.filled(header.length, ''));
  switch (kind) {
    case Excel.es:
      // «CSV (delimitado por comas)» en un Excel en español: «;» y ANSI (Windows-1252).
      final text = buildCsvDelimited(rows, excelHint: false).substring(1);
      return Uint8List.fromList(latin1.encode(text));
    case Excel.en:
      return Uint8List.fromList(utf8
          .encode(buildCsvDelimited(rows, delimiter: ',', excelHint: false)));
    case Excel.unicode:
      // «Texto Unicode»: UTF-16 LE con marca y tabuladores.
      final text = buildCsvDelimited(rows, delimiter: '\t', excelHint: false)
          .substring(1);
      final units = [0xFEFF, ...text.codeUnits];
      final b = BytesBuilder();
      for (final u in units) {
        b.addByte(u & 0xFF);
        b.addByte(u >> 8);
      }
      return b.toBytes();
  }
}

/// 20 personas «escritas a mano en Excel»: sin número, con variantes de escritura.
List<List<String>> _typedInExcel(int churches) {
  final cols = attendeeCsvHeaders;
  List<String> row(Map<String, String> v) => [for (final c in cols) v[c] ?? ''];
  return [
    for (var i = 0; i < 20; i++)
      row({
        'nombre': i.isEven ? 'Nueva$i' : 'Ñandú$i',
        'apellido1': 'Excelente',
        'apellido2': 'Ñ$i',
        'sexo': ['Mujer', 'Hombre', 'F', 'M'][i % 4],
        'edad': '${20 + i}',
        'iglesia': qaChurches[i % qaChurches.length].$1,
        'provincia': qaChurches[i % qaChurches.length].$2,
        'municipio': qaChurches[i % qaChurches.length].$3,
        'telefono': '5${1000000 + i}',
        'necesita_hospedaje': i % 3 == 0 ? 'Sí' : 'No',
        'observaciones': 'Escrita en Excel $i',
      })
  ];
}

Future<void> main() async {
  late AppDatabase db;
  setUp(() => db = qaDb());
  tearDown(() => db.close());

  test(
      'E2E-1 · evento completo de $_n personas: invariantes de las reglas nuevas',
      () async {
    final q = await _fullEvent(db);
    final people = await q.people();
    expect(people, hasLength(_n));
    expect({for (final p in people) p.regNumber},
        {for (var i = 1; i <= _n; i++) i});

    // Ningún hospedaje con gente incompatible (hombre/mujer/matrimonios).
    var hospedados = 0;
    for (final l in await q.lodgingViews()) {
      expect(await q.lodgings.incompatibleOccupants(l.row.id), isEmpty,
          reason: '«${l.row.name}» tiene gente que no encaja');
      hospedados += l.occupied;
    }
    expect(hospedados, greaterThan(100));

    // Ningún matrimonio del mismo sexo y cada pareja es recíproca.
    final sp = await q.social.spouseMap(q.eventId);
    final by = {for (final p in people) p.id: p};
    expect(sp, isNotEmpty);
    sp.forEach((a, b) {
      expect(by[a]!.sex, isNot(by[b]!.sex), reason: 'pareja del mismo sexo');
      expect(sp[b], a);
    });

    // Provincia/municipio salen de la iglesia.
    final churches = {
      for (final c in await db.select(db.churches).get()) c.id: c
    };
    for (final p in people) {
      expect(p.municipality, churches[p.churchId]!.municipality);
    }
  });

  test('E2E-2 · bloqueos: ninguna vía deja hospedar a alguien incompatible',
      () async {
    final q = await _fullEvent(db);
    final people = await q.people();
    final lods = await q.lodgingViews();
    final mujeres = lods.firstWhere((l) => l.row.accepts == 'women');
    final hombres = lods.firstWhere((l) => l.row.accepts == 'men');
    final matrimonios = lods.firstWhere((l) => l.row.accepts == 'couples');
    final hombre =
        people.firstWhere((p) => p.sex == 'M' && p.lodgingId == null);
    final mujer = people.firstWhere((p) => p.sex == 'F' && p.lodgingId == null);
    await expectLater(q.lodgings.assign(mujeres.row.id, [hombre.id]),
        throwsA(isA<LodgingIncompatibleException>()));
    await expectLater(q.lodgings.assign(hombres.row.id, [mujer.id]),
        throwsA(isA<LodgingIncompatibleException>()));
    final soltero = people.firstWhere(
        (p) => p.coupleId == null && p.lodgingId == null && p.sex == 'M');
    await expectLater(q.lodgings.assign(matrimonios.row.id, [soltero.id]),
        throwsA(isA<LodgingIncompatibleException>()));
    // Vía importación CSV: la fila incompatible queda sin hospedaje y con aviso.
    final csv = buildCsvDelimited([
      attendeeCsvHeaders,
      [
        for (final c in attendeeCsvHeaders)
          {
                'nombre': 'Intruso',
                'apellido1': 'Prueba',
                'sexo': 'Hombre',
                'edad': '30',
                'iglesia': qaChurches[0].$1,
                'provincia': qaChurches[0].$2,
                'municipio': qaChurches[0].$3,
                'necesita_hospedaje': 'Sí',
                'hospedaje': mujeres.row.name,
              }[c] ??
              ''
      ]
    ]);
    final ex = AttendeeExchange(db);
    final plan = await ex.plan(q.eventId, parseAttendeesCsv(csv));
    final rep = await ex.apply(q.eventId, plan, keepAssignments: true);
    expect(rep.created, 1);
    expect(rep.warnings.join(' '), contains('sin hospedaje'));
    final intruso =
        (await q.people()).firstWhere((p) => p.firstName == 'Intruso');
    expect(intruso.lodgingId, isNull);
    // Cambiar «acepta» es la única salida y no deja a nadie fuera de forma silenciosa.
    await q.lodgings.save(
        id: mujeres.row.id,
        eventId: q.eventId,
        name: mujeres.row.name,
        kind: mujeres.row.kind,
        capacity: mujeres.row.capacity,
        accepts: LodgingAccepts.men);
    expect(await q.lodgings.incompatibleOccupants(mujeres.row.id), isNotEmpty);
    // Siguen hospedadas: no se borró nada.
    expect(
        (await q.lodgingViews())
            .firstWhere((l) => l.row.id == mujeres.row.id)
            .occupied,
        mujeres.occupied);
    // Matrimonio del mismo sexo: imposible por todas las vías.
    final h1 = people.firstWhere((p) => p.sex == 'M' && p.coupleId == null);
    final h2 = people.lastWhere((p) => p.sex == 'M' && p.coupleId == null);
    await expectLater(
        q.social.setSpouse(h1.id, h2.id), throwsA(isA<DataException>()));
  });

  test('E2E-3 · preinscripción → confirmación → desconfirmación (con comidas)',
      () async {
    final q = await _fullEvent(db);
    // Evento nuevo: se pasan los participantes como preinscritos.
    final ev2 = await q.repo.createEvent(
        name: 'Congreso 2027', startDate: '2027-12-10', endDate: '2027-12-12');
    final ex = AttendeeExchange(db);
    final csv = await ex.exportCsv(q.eventId);
    final plan = await ex.plan(ev2, parseAttendeesCsv(csv));
    final rep = await ex.apply(ev2, plan, asPreregistered: true);
    expect(rep.created, _n);
    List<AttendeeRow> ps() => [];
    Future<Map<String, int>> counts() async {
      final all = await (db.select(db.attendees)
            ..where((a) => a.eventId.equals(ev2) & a.deletedAt.isNull()))
          .get();
      return {
        'pre': all.where((a) => a.status == 'preregistered').length,
        'conf': all.where((a) => a.status == 'confirmed').length,
      };
    }

    expect(ps(), isEmpty);
    expect(await counts(), {'pre': _n, 'conf': 0});
    // Confirma a 100 desde un CSV (número + estado) y comprueba que el resto sigue preinscrito.
    final rows = <List<String>>[
      ['numero', 'nombre', 'estado'],
      for (var i = 1; i <= 100; i++) ['$i', 'x', 'Confirmado'],
      for (var i = 101; i <= 120; i++) ['$i', 'x', 'Preinscrito'],
    ];
    final att = AttendanceExchange(db, ev2);
    final done = await att.apply(buildCsvDelimited(rows));
    expect(done.lines.first, 'Asistencias a confirmar: 100');
    expect(await counts(), {'pre': _n - 100, 'conf': 100});
    // Idempotente: repetir no cambia nada.
    await att.apply(buildCsvDelimited(rows));
    expect(await counts(), {'pre': _n - 100, 'conf': 100});
    // Desconfirmar: sin comidas se puede; con comidas se bloquea y no cambia a nadie.
    final conf = await (db.select(db.attendees)
          ..where((a) => a.eventId.equals(ev2) & a.status.equals('confirmed'))
          ..orderBy([(a) => OrderingTerm.asc(a.regNumber)]))
        .get();
    final meals = MealRepo(db);
    await meals.ensureDefaultTypes(ev2);
    final type = (await meals.types(ev2)).first;
    final s = await meals.createSession(ev2, type.id, 'Desayuno');
    await meals.mark(s.id, conf.first.id, operatorName: 'qa');
    await expectLater(q.repo.unconfirmAttendance([conf[1].id, conf.first.id]),
        throwsA(isA<DataException>()));
    expect(await counts(), {'pre': _n - 100, 'conf': 100});
    expect(await q.repo.unconfirmAttendance([conf[1].id, conf[2].id]), 2);
    expect(await counts(), {'pre': _n - 98, 'conf': 98});
  });

  // ── Fallo crítico: seguir desde Excel en un equipo NUEVO ──
  for (final kind in Excel.values) {
    test('E2E-4 · continuar desde Excel (${kind.name}) en una base nueva',
        () async {
      final a = await _fullEvent(db);
      final srcPeople = await a.people();
      final srcLodging = {
        for (final p in srcPeople)
          p.regNumber: (await (db.select(db.lodgings)
                    ..where((l) => l.id.equals(p.lodgingId ?? '')))
                  .getSingleOrNull())
              ?.name
      };
      final srcTeam = {
        for (final r in (await _teamRows(a)).skip(1)) int.parse(r[1]): r[0]
      };
      final srcCouples = (await a.social.spouseMap(a.eventId)).length ~/ 2;

      // 1) Lo que el usuario guarda ANTES del fallo: un CSV por vista.
      final csvAtt = await AttendeeExchange(db).exportCsv(a.eventId);
      final churches = await (db.select(db.churches)
            ..where((c) => c.deletedAt.isNull()))
          .get();
      final files = {
        'iglesias': buildCsvDelimited(ChurchExchange.toRows(churches)),
        'hospedajes': buildCsvDelimited(await _lodgingRows(a)),
        'asistentes': () {
          final t = parseCsv(csvAtt)..addAll(_typedInExcel(churches.length));
          return buildCsvDelimited(t);
        }(),
        'equipos': buildCsvDelimited(await _teamRows(a)),
      };
      // 2) Excel los abre y los vuelve a guardar a su manera.
      final resaved = {
        for (final e in files.entries) e.key: excelResave(e.value, kind)
      };

      // 3) Otro computador, base VACÍA: se crea el evento y se importa todo.
      final b = qaDb();
      addTearDown(b.close);
      final evB = await Repository(b).createEvent(
          name: 'Congreso QA 2026',
          startDate: '2026-12-11',
          endDate: '2026-12-13');
      Future<TableImportSummaryLike> imp(
          dynamic importer, Uint8List bytes) async {
        final text = decodeCsvBytes(bytes);
        final pre = await importer.preview(text);
        expect(pre.warnings, isEmpty,
            reason: '${importer.title}: ${pre.warnings.take(3)}');
        return TableImportSummaryLike(await importer.apply(text));
      }

      await imp(ChurchExchange(b), resaved['iglesias']!);
      await imp(LodgingExchange(b, evB), resaved['hospedajes']!);
      // Asistentes (con hospedaje y equipo por nombre; el equipo aún no existe: se importa después).
      final exB = AttendeeExchange(b);
      final parse = parseAttendeesCsv(decodeCsvBytes(resaved['asistentes']!));
      expect(parse.errors, isEmpty, reason: '${parse.errors.take(3)}');
      final plan = await exB.plan(evB, parse);
      final rep = await exB.apply(evB, plan, keepAssignments: true);
      expect(rep.created, _n + 20);
      await imp(TeamExchange(b, evB), resaved['equipos']!);

      // 4) Verificación contra el original.
      final people = await (b.select(b.attendees)
            ..where((p) => p.eventId.equals(evB) & p.deletedAt.isNull()))
          .get();
      expect(people, hasLength(_n + 20));
      final byNum = {for (final p in people) p.regNumber: p};
      expect({
        for (final p in people) p.regNumber
      }, {
        for (var i = 1; i <= _n + 20; i++) i
      }, reason: 'numeración continua');
      // Mismo nombre y datos que el original (con tildes y ñ intactas).
      for (final s in srcPeople) {
        final p = byNum[s.regNumber]!;
        expect('${p.firstName}|${p.lastName1}|${p.lastName2}|${p.sex}|${p.age}',
            '${s.firstName}|${s.lastName1}|${s.lastName2}|${s.sex}|${s.age}');
      }
      // Hospedaje y equipo se conservaron.
      final lodgingsB = {
        for (final l in await b.select(b.lodgings).get()) l.id: l.name
      };
      final teamsB = {
        for (final t in await b.select(b.teams).get()) t.id: t.name
      };
      var difH = 0, difT = 0;
      for (final s in srcPeople) {
        final p = byNum[s.regNumber]!;
        if (lodgingsB[p.lodgingId] != srcLodging[s.regNumber]) difH++;
        final tn = p.teamId == null ? 'Sin equipo' : teamsB[p.teamId];
        if (tn != srcTeam[s.regNumber]) difT++;
      }
      expect(difH, 0, reason: 'hospedajes distintos tras la vuelta');
      expect(difT, 0, reason: 'equipos distintos tras la vuelta');
      // Matrimonios de las personas originales: se conservan.
      final spB = await SocialRepo(b).spouseMap(evB);
      expect(spB.length ~/ 2, srcCouples);
      // Las 20 escritas en Excel: bien interpretadas (sexo, edad, iglesia, teléfono sin ceros perdidos).
      final nuevas = people.where((p) => p.regNumber > _n).toList();
      expect(nuevas.every((p) => p.lastName1 == 'Excelente'), isTrue);
      expect(nuevas.where((p) => p.sex == 'F'), hasLength(10));
      expect(nuevas.every((p) => (p.phone ?? '').startsWith('5')), isTrue);
      expect(nuevas.every((p) => p.status == 'confirmed'), isTrue);
      // Ningún hospedaje con gente incompatible en la base nueva.
      for (final l in await b.select(b.lodgings).get()) {
        expect(await LodgingRepo(b).incompatibleOccupants(l.id), isEmpty);
      }
      // Reimportar el mismo archivo no duplica a nadie.
      final plan2 = await exB.plan(
          evB, parseAttendeesCsv(decodeCsvBytes(resaved['asistentes']!)));
      await exB.apply(evB, plan2, keepAssignments: true);
      expect(
          (await (b.select(b.attendees)
                    ..where(
                        (p) => p.eventId.equals(evB) & p.deletedAt.isNull()))
                  .get())
              .length,
          _n + 20);
    }, timeout: const Timeout(Duration(minutes: 5)));
  }

  test(
      'E2E-5 · pasando por LibreOffice real (CSV → XLSX → CSV) se puede seguir',
      () async {
    final which = await Process.run('which', ['soffice']);
    if (which.exitCode != 0) {
      markTestSkipped('LibreOffice no está instalado');
      return;
    }
    final a = await _fullEvent(db);
    final csv = await AttendeeExchange(db).exportCsv(a.eventId);
    final dir = await Directory.systemTemp.createTemp('mievento_lo');
    addTearDown(() => dir.delete(recursive: true));
    final src = File('${dir.path}/asistentes.csv')..writeAsStringSync(csv);
    // CSV → XLSX (le decimos a LibreOffice que el separador es «;», como haría Excel con sep=;).
    var r = await Process.run('soffice', [
      '--headless',
      '--infilter=CSV:59,34,76,1',
      '--convert-to',
      'xlsx',
      '--outdir',
      dir.path,
      src.path
    ]);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    final xlsx = File('${dir.path}/asistentes.xlsx');
    expect(xlsx.existsSync(), isTrue);
    // XLSX → CSV (lo que «Guardar como CSV» deja).
    final out = Directory('${dir.path}/out')..createSync();
    r = await Process.run('soffice', [
      '--headless',
      '--convert-to',
      'csv:Text - txt - csv (StarCalc):59,34,76,1',
      '--outdir',
      out.path,
      xlsx.path
    ]);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    final back = File('${out.path}/asistentes.csv').readAsBytesSync();
    final text = decodeCsvBytes(back);
    final parse = parseAttendeesCsv(text);
    expect(parse.errors, isEmpty, reason: '${parse.errors.take(3)}');
    expect(parse.rows, hasLength(_n));
    // Importa en una base nueva y compara.
    final b = qaDb();
    addTearDown(b.close);
    final evB = await Repository(b).createEvent(
        name: 'Copia', startDate: '2026-12-11', endDate: '2026-12-13');
    final exB = AttendeeExchange(b);
    final plan = await exB.plan(evB, parse);
    final rep = await exB.apply(evB, plan);
    expect(rep.created, _n);
    final bPeople = await b.select(b.attendees).get();
    final aPeople = await a.people();
    expect({
      for (final p in bPeople)
        '${p.regNumber}|${p.firstName}|${p.lastName1}|${p.age}'
    }, {
      for (final p in aPeople)
        '${p.regNumber}|${p.firstName}|${p.lastName1}|${p.age}'
    });
    expect((await SocialRepo(b).spouseMap(evB)).length,
        (await a.social.spouseMap(a.eventId)).length);
  }, timeout: const Timeout(Duration(minutes: 5)));
}

class TableImportSummaryLike {
  TableImportSummaryLike(this.inner);
  final dynamic inner;
}
