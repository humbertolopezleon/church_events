import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/repository.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import 'attendees_screen.dart' show openRegister;
import 'backup_screen.dart' show ago;

class PanelScreen extends ConsumerWidget {
  const PanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = ref.watch(currentEventIdProvider)!;
    final e = ref.watch(eventProvider(id)).valueOrNull;
    final registered =
        ref.watch(attendeesProvider(id)).valueOrNull ?? const <AttendeeView>[];
    // Los totales cuentan solo a los confirmados; los preinscritos se muestran aparte.
    final all = [
      for (final v in registered)
        if (!v.isPreregistered) v
    ];
    final pending = registered.length - all.length;
    final men = all.where((v) => v.isMale).length;
    final women = all.length - men;
    final needLodging = all.where((v) => v.a.needsLodging).length;
    void go(String page) => ref.read(currentPageProvider.notifier).state = page;

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(e?.name ?? '…', style: headStyle(22, color: Colors.white)),
          if (e != null)
            Text(
                '${e.startDate} → ${e.endDate}${e.venue.isEmpty ? '' : ' · ${e.venue}'}',
                style: const TextStyle(fontSize: 13)),
        ]),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (registered.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                Text('Todavía no hay nadie inscrito',
                    key: const Key('panel-vacio'),
                    textAlign: TextAlign.center,
                    style: headStyle(24)),
                const SizedBox(height: 8),
                const Text(
                    'Cuando registres a la primera persona, aquí verás los totales por sexo y hospedaje.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Brand.gris)),
                const SizedBox(height: 16),
                FilledButton.icon(
                    key: const Key('panel-registrar'),
                    onPressed: () => openRegister(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Registrar primer asistente')),
              ]),
            ),
          )
        else ...[
          Wrap(spacing: 12, runSpacing: 12, children: [
            _Stat('Inscritos', '${all.length}', '$women mujeres · $men hombres',
                key: const Key('contador-inscritos')),
            if (pending > 0)
              _Stat('Preinscritos por confirmar', '$pending',
                  'Aún no cuentan en los totales',
                  key: const Key('contador-preinscritos'),
                  onTap: () => go('asistencia')),
            if (e?.offersLodging ?? false)
              _Stat('Necesitan hospedaje', '$needLodging',
                  'Sin asignar: $needLodging'),
          ]),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
                backgroundColor: Brand.naranja,
                foregroundColor: Brand.tinta,
                minimumSize: const Size.fromHeight(60)),
            onPressed: () => openRegister(context),
            icon: const Icon(Icons.person_add_alt_outlined),
            label: const Text('Registrar asistente'),
          ),
          const SizedBox(height: 12),
          _BackupStatus(
            lastBackup:
                ref.watch(appMetaProvider).valueOrNull?.lastBackupAt?.toLocal(),
            lastChange: all
                .map((v) => v.a.updatedAt)
                .fold<DateTime?>(
                    null, (m, t) => m == null || t.isAfter(m) ? t : m)
                ?.toLocal(),
            onTap: () => go('respaldo'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
              onPressed: () => go('asistentes'),
              icon: const Icon(Icons.list_alt_outlined),
              label: const Text('Ver asistentes')),
        ],
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.detail, {super.key, this.onTap});
  final String label, value, detail;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 260,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style:
                            const TextStyle(color: Brand.gris, fontSize: 15)),
                    Text(value, style: headStyle(44)),
                    Text(detail,
                        style:
                            const TextStyle(color: Brand.gris, fontSize: 14)),
                    if (onTap != null)
                      const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text('Confirmar asistencia →',
                              style: TextStyle(
                                  color: Brand.azul,
                                  fontWeight: FontWeight.w700))),
                  ]),
            ),
          ),
        ),
      );
}

/// Aviso amable sobre la última copia: ámbar si hay cambios sin copiar desde hace más de 30 minutos.
class _BackupStatus extends StatelessWidget {
  const _BackupStatus(
      {required this.lastBackup,
      required this.lastChange,
      required this.onTap});
  final DateTime? lastBackup, lastChange;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final last = lastBackup;
    final stale = last == null ||
        (lastChange != null &&
            lastChange!.isAfter(last) &&
            DateTime.now().difference(last).inMinutes > 30);
    return Container(
      key: Key(stale ? 'panel-copia-aviso' : 'panel-copia-ok'),
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        color: stale ? Brand.avisoSuave : Brand.exitoSuave,
        borderRadius: BorderRadius.circular(12),
        border: stale ? Border.all(color: Brand.aviso, width: 2) : null,
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Icon(
              stale ? Icons.warning_amber_rounded : Icons.check_circle_outline,
              color: stale ? Brand.avisoTexto : Brand.exito),
        ),
        const SizedBox(width: 10),
        // El texto y el botón se apilan: así caben en 360 px y con letra grande.
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                last == null
                    ? 'Todavía no hay copia de seguridad.'
                    : (stale
                        ? 'Última copia: ${ago(last)}. Hay cambios sin copiar.'
                        : 'Última copia: ${ago(last)}'),
                style: const TextStyle(fontSize: 15),
              ),
            ),
            Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                    onPressed: onTap, child: const Text('Guardar copia'))),
          ]),
        ),
      ]),
    );
  }
}
