import 'age_range.dart';
import 'models.dart';

/// Topes de la estrategia C (diferencias máximas entre equipos). Editables por evento.
class BalanceLimits {
  const BalanceLimits(
      {this.maxSizeDiff = 2, this.maxSexDiff = 4, this.maxAgeDiff = 3});
  final int maxSizeDiff;
  final int maxSexDiff;
  final double maxAgeDiff;
}

class TeamStats {
  const TeamStats(
      this.teamId, this.teamName, this.size, this.men, this.women, this.avgAge);
  final String teamId;
  final String teamName;
  final int size;
  final int men;
  final int women;

  /// 0 si el equipo está vacío.
  final double avgAge;
  int get sexDiff => (men - women).abs();

  factory TeamStats.of(String id, String name, Iterable<Attendee> members) {
    final l = members.toList();
    final m = l.where((a) => a.sex == Sex.male).length;
    final avg =
        l.isEmpty ? 0.0 : l.fold<int>(0, (s, a) => s + a.age) / l.length;
    return TeamStats(id, name, l.length, m, l.length - m, avg);
  }
}

enum BalanceCriterion { size, sex, age }

/// Un tope superado: qué criterio, qué equipos, cuánto y cuál era el máximo.
class BalanceIssue {
  const BalanceIssue(
      this.criterion, this.teamIds, this.actual, this.max, this.message);
  final BalanceCriterion criterion;
  final List<String> teamIds;
  final double actual;
  final double max;
  final String message;
}

