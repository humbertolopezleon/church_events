enum Sex { male, female }

/// Datos mínimos de un asistente para las reglas de dominio.
class Attendee {
  const Attendee({
    required this.id,
    required this.firstName,
    required this.lastName1,
    this.lastName2 = '',
    required this.sex,
    required this.age,
    this.churchId,
    this.teamId,
  });

  final String id;
  final String firstName;
  final String lastName1;
  final String lastName2;
  final Sex sex;
  final int age;
  final String? churchId;
  final String? teamId;

  String get fullName => [firstName, lastName1, lastName2]
      .where((e) => e.trim().isNotEmpty)
      .join(' ');
}
