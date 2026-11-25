# Mi Evento — Registro de decisiones

Qué se decidió, **por qué** y qué falta por decidir. Sirve de contexto para quien (persona o IA) continúe
el trabajo: antes de cambiar algo de lo de aquí, léelo; si una decisión ya no sirve, cámbiala **aquí también**
(con fecha y motivo). El plan general y la arquitectura están en `docs/PLAN.md`.

Convenciones: ✅ decidido · ⏳ pendiente de confirmar · «Recomendación aplicada» = el usuario delegó la decisión
en la recomendación del asistente (2026-11-25).

---

## 1. Forma de trabajar

| Decisión | Por qué |
|---|---|
| Una rama nueva y un PR a `main` por cada fase/bloque; **no se fusiona sin que el usuario lo pida**. | El usuario revisa y prueba entre fases. |
| Evitar `force-push`. Si un *squash* deja conflictos, se rehace la rama desde `main` con `cherry-pick` (rama `-v2`). | Los PR se fusionan con *squash*, así que la rama anterior queda con commits duplicados. |
| Antes de cada PR: `cd apps/mi_evento && flutter analyze && flutter test`; en el núcleo `dart analyze && dart test`. | La CI (`.github/workflows/ci.yml`: core, app, apk, windows) **falla incluso con avisos `info`**. |
| Se avisa con honestidad de lo que no se pudo probar (Android/Windows/Excel reales). | Solo hay pruebas automáticas y capturas del banco de pruebas. |
| Cambios visuales → capturas con `qa/capturas_ui_test.dart` (`QA_SHOTS_DIR=… flutter test qa/capturas_ui_test.dart`, fuera del CI). Para los iconos hace falta `FLUTTER_ROOT`. | Se revisa la interfaz sin dispositivo. |
| Los binarios se bajan del artefacto de la CI (`gh api …/actions/artifacts/<id>/zip`) y se envían al usuario. | Los enlaces de artefactos exigen iniciar sesión. |
| El APK es **de depuración** (no hay clave de firma). Windows: instalador y portable. | Sin clave de firma no hay APK de publicación. |
| Los commits terminan con `Co-Authored-By` y `Claude-Session`; los PR, con «Generated with Claude Code» y la URL de la sesión. | Trazabilidad. |
| Respuestas y textos de la app **siempre en español**. | Usuarios hispanohablantes. |

## 2. Diseño de interfaz (ya hecho; respetar)

- Los patrones valen en **móvil y escritorio**: en escritorio las listas son tablas (`DataTableView`, `useTables`, corte a 900 px).
- Widgets compartidos: `AppHeader` (menú ⋮ con claves por pantalla), `ListToolbar` + `filter_spec.dart` (hoja de filtros, chips), `AppFab`, `LabeledField` (etiqueta **siempre encima** del campo; «(opcional)» en la etiqueta), `plural()` / `pluralWord()` / `agree()`. Tema en `lib/theme/app_theme.dart` (`Brand`, `headStyle`, `bodyStyle`).
- **Sin «0» en las frases** («Sin asistentes», «Ninguna ocupada», «Sin equipos nuevos»). *Por qué:* la fuente Atkinson (accesibilidad) tacha el cero y se lee como «Ø». También se evita escribir cifras con ceros en la ayuda («al menos 1» en vez de «de 1 a 500»).
- La búsqueda solo cubre campos **sin filtro propio** (Asistentes: nombre y número; Iglesias: nombre; Hospedajes: nombre, anfitrión y zona).
- El aviso ámbar «N personas sin hospedaje» abre Asistentes filtrado (`attendeesPresetLodgingProvider`).
- Letra hasta el 130 % sin desbordes; las ayudas largas van **después** del resumen y las decisiones en los diálogos (con letra grande empujaban lo importante fuera de vista).

## 3. Reglas de hospedaje (`packages/mi_evento_core/lib/src/lodging_rules.dart`)

