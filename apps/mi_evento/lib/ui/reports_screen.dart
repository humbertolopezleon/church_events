import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_evento_core/mi_evento_core.dart';
import 'package:printing/printing.dart';

import '../data/database.dart';
import '../data/repos_b.dart';
import '../data/repository.dart';
import '../export/report_export.dart';
import '../providers.dart';
import '../theme/app_theme.dart';

/// Totales por sexo, rango de edad, iglesia, hospedaje y equipo; con listado exportable e imprimible.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});
  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  bool phone = false;
  bool busy = false;

  ReportData? _data() {
    final eventId = ref.read(currentEventIdProvider)!;
    final event = ref.read(eventProvider(eventId)).valueOrNull;
    if (event == null) return null;
    return buildReportData(
      event: event,
      people: ref.read(confirmedAttendeesProvider(eventId)).valueOrNull ??
          const <AttendeeView>[],
      ranges:
          ref.read(ageRangesProvider(eventId)).valueOrNull ?? AgeRange.defaults,
      lodgingNames: {
        for (final l in ref.read(lodgingsProvider(eventId)).valueOrNull ??
            const <LodgingView>[])
          l.row.id: l.row.name
      },
      teamNames: {
        for (final t in ref.read(teamsProvider(eventId)).valueOrNull ??
            const <TeamRow>[])
          t.id: t.name
      },
      includePhone: phone,
    );
  }

  Future<void> _run(Future<void> Function(ReportData d) job) async {
    final d = _data();
    if (d == null) return;
    setState(() => busy = true);
    try {
      await job(d);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('No se pudo exportar. Detalle técnico: $e')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _save(String name, Uint8List bytes, String mime) async {
    final ok =
        await ref.read(fileSaverProvider).save(name, bytes, mimeType: mime);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              ok ? 'Listo. Archivo exportado.' : 'Exportación cancelada.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventId = ref.watch(currentEventIdProvider)!;
    ref.watch(eventProvider(eventId));
    ref.watch(ageRangesProvider(eventId));
    ref.watch(lodgingsProvider(eventId));
    ref.watch(teamsProvider(eventId));
    final d = ref.watch(confirmedAttendeesProvider(eventId)).hasValue
        ? _data()
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Reportes')),
      body: d == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(16), children: [
              Text('${d.total} ${d.total == 1 ? 'inscrito' : 'inscritos'}',
                  key: const Key('rp-total'), style: headStyle(28)),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Exportar e imprimir', style: headStyle(20)),
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          key: const Key('rp-telefono'),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: phone,
                          onChanged: (v) => setState(() => phone = v ?? false),
                          title:
                              const Text('Incluir el teléfono de cada persona'),
                          subtitle: const Text(
                              'Por defecto no se incluye: es el dato más sensible'),
                        ),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          OutlinedButton.icon(
                              key: const Key('rp-excel'),
                              onPressed: busy
                                  ? null
                                  : () => _run((d) => _save(
                                      'reportes-${normalizeText(d.eventName).replaceAll(' ', '-')}.xlsx',
                                      reportXlsx(d),
                                      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')),
                              icon: const Icon(Icons.table_chart_outlined),
                              label: const Text('Excel (.xlsx)')),
                          OutlinedButton.icon(
                              key: const Key('rp-csv'),
                              onPressed: busy
                                  ? null
                                  : () => _run((d) => _save(
                                      'asistentes-${normalizeText(d.eventName).replaceAll(' ', '-')}.csv',
                                      Uint8List.fromList(
                                          utf8.encode(attendeesCsv(d))),
                                      'text/csv')),
                              icon: const Icon(Icons.description_outlined),
                              label: const Text('Listado en CSV')),
                          OutlinedButton.icon(
                              key: const Key('rp-pdf'),
                              onPressed: busy
                                  ? null
                                  : () => _run((d) async => _save(
                                      'reportes-${normalizeText(d.eventName).replaceAll(' ', '-')}.pdf',
                                      await reportPdf(d),
                                      'application/pdf')),
                              icon: const Icon(Icons.picture_as_pdf_outlined),
                              label: const Text('Guardar como PDF')),
                          FilledButton.icon(
                              key: const Key('rp-imprimir'),
                              onPressed: busy
                                  ? null
                                  : () => _run((d) async => Printing.layoutPdf(
                                      onLayout: (_) async => await reportPdf(d),
                                      name: 'Reportes de ${d.eventName}')),
                              icon: const Icon(Icons.print_outlined),
                              label: const Text('Imprimir')),
                        ]),
                      ]),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(spacing: 12, runSpacing: 12, children: [
                for (final s in d.sections) _SectionCard(s, d.total)
              ]),
            ]),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard(this.s, this.total);
  final ReportSection s;
  final int total;
  @override
  Widget build(BuildContext context) {
    final max = s.rows.fold<int>(1, (m, r) => r.count > m ? r.count : m);
    return SizedBox(
      width: 400,
      child: Card(
        key: Key('rp-${s.title}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.title, style: headStyle(20)),
            const SizedBox(height: 8),
            if (s.rows.isEmpty)
              const Text('Sin datos todavía.',
                  style: TextStyle(color: Brand.gris)),
            for (final r in s.rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                            child:
                                Text(r.label, overflow: TextOverflow.ellipsis)),
                        Text('${r.count}',
                            key: Key('rp-n-${s.title}-${r.label}'),
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                      ]),
                  const SizedBox(height: 3),
                  ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                          minHeight: 9,
                          value: r.count / max,
                          backgroundColor: Brand.azulSuave,
                          color: Brand.azul)),
                ]),
              ),
          ]),
        ),
      ),
    );
  }
}
