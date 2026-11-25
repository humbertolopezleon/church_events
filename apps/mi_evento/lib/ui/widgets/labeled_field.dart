import 'package:material_ui/material_ui.dart';

import '../../theme/app_theme.dart';

/// Campo con la etiqueta SIEMPRE encima (nunca como etiqueta flotante dentro del borde).
/// «(opcional)» va en la etiqueta, en texto normal y color secundario.
class LabeledField extends StatelessWidget {
  const LabeledField(
      {super.key,
      required this.label,
      required this.child,
      this.optional = false,
      this.helper,
      this.error});
  final String label;
  final bool optional;
  final String? helper;
  final String? error;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text.rich(TextSpan(children: [
          TextSpan(text: label, style: bodyStyle(16, weight: FontWeight.w700)),
          if (optional)
            TextSpan(
                text: ' (opcional)', style: bodyStyle(16, color: Brand.gris)),
        ])),
        const SizedBox(height: 6),
        child,
        if (error != null)
          Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(error!,
                  style: bodyStyle(15, color: Brand.error),
                  semanticsLabel: 'Error: $error'))
        else if (helper != null)
          Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(helper!, style: bodyStyle(15, color: Brand.gris))),
      ]);
}
