import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import '../providers.dart';

/// Nombre de archivo CSV seguro: `asistentes-retiro-de-jovenes.csv`.
String csvFileName(String what, [String? eventName]) {
  final slug = normalizeText(eventName ?? '').replaceAll(' ', '-');
  return slug.isEmpty ? '$what.csv' : '$what-$slug.csv';
}

/// Guarda/comparte una tabla como CSV (`;`, UTF-8 con BOM, listo para Excel) y avisa del resultado.
/// [rows] lleva la fila de títulos primero. Todas las listas de la app usan esta misma salida.
Future<void> saveCsv(BuildContext context, WidgetRef ref,
    {required String name, required List<List<String>> rows}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final ok = await ref.read(fileSaverProvider).save(
        name, Uint8List.fromList(utf8.encode(buildCsvDelimited(rows))),
        mimeType: 'text/csv');
    messenger.showSnackBar(SnackBar(
        content: Text(ok
            ? 'CSV guardado (${rows.length - 1} filas).'
            : 'Guardado cancelado.')));
  } catch (e) {
    messenger
        .showSnackBar(SnackBar(content: Text('No se pudo crear el CSV: $e')));
  }
}
