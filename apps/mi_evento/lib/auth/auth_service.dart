import 'dart:isolate';

import 'package:drift/drift.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import '../data/database.dart';

enum UserRole { admin, operator }

extension RoleX on AppUser {
  bool get isAdmin => role == 'admin';
  String get roleLabel => isAdmin ? 'Administrador' : 'Operador';
}

/// Error con mensaje listo para mostrar al usuario (en español).
class AuthException implements Exception {
  AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

enum LoginFailure { invalid, locked, inactive }

class LoginResult {
  const LoginResult.ok(this.user)
      : failure = null,
        wait = null;
  const LoginResult.fail(this.failure, {this.wait}) : user = null;
  final AppUser? user;
  final LoginFailure? failure;
  final Duration? wait;
  bool get ok => user != null;
}

typedef Runner = Future<T> Function<T>(T Function() f);

/// Ejecuta el cálculo pesado (hash) fuera del hilo de la interfaz.
Future<T> isolateRunner<T>(T Function() f) => Isolate.run(f);

/// Inicio de sesión local, usuarios y recuperación. Todo offline: la base de datos del
/// dispositivo es la única fuente. El inicio de sesión protege el USO de la app; no cifra el archivo.
class AuthService {
  AuthService(this.db,
      {PasswordHasher hasher = const PasswordHasher(),
      Runner runner = isolateRunner})
      : _hasher = hasher,
        _run = runner;

  final AppDatabase db;
  final PasswordHasher _hasher;
  final Runner _run;

  /// OJO: el cierre que viaja al otro hilo (Isolate) solo puede capturar datos enviables.
  /// Por eso se copia el hasher a una variable local: usar `_hasher` directamente capturaría
  /// `this` (el servicio, con la base de datos), que no se puede enviar y rompía todo el acceso.
  Future<String> _hash(String pw) {
    final hasher = _hasher;
    return _run(() => hasher.hash(pw));
  }

  Future<bool> _verify(String pw, String stored) =>
      _run(() => PasswordHasher.verify(pw, stored));

  Future<bool> hasUsers() async =>
      (await (db.select(db.appUsers)..where((u) => u.deletedAt.isNull())).get())
          .isNotEmpty;

  /// Usuarios activos de la lista (consulta puntual, para exportar).
  Future<List<AppUser>> listUsers() => (db.select(db.appUsers)
        ..where((u) => u.deletedAt.isNull())
        ..orderBy([(u) => OrderingTerm.asc(u.displayName)]))
      .get();

  Stream<List<AppUser>> watchUsers() => (db.select(db.appUsers)
        ..where((u) => u.deletedAt.isNull())
        ..orderBy([(u) => OrderingTerm.asc(u.displayName)]))
      .watch();

  void _checkNewCredentials(
      String username, String displayName, String password) {
    final ue = validateUsername(username);
    if (ue.isNotEmpty) throw AuthException(ue.first);
    if (displayName.trim().isEmpty) {
      throw AuthException('Falta el nombre de la persona.');
    }
    final pe = PasswordPolicy.validate(password,
        username: normalizeUsername(username));
    if (pe.isNotEmpty) throw AuthException(pe.first);
  }

  Future<AppUser> _insertUser(
      String username, String displayName, String password, String role,
      {bool mustChange = false}) async {
    final u = normalizeUsername(username);
    final exists = await (db.select(db.appUsers)
          ..where((x) => x.username.equals(u)))
        .getSingleOrNull();
    if (exists != null) {
      throw AuthException(
          'Ya existe un usuario «$u». Elige otro nombre de usuario.');
    }
    final now = DateTime.now().toUtc();
    final id = newUuidV7();
    await db.into(db.appUsers).insert(AppUsersCompanion.insert(
          id: id,
          createdAt: now,
          updatedAt: now,
          originDeviceId: await db.deviceId(),
          username: u,
          displayName: displayName.trim(),
          role: role,
          passwordHash: await _hash(password),
          mustChangePassword: Value(mustChange),
        ));
    return (db.select(db.appUsers)..where((x) => x.id.equals(id))).getSingle();
  }

