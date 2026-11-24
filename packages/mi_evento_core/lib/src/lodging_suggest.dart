import 'lodging_rules.dart';
import 'models.dart';

/// Tipo de hospedaje (albergue o casa particular).
enum LodgingKindRef { shelter, privateHome }

/// Hospedaje disponible para la sugerencia, con su ocupación actual.
class LodgingCandidate {
  const LodgingCandidate({
    required this.id,
    required this.name,
    required this.accepts,
    required this.capacity,
    required this.occupied,
    this.kind = LodgingKindRef.shelter,
    this.hostChurchId,
    this.occupantChurchIds = const {},
    this.distanceNote,
  });
  final String id;
  final String name;
  final LodgingAccepts accepts;
  final int capacity;
  final int occupied;
  final LodgingKindRef kind;
  final String? hostChurchId;
  final Set<String> occupantChurchIds;
  final String? distanceNote;

  /// Plazas libres (nunca negativas, aunque una edición manual lo haya sobrecargado).
  int get free => (capacity - occupied) < 0 ? 0 : capacity - occupied;
}

class SuggestOptions {
  const SuggestOptions(
      {this.keepTogether = true, this.preferHostChurch = true});

  /// «Mantener juntos si es posible». Si es falso, se reparte llenando hospedajes.
  final bool keepTogether;

  /// Preferir hospedajes de la misma iglesia (del anfitrión o de quienes ya están).
  final bool preferHostChurch;
}

/// Un tramo de la propuesta: estas personas, en este hospedaje.
class ProposalLeg {
  const ProposalLeg({
    required this.lodgingId,
    required this.lodgingName,
    required this.people,
    required this.reason,
    required this.occupiedBefore,
    required this.capacity,
  });
  final String lodgingId;
  final String lodgingName;
  final List<PersonRef> people;
  final String reason;
  final int occupiedBefore;
  final int capacity;
  int get occupiedAfter => occupiedBefore + people.length;
}

/// Una propuesta completa. NUNCA se aplica sola: el usuario decide.
class LodgingProposal {
  const LodgingProposal({
    required this.legs,
    required this.unplaced,
    required this.notes,
    required this.score,
  });
  final List<ProposalLeg> legs;

  /// Personas que no caben en ningún sitio compatible.
  final List<PersonRef> unplaced;

  /// Avisos y explicaciones en español (déficit, cónyuge sin hospedaje, etc.).
  final List<String> notes;
  final int score;

  bool get isComplete => unplaced.isEmpty && legs.isNotEmpty;
  int get placedCount => legs.fold(0, (a, l) => a + l.people.length);
}

enum _BlockKind { couples, men, women }

class _Block {
  _Block(this.kind, this.people);
  final _BlockKind kind;
  final List<PersonRef> people;
  int get size => people.length;
  String get label => switch (kind) {
        _BlockKind.couples => 'matrimonios',
        _BlockKind.men => 'hombres',
        _BlockKind.women => 'mujeres',
      };
}

class _Plan {
  _Plan(this.legs, this.unplaced, this.score);
  final List<ProposalLeg> legs;
  final List<PersonRef> unplaced;
  final int score;
  String get key => legs
      .map((l) => '${l.lodgingId}:${l.people.map((p) => p.id).join(',')}')
      .join('|');
}

