import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_evento/auth/auth_service.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

Future<T> _sync<T>(T Function() f) async => f();

void main() {
  late AppDatabase db;
  late AuthService auth;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    auth = AuthService(db,
        hasher: const PasswordHasher(iterations: 1000), runner: _sync);
  });
  tearDown(() => db.close());

  Future<AppUser> admin() async {
    await auth.createFirstAdmin(
        username: 'Admin', displayName: 'Ana Admin', password: 'secreto1');
    return (await auth.login('admin', 'secreto1')).user!;
  }

  test('primer uso: crea el administrador y entrega un código de recuperación',
      () async {
    expect(await auth.hasUsers(), isFalse);
    final code = await auth.createFirstAdmin(
        username: 'Admin', displayName: 'Ana', password: 'secreto1');
    expect(RegExp(r'^[A-Z2-9]{4}(-[A-Z2-9]{4}){3}$').hasMatch(code), isTrue);
    expect(await auth.hasUsers(), isTrue);
    final u = (await db.select(db.appUsers).get()).single;
    expect(u.username, 'admin'); // normalizado
    expect(u.role, 'admin');
    expect(u.passwordHash.contains('secreto1'), isFalse); // nunca en claro
    expect(isUuid(u.id), isTrue);
  });

  test('no se puede crear un segundo «primer administrador»', () async {
    await admin();
    expect(
        () => auth.createFirstAdmin(
            username: 'otro', displayName: 'X', password: 'secreto1'),
        throwsA(isA<AuthException>()));
  });

  test('credenciales inválidas se rechazan con mensajes en español', () async {
    expect(
        () => auth.createFirstAdmin(
            username: 'a', displayName: 'X', password: 'secreto1'),
        throwsA(isA<AuthException>()));
    expect(
        () => auth.createFirstAdmin(
            username: 'admin', displayName: ' ', password: 'secreto1'),
        throwsA(isA<AuthException>()));
    expect(
        () => auth.createFirstAdmin(
            username: 'admin', displayName: 'X', password: '123'),
        throwsA(isA<AuthException>()));
  });

  test('login correcto (usuario sin importar mayúsculas) y erróneo', () async {
    await admin();
    expect((await auth.login('ADMIN ', 'secreto1')).ok, isTrue);
    final bad = await auth.login('admin', 'mala');
    expect(bad.ok, isFalse);
    expect(bad.failure, LoginFailure.invalid);
    expect(
        (await auth.login('nadie', 'secreto1')).failure, LoginFailure.invalid);
  });

  test(
      'bloqueo tras 5 intentos fallidos y desbloqueo al acertar tras la espera',
      () async {
    await admin();
    for (var i = 0; i < 4; i++) {
      expect((await auth.login('admin', 'x$i')).failure, LoginFailure.invalid);
    }
    final fifth = await auth.login('admin', 'x5');
    expect(fifth.failure, LoginFailure.locked);
    expect(fifth.wait!.inSeconds, inInclusiveRange(25, 30));
    // aunque la clave sea correcta, sigue bloqueado
    expect(
        (await auth.login('admin', 'secreto1')).failure, LoginFailure.locked);
    // simulamos que pasó la espera
    await (db.update(db.appUsers)).write(AppUsersCompanion(
        lockedUntil: Value(
            DateTime.now().toUtc().subtract(const Duration(seconds: 1)))));
    final ok = await auth.login('admin', 'secreto1');
    expect(ok.ok, isTrue);
    expect((await db.select(db.appUsers).getSingle()).failedAttempts, 0);
  });

  test('solo el administrador crea usuarios; el operador no puede', () async {
    final a = await admin();
    final op = await auth.createUser(a,
        username: 'ruth', displayName: 'Ruth M.', password: 'ruth123');
    expect(op.role, 'operator');
    expect((await auth.login('ruth', 'ruth123')).ok, isTrue);
    expect(
        () => auth.createUser(op,
            username: 'otro', displayName: 'X', password: 'otro123'),
        throwsA(isA<AuthException>()));
    expect(() => auth.resetPassword(op, a.id, 'hackeo1'),
        throwsA(isA<AuthException>()));
    expect(
        () => auth.setActive(op, a.id, false), throwsA(isA<AuthException>()));
  });

  test('usuario duplicado se rechaza', () async {
    final a = await admin();
    expect(
        () => auth.createUser(a,
            username: 'ADMIN', displayName: 'X', password: 'otro123'),
        throwsA(isA<AuthException>()));
  });

  test(
      'usuario desactivado no entra (con la clave correcta) y puede reactivarse',
      () async {
    final a = await admin();
    final op = await auth.createUser(a,
        username: 'ruth', displayName: 'Ruth', password: 'ruth123');
    await auth.setActive(a, op.id, false);
    expect(
        (await auth.login('ruth', 'ruth123')).failure, LoginFailure.inactive);
    await auth.setActive(a, op.id, true);
    expect((await auth.login('ruth', 'ruth123')).ok, isTrue);
  });

  test('protecciones: no desactivarse, no quedarse sin administradores',
      () async {
    final a = await admin();
    expect(() => auth.setActive(a, a.id, false), throwsA(isA<AuthException>()));
    expect(() => auth.setAdmin(a, a.id, false), throwsA(isA<AuthException>()));
    final b = await auth.createUser(a,
        username: 'bea', displayName: 'Bea', password: 'bea1234', admin: true);
    await auth.setAdmin(a, b.id, false); // hay otro admin: permitido
    expect((await auth.login('bea', 'bea1234')).user!.role, 'operator');
  });

  test('cambiar la propia contraseña exige la actual', () async {
    final a = await admin();
    expect(() => auth.changeOwnPassword(a, 'equivocada', 'nueva123'),
        throwsA(isA<AuthException>()));
    expect(() => auth.changeOwnPassword(a, 'secreto1', '123'),
        throwsA(isA<AuthException>()));
    await auth.changeOwnPassword(a, 'secreto1', 'nueva123');
    expect((await auth.login('admin', 'secreto1')).ok, isFalse);
    expect((await auth.login('admin', 'nueva123')).ok, isTrue);
  });

  test(
      'el administrador restablece la contraseña de un operador y lo desbloquea',
      () async {
    final a = await admin();
    final op = await auth.createUser(a,
        username: 'ruth', displayName: 'Ruth', password: 'ruth123');
    for (var i = 0; i < 5; i++) {
      await auth.login('ruth', 'x$i');
    }
    await auth.resetPassword(a, op.id, 'nueva456');
    expect((await auth.login('ruth', 'nueva456')).ok, isTrue);
  });

  test('recuperación con el código: sirve una vez y entrega un código nuevo',
      () async {
    final code = await auth.createFirstAdmin(
        username: 'admin', displayName: 'Ana', password: 'secreto1');
    expect(() => auth.recoverAdmin('AAAA-BBBB-CCCC-DDDD', 'nueva123'),
        throwsA(isA<AuthException>()));
    final r = await auth.recoverAdmin(
        code.toLowerCase(), 'nueva123'); // tolera minúsculas y guiones
    expect(r.username, 'admin');
    expect((await auth.login('admin', 'nueva123')).ok, isTrue);
    expect(() => auth.recoverAdmin(code, 'otra1234'),
        throwsA(isA<AuthException>())); // código viejo ya no sirve
    expect((await auth.recoverAdmin(r.newCode, 'otra1234')).username, 'admin');
  });

  test('login re-hashea si el hash guardado tiene menos iteraciones', () async {
    await admin();
    final weak = const PasswordHasher(iterations: 10).hash('secreto1');
    await (db.update(db.appUsers))
        .write(AppUsersCompanion(passwordHash: Value(weak)));
    expect((await auth.login('admin', 'secreto1')).ok, isTrue);
    final now = (await db.select(db.appUsers).getSingle()).passwordHash;
    expect(const PasswordHasher(iterations: 1000).needsRehash(now), isFalse);
  });
}
