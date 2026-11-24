# Mi Evento — Plan de arquitectura e implementación

Versión 0.1 · Decisiones confirmadas: **Flutter** en ambas apps, **Windows 10/11** con Chrome/Edge, **Android 8+ (API 26)**, **un solo operador por turno** en el control de comidas, **sin QR en el MVP**.

> **Decisiones tomadas (v0.5):** **inicio de sesión con usuario y contraseña** (usuarios locales; roles administrador y operador; código de recuperación; bloqueo progresivo); **impresión en el MVP** (PDF y impresora conectada, empezando por la lista de hospedaje para el anfitrión); estrategia de equipos **C** (diferencias máximas entre equipos); **rangos de edad configurables por evento** (según los departamentos de la iglesia; los definirá el usuario más adelante); eventos de hasta **1000+ participantes** (media < 500) como objetivo de rendimiento.

---

## 0. Revisión del diseño de referencia

Identidad (azul `#1D4E89`, naranja `#E07A2E`, Nunito + Atkinson Hyperlegible, botones de 56/48 px, propuestas con borde discontinuo) se adopta tal cual. Ajustes propuestos:

| Punto del diseño | Problema | Alternativa |
|---|---|---|
| Fuentes desde Google Fonts | No cargan sin conexión | Empaquetar Nunito y Atkinson (solo latín, ~100 KB) como assets de Flutter |
| Imagen WhatsApp 1080×1350 | Convertir HTML→imagen es pesado | Dibujarla con `dart:ui` Canvas a partir de datos; igual en móvil y PC |
| Formulario móvil de 1640 px | Mucho scroll con teclado abierto | Visibles: nombre, apellidos, sexo, edad, iglesia. «Más datos» plegado: teléfono, matrimonio, grupo, observaciones |
| «Leer QR» | Cámara en gama baja es frágil | Fuera del MVP; búsqueda por nombre/número primero. QR en Fase 2 |
| «Ruth (mesa 2)», «3 voluntarios» | Contradice un solo dispositivo | Campo «Operador del turno» (texto libre, se elige al abrir la sesión de comida) |
| Aviso de desbalance fijo «>8 H–M» | Es el criterio que debes elegir tú | Se reemplaza por la estrategia elegida (sección 4) |
| Arrastrar equipos (PC) | Solo ratón | Mantener «Trasladar / intercambiar» también en PC (teclado y táctil) |

Sombras y animaciones: el diseño ya no usa sombras ni degradados, lo cual es bueno para gama baja. Mantener animaciones ≤150 ms.

---

## 1. Stack

### Recomendación: monorepo Flutter con paquete de dominio compartido

```
mi_evento/
  packages/mi_evento_core/   # Dart puro: ids, texto, duplicados, rangos de edad, balanceo (C); luego hospedaje, import/export
  apps/mi_evento/            # UNA app Flutter con dos destinos de compilación: Android (APK) y Windows,
                             # con interfaz adaptable (barra inferior en móvil, lateral en PC)
```
*(v0.4: se simplificó de dos proyectos de app a uno con dos destinos; la UI ya era la misma adaptable.)*

| Capa | Elección | Motivo |
|---|---|---|
| UI | Flutter 3.x, Material 3 con tema propio | Un solo código para Android y Windows; `Draggable/DragTarget` nativos para equipos |
| BD local | **SQLite vía `drift`** | Transacciones, índices para búsqueda rápida, migraciones; mismo esquema en ambas apps |
| Estado | `riverpod` | Simple, testeable |
| Excel/CSV | `excel`, `csv` | Sin servidor |
| Imagen WhatsApp | `dart:ui` + `share_plus` | Sin dependencias pesadas |
| Impresión/PDF | `pdf` + `printing` (`Printing.layoutPdf` abre el diálogo de impresión en Windows y Android; `sharePdf` para WhatsApp/guardar) | **MVP**: lista por hospedaje; luego pendientes y reportes. Misma función en ambas apps |
| Respaldo | `file_picker`, `archive` | ZIP `.mievento` |
| QR (Fase 2) | `mobile_scanner` (Android), `qr_flutter` (credencial) | |

**¿Compartir código?** Sí, y es la decisión que más simplifica la integración futura: la lógica de duplicados, hospedaje, balanceo, importación y exportación vive una sola vez en `mi_evento_core`, con pruebas unitarias. Las dos apps solo cambian en la capa de presentación (barra inferior en móvil, barra lateral en PC).

### Alternativas valoradas

| Opción | Pros | Contras | Veredicto |
|---|---|---|---|
| **Flutter (móvil + Windows)** | Un código, SQLite real, sin navegador | APK ~12–18 MB (por ABI), curva Dart | **Elegida** |
| Web (PWA) + Capacitor | Un código, instalación por navegador | Datos en IndexedDB que el navegador puede borrar; primera carga necesita internet | Alternativa si algún PC falla con Windows nativo |
| Kotlin nativo + Tauri | APK muy ligera | Dos bases de código, la lógica se duplica | Descartada |
| Electron | Conocido | 150+ MB, lento en PCs viejas | Descartada |

### App de PC: ¿PWA, escritorio o servidor local?

**Recomiendo app de escritorio Flutter para Windows**, empaquetada como instalador (`.exe` de Inno Setup o MSIX) y también como ZIP portable.

- Sin servidor ni base de datos que configurar: SQLite va dentro.
- Datos en una carpeta conocida (`Documentos\MiEvento`), copiable a una memoria USB; el navegador no puede borrarlos.
- Instalación: descargar, doble clic, Siguiente, Siguiente.
- Riesgo: SmartScreen avisa de «editor desconocido» al no tener certificado de firma. Se mitiga con una guía con capturas (sección 9) y, si hay presupuesto, firmando el instalador.
- Se puede publicar además la misma app como PWA (`flutter build web`) para quien prefiera abrirla en el navegador; no es el camino principal.

### Versión mínima

**Android 8.0 (API 26)** como confirmaste. Flutter soporta desde API 21, así que hay margen. Compilar `--split-per-abi` y distribuir `arm64-v8a` (y `armeabi-v7a` para móviles viejos de 32 bits).

---

## 2. Modelo de datos

Reglas comunes a **todas** las tablas: `id` UUID v7 (texto, ordenable por tiempo), `created_at`, `updated_at` (UTC ISO‑8601), `deleted_at` (borrado lógico, nulo si activo), `origin_device_id` (UUID del dispositivo que lo creó). `schema_version` global = 1.

### Entidades

**Event** — `id`, `name`, `start_date`, `end_date`, `venue`, `organizer`, `offers_lodging` (bool), `notes`.

**Church** (catálogo reutilizable entre eventos) — `id`, `name`, `name_normalized` (minúsculas, sin tildes ni signos; índice único con provincia+municipio), `province`, `municipality`, `denomination` (opcional).

