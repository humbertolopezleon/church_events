# Informe de QA de punta a punta — Mi Evento «como en Windows»

- **Fecha:** 24 de noviembre de 2026 · **Rama:** `claude/amazing-bohr-0mwlv7` (commit `9b43896`) · **Código de la app:** sin tocar (`lib/` y `packages/` intactos).
- **Prueba:** `apps/mi_evento/qa/windows_qa_test.dart` (carpeta `qa/`, no entra en el CI). Se ejecuta con `cd apps/mi_evento && flutter test qa/windows_qa_test.dart` (≈ 11 min; `QA_FAST=1` hace una pasada corta de depuración).
- **Cómo se probó:** un widget test de Flutter arranca la app REAL (`MiEventoApp`) con SQLite en memoria y la maneja por la interfaz a **1366×768 (100 %)**; además una pasada a **1920×1080** y una comprobación a **1093×614** (el 1366×768 al 125 %, alto < 720 px). En ≥ 900 px las listas son tablas. Todo lo que la app exporta pasa por un `MemoryFileSaver` y se guarda en esta carpeta.
- **No hay Windows ni instalador:** es el motor de pruebas de Flutter (ver «Limitaciones»). Todo lo escrito aquí lo ejecutó la corrida final; lo que no se ejecutó se dice expresamente.

## 1. Resumen ejecutivo

Se recorrió el evento completo de principio a fin: crear el evento, 22 hospedajes y 8 equipos, **216 personas** registradas (43 por el formulario y 173 por «Importar CSV»), **131 preinscritas** y 85 inscritas directamente, confirmación de asistencia, duplicado de evento (completo y solo estructura), pase de participantes, **6 sesiones de comidas** (almuerzo y cena × 3 días) con **1106 marcas**, hospedaje para las 216 personas, búsquedas/filtros/ordenación/exportaciones en todas las vistas y una ida y vuelta del respaldo CSV. Se guardaron **43 archivos exportados**.

Resultado: **34 de 35 bloques de la prueba pasan**; falla 1 (el 8b2, por un defecto real de la app). La corrida automática termina «en verde» solo porque los defectos se registran y la prueba sigue; el veredicto está en las secciones 3 y 5.

Lo más importante:

1. **Defecto ALTO (QA-WIN-06): «Sugerir hospedaje» propone más gente de la que cabe, sin avisar.** Con 216 personas y 312 plazas (de sobra), la propuesta trae **tres tramos para «Posada Betel» (capacidad 20) y la pantalla la acepta sin ningún aviso: queda 58/20**, mientras 9 hospedajes compatibles se quedan vacíos. Se reprodujo también a nivel de datos (`suggestLodging`). Con el volumen del QA anterior (120 personas) no ocurría. Hubo que reubicar **38 personas a mano** por la ficha para llegar a un estado válido.
2. **Defecto MEDIO (QA-WIN-03):** en el CSV, la «M» del sexo se lee como **Mujer**, pero el formulario dice «M (Hombre)». Una hoja llenada con la convención del formulario invierte el sexo sin aviso.
3. **Defecto MEDIO (QA-WIN-07):** los CSV de **reportes y de comidas usan coma** y los demás (asistentes, hospedajes, equipos, eventos) usan punto y coma; en Excel en español los primeros se abren todos en una sola columna.
4. Lo que funciona bien y se comprobó contra la base de datos: formulario (campos obligatorios con `*`, sexo M/F, provincia/municipio de la iglesia, Tab, aviso y diálogo de duplicado, iglesia nueva provincia→municipio→comunidad con sugerencia), importaciones CSV (UTF-8 con BOM `;` y Windows-1252 `,` con columnas en otro orden, filas malas y duplicados detectados, matrimonios por número), confirmación de asistencia, duplicado de evento (ids nuevos, preinscritos, equipos, hospedajes, parejas y grupos), pase de participantes sin repetir, reportes y comidas **solo con confirmados**, comidas (cierre, reabrir, repetido, deshacer, CSV/XLSX/PNG), filtros y ordenación en tablas, y **ida y vuelta del respaldo CSV sin diferencias**.
5. A 1366×768 y 1920×1080 **no apareció ningún desborde ni excepción de interfaz** en las pantallas visitadas.

