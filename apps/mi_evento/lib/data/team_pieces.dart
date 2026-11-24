import 'package:mi_evento_core/mi_evento_core.dart';

import 'database.dart';

/// Lo que se reparte y lo que queda fijo al generar equipos.
class TeamPieces {
  const TeamPieces(this.pieces, this.fixed);
  final List<TeamPiece> pieces;

  /// Quienes ya están en un equipo y no se tocan (vacío si se reorganiza a todos).
  final List<AttendeeRow> fixed;
}

/// Arma las piezas a repartir. Un matrimonio y los grupos «mantener juntos» se unen en una sola
/// pieza (si una persona está en un matrimonio y en un grupo, todo ese conjunto va junto).
/// Con [includeAssigned] falso solo se reparte a quien no tiene equipo.
TeamPieces buildTeamPieces(
  List<AttendeeRow> people, {
  required Map<String, String> spouses,
  required List<Set<String>> together,
  required bool includeAssigned,
}) {
  final movable = [
    for (final p in people)
      if (includeAssigned || p.teamId == null) p
  ];
  final ids = {for (final p in movable) p.id};
  final parent = {for (final p in movable) p.id: p.id};
  String find(String x) {
    while (parent[x] != x) {
      parent[x] = parent[parent[x]!]!;
      x = parent[x]!;
    }
    return x;
  }

  void union(String a, String b) {
    if (!ids.contains(a) || !ids.contains(b)) return;
    final ra = find(a), rb = find(b);
    if (ra != rb) {
      // El menor id manda, para que el resultado sea repetible.
      if (ra.compareTo(rb) < 0) {
        parent[rb] = ra;
      } else {
        parent[ra] = rb;
      }
    }
  }

  spouses.forEach(union);
  for (final s in together) {
    final l = s.where(ids.contains).toList()..sort();
    for (var i = 1; i < l.length; i++) {
      union(l.first, l[i]);
    }
  }

  final byRoot = <String, List<AttendeeRow>>{};
  for (final p in movable) {
    (byRoot[find(p.id)] ??= []).add(p);
  }
  final pieces = <TeamPiece>[
    for (final e in byRoot.entries)
      TeamPiece(
        e.key,
        e.value.length == 1
            ? '${e.value.first.firstName} ${e.value.first.lastName1}'
            : e.value.length == 2 &&
                    spouses[e.value.first.id] == e.value.last.id
                ? 'Matrimonio ${e.value.first.firstName} y ${e.value.last.firstName}'
                : 'Grupo de ${e.value.first.firstName} ${e.value.first.lastName1} (+${e.value.length - 1})',
        [
          for (final a in e.value)
            TeamPerson(
                id: a.id,
                name: '${a.firstName} ${a.lastName1}',
                sex: a.sex == 'M' ? Sex.male : Sex.female,
                age: a.age)
        ],
      )
  ];
  return TeamPieces(pieces, [
    for (final p in people)
      if (!ids.contains(p.id) && p.teamId != null) p
  ]);
}