**Attendee** — `id`, `event_id`, `reg_number` (entero correlativo por evento), `first_name`, `last_name1`, `last_name2`, `sex` (`M`/`F`), `age` (entero), `church_id`, `phone` (nulo), `province`, `municipality`, `needs_lodging` (bool), `notes`, `couple_id` (nulo), `team_id` (nulo), `lodging_id` (nulo), `dedupe_key` (nombre+apellido1 normalizados, indexado).

**Couple** — `id`, `event_id`, `attendee_a_id`, `attendee_b_id`. Restricción: un asistente solo en una pareja; ambos del mismo evento.

**Group** — `id`, `event_id`, `name`, `reason` (`church`|`preference`|`other`), `keep_together` (bool). **GroupMember** — `group_id`, `attendee_id` (un asistente puede estar en varios grupos; para hospedaje/equipos se resuelve con prioridad: matrimonio > grupo elegido > individual).

**Lodging** — `id`, `event_id`, `name`, `kind` (`shelter`|`private_home`), `contact_phone` (nulo), `directions`, `capacity` (camas/plazas), `accepts` (`men`|`women`|`couples`), `host_name` (nulo, para casas), `distance_note` (texto libre; la «cercanía» es declarada, no calculada por GPS).
Ocupación = suma de asistentes con `lodging_id` (se calcula, no se guarda). **Un matrimonio ocupa 2 plazas.**

**Team** — `id`, `event_id`, `name`, `color` (nulo), `captain_id` (nulo, asistente), `sort_order`.

**ControlType** — `id`, `event_id`, `name` (Desayuno, Almuerzo, Taller…), `sort_order`.

**ControlSession** — `id`, `event_id`, `control_type_id`, `name` («Almuerzo del sábado»), `scheduled_at` (nulo), `opened_at`, `closed_at` (nulo), `operator_name`.

**ControlRecord** — `id`, `session_id`, `attendee_id`, `marked_at`, `operator_name`, `undone_at` (nulo), `repeat_override` (bool: marcado de nuevo a pesar del aviso). Índice único parcial `(session_id, attendee_id)` donde `undone_at` es nulo y `repeat_override = false`.

**Suggestion** (opcional, auditoría) — `id`, `kind` (`lodging`|`teams`), `payload` JSON, `status` (`accepted`|`modified`|`discarded`). Útil para saber cuánto se confía en el algoritmo.

**AgeRange** (configurable por evento) — `id`, `event_id`, `label`, `min_age`, `max_age` (nulo = sin tope), `sort_order`; se usa en reportes y panel de equipos.

**AppUser** (inicio de sesión, v2 del esquema) — `username` (único, minúsculas), `display_name`, `role` (`admin`|`operator`), `password_hash` (PBKDF2-HMAC-SHA256, sal por usuario, iteraciones guardadas con el hash), `active`, `failed_attempts`, `locked_until`, `last_login_at`. `Attendee.created_by` guarda quién registró. El nombre del operador en las comidas sale del usuario con sesión.

**AppMeta** — `device_id`, `device_label`, `schema_version`, `last_backup_at`.

### Relaciones

```
Event 1─* Attendee *─1 Church        Attendee *─? Team        Attendee *─? Lodging
Event 1─* Couple (2 Attendee)        Event 1─* Group *─* Attendee
Event 1─* Lodging                    Event 1─* Team ─? captain Attendee
Event 1─* ControlType 1─* ControlSession 1─* ControlRecord *─1 Attendee
```

Integridad: al borrar (lógico) un asistente se limpia su pareja, equipo y hospedaje; si era capitán, el equipo queda sin capitán y se avisa.

---

## 3. Algoritmo de sugerencia de hospedaje

Siempre devuelve **propuestas**; no escribe nada hasta que el usuario pulsa Aceptar (puede Modificar o Descartar).

### Entradas
- `target`: una persona, un matrimonio o un grupo (lista de asistentes, con `sex`, `couple_id`, `church_id`).
- `lodgings`: hospedajes del evento con `accepts`, `capacity`, ocupación actual, `kind`, `distance_note`.
- Opciones del usuario: «mantener juntos si es posible» (por defecto sí), «preferir misma iglesia del anfitrión».

### Reglas duras (eliminan candidatos)
1. **Capacidad**: plazas libres ≥ personas asignadas ahí.
2. **Compatibilidad**: `men` solo hombres; `women` solo mujeres; `couples` solo matrimonios completos (ambos cónyuges, 2 plazas). Un hombre o mujer solo no entra en `couples`.
3. Un matrimonio nunca se separa.

### Puntuación (ordena los candidatos; mayor es mejor)
| Criterio | Peso |
|---|---|
| Cabe **todo** el objetivo en un solo hospedaje | +100 |
| Ajuste ajustado (menos plazas sobrantes) | +30 − sobrantes (mín. 0) |
| Mismo `church_id` que el anfitrión o ya hospeda gente de esa iglesia | +20 |
| Mismo `kind` que los demás del grupo, si ya están repartidos | +10 |
| Cercanía declarada («a 300 m del templo») | +5 |
| Dejaría el hospedaje casi vacío (<25 %) con otros que podrían llenarse | −10 |

### Salida
Lista ordenada de **propuestas**; cada una es un conjunto de «tramos»: `[(lodging, [personas], motivo)]`, más el estado de ocupación antes/después de cada hospedaje y un texto en español que explica el porqué.

### División de grupos (cuando nada acepta a todos)
1. Los matrimonios son unidades indivisibles; se agrupan primero → bloque `couples`.
2. Del resto se forman **bloques por sexo**: hombres, mujeres.
3. Para cada bloque se busca el mejor hospedaje compatible que lo contenga entero.
4. Si un bloque no cabe en ninguno, se **parte** minimizando el número de hospedajes (empaquetado codicioso por mayor espacio libre, desempate por score) y se prefieren hospedajes cercanos entre sí (misma `distance_note`) o del mismo `kind`.
5. Si aun así falta espacio: se muestra el **déficit** («faltan 3 plazas para mujeres») y se invita a registrar otro hospedaje; no se asigna parcialmente sin que el usuario lo confirme.

### Casos límite
- Persona sola sin hospedajes compatibles → mensaje claro, nunca error.
- Grupo con matrimonios y solteros de ambos sexos → hasta 3 tramos (parejas, hombres, mujeres).
- Hospedaje ya sobrecapacitado por una edición manual → se avisa, no se bloquea (principio de la decisión humana).
- Pareja con un cónyuge ya asignado y otro no → se propone el mismo hospedaje del primero si hay 1 plaza libre y acepta `couples`.
- Matrimonio donde un cónyuge no marcó «necesita hospedaje» → se pregunta, no se asume.
- Asistente en dos grupos → se usa el que el usuario esté asignando; si ya tiene hospedaje, se advierte antes de moverlo.
- Capacidad = 0 o cambiada a menos de la ocupación → aviso en la lista de hospedajes.
- Empates → orden estable por nombre de hospedaje para resultados repetibles.