## 2. Qué se hizo por la interfaz y qué no (sin maquillaje)

| Parte | Cómo |
|---|---|
| Evento, 22 hospedajes, 8 equipos | **UI** (diálogos «Crear evento», «Definir hospedajes», «Definir equipos») |
| 43 personas | **UI**, formulario «Registrar» (4 matrimonios con «Inscribir a su cónyuge ahora») |
| 173 personas | **UI**, «Copias de seguridad → Importar CSV» (CSV A 63 confirmados; CSV B 110 «como preinscripción»). Los archivos los genera la prueba en memoria; el selector de archivos está simulado. |
| Confirmación de asistencia | **UI** (una a una + Deshacer, subconjunto, búsqueda, «a los que se ven», «Confirmar a todos») |
| Duplicar / pasar participantes | **UI** (menú ⋮ del evento) |
| Marcas de comidas | **220 por la UI** (número + Enter, por nombre sin tildes, Deshacer, «ya pasó», «marcar otra vez») y **884 por repositorio** (`MealRepo.mark`) escritas con la app «apagada» (la pantalla se retira, se escribe y se vuelve a abrir) por el bloqueo de Drift. Creación y cierre de las 6 sesiones y todas las exportaciones: UI. |
| Hospedaje | 14 asignados en el formulario al inscribir; **202 por «Sugerir hospedaje» → Aceptar (UI)**; 38 reubicaciones por la ficha (buscador y filtros del formulario) y 3 reasignaciones más; todo por la UI. |
| Listas PDF de un hospedaje | **Por función** (`buildLodgingPdf`), no por la UI: el botón usa `Printing.sharePdf`, que no pasa por el `FileSaver`. |
| Ida y vuelta del respaldo | Por datos (`BackupService.export/import` en una base vacía), no por la pantalla «Abrir una copia» (esa vía ya la cubre `test/qa/windows_movil_test.dart`). |

## 3. Pasos y resultados