  /// Primer uso: crea el administrador y devuelve el código de recuperación (se muestra UNA vez).
  Future<String> createFirstAdmin(
      {required String username,
      required String displayName,
      required String password}) async {
    if (await hasUsers()) throw AuthException('Ya hay usuarios creados.');
    _checkNewCredentials(username, displayName, password);
    await _insertUser(username, displayName, password, 'admin');
    return _newRecoveryCode();
  }

  /// Nombre y contraseña del administrador inicial (se crea solo la primera vez que se abre la app).
  static const defaultAdminUser = 'admin';
  static const defaultAdminPassword = 'admin';

  /// Primera apertura: si no hay usuarios, crea el administrador inicial `admin` / `admin`
  /// (la app avisa hasta que se cambie esa contraseña). Devuelve si lo creó.
  Future<bool> ensureDefaultAdmin() async {
    if (await hasUsers()) return false;
    await _insertUser(
        defaultAdminUser, 'Administrador', defaultAdminPassword, 'admin');
    return true;
  }

  /// ¿El administrador inicial sigue con la contraseña `admin`?
  Future<bool> defaultAdminUsesDefaultPassword() async {
    final u = await (db.select(db.appUsers)
          ..where((x) =>
              x.username.equals(defaultAdminUser) & x.deletedAt.isNull()))
        .getSingleOrNull();
    if (u == null) return false;
    return _verify(defaultAdminPassword, u.passwordHash);
  }

  Future<String> _newRecoveryCode() async {
    final code = generateRecoveryCode();
    final h = await _hash(normalizeRecoveryCode(code));
    await (db.update(db.appMeta)..where((t) => t.key.equals(1)))
        .write(AppMetaCompanion(recoveryHash: Value(h)));
    return code;
  }

  static final String _dummy =
      const PasswordHasher(iterations: 1000).hash('no-existe');

  Future<LoginResult> login(String username, String password) async {
    final u = await (db.select(db.appUsers)
          ..where((x) =>
              x.username.equals(normalizeUsername(username)) &
              x.deletedAt.isNull()))
        .getSingleOrNull();
    if (u == null) {
      await _verify(
          password, _dummy); // tiempo parecido: no delata si el usuario existe
      return const LoginResult.fail(LoginFailure.invalid);
    }
    final now = DateTime.now().toUtc();
    if (u.lockedUntil != null && u.lockedUntil!.isAfter(now)) {
      return LoginResult.fail(LoginFailure.locked,
          wait: u.lockedUntil!.difference(now));
    }
    if (!await _verify(password, u.passwordHash)) {
      final n = u.failedAttempts + 1;
      final wait = lockoutFor(n);
      await (db.update(db.appUsers)..where((x) => x.id.equals(u.id))).write(
          AppUsersCompanion(
              failedAttempts: Value(n),
              lockedUntil:
                  Value(wait == Duration.zero ? null : now.add(wait))));
      return wait == Duration.zero
          ? const LoginResult.fail(LoginFailure.invalid)
          : LoginResult.fail(LoginFailure.locked, wait: wait);
    }
    if (!u.active) return const LoginResult.fail(LoginFailure.inactive);
    await (db.update(db.appUsers)..where((x) => x.id.equals(u.id))).write(
        AppUsersCompanion(
            failedAttempts: const Value(0),
            lockedUntil: const Value(null),
            lastLoginAt: Value(now),
            passwordHash: _hasher.needsRehash(u.passwordHash)
                ? Value(await _hash(password))
                : const Value.absent()));
    return LoginResult.ok(await (db.select(db.appUsers)
          ..where((x) => x.id.equals(u.id)))
        .getSingle());
  }

  AppUser _requireAdmin(AppUser actor) {
    if (!actor.isAdmin) {
      throw AuthException('Solo el administrador puede hacer esto.');
    }
    return actor;
  }

  Future<AppUser> createUser(AppUser actor,
      {required String username,
      required String displayName,
      required String password,
      bool admin = false,
      bool mustChange = false}) async {
    _requireAdmin(actor);
    _checkNewCredentials(username, displayName, password);
    return _insertUser(
        username, displayName, password, admin ? 'admin' : 'operator',
        mustChange: mustChange);
  }

  Future<void> changeOwnPassword(
      AppUser user, String current, String next) async {
    final u = await (db.select(db.appUsers)..where((x) => x.id.equals(user.id)))
        .getSingle();
    if (!await _verify(current, u.passwordHash)) {
      throw AuthException('La contraseña actual no es correcta.');
    }
    final pe = PasswordPolicy.validate(next, username: u.username);
    if (pe.isNotEmpty) throw AuthException(pe.first);
    if (next == current) {
      throw AuthException(
          'La contraseña nueva debe ser distinta de la actual.');
    }
    await _setPassword(u.id, next);
  }

