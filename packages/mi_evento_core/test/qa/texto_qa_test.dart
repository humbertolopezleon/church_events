// QA · Núcleo: normalización de nombres (búsqueda y duplicados) y rangos de edad.
import 'package:mi_evento_core/mi_evento_core.dart';
import 'package:test/test.dart';

void main() {
  group('texto y duplicados', () {
    test('QA-TXT-001 · tildes, diéresis y ñ se igualan, también en mayúsculas',
        () {
      expect(normalizeText('ÁÉÍÓÚ Ñandú ÜÖ'), 'aeiou nandu uo');
      expect(normalizeText('María José'), 'maria jose');
    });

    test(
        'QA-TXT-002 · espacios, tabuladores y saltos de línea se colapsan; vacío y solo espacios dan vacío',
        () {
      expect(normalizeText('  Juan \t\n  Pérez  '), 'juan perez');
      expect(normalizeText('   '), '');
      expect(normalizeText(''), '');
    });

    test(
        'QA-TXT-003 · el apóstrofe no cuenta: «O\'Farrill» y «OFarrill» son lo mismo para duplicados',
        () {
      expect(dedupeKey('Ñuri', "O'Farrill"), dedupeKey('nuri', 'OFarrill'));
    });

    test(
        'QA-TXT-004 · José Núñez, JOSE NUNEZ y jose núñez dan la misma clave de duplicado',
        () {
      final k = dedupeKey('José', 'Núñez');
      expect(dedupeKey('JOSE', 'NUNEZ'), k);
      expect(dedupeKey(' jose ', ' núñez '), k);
      expect(dedupeKey('José', 'Núñez Peña'),
          isNot(k)); // otro apellido compuesto: no es el mismo
    });

    test(
        'QA-TXT-005 · quien escribe «OFarrill» sin apóstrofe encuentra «O\'Farrill»',
        () {
      expect(normalizeText("O'Farrill").contains(normalizeText('OFarrill')),
          isTrue);
    });

    test(
        'QA-TXT-006 · letras fuera de la tabla de tildes (ã, ç, ø, ß, ł) se tratan como su letra base',
        () {
      expect(normalizeText('João Gonçalves'), 'joao goncalves');
      expect(dedupeKey('João', 'Silva'), dedupeKey('Joao', 'Silva'));
    });
  });

  group('identificadores y rangos de edad', () {
    test(
        'QA-TXT-010 · 1000 identificadores nuevos son UUID v7 válidos y no se repiten',
        () {
      final ids = {for (var i = 0; i < 1000; i++) newUuidV7()};
      expect(ids.length, 1000);
      expect(ids.every(isUuid), isTrue);
    });

    test(
        'QA-TXT-011 · los rangos de edad por defecto cubren desde 0 años (incluye «0–11»): nadie queda como «Sin rango»',
        () {
      for (var e = 0; e <= 110; e++) {
        expect(AgeRange.of(e, AgeRange.defaults), isNotNull, reason: 'edad $e');
      }
      expect(AgeRange.of(11, AgeRange.defaults)!.label, '0–11');
      expect(AgeRange.of(1, AgeRange.defaults)!.label, '0–11');
    });

    test(
        'QA-TXT-012 · rangos solapados o invertidos se rechazan con mensaje en español',
        () {
      expect(AgeRange.validate(AgeRange.defaults), isEmpty);
      final malos = AgeRange.validate(const [
        AgeRange('A', 10, 20),
        AgeRange('B', 15, 30),
        AgeRange('C', 40, 35)
      ]);
      expect(malos.join(' '),
          allOf(contains('se solapan'), contains('máximo menor')));
    });
  });
}
