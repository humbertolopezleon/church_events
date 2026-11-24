import 'dart:math';

import 'package:mi_evento_core/mi_evento_core.dart';

import '../auth/auth_service.dart';
import 'database.dart';
import 'table_import.dart';

/// Exportar e importar usuarios en CSV (usuario, nombre, rol, estado). Al importar NUNCA se lee una
/// contraseña del archivo: cada usuario nuevo recibe una contraseña temporal que se muestra UNA
/// sola vez al terminar y que está obligado a cambiar en su primer acceso.
class UsersExchange implements TableImporter {
  UsersExchange(this.db, this.auth, this.actor);
  final AppDatabase db;
  final AuthService auth;
  final AppUser actor;

  static const headers = ['usuario', 'nombre', 'rol', 'estado'];

  @override
  String get title => 'Importar usuarios';
  @override
  String get help =>
      'Columnas: usuario, nombre y rol (Administrador u Operador; si falta, Operador). '
      'Quien ya exista se omite. Cada usuario nuevo recibe una contraseña temporal que se muestra '
      'una sola vez al terminar y debe cambiar al entrar.';

  static final _rnd = Random.secure();
  static const _alphabet =
      'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// Contraseña temporal legible (sin caracteres que se confunden: 0/O, 1/l/I).
  static String tempPassword([int length = 10]) =>
      List.generate(length, (_) => _alphabet[_rnd.nextInt(_alphabet.length)])
          .join();

  Future<TableImportSummary> _run(String csvText, {required bool write}) async {
    final rows = readCsvTable(
        parseCsv(csvText),
        const {
          'usuario': ['user', 'username'],
          'nombre': ['name'],
          'rol': ['role'],
        },
        normalizeText);
    final out = TableImportSummary();
    if (rows.isEmpty) {
      out.warnings.add('El archivo está vacío o no tiene filas.');
      return out;
    }
    if (!rows.first.$2.containsKey('usuario') ||
        !rows.first.$2.containsKey('nombre')) {
      out.warnings
          .add('Faltan columnas: el archivo debe tener «usuario» y «nombre».');
      return out;
    }
    final existing = {
      for (final u in await db.select(db.appUsers).get()) u.username
    };
    final seen = <String>{};
    final created = <(String, String)>[]; // usuario, contraseña temporal
    var skipped = 0;
    for (final (line, r) in rows) {
      final user = normalizeUsername(r['usuario'] ?? '');
      final name = (r['nombre'] ?? '').trim();
      final roleRaw = normalizeText(r['rol'] ?? '');
      final ue = validateUsername(user);
      if (ue.isNotEmpty) {
        out.warnings.add('Fila $line: ${ue.first}');
        continue;
      }
      if (name.isEmpty) {
        out.warnings.add('Fila $line: falta el nombre de «$user».');
        continue;
      }
      if (roleRaw.isNotEmpty &&
          !['administrador', 'admin', 'operador', 'operator']
              .contains(roleRaw)) {
        out.warnings.add(
            'Fila $line: el rol «${r['rol']}» debe ser Administrador u Operador.');
        continue;
      }
      if (existing.contains(user) || !seen.add(user)) {
        skipped++;
        continue;
      }
      final admin = roleRaw == 'administrador' || roleRaw == 'admin';
      final pass = tempPassword();
      created.add((user, pass));
      if (write) {
        await auth.createUser(actor,
            username: user,
            displayName: name,
            password: pass,
            admin: admin,
            mustChange: true);
      }
    }
    out.work = created.length;
    out.lines.add('Usuarios nuevos: ${created.length}');
    if (skipped > 0) {
      out.lines.add('Omitidos (ya existen o repetidos): $skipped');
    }
    if (write && created.isNotEmpty) {
      out.lines
        ..add('')
        ..add(
            'CONTRASEÑAS TEMPORALES (se muestran una sola vez; deberán cambiarlas al entrar):')
        ..addAll([for (final (u, p) in created) '$u  →  $p']);
    }
    return out;
  }

  @override
  Future<TableImportSummary> preview(String csvText) =>
      _run(csvText, write: false);
  @override
  Future<TableImportSummary> apply(String csvText) =>
      _run(csvText, write: true);
}
