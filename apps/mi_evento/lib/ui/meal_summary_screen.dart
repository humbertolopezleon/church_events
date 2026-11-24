import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import '../data/database.dart';
import '../data/meal_repo.dart';
import '../data/repository.dart' show AttendeeView;
import '../export/meal_report.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import 'teams_screen.dart' show teamColor;

/// Resumen de una sesión de control (al cerrarla o al consultarla después) con la exportación
/// a Excel, CSV e imagen para WhatsApp.
class MealSummaryScreen extends ConsumerStatefulWidget {
  const MealSummaryScreen({super.key, required this.sessionId});
  final String sessionId;
  @override
  ConsumerState<MealSummaryScreen> createState() => _MealSummaryScreenState();
}

class _MealSummaryScreenState extends ConsumerState<MealSummaryScreen> {
  bool busy = false;

  MealReport? _report() {
    final eventId = ref.read(currentEventIdProvider)!;
    final event = ref.read(eventProvider(eventId)).valueOrNull;
    final session = (ref.read(sessionsProvider(eventId)).valueOrNull ??
            const <SessionView>[])
        .where((s) => s.row.id == widget.sessionId)
        .firstOrNull;
    if (event == null || session == null) return null;
    final views = ref.read(confirmedAttendeesProvider(eventId)).valueOrNull ??
        const <AttendeeView>[];
    final teams =
        ref.read(teamsProvider(eventId)).valueOrNull ?? const <TeamRow>[];
    return buildMealReport(
      event: event,
      session: session,
      people: [for (final v in views) v.a],
      churchNames: {
        for (final v in views)
          if (v.a.churchId != null && v.churchName != null)
            v.a.churchId!: v.churchName!
      },
      teams: {for (final t in teams) t.id: t},
      records: ref.read(recordsProvider(widget.sessionId)).valueOrNull ??
          const <ControlRecord>[],
    );
  }

  Future<void> _export(String what) async {
    final r = _report();
    if (r == null) return;
    setState(() => busy = true);
    try {
      final saver = ref.read(fileSaverProvider);
      final bool ok;
      switch (what) {
        case 'xlsx':
          ok = await saver.save('${r.fileBase}.xlsx', mealXlsx(r),
              mimeType:
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        case 'csv':
          ok = await saver.save('${r.fileBase}.csv', csvBytes(r),
              mimeType: 'text/csv');
        default:
          ok = await saver.save('${r.fileBase}.png', await mealSummaryPng(r),
              mimeType: 'image/png');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                ok ? 'Listo. Archivo exportado.' : 'Exportación cancelada.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('No se pudo exportar. Detalle técnico: $e')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventId = ref.watch(currentEventIdProvider)!;
    ref.watch(eventProvider(eventId));
    ref.watch(teamsProvider(eventId));
    ref.watch(confirmedAttendeesProvider(eventId));
    ref.watch(recordsProvider(widget.sessionId));
    final session = (ref.watch(sessionsProvider(eventId)).valueOrNull ??
            const <SessionView>[])
        .where((s) => s.row.id == widget.sessionId)
        .firstOrNull;
    final r = _report();
    if (session == null || r == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Resumen')),
          body: const Center(child: CircularProgressIndicator()));
    }
    final maxBucket = r.buckets.fold<int>(1, (m, b) => b.$2 > m ? b.$2 : m);

    return Scaffold(
      appBar: AppBar(
          title: Text(session.closed
              ? '${session.row.name} cerrada'
              : session.row.name)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (session.closed)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Brand.exitoSuave,
                borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.check_circle_outline, color: Brand.exito),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(
                      'Cerrada${session.row.closedAt == null ? '' : ' a las ${hhmm(session.row.closedAt!.toLocal())}'}')),
              TextButton(
                  key: const Key('res-reabrir'),
                  onPressed: () async {
                    await ref
                        .read(mealRepoProvider)
                        .reopenSession(session.row.id);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Reabrir')),
            ]),
          ),
        const SizedBox(height: 12),
        Wrap(spacing: 12, runSpacing: 12, children: [
          _Stat('Inscritos', '${r.total}', null,
              key: const Key('res-inscritos')),
          _Stat('Pasaron', '${r.passed.length}', '${r.percent} %',
              key: const Key('res-pasaron'), bg: Brand.exitoSuave),
          _Stat('No pasaron', '${r.notPassed.length}', null,
              key: const Key('res-no-pasaron'), bg: Brand.naranjaSuave),
          _Stat('Repetidos evitados', '${r.blockedRepeats}', null,
              key: const Key('res-repetidos')),
        ]),
        const SizedBox(height: 16),
        if (r.teams.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Por equipo', style: headStyle(20)),
                    const SizedBox(height: 8),
                    for (final t in r.teams)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(t.name, key: Key('res-eq-${t.name}')),
                                Text('${t.passed} / ${t.total}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                              ]),
                          const SizedBox(height: 4),
                          ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                  minHeight: 10,
                                  value: t.total == 0 ? 0 : t.passed / t.total,
                                  backgroundColor: Brand.azulSuave,
                                  color: teamColor(t.colorHex ?? '#1D4E89'))),
                        ]),
                      ),
                  ]),
            ),
          ),
        const SizedBox(height: 12),
        if (r.buckets.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Llegadas cada 15 minutos', style: headStyle(20)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (final b in r.buckets)
                              Expanded(
                                child: Tooltip(
                                  message: '${hhmm(b.$1)}: ${b.$2}',
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 1.5),
                                    child: Container(
                                        height: 8 + 100 * b.$2 / maxBucket,
                                        decoration: BoxDecoration(
                                            color: b.$2 == 0
                                                ? Brand.borde
                                                : Brand.azul,
                                            borderRadius:
                                                BorderRadius.circular(3))),
                                  ),
                                ),
                              ),
                          ]),
                    ),
                    const SizedBox(height: 4),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(hhmm(r.buckets.first.$1),
                              style: const TextStyle(
                                  fontSize: 12, color: Brand.gris)),
                          Text(hhmm(r.buckets.last.$1),
                              style: const TextStyle(
                                  fontSize: 12, color: Brand.gris)),
                        ]),
                  ]),
            ),
          ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Exportar', style: headStyle(20)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                OutlinedButton.icon(
                    key: const Key('ex-excel'),
                    onPressed: busy ? null : () => _export('xlsx'),
                    icon: const Icon(Icons.table_chart_outlined),
                    label: const Text('Excel (.xlsx)')),
                OutlinedButton.icon(
                    key: const Key('ex-csv'),
                    onPressed: busy ? null : () => _export('csv'),
                    icon: const Icon(Icons.description_outlined),
                    label: const Text('CSV (texto)')),
                FilledButton.icon(
                    key: const Key('ex-imagen'),
                    style: FilledButton.styleFrom(
                        backgroundColor: Brand.naranja,
                        foregroundColor: Brand.tinta),
                    onPressed: busy ? null : () => _export('png'),
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Imagen para WhatsApp')),
              ]),
              const SizedBox(height: 10),
              const Text(
                  'La imagen solo lleva cifras, nunca nombres. La lista de quienes no pasaron va en Excel y CSV.',
                  style: TextStyle(color: Brand.gris, fontSize: 14)),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.detail, {super.key, this.bg});
  final String label, value;
  final String? detail;
  final Color? bg;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 200,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: bg ?? Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Brand.borde)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    color: Brand.gris,
                    fontWeight: FontWeight.w700)),
            Text(value, style: headStyle(40)),
            if (detail != null)
              Text(detail!, style: const TextStyle(color: Brand.gris)),
          ]),
        ),
      );
}