  /// El usuario tal como está ahora en la base (p. ej. tras cambiar su contraseña).
  Future<AppUser> userById(String id) =>
      (db.select(db.appUsers)..where((x) => x.id.equals(id))).getSingle();

  Future<void> _setPassword(String id, String password) async {
    await (db.update(db.appUsers)..where((x) => x.id.equals(id))).write(
        AppUsersCompanion(
            passwordHash: Value(await _hash(password)),
            mustChangePassword: const Value(false),
            failedAttempts: const Value(0),
            lockedUntil: const Value(null),
            updatedAt: Value(DateTime.now().toUtc())));
  }

  Future<void> resetPassword(
      AppUser actor, String targetId, String newPassword) async {
    _requireAdmin(actor);
    final t = await (db.select(db.appUsers)
          ..where((x) => x.id.equals(targetId)))
        .getSingle();
    final pe = PasswordPolicy.validate(newPassword, username: t.username);
    if (pe.isNotEmpty) throw AuthException(pe.first);
    await _setPassword(targetId, newPassword);
  }

  Future<int> _activeAdmins() async => (await (db.select(db.appUsers)
            ..where((u) =>
                u.deletedAt.isNull() &
                u.active.equals(true) &
                u.role.equals('admin')))
          .get())
      .length;

  Future<void> setActive(AppUser actor, String targetId, bool active) async {
    _requireAdmin(actor);
    final t = await (db.select(db.appUsers)
          ..where((x) => x.id.equals(targetId)))
        .getSingle();
    if (!active) {
      if (t.id == actor.id) {
        throw AuthException('No puedes desactivarte a ti mismo.');
      }
      if (t.isAdmin && await _activeAdmins() <= 1) {
        throw AuthException('Debe quedar al menos un administrador activo.');
      }
    }
    await (db.update(db.appUsers)..where((x) => x.id.equals(targetId))).write(
        AppUsersCompanion(
            active: Value(active), updatedAt: Value(DateTime.now().toUtc())));
  }

  Future<void> setAdmin(AppUser actor, String targetId, bool admin) async {
    _requireAdmin(actor);
    final t = await (db.select(db.appUsers)
          ..where((x) => x.id.equals(targetId)))
        .getSingle();
    if (!admin && t.isAdmin && await _activeAdmins() <= 1) {
      throw AuthException('Debe quedar al menos un administrador activo.');
    }
    await (db.update(db.appUsers)..where((x) => x.id.equals(targetId))).write(
        AppUsersCompanion(
            role: Value(admin ? 'admin' : 'operator'),
            updatedAt: Value(DateTime.now().toUtc())));
  }

  /// «Olvidé mi contraseña» del administrador: con el código de recuperación entregado al crear la
  /// cuenta se fija una contraseña nueva. Devuelve un código NUEVO (el anterior deja de servir).
  Future<({String newCode, String username})> recoverAdmin(
      String recoveryCode, String newPassword) async {
    final meta = await (db.select(db.appMeta)..where((t) => t.key.equals(1)))
        .getSingle();
    final stored = meta.recoveryHash;
    if (stored == null ||
        !await _verify(normalizeRecoveryCode(recoveryCode), stored)) {
      throw AuthException('El código de recuperación no es correcto.');
    }
    final admins = await (db.select(db.appUsers)
          ..where((u) => u.deletedAt.isNull() & u.role.equals('admin'))
          ..orderBy([(u) => OrderingTerm.asc(u.createdAt)]))
        .get();
    if (admins.isEmpty) {
      throw AuthException('No hay un administrador al que recuperar.');
    }
    final a = admins.first;
    final pe = PasswordPolicy.validate(newPassword, username: a.username);
    if (pe.isNotEmpty) throw AuthException(pe.first);
    await _setPassword(a.id, newPassword);
    await (db.update(db.appUsers)..where((x) => x.id.equals(a.id)))
        .write(const AppUsersCompanion(active: Value(true)));
    return (newCode: await _newRecoveryCode(), username: a.username);
  }
}
