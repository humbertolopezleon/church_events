// Centro de notificaciones de escritorio: los avisos de abajo pasan a una campana con contador.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento/export/file_saver.dart';
import 'package:mi_evento/providers.dart';
import 'package:mi_evento/ui/notifications.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'helpers.dart';

const _pc = Size(1200, 2400);
const _movil = Size(390, 844);

Future<Ctx> _open(WidgetTester t, Size size, {MemoryFileSaver? saver}) async {
  final c = await pumpApp(t, size, overrides: [
    if (saver != null) fileSaverProvider.overrideWithValue(saver),
  ]);
  await t.runAsync(() async {
    final ev = await c.repo.createEvent(
        name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
    await c.repo.addAttendee(
        eventId: ev,
        firstName: 'Ana',
        lastName1: 'Pérez',
        sex: Sex.female,
        age: 30);
  });
  await login(t, 'admin', 'secreto1');
  await t.tap(find.text('Retiro'));
  await settle(t);
  return c;
}

int _unread() => NotificationCenter.instance.unread;

void main() {
  group('NotificationCenter (datos)', () {
    setUp(() => NotificationCenter.instance.clear());

    test(
        'agrega los más recientes primero, cuenta sin leer y marca como leídos',
        () {
      final c = NotificationCenter.instance;
      c.add('uno');
      c.add('dos', error: true);
      expect([for (final n in c.items) n.text], ['dos', 'uno']);
      expect(c.items.first.error, isTrue);
      expect(c.unread, 2);
      c.markRead(c.items.last);
      expect(c.unread, 1);
      c.markAllRead();
      expect(c.unread, 0);
      c.removeRead();
      expect(c.items, isEmpty);
    });

    test('guarda como mucho 100 (se descartan los más antiguos)', () {
      final c = NotificationCenter.instance;
      for (var i = 1; i <= 120; i++) {
        c.add('aviso $i');
      }
      expect(c.items.length, 100);
      expect(c.items.first.text, 'aviso 120');
      expect(c.items.last.text, 'aviso 21');
    });
  });

  group('en pantalla', () {
    testWidgets(
        'escritorio: un aviso NO sale abajo, va a la campana (con contador) y se puede marcar como leído',
        (t) async {
      final saver = MemoryFileSaver();
      await _open(t, _pc, saver: saver);
      await t.tap(find.text('Asistentes').first);
      await settle(t);
      expect(find.byKey(const Key('campana-contador')), findsNothing);
      await tapKey(t, 'exportar-csv'); // «CSV guardado (1 filas).»
      expect(find.byType(SnackBar), findsNothing);
      expect(_unread(), 1);
      expect(find.byKey(const Key('campana-contador')), findsOneWidget);
      // Abrir el panel: el aviso está, sin leer.
      await tapKey(t, 'campana');
      expect(find.byKey(const Key('notificaciones-panel')), findsOneWidget);
      expect(find.textContaining('CSV guardado'), findsOneWidget);
      expect(find.text('1 sin leer'), findsOneWidget);
      // Marcarlo como leído apaga el contador.
      final id = NotificationCenter.instance.items.first.id;
      await tapKey(t, 'notificacion-leer-$id');
      expect(_unread(), 0);
      expect(find.text('Todo leído'), findsOneWidget);
      await tapKey(t, 'notificaciones-cerrar');
      expect(find.byKey(const Key('campana-contador')), findsNothing);
    });

    testWidgets('«Marcar todas como leídas» y «Borrar las leídas»', (t) async {
      await _open(t, _pc);
      NotificationCenter.instance
        ..add('Primero')
        ..add('Segundo', error: true);
      await t.pump();
      await tapKey(t, 'campana');
      expect(find.text('2 sin leer'), findsOneWidget);
      await tapKey(t, 'notificaciones-marcar-todas');
      expect(_unread(), 0);
      expect(find.text('Primero'), findsOneWidget);
      await tapKey(t, 'notificaciones-borrar-leidas');
      expect(find.byKey(const Key('notificaciones-vacio')), findsOneWidget);
    });

    testWidgets(
        'un aviso con «Deshacer» sale abajo también en escritorio y queda anotado',
        (t) async {
      await _open(t, _pc);
      await t.tap(find.text('Confirmar asistencia').first);
      await settle(t);
      // Sin personas preinscritas no hay nada que confirmar: se prueba el helper directamente.
      final messenger =
          ScaffoldMessenger.of(t.element(find.byType(Scaffold).first));
      messenger.notice('Hecho',
          action: SnackBarAction(label: 'Deshacer', onPressed: () {}));
      await t.pump();
      expect(find.text('Deshacer'), findsOneWidget);
      expect(_unread(), 1);
    });

    testWidgets('móvil: el aviso sale abajo como siempre y no hay campana',
        (t) async {
      final saver = MemoryFileSaver();
      await _open(t, _movil, saver: saver);
      final messenger =
          ScaffoldMessenger.of(t.element(find.byType(Scaffold).first));
      messenger.notice('Listo');
      await t.pump();
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.byKey(const Key('campana')), findsNothing);
      expect(_unread(), 0, reason: 'en móvil no se acumulan avisos');
    });

    testWidgets('cerrar sesión borra los avisos', (t) async {
      await _open(t, _pc);
      NotificationCenter.instance.add('Algo');
      await t.pump();
      await tapKey(t, 'cerrar-sesion');
      expect(NotificationCenter.instance.items, isEmpty);
    });
  });
}
