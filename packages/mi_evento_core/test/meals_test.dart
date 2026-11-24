import 'package:mi_evento_core/mi_evento_core.dart';
import 'package:test/test.dart';

void main() {
  group('nombres', () {
    test('sugerencia de sesión con el día en español', () {
      expect(suggestSessionName('Almuerzo', DateTime(2026, 12, 12)),
          'Almuerzo del sábado'); // sábado
      expect(suggestSessionName('Cena', DateTime(2026, 12, 11)),
          'Cena del viernes');
      expect(suggestSessionName('Desayuno', DateTime(2026, 12, 13)),
          'Desayuno del domingo');
      expect(suggestSessionName('  ', DateTime(2026, 12, 14)),
          'Control del lunes');
      expect(weekdayEs(DateTime(2026, 12, 16)), 'miércoles');
    });
    test('textos según el tipo, tolerando tildes y mayúsculas', () {
      expect(alreadyDoneText('Almuerzo'), 'ya almorzó');
      expect(alreadyDoneText('DESAYUNO'), 'ya desayunó');
      expect(alreadyDoneText('Cena de clausura'), 'ya cenó');
      expect(
          alreadyDoneText('Entrega de materiales'), 'ya pasó por esta sesión');
      expect(canDoText('Almuerzo'), 'Puede almorzar');
      expect(canDoText('Taller de música'), 'Puede pasar');
    });
  });

  group('estadísticas', () {
    final people = [
      for (var i = 0; i < 10; i++)
        MealPerson(
            id: 'p$i',
            sexIsMale: i.isEven,
            teamId: i < 5 ? 'rojo' : (i < 9 ? 'azul' : null)),
    ];
    test('pasaron, faltan y porcentaje', () {
      final s = computeMealStats(people, {'p0', 'p1', 'p2'});
      expect((s.total, s.passed, s.pending, s.percent), (10, 3, 7, 30));
    });
    test('por equipo, incluyendo «sin equipo»', () {
      final s = computeMealStats(people, {'p0', 'p1', 'p5', 'p9'});
      expect(s.byTeam['rojo'], (2, 5));
      expect(s.byTeam['azul'], (1, 4));
      expect(s.byTeam[null], (1, 1));
    });
    test(
        'ids ajenos (personas eliminadas) no cuentan; evento vacío no divide por cero',
        () {
      expect(computeMealStats(people, {'fantasma'}).passed, 0);
      final e = computeMealStats(const [], {});
      expect((e.total, e.percent), (0, 0));
    });
    test('el porcentaje se redondea (231 de 248 = 93 %)', () {
      final many = [
        for (var i = 0; i < 248; i++) MealPerson(id: '$i', sexIsMale: true)
      ];
      expect(
          computeMealStats(many, {for (var i = 0; i < 231; i++) '$i'}).percent,
          93);
    });
  });

  group('llegadas cada 15 minutos', () {
    test('agrupa y no se salta tramos vacíos', () {
      final t = [
        DateTime(2026, 12, 12, 12, 1),
        DateTime(2026, 12, 12, 12, 14),
        DateTime(2026, 12, 12, 12, 16),
        DateTime(2026, 12, 12, 12, 50)
      ];
      final b = arrivalBuckets(t);
      expect(b.map((e) => hhmm(e.$1)), ['12:00', '12:15', '12:30', '12:45']);
      expect(b.map((e) => e.$2), [2, 1, 0, 1]);
    });
    test('un solo registro y lista vacía', () {
      expect(arrivalBuckets([DateTime(2026, 1, 1, 8, 7)]).single.$2, 1);
      expect(arrivalBuckets(const []), isEmpty);
    });
    test('cruza la hora y respeta tramos distintos', () {
      final b = arrivalBuckets(
          [DateTime(2026, 1, 1, 12, 55), DateTime(2026, 1, 1, 13, 5)],
          bucketMinutes: 10);
      expect(b.map((e) => hhmm(e.$1)), ['12:50', '13:00']);
    });
    test('la entrada sin ordenar da el mismo resultado', () {
      final a = [DateTime(2026, 1, 1, 12, 40), DateTime(2026, 1, 1, 12, 5)];
      expect(arrivalBuckets(a).map((e) => e.$2),
          arrivalBuckets(a.reversed.toList()).map((e) => e.$2));
    });
  });

  group('CSV', () {
    test('escapa comas, comillas y saltos; BOM y CRLF', () {
      final s = buildCsv([
        ['Nombre', 'Observaciones'],
        ['Pérez, Juan', 'dijo "hola"'],
        ['Ana', 'línea1\nlínea2'],
      ]);
      expect(s.startsWith('﻿'), isTrue);
      expect(s, contains('"Pérez, Juan";"dijo ""hola"""'));
      expect(s, contains('"línea1\nlínea2"'));
      expect(s.endsWith('\r\n'), isTrue);
      expect(s.split('\r\n').length, 4); // 3 filas + final vacío
    });
    test('no pone comillas innecesarias', () {
      expect(
          buildCsv([
            ['a', 'b']
          ]),
          '﻿a;b\r\n');
    });
  });
}