/// Sugiere dónde hospedar a [target] (una persona, un matrimonio o un grupo).
///
/// Función pura y determinista (ver docs/PLAN.md §3). Devuelve de 0 a [maxProposals]
/// propuestas ordenadas de mejor a peor; lista vacía si [target] está vacío.
/// Reglas duras: capacidad, compatibilidad y matrimonios nunca separados.
List<LodgingProposal> suggestLodging(
  List<PersonRef> target,
  List<LodgingCandidate> lodgings, {
  SuggestOptions options = const SuggestOptions(),
  int maxProposals = 3,
}) {
  if (target.isEmpty) return const [];
  final notes = <String>[];

  // 1. Bloques: matrimonios completos, y solteros por sexo.
  final byId = {for (final p in target) p.id: p};
  final used = <String>{};
  final couplePeople = <PersonRef>[];
  final men = <PersonRef>[];
  final women = <PersonRef>[];
  final forced = <PersonRef>[]; // cónyuge ya hospedado: va con él si se puede
  final ordered = [...target]..sort((a, b) => a.name.compareTo(b.name));
  for (final p in ordered) {
    if (used.contains(p.id)) continue;
    final sp = p.spouseId == null ? null : byId[p.spouseId];
    if (sp != null && !used.contains(sp.id)) {
      couplePeople
        ..add(p)
        ..add(sp);
      used
        ..add(p.id)
        ..add(sp.id);
    } else if (p.spouseId != null && p.spouseLodgingId != null) {
      forced.add(p);
      used.add(p.id);
    } else {
      if (p.spouseId != null) {
        notes.add(
            '${p.name} tiene cónyuge que no está en esta selección; se trata como persona sola. '
            'Si van juntos, selecciona a los dos.');
      }
      (p.sex == Sex.male ? men : women).add(p);
      used.add(p.id);
    }
  }

  final blocks = <_Block>[
    if (couplePeople.isNotEmpty) _Block(_BlockKind.couples, couplePeople),
    if (men.isNotEmpty) _Block(_BlockKind.men, men),
    if (women.isNotEmpty) _Block(_BlockKind.women, women),
  ];

  // 2. Cónyuge ya hospedado: mismo hospedaje si hay plaza y acepta matrimonios.
  final forcedLegs = <ProposalLeg>[];
  final forcedUnplaced = <PersonRef>[];
  final taken = <String, int>{}; // plazas que ya usan los tramos forzados
  for (final p in forced) {
    final l = lodgings.where((x) => x.id == p.spouseLodgingId).firstOrNull;
    final left = l == null ? 0 : l.free - (taken[l.id] ?? 0);
    if (l != null && acceptsCouples(l.accepts) && left >= 1) {
      taken[l.id] = (taken[l.id] ?? 0) + 1;
      forcedLegs.add(ProposalLeg(
        lodgingId: l.id,
        lodgingName: l.name,
        people: [p],
        reason: 'Es donde ya está su cónyuge y hay plaza.',
        occupiedBefore: l.occupied + (taken[l.id]! - 1),
        capacity: l.capacity,
      ));
    } else {
      forcedUnplaced.add(p);
      notes.add(
          'No hay plaza para ${p.name} junto a su cónyuge${l == null ? '' : ' en «${l.name}»'}.');
    }
  }

  // 3. Planes alternativos por bloque (los bloques no compiten: aceptan sexos distintos).
  final targetChurches = {
    for (final p in target)
      if (p.churchId != null) p.churchId!
  };
  // Los bloques SÍ compiten por las plazas de los hospedajes «Sin preferencia» (aceptan a todos):
  // se planifican en orden y cada uno ve las plazas que ya tomaron los anteriores (QA-WIN-06).
  List<_Plan> chooseFor(int i) {
    final used = <String, int>{...taken};
    final chosen = <_Plan>[];
    for (final b in blocks) {
      final adjusted = [
        for (final l in lodgings)
          LodgingCandidate(
            id: l.id,
            name: l.name,
            accepts: l.accepts,
            capacity: l.capacity,
            occupied: l.occupied + (used[l.id] ?? 0),
            kind: l.kind,
            hostChurchId: l.hostChurchId,
            occupantChurchIds: l.occupantChurchIds,
            distanceNote: l.distanceNote,
          )
      ];
      final plans = _plansFor(b, adjusted, options, targetChurches, notes);
      final plan = plans[i < plans.length ? i : plans.length - 1];
      for (final leg in plan.legs) {
        used[leg.lodgingId] = (used[leg.lodgingId] ?? 0) + leg.people.length;
      }
      chosen.add(plan);
    }
    return chosen;
  }

  // 4. Combinar: la propuesta i toma el plan i de cada bloque (o su último plan).
  final out = <LodgingProposal>[];
  final seen = <String>{};
  for (var i = 0; i < 3 && out.length < maxProposals; i++) {
    final chosen = chooseFor(i);
    final key = chosen.map((c) => c.key).join('#');
    if (!seen.add(key)) continue;
    final unplaced = [
      ...forcedUnplaced,
      for (final c in chosen) ...c.unplaced,
    ];
    final legs = [...forcedLegs, for (final c in chosen) ...c.legs];
    final pNotes = [...notes];
    for (final b in blocks.indexed) {
      final un = chosen[b.$1].unplaced;
      if (un.isNotEmpty) {
        pNotes.add(
            'Faltan ${un.length} plaza${un.length == 1 ? '' : 's'} para ${b.$2.label}. '
            'Registra otro hospedaje o libera plazas; no se asignará a esas personas sin que lo confirmes.');
      }
    }
    final noHosting = blocks.indexed
        .where((b) =>
            chosen[b.$1].legs.isEmpty && chosen[b.$1].unplaced.isNotEmpty)
        .map((b) => b.$2.label);
    for (final label in noHosting) {
      pNotes.add('No hay ningún hospedaje compatible para $label.');
    }
    out.add(LodgingProposal(
      legs: legs,
      unplaced: unplaced,
      notes: pNotes.toSet().toList(),
      score: chosen.fold(0, (a, c) => a + c.score),
    ));
  }
  return out;
}

