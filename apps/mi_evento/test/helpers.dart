import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento/auth/auth_service.dart';
import 'package:mi_evento/backup/backup_service.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/repository.dart';
import 'package:mi_evento/main.dart';
import 'package:mi_evento/ui/attendee_form.dart';
import 'package:mi_evento/providers.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

Future<T> syncRunner<T>(T Function() f) async => f();

/// Drift trabaja con async real; el reloj simulado de los widget tests no lo avanza.
Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 4; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
    await t.pump(const Duration(milliseconds: 100));
  }
  await t.pump(const Duration(
      milliseconds: 500)); // deja terminar las transiciones de pantalla
}

class Ctx {
  Ctx(this.db, this.auth, this.repo, this.backupDir);
  final Directory backupDir;
  final AppDatabase db;
  final AuthService auth;
  final Repository repo;
}

/// Arranca la app con base en memoria, un administrador (admin/secreto1) y, opcionalmente,
/// un operador (ruth/ruth123).
Future<Ctx> pumpApp(WidgetTester t, Size size,
    {bool operator = false,
    bool defaultAdmin = false,
    List<Override> overrides = const []}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final db = AppDatabase(NativeDatabase.memory());
  final auth = AuthService(db,
      hasher: const PasswordHasher(iterations: 1000), runner: syncRunner);
  await t.runAsync(() async {
    if (defaultAdmin) {
      await auth
          .ensureDefaultAdmin(); // como la primera apertura real: admin / admin
      return;
    }
    await auth.createFirstAdmin(
        username: 'admin', displayName: 'Ana Admin', password: 'secreto1');
    if (operator) {
      final a = (await auth.login('admin', 'secreto1')).user!;
      await auth.createUser(a,
          username: 'ruth', displayName: 'Ruth M.', password: 'ruth123');
    }
  });
  // Las copias automáticas van a una carpeta temporal (nunca a la del sistema).
  final backupDir = Directory.systemTemp.createTempSync('mievento_test_copias');
  addTearDown(() {
    if (backupDir.existsSync()) backupDir.deleteSync(recursive: true);
  });
  final ctx = Ctx(db, auth, Repository(db), backupDir);
  await t.pumpWidget(ProviderScope(overrides: [
    databaseProvider.overrideWithValue(db),
    authServiceProvider.overrideWithValue(auth),
    autoBackupProvider
        .overrideWithValue(AutoBackup(db, directory: () async => backupDir)),
    ...overrides,
  ], child: const MiEventoApp()));
  await settle(t);
  addTearDown(() async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(milliseconds: 50));
    await t.runAsync(
        () => db.close().timeout(const Duration(seconds: 5), onTimeout: () {}));
    await t.pump(const Duration(milliseconds: 50));
  });
  return ctx;
}

Future<void> login(WidgetTester t, String user, String pass) async {
  await t.enterText(find.byKey(const Key('login-usuario')), user);
  await t.enterText(find.byKey(const Key('login-clave')), pass);
  await t.tap(find.byKey(const Key('login-entrar')));
  await settle(t);
}

Future<void> tapKey(WidgetTester t, String key) async {
  // Importar/Exportar CSV viven en el menú ⋮ de la cabecera: si la clave no está a la vista y hay
  // menú, se abre primero.
  if (find.byKey(Key(key)).evaluate().isEmpty &&
      find.byKey(const Key('menu-csv')).evaluate().isNotEmpty) {
    await t.tap(find.byKey(const Key('menu-csv')));
    await settle(t);
  }
  await t.ensureVisible(find.byKey(Key(key)));
  await t.pump(); // la lista perezosa termina de colocarse antes de tocar
  await t.tap(find.byKey(Key(key)));
  await settle(t);
}

Future<void> enter(WidgetTester t, String key, String text) async {
  await t.ensureVisible(find.byKey(Key(key)));
  await t.enterText(find.byKey(Key(key)), text);
  await t.pump();
}

/// Elige el sexo en la lista desplegable del formulario de registro.
Future<void> pickSex(WidgetTester t, {required bool woman}) async {
  await tapKey(t, 'f-sexo');
  await t.tap(find.text(woman ? 'F (Mujer)' : 'M (Hombre)').last);
  await settle(t);
}

/// Elige municipio en la lista desplegable del diálogo «Iglesia nueva» (la provincia ya elegida).
Future<void> pickMunicipio(WidgetTester t, String name) async {
  await t.tap(find.byType(DropdownButtonFormField<String>).at(1));
  await settle(t);
  await t.tap(find.text(name).last);
  await settle(t);
}

/// Abre el formulario de registro: «Asistentes» → botón «Registrar persona».
Future<void> goRegister(WidgetTester t) async {
  await leaveForm(t);
  await t.tap(find.text('Asistentes').first);
  await settle(t);
  await tapKey(t, 'asis-registrar');
}

/// Si el formulario de registro/ficha está abierto encima de la navegación, vuelve a ella.
Future<void> leaveForm(WidgetTester t) async {
  if (find.byType(AttendeeFormScreen).evaluate().isEmpty) return;
  t
      .state<NavigatorState>(find.byType(Navigator).first)
      .popUntil((r) => r.isFirst);
  await settle(t);
}

/// Abre la hoja de filtros de la lista (botón «Filtros» junto al buscador).
Future<void> openFilters(WidgetTester t) async {
  await t.tap(find.byKey(const Key('filtros-toggle')));
  await settle(t);
}

/// Cierra la hoja de filtros con «Ver N …».
Future<void> closeFilters(WidgetTester t) async {
  await t.tap(find.byKey(const Key('filtros-ver')));
  await settle(t);
}
