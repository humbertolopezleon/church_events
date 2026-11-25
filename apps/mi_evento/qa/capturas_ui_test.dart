// CAPTURAS DE LA INTERFAZ (NO corre en el CI: está fuera de `test/`).
//
//   cd apps/mi_evento && QA_SHOTS_DIR=/ruta/salida flutter test qa/capturas_ui_test.dart
//
// Arranca la app real con datos de prueba, con las fuentes reales (Atkinson, Nunito e iconos) y
// guarda PNG de cada pantalla a 390×844 dp (móvil), con letra normal y al 130 %, y a 1366×768
// (escritorio).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart'
    show FocusHighlightStrategy, FocusManager, SingleChildScrollView;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/helpers.dart';
import '../test/qa/qa_support.dart';

final outDir = Directory(Platform.environment['QA_SHOTS_DIR'] ??
    '${Directory.systemTemp.path}/mievento_capturas')
  ..createSync(recursive: true);

Future<void> _loadFonts() async {
  Future<void> family(String name, List<String> assets) async {
    final l = FontLoader(name);
    for (final a in assets) {
      l.addFont(rootBundle.load(a));
    }
    await l.load();
  }

  await family('Atkinson', [
    'assets/fonts/AtkinsonHyperlegible-Regular.ttf',
    'assets/fonts/AtkinsonHyperlegible-Bold.ttf',
  ]);
  await family('Nunito', ['assets/fonts/Nunito-Variable.ttf']);
  final icons = File(
      '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter'}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  final l = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
  await l.load();
}

