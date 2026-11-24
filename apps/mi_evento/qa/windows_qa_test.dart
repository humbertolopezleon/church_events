// QA DE PUNTA A PUNTA «como en Windows» (NO corre en el CI: está fuera de `test/`).
//
//   cd apps/mi_evento && flutter test qa/windows_qa_test.dart > /tmp/qa.log 2>&1 &
//   (QA_FAST=1 para una pasada corta de depuración)
//
// Arranca la app REAL (MiEventoApp) y la maneja por la interfaz con ventana de escritorio
// 1366x768 (y una pasada a 1920x1080). Todo lo que la app exporta por el FileSaver de pruebas se
// guarda en /home/user/my_event/qa-windows-export/. Al terminar escribe INFORME.md ahí mismo.
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show BooleanExpressionOperators, OrderingTerm;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento/backup/backup_service.dart';
import 'package:mi_evento/backup/file_picker.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/meal_repo.dart';
import 'package:mi_evento/data/repos_b.dart' show SocialRepo;
import 'package:mi_evento/data/repository.dart' show DataException;
import 'package:mi_evento/export/file_saver.dart';
import 'package:mi_evento/main.dart' show MiEventoApp;
import 'package:mi_evento/providers.dart';
import 'package:mi_evento/ui/lodging_pdf.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import '../test/helpers.dart';
import '../test/qa/qa_support.dart';
import '../test/qa/qa_ui_support.dart';

const exportDir = '/home/user/my_event/qa-windows-export';
final fast = Platform.environment['QA_FAST'] == '1';

class Ch {
  const Ch(this.name, this.prov, this.muni, this.community);
  final String name, prov, muni, community;
}

/// Iglesias del escenario. 0–5 se crean por la interfaz («Iglesia nueva»); 6–8 las crea el CSV.
const myChurches = <Ch>[
  Ch('Bautista Ebenezer', 'Matanzas', 'Cárdenas', 'Varadero'),
  Ch('Metodista de Colón', 'Matanzas', 'Colón', 'Centro Urbano'),
  Ch('Pentecostal Monte Sión', 'Matanzas', 'Cárdenas', 'Varadero'),
  Ch('Iglesia del Nazareno Peñas Altas', 'La Habana', 'Playa', 'Miramar'),
  Ch('Asambleas de Dios Betel', 'Mayabeque', 'San José de las Lajas',
      'Casa Blanca'),
  Ch('Bautista Getsemaní', 'Matanzas', 'Jovellanos', ''),
  Ch('Presbiteriana La Trinidad', 'Matanzas', 'Perico', ''),
  Ch('Iglesia Evangélica Luz del Mundo', 'Villa Clara', 'Santa Clara', ''),
  Ch('Bautista Nuevo Pacto', 'Cienfuegos', 'Cienfuegos', ''),
];
const kChurch =
    8; // los preinscritos de esta iglesia se dejan sin confirmar hasta el paso 8

class StepRec {
  StepRec(this.id, this.title);
  final String id, title;
  bool failed = false;
  final ev = <String>[];
  Duration took = Duration.zero;
}

class Defect {
  Defect(this.id, this.sev, this.title, this.detail, this.step);
  final String id, sev, title, detail, step;
}

String _s(Object e) {
  final x = e.toString().replaceAll('\n', ' ');
  return x.length > 400 ? '${x.substring(0, 400)}…' : x;
}

// ── Lodgings: (nombre, tipo, capacidad, «acepta», anfitrión) ──
const lodgingDefs = <(String, String, int, String, String)>[
  ('Albergue Central Hombres', 'shelter', 30, 'Solo hombres', ''),
  ('Albergue Escuela Hombres', 'shelter', 25, 'Solo hombres', ''),
  ('Casa Hno. Ramón Cruz', 'private_home', 15, 'Solo hombres', 'Ramón Cruz'),
  (
    'Casa Hno. Osvaldo Díaz',
    'private_home',
    15,
    'Solo hombres',
    'Osvaldo Díaz'
  ),
  ('Casa Hno. Julián Báez', 'private_home', 15, 'Solo hombres', 'Julián Báez'),
  ('Albergue Juvenil Mujeres', 'shelter', 30, 'Solo mujeres', ''),
  ('Albergue Betania Mujeres', 'shelter', 25, 'Solo mujeres', ''),
  ('Casa Hna. Teresa Gil', 'private_home', 15, 'Solo mujeres', 'Teresa Gil'),
  ('Casa Hna. Carmen Soto', 'private_home', 15, 'Solo mujeres', 'Carmen Soto'),
  ('Casa Hna. Ñuri Peña', 'private_home', 15, 'Solo mujeres', 'Ñuri Peña'),
  ('Casa Familia Gómez', 'private_home', 10, 'Matrimonios', 'Pedro Gómez'),
  ('Casa Familia Ortiz', 'private_home', 10, 'Matrimonios', 'Luis Ortiz'),
  ('Casa Familia Ñáñez', 'private_home', 8, 'Matrimonios', 'Rolando Ñáñez'),
  ('Casa Familia Rivas', 'private_home', 8, 'Matrimonios', 'Julio Rivas'),
  ('Casa Familia Núñez', 'private_home', 6, 'Matrimonios', 'Ana Núñez'),
  ('Casa Familia Peña', 'private_home', 6, 'Matrimonios', 'Raúl Peña'),
  ('Posada Betel', 'shelter', 20, 'Sin preferencia', ''),
  ('Casa Pastoral', 'private_home', 12, 'Sin preferencia', 'Pastor Iván'),
  ('Casa Hno. Yunier Acosta', 'private_home', 8, 'Sin preferencia', 'Yunier'),
  ('Casa Hna. Rosa Leyva', 'private_home', 8, 'Sin preferencia', 'Rosa Leyva'),
  ('Posada Monte Sión', 'shelter', 10, 'Sin preferencia', ''),
  ('Casa Hno. Elier Piñeiro', 'private_home', 6, 'Sin preferencia', 'Elier'),
];

