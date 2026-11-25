// Atajos de teclado de escritorio y su ayuda.
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento/data/meal_repo.dart';
import 'package:mi_evento/data/repos_b.dart';
import 'package:mi_evento/export/file_saver.dart';
import 'package:mi_evento/providers.dart';
import 'package:mi_evento/ui/shortcuts.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'helpers.dart';

const _pc = Size(1200, 2400);

Future<void> ctrl(WidgetTester t, LogicalKeyboardKey k,
    {bool shift = false}) async {
  await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  if (shift) await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await t.sendKeyEvent(k);
  if (shift) await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await settle(t);
}

Future<void> key(WidgetTester t, LogicalKeyboardKey k) async {
  await t.sendKeyEvent(k);
  await settle(t);
}

Future<Ctx> open(WidgetTester t,
    {MemoryFileSaver? saver, bool teams = true, bool lodging = false}) async {
  final c = await pumpApp(t, _pc, overrides: [
    if (saver != null) fileSaverProvider.overrideWithValue(saver),
  ]);
  await t.runAsync(() async {
    final ev = await c.repo.createEvent(
        name: 'Retiro',
        startDate: '2026-12-12',
        endDate: '2026-12-14',
        offersTeams: teams);
    await c.repo.addAttendee(
        eventId: ev,
        firstName: 'Ana',
        lastName1: 'Pérez',
        sex: Sex.female,
        age: 30);
    if (lodging) {
      await LodgingRepo(c.db).save(
          eventId: ev,
          name: 'Casa Norte',
          kind: 'shelter',
          capacity: 3,
          accepts: LodgingAccepts.any);
    }
  });
  await login(t, 'admin', 'secreto1');
  await t.tap(find.text('Retiro'));
  await settle(t);
  return c;
}

