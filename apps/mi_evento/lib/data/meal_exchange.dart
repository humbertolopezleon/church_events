import 'package:drift/drift.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'csv_spec.dart';
import 'database.dart';
import 'meal_repo.dart';
import 'table_import.dart';

String _two(int n) => n.toString().padLeft(2, '0');
String _day(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';
String _dayTime(DateTime d) =>
    '${_day(d)} ${_two(d.hour)}:${_two(d.minute)}:${_two(d.second)}';

/// Día escrito como `2026-11-28` o `28/11/2026` (o `28-11-2026`). `null` si no se entiende.
DateTime? parseDay(String raw) {
  final t = raw.trim();
  final iso = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(t);
  final dmy = RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$').firstMatch(t);
  int y, m, d;
  if (iso != null) {
    y = int.parse(iso.group(1)!);
    m = int.parse(iso.group(2)!);
    d = int.parse(iso.group(3)!);
  } else if (dmy != null) {
    d = int.parse(dmy.group(1)!);
    m = int.parse(dmy.group(2)!);
    y = int.parse(dmy.group(3)!);
  } else {
    return null;
  }
  final out = DateTime(y, m, d);
  return out.year == y && out.month == m && out.day == d ? out : null;
}

/// Día y hora escritos como `2026-11-28 13:05` o `13:05:09` (o solo el día). `null` si no se entiende.
DateTime? parseDayTime(String raw) {
  final t = raw.trim();
  final m =
      RegExp(r'^(.*?)(?:[ T](\d{1,2}):(\d{2})(?::(\d{2}))?)?$').firstMatch(t);
  if (m == null) return null;
  final day = parseDay(m.group(1)!);
  if (day == null) return null;
  final h = int.tryParse(m.group(2) ?? '0') ?? 0;
  final min = int.tryParse(m.group(3) ?? '0') ?? 0;
  final sec = int.tryParse(m.group(4) ?? '0') ?? 0;
  if (h > 23 || min > 59 || sec > 59) return null;
  return DateTime(day.year, day.month, day.day, h, min, sec);
}

String _fullName(AttendeeRow a) => [a.firstName, a.lastName1, a.lastName2]
    .where((e) => e.trim().isNotEmpty)
    .join(' ');

/// Exportar e importar las SESIONES de control de comidas (tipo, nombre y fecha), para reutilizar
/// la misma programación en otro evento. No lleva quién pasó (para eso está [MealRecordsExchange]).
/// Una sesión cuyo nombre ya existe se omite; una fecha fuera del evento se importa sin fecha.
class MealSessionsExchange implements TableImporter {
  MealSessionsExchange(this.db, this.eventId);
  final AppDatabase db;
  final String eventId;

  static const headers = ['sesion', 'tipo', 'fecha'];

  static const csvSpec = CsvSpec(
      title: 'Columnas del CSV de sesiones de comidas',
      fileName: 'plantilla-sesiones-comidas.csv',
      columns: [
        CsvColumn(
            'sesion', 'nombre de la sesión (p. ej. «Almuerzo del sábado»)',
            required: true),
        CsvColumn('tipo',
            'Desayuno, Almuerzo, Cena u otro tipo (si no existe, se crea)',
            required: true),
        CsvColumn('fecha',
            'día de la sesión (2026-11-28 o 28/11/2026); si cae fuera del evento, la sesión se crea sin fecha'),
      ],
      note: csvSeparatorNote);

  @override
  CsvSpec get spec => csvSpec;
  @override
  String get title => 'Importar sesiones de comidas';
  @override
  String get help =>
      'Columnas: sesion, tipo (Desayuno, Almuerzo, Cena u otro) y fecha (opcional). '
      'Las sesiones que ya existen (mismo nombre) se omiten.';

  /// Todas las sesiones del evento (las borradas no salen), por fecha y nombre.
  Future<List<List<String>>> export() async {
    final types = await (db.select(db.controlTypes)
          ..where((t) => t.eventId.equals(eventId)))
        .get();
    final typeName = {for (final t in types) t.id: t.name};
    final rows = await (db.select(db.controlSessions)
          ..where((s) => s.eventId.equals(eventId) & s.deletedAt.isNull()))
        .get();
    rows.sort((a, b) {
      final da = a.scheduledAt, db_ = b.scheduledAt;
      if (da != null && db_ != null && da != db_) return da.compareTo(db_);
      if ((da == null) != (db_ == null)) return da == null ? 1 : -1;
      return normalizeText(a.name).compareTo(normalizeText(b.name));
    });
    return [
      headers,
      for (final s in rows)
        [
          s.name,
          typeName[s.controlTypeId] ?? '',
          s.scheduledAt == null ? '' : _day(s.scheduledAt!.toLocal()),
        ],
    ];
  }

  Future<TableImportSummary> _run(String csvText, {required bool write}) async {
    final repo = MealRepo(db);
    final rows = readCsvTable(
        parseCsv(csvText),
        const {
          'sesion': ['sesión', 'nombre', 'session'],
          'tipo': ['type'],
          'fecha': ['dia', 'día', 'date'],
        },
        normalizeText);
    final out = TableImportSummary();
    if (rows.isEmpty) {
      out.warnings.add('El archivo está vacío o no tiene filas.');
      return out;
    }
    if (!rows.first.$2.containsKey('sesion') ||
        !rows.first.$2.containsKey('tipo')) {
      out.warnings.add(
          'Faltan columnas: el archivo debe tener al menos «sesion» y «tipo».');
      return out;
    }
    final ev = await (db.select(db.events)..where((e) => e.id.equals(eventId)))
        .getSingle();
    final start = DateTime.tryParse(ev.startDate);
    final end = DateTime.tryParse(ev.endDate);
    final existing = await (db.select(db.controlSessions)
          ..where((s) => s.eventId.equals(eventId) & s.deletedAt.isNull()))
        .get();
    final known = {for (final s in existing) normalizeText(s.name)};
    final types = await repo.types(eventId);
    final typeByName = {for (final t in types) normalizeText(t.name): t.id};
    final newTypes = <String>{};
    final seen = <String>{};
    var created = 0, skipped = 0, noDate = 0;
    for (final (line, r) in rows) {
      final name = r['sesion'] ?? '';
      final typeRaw = r['tipo'] ?? '';
      if (name.isEmpty) {
        out.warnings.add('Fila $line: falta el nombre de la sesión.');
        continue;
      }
      if (typeRaw.isEmpty) {
        out.warnings.add('Fila $line: falta el tipo de «$name».');
        continue;
      }
      final dayRaw = r['fecha'] ?? '';
      DateTime? day;
      if (dayRaw.isNotEmpty) {
        day = parseDay(dayRaw);
        if (day == null) {
          out.warnings.add(
              'Fila $line: «$dayRaw» no es una fecha (usa 2026-11-28 o 28/11/2026).');
          continue;
        }
      }
      final key = normalizeText(name);
      if (!seen.add(key)) {
        out.warnings.add('Fila $line: «$name» está repetida en el archivo.');
        continue;
      }
      if (known.contains(key)) {
        skipped++;
        continue;
      }
      if (day != null && start != null && end != null) {
        final s0 = DateTime(start.year, start.month, start.day);
        final e0 = DateTime(end.year, end.month, end.day);
        if (day.isBefore(s0) || day.isAfter(e0)) {
          day = null;
          noDate++;
        }
      }
      final tKey = normalizeText(typeRaw);
      if (!typeByName.containsKey(tKey)) newTypes.add(typeRaw);
      created++;
      if (write) {
        var typeId = typeByName[tKey];
        if (typeId == null) {
          typeId = (await repo.createType(eventId, typeRaw)).id;
          typeByName[tKey] = typeId;
        }
        await repo.createSession(eventId, typeId, name, date: day);
      }
    }
    out.work = created;
    out.lines.add('Sesiones nuevas: $created');
    if (skipped > 0) {
      out.lines.add('Ya existían (se omiten): $skipped');
    }
    if (noDate > 0) {
      out.lines.add(
          '$noDate ${noDate == 1 ? 'sesión queda' : 'sesiones quedan'} sin fecha: la del archivo cae fuera de las fechas del evento.');
    }
    if (newTypes.isNotEmpty) {
      out.lines.add('Tipos nuevos que se crearán: ${newTypes.join(', ')}');
    }
    return out;
  }

  @override
  Future<TableImportSummary> preview(String csvText) =>
      _run(csvText, write: false);
  @override
  Future<TableImportSummary> apply(String csvText,
          {Map<String, int> choices = const {}}) async =>
      db.transaction(() => _run(csvText, write: true));
}

/// Exportar e importar QUIÉN PASÓ en cada sesión (una fila por marca activa). Al importar, la
/// sesión se busca por nombre y la persona por número de inscripción; una marca que ya está
/// (misma persona, misma sesión, misma hora al segundo) se omite, así que repetir la importación
/// no duplica nada. Sirve para juntar lo marcado en dos dispositivos.
class MealRecordsExchange implements TableImporter {
  MealRecordsExchange(this.db, this.eventId);
  final AppDatabase db;
  final String eventId;

  static const headers = [
    'sesion',
    'tipo',
    'numero',
    'nombre',
    'hora',
    'operador',
    'repetido'
  ];

  static const csvSpec = CsvSpec(
      title: 'Columnas del CSV de quién pasó',
      fileName: 'plantilla-quien-paso.csv',
      columns: [
        CsvColumn('sesion', 'nombre de una sesión que ya existe en el evento',
            required: true),
        CsvColumn('numero', 'número de inscripción de la persona',
            required: true),
        CsvColumn(
            'hora', 'día y hora (2026-11-28 13:05:09); si falta, se usa ahora'),
        CsvColumn('operador', 'quién la marcó'),
        CsvColumn(
            'repetido', 'Sí si pasó más de una vez (se calcula al importar)'),
        CsvColumn('tipo', 'solo informativa: se ignora al importar'),
        CsvColumn('nombre', 'solo informativa: se ignora al importar'),
      ],
      note: csvSeparatorNote);

  @override
  CsvSpec get spec => csvSpec;
  @override
  String get title => 'Importar quién pasó';
  @override
  String get help =>
      'Columnas: sesion (debe existir), numero (de inscripción), hora y operador (opcionales). '
      'Lo que ya está marcado se omite.';

  /// Marcas activas (no deshechas) de todas las sesiones del evento, por sesión y hora.
  Future<List<List<String>>> export() async {
    final sessions = await (db.select(db.controlSessions)
          ..where((s) => s.eventId.equals(eventId) & s.deletedAt.isNull()))
        .get();
    final types = await (db.select(db.controlTypes)
          ..where((t) => t.eventId.equals(eventId)))
        .get();
    final typeName = {for (final t in types) t.id: t.name};
    final people = await (db.select(db.attendees)
          ..where((a) => a.eventId.equals(eventId)))
        .get();
    final byId = {for (final a in people) a.id: a};
    sessions
        .sort((a, b) => normalizeText(a.name).compareTo(normalizeText(b.name)));
    final out = <List<String>>[headers];
    for (final s in sessions) {
      final recs = await (db.select(db.controlRecords)
            ..where((r) =>
                r.sessionId.equals(s.id) &
                r.undoneAt.isNull() &
                r.deletedAt.isNull())
            ..orderBy([(r) => OrderingTerm.asc(r.markedAt)]))
          .get();
      for (final r in recs) {
        final a = byId[r.attendeeId];
        out.add([
          s.name,
          typeName[s.controlTypeId] ?? '',
          a == null ? '' : '${a.regNumber}',
          a == null ? '' : _fullName(a),
          _dayTime(r.markedAt.toLocal()),
          r.operatorName,
          r.repeatOverride ? 'Sí' : 'No',
        ]);
      }
    }
    return out;
  }

  Future<TableImportSummary> _run(String csvText, {required bool write}) async {
    final rows = readCsvTable(
        parseCsv(csvText),
        const {
          'sesion': ['sesión', 'session'],
          'numero': ['número', 'num', 'n'],
          'hora': ['fecha', 'marcado'],
          'operador': ['marcado por'],
        },
        normalizeText);
    final out = TableImportSummary();
    if (rows.isEmpty) {
      out.warnings.add('El archivo está vacío o no tiene filas.');
      return out;
    }
    if (!rows.first.$2.containsKey('sesion') ||
        !rows.first.$2.containsKey('numero')) {
      out.warnings.add(
          'Faltan columnas: el archivo debe tener al menos «sesion» y «numero».');
      return out;
    }
    final sessions = await (db.select(db.controlSessions)
          ..where((s) => s.eventId.equals(eventId) & s.deletedAt.isNull()))
        .get();
    final sessionByName = {for (final s in sessions) normalizeText(s.name): s};
    final people = await (db.select(db.attendees)
          ..where((a) => a.eventId.equals(eventId) & a.deletedAt.isNull()))
        .get();
    final byNumber = {for (final a in people) a.regNumber: a};
    // Marcas activas ya guardadas: «sesión|persona» → horas (al minuto).
    final have = <String, List<DateTime>>{};
    for (final s in sessions) {
      final recs = await (db.select(db.controlRecords)
            ..where((r) =>
                r.sessionId.equals(s.id) &
                r.undoneAt.isNull() &
                r.deletedAt.isNull()))
          .get();
      for (final r in recs) {
        have.putIfAbsent('${s.id}|${r.attendeeId}', () => []).add(r.markedAt);
      }
    }
    // Misma marca = misma hora al segundo (un repetido a los pocos segundos sigue siendo otra).
    bool sameMoment(DateTime a, DateTime b) =>
        a.toUtc().difference(b.toUtc()).inMilliseconds.abs() < 1000;
    final deviceId = write ? await db.deviceId() : '';
    var created = 0, already = 0;
    for (final (line, r) in rows) {
      final sName = r['sesion'] ?? '';
      final s = sessionByName[normalizeText(sName)];
      if (sName.isEmpty) {
        out.warnings.add('Fila $line: falta la sesión.');
        continue;
      }
      if (s == null) {
        out.warnings.add(
            'Fila $line: la sesión «$sName» no existe (impórtala antes desde «Importar sesiones de comidas»).');
        continue;
      }
      final number = int.tryParse(r['numero'] ?? '');
      final a = number == null ? null : byNumber[number];
      if (a == null) {
        out.warnings.add(
            'Fila $line: no hay nadie inscrito con el número «${r['numero'] ?? ''}».');
        continue;
      }
      if (a.status == 'preregistered') {
        out.warnings.add(
            'Fila $line: ${_fullName(a)} está preinscrito; confirma antes su asistencia.');
        continue;
      }
      DateTime when = DateTime.now();
      final horaRaw = r['hora'] ?? '';
      if (horaRaw.isNotEmpty) {
        final t = parseDayTime(horaRaw);
        if (t == null) {
          out.warnings.add(
              'Fila $line: «$horaRaw» no es una hora (usa 2026-11-28 13:05:09).');
          continue;
        }
        when = t;
      }
      final key = '${s.id}|${a.id}';
      final list = have.putIfAbsent(key, () => []);
      if (horaRaw.isNotEmpty && list.any((x) => sameMoment(x, when))) {
        already++;
        continue;
      }
      final isRepeat = list.isNotEmpty;
      list.add(when.toUtc());
      created++;
      if (write) {
        final now = DateTime.now().toUtc();
        await db.into(db.controlRecords).insert(ControlRecordsCompanion.insert(
              id: newUuidV7(),
              createdAt: now,
              updatedAt: now,
              originDeviceId: deviceId,
              sessionId: s.id,
              attendeeId: a.id,
              markedAt: when.toUtc(),
              operatorName: Value(r['operador'] ?? ''),
              repeatOverride: Value(isRepeat),
            ));
      }
    }
    out.work = created;
    out.lines.add('Marcas nuevas: $created');
    if (already > 0) out.lines.add('Ya estaban marcadas (se omiten): $already');
    return out;
  }

  @override
  Future<TableImportSummary> preview(String csvText) =>
      _run(csvText, write: false);
  @override
  Future<TableImportSummary> apply(String csvText,
          {Map<String, int> choices = const {}}) async =>
      db.transaction(() => _run(csvText, write: true));
}
