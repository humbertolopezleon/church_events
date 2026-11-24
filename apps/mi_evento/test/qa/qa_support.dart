// Utilidades compartidas por las pruebas de QA (no es una prueba por sí misma).
//
// Genera personas ficticias con semilla fija (siempre las mismas) e imita lo que hace el
// formulario de inscripción al guardar: alta + cónyuge + grupos + equipo automático.
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/repos_b.dart';
import 'package:mi_evento/data/repository.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

/// Iglesias ficticias (nombre, provincia, municipio).
const qaChurches = <(String, String, String)>[
  ('Bautista Ebenezer', 'Matanzas', 'Cárdenas'),
  ('Metodista de Colón', 'Matanzas', 'Colón'),
  ('Pentecostal Monte Sión', 'Matanzas', 'Matanzas'),
  ('Iglesia del Nazareno Peñas Altas', 'La Habana', 'Playa'),
  ('Bautista Getsemaní', 'Matanzas', 'Jovellanos'),
  ('Asambleas de Dios Betel', 'Mayabeque', 'San José'),
  ('Presbiteriana La Trinidad', 'Matanzas', 'Perico'),
  ('Iglesia Evangélica Luz del Mundo', 'Villa Clara', 'Santa Clara'),
  ('Bautista Nuevo Pacto', 'Cienfuegos', 'Cienfuegos'),
];

const _hombres = [
  'José', 'Jesús', 'Ángel', 'Yoandry', 'Dayron', 'Raúl', 'Iván', 'Nicolás',
  'Joaquín', 'Andrés', 'Rubén', 'Osvaldo', 'Yunier', 'Orestes', 'Julián',
  'Mario', 'Elier', 'Yosvany', 'Héctor', 'Sandro', 'Ezequiel', 'Abel', //
];
const _mujeres = [
  'María',
  'Yaneisy',
  'Dayanis',
  'Lázara',
  'Niurka',
  'Rosa',
  'Mireya',
  'Yamilé',
  'Ana Lucía',
  'Beatriz',
  'Begoña',
  'Inés',
  'Yudith',
  'Sarahí',
  'Lourdes',
  'Magdalena',
  'Esther',
  'Rebeca',
  'Noemí',
  'Ángela',
  'Ñuri',
  'Débora',
];
const _apellidos = [
  'Peña',
  'Núñez',
  'Rodríguez',
  'Pérez',
  'García',
  'Muñoz',
  'Hernández',
  'Sánchez',
  'Cabrera',
  'Álvarez',
  'Fernández',
  'Ibáñez',
  'Domínguez',
  'Quiñones',
  'Ochoa',
  "O'Farrill",
  'Acosta',
  'Leyva',
  'Piñeiro',
  'Báez',
  'Valdés',
  'Echevarría',
  'Pedroso',
];

/// Una persona ficticia lista para inscribir.
class QaPerson {
  QaPerson({
    required this.first,
    required this.last1,
    required this.last2,
    required this.sex,
    required this.age,
    required this.churchIdx,
    required this.needsLodging,
    this.phone,
    this.notes = '',
    this.spouseIdx,
    this.groups = const {},
  });
  final String first, last1, last2, notes;
  final Sex sex;
  final int age, churchIdx;
  final bool needsLodging;
  final String? phone;

  /// Índice (en la lista) del cónyuge que ya estaba inscrito cuando esta persona llega.
  int? spouseIdx;
  Set<String> groups;
  String get fullName => '$first $last1 $last2'.trim();
}

/// Nombres de los grupos ficticios (hasta 5).
const qaGroupNames = [
  'Jóvenes Ebenezer',
  'Familia Núñez',
  'Coro de Colón',
  'Misioneros de Jovellanos',
  'Alabanza Betel',
];

