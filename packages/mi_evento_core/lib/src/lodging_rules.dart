import 'models.dart';

/// A quién acepta un hospedaje.
/// `any` = sin preferencia: acepta hombres, mujeres y matrimonios.
/// `menOrCouples` / `womenOrCouples` = hospedaje «mixto»: personas solas de ese sexo **o**
/// matrimonios, sin mezclar (p. ej. 2 plazas: 2 mujeres o un matrimonio).
enum LodgingAccepts { men, women, couples, any, menOrCouples, womenOrCouples }

LodgingAccepts lodgingAcceptsFromDb(String s) => switch (s) {
      'men' => LodgingAccepts.men,
      'women' => LodgingAccepts.women,
      'any' => LodgingAccepts.any,
      'men_couples' => LodgingAccepts.menOrCouples,
      'women_couples' => LodgingAccepts.womenOrCouples,
      _ => LodgingAccepts.couples,
    };

/// Valor que se guarda en la base de datos (texto; los nuevos no necesitan migración).
String lodgingAcceptsToDb(LodgingAccepts a) => switch (a) {
      LodgingAccepts.menOrCouples => 'men_couples',
      LodgingAccepts.womenOrCouples => 'women_couples',
      _ => a.name,
    };

/// Hospedajes «mixtos»: solteros de un sexo o matrimonios, sin mezclar.
bool isMixedLodging(LodgingAccepts a) =>
    a == LodgingAccepts.menOrCouples || a == LodgingAccepts.womenOrCouples;

/// Sexo de las personas solas que acepta un hospedaje mixto.
Sex mixedLodgingSex(LodgingAccepts a) =>
    a == LodgingAccepts.menOrCouples ? Sex.male : Sex.female;

/// Quiénes hay dentro de un hospedaje (para los mixtos, que no mezclan).
enum OccupantMix { none, couples, singles, mixed }

/// Mezcla actual de [people]: «matrimonio» = su cónyuge está también en la lista.
OccupantMix occupantMixOf(Iterable<PersonRef> people) {
  final list = people.toList();
  if (list.isEmpty) return OccupantMix.none;
  final ids = {for (final p in list) p.id};
  final coupled = list.where((p) => p.spouseId != null && ids.contains(p.spouseId));
  if (coupled.isEmpty) return OccupantMix.singles;
  return coupled.length == list.length ? OccupantMix.couples : OccupantMix.mixed;
}

String lodgingAcceptsLabel(LodgingAccepts a) => switch (a) {
      LodgingAccepts.men => 'Solo hombres',
      LodgingAccepts.women => 'Solo mujeres',
      LodgingAccepts.couples => 'Matrimonios',
      LodgingAccepts.any => 'Sin preferencia',
      LodgingAccepts.menOrCouples => 'Solo hombres o matrimonios',
      LodgingAccepts.womenOrCouples => 'Solo mujeres o matrimonios',
    };

/// ¿Un hospedaje con esta preferencia sirve para matrimonios? («Sin preferencia» también.)
bool acceptsCouples(LodgingAccepts a) =>
    a == LodgingAccepts.couples || a == LodgingAccepts.any || isMixedLodging(a);

/// ¿Encaja una persona de sexo [sex] en un hospedaje con preferencia [a]? Un hospedaje de
/// matrimonios solo encaja si la persona tiene cónyuge ([hasSpouse]).
bool lodgingFitsPerson(LodgingAccepts a, Sex sex, {bool hasSpouse = false}) =>
    switch (a) {
      LodgingAccepts.any => true,
      LodgingAccepts.men => sex == Sex.male,
      LodgingAccepts.women => sex == Sex.female,
      LodgingAccepts.couples => hasSpouse,
      LodgingAccepts.menOrCouples => sex == Sex.male || hasSpouse,
      LodgingAccepts.womenOrCouples => sex == Sex.female || hasSpouse,
    };

/// Estado de un hospedaje para evaluar una asignación.
class LodgingSlot {
  const LodgingSlot(
      {required this.name,
      required this.accepts,
      required this.capacity,
      required this.occupied});
  final String name;
  final LodgingAccepts accepts;
  final int capacity;
  final int occupied;
  int get free => capacity - occupied;
}

/// Persona a asignar. [spouseId] es el cónyuge (si está vinculado).
class PersonRef {
  const PersonRef(
      {required this.id,
      required this.name,
      required this.sex,
      this.spouseId,
      this.churchId,
      this.spouseLodgingId});
  final String id;
  final String name;
  final Sex sex;
  final String? spouseId;

  /// Iglesia de la persona (para preferir hospedajes de su misma iglesia).
  final String? churchId;

  /// Si el cónyuge NO está en la selección pero ya tiene hospedaje, cuál es.
  final String? spouseLodgingId;
}

