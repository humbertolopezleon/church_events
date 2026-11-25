import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../auth/auth_service.dart';
import '../data/database.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import 'backup_screen.dart';
import 'reports_screen.dart';
import 'attendance_screen.dart';
import 'attendees_screen.dart';
import 'auth_screens.dart';
import 'brand_logo.dart';
import 'churches_screen.dart';
import 'default_password_banner.dart';
import 'event_setup.dart';
import 'forced_password_screen.dart';
import 'events_screen.dart';
import 'lodgings_screen.dart';
import 'meals_screen.dart';
import 'panel_screen.dart';
import 'teams_screen.dart';
import 'notifications.dart';
import 'shortcuts.dart';
import 'users_screen.dart';

class Destination {
  const Destination(this.id, this.label, this.icon, this.builder,
      {this.adminOnly = false});
  final String id;
  final String label;
  final IconData icon;
  final WidgetBuilder builder;
  final bool adminOnly;
}

final allDestinations = <Destination>[
  Destination(
      'panel', 'Panel', Icons.home_outlined, (_) => const PanelScreen()),
  Destination('asistentes', 'Asistentes', Icons.list_alt_outlined,
      (_) => const AttendeesScreen()),
  Destination('asistencia', 'Confirmar asistencia', Icons.how_to_reg_outlined,
      (_) => const AttendanceScreen()),
  Destination('hospedajes', 'Hospedajes', Icons.house_outlined,
      (_) => const LodgingsScreen()),
  Destination(
      'equipos', 'Equipos', Icons.groups_outlined, (_) => const TeamsScreen()),
  Destination('comidas', 'Comidas', Icons.restaurant_outlined,
      (_) => const MealsScreen()),
  Destination('reportes', 'Reportes', Icons.bar_chart_outlined,
      (_) => const ReportsScreen()),
  Destination('configuracion', 'Configuración', Icons.settings_outlined,
      (_) => const EventConfigScreen(),
      adminOnly: true),
  Destination('respaldo', 'Copias de seguridad', Icons.backup_outlined,
      (_) => const BackupScreen(),
      adminOnly: true),
  Destination('iglesias', 'Iglesias', Icons.church_outlined,
      (_) => const ChurchesScreen(),
      adminOnly: true),
  Destination('usuarios', 'Usuarios', Icons.manage_accounts_outlined,
      (_) => const UsersScreen(),
      adminOnly: true),
];

/// En móvil se muestran 4 destinos principales + «Más»; en PC, barra lateral con todos.
const mobileMainIds = ['panel', 'asistentes', 'comidas', 'equipos'];

