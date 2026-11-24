import 'models.dart';

/// A quién acepta un hospedaje.
/// `any` = sin preferencia: acepta hombres, mujeres y matrimonios.
enum LodgingAccepts { men, women, couples, any }

LodgingAccepts lodgingAcceptsFromDb(String s) => switch (s) {
      'men' => LodgingAccepts.men,
      'women' => LodgingAccepts.women,
      'any' => LodgingAccepts.any,
      _ => LodgingAccepts.couples,
    };

String lodgingAcceptsToDb(LodgingAccepts a) => a.name;

String lodgingAcceptsLabel(LodgingAccepts a) => switch (a) {
      LodgingAccepts.men => 'Solo hombres',
      LodgingAccepts.women => 'Solo mujeres',
      LodgingAccepts.couples => 'Matrimonios',
      LodgingAccepts.any => 'Sin preferencia',
    };

/// ¿Un hospedaje con esta preferencia sirve para matrimonios? («Sin preferencia» también.)
bool acceptsCouples(LodgingAccepts a) =>
    a == LodgingAccepts.couples || a == LodgingAccepts.any;

/// ¿Encaja una persona de sexo [sex] en un hospedaje con preferencia [a]? Un hospedaje de
/// matrimonios solo encaja si la persona tiene cónyuge ([hasSpouse]).
bool lodgingFitsPerson(LodgingAccepts a, Sex sex, {bool hasSpouse = false}) =>
    switch (a) {
      LodgingAccepts.any => true,
      LodgingAccepts.men => sex == Sex.male,
      LodgingAccepts.women => sex == Sex.female,
      LodgingAccepts.couples => hasSpouse,
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

/// Revisa una asignación MANUAL de [people] a [lodging]. Devuelve avisos, nunca bloquea:
/// la decisión final es del usuario (que puede continuar de todas formas).
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