void main() {
  group('ayuda', () {
    testWidgets('F1 y Ctrl+/ abren la ayuda y Esc la cierra', (t) async {
      await open(t);
      await key(t, LogicalKeyboardKey.f1);
      expect(find.byKey(const Key('atajos-dialogo')), findsOneWidget);
      await key(t, LogicalKeyboardKey.escape);
      expect(find.byKey(const Key('atajos-dialogo')), findsNothing);
      await ctrl(t, LogicalKeyboardKey.slash);
      expect(find.byKey(const Key('atajos-dialogo')), findsOneWidget);
      await tapKey(t, 'atajos-cerrar');
      expect(find.byKey(const Key('atajos-dialogo')), findsNothing);
    });

    testWidgets(
        'también se abre desde la barra lateral y lista TODOS los atajos',
        (t) async {
      await open(t);
      await tapKey(t, 'atajos-ayuda');
      final dialog = find.byKey(const Key('atajos-dialogo'));
      final shown = t
          .widgetList<Text>(
              find.descendant(of: dialog, matching: find.byType(Text)))
          .map((w) => w.data ?? '')
          .join('\n');
      for (final d in appShortcutDefs) {
        if (d.intent is NavigateIntent) continue;
        expect(shown, contains(d.keys), reason: d.description);
        expect(shown, contains(d.description));
      }
      expect(shown, contains('Ctrl+1 … Ctrl+6'));
    });
  });

  group('navegar y volver', () {
    testWidgets(
        'Ctrl+2/5 cambian de sección; Ctrl+4 no hace nada si no hay equipos',
        (t) async {
      await open(t, teams: false);
      await ctrl(t, LogicalKeyboardKey.digit5);
      expect(find.byKey(const Key('hosp-nuevo')), findsOneWidget);
      await ctrl(t, LogicalKeyboardKey.digit2);
      expect(find.byKey(const Key('asis-registrar')), findsOneWidget);
      await ctrl(
          t, LogicalKeyboardKey.digit4); // Equipos: este evento no los usa
      expect(find.byKey(const Key('asis-registrar')), findsOneWidget);
    });

    testWidgets('con un formulario encima las teclas de sección no actúan',
        (t) async {
      await open(t);
      await ctrl(t, LogicalKeyboardKey.digit5);
      await tapKey(t, 'hosp-nuevo');
      expect(find.byKey(const Key('lf-nombre')), findsOneWidget);
      await ctrl(t, LogicalKeyboardKey.digit2);
      expect(find.byKey(const Key('lf-nombre')), findsOneWidget);
    });

    testWidgets(
        'Retroceso vuelve atrás fuera de un campo, pero dentro de un campo borra; Alt+← vuelve siempre',
        (t) async {
      await open(t);
      await ctrl(t, LogicalKeyboardKey.digit5);
      await tapKey(t, 'hosp-nuevo');
      await t.tap(find.byKey(const Key('lf-nombre')));
      await t.pump();
      await key(t, LogicalKeyboardKey.backspace);
      expect(find.byKey(const Key('lf-nombre')), findsOneWidget,
          reason: 'escribiendo, Retroceso no navega');
      // Alt+← sí vuelve, incluso desde un campo.
      await t.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await t.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await settle(t);
      expect(find.byKey(const Key('lf-nombre')), findsNothing);
      // Fuera de un campo, Retroceso vuelve.
      await tapKey(t, 'hosp-nuevo');
      FocusManager.instance.primaryFocus?.unfocus();
      await t.pump();
      await key(t, LogicalKeyboardKey.backspace);
      expect(find.byKey(const Key('lf-nombre')), findsNothing);
    });
  });

  group('en las pantallas', () {
    testWidgets('Ctrl+N abre «Nuevo», Ctrl+S guarda (valida) y Esc vuelve',
        (t) async {
      await open(t);
      await ctrl(t, LogicalKeyboardKey.digit5);
      await ctrl(t, LogicalKeyboardKey.keyN);
      expect(find.byKey(const Key('lf-nombre')), findsOneWidget);
      await ctrl(t, LogicalKeyboardKey.keyS);
      expect(find.text('Falta el nombre del hospedaje.'), findsOneWidget);
      await enter(t, 'lf-nombre', 'Casa Sur');
      await ctrl(t, LogicalKeyboardKey.enter);
      expect(find.byKey(const Key('lf-nombre')), findsNothing);
      expect(find.byKey(const Key('hosp-Casa Sur')), findsOneWidget);
    });

    testWidgets('Ctrl+F lleva al buscador y Ctrl+Mayús+F abre los filtros',
        (t) async {
      await open(t);
      await ctrl(t, LogicalKeyboardKey.digit2);
      await ctrl(t, LogicalKeyboardKey.keyF);
      expect(
          t
              .widget<TextField>(find.byKey(const Key('buscar')))
              .focusNode!
              .hasFocus,
          isTrue);
      await ctrl(t, LogicalKeyboardKey.keyF, shift: true);
      expect(find.byKey(const Key('filtros-ver')), findsOneWidget);
      await key(t, LogicalKeyboardKey.escape);
      expect(find.byKey(const Key('filtros-ver')), findsNothing);
    });

    testWidgets('Ctrl+E exporta y no hace nada si no hay nada que exportar',
        (t) async {
      final saver = MemoryFileSaver();
      await open(t, saver: saver);
      await ctrl(t, LogicalKeyboardKey.digit5);
      await ctrl(t, LogicalKeyboardKey.keyE); // sin hospedajes: deshabilitado
      expect(saver.saved, isEmpty);
      await ctrl(t, LogicalKeyboardKey.digit2);
      await ctrl(t, LogicalKeyboardKey.keyE);
      expect(saver.saved.keys.single, startsWith('asistentes'));
    });

    testWidgets('Comidas: Ctrl+Z deshace la última marca', (t) async {
      final c = await open(t);
      await ctrl(t, LogicalKeyboardKey.digit3);
      await tapKey(t, 'cm-nueva');
      await tapKey(t, 'ns-crear');
      await enter(t, 'cm-buscar', 'ana');
      await tapKey(t, 'cm-marcar-1');
      expect(find.byKey(const Key('cm-ok')), findsOneWidget);
      await ctrl(t, LogicalKeyboardKey.keyZ);
      expect(find.byKey(const Key('cm-ok')), findsNothing);
      final recs = (await t.runAsync(() async {
        final sid = (await c.db.select(c.db.controlSessions).getSingle()).id;
        return MealRepo(c.db).watchRecords(sid).first;
      }))!;
      expect(recs, isEmpty, reason: 'la marca quedó deshecha');
    });
  });
}