List<_Plan> _plansFor(_Block b, List<LodgingCandidate> all, SuggestOptions o,
    Set<String> churches, List<String> notes) {
  final accepts = switch (b.kind) {
    _BlockKind.couples => LodgingAccepts.couples,
    _BlockKind.men => LodgingAccepts.men,
    _BlockKind.women => LodgingAccepts.women,
  };
  final compatible = all
      .where((l) =>
          (l.accepts == accepts || l.accepts == LodgingAccepts.any) &&
          l.capacity > 0 &&
          l.free > 0)
      .toList();

  int score(LodgingCandidate l, int size, {required bool whole}) {
    var s = 0;
    if (whole) s += 100;
    final spare = l.free - size;
    s += (30 - spare) < 0 ? 0 : 30 - spare;
    if (o.preferHostChurch &&
        ((l.hostChurchId != null && churches.contains(l.hostChurchId)) ||
            l.occupantChurchIds.any(churches.contains))) {
      s += 20;
    }
    if (l.distanceNote != null && l.distanceNote!.trim().isNotEmpty) s += 5;
    if (l.capacity >= 4 && (l.occupied + size) / l.capacity < 0.25) s -= 10;
    // «Sin preferencia» es el comodín: se usa cuando no hay uno específico que sirva igual de bien.
    if (l.accepts == LodgingAccepts.any) s -= 8;
    return s;
  }

  String why(LodgingCandidate l, int size, bool whole) {
    final parts = <String>[
      whole ? 'Caben todos juntos' : 'Se reparte para aprovechar plazas',
      if (l.free - size == 0) 'lo deja exactamente lleno',
      if (o.preferHostChurch &&
          ((l.hostChurchId != null && churches.contains(l.hostChurchId)) ||
              l.occupantChurchIds.any(churches.contains)))
        'misma iglesia',
      if (l.distanceNote != null && l.distanceNote!.trim().isNotEmpty)
        l.distanceNote!.trim(),
    ];
    return '${parts.first}${parts.length > 1 ? ' (${parts.skip(1).join(', ')})' : ''}.';
  }

  int byName(LodgingCandidate a, LodgingCandidate c) =>
      a.name.compareTo(c.name);

  // Planes de un solo hospedaje (todo el bloque junto).
  final plans = <_Plan>[];
  if (o.keepTogether) {
    final fits = compatible.where((l) => l.free >= b.size).toList();
    final scored = {for (final l in fits) l.id: score(l, b.size, whole: true)};
    fits.sort((a, c) {
      final d = scored[c.id]!.compareTo(scored[a.id]!);
      return d != 0 ? d : byName(a, c);
    });
    for (final l in fits) {
      plans.add(_Plan([
        ProposalLeg(
          lodgingId: l.id,
          lodgingName: l.name,
          people: b.people,
          reason: why(l, b.size, true),
          occupiedBefore: l.occupied,
          capacity: l.capacity,
        )
      ], const [], scored[l.id]!));
    }
    if (plans.isNotEmpty) return plans.take(3).toList();
  }

  // División: codicioso por mayor espacio libre (matrimonios en pares).
  final order = [...compatible]..sort((a, c) {
      final d = c.free.compareTo(a.free);
      if (d != 0) return d;
      final sd = score(c, 1, whole: false).compareTo(score(a, 1, whole: false));
      return sd != 0 ? sd : byName(a, c);
    });
  final legs = <ProposalLeg>[];
  var rest = [...b.people];
  var total = 0;
  for (final l in order) {
    if (rest.isEmpty) break;
    var take = l.free < rest.length ? l.free : rest.length;
    if (b.kind == _BlockKind.couples) {
      take -= take % 2; // nunca separar un matrimonio
    }
    if (take <= 0) continue;
    final chunk = rest.sublist(0, take);
    rest = rest.sublist(take);
    total += score(l, take, whole: false);
    legs.add(ProposalLeg(
      lodgingId: l.id,
      lodgingName: l.name,
      people: chunk,
      reason: why(l, take, false),
      occupiedBefore: l.occupied,
      capacity: l.capacity,
    ));
  }
  return [_Plan(legs, rest, total)];
}

