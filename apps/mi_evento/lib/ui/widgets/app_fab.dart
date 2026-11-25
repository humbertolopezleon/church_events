import 'package:material_ui/material_ui.dart';

import '../../theme/app_theme.dart';
import '../shortcuts.dart';

/// Botón flotante extendido común: 60 dp de alto, esquinas de 16 dp. Naranja (texto #18202B) para la
/// acción rápida de Registrar; azul (texto blanco) para el resto. Es la única sombra de la app.
class AppFab extends StatelessWidget {
  const AppFab(
      {super.key,
      required this.label,
      required this.icon,
      required this.onPressed,
      this.accent = false,
      this.tooltip});
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  /// Naranja (Registrar) en vez de azul.
  final bool accent;
  final String? tooltip;

  /// Margen inferior que debe dejar una lista para que su último elemento no quede tapado.
  static const listBottomPadding = 96.0;

  @override
  Widget build(BuildContext context) {
    final bg = accent ? Brand.naranja : Brand.azul;
    final fg = accent ? Brand.tinta : Colors.white;
    return ScreenShortcutsScope(
      // Ctrl+N: el botón flotante siempre es la acción de «Nuevo» de la pantalla.
      handlers: {ScreenAction.newItem: onPressed},
      child: SizedBox(
        height: 60,
        child: FloatingActionButton.extended(
          heroTag: null,
          tooltip: tooltip ?? label,
          onPressed: onPressed,
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: Icon(icon),
          label: Text(label,
              style: bodyStyle(17, color: fg, weight: FontWeight.w700)),
        ),
      ),
    );
  }
}
