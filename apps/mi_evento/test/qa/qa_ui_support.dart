// Utilidades de QA para las pruebas de interfaz (no es una prueba por sí misma).
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento/auth/auth_service.dart';
import 'package:mi_evento/backup/backup_service.dart';
import 'package:mi_evento/backup/file_picker.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/main.dart';
import 'package:mi_evento/export/file_saver.dart';
import 'package:mi_evento/providers.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import '../helpers.dart';
import 'qa_support.dart';

const qaPc = Size(1200, 2400); // ventana ancha de Windows
const qaMovil = Size(400, 900); // teléfono

/// Pantalla abierta lista para usar.
class QaApp {
  QaApp(this.ctx, this.q, this.saver, this.picker);
  final Ctx ctx;
  final QaEvent q;
  final MemoryFileSaver saver;
  final MemoryFilePick picker;
}

/// Arranca la app, prepara el evento «Congreso QA 2026» ANTES de abrir la interfaz y la deja
/// dentro del evento. [prepare] corre antes de abrir la pantalla (datos, hospedajes, etc.).
Future<QaApp> qaOpen(
  WidgetTester t,
  Size size, {
  bool operator = false,
  int teams = 3,
  bool offersTeams = true,
  bool offersLodging = true,
  bool setupDone = true,
  Future<void> Function(QaEvent q)? prepare,
  String? goTo = 'Registrar',
  PickedFile? pick,
}) async {
  final saver = MemoryFileSaver();
  final picker = MemoryFilePick(pick);
  final c = await pumpApp(t, size, operator: operator, overrides: [
    fileSaverProvider.overrideWithValue(saver),
    filePickProvider.overrideWithValue(picker),
  ]);
  late QaEvent q;
  await t.runAsync(() async {
    q = await qaEvent(c.db,
        teams: offersTeams ? teams : 0,
        offersTeams: offersTeams,
        offersLodging: offersLodging);
    if (!setupDone) await c.repo.setSetupDone(q.eventId, false);
    if (prepare != null) await prepare(q);
  });
  await login(
      t, operator ? 'ruth' : 'admin', operator ? 'ruth123' : 'secreto1');
  await t.tap(find.text('Congreso QA 2026'));
  await settle(t);
  if (goTo == 'Registrar') {
    await goRegister(t);
  } else if (goTo != null) {
    await t.tap(find.text(goTo).first);
    await settle(t);
  }
  return QaApp(c, q, saver, picker);
}

/// Llena el formulario de inscripción (la iglesia se elige de la lista).
Future<void> qaFill(WidgetTester t,
    {required String first,
    required String last1,
    String last2 = '',
    required bool woman,
    required String age,
    int church = 0,
    String phone = '',
    String notes = '',
    bool quick = true}) async {
  final tap = quick ? qaTap : tapKey;
  await enter(t, 'f-nombre', first);
  await enter(t, 'f-apellido1', last1);
  if (last2.isNotEmpty) await enter(t, 'f-apellido2', last2);
  await tap(t, 'f-sexo');
  await t.tap(find.text(woman ? 'F (Mujer)' : 'M (Hombre)').last);
  quick ? await qaQuick(t) : await settle(t);
  await enter(t, 'f-edad', age);
  if (phone.isNotEmpty) await enter(t, 'f-telefono', phone);
  if (notes.isNotEmpty) await enter(t, 'f-observaciones', notes);
  final name = qaChurches[church].$1;
  await enter(t, 'f-iglesia', name.split(' ').first);
  quick ? await qaQuick(t) : await settle(t);
  await tap(t, 'iglesia-${normalizeText(name)}');
}

/// Va a una pantalla; en móvil, si no está en la barra inferior, la busca en «Más».
/// Si el destino no está dibujado porque la barra lateral (que se desplaza) lo deja fuera de la
/// ventana, la desplaza hasta que aparezca, como haría una persona con el dedo o la rueda.
Future<bool> qaScrollMenuTo(WidgetTester t, String label) async {
  if (find.text(label).evaluate().isNotEmpty) return true;
  // El menú es la lista que contiene cualquiera de sus ítems visibles (con el menú desplazado,
  // «Panel» puede no estar construido).
  Finder menu() {
    for (final l in const [
      'Panel',
      'Asistentes',
      'Confirmar asistencia',
      'Hospedajes',
      'Equipos',
      'Comidas',
      'Reportes',
      'Mis eventos'
    ]) {
      final f =
          find.ancestor(of: find.text(l), matching: find.byType(Scrollable));
      if (f.evaluate().isNotEmpty) return f;
    }
    return find.byType(Scrollable).first;
  }

  if (menu().evaluate().isEmpty) return false;
  // Primero hacia abajo y, si no aparece, de vuelta hacia arriba.
  for (final dy in const [-120.0, 120.0]) {
    for (var i = 0; i < 14 && find.text(label).evaluate().isEmpty; i++) {
      await t.drag(menu().first, Offset(0, dy));
      await t.pump();
    }
  }
  return find.text(label).evaluate().isNotEmpty;
}

