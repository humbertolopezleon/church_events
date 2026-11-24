import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../auth/auth_service.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import 'brand_logo.dart';

/// Marco de las pantallas de acceso. En PC: panel azul con la marca a la izquierda y el formulario a
/// la derecha. En móvil: la marca arriba, compacta, y el formulario debajo.
class _AuthFrame extends StatelessWidget {
  const _AuthFrame(
      {required this.title, required this.children, this.subtitle});
  final String title;
  final String? subtitle;
  final List<Widget> children;

  Widget _form({required bool showBrand}) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showBrand) ...[
                    const Center(child: BrandLogo(size: 64)),
                    const SizedBox(height: 10),
                    Text('Mi Evento',
                        textAlign: TextAlign.center, style: headStyle(30)),
                    const SizedBox(height: 24),
                  ],
                  Text(title, style: headStyle(24)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(subtitle!,
                        style:
                            const TextStyle(fontSize: 16, color: Brand.gris)),
                  ],
                  const SizedBox(height: 20),
                  ...children,
                ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    if (!wide) return Scaffold(body: SafeArea(child: _form(showBrand: true)));
    return Scaffold(
      body: Row(children: [
        Expanded(
          flex: 5,
          child: Container(
            color: Brand.azul,
            padding: const EdgeInsets.all(48),
            // Centrado, pero se desplaza si la ventana es baja (antes desbordaba 42 px).
            child: Center(
                child: SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                  const BrandLogo(size: 104),
                  const SizedBox(height: 28),
                  Text('Mi Evento', style: headStyle(52, color: Colors.white)),
                  const SizedBox(height: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: const Text(
                        'Registro de asistentes para eventos de iglesia, sin necesidad de internet.',
                        style: TextStyle(
                            fontSize: 20, height: 1.4, color: Colors.white)),
                  ),
                ]))),
          ),
        ),
        Expanded(flex: 6, child: SafeArea(child: _form(showBrand: false))),
      ]),
    );
  }
}

class ErrorBox extends StatelessWidget {
  const ErrorBox(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: const Color(0xFFFCE8E6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Brand.error, width: 2)),
        child: Row(children: [
          const Icon(Icons.error_outline, color: Brand.error),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ]),
      );
}

class PasswordField extends StatefulWidget {
  const PasswordField(
      {super.key,
      required this.controller,
      required this.label,
      this.onSubmitted});
  final TextEditingController controller;
  final String label;
  final VoidCallback? onSubmitted;
  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool hide = true;
  @override
  Widget build(BuildContext context) => TextField(
        controller: widget.controller,
        obscureText: hide,
        enableSuggestions: false,
        autocorrect: false,
        onSubmitted: (_) => widget.onSubmitted?.call(),
        decoration: InputDecoration(
          labelText: widget.label,
          suffixIcon: IconButton(
            tooltip: hide ? 'Mostrar contraseña' : 'Ocultar contraseña',
            icon: Icon(hide
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined),
            onPressed: () => setState(() => hide = !hide),
          ),
        ),
      );
}

