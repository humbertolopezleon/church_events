import 'package:material_ui/material_ui.dart';
import 'package:mi_evento_core/mi_evento_core.dart' show normalizeText;

import '../../theme/app_theme.dart';

/// Texto con las coincidencias de [query] resaltadas (sin distinguir tildes ni mayúsculas, igual
/// que la búsqueda). Sin búsqueda, o sin coincidencias, es un [Text] normal.
class HighlightText extends StatelessWidget {
  const HighlightText(this.text, this.query,
      {super.key, this.style, this.maxLines, this.overflow});
  final String text;
  final String query;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  /// Rangos [inicio, fin) de [text] que coinciden con alguna palabra de [query].
  static List<(int, int)> ranges(String text, String query) {
    final words = normalizeText(query).split(' ').where((w) => w.isNotEmpty);
    if (words.isEmpty || text.isEmpty) return const [];
    // Normaliza letra a letra para que las posiciones coincidan con el texto original.
    final hay = StringBuffer();
    for (final ch in text.split('')) {
      final n = normalizeText(ch);
      hay.write(n.length == ch.length ? n : ch.toLowerCase());
    }
    final h = hay.toString();
    if (h.length != text.length) return const [];
    final found = <(int, int)>[];
    for (final w in words) {
      var from = 0;
      while (true) {
        final i = h.indexOf(w, from);
        if (i < 0) break;
        found.add((i, i + w.length));
        from = i + w.length;
      }
    }
    found.sort((a, b) => a.$1.compareTo(b.$1));
    final merged = <(int, int)>[];
    for (final r in found) {
      if (merged.isNotEmpty && r.$1 <= merged.last.$2) {
        merged[merged.length - 1] =
            (merged.last.$1, r.$2 > merged.last.$2 ? r.$2 : merged.last.$2);
      } else {
        merged.add(r);
      }
    }
    return merged;
  }

  @override
  Widget build(BuildContext context) {
    final rs = ranges(text, query);
    if (rs.isEmpty) {
      return Text(text, style: style, maxLines: maxLines, overflow: overflow);
    }
    final spans = <TextSpan>[];
    var pos = 0;
    for (final (a, b) in rs) {
      if (a > pos) spans.add(TextSpan(text: text.substring(pos, a)));
      spans.add(TextSpan(
          text: text.substring(a, b),
          style: const TextStyle(
              backgroundColor: Brand.naranjaSuave,
              fontWeight: FontWeight.w900)));
      pos = b;
    }
    if (pos < text.length) spans.add(TextSpan(text: text.substring(pos)));
    return Text.rich(TextSpan(style: style, children: spans),
        maxLines: maxLines, overflow: overflow);
  }
}