- «Acepta» = Solo hombres / Solo mujeres / Matrimonios / Sin preferencia. Un hospedaje de matrimonios solo recibe a quien queda junto a su cónyuge.
- La **capacidad solo avisa** (el usuario decide); la **compatibilidad bloquea** (ver también §7: cambios en curso). *Por qué:* principio de la decisión humana (PLAN §3) para plazas, pero un hombre en un hospedaje de mujeres es un error, no una preferencia.
- El borrado es **lógico** (`deletedAt`).
- Formulario de hospedaje: capacidad con −/+ (mínimo 1) y «Acepta» en cuadrícula 2×2.

## 4. CSV: importar y exportar

### Formato
- `buildCsvDelimited` escribe **BOM + primera línea `sep=;` + CRLF**, separador `;`, listas con `|`. *Por qué:* Excel en español respeta tildes (BOM) y separa bien las columnas aunque su separador regional sea otro (`sep=`).
- `parseCsv` acepta `;`, `,` o tabulador (lo adivina por la primera fila), omite la línea `sep=`, filas vacías y el BOM.
- `decodeCsvBytes` lee UTF-16 («Texto Unicode»), UTF-8 y, si no, **Windows-1252** de verdad (fase 4). *Por qué:* antes era latin1 y las comillas tipográficas “ ”, rayas, «€» y «…» (0x80–0x9F) salían como controles; es lo que pasa al pegar desde Word y guardar como «CSV» en Excel.
- Las celdas que Excel tomaría por fórmula (`=`, `+`, `-`, `@`, tabulador) se **neutralizan con un apóstrofo** al exportar y `readCsvTable` lo **quita al importar** (ida y vuelta sin pérdida). *Coste conocido:* Excel muestra el apóstrofo (p. ej. en `+53 …`). Se acepta por seguridad.

### Plantilla y ayuda de columnas (fase 1)
- `CsvSpec`/`CsvColumn` (`lib/data/csv_spec.dart`) es la **única fuente** de las columnas de cada CSV: de ahí salen la ayuda «Columnas del CSV» y la plantilla vacía, y una prueba comprueba que coinciden con los encabezados reales. *Por qué:* evita que ayuda, exportación e importación se desincronicen.
- La plantilla vacía lleva **solo los encabezados** (sin fila de ejemplo). *Por qué:* una fila de ejemplo se importaría como dato real.
- Menú ⋮ de cabecera: «Plantilla CSV vacía» y «Columnas del CSV»; botones equivalentes en los estados vacíos (claves `*-vacio-plantilla`, `*-vacio-columnas`, distintas de las del menú para no chocar en las pruebas).
- Asistentes e Iglesias **no** se migraron a `TableImporter`: solo se añadió su especificación de columnas. *Por qué:* menos riesgo; sus importadores ya funcionan y tienen sus propias pruebas.

### Hospedajes (fase 2)
- Importar y exportar son simétricos (`LodgingExchange.export()`/`toRows`).
- Se exportan **todos** los hospedajes del evento (no solo los filtrados), ordenados por nombre y sin los borrados. *Por qué:* el usuario los quiere para **reutilizar las capacidades en otros eventos**; un filtro no debe vaciar un respaldo.
- El CSV **no lleva ocupantes ni `ocupadas`/`libres`**. *Por qué:* el usuario no quiere los asistentes asignados. Los CSV antiguos con esas columnas siguen importándose (se ignoran). Las asignaciones persona→hospedaje ya viajan por el CSV de Asistentes (columna `hospedaje`).
- Si el nombre ya existe, se actualiza.

