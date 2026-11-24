import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth/auth_service.dart';
import 'data/database.dart';
import 'providers.dart';
import 'theme/app_theme.dart';
import 'ui/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await AppDatabase.openDefault();
  // Primera apertura: administrador inicial admin/admin (hay que cambiarle la contraseña).
  await AuthService(db).ensureDefaultAdmin();
  runApp(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const MiEventoApp()));
}

class MiEventoApp extends StatelessWidget {
  const MiEventoApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Mi Evento',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        locale: const Locale('es'),
        home: const AppRoot(),
        builder: (context, child) => SystemBarsSafe(child: child!),
      );
}

/// Android moderno dibuja la app por debajo de la barra de navegación del sistema (botones o gesto),
/// y tapaba lo que quedaba abajo (por ejemplo «Guardar cambios»). Aquí se reserva ese espacio una
/// sola vez para TODAS las pantallas. Con el teclado abierto no se suma (ya lo cubre el teclado).
class SystemBarsSafe extends StatelessWidget {
  const SystemBarsSafe({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottom =
        (mq.viewPadding.bottom - mq.viewInsets.bottom).clamp(0.0, 200.0);
    if (bottom == 0 && mq.padding.bottom == 0) return child;
    return ColoredBox(
      color: Brand.fondo,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: MediaQuery(
          data: mq.copyWith(
            padding: mq.padding.copyWith(bottom: 0),
            viewPadding: mq.viewPadding.copyWith(bottom: 0),
          ),
          child: child,
        ),
      ),
    );
  }
}
