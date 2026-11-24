import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/repos_b.dart';
import 'package:mi_evento/data/repository.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'helpers.dart';

void main() {
  group('matrimonio solo entre hombre y mujer (datos)', () {
    late AppDatabase db;
    late Repository repo;
    late SocialRepo social;
    late String ev, ch;
    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repo = Repository(db);
      social = SocialRepo(db);
      ev = await repo.createEvent(
          name: 'E', startDate: '2026-01-01', endDate: '2026-01-02');
      ch = (await repo.createChurch(name: 'B', province: 'Matanzas')).id;
    });
    tearDown(() => db.close());
    Future<AttendeeRow> p(String n, Sex s) => repo.addAttendee(
        eventId: ev,
        firstName: n,
        lastName1: 'X',
        sex: s,
        age: 30,
        churchId: ch);

    test('vincular a dos del mismo sexo se rechaza', () async {
      final a = await p('Juan', Sex.male), b = await p('Luis', Sex.male);
      await expectLater(
          social.setSpouse(a.id, b.id),
          throwsA(isA<DataException>()
              .having((e) => e.message, 'msg', contains('mismo sexo'))));
      expect((await repo.attendeeById(a.id))!.coupleId, isNull);
      final m1 = await p('Ana', Sex.female), m2 = await p('Eva', Sex.female);
      await expectLater(
          social.setSpouse(m1.id, m2.id), throwsA(isA<DataException>()));
    });

    test(
        'hombre y mujer sí; y no se puede cambiar el sexo dejando un par igual',
        () async {
      final a = await p('Juan', Sex.male), b = await p('Ana', Sex.female);
      await social.setSpouse(a.id, b.id);
      await expectLater(
          repo.updateAttendee(a.id,
              firstName: 'Juan',
              lastName1: 'X',
              sex: Sex.female,
              age: 30,
              churchId: ch),
          throwsA(isA<DataException>()));
      expect((await repo.attendeeById(a.id))!.sex, 'M');
    });
  });

  testWidgets(
      'Edad y teléfono no admiten letras; el registro siguiente empieza limpio',
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
      await LodgingRepo(c.db).save(
          eventId: ev,
          name: 'Casa Abierta',
          kind: 'private_home',
          capacity: 3,
          accepts: LodgingAccepts.any);
    });
    await login(t, 'admin', 'secreto1');
    await t.tap(find.text('Retiro'));
    await settle(t);
    await goRegister(t);
    await enter(t, 'f-nombre', 'Lucía');
    await enter(t, 'f-apellido1', 'Gómez');
    await pickSex(t, woman: true);
    await enter(t, 'f-edad', 'ab2x5!');
    expect(
        t
            .widget<EditableText>(find.descendant(
                of: find.byKey(const Key('f-edad')),
                matching: find.byType(EditableText)))
            .controller
            .text,
        '25');
    await enter(t, 'f-telefono', '+53 5 abc 123');
    expect(
        t
            .widget<EditableText>(find.descendant(
                of: find.byKey(const Key('f-telefono')),
                matching: find.byType(EditableText)))
            .controller
            .text,
        '+53 5  123');
    await enter(t, 'f-iglesia', 'Bautista');
    await settle(t);
    await tapKey(t, 'iglesia-bautista');
    await tapKey(t, 'f-hospedaje');
    await enter(t, 'f-hosp-buscar', 'zzz');
    await tapKey(t, 'f-hosp-filtro-libres');
    await tapKey(t, 'f-guardar');
    await tapKey(t, 'exito-otra');
    await tapKey(t, 'f-hospedaje');
    expect(
        t
            .widget<EditableText>(find.descendant(
                of: find.byKey(const Key('f-hosp-buscar')),
                matching: find.byType(EditableText)))
            .controller
            .text,
        isEmpty);
    expect(
        t
            .widget<FilterChip>(find.byKey(const Key('f-hosp-filtro-libres')))
            .selected,
        isFalse);
    // Los grupos ya no se ofrecen en el registro.
    expect(find.byKey(const Key('social-grupos')), findsNothing);
  });
}
