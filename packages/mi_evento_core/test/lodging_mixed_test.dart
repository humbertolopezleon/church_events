import 'package:mi_evento_core/mi_evento_core.dart';
import 'package:test/test.dart';

PersonRef p(String id, Sex s, {String? spouse}) =>
    PersonRef(id: id, name: 'P$id', sex: s, spouseId: spouse);

LodgingCandidate cand(String id, LodgingAccepts a,
        {int cap = 2,
        int occ = 0,
        OccupantMix mix = OccupantMix.none}) =>
    LodgingCandidate(
        id: id,
        name: 'Casa $id',
        accepts: a,
        capacity: cap,
        occupied: occ,
        occupantMix: mix);

List<String> ids(ProposalLeg l) => l.people.map((x) => x.id).toList();

LodgingSlot slot(LodgingAccepts a, {int cap = 2, int occ = 0}) =>
    LodgingSlot(name: 'Casa', accepts: a, capacity: cap, occupied: occ);

void main() {
  group('hospedaje mixto: reglas', () {
    test('base de datos y etiquetas', () {
      for (final a in LodgingAccepts.values) {
        expect(lodgingAcceptsFromDb(lodgingAcceptsToDb(a)), a);
      }
      expect(lodgingAcceptsToDb(LodgingAccepts.womenOrCouples), 'women_couples');
      expect(lodgingAcceptsToDb(LodgingAccepts.menOrCouples), 'men_couples');
      expect(lodgingAcceptsLabel(LodgingAccepts.womenOrCouples),
          'Solo mujeres o matrimonios');
      expect(lodgingAcceptsLabel(LodgingAccepts.menOrCouples),
          'Solo hombres o matrimonios');
      expect(acceptsCouples(LodgingAccepts.womenOrCouples), isTrue);
      expect(acceptsCouples(LodgingAccepts.women), isFalse);
    });

    test('2 plazas «mujeres o matrimonios»: 2 mujeres sí', () {
      final b = lodgingBlockers(slot(LodgingAccepts.womenOrCouples),
          [p('a', Sex.female), p('b', Sex.female)]);
      expect(b, isEmpty);
    });

    test('un matrimonio sí', () {
      final b = lodgingBlockers(slot(LodgingAccepts.womenOrCouples), [
        p('m', Sex.male, spouse: 'f'),
        p('f', Sex.female, spouse: 'm'),
      ]);
      expect(b, isEmpty);
    });

    test('un hombre solo no entra (ni casado, sin su esposa)', () {
      expect(
          lodgingBlockers(
              slot(LodgingAccepts.womenOrCouples), [p('h', Sex.male)]),
          isNotEmpty);
      expect(
          lodgingBlockers(slot(LodgingAccepts.womenOrCouples),
              [p('h', Sex.male, spouse: 'x')]),
          isNotEmpty);
    });

    test('una mujer casada sola (su esposo en otro sitio) entra como mujer', () {
      expect(
          lodgingBlockers(slot(LodgingAccepts.womenOrCouples),
              [p('f', Sex.female, spouse: 'm')]),
          isEmpty);
    });

    test('no mezcla: matrimonio + mujer sola, en ambos sentidos', () {
      final pareja = [
        p('m', Sex.male, spouse: 'f'),
        p('f', Sex.female, spouse: 'm'),
      ];
      // La mujer sola llega a un hospedaje que ya tiene un matrimonio.
      final b1 = lodgingBlockers(
          slot(LodgingAccepts.womenOrCouples, cap: 3, occ: 2), [p('x', Sex.female)],
          alreadyThere: pareja);
      expect(b1.single.message, contains('no mezcla'));
      // El matrimonio llega a un hospedaje que ya tiene una mujer sola.
      final b2 = lodgingBlockers(
          slot(LodgingAccepts.womenOrCouples, cap: 3, occ: 1), pareja,
          alreadyThere: [p('x', Sex.female)]);
      expect(b2.single.message, contains('no mezcla'));
    });

    test('«hombres o matrimonios» es simétrico', () {
      expect(
          lodgingBlockers(slot(LodgingAccepts.menOrCouples),
              [p('a', Sex.male), p('b', Sex.male)]),
          isEmpty);
      expect(
          lodgingBlockers(
              slot(LodgingAccepts.menOrCouples), [p('f', Sex.female)]),
          isNotEmpty);
    });

    test('lodgingFitsPerson y occupantMixOf', () {
      expect(lodgingFitsPerson(LodgingAccepts.womenOrCouples, Sex.male), isFalse);
      expect(
          lodgingFitsPerson(LodgingAccepts.womenOrCouples, Sex.male,
              hasSpouse: true),
          isTrue);
      expect(occupantMixOf([]), OccupantMix.none);
      expect(occupantMixOf([p('a', Sex.female)]), OccupantMix.singles);
      expect(
          occupantMixOf([
            p('m', Sex.male, spouse: 'f'),
            p('f', Sex.female, spouse: 'm')
          ]),
          OccupantMix.couples);
      expect(
          occupantMixOf([
            p('m', Sex.male, spouse: 'f'),
            p('f', Sex.female, spouse: 'm'),
            p('x', Sex.female)
          ]),
          OccupantMix.mixed);
    });
  });

  group('hospedaje mixto: sugerencia', () {
    test('2 mujeres van a «mujeres o matrimonios» de 2 plazas', () {
      final r = suggestLodging([p('a', Sex.female), p('b', Sex.female)],
          [cand('x', LodgingAccepts.womenOrCouples)]);
      expect(r.first.legs.single.lodgingId, 'x');
      expect(r.first.unplaced, isEmpty);
    });

    test('un matrimonio va a un mixto de 2 plazas si no hay otro', () {
      final r = suggestLodging([
        p('m', Sex.male, spouse: 'f'),
        p('f', Sex.female, spouse: 'm'),
      ], [
        cand('x', LodgingAccepts.menOrCouples)
      ]);
      expect(r.first.legs.single.lodgingId, 'x');
    });

    test('prefiere el hospedaje específico al mixto', () {
      final r = suggestLodging([p('a', Sex.female), p('b', Sex.female)], [
        cand('mixto', LodgingAccepts.womenOrCouples),
        cand('mujeres', LodgingAccepts.women),
      ]);
      expect(r.first.legs.single.lodgingId, 'mujeres');
    });

    test('un mixto con un matrimonio dentro no recibe a una mujer sola', () {
      final r = suggestLodging([p('a', Sex.female)], [
        cand('x', LodgingAccepts.womenOrCouples,
            cap: 4, occ: 2, mix: OccupantMix.couples)
      ]);
      expect(r.first.unplaced, isNotEmpty);
      expect(r.first.legs, isEmpty);
    });

    test('un mixto con mujeres solas dentro no recibe a un matrimonio', () {
      final r = suggestLodging([
        p('m', Sex.male, spouse: 'f'),
        p('f', Sex.female, spouse: 'm'),
      ], [
        cand('x', LodgingAccepts.womenOrCouples,
            cap: 4, occ: 1, mix: OccupantMix.singles)
      ]);
      expect(r.first.unplaced, isNotEmpty);
    });

    test('en una misma propuesta no se mezclan: el matrimonio se queda con el mixto',
        () {
      // Un solo mixto de 2 plazas, un matrimonio y una mujer: el matrimonio lo toma (se planifica
      // primero) y la mujer queda sin sitio, nunca mezclada con ellos.
      final r = suggestLodging([
        p('m', Sex.male, spouse: 'f'),
        p('f', Sex.female, spouse: 'm'),
        p('x', Sex.female),
      ], [
        cand('x', LodgingAccepts.womenOrCouples, cap: 3)
      ]);
      final first = r.first;
      expect(first.legs.single.people.map((e) => e.id).toSet(), {'m', 'f'});
      expect(first.unplaced.map((e) => e.id), ['x']);
    });
  });

  group('matrimonios separados (opcional)', () {
    final pareja = [
      p('m', Sex.male, spouse: 'f'),
      p('f', Sex.female, spouse: 'm'),
    ];
    final lodgings = [
      cand('h', LodgingAccepts.men, cap: 4),
      cand('f', LodgingAccepts.women, cap: 4),
    ];

    test('por defecto un matrimonio nunca se separa', () {
      final r = suggestLodging(pareja, lodgings);
      expect(r.first.legs, isEmpty);
      expect(r.first.unplaced.length, 2);
      expect(r.first.splitCoupleIds, isEmpty);
    });

    test('activado y sin hospedaje de matrimonios: esposo con hombres, esposa con mujeres',
        () {
      final r = suggestLodging(pareja, lodgings,
          options: const SuggestOptions(splitCouples: true));
      final first = r.first;
      expect(first.unplaced, isEmpty);
      final by = {for (final l in first.legs) l.lodgingId: ids(l)};
      expect(by['h'], ['m']);
      expect(by['f'], ['f']);
      expect(first.splitCoupleIds, {'m', 'f'});
      expect(first.notes.join(' '), contains('por separado'));
    });

    test('activado pero con hospedaje de matrimonios: NO se separa', () {
      final r = suggestLodging(pareja, [
        ...lodgings,
        cand('c', LodgingAccepts.couples),
      ], options: const SuggestOptions(splitCouples: true));
      expect(r.first.splitCoupleIds, isEmpty);
      expect(r.first.legs.single.lodgingId, 'c');
    });

    test('solo se separan los matrimonios que sobran', () {
      final dos = [
        p('m1', Sex.male, spouse: 'f1'),
        p('f1', Sex.female, spouse: 'm1'),
        p('m2', Sex.male, spouse: 'f2'),
        p('f2', Sex.female, spouse: 'm2'),
      ];
      final r = suggestLodging(dos, [
        cand('c', LodgingAccepts.couples), // cabe un matrimonio
        ...lodgings,
      ], options: const SuggestOptions(splitCouples: true));
      final first = r.first;
      expect(first.splitCoupleIds.length, 2);
      expect(first.unplaced, isEmpty);
      final together = first.legs.where((l) => l.lodgingId == 'c').single;
      expect(together.people.length, 2);
    });

    test('un hospedaje mixto cuenta como lugar para matrimonios (no se separa)', () {
      final r = suggestLodging(pareja, [
        cand('x', LodgingAccepts.womenOrCouples),
        ...lodgings,
      ], options: const SuggestOptions(splitCouples: true));
      expect(r.first.splitCoupleIds, isEmpty);
      expect(r.first.legs.single.lodgingId, 'x');
    });
  });
}
