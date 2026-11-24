import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'attendee_csv.dart';

/// Versión del FORMATO del archivo de respaldo (no de la base de datos). Una app más vieja no abre
/// un archivo de formato más nuevo, y lo dice; una más nueva sí abre los viejos.
const bundleFormatVersion = 1;

/// Extensión del archivo de respaldo: es un CSV normal que Excel abre.
const backupFileExtension = 'csv';

/// Nombre de la tabla especial con los datos de cabecera del respaldo.
const _metaTable = 'meta';

/// Error con mensaje listo para el usuario (en español).
class BundleException implements Exception {
  BundleException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Cabecera del respaldo: de dónde viene y qué contiene.
class BundleManifest {
  const BundleManifest({
    required this.formatVersion,
    required this.dbSchemaVersion,
    required this.exportedAt,
    required this.deviceId,
    required this.eventId,
    required this.eventName,
    required this.counts,
  });
  final int formatVersion;
  final int dbSchemaVersion;
  final DateTime exportedAt;
  final String deviceId;
  final String eventId;
  final String eventName;

  /// Filas por tabla (para mostrar «Contiene 248 asistentes…» antes de importar y detectar
  /// archivos truncados).
  final Map<String, int> counts;
}

/// Contenido de un respaldo: tabla → filas, con TODOS los valores como texto (así viven en el CSV).
/// Quien lo importa convierte cada celda a su tipo según el esquema de la base de datos.
/// Todas las filas conservan su id UUID, sus marcas de tiempo (milisegundos UTC) y el borrado
/// lógico, para poder fusionarlas con otro dispositivo.
class Bundle {
  const Bundle(this.manifest, this.tables);
  final BundleManifest manifest;
  final Map<String, List<Map<String, String>>> tables;
}

String _cell(Object? v) => v == null ? '' : '$v';

/// Suma de verificación de las filas de datos (todo menos `meta`): detecta un archivo alterado,
/// cortado o que Excel «arregló» (p. ej. números largos pasados a notación científica).
String _sum(Iterable<List<String>> dataRows, int width) {
  final sink = StringBuffer();
  for (final r in dataRows) {
    for (var i = 0; i < width; i++) {
      sink
        ..write(i < r.length ? r[i] : '')
        ..write('\u0001');
    }
    sink.write('\n');
  }
  return sha256.convert(utf8.encode(sink.toString())).toString();
}

/// Arma un respaldo CSV de UN solo archivo. La primera columna es `tabla`; el resto son las
/// columnas de todas las tablas (cada fila rellena solo las suyas). Las filas `meta` llevan la
/// cabecera (`clave`/`valor`). UTF-8 con BOM y «;», como el resto de los CSV de la app.
Uint8List encodeBundle({
  required Map<String, List<Map<String, Object?>>> tables,
  required int dbSchemaVersion,
  required String deviceId,
  required String eventId,
  required String eventName,
  DateTime? now,
}) {
  final columns = <String>{'clave', 'valor'};
  for (final rows in tables.values) {
    for (final r in rows) {
      columns.addAll(r.keys);
    }
  }
  final header = ['tabla', ...columns];
  final data = <List<String>>[
    for (final e in tables.entries)
      for (final r in e.value)
        [
          for (final c in header) c == 'tabla' ? e.key : _cell(r[c]),
        ],
  ];
  final meta = <List<String>>[
    ['app', 'mi-evento'],
    ['formatVersion', '$bundleFormatVersion'],
    ['dbSchemaVersion', '$dbSchemaVersion'],
    ['exportedAt', (now ?? DateTime.now()).toUtc().toIso8601String()],
    ['deviceId', deviceId],
    ['eventId', eventId],
    ['eventName', eventName],
    for (final e in tables.entries) ['filas.${e.key}', '${e.value.length}'],
    ['sha256', _sum(data, header.length)],
  ];
  final out = <List<String>>[header];
  for (final m in meta) {
    out.add([
      for (final c in header)
        c == 'tabla'
            ? _metaTable
            : c == 'clave'
                ? m[0]
                : c == 'valor'
                    ? m[1]
                    : '',
    ]);
  }
  out.addAll(data);
  return Uint8List.fromList(utf8.encode(buildCsvDelimited(out)));
}

/// Abre un respaldo CSV (UTF-8, UTF-16 o ANSI). Valida: que sea un respaldo de Mi Evento, la
/// versión del formato y que no falten filas (cada tabla trae el número que declara la cabecera).
Bundle decodeBundle(List<int> bytes) {
  final rows = parseCsv(decodeCsvBytes(bytes));
  if (rows.length < 2 || rows.first.isEmpty || rows.first.first != 'tabla') {
    throw BundleException('Este archivo no es una copia de Mi Evento.');
  }
  final header = rows.first;
  final meta = <String, String>{};
  final tables = <String, List<Map<String, String>>>{};
  for (final r in rows.skip(1)) {
    final row = <String, String>{
      for (var i = 0; i < header.length; i++)
        header[i]: i < r.length ? r[i] : '',
    };
    final table = row['tabla'] ?? '';
    if (table == _metaTable) {
      meta[row['clave'] ?? ''] = row['valor'] ?? '';
    } else if (table.isNotEmpty) {
      (tables[table] ??= []).add(row..remove('tabla'));
    }
  }
  if (meta['app'] != 'mi-evento') {
    throw BundleException('Este archivo no es una copia de Mi Evento.');
  }
  final BundleManifest manifest;
  try {
    manifest = BundleManifest(
      formatVersion: int.parse(meta['formatVersion']!),
      dbSchemaVersion: int.parse(meta['dbSchemaVersion']!),
      exportedAt: DateTime.parse(meta['exportedAt']!),
      deviceId: meta['deviceId']!,
      eventId: meta['eventId']!,
      eventName: meta['eventName']!,
      counts: {
        for (final e in meta.entries)
          if (e.key.startsWith('filas.'))
            e.key.substring(6): int.parse(e.value),
      },
    );
  } catch (_) {
    throw BundleException('La cabecera de la copia está incompleta o dañada.');
  }
  if (manifest.formatVersion > bundleFormatVersion) {
    throw BundleException(
        'Esta copia es de una versión más nueva de Mi Evento. Actualiza la app para abrirla.');
  }
  final dataRows =
      rows.skip(1).where((r) => r.isNotEmpty && r.first != _metaTable);
  if (meta['sha256'] != _sum(dataRows, header.length)) {
    throw BundleException(
        'La copia está dañada o incompleta (no coincide la suma de verificación).');
  }
  for (final e in manifest.counts.entries) {
    if ((tables[e.key]?.length ?? 0) != e.value) {
      throw BundleException(
          'La copia está incompleta: de «${e.key}» faltan filas (¿el archivo se cortó o se editó?).');
    }
  }
  return Bundle(manifest, tables);
}

/// Regla de fusión con otro dispositivo: gana la fila con `updatedAt` MÁS RECIENTE; en empate se
/// conserva la local (no hay cambios que aplicar).
bool incomingWins(DateTime existingUpdatedAt, DateTime incomingUpdatedAt) =>
    incomingUpdatedAt.isAfter(existingUpdatedAt);
