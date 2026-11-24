import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_evento/auth/auth_service.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

/// Usa el ejecutor REAL (`Isolate.run`), el mismo que la app en Android y Windows.
/// Los demás tests usan un ejecutor síncrono y no podían detectar que el cálculo del hash
/// arrastraba la base de datos al otro hilo (no es enviable) y dejaba la app «Creando…» para siempre.
void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test(
      'crear administrador e iniciar sesión funcionan con el ejecutor real (Isolate)',
      () async {
    final auth = AuthService(db,
        hasher: const PasswordHasher(
            iterations: 1000)); // runner por defecto = Isolate.run
    final code = await auth.createFirstAdmin(
        username: 'admin', displayName: 'Ana', password: 'secreto1');
    expect(code, isNotEmpty);
    final ok = await auth.login('admin', 'secreto1');
    expect(ok.ok, isTrue);
    expect((await auth.login('admin', 'mala')).ok, isFalse);
  });

  test('con las iteraciones reales también termina en un tiempo razonable',
      () async {
    final auth = AuthService(db);
    final sw = Stopwatch()..start();
    await auth.createFirstAdmin(
        username: 'admin', displayName: 'Ana', password: 'secreto1');
    expect((await auth.login('admin', 'secreto1')).ok, isTrue);
    expect(sw.elapsed.inSeconds,
        lessThan(20)); // hash + verificación, 100 000 iteraciones
  });

  test(
      'recuperación, cambio de contraseña y usuarios nuevos también con Isolate',
      () async {
    final auth =
        AuthService(db, hasher: const PasswordHasher(iterations: 1000));
    final code = await auth.createFirstAdmin(
        username: 'admin', displayName: 'Ana', password: 'secreto1');
    final a = (await auth.login('admin', 'secreto1')).user!;
    await auth.createUser(a,
        username: 'ruth', displayName: 'Ruth', password: 'ruth123');
    await auth.changeOwnPassword(a, 'secreto1', 'nueva123');
    expect((await auth.login('ruth', 'ruth123')).ok, isTrue);
    final r = await auth.recoverAdmin(code, 'otra1234');
    expect(r.username, 'admin');
    expect((await auth.login('admin', 'otra1234')).ok, isTrue);
  });
}
