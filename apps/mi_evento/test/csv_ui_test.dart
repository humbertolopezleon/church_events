import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento/backup/file_picker.dart';
import 'package:mi_evento/export/file_saver.dart';
import 'package:mi_evento/providers.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'helpers.dart';

const _pc = Size(1200, 2400);

Future<(Ctx, MemoryFileSaver)> _open(WidgetTester t, {PickedFile? pick}) async {
  final saver = MemoryFileSaver();
  final c = await pumpApp(t, _pc, overrides: [
    fileSaverProvider.overrideWithValue(saver),
    filePickProvider.overrideWithValue(MemoryFilePick(pick)),
  ]);
  await t.runAsync(() async {
    final ev = await c.repo.createEvent(
        name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
    final ig = await c.repo.createChurch(
        name: 'Bautista Ebenezer',
        province: 'Matanzas',
        municipality: 'Cárdenas');
    await c.repo.addAttendee(
        eventId: ev,
        firstName: 'Juan',
        lastName1: 'Pérez',
        sex: Sex.male,
        age: 34,
        churchId: ig.id);
  });
  await login(t, 'admin', 'secreto1');
  await t.tap(find.text('Retiro'));
  await settle(t);
  await t.tap(find.text('Copias de seguridad').first);
  await settle(t);
  return (c, saver);
}

PickedFile csv(String body) =>
    PickedFile('asistentes.csv', Uint8List.fromList(utf8.encode(body)));

const _head =
    'id;numero;nombre;apellido1;apellido2;sexo;edad;iglesia;provincia;municipio;telefono;necesita_hospedaje;hospedaje;equipo;pareja_numero;grupos;observaciones;estado';

Future<int> _count(WidgetTester t, Ctx c) async =>
    (await t.runAsync(() => c.db.select(c.db.attendees).get()))!.length;

void main() {
  testWidgets(
      'exportar: crea el CSV de asistentes con las columnas del sistema',
      (t) async {
    final (_, saver) = await _open(t);
    await tapKey(t, 'csv-exportar');
    final f = saver.saved.entries.single;
    expect(f.key, endsWith('.csv'));
    final text = utf8.decode(f.value);
    expect(text.split('\r\n').first.replaceFirst('﻿', ''), _head);
    expect(text, contains('Juan'));
    expect(text, contains('Bautista Ebenezer'));
  });

  testWidgets('plantilla: solo los títulos de las columnas', (t) async {
    final (_, saver) = await _open(t);
    await tapKey(t, 'csv-plantilla');
    final text = utf8.decode(saver.saved['plantilla-asistentes.csv']!);
    expect(parseCsv(text), [attendeeCsvHeaders]);
  });

  testWidgets(
      'importar: vista previa primero; recién al confirmar se agregan las personas',
      (t) async {
    final (c, _) = await _open(t, pick: csv('''$_head
;;Rosa;Cruz;;Mujer;22;Bautista Ebenezer;;;;Sí;;;;;
;;Pedro;Cruz;;Hombre;45;Bautista Ebenezer;;;;;;;;;
;;;Cruz;;Mujer;20;Bautista Ebenezer;;;;;;;;;'''));
    await tapKey(t, 'csv-importar');
    expect(find.byKey(const Key('csvi-resumen')), findsOneWidget);
    expect(find.textContaining('2 personas nuevas ·'), findsOneWidget);
    expect(find.textContaining('1 filas con errores'), findsOneWidget);
    expect(find.textContaining('Fila 4: falta el nombre'), findsOneWidget);
    expect(await _count(t, c), 1); // todavía no se importó nada

    // Sin elegir cómo entran (preinscritos o confirmados) no se puede importar.
    expect(
        t
            .widget<FilledButton>(find.byKey(const Key('csvi-importar')))
            .onPressed,
        isNull);
    await tapKey(t, 'csvi-confirmados');
    await tapKey(t, 'csvi-importar');
    expect(find.byKey(const Key('csvi-resultado')), findsOneWidget);
    expect(find.text('Nuevas personas: 2'), findsOneWidget);
    await tapKey(t, 'csvi-cerrar');
    expect(await _count(t, c), 3);
  });

  testWidgets('importar: cancelar no cambia nada', (t) async {
    final (c, _) = await _open(t,
        pick: csv('$_head\n;;Rosa;Cruz;;Mujer;22;Bautista Ebenezer;;;;;;;;;'));
    await tapKey(t, 'csv-importar');
    await tapKey(t, 'csvi-cancelar');
    expect(await _count(t, c), 1);
  });

  testWidgets('importar: un posible duplicado se omite, y se puede incluir',
      (t) async {
    final (c, _) = await _open(t,
        pick:
            csv('$_head\n;;Juan;Pérez;;Hombre;34;Bautista Ebenezer;;;;;;;;;'));
    await tapKey(t, 'csv-importar');
    expect(find.textContaining('1 posibles duplicados'), findsOneWidget);
    expect(
        t
            .widget<FilledButton>(find.byKey(const Key('csvi-importar')))
            .onPressed,
        isNull); // no hay nada que importar
    await tapKey(t, 'csvi-duplicados');
    expect(find.textContaining('1 persona nueva ·'), findsOneWidget);
    await tapKey(t, 'csvi-confirmados');
    await tapKey(t, 'csvi-importar');
    await tapKey(t, 'csvi-cerrar');
    expect(await _count(t, c), 2);
  });

  testWidgets('importar: un archivo sin las columnas obligatorias se explica',
      (t) async {
    final (c, _) = await _open(t, pick: csv('nombre;edad\nAna;20'));
    await tapKey(t, 'csv-importar');
    expect(find.textContaining('Faltan columnas obligatorias'), findsOneWidget);
    expect(await _count(t, c), 1);
  });

  testWidgets(
      'importar: un CSV guardado en ANSI (tildes en Windows-1252) se lee bien',
      (t) async {
    final ansi = latin1
        .encode('$_head\n;;José;Peña;;Hombre;30;Bautista Ebenezer;;;;;;;;;');
    final (c, _) =
        await _open(t, pick: PickedFile('a.csv', Uint8List.fromList(ansi)));
    await tapKey(t, 'csv-importar');
    await tapKey(t, 'csvi-confirmados');
    await tapKey(t, 'csvi-importar');
    await tapKey(t, 'csvi-cerrar');
    final rows = (await t.runAsync(() => c.db.select(c.db.attendees).get()))!;
    expect(rows.map((r) => r.firstName), contains('José'));
    expect(rows.map((r) => r.lastName1), contains('Peña'));
  });
}