| Paso del escenario | Bloque | Resultado | Evidencia |
|---|---|---|---|
| 1. Crear evento, hospedajes y equipos | 1 | **Pasa** | 22 hospedajes por la UI: 5 «Solo hombres», 5 «Solo mujeres», 6 «Matrimonios», 6 «Sin preferencia»; 312 plazas; 8 equipos; al terminar se abre el panel. El calendario de rango funciona a 1366×768. |
| 2. Formulario: obligatorios `*`, sexo M/F, Tab | 2a | **Pasa** | Los 5 obligatorios llevan `*`; segundo apellido y teléfono dicen «(opcional)»; la lista de sexo ofrece «M (Hombre)»/«F (Mujer)»; «Falta el nombre» al guardar vacío; Tab recorre nombre → apellidos → (sexo) → edad → teléfono → iglesia. |
| 2. 43 registros a mano | 2b | **Pasa** | 43 personas (21 preinscritas, 22 confirmadas); provincia y municipio vienen de la iglesia y no son editables; 7 iglesias creadas por «Iglesia nueva» (provincia→municipio→comunidad; «Varadero» se sugiere al escribir «Var»; comunidades nuevas «Centro Urbano», «Miramar», «Casa Blanca»); 4 matrimonios con el mismo estado en ambos; equipo automático para todos; 14 con hospedaje; tildes y ñ. |
| 2. Duplicado | 2c | **Pasa** | Aviso al escribir mismo nombre y primer apellido (mayúsculas/sin tildes); al guardar sale «¿Ya está registrado?»; Cancelar no guarda; «Es otra persona, guardar» guarda y muestra la pantalla de éxito. |
| 2. Importar CSV (confirmados) | 3a | **Pasa** | «63 personas nuevas · 1 posible duplicado · 2 filas con errores» (sin nombre; sexo «Otro»); resultado 63 nuevas, 2 iglesias nuevas, 63 con equipo, 4 grupos; 16 matrimonios vinculados por `pareja_numero`; «incluir duplicados» sube a 64. Fila «M»: ver QA-WIN-03. |
| 2. Importar como preinscripción | 3b | **Pasa** | 110 nuevas, todas **preinscritas**; el hospedaje escrito en el archivo se ignora; iglesias escritas en minúsculas/con espacios no se duplican (catálogo = 9); CSV en Windows-1252 con columnas reordenadas se lee bien. |
| 2. Totales | 3c | **Pasa** | **216 personas** (≥ 200), **131 preinscritas** (≥ 100), 85 confirmadas; números de inscripción únicos; 0 duplicados nombre+apellido+edad. |
| 3. Confirmar asistencia | 4 y 8a | **Pasa** | Una a una (nº 216) + «Deshacer» devuelve a preinscrita y se reconfirma; subconjunto de 4; búsqueda «nunez» (16 coinciden); sin resultado → «Ningún preinscrito coincide»; «a los que se ven» por iglesia; diálogo con cantidad. Quedaron 13 preinscritos a propósito (para el paso 4) y «Confirmar a todos» los llevó a 0. **Final: 216 confirmados.** |
| 4. Duplicar evento (todo) | 5a | **Pasa** | Copia con 216 participantes, **todos preinscritos**, ids de participantes/equipos (8)/hospedajes (22)/grupos (4) distintos, 22 parejas con ids de la copia, cada persona conserva su hospedaje y su equipo (los de la copia). |
| 4. Duplicar solo estructura | 5b | **Pasa** | 0 participantes, 8 equipos, 22 hospedajes. |
| 4. Pasar participantes | 5c | **Pasa** | Original→copia completa: «0 personas pasadas · 216 ya estaban». Original→copia vacía: «216 personas pasadas» (preinscritas). Repetir: «0 pasadas · 216 ya estaban». |
| 4. Reportes y comidas solo confirmados | 6 | **Pasa (con un defecto)** | Con 13 preinscritos pendientes: Reportes dice «203 inscritos» y su CSV trae 203 filas; Comidas «Inscritos» = 203; el filtro «Preinscritos» da 13 y su CSV 13 filas. `MealRepo.mark` rechaza al preinscrito («confirma primero su asistencia»), **pero la pantalla no muestra ese aviso**: ver QA-WIN-05. |
| 5. Comidas (6 sesiones) | 7.1–7.7 | **Pasa** | Almuerzo y cena de viernes, sábado y domingo (+1 sesión de verificación del paso 6). Pasaron por sesión: 194 (tras reabrir), 183, 187, 173, 189, 179 de 203. Contador de pantalla = base de datos en todas; Deshacer, «YA PASÓ» → «Entendido» (cuenta 1 repetido evitado) y «Marcar otra vez» (no suma a «Pasaron»); lista «Faltan (n)»; cerrar → resumen = base; reabrir la 1.ª, marcar y volver a cerrar. Ningún preinscrito con marcas. 1107 registros de marca (1106 activos). |
| 5. Exportaciones de comidas | 7.x | **Pasa** | Por sesión: CSV (filas «Sí» = pasaron), XLSX (hojas Resumen/Pasaron/No pasaron, ZIP válido) y PNG 1080×1350 válido. |
| 6. «Sugerir hospedaje» → aceptar | 8b | **Pasa técnicamente, pero genera sobrecupo** | Una propuesta cubre a las 202 personas pendientes y no deja a nadie sin hospedaje. Ver 8b2. |
| 6. Comprobar capacidad y corregir a mano | 8b2 | **FALLA (defecto QA-WIN-06)** | Tras aceptar: «Posada Betel 58/20» y 9 hospedajes vacíos. 38 reubicaciones por la ficha (buscador + filtros «con plazas libres» y «solo compatibles») → 0 hospedajes excedidos. |
| 6. Asignación manual por ficha | 8c | **Pasa** | 3 reasignaciones. Sonda: elegir una casa de matrimonios para una mujer soltera muestra el aviso «solo acepta matrimonios y queda 1 persona sin su cónyuge» (no bloquea, por diseño). |
| 6. Verificación final por consulta | 8d | **Pasa (tras la corrección manual)** | **216 de 216 con hospedaje**; 0 hospedajes excedidos; 0 personas en hospedaje incompatible con su sexo/estado; **22 de 22 matrimonios juntos**. |
| 7. Asistentes: búsqueda, filtros, orden, CSV | 9a | **Pasa** | Tabla a 1366 px; orden por Edad (12 ↑, 70 ↓); «nunez» → 22; Sexo=Mujeres 101 (= base); +Iglesia 15; +Hospedaje 6; +Equipo 1; Asistencia/«Hospedaje» combinados; sin filtros vuelve a 216. CSV filtrado (101 filas) y completo (216 filas, 17 columnas). |
| 7. Hospedajes | 9b | **Pasa** | Búsqueda «casa» 16/22; Acepta=Matrimonios 6; «solo con plazas libres» 5; orden por Capacidad; CSV 5 y 22 filas. |
| 7. Equipos | 9c | **Pasa** | «8 equipos · 216 personas · 0 sin equipo»; búsqueda; CSV de 216 filas. Equipos de 27 personas cada uno (H 14–15 / M 12–13, edad media 35,0–36,4). |
| 7. Mis eventos | 9d | **Pasa** | Tabla, búsqueda («estructura» → 1 de 3), orden por Nombre, CSV de 3 filas. (El menú ⋮ queda fuera de pantalla con nombres largos: QA-WIN-04.) |
| 8. Plantilla, CSV de asistentes y respaldo | 10a | **Pasa** | Plantilla con las 17 cabeceras; CSV de 216 filas; respaldo CSV del evento (1434 filas, 13 tablas). |
| 8. Reportes (xlsx, csv, pdf) | 10b | **Pasa** | Con todos confirmados: «216 inscritos»; XLSX (Resumen + Asistentes), CSV (con y sin teléfono) y PDF (cabecera `%PDF-` válida, 54 848 B). |
| 8. CSV y respaldo de cada evento | 10c | **Pasa** | CSV de asistentes de los 3 eventos y respaldo CSV de las 2 copias. |
| 8. Ida y vuelta del respaldo CSV | 11 | **Pasa** | Base vacía + importar: 216 = 216 personas, **0 diferencias** en número, nombre, sexo, edad, iglesia, teléfono, hospedaje, equipo, pareja, grupos y observaciones; ids, estado, `confirmedAt` y necesidad de hospedaje idénticos; 7 sesiones y 1107 marcas, 22 hospedajes, 8 equipos y 4 grupos iguales. El archivo guardado por la UI también se reabre (216 personas). |
| Pasada 1920×1080 y alto < 720 | 12 | **Pasa** | Panel, Asistentes, Confirmar, Hospedajes, Equipos, Comidas, Reportes, Configuración y Copias sin desbordes a 1920×1080; filtros visibles; Mis eventos y Asistentes en tabla. A 1093×614 los filtros arrancan plegados, «Filtros» los despliega y los pliega, sin desbordes. |

