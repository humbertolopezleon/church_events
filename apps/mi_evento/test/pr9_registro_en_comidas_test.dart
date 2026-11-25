// Registrar a una persona nueva desde el control de comidas, con marca visible.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento/backup/backup_service.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/repository.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'helpers.dart';

const _pc = Size(1200, 2400);

Future<Ctx> _open(WidgetTester t) async {
  final c = await pumpApp(t, _pc);
  await t.runAsync(() async {
    final ev = await c.repo.createEvent(
        name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
    await c.repo.createChurch(
        name: 'Bautista', province: 'Matanzas', municipality: 'Cárdenas');
    await c.repo.addAttendee(
        eventId: ev,
        firstName: 'Ana',
        lastName1: 'Pérez',
        sex: Sex.female,
        age: 30);
  });
  await login(t, 'admin', 'secreto1');
  await t.tap(find.text('Retiro'));
  await settle(t);
  await t.tap(find.text('Comidas').first);
  await settle(t);
  await tapKey(t, 'cm-nueva');
  await tapKey(t, 'ns-crear');
  return c;
}

Future<List<AttendeeRow>> _people(WidgetTester t, Ctx c) async =>
    (await t.runAsync(() => c.db.select(c.db.attendees).get()))!;

void main() {
  testWidgets(
      'buscar a alguien que no está: se registra con lo mínimo, queda confirmada, marcada y con marca visible',
      (t) async {
    final c = await _open(t);
    await enter(t, 'cm-buscar', 'zoe gomez');
    expect(find.byKey(const Key('cm-registrar-vacio')), findsOneWidget);
    await tapKey(t, 'cm-registrar-vacio');
    // Adelanta nombre y apellido con lo que se buscaba.
    String v(String k) =>
        t.widget<TextField>(find.byKey(Key(k))).controller!.text;
    expect(v('qr-nombre'), 'zoe');
    expect(v('qr-apellido1'), 'gomez');
    await enter(t, 'qr-nombre', 'Zoe');
    await enter(t, 'qr-apellido1', 'Gómez');
    await tapKey(t, 'qr-mujer');
    await enter(t, 'qr-edad', '25');
    await tapKey(t, 'qr-guardar');
    await settle(t);
    expect(find.byKey(const Key('cm-ok')), findsOneWidget);
    expect(find.textContaining('Registrado y marcado'), findsOneWidget);
    final zoe = (await _people(t, c)).firstWhere((p) => p.firstName == 'Zoe');
    expect(zoe.registeredAtControl, isTrue);
    expect(zoe.status, 'confirmed');
    expect(zoe.regNumber, 2);
    final recs =
        (await t.runAsync(() => c.db.select(c.db.controlRecords).get()))!;
    expect(recs.single.attendeeId, zoe.id);
    // En «Últimos en pasar» se ve la marca.
    expect(find.textContaining('registrado en el control'), findsOneWidget);
    // Las demás personas no llevan la marca.
    expect((await _people(t, c)).where((p) => p.registeredAtControl).length, 1);
  });

  testWidgets('faltan datos: se explica y no se crea a nadie', (t) async {
    final c = await _open(t);
    await tapKey(t, 'cm-registrar');
    await enter(t, 'qr-nombre', 'Luis');
    await enter(t, 'qr-apellido1', 'Rey');
    await tapKey(t, 'qr-guardar');
    expect(find.text('Falta elegir si es hombre o mujer.'), findsOneWidget);
    await tapKey(t, 'qr-hombre');
    await tapKey(t, 'qr-guardar');
    expect(find.text('Falta la edad (un número).'), findsOneWidget);
    expect((await _people(t, c)).length, 1);
    await tapKey(t, 'qr-cancelar');
    expect(find.byKey(const Key('qr-nombre')), findsNothing);
  });

  testWidgets(
      'si ya existe alguien igual, avisa y deja cancelar o registrar igual',
      (t) async {
    final c = await _open(t);
    await tapKey(t, 'cm-registrar');
    await enter(t, 'qr-nombre', 'Ana');
    await enter(t, 'qr-apellido1', 'Perez');
    await tapKey(t, 'qr-mujer');
    await enter(t, 'qr-edad', '30');
    await tapKey(t, 'qr-guardar');
    expect(find.byKey(const Key('qr-duplicado')), findsOneWidget);
    await tapKey(t, 'qr-dup-cancelar');
    expect((await _people(t, c)).length, 1);
    await tapKey(t, 'qr-guardar');
    await tapKey(t, 'qr-dup-guardar');
    await settle(t);
    final all = await _people(t, c);
    expect(all.length, 2);
    expect(all.where((p) => p.registeredAtControl).length, 1);
  });

  testWidgets('en Asistentes se ve «Registrado en comidas»', (t) async {
    final c = await _open(t);
    await tapKey(t, 'cm-registrar');
    await enter(t, 'qr-nombre', 'Zoe');
    await enter(t, 'qr-apellido1', 'Gómez');
    await tapKey(t, 'qr-mujer');
    await enter(t, 'qr-edad', '25');
    await tapKey(t, 'qr-guardar');
    await settle(t);
    expect((await _people(t, c)).length, 2);
    await t.tap(find.text('Asistentes').first);
    await settle(t);
    expect(find.byKey(const Key('reg-control-2')), findsOneWidget);
    expect(find.byKey(const Key('reg-control-1')), findsNothing);
  });

  group('copias de seguridad', () {
    test(
        'una copia anterior a la v10 (sin «registeredAtControl») se restaura con la marca en falso',
        () async {
      final src = AppDatabase(NativeDatabase.memory());
      final dst = AppDatabase(NativeDatabase.memory());
      addTearDown(src.close);
      addTearDown(dst.close);
      final repo = Repository(src);
      final ev = await repo.createEvent(
          name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
      await repo.addAttendee(
          eventId: ev,
          firstName: 'Ana',
          lastName1: 'Pérez',
          sex: Sex.female,
          age: 30);
      await repo.addAttendee(
          eventId: ev,
          firstName: 'Zoe',
          lastName1: 'Gómez',
          sex: Sex.female,
          age: 25,
          registeredAtControl: true);
      final bytes = await BackupService(src).export(ev);
      // Copia nueva: la marca viaja y se restaura.
      await BackupService(dst).import(decodeBundle(bytes));
      final r1 = await dst.select(dst.attendees).get();
      expect({for (final p in r1) p.firstName: p.registeredAtControl},
          {'Ana': false, 'Zoe': true});
      // Copia antigua: se le quita la columna a la tabla de asistentes.
      final b = decodeBundle(bytes);
      final old = Bundle(b.manifest, {
        for (final e in b.tables.entries)
          e.key: [
            for (final row in e.value)
              {
                for (final c in row.entries)
                  if (!(e.key == 'attendees' && c.key == 'registeredAtControl'))
                    c.key: c.value
              }
          ]
      });
      final dst2 = AppDatabase(NativeDatabase.memory());
      addTearDown(dst2.close);
      await BackupService(dst2).import(old);
      final r2 = await dst2.select(dst2.attendees).get();
      expect(r2.length, 2);
      expect(r2.every((p) => !p.registeredAtControl), isTrue);
    });
  });
}
