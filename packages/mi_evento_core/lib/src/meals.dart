import 'attendee_csv.dart' show neutralizeFormula;
import 'text.dart';

const _weekdays = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo'
];

/// Día de la semana en español (`DateTime.weekday`: 1 = lunes).
String weekdayEs(DateTime d) => _weekdays[d.weekday - 1];

/// Nombre sugerido para una sesión: «Almuerzo del sábado». El usuario puede cambiarlo.
String suggestSessionName(String typeName, DateTime date) {
  final t = typeName.trim().isEmpty ? 'Control' : typeName.trim();
  return '$t del ${weekdayEs(date)}';
}

/// Verbo para el aviso de «ya pasó» según el tipo («ya almorzó», «ya desayunó»…).
/// Para tipos que no son comida (materiales, taller) se usa un texto neutro.
String alreadyDoneText(String typeName) {
  final n = normalizeText(typeName);
  if (n.contains('desayuno')) return 'ya desayunó';
  if (n.contains('almuerzo')) return 'ya almorzó';
  if (n.contains('cena')) return 'ya cenó';
  if (n.contains('merienda')) return 'ya merendó';
  return 'ya pasó por esta sesión';
}

/// Texto de la confirmación al marcar («Puede almorzar»).
String canDoText(String typeName) {
  final n = normalizeText(typeName);
  if (n.contains('desayuno')) return 'Puede desayunar';
  if (n.contains('almuerzo')) return 'Puede almorzar';
  if (n.contains('cena')) return 'Puede cenar';
  if (n.contains('merienda')) return 'Puede merendar';
  return 'Puede pasar';
}

/// Una persona con lo necesario para las estadísticas de una sesión.
class MealPerson {
  const MealPerson({required this.id, required this.sexIsMale, this.teamId});
  final String id;
  final bool sexIsMale;
  final String? teamId;
}

class MealStats {
  const MealStats(this.total, this.passed, this.byTeam);
  final int total;
  final int passed;

  /// teamId (o null = sin equipo) → (pasaron, total del equipo)
  final Map<String?, (int, int)> byTeam;

  int get pending => total - passed;
  int get percent => total == 0 ? 0 : (passed * 100 / total).round();
}

/// Estadísticas de una sesión. [passedIds] son los asistentes con registro activo (sin deshacer);
/// los ids que no pertenezcan a [people] (p. ej. alguien eliminado después) no se cuentan.
MealStats computeMealStats(List<MealPerson> people, Set<String> passedIds) {
  final byTeam = <String?, (int, int)>{};
  var passed = 0;
  for (final p in people) {
    final did = passedIds.contains(p.id);
    if (did) passed++;
    final cur = byTeam[p.teamId] ?? (0, 0);
    byTeam[p.teamId] = (cur.$1 + (did ? 1 : 0), cur.$2 + 1);
  }
  return MealStats(people.length, passed, byTeam);
}

/// Cuántas personas pasaron en cada tramo de [bucketMinutes] (por defecto 15), desde el primer
/// hasta el último registro, sin saltarse los tramos vacíos. Las claves son el inicio del tramo.
List<(DateTime, int)> arrivalBuckets(List<DateTime> times,
    {int bucketMinutes = 15}) {
  if (times.isEmpty) return const [];
  DateTime floor(DateTime t) {
    final m = t.minute - t.minute % bucketMinutes;
    return DateTime(t.year, t.month, t.day, t.hour, m);
  }

  final sorted = [...times]..sort();
  final start = floor(sorted.first), end = floor(sorted.last);
  final counts = <DateTime, int>{};
  for (final t in sorted) {
    counts.update(floor(t), (v) => v + 1, ifAbsent: () => 1);
  }
  final out = <(DateTime, int)>[];
  for (var t = start;
      !t.isAfter(end);
      t = t.add(Duration(minutes: bucketMinutes))) {
    out.add((t, counts[t] ?? 0));
  }
  return out;
}

String hhmm(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// CSV en texto: comillas dobles escapadas y saltos de línea CRLF. Se antepone el BOM para que
/// Excel en Windows respete las tildes.
String buildCsv(List<List<String>> rows) {
  String cell(String raw) {
    final c = neutralizeFormula(raw);
    final needs = c.contains(',') ||
        c.contains('"') ||
        c.contains('\n') ||
        c.contains('\r') ||
        c.contains(';');
    final esc = c.replaceAll('"', '""');
    return needs ? '"$esc"' : esc;
  }

  return '﻿${rows.map((r) => r.map(cell).join(';')).join('\r\n')}\r\n';
}