## 4. Cifras reales

- **Eventos:** 3 («Congreso Nacional QA 2026», «… (copia completa)», «… (solo estructura)»).
- **Personas del evento principal:** 216 (115 hombres, 101 mujeres); **por vía:** formulario 43 (21 preinscritas / 22 confirmadas) · CSV A 63 (confirmadas) · CSV B 110 (preinscritas). **Preinscritas al inicio: 131; confirmadas directas: 85; confirmadas al final: 216; preinscritas al final: 0** (tras el paso 4 quedaron 13 a propósito).
- **Iglesias:** 9 (7 creadas por la UI, 2 por el CSV), 8 provincias/municipios distintos, 4 grupos, 22 matrimonios.
- **Equipos:** 8 de 27 personas (todas con equipo automático).
- **Hospedajes:** 22 (312 plazas) · asignaciones: **216/216** (14 en el formulario, 202 por «Sugerir hospedaje», 41 reubicaciones/reasignaciones manuales por la ficha). Sobrecupo tras la propuesta: Posada Betel 58/20; tras la corrección manual: 0. Al final quedan vacíos 7 hospedajes (Ñuri Peña, Ñáñez, Rivas, Núñez, Peña, Yunier Acosta, Monte Sión): no es defecto, sobraban plazas.
- **Comidas:** 7 sesiones (6 del plan + 1 de verificación), 6 cerradas · **marcas: 220 por la UI + 884 por repositorio = 1105 personas-sesión (1106 registros activos, uno es el «marcar otra vez»; 1107 con la deshecha)** · repetidos bloqueados: 1.
- **Duplicados de evento:** copia completa 216 personas; pase de participantes: 216 pasadas, repetición omitió las 216.
- **Archivos exportados:** 43 (ver tabla; la carpeta pesa ≈ 1,5 MB con INFORME y log).

