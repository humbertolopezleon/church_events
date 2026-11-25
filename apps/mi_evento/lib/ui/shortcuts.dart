import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import 'escape_key.dart';

/// Acciones de pantalla que se pueden lanzar con el teclado. Cada pantalla (o widget común como
/// [AppFab], [AppHeader] o [ListToolbar]) registra las que sabe hacer con [ScreenShortcutsScope];
/// la tecla solo hace algo si la pantalla que está arriba la ha registrado.
enum ScreenAction {
  newItem,
  search,
  filters,
  importCsv,
  exportCsv,
  save,
  undo,
}

/// Qué pantallas escuchan las teclas. Solo cuentan las que están en la ruta de arriba (una
/// pantalla tapada por un formulario o un diálogo no recibe nada).
class ShortcutRegistry {
  ShortcutRegistry._();
  static final instance = ShortcutRegistry._();

  final List<_ScopeState> _scopes = [];

  VoidCallback? handlerFor(ScreenAction a) {
    for (final s in _scopes.reversed) {
      if (!s.isCurrent) continue;
      final h = s.widget.handlers[a];
      if (h != null) return h;
    }
    return null;
  }

  /// Ir a una sección (Ctrl+1…6): la pantalla principal la atiende si está arriba.
  bool navigate(String page) {
    for (final s in _scopes.reversed) {
      if (!s.isCurrent) continue;
      final n = s.widget.onNavigate;
      if (n != null) return n(page);
    }
    return false;
  }

  bool get canNavigate =>
      _scopes.any((s) => s.isCurrent && s.widget.onNavigate != null);
}

/// Registra las acciones de teclado de la pantalla que contiene a este widget. Un manejador nulo
/// equivale a no registrarlo (la tecla se deja pasar).
class ScreenShortcutsScope extends StatefulWidget {
  const ScreenShortcutsScope(
      {super.key,
      this.handlers = const {},
      this.onNavigate,
      required this.child});
  final Map<ScreenAction, VoidCallback?> handlers;

  /// Solo la pantalla principal: recibe la sección pedida («asistentes», «hospedajes»…).
  final bool Function(String page)? onNavigate;
  final Widget child;
  @override
  State<ScreenShortcutsScope> createState() => _ScopeState();
}

class _ScopeState extends State<ScreenShortcutsScope> {
  /// Solo está «arriba» si su ruta es la actual (no hay un diálogo ni otra pantalla encima).
  bool get isCurrent => mounted && (ModalRoute.of(context)?.isCurrent ?? true);

  @override
  void initState() {
    super.initState();
    ShortcutRegistry.instance._scopes.add(this);
  }