/// [n] personas con semilla fija: ~[couples] matrimonios (casi todos se inscriben seguidos; los
/// 3 últimos con la esposa llegando 10 puestos después), hombres y mujeres mezclados,
/// edades 12–70, nombres con tildes y ñ, ~70 % necesita hospedaje.
List<QaPerson> qaPeople(int n, {int seed = 2026, int couples = 15}) {
  final rng = Random(seed);
  final usedKeys = <String>{};

  (String, String, String) uniqueName(Sex sex) {
    for (var tries = 0; tries < 5000; tries++) {
      final firsts = sex == Sex.male ? _hombres : _mujeres;
      final f = firsts[rng.nextInt(firsts.length)];
      final l2 = _apellidos[rng.nextInt(_apellidos.length)];
      final base = _apellidos[rng.nextInt(_apellidos.length)];
      // Con muchas personas se acaban las combinaciones: se usan apellidos compuestos.
      final l1 = tries < 100 ? base : '$base-$l2';
      if (usedKeys.add(dedupeKey(f, l1))) return (f, l1, l2);
    }
    throw StateError('sin nombres únicos');
  }

  int anyAge() {
    final r = rng.nextInt(100);
    if (r < 40) return 12 + rng.nextInt(14); // 12–25
    if (r < 75) return 26 + rng.nextInt(20); // 26–45
    return 46 + rng.nextInt(25); // 46–70
  }

  final units = <String>[
    for (var i = 0; i < n - couples * 2; i++) 'S',
    for (var i = 0; i < couples; i++) 'C',
  ]..shuffle(rng);

  final seq = <QaPerson>[];
  final husbandOf = <QaPerson, QaPerson>{}; // esposa → esposo
  final late = <QaPerson>[]; // esposas que llegan 10 puestos después
  var coupleNo = 0;
  for (final u in units) {
    if (u == 'S') {
      final sex = rng.nextBool() ? Sex.male : Sex.female;
      final (f, l1, l2) = uniqueName(sex);
      final church = rng.nextInt(qaChurches.length);
      seq.add(QaPerson(
        first: f,
        last1: l1,
        last2: l2,
        sex: sex,
        age: anyAge(),
        churchIdx: church,
        needsLodging: church > 1 && rng.nextInt(100) < 85,
        phone: rng.nextInt(3) == 0
            ? '5 ${100 + rng.nextInt(900)} ${1000 + rng.nextInt(9000)}'
            : null,
        notes: rng.nextInt(15) == 0 ? 'Diabético, sin azúcar' : '',
      ));
    } else {
      final (hf, hl1, hl2) = uniqueName(Sex.male);
      var mf = _mujeres[rng.nextInt(_mujeres.length)];
      for (var k = 0; !usedKeys.add(dedupeKey(mf, hl1)); k++) {
        mf = k < 100
            ? _mujeres[rng.nextInt(_mujeres.length)]
            : '${_mujeres[rng.nextInt(_mujeres.length)]} ${_mujeres[rng.nextInt(_mujeres.length)]}';
      }
      final church = 2 + rng.nextInt(qaChurches.length - 2);
      final ageH = 28 + rng.nextInt(38); // 28–65
      final husband = QaPerson(
          first: hf,
          last1: hl1,
          last2: hl2,
          sex: Sex.male,
          age: ageH,
          churchIdx: church,
          needsLodging: true);
      final wife = QaPerson(
          first: mf,
          last1: hl1,
          last2: _apellidos[rng.nextInt(_apellidos.length)],
          sex: Sex.female,
          age: (ageH - 4 + rng.nextInt(9)).clamp(20, 70),
          churchIdx: church,
          needsLodging: true);
      husbandOf[wife] = husband;
      seq.add(husband);
      if (couples - coupleNo <= 3) {
        late.add(wife);
      } else {
        seq.add(wife);
      }
      coupleNo++;
    }
  }
  for (final wife in late) {
    final at = seq.indexOf(husbandOf[wife]!);
    seq.insert((at + 10).clamp(at + 1, seq.length), wife);
  }
  for (final e in husbandOf.entries) {
    e.key.spouseIdx = seq.indexOf(e.value);
  }
  // Grupos: cada grupo reúne a hasta 5 personas de una misma iglesia (sin matrimonios).
  final inCouple = {...husbandOf.keys, ...husbandOf.values};
  for (var g = 0; g < qaGroupNames.length; g++) {
    var taken = 0;
    for (final p in seq) {
      if (taken < 5 && p.churchIdx == 2 + g && !inCouple.contains(p)) {
        p.groups = {qaGroupNames[g]};
        taken++;
      }
    }
  }
  return seq;
}