/// Primer uso: crear el administrador.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});
  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final name = TextEditingController();
  final user = TextEditingController();
  final pass = TextEditingController();
  final pass2 = TextEditingController();
  String? error;
  String? recoveryCode;
  bool saved = false;
  bool busy = false;

  Future<void> _create() async {
    if (pass.text != pass2.text) {
      setState(() => error = 'Las contraseñas no coinciden.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final code = await ref.read(authServiceProvider).createFirstAdmin(
          username: user.text, displayName: name.text, password: pass.text);
      if (mounted) setState(() => recoveryCode = code);
    } on AuthException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (e) {
      if (mounted) {
        setState(() =>
            error = 'No se pudo crear el administrador. Detalle técnico: $e');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _continue() async {
    try {
      final r = await ref.read(authServiceProvider).login(user.text, pass.text);
      if (r.ok) {
        ref.read(currentUserProvider.notifier).state = r.user;
      } else if (mounted) {
        setState(() => error =
            'No se pudo iniciar sesión con el administrador recién creado.');
      }
    } catch (e) {
      if (mounted) {
        setState(
            () => error = 'No se pudo iniciar sesión. Detalle técnico: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (recoveryCode != null) {
      return _AuthFrame(
        title: 'Guarda tu código de recuperación',
        subtitle:
            'Si olvidas tu contraseña, este código es la única forma de entrar de nuevo. Se muestra una sola vez.',
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: Brand.avisoSuave,
                border: Border.all(color: Brand.aviso, width: 2),
                borderRadius: BorderRadius.circular(14)),
            child: SelectableText(recoveryCode!,
                key: const Key('codigo-recuperacion'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: recoveryCode!));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Código copiado.')));
              }
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copiar código'),
          ),
          const SizedBox(height: 4),
          const Text(
              'Anótalo en papel y guárdalo en un lugar seguro. No lo compartas por WhatsApp.',
              style: TextStyle(color: Brand.gris)),
          CheckboxListTile(
            key: const Key('codigo-guardado'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: saved,
            onChanged: (v) => setState(() => saved = v ?? false),
            title: const Text('Ya lo guardé en un lugar seguro'),
          ),
          FilledButton(
              key: const Key('setup-continuar'),
              onPressed: saved ? _continue : null,
              child: const Text('Continuar')),
        ],
      );
    }
    return _AuthFrame(
      title: 'Crea el administrador',
      subtitle:
          'Es la primera vez que se abre la app en este dispositivo. El administrador crea a los demás usuarios.',
      children: [
        TextField(
            key: const Key('setup-nombre'),
            controller: name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Tu nombre')),
        const SizedBox(height: 12),
        TextField(
            key: const Key('setup-usuario'),
            controller: user,
            autocorrect: false,
            decoration: const InputDecoration(
                labelText: 'Usuario',
                helperText: 'Sin espacios ni tildes. Ej.: ana.perez')),
        const SizedBox(height: 12),
        PasswordField(
            key: const Key('setup-clave'),
            controller: pass,
            label: 'Contraseña (mínimo 6 caracteres)'),
        const SizedBox(height: 12),
        PasswordField(
            key: const Key('setup-clave2'),
            controller: pass2,
            label: 'Repite la contraseña',
            onSubmitted: _create),
        if (error != null) ...[const SizedBox(height: 12), ErrorBox(error!)],
        const SizedBox(height: 16),
        FilledButton(
            key: const Key('setup-crear'),
            onPressed: busy ? null : _create,
            child: Text(busy ? 'Creando…' : 'Crear administrador')),
      ],
    );
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final user = TextEditingController();
  final pass = TextEditingController();
  String? error;
  bool busy = false;

  Future<void> _login() async {
    setState(() {
      busy = true;
      error = null;
    });
    LoginResult r;
    try {
      r = await ref.read(authServiceProvider).login(user.text, pass.text);
    } catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = 'No se pudo iniciar sesión. Detalle técnico: $e';
        });
      }
      return;
    }
    if (!mounted) return;
    if (r.ok) {
      ref.read(currentUserProvider.notifier).state = r.user;
      return;
    }
    setState(() {
      busy = false;
      pass.clear();
      error = switch (r.failure!) {
        LoginFailure.invalid => 'Usuario o contraseña incorrectos.',
        LoginFailure.inactive =>
          'Este usuario está desactivado. Habla con el administrador.',
        LoginFailure.locked =>
          'Demasiados intentos. Espera ${_fmt(r.wait!)} e inténtalo de nuevo.',
      };
    });
  }

  String _fmt(Duration d) => d.inSeconds < 90
      ? '${d.inSeconds} s'
      : '${(d.inSeconds / 60).ceil()} min';

  @override
  Widget build(BuildContext context) => _AuthFrame(
        title: 'Iniciar sesión',
        children: [
          if (ref.watch(defaultPasswordInUseProvider).valueOrNull ?? false) ...[
            Container(
              key: const Key('login-pista-inicial'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Brand.azulSuave,
                  borderRadius: BorderRadius.circular(12)),
              child: const Text(
                  'Primer uso: entra con el usuario «admin» y la contraseña «admin». Después te pediremos que la cambies.',
                  style: TextStyle(color: Brand.tinta)),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
              key: const Key('login-usuario'),
              controller: user,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Usuario')),
          const SizedBox(height: 12),
          PasswordField(
              key: const Key('login-clave'),
              controller: pass,
              label: 'Contraseña',
              onSubmitted: _login),
          if (error != null) ...[const SizedBox(height: 12), ErrorBox(error!)],
          const SizedBox(height: 16),
          FilledButton(
              key: const Key('login-entrar'),
              onPressed: busy ? null : _login,
              child: Text(busy ? 'Entrando…' : 'Entrar')),
          TextButton(
            key: const Key('login-olvide'),
            onPressed: () => showDialog<void>(
                context: context, builder: (_) => const RecoverDialog()),
            child: const Text('Olvidé mi contraseña'),
          ),
        ],
      );
}

class RecoverDialog extends ConsumerStatefulWidget {
  const RecoverDialog({super.key});
  @override
  ConsumerState<RecoverDialog> createState() => _RecoverDialogState();
}

class _RecoverDialogState extends ConsumerState<RecoverDialog> {
  final code = TextEditingController();
  final pass = TextEditingController();
  String? error;
  ({String newCode, String username})? done;

  Future<void> _recover() async {
    try {
      final r = await ref
          .read(authServiceProvider)
          .recoverAdmin(code.text, pass.text);
      if (mounted) setState(() => done = r);
    } on AuthException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => error = 'No se pudo restablecer. Detalle técnico: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (done != null) {
      return AlertDialog(
        title: const Text('Contraseña restablecida'),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Ya puedes entrar como «${done!.username}» con la contraseña nueva.'),
              const SizedBox(height: 12),
              const Text(
                  'Tu código de recuperación anterior dejó de servir. Guarda el nuevo:',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              SelectableText(done!.newCode,
                  key: const Key('codigo-nuevo'),
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5)),
            ]),
        actions: [
          FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Listo'))
        ],
      );
    }
    return AlertDialog(
      title: const Text('Olvidé mi contraseña'),
      content: SingleChildScrollView(
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Administrador: escribe el código de recuperación que recibiste al crear la cuenta y elige una contraseña nueva.\n\nOperador: pide al administrador que restablezca tu contraseña.'),
              const SizedBox(height: 12),
              TextField(
                  key: const Key('rec-codigo'),
                  controller: code,
                  autocorrect: false,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                      labelText: 'Código de recuperación')),
              const SizedBox(height: 12),
              PasswordField(
                  key: const Key('rec-clave'),
                  controller: pass,
                  label: 'Contraseña nueva'),
              if (error != null) ...[
                const SizedBox(height: 12),
                ErrorBox(error!)
              ],
            ]),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(
            key: const Key('rec-aceptar'),
            onPressed: _recover,
            child: const Text('Restablecer')),
      ],
    );
  }
}