### Archivos exportados (en esta carpeta)

| Tipo | Archivos | Bytes (ejemplos) |
|---|---|---|
| CSV de asistentes completo / filtrado (mujeres) / filtrado (preinscritos) | `25-`, `24-`, `04-`, `31-`, `43-` | 35 176 / 16 583 / 1 994 |
| Plantilla CSV | `30-plantilla--plantilla-asistentes.csv` | 159 |
| CSV hospedajes (completo y filtrado), equipos, eventos | `27-`, `26-`, `28-`, `29-` | 1 936 / 505 / 15 112 / 270 |
| Respaldo CSV del evento principal y de las 2 copias | `32-`, `40-`, `42-` | 438 304 / 109 705 / 89 025 |
| CSV de asistentes de cada evento | `43-`, `39-`, `41-` | 35 176 / 30 864 / 29 132 |
| Resúmenes de comidas (6 sesiones × csv, xlsx, png + 1 csv tras reabrir) | `05-` a `23-` | csv ≈ 18 000, xlsx ≈ 15 000, png ≈ 14 500 |
| Reportes con pendientes y finales (xlsx, csv, csv con teléfono, pdf) | `01-`–`03-`, `33-`–`36-` | xlsx 16 179 / 18 634; pdf 49 640 / 54 848 |
| Listas PDF de 2 hospedajes (por función) | `37-`, `38-` | 19 160 / 15 803 |

(La tabla completa con tamaños exactos está en `INFORME-detalle-automatico.md`.)

## 5. Defectos y observaciones

| ID | Severidad | Dónde | Resumen |
|---|---|---|---|
| **QA-WIN-06** | **Alta** | Hospedajes → «Sugerir hospedaje» | La propuesta repite el mismo hospedaje «Sin preferencia» en varios tramos y la UI no avisa: sobrecupo y hospedajes vacíos. |
| **QA-WIN-03** | Media | Copias → Importar CSV | «M» se lee como Mujer; el formulario dice «M (Hombre)». |
| **QA-WIN-07** | Media | Reportes y Comidas → CSV | Usan coma; el resto de CSV usa punto y coma (Excel en español los abre en una columna). |
| QA-WIN-05 | Baja | Comidas | Un preinscrito no sale en la búsqueda y el aviso «confirma primero» nunca se ve. |
| QA-WIN-04 | Baja | Mis eventos (tabla) | El menú ⋮ queda fuera de la ventana a 1366 px con nombres largos. |
| QA-WIN-01 | Baja | Registrar | «Preinscripción» sigue activado tras «Guardar y registrar otro». |
| QA-WIN-02 | Baja | Registrar | El aviso verde cubre parte del botón de guardar a 768 px de alto durante ~4 s. |

