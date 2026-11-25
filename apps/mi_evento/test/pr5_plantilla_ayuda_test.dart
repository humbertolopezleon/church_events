import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento/backup/file_picker.dart';
import 'package:mi_evento/data/attendee_exchange.dart';
import 'package:mi_evento/data/church_exchange.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/lodging_exchange.dart';
import 'package:mi_evento/data/repository.dart';
import 'package:mi_evento/data/team_exchange.dart';
import 'package:mi_evento/export/file_saver.dart';
import 'package:mi_evento/providers.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'helpers.dart';

void main() {
  group('CsvSpec: columnas, ayuda y plantilla', () {
    test('las columnas de la ayuda son las de los encabezados reales', () {
      expect(attendeeCsvSpec.headers, attendeeCsvHeaders);
      expect(LodgingExchange.csvSpec.headers, LodgingExchange.headers);
      expect(TeamExchange.csvSpec.headers, TeamExchange.headers);
      expect(ChurchExchange.csvSpec.headers, ChurchExchange.headers);
    });

    test(
        'la plantilla vacía se importa sin error y sin filas (hospedajes, equipos, iglesias)',
        () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = Repository(db);
      final ev = await repo.createEvent(
          name: 'E', startDate: '2026-01-01', endDate: '2026-01-02');
      for (final (imp, spec) in [
        (LodgingExchange(db, ev), LodgingExchange.csvSpec),
        (TeamExchange(db, ev), TeamExchange.csvSpec),
        (ChurchExchange(db), ChurchExchange.csvSpec),
      ]) {
        final csv = buildCsvDelimited(spec.templateRows);
        expect(csv.split('\r\n').first, '\uFEFFsep=;', reason: spec.fileName);
        final r = await imp.preview(csv);
        expect(r.work, 0, reason: spec.fileName);
        expect(r.warnings.where((w) => w.startsWith('Faltan')), isEmpty,
            reason: spec.fileName);
      }
    });
  });

  testWidgets(
      'Plantilla CSV y Columnas del CSV en el menú ⋮ y en el estado vacío (Asistentes, Iglesias, Hospedajes, Equipos)',
      (t) async {
    final saver = MemoryFileSaver();
    final c = await pumpApp(t, const Size(1200, 2400), overrides: [
      fileSaverProvider.overrideWithValue(saver),
      filePickProvider.overrideWithValue(MemoryFilePick()),
    ]);
    await t.runAsync(() => c.repo.createEvent(
        name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14'));
    await login(t, 'admin', 'secreto1');
    await t.tap(find.text('Retiro'));
    await settle(t);

    final screens = {
      'Asistentes': ('asis', 'plantilla-asistentes.csv'),
      'Iglesias': ('ig', 'plantilla-iglesias.csv'),
      'Hospedajes': ('hosp', 'plantilla-hospedajes.csv'),
      'Equipos': ('eq', 'plantilla-equipos-personas.csv'),
    };
    for (final e in screens.entries) {
      final (p, file) = e.value;
      await t.tap(find.text(e.key).first);
      await settle(t);
      // Menú ⋮: plantilla (se guarda) y columnas (abre el diálogo).
      await tapKey(t, '$p-plantilla');
      expect(saver.saved.containsKey(file), isTrue, reason: e.key);
      await tapKey(t, '$p-columnas');
      expect(find.text('Obligatorias'), findsOneWidget, reason: e.key);
      await t.tap(find.text('Entendido'));
      await settle(t);
    }
    // Estado vacío de Hospedajes, Equipos e Iglesias: botones a la vista.
    for (final p in ['ig', 'hosp', 'eq']) {
      final name =
          {'ig': 'Iglesias', 'hosp': 'Hospedajes', 'eq': 'Equipos'}[p]!;
      await t.tap(find.text(name).first);
      await settle(t);
      expect(find.byKey(Key('$p-vacio-plantilla')), findsOneWidget,
          reason: name);
      expect(find.byKey(Key('$p-vacio-columnas')), findsOneWidget,
          reason: name);
    }
  });
}
