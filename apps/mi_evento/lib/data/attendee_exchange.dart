import 'package:drift/drift.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import 'database.dart';
import 'repos_b.dart';
import 'repository.dart';

enum PlanAction { create, update, skipDuplicate }

class PlanItem {
  const PlanItem(this.row, this.action, {this.existingId, this.note});
  final AttendeeCsvRow row;
  final PlanAction action;
  final String? existingId;
  final String? note;
}

/// Lo que haría una importación, calculado SIN tocar la base de datos (vista previa).
class ImportPlan {
  const ImportPlan(this.items, this.errors, this.warnings);
  final List<PlanItem> items;
  final List<CsvIssue> errors;
  final List<String> warnings;
  int get creates => items.where((i) => i.action == PlanAction.create).length;
  int get updates => items.where((i) => i.action == PlanAction.update).length;
  int get duplicates =>
      items.where((i) => i.action == PlanAction.skipDuplicate).length;

  /// Personas nuevas cuya fila trae el estado (columna `estado`) de preinscrito/confirmado.
  int get createsPreregistered => items
      .where((i) => i.action == PlanAction.create && i.row.confirmed == false)
      .length;
  int get createsConfirmed => items
      .where((i) => i.action == PlanAction.create && i.row.confirmed == true)
      .length;
  bool get hasStatusColumn => createsPreregistered + createsConfirmed > 0;
  bool get hasWork => creates + updates > 0;
}

class ImportReport {
  ImportReport(
      {this.created = 0,
      this.updated = 0,
      this.skipped = 0,
      this.churchesCreated = 0,
      this.groupsCreated = 0,
      this.teamsAutoAssigned = 0,
      List<String>? warnings})
      : warnings = warnings ?? [];
  int created,
      updated,
      skipped,
      churchesCreated,
      groupsCreated,
      teamsAutoAssigned;
  final List<String> warnings;
}

/// Exportación e importación de asistentes en CSV: el mismo archivo sirve para sacar los datos,
/// completarlos en Excel e importarlos otra vez. Las columnas siguen la base de datos; hospedaje,
/// equipo, iglesia y grupos se escriben por NOMBRE (legible en Excel).
class AttendeeExchange {
  AttendeeExchange(this.db);
  final AppDatabase db;

  static String sexLabel(String code) => code == 'M' ? 'Hombre' : 'Mujer';

  /// Archivo vacío con solo los títulos de las columnas (plantilla para llenar en Excel).
  static String template() =>
      buildCsvDelimited([List<String>.of(attendeeCsvHeaders)]);

  /// [onlyIds]: exportar solo a esas personas (p. ej. las que deja la búsqueda/filtros de la lista).
  /// El formato es el mismo, así que el archivo se puede volver a importar.
  Future<String> exportCsv(String eventId, {Set<String>? onlyIds}) async {
    final people = await (db.select(db.attendees)
          ..where((a) => a.eventId.equals(eventId) & a.deletedAt.isNull())
          ..orderBy([(a) => OrderingTerm.asc(a.regNumber)]))
        .get();
    final churches = {
      for (final c in await db.select(db.churches).get()) c.id: c.name
    };
    final lodgings = {
      for (final l in await (db.select(db.lodgings)
            ..where((l) => l.eventId.equals(eventId)))
          .get())
        l.id: l.name
    };
    final teams = {
      for (final t in await (db.select(db.teams)
            ..where((t) => t.eventId.equals(eventId)))
          .get())
        t.id: t.name
    };
    final byId = {for (final p in people) p.id: p};
    final spouses = await SocialRepo(db).spouseMap(eventId);
    final groups = await (db.select(db.attendeeGroups)
          ..where((g) => g.eventId.equals(eventId) & g.deletedAt.isNull()))
        .get();
    final members = groups.isEmpty
        ? const <GroupMember>[]
        : await (db.select(db.groupMembers)
              ..where((m) =>
                  m.groupId.isIn(groups.map((g) => g.id)) &
                  m.deletedAt.isNull()))
            .get();
    final groupNames = {for (final g in groups) g.id: g.name};
    final groupsOf = <String, List<String>>{};
    for (final m in members) {
      final n = groupNames[m.groupId];
      if (n != null) (groupsOf[m.attendeeId] ??= []).add(n);
    }

    final rows = <List<String>>[List<String>.of(attendeeCsvHeaders)];
    for (final p in people) {
      if (onlyIds != null && !onlyIds.contains(p.id)) continue;
      final sp = spouses[p.id];
      rows.add([
        p.id,
        '${p.regNumber}',
        p.firstName,
        p.lastName1,
        p.lastName2,
        sexLabel(p.sex),
        '${p.age}',
        churches[p.churchId] ?? '',
        p.province,
        p.municipality,
        p.phone ?? '',
        p.needsLodging ? 'Sí' : 'No',
        lodgings[p.lodgingId] ?? '',
        teams[p.teamId] ?? '',
        sp == null ? '' : '${byId[sp]?.regNumber ?? ''}',
        (groupsOf[p.id] ?? const []).join(csvListSeparator),
        p.notes,
        p.status == 'preregistered' ? 'Preinscrito' : 'Confirmado',
      ]);
    }
    return buildCsvDelimited(rows);
  }