### Equipos (fase 3)
- **Dos CSV separados** en el menú ⋮ de Equipos: «personas por equipo» (`TeamExchange`, claves `eq-importar`/`eq-exportar`) y «equipos» = definición (`TeamDefinitionExchange`, `eq-def-*`). *Por qué:* son cosas distintas (quién está en cada equipo / cómo es cada equipo) y mezclarlas confundía el archivo.
- Definición: `equipo`, `color` (nombre de la paleta o `#RRGGBB`), `capitan_numero` (número de inscripción) y las informativas `capitan` e `integrantes`. Si el equipo existe se actualiza; si no, se crea. No asigna personas.
- **Capitán que no es del equipo:** nunca se mueve a nadie sin permiso. La revisión muestra una **decisión** (`ImportDecision`) con: moverlo y nombrarlo capitán (propuesta) · no cambiar el capitán · elegir a otro integrante del equipo. *Por qué (palabras del usuario):* «asígnalo al equipo y avisa, dando la elección de elegir otro capitán si no se aprueba el movimiento».
- `TeamRepo.create` sustituye al alta frágil anterior (`createMany` + leer el último + `update`).
- `TableImporter.apply(csv, {choices})` recibe las decisiones; los demás importadores solo adaptan la firma.

### Ida y vuelta (fase 4)
- Prueba de ida y vuelta de iglesias, hospedajes y definición de equipos en **7 formas de guardado** de Excel (UTF-8 con/sin BOM, ANSI con `;` y con coma, UTF-8 con coma y tabulador, «Texto Unicode»). Se verificó que la prueba falla con el decodificador antiguo.

## 5. Estado de las entregas (todo en `main`)