void main() {
  testWidgets('QA Windows de punta a punta (1366x768 y 1920x1080)',
      timeout: Timeout.none, (t) async {
    Directory(exportDir).createSync(recursive: true);
    for (final f in Directory(exportDir).listSync()) {
      if (f is File) f.deleteSync(); // corrida limpia
    }

    final steps = <StepRec>[];
    final defects = <Defect>[];
    final metrics = <String, Object>{};
    final limits = <String>[];
    final exported = <(String, int, String)>[];
    StepRec? cur;
    final started = DateTime.now();

    void note(String s) => cur?.ev.add(s);
    void bug(String sev, String title, String detail) {
      if (defects.any((d) => d.title == title)) return;
      defects.add(Defect(
          'QA-WIN-${(defects.length + 1).toString().padLeft(2, '0')}',
          sev,
          title,
          detail,
          cur?.id ?? '-'));
    }

    void ck(bool ok, String what,
        {String? sev, String? title, String? detail}) {
      cur?.ev.add('${ok ? 'OK' : 'FALLA'}: $what');
      if (!ok) {
        cur?.failed = true;
        if (sev != null) bug(sev, title ?? what, detail ?? what);
      }
    }

    // ── Entorno ──
    final saver = MemoryFileSaver();
    final picker = MemoryFilePick();
    final c = await pumpApp(t, const Size(1366, 768), overrides: [
      fileSaverProvider.overrideWithValue(saver),
      filePickProvider.overrideWithValue(picker),
    ]);
    final db = c.db;
    Future<R> rq<R>(Future<R> Function() f) async => (await t.runAsync(f)) as R;

    // A 768 px de alto muchos botones quedan bajo el pliegue: hay que desplazar Y repintar antes de tocar.
    // Si un aviso (SnackBar) tapa el botón, se espera a que desaparezca (como haría una persona).
    var snackNoted = false;
    Future<void> clearSnack(Finder f) async {
      if (find.byType(SnackBar).evaluate().isEmpty) return;
      final sb = t.getRect(find.byType(SnackBar).first);
      final b = t.getRect(f);
      if (b.overlaps(sb)) {
        if (!snackNoted) {
          snackNoted = true;
          bug(
              'Baja',
              'El aviso verde (SnackBar) tapa el botón de acción a 1366x768',
              'Tras «Guardar y registrar otro» el aviso «Listo. … quedó registrado/a como asistente nº N» (4 s) cubre la zona del botón «Guardar y registrar otro»/«Guardar asistente» (botón ${b.top.round()}–${b.bottom.round()} px, aviso ${sb.top.round()}–${sb.bottom.round()} px en una ventana de 768 px de alto): un toque inmediato cae sobre el aviso y no guarda. Con registro seguido a mano rara vez molesta (escribir tarda más de 4 s), pero en la prueba hizo fallar el segundo guardado inmediato.');
        }
        await t.pump(const Duration(seconds: 6));
        await t.pump(const Duration(milliseconds: 400));
      }
    }

    Future<void> tk(String key) async {
      final f = find.byKey(Key(key));
      await t.ensureVisible(f);
      await t.pump();
      await clearSnack(f);
      await t.tap(f);
      await settle(t);
    }

    Future<void> tq(String key) async {
      final f = find.byKey(Key(key));
      await t.ensureVisible(f);
      await t.pump();
      await clearSnack(f);
      await t.tap(f);
      await qaQuick(t);
    }

    Future<void> en(String key, String text) async {
      final f = find.byKey(Key(key));
      await t.ensureVisible(f);
      await t.pump();
      await t.enterText(f, text);
      await t.pump();
    }

    // Guarda en disco lo nuevo que haya pasado por el FileSaver (por identidad de los bytes).
    final seen = Set<Uint8List>.identity();
    var fileSeq = 0;
    List<String> grab(String label) {
      final out = <String>[];
      for (final e in saver.saved.entries) {
        if (!seen.add(e.value)) continue;
        final safe = e.key.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
        final fn = '${(++fileSeq).toString().padLeft(2, '0')}-$label--$safe';
        File('$exportDir/$fn').writeAsBytesSync(e.value);
        exported.add((fn, e.value.length, label));
        out.add(fn);
      }
      return out;
    }

    Future<void> home() async {
      try {
        t
            .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger).first)
            .clearSnackBars();
      } catch (_) {}
      try {
        t
            .state<NavigatorState>(find.byType(Navigator).first)
            .popUntil((r) => r.isFirst);
      } catch (_) {}
      await settle(t);
    }

    var menuScrollNoted = false;
    Future<void> menuTo(String label) async {
      final lv = find
          .byType(ListView)
          .first; // la barra lateral es lo primero del árbol
      final item = find.descendant(of: lv, matching: find.text(label));
      await t.drag(lv, const Offset(0, 1500));
      await t.pump();
      var scrolled = 0;
      while (item.evaluate().isEmpty && scrolled < 10) {
        await t.drag(lv, const Offset(0, -150));
        await t.pump();
        scrolled++;
      }
      if (scrolled > 0 && !menuScrollNoted) {
        menuScrollNoted = true;
        note(
            'A 1366x768 el menú lateral no cabe: «$label» exige desplazar el menú (no es defecto: el menú se desplaza).');
      }
      await t.ensureVisible(item.first);
      await t.pump();
      await t.tap(item.first);
      await settle(t);
    }

    Future<void> goTo(String label) async {
      await home();
      await menuTo(label);
    }

    /// Toca un botón de la página que puede estar fuera de la zona ya construida (lista larga).
    Future<void> tkS(String key) async {
      final f = find.byKey(Key(key));
      if (f.evaluate().isEmpty) {
        await t.dragFrom(const Offset(700, 300),
            const Offset(0, 4000)); // al principio de la página
        await t.pump();
      }
      for (var i = 0; i < 30 && f.evaluate().isEmpty; i++) {
        await t.dragFrom(const Offset(700, 400),
            const Offset(0, -220)); // rueda del ratón sobre la página
        await t.pump();
      }
      await tk(key);
    }

    Future<void> park() => goTo('Confirmar asistencia');

    // Escribir datos desde la prueba mientras hay pantallas con consultas vivas deja a Drift colgado:
    // se «apaga» la app (como cerrarla), se escribe y se vuelve a abrir (como abrirla de nuevo).
    Future<void> powerOn() async {
      await t.pumpWidget(ProviderScope(overrides: [
        databaseProvider.overrideWithValue(db),
        authServiceProvider.overrideWithValue(c.auth),
        autoBackupProvider.overrideWithValue(
            AutoBackup(db, directory: () async => c.backupDir)),
        fileSaverProvider.overrideWithValue(saver),
        filePickProvider.overrideWithValue(picker),
      ], child: const MiEventoApp()));
      await settle(t);
      await login(t, 'admin', 'secreto1');
    }

    Future<void> offlineWrite(Future<void> Function() fn) async {
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(milliseconds: 50));
      await t.runAsync(fn);
      await powerOn();
    }

    Future<void> openEventsList() async {
      await home();
      if (find.byKey(const Key('ev-crear-fab')).evaluate().isEmpty) {
        await menuTo('Mis eventos');
      }
    }

    var menuOffNoted = false;
    Future<void> openEventMenu(String name, String item) async {
      final m = find.byKey(Key('evento-menu-$name'));
      final cx = t.getCenter(m).dx;
      if (cx > 1366 && !menuOffNoted) {
        menuOffNoted = true;
        bug(
            'Baja',
            'En «Mis eventos» (tabla, 1366x768) el menú ⋮ de acciones queda fuera de la ventana con nombres largos',
            'Con dos eventos (el principal y su copia «… (copia completa)») la tabla es más ancha que la ventana de 1366 px y el botón ⋮ (Duplicar / Pasar participantes / Eliminar) se dibuja en x=${cx.round()}, fuera de la pantalla: hay que desplazar la tabla en horizontal para llegar a las acciones del evento.');
      }
      await t.ensureVisible(m);
      await t.pump();
      await t.tap(m);
      await settle(t);
      await t.tap(find.text(item));
      await settle(t);
    }

    Future<void> openEvent(String name) async {
      await openEventsList();
      await t.ensureVisible(find.byKey(Key('evento-$name')));
      await t.pump();
      await t.tap(find.byKey(Key('evento-$name')));
      await settle(t);
    }

    var stopped = false;
    final stopAt = Platform.environment['QA_STOP'];
    Future<void> step(
        String id, String title, Future<void> Function() body) async {
      if (stopped) return;
      if (stopAt != null && id == stopAt) stopped = true;
      final s = StepRec(id, title);
      steps.add(s);
      cur = s;
      final sw = Stopwatch()..start();
      // ignore: avoid_print
      print('>>> PASO $id $title');
      try {
        await body();
      } catch (e, st) {
        s.failed = true;
        s.ev.add('EXCEPCIÓN en el paso: ${_s(e)}');
        // ignore: avoid_print
        print('EXCEPCIÓN $id: $e\n$st');
        try {
          // ignore: avoid_print
          print(
              '  textos en pantalla: ${t.widgetList<Text>(find.byType(Text)).map((e) => e.data).whereType<String>().take(60).toList()}');
        } catch (_) {}
        try {
          await home();
        } catch (_) {}
      }
      final ex = t.takeException();
      if (ex != null) {
        s.failed = true;
        s.ev.add('Excepción/desborde de la interfaz: ${_s(ex)}');
        bug('Media', 'Excepción o desborde de la interfaz (paso $id)', _s(ex));
      }
      s.took = sw.elapsed;
      // ignore: avoid_print
      print('<<< PASO $id ${s.failed ? 'FALLA' : 'PASA'} (${sw.elapsed})');
      for (final e in s.ev.where((e) =>
          e.startsWith('FALLA') ||
          e.startsWith('EXC') ||
          e.startsWith('Exc'))) {
        // ignore: avoid_print
        print('    $e');
      }
      writeReport(steps, defects, metrics, limits, exported, started, false);
    }

    // ── Consultas directas ──
    Future<List<AttendeeRow>> attOf(String ev) =>
        rq(() => (db.select(db.attendees)
              ..where((a) => a.eventId.equals(ev) & a.deletedAt.isNull())
              ..orderBy([(a) => OrderingTerm.asc(a.regNumber)]))
            .get());
    Future<List<LodgingRow>> lodOf(String ev) =>
        rq(() => (db.select(db.lodgings)
              ..where((l) => l.eventId.equals(ev) & l.deletedAt.isNull()))
            .get());
    Future<List<TeamRow>> teamOf(String ev) => rq(() => (db.select(db.teams)
          ..where((x) => x.eventId.equals(ev) & x.deletedAt.isNull()))
        .get());
    Future<String> evIdByName(String n) async =>
        (await rq(() => (db.select(db.events)
                  ..where((e) => e.name.equals(n) & e.deletedAt.isNull()))
                .getSingle()))
            .id;

    String cardN(String key) => t
        .widget<Text>(find
            .descendant(of: find.byKey(Key(key)), matching: find.byType(Text))
            .at(1))
        .data!;
    String txt(String key) => t.widget<Text>(find.byKey(Key(key))).data ?? '';
    int firstInt(String s) =>
        int.tryParse(RegExp(r'\d+').firstMatch(s)?.group(0) ?? '') ?? -1;

    // ── Datos del escenario ──
    final total = fast ? 44 : 214;
    final formMin = fast ? 6 : 42;
    final csvAMin = fast ? 10 : 62;
    final all = qaPeople(total, seed: 2027, couples: fast ? 4 : 22);
    final wifeOf = <QaPerson, QaPerson>{};
    final wives = <QaPerson>{};
    for (final p in all) {
      if (p.spouseIdx != null) {
        wives.add(p);
        wifeOf[all[p.spouseIdx!]] = p;
      }
    }
    final units = <List<QaPerson>>[
      for (final p in all)
        if (!wives.contains(p)) [p, if (wifeOf[p] != null) wifeOf[p]!]
    ];
    final formUnits = <List<QaPerson>>[],
        aUnits = <List<QaPerson>>[],
        bUnits = <List<QaPerson>>[];
    var nf = 0, na = 0;
    for (final u in units) {
      if (nf < formMin) {
        formUnits.add(u);
        nf += u.length;
      } else if (na < csvAMin) {
        aUnits.add(u);
        na += u.length;
      } else {
        bUnits.add(u);
      }
    }
    int formChurch(QaPerson p) =>
        p.churchIdx >= 7 ? p.churchIdx - 7 : p.churchIdx;
    final createdChurches = <int>{};
    final evName =
        fast ? 'Congreso QA Windows (rápido)' : 'Congreso Nacional QA 2026';
    late String evId;
    var formRegistered = 0, formPre = 0, formDirect = 0;
    var csvANew = 0, csvBNew = 0;
    var lodgingsViaUiCount = 0;

    await login(t, 'admin', 'secreto1');

    // ═════════════════════ PASO 0 ═════════════════════
    await step('0', 'Arranque y entrada a la app a 1366x768 (100 %)', () async {
      ck(find.byKey(const Key('ev-crear-fab')).evaluate().isNotEmpty,
          'tras entrar como admin se ve «Mis eventos» con «Crear evento»');
      ck(t.view.physicalSize == const Size(1366, 768),
          'ventana de 1366x768 a dpr 1');
    });

    // ═════════════════════ PASO 1 ═════════════════════
    await step('1',
        'Crear evento por la UI y configurar hospedajes (22) y equipos (8)',
        () async {
      await t.tap(find.text('Crear evento').first);
      await settle(t);
      await t.enterText(find.byKey(const Key('ev-nombre')), evName);
      await t.pump();
      try {
        await tk('ev-fechas');
        await t.tap(find.text('15').first);
        await t.pump();
        await t.tap(find.text('17').first);
        await t.pump();
        await t.tap(find.text('Aceptar'));
        await settle(t);
        ck(find.textContaining('→').evaluate().isNotEmpty,
            'el calendario de rango (1366x768) deja fechas «inicio → fin»');
      } catch (e) {
        ck(false, 'elegir fechas en el calendario a 1366x768: ${_s(e)}',
            sev: 'Media',
            title: 'El selector de fechas no se puede usar a 1366x768');
        await home();
        await t.tap(find.text('Crear evento').first);
        await settle(t);
        await t.enterText(find.byKey(const Key('ev-nombre')), evName);
      }
      await t.tap(find.byKey(const Key('ev-crear')));
      await settle(t);
      ck(find.byKey(const Key('cfg-intro')).evaluate().isNotEmpty,
          'al crear se abre la pantalla de configuración del evento');
      ck(find.text('Registrar').evaluate().isEmpty,
          'mientras se configura no hay menú «Registrar»');

      for (final (name, kind, cap, accepts, host) in lodgingDefs) {
        await tk('cfg-hospedajes');
        await t.enterText(find.byKey(const Key('lf-nombre')), name);
        if (kind == 'private_home') {
          await t.tap(find.text('Casa particular'));
          await t.pump();
          await t.enterText(find.byKey(const Key('lf-anfitrion')), host);
        }
        await t.enterText(find.byKey(const Key('lf-capacidad')), '$cap');
        await t.tap(find.descendant(
            of: find.byType(AlertDialog), matching: find.text(accepts)));
        await t.pump();
        await t.enterText(find.byKey(const Key('lf-cerca')),
            kind == 'shelter' ? 'A 5 minutos del templo' : 'A 10 cuadras');
        await tk('lf-guardar');
        lodgingsViaUiCount++;
      }
      final est = txt('cfg-hospedajes-estado');
      final plazas = lodgingDefs.fold<int>(0, (s, d) => s + d.$3);
      ck(
          est.contains('${lodgingDefs.length} hospedajes') &&
              est.contains('$plazas plazas'),
          'estado de hospedajes: «$est» (esperado ${lodgingDefs.length} y $plazas plazas)');
      final mix = {
        for (final a in [
          'Solo hombres',
          'Solo mujeres',
          'Matrimonios',
          'Sin preferencia'
        ])
          a: lodgingDefs.where((d) => d.$4 == a).length
      };
      note('Mezcla de hospedajes creados por la UI: $mix');

      await tk('cfg-equipos-definir');
      await t.enterText(find.byKey(const Key('eq-cantidad')), '8');
      await t.pump();
      await tk('eq-crear-ok');
      ck(txt('cfg-equipos-estado').contains('8 equipos'),
          'estado de equipos: «${txt('cfg-equipos-estado')}»');
      await tk('cfg-terminar');
      ck(find.byKey(const Key('panel-vacio')).evaluate().isNotEmpty,
          'terminar la configuración abre el panel del evento');
      evId = await evIdByName(evName);
      final lods = await lodOf(evId);
      ck(lods.length == lodgingDefs.length,
          'en la base hay ${lods.length} hospedajes');
      ck((await teamOf(evId)).length == 8, 'en la base hay 8 equipos');
      metrics['hospedajes_creados_UI'] = lods.length;
      metrics['plazas_totales'] = plazas;
    });

    // ═════════════════════ PASO 2 ═════════════════════
    Future<void> pickChurch(int ci) async {
      final ch = myChurches[ci];
      await t.ensureVisible(find.byKey(const Key('f-iglesia')));
      await t.pump();
      await t.enterText(find.byKey(const Key('f-iglesia')), ch.name);
      await qaQuick(t);
      final k = Key('iglesia-${normalizeText(ch.name)}');
      if (find.byKey(k).evaluate().isNotEmpty) {
        await t.ensureVisible(find.byKey(k));
        await t.pump();
        await t.tap(find.byKey(k));
        await qaQuick(t);
        return;
      }
      await tq('iglesia-nueva');
      await t.tap(find.byKey(const Key('ni-provincia')));
      await settle(t);
      await t.tap(find.text(ch.prov).last);
      await settle(t);
      await pickMunicipio(t, ch.muni);
      if (ch.community.isNotEmpty) {
        await t.tap(find.byKey(const Key('ni-comunidad')));
        final suggest = createdChurches.any((j) =>
            myChurches[j].muni == ch.muni &&
            myChurches[j].community == ch.community);
        if (suggest) {
          await t.enterText(find.byKey(const Key('ni-comunidad')),
              ch.community.substring(0, 3));
          await t.pump();
          final op = find.byKey(Key('ni-comunidad-op-${ch.community}'));
          ck(op.evaluate().isNotEmpty,
              'la comunidad «${ch.community}» se sugiere al escribir «${ch.community.substring(0, 3)}» (municipio ${ch.muni})');
          if (op.evaluate().isNotEmpty) {
            await t.tap(op);
            await t.pump();
          } else {
            await t.enterText(
                find.byKey(const Key('ni-comunidad')), ch.community);
          }
        } else {
          await t.enterText(
              find.byKey(const Key('ni-comunidad')), ch.community);
          await t.pump();
          ck(find.byKey(const Key('ni-comunidad-nueva')).evaluate().isNotEmpty,
              'comunidad nueva «${ch.community}» avisa que se añadirá al guardar');
        }
      }
      await tk('ni-guardar');
      createdChurches.add(ci);
    }

    // Las opciones del desplegable de hospedaje («nombre · acepta · N libres»); no la etiqueta del filtro «Con plazas libres».
    Finder lodgOptF() => find.byWidgetPredicate((w) =>
        w is Text &&
        (w.data ?? '').contains(' · ') &&
        (w.data ?? '').endsWith('libres'));
    var preSticky = false;
    var chipSticky = false;
    Future<void> fillCore(QaPerson p, int ci, {required bool pre}) async {
      await en('f-nombre', p.first);
      await en('f-apellido1', p.last1);
      if (p.last2.isNotEmpty) await en('f-apellido2', p.last2);
      await tq('f-sexo');
      await t.tap(
          find.text(p.sex == Sex.female ? 'F (Mujer)' : 'M (Hombre)').last);
      await qaQuick(t);
      await en('f-edad', '${p.age}');
      if (p.phone != null) await en('f-telefono', p.phone!);
      if (p.notes.isNotEmpty) await en('f-observaciones', p.notes);
      await pickChurch(ci);
      final cur = t
          .widget<SwitchListTile>(find.byKey(const Key('f-preinscripcion')))
          .value;
      if (cur != pre) await tq('f-preinscripcion');
      if (cur && !preSticky) {
        preSticky = true;
        bug(
            'Baja',
            'El interruptor «Preinscripción» no se limpia con «Guardar y registrar otro»',
            'Tras guardar a una persona como preinscrita con «Guardar y registrar otro», el formulario se limpia (nombre, sexo, edad, iglesia, hospedaje…) pero «Preinscripción» sigue activado. Puede ser intencional para cargar lotes, pero quien registre después a una persona que SÍ llegó puede dejarla preinscrita sin notarlo (queda fuera de comidas y reportes hasta confirmarla).');
      }
    }

    Future<void> lodgingChoice(String mode) async {
      await tq('f-hospedaje');
      if (mode == 'usar') {
        if (find.byKey(const Key('f-hosp-usar')).evaluate().isNotEmpty) {
          await tq('f-hosp-usar');
        }
      } else if (mode == 'manual') {
        await t.ensureVisible(find.byKey(const Key('f-hosp-buscar')));
        await t.pump();
        await t.enterText(find.byKey(const Key('f-hosp-buscar')), 'Casa');
        await qaQuick(t);
        // los filtros del formulario se conservan al «registrar otro»: solo se tocan si no están activos
        if (t
                .widget<FilterChip>(
                    find.byKey(const Key('f-hosp-filtro-libres')))
                .selected &&
            !chipSticky) {
          chipSticky = true;
          note(
              'Los filtros de la lista de hospedajes del formulario («Con plazas libres», «Solo los que aceptan…») y el buscador siguen activos al pulsar «Guardar y registrar otro» (el formulario se limpia, ellos no).');
        }
        if (!t
            .widget<FilterChip>(find.byKey(const Key('f-hosp-filtro-libres')))
            .selected) {
          await tq('f-hosp-filtro-libres');
        }
        final chipSexo =
            t.widget<FilterChip>(find.byKey(const Key('f-hosp-filtro-sexo')));
        if (chipSexo.onSelected != null && !chipSexo.selected) {
          await tq('f-hosp-filtro-sexo');
        }
        await tq('f-hosp-sel');
        if (lodgOptF().evaluate().isNotEmpty) {
          await t.tap(lodgOptF().first);
          await settle(t);
        }
      }
    }

    Future<void> saveAnother({bool last = false}) async {
      await tq(last ? 'f-guardar' : 'f-guardar-otro');
      if (find.byKey(const Key('dup-confirmar')).evaluate().isNotEmpty) {
        note(
            'Apareció el diálogo de duplicado inesperadamente; se guarda igual.');
        await tk('dup-guardar-igual');
      }
    }

    bool hasFocus(String key) => t
        .widget<EditableText>(find.descendant(
            of: find.byKey(Key(key)), matching: find.byType(EditableText)))
        .focusNode
        .hasPrimaryFocus;
    Future<void> tab() async {
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pump();
    }

    await step(
        '2a', 'Formulario «Registrar»: etiquetas, sexo M/F, obligatorios, Tab',
        () async {
      await goTo('Registrar');
      for (final l in [
        'Nombre *',
        'Primer apellido *',
        'Sexo *',
        'Edad *',
        'Iglesia *'
      ]) {
        ck(find.text(l).evaluate().length == 1,
            'campo obligatorio marcado con * : «$l»');
      }
      ck(find.text('Segundo apellido (opcional)').evaluate().isNotEmpty,
          'segundo apellido dice (opcional)');
      ck(find.text('Teléfono (opcional)').evaluate().isNotEmpty,
          'teléfono dice (opcional)');
      // sexo: lista M/F
      await tq('f-sexo');
      ck(
          find.text('M (Hombre)').evaluate().isNotEmpty &&
              find.text('F (Mujer)').evaluate().isNotEmpty,
          'la lista de sexo ofrece «M (Hombre)» y «F (Mujer)»');
      await t.tap(find.text('M (Hombre)').last);
      await qaQuick(t);
      // validaciones
      await tq('f-guardar');
      ck(find.textContaining('Falta el nombre').evaluate().isNotEmpty,
          'guardar vacío avisa «Falta el nombre»');
      // Tab
      await t.enterText(find.byKey(const Key('f-nombre')), 'Lucía');
      await t.tap(find.byKey(const Key('f-nombre')));
      await t.pump();
      await tab();
      ck(hasFocus('f-apellido1'), 'Tab: nombre → primer apellido');
      await tab();
      ck(hasFocus('f-apellido2'), 'Tab: primer apellido → segundo apellido');
      await tab();
      await tab();
      ck(hasFocus('f-edad'), 'Tab: (sexo) → edad');
      await tab();
      ck(hasFocus('f-telefono'), 'Tab: edad → teléfono');
      await tab();
      ck(hasFocus('f-iglesia'), 'Tab: teléfono → iglesia');
      await t.enterText(find.byKey(const Key('f-nombre')), '');
      await t.pump();
    });

    var unitNo = 0;
    await step('2b',
        'Registrar $formMin+ personas a mano (iglesia nueva provincia→municipio→comunidad, matrimonios, preinscritos, hospedaje)',
        () async {
      await goTo('Registrar');
      for (final u in formUnits) {
        final p = u.first;
        final ci = formChurch(p);
        final pre = unitNo.isEven;
        try {
          await fillCore(p, ci, pre: pre);
          if (u.length > 1) {
            final w = u[1];
            await tq('social-conyuge-nuevo-btn');
            await en('ns-nombre', w.first);
            await en('ns-apellido1', w.last1);
            if (w.last2.isNotEmpty) await en('ns-apellido2', w.last2);
            await en('ns-edad', '${w.age}');
            await tk('ns-aceptar');
          }
          // municipio/provincia solo lectura tomados de la iglesia
          if (unitNo == 0) {
            final fp = find.descendant(
                of: find.byKey(const Key('f-provincia')),
                matching: find.text(myChurches[ci].prov));
            final fm = find.descendant(
                of: find.byKey(const Key('f-municipio')),
                matching: find.text(myChurches[ci].muni));
            ck(fp.evaluate().isNotEmpty && fm.evaluate().isNotEmpty,
                'provincia/municipio (${myChurches[ci].prov}/${myChurches[ci].muni}) vienen de la iglesia elegida');
            final editable = find.byType(TextField).evaluate().where((e) =>
                e.widget.key == const Key('f-municipio') ||
                e.widget.key == const Key('f-provincia'));
            ck(editable.isEmpty,
                'provincia y municipio no son campos editables');
          }
          await lodgingChoice(Platform.environment['QA_MANUAL'] == '1'
              ? 'manual'
              : unitNo < 8
                  ? 'usar'
                  : unitNo < 14
                      ? 'manual'
                      : 'none');
          final last = identical(u, formUnits.last);
          final nBefore = (await attOf(evId)).length;
          await saveAnother(last: false);
          final nAfter = (await attOf(evId)).length;
          if (nAfter != nBefore + u.length) {
            final msgs = t
                .widgetList<Text>(find.byType(Text))
                .map((e) => e.data ?? '')
                .where((e) => RegExp(r'^(Falta|Elige|Ojo|La edad|No hay|Ya )')
                    .hasMatch(e))
                .toSet()
                .toList();
            // ignore: avoid_print
            print(
                'DEBUG textos: ${t.widgetList<Text>(find.byType(Text)).map((e) => e.data).whereType<String>().toList()}');
            ck(false,
                'tras guardar a ${p.fullName} (unidad ${unitNo + 1}) hay ${nAfter - nBefore} nuevas, esperadas ${u.length}; mensajes visibles: $msgs');
          }
          if (last) {
            // cierre con «Guardar» + pantalla de éxito se hace con la persona del duplicado (2c)
          }
          formRegistered += u.length;
          if (pre) {
            formPre += u.length;
          } else {
            formDirect += u.length;
          }
        } catch (e, st) {
          // ignore: avoid_print
          print(
              'DEBUG2b ${p.fullName}: $e\n$st\nTEXTOS: ${t.widgetList<Text>(find.byType(Text)).map((e) => e.data).whereType<String>().skip(12).toList()}');
          ck(false, 'registrar a ${p.fullName}: ${_s(e)}');
          await goTo('Registrar');
        }
        unitNo++;
      }
      final rows = await attOf(evId);
      ck(rows.length == formRegistered,
          'tras el formulario hay ${rows.length} personas (esperado $formRegistered)');
      ck(rows.where((r) => r.status == 'preregistered').length == formPre,
          'preinscritos por formulario: ${rows.where((r) => r.status == 'preregistered').length} (esperado $formPre)');
      // la pareja nueva hereda la preinscripción del titular
      final sp = await rq(() => SocialRepoProxy(db).spouseMap(evId));
      var coherent = true;
      final byId = {for (final r in rows) r.id: r};
      sp.forEach((a, b) {
        if (byId[a]!.status != byId[b]!.status) coherent = false;
      });
      ck(coherent,
          'los matrimonios tienen el mismo estado (preinscrito/confirmado) en ambos cónyuges; parejas: ${sp.length ~/ 2}');
      ck(rows.where((r) => r.teamId != null).length == rows.length,
          'todas las personas del formulario tienen equipo automático');
      final withLodg = rows.where((r) => r.lodgingId != null).length;
      final lodNames = {for (final l in await lodOf(evId)) l.id: l.name};
      final spm = await rq(() => SocialRepoProxy(db).spouseMap(evId));
      note('Hospedaje aceptado/elegido en el formulario: $withLodg personas: ${[
        for (final r in rows.where((r) => r.lodgingId != null))
          '#${r.regNumber} ${r.sex}${spm.containsKey(r.id) ? ' casado/a' : ''} → ${lodNames[r.lodgingId]}'
      ].join('; ')}');
      metrics['form_hospedaje_asignado'] = withLodg;
      final tildes = rows
          .where((r) => RegExp(r'[áéíóúñÁÉÍÓÚÑ]')
              .hasMatch('${r.firstName}${r.lastName1}${r.lastName2}'))
          .length;
      ck(tildes > 0, 'hay nombres con tildes/ñ ($tildes personas)');
      final churches = await rq(() => db.select(db.churches).get());
      note(
          'Iglesias creadas por la UI: ${churches.length}; comunidades: ${churches.map((e) => e.community).where((e) => e.isNotEmpty).toSet()}');
      ck(churches.length == createdChurches.length,
          'catálogo de iglesias = ${churches.length} (esperado ${createdChurches.length})');
      final vara = churches.where((e) => e.community == 'Varadero').length;
      ck(vara == 2 || !createdChurches.contains(2),
          'la comunidad «Varadero» quedó guardada en las iglesias de Cárdenas ($vara)');
    });

    await step('2c',
        'Duplicado: aviso al escribir, diálogo al guardar (cancelar / guardar igual) y pantalla de éxito',
        () async {
      await goTo('Registrar');
      final base = formUnits[1].first;
      final before = (await attOf(evId)).length;
      await en('f-nombre', base.first.toUpperCase());
      await en('f-apellido1', normalizeText(base.last1));
      await t.pump(const Duration(milliseconds: 100));
      await settle(t);
      ck(find.byKey(const Key('dup-aviso')).evaluate().isNotEmpty,
          'aviso de duplicado al escribir mismo nombre y primer apellido (mayúsculas/sin tildes)');
      await en('f-nombre', base.first);
      await en('f-apellido1', base.last1);
      if (base.last2.isNotEmpty) await en('f-apellido2', base.last2);
      await tq('f-sexo');
      await t.tap(
          find.text(base.sex == Sex.female ? 'F (Mujer)' : 'M (Hombre)').last);
      await qaQuick(t);
      await en('f-edad', '${base.age + 1}');
      await pickChurch(formChurch(base));
      await lodgingChoice('none');
      await tq('f-guardar-otro');
      ck(find.byKey(const Key('dup-confirmar')).evaluate().isNotEmpty,
          'al guardar con mismo nombre y apellidos sale el diálogo «¿Ya está registrado?»');
      await tk('dup-cancelar');
      ck((await attOf(evId)).length == before,
          'cancelar el diálogo no guarda nada');
      await tq('f-guardar'); // última de las manuales: guardar y ver éxito
      await settle(t);
      final dlg2 = find.byKey(const Key('dup-confirmar')).evaluate().isNotEmpty;
      note('Segundo intento de guardar: diálogo de duplicado visible=$dlg2');
      if (dlg2) {
        await tk('dup-guardar-igual');
        await settle(t);
      } else {
        // ignore: avoid_print
        print(
            'DEBUG2c textos: ${t.widgetList<Text>(find.byType(Text)).map((e) => e.data).whereType<String>().skip(14).toList()}');
      }
      ck((await attOf(evId)).length == before + 1,
          '«Es otra persona, guardar» la guarda (homónimo, edad ${base.age + 1})');
      ck(find.byKey(const Key('exito-numero')).evaluate().isNotEmpty,
          'pantalla de éxito con el número de inscripción');
      formRegistered += 1;
      formDirect += 1;
      metrics['formulario_total'] = formRegistered;
    });

    // ═════════════════════ PASO 3 · CSV ═════════════════════
    List<List<String>> buildRows(List<List<QaPerson>> us, int startNo,
        {bool lowerChurch = false}) {
      const hdr = attendeeCsvHeaders;
      final rows = <List<String>>[List<String>.of(hdr)];
      var n = startNo;
      for (final u in us) {
        final husbandNo = n;
        for (var i = 0; i < u.length; i++) {
          final p = u[i];
          final ch = myChurches[p.churchIdx];
          final no = n++;
          final pair =
              u.length > 1 ? (i == 0 ? husbandNo + 1 : husbandNo) : null;
          rows.add([
            '',
            '$no',
            p.first,
            p.last1,
            p.last2,
            p.sex == Sex.male ? 'Hombre' : 'Mujer',
            '${p.age}',
            lowerChurch && no.isOdd ? '  ${ch.name.toLowerCase()} ' : ch.name,
            ch.prov,
            ch.muni,
            p.phone ?? '',
            'Sí',
            '',
            '',
            pair == null ? '' : '$pair',
            p.groups.join('|'),
            p.notes,
          ]);
        }
      }
      return rows;
    }

    Future<void> importCsv(String label, Uint8List bytes,
        {bool pre = false, bool toggleDup = false}) async {
      picker.file = PickedFile('$label.csv', bytes);
      await goTo('Copias de seguridad');
      await tkS('csv-importar');
      ck(find.byKey(const Key('csvi-resumen')).evaluate().isNotEmpty,
          '$label: vista previa antes de importar');
      final res = txt('csvi-resumen');
      note('$label · vista previa: «$res»');
      final dlg = t
          .widgetList<Text>(find.descendant(
              of: find.byKey(const Key('csvi-dialogo')),
              matching: find.byType(Text)))
          .map((e) => e.data ?? '')
          .where((e) =>
              e.startsWith('Fila ') ||
              e.contains('Columnas') ||
              e.contains('hospedaje'))
          .take(6)
          .toList();
      if (dlg.isNotEmpty) {
        note('$label · avisos/errores mostrados: ${dlg.join(' | ')}');
      }
      if (toggleDup) {
        await tk('csvi-duplicados');
        note('$label · con «incluir duplicados»: «${txt('csvi-resumen')}»');
        await tk('csvi-duplicados');
      }
      await tk(pre ? 'csvi-preinscritos' : 'csvi-confirmados');
      await tk('csvi-importar');
      ck(find.byKey(const Key('csvi-resultado')).evaluate().isNotEmpty,
          '$label: pantalla de resultado');
      final created = t
          .widgetList<Text>(find.textContaining('Nuevas personas:'))
          .map((e) => e.data!)
          .toList();
      note(
          '$label · resultado: ${t.widgetList<Text>(find.descendant(of: find.byKey(const Key('csvi-resultado')), matching: find.byType(Text))).map((e) => e.data).whereType<String>().where((e) => e.contains(':') || e.startsWith('Fila')).take(8).join(' | ')}');
      final n = created.isEmpty ? -1 : firstInt(created.first);
      if (label.contains('A')) {
        csvANew = n;
      } else {
        csvBNew = n;
      }
      await tk('csvi-cerrar');
    }

    late int maxNo;
    await step('3a',
        'Importar CSV A (confirmados): ;, UTF-8 con BOM, matrimonios por pareja_numero, filas malas y duplicado',
        () async {
      final rows0 = await attOf(evId);
      maxNo = rows0.fold<int>(0, (m, r) => r.regNumber > m ? r.regNumber : m);
      final rows = buildRows(aUnits, maxNo + 1);
      final f0 = formUnits[2]
          .first; // duplicado exacto de alguien del formulario (nombre y edad)
      rows.add([
        '',
        '',
        f0.first,
        f0.last1,
        f0.last2,
        f0.sex == Sex.male ? 'Hombre' : 'Mujer',
        '${f0.age}',
        myChurches[formChurch(f0)].name,
        '',
        '',
        '',
        'Sí',
        '',
        '',
        '',
        '',
        ''
      ]);
      rows.add([
        '',
        '',
        '',
        'SinNombre',
        '',
        'Mujer',
        '30',
        'Bautista Ebenezer',
        '',
        '',
        '',
        'Sí',
        '',
        '',
        '',
        '',
        ''
      ]); // sin nombre
      rows.add([
        '',
        '',
        'Raro',
        'ConSexo',
        '',
        'Otro',
        '30',
        'Bautista Ebenezer',
        '',
        '',
        '',
        'Sí',
        '',
        '',
        '',
        '',
        ''
      ]); // sexo inválido
      rows.add([
        '',
        '',
        'Mario',
        'Ñáñez-Sexom',
        'Pérez',
        'M',
        '33',
        'Bautista Ebenezer',
        'Matanzas',
        'Cárdenas',
        '',
        'Sí',
        '',
        '',
        '',
        '',
        'Celda con ; punto y coma y "comillas"'
      ]); // «M» en CSV
      final text = buildCsvDelimited(rows);
      await importCsv(
          'csv-A-confirmados', Uint8List.fromList(utf8.encode(text)),
          toggleDup: true);
      final after = await attOf(evId);
      final expectNew =
          aUnits.fold<int>(0, (s, u) => s + u.length) + 1; // + «Mario»
      ck(csvANew == expectNew,
          'CSV A: nuevas personas $csvANew (esperado $expectNew); malas: 2; duplicado omitido: 1');
      final newOnes = after.where((r) => r.regNumber > maxNo).toList();
      ck(newOnes.every((r) => r.status == 'confirmed'),
          'las personas del CSV A quedan CONFIRMADAS (${newOnes.where((r) => r.status == 'confirmed').length}/${newOnes.length})');
      final mario = after.where((r) => r.lastName1 == 'Ñáñez-Sexom');
      if (mario.isNotEmpty) {
        note(
            'Fila con sexo «M» y nombre «Mario»: se importó como sexo=${mario.first.sex} (en el formulario «M» = Hombre).');
        if (mario.first.sex == 'F') {
          bug(
              'Media',
              'En el CSV la «M» se lee como Mujer, pero en el formulario «M (Hombre)»',
              'Fila «Mario Ñáñez-Sexom;sexo=M» del CSV A se importó como mujer. El formulario de registro etiqueta «M (Hombre)/F (Mujer)», y parseSexCell (packages/mi_evento_core/lib/src/attendee_csv.dart) interpreta M como mujer (y H como hombre). Quien llene Excel pensando en la convención del formulario invierte el sexo sin aviso y afecta a hospedaje y equipos.');
        }
      }
      final sp = await rq(() => SocialRepoProxy(db).spouseMap(evId));
      final coupleUnits = formUnits.where((u) => u.length > 1).length +
          aUnits.where((u) => u.length > 1).length;
      ck(sp.length ~/ 2 == coupleUnits,
          'matrimonios vinculados: ${sp.length ~/ 2} (esperado $coupleUnits)');
      final groups = await rq(() => (db.select(db.attendeeGroups)
            ..where((g) => g.eventId.equals(evId)))
          .get());
      note(
          'Grupos en el evento tras el CSV A: ${groups.map((g) => g.name).toList()}');
      final ch = await rq(() => db.select(db.churches).get());
      ck(ch.length >= 7,
          'el CSV creó iglesias nuevas en el catálogo (total ${ch.length})');
      final teamless =
          (await attOf(evId)).where((r) => r.teamId == null).length;
      ck(teamless == 0, 'personas sin equipo tras importar: $teamless');
    });

    await step('3b',
        'Importar CSV B «como preinscripción» (, sin BOM, Windows-1252, columnas en otro orden, hospedaje del archivo ignorado)',
        () async {
      final rows0 = await attOf(evId);
      maxNo = rows0.fold<int>(0, (m, r) => r.regNumber > m ? r.regNumber : m);
      final body = buildRows(bUnits, maxNo + 1, lowerChurch: true);
      // Reordenar columnas (nombre antes que numero) y rellenar «hospedaje» con uno real en algunas filas.
      final order = [2, 3, 4, 5, 6, 7, 8, 9, 1, 0, 10, 11, 12, 13, 14, 15, 16];
      final out = <List<String>>[];
      for (var i = 0; i < body.length; i++) {
        final r = List<String>.of(body[i]);
        if (i > 0 && i % 5 == 0) r[12] = 'Casa Familia Gómez';
        out.add([for (final k in order) r[k]]);
      }
      final text =
          buildCsvDelimited(out, delimiter: ',').substring(1); // sin BOM
      final bytes = Uint8List.fromList(latin1.encode(text));
      await importCsv('csv-B-preinscripcion', bytes, pre: true);
      final after = await attOf(evId);
      final newOnes = after.where((r) => r.regNumber > maxNo).toList();
      final expectNew = bUnits.fold<int>(0, (s, u) => s + u.length);
      ck(csvBNew == expectNew,
          'CSV B: nuevas personas $csvBNew (esperado $expectNew)');
      ck(newOnes.every((r) => r.status == 'preregistered'),
          'todas entran PREINSCRITAS (${newOnes.where((r) => r.status == 'preregistered').length}/${newOnes.length})');
      ck(newOnes.every((r) => r.lodgingId == null),
          'el hospedaje escrito en el archivo se ignora en la preinscripción');
      final ch = await rq(() => db.select(db.churches).get());
      ck(ch.length == myChurches.length,
          'iglesias en catálogo: ${ch.length} (esperado ${myChurches.length}: las escritas en minúsculas/con espacios no se duplican)');
      ck(
          newOnes.any((r) =>
              RegExp(r'[ñÑáéíóú]').hasMatch('${r.firstName}${r.lastName1}')),
          'tildes/ñ en Windows-1252 se leyeron bien (ejemplo: ${newOnes.firstWhere((r) => RegExp(r'[ñÑáéíóú]').hasMatch('${r.firstName}${r.lastName1}'), orElse: () => newOnes.first).firstName})');
      metrics['csv_A_nuevas'] = csvANew;
      metrics['csv_B_nuevas_preinscritas'] = csvBNew;
    });

    await step('3c', 'Totales tras el registro', () async {
      final rows = await attOf(evId);
      final pre = rows.where((r) => r.status == 'preregistered').length;
      metrics['personas_total'] = rows.length;
      metrics['preinscritos_inicial'] = pre;
      metrics['confirmados_directos_inicial'] = rows.length - pre;
      ck(rows.length >= (fast ? 40 : 200),
          'personas registradas: ${rows.length} (objetivo ≥ 200)');
      ck(pre >= (fast ? 25 : 100), 'preinscritas: $pre (objetivo ≥ 100)');
      note(
          'Por vía: formulario $formRegistered (preinscritos $formPre, confirmados $formDirect) · CSV A $csvANew confirmados · CSV B $csvBNew preinscritos.');
      final reg = rows.map((r) => r.regNumber).toList();
      ck(reg.toSet().length == reg.length, 'números de inscripción únicos');
      final keys = <String>{};
      var dups = 0;
      for (final r in rows) {
        if (!keys.add(
            '${normalizeText(r.firstName)}|${normalizeText(r.lastName1)}|${r.age}')) {
          dups++;
        }
      }
      ck(dups == 0, 'sin duplicados nombre+apellido+edad ($dups)');
      final byMuni = <String, int>{};
      for (final r in rows) {
        byMuni['${r.province}/${r.municipality}'] =
            (byMuni['${r.province}/${r.municipality}'] ?? 0) + 1;
      }
      note('Personas por provincia/municipio: $byMuni');
    });

    // ═════════════════════ PASO 4 · confirmar asistencia ═════════════════════
    int pendingCount(String s) => firstInt(s);
    Future<int> prePending() async =>
        (await attOf(evId)).where((r) => r.status == 'preregistered').length;
    await step('4',
        'Confirmar asistencia por la UI: una a una + «Deshacer», subconjunto, búsqueda y «a los que se ven»',
        () async {
      await goTo('Confirmar asistencia');
      final p0 = await prePending();
      ck(pendingCount(txt('ca-conteo')) == p0,
          'contador «${txt('ca-conteo')}» coincide con la base ($p0 por confirmar)');
      final pend = (await attOf(evId))
          .where((r) => r.status == 'preregistered')
          .toList()
          .reversed
          .toList(); // la lista va del nº más alto al más bajo
      // uno por uno
      final first = pend.first.regNumber;
      await tk('ca-confirmar-$first');
      ck(pendingCount(txt('ca-conteo')) == p0 - 1,
          'confirmar a la nº $first: queda «${txt('ca-conteo')}»');
      await t.tap(find.text('Deshacer').last);
      await settle(t);
      ck(pendingCount(txt('ca-conteo')) == p0,
          '«Deshacer» la devuelve a preinscrita: «${txt('ca-conteo')}»');
      await tk('ca-confirmar-$first');
      ck(pendingCount(txt('ca-conteo')) == p0 - 1,
          'se vuelve a confirmar a la nº $first');
      // subconjunto marcado
      final visible = pend.skip(1).take(4).map((r) => r.regNumber).toList();
      for (final n in visible) {
        await tk('ca-fila-$n');
      }
      ck(
          find
              .text('Confirmar seleccionados (${visible.length})')
              .evaluate()
              .isNotEmpty,
          'botón «Confirmar seleccionados (${visible.length})»');
      await tk('ca-confirmar-sel');
      ck(pendingCount(txt('ca-conteo')) == p0 - 1 - visible.length,
          'tras confirmar el subconjunto: «${txt('ca-conteo')}»');
      // búsqueda + seleccionar todos los que coinciden
      await t.enterText(find.byKey(const Key('ca-buscar')), 'nunez');
      await settle(t);
      final coinciden = txt('ca-conteo');
      ck(coinciden.contains('coinciden'),
          'búsqueda sin tilde «nunez»: «$coinciden»');
      if (find.byKey(const Key('ca-sel-todos')).evaluate().isNotEmpty) {
        await tk('ca-sel-todos');
        await tk('ca-confirmar-sel');
      }
      await t.enterText(find.byKey(const Key('ca-buscar')), 'zzzz');
      await settle(t);
      ck(find.byKey(const Key('ca-vacio')).evaluate().isNotEmpty,
          'búsqueda sin resultado muestra «Ningún preinscrito coincide»');
      // por iglesia (todas menos la iglesia K): «Confirmar a los que se ven»
      for (final tok in [
        'ebenezer',
        'metodista',
        'monte',
        'nazareno',
        'betel',
        'getsemani',
        'trinidad',
        'luz del mundo'
      ]) {
        await t.enterText(find.byKey(const Key('ca-buscar')), tok);
        await settle(t);
        if (find.byKey(const Key('ca-confirmar-todos')).evaluate().isEmpty) {
          continue;
        }
        await tk('ca-confirmar-todos');
        if (find.byKey(const Key('ca-dialogo-todos')).evaluate().isNotEmpty) {
          if (tok == 'ebenezer') {
            ck(
                find
                    .textContaining('Se confirmará la asistencia de')
                    .evaluate()
                    .isNotEmpty,
                'diálogo de confirmación masiva con la cantidad');
            await t.tap(find.text('Cancelar'));
            await settle(t);
            await tk('ca-confirmar-todos');
          }
          await tk('ca-dialogo-ok');
        }
      }
      await t.enterText(find.byKey(const Key('ca-buscar')), '');
      await settle(t);
      final left = await prePending();
      final k = (await attOf(evId))
          .where((r) => r.status == 'preregistered')
          .toList();
      final allK = k.every((r) => r.churchId != null);
      metrics['preinscritos_sin_confirmar_tras_paso4'] = left;
      note(
          'Quedan $left preinscritos sin confirmar a propósito (iglesia «Bautista Nuevo Pacto»), para comprobar que reportes y comidas cuentan SOLO confirmados; se confirman con «Confirmar a todos» en el paso 8.');
      ck(left > 0 && allK, 'quedan $left preinscritos pendientes');
      final conf = (await attOf(evId)).length - left;
      metrics['confirmados_tras_paso4'] = conf;
      ck(pendingCount(txt('ca-conteo')) == left,
          'contador de la pantalla = $left');
    });

    // ═════════════════════ PASO 5 · duplicar evento ═════════════════════
    final copyFull = '$evName (copia completa)';
    final copyStruct = '$evName (solo estructura)';
    await step('5a',
        'Duplicar evento (todo) por «Mis eventos» → menú → Duplicar evento…',
        () async {
      // Antes: dejar algo de hospedaje asignado a mano por BD NO; se usa lo asignado por formulario.
      await openEventsList();
      await openEventMenu(evName, 'Duplicar evento…');
      await en('dup-nombre', copyFull);
      await tk('dup-guardar');
      final copyId = await evIdByName(copyFull);
      final orig = await attOf(evId);
      final copy = await attOf(copyId);
      ck(copy.length == orig.length,
          'la copia tiene ${copy.length} participantes (original ${orig.length})');
      ck(copy.every((r) => r.status == 'preregistered'),
          'todos los de la copia están PREINSCRITOS');
      ck(
          copy
              .map((r) => r.id)
              .toSet()
              .intersection(orig.map((r) => r.id).toSet())
              .isEmpty,
          'ids de participantes distintos a los del original');
      ck(
          copy.map((r) => r.regNumber).toSet().length ==
              orig.map((r) => r.regNumber).toSet().length,
          'números de inscripción conservados');
      final ot = await teamOf(evId), ct = await teamOf(copyId);
      ck(
          ct.length == ot.length &&
              ct
                  .map((e) => e.id)
                  .toSet()
                  .intersection(ot.map((e) => e.id).toSet())
                  .isEmpty,
          'equipos copiados (${ct.length}) con ids distintos');
      ck(copy.every((r) => r.teamId == null || ct.any((x) => x.id == r.teamId)),
          'cada participante de la copia apunta a un equipo de la copia');
      final ol = await lodOf(evId), cl = await lodOf(copyId);
      ck(
          cl.length == ol.length &&
              cl
                  .map((e) => e.id)
                  .toSet()
                  .intersection(ol.map((e) => e.id).toSet())
                  .isEmpty,
          'hospedajes copiados (${cl.length}) con ids distintos');
      ck(
          copy.every(
              (r) => r.lodgingId == null || cl.any((x) => x.id == r.lodgingId)),
          'cada hospedaje asignado en la copia es de la copia');
      final nameOfL = {for (final l in ol) l.id: l.name};
      final nameOfCL = {for (final l in cl) l.id: l.name};
      final origByKey = {
        for (final r in orig) '${r.regNumber}': nameOfL[r.lodgingId]
      };
      final sameLodg = copy
          .every((r) => origByKey['${r.regNumber}'] == nameOfCL[r.lodgingId]);
      ck(sameLodg,
          'cada persona conserva su hospedaje (por nombre) en la copia');
      final sp0 = await rq(() => SocialRepoProxy(db).spouseMap(evId));
      final sp1 = await rq(() => SocialRepoProxy(db).spouseMap(copyId));
      final copyIds = copy.map((r) => r.id).toSet();
      ck(
          sp1.length == sp0.length &&
              sp1.entries.every(
                  (e) => copyIds.contains(e.key) && copyIds.contains(e.value)),
          'parejas copiadas: ${sp1.length ~/ 2} (original ${sp0.length ~/ 2}), con ids de la copia');
      final g0 = await rq(() => (db.select(db.attendeeGroups)
            ..where((g) => g.eventId.equals(evId) & g.deletedAt.isNull()))
          .get());
      final g1 = await rq(() => (db.select(db.attendeeGroups)
            ..where((g) => g.eventId.equals(copyId) & g.deletedAt.isNull()))
          .get());
      ck(
          g1.length == g0.length &&
              g1
                  .map((e) => e.id)
                  .toSet()
                  .intersection(g0.map((e) => e.id).toSet())
                  .isEmpty,
          'grupos copiados: ${g1.length} (original ${g0.length}) con ids distintos');
      final ct0 = await rq(() => (db.select(db.controlTypes)
            ..where((x) => x.eventId.equals(copyId)))
          .get());
      note('Tipos de control en la copia: ${ct0.map((e) => e.name).toList()}');
      metrics['copia_completa_personas'] = copy.length;
    });

    await step('5b', 'Duplicar evento solo estructura (sin participantes)',
        () async {
      await openEventsList();
      await openEventMenu(evName, 'Duplicar evento…');
      await en('dup-nombre', copyStruct);
      await tk('dup-personas');
      await tk('dup-guardar');
      final sid = await evIdByName(copyStruct);
      ck((await attOf(sid)).isEmpty,
          'la copia solo-estructura no tiene participantes');
      ck((await teamOf(sid)).length == 8,
          'equipos copiados: ${(await teamOf(sid)).length}');
      ck((await lodOf(sid)).length == lodgingDefs.length,
          'hospedajes copiados: ${(await lodOf(sid)).length}');
    });

    await step('5c', 'Pasar participantes a otro evento…: omite repetidos',
        () async {
      final copyId = await evIdByName(copyFull);
      final sid = await evIdByName(copyStruct);
      Future<String> pasar(String dest) async {
        await openEventsList();
        await openEventMenu(evName, 'Pasar participantes a otro evento…');
        await t.tap(find.byKey(const Key('pasar-destino')));
        await settle(t);
        await t.tap(find.text(dest).last);
        await settle(t);
        await tk('pasar-ok');
        final sn = find.textContaining('pasad');
        return sn.evaluate().isEmpty
            ? '(sin mensaje)'
            : (t.widget<Text>(sn.first).data ?? '');
      }

      final before = (await attOf(copyId)).length;
      final m1 = await pasar(copyFull);
      note('Pasar original → copia completa (ya tiene a todos): «$m1»');
      final after1 = (await attOf(copyId)).length;
      ck(after1 == before,
          'no se duplica a nadie en la copia completa ($before → $after1)');
      final m2 = await pasar(copyStruct);
      note('Pasar original → copia solo-estructura (vacía): «$m2»');
      final n2 = (await attOf(sid)).length;
      final orig = (await attOf(evId)).length;
      ck(n2 == orig, 'a la copia vacía pasan todos: $n2 de $orig');
      final rows2 = await attOf(sid);
      ck(rows2.every((r) => r.status == 'preregistered'),
          'pasados como preinscritos');
      final m3 = await pasar(copyStruct);
      note('Repetir el pase → copia ya llena: «$m3»');
      ck((await attOf(sid)).length == n2,
          'repetir el pase omite repetidos (sigue en $n2)');
      metrics['pasar_participantes'] = '$n2 pasados, repetición omitió todos';
    });

    // ═════════════════════ PASO 6 · solo confirmados (con pendientes) ═════════════════════
    var confCountNow = 0;
    await step('6',
        'Reportes y comidas cuentan SOLO confirmados; aviso al marcar a un preinscrito; filtro «Preinscritos»',
        () async {
      await openEvent(evName);
      final all0 = await attOf(evId);
      final pre = all0.where((r) => r.status == 'preregistered').toList();
      confCountNow = all0.length - pre.length;
      await goTo('Reportes');
      ck(txt('rp-total').contains('$confCountNow'),
          'Reportes dice «${txt('rp-total')}» (confirmados $confCountNow de ${all0.length})');
      await tk('rp-csv');
      await tk('rp-excel');
      await tk('rp-pdf');
      for (var i = 0; i < 6; i++) {
        await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 150)));
        await t.pump();
      }
      final g = grab('reportes-con-pendientes');
      note(
          'Archivos de reportes (con $confCountNow confirmados y ${pre.length} preinscritos): $g');
      final csvName = g.firstWhere((e) => e.endsWith('.csv'), orElse: () => '');
      if (csvName.isNotEmpty) {
        final rows = parseCsv(
            utf8.decode(File('$exportDir/$csvName').readAsBytesSync()));
        ck(rows.length - 1 == confCountNow,
            'el CSV de reportes lista ${rows.length - 1} filas = confirmados ($confCountNow)');
      }
      // Comidas
      await goTo('Comidas');
      if (find.byKey(const Key('cm-nueva')).evaluate().isNotEmpty &&
          find.byKey(const Key('cm-buscar')).evaluate().isEmpty) {
        await tk('cm-nueva');
        await t.enterText(find.byKey(const Key('ns-nombre')),
            'Prueba de conteo (solo verificación)');
        await t.pump();
        await tk('ns-crear');
      }
      ck(cardN('cm-inscritos') == '$confCountNow',
          'Comidas: «Inscritos» = ${cardN('cm-inscritos')} (confirmados $confCountNow)');
      final p = pre.first;
      await t.enterText(find.byKey(const Key('cm-buscar')), '${p.regNumber}');
      await settle(t);
      final noRes = find.byKey(Key('cm-res-${p.regNumber}')).evaluate().isEmpty;
      final msg =
          find.textContaining('Nadie con ese nombre').evaluate().isNotEmpty;
      final hasAviso =
          find.textContaining('confirma primero').evaluate().isNotEmpty;
      note(
          'Buscar en Comidas a la preinscrita nº ${p.regNumber}: aparece en resultados=${!noRes}, mensaje «Nadie con ese nombre»=$msg, aviso «confirma primero»=$hasAviso');
      if (noRes && !hasAviso) {
        bug(
            'Baja',
            'Comidas: a un preinscrito no se le puede marcar y no hay aviso (solo «Nadie con ese nombre. ¿Falta registrarlo?»)',
            'Con la persona nº ${p.regNumber} PREINSCRITA, en Control de comidas la búsqueda por su número no la encuentra y muestra «Nadie con ese nombre. ¿Falta registrarlo?». PLAN.md promete un aviso «confirma primero su asistencia» al marcarla; ese aviso solo existe en la capa de datos (MealRepo.mark lanza DataException), pero la pantalla filtra a los preinscritos y nunca lo muestra. Un operador creerá que la persona no está inscrita.');
      }
      await t.enterText(find.byKey(const Key('cm-buscar')), '');
      await settle(t);
      await park();
      // En la capa de datos sí se rechaza.
      final sess = (await rq(() => (db.select(db.controlSessions)
                ..where((s) => s.eventId.equals(evId)))
              .get()))
          .first;
      String? errMsg;
      await t.runAsync(() async {
        try {
          await MealRepo(db).mark(sess.id, p.id, operatorName: 'QA');
        } on DataException catch (e) {
          errMsg = e.message;
        }
      });
      ck(errMsg != null && errMsg!.contains('preinscrita'),
          'MealRepo.mark rechaza al preinscrito: «$errMsg»');
      // filtro Preinscritos
      await goTo('Asistentes');
      await tk('filtro-asistencia');
      await t.tap(find.text('Preinscritos').last);
      await settle(t);
      ck(txt('lista-conteo').startsWith('${pre.length} de'),
          'filtro Asistencia=Preinscritos: «${txt('lista-conteo')}» (esperado ${pre.length})');
      await tk('exportar-csv');
      final g2 = grab('asistentes-filtro-preinscritos');
      if (g2.isNotEmpty) {
        final rows = parseCsv(
            utf8.decode(File('$exportDir/${g2.first}').readAsBytesSync()));
        ck(rows.length - 1 == pre.length,
            'CSV exportado respeta el filtro: ${rows.length - 1} filas');
      }
    });

    // ═════════════════════ PASO 7 · comidas ═════════════════════
    final sessionDefs = <(String, String)>[
      ('Almuerzo', 'Almuerzo viernes'),
      ('Cena', 'Cena viernes'),
      ('Almuerzo', 'Almuerzo sábado'),
      ('Cena', 'Cena sábado'),
      ('Almuerzo', 'Almuerzo domingo'),
      ('Cena', 'Cena domingo'),
    ];
    final sessionIds = <String, String>{};
    final marksUi = <String, int>{}, marksRepo = <String, int>{};

    Future<List<AttendeeRow>> confirmedSorted() async =>
        (await attOf(evId)).where((r) => r.status == 'confirmed').toList();

    Future<void> newSession(String type, String name) async {
      await tk('cm-nueva');
      if (type != 'Almuerzo') {
        await tk('ns-tipo');
        await t.tap(find.text(type).last);
        await settle(t);
      }
      await t.enterText(find.byKey(const Key('ns-nombre')), name);
      await t.pump();
      await tk('ns-crear');
      final s = await rq(() => (db.select(db.controlSessions)
            ..where((x) => x.eventId.equals(evId) & x.name.equals(name)))
          .getSingle());
      sessionIds[name] = s.id;
    }

    Future<void> markNumber(int n) async {
      await t.enterText(find.byKey(const Key('cm-buscar')), '$n');
      await qaQuick(t);
      await t.testTextInput.receiveAction(TextInputAction.done);
      await qaQuick(t);
    }

    Future<int> activeMarks(String sid) async {
      final recs = await rq(() => (db.select(db.controlRecords)
            ..where((r) =>
                r.sessionId.equals(sid) &
                r.undoneAt.isNull() &
                r.deletedAt.isNull()))
          .get());
      return recs.map((r) => r.attendeeId).toSet().length;
    }

    for (var si = 0; si < sessionDefs.length; si++) {
      final (type, sname) = sessionDefs[si];
      final uiTarget = fast
          ? 6
          : (si == 0
              ? 70
              : si == 1
                  ? 45
                  : si == 2
                      ? 35
                      : si == 3
                          ? 30
                          : 20);
      final fill = [0.95, 0.9, 0.92, 0.85, 0.93, 0.88][si];
      await step('7.${si + 1}',
          'Comidas · sesión «$sname» ($type): marcas por la UI, resto por repositorio, cierre y exportaciones',
          () async {
        // ignore: avoid_print
        print('  [7] abrir evento');
        await openEvent(evName);
        await goTo('Comidas');
        // ignore: avoid_print
        print('  [7] nueva sesión');
        await newSession(type, sname);
        final conf = await confirmedSorted();
        final sid = sessionIds[sname]!;
        ck(cardN('cm-inscritos') == '${conf.length}',
            'contador Inscritos ${cardN('cm-inscritos')} = confirmados ${conf.length}');
        final off = (si * 37) % conf.length;
        final uiList = [
          for (var i = 0; i < uiTarget; i++) conf[(off + i) % conf.length]
        ];
        // ignore: avoid_print
        print('  [7] marcas por UI');
        // marcas por número + Enter
        var done = 0;
        for (final p in uiList.take(uiTarget - 3)) {
          await markNumber(p.regNumber);
          done++;
        }
        // por nombre sin tildes en mayúsculas (3 personas)
        for (final p in uiList.skip(uiTarget - 3)) {
          await t.enterText(
              find.byKey(const Key('cm-buscar')),
              '${normalizeText(p.firstName)} ${normalizeText(p.lastName1)}'
                  .toUpperCase());
          await settle(t);
          if (find
              .byKey(Key('cm-marcar-${p.regNumber}'))
              .evaluate()
              .isNotEmpty) {
            await tk('cm-marcar-${p.regNumber}');
            done++;
          } else {
            note(
                'Búsqueda por nombre de «${p.firstName} ${p.lastName1}»: sin botón Marcar visible');
          }
        }
        marksUi[sname] = done;
        final uiCount = int.tryParse(cardN('cm-pasaron')) ?? -1;
        ck(uiCount == done,
            'contador «Pasaron» = $uiCount tras $done marcas por la UI');
        if (si == 0) {
          // deshacer
          await tk('cm-deshacer');
          ck(int.tryParse(cardN('cm-pasaron')) == done - 1,
              'Deshacer última marca: Pasaron ${cardN('cm-pasaron')}');
          await markNumber(uiList.last.regNumber);
          // repetido: «ya pasó» → entendido
          await t.enterText(
              find.byKey(const Key('cm-buscar')), '${uiList.first.regNumber}');
          await settle(t);
          await t.tap(find.byKey(Key('cm-res-${uiList.first.regNumber}')));
          await settle(t);
          ck(find.byKey(const Key('cm-ya-paso')).evaluate().isNotEmpty,
              'marcar a quien ya pasó muestra «YA PASÓ POR ESTA SESIÓN»');
          await tk('cm-entendido');
          // repetido a propósito
          await t.enterText(
              find.byKey(const Key('cm-buscar')), '${uiList[1].regNumber}');
          await settle(t);
          await t.tap(find.byKey(Key('cm-res-${uiList[1].regNumber}')));
          await settle(t);
          await tk('cm-repetir');
          ck(int.tryParse(cardN('cm-pasaron')) == done,
              '«Marcar otra vez» no suma a Pasaron (${cardN('cm-pasaron')})');
          await t.enterText(find.byKey(const Key('cm-buscar')), '');
          await settle(t);
          await tk('cm-faltan');
          ck(find.textContaining('Faltan (').evaluate().isNotEmpty,
              'lista «Faltan (…)»: ${t.widgetList<Text>(find.textContaining('Faltan (')).first.data}');
          await t.tapAt(const Offset(5, 5));
          await settle(t);
        }
        // ignore: avoid_print
        print('  [7] repositorio');
        // el resto por repositorio (aparcando antes)
        final target = (conf.length * fill).round();
        final marked = (await rq(() => (db.select(db.controlRecords)
                  ..where((r) => r.sessionId.equals(sid) & r.undoneAt.isNull()))
                .get()))
            .map((r) => r.attendeeId)
            .toSet();
        var added = 0;
        await offlineWrite(() async {
          for (final p in conf) {
            if (marked.length + added >= target) break;
            if (marked.contains(p.id)) continue;
            await MealRepo(db).mark(sid, p.id, operatorName: 'Ruth (QA)');
            added++;
          }
        });
        marksRepo[sname] = added;
        await openEvent(evName);
        await goTo('Comidas');
        if (find.byKey(Key('ses-$sid')).evaluate().isEmpty) {
          // elegir la sesión en la lista
          final dd = find.byType(DropdownButtonFormField<String>);
          if (dd.evaluate().isNotEmpty) {
            await t.tap(dd.first);
            await settle(t);
            await t.tap(find.text(sname).last);
            await settle(t);
          }
        }
        final total = await activeMarks(sid);
        ck(int.tryParse(cardN('cm-pasaron')) == total,
            'tras el resto por repositorio Pasaron=${cardN('cm-pasaron')} = $total en BD');
        // ignore: avoid_print
        print('  [7] cerrar');
        await tk('cm-cerrar');
        await tk('cm-cerrar-ok');
        ck(cardN('res-inscritos') == '${conf.length}',
            'resumen: Inscritos ${cardN('res-inscritos')}');
        ck(cardN('res-pasaron') == '$total',
            'resumen: Pasaron ${cardN('res-pasaron')} (BD $total)');
        ck(cardN('res-no-pasaron') == '${conf.length - total}',
            'resumen: No pasaron ${cardN('res-no-pasaron')}');
        // ignore: avoid_print
        print('  [7] exportar');
        await tkS('ex-csv');
        await tkS('ex-excel');
        await tkS('ex-imagen');
        for (var i = 0; i < 8; i++) {
          await t.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 150)));
          await t.pump();
        }
        final g = grab('comidas-${normalizeText(sname).replaceAll(' ', '-')}');
        ck(g.length == 3, 'exportó csv, xlsx y png (${g.length} archivos)');
        for (final f in g) {
          final b = File('$exportDir/$f').readAsBytesSync();
          if (f.endsWith('.csv')) {
            final txt = utf8.decode(b);
            final si_ = RegExp(r'[,;]Sí[,;]').allMatches(txt).length;
            ck(si_ == total, 'CSV de comidas: filas «Sí» $si_ = $total');
          } else if (f.endsWith('.png')) {
            ck(b.take(4).toList().join(',') == '137,80,78,71',
                'PNG válido (${b.length} B)');
          } else if (f.endsWith('.xlsx')) {
            final z = ZipDecoder().decodeBytes(b);
            ck(z.findFile('xl/workbook.xml') != null,
                'XLSX válido (${b.length} B)');
          }
        }
        if (si == 0) {
          // reabrir, marcar una más, cerrar y exportar otra vez
          await t.pageBack();
          await settle(t);
          if (find.byKey(const Key('cm-reabrir')).evaluate().isEmpty) {
            // la pantalla vuelve a otra sesión abierta: se elige la cerrada en la lista de sesiones
            await t.tap(find.byType(DropdownButtonFormField<String>).first);
            await settle(t);
            await t.tap(find.text('$sname (cerrada)').last);
            await settle(t);
          }
          await tk('cm-reabrir');
          ck(find.byKey(const Key('cm-buscar')).evaluate().isNotEmpty,
              'reabrir la sesión permite marcar otra vez');
          final extra = conf.firstWhere((p) => !marked.contains(p.id) && true,
              orElse: () => conf.first);
          final nowMarked = (await rq(() => (db.select(db.controlRecords)
                    ..where(
                        (r) => r.sessionId.equals(sid) & r.undoneAt.isNull()))
                  .get()))
              .map((r) => r.attendeeId)
              .toSet();
          final cand = conf.where((p) => !nowMarked.contains(p.id)).toList();
          if (cand.isNotEmpty) {
            await markNumber(cand.first.regNumber);
            ck(await activeMarks(sid) == total + 1,
                'tras reabrir y marcar a la nº ${cand.first.regNumber}: ${await activeMarks(sid)} marcas');
          } else {
            note('nadie más para marcar (${extra.regNumber})');
          }
          await tk('cm-cerrar');
          await tk('cm-cerrar-ok');
          await tkS('ex-csv');
          grab('comidas-almuerzo-viernes-v2-tras-reabrir');
        }
        await home();
      });
    }

    await step('7.7', 'Comidas · totales', () async {
      final sess = await rq(() => (db.select(db.controlSessions)
            ..where((s) => s.eventId.equals(evId) & s.deletedAt.isNull()))
          .get());
      final recs = await rq(() => db.select(db.controlRecords).get());
      final active = recs
          .where((r) =>
              r.undoneAt == null &&
              r.deletedAt == null &&
              sess.any((s) => s.id == r.sessionId))
          .toList();
      final uiMarks = marksUi.values.fold<int>(0, (a, b) => a + b);
      final repoMarks = marksRepo.values.fold<int>(0, (a, b) => a + b);
      metrics['comidas_sesiones'] = sess.length;
      metrics['comidas_sesiones_cerradas'] =
          sess.where((s) => s.closedAt != null).length;
      metrics['comidas_marcas_activas_total'] = active.length;
      metrics['comidas_marcas_por_UI'] = uiMarks;
      metrics['comidas_marcas_por_repositorio'] = repoMarks;
      metrics['comidas_repetidos_bloqueados'] =
          sess.fold<int>(0, (a, s) => a + s.blockedRepeats);
      final plan =
          sess.where((s) => sessionDefs.any((d) => d.$2 == s.name)).toList();
      ck(plan.length == 6,
          '6 sesiones del plan (3 almuerzos + 3 cenas): ${plan.length} (más ${sess.length - plan.length} de verificación del paso 6)');
      ck(plan.every((s) => s.closedAt != null),
          'las 6 sesiones del plan quedan cerradas');
      note(
          'Marcas por la UI: $uiMarks · por repositorio: $repoMarks · activas en total: ${active.length}');
      final pre = (await attOf(evId))
          .where((r) => r.status == 'preregistered')
          .map((r) => r.id)
          .toSet();
      ck(!active.any((r) => pre.contains(r.attendeeId)),
          'ningún preinscrito tiene marcas de comida');
    });

    // ═════════════════════ PASO 8 · confirmar a todos + hospedaje ═════════════════════
    await step(
        '8a', 'Confirmar a todos (los preinscritos que quedaban) por la UI',
        () async {
      await goTo('Confirmar asistencia');
      final left = await prePending();
      await tk('ca-confirmar-todos');
      ck(find.byKey(const Key('ca-dialogo-todos')).evaluate().isNotEmpty,
          'diálogo «Confirmar a todos» con la cantidad');
      await tk('ca-dialogo-ok');
      final after = await prePending();
      ck(after == 0,
          'tras «Confirmar a todos» (eran $left) quedan $after preinscritos');
      ck(find.byKey(const Key('ca-vacio')).evaluate().isNotEmpty,
          'la pantalla dice que no hay preinscritos por confirmar');
      metrics['confirmados_final'] =
          (await attOf(evId)).where((r) => r.status == 'confirmed').length;
    });

    await step('8b',
        'Hospedaje: «Sugerir hospedaje» → aceptar (varias rondas) hasta ubicar a todos',
        () async {
      for (var attempt = 0; attempt < 4; attempt++) {
        final pend = (await attOf(evId))
            .where((r) => r.needsLodging && r.lodgingId == null)
            .length;
        note('Ronda ${attempt + 1}: pendientes de hospedaje $pend');
        if (pend == 0) break;
        await goTo('Hospedajes');
        if (find.byKey(const Key('hosp-sugerir')).evaluate().isEmpty) break;
        await tk('hosp-sugerir');
        await tk('sg-buscar');
        if (find.byKey(const Key('sg-aceptar-0')).evaluate().isEmpty) {
          note(
              'No hay propuesta: ${t.widgetList<Text>(find.byType(Text)).map((e) => e.data ?? '').where((e) => e.contains('sin lugar') || e.contains('Faltan') || e.contains('No hay')).take(3).join(' | ')}');
          break;
        }
        if (attempt == 0) {
          final betel = find.textContaining('Posada Betel').evaluate().length;
          final avisos = t
              .widgetList<Text>(find.byType(Text))
              .map((e) => e.data ?? '')
              .where((e) => RegExp(
                      r'capacidad|excede|Atención|sobrecupo|no caben|Faltan',
                      caseSensitive: false)
                  .hasMatch(e))
              .toList();
          note(
              'Propuesta en pantalla: «Posada Betel» aparece en $betel textos de tramos; avisos visibles antes de aceptar: ${avisos.isEmpty ? 'NINGUNO' : avisos}');
          final names = lodgingDefs.map((d) => d.$1).toSet();
          final tramos = t
              .widgetList<Text>(find.byType(Text))
              .map((e) => e.data ?? '')
              .where((e) =>
                  names.contains(e) ||
                  e.startsWith('Ocupación:') ||
                  RegExp(r'^\d+ personas?:').hasMatch(e))
              .map((e) => e.length > 70 ? '${e.substring(0, 70)}…' : e)
              .toList();
          note(
              'Tramos de la propuesta (nombre / personas / ocupación): $tramos');
        }
        await tk('sg-aceptar-0');
        if (find
            .byKey(const Key('sg-confirmar-parcial'))
            .evaluate()
            .isNotEmpty) {
          note('Propuesta incompleta: se acepta «Asignar a quienes caben»');
          await tk('sg-confirmar-parcial');
        }
        if (find.byKey(const Key('sg-continuar')).evaluate().isNotEmpty) {
          note('Avisos al aceptar: se acepta «Asignar de todas formas»');
          await tk('sg-continuar');
        }
        await settle(t);
      }
      final left = (await attOf(evId))
          .where((r) => r.needsLodging && r.lodgingId == null)
          .length;
      note('Sin hospedaje tras la sugerencia: $left');
      metrics['hospedaje_pendiente_tras_sugerencia'] = left;
    });

    // Asigna/reubica a una persona por su ficha con el buscador y los filtros del formulario.
    // Elige un hospedaje compatible (específico de su sexo antes que «Sin preferencia») con plazas libres.
    Future<bool> moveViaForm(AttendeeRow p, {String? avoid}) async {
      await goTo('Asistentes');
      await t.enterText(find.byKey(const Key('buscar')), '${p.regNumber}');
      await settle(t);
      await t.tap(find.byKey(Key('asistente-${p.regNumber}')).first);
      await settle(t);
      await t.ensureVisible(find.byKey(const Key('f-hosp-buscar')));
      await t.pump();
      if (!t
          .widget<FilterChip>(find.byKey(const Key('f-hosp-filtro-libres')))
          .selected) {
        await tq('f-hosp-filtro-libres');
      }
      final chipSexo =
          t.widget<FilterChip>(find.byKey(const Key('f-hosp-filtro-sexo')));
      if (chipSexo.onSelected != null && !chipSexo.selected) {
        await tq('f-hosp-filtro-sexo');
      }
      await tq('f-hosp-sel');
      final opt = lodgOptF();
      final texts =
          opt.evaluate().map((e) => (e.widget as Text).data ?? '').toList();
      final spec = p.sex == 'M' ? 'Solo hombres' : 'Solo mujeres';
      var idx = texts.indexWhere(
          (x) => x.contains(spec) && (avoid == null || !x.startsWith(avoid)));
      if (idx < 0) {
        idx = texts.indexWhere((x) =>
            x.contains('Sin preferencia') &&
            (avoid == null || !x.startsWith(avoid)));
      }
      if (idx < 0) {
        note(
            'nº ${p.regNumber}: sin hospedaje compatible con plazas en la lista del formulario (${texts.length} opciones)');
        await home();
        return false;
      }
      await t.tap(opt.at(idx));
      await settle(t);
      await tk('f-guardar');
      await home();
      return true;
    }

    await step('8b2',
        'Hospedaje: comprobar la propuesta aceptada y, si hay sobrecupo, reubicar a mano por la ficha (buscador y filtros)',
        () async {
      var rows = await attOf(evId);
      final lods = await lodOf(evId);
      final sp = await rq(() => SocialRepoProxy(db).spouseMap(evId));
      Map<String, int> occOf(List<AttendeeRow> rs) {
        final m = <String, int>{};
        for (final r in rs) {
          if (r.lodgingId != null) m[r.lodgingId!] = (m[r.lodgingId!] ?? 0) + 1;
        }
        return m;
      }

      var occ = occOf(rows);
      final over = lods.where((l) => (occ[l.id] ?? 0) > l.capacity).toList();
      final empty =
          lods.where((l) => (occ[l.id] ?? 0) == 0).map((l) => l.name).toList();
      metrics['sobrecupo_tras_sugerencia'] =
          over.map((l) => '${l.name}: ${occ[l.id]}/${l.capacity}').toList();
      note(
          'Tras aceptar la propuesta de «Sugerir hospedaje»: hospedajes con sobrecupo ${over.map((l) => '${l.name} ${occ[l.id]}/${l.capacity}').toList()}; hospedajes que quedaron VACÍOS: $empty');
      if (over.isNotEmpty) {
        bug(
            'Alta',
            '«Sugerir hospedaje» propone más gente de la que cabe: el mismo hospedaje «Sin preferencia» se llena varias veces y no avisa',
            'Con ${rows.length} personas que necesitan hospedaje (114 hombres, 100 mujeres, 22 matrimonios; 312 plazas en 22 hospedajes) la propuesta única de «Sugerir hospedaje» trae TRES tramos para «Posada Betel» (capacidad 20), cada uno «exactamente lleno», y la UI los acepta sin ningún aviso porque valida cada tramo por separado: resultado ${over.map((l) => '${l.name} ${occ[l.id]}/${l.capacity}').join(', ')}. Mientras, hospedajes compatibles con plazas libres quedan vacíos: ${empty.join(', ')}. Reproducido también a nivel de datos con suggestLodging (packages/mi_evento_core/lib/src/lodging_suggest.dart): los mismos 214 con los mismos hospedajes dan 3 tramos de 20 para «Posada Betel». Con el volumen del QA anterior (120 personas) no ocurría. Causa probable: el comodín «Sin preferencia» se reutiliza para cada categoría (matrimonios, hombres, mujeres) sin descontar lo ya asignado en los tramos anteriores.');
      }
      ck(over.isEmpty,
          'la propuesta aceptada no excede la capacidad de ningún hospedaje (${over.length} con sobrecupo)');
      // Corrección manual como lo haría una persona: sacar solteros del hospedaje excedido.
      var moved = 0, failed = 0;
      for (final l in over) {
        var excess = (occ[l.id] ?? 0) - l.capacity;
        final singles = rows
            .where((r) => r.lodgingId == l.id && !sp.containsKey(r.id))
            .toList();
        for (final p in singles) {
          if (excess <= 0) break;
          if (await moveViaForm(p, avoid: l.name)) {
            moved++;
            excess--;
          } else {
            failed++;
          }
        }
        if (excess > 0) {
          note(
              '«${l.name}» sigue excedido en $excess (solo quedaban matrimonios o no hubo sitio).');
        }
      }
      rows = await attOf(evId);
      occ = occOf(rows);
      final still = lods.where((l) => (occ[l.id] ?? 0) > l.capacity).length;
      note(
          'Reubicados a mano por la ficha: $moved (fallos $failed). Hospedajes aún excedidos: $still');
      metrics['hospedaje_reubicados_a_mano_por_sobrecupo'] = moved;
      if (over.isNotEmpty) {
        ck(still == 0,
            'tras reubicar a mano no queda ningún hospedaje excedido ($still)');
      }
    });

    await step('8c',
        'Hospedaje: asignación manual con buscador y filtros del formulario (reasignar solteros) y de quienes queden',
        () async {
      var rows = await attOf(evId);
      final sp = await rq(() => SocialRepoProxy(db).spouseMap(evId));
      final lods = await lodOf(evId);
      final nameOfL = {for (final l in lods) l.id: l};
      // 1) quienes queden sin hospedaje
      final left =
          rows.where((r) => r.needsLodging && r.lodgingId == null).toList();
      // 2) tres solteros ya hospedados para probar la reasignación manual
      final singles = rows
          .where((r) =>
              r.lodgingId != null &&
              !sp.containsKey(r.id) &&
              nameOfL[r.lodgingId]!.accepts == 'any')
          .take(3)
          .toList();
      final targets = [...left.take(25), ...singles];
      // Sonda: elegir a mano para una mujer soltera una casa de MATRIMONIOS: debe avisar (sin guardar).
      final probe = rows
          .where((r) =>
              r.sex == 'F' && r.lodgingId != null && !sp.containsKey(r.id))
          .firstOrNull;
      if (probe != null) {
        await goTo('Asistentes');
        await t.enterText(
            find.byKey(const Key('buscar')), '${probe.regNumber}');
        await settle(t);
        await t.tap(find.byKey(Key('asistente-${probe.regNumber}')).first);
        await settle(t);
        await tq('f-hosp-sel');
        final texts = lodgOptF()
            .evaluate()
            .map((e) => (e.widget as Text).data ?? '')
            .toList();
        final idx = texts.indexWhere((x) => x.contains('Matrimonios'));
        if (idx >= 0) {
          await t.tap(lodgOptF().at(idx));
          await settle(t);
          final msgs = [
            for (final k in ['f-hosp-aviso', 'f-hosp-separa'])
              if (find.byKey(Key(k)).evaluate().isNotEmpty)
                t.widget<Text>(find.byKey(Key(k))).data ?? ''
          ];
          note(
              'Sonda: mujer soltera nº ${probe.regNumber} → casa de «Matrimonios»: avisos ${msgs.isEmpty ? 'NINGUNO' : msgs}; el botón Guardar sigue activo=${t.widget<ButtonStyleButton>(find.byKey(const Key('f-guardar'))).onPressed != null} (no se guarda)');
          ck(msgs.isNotEmpty,
              'elegir una casa de matrimonios para una mujer soltera muestra un aviso');
        }
        await home();
      }
      var okN = 0;
      for (final p in targets) {
        if (await moveViaForm(p, avoid: nameOfL[p.lodgingId]?.name)) okN++;
      }
      rows = await attOf(evId);
      final stillLeft =
          rows.where((r) => r.needsLodging && r.lodgingId == null).toList();
      ck(okN == targets.length,
          'asignadas/reasignadas $okN de ${targets.length} personas con el formulario (${left.length} pendientes + ${singles.length} reasignaciones)');
      note(
          'Pendientes que no pudo resolver la asignación manual: ${stillLeft.length}');
      metrics['hospedaje_manual_por_formulario'] = targets.length;
    });

    await step('8d',
        'Hospedaje: pendientes finales por «Asignar personas» del hospedaje (buscador, filtro y grupo) y verificación',
        () async {
      var rows = await attOf(evId);
      var left =
          rows.where((r) => r.needsLodging && r.lodgingId == null).toList();
      if (left.isNotEmpty) {
        final lods = await lodOf(evId);
        final allNow = await attOf(evId);
        final views = {
          for (final l in lods)
            l.id: allNow.where((a) => a.lodgingId == l.id).length
        };
        for (final p in left.take(20)) {
          // un hospedaje compatible con plazas
          final okL = lods
              .where((l) =>
                  (views[l.id] ?? 0) < l.capacity &&
                  lodgingFitsPerson(lodgingAcceptsFromDb(l.accepts),
                      p.sex == 'M' ? Sex.male : Sex.female,
                      hasSpouse: false))
              .toList();
          if (okL.isEmpty) continue;
          await goTo('Hospedajes');
          await t.tap(find.byKey(Key('hosp-${okL.first.name}')).first);
          await settle(t);
          await tk('hd-asignar');
          await t.enterText(
              find.byKey(const Key('as-buscar')), '${p.regNumber}');
          await settle(t);
          if (find.byKey(Key('as-${p.regNumber}')).evaluate().isNotEmpty) {
            await tk('as-${p.regNumber}');
            await tk('as-confirmar');
            if (find.byKey(const Key('hd-continuar')).evaluate().isNotEmpty) {
              await tk('hd-continuar');
            }
            views[okL.first.id] = (views[okL.first.id] ?? 0) + 1;
          }
          await home();
        }
        rows = await attOf(evId);
        left =
            rows.where((r) => r.needsLodging && r.lodgingId == null).toList();
      } else {
        // aun sin pendientes: se prueba el diálogo «Asignar personas» (abrir, buscar, cancelar)
        final lods = await lodOf(evId);
        await goTo('Hospedajes');
        await t.tap(find.byKey(Key('hosp-${lods.first.name}')).first);
        await settle(t);
        await tk('hd-asignar');
        ck(find.byKey(const Key('as-buscar')).evaluate().isNotEmpty,
            'diálogo «Asignar personas» abre con buscador');
        await t.tap(find.text('Cancelar'));
        await settle(t);
        await home();
      }
      // VERIFICACIÓN FINAL por consulta
      rows = await attOf(evId);
      final conf = rows.where((r) => r.status == 'confirmed').toList();
      final lods = await lodOf(evId);
      final lmap = {for (final l in lods) l.id: l};
      final sp = await rq(() => SocialRepoProxy(db).spouseMap(evId));
      final byId = {for (final r in rows) r.id: r};
      final sinHosp = conf.where((r) => r.lodgingId == null).toList();
      metrics['hospedaje_confirmados_sin_hospedaje'] = sinHosp.length;
      ck(sinHosp.isEmpty,
          'ningún confirmado sin hospedaje: ${sinHosp.length} sin hospedaje (${sinHosp.take(8).map((r) => '#${r.regNumber} ${r.firstName} ${r.lastName1} ${r.sex} ${sp.containsKey(r.id) ? '(casado/a)' : ''}').join('; ')})',
          sev: sinHosp.isEmpty ? null : 'Alta',
          title:
              'Hay confirmados que se quedan sin hospedaje aunque hay capacidad total suficiente',
          detail:
              '${sinHosp.length} confirmados sin hospedaje tras «Sugerir hospedaje» (varias rondas) + asignación manual, con ${lodgingDefs.fold<int>(0, (s, d) => s + d.$3)} plazas para ${conf.length} personas. Ejemplos: ${sinHosp.take(8).map((r) => '#${r.regNumber} ${r.sex}').join(', ')}.');
      var over = 0;
      final occ = <String, int>{};
      for (final r in rows) {
        if (r.lodgingId != null) {
          occ[r.lodgingId!] = (occ[r.lodgingId!] ?? 0) + 1;
        }
      }
      for (final l in lods) {
        if ((occ[l.id] ?? 0) > l.capacity) over++;
      }
      ck(over == 0, 'ningún hospedaje excede su capacidad ($over excedidos)');
      var misfit = 0;
      final misList = <String>[];
      for (final r in rows) {
        if (r.lodgingId == null) continue;
        final fits = lodgingFitsPerson(
            lodgingAcceptsFromDb(lmap[r.lodgingId]!.accepts),
            r.sex == 'M' ? Sex.male : Sex.female,
            hasSpouse: sp.containsKey(r.id));
        if (!fits) {
          misfit++;
          misList.add(
              '#${r.regNumber} ${r.sex}${sp.containsKey(r.id) ? ' casado/a' : ''} en «${lmap[r.lodgingId]!.name}»');
        }
      }
      ck(misfit == 0,
          'todos en un hospedaje compatible con su sexo/estado: $misfit incompatibles ${misList.take(5)}');
      var split = 0;
      sp.forEach((a, b) {
        if (a.compareTo(b) < 0 && byId[a]!.lodgingId != byId[b]!.lodgingId) {
          split++;
        }
      });
      ck(split == 0,
          'todos los matrimonios van juntos: $split separados de ${sp.length ~/ 2}');
      final assigned = rows.where((r) => r.lodgingId != null).length;
      metrics['hospedaje_asignaciones'] = assigned;
      metrics['hospedaje_ocupacion_max'] = lods
          .map((l) => '${l.name}: ${occ[l.id] ?? 0}/${l.capacity}')
          .toList();
      note(
          'Asignaciones de hospedaje: $assigned de ${rows.length} personas (${conf.length} confirmadas).');
    });

    // ═════════════════════ PASO 9 · búsqueda, filtros, ordenar, exportar ═════════════════════
    await step('9a',
        'Asistentes: búsqueda, filtros (sexo/iglesia/hospedaje/equipo/asistencia), tabla ordenable y CSV',
        () async {
      await openEvent(evName);
      await goTo('Asistentes');
      final rows = await attOf(evId);
      ck(find.byType(DataTable).evaluate().isNotEmpty,
          'a 1366 px la lista es una TABLA');
      ck(txt('lista-conteo') == '${rows.length} inscritos',
          'conteo «${txt('lista-conteo')}»');
      // ordenar por Edad
      int firstAge() => int.parse(((t
              .widget<DataTable>(find.byType(DataTable))
              .rows
              .first
              .cells[3]
              .child) as Text)
          .data!);
      await t.tap(find.descendant(
          of: find.byType(DataTable), matching: find.text('Edad')));
      await settle(t);
      final a1 = firstAge();
      await t.tap(find.descendant(
          of: find.byType(DataTable), matching: find.text('Edad')));
      await settle(t);
      final a2 = firstAge();
      final minAge = rows.map((r) => r.age).reduce((a, b) => a < b ? a : b);
      final maxAge = rows.map((r) => r.age).reduce((a, b) => a > b ? a : b);
      ck(a1 == minAge && a2 == maxAge,
          'orden por Edad: ascendente $a1 (mín $minAge), descendente $a2 (máx $maxAge)');
      // búsqueda
      await t.enterText(find.byKey(const Key('buscar')), 'nunez');
      await settle(t);
      final expN = rows
          .where((r) =>
              normalizeText('${r.firstName} ${r.lastName1} ${r.lastName2}')
                  .contains('nunez') ||
              (myChurches.any((c) => false)))
          .length;
      ck(txt('lista-conteo').contains('de ${rows.length}'),
          'búsqueda «nunez» → «${txt('lista-conteo')}» (≥$expN por nombre; también cuenta la iglesia)');
      await t.enterText(find.byKey(const Key('buscar')), '');
      await settle(t);
      // filtros
      Future<void> pickFilter(String key, String label) async {
        if (find.byKey(const Key('filtro-sexo')).evaluate().isEmpty) {
          await tk('filtros-toggle');
        }
        await t.tap(find.byKey(Key(key)));
        await settle(t);
        await t.tap(find.text(label).last);
        await settle(t);
      }

      await pickFilter('filtro-sexo', 'Mujeres');
      final mujeres = rows.where((r) => r.sex == 'F').length;
      ck(txt('lista-conteo') == '$mujeres de ${rows.length}',
          'filtro Sexo=Mujeres → «${txt('lista-conteo')}» (BD $mujeres)');
      await tk('exportar-csv');
      final f1 = grab('asistentes-filtrado-mujeres');
      if (f1.isNotEmpty) {
        final r = parseCsv(
            utf8.decode(File('$exportDir/${f1.first}').readAsBytesSync()));
        ck(r.length - 1 == mujeres,
            'CSV filtrado (mujeres): ${r.length - 1} filas');
      }
      final ch0 = (await rq(() => (db.select(db.churches)
            ..where((c) => c.name.equals('Bautista Ebenezer')))
          .getSingle()));
      await pickFilter('filtro-iglesia', 'Bautista Ebenezer');
      final nm = rows.where((r) => r.sex == 'F' && r.churchId == ch0.id).length;
      ck(txt('lista-conteo') == '$nm de ${rows.length}',
          'filtros Mujeres + Iglesia Ebenezer → «${txt('lista-conteo')}» (BD $nm)');
      final lods = await lodOf(evId);
      final lod0 = lods.firstWhere((l) => l.name == 'Albergue Betania Mujeres');
      await pickFilter('filtro-hospedaje', 'Albergue Betania Mujeres');
      final nh = rows
          .where((r) =>
              r.sex == 'F' && r.churchId == ch0.id && r.lodgingId == lod0.id)
          .length;
      ck(txt('lista-conteo').startsWith('$nh de'),
          'añadir En el hospedaje=Albergue Betania Mujeres → «${txt('lista-conteo')}» (BD $nh)');
      final team0 = (await teamOf(evId)).first;
      await pickFilter('filtro-equipo', team0.name);
      final nt = rows
          .where((r) =>
              r.sex == 'F' &&
              r.churchId == ch0.id &&
              r.lodgingId == lod0.id &&
              r.teamId == team0.id)
          .length;
      ck(txt('lista-conteo').startsWith('$nt de'),
          'añadir Equipo=${team0.name} → «${txt('lista-conteo')}» (BD $nt)');
      await pickFilter('filtro-asistencia', 'Confirmados');
      await pickFilter('filtro-hospedaje-estado', 'Con hospedaje');
      ck(txt('lista-conteo').startsWith('$nt de'),
          'Asistencia=Confirmados + Hospedaje=Con hospedaje no cambia (todos lo están): «${txt('lista-conteo')}»');
      // limpiar filtros (la pantalla conserva su estado al volver): «Todos» en cada uno
      for (final k in [
        'filtro-asistencia',
        'filtro-sexo',
        'filtro-iglesia',
        'filtro-hospedaje-estado',
        'filtro-hospedaje',
        'filtro-equipo'
      ]) {
        await pickFilter(k, 'Todos');
      }
      ck(txt('lista-conteo') == '${rows.length} inscritos',
          'sin filtros el conteo vuelve a «${txt('lista-conteo')}»');
      await tk('exportar-csv');
      final f2 = grab('asistentes-completo');
      if (f2.isNotEmpty) {
        final r = parseCsv(
            utf8.decode(File('$exportDir/${f2.first}').readAsBytesSync()));
        ck(r.length - 1 == rows.length,
            'CSV completo: ${r.length - 1} filas = ${rows.length} personas');
        final head = r.first.join(';');
        ck(head.startsWith('id;numero;nombre'), 'cabecera del CSV: $head');
      }
    });

    await step('9b',
        'Hospedajes: búsqueda, filtro «Acepta», plazas libres, tabla ordenable y CSV',
        () async {
      await goTo('Hospedajes');
      final lods = await lodOf(evId);
      ck(find.byType(DataTable).evaluate().isNotEmpty, 'tabla de hospedajes');
      await t.enterText(find.byKey(const Key('hosp-buscar')), 'casa');
      await settle(t);
      final nCasa = lods
          .where((l) => normalizeText(
                  '${l.name} ${l.hostName ?? ''} ${l.directions} ${l.distanceNote}')
              .contains('casa'))
          .length;
      ck(txt('hosp-conteo') == '$nCasa de ${lods.length}',
          'búsqueda «casa»: «${txt('hosp-conteo')}» (BD $nCasa)');
      await t.enterText(find.byKey(const Key('hosp-buscar')), '');
      await settle(t);
      if (find.byKey(const Key('hosp-filtro-acepta')).evaluate().isEmpty) {
        await tk('filtros-toggle');
      }
      await t.tap(find.byKey(const Key('hosp-filtro-acepta')));
      await settle(t);
      await t.tap(find.text('Matrimonios').last);
      await settle(t);
      final nm = lods.where((l) => l.accepts == 'couples').length;
      ck(txt('hosp-conteo') == '$nm de ${lods.length}',
          'filtro Acepta=Matrimonios: «${txt('hosp-conteo')}» (BD $nm)');
      await tk('hosp-filtro-libres');
      note('Con «solo plazas libres» además: «${txt('hosp-conteo')}»');
      await tk('hosp-exportar');
      final f = grab('hospedajes-filtrado-matrimonios-libres');
      await t.tap(find.byKey(const Key('hosp-filtro-acepta')));
      await settle(t);
      await t.tap(find.text('Todos').last);
      await settle(t);
      await tk('hosp-filtro-libres');
      ck(txt('hosp-conteo') == '${lods.length} hospedajes',
          'sin filtros: «${txt('hosp-conteo')}»');
      await t.tap(find.descendant(
          of: find.byType(DataTable), matching: find.text('Capacidad')));
      await settle(t);
      final capFirst = ((t
              .widget<DataTable>(find.byType(DataTable))
              .rows
              .first
              .cells[3]
              .child) as Text)
          .data;
      ck(
          capFirst ==
              '${lods.map((l) => l.capacity).reduce((a, b) => a < b ? a : b)}',
          'orden por Capacidad ascendente: primera fila $capFirst');
      await tk('hosp-exportar');
      final f2 = grab('hospedajes-completo');
      if (f2.isNotEmpty) {
        final r = parseCsv(
            utf8.decode(File('$exportDir/${f2.first}').readAsBytesSync()));
        ck(r.length - 1 == lods.length,
            'CSV de hospedajes: ${r.length - 1} filas = ${lods.length}');
        note('Cabecera: ${r.first.join(';')}');
      }
      note('Archivos filtrado: $f');
    });

    await step('9c', 'Equipos: búsqueda y CSV (con «Sin equipo»)', () async {
      await goTo('Equipos');
      final teams = await teamOf(evId);
      final rows = await attOf(evId);
      ck(txt('eq-resumen').contains('${teams.length} equipos'),
          'resumen «${txt('eq-resumen')}»');
      await t.enterText(find.byKey(const Key('eq-buscar')), teams.first.name);
      await settle(t);
      ck(
          txt('eq-conteo').contains('de ${teams.length}') ||
              txt('eq-conteo').contains('${teams.length}'),
          'búsqueda por equipo: «${txt('eq-conteo')}»');
      await t.enterText(find.byKey(const Key('eq-buscar')), '');
      await settle(t);
      await tk('eq-exportar');
      final f = grab('equipos-completo');
      if (f.isNotEmpty) {
        final r = parseCsv(
            utf8.decode(File('$exportDir/${f.first}').readAsBytesSync()));
        ck(r.length - 1 == rows.length,
            'CSV de equipos: ${r.length - 1} filas = ${rows.length} personas');
      }
      final st = <String>[];
      final tsNow = await teamOf(evId);
      final allNow = await attOf(evId);
      for (final x in tsNow) {
        final m = allNow.where((a) => a.teamId == x.id).toList();
        final men = m.where((a) => a.sex == 'M').length;
        st.add(
            '${x.name}: ${m.length} (H$men/M${m.length - men}, edad media ${(m.fold<int>(0, (s, a) => s + a.age) / (m.isEmpty ? 1 : m.length)).toStringAsFixed(1)})');
      }
      note('Equipos al final: ${st.join(' | ')}');
      metrics['equipos_resumen'] = st;
    });

    await step('9d', 'Mis eventos: búsqueda, tabla ordenable y CSV', () async {
      await openEventsList();
      final evs = await rq(() =>
          (db.select(db.events)..where((e) => e.deletedAt.isNull())).get());
      ck(find.byType(DataTable).evaluate().isNotEmpty, 'tabla de eventos');
      ck(txt('ev-conteo') == '${evs.length} eventos',
          'conteo «${txt('ev-conteo')}»');
      await t.enterText(find.byKey(const Key('ev-buscar')), 'estructura');
      await settle(t);
      ck(txt('ev-conteo') == '1 de ${evs.length}',
          'búsqueda «estructura»: «${txt('ev-conteo')}»');
      await t.enterText(find.byKey(const Key('ev-buscar')), '');
      await settle(t);
      await t.tap(find.descendant(
          of: find.byType(DataTable), matching: find.text('Nombre')));
      await settle(t);
      final first = ((t
              .widget<DataTable>(find.byType(DataTable))
              .rows
              .first
              .cells[0]
              .child) as Text)
          .data;
      final maxName = evs.map((e) => e.name).reduce(
          (a, b) => normalizeText(a).compareTo(normalizeText(b)) > 0 ? a : b);
      ck(first == maxName,
          'orden por Nombre descendente: primera fila «$first»');
      await tk('ev-exportar');
      final f = grab('eventos');
      if (f.isNotEmpty) {
        final r = parseCsv(
            utf8.decode(File('$exportDir/${f.first}').readAsBytesSync()));
        ck(r.length - 1 == evs.length, 'CSV de eventos: ${r.length - 1} filas');
      }
      metrics['eventos_total'] = evs.length;
    });

    // ═════════════════════ PASO 10 · exportaciones ═════════════════════
    await step('10a',
        'Exportaciones de «Copias de seguridad»: plantilla, CSV de asistentes y respaldo CSV del evento',
        () async {
      await openEvent(evName);
      await goTo('Copias de seguridad');
      await tkS('csv-plantilla');
      final p = grab('plantilla');
      await tkS('csv-exportar');
      final a = grab('asistentes-backup-screen');
      await tkS('bk-guardar');
      final b = grab('respaldo-evento');
      ck(p.length == 1 && a.length == 1 && b.length == 1,
          'plantilla, CSV y respaldo guardados: $p $a $b');
      if (p.isNotEmpty) {
        final r = parseCsv(
            utf8.decode(File('$exportDir/${p.first}').readAsBytesSync()));
        ck(r.length == 1 && r.first.length == attendeeCsvHeaders.length,
            'la plantilla trae solo las ${attendeeCsvHeaders.length} cabeceras');
      }
    });

    await step('10b',
        'Reportes finales (todos confirmados): xlsx, csv (con y sin teléfono) y pdf',
        () async {
      await goTo('Reportes');
      final all0 = await attOf(evId);
      ck(txt('rp-total').contains('${all0.length}'),
          'Reportes dice «${txt('rp-total')}» (todos confirmados: ${all0.length})');
      await tk('rp-excel');
      await tk('rp-csv');
      await tk('rp-pdf');
      for (var i = 0; i < 8; i++) {
        await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 150)));
        await t.pump();
      }
      final g = grab('reportes-final');
      await tk('rp-telefono');
      await tk('rp-csv');
      final g2 = grab('reportes-final-con-telefono');
      ck(g.length == 3 && g2.length == 1,
          'xlsx, csv y pdf + csv con teléfono: $g $g2');
      for (final f in [...g, ...g2]) {
        final b = File('$exportDir/$f').readAsBytesSync();
        if (f.endsWith('.pdf')) {
          ck(String.fromCharCodes(b.take(5)) == '%PDF-',
              'PDF válido (${b.length} B)');
        }
        if (f.endsWith('.xlsx')) {
          final z = ZipDecoder().decodeBytes(b);
          final wb =
              utf8.decode(z.findFile('xl/workbook.xml')!.content as List<int>);
          ck(wb.contains('Resumen') && wb.contains('Asistentes'),
              'XLSX con hojas Resumen y Asistentes (${b.length} B)');
        }
        if (f.endsWith('.csv')) {
          final r = parseCsv(utf8.decode(b));
          ck(r.length - 1 == all0.length,
              'CSV de reportes: ${r.length - 1} filas = ${all0.length}');
        }
      }
      // Lista imprimible de un hospedaje: el botón usa Printing.sharePdf (no pasa por FileSaver); se genera con la misma función.
      final lods = await lodOf(evId);
      final churches = await rq(() => db.select(db.churches).get());
      final ev = await rq(() =>
          (db.select(db.events)..where((e) => e.id.equals(evId))).getSingle());
      var n = 0;
      for (final l in lods.where((l) => [
            'Albergue Central Hombres',
            'Casa Familia Gómez'
          ].contains(l.name))) {
        final occ = all0.where((a) => a.lodgingId == l.id).toList();
        final bytes = await rq(() => buildLodgingPdf(
            eventName: ev.name,
            eventDates: 'del ${ev.startDate} al ${ev.endDate}',
            lodging: l,
            occupants: occ,
            churchNames: {for (final c in churches) c.id: c.name}));
        File('$exportDir/${(++fileSeq).toString().padLeft(2, '0')}-lista-hospedaje--Lista - ${l.name}.pdf')
            .writeAsBytesSync(bytes);
        exported.add((
          '${fileSeq.toString().padLeft(2, '0')}-lista-hospedaje--Lista - ${l.name}.pdf',
          bytes.length,
          'lista-hospedaje (función, no UI)'
        ));
        n++;
      }
      ck(n == 2, 'listas PDF de hospedaje generadas con buildLodgingPdf: $n');
      limits.add(
          '«Guardar como PDF» de la lista de un hospedaje usa Printing.sharePdf (canal de plataforma), que no pasa por el FileSaver de pruebas; se generó el PDF llamando a buildLodgingPdf (no por la UI).');
    });

    await step('10c', 'CSV de asistentes y respaldo de CADA evento', () async {
      for (final name in [copyFull, copyStruct]) {
        await openEvent(name);
        await goTo('Copias de seguridad');
        await tkS('csv-exportar');
        final a = grab(
            'asistentes-evento-${normalizeText(name).replaceAll(' ', '-')}');
        await tkS('bk-guardar');
        final b =
            grab('respaldo-evento-${normalizeText(name).replaceAll(' ', '-')}');
        final id = await evIdByName(name);
        final n = (await attOf(id)).length;
        if (a.isNotEmpty) {
          final r = parseCsv(
              utf8.decode(File('$exportDir/${a.first}').readAsBytesSync()));
          ck(r.length - 1 == n,
              '«$name»: CSV de asistentes ${r.length - 1} filas = $n personas');
        }
        ck(b.length == 1, '«$name»: respaldo CSV guardado');
      }
      // el evento principal: CSV de asistentes por su evento
      await openEvent(evName);
      await goTo('Copias de seguridad');
      await tkS('csv-exportar');
      grab('asistentes-evento-${normalizeText(evName).replaceAll(' ', '-')}');
    });

    // ═════════════════════ PASO 11 · ida y vuelta ═════════════════════
    await step('11',
        'Ida y vuelta del respaldo CSV: reabrir en una base vacía y comparar',
        () async {
      await park();
      final svc = BackupService(db);
      final bytes = await rq(() => svc.export(evId));
      final db2 = qaDb();
      try {
        await t.runAsync(() async {
          await BackupService(db2).import(decodeBundle(bytes));
        });
        final q1 = QaEvent(db, evId, const [], const {}, const []);
        final q2 = QaEvent(db2, evId, const [], const {}, const []);
        final f1 = await rq(() => qaFilas(q1));
        final f2 = await rq(() => qaFilas(q2));
        ck(f1.length == f2.length,
            'personas: original ${f1.length} · restaurado ${f2.length}');
        var diff = 0;
        String? firstDiff;
        for (var i = 0; i < f1.length && i < f2.length; i++) {
          if ('${f1[i]}' != '${f2[i]}') {
            diff++;
            firstDiff ??= '${f1[i]} <> ${f2[i]}';
          }
        }
        ck(diff == 0,
            'cada fila coincide (numero, nombre, sexo, edad, iglesia, tel, hospedaje, equipo, pareja, grupos, obs): $diff diferencias ${firstDiff ?? ''}');
        final a1 = await rq(() => (db.select(db.attendees)
              ..where((a) => a.eventId.equals(evId)))
            .get());
        final a2 = await rq(() => (db2.select(db2.attendees)
              ..where((a) => a.eventId.equals(evId)))
            .get());
        final m2 = {for (final a in a2) a.id: a};
        var stDiff = 0;
        for (final a in a1) {
          final b = m2[a.id];
          if (b == null ||
              b.status != a.status ||
              b.confirmedAt?.millisecondsSinceEpoch !=
                  a.confirmedAt?.millisecondsSinceEpoch ||
              b.needsLodging != a.needsLodging ||
              b.dedupeKey != a.dedupeKey) {
            stDiff++;
          }
        }
        ck(stDiff == 0,
            'ids, estado (confirmado/preinscrito), confirmedAt y necesidad de hospedaje idénticos: $stDiff diferencias');
        final sessions1 = await rq(() => (db.select(db.controlSessions)
              ..where((s) => s.eventId.equals(evId)))
            .get());
        final sessions2 = await rq(() => (db2.select(db2.controlSessions)
              ..where((s) => s.eventId.equals(evId)))
            .get());
        final r1 = await rq(() => db.select(db.controlRecords).get());
        final r2 = await rq(() => db2.select(db2.controlRecords).get());
        ck(sessions1.length == sessions2.length && r1.length == r2.length,
            'comidas: sesiones ${sessions1.length}/${sessions2.length} · marcas ${r1.length}/${r2.length}');
        final l1 = await lodOf(evId);
        final l2 = await rq(() => (db2.select(db2.lodgings)
              ..where((l) => l.eventId.equals(evId)))
            .get());
        ck(l1.length == l2.length, 'hospedajes ${l1.length}/${l2.length}');
        final t1 = await teamOf(evId);
        final t2 = await rq(() => (db2.select(db2.teams)
              ..where((x) => x.eventId.equals(evId)))
            .get());
        ck(t1.length == t2.length, 'equipos ${t1.length}/${t2.length}');
        final g1 = await rq(() => (db.select(db.attendeeGroups)
              ..where((g) => g.eventId.equals(evId)))
            .get());
        final g2 = await rq(() => (db2.select(db2.attendeeGroups)
              ..where((g) => g.eventId.equals(evId)))
            .get());
        ck(g1.length == g2.length, 'grupos ${g1.length}/${g2.length}');
        // el archivo guardado por la UI (paso 10a) también se reabre
        final saved = Directory(exportDir)
            .listSync()
            .whereType<File>()
            .firstWhere((f) => f.path.contains('respaldo-evento--'));
        final db3 = qaDb();
        try {
          await t.runAsync(() async => BackupService(db3).import(
              decodeBundle(Uint8List.fromList(saved.readAsBytesSync()))));
          final n3 = await rq(() => (db3.select(db3.attendees)
                ..where((a) => a.eventId.equals(evId)))
              .get());
          ck(n3.length == a1.length,
              'el archivo exportado por la UI (${saved.path.split('/').last}) se reabre en base vacía: ${n3.length} personas');
        } finally {
          await t.runAsync(() => db3
              .close()
              .timeout(const Duration(seconds: 5), onTimeout: () {}));
        }
        metrics['ida_y_vuelta'] =
            'personas ${f1.length}=${f2.length}, diferencias de fila $diff, de estado $stDiff';
      } finally {
        await t.runAsync(() =>
            db2.close().timeout(const Duration(seconds: 5), onTimeout: () {}));
      }
    });

    // ═════════════════════ PASO 12 · 1920x1080 ═════════════════════
    await step('12', 'Pasada a 1920x1080 por todas las pantallas', () async {
      t.view.physicalSize = const Size(1920, 1080);
      await t.pump();
      await openEvent(evName);
      for (final label in [
        'Panel',
        'Asistentes',
        'Confirmar asistencia',
        'Hospedajes',
        'Equipos',
        'Comidas',
        'Reportes',
        'Configuración',
        'Copias de seguridad'
      ]) {
        await goTo(label);
        final ex = t.takeException();
        ck(ex == null,
            '1920x1080 · «$label» sin desbordes/errores${ex == null ? '' : ': ${_s(ex)}'}');
        if (ex != null) {
          bug('Media', 'Desborde en «$label» a 1920x1080', _s(ex));
        }
      }
      await goTo('Asistentes');
      ck(find.byType(DataTable).evaluate().isNotEmpty,
          '1920x1080: Asistentes es tabla');
      ck(find.byKey(const Key('filtro-sexo')).evaluate().isNotEmpty,
          '1920x1080: filtros visibles (alto ≥ 720)');
      await t.enterText(find.byKey(const Key('buscar')), 'ñ');
      await settle(t);
      note('Búsqueda «ñ» a 1920x1080: ${txt('lista-conteo')}');
      await t.enterText(find.byKey(const Key('buscar')), '');
      await settle(t);
      await openEventsList();
      ck(find.byType(DataTable).evaluate().isNotEmpty,
          '1920x1080: Mis eventos es tabla');
      // y a 1093x614 (1366x768 al 125 %): la barra de filtros arranca plegada
      t.view.physicalSize = const Size(1093, 614);
      await t.pump();
      await openEvent(evName);
      await goTo('Asistentes');
      ck(find.byKey(const Key('filtro-sexo')).evaluate().isEmpty,
          '1093x614 (alto < 720): los filtros arrancan plegados');
      await tk('filtros-toggle');
      ck(find.byKey(const Key('filtro-sexo')).evaluate().isNotEmpty,
          '«Filtros» los despliega');
      await tk('filtros-toggle');
      ck(find.byKey(const Key('filtro-sexo')).evaluate().isEmpty,
          '«Filtros» los vuelve a plegar');
      final ex = t.takeException();
      ck(ex == null,
          '1093x614 sin desbordes${ex == null ? '' : ': ${_s(ex)}'}');
      t.view.physicalSize = const Size(1366, 768);
      await t.pump();
    });

    // ═════════════════════ FINAL ═════════════════════
    await step('13', 'Cifras finales', () async {
      final rows = await attOf(evId);
      metrics['evento_principal_personas'] = rows.length;
      metrics['confirmados_final'] =
          rows.where((r) => r.status == 'confirmed').length;
      metrics['preinscritos_final'] =
          rows.where((r) => r.status == 'preregistered').length;
      metrics['hombres'] = rows.where((r) => r.sex == 'M').length;
      metrics['mujeres'] = rows.where((r) => r.sex == 'F').length;
      metrics['vias'] =
          'formulario $formRegistered · CSV A $csvANew · CSV B (preinscripción) $csvBNew';
      metrics['hospedajes_via_UI'] = lodgingsViaUiCount;
      final evs = await rq(() =>
          (db.select(db.events)..where((e) => e.deletedAt.isNull())).get());
      metrics['eventos'] = evs.map((e) => e.name).toList();
      note(
          'Cifras: ${metrics['vias']}; confirmados ${metrics['confirmados_final']}; preinscritos ${metrics['preinscritos_final']}.');
    });

    limits.addAll([
      'No hay Windows: es el motor de widget tests de Flutter con SQLite en memoria, ventana simulada (dpr 1) y MemoryFileSaver/MemoryFilePick; no se probaron diálogos nativos de «Guardar como…», impresión real, DPI real ni rendimiento de un equipo real.',
      'Drift se cuelga si se escribe desde la prueba mientras una pantalla observa hospedajes/equipos: por eso las marcas de comida «por repositorio» se escribieron con la app apagada (como cerrarla y volver a abrirla) y la pantalla se reabrió después.',
      'El tiempo del reloj de pruebas no avanza solo (hay que usar runAsync); los tiempos medidos no son rendimiento real.',
    ]);
    writeReport(steps, defects, metrics, limits, exported, started, true);
    // ignore: avoid_print
    print(
        'QA-FIN pasos=${steps.length} fallan=${steps.where((s) => s.failed).length} defectos=${defects.length}');
  });
}

