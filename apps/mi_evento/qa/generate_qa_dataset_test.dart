// GENERADOR MANUAL de datos de prueba (NO corre en el CI: está fuera de `test/`).
//
//   cd apps/mi_evento && timeout 580 flutter test qa/generate_qa_dataset_test.dart
//
// Usa los servicios REALES de la app (Repository, TeamRepo.autoAssign, LodgingRepo, MealRepo,
// BackupService.export, AttendeeExchange.exportCsv/template) con semilla fija y escribe en
// /home/user/my_event/qa-datasets/ (o en la carpeta de la variable QA_DATASETS_DIR).
// Al final comprueba cada archivo importándolo en una base nueva y escribe el LEEME.md con los
// resultados REALES de esas importaciones.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mi_evento/backup/backup_service.dart' show BackupService;
import 'package:mi_evento/data/attendee_exchange.dart';
import 'package:mi_evento/data/database.dart';
import 'package:mi_evento/data/meal_repo.dart';
import 'package:mi_evento_core/mi_evento_core.dart';

import '../test/qa/qa_support.dart';

const _cabecera = attendeeCsvHeaders;

/// Fila de CSV con las 17 columnas del sistema.
List<String> fila({
  String id = '',
  String numero = '',
  required String nombre,
  required String ap1,
  String ap2 = '',
  required String sexo,
  required String edad,
  required String iglesia,
  String provincia = '',
  String municipio = '',
  String tel = '',
  String necesita = '',
  String hospedaje = '',
  String equipo = '',
  String pareja = '',
  String grupos = '',
  String obs = '',
}) =>
    [
      id,
      numero,
      nombre,
      ap1,
      ap2,
      sexo,
      edad,
      iglesia,
      provincia,
      municipio,
      tel,
      necesita,
      hospedaje,
      equipo,
      pareja,
      grupos,
      obs
    ];

/// Evento destino «vacío» pero ya configurado (mismos equipos y hospedajes, nombres iguales).
Future<QaEvent> _destino(AppDatabase db,
    {bool conLas120 = false, String? csv}) async {
  final q = await qaEvent(db, teams: 6, groups: const []);
  await qaLodgings(q);
  if (conLas120 && csv != null) {
    final ex = AttendeeExchange(db);
    await ex.apply(q.eventId, await ex.plan(q.eventId, parseAttendeesCsv(csv)));
  }
  return q;
}

Future<ImportReport> _importar(AppDatabase db, QaEvent q, String csv,
    {bool dup = false}) async {
  final ex = AttendeeExchange(db);
  final plan =
      await ex.plan(q.eventId, parseAttendeesCsv(csv), includeDuplicates: dup);
  return ex.apply(q.eventId, plan);
}

