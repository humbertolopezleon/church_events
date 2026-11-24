import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento/auth/auth_service.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/main.dart';
import 'package:mi_evento/providers.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

Future<T> _sync<T>(T Function() f) async => f();

/// Drift trabaja con async real; el reloj simulado de los widget tests no lo avanza.
/// Este ayudante deja pasar tiempo real y luego redibuja.
Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 4; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
    await t.pump(const Duration(milliseconds: 100));
  }
}

class Ctx {
  Ctx(this.db, this.auth);
  final AppDatabase db;
  final AuthService auth;
}

Future<Ctx> _pump(WidgetTester t, Size size, {bool seedAdmin = false}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final db = AppDatabase(NativeDatabase.memory());
  final auth = AuthService(db,
      hasher: const PasswordHasher(iterations: 1000), runner: _sync);
  if (seedAdmin) {
    await t.runAsync(() => auth.createFirstAdmin(
        username: 'admin', displayName: 'Ana Admin', password: 'secreto1'));
  }
  await t.pumpWidget(ProviderScope(overrides: [
    databaseProvider.overrideWithValue(db),
    authServiceProvider.overrideWithValue(auth)
  ], child: const MiEventoApp()));
  await settle(t);
  addTearDown(() async {
    await t.pumpWidget(
        const SizedBox()); // desmonta: Drift cancela sus streams con un Timer(0)
    await t.pump(const Duration(
        milliseconds: 50)); // ...que el reloj simulado debe ejecutar
    await t.runAsync(
        () => db.close().timeout(const Duration(seconds: 5), onTimeout: () {}));
    await t.pump(const Duration(milliseconds: 50));
  });
  return Ctx(db, auth);
}

Future<void> _login(WidgetTester t, String user, String pass) async {
  await t.enterText(find.byKey(const Key('login-usuario')), user);
  await t.enterText(find.byKey(const Key('login-clave')), pass);
  await t.tap(find.byKey(const Key('login-entrar')));
  await settle(t);
}

/// Al crear un evento primero se configura; estas pruebas terminan la configuración sin definir nada
/// (confirmando el aviso de lo que falta) para llegar al panel.
Future<void> skipSetup(WidgetTester t) async {
  if (find.byKey(const Key('cfg-terminar')).evaluate().isNotEmpty) {
    await t.tap(find.byKey(const Key('cfg-terminar')));
    await settle(t);
    if (find.byKey(const Key('cfg-terminar-igual')).evaluate().isNotEmpty) {
      await t.tap(find.byKey(const Key('cfg-terminar-igual')));
      await settle(t);
    }
  }
}