Se implementa como función pura en `mi_evento_core` (`suggestLodging(target, lodgings, options) → List<Proposal>`), con pruebas de tabla para cada caso.

---

## 4. Equipos: estrategias de balanceo — **elige una**

Todas comparten: el resultado es una **propuesta** revisable; los grupos «mantener juntos» se tratan como una sola pieza; el aviso nunca bloquea y siempre dice **cuánto** y **respecto a qué**; el panel muestra cantidad, H/M y distribución de edad por equipo.

Datos de ejemplo común: 4 equipos, 120 personas (60 H / 60 M), edades 12–60.

### Estrategia A — Rangos de edad × sexo (estratificada)
Se definen rangos (p. ej. 12–17, 18–25, 26–40, 41+). Cada celda (rango × sexo) se reparte lo más parejo posible entre equipos.
- **Aviso**: «Equipo Azul tiene 4 mujeres de 18–25 más que el promedio de equipos.» Umbral: diferencia de más de ±N personas por celda (configurable; por defecto 2).
- **Ventajas**: fácil de entender y de explicar al organizador; el resultado se ve «justo» a simple vista; los rangos se pueden adaptar al evento.
- **Desventajas**: depende de dónde se pongan los cortes (un joven de 25 y otro de 26 caen en rangos distintos); con pocos asistentes hay celdas vacías y avisos constantes.
- **Ejemplo**: celda «H 18–25» tiene 14 personas → 4 equipos: 4/4/3/3. Mover a un joven de Azul(4) a Rojo(3) da 3/4/3/3: sigue dentro de ±1, sin aviso.

### Estrategia B — Edad media y desviación (estadística)
Se calcula, por equipo, edad media y desviación estándar, y la proporción H/M. Se busca minimizar la distancia entre equipos.
- **Aviso**: «Edad media del equipo Rojo (31,2) se aleja 4,1 años de la media general (27,1); el máximo permitido es 3.» Dos umbrales: años de diferencia y puntos porcentuales de H/M.
- **Ventajas**: no depende de cortes; funciona con pocos asistentes; se adapta solo a cualquier evento.
- **Desventajas**: menos intuitivo para voluntarios (¿qué significa «desviación»?); la media puede esconder un equipo con muchos niños y muchos mayores y nadie en medio.
- **Ejemplo**: Azul y Rojo tienen media 27; Azul tiene edades 12–45 y Rojo 25–29. Media igual, composición muy distinta; con desviación se detecta, pero hay que explicarla.

### Estrategia C — Diferencias máximas entre equipos (umbrales simples)
Se fijan tres topes visibles y fáciles de editar, comparando el equipo más grande con el más pequeño: **tamaño** (±2 personas), **sexo** (diferencia H–M por equipo ≤ 4, o proporción) y **edad media** (±3 años).
- **Aviso**: una línea por cada tope superado: «Tamaño: Azul 31, Amarillo 27 (diferencia 4, máx. 2).»
- **Ventajas**: lo más sencillo de configurar y de leer; el mensaje es directo; poco cálculo (rápido en gama baja).
- **Desventajas**: cada criterio es independiente (puede cumplirse cada tope y aun así haber un equipo desequilibrado en conjunto); no considera cómo se distribuyen las edades.
- **Ejemplo**: Azul 30 (15H/15M, media 24), Rojo 28 (10H/18M, media 24). Tamaño pasa; sexo: aviso (diferencia 8, tope 4).

### Opción D — Ponderación mixta (combinación)
Una puntuación única = `wₑ·desvío de edad + wₛ·desvío de sexo + wₜ·desvío de tamaño` (pesos editables) y un solo umbral de aviso. Es la más flexible, pero la que más cuesta explicar. Recomendada solo si ya sabes que quieres afinar pesos.

### ✅ Decisión: estrategia C

**Topes por defecto** (editables por evento; mismos nombres en el prototipo): tamaño ±2 personas, hombres–mujeres por equipo ≤ 4, edad media ±3 años, comparando el equipo mayor con el menor.
- **Aviso** (nunca bloquea): una línea por tope superado, con valores y el tope; ej. «Tamaño: Azul 31 y Amarillo 27 (diferencia 4, máximo 2)». Siempre ofrece «Continuar».
- **Generación automática** (Fase 2): reparto voraz por piezas (persona suelta, matrimonio o grupo «juntos»), de mayor a menor, asignando cada pieza al equipo que menos empeore los tres topes; luego mejora local por intercambios. Es una propuesta que el usuario revisa y confirma.
- **Rangos de edad configurables por evento:** el panel de composición agrupa por los rangos del evento (modelo: `AgeRange{event_id, label, min_age, max_age, sort_order}`; por defecto 12–17 / 18–25 / 26–40 / 41+ hasta que el usuario los defina). Los reportes por edad usan los mismos rangos. Los topes de C no dependen de los rangos, así que cambiarlos no altera el aviso.
- **Rendimiento:** con 1000+ asistentes, las estadísticas por equipo se calculan incrementalmente (al mover una persona solo cambian dos equipos) y las listas se virtualizan.

### Referencia: mi recomendación original (tú decidiste C)
**C para el aviso + A como método de generación** (se adoptó C; la generación usa el reparto descrito arriba). Los topes de C son lo que un voluntario entiende al leer el aviso, y A es el reparto automático que produce equipos que «se ven» justos. Si prefieres una sola estrategia sin mezclar, elige **C**. La B pierde claridad para este perfil de usuarios.

El prototipo usa un aviso **provisional** (diferencia H–M > 8, el del diseño) hasta que elijas.

---

## 5. MVP y fases

### Inicio de sesión (v0.5)
- **Roles:** *administrador* (todo: usuarios, borrar, respaldos, configuración) y *operador* (registrar, buscar, controlar comidas, equipos y hospedajes; no administra usuarios ni borra datos).
- **Primer uso:** se crea el administrador y se entrega un **código de recuperación** de un solo uso (se muestra una vez; se guarda solo su hash). Con él se restablece la contraseña del administrador y se emite un código nuevo.
- **Contraseñas:** mínimo 6 caracteres, distinta del usuario; hash PBKDF2-HMAC-SHA256 (100 000 iteraciones, fuera del hilo de la interfaz) con sal propia; se re-hashea solo si se suben las iteraciones.
- **Fuerza bruta:** desde el 5.º intento fallido, espera de 30 s, 1 min, 5 min y 15 min; el mensaje de error no revela si el usuario existe.
- **Protecciones:** no se puede desactivar a uno mismo ni dejar el sistema sin administrador activo.
- **Límite honesto:** el inicio de sesión protege el *uso* de la app, **no cifra el archivo** de datos. Quien copie el archivo `.db` del dispositivo podría leerlo. Para cifrado en reposo (SQLCipher) y bloqueo por inactividad ver *Pendientes*.
- **Pendientes:** bloqueo automático por inactividad, cifrado de la base de datos y de los respaldos con la contraseña, y fuentes empaquetadas.