void main() {
  test('Generar los datos de prueba «Congreso QA 2026»', () async {
    final dir = Directory(Platform.environment['QA_DATASETS_DIR'] ??
        '/home/user/my_event/qa-datasets')
      ..createSync(recursive: true);
    String ruta(String n) => '${dir.path}/$n';

    // ── 1. El evento, con los servicios reales ──
    final db = qaDb();
    final q = await qaEvent(db, teams: 6);
    final personas = qaPeople(120); // semilla fija 2026
    await qaInscribeAll(q,
        personas); // alta + matrimonio + grupos + equipo automático (autoAssign)
    await qaLodgings(q);
    final propuesta = await qaSuggestAndAccept(
        q); // hospedaje para todos, aceptando la sugerencia
    expect(propuesta!.isComplete, isTrue, reason: propuesta.notes.join(' / '));

    // Dos sesiones de comida con marcas (nombres «Almuerzo del sábado» y «Cena del viernes»).
    final meals = MealRepo(db);
    await meals.ensureDefaultTypes(q.eventId);
    final tipos = {for (final t in await meals.types(q.eventId)) t.name: t};
    final almuerzo = await meals.createSession(
        q.eventId, tipos['Almuerzo']!.id, 'Almuerzo del sábado',
        operatorName: 'Ruth');
    final cena = await meals.createSession(
        q.eventId, tipos['Cena']!.id, 'Cena del viernes',
        operatorName: 'Ruth');
    for (final id in q.ids.take(90)) {
      await meals.mark(almuerzo.id, id, operatorName: 'Ruth');
    }
    for (final id in q.ids.take(60)) {
      await meals.mark(cena.id, id, operatorName: 'Pedro');
    }
    await meals.closeSession(cena.id);

    // ── 2. Comprobaciones de lo generado ──
    final gente = await q.people();
    expect(gente.length, 120);
    expect(gente.every((p) => p.age >= 12 && p.age <= 70), isTrue);
    expect(gente.where((p) => p.sex == 'M').length, inInclusiveRange(40, 80));
    expect(
        gente.map((p) => p.churchId).toSet().length, greaterThanOrEqualTo(8));
    final parejas = (await q.social.spouseMap(q.eventId)).length ~/ 2;
    expect(parejas, 15);
    expect((await q.social.togetherSets(q.eventId)).length,
        greaterThanOrEqualTo(3));
    expect(gente.where((p) => p.needsLodging && p.lodgingId == null), isEmpty);
    expect(gente.where((p) => p.teamId == null), isEmpty);
    final estadisticas = await qaTeamStats(q);
    final resumenEquipos = qaTeamSummary(estadisticas);
    final lods = await q.lodgingViews();
    final ocupacion = lods
        .map((l) => '${l.row.name}: ${l.occupied}/${l.row.capacity}')
        .join('; ');
    final sexo = (
      gente.where((p) => p.sex == 'M').length,
      gente.where((p) => p.sex == 'F').length
    );
    final conAlbergue = gente.where((p) => p.needsLodging).length;

    // ── 3. Archivos ──
    final ex = AttendeeExchange(db);
    final csv120 = await ex.exportCsv(q.eventId);
    File(ruta('asistentes_120.csv')).writeAsStringSync(csv120);
    File(ruta('plantilla_vacia.csv'))
        .writeAsStringSync(AttendeeExchange.template());

    // 30 personas nuevas (sin id ni número) para «seguir inscribiendo desde Excel».
    final claves = {for (final p in gente) dedupeKey(p.firstName, p.lastName1)};
    final nuevas = <QaPerson>[];
    for (final p in qaPeople(200, seed: 4242, couples: 0)) {
      if (nuevas.length == 30) break;
      if (claves.add(dedupeKey(p.first, p.last1))) nuevas.add(p);
    }
    final filasNuevas = <List<String>>[
      [..._cabecera],
      for (final p in nuevas)
        fila(
          nombre: p.first,
          ap1: p.last1,
          ap2: p.last2,
          sexo: p.sex == Sex.male ? 'Hombre' : 'Mujer',
          edad: '${p.age}',
          iglesia: qaChurches[p.churchIdx].$1,
          provincia: qaChurches[p.churchIdx].$2,
          municipio: qaChurches[p.churchIdx].$3,
          tel: p.phone ?? '',
          necesita: p.needsLodging ? 'Sí' : 'No',
        ),
    ];
    final csvNuevos = buildCsvDelimited(filasNuevas);
    File(ruta('importar_nuevos_30.csv')).writeAsStringSync(csvNuevos);

    // Archivo con errores variados y duplicados (la fila 2 es la primera de datos).
    final existente = gente.first;
    final ch = {
      for (final c in await db.select(db.churches).get()) c.id: c.name
    };
    final iglesia = qaChurches[0].$1;
    final filasErr = <List<String>>[
      [..._cabecera],
      fila(
          nombre: 'Lucía',
          ap1: 'Prueba',
          ap2: 'Uno',
          sexo: 'Mujer',
          edad: '28',
          iglesia: iglesia), // 2 buena
      fila(
          nombre: 'Óscar',
          ap1: 'Prueba',
          ap2: 'Dos',
          sexo: 'Hombre',
          edad: '35',
          iglesia: iglesia), // 3 buena
      fila(
          nombre: '',
          ap1: 'SinNombre',
          sexo: 'Mujer',
          edad: '30',
          iglesia: iglesia), // 4 falta nombre
      fila(
          nombre: 'SinApellido',
          ap1: '',
          sexo: 'Hombre',
          edad: '30',
          iglesia: iglesia), // 5 falta apellido
      fila(
          nombre: 'Sexo',
          ap1: 'Raro',
          sexo: 'Otro',
          edad: '30',
          iglesia: iglesia), // 6 sexo no se entiende
      fila(
          nombre: 'Edad',
          ap1: 'Texto',
          sexo: 'Mujer',
          edad: 'treinta',
          iglesia: iglesia), // 7 edad no numérica
      fila(
          nombre: 'Edad',
          ap1: 'Cero',
          sexo: 'Mujer',
          edad: '0',
          iglesia: iglesia), // 8 edad 0
      fila(
          nombre: 'Edad',
          ap1: 'Enorme',
          sexo: 'Hombre',
          edad: '111',
          iglesia: iglesia), // 9 edad 111
      fila(
          nombre: 'Sin',
          ap1: 'Iglesia',
          sexo: 'Hombre',
          edad: '40',
          iglesia: ''), // 10 sin iglesia
      fila(
          nombre: 'Hospedaje',
          ap1: 'Quizás',
          sexo: 'Mujer',
          edad: '22',
          iglesia: iglesia,
          necesita: 'Quizás'), // 11
      fila(
          nombre: 'Pareja',
          ap1: 'Mala',
          sexo: 'Mujer',
          edad: '33',
          iglesia: iglesia,
          pareja: 'abc'), // 12
      fila(
          id: 'DUP-1',
          nombre: 'IdUno',
          ap1: 'Repetido',
          sexo: 'Hombre',
          edad: '26',
          iglesia: iglesia), // 13 buena
      fila(
          id: 'DUP-1',
          nombre: 'IdDos',
          ap1: 'Repetido',
          sexo: 'Hombre',
          edad: '27',
          iglesia: iglesia), // 14 id repetido
      fila(
          numero: '500',
          nombre: 'NumUno',
          ap1: 'Repetido',
          sexo: 'Mujer',
          edad: '31',
          iglesia: iglesia), // 15 buena
      fila(
          numero: '500',
          nombre: 'NumDos',
          ap1: 'Repetido',
          sexo: 'Mujer',
          edad: '32',
          iglesia: iglesia), // 16 número repetido
      fila(
          nombre: existente.firstName,
          ap1: existente.lastName1,
          ap2: existente.lastName2,
          sexo: existente.sex == 'M' ? 'Hombre' : 'Mujer',
          edad: '${existente.age}',
          iglesia: ch[existente.churchId] ?? iglesia), // 17 ya existe
      fila(
          nombre: 'Lucía',
          ap1: 'Prueba',
          ap2: 'Uno',
          sexo: 'Mujer',
          edad: '28',
          iglesia: iglesia), // 18 repetida en el archivo
      fila(
          nombre: 'Hotel',
          ap1: 'Fantasma',
          sexo: 'Hombre',
          edad: '45',
          iglesia: iglesia,
          necesita: 'Sí',
          hospedaje: 'Hotel Fantasma'), // 19 hospedaje inexistente
      fila(
          nombre: 'Equipo',
          ap1: 'Inventado',
          sexo: 'Mujer',
          edad: '19',
          iglesia: iglesia,
          equipo: 'Equipo Inventado'), // 20 equipo inexistente
      fila(
          nombre: 'Pareja',
          ap1: 'Perdida',
          sexo: 'Hombre',
          edad: '50',
          iglesia: iglesia,
          pareja: '999'), // 21 pareja que no existe
      fila(
          nombre: 'Con',
          ap1: 'Grupos',
          sexo: 'Mujer',
          edad: '24',
          iglesia: iglesia,
          grupos: 'Coro nuevo|Jóvenes Ebenezer',
          obs:
              'Texto con "comillas"; punto y coma\ny salto de línea'), // 22 buena con grupos
    ];
    final csvErrores = buildCsvDelimited(filasErr);
    File(ruta('importar_con_errores.csv')).writeAsStringSync(csvErrores);

    // Windows-1252 (ANSI) con tildes y ñ, SIN BOM (como un «CSV» antiguo de Excel).
    final filasAnsi = <List<String>>[
      [..._cabecera],
      fila(
          nombre: 'José',
          ap1: 'Peña',
          ap2: 'Núñez',
          sexo: 'Hombre',
          edad: '41',
          iglesia: 'Metodista de Colón',
          provincia: 'Matanzas',
          municipio: 'Colón',
          necesita: 'No'),
      fila(
          nombre: 'María Ángeles',
          ap1: 'Muñoz',
          ap2: 'Quiñones',
          sexo: 'Mujer',
          edad: '37',
          iglesia: 'Bautista Ebenezer',
          necesita: 'Sí'),
      fila(
          nombre: 'Ñico',
          ap1: 'Báez',
          ap2: 'Piñeiro',
          sexo: 'Hombre',
          edad: '19',
          iglesia: 'Presbiteriana La Trinidad'),
      fila(
          nombre: 'Inés',
          ap1: 'Echevarría',
          ap2: 'Domínguez',
          sexo: 'Mujer',
          edad: '55',
          iglesia: 'Iglesia del Nazareno Peñas Altas',
          obs: 'Prefiere planta baja'),
      fila(
          nombre: 'Raúl',
          ap1: 'Ibáñez',
          sexo: 'Hombre',
          edad: '63',
          iglesia: 'Pentecostal Monte Sión'),
      fila(
          nombre: 'Yamilé',
          ap1: 'Álvarez',
          ap2: 'Hernández',
          sexo: 'Mujer',
          edad: '27',
          iglesia: 'Bautista Getsemaní'),
      fila(
          nombre: 'Joaquín',
          ap1: "O'Farrill",
          sexo: 'Hombre',
          edad: '33',
          iglesia: 'Asambleas de Dios Betel'),
      fila(
          nombre: 'Débora',
          ap1: 'Valdés',
          ap2: 'Núñez',
          sexo: 'Mujer',
          edad: '29',
          iglesia: 'Bautista Nuevo Pacto'),
    ];
    final textoAnsi = buildCsvDelimited(filasAnsi).replaceFirst('\u{FEFF}', '');
    final bytesAnsi = Uint8List.fromList(latin1.encode(textoAnsi));
    File(ruta('importar_ansi.csv')).writeAsBytesSync(bytesAnsi);

    // Copia de seguridad del evento (un único CSV).
    final bundle = await BackupService(db).export(q.eventId);
    File(ruta('respaldo_evento_qa.csv')).writeAsBytesSync(bundle);

    // ── 4. Verificación: se importan de verdad (ida y vuelta) y se anotan los resultados ──
    final filasOrigen = await qaFilas(q);
    final resultados = <String, String>{};

    // asistentes_120.csv → evento destino vacío (mismos hospedajes y equipos)
    final db1 = qaDb();
    final d1 = await _destino(db1);
    final r1 = await _importar(db1, d1, csv120);
    final filas1 = await qaFilas(d1);
    expect(r1.created, 120);
    expect(r1.warnings, isEmpty, reason: r1.warnings.join(' / '));
    for (var i = 0; i < 120; i++) {
      expect('${filas1[i]}', '${filasOrigen[i]}',
          reason: 'ida y vuelta CSV, persona ${i + 1}');
    }
    resultados['csv120'] =
        '${r1.created} personas nuevas, ${r1.groupsCreated} grupos nuevos, ${r1.churchesCreated} iglesias nuevas, ${r1.warnings.length} avisos';

    // importar_nuevos_30.csv → sobre el evento con las 120 ya cargadas
    final db2 = qaDb();
    final d2 = await _destino(db2, conLas120: true, csv: csv120);
    final ex2 = AttendeeExchange(db2);
    final plan2 = await ex2.plan(d2.eventId, parseAttendeesCsv(csvNuevos));
    expect((plan2.creates, plan2.duplicates, plan2.errors.length), (30, 0, 0));
    final r2 = await ex2.apply(d2.eventId, plan2);
    expect(r2.created, 30);
    final nums = ((await d2.people())
          ..sort((a, b) => a.regNumber.compareTo(b.regNumber)))
        .map((p) => p.regNumber)
        .toList();
    expect(nums, [for (var i = 1; i <= 150; i++) i]);
    resultados['nuevos30'] =
        '30 personas nuevas, 0 errores, 0 duplicados; números 121 a 150';

    // importar_con_errores.csv → sobre el evento con las 120
    final db3 = qaDb();
    final d3 = await _destino(db3, conLas120: true, csv: csv120);
    final ex3 = AttendeeExchange(db3);
    final parse3 = parseAttendeesCsv(csvErrores);
    final plan3 = await ex3.plan(d3.eventId, parse3);
    final r3 = await ex3.apply(d3.eventId, plan3);
    final lineasError = parse3.errors.map((e) => e.line).toList();
    resultados['errores'] =
        '${plan3.creates} personas nuevas, ${plan3.duplicates} posibles duplicados omitidos, ${parse3.errors.length} filas con errores (filas ${lineasError.join(', ')}), avisos de la revisión: ${plan3.warnings.length} (${plan3.warnings.where((w) => w.contains('hospedaje')).length} de hospedaje y ${plan3.warnings.where((w) => w.contains('equipo')).length} de equipo), avisos al importar: ${r3.warnings.length} (pareja que no existe), grupos nuevos: ${r3.groupsCreated}';
    final erroresDetalle =
        parse3.errors.map((e) => '${e.line}: ${e.message}').toList();
    expect(r3.created, plan3.creates);

    // importar_ansi.csv → se lee como Windows-1252 y conserva tildes
    final db4 = qaDb();
    final d4 = await _destino(db4);
    final textoLeido = decodeCsvBytes(bytesAnsi);
    final p4 = parseAttendeesCsv(textoLeido);
    expect(p4.errors, isEmpty);
    expect(p4.rows.map((r) => r.firstName), contains('María Ángeles'));
    final r4 = await _importar(db4, d4, textoLeido);
    expect(r4.created, 8);
    expect((await d4.people()).map((p) => p.lastName1),
        containsAll(['Peña', 'Muñoz', 'Báez', "O'Farrill"]));
    resultados['ansi'] =
        '8 personas nuevas, 0 errores, con tildes y ñ intactas';

    // Respaldo CSV → «Abrir una copia» en una base vacía
    {
      final dbb = qaDb();
      final rep = await BackupService(dbb).import(decodeBundle(bundle));
      final qb = QaEvent(dbb, q.eventId, const [], const {}, const []);
      final fb = await qaFilas(qb);
      expect(fb.length, 120);
      for (var i = 0; i < 120; i++) {
        expect('${fb[i]}', '${filasOrigen[i]}',
            reason: 'respaldo CSV, persona ${i + 1}');
      }
      expect((await dbb.select(dbb.controlSessions).get()).length, 2);
      expect((await dbb.select(dbb.controlRecords).get()).length, 150);
      resultados['respaldo'] =
          '${rep.inserted} filas nuevas, ${rep.updated} actualizadas, ${rep.skipped} sin cambios';
    }

    // ── 5. LEEME.md con los resultados reales ──
    final conteo = {
      for (final e in decodeBundle(bundle).manifest.counts.entries)
        e.key: e.value
    };
    File(ruta('LEEME.md'))
        .writeAsStringSync('''# Datos de prueba de «Mi Evento» (QA)

Generados con los servicios reales de la app y una **semilla fija** (2026). Todos los nombres,
teléfonos y observaciones son **inventados**. Evento: **Congreso QA 2026** (11 al 13 de diciembre de 2026).

## Qué contiene el evento

- **120 personas** (${sexo.$1} hombres y ${sexo.$2} mujeres), edades de 12 a 70, nombres con tildes y ñ, 9 iglesias.
- **15 matrimonios** (3 de ellos con la esposa inscrita 10 puestos después de su esposo), **5 grupos** de iglesia («mantener juntos»).
- **6 equipos** (Rojo, Azul, Verde, Amarillo, Morado, Naranja) repartidos con el equipo automático al inscribir:
  $resumenEquipos
- **11 hospedajes** (albergues y casas; solo hombres, solo mujeres y matrimonios). $conAlbergue personas necesitan hospedaje y **todas** lo tienen (sugerencia aceptada).
  Ocupación: $ocupacion
- **2 sesiones de comida**: «Almuerzo del sábado» (90 personas marcadas, abierta) y «Cena del viernes» (60 marcadas, cerrada). 150 marcas en total.
- Contenido del respaldo CSV: ${conteo.entries.map((e) => '${e.key} ${e.value}').join(', ')}.

## Archivos

| Archivo | Qué es | Filas de datos |
|---|---|---|
| `asistentes_120.csv` | Exportación real de «Exportar asistentes» (`;`, UTF-8 con BOM, 17 columnas). | 120 |
| `plantilla_vacia.csv` | Plantilla vacía: solo los títulos de las columnas. | 0 |
| `importar_nuevos_30.csv` | 30 personas **nuevas** (sin id ni número) para «seguir inscribiendo desde Excel». | 30 |
| `importar_con_errores.csv` | Filas buenas, filas con errores variados, duplicados, hospedaje/equipo/pareja inexistentes. | 21 |
| `importar_ansi.csv` | Windows-1252 («CSV» antiguo de Excel, sin BOM) con tildes y ñ. | 8 |
| `respaldo_evento_qa.csv` | Copia de seguridad completa del evento: un solo CSV con columna `tabla` (se ve en Excel). | – |

## Resultados esperados al importar (comprobados al generar los archivos)

> Para importar un CSV hay que **estar dentro de un evento**: «Copias de seguridad → Importar CSV…».
> El CSV no lleva la configuración: para que `hospedaje` y `equipo` se asignen, el evento destino debe tener
> hospedajes y equipos con **los mismos nombres** (Rojo, Azul, Verde, Amarillo, Morado, Naranja y los 11 hospedajes).
> Si no existen, la importación avisa fila por fila y deja a esas personas sin hospedaje/equipo.
> El respaldo CSV sí lleva todo y se abren desde «Mis eventos → Abrir una copia».

1. **`asistentes_120.csv`** en un evento destino con los mismos equipos y hospedajes (y sin personas): ${resultados['csv120']}.
   El resultado es idéntico al original (nombres, edades, iglesias, teléfonos, hospedaje, equipo, parejas, grupos, números 1–120).
2. **`plantilla_vacia.csv`**: al importarla no hay filas ni errores (la vista previa no tiene nada que importar).
3. **`importar_nuevos_30.csv`** sobre un evento que ya tiene las 120: ${resultados['nuevos30']}.
   Las personas importadas quedan **sin equipo** (el equipo automático solo funciona al inscribir por el formulario; ver docs/QA-informe.md, QA-BUG-006).
4. **`importar_con_errores.csv`** sobre un evento que ya tiene las 120: ${resultados['errores']}.
   Detalle de las filas rechazadas (número de fila de Excel: motivo):
${erroresDetalle.map((e) => '   - $e').join('\n')}
5. **`importar_ansi.csv`**: ${resultados['ansi']}.
6. **`respaldo_evento_qa.csv`** abierto en una base vacía: ${resultados['respaldo']}; quedan las 120 personas, 6 equipos, 11 hospedajes, 15 matrimonios, 5 grupos, 2 sesiones y 150 marcas.

## Cómo regenerarlos

```
cd apps/mi_evento
timeout 580 flutter test qa/generate_qa_dataset_test.dart
```

Los **contenidos** salen siempre iguales (semilla fija); los identificadores internos (`id`) y las marcas de hora cambian en cada generación.
La carpeta de salida se puede cambiar con la variable de entorno `QA_DATASETS_DIR`.
''');
    await db.close();
    for (final d in [db1, db2, db3, db4]) {
      await d.close();
    }
    // ignore: avoid_print
    print('QA-DATASETS escritos en ${dir.path}');
  }, timeout: const Timeout(Duration(minutes: 8)));
}
