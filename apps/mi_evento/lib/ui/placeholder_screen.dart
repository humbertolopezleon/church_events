import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen(this.title, this.phase, {super.key});
  final String title;
  final String phase;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Esta pantalla se construye en la $phase.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Brand.gris)),
          ),
        ),
      );
}
