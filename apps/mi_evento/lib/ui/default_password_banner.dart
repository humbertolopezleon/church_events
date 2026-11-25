import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../auth/auth_service.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import 'users_screen.dart' show ChangePasswordDialog;

/// ¿Está oculto el aviso hoy? («Recordar más tarde» lo oculta hasta el día siguiente.)
bool passwordReminderHiddenToday(DateTime? hiddenAt, DateTime now) {
  if (hiddenAt == null) return false;
  final a = hiddenAt.toLocal(), b = now.toLocal();
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Aviso de una línea (48 dp) mientras el administrador inicial siga con la contraseña `admin`.
/// La X lo oculta hasta el día siguiente; desaparece del todo al cambiar la contraseña.
class DefaultPasswordBanner extends ConsumerWidget {
  const DefaultPasswordBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    final inUse = me?.username == AuthService.defaultAdminUser &&
        (ref.watch(defaultPasswordInUseProvider).valueOrNull ?? false);
    final hiddenAt =
        ref.watch(appMetaProvider).valueOrNull?.passwordReminderHiddenAt;
    if (!inUse || passwordReminderHiddenToday(hiddenAt, DateTime.now())) {
      return const SizedBox.shrink();
    }
    return Material(
      color: Brand.avisoSuave,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 48,
          padding: const EdgeInsets.only(left: 16, right: 4),
          decoration: const BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: Brand.aviso, width: 1.5))),
          child: Row(children: [
            const Icon(Icons.warning_amber_rounded,
                color: Brand.avisoTexto, size: 22),
            const SizedBox(width: 10),
            Expanded(
                child: Text('Contraseña inicial en uso',
                    key: const Key('banner-clave-inicial'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: bodyStyle(15,
                        color: Brand.avisoTexto, weight: FontWeight.w700))),
            TextButton(
                key: const Key('banner-cambiar'),
                style: TextButton.styleFrom(
                    foregroundColor: Brand.avisoTexto,
                    minimumSize: const Size(44, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 12)),
                onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const ChangePasswordDialog()),
                child: Text('Cambiar',
                    style: bodyStyle(15,
                        color: Brand.avisoTexto, weight: FontWeight.w700))),
            IconButton(
                key: const Key('banner-recordar-despues'),
                tooltip: 'Recordar más tarde',
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                color: Brand.avisoTexto,
                icon: const Icon(Icons.close,
                    semanticLabel: 'Recordar más tarde'),
                onPressed: () =>
                    ref.read(repositoryProvider).snoozePasswordReminder()),
          ]),
        ),
      ),
    );
  }
}
