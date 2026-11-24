// QA · Escenario «Windows → móvil»: DOS bases de datos independientes (dos dispositivos con
// distinto device_id). A (pantalla ancha) prepara el evento y exporta; B (pantalla de móvil) lo
// recibe por CSV y, por separado, por «Abrir una copia»; B sigue trabajando y devuelve a A.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento/backup/backup_service.dart';
import 'package:mi_evento/backup/file_picker.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/meal_repo.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import '../helpers.dart';
import 'qa_support.dart';
import 'qa_ui_support.dart';

/// Dispositivo A listo (antes de abrir la interfaz): evento «Congreso QA 2026», 6 equipos,
/// hospedajes, 120 personas inscritas EN ORDEN, hospedaje aceptado para todos y 3 grupos.
Future<(AppDatabase, QaEvent)> _dispositivoA() async {
  final db = qaDb();
  final q = await qaEvent(db, teams: 6);
  await qaInscribeAll(q, qaPeople(120));
  await qaLodgings(q);
  await qaSuggestAndAccept(q);
  return (db, q);
}

Future<void> _irACopias(WidgetTester t) async {
  await t.tap(find.text('Congreso QA 2026'));
  await settle(t);
  await qaGoTo(t, 'Copias de seguridad');
}

void main() {
  testWidgets(
      'QA-WIN-001 · A (Windows) exporta el CSV de asistentes y el respaldo CSV por la interfaz; B (móvil) importa el CSV y, en otra base, abre la copia: todo coincide con A',
      (t) async {
    final (dbA, qA) = (await t.runAsync(_dispositivoA))!;
    qaCloseAtEnd(t, dbA);
    final filasA = (await t.runAsync(() => qaFilas(qA)))!;
    expect(filasA.length, 120);
    final idA = (await t.runAsync(dbA.deviceId))!;

    // ── A: exporta ──
    final saverA = await qaPumpOn(t, qaPc, dbA);
    await login(t, 'admin', 'secreto1');
    await _irACopias(t);
    await qaTapScroll(t, 'csv-exportar');
    await qaTapScroll(t, 'bk-guardar');
    final csvName =
        saverA.saved.keys.firstWhere((n) => n.startsWith('asistentes-'));
    final bundleName = saverA.saved.keys
        .firstWhere((n) => n.endsWith('.csv') && !n.startsWith('asistentes-'));
    final csvBytes = saverA.saved[csvName]!;
    final bundleBytes = saverA.saved[bundleName]!;
    await qaPowerOff(t);

    // ── B1 (móvil): evento con los mismos hospedajes y equipos ya creados, e importación CSV ──
    final dbB1 = qaDb();
    qaCloseAtEnd(t, dbB1);
    final qB1 = (await t.runAsync(() async {
      final q = await qaEvent(dbB1, teams: 6, groups: const []);
      await qaLodgings(q);
      return q;
    }))!;
    await qaPumpOn(t, qaMovil, dbB1,
        pick: PickedFile('asistentes.csv', csvBytes));
    await login(t, 'admin', 'secreto1');
    await _irACopias(t);
    await qaTapScroll(t, 'csv-importar');
    expect(find.byKey(const Key('csvi-resumen')), findsOneWidget);
    expect(find.textContaining('120 personas nuevas ·'), findsOneWidget);
    await tapKey(t, 'csvi-confirmados');
    await tapKey(t, 'csvi-importar');
    expect(find.text('Nuevas personas: 120'), findsOneWidget);
    await tapKey(t, 'csvi-cerrar');
    expect(t.takeException(), isNull);
    final filasB1 = (await t.runAsync(() => qaFilas(qB1)))!;
    expect(filasB1.length, 120);
    for (var i = 0; i < 120; i++) {
      expect('${filasB1[i]}', '${filasA[i]}',
          reason: 'CSV: persona nº ${i + 1}');
    }
    await qaPowerOff(t);

    // ── B2 (móvil, otra base vacía): «Abrir una copia» (respaldo CSV) ──
    final dbB2 = qaDb();
    qaCloseAtEnd(t, dbB2);
    final idB2 = (await t.runAsync(dbB2.deviceId))!;
    await qaPumpOn(t, qaMovil, dbB2, pick: PickedFile(bundleName, bundleBytes));
    await login(t, 'admin', 'secreto1');
    await tapKey(t, 'ev-abrir-copia-vacio');
    expect(find.byKey(const Key('imp-vista-previa')), findsOneWidget);
    expect(find.text('Congreso QA 2026'), findsOneWidget);
    expect(t.widget<Text>(find.byKey(const Key('imp-contenido'))).data,
        startsWith('120 asistentes'));
    await tapKey(t, 'imp-confirmar');
    await tapKey(t, 'imp-cifras');
    await t.tap(find.text('Listo'));
    await settle(t);
    expect(find.text('Congreso QA 2026'), findsOneWidget);
    final qB2 = QaEvent(dbB2, qA.eventId, const [], const {}, const []);
    final filasB2 = (await t.runAsync(() => qaFilas(qB2)))!;
    expect(filasB2.length, 120);
    for (var i = 0; i < 120; i++) {
      expect('${filasB2[i]}', '${filasA[i]}',
          reason: 'respaldo CSV: persona nº ${i + 1}');
    }
    final lA = (await t.runAsync(qA.lodgingViews))!;
    final lB = (await t.runAsync(qB2.lodgingViews))!;
    expect(
        [for (final l in lB) '${l.row.name}:${l.occupied}/${l.row.capacity}'],
        [for (final l in lA) '${l.row.name}:${l.occupied}/${l.row.capacity}']);
    expect((await t.runAsync(() => qB2.teamRows()))!.map((e) => e.name),
        (await t.runAsync(() => qA.teamRows()))!.map((e) => e.name));
    expect(idB2, isNot(idA));
    expect(t.takeException(), isNull);
  });

  testWidgets(
      'QA-WIN-002 · B (móvil) sigue inscribiendo y marcando comidas, exporta de vuelta y A lo abre: se fusiona sin duplicados',
      (t) async {
    final (dbA, qA) = (await t.runAsync(_dispositivoA))!;
    qaCloseAtEnd(t, dbA);
    // B recibe la copia de A (ya probado en QA-WIN-001): se hace por datos para ir directo al grano.
    final bundleA =
        (await t.runAsync(() => BackupService(dbA).export(qA.eventId)))!;
    final dbB = qaDb();
    qaCloseAtEnd(t, dbB);
    await t.runAsync(() => BackupService(dbB).import(decodeBundle(bundleA)));
    final almuerzo = (await t.runAsync(() async {
      final m = MealRepo(dbB);
      await m.ensureDefaultTypes(qA.eventId);
      final tipo =
          (await m.types(qA.eventId)).firstWhere((x) => x.name == 'Almuerzo');
      return m.createSession(qA.eventId, tipo.id, 'Almuerzo del sábado',
          operatorName: 'Ruth');
    }))!;
    // Las personas nº 1–40 ya pasaron por el almuerzo en B (antes de abrir la pantalla).
    final idsPrimeros = (await t.runAsync(() async {
      final l =
          await QaEvent(dbB, qA.eventId, const [], const {}, const []).people();
      l.sort((a, b) => a.regNumber.compareTo(b.regNumber));
      return l.take(40).map((p) => p.id).toList();
    }))!;
    await t.runAsync(() async {
      for (final id in idsPrimeros) {
        await MealRepo(dbB).mark(almuerzo.id, id, operatorName: 'Ruth');
      }
    });

    // ── B (móvil) por la interfaz: inscribe a 2 personas y marca a otra por número ──
    final saverB = await qaPumpOn(t, qaMovil, dbB);
    await login(t, 'admin', 'secreto1');
    await t.tap(find.text('Congreso QA 2026'));
    await settle(t);
    await qaGoTo(t, 'Registrar');
    await qaFill(t,
        first: 'Nueva',
        last1: 'Desde-Móvil',
        woman: true,
        age: '29',
        church: 3);
    await tapKey(t, 'f-guardar-otro');
    await qaFill(t,
        first: 'Segundo',
        last1: 'Desde-Móvil',
        woman: false,
        age: '41',
        church: 4);
    await tapKey(t, 'f-guardar');
    expect(find.byKey(const Key('exito-numero')), findsOneWidget);
    await qaGoTo(t, 'Comidas');
    if (find.byKey(const Key('cm-buscar')).evaluate().isEmpty) {
      await t.tap(find.textContaining('Almuerzo del sábado').first);
      await settle(t);
    }
    await t.enterText(find.byKey(const Key('cm-buscar')), '77');
    await settle(t);
    await t.testTextInput.receiveAction(TextInputAction.done);
    await settle(t);
    await qaGoTo(t, 'Copias de seguridad');
    await qaTapScroll(t, 'bk-guardar');
    final bundleB =
        saverB.saved.entries.firstWhere((e) => e.key.endsWith('.csv')).value;
    await qaPowerOff(t);

    final nuevos = (await t.runAsync(() async {
      final l =
          await QaEvent(dbB, qA.eventId, const [], const {}, const []).people();
      return l.where((p) => p.lastName1 == 'Desde-Móvil').toList()
        ..sort((a, b) => a.regNumber.compareTo(b.regNumber));
    }))!;
    expect(nuevos.map((p) => p.regNumber), [121, 122]);
    expect(nuevos.every((p) => p.teamId != null), isTrue,
        reason: 'equipo automático en el móvil');

    // ── A (Windows) abre la copia de B por la interfaz ──
    await qaPumpOn(t, qaPc, dbA, pick: PickedFile('de-movil.csv', bundleB));
    await login(t, 'admin', 'secreto1');
    await _irACopias(t);
    await qaTapScroll(t, 'bk-abrir');
    expect(find.byKey(const Key('imp-vista-previa')), findsOneWidget);
    await tapKey(t, 'imp-confirmar');
    expect(find.byKey(const Key('imp-resultado')), findsOneWidget);
    final cifras = t.widget<Text>(find.byKey(const Key('imp-cifras'))).data!;
    await t.tap(find.text('Listo'));
    await settle(t);
    // Se agregan 2 personas + 2 grupos de filas de comida (tipos) + sesión + 41 marcas; nada se duplica.
    final todosA = (await t.runAsync(qA.people))!;
    expect(todosA.length, 122, reason: cifras);
    expect(todosA.map((p) => p.regNumber).toSet().length, 122);
    expect(
        (await t.runAsync(() => dbA.select(dbA.controlSessions).get()))!.length,
        1);
    expect(
        (await t.runAsync(() => dbA.select(dbA.controlRecords).get()))!.length,
        41);
    expect((await t.runAsync(() => dbA.select(dbA.events).get()))!.length, 1);
    expect((await t.runAsync(() => dbA.select(dbA.teams).get()))!.length, 6);
    expect(
        (await t.runAsync(() => dbA.select(dbA.lodgings).get()))!.length, 11);
    // Lo ya existente no cambió: la parte de las 120 sigue igual.
    final filasA = (await t.runAsync(() => qaFilas(qA)))!;
    expect(filasA.take(120).map((f) => f.nombre).toSet().length, 120);
    // Y si B vuelve a mandar la misma copia, nada cambia (con la pantalla apagada: sin consultas vivas).
    await qaPowerOff(t);
    final dup = (await t
        .runAsync(() => BackupService(dbA).import(decodeBundle(bundleB))))!;
    expect(dup.inserted + dup.updated, 0);
    expect(t.takeException(), isNull);
  });
}