/// Guarda la pantalla actual como PNG (2× para que se lea bien).
Future<void> shot(WidgetTester t, String name) async {
  await t.pump(const Duration(milliseconds: 300));
  final bytes = await t.runAsync(() async {
    final rv = t.binding.renderViews.first;
    final layer = rv.debugLayer! as OffsetLayer;
    final image = await layer.toImage(rv.paintBounds, pixelRatio: 2);
    return (await image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  });
  File('${outDir.path}/$name.png').writeAsBytesSync(bytes!);
}

const _movil = Size(390, 844);
const _pc = Size(1366, 768);

/// Evento con [n] personas, hospedajes, equipos y un par de preinscritos.
Future<void> _datos(Ctx c, {int n = 14}) async {
  final q = await qaEvent(c.db, teams: 3);
  await qaInscribeAll(q, qaPeople(n, couples: 2));
  await qaLodgings(q, scale: 0.6);
  await qaSuggestAndAccept(q);
  final todos = await q.people();
  // Algunos quedan sin hospedaje para ver la etiqueta ámbar.
  await q.lodgings.unassign(
      [for (final p in todos.where((p) => p.lodgingId != null).take(4)) p.id]);
  await c.repo.unconfirmAttendance([todos[0].id, todos[3].id]);
}

Future<Ctx> _abrir(WidgetTester t, Size size,
    {bool datos = true, double escala = 1.0}) async {
  t.platformDispatcher.textScaleFactorTestValue = escala;
  addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
  final c = await pumpApp(t, size, defaultAdmin: true);
  await t.runAsync(() async {
    if (datos) {
      await _datos(c);
    } else {
      await c.repo.createEvent(
          name: 'Congreso 2026',
          startDate: '2026-12-11',
          endDate: '2026-12-13');
    }
  });
  await login(t, 'admin', 'admin');
  await t.tap(find.textContaining('Congreso').first);
  await settle(t);
  return c;
}

Future<void> _ir(WidgetTester t, String label) async {
  if (find.text(label).evaluate().isEmpty &&
      find.text('Más').evaluate().isNotEmpty) {
    await t.tap(find.text('Más').first);
    await settle(t);
  }
  await t.tap(find.text(label).first);
  await settle(t);
}

/// Prueba de captura: el banco de pruebas pinta las sombras como bloques negros; aquí se dibujan
/// de verdad (y se restaura al terminar, antes de que el banco revise sus invariantes).
void cap(String name, Future<void> Function(WidgetTester t) body) =>
    testWidgets(name, (t) async {
      debugDisableShadows = false;
      try {
        await body(t);
      } finally {
        debugDisableShadows = true;
      }
    });

void main() {
  setUpAll(_loadFonts);
  setUp(() {
    // Como en un teléfono: sin anillo de foco de teclado alrededor del botón flotante.
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTouch;
  });

  group('Fase 2 · Asistentes', () {
    cap('móvil con datos, filtros y letra al 130 %', (t) async {
      await _abrir(t, _movil);
      await _ir(t, 'Asistentes');
      await shot(t, 'asistentes-movil-datos');
      await openFilters(t);
      await shot(t, 'asistentes-movil-filtros');
      await t.tap(find.text('Por confirmar'));
      await settle(t);
      await shot(t, 'asistentes-movil-filtros-elegido');
      await closeFilters(t);
      await shot(t, 'asistentes-movil-filtro-activo');
    });

    cap('móvil con letra al 130 %', (t) async {
      await _abrir(t, _movil, escala: 1.3);
      await _ir(t, 'Asistentes');
      await shot(t, 'asistentes-movil-letra130');
    });

    cap('móvil vacía y ayuda del CSV', (t) async {
      await _abrir(t, _movil, datos: false);
      await _ir(t, 'Asistentes');
      await shot(t, 'asistentes-movil-vacia');
      await tapKey(t, 'asis-vacio-ayuda');
      await shot(t, 'asistentes-movil-vacia-ayuda');
    });

    cap('escritorio con datos', (t) async {
      await _abrir(t, _pc);
      await _ir(t, 'Asistentes');
      await shot(t, 'asistentes-escritorio');
    });
  });

  group('Fase 3 · Iglesias y Hospedajes', () {
    cap('móvil Iglesias', (t) async {
      await _abrir(t, _movil);
      await _ir(t, 'Iglesias');
      await shot(t, 'iglesias-movil-datos');
      await openFilters(t);
      await shot(t, 'iglesias-movil-filtros');
    });
    cap('móvil Hospedajes con datos y letra al 130 %', (t) async {
      await _abrir(t, _movil);
      await _ir(t, 'Hospedajes');
      await shot(t, 'hospedajes-movil-datos');
    });
    cap('móvil Hospedajes al 130 %', (t) async {
      await _abrir(t, _movil, escala: 1.3);
      await _ir(t, 'Hospedajes');
      await shot(t, 'hospedajes-movil-letra130');
    });
    cap('móvil Hospedajes vacía', (t) async {
      await _abrir(t, _movil, datos: false);
      await _ir(t, 'Hospedajes');
      await shot(t, 'hospedajes-movil-vacia');
    });
    cap('móvil Hospedajes aviso → Asistentes filtrados', (t) async {
      await _abrir(t, _movil);
      await _ir(t, 'Hospedajes');
      await tapKey(t, 'hosp-resumen');
      await shot(t, 'hospedajes-aviso-asistentes-filtrados');
    });
    cap('escritorio Iglesias y Hospedajes', (t) async {
      await _abrir(t, _pc);
      await _ir(t, 'Iglesias');
      await shot(t, 'iglesias-escritorio');
      await _ir(t, 'Hospedajes');
      await shot(t, 'hospedajes-escritorio');
    });
  });

  group('Fase 4 · Nuevo hospedaje', () {
    cap('móvil formulario', (t) async {
      await _abrir(t, _movil, datos: false);
      await _ir(t, 'Hospedajes');
      await tapKey(t, 'hosp-nuevo');
      await shot(t, 'nuevo-hospedaje-albergue');
      await t.tap(find.text('Casa particular'));
      await t.pump();
      await tapKey(t, 'lf-mas');
      await tapKey(t, 'lf-mas');
      await tapKey(t, 'lf-acepta-couples');
      await shot(t, 'nuevo-hospedaje-casa');
      await t.drag(
          find.byType(SingleChildScrollView).last, const Offset(0, -700));
      await t.pump();
      await shot(t, 'nuevo-hospedaje-casa-abajo');
      await tapKey(t, 'lf-guardar');
      await shot(t, 'nuevo-hospedaje-errores');
    });
    cap('móvil formulario al 130 %', (t) async {
      await _abrir(t, _movil, datos: false, escala: 1.3);
      await _ir(t, 'Hospedajes');
      await tapKey(t, 'hosp-nuevo');
      await shot(t, 'nuevo-hospedaje-letra130');
    });
    cap('escritorio formulario', (t) async {
      await _abrir(t, _pc, datos: false);
      await _ir(t, 'Hospedajes');
      await tapKey(t, 'hosp-nuevo');
      await shot(t, 'nuevo-hospedaje-escritorio');
    });
  });

  group('Fase 5 · todas las pantallas', () {
    const pantallas = {
      'panel': 'Panel',
      'asistentes': 'Asistentes',
      'confirmar': 'Confirmar asistencia',
      'hospedajes': 'Hospedajes',
      'equipos': 'Equipos',
      'comidas': 'Comidas',
      'reportes': 'Reportes',
      'iglesias': 'Iglesias',
      'usuarios': 'Usuarios',
      'configuracion': 'Configuración',
      'copias': 'Copias de seguridad',
    };
    for (final e in {'normal': 1.0, 'letra130': 1.3}.entries) {
      cap('móvil con datos · ${e.key}', (t) async {
        await _abrir(t, _movil, escala: e.value);
        for (final p in pantallas.entries) {
          await _ir(t, p.value);
          await shot(t, 'todas-${p.key}-${e.key}');
        }
        await _ir(t, 'Asistentes');
        await openFilters(t);
        await shot(t, 'todas-asistentes-hoja-filtros-${e.key}');
        await closeFilters(t);
        await _ir(t, 'Iglesias');
        await openFilters(t);
        await shot(t, 'todas-iglesias-hoja-filtros-${e.key}');
      });
    }
    cap('móvil vacías', (t) async {
      await _abrir(t, _movil, datos: false);
      for (final p in ['Hospedajes', 'Equipos', 'Iglesias', 'Comidas']) {
        await _ir(t, p);
        await shot(t, 'vacia-${p.toLowerCase()}');
      }
    });
    cap('escritorio con datos', (t) async {
      await _abrir(t, _pc);
      for (final p in ['Asistentes', 'Equipos']) {
        await _ir(t, p);
        await shot(t, 'escritorio-${p.toLowerCase()}');
      }
    });
  });

  group('Fase 6 · etiquetas encima del campo', () {
    cap('inicio de sesión', (t) async {
      await pumpApp(t, _movil, defaultAdmin: true);
      await shot(t, 'etiquetas-login');
    });
    cap('formulario de asistente', (t) async {
      await _abrir(t, _movil);
      await _ir(t, 'Asistentes');
      await tapKey(t, 'asis-registrar');
      await shot(t, 'etiquetas-asistente-1');
      await t.drag(
          find.byType(SingleChildScrollView).last, const Offset(0, -600));
      await t.pump();
      await shot(t, 'etiquetas-asistente-2');
    });
    cap('formulario de asistente al 130 %', (t) async {
      await _abrir(t, _movil, escala: 1.3);
      await _ir(t, 'Asistentes');
      await tapKey(t, 'asis-registrar');
      await shot(t, 'etiquetas-asistente-letra130');
    });
    cap('nuevo usuario y generar equipos', (t) async {
      await _abrir(t, _movil);
      await _ir(t, 'Usuarios');
      await t.tap(find.text('Nuevo usuario').first);
      await settle(t);
      await shot(t, 'etiquetas-usuario');
    });
  });

  group('Importar/exportar · plantilla y ayuda de columnas', () {
    cap('móvil: menú ⋮, columnas y estados vacíos', (t) async {
      await _abrir(t, _movil, datos: false);
      for (final e in {'Hospedajes': 'hosp', 'Equipos': 'eq', 'Iglesias': 'ig'}
          .entries) {
        await _ir(t, e.key);
        await shot(t, 'plantilla-vacia-${e.value}');
        await t.tap(find.byKey(const Key('menu-csv')));
        await settle(t);
        await shot(t, 'plantilla-menu-${e.value}');
        await t.tap(find.byKey(Key('${e.value}-columnas')));
        await settle(t);
        await shot(t, 'plantilla-columnas-${e.value}');
        await t.tap(find.text('Entendido'));
        await settle(t);
      }
    });
    cap('móvil: columnas de hospedajes al 130 %', (t) async {
      await _abrir(t, _movil, datos: false, escala: 1.3);
      await _ir(t, 'Hospedajes');
      await tapKey(t, 'hosp-columnas');
      await shot(t, 'plantilla-columnas-hosp-letra130');
    });
    cap('escritorio: Hospedajes vacía y columnas', (t) async {
      await _abrir(t, _pc, datos: false);
      await _ir(t, 'Hospedajes');
      await shot(t, 'plantilla-escritorio-hosp');
      await tapKey(t, 'hosp-columnas');
      await shot(t, 'plantilla-escritorio-columnas-hosp');
    });
  });
}
