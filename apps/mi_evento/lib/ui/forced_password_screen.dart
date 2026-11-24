import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../auth/auth_service.dart';
import '../providers.dart';
import 'app_shell.dart' show signOut;
import 'auth_screens.dart' show ErrorBox, PasswordField;

/// Pantalla obligatoria: un usuario con contraseña temporal (p. ej. importado) debe elegir la
/// suya antes de usar la app.
class ForcedPasswordScreen extends ConsumerStatefulWidget {
  const ForcedPasswordScreen({super.key});
  @override
  ConsumerState<ForcedPasswordScreen> createState() =>
      _ForcedPasswordScreenState();
}

class _ForcedPasswordScreenState extends ConsumerState<ForcedPasswordScreen> {
  final cur = TextEditingController();
  final next = TextEditingController();
  String? error;

  @override
  void dispose() {
    cur.dispose();
    next.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final auth = ref.read(authServiceProvider);
    final me = ref.read(currentUserProvider)!;
    try {
      await auth.changeOwnPassword(me, cur.text, next.text);
      final fresh = await auth.userById(me.id);
      if (mounted) ref.read(currentUserProvider.notifier).state = fresh;
    } on AuthException catch (e) {
      setState(() => error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Elige tu contraseña')),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text(
                    'Entraste con una contraseña temporal. Para continuar, elige una contraseña propia.',
                    key: Key('fp-aviso'),
                    style: TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
                PasswordField(
                    key: const Key('fp-actual'),
                    controller: cur,
                    label: 'Contraseña temporal'),
                const SizedBox(height: 12),
                PasswordField(
                    key: const Key('fp-nueva'),
                    controller: next,
                    label: 'Contraseña nueva'),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  ErrorBox(error!)
                ],
                const SizedBox(height: 16),
                FilledButton(
                    key: const Key('fp-guardar'),
                    onPressed: _save,
                    child: const Text('Guardar y continuar')),
                TextButton(
                    key: const Key('fp-salir'),
                    onPressed: () => signOut(ref),
                    child: const Text('Salir')),
              ]),
            ),
          ),
        ),
      );
}