/// Un evento ya configurado, con todo lo que necesita el formulario.
class QaEvent {
  QaEvent(this.db, this.eventId, this.churchIds, this.groupIds, this.teamIds);
  final AppDatabase db;
  final String eventId;
  final List<String> churchIds;
  final Map<String, String> groupIds;
  final List<String> teamIds;
  late final Repository repo = Repository(db);
  late final TeamRepo teams = TeamRepo(db);
  late final LodgingRepo lodgings = LodgingRepo(db);
  late final SocialRepo social = SocialRepo(db);

  /// Ids de las personas inscritas, en el orden de inscripción.
  final List<String> ids = [];

  /// Equipos del evento (consulta directa, sin streams).
  Future<List<TeamRow>> teamRows() => (db.select(db.teams)
        ..where((t) => t.eventId.equals(eventId) & t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
      .get();

  /// Hospedajes con su ocupación (consulta directa, sin streams).
  Future<List<LodgingView>> lodgingViews() async {
    final lods = await (db.select(db.lodgings)
          ..where((l) => l.eventId.equals(eventId) & l.deletedAt.isNull())
          ..orderBy([(l) => OrderingTerm.asc(l.name)]))
        .get();
    final all = await people();
    return [
      for (final l in lods)
        LodgingView(l, all.where((a) => a.lodgingId == l.id).length)
    ];
  }

  Future<List<AttendeeRow>> people() => (db.select(db.attendees)
        ..where((a) => a.eventId.equals(eventId) & a.deletedAt.isNull()))
      .get();
}

AppDatabase qaDb() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

/// Crea el evento con iglesias, grupos y [teams] equipos. Todo con los repositorios reales.
Future<QaEvent> qaEvent(AppDatabase db,
    {String name = 'Congreso QA 2026',
    int teams = 6,
    bool offersLodging = true,
    bool offersTeams = true,
    List<String> groups = qaGroupNames}) async {
  final repo = Repository(db);
  final ev = await repo.createEvent(
      name: name,
      startDate: '2026-12-11',
      endDate: '2026-12-13',
      venue: 'Templo central',
      organizer: 'Convención',
      offersLodging: offersLodging,
      offersTeams: offersTeams);
  final churchIds = <String>[];
  for (final (n, p, m) in qaChurches) {
    final existing = await (db.select(db.churches)
          ..where((c) => c.nameNormalized.equals(normalizeText(n))))
        .getSingleOrNull();
    churchIds.add(existing?.id ??
        (await repo.createChurch(name: n, province: p, municipality: m)).id);
  }
  final social = SocialRepo(db);
  final groupIds = <String, String>{};
  for (final g in groups) {
    groupIds[g] = (await social.createGroup(ev, g, reason: 'church')).id;
  }
  final teamIds = <String>[];
  if (offersTeams && teams > 0) {
    await TeamRepo(db).createMany(ev, teams);
    teamIds.addAll((await (db.select(db.teams)
              ..where((t) => t.eventId.equals(ev))
              ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
            .get())
        .map((t) => t.id));
  }
  return QaEvent(db, ev, churchIds, groupIds, teamIds);
}

/// Imita el guardado del formulario: alta, cónyuge, grupos y equipo automático (en una
/// transacción, como la pantalla). El hospedaje se asigna aparte.
Future<AttendeeRow> qaInscribe(QaEvent q, QaPerson p) async {
  late AttendeeRow row;
  await q.db.transaction(() async {
    row = await q.repo.addAttendee(
        eventId: q.eventId,
        firstName: p.first,
        lastName1: p.last1,
        lastName2: p.last2,
        sex: p.sex,
        age: p.age,
        churchId: q.churchIds[p.churchIdx],
        phone: p.phone,
        province: qaChurches[p.churchIdx].$2,
        municipality: qaChurches[p.churchIdx].$3,
        needsLodging: p.needsLodging,
        notes: p.notes);
    await q.social
        .setSpouse(row.id, p.spouseIdx == null ? null : q.ids[p.spouseIdx!]);
    await q.social.setGroups(row.id, {
      for (final g in p.groups) q.groupIds[g]!,
    });
    await q.teams.autoAssign(row.id);
  });
  q.ids.add(row.id);
  return row;
}

/// Inscribe a todas las personas EN ORDEN (como en un evento real).
Future<void> qaInscribeAll(QaEvent q, List<QaPerson> people) async {
  for (final p in people) {
    await qaInscribe(q, p);
  }
}

/// Hospedajes realistas: albergues y casas, solo hombres, solo mujeres y matrimonios.
/// Devuelve los ids creados. [scale] 1.0 = holgado para 120 personas (~84 necesitan hospedaje).
Future<List<String>> qaLodgings(QaEvent q, {double scale = 1.0}) async {
  final defs = <(String, String, int, LodgingAccepts, String?)>[
    ('Albergue Central (hombres)', 'shelter', 24, LodgingAccepts.men, null),
    ('Albergue Juvenil (mujeres)', 'shelter', 24, LodgingAccepts.women, null),
    (
      'Casa del Hno. Ramón',
      'private_home',
      6,
      LodgingAccepts.men,
      'Ramón Cruz'
    ),
    (
      'Casa de la Hna. Teresa',
      'private_home',
      5,
      LodgingAccepts.women,
      'Teresa Gil'
    ),
    (
      'Casa de la Hna. Carmen',
      'private_home',
      6,
      LodgingAccepts.women,
      'Carmen Soto'
    ),
    (
      'Casa Familia Gómez',
      'private_home',
      8,
      LodgingAccepts.couples,
      'Pedro Gómez'
    ),
    (
      'Casa Familia Ortiz',
      'private_home',
      8,
      LodgingAccepts.couples,
      'Luis Ortiz'
    ),
    (
      'Casa Familia Ñáñez',
      'private_home',
      10,
      LodgingAccepts.couples,
      'Rolando Ñáñez'
    ),
    (
      'Casa Familia Rivas',
      'private_home',
      10,
      LodgingAccepts.couples,
      'Julio Rivas'
    ),
    (
      'Albergue de la Escuela (hombres)',
      'shelter',
      12,
      LodgingAccepts.men,
      null
    ),
    (
      'Casa del Hno. Osvaldo',
      'private_home',
      4,
      LodgingAccepts.men,
      'Osvaldo Diaz'
    ),
  ];
  final ids = <String>[];
  for (final (n, k, c, a, host) in defs) {
    final cap = (c * scale).round().clamp(1, 500);
    ids.add((await q.lodgings.save(
            eventId: q.eventId,
            name: n,
            kind: k,
            capacity: cap,
            accepts: a,
            hostName: host,
            contactPhone: host == null ? null : '5 555 0000',
            distanceNote:
                k == 'shelter' ? 'A 5 minutos del templo' : '10 cuadras'))
        .id);
  }
  return ids;
}

/// Hace lo mismo que «Sugerir hospedaje» con todos los pendientes y acepta la primera propuesta.
/// Devuelve la propuesta aceptada.
Future<LodgingProposal?> qaSuggestAndAccept(QaEvent q,
    {bool keepTogether = true}) async {
  final all = await q.people();
  final sp = await q.social.spouseMap(q.eventId);
  final pending = all
      .where((p) => p.needsLodging && p.lodgingId == null)
      .toList()
    ..sort((a, b) => a.regNumber.compareTo(b.regNumber));
  if (pending.isEmpty) return null;
  final refs = [for (final p in pending) p.toPersonRef(sp[p.id])];
  final lods = await q.lodgingViews();
  final candidates = [
    for (final l in lods)
      LodgingCandidate(
        id: l.row.id,
        name: l.row.name,
        accepts: lodgingAcceptsFromDb(l.row.accepts),
        capacity: l.row.capacity,
        occupied: l.occupied,
        kind: l.row.kind == 'shelter'
            ? LodgingKindRef.shelter
            : LodgingKindRef.privateHome,
        occupantChurchIds: {
          for (final p in all)
            if (p.lodgingId == l.row.id && p.churchId != null) p.churchId!
        },
        distanceNote: l.row.distanceNote,
      )
  ];
  final proposals = suggestLodging(refs, candidates,
      options: SuggestOptions(keepTogether: keepTogether));
  if (proposals.isEmpty) return null;
  final best = proposals.first;
  for (final leg in best.legs) {
    await q.lodgings.assign(leg.lodgingId, leg.people.map((p) => p.id));
  }
  return best;
}

/// Cuenta de equipos con sus estadísticas actuales (usa la lógica real del núcleo).
Future<List<TeamStats>> qaTeamStats(QaEvent q) async {
  final teams = await q.teamRows();
  final people = await q.people();
  return [
    for (final t in teams)
      TeamStats.of(t.id, t.name,
          people.where((p) => p.teamId == t.id).map((p) => p.toCore()))
  ];
}

/// Texto corto de las estadísticas de equipos para los informes.
String qaTeamSummary(List<TeamStats> s) => s
    .map((t) =>
        '${t.teamName}: ${t.size} (H${t.men}/M${t.women}, edad media ${t.avgAge.toStringAsFixed(1)})')
    .join(' | ');

/// Escribe una métrica para el informe (se ve en la salida de la prueba, con el prefijo QA-METRICA).
// ignore: avoid_print
void metric(String text) => print('QA-METRICA $text');

/// Una fila lógica de una persona para comparar eventos de bases distintas (sin ids).
typedef QaFila = ({
  int numero,
  String nombre,
  String sexo,
  int edad,
  String iglesia,
  String tel,
  bool necesita,
  String hosp,
  String equipo,
  int? pareja,
  List<String> grupos,
  String obs
});

Future<List<QaFila>> qaFilas(QaEvent q) async {
  final db = q.db;
  final people = await q.people();
  people.sort((a, b) => a.regNumber.compareTo(b.regNumber));
  final ch = {for (final c in await db.select(db.churches).get()) c.id: c.name};
  final lo = {for (final l in await q.lodgingViews()) l.row.id: l.row.name};
  final te = {for (final t in await q.teamRows()) t.id: t.name};
  final byId = {for (final p in people) p.id: p};
  final sp = await q.social.spouseMap(q.eventId);
  final groups = {
    for (final g in await db.select(db.attendeeGroups).get()) g.id: g.name
  };
  final gm = await db.select(db.groupMembers).get();
  return [
    for (final p in people)
      (
        numero: p.regNumber,
        nombre: '${p.firstName} ${p.lastName1} ${p.lastName2}',
        sexo: p.sex,
        edad: p.age,
        iglesia: ch[p.churchId] ?? '',
        tel: p.phone ?? '',
        necesita: p.needsLodging,
        hosp: lo[p.lodgingId] ?? '',
        equipo: te[p.teamId] ?? '',
        pareja: sp[p.id] == null ? null : byId[sp[p.id]]!.regNumber,
        grupos: [
          for (final m in gm)
            if (m.attendeeId == p.id && m.deletedAt == null) groups[m.groupId]!
        ]..sort(),
        obs: p.notes,
      )
  ];
}
