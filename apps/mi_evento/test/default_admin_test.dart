import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento/auth/auth_service.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'helpers.dart';

void main() {
  group('administrador inicial', () {
    late AppDatabase db;
    late AuthService auth;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      auth = AuthService(db,
          hasher: const PasswordHasher(iterations: 1000), runner: syncRunner);
    });
    tearDown(() => db.close());

    test('se crea solo si no hay usuarios y entra con admin / admin', () async {
      expect(await auth.ensureDefaultAdmin(), isTrue);
      expect(await auth.ensureDefaultAdmin(), isFalse); // no se repite
      final r = await auth.login('admin', 'admin');
      expect(r.ok, isTrue);
      expect(r.user!.isAdmin, isTrue);
      expect(await auth.hasUsers(), isTrue);
    });

    test(
        'se detecta que sigue con la contraseña inicial y deja de detectarse al cambiarla',
        () async {
      await auth.ensureDefaultAdmin();
      expect(await auth.defaultAdminUsesDefaultPassword(), isTrue);
      final u = (await auth.login('admin', 'admin')).user!;
      await auth.changeOwnPassword(u, 'admin', 'secreto1');
      expect(await auth.defaultAdminUsesDefaultPassword(), isFalse);
      expect((await auth.login('admin', 'admin')).ok, isFalse);
      expect((await auth.login('admin', 'secreto1')).ok, isTrue);
    });

    test('el administrador inicial puede añadir otros administradores',
        () async {
      await auth.ensureDefaultAdmin();
      final admin = (await auth.login('admin', 'admin')).user!;
      final b = await auth.createUser(admin,
          username: 'carlos',
          displayName: 'Carlos',
          password: 'clave-larga-1',
          admin: true);
      expect(b.isAdmin, isTrue);
    });

    test('no se crea si ya hay un administrador propio', () async {
      await auth.createFirstAdmin(
          username: 'ana', displayName: 'Ana', password: 'secreto1');
      expect(await auth.ensureDefaultAdmin(), isFalse);
      expect((await auth.login('admin', 'admin')).ok, isFalse);
    });
  });

  testWidgets(
      'primer uso: el acceso explica admin/admin y, al entrar, avisa de cambiar la clave',
      (t) async {
    await pumpApp(t, const Size(1200, 2000), defaultAdmin: true);
    expect(find.byKey(const Key('login-pista-inicial')), findsOneWidget);
    await login(t, 'admin', 'admin');
    expect(find.byKey(const Key('banner-clave-inicial')), findsOneWidget);
    await tapKey(t, 'banner-cambiar');
    await enter(t, 'cp-actual', 'admin');
    await enter(t, 'cp-nueva', 'secreto1');
    await tapKey(t, 'cp-guardar');
    expect(find.byKey(const Key('banner-clave-inicial')), findsNothing);
  });
}