/// Estado de la app: sin usuarios → configuración; sin sesión → login; sin evento → «Mis eventos».
class AppRoot extends ConsumerStatefulWidget {
  const AppRoot({super.key});
  @override
  ConsumerState<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends ConsumerState<AppRoot> {
  bool? hasUsers;

  @override
  void initState() {
    super.initState();
    ref.read(authServiceProvider).hasUsers().then((v) {
      if (mounted) setState(() => hasUsers = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final eventId = ref.watch(currentEventIdProvider);
    if (user != null) {
      if (user.mustChangePassword) return const ForcedPasswordScreen();
      return eventId == null ? const EventsScreen() : const AppShell();
    }
    if (hasUsers == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return hasUsers! ? const LoginScreen() : const SetupScreen();
  }
}

void signOut(WidgetRef ref) {
  NotificationCenter.instance.clear();
  ref.read(currentPageProvider.notifier).state = 'panel';
  ref.read(currentEventIdProvider.notifier).state = null;
  ref.read(currentUserProvider.notifier).state = null;
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});
  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  Widget build(BuildContext context) {
    final current = ref.watch(currentPageProvider);
    void setPage(String id) =>
        ref.read(currentPageProvider.notifier).state = id;
    final me = ref.watch(currentUserProvider)!;
    final eventId = ref.watch(currentEventIdProvider);
    final event =
        eventId == null ? null : ref.watch(eventProvider(eventId)).valueOrNull;
    // Primer momento: mientras el evento se configura, solo se ve la configuración.
    if (event != null && !event.setupDone) {
      return Scaffold(
        body: Column(children: [
          const DefaultPasswordBanner(),
          const Expanded(child: EventConfigScreen()),
        ]),
      );
    }
    // Un evento que no usa equipos no muestra «Equipos» en ninguna parte.
    final dests = allDestinations
        .where((d) => !d.adminOnly || me.isAdmin)
        .where((d) => d.id != 'equipos' || (event?.offersTeams ?? true))
        .toList();
    final sel =
        dests.firstWhere((d) => d.id == current, orElse: () => dests.first);
    final page = sel.builder(context);
    final body = ScreenShortcutsScope(
      // Ctrl+1…6: ir a una sección (solo las que este usuario y este evento tienen).
      onNavigate: (id) {
        if (!dests.any((d) => d.id == id)) return false;
        setPage(id);
        return true;
      },
      child: Column(children: [
        const DefaultPasswordBanner(),
        Expanded(child: page),
      ]),
    );
    final wide = MediaQuery.sizeOf(context).width >= 900;
    if (wide) {
      return Scaffold(
        body: Row(children: [
          Container(
            width: 230,
            decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: Brand.borde))),
            padding: const EdgeInsets.all(12),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
                      child: Row(children: [
                        const BrandLogo(size: 36),
                        const SizedBox(width: 10),
                        Expanded(
                            // flexible: no desborda con texto grande o fuentes más anchas
                            child: Text('Mi Evento',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: headStyle(22))),
                      ])),
                  // Los destinos se desplazan si la ventana es baja; el pie queda fijo.
                  Expanded(
                    child: ListView(padding: EdgeInsets.zero, children: [
                      for (final d in dests)
                        _SideItem(d.label, d.icon,
                            selected: d.id == sel.id,
                            onTap: () => setPage(d.id)),
                      _SideItem('Mis eventos', Icons.event_outlined,
                          selected: false,
                          onTap: () => ref
                              .read(currentEventIdProvider.notifier)
                              .state = null),
                      // Al final de la lista (el pie fijo no debe crecer: en ventanas bajas
                      // quitaría sitio a los destinos).
                      _SideItem(
                          'Atajos de teclado (F1)', Icons.keyboard_outlined,
                          selected: false,
                          key: const Key('atajos-ayuda'),
                          onTap: () => showShortcutsHelp(context)),
                    ]),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
                    child: Row(children: [
                      Expanded(
                        child: Text('${me.displayName}\n${me.roleLabel}',
                            style: const TextStyle(
                                fontSize: 14, color: Brand.gris)),
                      ),
                      // Centro de notificaciones: aquí quedan los avisos de escritorio.
                      const NotificationBell(),
                    ]),
                  ),
                  _SideItem('Cambiar contraseña', Icons.key_outlined,
                      selected: false,
                      onTap: () => showDialog<void>(
                          context: context,
                          builder: (_) => const ChangePasswordDialog())),
                  _SideItem('Cerrar sesión', Icons.logout,
                      selected: false,
                      key: const Key('cerrar-sesion'),
                      onTap: () => signOut(ref)),
                ]),
          ),
          Expanded(child: body),
        ]),
      );
    }
    // Si un destino principal no aplica (p. ej. Equipos en un evento sin equipos), no sale en la
    // barra inferior y el resto se corre; no se rellena el hueco con otro destino.
    final mobile = [
      for (final id in mobileMainIds)
        if (dests.any((d) => d.id == id)) dests.firstWhere((d) => d.id == id)
    ];
    final mi = mobile.indexWhere((d) => d.id == sel.id);
    return Scaffold(
      body: body,
      bottomNavigationBar: MediaQuery(
          // Las etiquetas de la barra no crecen más de un 15 %: con letra grande se partirían.
          data: MediaQuery.of(context).copyWith(
              textScaler:
                  MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.15)),
          child: NavigationBar(
            selectedIndex: mi >= 0 ? mi : mobile.length,
            onDestinationSelected: (i) {
              if (i < mobile.length) {
                setPage(mobile[i].id);
              } else {
                _more(context, dests, me);
              }
            },
            destinations: [
              for (final d in mobile)
                NavigationDestination(icon: Icon(d.icon), label: d.label),
              const NavigationDestination(icon: Icon(Icons.menu), label: 'Más'),
            ],
          )),
    );
  }

  void _more(BuildContext context, List<Destination> dests, AppUser me) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled:
          true, // puede ocupar el alto que necesite (si no, solo ~55 % de la pantalla)
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
                title: Text(me.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(me.roleLabel)),
            const Divider(height: 1),
            for (final d in dests)
              if (!mobileMainIds.contains(d.id))
                ListTile(
                  minTileHeight: 56,
                  leading: Icon(d.icon),
                  title: Text(d.label),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref.read(currentPageProvider.notifier).state = d.id;
                  },
                ),
            ListTile(
              minTileHeight: 56,
              leading: const Icon(Icons.event_outlined),
              title: const Text('Mis eventos'),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(currentEventIdProvider.notifier).state = null;
              },
            ),
            ListTile(
              minTileHeight: 56,
              leading: const Icon(Icons.key_outlined),
              title: const Text('Cambiar contraseña'),
              onTap: () {
                Navigator.pop(ctx);
                showDialog<void>(
                    context: context,
                    builder: (_) => const ChangePasswordDialog());
              },
            ),
            ListTile(
              key: const Key('cerrar-sesion-movil'),
              minTileHeight: 56,
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () {
                Navigator.pop(ctx);
                signOut(ref);
              },
            ),
          ]),
        ),
      ),
    );
  }
}

class _SideItem extends StatelessWidget {
  const _SideItem(this.label, this.icon,
      {super.key, required this.selected, required this.onTap});
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Material(
          color: selected ? Brand.azulSuave : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: SizedBox(
              height: 48,
              child: Row(children: [
                const SizedBox(width: 12),
                Icon(icon, color: selected ? Brand.azul : Brand.gris),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(label,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: selected ? Brand.azul : Brand.gris))),
              ]),
            ),
          ),
        ),
      );
}