### QA-WIN-06 · «Sugerir hospedaje» excede la capacidad sin avisar (ALTA)
- **Pasos:** evento con 216 personas que necesitan hospedaje (115 hombres, 101 mujeres, 22 matrimonios) y 22 hospedajes (312 plazas: 5 «Solo hombres» 100 plazas, 5 «Solo mujeres» 100, 6 «Matrimonios» 48, 6 «Sin preferencia» 64). «Hospedajes → Sugerir hospedaje → Buscar propuestas → Aceptar».
- **Esperado:** una propuesta que no exceda ninguna capacidad (hay 312 plazas para 216), o un aviso claro.
- **Obtenido:** la propuesta única trae tres tramos para «Posada Betel» (cada uno «Ocupación: 0 → 20 de 20 plazas»: 20 + 20 + 18 personas); **ningún aviso visible** (los avisos de capacidad solo se calculan por tramo y solo en «Modificar»). Al aceptar: **Posada Betel 58/20** y vacíos: Casa Hno. Ramón Cruz, Casa Hna. Teresa Gil, Casa Hna. Ñuri Peña, Casa Familia Ñáñez, Rivas, Núñez, Peña, Casa Hno. Yunier Acosta y Posada Monte Sión. En la prueba hubo que mover a 38 personas a mano.
- **Evidencia:** `INFORME-detalle-automatico.md`, pasos 8b y 8b2 (texto de los tramos de la propuesta); reproducido con la capa de datos (`suggestLodging`, mismos 214 de entrada → «Posada Betel: 60/20»). Con 120 personas (QA anterior) no aparecía.
- **Causa probable:** el comodín «Sin preferencia» (`LodgingAccepts.any`) se reutiliza para cada categoría (matrimonios, hombres, mujeres) sin descontar lo ya asignado en los tramos anteriores (`packages/mi_evento_core/lib/src/lodging_suggest.dart`), y `_warnings` valida cada tramo contra la ocupación actual, no contra la suma de tramos.
- **Impacto:** el hospedaje es una de las funciones centrales; el administrador aceptaría la propuesta creyendo que está bien y entregaría a un anfitrión una lista con 58 personas para 20 plazas.

### QA-WIN-03 · «M» del CSV = Mujer (MEDIA)
Fila `Mario Ñáñez-Sexom;sexo=M` del CSV A se importó como mujer. El formulario etiqueta «M (Hombre) / F (Mujer)», pero `parseSexCell` (`packages/mi_evento_core/lib/src/attendee_csv.dart`) interpreta «M» como mujer (y «H» como hombre). Sugerencia: no aceptar «M»/«F» sueltas (pedir Hombre/Mujer) o avisar en la vista previa.

### QA-WIN-07 · CSV de reportes y de comidas con coma (MEDIA)
Los CSV de **Reportes** (`asistentes-<evento>.csv` de «Listado en CSV») y de **Comidas** (resumen) se escriben con `,` (`buildCsv` en `packages/mi_evento_core/lib/src/meals.dart`), mientras que asistentes, hospedajes, equipos y eventos usan `;` con BOM (`buildCsvDelimited`). En un Windows con configuración regional en español, Excel abre los de coma con todo en la columna A. Evidencia: archivos `01-`, `05-`, `33-`, `36-` frente a `25-`, `27-`, `28-`. (Nota: el nombre del CSV de Reportes coincide con el del CSV de la pantalla Asistentes, `asistentes-<evento>.csv`, pero con otro contenido y otro separador.)

