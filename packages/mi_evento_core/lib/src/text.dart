const _map = {
  'á': 'a',
  'à': 'a',
  'ä': 'a',
  'â': 'a',
  'é': 'e',
  'è': 'e',
  'ë': 'e',
  'ê': 'e',
  'í': 'i',
  'ì': 'i',
  'ï': 'i',
  'î': 'i',
  'ó': 'o',
  'ò': 'o',
  'ö': 'o',
  'ô': 'o',
  'ú': 'u',
  'ù': 'u',
  'ü': 'u',
  'û': 'u',
  'ñ': 'n',
  'ã': 'a',
  'å': 'a',
  'ā': 'a',
  'õ': 'o',
  'ø': 'o',
  'ō': 'o',
  'ç': 'c',
  'ć': 'c',
  'č': 'c',
  'ł': 'l',
  'ś': 's',
  'š': 's',
  'ß': 'ss',
  'ž': 'z',
  'ź': 'z',
  'ý': 'y',
  'ÿ': 'y',
  'ē': 'e',
  'ī': 'i',
  'ū': 'u',
  'æ': 'ae',
  'œ': 'oe',
};

/// Minúsculas, sin tildes ni signos, espacios colapsados. Base de búsquedas,
/// claves de duplicado y catálogo de iglesias.
String normalizeText(String s) {
  // Los apóstrofes se quitan (no separan): «O'Farrill» y «OFarrill» son lo mismo.
  final lower = s.toLowerCase().replaceAll(RegExp("['’ʼ`´]"), '');
  final sb = StringBuffer();
  for (final r in lower.runes) {
    final c = String.fromCharCode(r);
    sb.write(_map[c] ?? c);
  }
  return sb
      .toString()
      .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
