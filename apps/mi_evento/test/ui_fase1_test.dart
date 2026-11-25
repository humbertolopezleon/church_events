import 'dart:ui' show Tristate;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento/theme/app_theme.dart';
import 'package:mi_evento/ui/default_password_banner.dart';
import 'package:mi_evento/ui/widgets/filter_spec.dart';
import 'package:mi_evento/ui/widgets/list_toolbar.dart';
import 'package:mi_evento/ui/widgets/plural.dart';

import 'helpers.dart';

/// Fase 1 de las mejoras de interfaz: plurales, filtros (hoja, chips, contador), tema y aviso.
void main() {
  group('plurales', () {
    test('singular, plural y frases sin «0»', () {
      expect(plural(1, 'iglesia', 'iglesias'), '1 iglesia');
      expect(plural(2, 'iglesia', 'iglesias'), '2 iglesias');
      expect(plural(1, 'plaza libre', 'plazas libres'), '1 plaza libre');
      expect(plural(0, 'inscrito', 'inscritos', zero: 'Nadie inscrito todavía'),
          'Nadie inscrito todavía');
      expect(plural(0, 'plaza', 'plazas'), '0 plazas'); // sin frase propia
      expect(pluralWord(1, 'persona', 'personas'), 'persona');
      expect(agree(3, 'queda', 'quedan'), 'quedan');
    });
  });

  group('filtros', () {
    test('un filtro activo expone su texto; «Limpiar» lo desactiva', () {
      String? sex;
      bool free = false;
      final f1 = ChoiceFilter<String>(
          key: const Key('s'),
          label: 'Sexo',
          value: sex,
          options: const {'M': 'Hombres', 'F': 'Mujeres'},
          onChanged: (v) => sex = v);
      expect(f1.active, isFalse);
      expect(f1.activeText, isNull);
      final f2 = ChoiceFilter<String>(
          key: const Key('s'),
          label: 'Sexo',
          value: 'F',
          options: const {'M': 'Hombres', 'F': 'Mujeres'},
          onChanged: (v) => sex = v);
      expect(f2.activeText, 'Sexo: Mujeres');
      f2.clear();
      expect(sex, isNull);
      final t = ToggleFilter(
          key: const Key('l'),
          label: 'Con plazas libres',
          value: true,
          onChanged: (v) => free = v);
      expect(t.active, isTrue);
      t.clear();
      expect(free, isFalse);
    });

    testWidgets(
        'el contador del botón Filtros coincide con los filtros activos; la hoja da el resultado en vivo y limpia',
        (t) async {
      String? sex, church;
      final ctrl = TextEditingController();
      late StateSetter set;
      List<FilterSpec> specs() => [
            ChoiceFilter<String>(
                key: const Key('f-sexo'),
                label: 'Sexo',
                value: sex,
                options: const {'M': 'Hombres', 'F': 'Mujeres'},
                onChanged: (v) => set(() => sex = v)),
            ChoiceFilter<String>(
                key: const Key('f-iglesia'),
                label: 'Iglesia',
                allLabel: 'Todas',
                wide: true,
                value: church,
                options: const {'a': 'Bautista', 'b': 'Metodista'},
                onChanged: (v) => set(() => church = v)),
          ];
      int results() => 100 - (sex == null ? 0 : 40) - (church == null ? 0 : 30);
      await t.pumpWidget(MaterialApp(
        theme: buildTheme(),
        home: Scaffold(
          body: StatefulBuilder(builder: (c, s) {
            set = s;
            return ListToolbar(
                controller: ctrl,
                hint: 'Nombre',
                onChanged: () {},
                count: '',
                filters: specs,
                resultCount: results,
                resultLabel: (n) =>
                    'Ver ${plural(n, 'asistente', 'asistentes')}');
          }),
        ),
      ));
      expect(find.byKey(const Key('filtros-contador')), findsNothing);
      await t.tap(find.byKey(const Key('filtros-toggle')));
      await t.pumpAndSettle();
      expect(find.text('Ver 100 asistentes'), findsOneWidget);
      expect(find.text('Todas'), findsOneWidget); // femenino para Iglesia
      await t.tap(find.text('Hombres'));
      await t.pumpAndSettle();
      expect(find.text('Ver 60 asistentes'), findsOneWidget);
      // El chip seleccionado lleva ✓ y se anuncia como seleccionado.
      expect(find.byIcon(Icons.check), findsWidgets);
      await t.tap(find.byKey(const Key('filtros-ver')));
      await t.pumpAndSettle();
      expect(find.text('1'), findsOneWidget); // contador naranja
      expect(find.text('Sexo: Hombres'), findsOneWidget); // chip activo
      // Quitar con la X del chip activo.
      await t.tap(find.text('Sexo: Hombres'));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('filtros-contador')), findsNothing);
      expect(sex, isNull);
    });

    testWidgets('los chips de filtro anuncian si están seleccionados',
        (t) async {
      final h = t.ensureSemantics();
      await t.pumpWidget(MaterialApp(
        theme: buildTheme(),
        home: Scaffold(
            body: Column(children: [
          SelectChip(label: 'Mujeres', selected: true, onTap: () {}),
          SelectChip(label: 'Hombres', selected: false, onTap: () {}),
        ])),
      ));
      expect(t.getSemantics(find.text('Mujeres')).flagsCollection.isSelected,
          Tristate.isTrue);
      expect(t.getSemantics(find.text('Hombres')).flagsCollection.isSelected,
          Tristate.isFalse);
      h.dispose();
    });
  });

  group('tema', () {
    test('todos los estilos usan Atkinson (ninguno cae a Roboto)', () {
      final th = buildTheme();
      expect(th.textTheme.bodyLarge!.fontFamily, 'Atkinson');
      expect(th.textTheme.bodyLarge!.fontSize, 18);
      expect(th.textTheme.bodySmall!.fontSize, 15);
      for (final style in [
        th.filledButtonTheme.style!.textStyle!.resolve({}),
        th.outlinedButtonTheme.style!.textStyle!.resolve({}),
        th.textButtonTheme.style!.textStyle!.resolve({}),
        th.dialogTheme.titleTextStyle,
        th.dialogTheme.contentTextStyle,
        th.chipTheme.labelStyle,
        th.popupMenuTheme.textStyle,
        th.inputDecorationTheme.labelStyle,
      ]) {
        expect(style!.fontFamily, 'Atkinson');
      }
      expect(th.appBarTheme.titleTextStyle!.fontFamily, 'Nunito');
      expect(th.appBarTheme.toolbarHeight, 64);
      expect(th.filledButtonTheme.style!.minimumSize!.resolve({})!.height, 56);
    });
  });

  group('aviso de contraseña inicial', () {
    test('«Recordar más tarde» lo oculta solo ese día', () {
      final hoy = DateTime(2026, 11, 25, 10);
      expect(passwordReminderHiddenToday(null, hoy), isFalse);
      expect(
          passwordReminderHiddenToday(DateTime(2026, 11, 25, 8), hoy), isTrue);
      expect(passwordReminderHiddenToday(DateTime(2026, 11, 24, 23), hoy),
          isFalse);
    });

    testWidgets(
        'una línea de 48 dp, la X lo oculta y no vuelve en el mismo día',
        (t) async {
      final c = await pumpApp(t, const Size(411, 890), defaultAdmin: true);
      await login(t, 'admin', 'admin');
      expect(find.text('Contraseña inicial en uso'), findsOneWidget);
      expect(t.getSize(find.byKey(const Key('banner-clave-inicial'))).height,
          lessThan(48));
      expect(find.bySemanticsLabel('Recordar más tarde'), findsWidgets);
      await t.tap(find.byKey(const Key('banner-recordar-despues')));
      await settle(t);
      expect(find.text('Contraseña inicial en uso'), findsNothing);
      final meta =
          (await t.runAsync(() => c.db.select(c.db.appMeta).getSingle()))!;
      expect(meta.passwordReminderHiddenAt, isNotNull);
    });
  });

  testWidgets('con letra al 130 % el buscador y los botones no se desbordan',
      (t) async {
    t.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    final ctrl = TextEditingController();
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListToolbar(
              controller: ctrl,
              hint: 'Nombre, iglesia o número',
              onChanged: () {},
              count: '12 de 248 · más recientes primero',
              filters: () => [
                    ChoiceFilter<String>(
                        key: const Key('x'),
                        label: 'Iglesia',
                        value: 'a',
                        options: const {'a': 'Bautista Ebenezer de Cárdenas'},
                        onChanged: (_) {}),
                    ChoiceFilter<String>(
                        key: const Key('y'),
                        label: 'Sexo',
                        value: 'F',
                        options: const {'F': 'Mujeres'},
                        onChanged: (_) {}),
                  ],
              resultCount: () => 12,
              resultLabel: (n) => 'Ver $n'),
        ),
      ),
    ));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    await t.tap(find.byKey(const Key('filtros-toggle')));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });
}