Future<void> qaGoTo(WidgetTester t, String label) async {
  if (label == 'Registrar') {
    await goRegister(t);
    return;
  }
  await leaveForm(t);
  await qaScrollMenuTo(t, label);
  if (find.text(label).evaluate().isEmpty &&
      find.text('Más').evaluate().isNotEmpty) {
    await t.tap(find.text('Más').first);
    await settle(t);
  }
  await t.tap(find.text(label).first);
  await settle(t);
}

/// Espera corta para ráfagas (menos tiempo de reloj que `settle`; sin transiciones de pantalla).
Future<void> qaQuick(WidgetTester t) async {
  await t
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 25)));
  await t.pump(const Duration(milliseconds: 100));
  await t
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 25)));
  await t.pump(const Duration(milliseconds: 150));
}

Future<void> qaTap(WidgetTester t, String key) async {
  await t.ensureVisible(find.byKey(Key(key)));
  await t.tap(find.byKey(Key(key)));
  await qaQuick(t);
}

Future<List<T>> qaRows<T>(WidgetTester t, Future<List<T>> Function() f) async =>
    (await t.runAsync(f))!;

/// Arranca la app sobre una base YA existente (un «dispositivo»), con el administrador admin/secreto1.
/// Sirve para simular dos dispositivos distintos en una misma prueba: antes de cambiar de
/// dispositivo se debe vaciar la pantalla con `t.pumpWidget(const SizedBox())`.
Future<MemoryFileSaver> qaPumpOn(WidgetTester t, Size size, AppDatabase db,
    {PickedFile? pick}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final auth = AuthService(db,
      hasher: const PasswordHasher(iterations: 1000), runner: syncRunner);
  await t.runAsync(() async {
    if (!await auth.hasUsers()) {
      await auth.createFirstAdmin(
          username: 'admin', displayName: 'Ana Admin', password: 'secreto1');
    }
  });
  final dir = Directory.systemTemp.createTempSync('mievento_qa_copias');
  addTearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });
  final saver = MemoryFileSaver();
  await t.pumpWidget(ProviderScope(overrides: [
    databaseProvider.overrideWithValue(db),
    authServiceProvider.overrideWithValue(auth),
    autoBackupProvider
        .overrideWithValue(AutoBackup(db, directory: () async => dir)),
    fileSaverProvider.overrideWithValue(saver),
    filePickProvider.overrideWithValue(MemoryFilePick(pick)),
  ], child: const MiEventoApp()));
  await settle(t);
  // Al terminar, primero se apaga la pantalla y luego se cierran las bases (orden inverso de registro).
  addTearDown(() async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(milliseconds: 50));
  });
  return saver;
}

/// Cierra la base al terminar la prueba (con tiempo límite, como `pumpApp`), después de apagar la pantalla.
void qaCloseAtEnd(WidgetTester t, AppDatabase db) => addTearDown(() async {
      await t.runAsync(() =>
          db.close().timeout(const Duration(seconds: 5), onTimeout: () {}));
    });

/// Quita la app de la pantalla (apaga «el dispositivo») sin cerrar su base.
Future<void> qaPowerOff(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(milliseconds: 50));
}

/// Toca un botón que puede estar fuera de la pantalla en una lista larga (móvil): desplaza hasta verlo.
Future<void> qaTapScroll(WidgetTester t, String key) async {
  final f = find.byKey(Key(key));
  if (f.evaluate().isEmpty) {
    await t.scrollUntilVisible(f, 200,
        scrollable: find.byType(Scrollable).first, maxScrolls: 30);
  }
  final alto = t.view.physicalSize.height;
  for (var i = 0; i < 30 && t.getCenter(f).dy > alto - 140; i++) {
    await t.drag(find.byType(Scrollable).first, const Offset(0, -250));
    await t.pump();
  }
  await t.tap(f);
  await settle(t);
}