/// Propuesta para un matrimonio que ya tiene hospedaje pero NO bien (QA-BUG-003): están en
/// hospedajes distintos, o alguno está en uno que no acepta matrimonios (p. ej. el esposo en un
/// albergue de hombres cuando se vincula a su esposa).
///
/// [aLodgingId] y [bLodgingId] son los hospedajes actuales de [a] y [b] (nulo = sin hospedaje).
/// [lodgings] debe describir la ocupación SIN contar a estas dos personas. Devuelve la propuesta
/// de mover a los dos a un mismo hospedaje de matrimonios (2 plazas), o nulo si no hace falta
/// moverlos (ya están juntos en un hospedaje de matrimonios, o ninguno tiene hospedaje) o si no
/// hay un hospedaje de matrimonios con 2 plazas libres. Nunca se aplica sola.
LodgingProposal? proposeCoupleMove({
  required PersonRef a,
  required PersonRef b,
  required String? aLodgingId,
  required String? bLodgingId,
  required List<LodgingCandidate> lodgings,
}) {
  if (aLodgingId == null && bLodgingId == null) return null;
  LodgingCandidate? find(String? id) =>
      lodgings.where((l) => l.id == id).firstOrNull;
  final together = aLodgingId == bLodgingId;
  bool couplesOk(LodgingCandidate? l) => l != null && acceptsCouples(l.accepts);
  final fine = together && couplesOk(find(aLodgingId));
  // Uno solo con hospedaje de matrimonios: la sugerencia normal ya lo junta con su cónyuge.
  final oneInCouples = (aLodgingId == null || bLodgingId == null) &&
      couplesOk(find(aLodgingId ?? bLodgingId));
  if (fine || oneInCouples) return null;
  final target = [
    PersonRef(
        id: a.id,
        name: a.name,
        sex: a.sex,
        spouseId: b.id,
        churchId: a.churchId),
    PersonRef(
        id: b.id,
        name: b.name,
        sex: b.sex,
        spouseId: a.id,
        churchId: b.churchId),
  ];
  final proposals = suggestLodging(target, lodgings, maxProposals: 1);
  if (proposals.isEmpty) return null;
  final p = proposals.first;
  final ok = p.legs.length == 1 &&
      p.legs.first.people.length == 2 &&
      p.unplaced.isEmpty;
  return ok ? p : null;
}
