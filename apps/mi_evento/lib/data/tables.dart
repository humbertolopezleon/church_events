import 'package:drift/drift.dart';

/// Columnas comunes a TODAS las tablas (plan, sección 2): id UUID v7, marcas de tiempo,
/// borrado lógico y dispositivo de origen. Permiten fusionar datos entre dispositivos.
mixin BaseColumns on Table {
  TextColumn get id => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get originDeviceId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class Events extends Table with BaseColumns {
  TextColumn get name => text()();
  TextColumn get startDate => text()(); // AAAA-MM-DD
  TextColumn get endDate => text()();
  TextColumn get venue => text().withDefault(const Constant(''))();
  TextColumn get organizer => text().withDefault(const Constant(''))();
  BoolColumn get offersLodging => boolean().withDefault(const Constant(true))();
  BoolColumn get offersTeams => boolean().withDefault(const Constant(true))();
  // Falso mientras el evento se está configurando (hospedajes, equipos, criterios); luego se
  // abren las inscripciones. Los eventos anteriores a esta opción ya están configurados.
  BoolColumn get setupDone => boolean().withDefault(const Constant(true))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  // Topes de la estrategia C (diferencias máximas entre equipos), editables por evento.
  IntColumn get maxSizeDiff => integer().withDefault(const Constant(2))();
  IntColumn get maxSexDiff => integer().withDefault(const Constant(4))();
  RealColumn get maxAgeDiff => real().withDefault(const Constant(3.0))();
}

/// Catálogo reutilizable entre eventos.
@DataClassName('ChurchRow')
class Churches extends Table with BaseColumns {
  TextColumn get name => text()();
  TextColumn get nameNormalized => text()();
  TextColumn get province => text().withDefault(const Constant(''))();
  TextColumn get municipality => text().withDefault(const Constant(''))();
  TextColumn get denomination => text().nullable()();
  // Comunidad (barrio/localidad) dentro del municipio; se sugiere a partir de otras iglesias.
  TextColumn get community => text().withDefault(const Constant(''))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {nameNormalized, province, municipality}
      ];
}