  /// Calcula qué pasaría al importar [parse] en [eventId] (sin escribir nada).
  Future<ImportPlan> plan(String eventId, AttendeeCsvParse parse,
      {bool includeDuplicates = false}) async {
    final existing = await (db.select(db.attendees)
          ..where((a) => a.eventId.equals(eventId) & a.deletedAt.isNull()))
        .get();
    final byId = {for (final a in existing) a.id: a};
    final byNumber = {for (final a in existing) a.regNumber: a};
    final lodgingNames = {
      for (final l in await (db.select(db.lodgings)
            ..where((l) => l.eventId.equals(eventId) & l.deletedAt.isNull()))
          .get())
        normalizeText(l.name)
    };
    final teamNames = {
      for (final t in await (db.select(db.teams)
            ..where((t) => t.eventId.equals(eventId) & t.deletedAt.isNull()))
          .get())
        normalizeText(t.name)
    };
    final warnings = <String>[...parse.notes];
    final items = <PlanItem>[];
    final seenNew = <String>{};
    for (final r in parse.rows) {
      if (r.lodging.isNotEmpty &&
          !lodgingNames.contains(normalizeText(r.lodging))) {
        warnings.add(
            'Fila ${r.line}: el hospedaje «${r.lodging}» no existe en el evento; esa persona queda sin hospedaje asignado.');
      }
      if (r.team.isNotEmpty && !teamNames.contains(normalizeText(r.team))) {
        warnings.add(
            'Fila ${r.line}: el equipo «${r.team}» no existe en el evento; no se usa (si el evento reparte equipos, se le asigna uno automáticamente).');
      }
      AttendeeRow? match;
      String? note;
      if (r.id != null) match = byId[r.id!];
      if (match == null && r.id == null && r.number != null) {
        final byNum = byNumber[r.number!];
        if (byNum != null) {
          if (dedupeKey(byNum.firstName, byNum.lastName1) ==
              dedupeKey(r.firstName, r.lastName1)) {
            match = byNum;
          } else {
            note =
                'El número ${r.number} ya es de ${byNum.firstName} ${byNum.lastName1}; se importa como persona nueva con otro número.';
          }
        }
      }
      if (match != null) {
        items.add(PlanItem(r, PlanAction.update, existingId: match.id));
        continue;
      }
      final key = '${dedupeKey(r.firstName, r.lastName1)}|${r.age}';
      final dupInDb = existing.any((a) =>
          a.dedupeKey == dedupeKey(r.firstName, r.lastName1) && a.age == r.age);
      final dupInFile = !seenNew.add(key);
      if ((dupInDb || dupInFile) && !includeDuplicates) {
        items.add(PlanItem(r, PlanAction.skipDuplicate,
            note: dupInDb
                ? 'Ya hay alguien con ese nombre y edad en el evento.'
                : 'Repetida en el mismo archivo.'));
        continue;
      }
      items.add(PlanItem(r, PlanAction.create, note: note));
    }
    return ImportPlan(items, parse.errors, warnings);
  }

