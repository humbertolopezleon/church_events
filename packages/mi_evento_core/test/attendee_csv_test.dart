import 'dart:convert';

import 'package:mi_evento_core/mi_evento_core.dart';
import 'package:test/test.dart';

void main() {
  group('lector de CSV', () {
    test('separador «;» (Excel en español), BOM y saltos CRLF', () {
      final t = parseCsv('﻿a;b;c\r\n1;2;3\r\n');
      expect(t, [
        ['a', 'b', 'c'],
        ['1', '2', '3']
      ]);
    });
    test('separador «,» y tabulador se adivinan solos', () {
      expect(parseCsv('a,b\n1,2'), [
        ['a', 'b'],
        ['1', '2']
      ]);
      expect(parseCsv('a\tb\n1\t2'), [
        ['a', 'b'],
        ['1', '2']
      ]);
    });
    test(
        'comillas: separador, comillas dobles y saltos de línea dentro de la celda',
        () {
      final t = parseCsv('a;b\n"x;y";"dice ""hola""\nlinea 2"');
      expect(t[1], ['x;y', 'dice "hola"\nlinea 2']);
    });
    test('omite filas vacías y acepta que falte el salto final', () {
      expect(parseCsv('a;b\n\n1;2'), [
        ['a', 'b'],
        ['1', '2']
      ]);
      expect(parseCsv(''), isEmpty);
    });
    test('ida y vuelta con el escritor (tildes, comillas, saltos, separadores)',
        () {
      final rows = [
        ['nombre', 'obs'],
        ['José Ángel', 'dice "hola"; adiós\nfin'],
        ['Ana, María', ''],
      ];
      expect(parseCsv(buildCsvDelimited(rows)), rows);
      expect(parseCsv(buildCsvDelimited(rows, delimiter: ',')), rows);
    });
  });

  String file(List<String> lines) =>
      '${attendeeCsvHeaders.join(';')}\n${lines.join('\n')}';

  group('asistentes', () {
    test('fila válida con todas las columnas', () {
      final r = parseAttendeesCsv(file([
        ';;Ana;Pérez;Gómez;Mujer;27;Bautista Ebenezer;Matanzas;Cárdenas;555;Sí;Casa de Ana;Azul;3;Jóvenes|Coro;Alérgica',
      ]));
      expect(r.errors, isEmpty);
      final a = r.rows.single;
      expect(a.firstName, 'Ana');
      expect(a.sex, Sex.female);
      expect(a.age, 27);
      expect(a.church, 'Bautista Ebenezer');
      expect(a.needsLodging, isTrue);
      expect(a.lodging, 'Casa de Ana');
      expect(a.team, 'Azul');
      expect(a.spouseNumber, 3);
      expect(a.groups, ['Jóvenes', 'Coro']);
      expect(a.line, 2);
    });

    test('columnas en otro orden, con otros nombres y sin tildes ni mayúsculas',
        () {
      final r = parseAttendeesCsv(
          'Iglesia;EDAD;Sexo;Primer Apellido;Nombre\nCentral;30;H;López;Luis');
      expect(r.errors, isEmpty);
      expect(r.rows.single.sex, Sex.male);
      expect(r.rows.single.lastName1, 'López');
    });

    test('faltan columnas obligatorias: error claro y nada importable', () {
      final r = parseAttendeesCsv('nombre;edad\nAna;20');
      expect(r.rows, isEmpty);
      expect(r.errors.single.message, contains('Faltan columnas obligatorias'));
      expect(r.errors.single.message, contains('apellido1'));
    });

    test('errores por fila con su número; las demás filas sí pasan', () {
      final r = parseAttendeesCsv(file([
        ';;Ana;Pérez;;Mujer;27;Central;;;;;;;;;',
        ';;;Gómez;;Mujer;27;Central;;;;;;;;;', // sin nombre
        ';;Luis;Díaz;;Robot;27;Central;;;;;;;;;', // sexo
        ';;Rosa;Cruz;;Mujer;abc;Central;;;;;;;;;', // edad
        ';;Pepe;Cruz;;Hombre;200;Central;;;;;;;;;', // edad fuera de rango
        ';;Eva;Cruz;;Mujer;20;;;;;;;;;;', // sin iglesia
      ]));
      expect(r.rows.map((x) => x.firstName), ['Ana']);
      expect(r.errors.map((e) => e.line), [3, 4, 5, 6, 7]);
      expect(r.errors[0].message, contains('falta el nombre'));
      expect(r.errors[1].message, contains('Robot'));
      expect(r.errors[2].message, contains('abc'));
      expect(r.errors[3].message, contains('entre 1 y 110'));
      expect(r.errors[4].message, contains('falta la iglesia'));
    });

    test('id o número repetidos en el archivo se señalan', () {
      final r = parseAttendeesCsv(file([
        'u1;1;Ana;Pérez;;Mujer;27;Central;;;;;;;;;',
        'u1;2;Eva;Pérez;;Mujer;27;Central;;;;;;;;;',
        ';1;Rosa;Pérez;;Mujer;27;Central;;;;;;;;;',
      ]));
      expect(r.rows, hasLength(1));
      expect(r.errors[0].message, contains('repite el de la fila 2'));
      expect(r.errors[1].message, contains('número 1 repite'));
    });

    test('Sí/No y celdas vacías de hospedaje', () {
      final r = parseAttendeesCsv(file([
        ';;Ana;P;;Mujer;27;Central;;;;no;;;;;',
        ';;Eva;P;;Mujer;27;Central;;;;;;;;;',
        ';;Rosa;P;;Mujer;27;Central;;;;quizá;;;;;',
      ]));
      expect(r.rows[0].needsLodging, isFalse);
      expect(r.rows[1].needsLodging, isNull); // vacío: no cambia lo guardado
      expect(r.errors.single.message, contains('Sí o No'));
    });

    test('columnas desconocidas se ignoran con un aviso', () {
      final r = parseAttendeesCsv(
          'nombre;apellido1;sexo;edad;iglesia;color favorito\nAna;P;Mujer;20;C;azul');
      expect(r.errors, isEmpty);
      expect(r.notes.single, contains('color favorito'));
    });

    test('archivo vacío', () {
      expect(parseAttendeesCsv('').errors.single.message, contains('vacío'));
    });

    test('sexo: H/M/F/Hombre/Mujer', () {
      expect(parseSexCell('Hombre'), Sex.male);
      expect(parseSexCell(' h '), Sex.male);
      expect(parseSexCell('Mujer'), Sex.female);
      expect(
          parseSexCell('M'), Sex.male); // M = masculino, como en el formulario
      expect(parseSexCell('F'), Sex.female);
      expect(parseSexCell('x'), isNull);
    });
  });

  group('compatibilidad con Excel (línea sep=;)', () {
    test('lo exportado empieza con BOM + «sep=;» y se vuelve a leer igual', () {
      final rows = [
        ['nombre', 'edad', 'nota'],
        ['María', '30', 'a;b'],
        ['=SUMA(A1)', '5', 'dice "hola"\nlínea 2'],
      ];
      final text = buildCsvDelimited(rows);
      expect(text.startsWith('\u{FEFF}sep=;\r\n'), isTrue);
      expect(parseCsv(text), rows);
    });
    test('sin la ayuda, igual que antes (sin línea sep)', () {
      final text = buildCsvDelimited([
        ['a', 'b']
      ], excelHint: false);
      expect(text.startsWith('\u{FEFF}a;b'), isTrue);
    });
    test(
        'un archivo con «sep=,» se lee con coma aunque el resto sugiera otra cosa',
        () {
      expect(parseCsv('sep=,\r\na;b,c\r\n1,2\r\n'), [
        ['a;b', 'c'],
        ['1', '2']
      ]);
    });
    test(
        'la línea sep puede volver rellena de separadores o entre comillas (otras hojas de cálculo)',
        () {
      for (final first in ['sep=;;;;', '"sep=;"', '"sep=;";;;', 'SEP=;']) {
        expect(
            parseCsv('$first\n"a";"b"\n1;2\n'),
            [
              ['a', 'b'],
              ['1', '2']
            ],
            reason: first);
      }
    });
    test('un archivo guardado por Excel (sin la línea sep) sigue leyéndose',
        () {
      expect(parseCsv('a;b\r\n1;2\r\n'), [
        ['a', 'b'],
        ['1', '2']
      ]);
    });
  });

  group('decodeCsvBytes (Excel en Windows)', () {
    test('UTF-8 con BOM y sin BOM', () {
      final utf = utf8.encode('Ñandú;Álvarez');
      expect(decodeCsvBytes(utf), 'Ñandú;Álvarez');
      expect(parseCsv(decodeCsvBytes([0xEF, 0xBB, 0xBF, ...utf])).first,
          ['Ñandú', 'Álvarez']);
    });

    test('ANSI (Windows-1252): tildes, eñes y diéresis', () {
      // «Ñandú;Álvarez;Güell;¿ok?» en Windows-1252.
      final ansi = [
        0xD1, 0x61, 0x6E, 0x64, 0xFA, 0x3B, //
        0xC1, 0x6C, 0x76, 0x61, 0x72, 0x65, 0x7A, 0x3B,
        0x47, 0xFC, 0x65, 0x6C, 0x6C, 0x3B, 0xBF, 0x6F, 0x6B, 0x3F
      ];
      expect(decodeCsvBytes(ansi), 'Ñandú;Álvarez;Güell;¿ok?');
    });

    test('ANSI: comillas tipográficas, rayas, «€» y «…» (0x80–0x9F)', () {
      // “Iglesia” – 5€ … ‘a’ — ™
      final ansi = [
        0x93, ...'Iglesia'.codeUnits, 0x94, 0x20, 0x96, 0x20, 0x35, 0x80, 0x20,
        0x85, 0x20, 0x91, 0x61, 0x92, 0x20, 0x97, 0x20, 0x99
      ];
      expect(decodeCsvBytes(ansi), '“Iglesia” – 5€ … ‘a’ — ™');
    });

    test('UTF-16 («Texto Unicode» de Excel, tabulador)', () {
      final units = 'nombre\tedad\r\nÑandú\t30\r\n'.codeUnits;
      final le = [
        0xFF, 0xFE,
        for (final u in units) ...[u & 0xFF, u >> 8]
      ];
      final be = [
        0xFE, 0xFF,
        for (final u in units) ...[u >> 8, u & 0xFF]
      ];
      for (final b in [le, be]) {
        expect(parseCsv(decodeCsvBytes(b)), [
          ['nombre', 'edad'],
          ['Ñandú', '30']
        ]);
      }
    });
  });
}