### Estado de avance
- ✅ Fase 0 — Prototipo aprobado.
- ✅ **Base** — monorepo, núcleo con 16 pruebas, esquema SQLite (13 tablas, UUID v7, marcas de tiempo, borrado lógico), tema, navegación adaptable, crear/listar eventos, panel con contador en vivo, CI. 7 pruebas en la app.
- ✅ **Inicio de sesión** — usuarios, roles, recuperación, bloqueo progresivo, pantallas y migración v1→v2. 26 pruebas del núcleo y 26 de la app.
- ✅ **MVP-A** — registro de asistentes (validaciones en español, aviso de duplicado en pantalla, pantalla de éxito con número de inscripción, «Guardar y registrar otro»), catálogo de iglesias sin duplicados (alta desde el propio formulario), lista con búsqueda (nombre en cualquier orden, sin tildes, iglesia o número), edición, borrado lógico solo para administrador, panel con totales; fuentes Nunito y Atkinson empaquetadas. 41 pruebas en la app y 26 en el núcleo.
- ✅ **MVP-B** — matrimonios y grupos (se vinculan desde la ficha; un grupo se puede asignar entero), hospedajes (alta y edición, asignación manual con **avisos** de capacidad y compatibilidad —el cónyuge se arrastra junto—, lista imprimible/PDF con teléfono opcional), equipos manuales (crear N, color, capitán, traslado con vista previa antes/después, arrastrar en PC, intercambio, panel de composición con los rangos de edad del evento, topes del criterio C editables por evento). Esquema v3. 38 pruebas del núcleo y 80 de la app.
- 🐞 Corregido tras la primera prueba en Windows: el hash de la contraseña arrastraba la base de datos al otro hilo y la app se quedaba en «Creando…». Ahora hay pruebas con el ejecutor real (`Isolate`) y la interfaz muestra cualquier error inesperado. **Lección:** las pruebas con ejecutores falsos no cubren el comportamiento real; cada pieza que use hilos, archivos o impresoras necesita una prueba con la implementación real.
- 🎨 **Pulido de interfaz** (guía frontend-design, respetando la identidad aprobada): el logotipo —dos círculos que se tocan— pasa a ser el elemento de marca en el acceso (panel azul en PC, compacto en móvil), la barra lateral y los íconos de Android (adaptativo) y Windows; la ventana de Windows se llama «Mi Evento». **Defecto corregido:** el texto de cuerpo nunca usaba Atkinson Hyperlegible porque un `textTheme` propio con Roboto anulaba la fuente del tema. Los íconos se regeneran con `apps/mi_evento/tools/make_icons.py`.
- ✅ **MVP-C** — control de comidas: tipos configurables (Desayuno, Almuerzo y Cena por defecto; se pueden añadir otros como «Entrega de materiales»), sesiones con nombre sugerido («Almuerzo del sábado»), marcar por nombre (sin tildes, cualquier orden) o por número con **Enter**, aviso de **«ya pasó»** con hora, quién lo marcó, iglesia y equipo («Entendido» o «Marcar otra vez de todas formas»), deshacer, contadores en vivo (inscritos, pasaron, faltan), lista de pendientes con búsqueda, cierre con resumen (por equipo, llegadas cada 15 minutos, repetidos evitados), reabrir, y exportación a **Excel**, **CSV** e **imagen para WhatsApp** (solo cifras, comprobado con una prueba de privacidad). El operador es el usuario con sesión. Esquema v4. 58 pruebas del núcleo y 119 de la app.
  - *Decisión técnica:* el `.xlsx` lo genera el propio núcleo (ZIP de XML, validado con una hoja de cálculo real) porque la librería `excel` exige una versión de `xml` incompatible con la de `pdf`.
  - *Android:* se comparte con la hoja «Compartir» (WhatsApp, Bluetooth, guardar); *Windows:* «Guardar como…». Esa parte nativa solo se prueba en un dispositivo real.
- ✅ **MVP-D** — **Reportes** (totales por sexo, rango de edad del evento, iglesia, hospedaje y equipo; todas las secciones suman lo mismo; exportables a Excel, CSV y PDF, imprimibles; el teléfono solo si se pide). **Copias de seguridad** con archivos `.mievento` (ZIP con `manifest.json` + `data.json` y suma SHA-256; sin usuarios ni contraseñas): guardar con **contraseña opcional (AES-256)**, abrir una copia con vista previa y **fusión por identificador** (gana lo más reciente, el borrado lógico viaja, iglesias duplicadas se unen, números de inscripción en conflicto se renumeran, todo o nada), **copias automáticas** (al cerrar una comida y cada 20 registros, se conservan las últimas 10), aviso en el panel si hay cambios sin copiar, y **eliminar un evento para siempre** (exige escribir su nombre). 74 pruebas del núcleo y 150 de la app.
  - *Límite honesto del cifrado:* el ZIP usa AES-256 del estándar WinZip (abre con 7-Zip), pero ese estándar deriva la clave con solo 1 000 iteraciones: una contraseña corta se podría adivinar por fuerza bruta si alguien consigue el archivo. Recomendación: contraseñas largas (varias palabras).
  - *Pendiente de la sección de privacidad:* cifrar la base de datos en el dispositivo (SQLCipher) y bloqueo por inactividad.
- ✅ **Fase 2 (parte 1) — hospedaje sugerido** (`suggestLodging`, función pura con 20 pruebas): reglas duras, puntuación, división de grupos, déficit y casos límite; pantalla «Sugerir hospedaje» con propuestas de borde discontinuo (Aceptar / Modificar / Descartar).
- ✅ **Correcciones pedidas por el usuario (v0.6)**: (1) fechas del evento en **un solo calendario de rango** (tocar el mismo día dos veces = evento de un solo día); (2) el evento declara si **ofrece hospedaje** y si **se divide en equipos** (esquema v5, `offersTeams`); (3) al crear el evento se **pide definir hospedajes y equipos** (se puede dejar para después) y el panel lo recuerda; (4) **no se inscribe sin eso** salvo que quien inscribe elija «Inscribir de todas formas»; (5) **equipo y hospedaje se asignan al inscribirse** (y al editar), con sugerencia propia (`suggestTeam`, estrategia C, el cónyuge manda) como propuesta revisable o elección manual con avisos. 101 pruebas del núcleo y 162 de la app.
  - *Límite conocido:* la sugerencia de hospedaje en el formulario considera solo a la persona que se inscribe (con el hospedaje de su cónyuge si ya lo tiene); para grupos usa «Sugerir hospedaje» en Hospedajes. No hay aún pantalla para cambiar después las opciones «hospedaje/equipos» de un evento ya creado.
  - *Pruebas:* el Panel usa un contador liviano (`setupCountsProvider`, se libera al salir) para no dejar vivas las consultas de hospedajes/equipos, que cuelgan las pruebas de widgets que escriben datos.
