import 'dart:math';

final Random _secure = Random.secure();

/// UUID v7 (RFC 9562): ordenable por tiempo, único globalmente sin coordinación.
/// Es el identificador de TODAS las filas, para poder fusionar datos entre dispositivos.
String newUuidV7({DateTime? now, Random? random}) {
  final rnd = random ?? _secure;
  final ms = (now ?? DateTime.now()).toUtc().millisecondsSinceEpoch;
  final b = List<int>.filled(16, 0);
  for (var i = 0; i < 6; i++) {
    b[i] = (ms >> (8 * (5 - i))) & 0xff;
  }
  for (var i = 6; i < 16; i++) {
    b[i] = rnd.nextInt(256);
  }
  b[6] = (b[6] & 0x0f) | 0x70; // versión 7
  b[8] = (b[8] & 0x3f) | 0x80; // variante RFC
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
      '${h.substring(16, 20)}-${h.substring(20)}';
}

final RegExp _uuidRe = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
bool isUuid(String s) => _uuidRe.hasMatch(s);