Revisión de interfaz completa (#11, #14, #15, #17), CSV de ejemplo regenerados (#18), plantilla y ayuda (#19), hospedajes simétricos (#20), definición de equipos (#21), ida y vuelta y ANSI (#22).

## 6. Prioridades para el primer evento real (decididas 2026-11-25)

Principio: primero lo que **sin eso el evento no funciona**; lo demás, después.

**Imprescindible, en este orden:**
1. Ficha del asistente: mostrar **siempre** los hospedajes con plazas; quitar el filtro «Con plazas libres» (conservar el hospedaje actual aunque esté lleno).
2. Capacidad inicial **1** propuesta al crear un hospedaje (revierte el «empieza vacía a propósito» de la revisión de interfaz: el usuario lo pidió expresamente).
3. Fechas del evento: **no anteriores a hoy** (crear, copiar y editar; al editar un evento ya empezado se respetan sus fechas) y botón **«Hoy»** en el selector.
4. Si el evento no usa equipos, **no mostrar Equipos** en ninguna parte de la UI.
5. Hospedaje **mixto** (ver §7).
6. Matrimonios en hospedajes **separados**, opcional (ver §7).
7. «Sugerir hospedaje»: buscador al elegir personas y «Marcar todos / Desmarcar todos».
8. Control de comidas (ver §8) y **Esc** para cerrar ventanas/cancelar en escritorio.

**Puede esperar:** asistente (wizard) de configuración inicial con pasos omitibles y advertencia; exportar/importar sesiones de comidas; centro de notificaciones en escritorio; atajos de teclado y su ayuda; revisión de la gestión de equipos.

## 7. Reglas de hospedaje nuevas (recomendaciones aplicadas)

- **Hospedaje mixto:** dos valores nuevos de «Acepta»: **«Solo mujeres o matrimonios»** y **«Solo hombres o matrimonios»** (p. ej. 2 plazas: 2 mujeres **o** un matrimonio, sin mezclar). Se guardan en la columna `accepts` (ya es texto), **sin migración de base de datos**. Dentro de un hospedaje no se mezclan solteros y matrimonios: manda el primer ocupante. *Por qué:* cubre el caso pedido con el menor cambio de modelo.
- **Separar matrimonios (opcional):** se activa **al sugerir** (casilla en «Sugerir hospedaje») y también se permite en la **asignación manual con confirmación**. Es el último recurso: solo si no hay hospedaje que reciba matrimonios. Marca a los separados para poder reunirlos después. *Por qué:* el bloqueo actual no tiene excepciones y deja a esas personas sin hospedaje; la confirmación mantiene la decisión humana.

## 8. Control de comidas (recomendaciones aplicadas)

- La sesión lleva **fecha al crearla**, dentro del rango del evento; la sugerida es el **primer día** del evento.
- **Repetidos:** se advierte a quien registra y puede permitirlo; queda **registrado** (`repeatOverride`) y se muestra en estadísticas, con la **distribución de veces** (1, 2, 3 o más) por sesión, no solo cuántas personas repiten.
- **Registrar un asistente desde Control de comidas** con una **marca visible** que lo identifique (campo nuevo en la base de datos; implica migración).
- **Exportar/importar sesiones** (las configuradas y las ya realizadas): en **dos archivos separados**, sesiones y quién pasó en cada una. *Por qué:* las sesiones sirven de plantilla para otro evento; los registros, de respaldo. (Pospuesto: ver §6.)

## 9. Teclado y notificaciones (escritorio)

- **Esc** cierra diálogos y cancela; en un formulario con cambios pregunta antes de descartar (pendiente). Los diálogos de Material ya lo hacen; las pantallas completas lo hacen desde el bloque A con `lib/ui/escape_key.dart`. *Detalle técnico importante:* cada ruta de página deja `DismissIntent` **deshabilitado** y eso tapa a cualquier manejador de más arriba, por eso se usa un intent propio (`GoBackIntent`) que solo se habilita si la ruta superior es una pantalla (`TopRouteObserver`); con un diálogo arriba no interviene.
- **«Back»** se interpreta como **Retroceso (fuera de campos de texto) y Alt+←** = volver atrás. *Recomendación aplicada.*
- Atajos propuestos: F1 / Ctrl+/ ayuda de atajos; Ctrl+1…6 secciones; Ctrl+N nuevo; Ctrl+F o «/» buscar; Ctrl+Shift+F filtros; Ctrl+S guardar; Ctrl+Enter guardar y cerrar; Ctrl+I / Ctrl+E importar/exportar; ↑↓ Enter en listas; en comidas Enter marca y Ctrl+Z deshace. **✅ Tabla aprobada por el usuario (2026-11-25).** Se implementa después de los imprescindibles y debe incluir una ayuda dentro de la app para aprenderlos.
- **Notificaciones:** los avisos de la parte inferior pasan a un **centro de notificaciones solo en escritorio** (campana con contador, «marcar como leída»). El móvil mantiene el aviso temporal. *Recomendación aplicada.*

## 10. Pendiente de decidir

- ⏳ **Gestión de equipos:** crear, editar, eliminar y ver ya existen. El usuario pidió «el sistema debe permitir la gestión de equipos»; falta saber **qué echa en falta** (¿acciones en la tabla de escritorio?, ¿pantalla de detalle?, ¿no encontrarlo?).
- ⏳ Decisión heredada de `PLAN.md`: ¿el equipo automático debe reubicar solo o proponer un ajuste cuando no cumple los topes? (hoy solo avisa).

## 11. Bloque A de imprescindibles (hecho en la rama `feat/imprescindibles-a`)

- **Ficha del asistente:** sin filtro «Con plazas libres»; la lista **siempre** excluye los hospedajes llenos (se conserva el elegido aunque esté lleno). Queda el filtro de cantidad de plazas («2 o más» para un matrimonio).
- **Capacidad inicial = 1** en «Nuevo hospedaje».
- **Fechas del evento** (`lib/ui/event_dates.dart`): un diálogo propio con pestañas «Inicio» y «Fin» sobre un calendario, botón **Hoy**, y sin días anteriores a hoy. *Por qué propio:* `showDateRangePicker` de Flutter no tiene botón «Hoy» y no se puede añadir sin trucos. Al **editar** un evento que ya empezó se respeta su fecha de inicio (`earliestEventDate`); al **copiar** un evento ya pasado se propone hoy conservando su duración. La validación «no antes de hoy» está **solo en la interfaz** (el repositorio acepta cualquier fecha: las importaciones y pruebas usan fechas arbitrarias).
- **Equipos oculto** si el evento no los usa (menú lateral e inferior, columna de la tabla de Asistentes y ficha de la sesión de comidas). Los filtros por equipo ya dependían de que existan equipos. *No* se ocultó Hospedajes cuando el evento no los ofrece (no se pidió).
- **Esc** en escritorio vuelve atrás en pantallas completas (ver §9).

## 12. Bloque de hospedaje: mixto y matrimonios separados (hecho en la rama `feat/hospedaje-mixto-y-separados`)

- **Hospedaje mixto:** `LodgingAccepts.menOrCouples` / `womenOrCouples` («Solo hombres o matrimonios» / «Solo mujeres o matrimonios»), guardados como `men_couples` / `women_couples` en la columna `accepts` (**sin migración**).
  - Una persona **sola** debe ser del sexo del hospedaje. Una mujer casada cuyo esposo está en otro sitio cuenta como mujer sola; un hombre casado sin su esposa en un hospedaje de mujeres, no.
  - **No se mezclan solteros y matrimonios** dentro del mismo hospedaje (bloqueo, con mensaje). Un matrimonio es «matrimonio» cuando los dos cónyuges están dentro.
  - En la sugerencia, el mixto es el **último recurso** de su tipo (puntúa −3 frente a un hospedaje específico) y cuenta como lugar para matrimonios. `LodgingCandidate.occupantMix` dice qué hay dentro; dentro de una misma propuesta se va actualizando para que dos bloques no mezclen un mixto.
  - El formulario de hospedaje pasa a una cuadrícula 2×3 con una línea de ayuda; el CSV acepta los dos valores nuevos.
- **Matrimonios por separado (opcional):** casilla «Si no hay hospedaje para matrimonios, alojarlos por separado» en «Sugerir hospedaje» (`SuggestOptions.splitCouples`, desactivada por defecto).
  - Solo se separan **los matrimonios que sobran** (los que no caben en hospedajes que reciben matrimonios: «matrimonios», «sin preferencia» y mixtos libres); el esposo va con los hombres y la esposa con las mujeres. La propuesta lo explica y lo marca en `LodgingProposal.splitCoupleIds`.
  - *Asignación manual:* se mantiene el aviso que ya existía en la ficha («esto separa al matrimonio…») en vez de un diálogo de confirmación aparte, porque ya es visible antes de guardar y no frena al operador.

## 13. «Sugerir hospedaje» y control de comidas (rama `feat/sugerir-buscar-y-comidas`)

- **Elegir personas (sugerir hospedaje):** buscador por nombre (sin tildes) o número, contador «N de M · K marcadas» y «Marcar todos» / «Desmarcar todos». Estos dos botones actúan **solo sobre lo que se ve** (la búsqueda filtra); marcar a una persona sigue arrastrando a su cónyuge. *Por qué sobre lo visible:* permite componer grupos («todos los de tal iglesia») sin tocar al resto.
- **Fecha de la sesión de comidas:** `MealRepo.createSession(date:)` guarda `scheduledAt` y **rechaza fechas fuera del evento** (`DataException`); la interfaz propone el **primer día del evento** (y el nombre sugerido usa ese día de la semana, «Almuerzo del sábado»). Las sesiones antiguas sin fecha siguen siendo válidas.
- **Repetidos:** el modelo ya existía (`mark(repeat: true)` crea otra marca con `repeatOverride`, tras el aviso «Marcar otra vez de todas formas»). Se añade la **estadística**: `MealReport.repeatCounts` ({veces: personas}, solo ≥ 2), `repeaters` y `extraPasses`; el resumen muestra «Repitieron», «pasadas de más» y una barra por cantidad de veces; el CSV y el Excel llevan una columna **«Veces»**, y el Excel resume cuántos pasaron 2, 3… veces. Cada persona sigue contando **una** vez en «Pasaron».
- **Pendiente de este bloque:** registrar a un asistente desde Control de comidas con una marca visible (requiere migración de la base de datos, v10) y exportar/importar sesiones.
