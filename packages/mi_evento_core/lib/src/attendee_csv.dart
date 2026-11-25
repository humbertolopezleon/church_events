import 'dart:convert';

import 'models.dart';
import 'text.dart';

/// Columnas del archivo de intercambio de asistentes, en el orden en que se exportan. Los nombres
/// siguen la base de datos del sistema. Al importar se reconocen por su nombre (sin tildes ni
/// mayúsculas) y pueden estar en cualquier orden; las columnas desconocidas se ignoran.
const attendeeCsvHeaders = <String>[
  'id',
  'numero',
  'nombre',
  'apellido1',
  'apellido2',
  'sexo',
  'edad',
  'iglesia',
  'provincia',
  'municipio',
  'telefono',
  'necesita_hospedaje',
  'hospedaje',
  'equipo',
  'pareja_numero',
  'grupos',
  'observaciones',
  'estado',
];

/// Separador de listas dentro de una celda (p. ej. varios grupos).
const csvListSeparator = '|';

/// Lee los bytes de un CSV como UTF-16 (Excel «Texto Unicode», con marca FF FE / FE FF), UTF-8 y,
/// si no lo es (Excel «CSV» antiguo guarda en ANSI), como Windows-1252 (ver [decodeWindows1252]).
String decodeCsvBytes(List<int> bytes) {
  if (bytes.length >= 2 &&
      ((bytes[0] == 0xFF && bytes[1] == 0xFE) ||
          (bytes[0] == 0xFE && bytes[1] == 0xFF))) {
    final le = bytes[0] == 0xFF;
    final units = <int>[
      for (var i = 2; i + 1 < bytes.length; i += 2)
        le ? bytes[i] | (bytes[i + 1] << 8) : (bytes[i] << 8) | bytes[i + 1]
    ];
    return String.fromCharCodes(units);
  }
  try {
    return utf8.decode(bytes);
  } on FormatException {
    return decodeWindows1252(bytes);
  }
}

/// Caracteres de Windows-1252 en 0x80–0x9F (latin1 los toma por controles). Los huecos sin
/// asignar (81, 8D, 8F, 90, 9D) quedan como el carácter de control del mismo código.
const _cp1252High = <int, int>{
  0x80: 0x20AC, 0x82: 0x201A, 0x83: 0x0192, 0x84: 0x201E, 0x85: 0x2026,
  0x86: 0x2020, 0x87: 0x2021, 0x88: 0x02C6, 0x89: 0x2030, 0x8A: 0x0160,
  0x8B: 0x2039, 0x8C: 0x0152, 0x8E: 0x017D, 0x91: 0x2018, 0x92: 0x2019,
  0x93: 0x201C, 0x94: 0x201D, 0x95: 0x2022, 0x96: 0x2013, 0x97: 0x2014,
  0x98: 0x02DC, 0x99: 0x2122, 0x9A: 0x0161, 0x9B: 0x203A, 0x9C: 0x0153,
  0x9E: 0x017E, 0x9F: 0x0178,
};

/// Windows-1252 (el «ANSI» de Excel en español): como latin1, pero con comillas tipográficas,
/// rayas, «€», «…», etc. en 0x80–0x9F.
String decodeWindows1252(List<int> bytes) =>
    String.fromCharCodes([for (final b in bytes) _cp1252High[b] ?? b]);

/// Neutraliza una celda que Excel tomaría por fórmula (empieza con `=`, `+`, `-` o `@`, o con
/// tabulador): le antepone un apóstrofe. Los números sueltos («-5», «+53») no se tocan.
String neutralizeFormula(String c) {
  if (c.isEmpty) return c;
  final first = c[0];
  if (first != '=' &&
      first != '+' &&
      first != '-' &&
      first != '@' &&
      first != '\t') {
    return c;
  }
  if (RegExp(r'^[+-]?\d[\d.]*$').hasMatch(c)) return c;
  return "'$c";
}

/// Deshace [neutralizeFormula] al leer: «'=1+1» vuelve a ser «=1+1».
String restoreFormula(String c) =>
    RegExp(r"^'[=+\-@\t]").hasMatch(c) ? c.substring(1) : c;

