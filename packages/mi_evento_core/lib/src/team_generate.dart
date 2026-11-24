import 'balance.dart';
import 'models.dart';

/// Persona a repartir en equipos.
class TeamPerson {
  const TeamPerson(
      {required this.id,
      required this.name,
      required this.sex,
      required this.age});
  final String id;
  final String name;
  final Sex sex;
  final int age;
}

/// Una «pieza» se reparte entera: una persona suelta, un matrimonio o un grupo que debe ir junto.
class TeamPiece {
  const TeamPiece(this.id, this.label, this.members);
  final String id;
  final String label;
  final List<TeamPerson> members;
  int get size => members.length;
}

/// Resultado de generar equipos. Es una PROPUESTA: no cambia nada hasta que el usuario acepta.
class TeamPlan {
  const TeamPlan({
    required this.assignments,
    required this.before,
    required this.after,
    required this.issues,
    required this.notes,
  });

  /// persona → equipo.
  final Map<String, String> assignments;

  /// Estadísticas de cada equipo antes (solo quienes ya estaban) y después de aplicar la propuesta.
  final List<TeamStats> before;
  final List<TeamStats> after;

  /// Topes de la estrategia C que aun así quedan superados.
  final List<BalanceIssue> issues;
  final List<String> notes;
  bool get isBalanced => issues.isEmpty;
}

class _State {
  _State(List<TeamStats> base)
      : size = [for (final t in base) t.size],
        men = [for (final t in base) t.men],
        women = [for (final t in base) t.women],
        ageSum = [for (final t in base) t.avgAge * t.size];
  final List<int> size, men, women;
  final List<double> ageSum;
  int get n => size.length;

  void add(TeamPiece p, int t, int sign) {
    for (final m in p.members) {
      size[t] += sign;
      if (m.sex == Sex.male) {
        men[t] += sign;
      } else {
        women[t] += sign;
      }
      ageSum[t] += sign * m.age;
    }
  }

  /// Costo de la estrategia C (ver [balanceCost]).
  double cost(BalanceLimits l) => balanceCost(size, men, women, ageSum, l);
}

/// Genera una propuesta de equipos (estrategia C): reparto voraz por piezas de mayor a menor,
/// cada una al equipo que deja el mejor balance, y luego mejora local por traslados e
/// intercambios. Determinista: mismos datos → mismo resultado.
///
/// [teams] son las estadísticas de quienes YA están en cada equipo y no se mueven (puede estar
/// vacío de gente). Las [pieces] son lo que se reparte; ninguna pieza se parte.
TeamPlan generateTeams({
  required List<TeamStats> teams,
  required List<TeamPiece> pieces,
  BalanceLimits limits = const BalanceLimits(),
  int maxPasses = 8,
}) {
  final notes = <String>[];
  if (teams.isEmpty) {
    return const TeamPlan(
        assignments: {},
        before: [],
        after: [],
        issues: [],
        notes: ['No hay equipos: crea al menos uno.']);
  }
  final st = _State(teams);
  final order = [...pieces]..sort((a, b) {
      final d = b.size - a.size;
      return d != 0 ? d : a.id.compareTo(b.id);
    });
  final where = <String, int>{}; // pieza → índice de equipo

  // 1) Reparto voraz.
  for (final p in order) {
    var best = 0;
    var bestCost = double.infinity;
    for (var t = 0; t < st.n; t++) {
      st.add(p, t, 1);
      final c = st.cost(limits);
      st.add(p, t, -1);
      if (c < bestCost - 1e-9) {
        bestCost = c;
        best = t;
      }
    }
    st.add(p, best, 1);
    where[p.id] = best;
  }

  // 2) Mejora local: traslados de una pieza y luego intercambios entre piezas.
  var budget =
      400000; // evaluaciones máximas (acota el tiempo con 1000+ personas)
  for (var pass = 0; pass < maxPasses && budget > 0; pass++) {
    var improved = false;
    var cur = st.cost(limits);
    for (final p in order) {
      final a = where[p.id]!;
      var best = a;
      var bestCost = cur;
      st.add(p, a, -1);
      for (var t = 0; t < st.n; t++) {
        if (t == a) continue;
        st.add(p, t, 1);
        final c = st.cost(limits);
        st.add(p, t, -1);
        budget--;
        if (c < bestCost - 1e-9) {
          bestCost = c;
          best = t;
        }
      }
      st.add(p, best, 1);
      if (best != a) {
        where[p.id] = best;
        cur = bestCost;
        improved = true;
      }
    }
    for (var i = 0; i < order.length && budget > 0; i++) {
      for (var j = i + 1; j < order.length && budget > 0; j++) {
        final p = order[i], q = order[j];
        final a = where[p.id]!, b = where[q.id]!;
        if (a == b) continue;
        st
          ..add(p, a, -1)
          ..add(q, b, -1)
          ..add(p, b, 1)
          ..add(q, a, 1);
        final c = st.cost(limits);
        budget--;
        if (c < cur - 1e-9) {
          cur = c;
          where[p.id] = b;
          where[q.id] = a;
          improved = true;
        } else {
          st
            ..add(p, b, -1)
            ..add(q, a, -1)
            ..add(p, a, 1)
            ..add(q, b, 1);
        }
      }
    }
    if (!improved) break;
  }

  // 3) Resultado.
  final total = teams.fold<int>(0, (s, t) => s + t.size) +
      pieces.fold<int>(0, (s, p) => s + p.size);
  final avgTeam = (total / teams.length).ceil();
  for (final p in pieces.where((p) => p.size > avgTeam && p.size > 1)) {
    notes.add(
        '«${p.label}» tiene ${p.size} personas y debe ir junto: es más grande que un equipo promedio ($avgTeam).');
  }
  final assignments = <String, String>{};
  for (final p in pieces) {
    for (final m in p.members) {
      assignments[m.id] = teams[where[p.id]!].teamId;
    }
  }
  final after = <TeamStats>[
    for (var i = 0; i < teams.length; i++)
      TeamStats(teams[i].teamId, teams[i].teamName, st.size[i], st.men[i],
          st.women[i], st.size[i] == 0 ? 0 : st.ageSum[i] / st.size[i])
  ];
  return TeamPlan(
    assignments: assignments,
    before: teams,
    after: after,
    issues: evaluateBalance(after, limits),
    notes: notes,
  );
}
