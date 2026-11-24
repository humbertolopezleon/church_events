import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// Logotipo de Mi Evento: dos círculos que se tocan (personas que se encuentran) sobre una base.
/// Es el único elemento «de marca»: aparece en el acceso, la barra lateral y los íconos de la app.
/// Mismas proporciones que el SVG del diseño aprobado (cuadrícula de 72).
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 72, this.rounded = true});
  final double size;
  final bool rounded;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Logotipo de Mi Evento',
        image: true,
        child: SizedBox(
            width: size,
            height: size,
            child: CustomPaint(painter: _LogoPainter(rounded))),
      );
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter(this.rounded);
  final bool rounded;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 72;
    final bg = Paint()..color = Brand.azul;
    if (rounded) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(20 * u)),
          bg);
    } else {
      canvas.drawRect(Offset.zero & size, bg);
    }
    Paint stroke(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5 * u
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(28 * u, 32 * u), 11 * u, stroke(Colors.white));
    canvas.drawCircle(Offset(44 * u, 32 * u), 11 * u, stroke(Brand.naranja));
    canvas.drawLine(
        Offset(20 * u, 54 * u), Offset(52 * u, 54 * u), stroke(Colors.white));
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.rounded != rounded;
}
