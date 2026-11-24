import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento/data/repos_b.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'helpers.dart';

void main() {
  testWidgets(
      'al inscribir: buscar y filtrar hospedajes por sexo y plazas; «sin preferencia» aparece en el editor',
      (t) async {
    final c = await pumpApp(t, const Size(1200, 2600));
    await t.runAsync(() async {
      final ev = await c.repo.createEvent(
          name: 'Retiro',
          startDate: '2026-12-12',
          endDate: '2026-12-14',
          offersTeams: false);
      await c.repo.createChurch(
          name: 'Bautista', province: 'Matanzas', municipality: 'Cárdenas');
      final l = LodgingRepo(c.db);
      await l.save(
          eventId: ev,
          name: 'Albergue Norte',
          kind: 'shelter',
          capacity: 5,
          accepts: LodgingAccepts.men);
      await l.save(
          eventId: ev,
          name: 'Casa de Teresa',
          kind: 'private_home',
          capacity: 2,
          accepts: LodgingAccepts.women,
          hostName: 'Teresa');
      await l.save(
          eventId: ev,
          name: 'Casa Abierta',
          kind: 'private_home',
          capacity: 3,
          accepts: LodgingAccepts.any);
    });
    await login(t, 'admin', 'secreto1');
    await t.tap(find.text('Retiro'));
    await settle(t);
    await t.tap(find.text('Registrar').first);
    await settle(t);
    await enter(t, 'f-nombre', 'Lucía');
    await enter(t, 'f-apellido1', 'Gómez');
    await pickSex(t, woman: true);
    await enter(t, 'f-edad', '25');
    await enter(t, 'f-iglesia', 'Bautista');
    await settle(t);
    await tapKey(t, 'iglesia-bautista');
    await tapKey(t, 'f-hospedaje');

    Future<List<String>> options() async {
      await tapKey(t, 'f-hosp-sel');
      final names = [
        for (final n in ['Albergue Norte', 'Casa de Teresa', 'Casa Abierta'])
          if (find.textContaining(n).evaluate().isNotEmpty) n
      ];
      await t.tapAt(const Offset(5, 5)); // cierra el menú
      await settle(t);
      return names;
    }

    expect(await options(), hasLength(3));
    // por texto
    await enter(t, 'f-hosp-buscar', 'teresa');
    await settle(t);
    expect(await options(), ['Casa de Teresa']);
    await enter(t, 'f-hosp-buscar', '');
    await settle(t);
    // por sexo: una mujer no ve el albergue de hombres
    await tapKey(t, 'f-hosp-filtro-sexo');
    expect(
        await options(), unorderedEquals(['Casa de Teresa', 'Casa Abierta']));
    await enter(t, 'f-hosp-buscar', 'zzz');
    await settle(t);
    expect(find.byKey(const Key('f-hosp-sin-resultados')), findsOneWidget);
  });

  testWidgets('el editor de hospedaje ofrece «Sin preferencia»', (t) async {
    final c = await pumpApp(t, const Size(1200, 2000));
    await t.runAsync(() async {
      await c.repo.createEvent(
          name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
    });
    await login(t, 'admin', 'secreto1');
    await t.tap(find.text('Retiro'));
    await settle(t);
    await t.tap(find.text('Hospedajes').first);
    await settle(t);
    await tapKey(t, 'hosp-nuevo');
    expect(find.text('Sin preferencia'), findsWidgets);
  });
}