String _n(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

/// Evalúa la estrategia C sobre todos los equipos. Devuelve una incidencia por tope superado.
/// Nunca bloquea: la UI muestra el aviso y ofrece «Continuar».
List<BalanceIssue> evaluateBalance(List<TeamStats> teams,
    [BalanceLimits limits = const BalanceLimits()]) {
  final out = <BalanceIssue>[];
  if (teams.length < 2) return out;

  final big = teams.reduce((a, b) => a.size >= b.size ? a : b);
  final small = teams.reduce((a, b) => a.size <= b.size ? a : b);
  final sizeDiff = big.size - small.size;
  if (sizeDiff > limits.maxSizeDiff) {
    out.add(BalanceIssue(
        BalanceCriterion.size,
        [big.teamId, small.teamId],
        sizeDiff.toDouble(),
        limits.maxSizeDiff.toDouble(),
        'Tamaño: ${big.teamName} ${big.size} y ${small.teamName} ${small.size} (diferencia $sizeDiff, máximo ${limits.maxSizeDiff}).'));
  }

  for (final t in teams) {
    if (t.sexDiff > limits.maxSexDiff) {
      out.add(BalanceIssue(
          BalanceCriterion.sex,
          [t.teamId],
          t.sexDiff.toDouble(),
          limits.maxSexDiff.toDouble(),
          'Sexo: ${t.teamName} tiene ${t.men} hombres y ${t.women} mujeres (diferencia ${t.sexDiff}, máximo ${limits.maxSexDiff}).'));
    }
  }

  final withPeople = teams.where((t) => t.size > 0).toList();
  if (withPeople.length >= 2) {
    final old = withPeople.reduce((a, b) => a.avgAge >= b.avgAge ? a : b);
    final young = withPeople.reduce((a, b) => a.avgAge <= b.avgAge ? a : b);
    final d = old.avgAge - young.avgAge;
    if (d > limits.maxAgeDiff) {
      out.add(BalanceIssue(
          BalanceCriterion.age,
          [old.teamId, young.teamId],
          d,
          limits.maxAgeDiff,
          'Edad media: ${old.teamName} ${_n(double.parse(old.avgAge.toStringAsFixed(1)))} y ${young.teamName} ${_n(double.parse(young.avgAge.toStringAsFixed(1)))} años (diferencia ${_n(double.parse(d.toStringAsFixed(1)))}, máximo ${_n(limits.maxAgeDiff)}).'));
    }
  }
  return out;
}

/// Las partes del costo de un reparto (menor es mejor en todas).
class BalanceParts {
  const BalanceParts(this.hardOver, this.ageOver, this.sizeDiff, this.sexTotal,
      this.ageSpread);

  /// Cuánto se exceden los topes de tamaño y de hombres–mujeres (suma de excesos).
  final int hardOver;

  /// Cuánto se excede el tope de edad media (años).
  final double ageOver;
  final int sizeDiff;
  final int sexTotal;
  final double ageSpread;

  double get total =>
      hardOver * 1000 +
      ageOver * 100 +
      sizeDiff * 10 +
      sexTotal * 1.0 +
      ageSpread;

  /// Orden estricto: topes (tamaño y sexo, luego edad), y después igualar tamaño, sexo y edad.
  int compareTo(BalanceParts o) {
    for (final c in [
      hardOver.compareTo(o.hardOver),
      ageOver.compareTo(o.ageOver),
      sizeDiff.compareTo(o.sizeDiff),
      sexTotal.compareTo(o.sexTotal),
      ageSpread.compareTo(o.ageSpread),
    ]) {
      if (c != 0) return c;
    }
    return 0;
  }
}

/// Mide un reparto según la estrategia C: los topes superados pesan mucho (con la magnitud del
/// exceso, aunque el tope ya estuviera superado); luego se busca igualar tamaño, sexo y edad.
/// La usan «Generar equipos» y el equipo automático al inscribir.
///
/// Los argumentos son listas paralelas, una posición por equipo: tamaño, hombres, mujeres y
/// SUMA de edades (no la media).
BalanceParts balanceParts(List<int> size, List<int> men, List<int> women,
    List<double> ageSum, BalanceLimits l) {
  final n = size.length;
  if (n == 0) return const BalanceParts(0, 0, 0, 0, 0);
  var minS = size[0], maxS = size[0];
  var sexOver = 0, sexTotal = 0;
  double minA = double.infinity, maxA = -double.infinity;
  for (var i = 0; i < n; i++) {
    if (size[i] < minS) minS = size[i];
    if (size[i] > maxS) maxS = size[i];
    final d = (men[i] - women[i]).abs();
    sexTotal += d;
    if (d > l.maxSexDiff) sexOver += d - l.maxSexDiff;
    if (size[i] > 0) {
      final a = ageSum[i] / size[i];
      if (a < minA) minA = a;
      if (a > maxA) maxA = a;
    }
  }
  final sizeDiff = maxS - minS;
  final ageSpread = maxA.isFinite ? maxA - minA : 0.0;
  final sizeOver = sizeDiff > l.maxSizeDiff ? sizeDiff - l.maxSizeDiff : 0;
  final ageOver = ageSpread > l.maxAgeDiff ? ageSpread - l.maxAgeDiff : 0.0;
  return BalanceParts(
      sizeOver + sexOver, ageOver, sizeDiff, sexTotal, ageSpread);
}

/// Costo total de un reparto (ver [balanceParts]); menor es mejor.
double balanceCost(List<int> size, List<int> men, List<int> women,
        List<double> ageSum, BalanceLimits l) =>
    balanceParts(size, men, women, ageSum, l).total;

/// Estadísticas por equipo tras mover [attendeeId] a [toTeamId] (sin modificar nada).
/// Solo recalcula los dos equipos afectados al comparar, pero devuelve todos para evaluar.
List<TeamStats> statsAfterMove(Map<String, String> teamNames,
    List<Attendee> all, String attendeeId, String toTeamId) {
  return teamNames.entries.map((e) {
    final members =
        all.where((a) => a.id != attendeeId && a.teamId == e.key).toList();
    if (e.key == toTeamId) {
      members.add(all.firstWhere((a) => a.id == attendeeId));
    }
    return TeamStats.of(e.key, e.value, members);
  }).toList();
}

/// Distribución de edades de un equipo según los rangos configurados del evento.
/// Quien no cae en ningún rango se cuenta bajo «Sin rango».
Map<String, int> ageDistribution(
    Iterable<Attendee> members, List<AgeRange> ranges) {
  final out = {for (final r in ranges) r.label: 0};
  for (final m in members) {
    final r = AgeRange.of(m.age, ranges);
    final k = r?.label ?? 'Sin rango';
    out[k] = (out[k] ?? 0) + 1;
  }
  out.removeWhere((k, v) => k == 'Sin rango' && v == 0);
  return out;
}

/// Una sugerencia de equipo para una persona que se inscribe (nunca se aplica sola).
class TeamSuggestion {
  const TeamSuggestion(this.teamId, this.teamName, this.issues, this.reason);
  final String teamId;
  final String teamName;

  /// Topes de la estrategia C que se superarían si la persona entra ahí.
  final List<BalanceIssue> issues;
  final String reason;
  bool get isClean => issues.isEmpty;
}

/// Ordena los equipos de mejor a peor para una persona de [sex] y [age] (estrategia C).
///
/// [teams] son las estadísticas ACTUALES (sin contar a esa persona). Orden: primero el equipo
/// de su cónyuge ([spouseTeamId]) si existe; luego el equipo que deja el menor [balanceCost]
/// (el mismo que «Generar equipos»: pesa cuánto se excede cada tope, aunque ya estuviera superado);
/// y por nombre.
List<TeamSuggestion> suggestTeam(
  Sex sex,
  int age,
  List<TeamStats> teams, {
  BalanceLimits limits = const BalanceLimits(),
  String? spouseTeamId,
}) {
  if (teams.isEmpty) return const [];
  TeamStats after(TeamStats t) {
    final men = t.men + (sex == Sex.male ? 1 : 0);
    final women = t.women + (sex == Sex.female ? 1 : 0);
    final size = t.size + 1;
    return TeamStats(t.teamId, t.teamName, size, men, women,
        (t.avgAge * t.size + age) / size);
  }

  List<int> sizes(List<TeamStats> l) => [for (final t in l) t.size];
  List<int> menOf(List<TeamStats> l) => [for (final t in l) t.men];
  List<int> womenOf(List<TeamStats> l) => [for (final t in l) t.women];
  List<double> ageSums(List<TeamStats> l) =>
      [for (final t in l) t.avgAge * t.size];
  BalanceParts partsOf(List<TeamStats> l) =>
      balanceParts(sizes(l), menOf(l), womenOf(l), ageSums(l), limits);

  final beforeIssues = {
    for (final i in evaluateBalance(teams, limits))
      '${i.criterion.name}:${i.teamIds.join(',')}': i.actual
  };
  final hasEmpty = teams.any((t) => t.size == 0);
  final scored = <(TeamStats, List<BalanceIssue>, BalanceParts)>[];
  bool notEmptyFirst(TeamStats t) =>
      hasEmpty && t.size > 0 && t.teamId != spouseTeamId;
  // Mientras haya equipos vacíos, los equipos se llenan de uno en uno: la media de edad de
  // 1 o 2 personas no dice nada y no debe empujar a juntar a la gente (QA-BUG-002).
  for (final t in teams) {
    final next = [for (final o in teams) o.teamId == t.teamId ? after(t) : o];
    // Topes que ESTE ingreso causa o empeora respecto a hoy (para el aviso en pantalla).
    final issues = evaluateBalance(next, limits).where((i) {
      final prev = beforeIssues['${i.criterion.name}:${i.teamIds.join(',')}'];
      return prev == null || i.actual > prev + 1e-9;
    }).toList();
    scored.add((t, issues, partsOf(next)));
  }

  scored.sort((a, b) {
    final aSp = a.$1.teamId == spouseTeamId ? 0 : 1;
    final bSp = b.$1.teamId == spouseTeamId ? 0 : 1;
    if (aSp != bSp) return aSp - bSp;
    final aE = notEmptyFirst(a.$1) ? 1 : 0, bE = notEmptyFirst(b.$1) ? 1 : 0;
    if (aE != bE) return aE - bE;
    final c = a.$3.compareTo(b.$3);
    if (c != 0) return c;
    return a.$1.teamName.compareTo(b.$1.teamName);
  });

  return [
    for (final e in scored)
      TeamSuggestion(
        e.$1.teamId,
        e.$1.teamName,
        e.$2,
        e.$1.teamId == spouseTeamId
            ? 'Su cónyuge ya está en este equipo.'
            : e.$2.isEmpty
                ? 'Mantiene el equilibrio (${e.$1.size} → ${e.$1.size + 1} personas).'
                : 'Rompería ${e.$2.length == 1 ? 'un tope' : '${e.$2.length} topes'} de equilibrio.',
      )
  ];
}