/// Pequeño envoltorio para no importar repos_b en todas partes.
class SocialRepoProxy {
  SocialRepoProxy(this.db) : _r = SocialRepo(db);
  final AppDatabase db;
  final SocialRepo _r;
  Future<Map<String, String>> spouseMap(String ev) => _r.spouseMap(ev);
}

void writeReport(
    List<StepRec> steps,
    List<Defect> defects,
    Map<String, Object> metrics,
    List<String> limits,
    List<(String, int, String)> files,
    DateTime started,
    bool done) {
  final b = StringBuffer();
  b.writeln('# Informe de QA — Mi Evento en Windows (simulado)\n');
  b.writeln(
      'Estado: ${done ? 'COMPLETO' : 'PARCIAL (en curso)'} · inicio ${started.toIso8601String()} · duración ${DateTime.now().difference(started).inMinutes} min\n');
  b.writeln('## Pasos\n');
  b.writeln('| Paso | Resultado | Evidencia |');
  b.writeln('|---|---|---|');
  for (final s in steps) {
    final ev = s.ev
        .where((e) =>
            e.startsWith('FALLA') || e.startsWith('EXC') || e.startsWith('Exc'))
        .toList();
    final oks = s.ev.where((e) => e.startsWith('OK')).length;
    final res = s.failed ? 'Falla' : 'Pasa';
    final text = ev.isNotEmpty
        ? ev.map((e) => e.replaceAll('|', '/')).join('<br>')
        : '$oks comprobaciones OK';
    b.writeln('| ${s.id} · ${s.title} | $res | $text |');
  }
  b.writeln('\n## Detalle por paso\n');
  for (final s in steps) {
    b.writeln(
        '### ${s.id} · ${s.title} — ${s.failed ? 'FALLA' : 'PASA'} (${s.took.inSeconds}s)\n');
    for (final e in s.ev) {
      b.writeln('- ${e.replaceAll('\n', ' ')}');
    }
    b.writeln();
  }
  b.writeln('## Cifras\n');
  metrics.forEach((k, v) => b.writeln('- **$k**: $v'));
  b.writeln('\n## Defectos\n');
  if (defects.isEmpty) b.writeln('(ninguno registrado automáticamente)');
  for (final d in defects) {
    b.writeln(
        '- **${d.id}** (${d.sev}, paso ${d.step}) ${d.title}\n  - ${d.detail}');
  }
  b.writeln('\n## Archivos exportados\n');
  b.writeln('| Archivo | Bytes | Origen |');
  b.writeln('|---|---:|---|');
  for (final f in files) {
    b.writeln('| ${f.$1} | ${f.$2} | ${f.$3} |');
  }
  b.writeln('\n## Limitaciones\n');
  for (final l in limits) {
    b.writeln('- $l');
  }
  File('$exportDir/INFORME-auto.md').writeAsStringSync(b.toString());
}
