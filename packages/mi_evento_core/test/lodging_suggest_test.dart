import 'package:mi_evento_core/mi_evento_core.dart';
import 'package:test/test.dart';

PersonRef p(String id, Sex s,
        {String? spouse, String? church, String? spouseLodging}) =>
    PersonRef(
        id: id,
        name: 'P$id',
        sex: s,
        spouseId: spouse,
        churchId: church,
        spouseLodgingId: spouseLodging);

LodgingCandidate lodging(String id, LodgingAccepts a,
        {int cap = 4,
        int occ = 0,
        LodgingKindRef kind = LodgingKindRef.shelter,
        String? host,
        Set<String> occupants = const {},
        String? distance}) =>
    LodgingCandidate(
        id: id,
        name: 'Casa $id',
        accepts: a,
        capacity: cap,
        occupied: occ,
        kind: kind,
        hostChurchId: host,
        occupantChurchIds: occupants,
        distanceNote: distance);

List<String> ids(ProposalLeg l) => l.people.map((x) => x.id).toList();

void main() {
  coupleMoveTests();
  sinPreferenciaTests();
  group('casos básicos', () {
    test('selección vacía: sin propuestas', () {
      expect(suggestLodging([], [lodging('a', LodgingAccepts.men)]), isEmpty);
    });

    test(
        'hombre solo: va a un hospedaje de hombres, nunca a mujeres/matrimonios',
        () {
      final r = suggestLodging([
        p('1', Sex.male)
      ], [
        lodging('w', LodgingAccepts.women),
        lodging('c', LodgingAccepts.couples),
        lodging('m', LodgingAccepts.men),
      ]);
      expect(r, hasLength(1));
      expect(r.single.legs.single.lodgingId, 'm');
      expect(r.single.isComplete, isTrue);
    });

    test('persona sola sin hospedajes compatibles: mensaje claro, sin error',
        () {
      final r = suggestLodging(
          [p('1', Sex.female)], [lodging('m', LodgingAccepts.men)]);
      expect(r.single.isComplete, isFalse);
      expect(r.single.unplaced, hasLength(1));
      expect(r.single.notes.join(' '), contains('ningún hospedaje compatible'));
    });

    test('matrimonio: solo a «matrimonios» y ocupa 2 plazas', () {
      final r = suggestLodging([
        p('1', Sex.male, spouse: '2'),
        p('2', Sex.female, spouse: '1')
      ], [
        lodging('m', LodgingAccepts.men),
        lodging('c', LodgingAccepts.couples, cap: 2),
      ]);
      expect(r.single.legs.single.lodgingId, 'c');
      expect(r.single.legs.single.people, hasLength(2));
      expect(r.single.legs.single.occupiedAfter, 2);
    });

    test('matrimonio no cabe con 1 plaza libre: no se separa', () {
      final r = suggestLodging(
          [p('1', Sex.male, spouse: '2'), p('2', Sex.female, spouse: '1')],
          [lodging('c', LodgingAccepts.couples, cap: 3, occ: 2)]);
      expect(r.single.legs, isEmpty);
      expect(r.single.unplaced, hasLength(2));
    });
  });

  group('puntuación', () {
    test('prefiere el ajuste más justo', () {
      final r = suggestLodging([
        p('1', Sex.male),
        p('2', Sex.male)
      ], [
        lodging('grande', LodgingAccepts.men, cap: 10),
        lodging('justo', LodgingAccepts.men, cap: 2),
      ]);
      expect(r.first.legs.single.lodgingId, 'justo');
      expect(r.first.legs.single.reason, contains('exactamente lleno'));
    });

    test('misma iglesia suma; se puede desactivar', () {
      final target = [p('1', Sex.male, church: 'X')];
      final lods = [
        lodging('a', LodgingAccepts.men, cap: 5),
        lodging('b', LodgingAccepts.men, cap: 5, host: 'X'),
      ];
      expect(suggestLodging(target, lods).first.legs.single.lodgingId, 'b');
      final off = suggestLodging(target, lods,
          options: const SuggestOptions(preferHostChurch: false));
      expect(off.first.legs.single.lodgingId, 'a'); // empate → por nombre
    });

    test('también cuenta si ya hospeda gente de esa iglesia', () {
      final r = suggestLodging([
        p('1', Sex.female, church: 'X')
      ], [
        lodging('a', LodgingAccepts.women, cap: 5),
        lodging('b', LodgingAccepts.women, cap: 5, occupants: {'X'}, occ: 1),
      ]);
      expect(r.first.legs.single.lodgingId, 'b');
    });

    test('empates: orden estable por nombre', () {
      final lods = [
        lodging('z', LodgingAccepts.men),
        lodging('a', LodgingAccepts.men),
        lodging('m', LodgingAccepts.men),
      ];
      final r1 = suggestLodging([p('1', Sex.male)], lods);
      final r2 = suggestLodging([p('1', Sex.male)], lods.reversed.toList());
      expect(r1.first.legs.single.lodgingId, 'a');
      expect(r2.first.legs.single.lodgingId, 'a');
    });

    test('ofrece alternativas distintas, máximo 3', () {
      final r = suggestLodging([
        p('1', Sex.male)
      ], [
        for (final x in 'abcde'.split(''))
          lodging(x, LodgingAccepts.men, cap: 3 + 'abcde'.indexOf(x))
      ]);
      expect(r, hasLength(3));
      expect(r.map((x) => x.legs.single.lodgingId).toSet(), hasLength(3));
      expect(r[0].score, greaterThanOrEqualTo(r[1].score));
    });
  });

  group('división de grupos', () {
    test(
        'grupo mixto con matrimonio: hasta 3 tramos (parejas, hombres, mujeres)',
        () {
      final r = suggestLodging([
        p('1', Sex.male, spouse: '2'),
        p('2', Sex.female, spouse: '1'),
        p('3', Sex.male),
        p('4', Sex.female),
      ], [
        lodging('c', LodgingAccepts.couples, cap: 2),
        lodging('m', LodgingAccepts.men, cap: 2),
        lodging('w', LodgingAccepts.women, cap: 2),
      ]);
      final legs = r.first.legs;
      expect(legs, hasLength(3));
      expect(r.first.isComplete, isTrue);
      expect(legs.firstWhere((l) => l.lodgingId == 'c').people, hasLength(2));
    });

    test('un bloque que no cabe entero se parte minimizando hospedajes', () {
      final r = suggestLodging([
        for (var i = 1; i <= 5; i++) p('$i', Sex.female)
      ], [
        lodging('a', LodgingAccepts.women, cap: 2),
        lodging('b', LodgingAccepts.women, cap: 3),
        lodging('c', LodgingAccepts.women, cap: 2),
      ]);
      final legs = r.single.legs;
      expect(legs.map((l) => l.lodgingId), ['b', 'a']);
      expect(legs.fold(0, (a, l) => a + l.people.length), 5);
      expect(r.single.isComplete, isTrue);
    });

    test('al partir matrimonios nunca se separan (pares)', () {
      final r = suggestLodging([
        p('1', Sex.male, spouse: '2'),
        p('2', Sex.female, spouse: '1'),
        p('3', Sex.male, spouse: '4'),
        p('4', Sex.female, spouse: '3'),
      ], [
        lodging('a', LodgingAccepts.couples, cap: 3),
        lodging('b', LodgingAccepts.couples, cap: 3),
      ]);
      for (final l in r.single.legs) {
        expect(l.people.length.isEven, isTrue);
      }
      expect(r.single.isComplete, isTrue);
    });

    test('déficit: se informa cuántas plazas faltan y no se asigna de más', () {
      final r = suggestLodging([for (var i = 1; i <= 5; i++) p('$i', Sex.male)],
          [lodging('a', LodgingAccepts.men, cap: 3, occ: 1)]);
      expect(r.single.placedCount, 2);
      expect(r.single.unplaced, hasLength(3));
      expect(r.single.isComplete, isFalse);
      expect(
          r.single.notes.join(' '), contains('Faltan 3 plazas para hombres'));
    });

    test('mantener juntos desactivado: reparte en lugar de juntar', () {
      final r = suggestLodging([
        p('1', Sex.male),
        p('2', Sex.male)
      ], [
        lodging('a', LodgingAccepts.men, cap: 10),
        lodging('b', LodgingAccepts.men, cap: 1),
        lodging('c', LodgingAccepts.men, cap: 1),
      ], options: const SuggestOptions(keepTogether: false));
      expect(r.single.legs.length, greaterThan(0));
      expect(r.single.isComplete, isTrue);
    });
  });

  group('casos límite', () {
    test('hospedaje sobrecargado o con capacidad 0 no se propone', () {
      final r = suggestLodging([
        p('1', Sex.male)
      ], [
        lodging('a', LodgingAccepts.men, cap: 2, occ: 5),
        lodging('b', LodgingAccepts.men, cap: 0),
      ]);
      expect(r.single.legs, isEmpty);
      expect(r.single.isComplete, isFalse);
    });

    test('cónyuge ya hospedado: se propone el mismo sitio si hay plaza', () {
      final r = suggestLodging([
        p('2', Sex.female, spouse: '1', spouseLodging: 'c')
      ], [
        lodging('c', LodgingAccepts.couples, cap: 4, occ: 1),
        lodging('d', LodgingAccepts.couples, cap: 4),
      ]);
      expect(r.single.legs.single.lodgingId, 'c');
      expect(r.single.legs.single.reason, contains('cónyuge'));
    });

    test('cónyuge ya hospedado sin plaza libre: aviso, sin asignar', () {
      final r = suggestLodging([
        p('2', Sex.female, spouse: '1', spouseLodging: 'c')
      ], [
        lodging('c', LodgingAccepts.couples, cap: 2, occ: 2),
      ]);
      expect(r.single.legs, isEmpty);
      expect(r.single.unplaced, hasLength(1));
      expect(r.single.notes.join(' '), contains('No hay plaza'));
    });

    test(
        'cónyuge fuera de la selección y sin hospedaje: se trata como solo y se avisa',
        () {
      final r = suggestLodging(
          [p('1', Sex.male, spouse: '9')], [lodging('m', LodgingAccepts.men)]);
      expect(r.single.legs.single.lodgingId, 'm');
      expect(r.single.notes.join(' '), contains('cónyuge'));
    });

    test('no modifica las listas recibidas y es repetible', () {
      final target = [p('1', Sex.male), p('2', Sex.female)];
      final lods = [
        lodging('m', LodgingAccepts.men),
        lodging('w', LodgingAccepts.women)
      ];
      final a = suggestLodging(target, lods);
      final b = suggestLodging(target, lods);
      expect(a.first.legs.map((l) => l.lodgingId),
          b.first.legs.map((l) => l.lodgingId));
      expect(target.map((x) => x.id), ['1', '2']);
    });
  });
}

