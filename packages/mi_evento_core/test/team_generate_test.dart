import 'package:mi_evento_core/mi_evento_core.dart';
import 'package:test/test.dart';

TeamStats empty(String id) => TeamStats(id, 'Equipo $id', 0, 0, 0, 0);
TeamPerson person(int i, Sex s, int age) =>
    TeamPerson(id: 'p$i', name: 'P$i', sex: s, age: age);
TeamPiece single(TeamPerson p) => TeamPiece(p.id, p.name, [p]);

List<TeamPiece> crowd(int n, {int seed = 1}) {
  // Edades y sexos «irregulares» pero repetibles.
  var x = seed;
  int next() {
    x = (x * 1103515245 + 12345) & 0x7fffffff;
    return x;
  }

  return [
    for (var i = 0; i < n; i++)
      single(
          person(i, next() % 5 < 3 ? Sex.male : Sex.female, 12 + next() % 50))
  ];
}

Map<String, int> sizes(TeamPlan p) =>
    {for (final t in p.after) t.teamId: t.size};

void main() {
  test('sin equipos: no hay propuesta y se explica', () {
    final r = generateTeams(teams: [], pieces: crowd(5));
    expect(r.assignments, isEmpty);
    expect(r.notes.single, contains('No hay equipos'));
  });

  test('sin gente: nada que repartir', () {
    final r = generateTeams(teams: [empty('A'), empty('B')], pieces: []);
    expect(r.assignments, isEmpty);
    expect(r.isBalanced, isTrue);
  });

  test('40 personas en 4 equipos: tamaños parejos y sin topes superados', () {
    final r = generateTeams(
        teams: [for (final i in 'ABCD'.split('')) empty(i)], pieces: crowd(40));
    expect(r.assignments, hasLength(40));
    expect(sizes(r).values.every((s) => s == 10), isTrue);
    expect(r.after.every((t) => t.sexDiff <= 4), isTrue);
    final ages = r.after.map((t) => t.avgAge);
    expect(
        ages.reduce((a, b) => a > b ? a : b) -
            ages.reduce((a, b) => a < b ? a : b),
        lessThanOrEqualTo(3));
    expect(r.isBalanced, isTrue);
  });

  test('cada persona recibe exactamente un equipo existente', () {
    final r = generateTeams(
        teams: [empty('A'), empty('B'), empty('C')],
        pieces: crowd(31, seed: 7));
    expect(r.assignments.keys.toSet(), {for (var i = 0; i < 31; i++) 'p$i'});
    expect(r.assignments.values.toSet().difference({'A', 'B', 'C'}), isEmpty);
    expect(sizes(r).values.reduce((a, b) => a + b), 31);
  });

  test('un matrimonio o grupo «juntos» nunca se parte', () {
    final couple = TeamPiece('c1', 'Ana y Luis',
        [person(100, Sex.male, 40), person(101, Sex.female, 38)]);
    final group = TeamPiece('g1', 'Jóvenes de Cárdenas',
        [for (var i = 0; i < 5; i++) person(200 + i, Sex.female, 17)]);
    final r = generateTeams(
        teams: [empty('A'), empty('B'), empty('C')],
        pieces: [couple, group, ...crowd(24, seed: 3)]);
    expect(r.assignments['p100'], r.assignments['p101']);
    expect({for (var i = 0; i < 5; i++) r.assignments['p${200 + i}']},
        hasLength(1));
  });

  test('respeta a quienes ya están en un equipo (solo reparte lo nuevo)', () {
    // A ya tiene 6, B tiene 0: lo nuevo debe ir sobre todo a B para igualar.
    final a = TeamStats('A', 'Equipo A', 6, 3, 3, 30);
    final r = generateTeams(teams: [a, empty('B')], pieces: crowd(6, seed: 5));
    expect(r.before.first.size, 6);
    expect(sizes(r)['A']! - sizes(r)['B']!, lessThanOrEqualTo(2));
    expect(r.assignments.values.where((t) => t == 'B').length,
        greaterThanOrEqualTo(4));
  });

  test('una pieza enorme que debe ir junta se avisa', () {
    final giant = TeamPiece('g', 'Iglesia Central',
        [for (var i = 0; i < 12; i++) person(300 + i, Sex.male, 30)]);
    final r = generateTeams(
        teams: [empty('A'), empty('B')], pieces: [giant, ...crowd(6)]);
    expect(r.notes.join(' '), contains('Iglesia Central'));
    expect(r.notes.join(' '), contains('más grande que un equipo promedio'));
  });

  test('determinista: mismos datos, mismo resultado', () {
    final t = [empty('A'), empty('B'), empty('C')];
    final a = generateTeams(teams: t, pieces: crowd(37, seed: 9));
    final b = generateTeams(teams: t, pieces: crowd(37, seed: 9));
    expect(a.assignments, b.assignments);
  });

  test('los topes se pueden endurecer y la mejora local los respeta', () {
    final r = generateTeams(
        teams: [empty('A'), empty('B')],
        pieces: crowd(20, seed: 11),
        limits:
            const BalanceLimits(maxSizeDiff: 0, maxSexDiff: 2, maxAgeDiff: 2));
    expect((r.after[0].size - r.after[1].size).abs(), 0);
  });

  test('1000 personas en 20 equipos: rápido y parejo', () {
    final sw = Stopwatch()..start();
    final r = generateTeams(
        teams: [for (var i = 0; i < 20; i++) empty('T$i')],
        pieces: crowd(1000, seed: 21));
    sw.stop();
    expect(sw.elapsedMilliseconds, lessThan(5000));
    final s = sizes(r).values;
    expect(
        s.reduce((a, b) => a > b ? a : b) - s.reduce((a, b) => a < b ? a : b),
        lessThanOrEqualTo(2));
    expect(r.assignments, hasLength(1000));
  });
}