- ✅ **Fase 2 (parte 2) — generar equipos** (`generateTeams`, estrategia C): reparto voraz por piezas de mayor a menor (matrimonio y grupos «mantener juntos» = una pieza; si una persona está en ambos, todo el conjunto va junto) + mejora local por traslados e intercambios; determinista; 1000 personas en 20 equipos en menos de 5 s. Pantalla «Generar equipos» (en Equipos): propuesta con tamaño/H–M/edad media por equipo y los topes que aún se superen, **Aceptar / Calcular de nuevo / Descartar**, y **Deshacer** tras aceptar. Por defecto solo reparte a quien no tiene equipo. 111 pruebas del núcleo y 170 de la app.
  - *Decisión:* «Modificar» se hace después de aceptar con los traslados/intercambios manuales ya existentes (más «Deshacer»), en vez de una edición dentro de la propuesta.
- ✅ **Cambios pedidos (v0.7)**: (1) la app funciona en **dos momentos**: *configuración* del evento (datos, fechas, hospedajes, equipos con **confirmación de los criterios de balance**; esquema v6, `setupDone`) y luego *inscripción y actividades*; el administrador puede volver a «Configuración» cuando quiera; (2) el **equipo se asigna automáticamente** al inscribir (`autoAssign`, estrategia C, el cónyuge primero) y solo se cambia desde la vista de Equipos; (3) el **hospedaje sugerido se puede tomar o dejar para después** (p. ej. para asignarlo con su grupo); (4) administrador inicial **admin / admin** creado al abrir la app por primera vez, con aviso fijo hasta que se cambie la contraseña; el administrador puede añadir otros administradores; (5) el panel lateral de PC se desplaza en ventanas bajas.
  - *Riesgo asumido:* un administrador conocido (admin/admin) es un acceso predecible; por eso el aviso persiste hasta cambiar la clave. El administrador inicial no tiene código de recuperación: conviene crear un segundo administrador.
- ✅ **Intercambio CSV (Excel)**: un solo archivo `.csv` para exportar, completar en Excel (o seguir inscribiendo desde allí) e importar. Columnas coherentes con la base de datos (`id, numero, nombre, apellido1, apellido2, sexo, edad, iglesia, provincia, municipio, telefono, necesita_hospedaje, hospedaje, equipo, pareja_numero, grupos, observaciones`); hospedaje/equipo/iglesia/grupos por **nombre**. Separador «;» y BOM (Excel en español); al leer se acepta «;», «,» o tabulador, UTF-8 o ANSI, columnas en cualquier orden. Importación con **vista previa** (nuevas / se actualizan / posibles duplicados / errores por fila con su número), todo o nada, y coincidencia por `id` (o número + nombre). En «Copias de seguridad» (administrador): Exportar, Plantilla vacía, Importar. 125 pruebas del núcleo y 202 de la app.
  - *Límite:* el CSV no lleva usuarios, contraseñas, ni el historial de comidas (eso va en la copia `.mievento`).
- ✅ **Matrimonio desde la ficha (v0.8)**: «Inscribir a su cónyuge ahora» (formulario corto: nombre, apellidos y edad; sexo contrario y fijo; misma iglesia y lugar). No se crea nada hasta guardar la ficha; si ya estaba inscrito se avisa y se puede vincular a esa persona. La pareja cae en el mismo equipo y el hospedaje se **propone para los dos** (hospedaje de matrimonios, 2 plazas): se acepta o se deja para después. También: la app reserva el espacio de la barra de navegación de Android en todas las pantallas (los botones de abajo ya no quedan tapados). 217 pruebas de la app.
- ✅ **QA funcional (v0.9)**: 179 pruebas nuevas (`apps/mi_evento/test/qa/`, `packages/mi_evento_core/test/qa/`) y datos de prueba reutilizables en `qa-datasets/` (generador manual `apps/mi_evento/qa/generate_qa_dataset_test.dart`). Informe y catálogo completo en `docs/QA-informe.md`: 13 defectos (2 altos: balance del equipo automático y PDF con más de ~600 inscritos; 17 pruebas omitidas con `skip` hasta corregirlos). Todo probado en el entorno de pruebas, **no** en dispositivos reales.
- ✅ **Correcciones de QA (v0.10)** (rama `correcciones-qa`; detalle en `docs/QA-informe.md`): (1) **equipo automático** con el mismo costo que «Generar equipos» (`balanceParts`): 24 de 30 combinaciones cumplen los topes (antes 13); los 6 casos restantes son por datos (muchas más mujeres que hombres con pocos equipos) o esposas tardías, y no se corrigen moviendo a gente ya asignada (*decisión pendiente*: ¿reubicar solo o proponer un ajuste?); (2) **PDF** sin límite de 20 páginas (1000 inscritos = 37 páginas); (3) **matrimonio en dos fichas**: propuesta (borde discontinuo) para mover a los dos a un hospedaje de matrimonios, el cónyuge se mueve con la persona al elegir uno de matrimonios, y aviso si se separa; (4) **borrar** un asistente limpia pareja, equipo, capitán (se avisa), hospedaje y grupos; (5) **CSV**: equipo automático para las personas nuevas sin equipo válido, y se conserva el número del archivo si está libre (si no, el siguiente; cuentan los números de borrados); (6) **interfaz**: «Mis eventos», aviso de copia, Hospedajes, estados vacíos y acceso sin desbordes en 360×640 hasta letra al 150 % y en ventanas bajas; (7) bajos: celdas de CSV neutralizadas contra fórmulas, normalización de apóstrofes y letras (ã, ç…), guardado sin doble toque. Segunda tanda: QA-BUG-007 (parejas contradictorias en el CSV: no se vincula a nadie y se avisa), UTF-16 legible y rango «0–11» por defecto en eventos nuevos. Decidido: el equipo automático sigue ignorando los grupos «juntos»; los topes de balance superados solo se avisan. Probado en el entorno de pruebas, **no en dispositivos reales**.
- ⏭ Siguiente: **Fase 2 (resto)** — credenciales con QR (la importación desde Excel ya está hecha con el CSV) (y, si se pide, editar después las opciones hospedaje/equipos del evento); y **Fase 3** (fusión entre dispositivos por red, reportes avanzados).
- Notas de MVP-A: los municipios sugeridos solo vienen precargados para Matanzas (en las demás provincias se escribe y se sugiere a partir de iglesias ya registradas); falta verificar la lista oficial por provincia.