### QA-WIN-05 · Comidas no muestra el aviso del preinscrito (BAJA)
Con la persona nº 110 preinscrita, la búsqueda por su número en Control de comidas dice «Nadie con ese nombre. ¿Falta registrarlo?». El aviso «confirma primero su asistencia» solo existe en `MealRepo.mark` (lo comprobé: rechaza con ese texto). Un operador creerá que no está inscrita.

### QA-WIN-04 · Menú ⋮ de «Mis eventos» fuera de pantalla (BAJA)
Con el evento y su «(copia completa)» la tabla es más ancha que 1366 px y el ⋮ (Duplicar / Pasar participantes / Eliminar) queda en x≈1492; hay que desplazar la tabla en horizontal para encontrarlo.

### QA-WIN-01 y QA-WIN-02 (BAJAS)
«Preinscripción» (`preregister`) no se limpia con `_reset()` tras «Guardar y registrar otro» (puede ser intencional para cargar lotes, pero es fácil dejar preinscrito a quien sí llegó). Además, a 768 px el SnackBar «Listo. … quedó registrado/a como asistente nº N» tapa el botón «Guardar y registrar otro» unos 4 s (en la prueba un toque inmediato cayó sobre el aviso).

### Observaciones (no son defectos)
- A 1366×768 el menú lateral no cabe para un administrador (12 entradas): «Mis eventos», «Usuarios» y «Copias de seguridad» exigen desplazar el menú; el menú sí se desplaza.
- Los filtros de hospedaje del formulario («Con plazas libres», «Solo los que aceptan…») y el buscador se conservan al pulsar «Guardar y registrar otro» (como «Preinscripción»). Alternar sin mirar su estado cambia el filtro al revés.
- El formulario permite guardar a una mujer soltera en una casa de «Matrimonios»: solo muestra el aviso rojo (por diseño: «solo se avisa»).
- La copia de evento «siempre copia los tipos de control», pero en el momento de duplicar el original no tenía ninguno (se crean al abrir Comidas), así que **eso no se pudo comprobar**.
- La copia «(solo estructura)» acabó con 216 personas porque el paso 5c le pasó los participantes (era el destino vacío de la prueba); su CSV `41-` lo refleja.

## 6. Limitaciones

- **No es Windows:** es el motor de widget tests de Flutter con SQLite en memoria, ventana simulada a dpr 1, `MemoryFileSaver` y selector de archivos simulado. No se probaron «Guardar como…» nativo, impresión real, DPI/escala real de Windows, instalador ni rendimiento real. Lo del alto < 720 px se comprobó con 1093×614 (el 1366×768 al 125 %).
- **Drift se cuelga** si la prueba escribe mientras una pantalla observa hospedajes/equipos; las 884 marcas de comida «por repositorio» se escribieron con la app apagada y reabierta (entran por `MealRepo.mark`, igual que la pantalla, con constancia arriba).
- El reloj de pruebas es simulado: los tiempos de la corrida (≈ 11 min en total; 55 s para registrar 43 personas a mano, 2 s por cada importación CSV) **no** son rendimiento de usuario.
- En la prueba se esperó a que el SnackBar desapareciera antes de tocar botones que cubría (lo que haría una persona).
- Los CSV de importación son generados por la prueba (UTF-8 con BOM y `;`, y Windows-1252 con `,` sin BOM); no se probaron archivos reales guardados por Excel.
- Una sola corrida completa de la versión final; las anteriores sirvieron para depurar la prueba (errores de la prueba, no de la app, como botones bajo el pliegue a 768 px o filtros que se conservan entre registros).

## 7. Archivos de esta carpeta

- `INFORME.md` (este) · `INFORME-detalle-automatico.md` (evidencia paso por paso y tabla de archivos con tamaños exactos) · `log-corrida.txt` (traza de la corrida) · 43 archivos exportados numerados por orden de exportación (`NN-<etiqueta>--<nombre original>`).
- Prueba reproducible: `apps/mi_evento/qa/windows_qa_test.dart`.
