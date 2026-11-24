import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

const _sep = '\$';

/// Hash de contraseñas PBKDF2-HMAC-SHA256 con sal aleatoria por usuario.
/// Formato guardado: `pbkdf2-sha256$<iteraciones>$<sal base64>$<hash base64>`.
/// Las iteraciones viajan con el hash, así se pueden subir en el futuro sin romper cuentas.
class PasswordHasher {
  const PasswordHasher({this.iterations = defaultIterations});
  final int iterations;

  /// Equilibrio para móviles de gama baja (se ejecuta fuera del hilo de la interfaz).
  static const defaultIterations = 100000;

  static final Random _rnd = Random.secure();

  String hash(String password, {Uint8List? salt}) {
    final s =
        salt ?? Uint8List.fromList(List.generate(16, (_) => _rnd.nextInt(256)));
    final dk = pbkdf2(utf8.encode(password), s, iterations, 32);
    return ['pbkdf2-sha256', '$iterations', base64.encode(s), base64.encode(dk)]
        .join(_sep);
  }

  /// Verifica en tiempo constante. Devuelve false si el formato no es válido.
  static bool verify(String password, String stored) {
    final parts = stored.split(_sep);
    if (parts.length != 4 || parts[0] != 'pbkdf2-sha256') return false;
    final iters = int.tryParse(parts[1]);
    if (iters == null || iters < 1) return false;
    try {
      final salt = base64.decode(parts[2]);
      final expected = base64.decode(parts[3]);
      if (expected.isEmpty) return false;
      final dk = pbkdf2(utf8.encode(password), salt, iters, expected.length);
      return constantTimeEquals(dk, expected);
    } on FormatException {
      return false;
    }
  }

  /// ¿El hash usa menos iteraciones que las actuales? (para re-hashear al iniciar sesión)
  bool needsRehash(String stored) {
    final parts = stored.split(_sep);
    final iters = parts.length == 4 ? int.tryParse(parts[1]) : null;
    return iters == null || iters < iterations;
  }
}

/// PBKDF2 (RFC 8018) con HMAC-SHA256.
Uint8List pbkdf2(
    List<int> password, List<int> salt, int iterations, int length) {
  final hmac = Hmac(sha256, password);
  final blocks = (length / 32).ceil();
  final out = BytesBuilder();
  for (var i = 1; i <= blocks; i++) {
    final intBlock = [
      (i >> 24) & 0xff,
      (i >> 16) & 0xff,
      (i >> 8) & 0xff,
      i & 0xff
    ];
    var u = hmac.convert([...salt, ...intBlock]).bytes;
    final t = List<int>.from(u);
    for (var j = 1; j < iterations; j++) {
      u = hmac.convert(u).bytes;
      for (var k = 0; k < t.length; k++) {
        t[k] ^= u[k];
      }
    }
    out.add(t);
  }
  return Uint8List.fromList(out.toBytes().sublist(0, length));
}

bool constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}

/// Reglas simples para voluntarios: mínimo 6 caracteres, no igual al usuario.
class PasswordPolicy {
  static const minLength = 6;
  static List<String> validate(String password, {String? username}) {
    final e = <String>[];
    if (password.length < minLength) {
      e.add('La contraseña debe tener al menos $minLength caracteres.');
    }
    if (username != null &&
        username.isNotEmpty &&
        password.toLowerCase() == username.toLowerCase()) {
      e.add('La contraseña no puede ser igual al usuario.');
    }
    if (password.isNotEmpty && password.trim().isEmpty) {
      e.add('La contraseña no puede estar en blanco.');
    }
    return e;
  }
}

/// Usuario válido: 3–30 caracteres, minúsculas/números/punto/guion bajo (se normaliza).
String normalizeUsername(String s) => s.trim().toLowerCase();
List<String> validateUsername(String s) {
  final u = normalizeUsername(s);
  if (!RegExp(r'^[a-z0-9._]{3,30}$').hasMatch(u)) {
    return [
      'El usuario debe tener entre 3 y 30 letras, números, punto o guion bajo (sin espacios ni tildes).'
    ];
  }
  return const [];
}

/// Código de recuperación de un solo uso, ej. `K7QM-2XZP-9RTD-4WNB` (sin caracteres confusos).
String generateRecoveryCode({Random? random}) {
  const alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  final r = random ?? Random.secure();
  final chars = List.generate(16, (_) => alphabet[r.nextInt(alphabet.length)]);
  return [for (var i = 0; i < 16; i += 4) chars.sublist(i, i + 4).join()]
      .join('-');
}

String normalizeRecoveryCode(String s) =>
    s.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

/// Freno ante intentos fallidos: nada hasta el 4.º; luego 30 s, 1 min, 5 min y 15 min (máx.).
/// Sin esto, alguien con el dispositivo podría probar contraseñas sin límite.
Duration lockoutFor(int failedAttempts) {
  if (failedAttempts < 5) return Duration.zero;
  const steps = [30, 60, 300, 900];
  return Duration(seconds: steps[min(failedAttempts - 5, steps.length - 1)]);
}