  /// Aplica el plan. Todo o nada: si algo falla, no se importa nada.
  ///
  /// Las personas NUEVAS entran como preinscritas (si [asPreregistered]) o confirmadas. Con
  /// [useFileStatus] manda la columna `estado` de cada fila (las filas sin estado siguen
  /// [asPreregistered]). No se usa por defecto: un archivo exportado de otro evento trae «Confirmado»
  /// en todas las filas y aun así puede importarse como preinscripción. A quien ya está registrado NUNCA se le cambia el
  /// estado: una importación no deshace una confirmación.
  ///
  /// Hospedaje y equipo del archivo: las personas confirmadas los conservan siempre; las
  /// preinscritas solo con [keepAssignments] (pueden pertenecer a otro evento).
  Future<ImportReport> apply(String eventId, ImportPlan plan,
      {String? createdBy,
      bool asPreregistered = false,
      bool useFileStatus = false,
      bool keepAssignments = false}) async {
    final rep = ImportReport();
    final repo = Repository(db);
    final social = SocialRepo(db);
    final lodgingRepo = LodgingRepo(db);
    final teamRepo = TeamRepo(db);

    await db.transaction(() async {
      final churches = await db.select(db.churches).get();
      final lodgings = {
        for (final l in await (db.select(db.lodgings)
              ..where((l) => l.eventId.equals(eventId) & l.deletedAt.isNull()))
            .get())
          normalizeText(l.name): l.id
      };
      final teams = {
        for (final t in await (db.select(db.teams)
              ..where((t) => t.eventId.equals(eventId) & t.deletedAt.isNull()))
            .get())
          normalizeText(t.name): t.id
      };
      final groups = {
        for (final g in await (db.select(db.attendeeGroups)
              ..where((g) => g.eventId.equals(eventId) & g.deletedAt.isNull()))
            .get())
          normalizeText(g.name): g.id
      };

      Future<String> churchId(AttendeeCsvRow r) async {
        final n = normalizeText(r.church);
        final c = churches
            .where((c) =>
                c.nameNormalized == n &&
                c.deletedAt == null &&
                (r.province.isEmpty ||
                    c.province.isEmpty ||
                    normalizeText(c.province) == normalizeText(r.province)))
            .firstOrNull;
        if (c != null) return c.id;
        final made = await repo.createChurch(
            name: r.church, province: r.province, municipality: r.municipality);
        churches.add(made);
        rep.churchesCreated++;
        return made.id;
      }

      final ids = <int, String>{}; // número del archivo / actual → id
      final spouseLinks = <String, AttendeeCsvRow>{};
      final needTeam = <String>[]; // nuevas sin equipo válido en el archivo
      final wantLodging = <String, (String, String, int)>{};
      for (final item in plan.items) {
        final r = item.row;
        if (item.action == PlanAction.skipDuplicate) {
          rep.skipped++;
          continue;
        }
        final cid = await churchId(r);
        String id;
        final pre = useFileStatus && r.confirmed != null
            ? !r.confirmed!
            : asPreregistered;
        final fromFile =
            !pre || keepAssignments || item.action == PlanAction.update;
        final lodgingId = r.lodging.isEmpty || !fromFile
            ? null
            : lodgings[normalizeText(r.lodging)];
        final needs = r.needsLodging ?? (lodgingId != null ? true : null);
        if (item.action == PlanAction.update) {
          id = item.existingId!;
          final cur = await repo.attendeeById(id);
          await repo.updateAttendee(id,
              firstName: r.firstName,
              lastName1: r.lastName1,
              lastName2: r.lastName2,
              sex: r.sex,
              age: r.age,
              churchId: cid,
              phone: r.phone.isEmpty ? cur?.phone : r.phone,
              province: r.province.isEmpty ? (cur?.province ?? '') : r.province,
              municipality: r.municipality.isEmpty
                  ? (cur?.municipality ?? '')
                  : r.municipality,
              needsLodging: needs ?? cur?.needsLodging ?? false,
              notes: r.notes.isEmpty ? (cur?.notes ?? '') : r.notes);
          rep.updated++;
          if (cur != null) ids[cur.regNumber] = id;
        } else {
          final row = await repo.addAttendee(
              eventId: eventId,
              firstName: r.firstName,
              lastName1: r.lastName1,
              lastName2: r.lastName2,
              sex: r.sex,
              age: r.age,
              churchId: cid,
              phone: r.phone,
              province: r.province,
              municipality: r.municipality,
              needsLodging: needs ?? false,
              notes: r.notes,
              createdBy: createdBy,
              preregistered: pre,
              preferredRegNumber: r.number);
          id = row.id;
          rep.created++;
          if (r.number == null) ids[row.regNumber] = id;
        }
        if (r.number != null) ids.putIfAbsent(r.number!, () => id);
        // El hospedaje se asigna al final, cuando ya están vinculadas las parejas (un hospedaje de
        // matrimonios exige al cónyuge) y comprobando la compatibilidad: si no cabe, la fila queda
        // sin hospedaje y con aviso.
        if (lodgingId != null) wantLodging[id] = (lodgingId, r.lodging, r.line);
        final teamId =
            r.team.isEmpty || !fromFile ? null : teams[normalizeText(r.team)];
        if (teamId != null) {
          await teamRepo.setTeam([id], teamId);
        } else if (item.action == PlanAction.create) {
          needTeam.add(id);
        }
        if (r.groups.isNotEmpty) {
          final have = await social.groupIdsOf(id);
          for (final g in r.groups) {
            var gid = groups[normalizeText(g)];
            if (gid == null) {
              gid = (await social.createGroup(eventId, g)).id;
              groups[normalizeText(g)] = gid;
              rep.groupsCreated++;
            }
            have.add(gid);
          }
          await social.setGroups(id, have);
        }
        if (r.spouseNumber != null) spouseLinks[id] = r;
      }

      // Parejas: cuando ya se conocen todos los números.
      final current = await (db.select(db.attendees)
            ..where((a) => a.eventId.equals(eventId) & a.deletedAt.isNull()))
          .get();
      for (final a in current) {
        ids.putIfAbsent(a.regNumber, () => a.id);
      }
      // Parejas contradictorias (A→B pero B→C, o dos personas que dicen ser pareja de la misma):
      // no se vincula a ninguna de las implicadas y se avisa (QA-BUG-007).
      final target = <String, String>{
        for (final e in spouseLinks.entries)
          if (ids[e.value.spouseNumber!] != null &&
              ids[e.value.spouseNumber!] != e.key)
            e.key: ids[e.value.spouseNumber!]!
      };
      final pointedBy = <String, List<String>>{};
      target.forEach((x, y) => (pointedBy[y] ??= []).add(x));
      final contradictory = <String>{};
      target.forEach((x, y) {
        final yTarget = target[y];
        if ((yTarget != null && yTarget != x) || pointedBy[y]!.length > 1) {
          contradictory.addAll([x, y]);
          contradictory.addAll(pointedBy[y]!);
        }
      });
      for (final x in contradictory.where(spouseLinks.containsKey)) {
        rep.warnings.add(
            'Fila ${spouseLinks[x]!.line}: la pareja que indica ese archivo se contradice con otra fila (alguien más dice ser pareja de la misma persona); no se vinculó a nadie de ese grupo. Corrige el archivo o vincúlalos desde la ficha.');
      }
      for (final e in spouseLinks.entries) {
        if (contradictory.contains(e.key)) continue;
        final r = e.value;
        final other = ids[r.spouseNumber!];
        if (other == null || other == e.key) {
          rep.warnings.add(
              'Fila ${r.line}: no se encontró a la pareja con número ${r.spouseNumber}.');
          continue;
        }
        try {
          await social.setSpouse(e.key, other);
        } on DataException catch (ex) {
          rep.warnings.add('Fila ${r.line}: ${ex.message}');
        }
      }
      // Hospedajes: por hospedaje y juntos (así un matrimonio entra a la vez); si el grupo no es
      // compatible se prueba persona por persona y a quien no cabe se le deja sin hospedaje.
      final byLodging = <String, List<String>>{};
      wantLodging.forEach((p, v) => (byLodging[v.$1] ??= []).add(p));
      for (final e in byLodging.entries) {
        if ((await lodgingRepo.compatibilityProblems(e.key, e.value)).isEmpty) {
          await lodgingRepo.assign(e.key, e.value);
          continue;
        }
        for (final pid in e.value) {
          final problems =
              await lodgingRepo.compatibilityProblems(e.key, [pid]);
          final w = wantLodging[pid]!;
          if (problems.isEmpty) {
            await lodgingRepo.assign(e.key, [pid]);
          } else {
            rep.warnings.add(
                'Fila ${w.$3}: no se asignó el hospedaje «${w.$2}» (${problems.join(' ')}) y la persona queda sin hospedaje. Edita el hospedaje o elige otro.');
          }
        }
      }
      // Equipo automático para las personas nuevas sin equipo en el archivo, igual que al inscribir
      // por el formulario (después de las parejas, para que el cónyuge quede en su equipo).
      rep.teamsAutoAssigned = await teamRepo.autoAssignMany(eventId, needTeam);
    });
    return rep;
  }
}
