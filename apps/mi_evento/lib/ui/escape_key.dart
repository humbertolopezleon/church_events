import 'package:material_ui/material_ui.dart';

/// Volver atrás con el teclado (Esc, Alt+← y Retroceso).
///
/// Cómo funciona: Flutter mapea Esc a `DismissIntent`, pero cada ruta de página lo deja
/// DESHABILITADO y eso tapa a cualquier manejador de más arriba. Por eso aquí se usa un intent
/// propio ([GoBackIntent]) que solo se habilita cuando la ruta superior es una pantalla; si es un
/// diálogo o un menú, no se hace nada y Esc llega al manejo normal de Flutter. Las teclas están en
/// `lib/ui/shortcuts.dart` (`AppKeyboard`).
class GoBackIntent extends Intent {
  const GoBackIntent({this.outsideTextOnly = false});

  /// Retroceso: solo vale fuera de un campo de texto (dentro borra letras).
  final bool outsideTextOnly;
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

class GoBackAction extends Action<GoBackIntent> {
  GoBackAction(this.navigatorKey, this.observer);
  final GlobalKey<NavigatorState> navigatorKey;
  final TopRouteObserver observer;

  static bool _typing() {
    final ctx = FocusManager.instance.primaryFocus?.context;
    return ctx != null &&
        ctx.findAncestorStateOfType<EditableTextState>() != null;
  }

  @override
  bool isEnabled(GoBackIntent intent) =>
      observer.top is PageRoute &&
      (navigatorKey.currentState?.canPop() ?? false) &&
      !(intent.outsideTextOnly && _typing());

  @override
  Object? invoke(GoBackIntent intent) {
    navigatorKey.currentState?.maybePop();
    return null;
  }
}
