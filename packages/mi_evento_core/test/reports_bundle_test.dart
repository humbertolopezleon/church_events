import 'dart:convert';
import 'dart:typed_data';

import 'package:mi_evento_core/mi_evento_core.dart';
import 'package:test/test.dart';

ReportPerson p(bool male, int age,
        {String? church, String? team, String? lodging, bool needs = false}) =>
    ReportPerson(
        isMale: male,
        age: age,
        church: church,
        team: team,
        lodging: lodging,
        needsLodging: needs);

void main() {
  group('reportes', () {
    final people = [
      p(true, 13,
          church: 'Bautista', team: 'Rojo', lodging: 'Albergue', needs: true),
      p(false, 19, church: 'Bautista', team: 'Rojo', needs: true),
      p(false, 30, church: 'Metodista', team: 'Azul'),
      p(true, 45, church: 'Metodista'),
      p(true, 70),
      p(false, 5, church: 'Bautista'),
    ];
    final sections = buildReportSections(people, AgeRange.defaults);
    ReportSection sec(String t) => sections.firstWhere((s) => s.title == t);

    test('cada sección suma el total de personas (los reportes cuadran)', () {
      for (final s in sections) {
        expect(s.total, 6, reason: s.title);
      }
    });
    test('por sexo', () {
      expect(sec('Por sexo').rows.map((r) => (r.label, r.count)),
          [('Mujeres', 3), ('Hombres', 3)]);
    });
    test(
        'por rango de edad: usa los rangos del evento y avisa de quien queda fuera',
        () {
      expect(sec('Por rango de edad').rows.map((r) => (r.label, r.count)),
          [('0–11', 1), ('12–17', 1), ('18–25', 1), ('26–40', 1), ('41+', 2)]);
      final custom = buildReportSections(
          people, const [AgeRange('Jóvenes', 10, 30), AgeRange('Adultos', 31)]);
      expect(custom[1].rows.map((r) => (r.label, r.count)),
          [('Jóvenes', 3), ('Adultos', 2), ('Sin rango', 1)]);
    });
    test('por iglesia: de mayor a menor y «Sin iglesia» al final', () {
      expect(sec('Por iglesia').rows.map((r) => (r.label, r.count)),
          [('Bautista', 3), ('Metodista', 2), ('Sin iglesia', 1)]);
    });
    test('por hospedaje: hospedados, necesitan sin asignar y no necesitan', () {
      expect(sec('Por hospedaje').rows.map((r) => (r.label, r.count)), [
        ('Albergue', 1),
        ('Necesitan y sin asignar', 1),
        ('No necesitan hospedaje', 4)
      ]);
    });
    test('por equipo, con «Sin equipo» al final', () {
      expect(sec('Por equipo').rows.map((r) => (r.label, r.count)),
          [('Azul', 1), ('Rojo', 2), ('Sin equipo', 3)]);
    });
    test('evento vacío: secciones sin filas inventadas', () {
      final e = buildReportSections(const [], AgeRange.defaults);
      expect(e.every((s) => s.total == 0), isTrue);
      expect(e.firstWhere((s) => s.title == 'Por iglesia').rows, isEmpty);
    });
  });

  group('respaldo CSV', () {
    final tables = {
      'events': [
        {'id': 'e1', 'name': 'Retiro', 'updatedAt': 1}
      ],
      'attendees': [
        {'id': 'a1', 'firstName': 'María', 'notes': 'ñandú "x" \n línea; =1+1'},
        {'id': 'a2', 'firstName': 'Juan', 'notes': '', 'phone': null},
      ],
    };
    Uint8List make() => encodeBundle(
        tables: tables,
        dbSchemaVersion: 4,
        deviceId: 'dev1',
        eventId: 'e1',
        eventName: 'Retiro de Jóvenes',
        now: DateTime.utc(2026, 12, 12, 10));

    test(
        'ida y vuelta sin pérdida (tildes, comillas, saltos de línea, fórmulas)',
        () {
      final b = decodeBundle(make());
      expect(b.tables['attendees']![0]['notes'], 'ñandú "x" \n línea; =1+1');
      expect(b.tables['events']!.single['name'], 'Retiro');
      expect(b.manifest.eventName, 'Retiro de Jóvenes');
      expect(b.manifest.counts, {'events': 1, 'attendees': 2});
      expect(b.manifest.deviceId, 'dev1');
      expect(b.manifest.exportedAt, DateTime.utc(2026, 12, 12, 10));
      expect(b.manifest.formatVersion, bundleFormatVersion);
    });
    test('es un único CSV de texto con columna «tabla» (Excel lo abre)', () {
      final bytes = make();
      expect(bytes.take(3), [0xEF, 0xBB, 0xBF]); // BOM UTF-8
      final text = utf8.decode(bytes);
      expect(text.startsWith('tabla;'), isTrue);
      expect(text, contains('meta;'));
      expect(text, contains('attendees;'));
      expect(text, contains('María')); // sin cifrar: se puede leer
    });
    test('también se abre si Excel lo guardó en ANSI o UTF-16', () {
      final text = utf8.decode(make());
      final ansi = latin1.encode(text.replaceAll('\u{FEFF}', ''));
      expect(decodeBundle(ansi).tables['attendees'], hasLength(2));
      final u16 = <int>[
        0xFF,
        0xFE,
        for (final c in text.replaceAll('\u{FEFF}', '').codeUnits) ...[
          c & 255,
          c >> 8
        ]
      ];
      expect(decodeBundle(u16).tables['attendees']![0]['firstName'], 'María');
    });
    test('archivos que no son copias dan mensajes claros', () {
      expect(() => decodeBundle(utf8.encode('hola')),
          throwsA(isA<BundleException>()));
      expect(
          () => decodeBundle(utf8.encode('nombre;edad\nAna;3\n')),
          throwsA(isA<BundleException>().having(
              (e) => e.message, 'message', contains('no es una copia'))));
    });
    test('un archivo truncado (faltan filas) se detecta', () {
      final lines = utf8.decode(make()).trimRight().split('\r\n');
      final cut = '${lines.take(lines.length - 1).join('\r\n')}\r\n';
      expect(
          () => decodeBundle(utf8.encode(cut)),
          throwsA(isA<BundleException>()
              .having((e) => e.message, 'message', contains('incompleta'))));
    });
    test('un archivo de formato más nuevo se rechaza pidiendo actualizar', () {
      final text = utf8.decode(make()).replaceFirst(
          'formatVersion;$bundleFormatVersion',
          'formatVersion;${bundleFormatVersion + 1}');
      expect(
          () => decodeBundle(utf8.encode(text)),
          throwsA(isA<BundleException>().having(
              (e) => e.message, 'message', contains('Actualiza la app'))));
    });
    test(
        'regla de fusión: gana la fila más reciente; en empate se conserva la local',
        () {
      final t = DateTime.utc(2026, 1, 1);
      expect(incomingWins(t, t.add(const Duration(seconds: 1))), isTrue);
      expect(incomingWins(t, t), isFalse);
      expect(incomingWins(t, t.subtract(const Duration(seconds: 1))), isFalse);
    });
    test('1500 filas se empaquetan y abren rápido', () {
      final big = {
        'attendees': [
          for (var i = 0; i < 1500; i++)
            {'id': 'a$i', 'firstName': 'Nombre $i', 'notes': 'x' * 40}
        ]
      };
      final sw = Stopwatch()..start();
      final bytes = encodeBundle(
          tables: big,
          dbSchemaVersion: 4,
          deviceId: 'd',
          eventId: 'e',
          eventName: 'E');
      expect(decodeBundle(bytes).tables['attendees'], hasLength(1500));
      expect(sw.elapsedMilliseconds, lessThan(3000));
    });
  });
}
