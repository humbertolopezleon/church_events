import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/repository.dart';

import 'helpers.dart';

void main() {
  test(
      'createChurch guarda la comunidad y exige provincia y municipio al registrar a mano',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = Repository(db);
    final c = await repo.createChurch(
        name: 'Bautista',
        province: 'Matanzas',
        municipality: 'Cárdenas',
        community: '  Varadero   Norte ',
        requireLocation: true);
    expect(c.community, 'Varadero Norte');
    expect(
        () => repo.createChurch(
            name: 'X', municipality: 'Y', requireLocation: true),
        throwsA(isA<DataException>()));
    expect(
        () => repo.createChurch(
            name: 'X', province: 'Matanzas', requireLocation: true),
        throwsA(isA<DataException>()));
    // sin requireLocation (importaciones) sigue siendo opcional
    expect((await repo.createChurch(name: 'Importada')).province, '');
  });

  test('communitiesOf sugiere por municipio, sin repetir y sin tildes',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = Repository(db);
    for (final (n, m, c) in [
      ('A', 'Cárdenas', 'Varadero'),
      ('B', 'Cárdenas', 'varadero'),
      ('C', 'Cárdenas', 'Santa Marta'),
      ('D', 'Colón', 'Otra'),
    ]) {
      await repo.createChurch(
          name: n, province: 'Matanzas', municipality: m, community: c);
    }
    final all = await repo.watchChurches().first;
    expect(communitiesOf(all, 'Matanzas', 'cardenas'),
        ['Santa Marta', 'Varadero']);
    expect(communitiesOf(all, 'Matanzas', 'Colón'), ['Otra']);
    expect(communitiesOf(all, 'La Habana', 'Cárdenas'), isEmpty);
  });

  testWidgets(
      'diálogo de iglesia: los municipios dependen de la provincia y la comunidad nueva queda para la próxima',
      (t) async {
    final c = await pumpApp(t, const Size(1200, 2400));
    await t.runAsync(() async {
      await c.repo.createEvent(
          name: 'Retiro',
          startDate: '2026-12-12',
          endDate: '2026-12-14',
          offersTeams: false,
          offersLodging: false);
    });
    await login(t, 'admin', 'secreto1');
    await t.tap(find.text('Retiro'));
    await settle(t);
    await t.tap(find.text('Registrar').first);
    await settle(t);

    Future<void> openDialog(String name) async {
      await enter(t, 'f-iglesia', name);
      await settle(t);
      await tapKey(t, 'iglesia-nueva');
    }

    await openDialog('Primera');
    // sin provincia, el municipio está bloqueado
    expect(find.text('Elige primero la provincia'), findsOneWidget);
    await t.tap(find.byKey(const Key('ni-provincia')));
    await settle(t);
    await t.tap(find.text('Matanzas').last);
    await settle(t);
    await t.tap(find.byType(DropdownButtonFormField<String>).at(1));
    await settle(t);
    expect(find.text('Cárdenas'), findsOneWidget); // municipio de Matanzas
    expect(find.text('Cumanayagua'), findsNothing); // es de Cienfuegos
    await t.tap(find.text('Cárdenas').last);
    await settle(t);
    // guardar sin municipio ya no es posible; con él, la comunidad es opcional y nueva
    await t.enterText(find.byKey(const Key('ni-comunidad')), 'Varadero');
    await t.pump();
    expect(find.byKey(const Key('ni-comunidad-nueva')), findsOneWidget);
    await tapKey(t, 'ni-guardar');
    var rows = (await t.runAsync(() => c.db.select(c.db.churches).get()))!;
    expect(rows.single.community, 'Varadero');
    expect(rows.single.municipality, 'Cárdenas');

    // La segunda iglesia del mismo municipio sugiere la comunidad ya añadida.
    await t.tap(find.text('Registrar').first);
    await settle(t);
    await t.tap(find.text('Registrar').first);
    await settle(t);
    await openDialog('Segunda');
    await t.tap(find.byKey(const Key('ni-provincia')));
    await settle(t);
    await t.tap(find.text('Matanzas').last);
    await settle(t);
    await pickMunicipio(t, 'Cárdenas');
    await t.tap(find.byKey(const Key('ni-comunidad')));
    await t.enterText(find.byKey(const Key('ni-comunidad')), 'Var');
    await t.pump();
    expect(find.byKey(const Key('ni-comunidad-op-Varadero')), findsOneWidget);
    await t.tap(find.byKey(const Key('ni-comunidad-op-Varadero')));
    await t.pump();
    await tapKey(t, 'ni-guardar');
    rows = (await t.runAsync(() => c.db.select(c.db.churches).get()))!;
    expect(rows, hasLength(2));
    expect(rows.every((r) => r.community == 'Varadero'), isTrue);
  });
}
