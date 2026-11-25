import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento/backup/file_picker.dart';
import 'package:mi_evento/data/church_exchange.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/repository.dart';
import 'package:mi_evento/export/file_saver.dart';
import 'package:mi_evento/providers.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'helpers.dart';

void main() {
  group('iglesias (datos)', () {
    late AppDatabase db;
    late Repository repo;
    late String ev;
    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repo = Repository(db);
      ev = await repo.createEvent(
          name: 'E', startDate: '2026-01-01', endDate: '2026-01-02');
    });
    tearDown(() => db.close());

    test('editar cambia nombre y ubicación y se la lleva a sus asistentes',
        () async {
      final c = await repo.createChurch(
          name: 'Bautista', province: 'Matanzas', municipality: 'Cárdenas');
      final a = await repo.addAttendee(
          eventId: ev,
          firstName: 'Ana',
          lastName1: 'X',
          sex: Sex.female,
          age: 30,
          churchId: c.id,
          province: 'Matanzas',
          municipality: 'Cárdenas');
      final u = await repo.updateChurch(c.id,
          name: 'Bautista Ebenezer',
          province: 'Matanzas',
          municipality: 'Colón',
          community: 'Los Arabos');
      expect(u.name, 'Bautista Ebenezer');
      expect(u.municipality, 'Colón');
      final r = (await repo.attendeeById(a.id))!;
      expect(r.municipality, 'Colón');
    });

    test('editar valida obligatorios y duplicados', () async {
      final a = await repo.createChurch(
          name: 'A', province: 'Matanzas', municipality: 'Cárdenas');
      await repo.createChurch(
          name: 'B', province: 'Matanzas', municipality: 'Cárdenas');
      await expectLater(
          repo.updateChurch(a.id,
              name: 'B', province: 'Matanzas', municipality: 'Cárdenas'),
          throwsA(isA<DataException>()));
      await expectLater(
          repo.updateChurch(a.id, name: 'A', province: '', municipality: 'X'),
          throwsA(isA<DataException>()));
    });

    test(
        'eliminar: se bloquea con asistentes (dice cuántos); sin ellos es lógico',
        () async {
      final c = await repo.createChurch(
          name: 'Bautista', province: 'Matanzas', municipality: 'Cárdenas');
      final a = await repo.addAttendee(
          eventId: ev,
          firstName: 'Ana',
          lastName1: 'X',
          sex: Sex.female,
          age: 30,
          churchId: c.id);
      await expectLater(
          repo.deleteChurch(c.id),
          throwsA(isA<DataException>()
              .having((e) => e.message, 'msg', contains('1 asistente'))));
      expect((await repo.churchAttendeeCounts())[c.id], 1);
      await repo.deleteAttendee(a.id, isAdmin: true);
      await repo.deleteChurch(c.id);
      final rows = await db.select(db.churches).get();
      expect(rows.single.deletedAt, isNotNull);
    });

    test(
        'CSV: exporta, y al importar crea, actualiza comunidad y avisa de filas malas',
        () async {
      await repo.createChurch(
          name: 'Bautista', province: 'Matanzas', municipality: 'Cárdenas');
      final ex = ChurchExchange(db);
      final csv = buildCsvDelimited([
        ChurchExchange.headers,
        ['Bautista', 'Matanzas', 'Cárdenas', 'Varadero'], // actualiza comunidad
        ['Metodista', 'La Habana', 'Plaza de la Revolución', ''], // nueva
        ['Metodista', 'la habana', 'Plaza de la Revolución', ''], // repetida
        ['Sin provincia', 'Narnia', 'X', ''],
        ['', 'Matanzas', 'Colón', ''],
      ]);
      final pre = await ex.preview(csv);
      expect(pre.work, 2);
      expect(pre.warnings, hasLength(3));
      expect((await db.select(db.churches).get()),
          hasLength(1)); // preview no escribe
      await ex.apply(csv);
      final rows = await db.select(db.churches).get();
      expect(rows, hasLength(2));
      expect(
          rows.firstWhere((c) => c.name == 'Bautista').community, 'Varadero');
      final out = ChurchExchange.toRows(rows);
      expect(out.first, ChurchExchange.headers);
      expect(out, hasLength(3));
    });
  });

  testWidgets('vista Iglesias: buscar, exportar, importar, editar y eliminar',
      (t) async {
    final saver = MemoryFileSaver();
    final picker = MemoryFilePick();
    final c = await pumpApp(t, const Size(1200, 2400), overrides: [
      fileSaverProvider.overrideWithValue(saver),
      filePickProvider.overrideWithValue(picker),
    ]);
    await t.runAsync(() async {
      final ev = await c.repo.createEvent(
          name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
      final a = await c.repo.createChurch(
          name: 'Bautista', province: 'Matanzas', municipality: 'Cárdenas');
      await c.repo.createChurch(
          name: 'Metodista', province: 'Matanzas', municipality: 'Colón');
      await c.repo.addAttendee(
          eventId: ev,
          firstName: 'Ana',
          lastName1: 'X',
          sex: Sex.female,
          age: 30,
          churchId: a.id);
    });
    await login(t, 'admin', 'secreto1');
    await t.tap(find.text('Retiro'));
    await settle(t);
    await t.tap(find.text('Iglesias').first);
    await settle(t);
    expect(find.text('2 iglesias'), findsOneWidget);

    await t.enterText(find.byKey(const Key('ig-buscar')), 'metod');
    await settle(t);
    expect(find.text('1 de 2 · orden alfabético'), findsOneWidget);
    await tapKey(t, 'ig-exportar');
    final rows = parseCsv(utf8.decode(saver.saved.values.first));
    expect(rows.first, ChurchExchange.headers);
    expect(rows, hasLength(2));
    await t.enterText(find.byKey(const Key('ig-buscar')), '');
    await settle(t);

    // Importar
    picker.file = PickedFile(
        'iglesias.csv',
        Uint8List.fromList(utf8.encode(buildCsvDelimited([
          ChurchExchange.headers,
          ['Pentecostal', 'Camagüey', 'Camagüey', 'Reparto Lenin'],
        ]))));
    await tapKey(t, 'ig-importar');
    expect(find.byKey(const Key('ti-revision')), findsOneWidget);
    expect(find.text('Iglesias nuevas: 1'), findsOneWidget);
    await tapKey(t, 'ti-importar');
    expect(find.byKey(const Key('ti-resultado')), findsOneWidget);
    await t.tap(find.text('Aceptar'));
    await settle(t);
    expect(find.text('3 iglesias'), findsOneWidget);

    // Eliminar la que tiene asistentes: bloqueo con cantidad.
    await tapKey(t, 'ig-menu-Bautista');
    await tapKey(t, 'ig-eliminar');
    expect(find.byKey(const Key('ig-no-eliminar')), findsOneWidget);
    expect(find.textContaining('1 asistente'), findsOneWidget);
    await t.tap(find.text('Entendido'));
    await settle(t);

    // Eliminar una sin asistentes.
    await tapKey(t, 'ig-menu-Metodista');
    await tapKey(t, 'ig-eliminar');
    await tapKey(t, 'ig-confirmar-eliminar');
    expect(find.text('2 iglesias'), findsOneWidget);
  });
}
