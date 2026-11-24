import 'package:mi_evento_core/mi_evento_core.dart';

import 'database.dart';
import 'repos_b.dart';
import 'repository.dart';

enum LodgingStatus { assigned, pending, notNeeded }

enum TeamStatus { assigned, none }

/// Filtros combinables de la lista de asistentes (se suman con «y»). Null = sin filtrar.
class AttendeeFilter {
  const AttendeeFilter(
      {this.sex,
      this.churchId,
      this.lodging,
      this.team,
      this.lodgingId,
      this.teamId,
      this.preregistered});
  final String? sex; // 'M' | 'F'
  final String? churchId;
  final LodgingStatus? lodging;
  final TeamStatus? team;
  final String? lodgingId;
  final String? teamId;

  /// true = solo preinscritos · false = solo confirmados · null = todos.
  final bool? preregistered;

  bool get isEmpty =>
      sex == null &&
      churchId == null &&
      lodging == null &&
      team == null &&
      lodgingId == null &&
      teamId == null &&
      preregistered == null;

  bool matches(AttendeeView v) {
    final a = v.a;
    if (sex != null && a.sex != sex) return false;
    if (churchId != null && a.churchId != churchId) return false;
    if (lodgingId != null && a.lodgingId != lodgingId) return false;
    if (teamId != null && a.teamId != teamId) return false;
    if (preregistered != null && v.isPreregistered != preregistered) {
      return false;
    }
    switch (lodging) {
      case LodgingStatus.assigned:
        if (a.lodgingId == null) return false;
      case LodgingStatus.pending:
        if (!(a.needsLodging && a.lodgingId == null)) return false;
      case LodgingStatus.notNeeded:
        if (a.needsLodging) return false;
      case null:
        break;
    }
    switch (team) {
      case TeamStatus.assigned:
        if (a.teamId == null) return false;
      case TeamStatus.none:
        if (a.teamId != null) return false;
      case null:
        break;
    }
    return true;
  }

  List<AttendeeView> apply(List<AttendeeView> all) => isEmpty
      ? all
      : [
          for (final v in all)
            if (matches(v)) v
        ];
}

/// Búsqueda de hospedajes por nombre, anfitrión, indicaciones o cercanía (sin tildes ni mayúsculas).
/// [accepts] y [onlyFree] filtran por tipo de huésped y por plazas libres.
List<LodgingView> filterLodgings(List<LodgingView> all, String query,
    {LodgingAccepts? accepts, bool onlyFree = false}) {
  final q = normalizeText(query);
  return [
    for (final l in all)
      if ((accepts == null || lodgingAcceptsFromDb(l.row.accepts) == accepts) &&
          (!onlyFree || l.free > 0) &&
          (q.isEmpty ||
              normalizeText(
                      '${l.row.name} ${l.row.hostName ?? ''} ${l.row.directions} ${l.row.distanceNote}')
                  .contains(q)))
        l
  ];
}

/// Equipos cuyo nombre coincide o que tienen algún miembro que coincide con [query].
List<TeamRow> filterTeams(
    List<TeamRow> all, List<AttendeeView> people, String query) {
  final q = normalizeText(query);
  if (q.isEmpty) return all;
  return [
    for (final t in all)
      if (normalizeText(t.name).contains(q) ||
          people.any((v) =>
              v.a.teamId == t.id && normalizeText(v.fullName).contains(q)))
        t
  ];
}
