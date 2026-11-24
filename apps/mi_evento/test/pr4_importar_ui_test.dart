import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento/backup/file_picker.dart';
import 'package:mi_evento/data/event_exchange.dart';
import 'package:mi_evento/data/lodging_exchange.dart';
import 'package:mi_evento/data/repos_b.dart';
import 'package:mi_evento/data/users_exchange.dart';
import 'package:mi_evento/export/file_saver.dart';
import 'package:mi_evento/providers.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'helpers.dart';

PickedFile _csv(List<List<String>> rows) => PickedFile(
    'a.csv', Uint8List.fromList(utf8.encode(buildCsvDelimited(rows))));

void main() {
  testWidgets(
      'REGLA: donde hay «Exportar CSV» también hay «Importar CSV» (Asistentes, Hospedajes, Equipos, Confirmar asistencia, Iglesias, Usuarios)',
      (t) async {
    final c = await pumpApp(t, const Size(1200, 2400), overrides: [
      fileSaverProvider.overrideWithValue(MemoryFileSaver()),
      filePickProvider.overrideWithValue(MemoryFilePick()),
    ]);
    await t.runAsync(() async {
      final ev = await c.repo.createEvent(
          name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
      final ch = await c.repo.createChurch(
          name: 'Bautista', province: 'Matanzas', municipality: 'Cárdenas');
      await c.repo.addAttendee(
          eventId: ev,
          firstName: 'Ana',
          lastName1: 'X',
          sex: Sex.female,
          age: 30,
          churchId: ch.id,
          preregistered: true);
      await LodgingRepo(c.db).save(
          eventId: ev,
          name: 'Casa',
          kind: 'shelter',
          capacity: 3,
          accepts: LodgingAccepts.any);
      await TeamRepo(c.db).createMany(ev, 1);
    });
    await login(t, 'admin', 'secreto1');
    // Antes de abrir un evento: Mis eventos.
    expect(find.byKey(const Key('ev-exportar')), findsOneWidget);
    expect(find.byKey(const Key('ev-importar')), findsOneWidget);
    await t.tap(find.text('Retiro'));
    await settle(t);
    final pairs = {
      'Asistentes': ('exportar-csv', 'asis-importar'),
      'Hospedajes': ('hosp-exportar', 'hosp-importar'),
      'Equipos': ('eq-exportar', 'eq-importar'),
      'Confirmar asistencia': ('ca-exportar', 'ca-importar'),
      'Iglesias': ('ig-exportar', 'ig-importar'),
      'Usuarios': ('usr-exportar', 'usr-importar'),
    };
    for (final e in pairs.entries) {
      await t.tap(find.text(e.key).first);
      await settle(t);
      expect(find.byKey(Key(e.value.$1)), findsOneWidget,
          reason: '${e.key} exporta');
      expect(find.byKey(Key(e.value.$2)), findsOneWidget,
          reason: '${e.key} debe poder importar');
    }
  });

  testWidgets(
      'Hospedajes: importar desde un evento vacío (revisión → importar)',
      (t) async {
    final picker = MemoryFilePick();
    final c = await pumpApp(t, const Size(1200, 2400), overrides: [
      filePickProvider.overrideWithValue(picker),
    ]);
    await t.runAsync(() async {
      await c.repo.createEvent(
          name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
    });
    await login(t, 'admin', 'secreto1');
    await t.tap(find.text('Retiro'));
    await settle(t);
    await t.tap(find.text('Hospedajes').first);
    await settle(t);
    picker.file = _csv([
      LodgingExchange.headers,
      [
        'Casa Sur',
        'Casa particular',
        'Matrimonios',
        '2',
        '',
        '',
        'Rita',
        '',
        '',
        ''
      ],
      ['Mala', 'Albergue', 'Nadie', '2', '', '', '', '', '', ''],
    ]);
    await tapKey(t, 'hosp-importar-vacio');
    expect(find.text('Hospedajes nuevos: 1'), findsOneWidget);
    expect(find.textContaining('1 fila no se importará'), findsOneWidget);
    await tapKey(t, 'ti-importar');
    await t.tap(find.text('Aceptar'));
    await settle(t);
    expect(find.byKey(const Key('hosp-Casa Sur')), findsOneWidget);
  });

  testWidgets('Mis eventos: importar eventos', (t) async {
    final picker = MemoryFilePick();
    final c = await pumpApp(t, const Size(1200, 2400), overrides: [
      filePickProvider.overrideWithValue(picker),
    ]);
    await login(t, 'admin', 'secreto1');
    expect(c.db, isNotNull);
    picker.file = _csv([
      EventExchange.headers,
      ['Congreso', '2027-01-10', '2027-01-12', 'Templo', 'Ana', 'Sí', 'No'],
    ]);
    await tapKey(t, 'ev-importar-vacio');
    expect(find.text('Eventos nuevos: 1'), findsOneWidget);
    await tapKey(t, 'ti-importar');
    await t.tap(find.text('Aceptar'));
    await settle(t);
    expect(find.text('Congreso'), findsOneWidget);
  });

  testWidgets(
      'Usuarios: importar crea cuentas con contraseña temporal y obliga a cambiarla al entrar',
      (t) async {
    final picker = MemoryFilePick();
    final c = await pumpApp(t, const Size(1200, 2400), overrides: [
      filePickProvider.overrideWithValue(picker),
    ]);
    await t.runAsync(() async {
      await c.repo.createEvent(
          name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
    });
    await login(t, 'admin', 'secreto1');
    await t.tap(find.text('Retiro'));
    await settle(t);
    await t.tap(find.text('Usuarios').first);
    await settle(t);
    picker.file = _csv([
      UsersExchange.headers,
      ['marta', 'Marta Gil', 'Operador', 'Activo'],
      ['admin', 'Otro', 'Operador', ''], // ya existe
    ]);
    await tapKey(t, 'usr-importar');
    expect(find.text('Usuarios nuevos: 1'), findsOneWidget);
    await tapKey(t, 'ti-importar');
    final shown = find.byKey(const Key('ti-resultado'));
    expect(shown, findsOneWidget);
    final line = t
        .widgetList<SelectableText>(find.byType(SelectableText))
        .map((w) => w.data ?? '')
        .firstWhere((s) => s.contains('marta  →  '));
    final pass = RegExp(r'marta  →  (\S+)').firstMatch(line)!.group(1)!;
    await t.tap(find.text('Aceptar'));
    await settle(t);
    // Sale y entra como marta con la temporal: debe cambiarla.
    await t.tap(find.text('Cerrar sesión').first);
    await settle(t);
    await login(t, 'marta', pass);
    expect(find.byKey(const Key('fp-aviso')), findsOneWidget);
    await t.enterText(find.byKey(const Key('fp-actual')), pass);
    await t.enterText(
        find.byKey(const Key('fp-nueva')), pass); // igual: rechazada
    await tapKey(t, 'fp-guardar');
    expect(find.textContaining('distinta'), findsOneWidget);
    await t.enterText(find.byKey(const Key('fp-nueva')), 'MiClaveNueva9');
    await tapKey(t, 'fp-guardar');
    expect(find.byKey(const Key('fp-aviso')), findsNothing);
  });
}