  @override
  void dispose() {
    ShortcutRegistry.instance._scopes.remove(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ── Atajos y su ayuda ───────────────────────────────────────────────────────────────────────

class ScreenIntent extends Intent {
  const ScreenIntent(this.action, {this.outsideTextOnly = false});
  final ScreenAction action;

  /// Teclas sin Ctrl (como «/»): no valen mientras se escribe en un campo.
  final bool outsideTextOnly;
}

class NavigateIntent extends Intent {
  const NavigateIntent(this.page);
  final String page;
}

class HelpIntent extends Intent {
  const HelpIntent();
}

/// Un atajo para la ayuda y para las teclas: de aquí salen las dos cosas, así nunca se separan.
class ShortcutDef {
  const ShortcutDef(
      this.group, this.keys, this.description, this.activators, this.intent);
  final String group;

  /// Texto para la ayuda («Ctrl+N»).
  final String keys;
  final String description;
  final List<SingleActivator> activators;
  final Intent intent;
}

SingleActivator _ctrl(LogicalKeyboardKey k, {bool shift = false}) =>
    SingleActivator(k, control: true, shift: shift);

/// Todos los atajos de la app (solo escritorio). Orden = el de la ayuda.
final List<ShortcutDef> appShortcutDefs = [
  const ShortcutDef(
      'En cualquier pantalla',
      'Esc',
      'Cerrar el diálogo o volver atrás',
      [SingleActivator(LogicalKeyboardKey.escape)],
      GoBackIntent()),
  const ShortcutDef(
      'En cualquier pantalla',
      'Alt+Izquierda o Retroceso',
      'Volver a la pantalla anterior (Alt+Flecha izquierda; Retroceso, solo fuera de un campo de texto)',
      [SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true)],
      GoBackIntent()),
  ShortcutDef(
      'En cualquier pantalla',
      'F1 o Ctrl+/',
      'Mostrar esta ayuda',
      [
        const SingleActivator(LogicalKeyboardKey.f1),
        _ctrl(LogicalKeyboardKey.slash),
      ],
      const HelpIntent()),
  for (final (i, id, name) in [
    (1, 'panel', 'Panel'),
    (2, 'asistentes', 'Asistentes'),
    (3, 'comidas', 'Comidas'),
    (4, 'equipos', 'Equipos'),
    (5, 'hospedajes', 'Hospedajes'),
    (6, 'iglesias', 'Iglesias'),
  ])
    ShortcutDef(
        'En cualquier pantalla',
        'Ctrl+$i',
        'Ir a $name',
        [
          _ctrl(<LogicalKeyboardKey>[
            LogicalKeyboardKey.digit1,
            LogicalKeyboardKey.digit2,
            LogicalKeyboardKey.digit3,
            LogicalKeyboardKey.digit4,
            LogicalKeyboardKey.digit5,
            LogicalKeyboardKey.digit6,
          ][i - 1])
        ],
        NavigateIntent(id)),
  ShortcutDef(
      'En las listas',
      'Ctrl+N',
      'Nuevo (asistente, hospedaje, equipo…)',
      [_ctrl(LogicalKeyboardKey.keyN)],
      const ScreenIntent(ScreenAction.newItem)),
  ShortcutDef(
      'En las listas',
      'Ctrl+F o /',
      'Ir al buscador',
      [
        _ctrl(LogicalKeyboardKey.keyF),
      ],
      const ScreenIntent(ScreenAction.search)),
  ShortcutDef(
      'En las listas',
      'Ctrl+Mayús+F',
      'Abrir los filtros',
      [_ctrl(LogicalKeyboardKey.keyF, shift: true)],
      const ScreenIntent(ScreenAction.filters)),
  ShortcutDef(
      'En las listas',
      'Ctrl+I',
      'Importar CSV',
      [_ctrl(LogicalKeyboardKey.keyI)],
      const ScreenIntent(ScreenAction.importCsv)),
  ShortcutDef(
      'En las listas',
      'Ctrl+E',
      'Exportar CSV',
      [_ctrl(LogicalKeyboardKey.keyE)],
      const ScreenIntent(ScreenAction.exportCsv)),
  ShortcutDef(
      'En los formularios',
      'Ctrl+S o Ctrl+Enter',
      'Guardar',
      [
        _ctrl(LogicalKeyboardKey.keyS),
        _ctrl(LogicalKeyboardKey.enter),
      ],
      const ScreenIntent(ScreenAction.save)),
  ShortcutDef(
      'En Control de comidas',
      'Enter',
      'Marcar a la primera persona de la lista (como el botón «Marcar»)',
      [],
      const ScreenIntent(ScreenAction.save)),
  ShortcutDef(
      'En Control de comidas',
      'Ctrl+Z',
      'Deshacer la última marca (la que aparece en el aviso verde)',
      [_ctrl(LogicalKeyboardKey.keyZ)],
      const ScreenIntent(ScreenAction.undo)),
];

/// «/» a secas lleva al buscador (solo fuera de los campos de texto).
const _slashSearch = SingleActivator(LogicalKeyboardKey.slash);
const _backspaceBack = SingleActivator(LogicalKeyboardKey.backspace);

bool _typingInTextField() {
  final ctx = FocusManager.instance.primaryFocus?.context;
  return ctx != null &&
      ctx.findAncestorStateOfType<EditableTextState>() != null;
}

class _ScreenActionHandler extends Action<ScreenIntent> {
  @override
  bool isEnabled(ScreenIntent intent) =>
      ShortcutRegistry.instance.handlerFor(intent.action) != null &&
      !(intent.outsideTextOnly && _typingInTextField());

  @override
  Object? invoke(ScreenIntent intent) {
    ShortcutRegistry.instance.handlerFor(intent.action)?.call();
    return null;
  }
}

class _NavigateHandler extends Action<NavigateIntent> {
  @override
  bool isEnabled(NavigateIntent intent) =>
      ShortcutRegistry.instance.canNavigate;

  @override
  Object? invoke(NavigateIntent intent) {
    ShortcutRegistry.instance.navigate(intent.page);
    return null;
  }
}

class _HelpHandler extends Action<HelpIntent> {
  _HelpHandler(this.navigatorKey);
  final GlobalKey<NavigatorState> navigatorKey;
  @override
  Object? invoke(HelpIntent intent) {
    final ctx = navigatorKey.currentContext;
    if (ctx != null) showShortcutsHelp(ctx);
    return null;
  }
}

/// Atajos de teclado de escritorio y Esc/Atrás. Se coloca ENCIMA del navegador (en
/// `MaterialApp.builder`); [navigatorKey] y [observer] son los del `MaterialApp`.
class AppKeyboard extends StatelessWidget {
  const AppKeyboard(
      {super.key,
      required this.navigatorKey,
      required this.observer,
      required this.child});
  final GlobalKey<NavigatorState> navigatorKey;
  final TopRouteObserver observer;
  final Widget child;

  @override
  Widget build(BuildContext context) => Shortcuts(
        shortcuts: <ShortcutActivator, Intent>{
          for (final d in appShortcutDefs)
            for (final a in d.activators) a: d.intent,
          _slashSearch:
              const ScreenIntent(ScreenAction.search, outsideTextOnly: true),
          _backspaceBack: const GoBackIntent(outsideTextOnly: true),
        },
        child: Actions(
          actions: {
            GoBackIntent: GoBackAction(navigatorKey, observer),
            ScreenIntent: _ScreenActionHandler(),
            NavigateIntent: _NavigateHandler(),
            HelpIntent: _HelpHandler(navigatorKey),
          },
          // Con autofocus, si nada tiene el foco (nadie tocó un campo) las teclas llegan igual.
          child: Focus(autofocus: true, skipTraversal: true, child: child),
        ),
      );
}

/// Ayuda con todos los atajos (F1 o Ctrl+/).
Future<void> showShortcutsHelp(BuildContext context) {
  final groups = <String, List<ShortcutDef>>{};
  for (final d in appShortcutDefs) {
    // Ctrl+1…6 se resumen en una sola línea.
    if (d.intent is NavigateIntent && d.keys != 'Ctrl+1') continue;
    (groups[d.group] ??= []).add(d);
  }
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      key: const Key('atajos-dialogo'),
      title: const Text('Atajos de teclado'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(
                'Para el teclado de escritorio. Las teclas de una pantalla solo valen si esa pantalla está abierta.',
                style: TextStyle(color: Brand.gris)),
            for (final g in groups.entries) ...[
              const SizedBox(height: 14),
              Text(g.key, style: bodyStyle(17, weight: FontWeight.w800)),
              const SizedBox(height: 4),
              for (final d in g.value)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _KeyCap(d.intent is NavigateIntent
                            ? 'Ctrl+1 … Ctrl+6'
                            : d.keys),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(d.intent is NavigateIntent
                                ? 'Ir a Panel, Asistentes, Comidas, Equipos, Hospedajes o Iglesias'
                                : d.description)),
                      ]),
                ),
            ],
          ]),
        ),
      ),
      actions: [
        FilledButton(
            key: const Key('atajos-cerrar'),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido')),
      ],
    ),
  );
}

class _KeyCap extends StatelessWidget {
  const _KeyCap(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 150, maxWidth: 170),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: Brand.azulSuave,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Brand.azul)),
          child: Text(text,
              textAlign: TextAlign.center,
              style: bodyStyle(15, weight: FontWeight.w700, color: Brand.azul)),
        ),
      );
}