### Fase 0 — Prototipo de interfaz (ya incluido: `prototype/index.html`)
Para aprobar flujos y pantallas antes de programar. Sin datos reales ni persistencia.

### MVP (Fase 1) — «Un evento funciona de punta a punta, sin internet»
- Eventos: crear, listar, abrir.
- Asistentes: registro con validaciones, catálogo de iglesias, búsqueda rápida, edición, detección de duplicados, número de inscripción visible.
- Matrimonio y grupos (vincular, ver).
- Hospedajes: alta, lista, asignación **manual** con control de capacidad, **lista imprimible por hospedaje (PDF o impresora conectada)**: encabezado con evento, hospedaje, dirección y cómo llegar; tabla ordenada por apellido (nombre, sexo, edad, iglesia, observaciones); **sin teléfono por defecto** (casilla opcional); pie «uso exclusivo del anfitrión».
- Equipos: crear N, capitán, asignación y traslado **manual**, panel de composición, aviso de desbalance (estrategia elegida).
- Comidas: tipos, sesiones, marcar por **nombre o número**, aviso de «ya pasó», contadores en vivo, lista de pendientes, cierre y exportación (CSV, Excel, imagen para WhatsApp).
- Reportes básicos: totales por sexo, edad, iglesia, hospedaje y equipo; exportar e imprimir.
- **Respaldo y exportación/importación** (JSON y CSV/Excel) — desde el inicio.
- Ambas apps (Android + Windows) con el mismo núcleo.

### Fase 2 — Automatización
- Sugerencia automática de hospedaje (persona, matrimonio, grupo, división).
- Generación automática de equipos (estrategia elegida), con revisión y confirmación.
- Intercambio entre equipos con vista previa antes/después.
- Credenciales con QR + lectura de QR; impresión de credenciales.
- Importar asistentes desde Excel (la pantalla vacía ya lo anuncia).

### Fase 3 — Integración y robustez
- Fusión de datos entre dispositivos (sección 6).
- Respaldo automático programado y a carpeta externa.
- Reportes avanzados, plantillas de informe, tema de alto contraste.

### Futuro
- Sincronización por red local (Wi‑Fi sin internet), multi‑operador.
- Servidor central opcional, cuentas, historial entre eventos.

---

## 6. Integración futura entre APK y app web/PC

Hoy: un dispositivo por evento. La integración se resuelve **por archivo**, sin servidor, y se diseña desde el MVP.

1. **Formato único**: archivo `.mievento` = ZIP con `manifest.json` (`schema_version`, `exported_at`, `device_id`, `event_id`), `data.json` (todas las tablas) y opcionalmente CSV/XLSX de cortesía. Misma lectura/escritura en las dos apps (viene del paquete compartido).
2. **Identificadores**: UUID v7 en todo; nunca ids autoincrementales, para que los datos de dos dispositivos jamás choquen.
3. **Fusión (Fase 3)** al importar: por `id`; gana el `updated_at` más reciente; los `deleted_at` se respetan (borrados lógicos). Duplicados de personas con ids distintos se señalan con el detector existente y los decide el usuario.
4. **Casos de uso**: (a) pasar un evento del móvil a la PC (un solo sentido, `.mievento`); (b) un móvil registra en la entrada y una PC controla comidas: se exporta/importa por tandas en Fase 3.
5. **Compatibilidad**: `schema_version`; migraciones en el importador (nunca se importa un archivo más nuevo que la app; se avisa para actualizar).
6. **Futuro con servidor**: el mismo esquema (ids, timestamps, tombstones, `origin_device_id`) sirve de base para sincronización incremental.

---

## 7. Respaldo de datos

- **Respaldo automático local**: tras cada cierre de sesión de comida y cada N registros (por defecto 20), copia a una carpeta rotativa (últimas 10 versiones).
- **Respaldo manual en un toque**: botón «Guardar copia» → `.mievento` que se comparte por WhatsApp, Bluetooth, USB o correo.
- **Aviso de riesgo**: si el último respaldo tiene más de 30 minutos y hubo cambios, un indicador amable en el panel («Última copia: hace 2 h»).
- **Modo diario**: cada día del evento, recordatorio de copia a un segundo dispositivo.
- **SQLite en modo WAL** y transacciones: sin pérdida por cierre brusco o batería agotada.
- **Restaurar**: «Abrir copia» sobre una instalación nueva; verificación de integridad (hash en el manifiesto).
- Android: copia en almacenamiento visible al usuario (`Documents/MiEvento`) mediante el selector del sistema; no depende de permisos amplios.
- Cifrado opcional del respaldo con contraseña (ver sección 8).

---

## 8. Privacidad

Datos sensibles: edad, sexo, teléfono, estado civil, observaciones (pueden incluir salud). Principios: mínimo necesario, todo local, el usuario controla qué sale del dispositivo.

- **Todo local, sin servidores ni analíticas**; la app ni siquiera pide permiso de Internet en el MVP (así se puede afirmar y verificar).
- **Teléfono opcional**; observaciones con aviso: «No escribas datos médicos innecesarios».
- **Inicio de sesión con usuario y contraseña** (obligatorio, ver arriba). Opcional más adelante: PIN corto y huella para reabrir, y bloqueo por inactividad.
- **Exportaciones**: cada exportación avisa qué datos contiene. La **imagen de WhatsApp contiene solo cifras agregadas**, nunca nombres ni teléfonos (como ya indica el diseño). Los listados con nombres piden confirmación.
- **Respaldos con contraseña** opcional (AES‑256 sobre el ZIP).
- **Menores de edad**: advertir al registrar a menores que se guardan sus datos; la edad se guarda como número, no la fecha de nacimiento.
- **Borrado**: «Eliminar evento» borra de verdad (no solo lógico) tras confirmación; «Borrar datos personales» tras el evento mantiene solo estadísticas agregadas.
- **Consentimiento**: texto corto para mostrar al registrar y política de privacidad simple dentro de la app.
- Android: `allowBackup="false"` para que los datos no suban a la nube de Google sin que el usuario lo decida.
- Aviso a los voluntarios: no dejar el dispositivo desbloqueado ni capturar pantallas con datos.

---

## 9. Distribución e instalación (usuarios no técnicos)

### Android (APK)
- Archivo único firmado con una **clave propia que se guarda con copia segura** (perder la clave impide actualizar la app instalada).
- Distribución: enlace de descarga directa, WhatsApp, Bluetooth, USB. Nombre claro: `MiEvento-1.0.apk`.
- Guía de 5 pasos con capturas: descargar → abrir → permitir «instalar de esta fuente» → Instalar → Abrir.
- Pantalla de **Acerca de** con número de versión para soporte; actualización = instalar el APK nuevo encima (datos se conservan).
- Peso objetivo ≤ 20 MB (arm64) y ≤ 25 MB universal.

