import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento/backup/backup_service.dart';
import 'package:mi_evento/backup/file_picker.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/repos_b.dart';
import 'package:mi_evento/data/repository.dart';
import 'package:mi_evento/export/file_saver.dart';
import 'package:mi_evento/providers.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'helpers.dart';

const _pc = Size(1200, 2400);

class D {
  D(this.c, this.ev, this.saver, this.picker);
  final Ctx c;
  final String ev;
  final MemoryFileSaver saver;
  final MemoryFilePick picker;
}

/// Evento con 4 personas (Juan y María en el equipo Rojo, María hospedada), antes de abrir la interfaz.
Future<D> _open(WidgetTester t,
    {bool operator = false, bool withEvent = true, PickedFile? pick}) async {
  final saver = MemoryFileSaver();
  final picker = MemoryFilePick(pick);
  final c = await pumpApp(t, _pc, operator: operator, overrides: [
    fileSaverProvider.overrideWithValue(saver),
    filePickProvider.overrideWithValue(picker)
  ]);
  late String ev;
  if (withEvent) {
    await t.runAsync(() async {
      ev = await c.repo.createEvent(
          name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
      final ig = await c.repo.createChurch(
          name: 'Bautista Ebenezer',
          province: 'Matanzas',
          municipality: 'Cárdenas');
      for (final (n, s, a) in [
        ('Juan', Sex.male, 34),
        ('María', Sex.female, 27),
        ('Pedro', Sex.male, 40),
        ('Ana', Sex.female, 19)
      ]) {
        await c.repo.addAttendee(
            eventId: ev,
            firstName: n,
            lastName1: 'Pérez',
            sex: s,
            age: a,
            churchId: ig.id,
            phone: '5 123 4567',
            needsLodging: n != 'Pedro');
      }
    });
    final tr = TeamRepo(c.db);
    await t.runAsync(() => tr.createMany(ev, 2));
    final teams = (await t.runAsync(() => c.db.select(c.db.teams).get()))!;
    final rows = (await t.runAsync(() => c.db.select(c.db.attendees).get()))!;
    await t.runAsync(() => tr.setTeam([rows[0].id, rows[1].id], teams[0].id));
    final lod = LodgingRepo(c.db);
    final l = (await t.runAsync(() => lod.save(
        eventId: ev,
        name: 'Casa de Teresa',
        kind: 'private_home',
        capacity: 4,
        accepts: LodgingAccepts.women)))!;
    await t.runAsync(() => lod.assign(l.id, [rows[1].id]));
  }
  await login(
      t, operator ? 'ruth' : 'admin', operator ? 'ruth123' : 'secreto1');
  if (withEvent) {
    await t.tap(find.text('Retiro'));
    await settle(t);
  }
  return D(c, withEvent ? ev : '', saver, picker);
}

Future<void> _goTo(WidgetTester t, String label) async {
  await t.tap(find.text(label).first);
  await settle(t);
}

String _text(WidgetTester t, String key) =>
    t.widget<Text>(find.byKey(Key(key))).data!;

/// Una copia hecha en OTRO dispositivo (base distinta), con o sin contraseña.
Future<Uint8List> _otherDeviceBundle(
    {String name = 'Congreso de Mujeres'}) async {
  final db = AppDatabase(NativeDatabase.memory());
  final repo = Repository(db);
  final ev = await repo.createEvent(
      name: name, startDate: '2027-03-01', endDate: '2027-03-03');
  final ig =
      await repo.createChurch(name: 'Metodista de Colón', province: 'Matanzas');
  for (final n in ['Rosa', 'Elena', 'Marta']) {
    await repo.addAttendee(
        eventId: ev,
        firstName: n,
        lastName1: 'Leyva',
        sex: Sex.female,
        age: 30,
        churchId: ig.id);
  }
  final bytes = await BackupService(db).export(ev);
  await db.close();
  return bytes;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('reportes', () {
    testWidgets('los reportes reflejan los datos reales', (t) async {
      await _open(t);
      await _goTo(t, 'Reportes');
      expect(_text(t, 'rp-total'), '4 inscritos');
      expect(_text(t, 'rp-n-Por sexo-Mujeres'), '2');
      expect(_text(t, 'rp-n-Por sexo-Hombres'), '2');
      expect(_text(t, 'rp-n-Por rango de edad-18–25'), '1'); // Ana
      expect(_text(t, 'rp-n-Por rango de edad-26–40'),
          '3'); // María 27, Juan 34 y Pedro 40
      expect(_text(t, 'rp-n-Por iglesia-Bautista Ebenezer'), '4');
      expect(_text(t, 'rp-n-Por hospedaje-Casa de Teresa'), '1');
      expect(_text(t, 'rp-n-Por hospedaje-Necesitan y sin asignar'),
          '2'); // Juan y Ana
      expect(
          _text(t, 'rp-n-Por hospedaje-No necesitan hospedaje'), '1'); // Pedro
      expect(_text(t, 'rp-n-Por equipo-Rojo'), '2');
      expect(_text(t, 'rp-n-Por equipo-Sin equipo'), '2');
    });

    testWidgets('el listado en CSV NO lleva teléfono salvo que se pida',
        (t) async {
      final x = await _open(t);
      await _goTo(t, 'Reportes');
      await tapKey(t, 'rp-csv');
      var csv = utf8.decode(x.saver.saved.entries
          .firstWhere((e) => e.key.endsWith('.csv'))
          .value);
      expect(csv, contains('Juan Pérez'));
      expect(csv.contains('5 123 4567'), isFalse);
      expect(csv.contains('Teléfono'), isFalse);
      x.saver.saved.clear();
      await tapKey(t, 'rp-telefono');
      await tapKey(t, 'rp-csv');
      csv = utf8.decode(x.saver.saved.entries
          .firstWhere((e) => e.key.endsWith('.csv'))
          .value);
      expect(csv, contains('Teléfono'));
      expect(csv, contains('5 123 4567'));
    });

    testWidgets('Excel con resumen y asistentes; PDF válido', (t) async {
      final x = await _open(t);
      await _goTo(t, 'Reportes');
      await tapKey(t, 'rp-excel');
      await tapKey(t, 'rp-pdf');
      for (var i = 0; i < 5; i++) {
        await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 150)));
        await t.pump();
      }
      final xlsx = x.saver.saved.entries
          .firstWhere((e) => e.key.endsWith('.xlsx'))
          .value;
      final a = ZipDecoder().decodeBytes(xlsx);
      final wb =
          utf8.decode(a.findFile('xl/workbook.xml')!.content as List<int>);
      expect(
          wb, allOf(contains('name="Resumen"'), contains('name="Asistentes"')));
      expect(
          utf8.decode(
              a.findFile('xl/worksheets/sheet2.xml')!.content as List<int>),
          contains('Juan Pérez'));
      final pdf =
          x.saver.saved.entries.firstWhere((e) => e.key.endsWith('.pdf')).value;
      expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
    });
  });

  group('copias de seguridad', () {
    testWidgets(
        'al inicio avisa que no hay copia; guardar crea un CSV válido y cambia el estado',
        (t) async {
      final x = await _open(t);
      await _goTo(t, 'Copias de seguridad');
      expect(
          find.textContaining('Todavía no hay ninguna copia'), findsOneWidget);
      await tapKey(t, 'bk-guardar');
      final name = x.saver.saved.keys.single;
      expect(name, startsWith('retiro-'));
      expect(name, endsWith('.csv'));
      final b = decodeBundle(x.saver.saved[name]!);
      expect(b.manifest.eventName, 'Retiro');
      expect(b.manifest.counts['attendees'], 4);
      expect(
          find.textContaining('Última copia: hace un momento'), findsOneWidget);
    });

    testWidgets(
        'abrir una copia de otro dispositivo: vista previa, confirmar y resultado',
        (t) async {
      final bytes = await _otherDeviceBundle();
      final x = await _open(t, pick: PickedFile('copia.csv', bytes));
      await _goTo(t, 'Copias de seguridad');
      await tapKey(t, 'bk-abrir');
      expect(find.byKey(const Key('imp-vista-previa')), findsOneWidget);
      expect(find.text('Congreso de Mujeres'), findsOneWidget);
      expect(_text(t, 'imp-contenido'), startsWith('3 asistentes'));
      await tapKey(t, 'imp-confirmar');
      expect(find.byKey(const Key('imp-resultado')), findsOneWidget);
      expect(
          find.textContaining('«Congreso de Mujeres» ya está en Mis eventos'),
          findsOneWidget);
      final events =
          (await t.runAsync(() => x.c.db.select(x.c.db.events).get()))!;
      expect(events.map((e) => e.name),
          containsAll(['Retiro', 'Congreso de Mujeres']));
    });

    testWidgets('cancelar en la vista previa no importa nada', (t) async {
      final x = await _open(t,
          pick: PickedFile('copia.csv', await _otherDeviceBundle()));
      await _goTo(t, 'Copias de seguridad');
      await tapKey(t, 'bk-abrir');
      await tapKey(t, 'imp-cancelar');
      expect(
          (await t.runAsync(() => x.c.db.select(x.c.db.events).get()))!.length,
          1);
    });

    testWidgets(
        'un archivo que no es una copia da un mensaje claro y no cambia nada',
        (t) async {
      final x = await _open(t,
          pick: PickedFile('foto.csv',
              Uint8List.fromList(utf8.encode('esto no es una copia'))));
      await _goTo(t, 'Copias de seguridad');
      await tapKey(t, 'bk-abrir');
      expect(find.byKey(const Key('imp-error')), findsOneWidget);
      expect(
          find.textContaining('no es una copia de Mi Evento'), findsOneWidget);
      expect(
          (await t.runAsync(() => x.c.db.select(x.c.db.events).get()))!.length,
          1);
    });

    testWidgets(
        'en un dispositivo SIN eventos se puede abrir una copia desde «Mis eventos»',
        (t) async {
      final bytes = await _otherDeviceBundle();
      await _open(t, withEvent: false, pick: PickedFile('copia.csv', bytes));
      expect(find.byKey(const Key('ev-abrir-copia-vacio')), findsOneWidget);
      await tapKey(t, 'ev-abrir-copia-vacio');
      await tapKey(t, 'imp-confirmar');
      await tapKey(t, 'imp-cifras');
      await t.tap(find.text('Listo'));
      await settle(t);
      expect(find.text('Congreso de Mujeres'), findsOneWidget);
    });

    testWidgets(
        'el operador no ve las copias de seguridad ni «Abrir una copia»',
        (t) async {
      await _open(t, operator: true);
      expect(find.text('Copias de seguridad'),
          findsNothing); // ni en la barra lateral
      expect(find.text('Reportes'), findsWidgets); // pero sí los reportes
      await t.tap(find.text('Mis eventos').first);
      await settle(t);
      expect(find.byKey(const Key('ev-abrir-copia')), findsNothing);
      expect(find.byKey(const Key('evento-menu-Retiro')),
          findsNothing); // ni eliminar eventos
    });

    testWidgets('al cerrar una sesión de comida se guarda sola una copia',
        (t) async {
      final x = await _open(t);
      await _goTo(t, 'Comidas');
      await tapKey(t, 'cm-nueva');
      await tapKey(t, 'ns-crear');
      await tapKey(t, 'cm-cerrar');
      await tapKey(t, 'cm-cerrar-ok');
      for (var i = 0; i < 4; i++) {
        await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 150)));
        await t.pump();
      }
      final copies = x.c.backupDir
          .listSync()
          .whereType<dynamic>()
          .where((f) => f.path.toString().endsWith('.csv'))
          .toList();
      expect(copies, hasLength(1));
    });
  });

  group('panel y eliminación', () {
    testWidgets(
        'el panel avisa si no hay copia y lo marca como bien tras guardarla',
        (t) async {
      await _open(t);
      expect(find.byKey(const Key('panel-copia-aviso')), findsOneWidget);
      await _goTo(t, 'Copias de seguridad');
      await tapKey(t, 'bk-guardar');
      await _goTo(t, 'Panel');
      expect(find.byKey(const Key('panel-copia-ok')), findsOneWidget);
    });

    testWidgets(
        'eliminar un evento: exige escribir su nombre y lo borra de verdad',
        (t) async {
      final x = await _open(t);
      await t.runAsync(() => Repository(x.c.db).createEvent(
          name: 'Otro evento', startDate: '2027-01-01', endDate: '2027-01-02'));
      await t.tap(find.text('Mis eventos').first);
      await settle(t);
      await tapKey(t, 'evento-menu-Retiro');
      await t.tap(find.text('Eliminar evento…'));
      await settle(t);
      expect(find.byKey(const Key('ev-eliminar')), findsOneWidget);
      expect(
          t
              .widget<FilledButton>(find.byKey(const Key('ev-eliminar-ok')))
              .onPressed,
          isNull); // bloqueado
      await enter(t, 'ev-eliminar-nombre', 'otro nombre');
      expect(
          t
              .widget<FilledButton>(find.byKey(const Key('ev-eliminar-ok')))
              .onPressed,
          isNull);
      await enter(t, 'ev-eliminar-nombre', 'retiro');
      expect(
          t
              .widget<FilledButton>(find.byKey(const Key('ev-eliminar-ok')))
              .onPressed,
          isNotNull);
      await tapKey(t, 'ev-eliminar-ok');
      expect(find.byKey(const Key('evento-Retiro')), findsNothing);
      expect(find.byKey(const Key('evento-Otro evento')), findsOneWidget);
      expect((await t.runAsync(() => x.c.db.select(x.c.db.attendees).get()))!,
          isEmpty);
    });
  });
}
