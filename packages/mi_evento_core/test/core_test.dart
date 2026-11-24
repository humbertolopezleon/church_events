import 'dart:math';
import 'package:mi_evento_core/mi_evento_core.dart';
import 'package:test/test.dart';

Attendee a(String id, Sex s, int age,
        [String? team, String n = 'Juan', String l = 'Pérez']) =>
    Attendee(
        id: id, firstName: n, lastName1: l, sex: s, age: age, teamId: team);

void main() {
  group('UUID v7', () {
    test('formato válido, versión 7 y único', () {
      final ids = {for (var i = 0; i < 2000; i++) newUuidV7()};
      expect(ids.length, 2000);
      for (final id in ids.take(50)) {
        expect(isUuid(id), isTrue);
        expect(id[14], '7');
      }
    });
    test('ordenable por tiempo', () {
      final r = Random(1);
      final x = newUuidV7(now: DateTime.utc(2026, 1, 1), random: r);
      final y = newUuidV7(now: DateTime.utc(2026, 1, 2), random: r);
      expect(x.compareTo(y) < 0, isTrue);
    });
  });

  group('normalizeText', () {
    test('quita tildes, signos y espacios', () {
      expect(normalizeText('  Pérez-Gómez,  Ñandú '), 'perez gomez nandu');
      expect(normalizeText('Eben-Ezer'), 'eben ezer');
    });
  });

  group('AgeRange', () {
    test('asigna rango y por defecto cubre desde 0 años', () {
      expect(AgeRange.of(17, AgeRange.defaults)!.label, '12–17');
      expect(AgeRange.of(18, AgeRange.defaults)!.label, '18–25');
      expect(AgeRange.of(70, AgeRange.defaults)!.label, '41+');
      expect(AgeRange.of(5, AgeRange.defaults)!.label, '0–11');
    });
    test('valida solapes e inversiones', () {
      expect(AgeRange.validate(AgeRange.defaults), isEmpty);
      expect(
          AgeRange.validate(
              const [AgeRange('a', 10, 20), AgeRange('b', 18, 30)]),
          isNotEmpty);
      expect(AgeRange.validate(const [AgeRange('a', 30, 20)]), isNotEmpty);
      expect(AgeRange.validate(const [AgeRange('a', 10), AgeRange('b', 30)]),
          isNotEmpty);
    });
  });

  group('duplicados', () {
    final ex = [
      a('1', Sex.male, 34),
      a('2', Sex.female, 20, null, 'María', 'Leyva')
    ];
    test('coincide ignorando tildes y mayúsculas', () {
      expect(findDuplicates(ex, firstName: 'JUAN', lastName1: 'perez', age: 34),
          hasLength(1));
    });
    test('edad distinta no es duplicado; sin edad sí avisa', () {
      expect(findDuplicates(ex, firstName: 'Juan', lastName1: 'Pérez', age: 17),
          isEmpty);
      expect(findDuplicates(ex, firstName: 'Juan', lastName1: 'Pérez'),
          hasLength(1));
    });
    test('campos vacíos no avisan', () {
      expect(findDuplicates(ex, firstName: '', lastName1: 'Pérez'), isEmpty);
    });
  });

  group('balance (estrategia C)', () {
    List<TeamStats> teams(List<List<Attendee>> ms) =>
        [for (var i = 0; i < ms.length; i++) TeamStats.of('t$i', 'E$i', ms[i])];
    List<Attendee> grp(int men, int women, int age) => [
          for (var i = 0; i < men; i++) a('m$i$age$women', Sex.male, age),
          for (var i = 0; i < women; i++) a('w$i$age$men', Sex.female, age),
        ];

    test('equipos parejos: sin incidencias', () {
      expect(evaluateBalance(teams([grp(5, 5, 25), grp(5, 5, 26)])), isEmpty);
    });
    test('tamaño: diferencia 4 con tope 2', () {
      final r = evaluateBalance(teams([grp(8, 8, 25), grp(6, 6, 25)]));
      expect(
          r.where((i) => i.criterion == BalanceCriterion.size), hasLength(1));
      expect(r.first.message, contains('diferencia 4, máximo 2'));
    });
    test('sexo: 10H·2M con tope 4', () {
      final r = evaluateBalance(teams([grp(10, 2, 25), grp(6, 6, 25)]));
      final s = r.where((i) => i.criterion == BalanceCriterion.sex).single;
      expect(s.teamIds, ['t0']);
      expect(s.actual, 8);
    });
    test('edad media: 6 años con tope 3', () {
      final r = evaluateBalance(teams([grp(5, 5, 30), grp(5, 5, 24)]));
      expect(r.single.criterion, BalanceCriterion.age);
    });
    test('topes personalizados y límite exacto no avisa', () {
      expect(evaluateBalance(teams([grp(5, 5, 30), grp(5, 5, 27)])), isEmpty);
      expect(
          evaluateBalance(teams([grp(5, 5, 30), grp(5, 5, 27)]),
              const BalanceLimits(maxAgeDiff: 2)),
          isNotEmpty);
    });
    test('equipo vacío no distorsiona la edad media', () {
      expect(
          evaluateBalance(teams([grp(1, 1, 30), <Attendee>[]]),
              const BalanceLimits(maxSizeDiff: 5)),
          isEmpty);
    });
    test('statsAfterMove no modifica y calcula el destino', () {
      final all = [
        for (var i = 0; i < 4; i++) a('x$i', Sex.female, 20, 't1'),
        a('y', Sex.male, 20, 't2'),
      ];
      final r = statsAfterMove({'t1': 'Azul', 't2': 'Rojo'}, all, 'x0', 't2');
      expect(r.firstWhere((t) => t.teamId == 't1').size, 3);
      expect(r.firstWhere((t) => t.teamId == 't2').size, 2);
      expect(all.first.teamId, 't1');
    });
    test('rendimiento con 1500 asistentes', () {
      final all = [
        for (var i = 0; i < 1500; i++)
          a('p$i', i.isEven ? Sex.male : Sex.female, 12 + i % 45, 't${i % 6}')
      ];
      final names = {for (var i = 0; i < 6; i++) 't$i': 'E$i'};
      final sw = Stopwatch()..start();
      for (var i = 0; i < 50; i++) {
        evaluateBalance(statsAfterMove(names, all, 'p$i', 't5'));
      }
      expect(sw.elapsedMilliseconds, lessThan(2000));
    });
  });
}
