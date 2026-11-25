import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// Un aviso de la app («CSV guardado», «Contraseña cambiada», un error…).
class AppNotice {
  AppNotice(this.id, this.text, this.time, {this.error = false});
  final int id;
  final String text;
  final DateTime time;
  final bool error;
  bool read = false;
}

/// Centro de notificaciones de ESCRITORIO: los avisos que en el móvil salen un momento abajo
/// quedan aquí, ordenados, hasta que se marcan como leídos.
class NotificationCenter extends ChangeNotifier {
  NotificationCenter._();
  static final instance = NotificationCenter._();

  final List<AppNotice> _items = [];
  int _next = 1;

  /// Más recientes primero.
  List<AppNotice> get items => List.unmodifiable(_items);
  int get unread => _items.where((n) => !n.read).length;

  /// Se guardan como mucho 100 (los más antiguos se descartan).
  AppNotice add(String text, {bool error = false}) {
    final n = AppNotice(_next++, text, DateTime.now(), error: error);
    _items.insert(0, n);
    if (_items.length > 100) _items.removeLast();
    notifyListeners();
    return n;
  }

  void markRead(AppNotice n) {
    if (n.read) return;
    n.read = true;
    notifyListeners();
  }

  void markAllRead() {
    for (final n in _items) {
      n.read = true;
    }
    notifyListeners();
  }

  void removeRead() {
    _items.removeWhere((n) => n.read);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}

/// Ancho desde el que la app usa el diseño de escritorio (igual que las tablas).
bool isDesktopWidth(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= 900;

extension AppNotices on ScaffoldMessengerState {
  /// Avisa de algo. En ESCRITORIO va al centro de notificaciones (campana con contador) en vez de
  /// salir abajo; en móvil sale abajo como siempre. Un aviso con acción («Deshacer») sale abajo
  /// también en escritorio, porque se puede perder a tiempo, y además queda anotado.
  void notice(String text,
      {SnackBarAction? action, Duration? duration, bool error = false}) {
    final desktop = isDesktopWidth(context);
    if (desktop) NotificationCenter.instance.add(text, error: error);
    if (!desktop || action != null) {
      hideCurrentSnackBar();
      showSnackBar(SnackBar(
          content: Text(text),
          action: action,
          duration: duration ?? const Duration(seconds: 4)));
    }
  }
}

/// Círculo naranja con el número de avisos sin leer.
class NotificationBadge extends StatelessWidget {
  const NotificationBadge(this.count, {super.key});
  final int count;
  @override
  Widget build(BuildContext context) => Container(
        key: const Key('campana-contador'),
        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
        padding: const EdgeInsets.symmetric(horizontal: 5),
        alignment: Alignment.center,
        decoration:
            const BoxDecoration(color: Brand.naranja, shape: BoxShape.circle),
        child: Text(count > 99 ? '99+' : '$count',
            style: bodyStyle(12, color: Brand.tinta, weight: FontWeight.w800)),
      );
}

/// Campana con el número de avisos sin leer; abre el panel de notificaciones.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key, this.color});
  final Color? color;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: NotificationCenter.instance,
        builder: (context, _) {
          final n = NotificationCenter.instance.unread;
          return Semantics(
            label: n == 0
                ? 'Notificaciones'
                : 'Notificaciones, ${n == 1 ? '1 sin leer' : '$n sin leer'}',
            button: true,
            excludeSemantics: true,
            child: IconButton(
              key: const Key('campana'),
              tooltip:
                  n == 0 ? 'Notificaciones' : 'Notificaciones ($n sin leer)',
              onPressed: () => showNotificationsPanel(context),
              icon: Stack(clipBehavior: Clip.none, children: [
                Icon(n == 0 ? Icons.notifications_none : Icons.notifications,
                    color: color),
                if (n > 0)
                  Positioned(right: -8, top: -8, child: NotificationBadge(n)),
              ]),
            ),
          );
        },
      );
}

String _hhmm(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// Panel con todos los avisos: tocar uno lo marca como leído.
Future<void> showNotificationsPanel(BuildContext context) => showDialog<void>(
      context: context,
      builder: (ctx) => const _NotificationsDialog(),
    );

class _NotificationsDialog extends StatelessWidget {
  const _NotificationsDialog();

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: NotificationCenter.instance,
        builder: (context, _) {
          final c = NotificationCenter.instance;
          final items = c.items;
          return AlertDialog(
            key: const Key('notificaciones-panel'),
            title: Row(children: [
              const Expanded(child: Text('Notificaciones')),
              Text(c.unread == 0 ? 'Todo leído' : '${c.unread} sin leer',
                  key: const Key('notificaciones-resumen'),
                  style: bodyStyle(15, color: Brand.gris)),
            ]),
            content: SizedBox(
              width: 520,
              height: 420,
              child: items.isEmpty
                  ? const Center(
                      child: Text('No hay notificaciones.',
                          key: Key('notificaciones-vacio'),
                          style: TextStyle(color: Brand.gris)))
                  : ListView(children: [
                      for (final n in items)
                        Card(
                          color: n.read ? null : Brand.azulSuave,
                          child: ListTile(
                            key: Key('notificacion-${n.id}'),
                            onTap: () => c.markRead(n),
                            leading: Icon(
                                n.error
                                    ? Icons.error_outline
                                    : Icons.info_outline,
                                color: n.error ? Brand.error : Brand.azul),
                            title: Text(n.text,
                                style: TextStyle(
                                    fontWeight: n.read
                                        ? FontWeight.w400
                                        : FontWeight.w700)),
                            subtitle: Text(_hhmm(n.time)),
                            trailing: n.read
                                ? const Icon(Icons.check, color: Brand.exito)
                                : TextButton(
                                    key: Key('notificacion-leer-${n.id}'),
                                    onPressed: () => c.markRead(n),
                                    child: const Text('Marcar leída')),
                          ),
                        ),
                    ]),
            ),
            actions: [
              TextButton(
                  key: const Key('notificaciones-borrar-leidas'),
                  onPressed: items.any((n) => n.read) ? c.removeRead : null,
                  child: const Text('Borrar las leídas')),
              TextButton(
                  key: const Key('notificaciones-marcar-todas'),
                  onPressed: c.unread == 0 ? null : c.markAllRead,
                  child: const Text('Marcar todas como leídas')),
              FilledButton(
                  key: const Key('notificaciones-cerrar'),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar')),
            ],
          );
        },
      );
}
