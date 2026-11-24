import 'package:drift/drift.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'database.dart';
import 'repos_b.dart';
import 'table_import.dart';

/// Exportar e importar equipos en CSV: una fila por persona (equipo, numero, nombre, sexo, edad,
/// iglesia). Al importar, el equipo de cada persona (por su número de inscripción) se pone según
/// el archivo; si el equipo no existe se crea y «Sin equipo» deja a la persona sin equipo.
class TeamExchange implements TableImporter {
  TeamExchange(this.db, this.eventId);
  final AppDatabase db;
  final String eventId;

  static const headers = [
    'equipo',
    'numero',
    'nombre',
    'sexo',
    'edad',
    'iglesia'
  ];
  static const noTeam = 'sin equipo';

  @override
  String get title => 'Importar equipos';
  @override
  String get help =>
      'Columnas: equipo y numero (el número de inscripción de la persona). Los equipos que no '
      'existan se crean; «Sin equipo» deja a la persona sin equipo. Las demás columnas se ignoran.';

  Future<TableImportSummary> _run(String csvText, {required bool write}) async {
    final teamRepo = TeamRepo(db);
    final rows = readCsvTable(
        parseCsv(csvText),
        const {
          'equipo': ['team'],
          'numero': ['número', 'nº', 'n'],
        },
        normalizeText);
    final out = TableImportSummary();
    if (rows.isEmpty) {
      out.warnings.add('El archivo está vacío o no tiene filas.');
      return out;
    }
    if (!rows.first.$2.containsKey('equipo') ||
        !rows.first.$2.containsKey('numero')) {
      out.warnings
          .add('Faltan columnas: el archivo debe tener «equipo» y «numero».');
      return out;
    }
    final people = await (db.select(db.attendees)
          ..where((a) => a.eventId.equals(eventId) & a.deletedAt.isNull()))
        .get();
    final byNumber = {for (final p in people) p.regNumber: p};
    final teams = await (db.select(db.teams)
          ..where((t) => t.eventId.equals(eventId) & t.deletedAt.isNull()))
        .get();
    final teamId = {for (final t in teams) normalizeText(t.name): t.id};
    final newTeams = <String, String>{}; // normalizado → nombre original
    final plan = <String, List<int>>{}; // equipo normalizado → números
    final seen = <int>{};
    for (final (line, r) in rows) {
      final n = int.tryParse(r['numero'] ?? '');
      final team = (r['equipo'] ?? '').trim();
      if (n == null || !byNumber.containsKey(n)) {
        out.warnings.add(
            'Fila $line: no hay nadie con el número «${r['numero'] ?? ''}» en este evento.');
        continue;
      }
      if (team.isEmpty) {
        out.warnings.add('Fila $line: falta el equipo.');
        continue;
      }
      if (!seen.add(n)) {
        out.warnings
            .add('Fila $line: el número $n está repetido en el archivo.');
        continue;
      }
      final key = normalizeText(team);
      if (key != noTeam && !teamId.containsKey(key)) {
        newTeams.putIfAbsent(key, () => team);
      }
      (plan[key] ??= []).add(n);
    }
    var assigned = 0, cleared = 0;
    for (final e in plan.entries) {
      if (e.key == noTeam) {
        cleared += e.value.length;
      } else {
        assigned += e.value.length;
      }
    }
    out.work = assigned + cleared;
    out.lines
      ..add('Equipos nuevos: ${newTeams.length}')
      ..add('Personas asignadas a un equipo: $assigned')
      ..add('Personas sin equipo: $cleared');
    if (!write || out.work == 0) return out;
    for (final e in newTeams.entries) {
      await teamRepo.createMany(eventId, 1);
      final created = await (db.select(db.teams)
            ..where((t) => t.eventId.equals(eventId) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.sortOrder)])
            ..limit(1))
          .getSingle();
      await teamRepo.update(created.id,
          name: e.value, color: created.color, captainId: null);
      teamId[e.key] = created.id;
    }
    for (final e in plan.entries) {
      await teamRepo.setTeam([for (final n in e.value) byNumber[n]!.id],
          e.key == noTeam ? null : teamId[e.key]);
    }
    return out;
  }

  @override
  Future<TableImportSummary> preview(String csvText) =>
      _run(csvText, write: false);
  @override
  Future<TableImportSummary> apply(String csvText) async =>
      db.transaction(() => _run(csvText, write: true));
}
