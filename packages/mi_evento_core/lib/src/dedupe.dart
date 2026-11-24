import 'models.dart';
import 'text.dart';

/// Clave de duplicado: nombre + primer apellido normalizados.
String dedupeKey(String firstName, String lastName1) =>
    '${normalizeText(firstName)}|${normalizeText(lastName1)}';

/// Posibles duplicados de un candidato entre los ya registrados.
/// Coincide nombre y primer apellido; si se conoce la edad, debe diferir ≤ [ageTolerance].
/// Es un AVISO: la decisión final es del usuario.
List<Attendee> findDuplicates(
  List<Attendee> existing, {
  required String firstName,
  required String lastName1,
  int? age,
  int ageTolerance = 0,
}) {
  final key = dedupeKey(firstName, lastName1);
  if (normalizeText(firstName).isEmpty || normalizeText(lastName1).isEmpty) {
    return const [];
  }
  return existing.where((a) {
    if (dedupeKey(a.firstName, a.lastName1) != key) return false;
    if (age == null || age <= 0) return true;
    return (a.age - age).abs() <= ageTolerance;
  }).toList();
}
