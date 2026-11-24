import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers.dart';

Future<Ctx> _open(WidgetTester t) async {
  final c = await pumpApp(t, const Size(1200, 2400));
  await t.runAsync(() async {
    await c.repo.createEvent(
        name: 'Retiro',
        startDate: '2026-12-12',
        endDate: '2026-12-14',
        offersTeams: false,
        offersLodging: false);
    await c.repo.createChurch(
        name: 'Bautista Ebenezer',
        province: 'Matanzas',
        municipality: 'Cárdenas');
  });
  await login(t, 'admin', 'secreto1');
  await t.tap(find.text('Retiro'));
  await settle(t);
  await goRegister(t);
  await settle(t);
  return c;
}

bool _hasFocus(WidgetTester t, String key) => t
    .widget<EditableText>(find.descendant(
        of: find.byKey(Key(key)), matching: find.byType(EditableText)))
    .focusNode
    .hasPrimaryFocus;

Future<void> _tab(WidgetTester t) async {
  await t.sendKeyEvent(LogicalKeyboardKey.tab);
  await t.pump();
}

void main() {
  testWidgets('los campos obligatorios llevan * y los opcionales lo dicen',
      (t) async {
    await _open(t);
    for (final l in [
      'Nombre *',
      'Primer apellido *',
      'Sexo *',
      'Edad *',
      'Iglesia *'
    ]) {
      expect(find.text(l), findsOneWidget, reason: l);
    }
    expect(find.text('Segundo apellido (opcional)'), findsOneWidget);
    expect(find.text('Teléfono (opcional)'), findsOneWidget);
  });

  testWidgets(
      'Tab solo recorre los campos en orden y la iglesia se elige con el teclado',
      (t) async {
    final c = await _open(t);
    expect(_hasFocus(t, 'f-nombre'), isTrue); // arranca en el nombre
    await t.enterText(find.byKey(const Key('f-nombre')), 'Lucía');
    await _tab(t);
    expect(_hasFocus(t, 'f-apellido1'), isTrue);
    await _tab(t);
    expect(_hasFocus(t, 'f-apellido2'), isTrue);
    await _tab(t); // lista de sexo
    expect(_hasFocus(t, 'f-nombre'), isFalse);
    await _tab(t);
    expect(_hasFocus(t, 'f-edad'), isTrue);
    await _tab(t);
    expect(_hasFocus(t, 'f-telefono'), isTrue);
    await _tab(t);
    expect(_hasFocus(t, 'f-iglesia'), isTrue);

    // Escribe la iglesia y sale con Tab: queda elegida sin tocar la lista de sugerencias.
    await t.enterText(find.byKey(const Key('f-iglesia')), 'Bautista');
    await t.pump();
    expect(find.byKey(const Key('iglesia-bautista ebenezer')), findsOneWidget);
    await _tab(t);
    await settle(t);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const Key('f-provincia')),
            matching: find.text('Matanzas')),
        findsOneWidget);
    expect(c, isNotNull);
  });

  testWidgets('provincia y municipio vienen de la iglesia y no se editan',
      (t) async {
    final c = await _open(t);
    await enter(t, 'f-nombre', 'Lucía');
    await enter(t, 'f-apellido1', 'Gómez');
    await pickSex(t, woman: true);
    await enter(t, 'f-edad', '25');
    await enter(t, 'f-iglesia', 'Bautista');
    await settle(t);
    await tapKey(t, 'iglesia-bautista ebenezer');
    expect(
        find.byType(TextField).evaluate().where((e) {
          final k = e.widget.key;
          return k == const Key('f-municipio') || k == const Key('f-provincia');
        }),
        isEmpty);
    await tapKey(t, 'f-guardar');
    final r =
        (await t.runAsync(() => c.db.select(c.db.attendees).get()))!.single;
    expect((r.province, r.municipality), ('Matanzas', 'Cárdenas'));
  });
}
