import 'package:drift/drift.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'database.dart';
import 'repository.dart';
import 'csv_spec.dart';
import 'table_import.dart';

/// Importar en «Confirmar asistencia»: el CSV que exporta la vista (numero, nombre, …, estado) se
/// usa para confirmar la asistencia de quienes aparecen con número de inscripción. Sirve para
/// seguir el control desde Excel: se marcan filas y se importa.
class AttendanceExchange implements TableImporter {
  AttendanceExchange(this.db, this.eventId);
  final AppDatabase db;
  final String eventId;

  @override
  CsvSpec? get spec => null;

  @override
  String get title => 'Importar confirmaciones';
  @override
  String get help =>
      'Columna numero (número de inscripción). Se confirma a quien aparezca como preinscrito; '
      'si el archivo trae la columna estado, solo a quienes digan «Confirmado». '
      'Nadie se desconfirma desde aquí.';

  Future<TableImportSummary> _run(String csvText, {required bool write}) async {
    final repo = Repository(db);
    final rows = readCsvTable(
        parseCsv(csvText),
        const {
          'numero': ['número', 'nº', 'n'],
          'estado': ['asistencia'],
        },
        normalizeText);
    final out = TableImportSummary();
    if (rows.isEmpty) {
      out.warnings.add('El archivo está vacío o no tiene filas.');
      return out;
    }
    if (!rows.first.$2.containsKey('numero')) {
      out.warnings.add('Falta la columna «numero».');
      return out;
    }
    final hasState = rows.first.$2.containsKey('estado');
    final people = await (db.select(db.attendees)
          ..where((a) => a.eventId.equals(eventId) & a.deletedAt.isNull()))
        .get();
    final byNumber = {for (final p in people) p.regNumber: p};
    final toConfirm = <String>[];
    var already = 0, notConfirmed = 0;
    final seen = <int>{};
    for (final (line, r) in rows) {
      final n = int.tryParse(r['numero'] ?? '');
      final p = n == null ? null : byNumber[n];
      if (p == null) {
        out.warnings.add(
            'Fila $line: no hay nadie con el número «${r['numero'] ?? ''}» en este evento.');
        continue;
      }
      if (!seen.add(n!)) continue;
      if (hasState) {
        final s = normalizeText(r['estado'] ?? '');
        if (s != 'confirmado' && s != 'confirmada') {
          notConfirmed++;
          continue;
        }
      }
      if (p.status == 'confirmed') {
        already++;
      } else {
        toConfirm.add(p.id);
      }
    }
    out.work = toConfirm.length;
    out.lines.add('Asistencias a confirmar: ${toConfirm.length}');
    if (already > 0) out.lines.add('Ya estaban confirmadas: $already');
    if (notConfirmed > 0) {
      out.lines.add(
          'Filas que no dicen «Confirmado» (se dejan igual): $notConfirmed');
    }
    if (write && toConfirm.isNotEmpty) await repo.confirmAttendance(toConfirm);
    return out;
  }

  @override
  Future<TableImportSummary> preview(String csvText) =>
      _run(csvText, write: false);
  @override
  Future<TableImportSummary> apply(String csvText,
          {Map<String, int> choices = const {}}) =>
      _run(csvText, write: true);
}
