import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:mi_evento_core/mi_evento_core.dart';
import 'package:test/test.dart';

String hex(List<int> b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

void main() {
  test('PBKDF2-HMAC-SHA256: vectores de prueba conocidos', () {
    expect(hex(pbkdf2(utf8.encode('password'), utf8.encode('salt'), 1, 32)),
        '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b');
    expect(hex(pbkdf2(utf8.encode('password'), utf8.encode('salt'), 2, 32)),
        'ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43');
  });

  const h = PasswordHasher(iterations: 1000);
  test('hash y verificación correctos; contraseña errónea falla', () {
    final s = h.hash('clave123');
    expect(PasswordHasher.verify('clave123', s), isTrue);
    expect(PasswordHasher.verify('clave124', s), isFalse);
    expect(PasswordHasher.verify('', s), isFalse);
  });
  test('la sal es distinta en cada hash y no se guarda la clave en claro', () {
    final a = h.hash('igual'), b = h.hash('igual');
    expect(a, isNot(b));
    expect(a.contains('igual'), isFalse);
  });
  test('formato corrupto o vacío nunca verifica ni lanza', () {
    const d = '\$';
    for (final bad in [
      '',
      'x',
      ['pbkdf2-sha256', 'a', 'b', 'c'].join(d),
      ['md5', '1', 'AA==', 'AA=='].join(d),
      ['pbkdf2-sha256', '1', '@@@', '@@@'].join(d),
    ]) {
      expect(PasswordHasher.verify('x', bad), isFalse);
    }
  });
  test('sal fija produce hash reproducible', () {
    final salt = Uint8List.fromList(List.filled(16, 7));
    expect(h.hash('a', salt: salt), h.hash('a', salt: salt));
  });
  test('needsRehash detecta iteraciones antiguas', () {
    final old = const PasswordHasher(iterations: 10).hash('x');
    expect(h.needsRehash(old), isTrue);
    expect(h.needsRehash(h.hash('x')), isFalse);
    expect(h.needsRehash('basura'), isTrue);
  });
  test('política de contraseña', () {
    expect(PasswordPolicy.validate('12345'), isNotEmpty);
    expect(PasswordPolicy.validate('123456'), isEmpty);
    expect(PasswordPolicy.validate('Ruth123', username: 'ruth123'), isNotEmpty);
    expect(PasswordPolicy.validate('      '), isNotEmpty);
  });
  test('validación y normalización de usuario', () {
    expect(validateUsername('Ruth.M'), isEmpty);
    expect(normalizeUsername('  Ruth.M '), 'ruth.m');
    expect(validateUsername('ab'), isNotEmpty);
    expect(validateUsername('con espacio'), isNotEmpty);
    expect(validateUsername('José'), isNotEmpty);
  });
  test('código de recuperación: formato y sin caracteres ambiguos', () {
    final c = generateRecoveryCode(random: Random(3));
    expect(RegExp(r'^[A-Z2-9]{4}(-[A-Z2-9]{4}){3}$').hasMatch(c), isTrue);
    expect(c.contains(RegExp('[01OIL]')), isFalse);
    expect(
        normalizeRecoveryCode(' ${c.toLowerCase()} '), c.replaceAll('-', ''));
    expect({for (var i = 0; i < 100; i++) generateRecoveryCode()}.length, 100);
  });
  test('bloqueo progresivo tras intentos fallidos', () {
    expect(lockoutFor(4), Duration.zero);
    expect(lockoutFor(5), const Duration(seconds: 30));
    expect(lockoutFor(6), const Duration(minutes: 1));
    expect(lockoutFor(7), const Duration(minutes: 5));
    expect(lockoutFor(50), const Duration(minutes: 15));
  });
}