### Windows
- Instalador `.exe` (Inno Setup) de unos 20–30 MB + ZIP portable para memoria USB.
- Guía con capturas incluyendo el aviso de SmartScreen («Más información → Ejecutar de todas formas»).
- Datos en `Documentos\MiEvento`; desinstalar no los borra.
- Sin requisitos de .NET ni de servicios; verificar Visual C++ Redistributable (incluir en el instalador).

### Común
- Una **página sencilla de descarga** (puede alojarse en GitHub Releases) con ambas versiones y las guías en PDF imprimible.
- Primer arranque: asistente de 3 pantallas («Crea tu evento → Registra → Haz una copia») y un **evento de práctica** que se puede borrar.

---

## 10. Riesgos y mitigaciones

| Riesgo | Prob. | Impacto | Mitigación |
|---|---|---|---|
| Pérdida del dispositivo / batería / avería | Media | Muy alto | Respaldo automático + manual, aviso de antigüedad, SQLite WAL |
| Duplicados por errores de escritura | Alta | Medio | Clave normalizada nombre+apellido+edad, aviso no bloqueante, catálogo de iglesias |
| Voluntarios abandonan por complejidad | Media | Alto | Prototipo validado antes de programar; pruebas con 2–3 voluntarios; flujo de registro de 5 campos |
| Rendimiento en Android de gama baja | Media | Alto | Probar en móvil real de 2 GB RAM; listas virtualizadas; `--split-per-abi`; sin animaciones pesadas |
| APK bloqueada o rechazada por Android/Play Protect | Media | Medio | Guía clara; clave de firma estable; evitar permisos innecesarios |
| Impresoras distintas / sin controlador en Windows | Media | Medio | Siempre ofrecer «Guardar como PDF» como alternativa; probar con 2 impresoras reales; vista previa antes de imprimir |
| SmartScreen alarma en Windows | Alta | Medio | Guía con capturas; firma de código si hay presupuesto |
| Pérdida de la clave de firma de la APK | Baja | Alto | Copia cifrada en 2 lugares |
| Algoritmos que «sugieren mal» | Media | Medio | Siempre propuesta; mostrar motivo; registrar aceptada/modificada/descartada |
| Alcance creciente | Alta | Alto | Fases definidas; lo no listado en el MVP no entra |
| Fuga de datos personales | Baja | Alto | Todo local, exportaciones avisadas, PIN, respaldo cifrado |
| Dependencia de un solo desarrollador | Media | Alto | Documentación breve, pruebas del núcleo, código sencillo |

---

## 11. Estimación de esfuerzo (un desarrollador, Flutter)

Semanas de trabajo efectivo, con margen para pruebas con usuarios reales.

| Fase | Contenido | Estimación |
|---|---|---|
| 0 | Prototipo + decisiones (incluye este plan) | 1 sem |
| Base | Monorepo, núcleo, esquema SQLite, tema, navegación, CI | 1–1,5 sem |
| MVP-A | Eventos, asistentes, iglesias, duplicados | 2 sem |
| MVP-B | Matrimonio, grupos, hospedajes manuales (con lista imprimible/PDF), equipos manuales | 2,5–3 sem |
| MVP-C | Comidas, cierre, exportaciones (CSV/Excel/imagen), reportes | 2–2,5 sem |
| MVP-D | Respaldo, importar/exportar `.mievento`, instaladores, pruebas | 1,5–2 sem |
| **Total MVP** | | **≈ 9,5–11,5 sem** |
| Fase 2 | Hospedaje automático, equipos automáticos, QR + credenciales, importar Excel | 5–6 sem |
| Fase 3 | Fusión entre dispositivos, respaldo avanzado, reportes avanzados | 3–4 sem |

Si la estrategia de equipos elegida es la D, sumar ~1 semana de afinado.

---

## 12. Mapa de pantallas y navegación

### Móvil (barra inferior: Evento · Registrar · Comidas · Equipos · Más)
| Pantalla | Estado en el diseño |
|---|---|
| Selección / creación de evento | **Falta** |
| Panel del evento (con datos) | Parcial — solo existe el vacío |
| Panel del evento vacío | ✅ M‑Panel‑Vacio |
| Registro de asistente (+ duplicado) | ✅ M‑Registro |
| Registro guardado (+ propuesta de hospedaje) | ✅ M‑Registro‑Exito |
| Nueva iglesia (alta en catálogo) | Parcial (solo en PC) |
| Lista de asistentes + búsqueda + ficha/edición | **Falta** |
| Vincular matrimonio / añadir a grupo | **Falta** (solo botones) |
| Lista de hospedajes + alta/edición | **Falta** |
| Sugerencia de hospedaje | Solo PC → **falta móvil** |
| Lista imprimible por hospedaje | **Falta** |
| Equipos (lista y composición) | ✅ M‑Equipos |
| Confirmar traslado | ✅ M‑Traslado |
| Generar equipos automáticamente | **Falta** |
| Control de comidas (éxito) | ✅ M‑Comidas |
| Control de comidas (ya pasó) | ✅ M‑Comidas‑YaPaso |
| Lista de pendientes | **Falta** (existe el enlace «Faltan ›») |
| Cierre de sesión de comida | Solo PC → **falta móvil** |
| Configuración de tipos de control y sesiones | **Falta** |
| Reportes + exportar | **Falta** |
| Respaldo / restaurar / PIN / ajustes | **Falta** |

### PC (barra lateral: Panel · Registrar · Asistentes · Hospedajes · Equipos · Comidas · Reportes)
| Pantalla | Estado |
|---|---|
| Registro de asistente (duplicado, iglesia nueva) | ✅ PC‑Registro |
| Equipos con arrastre | ✅ PC‑Equipos |
| Control de comidas (con atajos) | ✅ PC‑Comidas |
| Sugerencia de hospedaje | ✅ PC‑Hospedaje‑Sugerencia |
| Cierre de comida + exportar | ✅ PC‑Cierre |
| Imagen WhatsApp | ✅ WhatsApp‑Resumen |
| Selección de evento, panel con datos, asistentes, hospedajes, reportes, ajustes/respaldo | **Faltan** — el prototipo las propone con el mismo estilo |

Todas las pantallas nuevas del prototipo siguen la identidad visual existente.

---

