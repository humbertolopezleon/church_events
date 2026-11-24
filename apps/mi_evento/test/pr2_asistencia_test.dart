import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/meal_repo.dart';
import 'package:mi_evento/data/repository.dart';
import 'package:mi_evento/ui/widgets/highlight_text.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'helpers.dart';

void main() {
  group('resaltado', () {
    test('sin tildes ni mayúsculas, varias palabras y rangos unidos', () {
      expect(HighlightText.ranges('María José Pérez', 'maria perez'),
          [(0, 5), (11, 16)]);
      expect(HighlightText.ranges('Ángel Ñuri', 'nuri'), [(6, 10)]);
      expect(HighlightText.ranges('Ana Ana', 'an'), [(0, 2), (4, 6)]);
      expect(HighlightText.ranges('Ana', ''), isEmpty);
      expect(HighlightText.ranges('Ana', 'zzz'), isEmpty);
    });
  });

  group('desconfirmar (datos)', () {
    late AppDatabase db;
    late Repository repo;
    late String ev;
    late AttendeeRow a, b;
    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repo = Repository(db);
      ev = await repo.createEvent(
          name: 'E', startDate: '2026-01-01', endDate: '2026-01-02');
      a = await repo.addAttendee(
          eventId: ev,
          firstName: 'Ana',
          lastName1: 'X',
          sex: Sex.female,
          age: 30);
      b = await repo.addAttendee(
          eventId: ev,
          firstName: 'Beto',
          lastName1: 'Y',
          sex: Sex.male,
          age: 30);
    });
    tearDown(() => db.close());

    test('desconfirmar devuelve a preinscrito y quita confirmedAt', () async {
      expect(await repo.unconfirmAttendance([a.id]), 1);
      final r = (await repo.attendeeById(a.id))!;
      expect(r.status, 'preregistered');
      expect(r.confirmedAt, isNull);
      expect(await repo.confirmAttendance([a.id]), 1);
    });

    test('con comidas marcadas se BLOQUEA (todo o nada) y se dice cuántas',
        () async {
      final meals = MealRepo(db);
      await meals.ensureDefaultTypes(ev);
      final type = (await meals.types(ev)).first;
      final s = await meals.createSession(ev, type.id, 'Desayuno 1');
      await meals.mark(s.id, a.id, operatorName: 'x');
      await expectLater(
          repo.unconfirmAttendance([a.id, b.id]),
          throwsA(isA<DataException>().having((e) => e.message, 'msg',
              allOf(contains('Ana X'), contains('1 comida')))));
      // Todo o nada: Beto tampoco cambió.
      expect((await repo.attendeeById(b.id))!.status, 'confirmed');
      expect((await repo.attendeeById(a.id))!.status, 'confirmed');
    });
  });

  testWidgets(
      'Confirmar asistencia (escritorio): filtros, desconfirmar y resaltado',
      (t) async {
    final c = await pumpApp(t, const Size(1200, 2400));
    await t.runAsync(() async {
      final ev = await c.repo.createEvent(
          name: 'Retiro', startDate: '2026-12-12', endDate: '2026-12-14');
      for (final (n, s, pre) in [
        ('Lidia', Sex.female, true),
        ('Mario', Sex.male, true),
        ('Rosa', Sex.female, false),
      ]) {
        await c.repo.addAttendee(
            eventId: ev,
            firstName: n,
            lastName1: 'Prueba',
            sex: s,
            age: 30,
            preregistered: pre);
      }
    });
    await login(t, 'admin', 'secreto1');
    await t.tap(find.text('Retiro'));
    await settle(t);
    await t.tap(find.text('Confirmar asistencia').first);
    await settle(t);
    expect(find.text('2 por confirmar · 1 ya confirmados'), findsOneWidget);
    expect(find.text('Lidia Prueba'), findsOneWidget);
    expect(find.text('Rosa Prueba'),
        findsNothing); // por defecto solo por confirmar

    // Mostrar confirmados y desconfirmar a Rosa (nº 3).
    await tapKey(t, 'ca-filtro-estado');
    await t.tap(find.text('Confirmados').last);
    await settle(t);
    expect(find.text('Rosa Prueba'), findsOneWidget);
    await tapKey(t, 'ca-desconfirmar-3');
    await tapKey(t, 'ca-desconfirmar-ok');
    expect(find.text('3 por confirmar · 0 ya confirmados'), findsOneWidget);

    // Vuelve a «por confirmar» (opción «Todos» del desplegable).
    await tapKey(t, 'ca-filtro-estado');
    await t.tap(find.text('Todos').last);
    await settle(t);

    // Búsqueda: resalta la coincidencia (texto con rango resaltado).
    await t.enterText(find.byKey(const Key('ca-buscar')), 'lid');
    await settle(t);
    var marked = false;
    expect(
        find.byWidgetPredicate(
            (w) => w is RichText && w.text.toPlainText() == 'Lidia Prueba'),
        findsOneWidget);
    t
        .widget<RichText>(find.byWidgetPredicate(
            (w) => w is RichText && w.text.toPlainText() == 'Lidia Prueba'))
        .text
        .visitChildren((s) {
      if (s is TextSpan &&
          s.text == 'Lid' &&
          s.style?.backgroundColor != null) {
        marked = true;
      }
      return true;
    });
    expect(marked, isTrue, reason: 'la coincidencia «Lid» va resaltada');
  });
}
