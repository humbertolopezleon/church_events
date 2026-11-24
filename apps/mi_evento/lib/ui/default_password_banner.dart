import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../auth/auth_service.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import 'users_screen.dart' show ChangePasswordDialog;

/// Aviso fijo mientras el administrador inicial siga con la contraseña `admin`.
class DefaultPasswordBanner extends ConsumerWidget {
  const DefaultPasswordBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    final inUse = me?.username == AuthService.defaultAdminUser &&
        (ref.watch(defaultPasswordInUseProvider).valueOrNull ?? false);
    if (!inUse) return const SizedBox.shrink();
    return Material(
      color: Brand.avisoSuave,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            const Icon(Icons.warning_amber_rounded, color: Brand.avisoTexto),
            const SizedBox(width: 10),
            const Expanded(
                child: Text(
                    'Sigues con la contraseña inicial (admin). Cámbiala para proteger los datos.',
                    key: Key('banner-clave-inicial'),
                    style: TextStyle(color: Brand.avisoTexto))),
            TextButton(
                key: const Key('banner-cambiar'),
                onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const ChangePasswordDialog()),
                child: const Text('Cambiar ahora')),
          ]),
        ),
      ),
    );
  }
}
