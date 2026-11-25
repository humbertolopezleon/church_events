import 'package:drift/drift.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'csv_spec.dart';
import 'database.dart';
import 'repos_b.dart';
import 'table_import.dart';

/// Exportar e importar la DEFINICIÓN de los equipos (nombre, color y capitán), sin las personas
/// (para eso está `TeamExchange`). Si el equipo ya existe (mismo nombre) se actualiza; si no, se
/// crea. Un capitán que no es del equipo se mueve a él, pero solo si el usuario lo aprueba en la
/// revisión (puede elegir otro integrante o no cambiar el capitán).
class TeamDefinitionExchange implements TableImporter {
  TeamDefinitionExchange(this.db, this.eventId);
  final AppDatabase db;
  final String eventId;

  static const headers = [
    'equipo',
    'color',
    'capitan_numero',
    'capitan',
    'integrantes'
  ];

  static const csvSpec = CsvSpec(
      title: 'Columnas del CSV de equipos',
      fileName: 'plantilla-equipos.csv',
      columns: [
        CsvColumn('equipo', 'nombre del equipo (si ya existe, se actualiza)',
            required: true),
        CsvColumn('color',
            'Rojo, Azul, Verde, Amarillo, Morado, Naranja, Turquesa o Rosa (o un código #RRGGBB)'),
        CsvColumn('capitan_numero',
            'número de inscripción del capitán (si no es del equipo, se pide permiso para moverlo)'),
        CsvColumn('capitan', 'solo informativa: se ignora al importar'),
        CsvColumn('integrantes', 'solo informativa: se ignora al importar'),
      ],
      note: csvSeparatorNote);

  @override
  CsvSpec get spec => csvSpec;

  @override
  String get title => 'Importar equipos';
  @override
  String get help =>
      'Columnas: equipo, color (opcional) y capitan_numero (opcional, el número de inscripción). '
      'Si el equipo ya existe se actualiza; si no, se crea. No asigna personas a los equipos.';

  /// Color del CSV → código «#RRGGBB». Acepta el nombre de la paleta o un código hexadecimal.
  static String? colorFromText(String raw) {
    final n = normalizeText(raw);
    for (final (name, hex) in teamPalette) {
      if (normalizeText(name) == n) return hex;
    }
    final m = RegExp(r'^#?([0-9a-fA-F]{6})$').firstMatch(raw.trim());
    return m == null ? null : '#${m.group(1)!.toUpperCase()}';
  }

  /// Código → nombre de la paleta (o el código si no es de la paleta; vacío si no hay color).
  static String colorLabel(String? hex) {
    if (hex == null || hex.isEmpty) return '';
    for (final (name, h) in teamPalette) {
      if (h.toLowerCase() == hex.toLowerCase()) return name;
    }
    return hex;
  }

  static String _name(AttendeeRow a) => [a.firstName, a.lastName1, a.lastName2]
      .where((e) => e.trim().isNotEmpty)
      .join(' ');

