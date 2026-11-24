/// Rango de edad configurable por evento (según los departamentos de la iglesia).
class AgeRange {
  const AgeRange(this.label, this.minAge, [this.maxAge]);
  final String label;
  final int minAge;

  /// `null` = sin tope superior.
  final int? maxAge;

  bool contains(int age) => age >= minAge && (maxAge == null || age <= maxAge!);

  /// Valores por defecto hasta que el usuario defina los del evento.
  static const defaults = [
    AgeRange('0–11', 0, 11),
    AgeRange('12–17', 12, 17),
    AgeRange('18–25', 18, 25),
    AgeRange('26–40', 26, 40),
    AgeRange('41+', 41),
  ];

  /// Rango al que pertenece [age], o `null` si no cae en ninguno.
  static AgeRange? of(int age, List<AgeRange> ranges) {
    for (final r in ranges) {
      if (r.contains(age)) return r;
    }
    return null;
  }

  /// Valida que los rangos no se solapen ni tengan límites invertidos.
  /// Devuelve mensajes de error en español (vacío = válido).
  static List<String> validate(List<AgeRange> ranges) {
    final errors = <String>[];
    for (final r in ranges) {
      if (r.maxAge != null && r.maxAge! < r.minAge) {
        errors
            .add('El rango «${r.label}» tiene el máximo menor que el mínimo.');
      }
    }
    final sorted = [...ranges]..sort((a, b) => a.minAge.compareTo(b.minAge));
    for (var i = 1; i < sorted.length; i++) {
      final prev = sorted[i - 1];
      if (prev.maxAge == null || prev.maxAge! >= sorted[i].minAge) {
        errors.add(
            'Los rangos «${prev.label}» y «${sorted[i].label}» se solapan.');
      }
    }
    return errors;
  }
}