/// Escribe un CSV con [delimiter]. Lleva BOM (Excel respeta las tildes), saltos de línea CRLF y,
/// con [excelHint], la primera línea `sep=;`: Excel la obedece sea cual sea el separador de lista
/// de su configuración regional (sin ella, un Excel configurado con «,» mostraba todo en una sola
/// columna). [parseCsv] la reconoce y la omite.
String buildCsvDelimited(List<List<String>> rows,
    {String delimiter = ';', bool excelHint = true}) {
  String cell(String raw) {
    final c = neutralizeFormula(raw);
    final needs = c.contains(delimiter) ||
        c.contains('"') ||
        c.contains('\n') ||
        c.contains('\r') ||
        c.contains(',') ||
        c.contains(';');
    final esc = c.replaceAll('"', '""');
    return needs ? '"$esc"' : esc;
  }

  final body =
      '${rows.map((r) => r.map(cell).join(delimiter)).join('\r\n')}\r\n';
  return '\u{FEFF}${excelHint ? 'sep=$delimiter\r\n' : ''}$body';
}

/// Lee un CSV: quita el BOM, adivina el separador (`;`, `,` o tabulador) por la primera fila,
/// respeta comillas (con saltos de línea y comillas dobles escapadas) y omite filas vacías.
List<List<String>> parseCsv(String text) {
  var t = text.startsWith('\u{FEFF}') ? text.substring(1) : text;
  // Primera línea «sep=;» (la pone la exportación para Excel): fija el separador y se omite.
  String? hinted;
  // (Una hoja de cálculo que la guardó como fila pudo rellenarla con separadores: «sep=;;;;» o entre comillas.)
  final hint =
      RegExp(r'^"?sep=(.)"?\1*\r?\n', caseSensitive: false).firstMatch(t);
  if (hint != null) {
    hinted = hint.group(1);
    t = t.substring(hint.end);
  }
  if (t.trim().isEmpty) return const [];
  // Separador: el más frecuente fuera de comillas en la primera línea.
  final counts = {';': 0, ',': 0, '\t': 0};
  var inQ = false;
  for (var i = 0; i < t.length; i++) {
    final ch = t[i];
    if (ch == '"') {
      inQ = !inQ;
    } else if (!inQ) {
      if (ch == '\n' || ch == '\r') break;
      if (counts.containsKey(ch)) counts[ch] = counts[ch]! + 1;
    }
  }
  final delimiter =
      hinted ?? counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;

  final rows = <List<String>>[];
  var row = <String>[];
  final cell = StringBuffer();
  var quoted = false;
  var i = 0;
  void endCell() {
    row.add(restoreFormula(cell.toString()));
    cell.clear();
  }

  void endRow() {
    endCell();
    if (row.any((c) => c.trim().isNotEmpty)) rows.add(row);
    row = <String>[];
  }

  while (i < t.length) {
    final ch = t[i];
    if (quoted) {
      if (ch == '"') {
        if (i + 1 < t.length && t[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          quoted = false;
        }
      } else {
        cell.write(ch);
      }
    } else if (ch == '"' && cell.isEmpty) {
      quoted = true;
    } else if (ch == delimiter) {
      endCell();
    } else if (ch == '\n' || ch == '\r') {
      if (ch == '\r' && i + 1 < t.length && t[i + 1] == '\n') i++;
      endRow();
    } else {
      cell.write(ch);
    }
    i++;
  }
  if (cell.isNotEmpty || row.isNotEmpty) endRow();
  return rows;
}

/// Una fila del archivo ya validada.
class AttendeeCsvRow {
  const AttendeeCsvRow({
    required this.line,
    this.id,
    this.number,
    required this.firstName,
    required this.lastName1,
    this.lastName2 = '',
    required this.sex,
    required this.age,
    required this.church,
    this.province = '',
    this.municipality = '',
    this.phone = '',
    this.needsLodging,
    this.lodging = '',
    this.team = '',
    this.spouseNumber,
    this.groups = const [],
    this.notes = '',
    this.hasLodgingColumn = false,
    this.hasTeamColumn = false,
    this.confirmed,
  });

  /// Número de fila en el archivo (la primera de datos es la 2), para los mensajes.
  final int line;
  final String? id;
  final int? number;
  final String firstName, lastName1, lastName2;
  final Sex sex;
  final int age;
  final String church, province, municipality, phone;

  /// Nulo si el archivo no trae esa columna o la celda está vacía (no cambia lo guardado).
  final bool? needsLodging;
  final String lodging, team;
  final int? spouseNumber;
  final List<String> groups;
  final String notes;
  final bool hasLodgingColumn, hasTeamColumn;

  /// Estado que trae el archivo: `true` confirmado, `false` preinscrito, nulo = sin indicar.
  final bool? confirmed;
}

class CsvIssue {
  const CsvIssue(this.line, this.message);
  final int line;
  final String message;
  @override
  String toString() => 'Fila $line: $message';
}

class AttendeeCsvParse {
  const AttendeeCsvParse(this.rows, this.errors, this.notes);
  final List<AttendeeCsvRow> rows;

  /// Filas con problemas: no se importan; el resto sí.
  final List<CsvIssue> errors;

  /// Avisos generales (columnas desconocidas, etc.).
  final List<String> notes;
  bool get isEmpty => rows.isEmpty && errors.isEmpty;
}

String _key(String s) =>
    normalizeText(s).replaceAll(RegExp(r'[^a-z0-9]+'), '_');

const _aliases = <String, String>{
  'id': 'id',
  'numero': 'numero',
  'n': 'numero',
  'no': 'numero',
  'nro': 'numero',
  'nombre': 'nombre',
  'nombres': 'nombre',
  'apellido1': 'apellido1',
  'primer_apellido': 'apellido1',
  'apellido_1': 'apellido1',
  'apellido': 'apellido1',
  'apellido2': 'apellido2',
  'segundo_apellido': 'apellido2',
  'apellido_2': 'apellido2',
  'sexo': 'sexo',
  'genero': 'sexo',
  'edad': 'edad',
  'iglesia': 'iglesia',
  'provincia': 'provincia',
  'municipio': 'municipio',
  'telefono': 'telefono',
  'tel': 'telefono',
  'celular': 'telefono',
  'necesita_hospedaje': 'necesita_hospedaje',
  'hospedaje_necesario': 'necesita_hospedaje',
  'hospedaje': 'hospedaje',
  'equipo': 'equipo',
  'pareja_numero': 'pareja_numero',
  'pareja': 'pareja_numero',
  'conyuge': 'pareja_numero',
  'grupos': 'grupos',
  'grupo': 'grupos',
  'observaciones': 'observaciones',
  'notas': 'observaciones',
  'estado': 'estado',
  'asistencia': 'estado',
};

/// Interpreta «Hombre/Mujer» (también H, M = masculino, F, V, masculino, femenino). Nulo si no se entiende.
Sex? parseSexCell(String raw) {
  final k = normalizeText(raw);
  switch (k) {
    case 'hombre':
    case 'h':
    case 'varon':
    case 'masculino':
    case 'm': // «M» = masculino, igual que en el formulario («M (Hombre)»)
    case 'v':
      return Sex.male;
    case 'mujer':
    case 'f':
    case 'femenino':
      return Sex.female;
  }
  return null;
}

/// Estado de asistencia escrito en el archivo: `true` = confirmado, `false` = preinscrito, nulo si
/// la celda está vacía (vale lo que se elija al importar). [unknown] se pone a `true` si no se
/// entiende.
bool? parseStatusCell(String raw, {void Function()? unknown}) {
  final k = normalizeText(raw);
  if (k.isEmpty) return null;
  if (['confirmado', 'confirmada', 'confirmados', 'asistio', 'asiste']
      .contains(k)) {
    return true;
  }
  if (['preinscrito', 'preinscrita', 'preinscritos', 'pre', 'pendiente']
      .contains(k)) {
    return false;
  }
  unknown?.call();
  return null;
}

bool? _yesNo(String raw) {
  final k = normalizeText(raw);
  if (k.isEmpty) return null;
  if (['si', 's', 'x', '1', 'true', 'verdadero', 'yes', 'y'].contains(k)) {
    return true;
  }
  if (['no', 'n', '0', 'false', 'falso'].contains(k)) return false;
  return null;
}

/// Valida un archivo de asistentes. Nunca lanza: devuelve las filas buenas y la lista de errores.
AttendeeCsvParse parseAttendeesCsv(String text) {
  final table = parseCsv(text);
  if (table.isEmpty) {
    return const AttendeeCsvParse(
        [], [CsvIssue(1, 'El archivo está vacío.')], []);
  }
  final header = table.first;
  final col = <String, int>{};
  final unknown = <String>[];
  for (var i = 0; i < header.length; i++) {
    final raw = header[i].trim();
    if (raw.isEmpty) continue;
    final canon = _aliases[_key(raw)];
    if (canon == null) {
      unknown.add(raw);
    } else {
      col.putIfAbsent(canon, () => i);
    }
  }
  final notes = <String>[];
  final missing = [
    for (final r in ['nombre', 'apellido1', 'sexo', 'edad', 'iglesia'])
      if (!col.containsKey(r)) r
  ];
  if (missing.isNotEmpty) {
    return AttendeeCsvParse([], [
      CsvIssue(1,
          'Faltan columnas obligatorias: ${missing.join(', ')}. Usa la plantilla de Mi Evento.')
    ], notes);
  }
  if (unknown.isNotEmpty) {
    notes.add('Columnas que se ignoran: ${unknown.join(', ')}.');
  }

  String at(List<String> r, String name) {
    final i = col[name];
    return i == null || i >= r.length ? '' : r[i].trim();
  }

  final rows = <AttendeeCsvRow>[];
  final errors = <CsvIssue>[];
  final seenIds = <String, int>{};
  final seenNumbers = <int, int>{};
  for (var n = 1; n < table.length; n++) {
    final r = table[n];
    final line = n + 1;
    final problems = <String>[];
    final first = at(r, 'nombre');
    final last1 = at(r, 'apellido1');
    if (first.isEmpty) problems.add('falta el nombre');
    if (last1.isEmpty) problems.add('falta el primer apellido');
    final sex = parseSexCell(at(r, 'sexo'));
    if (sex == null) {
      problems.add(at(r, 'sexo').isEmpty
          ? 'falta el sexo (Hombre o Mujer)'
          : 'el sexo «${at(r, 'sexo')}» no se entiende (usa Hombre o Mujer)');
    }
    final age = int.tryParse(at(r, 'edad'));
    if (age == null) {
      problems.add(at(r, 'edad').isEmpty
          ? 'falta la edad'
          : 'la edad «${at(r, 'edad')}» no es un número');
    } else if (age < 1 || age > 110) {
      problems.add('la edad debe estar entre 1 y 110 años');
    }
    if (at(r, 'iglesia').isEmpty) problems.add('falta la iglesia');

    int? number;
    if (at(r, 'numero').isNotEmpty) {
      number = int.tryParse(at(r, 'numero'));
      if (number == null || number < 1) {
        problems.add('el número «${at(r, 'numero')}» no es válido');
        number = null;
      }
    }
    int? spouse;
    if (at(r, 'pareja_numero').isNotEmpty) {
      spouse = int.tryParse(at(r, 'pareja_numero'));
      if (spouse == null || spouse < 1) {
        problems.add(
            'el número de pareja «${at(r, 'pareja_numero')}» no es válido');
        spouse = null;
      }
    }
    final id = at(r, 'id');
    if (id.isNotEmpty && seenIds.containsKey(id)) {
      problems.add('el id repite el de la fila ${seenIds[id]}');
    }
    if (number != null && seenNumbers.containsKey(number)) {
      problems
          .add('el número $number repite el de la fila ${seenNumbers[number]}');
    }
    final needs = col.containsKey('necesita_hospedaje') &&
            at(r, 'necesita_hospedaje').isNotEmpty
        ? _yesNo(at(r, 'necesita_hospedaje'))
        : null;
    if (col.containsKey('necesita_hospedaje') &&
        at(r, 'necesita_hospedaje').isNotEmpty &&
        needs == null) {
      problems.add('«necesita_hospedaje» debe ser Sí o No');
    }

    var badStatus = false;
    final confirmed = parseStatusCell(at(r, 'estado'), unknown: () {
      badStatus = true;
    });
    if (badStatus) {
      problems.add(
          'el estado «${at(r, 'estado')}» no se entiende (usa Preinscrito o Confirmado)');
    }

    if (problems.isNotEmpty) {
      errors.add(CsvIssue(line, '${problems.join('; ')}.'));
      continue;
    }
    if (id.isNotEmpty) seenIds[id] = line;
    if (number != null) seenNumbers[number] = line;
    rows.add(AttendeeCsvRow(
      line: line,
      id: id.isEmpty ? null : id,
      number: number,
      firstName: first,
      lastName1: last1,
      lastName2: at(r, 'apellido2'),
      sex: sex!,
      age: age!,
      church: at(r, 'iglesia'),
      province: at(r, 'provincia'),
      municipality: at(r, 'municipio'),
      phone: at(r, 'telefono'),
      needsLodging: needs,
      lodging: at(r, 'hospedaje'),
      team: at(r, 'equipo'),
      spouseNumber: spouse,
      groups: [
        for (final g in at(r, 'grupos').split(csvListSeparator))
          if (g.trim().isNotEmpty) g.trim()
      ],
      notes: at(r, 'observaciones'),
      hasLodgingColumn: col.containsKey('hospedaje'),
      hasTeamColumn: col.containsKey('equipo'),
      confirmed: confirmed,
    ));
  }
  return AttendeeCsvParse(rows, errors, notes);
}
