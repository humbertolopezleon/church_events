import 'package:mi_evento_core/mi_evento_core.dart';
import 'package:test/test.dart';

TeamStats t(String id, int men, int women, double avg) =>
    TeamStats(id, 'Equipo $id', men + women, men, women, avg);

void main() {
  test('sin equipos: no hay sugerencias', () {
    expect(suggestTeam(Sex.male, 20, []), isEmpty);
  });

  test('el equipo más pequeño gana si todos mantienen el equilibrio', () {
    final r = suggestTeam(
        Sex.male, 30, [t('A', 3, 3, 30), t('B', 2, 2, 30), t('C', 3, 3, 30)]);
    expect(r.first.teamId, 'B');
    expect(r.first.isClean, isTrue);
  });

  test('prefiere equilibrar sexos entre equipos del mismo tamaño', () {
    // Misma cantidad: A tiene más hombres → una mujer debería ir a A para compensar.
    final r = suggestTeam(Sex.female, 30, [t('A', 3, 1, 30), t('B', 2, 2, 30)]);
    expect(r.first.teamId, 'A');
  });

  test('evita el equipo donde se superaría el tope de tamaño', () {
    final r = suggestTeam(Sex.male, 30, [t('A', 3, 3, 30), t('B', 2, 2, 30)],
        limits: const BalanceLimits(maxSizeDiff: 2));
    // B pasa de 4 a 5 (diff 1 con A=6) → limpio; A pasaría a 7 vs 4 → rompe.
    expect(r.first.teamId, 'B');
    final a = r.firstWhere((x) => x.teamId == 'A');
    expect(a.isClean, isFalse);
    expect(a.reason, contains('Rompería'));
  });

  test('un equipo vacío es el más pequeño', () {
    final r = suggestTeam(Sex.male, 25, [t('A', 2, 2, 25), t('B', 0, 0, 0)]);
    expect(r.first.teamId, 'B');
  });

  test('el cónyuge manda: va primero su equipo, aunque no sea el mejor', () {
    final r = suggestTeam(Sex.female, 30, [t('A', 2, 2, 30), t('B', 5, 5, 30)],
        spouseTeamId: 'B');
    expect(r.first.teamId, 'B');
    expect(r.first.reason, contains('cónyuge'));
  });

  test('a igualdad de tamaño y sexo, elige el que más acerca las edades medias',
      () {
    final teams = [t('A', 2, 2, 20), t('B', 2, 2, 40), t('C', 2, 2, 30)];
    final r = suggestTeam(Sex.male, 30, teams);
    // Cada uno queda con 3/2 hombres. Entrar en A (el más joven) sube su media a 22 y reduce la
    // diferencia entre equipos (de 20 a 18 años); en C no la cambia y en B también (entra la persona de 30 entre 20 y 40: 18); C no cambia.
    expect(r.first.teamId, 'A');
    final again = suggestTeam(Sex.male, 30, teams.reversed.toList());
    expect(again.map((x) => x.teamId), r.map((x) => x.teamId));
  });

  test('no cuenta como culpa de la persona un desequilibrio que ya existía',
      () {
    // A y B ya difieren en 5 (tope 2) desde antes; entrar en B no lo empeora de forma nueva.
    final r = suggestTeam(Sex.male, 30, [t('A', 5, 5, 30), t('B', 0, 0, 0)],
        limits: const BalanceLimits(maxSizeDiff: 2));
    expect(r.first.teamId, 'B');
  });

  test('empeorar un tope que ya estaba superado SÍ cuesta (QA-BUG-001)', () {
    // A y B ya superan el tope de sexo y el de edad; un hombre joven en A lo empeora.
    final r = suggestTeam(Sex.male, 20, [t('A', 8, 2, 20), t('B', 2, 8, 50)]);
    expect(r.first.teamId, 'B');
  });

  test('con equipos vacíos, la persona va a uno vacío (QA-BUG-002)', () {
    final r = suggestTeam(
        Sex.female, 22, [t('A', 1, 0, 40), t('B', 0, 0, 0), t('C', 0, 0, 0)]);
    expect(r.first.teamId, isNot('A'));
  });
}
