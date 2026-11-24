// QA · Intercambio CSV (Excel): exportar, plantilla, importar, ida y vuelta y casos difíciles.
// Capa de datos real (AttendeeExchange + SQLite en memoria) y lectura del núcleo.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mi_evento/data/attendee_exchange.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'qa_support.dart';

const _head =
    'id;numero;nombre;apellido1;apellido2;sexo;edad;iglesia;provincia;municipio;telefono;necesita_hospedaje;hospedaje;equipo;pareja_numero;grupos;observaciones;estado';

/// Evento completo de 120 personas en la base [db] (equipos, hospedajes asignados, parejas, grupos).
Future<QaEvent> _full120(AppDatabase db) async {
  final q = await qaEvent(db, teams: 6);
  await qaInscribeAll(q, qaPeople(120));
  await qaLodgings(q);
  await qaSuggestAndAccept(q);
  return q;
}

Future<ImportReport> _importar(QaEvent q, String csv,
    {bool dup = false}) async {
  final ex = AttendeeExchange(q.db);
  final plan =
      await ex.plan(q.eventId, parseAttendeesCsv(csv), includeDuplicates: dup);
  return ex.apply(q.eventId, plan);
}

void main() {
  late AppDatabase db;
  setUp(() => db = qaDb());
  tearDown(() => db.close());

  group('exportar y plantilla', () {
    test(
        'QA-CSV-001 · el archivo exportado tiene las 18 columnas, BOM, separador «;» y filas CRLF, una por persona',
        () async {
      final q = await _full120(db);
      final csv = await AttendeeExchange(db).exportCsv(q.eventId);
      expect(csv.startsWith('\u{FEFF}'), isTrue);
      expect(csv.split('\r\n').first.replaceFirst('\u{FEFF}', ''), _head);
      final t = parseCsv(csv);
      expect(t.length, 121);
      expect(t.every((r) => r.length == 18), isTrue);
      // Hospedaje, equipo, pareja y grupos salen por nombre/número.
      final fila = t.skip(1).firstWhere((r) => r[14].isNotEmpty);
      expect(int.tryParse(fila[14]), isNotNull);
      expect(t.skip(1).where((r) => r[12].isEmpty && r[11] == 'Sí'), isEmpty,
          reason: 'quien necesita hospedaje y lo tiene debe llevar su nombre');
    });

    test(
        'QA-CSV-002 · plantilla vacía: solo los títulos, y al leerla no da filas ni errores',
        () async {
      final t = AttendeeExchange.template();
      expect(parseCsv(t), [attendeeCsvHeaders]);
      final p = parseAttendeesCsv(t);
      expect(p.rows, isEmpty);
      expect(p.errors, isEmpty);
      expect(p.isEmpty, isTrue);
    });

    test(
        'QA-CSV-003 · archivo vacío o de solo espacios: mensaje en español, sin fallar',
        () {
      for (final s in ['', '   ', '\n\n', '\u{FEFF}']) {
        final p = parseAttendeesCsv(s);
        expect(p.errors.single.message, contains('vacío'),
            reason: 'entrada «${s.replaceAll('\n', '\\n')}»');
      }
    });

    test(
        'QA-CSV-004 · el CSV no lleva usuarios, contraseñas ni código de recuperación',
        () async {
      final q = await _full120(db);
      final csv =
          (await AttendeeExchange(db).exportCsv(q.eventId)).toLowerCase();
      for (final w in [
        'password',
        'hash',
        'contraseña',
        'recovery',
        'lockedUntil'
      ]) {
        expect(csv.contains(w.toLowerCase()), isFalse, reason: w);
      }
    });
  });

  group('ida y vuelta sin pérdida', () {
    test(
        'QA-CSV-010 · exportar 120 personas de A e importarlas a un evento vacío de B (mismos hospedajes y equipos) conserva todo',
        () async {
      final a = await _full120(db);
      final csv = await AttendeeExchange(db).exportCsv(a.eventId);
      final db2 = qaDb();
      addTearDown(db2.close);
      final b = await qaEvent(db2, teams: 6, groups: const []);
      await qaLodgings(b);
      final rep = await _importar(b, csv);
      metric(
          'CSV-010 ida y vuelta 120: creadas ${rep.created}, iglesias nuevas ${rep.churchesCreated}, grupos nuevos ${rep.groupsCreated}, avisos ${rep.warnings.length}');
      expect(rep.created, 120);
      expect(rep.warnings, isEmpty, reason: rep.warnings.join(' / '));
      final fa = await qaFilas(a), fb = await qaFilas(b);
      expect(fb.length, 120);
      for (var i = 0; i < 120; i++) {
        expect('${fb[i]}', '${fa[i]}', reason: 'persona nº ${i + 1}');
      }
    });

    test(
        'QA-CSV-011 · la segunda exportación (de B) es idéntica a la de A salvo los id',
        () async {
      final a = await _full120(db);
      final csvA = await AttendeeExchange(db).exportCsv(a.eventId);
      final db2 = qaDb();
      addTearDown(db2.close);
      final b = await qaEvent(db2, teams: 6, groups: const []);
      await qaLodgings(b);
      await _importar(b, csvA);
      final csvB = await AttendeeExchange(db2).exportCsv(b.eventId);
      List<List<String>> sinId(String c) =>
          [for (final r in parseCsv(c)) r.skip(1).toList()];
      expect(sinId(csvB), sinId(csvA));
    });

    test(
        'QA-CSV-012 · textos difíciles (;  ,  comillas, saltos de línea, tabulador, emoji) sobreviven al viaje de ida y vuelta',
        () async {
      final q = await qaEvent(db, teams: 2);
      final raros = [
        'Una; con punto y coma',
        'Con "comillas" dentro',
        'Línea 1\nLínea 2\r\nLínea 3',
        'Con\ttabulador',
        'Coma, y más, comas',
        '=SUMA(A1:A2)',
        'Emoji 🙂 y símbolos ñÑ áÉíÓú ü',
        '   espacios alrededor   ',
      ];
      for (final (i, n) in raros.indexed) {
        final p = qaPeople(10, seed: 1, couples: 0)[i];
        await q.repo.addAttendee(
            eventId: q.eventId,
            firstName: p.first,
            lastName1: p.last1,
            sex: p.sex,
            age: 20 + i,
            churchId: q.churchIds[0],
            notes: n);
      }
      final csv = await AttendeeExchange(db).exportCsv(q.eventId);
      final db2 = qaDb();
      addTearDown(db2.close);
      final b = await qaEvent(db2, teams: 2, groups: const []);
      final rep = await _importar(b, csv);
      expect(rep.created, raros.length);
      final notas = (await b.people()).map((p) => p.notes).toList()..sort();
      expect(notas, [for (final n in raros) n.trim()]..sort());
    });

    test(
        'QA-CSV-013 · una celda que empieza con «=», «+», «-» o «@» se exporta neutralizada (con apóstrofe) y al importar vuelve a su valor; los números y teléfonos normales no se tocan',
        () async {
      final q = await qaEvent(db, teams: 0, offersTeams: false);
      await q.repo.addAttendee(
          eventId: q.eventId,
          firstName: '=1+1',
          lastName1: '@cmd',
          sex: Sex.male,
          age: 30,
          churchId: q.churchIds[0],
          phone: '+5355551234',
          notes: '+5 -3');
      final csv = await AttendeeExchange(db).exportCsv(q.eventId);
      expect(csv, contains(";'=1+1;"));
      expect(csv, contains(";'@cmd;"));
      expect(csv, contains(";'+5 -3"));
      expect(csv,
          contains(';+5355551234;')); // un número sin espacios no es fórmula
      // Ida y vuelta: al importar en otro evento los textos son los originales.
      final db2 = qaDb();
      addTearDown(db2.close);
      final b = await qaEvent(db2, teams: 0, offersTeams: false);
      await _importar(b, csv);
      final p = (await b.people()).single;
      expect((p.firstName, p.lastName1, p.phone, p.notes),
          ('=1+1', '@cmd', '+5355551234', '+5 -3'));
    });
  });

  group('formatos de entrada', () {
    const cuerpo = [
      [
        'id',
        'numero',
        'nombre',
        'apellido1',
        'apellido2',
        'sexo',
        'edad',
        'iglesia',
        'provincia',
        'municipio',
        'telefono',
        'necesita_hospedaje',
        'hospedaje',
        'equipo',
        'pareja_numero',
        'grupos',
        'observaciones'
      ],
      [
        '',
        '',
        'José',
        'Peña',
        'Núñez',
        'Hombre',
        '30',
        'Bautista Ebenezer',
        'Matanzas',
        'Cárdenas',
        '',
        'Sí',
        '',
        '',
        '',
        '',
        'Ñandú'
      ],
      [
        '',
        '',
        'María',
        'Báez',
        '',
        'Mujer',
        '25',
        'Metodista de Colón',
        '',
        '',
        '5 111 2222',
        'No',
        '',
        '',
        '',
        '',
        ''
      ],
    ];
    String unir(String d) => '${cuerpo.map((r) => r.join(d)).join('\n')}\n';

    test('QA-CSV-020 · separador «;», «,» o tabulador dan las mismas filas',
        () {
      final a = parseAttendeesCsv(unir(';'));
      final b = parseAttendeesCsv(unir(','));
      final c = parseAttendeesCsv(unir('\t'));
      for (final p in [a, b, c]) {
        expect(p.errors, isEmpty);
        expect(
            p.rows.map(
                (r) => '${r.firstName}|${r.lastName1}|${r.age}|${r.church}'),
            [
              'José|Peña|30|Bautista Ebenezer',
              'María|Báez|25|Metodista de Colón'
            ]);
      }
    });

    test(
        'QA-CSV-021 · UTF-8 con y sin BOM, ANSI (Windows-1252), saltos \\n y \\r\\n se leen igual',
        () {
      final txt = unir(';');
      final casos = <String, Uint8List>{
        'utf8': Uint8List.fromList(utf8.encode(txt)),
        'utf8-bom': Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(txt)]),
        'ansi': Uint8List.fromList(latin1.encode(txt)),
        'crlf': Uint8List.fromList(utf8.encode(txt.replaceAll('\n', '\r\n'))),
        'cr-solo': Uint8List.fromList(utf8.encode(txt.replaceAll('\n', '\r'))),
      };
      for (final e in casos.entries) {
        final p = parseAttendeesCsv(decodeCsvBytes(e.value));
        expect(p.errors, isEmpty, reason: e.key);
        expect(p.rows.first.firstName, 'José', reason: e.key);
        expect(p.rows.first.lastName2, 'Núñez', reason: e.key);
        expect(p.rows.first.notes, 'Ñandú', reason: e.key);
      }
    });

    test(
        'QA-CSV-022 · columnas en otro orden, con alias (género, notas, cónyuge) y columnas desconocidas',
        () {
      const t =
          'Edad;Iglesia;Nombres;Primer apellido;Género;Notas;Columna rara;Pareja\n'
          '28;Bautista Ebenezer;Lucía;Pérez;F;hola;x;\n';
      final p = parseAttendeesCsv(t);
      expect(p.errors, isEmpty);
      expect(p.rows.single.sex, Sex.female);
      expect(p.rows.single.notes, 'hola');
      expect(p.notes.join(), contains('Columna rara'));
    });

    test(
        'QA-CSV-023 · UTF-16 (Excel «Texto Unicode», con marca FF FE o FE FF) se lee igual que UTF-8',
        () {
      final txt = unir('\t');
      final units = txt.codeUnits;
      final bytes = Uint8List.fromList([
        0xFF,
        0xFE,
        for (final u in units) ...[u & 0xFF, u >> 8]
      ]);
      final p = parseAttendeesCsv(decodeCsvBytes(bytes));
      final ref = parseAttendeesCsv(txt);
      expect(p.errors, isEmpty);
      expect(p.rows, isNotEmpty);
      expect(p.rows.length, ref.rows.length);
      expect([for (final r in p.rows) r.firstName],
          [for (final r in ref.rows) r.firstName]);
      // Y en big-endian (FE FF).
      final be = Uint8List.fromList([
        0xFE,
        0xFF,
        for (final u in units) ...[u >> 8, u & 0xFF]
      ]);
      expect(
          parseAttendeesCsv(decodeCsvBytes(be)).rows.length, ref.rows.length);
    });

    test(
        'QA-CSV-024 · sexo escrito como H, M, V, F, masculino, femenino, Hombre, Mujer; otro texto se rechaza con su fila',
        () {
      final t = StringBuffer('$_head\n');
      final sexos = [
        'H',
        'M',
        'V',
        'F',
        'masculino',
        'FEMENINO',
        'Hombre',
        'Mujer',
        'otro',
        ''
      ];
      for (final (i, s) in sexos.indexed) {
        t.writeln(';;N$i;A$i;;$s;30;Bautista Ebenezer;;;;;;;;;');
      }
      final p = parseAttendeesCsv(t.toString());
      expect(p.rows.length, 8);
      expect(p.errors.map((e) => e.line), [10, 11]);
      expect(p.errors.first.message, contains('no se entiende'));
      expect(p.errors.last.message, contains('falta el sexo'));
    });

    test(
        'QA-CSV-025 · filas con errores variados: cada una con su número de fila y las buenas se importan',
        () async {
      final q = await qaEvent(db, teams: 0, offersTeams: false);
      final t = '$_head\n'
          ';;Ok;Uno;;Hombre;30;Bautista Ebenezer;;;;;;;;;\n' // 2 ok
          ';;;Dos;;Hombre;30;Bautista Ebenezer;;;;;;;;;\n' // 3 sin nombre
          ';;Tres;;;Hombre;30;Bautista Ebenezer;;;;;;;;;\n' // 4 sin apellido
          ';;Cuatro;X;;Hombre;abc;Bautista Ebenezer;;;;;;;;;\n' // 5 edad texto
          ';;Cinco;X;;Hombre;0;Bautista Ebenezer;;;;;;;;;\n' // 6 edad 0
          ';;Seis;X;;Hombre;111;Bautista Ebenezer;;;;;;;;;\n' // 7 edad 111
          ';;Siete;X;;Hombre;30;;;;;;;;;;\n' // 8 sin iglesia
          ';;Ocho;X;;Hombre;30;Bautista Ebenezer;;;;Quizás;;;;;\n' // 9 hospedaje Quizás
          ';;Nueve;X;;Hombre;30;Bautista Ebenezer;;;;;;;xx;;\n' // 10 pareja inválida
          ';;Diez;X;;Hombre;30;Bautista Ebenezer;;;;;;;;;\n'; // 11 ok
      final p = parseAttendeesCsv(t);
      expect(p.errors.map((e) => e.line), [3, 4, 5, 6, 7, 8, 9, 10]);
      expect(p.rows.map((r) => r.firstName), ['Ok', 'Diez']);
      final rep = await _importar(q, t);
      expect(rep.created, 2);
      expect((await q.people()).length, 2);
    });
  });

  group('importar a un evento con datos', () {
    test(
        'QA-CSV-030 · importar el mismo archivo dos veces no duplica: la segunda vez actualiza por id',
        () async {
      final a = await _full120(db);
      final csv = await AttendeeExchange(db).exportCsv(a.eventId);
      final rep = await _importar(a, csv);
      expect(rep.created, 0);
      expect(rep.updated, 120);
      expect((await a.people()).length, 120);
    });

    test(
        'QA-CSV-031 · actualizar por id cambia edad, teléfono y observaciones sin tocar equipo, hospedaje ni número',
        () async {
      final a = await _full120(db);
      final antes = {for (final p in await a.people()) p.id: p};
      final filas = parseCsv(await AttendeeExchange(db).exportCsv(a.eventId));
      final i = filas[1];
      final id = i[0];
      i[6] = '${int.parse(i[6]) == 70 ? 69 : int.parse(i[6]) + 1}';
      i[10] = '5 999 8888';
      i[16] = 'Corregido en Excel';
      final nuevo = buildCsvDelimited(filas);
      final rep = await _importar(a, nuevo);
      expect(rep.updated, 120);
      final p = (await a.repo.attendeeById(id))!;
      expect(p.age, int.parse(i[6]));
      expect(p.phone, '5 999 8888');
      expect(p.notes, 'Corregido en Excel');
      expect(p.regNumber, antes[id]!.regNumber);
      expect(p.teamId, antes[id]!.teamId);
      expect(p.lodgingId, antes[id]!.lodgingId);
    });

    test(
        'QA-CSV-032 · 30 personas nuevas («seguir inscribiendo desde Excel») se suman con números seguidos',
        () async {
      final a = await _full120(db);
      final b = StringBuffer('$_head\n');
      for (final (i, p) in qaPeople(30, seed: 4242, couples: 0).indexed) {
        b.writeln(
            ';;${p.first} ${i}x;${p.last1}z;;${p.sex == Sex.male ? 'Hombre' : 'Mujer'};${p.age};${qaChurches[p.churchIdx].$1};;;;Sí;;;;;');
      }
      final rep = await _importar(a, b.toString());
      expect(rep.created, 30);
      final nums = ((await a.people())
            ..sort((x, y) => x.regNumber.compareTo(y.regNumber)))
          .map((p) => p.regNumber)
          .toList();
      expect(nums, [for (var i = 1; i <= 150; i++) i]);
    });

    test(
        'QA-CSV-033 · las personas que llegan por CSV quedan SIN equipo aunque el evento reparta equipos automáticamente (observación)',
        () async {
      final a = await qaEvent(db, teams: 4);
      await qaInscribeAll(a, qaPeople(12, couples: 0));
      final csv =
          '$_head\n;;Nueva;Persona;;Mujer;30;Bautista Ebenezer;;;;;;;;;\n';
      await _importar(a, csv);
      final nueva =
          (await a.people()).firstWhere((p) => p.firstName == 'Nueva');
      expect(nueva.teamId, isNotNull,
          reason:
              'inscribir por CSV debería dar equipo como inscribir por el formulario');
    });

    test(
        'QA-CSV-034 · duplicados: persona ya existente y repetida en el archivo se omiten; con «incluir duplicados» se importan',
        () async {
      final a = await qaEvent(db, teams: 0, offersTeams: false);
      await _importar(
          a, '$_head\n;;Juan;Pérez;;Hombre;34;Bautista Ebenezer;;;;;;;;;\n');
      final t = '$_head\n'
          ';;Juan;Pérez;;Hombre;34;Bautista Ebenezer;;;;;;;;;\n' // ya existe
          ';;Rosa;Cruz;;Mujer;20;Bautista Ebenezer;;;;;;;;;\n'
          ';;ROSA;cruz;;Mujer;20;Bautista Ebenezer;;;;;;;;;\n'; // repetida
      final ex = AttendeeExchange(db);
      final plan = await ex.plan(a.eventId, parseAttendeesCsv(t));
      expect((plan.creates, plan.duplicates), (1, 2));
      final plan2 = await ex.plan(a.eventId, parseAttendeesCsv(t),
          includeDuplicates: true);
      expect((plan2.creates, plan2.duplicates), (3, 0));
    });

    test(
        'QA-CSV-035 · id o número repetidos en el archivo se rechazan en las filas repetidas',
        () {
      final t = '$_head\n'
          'abc;1;Ana;Uno;;Mujer;20;Bautista Ebenezer;;;;;;;;;\n'
          'abc;2;Bea;Dos;;Mujer;21;Bautista Ebenezer;;;;;;;;;\n'
          ';1;Cris;Tres;;Mujer;22;Bautista Ebenezer;;;;;;;;;\n';
      final p = parseAttendeesCsv(t);
      expect(p.rows.length, 1);
      expect(p.errors.map((e) => e.message), [
        contains('repite el de la fila 2'),
        contains('repite el de la fila 2')
      ]);
    });

    test(
        'QA-CSV-036 · el número del archivo ya ocupado por otra persona: se importa como nueva con otro número',
        () async {
      final a = await qaEvent(db, teams: 0, offersTeams: false);
      await _importar(
          a, '$_head\n;;Juan;Pérez;;Hombre;34;Bautista Ebenezer;;;;;;;;;\n');
      final rep = await _importar(
          a, '$_head\n;1;Pedro;Gil;;Hombre;40;Bautista Ebenezer;;;;;;;;;\n');
      expect(rep.created, 1);
      final nums = (await a.people())
          .map((p) => '${p.regNumber}:${p.firstName}')
          .toSet();
      expect(nums, {'1:Juan', '2:Pedro'});
    });

    test(
        'QA-CSV-036b · número libre con hueco: se conserva; ocupado: el siguiente; la pareja por número sigue funcionando',
        () async {
      final a = await qaEvent(db, teams: 0, offersTeams: false);
      await _importar(
          a, '$_head\n;;Juan;Pérez;;Hombre;34;Bautista Ebenezer;;;;;;;;;\n');
      // 1 ocupado (Juan), 7 y 9 libres con hueco; Rosa (7) es pareja de Luis (9).
      final rep = await _importar(
          a,
          '$_head\n'
          ';1;Pedro;Gil;;Hombre;40;Bautista Ebenezer;;;;;;;;;\n'
          ';7;Rosa;Cruz;;Mujer;30;Bautista Ebenezer;;;;;;;9;;\n'
          ';9;Luis;Mora;;Hombre;31;Bautista Ebenezer;;;;;;;7;;\n');
      expect(rep.created, 3);
      final todos = {for (final p in await a.people()) p.firstName: p};
      expect(todos['Pedro']!.regNumber, 2);
      expect(todos['Rosa']!.regNumber, 7);
      expect(todos['Luis']!.regNumber, 9);
      final pareja = await a.social.spouseOf(todos['Rosa']!.id);
      expect(pareja?.id, todos['Luis']!.id);
    });

    test(
        'QA-CSV-036c · un número libre en la base pero de alguien borrado se considera ocupado',
        () async {
      final a = await qaEvent(db, teams: 0, offersTeams: false);
      await qaInscribeAll(a, qaPeople(3, couples: 0));
      await a.repo
          .deleteAttendee(a.ids[2], isAdmin: true); // el nº 3 queda reservado
      await _importar(
          a, '$_head\n;3;Pedro;Gil;;Hombre;40;Bautista Ebenezer;;;;;;;;;\n');
      final pedro =
          (await a.people()).firstWhere((p) => p.firstName == 'Pedro');
      expect(pedro.regNumber, 4);
    });

    test(
        'QA-CSV-033b · equipo del archivo manda sobre el automático; sin equipo en el archivo se reparte; la pareja nueva queda junta',
        () async {
      final a = await qaEvent(db, teams: 4);
      await qaInscribeAll(a, qaPeople(12, couples: 0));
      final equipos = await a.teamRows();
      final elegido = equipos.last.name;
      final rep = await _importar(
          a,
          '$_head\n'
          ';;Con;Equipo;;Mujer;30;Bautista Ebenezer;;;;;;$elegido;;;\n'
          ';20;Esposo;Nuevo;;Hombre;40;Bautista Ebenezer;;;;;;;21;;\n'
          ';21;Esposa;Nueva;;Mujer;38;Bautista Ebenezer;;;;;;;20;;\n');
      final todos = {for (final p in await a.people()) p.firstName: p};
      expect(todos['Con']!.teamId, equipos.last.id);
      expect(todos['Esposo']!.teamId, isNotNull);
      expect(todos['Esposo']!.teamId, todos['Esposa']!.teamId);
      expect(rep.teamsAutoAssigned, 2);
    });

    test(
        'QA-CSV-033c · evento sin equipos o que no los usa: nada se asigna y no falla',
        () async {
      final a = await qaEvent(db, teams: 0, offersTeams: false);
      final rep = await _importar(
          a, '$_head\n;;Nueva;Persona;;Mujer;30;Bautista Ebenezer;;;;;;;;;\n');
      expect(rep.created, 1);
      expect(rep.teamsAutoAssigned, 0);
      expect((await a.people()).single.teamId, isNull);
    });

    test(
        'QA-CSV-037 · hospedaje o equipo que no existen: avisa fila por fila, importa a la persona sin eso',
        () async {
      final a = await qaEvent(db, teams: 2);
      await qaLodgings(a);
      final t = '$_head\n'
          ';;Ana;Uno;;Mujer;20;Bautista Ebenezer;;;;Sí;Hotel Fantasma;Equipo Inventado;;;\n'
          ';;Bea;Dos;;Mujer;21;Bautista Ebenezer;;;;Sí;Casa de la Hna. Teresa;Azul;;;\n';
      final ex = AttendeeExchange(db);
      final plan = await ex.plan(a.eventId, parseAttendeesCsv(t));
      expect(
          plan.warnings.where((w) => w.contains('Hotel Fantasma')).length, 1);
      expect(
          plan.warnings.where((w) => w.contains('Equipo Inventado')).length, 1);
      await ex.apply(a.eventId, plan);
      final rows = await a.people();
      final ana = rows.firstWhere((p) => p.firstName == 'Ana');
      final bea = rows.firstWhere((p) => p.firstName == 'Bea');
      expect(ana.lodgingId, isNull);
      expect(ana.teamId,
          isNotNull); // equipo inválido en el archivo: se asigna uno automático
      expect(bea.lodgingId, isNotNull);
      expect(bea.teamId, isNotNull);
    });

    test(
        'QA-CSV-038 · parejas: bien formadas se vinculan; a un número que no existe o a sí mismo avisan',
        () async {
      final a = await qaEvent(db, teams: 0, offersTeams: false);
      final t = '$_head\n'
          ';1;Raúl;Gil;;Hombre;40;Bautista Ebenezer;;;;;;;2;;\n'
          ';2;Elena;Gil;;Mujer;38;Bautista Ebenezer;;;;;;;1;;\n'
          ';3;Solo;Uno;;Hombre;30;Bautista Ebenezer;;;;;;;99;;\n'
          ';4;Yo;Mismo;;Hombre;30;Bautista Ebenezer;;;;;;;4;;\n';
      final rep = await _importar(a, t);
      expect(rep.warnings.length, 2);
      expect(rep.warnings.join(' '), contains('no se encontró a la pareja'));
      final sp = await a.social.spouseMap(a.eventId);
      expect(sp.length, 2);
    });

    test(
        'QA-CSV-039 · parejas contradictorias (A→B, B→C): no deja a nadie en un estado roto y avisa',
        () async {
      final a = await qaEvent(db, teams: 0, offersTeams: false);
      final t = '$_head\n'
          ';1;Ana;Uno;;Mujer;40;Bautista Ebenezer;;;;;;;2;;\n'
          ';2;Beto;Dos;;Hombre;38;Bautista Ebenezer;;;;;;;3;;\n'
          ';3;Cris;Tres;;Mujer;30;Bautista Ebenezer;;;;;;;2;;\n';
      final rep = await _importar(a, t);
      final sp = await a.social.spouseMap(a.eventId);
      // Cada persona tiene a lo sumo una pareja y es recíproca.
      for (final e in sp.entries) {
        expect(sp[e.value], e.key);
      }
      expect(rep.warnings, isNotEmpty,
          reason: 'la fila de Ana quedó sin pareja y no se avisó');
      // Decisión: con parejas contradictorias no se vincula a nadie del grupo.
      expect(sp, isEmpty);
      expect(rep.warnings.where((w) => w.contains('se contradice')).length, 3);
    });

    test(
        'QA-CSV-040 · grupos: varios por celda con «|», se crean los que no existen y no se repiten',
        () async {
      final a =
          await qaEvent(db, teams: 0, offersTeams: false, groups: const []);
      final t = '$_head\n'
          ';;Ana;Uno;;Mujer;20;Bautista Ebenezer;;;;;;;;Coro|Jóvenes;\n'
          ';;Bea;Dos;;Mujer;21;Bautista Ebenezer;;;;;;;;coro;\n';
      final rep = await _importar(a, t);
      expect(rep.groupsCreated, 2);
      final gs = await db.select(db.attendeeGroups).get();
      expect(gs.length, 2);
    });
  });

  group('volumen y rendimiento (1000 filas)', () {
    test(
        'QA-CSV-050 · un archivo de 1000 filas se lee, se revisa e importa; tiempos medidos',
        () async {
      final people = qaPeople(1000, seed: 77, couples: 60);
      final b = StringBuffer('$_head\n');
      for (final (i, p) in people.indexed) {
        final sp = p.spouseIdx == null ? '' : '${p.spouseIdx! + 1}';
        b.writeln(
            ';${i + 1};${p.first};${p.last1};${p.last2};${p.sex == Sex.male ? 'Hombre' : 'Mujer'};${p.age};${qaChurches[p.churchIdx].$1};;;;${p.needsLodging ? 'Sí' : 'No'};;;$sp;;');
      }
      final q = await qaEvent(db, teams: 0, offersTeams: false);
      final sw = Stopwatch()..start();
      final parse = parseAttendeesCsv(b.toString());
      final tParse = sw.elapsedMilliseconds;
      final ex = AttendeeExchange(db);
      final plan = await ex.plan(q.eventId, parse);
      final tPlan = sw.elapsedMilliseconds - tParse;
      final rep = await ex.apply(q.eventId, plan);
      final tApply = sw.elapsedMilliseconds - tParse - tPlan;
      metric(
          'CSV-050 1000 filas: leer $tParse ms, revisar $tPlan ms, importar $tApply ms');
      expect(parse.errors, isEmpty);
      expect(rep.created, 1000);
      expect(rep.warnings, isEmpty, reason: rep.warnings.take(3).join(' / '));
      expect((await q.social.spouseMap(q.eventId)).length, 120);
      expect(tParse + tPlan + tApply, lessThan(30000));
    });
  });

  group('número de inscripción al importar', () {
    test(
        'QA-CSV-060 · al importar a un evento vacío se conservan los números del archivo aunque haya huecos',
        () async {
      final a = await qaEvent(db, teams: 0, offersTeams: false);
      await qaInscribeAll(a, qaPeople(10, couples: 0));
      await a.repo
          .deleteAttendee(a.ids[2], isAdmin: true); // el nº 3 se borra: hueco
      final csv = await AttendeeExchange(db).exportCsv(a.eventId);
      final db2 = qaDb();
      addTearDown(db2.close);
      final b = await qaEvent(db2, teams: 0, offersTeams: false);
      await _importar(b, csv);
      final na = ((await a.people())
            ..sort((x, y) => x.regNumber.compareTo(y.regNumber)))
          .map((p) => p.regNumber)
          .toList();
      final nb = ((await b.people())
            ..sort((x, y) => x.regNumber.compareTo(y.regNumber)))
          .map((p) => p.regNumber)
          .toList();
      expect(nb, na, reason: 'A: $na, B: $nb');
    });
  });
}