void coupleMoveTests() {
  group('proposeCoupleMove (QA-BUG-003)', () {
    final h = p('h', Sex.male, spouse: 'w');
    final w = p('w', Sex.female, spouse: 'h');

    test('esposo en albergue de hombres: propone mover a los dos a matrimonios',
        () {
      final r = proposeCoupleMove(
        a: h,
        b: w,
        aLodgingId: 'A',
        bLodgingId: null,
        lodgings: [
          lodging('A', LodgingAccepts.men, occ: 0),
          lodging('C', LodgingAccepts.couples, cap: 2),
        ],
      );
      expect(r, isNotNull);
      expect(r!.legs.single.lodgingId, 'C');
      expect(r.legs.single.people.length, 2);
    });

    test('ya juntos en un hospedaje de matrimonios: no hace falta moverlos',
        () {
      expect(
          proposeCoupleMove(
              a: h,
              b: w,
              aLodgingId: 'C',
              bLodgingId: 'C',
              lodgings: [lodging('C', LodgingAccepts.couples)]),
          isNull);
    });

    test('uno solo en matrimonios con plaza: la sugerencia normal ya los junta',
        () {
      expect(
          proposeCoupleMove(
              a: h,
              b: w,
              aLodgingId: 'C',
              bLodgingId: null,
              lodgings: [lodging('C', LodgingAccepts.couples)]),
          isNull);
    });

    test('en hospedajes distintos de matrimonios: propone juntarlos', () {
      final r = proposeCoupleMove(
          a: h,
          b: w,
          aLodgingId: 'C1',
          bLodgingId: 'C2',
          lodgings: [
            lodging('C1', LodgingAccepts.couples, occ: 0),
            lodging('C2', LodgingAccepts.couples, occ: 0),
          ]);
      expect(r, isNotNull);
      expect(r!.legs.single.people.length, 2);
    });

    test('ninguno con hospedaje, o sin casa de matrimonios con 2 plazas: nada',
        () {
      expect(
          proposeCoupleMove(
              a: h,
              b: w,
              aLodgingId: null,
              bLodgingId: null,
              lodgings: [lodging('C', LodgingAccepts.couples)]),
          isNull);
      expect(
          proposeCoupleMove(
              a: h,
              b: w,
              aLodgingId: 'A',
              bLodgingId: null,
              lodgings: [
                lodging('A', LodgingAccepts.men),
                lodging('C', LodgingAccepts.couples, cap: 2, occ: 1),
              ]),
          isNull);
    });
  });
}