enum WarningKind { capacity, compatibility }

class AssignmentWarning {
  const AssignmentWarning(this.kind, this.message);
  final WarningKind kind;
  final String message;
}

/// Revisa una asignación de [people] a [lodging]. Devuelve la capacidad (aviso, el usuario decide)
/// y la compatibilidad (BLOQUEO: ver [lodgingBlockers]).
/// [alreadyThere] son quienes ya están en ese hospedaje (cuentan para la capacidad y para
/// completar matrimonios).
List<AssignmentWarning> checkLodgingAssignment(
    LodgingSlot lodging, List<PersonRef> people,
    {List<PersonRef> alreadyThere = const []}) {
  final out = <AssignmentWarning>[];
  if (people.isEmpty) return out;

  final after = lodging.occupied + people.length;
  if (after > lodging.capacity) {
    out.add(AssignmentWarning(
        WarningKind.capacity,
        'Capacidad: «${lodging.name}» quedaría con $after personas y solo tiene ${lodging.capacity} plazas '
        '(${lodging.free < 0 ? 0 : lodging.free} libres ahora).'));
  }
  out.addAll(lodgingBlockers(lodging, people, alreadyThere: alreadyThere));
  return out;
}

/// Incompatibilidades que IMPIDEN la asignación (sin excepciones): un hombre no entra en un
/// hospedaje de mujeres ni al revés; uno de matrimonios solo recibe a quien queda junto a su
/// cónyuge (en la selección o ya dentro); «Sin preferencia» acepta a todos. La única forma de
/// cambiar esto es editar el hospedaje (para quién es). Lista vacía = se puede asignar.
List<AssignmentWarning> lodgingBlockers(
    LodgingSlot lodging, List<PersonRef> people,
    {List<PersonRef> alreadyThere = const []}) {
  final out = <AssignmentWarning>[];
  if (people.isEmpty) return out;
  switch (lodging.accepts) {
    case LodgingAccepts.men:
      final wrong = people.where((p) => p.sex == Sex.female).toList();
      if (wrong.isNotEmpty) {
        out.add(AssignmentWarning(WarningKind.compatibility,
            '«${lodging.name}» solo acepta hombres y en la selección hay ${wrong.length} ${wrong.length == 1 ? 'mujer' : 'mujeres'}: ${_names(wrong)}.'));
      }
    case LodgingAccepts.women:
      final wrong = people.where((p) => p.sex == Sex.male).toList();
      if (wrong.isNotEmpty) {
        out.add(AssignmentWarning(WarningKind.compatibility,
            '«${lodging.name}» solo acepta mujeres y en la selección hay ${wrong.length} ${wrong.length == 1 ? 'hombre' : 'hombres'}: ${_names(wrong)}.'));
      }
    case LodgingAccepts.any:
      break;
    case LodgingAccepts.menOrCouples:
    case LodgingAccepts.womenOrCouples:
      final pref = mixedLodgingSex(lodging.accepts);
      final together = {
        ...people.map((p) => p.id),
        ...alreadyThere.map((p) => p.id)
      };
      bool coupled(PersonRef p) =>
          p.spouseId != null && together.contains(p.spouseId);
      final wrong = people.where((p) => p.sex != pref && !coupled(p)).toList();
      final who = pref == Sex.male ? 'hombres' : 'mujeres';
      if (wrong.isNotEmpty) {
        out.add(AssignmentWarning(WarningKind.compatibility,
            '«${lodging.name}» solo acepta $who o matrimonios y ${wrong.length == 1 ? 'hay 1 persona' : 'hay ${wrong.length} personas'} de otro sexo sin su cónyuge: ${_names(wrong)}.'));
        break;
      }
      final all = [...people, ...alreadyThere];
      if (all.any(coupled) && all.any((p) => !coupled(p))) {
        out.add(AssignmentWarning(WarningKind.compatibility,
            '«${lodging.name}» no mezcla matrimonios con personas solas: es para $who o para un matrimonio.'));
      }
    case LodgingAccepts.couples:
      final together = {
        ...people.map((p) => p.id),
        ...alreadyThere.map((p) => p.id)
      };
      final alone = people
          .where((p) => p.spouseId == null || !together.contains(p.spouseId))
          .toList();
      if (alone.isNotEmpty) {
        out.add(AssignmentWarning(WarningKind.compatibility,
            '«${lodging.name}» solo acepta matrimonios y ${alone.length == 1 ? 'queda 1 persona' : 'quedan ${alone.length} personas'} sin su cónyuge: ${_names(alone)}.'));
      }
  }
  return out;
}

String _names(List<PersonRef> l) =>
    l.take(4).map((p) => p.name).join(', ') + (l.length > 4 ? '…' : '');
