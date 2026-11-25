import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:material_ui/material_ui.dart';

/// Esc en escritorio: además de cerrar diálogos y menús (que Flutter ya hace), vuelve atrás en las
/// pantallas completas (formularios, fichas…), igual que el botón «Atrás». En la pantalla raíz no
/// hace nada.
///
/// Cómo funciona: Flutter mapea Esc a `DismissIntent`, pero cada ruta de página lo deja
/// DESHABILITADO y eso tapa a cualquier manejador de más arriba. Por eso aquí se usa un intent
/// propio ([GoBackIntent]) que solo se habilita cuando la ruta superior es una pantalla; si es un
/// diálogo o un menú, no se hace nada y Esc llega al manejo normal de Flutter.
class GoBackIntent extends Intent {
  const GoBackIntent();
}

/// Sigue la pila del navegador para saber qué ruta está arriba.
class TopRouteObserver extends NavigatorObserver {
  final List<Route<dynamic>> _stack = [];
  Route<dynamic>? get top => _stack.isEmpty ? null : _stack.last;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _stack.add(route);
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _stack.remove(route);
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _stack.remove(route);
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final i = oldRoute == null ? -1 : _stack.indexOf(oldRoute);
    if (i >= 0) _stack.removeAt(i);
    if (newRoute != null) _stack.insert(i < 0 ? _stack.length : i, newRoute);
  }
}

class _GoBackAction extends Action<GoBackIntent> {
  _GoBackAction(this.navigatorKey, this.observer);
  final GlobalKey<NavigatorState> navigatorKey;
  final TopRouteObserver observer;

  @override
  bool isEnabled(GoBackIntent intent) =>
      observer.top is PageRoute &&
      (navigatorKey.currentState?.canPop() ?? false);

  @override
  Object? invoke(GoBackIntent intent) {
    navigatorKey.currentState?.maybePop();
    return null;
  }
}

/// Se coloca ENCIMA del navegador (en `MaterialApp.builder`). [navigatorKey] y [observer] son los
/// del `MaterialApp` (`navigatorKey` y `navigatorObservers`).
class EscapeGoesBack extends StatelessWidget {
  const EscapeGoesBack(
      {super.key,
      required this.navigatorKey,
      required this.observer,
      required this.child});
  final GlobalKey<NavigatorState> navigatorKey;
  final TopRouteObserver observer;
  final Widget child;

  @override
  Widget build(BuildContext context) => Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.escape): GoBackIntent(),
        },
        child: Actions(
          actions: {GoBackIntent: _GoBackAction(navigatorKey, observer)},
          // Con autofocus, si nada tiene el foco (nadie tocó un campo) Esc llega igual aquí.
          child: Focus(autofocus: true, skipTraversal: true, child: child),
        ),
      );
}
