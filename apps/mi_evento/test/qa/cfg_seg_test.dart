// QA · Configuración del evento en dos momentos, y seguridad/permisos.
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento/auth/auth_service.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/repository.dart' show DataException;
import 'package:mi_evento_core/mi_evento_core.dart';

import '../helpers.dart';
import 'qa_support.dart';
import 'qa_ui_support.dart';

void main() {
  group('configuración (interfaz)', () {
    testWidgets(
        'QA-CFG-001 · crear evento: nombre obligatorio, rango de fechas, criterios de balance confirmables, terminar con lo pendiente y volver a Configuración',
        (t) async {
      final c = await pumpApp(t, qaPc);
      await login(t, 'admin', 'secreto1');
      await t.tap(find.text('Crear evento'));
      await settle(t);
      await tapKey(t, 'ev-crear');
      expect(find.textContaining('Falta el nombre'), findsOneWidget);
      await enter(t, 'ev-nombre', '    '); // solo espacios
      await tapKey(t, 'ev-crear');
      expect(find.textContaining('Falta el nombre'), findsOneWidget);
      await enter(t, 'ev-nombre', 'Congreso de Jóvenes Ñandú 2026');
      await tapKey(t, 'ev-fechas');
      await t.tap(find.text('15').first);
      await t.pump();
      await t.tap(find.text('17').first);
      await t.pump();
      await t.tap(find.text('Aceptar'));
      await settle(t);
      expect(find.textContaining('→'), findsOneWidget);
      await tapKey(t, 'ev-crear');
      // Primer momento: solo configuración.
      expect(find.byKey(const Key('cfg-intro')), findsOneWidget);
      expect(find.text('Asistentes'), findsNothing);
      // Equipos con un criterio cambiado (edad media ±2).
      await tapKey(t, 'cfg-equipos-definir');
      await enter(t, 'eq-tope-edad', '2');
      await tapKey(t, 'eq-crear-ok');
      expect(find.textContaining('edad media ±2.0 años'), findsOneWidget);
      // Terminar con los hospedajes todavía sin definir: avisa y deja elegir.
      await tapKey(t, 'cfg-terminar');
      expect(find.textContaining('Faltan los hospedajes'), findsOneWidget);
      await tapKey(t, 'cfg-terminar-igual');
      expect(find.byKey(const Key('panel-vacio')), findsOneWidget);
      final ev =
          (await t.runAsync(() => c.db.select(c.db.events).getSingle()))!;
      expect(ev.setupDone, isTrue);
      expect(ev.maxAgeDiff, 2.0);
      expect(ev.name, 'Congreso de Jóvenes Ñandú 2026');
      expect(ev.endDate.compareTo(ev.startDate), greaterThan(0));
      // El administrador vuelve a Configuración y puede reabrir.
      await t.tap(find.text('Configuración').first);
      await settle(t);
      expect(find.byKey(const Key('cfg-volver')), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets(
        'QA-CFG-002 · un operador no configura ni inscribe mientras el evento se está configurando',
        (t) async {
      await qaOpen(t, qaPc, operator: true, setupDone: false, goTo: null);
      expect(find.textContaining('administrador está configurando'),
          findsOneWidget);
      expect(find.byKey(const Key('cfg-terminar')), findsNothing);
      expect(find.text('Asistentes'), findsNothing);
    });
  });

  group('permisos (interfaz)', () {
    testWidgets(
        'QA-SEG-001 · el operador no ve Configuración, Copias ni Usuarios, no elimina asistentes ni eventos; el administrador sí',
        (t) async {
      final a = await qaOpen(t, qaPc, operator: true, goTo: 'Asistentes',
          prepare: (q) async {
        await qaInscribe(q, qaPeople(3).first);
      });
      for (final l in ['Configuración', 'Copias de seguridad', 'Usuarios']) {
        expect(find.text(l), findsNothing, reason: 'operador ve «$l»');
      }
      for (final l in [
        'Panel',
        'Asistentes',
        'Hospedajes',
        'Equipos',
        'Comidas',
        'Reportes'
      ]) {
        expect(find.text(l), findsWidgets, reason: 'operador no ve «$l»');
      }
      await tapKey(t, 'asistente-1');
      expect(find.byKey(const Key('f-eliminar')), findsNothing);
      // Aunque lo intentara por código, el dato protege: mensaje en español.
      Future<String> intento(Future<Object?> Function() f) async {
        try {
          await f();
          return 'SIN ERROR';
        } on DataException catch (e) {
          return e.message;
        }
      }

      expect(
          await t.runAsync(() => intento(
              () => a.q.repo.deleteAttendee(a.q.ids.first, isAdmin: false))),
          contains('Solo el administrador'));
      expect(
          await t.runAsync(() => intento(() =>
              a.q.repo.deleteEventPermanently(a.q.eventId, isAdmin: false))),
          contains('Solo el administrador'));
    });

    testWidgets(
        'QA-SEG-002 · administrador inicial admin/admin: aviso en el acceso y banner fijo; al cambiar la contraseña desaparece (y una clave floja se rechaza)',
        (t) async {
      final c = await pumpApp(t, qaPc, defaultAdmin: true);
      expect(find.byKey(const Key('login-pista-inicial')), findsOneWidget);
      await login(t, 'admin', 'admin');
      expect(find.byKey(const Key('banner-clave-inicial')), findsOneWidget);
      await tapKey(t, 'banner-cambiar');
      await enter(t, 'cp-actual', 'admin');
      await enter(t, 'cp-nueva', 'abc');
      await tapKey(t, 'cp-guardar');
      expect(find.byKey(const Key('banner-clave-inicial')), findsOneWidget);
      expect(find.textContaining('6'), findsWidgets); // mensaje de largo mínimo
      await enter(t, 'cp-nueva', 'admin'); // igual al usuario
      await tapKey(t, 'cp-guardar');
      expect(find.byKey(const Key('banner-clave-inicial')), findsOneWidget);
      await enter(t, 'cp-nueva', 'una-clave-nueva-2026');
      await tapKey(t, 'cp-guardar');
      expect(find.byKey(const Key('banner-clave-inicial')), findsNothing);
      final ok =
          await t.runAsync(() => c.auth.login('admin', 'una-clave-nueva-2026'));
      expect(ok!.ok, isTrue);
      final viejo = await t.runAsync(() => c.auth.login('admin', 'admin'));
      expect(viejo!.ok, isFalse);
    });

    testWidgets(
        'QA-SEG-003 · en la pantalla de acceso, tras 5 contraseñas erróneas se bloquea con un mensaje de espera, incluso con la contraseña correcta',
        (t) async {
      await pumpApp(t, qaPc);
      for (var i = 0; i < 4; i++) {
        await login(t, 'admin', 'mala$i');
        expect(find.text('Usuario o contraseña incorrectos.'), findsOneWidget);
      }
      await login(t, 'admin', 'mala5');
      expect(
          find.textContaining('Demasiados intentos. Espera'), findsOneWidget);
      await login(t, 'admin', 'secreto1'); // la correcta, durante el bloqueo
      expect(
          find.textContaining('Demasiados intentos. Espera'), findsOneWidget);
      expect(find.byKey(const Key('login-entrar')),
          findsOneWidget); // sigue en el acceso
    });
  });

  group('seguridad (capa de datos, con ejecutor de hilos real y falso)', () {
    late AppDatabase db;
    late AuthService auth;
    setUp(() {
      db = qaDb();
      auth = AuthService(db,
          hasher: const PasswordHasher(iterations: 1000), runner: syncRunner);
    });
    tearDown(() => db.close());

    Future<AppUser> admin() async {
      await auth.createFirstAdmin(
          username: 'admin', displayName: 'Ana', password: 'secreto1');
      return (await auth.login('admin', 'secreto1')).user!;
    }

    test(
        'QA-SEG-010 · bloqueo progresivo: 30 s, 1 min, 5 min, 15 min y se mantiene en 15 min; un acierto reinicia',
        () async {
      await admin();
      final esperados = [30, 60, 300, 900, 900];
      for (var i = 0; i < 4; i++) {
        expect(
            (await auth.login('admin', 'x$i')).failure, LoginFailure.invalid);
      }
      for (final seg in esperados) {
        final r = await auth.login('admin', 'mala');
        expect(r.failure, LoginFailure.locked);
        expect(r.wait!.inSeconds, inInclusiveRange(seg - 2, seg));
        // «Pasa el tiempo»: se corre el bloqueo al pasado.
        await (db.update(db.appUsers)).write(AppUsersCompanion(
            lockedUntil: Value(
                DateTime.now().toUtc().subtract(const Duration(seconds: 1)))));
      }
      expect((await auth.login('admin', 'secreto1')).ok, isTrue);
      final u = await db.select(db.appUsers).getSingle();
      expect(u.failedAttempts, 0);
      expect(u.lockedUntil, isNull);
    });

    test(
        'QA-SEG-011 · un usuario que no existe recibe el mismo mensaje que una clave errónea (no revela cuentas)',
        () async {
      await admin();
      final a = await auth.login('nadie', 'secreto1');
      final b = await auth.login('admin', 'mala');
      expect(a.failure, LoginFailure.invalid);
      expect(b.failure, LoginFailure.invalid);
      for (var i = 0; i < 8; i++) {
        expect((await auth.login('nadie', 'x')).failure, LoginFailure.invalid,
            reason: 'un usuario inexistente nunca se bloquea');
      }
    });

    test(
        'QA-SEG-012 · inicio de sesión con el ejecutor REAL (Isolate): entra, rechaza y cambia la clave',
        () async {
      final real =
          AuthService(db, hasher: const PasswordHasher(iterations: 1000));
      await real.createFirstAdmin(
          username: 'admin', displayName: 'Ana', password: 'secreto1');
      final u = (await real.login('admin', 'secreto1')).user!;
      expect((await real.login('admin', 'otra')).ok, isFalse);
      await real.changeOwnPassword(u, 'secreto1', 'otra-clave-larga');
      expect((await real.login('admin', 'otra-clave-larga')).ok, isTrue);
    });

    test(
        'QA-SEG-013 · cambio de contraseña: exige la actual, mínimo 6, distinta del usuario; en español',
        () async {
      final u = await admin();
      Future<void> bad(String actual, String nueva, String texto) =>
          expectLater(
              auth.changeOwnPassword(u, actual, nueva),
              throwsA(isA<AuthException>()
                  .having((e) => e.message, 'm', contains(texto))));
      await bad('equivocada', 'nueva-clave-1', 'actual no es correcta');
      await bad('secreto1', '123', '6');
    });

    test(
        'QA-SEG-014 · código de recuperación: restablece, sirve una sola vez y entrega un código nuevo',
        () async {
      final code = await auth.createFirstAdmin(
          username: 'admin', displayName: 'Ana', password: 'secreto1');
      await expectLater(
          auth.recoverAdmin('AAAA-BBBB-CCCC-DDDD', 'nueva-clave-1'),
          throwsA(isA<AuthException>()
              .having((e) => e.message, 'm', contains('no es correcto'))));
      final r = await auth.recoverAdmin(
          code.toLowerCase(), 'nueva-clave-1'); // minúsculas también
      expect((await auth.login('admin', 'nueva-clave-1')).ok, isTrue);
      await expectLater(auth.recoverAdmin(code, 'otra-clave-22'),
          throwsA(isA<AuthException>()));
      expect(r.newCode, isNot(code));
    });

    test(
        'QA-SEG-015 · el operador no crea usuarios ni resetea claves; no se deja el sistema sin administrador',
        () async {
      final a = await admin();
      final op = await auth.createUser(a,
          username: 'ruth', displayName: 'Ruth', password: 'ruth123');
      await expectLater(
          auth.createUser(op,
              username: 'otro', displayName: 'X', password: 'clave123'),
          throwsA(isA<AuthException>()));
      await expectLater(auth.resetPassword(op, a.id, 'clave-nueva-1'),
          throwsA(isA<AuthException>()));
      await expectLater(
          auth.setActive(a, a.id, false), throwsA(isA<AuthException>()));
      await expectLater(
          auth.setAdmin(a, a.id, false), throwsA(isA<AuthException>()));
    });

    test('QA-SEG-016 · un usuario desactivado no entra', () async {
      final a = await admin();
      final op = await auth.createUser(a,
          username: 'ruth', displayName: 'Ruth', password: 'ruth123');
      await auth.setActive(a, op.id, false);
      expect(
          (await auth.login('ruth', 'ruth123')).failure, LoginFailure.inactive);
    });
  });

  group('criterios de balance y evento (capa de datos)', () {
    test(
        'QA-CFG-010 · los topes editados se guardan y no admiten negativos; el evento valida nombre y fechas',
        () async {
      final db = qaDb();
      addTearDown(db.close);
      final q = await qaEvent(db, teams: 3);
      await q.teams.setLimits(q.eventId,
          const BalanceLimits(maxSizeDiff: 1, maxSexDiff: 3, maxAgeDiff: 2.5));
      final ev = await (db.select(db.events)
            ..where((e) => e.id.equals(q.eventId)))
          .getSingle();
      expect((ev.maxSizeDiff, ev.maxSexDiff, ev.maxAgeDiff), (1, 3, 2.5));
      await expectLater(
          q.teams.setLimits(q.eventId, const BalanceLimits(maxSizeDiff: -1)),
          throwsA(predicate((e) => '$e'.contains('negativos'))));
      await expectLater(
          q.repo.updateEvent(q.eventId,
              name: '  ',
              startDate: '2026-12-11',
              endDate: '2026-12-12',
              offersLodging: true,
              offersTeams: true),
          throwsA(predicate((e) => '$e'.contains('Falta el nombre'))));
      await expectLater(
          q.repo.updateEvent(q.eventId,
              name: 'X',
              startDate: '2026-12-12',
              endDate: '2026-12-11',
              offersLodging: true,
              offersTeams: true),
          throwsA(predicate((e) => '$e'.contains('fecha de fin'))));
      // Un solo día es válido.
      await q.repo.updateEvent(q.eventId,
          name: 'X',
          startDate: '2026-12-12',
          endDate: '2026-12-12',
          offersLodging: false,
          offersTeams: false);
    });

    test(
        'QA-CFG-011 · eliminar un evento borra TODO lo suyo y conserva el catálogo de iglesias',
        () async {
      final db = qaDb();
      addTearDown(db.close);
      final q = await qaEvent(db, teams: 4);
      await qaInscribeAll(q, qaPeople(30));
      await qaLodgings(q);
      final n = await q.repo.deleteEventPermanently(q.eventId, isAdmin: true);
      expect(n, 30);
      expect(await db.select(db.attendees).get(), isEmpty);
      expect(await db.select(db.lodgings).get(), isEmpty);
      expect(await db.select(db.teams).get(), isEmpty);
      expect(await db.select(db.couples).get(), isEmpty);
      expect(await db.select(db.groupMembers).get(), isEmpty);
      expect(await db.select(db.events).get(), isEmpty);
      expect((await db.select(db.churches).get()).length, qaChurches.length);
    });
  });
}
