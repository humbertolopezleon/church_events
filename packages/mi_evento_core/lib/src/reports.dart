import 'age_range.dart';
import 'text.dart';

/// Datos mínimos de una persona para los reportes (sin datos de contacto).
class ReportPerson {
  const ReportPerson({
    required this.isMale,
    required this.age,
    this.church,
    this.team,
    this.lodging,
    this.needsLodging = false,
  });
  final bool isMale;
  final int age;
  final String? church;
  final String? team;
  final String? lodging;
  final bool needsLodging;
}

class ReportRow {
  const ReportRow(this.label, this.count);
  final String label;
  final int count;
}

/// Una tabla de totales («Por sexo», «Por iglesia»…). La suma de [rows] es siempre el total
/// de personas, así los reportes cuadran entre sí.
class ReportSection {
  const ReportSection(this.title, this.rows);
  final String title;
  final List<ReportRow> rows;
  int get total => rows.fold(0, (s, r) => s + r.count);
}

List<ReportRow> _count(Iterable<String> keys, {bool byName = false}) {
  final m = <String, int>{};
  for (final k in keys) {
    m.update(k, (v) => v + 1, ifAbsent: () => 1);
  }
  final rows = [for (final e in m.entries) ReportRow(e.key, e.value)];
  rows.sort((a, b) {
    final c = byName ? 0 : b.count.compareTo(a.count);
    return c != 0
        ? c
        : normalizeText(a.label).compareTo(normalizeText(b.label));
  });
  return rows;
}

/// Totales por sexo, rango de edad (los del evento), iglesia, hospedaje y equipo.
/// Las categorías vacías especiales («Sin iglesia», «Sin equipo»…) van al final.
List<ReportSection> buildReportSections(
    List<ReportPerson> people, List<AgeRange> ranges) {
  final sex = [
    ReportRow('Mujeres', people.where((p) => !p.isMale).length),
    ReportRow('Hombres', people.where((p) => p.isMale).length),
  ];

  final age = <ReportRow>[
    for (final r in ranges)
      ReportRow(
          r.label, people.where((p) => AgeRange.of(p.age, ranges) == r).length),
  ];
  final outside =
      people.where((p) => AgeRange.of(p.age, ranges) == null).length;
  if (outside > 0) age.add(ReportRow('Sin rango', outside));

  final churches = _count(people
      .where((p) => p.church != null && p.church!.isNotEmpty)
      .map((p) => p.church!));
  final noChurch =
      people.where((p) => p.church == null || p.church!.isEmpty).length;
  if (noChurch > 0) churches.add(ReportRow('Sin iglesia', noChurch));

  final lodgings = _count(
      people.where((p) => p.lodging != null).map((p) => p.lodging!),
      byName: true);
  final pending =
      people.where((p) => p.lodging == null && p.needsLodging).length;
  final none = people.where((p) => p.lodging == null && !p.needsLodging).length;
  if (pending > 0) lodgings.add(ReportRow('Necesitan y sin asignar', pending));
  if (none > 0) lodgings.add(ReportRow('No necesitan hospedaje', none));

  final teams = _count(people.where((p) => p.team != null).map((p) => p.team!),
      byName: true);
  final noTeam = people.where((p) => p.team == null).length;
  if (noTeam > 0) teams.add(ReportRow('Sin equipo', noTeam));

  return [
    ReportSection('Por sexo', sex),
    ReportSection('Por rango de edad', age),
    ReportSection('Por iglesia', churches),
    ReportSection('Por hospedaje', lodgings),
    ReportSection('Por equipo', teams),
  ];
}