@DataClassName('AgeRangeRow')
class AgeRanges extends Table with BaseColumns {
  TextColumn get eventId => text().references(Events, #id)();
  TextColumn get label => text()();
  IntColumn get minAge => integer()();
  IntColumn get maxAge => integer().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

@DataClassName('AttendeeRow')
class Attendees extends Table with BaseColumns {
  TextColumn get eventId => text().references(Events, #id)();
  IntColumn get regNumber => integer()();
  TextColumn get firstName => text()();
  TextColumn get lastName1 => text()();
  TextColumn get lastName2 => text().withDefault(const Constant(''))();
  TextColumn get sex => text()(); // 'M' hombre · 'F' mujer
  IntColumn get age => integer()();
  TextColumn get churchId => text().nullable().references(Churches, #id)();
  TextColumn get phone => text().nullable()();
  TextColumn get province => text().withDefault(const Constant(''))();
  TextColumn get municipality => text().withDefault(const Constant(''))();
  BoolColumn get needsLodging => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get coupleId => text().nullable()();
  TextColumn get teamId => text().nullable()();
  TextColumn get lodgingId => text().nullable()();
  TextColumn get dedupeKey => text()();
  TextColumn get createdBy =>
      text().nullable()(); // id del usuario que lo registró
  // 'preregistered' (preinscrito) | 'confirmed' (asistencia confirmada). Los anteriores: confirmed.
  TextColumn get status => text().withDefault(const Constant('confirmed'))();
  DateTimeColumn get confirmedAt => dateTime().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {eventId, regNumber}
      ];
}

class Couples extends Table with BaseColumns {
  TextColumn get eventId => text().references(Events, #id)();
  TextColumn get attendeeAId => text().references(Attendees, #id)();
  TextColumn get attendeeBId => text().references(Attendees, #id)();
}

class AttendeeGroups extends Table with BaseColumns {
  TextColumn get eventId => text().references(Events, #id)();
  TextColumn get name => text()();
  TextColumn get reason => text().withDefault(const Constant('preference'))();
  BoolColumn get keepTogether => boolean().withDefault(const Constant(true))();
}

class GroupMembers extends Table with BaseColumns {
  TextColumn get groupId => text().references(AttendeeGroups, #id)();
  TextColumn get attendeeId => text().references(Attendees, #id)();
}

@DataClassName('LodgingRow')
class Lodgings extends Table with BaseColumns {
  TextColumn get eventId => text().references(Events, #id)();
  TextColumn get name => text()();
  TextColumn get kind => text()(); // 'shelter' | 'private_home'
  TextColumn get contactPhone => text().nullable()();
  TextColumn get directions => text().withDefault(const Constant(''))();
  IntColumn get capacity => integer()();
  TextColumn get accepts => text()(); // 'men' | 'women' | 'couples' | 'any'
  TextColumn get hostName => text().nullable()();
  TextColumn get distanceNote => text().withDefault(const Constant(''))();
}

@DataClassName('TeamRow')
class Teams extends Table with BaseColumns {
  TextColumn get eventId => text().references(Events, #id)();
  TextColumn get name => text()();
  TextColumn get color => text().nullable()();
  TextColumn get captainId => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

class ControlTypes extends Table with BaseColumns {
  TextColumn get eventId => text().references(Events, #id)();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

class ControlSessions extends Table with BaseColumns {
  TextColumn get eventId => text().references(Events, #id)();
  TextColumn get controlTypeId => text().references(ControlTypes, #id)();
  TextColumn get name => text()();
  DateTimeColumn get scheduledAt => dateTime().nullable()();
  DateTimeColumn get openedAt => dateTime().nullable()();
  DateTimeColumn get closedAt => dateTime().nullable()();
  TextColumn get operatorName => text().withDefault(const Constant(''))();

  /// Veces que se avisó «ya pasó» y no se marcó de nuevo (para el resumen de cierre).
  IntColumn get blockedRepeats => integer().withDefault(const Constant(0))();
}

class ControlRecords extends Table with BaseColumns {
  TextColumn get sessionId => text().references(ControlSessions, #id)();
  TextColumn get attendeeId => text().references(Attendees, #id)();
  DateTimeColumn get markedAt => dateTime()();
  TextColumn get operatorName => text().withDefault(const Constant(''))();
  DateTimeColumn get undoneAt => dateTime().nullable()();
  BoolColumn get repeatOverride =>
      boolean().withDefault(const Constant(false))();
}

/// Usuarios locales de la app. Roles: 'admin' (todo) y 'operator' (registrar y controlar;
/// no administra usuarios ni borra datos). Solo se guarda el hash de la contraseña.
class AppUsers extends Table with BaseColumns {
  TextColumn get username => text().unique()(); // normalizado (minúsculas)
  TextColumn get displayName => text()();
  TextColumn get role => text()(); // 'admin' | 'operator'
  TextColumn get passwordHash => text()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  IntColumn get failedAttempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get lockedUntil => dateTime().nullable()();
  DateTimeColumn get lastLoginAt => dateTime().nullable()();
  // Contraseña temporal (p. ej. usuario importado): debe cambiarla al entrar.
  BoolColumn get mustChangePassword =>
      boolean().withDefault(const Constant(false))();
}

/// Metadatos de la instalación (una sola fila).
class AppMeta extends Table {
  IntColumn get key => integer()();
  TextColumn get deviceId => text()();
  TextColumn get deviceLabel => text().withDefault(const Constant(''))();
  IntColumn get schemaVersion => integer()();
  DateTimeColumn get lastBackupAt => dateTime().nullable()();

  /// Cuándo se pulsó «Recordar más tarde» en el aviso de contraseña inicial (se oculta ese día).
  DateTimeColumn get passwordReminderHiddenAt => dateTime().nullable()();

  /// Hash del código de recuperación del administrador (un solo uso).
  TextColumn get recoveryHash => text().nullable()();

  @override
  Set<Column> get primaryKey => {key};
}