void main() {
  testWidgets(
      'primer uso: crear administrador, ver código de recuperación y entrar',
      (t) async {
    await _pump(t, const Size(390, 844));
    expect(find.text('Crea el administrador'), findsOneWidget);

    await t.enterText(find.byKey(const Key('setup-nombre')), 'Ana Pérez');
    await t.enterText(find.byKey(const Key('setup-usuario')), 'ana.perez');
    await t.enterText(find.byKey(const Key('setup-clave')), 'secreto1');
    await t.enterText(find.byKey(const Key('setup-clave2')), 'distinta');
    await t.tap(find.byKey(const Key('setup-crear')));
    await settle(t);
    expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);

    await t.enterText(find.byKey(const Key('setup-clave2')), 'secreto1');
    await t.tap(find.byKey(const Key('setup-crear')));
    await settle(t);
    expect(find.byKey(const Key('codigo-recuperacion')), findsOneWidget);

    // «Continuar» está bloqueado hasta confirmar que se guardó el código
    expect(
        t
            .widget<FilledButton>(find.byKey(const Key('setup-continuar')))
            .onPressed,
        isNull);
    await t.tap(find.byKey(const Key('codigo-guardado')));
    await t.pump();
    await t.tap(find.byKey(const Key('setup-continuar')));
    await settle(t);
    expect(find.text('Mis eventos'), findsOneWidget);
  });

  testWidgets('el acceso muestra el logotipo de la marca (móvil y PC)',
      (t) async {
    await _pump(t, const Size(390, 844), seedAdmin: true);
    expect(find.bySemanticsLabel('Logotipo de Mi Evento'), findsOneWidget);
    t.view.physicalSize = const Size(1280, 760);
    await settle(t);
    expect(find.bySemanticsLabel('Logotipo de Mi Evento'), findsOneWidget);
    // panel de marca visible solo en PC
    expect(find.textContaining('sin necesidad de internet'), findsOneWidget);
  });

  testWidgets('login: contraseña errónea muestra error; correcta entra',
      (t) async {
    await _pump(t, const Size(390, 844), seedAdmin: true);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    await _login(t, 'admin', 'mala');
    expect(find.text('Usuario o contraseña incorrectos.'), findsOneWidget);
    expect(find.text('Mis eventos'), findsNothing);
    await _login(t, 'ADMIN', 'secreto1');
    expect(find.text('Mis eventos'), findsOneWidget);
  });

  testWidgets('login: tras 5 fallos avisa de la espera', (t) async {
    await _pump(t, const Size(390, 844), seedAdmin: true);
    for (var i = 0; i < 5; i++) {
      await _login(t, 'admin', 'x$i');
    }
    expect(find.textContaining('Demasiados intentos'), findsOneWidget);
  });

  testWidgets('recuperación desde «Olvidé mi contraseña» con código inválido',
      (t) async {
    await _pump(t, const Size(390, 844), seedAdmin: true);
    await t.tap(find.byKey(const Key('login-olvide')));
    await settle(t);
    await t.enterText(
        find.byKey(const Key('rec-codigo')), 'AAAA-BBBB-CCCC-DDDD');
    await t.enterText(find.byKey(const Key('rec-clave')), 'nueva123');
    await t.tap(find.byKey(const Key('rec-aceptar')));
    await settle(t);
    expect(
        find.text('El código de recuperación no es correcto.'), findsOneWidget);
  });

  testWidgets('móvil: crear evento, panel, barra inferior y cerrar sesión',
      (t) async {
    await _pump(t, const Size(390, 844), seedAdmin: true);
    await _login(t, 'admin', 'secreto1');
    expect(find.textContaining('Todavía no hay eventos'), findsOneWidget);
    await t.tap(find.text('Crear evento'));
    await settle(t);
    await t.tap(find.byKey(const Key('ev-crear')));
    await settle(t);
    expect(find.textContaining('Falta el nombre'), findsOneWidget);
    await t.enterText(find.byKey(const Key('ev-nombre')), 'Retiro de Jóvenes');
    await t.tap(find.byKey(const Key('ev-crear')));
    await settle(t);
    await skipSetup(t);
    expect(find.text('Retiro de Jóvenes'), findsOneWidget);
    expect(find.byKey(const Key('panel-vacio')),
        findsOneWidget); // evento sin asistentes: estado vacío del diseño
    expect(find.byType(NavigationBar), findsOneWidget);

    await t.tap(find.text('Más'));
    await settle(t);
    expect(find.text('Usuarios'), findsOneWidget); // el administrador lo ve
    await t.tap(find.byKey(const Key('cerrar-sesion-movil')));
    await settle(t);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  testWidgets('PC: barra lateral completa para el administrador, con Usuarios',
      (t) async {
    await _pump(t, const Size(1366, 800), seedAdmin: true);
    await _login(t, 'admin', 'secreto1');
    await t.tap(find.text('Crear evento'));
    await settle(t);
    await t.enterText(find.byKey(const Key('ev-nombre')), 'Congreso');
    await t.tap(find.byKey(const Key('ev-crear')));
    await settle(t);
    await skipSetup(t);
    expect(find.byType(NavigationBar), findsNothing);
    for (final l in [
      'Panel',
      'Registrar',
      'Asistentes',
      'Hospedajes',
      'Equipos',
      'Comidas',
      'Reportes',
      'Usuarios'
    ]) {
      expect(find.text(l), findsWidgets);
    }
  });

  testWidgets(
      'el operador NO ve «Usuarios» y el administrador crea al operador desde la app',
      (t) async {
    final c = await _pump(t, const Size(1366, 900), seedAdmin: true);
    await _login(t, 'admin', 'secreto1');
    await t.tap(find.text('Crear evento'));
    await settle(t);
    await t.enterText(find.byKey(const Key('ev-nombre')), 'Congreso');
    await t.tap(find.byKey(const Key('ev-crear')));
    await settle(t);
    await skipSetup(t);

    await t.tap(find.text('Usuarios').first);
    await settle(t);
    await t.tap(find.byKey(const Key('usuario-nuevo')));
    await settle(t);
    await t.enterText(find.byKey(const Key('nu-nombre')), 'Ruth M.');
    await t.enterText(find.byKey(const Key('nu-usuario')), 'ruth');
    await t.enterText(
        find.byKey(const Key('nu-clave')), '123'); // demasiado corta
    await t.tap(find.byKey(const Key('nu-guardar')));
    await settle(t);
    expect(find.textContaining('al menos 6 caracteres'), findsOneWidget);
    await t.enterText(find.byKey(const Key('nu-clave')), 'ruth123');
    await t.tap(find.byKey(const Key('nu-guardar')));
    await settle(t);
    expect(find.textContaining('@ruth'), findsOneWidget);

    await t.tap(find.byKey(const Key('cerrar-sesion')));
    await settle(t);
    await _login(t, 'ruth', 'ruth123');
    await t.tap(find.text('Congreso'));
    await settle(t);
    expect(find.text('Usuarios'), findsNothing);
    expect(find.text('Registrar'), findsWidgets);
    expect(
        (await t.runAsync(() => c.db.select(c.db.appUsers).get()))!.length, 2);
  });
}
