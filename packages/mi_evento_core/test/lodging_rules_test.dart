import 'package:mi_evento_core/mi_evento_core.dart';
import 'package:test/test.dart';

PersonRef p(String id, Sex s, [String? spouse]) =>
    PersonRef(id: id, name: 'P$id', sex: s, spouseId: spouse);
LodgingSlot slot(LodgingAccepts a, {int cap = 4, int occ = 0}) =>
    LodgingSlot(name: 'Casa', accepts: a, capacity: cap, occupied: occ);

void main() {
  group('capacidad', () {
    test('dentro de la capacidad no avisa', () {
      expect(
          checkLodgingAssignment(
              slot(LodgingAccepts.men), [p('1', Sex.male), p('2', Sex.male)]),
          isEmpty);
    });
    test('al llenar justo no avisa; pasarse sí, con el número', () {
      final exact = checkLodgingAssignment(
          slot(LodgingAccepts.men, cap: 2, occ: 1), [p('1', Sex.male)]);
      expect(exact, isEmpty);
      final over = checkLodgingAssignment(
          slot(LodgingAccepts.men, cap: 2, occ: 1),
          [p('1', Sex.male), p('2', Sex.male)]);
      expect(over.single.kind, WarningKind.capacity);
      expect(over.single.message, contains('3 personas'));
      expect(over.single.message, contains('2 plazas'));
    });
    test('ya sobrecargado: «0 libres», nunca negativos', () {
      final w = checkLodgingAssignment(
          slot(LodgingAccepts.women, cap: 2, occ: 3), [p('1', Sex.female)]);
      expect(w.single.message, contains('0 libres'));
    });
    test('selección vacía: sin avisos', () {
      expect(checkLodgingAssignment(slot(LodgingAccepts.men), []), isEmpty);
    });
  });

  group('compatibilidad', () {
    test('solo hombres: avisa de las mujeres y las nombra', () {
      final w = checkLodgingAssignment(
          slot(LodgingAccepts.men), [p('1', Sex.male), p('2', Sex.female)]);
      expect(w.single.kind, WarningKind.compatibility);
      expect(w.single.message, contains('1 mujer'));
      expect(w.single.message, contains('P2'));
    });
    test('solo mujeres: avisa de los hombres', () {
      final w = checkLodgingAssignment(
          slot(LodgingAccepts.women), [p('1', Sex.male), p('2', Sex.male)]);
      expect(w.single.message, contains('2 hombres'));
    });
    test('matrimonios: la pareja completa pasa; una persona sola avisa', () {
      expect(
          checkLodgingAssignment(slot(LodgingAccepts.couples),
              [p('1', Sex.male, '2'), p('2', Sex.female, '1')]),
          isEmpty);
      final alone = checkLodgingAssignment(
          slot(LodgingAccepts.couples), [p('1', Sex.male, '2')]);
      expect(alone.single.message, contains('sin su cónyuge'));
      final single = checkLodgingAssignment(
          slot(LodgingAccepts.couples), [p('3', Sex.female)]);
      expect(single.single.kind, WarningKind.compatibility);
    });
    test('matrimonios: si el cónyuge ya está en ese hospedaje, no avisa', () {
      final w = checkLodgingAssignment(
          slot(LodgingAccepts.couples, occ: 1), [p('2', Sex.female, '1')],
          alreadyThere: [p('1', Sex.male, '2')]);
      expect(w, isEmpty);
    });
    test('capacidad y compatibilidad pueden avisar a la vez', () {
      final w = checkLodgingAssignment(slot(LodgingAccepts.men, cap: 1),
          [p('1', Sex.female), p('2', Sex.female)]);
      expect(w.map((x) => x.kind),
          containsAll([WarningKind.capacity, WarningKind.compatibility]));
    });
    test('listas largas se abrevian', () {
      final many = [for (var i = 0; i < 8; i++) p('$i', Sex.female)];
      expect(
          checkLodgingAssignment(slot(LodgingAccepts.men, cap: 20), many)
              .single
              .message,
          contains('…'));
    });
  });

  test('conversión a/desde la base de datos', () {
    for (final a in LodgingAccepts.values) {
      expect(lodgingAcceptsFromDb(lodgingAcceptsToDb(a)), a);
    }
    expect(lodgingAcceptsLabel(LodgingAccepts.couples), 'Matrimonios');
  });

  test('distribución por rangos de edad configurables del evento', () {
    Attendee a(int age) => Attendee(
        id: '$age${DateTime.now().microsecond}',
        firstName: 'A',
        lastName1: 'B',
        sex: Sex.male,
        age: age);
    final d = ageDistribution(
        [a(13), a(17), a(18), a(40), a(41), a(70), a(5)], AgeRange.defaults);
    expect(d, {'0–11': 1, '12–17': 2, '18–25': 1, '26–40': 1, '41+': 2});
    expect(
        ageDistribution([a(20)],
            const [AgeRange('Jóvenes', 15, 30), AgeRange('Adultos', 31)]),
        {'Jóvenes': 1, 'Adultos': 0});
    expect(ageDistribution([], AgeRange.defaults).values.every((v) => v == 0),
        isTrue);
  });
}
