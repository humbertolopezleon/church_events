import 'package:drift/drift.dart' show Variable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'auth/auth_service.dart';
import 'data/attendee_exchange.dart';
import 'data/database.dart';
import 'backup/backup_service.dart';
import 'backup/file_picker.dart';
import 'data/meal_repo.dart';
import 'export/file_saver.dart';
import 'data/repos_b.dart';
import 'data/repository.dart';

/// Se sobrescribe en `main` (base real) y en las pruebas (base en memoria).
final databaseProvider =
    Provider<AppDatabase>((ref) => throw UnimplementedError());
final repositoryProvider =
    Provider<Repository>((ref) => Repository(ref.watch(databaseProvider)));

/// Evento abierto actualmente (id), o null si se está en «Mis eventos».
final currentEventIdProvider = StateProvider<String?>((ref) => null);

final authServiceProvider =
    Provider<AuthService>((ref) => AuthService(ref.watch(databaseProvider)));

/// Usuario con sesión iniciada (null = pantalla de inicio de sesión).
final currentUserProvider = StateProvider<AppUser?>((ref) => null);

/// Pantalla activa dentro de un evento (para poder navegar desde el panel).
final currentPageProvider = StateProvider<String>((ref) => 'panel');

final churchesProvider = StreamProvider<List<ChurchRow>>(
    (ref) => ref.watch(repositoryProvider).watchChurches());

/// Todos los eventos (para elegir uno de destino).
final eventsListProvider = StreamProvider<List<Event>>(
    (ref) => ref.watch(repositoryProvider).watchEvents());

final eventProvider = StreamProvider.family<Event, String>(
    (ref, id) => ref.watch(repositoryProvider).watchEvent(id));

final attendeesProvider = StreamProvider.family<List<AttendeeView>, String>(
    (ref, eventId) => ref.watch(repositoryProvider).watchAttendees(eventId));

/// Solo los que ya confirmaron su asistencia (los preinscritos no cuentan en reportes ni comidas).
final confirmedAttendeesProvider =
    Provider.family<AsyncValue<List<AttendeeView>>, String>((ref, eventId) =>
        ref.watch(attendeesProvider(eventId)).whenData((l) => [
              for (final v in l)
                if (!v.isPreregistered) v
            ]));

final socialRepoProvider =
    Provider<SocialRepo>((ref) => SocialRepo(ref.watch(databaseProvider)));
final lodgingRepoProvider =
    Provider<LodgingRepo>((ref) => LodgingRepo(ref.watch(databaseProvider)));
final teamRepoProvider =
    Provider<TeamRepo>((ref) => TeamRepo(ref.watch(databaseProvider)));

final groupsProvider = StreamProvider.family<List<GroupView>, String>(
    (ref, eventId) => ref.watch(socialRepoProvider).watchGroups(eventId));
final lodgingsProvider = StreamProvider.family<List<LodgingView>, String>(
    (ref, eventId) => ref.watch(lodgingRepoProvider).watchLodgings(eventId));
final teamsProvider = StreamProvider.family<List<TeamRow>, String>(
    (ref, eventId) => ref.watch(teamRepoProvider).watchTeams(eventId));

/// Rangos de edad configurados del evento (para el panel de composición de equipos y reportes).
final ageRangesProvider = FutureProvider.family<List<AgeRange>, String>(
    (ref, eventId) => ref.watch(repositoryProvider).ageRanges(eventId));

final mealRepoProvider =
    Provider<MealRepo>((ref) => MealRepo(ref.watch(databaseProvider)));
final controlTypesProvider = StreamProvider.family<List<ControlType>, String>(
    (ref, eventId) => ref.watch(mealRepoProvider).watchTypes(eventId));
final sessionsProvider = StreamProvider.family<List<SessionView>, String>(
    (ref, eventId) => ref.watch(mealRepoProvider).watchSessions(eventId));
final recordsProvider = StreamProvider.family<List<ControlRecord>, String>(
    (ref, sessionId) => ref.watch(mealRepoProvider).watchRecords(sessionId));

/// Sesión de control elegida en la pantalla de comidas.
final currentSessionIdProvider = StateProvider<String?>((ref) => null);

/// Cómo se entrega un archivo exportado (compartir en Android, «Guardar como» en Windows).
final fileSaverProvider =
    Provider<FileSaver>((ref) => const PlatformFileSaver());

final backupServiceProvider = Provider<BackupService>(
    (ref) => BackupService(ref.watch(databaseProvider)));
final autoBackupProvider =
    Provider<AutoBackup>((ref) => AutoBackup(ref.watch(databaseProvider)));
final filePickProvider = Provider<FilePick>((ref) => const PlatformFilePick());

/// Datos de la instalación (incluye la fecha de la última copia).
final appMetaProvider = StreamProvider<AppMetaData>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.appMeta)..where((m) => m.key.equals(1))).watchSingle();
});

/// Cuántos hospedajes (y plazas) y equipos tiene el evento. Consulta liviana que se libera al salir
/// de la pantalla (el panel y el aviso de preparación la usan).
class SetupCounts {
  const SetupCounts(this.lodgings, this.places, this.teams);
  final int lodgings, places, teams;
}

final setupCountsProvider =
    StreamProvider.autoDispose.family<SetupCounts, String>((ref, eventId) {
  final db = ref.watch(databaseProvider);
  return db
      .customSelect(
        'SELECT '
        '(SELECT COUNT(*) FROM lodgings WHERE event_id = ?1 AND deleted_at IS NULL) AS l, '
        '(SELECT COALESCE(SUM(capacity), 0) FROM lodgings WHERE event_id = ?1 AND deleted_at IS NULL) AS p, '
        '(SELECT COUNT(*) FROM teams WHERE event_id = ?1 AND deleted_at IS NULL) AS t',
        variables: [Variable<String>(eventId)],
        readsFrom: {db.lodgings, db.teams},
      )
      .watchSingle()
      .map((r) =>
          SetupCounts(r.read<int>('l'), r.read<int>('p'), r.read<int>('t')));
});

/// ¿El administrador inicial (`admin`) sigue con su contraseña inicial? Sirve para el aviso del
/// acceso y el banner; se vuelve a consultar con `ref.invalidate` al cambiar la contraseña.
final defaultPasswordInUseProvider = FutureProvider.autoDispose<bool>(
    (ref) => ref.watch(authServiceProvider).defaultAdminUsesDefaultPassword());

final attendeeExchangeProvider = Provider<AttendeeExchange>(
    (ref) => AttendeeExchange(ref.watch(databaseProvider)));
