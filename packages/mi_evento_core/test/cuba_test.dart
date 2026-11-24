import 'package:mi_evento_core/mi_evento_core.dart';
import 'package:test/test.dart';

void main() {
  test('todas las provincias tienen municipios y el total es 168', () {
    for (final p in cubaProvinces) {
      expect(suggestedMunicipalities(p), isNotEmpty, reason: p);
    }
    final total = cubaProvinces.fold<int>(
        0, (n, p) => n + suggestedMunicipalities(p).length);
    expect(total, 168);
    expect(suggestedMunicipalities('Narnia'), isEmpty);
  });

  test(
      'LodgingAccepts.any (sin preferencia) no genera avisos de compatibilidad',
      () {
    const slot = LodgingSlot(
        name: 'Casa', accepts: LodgingAccepts.any, capacity: 4, occupied: 0);
    final w = checkLodgingAssignment(slot, const [
      PersonRef(id: 'a', name: 'Ana', sex: Sex.female),
      PersonRef(id: 'b', name: 'Beto', sex: Sex.male),
    ]);
    expect(w, isEmpty);
    expect(lodgingAcceptsFromDb('any'), LodgingAccepts.any);
  });
}