## Preguntas que quedan abiertas
1. ~~Estrategia de equipos~~ → **C** (resuelto).
2. Rangos de edad por departamento de la iglesia: **pendiente de que los facilites**; mientras, valores por defecto y editables por evento.
3. ~~Impresión~~ → **sí**, PDF o impresora conectada (resuelto). Pendiente de confirmar: ¿también las listas de pendientes de comida y los reportes? (el plan las incluye tras la lista de hospedaje).
4. ~~Tamaño de evento~~ → hasta 1000+ (media < 500): objetivo de rendimiento fijado; se probará con datos sintéticos de 1500 asistentes.

## Cambio de formato de respaldo (feedback de usuario)

El formato `.mievento` (ZIP + JSON, con contraseña AES) **ya no existe**. La app solo intercambia CSV:

- **Respaldo de un evento** = un único CSV (`;`, UTF-8 con BOM) con la columna `tabla` (`meta`, `events`, `attendees`, …).
  Cada fila conserva `id`, `createdAt`, `updatedAt`, `deletedAt` (marcas en ms UTC) y las referencias por id, así que se sigue
  fusionando por «gana la fila más reciente». Las filas `meta` llevan versión de formato/esquema, dispositivo, evento,
  número de filas por tabla y una suma SHA-256: un archivo cortado, editado o «arreglado» por Excel se rechaza con un mensaje claro.
- Sin cifrado: el archivo contiene datos personales y se debe guardar/compartir con cuidado.
- XLSX, PDF e imágenes quedan solo para **reportes** (reportes, comidas, hoja de hospedaje).
- Código: `packages/mi_evento_core/lib/src/bundle.dart` (formato) y `apps/mi_evento/lib/backup/backup_service.dart` (export/import).

## Preinscripción y confirmación de asistencia (feedback de usuario)

- Cada asistente tiene un estado: **confirmado** (por defecto, como siempre) o **preinscrito** (`Attendees.status`, `confirmedAt`).
- Registrar: el formulario tiene el interruptor «Preinscripción» (también para el cónyuge nuevo). En la ficha de un preinscrito hay un botón «Confirmar».
- **Confirmar asistencia** (menú «Confirmar asistencia»): lista de preinscritos con búsqueda; confirmar uno, marcar un subconjunto o «Confirmar a todos» (los que se ven). Con «Deshacer».
  Código: `Repository.confirmAttendance` / `unconfirmAttendance`, `ui/attendance_screen.dart`.
- Pasar la lista de un evento a otro: «Exportar asistentes» (CSV) en el evento de origen e «Importar CSV» en el destino con la casilla **«Importar como preinscripción»**
  (las personas nuevas entran preinscritas; se ignoran el hospedaje y el equipo del archivo porque son del otro evento).
- En «Asistentes» hay un filtro «Asistencia» (Confirmados / Preinscritos) y una etiqueta «Preinscrito»; la exportación respeta el filtro.
- Pendiente a decidir: que reportes y control de comidas cuenten solo confirmados (hoy cuentan a todos los inscritos).

## Duplicar evento y pasar participantes (feedback de usuario)

- «Mis eventos» → menú del evento (administrador):
  - **Duplicar evento…**: crea un evento nuevo (nombre y fechas propios) con ids nuevos. Siempre copia datos del evento, rangos de edad y tipos de control;
    opcionalmente participantes (como preinscritos o conservando su estado), grupos, equipos y hospedajes. Con participantes, cada uno conserva su equipo/hospedaje
    solo si esa estructura también se copia; los matrimonios y el capitán se remapean. No copia sesiones ni marcas de comidas.
  - **Pasar participantes a otro evento…**: copia a las personas a un evento que ya existe (preinscritas por defecto), omitiendo a quien ya está
    (mismo nombre, primer apellido y edad) y conservando matrimonios. No lleva equipo ni hospedaje.
- Código: `data/event_copy.dart` (`EventCopy.duplicateEvent`, `EventCopy.copyPeople`), `ui/event_copy_dialogs.dart`.
- **Reportes y comidas cuentan solo a los confirmados** (`confirmedAttendeesProvider`); marcar a un preinscrito en una sesión de control da un aviso
  («confirma primero su asistencia»). Los inscritos el día del evento son confirmados por defecto.

## Formulario de registro (feedback de usuario)

- **Sexo**: lista desplegable con «M (Hombre)» / «F (Mujer)» (`f-sexo`).
- **Obligatorios** marcados con `*`: nombre, primer apellido, sexo, edad e iglesia. Segundo apellido y teléfono son opcionales y lo dicen en su etiqueta.
- **Provincia y municipio** se toman de la iglesia elegida (solo lectura, fuera del orden de Tab) y esos son los que se guardan en la persona.
- **Duplicados**: el aviso se basa en mismo nombre y apellidos (la edad ya no cuenta; con segundo apellido escrito, coincide con quien tenga el mismo o ninguno).
  Al guardar, si hay coincidencia y no se pulsó «Es otra persona», aparece un diálogo (cancelar / ver ese registro / guardar igual).
- **Tab** recorre solo los campos, en orden: nombre, apellidos, sexo, edad, teléfono, iglesia (luego los interruptores y botones de abajo). Las sugerencias de iglesia, el aviso de duplicado
  y el botón de eliminar quedan fuera del orden de Tab; la iglesia se elige con el teclado al salir del campo (Tab o Enter) si coincide exactamente o es la única sugerida.

## Iglesias: provincia → municipio → comunidad (feedback de usuario)

- «Iglesia nueva»: Provincia (lista) → Municipio (lista con los municipios de esa provincia; se vacía al cambiar de provincia) → Comunidad (opcional, autocompleta con las comunidades ya registradas en ese municipio;
  si no aparece se escribe y queda añadida para las próximas). Nombre, provincia y municipio son obligatorios al registrar a mano (`createChurch(requireLocation: true)`; las importaciones CSV no lo exigen).
- Las sugerencias de iglesia muestran «comunidad, municipio, provincia». Código: `communitiesOf`, `normalizeCommunity` en `data/repository.dart`, `_NewChurchDialog` en `ui/attendee_form.dart`.

## Hospedajes y vistas de escritorio (feedback de usuario)

- **Sin preferencia** (`LodgingAccepts.any`): acepta hombres, mujeres y matrimonios. La sugerencia lo usa como comodín (después de un hospedaje específico que sirva igual de bien) y cuenta como hospedaje de matrimonios (`acceptsCouples`).
- Al inscribir, la lista de hospedajes se puede **buscar** (nombre, anfitrión, zona) y **filtrar** («solo los que aceptan hombres/mujeres» según el sexo elegido, «con plazas libres»). El hospedaje ya elegido siempre se muestra.
- **Escritorio (≥ 900 px)**: Mis eventos, Asistentes y Hospedajes se muestran como **tablas** con columnas ordenables (`ui/widgets/data_table_view.dart`), junto con la barra de búsqueda/filtros/exportar. En móvil siguen las tarjetas.
  Equipos conserva su vista de tarjetas con arrastrar y soltar (ya era específica de escritorio).
