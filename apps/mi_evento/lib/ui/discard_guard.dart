import 'package:material_ui/material_ui.dart';

/// Pregunta «¿Descartar los cambios?». Devuelve `true` si la persona decide descartarlos.
Future<bool> confirmDiscard(BuildContext context) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      key: const Key('descartar-dialogo'),
      title: const Text('¿Descartar los cambios?'),
      content:
          const Text('Hay cambios sin guardar. Si sales ahora, se perderán.'),
      actions: [
        TextButton(
            key: const Key('descartar-seguir'),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Seguir editando')),
        FilledButton(
            key: const Key('descartar-ok'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Descartar')),
      ],
    ),
  );
  return r == true;
}

/// Envuelve un formulario de pantalla completa: si [isDirty] dice que hay cambios sin guardar,
/// salir con «Atrás», la X, Esc o el gesto del móvil pregunta antes de descartar. Guardar o
/// eliminar cierran la pantalla con `Navigator.pop`, que no pasa por aquí (no preguntan).
///
/// [isDirty] se evalúa al intentar salir (no al construir): teclear no reconstruye la pantalla.
class DiscardGuard extends StatelessWidget {
  const DiscardGuard({super.key, required this.isDirty, required this.child});
  final bool Function() isDirty;
  final Widget child;

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          if (!isDirty() || await confirmDiscard(context)) {
            if (context.mounted) Navigator.pop(context);
          }
        },
        child: child,
      );
}
