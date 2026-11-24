import 'dart:ui' show PathMetric;

import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// Tarjeta de PROPUESTA: borde discontinuo y etiqueta, para que nadie la confunda con un
/// dato ya guardado. Las sugerencias automáticas nunca se aplican solas.
class ProposalCard extends StatelessWidget {
  const ProposalCard(
      {super.key, required this.child, this.label = 'PROPUESTA'});
  final Widget child;
  final String label;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedBorder(Brand.naranja),
      child: Container(
        decoration: BoxDecoration(
            color: Brand.naranjaSuave, borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
                color: Brand.naranja, borderRadius: BorderRadius.circular(20)),
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.8)),
          ),
          const SizedBox(height: 10),
          child,
        ]),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  _DashedBorder(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, const Radius.circular(16)));
    for (final PathMetric m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 8), paint);
        d += 14;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}