  /// Todos los equipos del evento, con su color, capitán y número de integrantes.
  Future<List<List<String>>> export() async {
    final teams = await (db.select(db.teams)
          ..where((t) => t.eventId.equals(eventId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    final people = await (db.select(db.attendees)
          ..where((a) => a.eventId.equals(eventId) & a.deletedAt.isNull()))
        .get();
    final byId = {for (final p in people) p.id: p};
    return [
      headers,
      for (final t in teams)
        [
          t.name,
          colorLabel(t.color),
          if (t.captainId != null && byId[t.captainId] != null)
            '${byId[t.captainId]!.regNumber}'
          else
            '',
          if (t.captainId != null && byId[t.captainId] != null)
            _name(byId[t.captainId]!)
          else
            '',
          '${people.where((p) => p.teamId == t.id).length}',
        ],
    ];
  }

  Future<TableImportSummary> _run(String csvText,
      {required bool write, Map<String, int> choices = const {}}) async {
    final repo = TeamRepo(db);
    final rows = readCsvTable(
        parseCsv(csvText),
        const {
          'equipo': ['team', 'nombre'],
          'color': [],
          'capitan_numero': ['capitán_numero', 'capitan numero', 'capitan_n'],
        },
        normalizeText);
    final out = TableImportSummary();
    if (rows.isEmpty) {
      out.warnings.add('El archivo está vacío o no tiene filas.');
      return out;
    }
    if (!rows.first.$2.containsKey('equipo')) {
      out.warnings.add('Falta la columna «equipo».');
      return out;
    }
    final people = await (db.select(db.attendees)
          ..where((a) => a.eventId.equals(eventId) & a.deletedAt.isNull()))
        .get();
    final byNumber = {for (final p in people) p.regNumber: p};
    final teams = await (db.select(db.teams)
          ..where((t) => t.eventId.equals(eventId) & t.deletedAt.isNull()))
        .get();
    final byName = {for (final t in teams) normalizeText(t.name): t};
    final teamName = {for (final t in teams) t.id: t.name};

    final plans = <_Plan>[];
    final seenTeams = <String>{};
    final seenCaptains = <int>{};
    for (final (line, r) in rows) {
      final name = (r['equipo'] ?? '').trim();
      if (name.isEmpty) {
        out.warnings.add('Fila $line: falta el nombre del equipo.');
        continue;
      }
      if (!seenTeams.add(normalizeText(name))) {
        out.warnings.add('Fila $line: el equipo «$name» está repetido.');
        continue;
      }
      String? color;
      final rawColor = (r['color'] ?? '').trim();
      if (rawColor.isNotEmpty) {
        color = colorFromText(rawColor);
        if (color == null) {
          out.warnings.add(
              'Fila $line: el color «$rawColor» no es de la paleta ni un código #RRGGBB.');
          continue;
        }
      }
      AttendeeRow? captain;
      final rawCap = (r['capitan_numero'] ?? '').trim();
      if (rawCap.isNotEmpty) {
        final n = int.tryParse(rawCap);
        captain = n == null ? null : byNumber[n];
        if (captain == null) {
          out.warnings.add(
              'Fila $line: no hay nadie con el número «$rawCap» para ser capitán de «$name».');
          continue;
        }
        if (!seenCaptains.add(captain.regNumber)) {
          out.warnings.add(
              'Fila $line: el número ${captain.regNumber} ya es capitán de otro equipo del archivo.');
          continue;
        }
      }
      plans.add(_Plan(line, name, byName[normalizeText(name)], color, captain));
    }

    // Capitanes que no son del equipo: hay que pedir permiso para moverlos.
    var created = 0, updated = 0, captains = 0, moves = 0;
    final actions = <_Action>[];
    for (final p in plans) {
      p.existing == null ? created++ : updated++;
      final cap = p.captain;
      if (cap == null) {
        actions.add(_Action(p, keepCaptain: true));
        continue;
      }
      if (p.existing != null && cap.teamId == p.existing!.id) {
        captains++;
        actions.add(_Action(p, captainId: cap.id));
        continue;
      }
      final from = cap.teamId == null
          ? 'no tiene equipo'
          : 'está en «${teamName[cap.teamId] ?? 'otro equipo'}»';
      final members = p.existing == null
          ? const <AttendeeRow>[]
          : [
              for (final m in people)
                if (m.teamId == p.existing!.id) m
            ];
      final d = ImportDecision(
        id: 'cap-${p.line}',
        message:
            '«${p.name}»: el capitán indicado (n.º ${cap.regNumber}, ${_name(cap)}) $from.',
        options: [
          'Moverlo a «${p.name}» y nombrarlo capitán',
          'No cambiar el capitán de «${p.name}»',
          for (final m in members)
            'Elegir a otro integrante: n.º ${m.regNumber} ${_name(m)}',
        ],
      );
      d.selected = (choices[d.id] ?? 0).clamp(0, d.options.length - 1);
      out.decisions.add(d);
      switch (d.selected) {
        case 0:
          captains++;
          moves++;
          actions.add(_Action(p, captainId: cap.id, move: cap));
        case 1:
          actions.add(_Action(p, keepCaptain: true));
        default:
          captains++;
          actions.add(_Action(p, captainId: members[d.selected - 2].id));
      }
    }
    out.work = plans.length;
    // Sin «0» en las frases (la fuente Atkinson lo tacha).
    out.lines
      ..add(created == 0 ? 'Sin equipos nuevos' : 'Equipos nuevos: $created')
      ..add(updated == 0
          ? 'Sin equipos que actualizar'
          : 'Equipos actualizados: $updated')
      ..add(captains == 0
          ? 'Sin cambios de capitán'
          : 'Capitanes asignados: $captains');
    if (moves > 0) {
      out.lines.add(
          'Personas que cambian de equipo para ser capitán: $moves (elige abajo si no estás de acuerdo)');
    }
    if (!write || out.work == 0) return out;

    final teamIds = <_Plan, String>{};
    for (final a in actions) {
      final p = a.plan;
      teamIds[p] = p.existing?.id ??
          (await repo.create(eventId, name: p.name, color: p.color)).id;
    }
    // Primero los traslados (quitan a la persona de su equipo anterior y de su capitanía)…
    for (final a in actions) {
      if (a.move != null) await repo.setTeam([a.move!.id], teamIds[a.plan]);
    }
    // …y luego nombre/color/capitán de cada equipo, con los datos ya actualizados.
    for (final a in actions) {
      final id = teamIds[a.plan]!;
      final cur = await (db.select(db.teams)..where((t) => t.id.equals(id)))
          .getSingle();
      await repo.update(id,
          name: cur.name,
          color: a.plan.color ?? cur.color,
          captainId: a.keepCaptain ? cur.captainId : a.captainId);
    }
    return out;
  }

  @override
  Future<TableImportSummary> preview(String csvText) =>
      _run(csvText, write: false);
  @override
  Future<TableImportSummary> apply(String csvText,
          {Map<String, int> choices = const {}}) async =>
      db.transaction(() => _run(csvText, write: true, choices: choices));
}

class _Plan {
  _Plan(this.line, this.name, this.existing, this.color, this.captain);
  final int line;
  final String name;
  final TeamRow? existing;
  final String? color;
  final AttendeeRow? captain;
}

class _Action {
  _Action(this.plan, {this.captainId, this.move, this.keepCaptain = false});
  final _Plan plan;
  final String? captainId;

  /// Persona que hay que mover al equipo antes de nombrarla capitán.
  final AttendeeRow? move;
  final bool keepCaptain;
}
