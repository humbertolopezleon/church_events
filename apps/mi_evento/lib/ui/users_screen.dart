import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../auth/auth_service.dart';
import '../data/database.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import 'auth_screens.dart';

/// Administración de usuarios (solo administrador).
class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authServiceProvider);
    final me = ref.watch(currentUserProvider)!;
    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('usuario-nuevo'),
        onPressed: () => showDialog<void>(
            context: context, builder: (_) => _UserDialog(actor: me)),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Nuevo usuario'),
      ),
      body: StreamBuilder<List<AppUser>>(
        stream: auth.watchUsers(),
        builder: (context, snap) {
          final list = snap.data ?? const <AppUser>[];
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final u = list[i];
              return Card(
                child: ListTile(
                  minVerticalPadding: 12,
                  leading: CircleAvatar(
                      backgroundColor: Brand.naranjaSuave,
                      child:
                          Text(u.displayName.characters.first.toUpperCase())),
                  title: Text(u.displayName + (u.id == me.id ? ' (tú)' : ''),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                      '@${u.username} · ${u.roleLabel}${u.active ? '' : ' · desactivado'}'),
                  trailing: PopupMenuButton<String>(
                    tooltip: 'Acciones',
                    onSelected: (a) => _action(context, ref, me, u, a),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'reset',
                          child: Text('Restablecer contraseña')),
                      PopupMenuItem(
                          value: 'active',
                          child: Text(u.active ? 'Desactivar' : 'Activar')),
                      PopupMenuItem(
                          value: 'role',
                          child: Text(u.isAdmin
                              ? 'Cambiar a operador'
                              : 'Hacer administrador')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _action(BuildContext context, WidgetRef ref, AppUser me,
      AppUser u, String a) async {
    final auth = ref.read(authServiceProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      switch (a) {
        case 'reset':
          final pw = await showDialog<String>(
              context: context, builder: (_) => _NewPasswordDialog(user: u));
          if (pw != null) {
            await auth.resetPassword(me, u.id, pw);
            messenger.showSnackBar(SnackBar(
                content: Text('Contraseña de ${u.displayName} restablecida.')));
          }
        case 'active':
          await auth.setActive(me, u.id, !u.active);
        case 'role':
          await auth.setAdmin(me, u.id, !u.isAdmin);
      }
    } on AuthException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

class _UserDialog extends ConsumerStatefulWidget {
  const _UserDialog({required this.actor});
  final AppUser actor;
  @override
  ConsumerState<_UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends ConsumerState<_UserDialog> {
  final name = TextEditingController();
  final user = TextEditingController();
  final pass = TextEditingController();
  bool admin = false;
  String? error;

  Future<void> _save() async {
    try {
      await ref.read(authServiceProvider).createUser(widget.actor,
          username: user.text,
          displayName: name.text,
          password: pass.text,
          admin: admin);
      if (mounted) Navigator.pop(context);
    } on AuthException catch (e) {
      setState(() => error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Nuevo usuario'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 420,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  key: const Key('nu-nombre'),
                  controller: name,
                  textCapitalization: TextCapitalization.words,
                  decoration:
                      const InputDecoration(labelText: 'Nombre de la persona')),
              const SizedBox(height: 12),
              TextField(
                  key: const Key('nu-usuario'),
                  controller: user,
                  autocorrect: false,
                  decoration: const InputDecoration(labelText: 'Usuario')),
              const SizedBox(height: 12),
              PasswordField(
                  key: const Key('nu-clave'),
                  controller: pass,
                  label: 'Contraseña inicial'),
              SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Es administrador'),
                  subtitle: const Text('Puede crear usuarios y borrar datos'),
                  value: admin,
                  onChanged: (v) => setState(() => admin = v)),
              if (error != null) ErrorBox(error!),
            ]),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              key: const Key('nu-guardar'),
              onPressed: _save,
              child: const Text('Crear usuario')),
        ],
      );
}

class _NewPasswordDialog extends StatelessWidget {
  _NewPasswordDialog({required this.user});
  final AppUser user;
  final pass = TextEditingController();
  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('Nueva contraseña para ${user.displayName}'),
        content: PasswordField(controller: pass, label: 'Contraseña nueva'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, pass.text),
              child: const Text('Guardar')),
        ],
      );
}

/// Cambiar mi propia contraseña.
class ChangePasswordDialog extends ConsumerStatefulWidget {
  const ChangePasswordDialog({super.key});
  @override
  ConsumerState<ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<ChangePasswordDialog> {
  final cur = TextEditingController();
  final next = TextEditingController();
  String? error;

  Future<void> _save() async {
    try {
      await ref.read(authServiceProvider).changeOwnPassword(
          ref.read(currentUserProvider)!, cur.text, next.text);
      ref.invalidate(defaultPasswordInUseProvider);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Contraseña cambiada.')));
    } on AuthException catch (e) {
      setState(() => error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Cambiar mi contraseña'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 420,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              PasswordField(
                  key: const Key('cp-actual'),
                  controller: cur,
                  label: 'Contraseña actual'),
              const SizedBox(height: 12),
              PasswordField(
                  key: const Key('cp-nueva'),
                  controller: next,
                  label: 'Contraseña nueva'),
              if (error != null) ...[
                const SizedBox(height: 12),
                ErrorBox(error!)
              ],
            ]),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
              key: const Key('cp-guardar'),
              onPressed: _save,
              child: const Text('Cambiar')),
        ],
      );
}