void sinPreferenciaTests() {
  group('hospedaje sin preferencia', () {
    test(
        'sirve a hombres, mujeres y matrimonios, pero se usa después de uno específico',
        () {
      final h = suggestLodging([
        p('1', Sex.male)
      ], [
        lodging('any', LodgingAccepts.any),
        lodging('m', LodgingAccepts.men)
      ]);
      expect(h.first.legs.single.lodgingId, 'm');
      for (final sx in [Sex.male, Sex.female]) {
        final r =
            suggestLodging([p('1', sx)], [lodging('any', LodgingAccepts.any)]);
        expect(r.first.legs.single.lodgingId, 'any', reason: '$sx');
      }
      final c = suggestLodging([
        p('1', Sex.male, spouse: '2'),
        p('2', Sex.female, spouse: '1'),
      ], [
        lodging('any', LodgingAccepts.any)
      ]);
      expect(c.first.legs.single.lodgingId, 'any');
      expect(c.first.legs.single.people, hasLength(2));
    });

    test(
        'no genera avisos ni se propone mover un matrimonio que ya está junto ahí',
        () {
      expect(acceptsCouples(LodgingAccepts.any), isTrue);
      expect(acceptsCouples(LodgingAccepts.men), isFalse);
      expect(
          proposeCoupleMove(
              a: p('1', Sex.male, spouse: '2'),
              b: p('2', Sex.female, spouse: '1'),
              aLodgingId: 'any',
              bLodgingId: 'any',
              lodgings: [lodging('any', LodgingAccepts.any)]),
          isNull);
    });

    test(
        'QA-WIN-06: bloques distintos no se pasan de la capacidad de un hospedaje «Sin preferencia»',
        () {
      final target = [
        for (var i = 0; i < 20; i++) p('h$i', Sex.male),
        for (var i = 0; i < 20; i++) p('m$i', Sex.female),
        p('c1', Sex.male, spouse: 'c2'),
        p('c2', Sex.female, spouse: 'c1'),
      ];
      final lodgings = [
        lodging('any', LodgingAccepts.any, cap: 20),
        lodging('men', LodgingAccepts.men, cap: 10),
        lodging('women', LodgingAccepts.women, cap: 10),
        lodging('cou', LodgingAccepts.couples, cap: 4),
      ];
      for (final prop in suggestLodging(target, lodgings)) {
        final used = <String, int>{};
        for (final l in prop.legs) {
          used[l.lodgingId] = (used[l.lodgingId] ?? 0) + l.people.length;
        }
        for (final l in lodgings) {
          expect(used[l.id] ?? 0, lessThanOrEqualTo(l.capacity),
              reason: l.id);
        }
        expect(prop.placedCount + prop.unplaced.length, target.length);
      }
    });

    test('lodgingFitsPerson filtra por sexo', () {
      expect(lodgingFitsPerson(LodgingAccepts.men, Sex.female), isFalse);
      expect(lodgingFitsPerson(LodgingAccepts.women, Sex.female), isTrue);
      expect(lodgingFitsPerson(LodgingAccepts.couples, Sex.male), isFalse);
      expect(
          lodgingFitsPerson(LodgingAccepts.couples, Sex.male, hasSpouse: true),
          isTrue);
      expect(lodgingFitsPerson(LodgingAccepts.any, Sex.male), isTrue);
    });
  });
}
