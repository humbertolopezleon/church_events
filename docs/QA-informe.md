# Informe de QA funcional — Mi Evento

> **Estado tras las correcciones (rama `correcciones-qa`):** corregidos los 2 defectos ALTOS (QA-BUG-001, 009), los 6 MEDIOS (003, 004, 006, 008, 010, 011) y los BAJOS 002, 005, 012 y 013. **Todos los defectos quedan corregidos** (007 en una segunda tanda). Cada defecto de la sección 4 indica su estado y cómo se corrigió. Las cifras de las secciones 1, 3 y 5 son las de la **primera** ejecución (antes de corregir); los números nuevos están en cada defecto y en la sección 5.1.

Fecha: 22 de noviembre de 2026 · Versión probada: repositorio en el commit `cfa2269` («Inscribir al cónyuge desde la ficha…»); las exploraciones empezaron en `e8981c8` y el código de `lib/` no se modificó en ningún momento.
Todo lo de este informe se probó en el **entorno de pruebas de Flutter** (motor de pruebas, SQLite en memoria, pantalla simulada). **No se probó en dispositivos reales**: ver la sección «Límites honestos».

---

## 1. Resumen ejecutivo

**Qué se hizo.** Se diseñó e implementó un conjunto de pruebas que imitan a usuarios reales (voluntaria con poca experiencia, operador con prisa, administrador, alguien que se equivoca) sobre la app «Mi Evento»: inscripción, configuración en dos momentos, equipos automáticos, hospedaje, exportación e importación (CSV y `.mievento`), el flujo «Windows → móvil», control de comidas, reportes, seguridad y robustez. El evento de referencia tiene **120 personas** (y se llegó a **1000** para los tiempos).

**Números.**

- **179 pruebas nuevas**: 170 en la app (`apps/mi_evento/test/qa/`) y 9 en el núcleo (`packages/mi_evento_core/test/qa/`).
- **162 pasan, 17 están omitidas a propósito** (cada una tiene la prueba completa escrita y el defecto que la hace fallar) y **0 fallan**.
- Suite completa de la app tras añadirlas: **387 pruebas, 372 pasan, 15 omitidas, 0 fallan**; núcleo: **134 pruebas, 132 pasan, 2 omitidas, 0 fallan**. `flutter analyze` y `dart analyze`: sin avisos.
- Costo en el CI: la carpeta `test/qa` tarda unos **2 minutos** (118 s de reloj en este entorno; la suite completa de la app tarda 298 s). Las pruebas son deterministas (semilla fija) y no escriben fuera de carpetas temporales.
- **13 defectos** encontrados (2 de gravedad alta, 6 media, 5 baja) y varias observaciones. Todos están documentados con pasos, causa probable y corrección sugerida.
- Entregables adicionales: generador manual de datos (`apps/mi_evento/qa/generate_qa_dataset_test.dart`) y la carpeta `qa-datasets/` con 8 archivos listos para probar la importación (CSV y `.mievento`), cuyo contenido se comprobó con las propias pruebas (`QA-DAT-*`) y leyendo los CSV con Python como si fuera una hoja de cálculo.

**Lo más importante que debe saber quien decide.**

1. **El equipo automático al inscribir no garantiza los topes de balance** (QA-BUG-001, alta). Con 120 personas y datos distintos, en **17 de 30 combinaciones** (2, 3, 4, 6 y 8 equipos) se superó algún tope: hombres–mujeres hasta **15** de diferencia (tope 4) o edad media hasta **14 años** (tope 3). El tamaño de los equipos sí casi siempre queda dentro del tope (±2). En cambio, «Generar equipos» cumple los tres topes con los mismos 120 (QA-EQP-030: equipos de 20, 10 hombres y 10 mujeres, edad media entre 36,0 y 36,3). Recomendación inmediata: al terminar las inscripciones usar «Generar equipos» reorganizando a todos; y corregir `suggestTeam`.
2. **El PDF de reportes falla con más de ~600 inscritos** (QA-BUG-009, alta): «No se pudo exportar. Detalle técnico: PdfTooBigPageException…». El objetivo del proyecto es 1000+. Excel y CSV sí funcionan con 1000.
3. **Matrimonios inscritos de uno en uno con hospedaje aceptado quedan separados** (QA-BUG-003, media): la esposa queda «sin hospedaje» porque el esposo ya está en un albergue de un solo sexo. La función nueva «Inscribir al cónyuge desde la ficha» (commit `cfa2269`) cubre el caso en que se inscribe a los dos juntos; el caso de dos inscripciones separadas sigue fallando.
4. Lo que **sí funciona bien** y se probó a fondo: inscripción y validaciones en PC y móvil, numeración seguida, aviso de duplicados, 20 inscripciones seguidas por la interfaz; hospedaje para 84 personas (todas ubicadas, sin sobrecupo, sexos compatibles, 15 matrimonios juntos) y avisos al forzar; ida y vuelta CSV sin pérdida (120 personas); copias `.mievento` (con y sin contraseña, fusión, renumeración, borrado, archivos alterados); escenario Windows → móvil completo con dos bases independientes; control de comidas con 120 personas; seguridad (bloqueo progresivo, permisos, admin/admin); rendimiento con 1000 inscritos (importar el CSV 1,2 s, generar equipos 0,3 s, copia 0,2 s).

---

## 2. Qué se probó y cómo

| Capa | Cómo | Para qué |
|---|---|---|
| **Interfaz real** (`testWidgets`) | La app completa (`MiEventoApp`) con base en memoria, en ancho de PC (1200×2400) y de móvil (400×900); también 360×640, 911×512 y 1093×614. Toques, escritura, Enter, diálogos. | Lo que ve y toca una persona. |
| **Capa de datos real** | Los repositorios reales (`Repository`, `SocialRepo`, `LodgingRepo`, `TeamRepo`, `MealRepo`, `AttendeeExchange`, `BackupService`, `AuthService`) sobre SQLite en memoria; con 120 y 1000 personas. | Volumen y reglas de negocio. Las inscripciones imitan **exactamente** el guardado del formulario (alta + cónyuge + grupos + `autoAssign` en una transacción). |
| **Núcleo** | `suggestTeam`, `evaluateBalance`, `generateTeams`, `suggestLodging`, lectura de CSV, `.mievento`, normalización de texto. | Algoritmos y formatos. |

Reglas que se respetaron: no se tocó `lib/` ni ninguna prueba existente; no se hizo commit; las pruebas del CI no escriben en el repo (solo carpetas temporales que se borran); se usa el ejecutor real de hilos (`Isolate`) en una prueba de contraseñas (QA-SEG-012) además del falso; los desbordes de pantalla se tratan como hallazgos.

**Datos de prueba.** `qaPeople(n, semilla)` genera personas ficticias siempre iguales: nombres con tildes y ñ («Ñuri O'Farrill Quiñones»…), edades 12–70 (sesgadas a jóvenes), hombres y mujeres mezclados, 9 iglesias, 15 matrimonios (3 con la esposa llegando 10 puestos después del esposo), 5 grupos de iglesia y ~70 % que necesita hospedaje.

---

## 3. Resultados por módulo

| Módulo | Pruebas | Pasan | Omitidas por defecto | Fallan |
|---|---:|---:|---:|---:|
| Inscripción | 11 | 10 | 1 | 0 |
| Configuración del evento | 4 | 4 | 0 | 0 |
| Equipos | 34 | 30 | 4 | 0 |
| Hospedaje | 23 | 21 | 2 | 0 |
| Exportación e importación CSV | 27 | 23 | 4 | 0 |
| Copias .mievento | 22 | 22 | 0 | 0 |
| Escenario Windows → móvil | 2 | 2 | 0 | 0 |
| Control de comidas | 15 | 15 | 0 | 0 |
| Seguridad y permisos | 10 | 10 | 0 | 0 |
| Robustez e interfaz | 11 | 7 | 4 | 0 |
| Reportes | 5 | 5 | 0 | 0 |
| Datos de prueba entregados | 6 | 6 | 0 | 0 |
| Núcleo (texto, duplicados, rangos) | 9 | 7 | 2 | 0 |
| **Total con el núcleo** | **179** | **162** | **17** | **0** |

(«Omitidas por defecto» = la prueba está escrita completa y se omite con `skip` porque descubrió un defecto real; se verificó, quitando el `skip` en una copia temporal, que cada una **falla** tal como se describe.)

---

## 4. Defectos encontrados

Gravedad: **alta** = una función principal no cumple lo prometido o falla en el tamaño objetivo; **media** = hay que dar vueltas o se pierde información sin grave consecuencia; **baja** = molestia o caso raro.

| ID | Gravedad | Resumen | Prueba omitida (ya activa si está corregido) | Estado |
|---|---|---|---|---|
| QA-BUG-001 | **Alta** | El equipo automático al inscribir no cumple los topes de balance (sexo y edad; a veces tamaño) | `QA-EQP-001b`, `007b`, `010` | Corregido (24 de 30 cumplen; ver 5.1) |
| QA-BUG-009 | **Alta** | El PDF de reportes falla con más de ~600 inscritos | `QA-ROB-002` | Corregido (1000 inscritos → 37 páginas) |
| QA-BUG-003 | Media | Matrimonio inscrito en dos fichas separadas: la esposa queda sin hospedaje | `QA-HOS-027` | Corregido (propuesta de mover a los dos) |
| QA-BUG-004 | Media | Borrar a un asistente no limpia pareja, equipo, capitán ni hospedaje | `QA-HOS-041` | Corregido |
| QA-BUG-006 | Media | La importación CSV no asigna equipo automático a las personas nuevas | `QA-CSV-033` | Corregido |
| QA-BUG-008 | Media | La importación CSV renumera: con huecos los números dejan de coincidir entre dispositivos | `QA-CSV-060` | Corregido |
| QA-BUG-010 | Media | En móvil estrecho (360×640) se desbordan pantallas (Panel a 100 %; 4 pantallas con letra grande) | `QA-ROB-011` (360×640) | Corregido |
| QA-BUG-011 | Media | En ventana baja (911×512) el menú lateral no se desplaza: «Comidas» y «Reportes» son inalcanzables | `QA-ROB-012` (150 %) | Corregido (el menú ya se desplazaba; ver detalle) |
| QA-BUG-002 | Baja | Con equipos vacíos al inicio, la 2.ª persona va al mismo equipo que la 1.ª | `QA-EQP-003` | Corregido |
| QA-BUG-005 | Baja | El CSV exportado no neutraliza celdas que empiezan con `= + - @` (fórmulas en Excel) | `QA-CSV-013` | Corregido |
| QA-BUG-007 | Baja | CSV con parejas contradictorias: una persona pierde su pareja sin aviso | `QA-CSV-039` | Corregido |
| QA-BUG-012 | Baja | La normalización de texto parte «O'Farrill», «João», «Gonçalves» | `QA-TXT-005`, `006` | Corregido |
| QA-BUG-013 | Baja | Dos toques en el mismo fotograma en «Guardar» crean la persona dos veces | `QA-INS-014` | Corregido |

### QA-BUG-001 · Equipo automático sin garantía de balance (alta)

**Estado: Corregido (parcialmente medible: 24 de 30 combinaciones cumplen los tres topes; antes 13 de 30).** `suggestTeam` ahora elige el equipo que deja el menor *costo* de balance tras añadir a la persona, con el mismo cálculo que «Generar equipos» (función compartida `balanceParts`/`balanceCost` en `balance.dart`): primero cuánto se exceden los topes de tamaño y sexo (aunque ya estuvieran superados), luego el de edad, y después igualar tamaño, sexo y edad. El cónyuge sigue yendo con su cónyuge. Mientras haya equipos vacíos se llenan primero (arregla QA-BUG-002). Resultados con las mismas 30 combinaciones: **6 siguen superando algún tope** y todas por causas que no se pueden evitar sin mover a gente ya asignada: 2 equipos/datos 303 (H–M 8) y 3 equipos/datos 303 (H–M 6) y 2 equipos/datos 505 (H–M 5) tienen muchas más mujeres que hombres en total, de modo que con tan pocos equipos es matemáticamente imposible cumplir el tope; 6 equipos/datos 101 y 8 equipos/datos 101 (tamaño 3) por esposas que llegan después y entran por fuerza al equipo del esposo; 8 equipos/datos 202 (edad 3,7 años). Peor caso ahora: H–M 8 (antes 15), edad 3,7 años (antes 14,3), tamaño 3 (antes 3). *Mejora valorada y NO aplicada:* un intercambio local al inscribir cambiaría de equipo a personas ya asignadas sin que lo pidan (rompe el principio «solo sugerir»); para cerrar esos casos se usa «Generar equipos» (reorganizando a todos), que es una propuesta. **Decisión pendiente de la persona usuaria:** si quiere que el sistema reubique solo, o que muestre una propuesta de ajuste cuando un tope se supera. Pruebas: `QA-EQP-001b` (ahora acepta solo los casos inevitables y exige ≤ 7 fallos), `007b`, `010` y pruebas nuevas en `team_suggest_test.dart`. Se relajaron `QA-EQP-001c`, `007.n` y `010` (tamaño hasta 3-4) porque las esposas tardías pueden sumar 1-2 a un equipo; el tope estricto de tamaño no es garantizable al inscribir de una en una.

- **Qué pasa.** Al inscribir una por una, la persona se asigna al equipo que «menos empeora» el balance (estrategia C), pero el resultado final no siempre cumple los topes (tamaño ±2, hombres–mujeres ≤ 4, edad media ±3 años).
- **Evidencia** (QA-EQP-001b/001c, 120 personas inscritas en orden): de 30 combinaciones (2, 3, 4, 6, 8 equipos × 6 conjuntos de datos) **17 superan algún tope**. Ejemplos: 2 equipos, datos 303: hombres–mujeres **15** (tope 4); 4 equipos, datos 505: edad media **14,3** años de diferencia (tope 3); 8 equipos: edad entre 7,4 y 12,8 en los 6 conjuntos. Con 100 personas en 3 equipos el tamaño llegó a 3 (QA-EQP-007.3). El caso base (semilla 2026, 6 equipos) sí cumple: tamaño 2, H–M 1, edad 1,31.
- **Pasos para reproducir.** Crear un evento con 6 equipos (criterios por defecto), inscribir 120 personas seguidas con el formulario y abrir «Equipos»: el aviso de edad media aparece. En pruebas: quitar el `skip` de `QA-EQP-001b` en `eq_data_test.dart`.
- **Causa probable.** `suggestTeam` (`packages/mi_evento_core/lib/src/balance.dart`) solo cuenta los topes **nuevos** que causaría la persona: descarta los que ya estaban superados entre los mismos equipos, así que empeorarlos «no cuesta». Después ordena por: equipo del cónyuge → nº de topes nuevos → tamaño → hombres–mujeres → cercanía de la edad media; la edad queda siempre al final y sin medir cuánto se excede.
- **Corrección sugerida.** Elegir el equipo que minimice una **puntuación con la magnitud del exceso** (la misma que usa `generateTeams`, que sí cumple: QA-EQP-030), o al menos priorizar edad y sexo cuando el tamaño está dentro del tope. Mientras tanto, usar «Generar equipos» (reorganizando a todos) al cerrar las inscripciones.

### QA-BUG-009 · PDF de reportes falla desde ~600 inscritos (alta)

**Estado: Corregido.** `reportPdf` y el PDF de la lista de hospedaje usan `maxPages: 2000`. Con 1000 inscritos el PDF se genera en ≈1,5 s, 167 KB y **37 páginas** (`QA-ROB-002`, ya activa). No hay otros PDF en la app.

- **Evidencia.** Con 400 inscritos el PDF se genera (0,8 s); con 600, 800, 900 y 1000 lanza `PdfTooBigPageException: This widget created more than 20 pages` (QA-ROB-002). En pantalla se vería «No se pudo exportar. Detalle técnico: PdfTooBigPageException…» (hay mensaje, no spinner), pero no se obtiene el PDF.
- **Pasos.** Importar un CSV de 600+ personas → «Reportes» → «Guardar como PDF» o «Imprimir».
- **Causa probable.** `reportPdf` (`apps/mi_evento/lib/export/report_export.dart`, ~línea 216) usa `pw.MultiPage` con el límite por defecto de 20 páginas.
- **Corrección.** Pasar `maxPages` suficiente (p. ej. 500) o paginar la tabla en varios documentos; añadir la prueba con 1000.

### QA-BUG-003 · Matrimonio en dos fichas separadas (media)

**Estado: Corregido.** Al vincular a alguien cuyo cónyuge ya está hospedado donde no pueden estar juntos (albergue de un solo sexo, o hospedajes distintos), la ficha muestra un aviso y una **propuesta con borde discontinuo**: «mover a los dos cónyuges a «X» (2 plazas)», con «Mover a los dos» o «Dejarlos como están» (y la lista para elegir otro). No se mueve a nadie hasta guardar. Además, si se elige a mano un hospedaje de matrimonios, el cónyuge se mueve con la persona (y se dice «X también pasará a…»); si se elige uno de un solo sexo, avisa que separa al matrimonio. La lógica es `proposeCoupleMove` (núcleo). `QA-HOS-027` activa: 15 matrimonios juntos, 0 pendientes. Pruebas de interfaz: `test/couple_move_ui_test.dart`. *Aclaración tras una revisión manual:* una primera versión solo cubría el caso de «propuesta»; al elegir a mano un hospedaje de matrimonios se movía solo a una persona y quedaba el aviso engañoso «queda 1 persona sin su cónyuge»; ya no ocurre.

- **Evidencia** (QA-HOS-027): inscribiendo a las 120 personas una por una y aceptando siempre la sugerencia del formulario, **los 15 matrimonios** quedaron con la esposa sin hospedaje (15 pendientes).
- **Pasos.** Inscribir al esposo y aceptar el hospedaje sugerido (queda en un albergue «solo hombres»). Inscribir a la esposa vinculándola a él: el formulario dice que no hay plaza junto a su cónyuge.
- **Causa.** `suggestLodging` solo coloca al segundo cónyuge «junto al primero» si ese hospedaje acepta matrimonios; el primero no sabía que era casado cuando se le sugirió un albergue de un solo sexo.
- **Corrección.** Al vincular a alguien que ya está en un hospedaje de un solo sexo, ofrecer mover a los dos a uno de matrimonios (misma propuesta de 2 plazas que ya usa el commit `cfa2269`). Alternativa de uso: «Dejar para después» y luego «Sugerir hospedaje» con los dos (QA-HOS-001 y 004 comprueban que así los 15 matrimonios quedan juntos).

### QA-BUG-004 · Borrar a un asistente deja referencias (media)

**Estado: Corregido.** `Repository.deleteAttendee` (una transacción) desvincula la pareja (el cónyuge queda sin pareja), vacía equipo y hospedaje, quita el cargo de capitán (el equipo queda sin capitán), saca a la persona de sus grupos y devuelve el nombre del equipo para avisar: «Era capitán de «X»: ese equipo se quedó sin capitán». `QA-HOS-041` y la nueva `041b`.

- **Evidencia** (QA-HOS-041, capa de datos): tras borrar a un esposo, la esposa sigue vinculada a él (`spouseOf` lo devuelve); por el código, la persona borrada también conserva su equipo, su hospedaje y, si era capitán, el equipo sigue apuntando a ella. PLAN.md §2 promete limpiar pareja, equipo y hospedaje, y avisar si era capitán. Los conteos de equipos y hospedajes sí excluyen a los borrados (QA-HOS-040 pasa).
- **Causa.** `Repository.deleteAttendee` solo escribe `deleted_at`. **Corrección:** en la misma transacción desvincular la pareja, vaciar equipo/hospedaje/capitán y marcar sus filas de grupo como borradas. (No se comprobó cómo lo muestra la ficha de la esposa: solo la capa de datos.)

### QA-BUG-006 · CSV sin equipo automático (media)

**Estado: Corregido.** Tras vincular las parejas, las personas nuevas que no traen equipo válido en el archivo reciben equipo automático (`TeamRepo.autoAssignMany`, que lee la base una sola vez: 1000 personas se importan en ≈1,6 s, con 0 topes superados). Si el archivo trae un equipo que existe, ese manda. Si el equipo del archivo no existe, avisa y se asigna uno automático. El resumen de la importación dice cuántas quedaron con equipo automático. `QA-CSV-033` y nuevas `033b/033c`.

- **Evidencia** (QA-CSV-033; mismo efecto con `qa-datasets/importar_nuevos_30.csv`): las personas nuevas importadas quedan **sin equipo** aunque el evento tenga equipos. El formulario sí los asigna.
- **Causa.** `AttendeeExchange.apply` solo asigna el equipo que trae el archivo. **Corrección:** llamar a `TeamRepo.autoAssign` para las personas nuevas sin equipo en el archivo (o avisar «30 personas sin equipo: usa Generar equipos»).

### QA-BUG-008 · El CSV no conserva el número de inscripción (media)

**Estado: Corregido.** Decisión: para las personas **nuevas** se conserva el `numero` del archivo si está libre en el evento (cuentan también los números de personas borradas, porque su número sigue reservado); si está ocupado, se usa el siguiente. Las parejas por número siguen resolviéndose con el número del archivo. Los números de personas sin `numero` siguen siendo el siguiente. `QA-CSV-060` y nuevas `036b/036c`.

- **Evidencia** (QA-CSV-060): un evento A con el nº 3 borrado exporta números 1,2,4,5…10; al importar en un evento vacío de B, los números quedan 1…9. Con la copia `.mievento` sí se conservan (QA-BAK-010). Si se imprimieron credenciales o listas con los números de A, no coincidirán.
- **Causa.** `Repository.addAttendee` siempre pone el siguiente número; el `numero` del archivo solo sirve para enlazar parejas. **Corrección:** usar el número del archivo cuando esté libre en el evento destino (y renumerar solo si choca).

### QA-BUG-010 · Móvil estrecho y letra grande (media)

**Estado: Corregido** (comprobado en el entorno de pruebas, no en un teléfono real). En realidad el desborde del Panel a 100 % venía de la barra de «Mis eventos» (dos botones con texto + título): en pantallas < 480 px ahora son botones de solo icono con ayuda. Además: el aviso de copia del Panel apila texto y botón, Hospedajes reparte el ancho nombre/tipo con `flex`, y los estados vacíos de Equipos y Comidas se desplazan. `QA-ROB-011` (360×640 a 100 % y 150 %) activa y sin problemas.

- **Evidencia** (QA-ROB-011, fuente de pruebas ancha: los desbordes aparecen antes que en un teléfono real): en **360×640 con letra al 100 %** el Panel se desborda 30 px a la derecha; con **letra al 150 %**: Panel (varias), Hospedajes (11 desbordes), Equipos (3 px) y Comidas (173 px hacia abajo). En 400×900 con letra al 100 % y 130 % **no** hay desbordes en ninguna de las 7 pantallas.
- **Corrección.** Revisar con letra grande las filas fijas del Panel y de Hospedajes, y la columna de Comidas (permitir desplazamiento). Confirmar en un teléfono real de 360 px.

### QA-BUG-011 · Ventana baja: menú inalcanzable (media)

**Estado: Corregido / aclarado.** El menú lateral ya era una lista que se desplaza; lo que no se alcanzaba en la prueba era porque el ayudante buscaba el texto sin desplazar el menú. El ayudante ahora desplaza el menú (`qaScrollMenuTo`) y comprueba que «Comidas» y «Reportes» se alcanzan. El desborde real a 911×512 era de la pantalla de acceso (panel azul no desplazable): ahora se desplaza. `QA-ROB-012` activa y sin problemas.

- **Evidencia** (QA-ROB-012): con una ventana de **911×512** (portátil 1366×768 al 150 %) el menú lateral no se desplaza: «Comidas» y «Reportes» no se alcanzan, y el Panel se desborda 42 px. Con **1093×614** (al 125 %) todo funciona.
- **Corrección.** Hacer el menú lateral desplazable (`ListView`/`SingleChildScrollView`).

### Defectos de gravedad baja

**Estados:** QA-BUG-002 corregido (con QA-BUG-001: las 6 primeras personas caen en 6 equipos distintos). QA-BUG-005 corregido: al exportar CSV (asistentes, reportes y comidas) las celdas que empiezan con `=`, `+`, `-` o `@` (o tabulador) llevan un apóstrofe delante, salvo números sueltos como `+5355551234`; al importar se quita. QA-BUG-012 corregido: se ignoran los apóstrofes y se amplía la tabla (ã, ç, ø, ß, ł…); QA-BUG-013 corregido (`if (busy) return;` en el guardado). **QA-BUG-007 corregido (decisión de la persona usuaria: avisar y no vincular a nadie):** si en el CSV A→B pero B→C, o dos personas dicen ser pareja de la misma, no se vincula a ninguna de las implicadas y se avisa fila por fila («se contradice con otra fila»). `QA-CSV-039` activa. QA-BUG-012: no hace falta migración porque la app aún no está en producción (no hay datos guardados con la normalización anterior).
**Observaciones resueltas en la segunda tanda:** UTF-16 (Excel «Texto Unicode», con marca FF FE o FE FF) ahora se lee bien (`QA-CSV-023`); los rangos de edad por defecto de eventos NUEVOS incluyen «0–11» ( `QA-TXT-011`). **Decididos y no cambiados:** el equipo automático al inscribir sigue ignorando los grupos «mantener juntos» («Generar equipos» sí los respeta); los 6 casos de balance restantes solo se avisan (el aviso ya aparece en Equipos).


- **QA-BUG-002** (QA-EQP-003, 003b): con 6 equipos vacíos, tras las 6 primeras personas sin pareja quedan **3 equipos vacíos**; los equipos tardan unas 12 inscripciones en tener gente. Es consecuencia de la misma lógica de `suggestTeam` (entrar a un equipo vacío crea un tope de edad «nuevo» si las edades difieren, y por eso se prefiere el equipo con gente). El tamaño sigue dentro del tope. Corrección: preferir equipos vacíos.
- **QA-BUG-005** (QA-CSV-013): un nombre u observación que empiece con `=`, `+`, `-` o `@` se exporta tal cual; al abrir el CSV en Excel se evalúa como fórmula («inyección de fórmulas»). Riesgo bajo en una iglesia, pero un visitante malintencionado podría inscribirse con `=HYPERLINK(…)`. Corrección: anteponer un apóstrofe o un espacio a esas celdas al exportar (y al exportar reportes/comidas).
- **QA-BUG-007** (QA-CSV-039): en un CSV con parejas contradictorias (Ana→Beto, Beto→Cris) Ana queda sin pareja y **no se avisa** (el último vínculo desvincula al anterior). Corrección: detectar y avisar.
- **QA-BUG-012** (QA-TXT-005/006): `normalizeText` convierte el apóstrofe en espacio («OFarrill» no encuentra a «O'Farrill») y solo conoce las tildes españolas: «João», «Gonçalves» quedan partidos («jo o»). Importa para búsqueda y duplicados. Corrección: eliminar apóstrofes y ampliar la tabla (o usar descomposición Unicode).
- **QA-BUG-013** (QA-INS-014): dos toques **en el mismo fotograma** en «Guardar» crean a la persona dos veces (el botón se desactiva en el siguiente fotograma). Un dedo no lo provoca: con un fotograma entre toques (como un doble toque real) no se duplica (QA-INS-013 pasa). Un teclado con rebote o un ratón sí podrían. Corrección: cerrojo (`if (busy) return;`) al inicio de `_save`.

### Observaciones (no son defectos, pero conviene saberlas)

- **Marcas de tiempo en segundos** (QA-BAK-025): la base guarda las horas con precisión de 1 s. Si el mismo dato se cambia en dos dispositivos dentro del mismo segundo, gana la copia local. La fusión por «más reciente» funciona con minutos de diferencia (QA-BAK-021).
- **El CSV no lleva la configuración**: el evento destino necesita hospedajes y equipos con los **mismos nombres**; si no, avisa fila por fila y esas personas quedan sin ellos (QA-CSV-037). La copia `.mievento` sí lleva todo.
- **El equipo automático ignora los grupos «mantener juntos»**: los 5 grupos de la prueba quedaron repartidos en varios equipos al inscribir (QA-EQP-011). «Generar equipos» sí los mantiene juntos (QA-EQP-034) y avisa cuando un grupo enorme rompe el tope de tamaño (QA-EQP-036: grupo de 14 en 4 equipos → «Tamaño: … diferencia 6»).
- **El teléfono acepta cualquier texto** («no tiene»), sin validar formato (QA-INS-005).
- **UTF-16** (Excel «Texto Unicode») no se entiende: sale «Fila 1: Faltan columnas obligatorias: nombre, apellido1, sexo, edad, iglesia. Usa la plantilla de Mi Evento.», que no explica la causa real (la codificación) (QA-CSV-023).
- **Menores de 12 años** no entran en ningún rango de edad por defecto (12–17, 18–25, 26–40, 41+) y salen como «Sin rango» en los reportes (QA-TXT-011), aunque la inscripción admite edad desde 1.
- **La sugerencia de hospedaje llena unos hospedajes y deja otros casi vacíos** (por diseño «aprovechar plazas»): Casa Familia Ortiz 2/8, Albergue de la Escuela 4/12, tres casas sin nadie (QA-HOS-002).
- En comidas la búsqueda muestra solo los **6** primeros resultados (hay que escribir más para acotar).
- Un detalle que **sí** funciona: el matrimonio cuya esposa llega 10 inscripciones después del esposo queda igualmente en el mismo equipo (QA-EQP-006).

---

## 5. Métricas reales

### 5.1 Balance de equipos (estrategia C: tamaño ±2, H–M ≤ 4, edad ±3)

**Después de la corrección (QA-BUG-001):** de las 30 combinaciones, **24 cumplen los tres topes y 6 no** (antes 13 cumplían y 17 no). Las 6: 2 equipos/datos 303 (tamaño 0, H–M 8, edad 0,9) · 2 equipos/datos 505 (2 / 5 / 0,6) · 3 equipos/datos 303 (3 / 6 / 1,8) · 6 equipos/datos 101 (3 / 2 / 1,7) · 8 equipos/datos 101 (3 / 2 / 3,2) · 8 equipos/datos 202 (2 / 4 / 3,7). Las 3 primeras de sexo son inevitables por los datos; las demás, por esposas que llegan tarde. Con 1000 personas importadas por CSV en 20 equipos: 0 topes superados. Las tablas de abajo son las de **antes** de corregir.


**Caso base, 120 personas inscritas una por una, 6 equipos (semilla 2026)** — QA-EQP-001:

| Equipo | Personas | Hombres / Mujeres | Edad media |
|---|---:|---|---:|
| Rojo | 19 | 10 / 9 | 36,8 |
| Azul | 20 | 10 / 10 | 36,0 |
| Verde | 21 | 10 / 11 | 35,8 |
| Amarillo | 19 | 10 / 9 | 36,6 |
| Morado | 20 | 10 / 10 | 36,4 |
| Naranja | 21 | 10 / 11 | 35,5 |

Diferencias obtenidas: tamaño **2** (tope 2), H–M máximo **1** (tope 4), edad media **1,31** años (tope 3) → **cumple los tres**. Durante la inscripción (desde la nº 12) el tamaño nunca pasó de 2 en los 109 pasos medidos (QA-EQP-004).

**Matriz de robustez** (120 personas, 6 conjuntos de datos, QA-EQP-001b) — diferencia de tamaño / H–M máx. / edad media; **negrita** = supera el tope:

| Equipos | datos 101 | datos 202 | datos 303 | datos 404 | datos 505 | datos 606 |
|---|---|---|---|---|---|---|
| 2 | 2 / 3 / 0,5 | 0 / 4 / 0,5 | 2 / **15** / 2,1 | 0 / 4 / 0,2 | 2 / **7** / 1,6 | 0 / 2 / 1,5 |
| 3 | 2 / 4 / 1,3 | 2 / 4 / 1,2 | 2 / **8** / **5,2** | 0 / 4 / 0,6 | 2 / 4 / **3,2** | 0 / 2 / 1,3 |
| 4 | 0 / 2 / 2,6 | 2 / 3 / 2,5 | 2 / **10** / **3,8** | 0 / 2 / 2,1 | 2 / 3 / **14,3** | 2 / 3 / **3,0x** |
| 6 | 2 / 2 / **10,0** | 2 / 3 / **12,2** | 2 / 4 / **6,8** | 0 / 2 / 2,9 | 2 / 3 / 2,6 | 2 / 2 / **11,3** |
| 8 | 2 / 2 / **9,4** | 2 / 2 / **11,2** | 2 / 4 / **7,4** | 2 / 4 / **9,8** | 2 / 4 / **12,0** | 2 / 1 / **12,8** |

(«3,0x» = 3,0 y fracción, supera por décimas.) **17 de 30 superan algún tope.** Además, 100 personas en 3 equipos llegaron a tamaño 3 (QA-EQP-007.3) y con 2 equipos H–M 6 (QA-EQP-007.2). Con topes más estrictos (±1, 2, 2) tampoco se cumplen (QA-EQP-010, omitida: el tamaño llega a 2 con tope 1).

**«Generar equipos» con los mismos 120** (QA-EQP-030): Rojo, Azul, Verde, Amarillo, Morado y Naranja con **20 personas** cada uno, 10 hombres y 10 mujeres, edad media entre 36,0 y 36,3 → **0 topes superados**. «Aceptar», «Descartar», «Deshacer» y que respete a quien ya tiene equipo: QA-EQP-031 a 033 y la prueba de interfaz QA-EQP-050. Con 1000 personas en 20 equipos: 273 ms y 0 topes superados (QA-ROB-001).

### 5.2 Hospedaje (120 personas; 84 necesitan: 28 hombres solos, 26 mujeres solas, 15 matrimonios = 30 personas)

Hospedajes creados (11): albergues de hombres (24 y 12 plazas) y de mujeres (24), casas de hombres (6 y 4), de mujeres (5 y 6) y de matrimonios (8, 8, 10 y 10 plazas). Con la sugerencia aceptada (QA-HOS-001/002): **84 de 84 ubicadas, 0 sin lugar, ninguna sobrecapacidad, sexos compatibles, 15 matrimonios juntos en casas de matrimonios**. Ocupación: Albergue Central (hombres) 24/24 · Albergue Juvenil (mujeres) 24/24 · Albergue de la Escuela (hombres) 4/12 · Casa Familia Gómez 8/8 · Casa Familia Ortiz 2/8 · Casa Familia Rivas 10/10 · Casa Familia Ñáñez 10/10 · Casa de la Hna. Carmen 2/6 · Casa de la Hna. Teresa 0/5 · Casa del Hno. Osvaldo 0/4 · Casa del Hno. Ramón 0/6.

- Con las plazas **justas** (28 + 26 + 30): también las ubica a todas (QA-HOS-005).
- Con **40 %** de las plazas: «Faltan 18 plazas para matrimonios», «9 para hombres», «12 para mujeres»; 39 personas sin lugar, nadie asignado de más (QA-HOS-010, y en pantalla QA-HOS-051 con «Asignar a quienes caben»).
- Forzar a un hombre en un albergue de mujeres avisa «solo acepta mujeres» y deja continuar; pasarse de capacidad avisa «quedaría con 3 personas y solo tiene 2 plazas» (QA-HOS-020/021).
- Listas imprimibles: se generó un PDF válido (`%PDF-`) por cada hospedaje con gente, con y sin teléfono (QA-HOS-030/031). **No se abrió en un visor ni se imprimió.**

### 5.3 Rendimiento con 1000 inscritos (tiempos del entorno de pruebas; PC de desarrollo, no móvil)

**Cambios tras las correcciones:** PDF de reportes con 1000 personas: ≈1,5 s, 37 páginas (ya no falla). Importar 1000 filas por CSV: ≈1,6 s (ahora incluye asignar equipo a cada persona nueva).


| Operación | Tiempo |
|---|---:|
| Leer el CSV de 1000 filas | 13 ms |
| Revisar (vista previa) | 6 – 86 ms |
| Importar 1000 filas (con 60 matrimonios) | 0,7 – 1,2 s |
| Abrir la lista de asistentes (consulta) | 47 ms |
| 5 búsquedas por nombre/número | 92 ms |
| Búsqueda en pantalla (con esperas de la prueba) | ≈ 0,5 s |
| Exportar CSV | 29 ms |
| Generar equipos (20) | 273 ms (+ 25 ms aplicar) |
| Copia `.mievento` | 214 ms · 64 KB |
| Abrir esa copia en otra base | 256 ms |
| Reportes CSV + Excel | 129 ms |
| PDF de reportes (400 personas) | 786 ms |
| PDF de reportes (1000 personas) | **falla** (QA-BUG-009) |
| Alta nº 1001 con equipo automático | 20 ms (promedio de 10) |

Otros tiempos: 20 inscripciones seguidas por la interfaz: 11,7 s de prueba (incluye esperas artificiales entre toques). **No se midió gama baja**: estos números son una cota optimista.

---

## 6. Escenario «Windows → móvil» (QA-WIN-001/002)

Dos bases independientes con distinto `device_id`, con la pantalla de PC (A) y la de móvil (B):

1. **A (1200×2400)** tiene el evento «Congreso QA 2026» (6 equipos, 11 hospedajes, 120 personas inscritas en orden, hospedaje aceptado, parejas y grupos). Por la interfaz, en «Copias de seguridad», **exporta el CSV y la copia `.mievento`** (con `MemoryFileSaver`).
2. **B1 (móvil 400×900)** tiene el evento con los mismos equipos y hospedajes; **importa el CSV por la interfaz** (vista previa «120 personas nuevas» → importar). Resultado: las 120 personas coinciden con A **una por una**: nombre, sexo, edad, iglesia, teléfono, necesita hospedaje, **hospedaje, equipo, pareja, grupos, observaciones y número de inscripción**.
3. **B2 (móvil, otra base vacía)** usa «Abrir una copia» con el `.mievento`: la vista previa dice «120 asistentes…», al confirmar quedan las 120 personas idénticas a A, los mismos 11 hospedajes con la misma ocupación y los 6 equipos. Los `device_id` de A y B son distintos.
4. **B sigue trabajando**: inscribe 2 personas nuevas por la interfaz (números 121 y 122, con equipo automático) y marca a otra en el almuerzo (40 ya marcadas); guarda una copia.
5. **A abre esa copia** por «Abrir copia…»: quedan **122 personas** (sin duplicados), la sesión de comida y sus **41 marcas** una sola vez, y volver a abrir la misma copia no cambia nada (0 nuevos, 0 actualizados).

Además, a nivel de datos (QA-BAK-020): si A y B inscriben cada uno a alguien con el mismo número 121, al fusionar **se renumera uno** y no se pierde a nadie.

---

## 7. Catálogo completo de pruebas

Cada fila es una prueba. «Escenario» resume los pasos y el resultado esperado (el título de la prueba); «Resultado real» es el obtenido en la última ejecución completa. Para ver los pasos exactos, abrir el archivo indicado (carpeta `apps/mi_evento/test/qa/`, salvo `texto_qa_test.dart` en `packages/mi_evento_core/test/qa/`). Las pruebas con nombre «QA-xxx-nnn/mmm» cubren dos casos en una sola apertura de la app para ahorrar tiempo.

### Inscripción

| ID | Escenario (pasos y resultado esperado) | Resultado real | Archivo |
|---|---|---|---|
| QA-INS-001/002 | cada dato obligatorio da su mensaje en español, no se guarda nada hasta completarlo, y las edades límite 1 y 110 sí se guardan | Pasa | `ins_ui_test.dart` |
| QA-INS-003 | tildes, ñ y apóstrofe se guardan tal cual, se encuentran sin tildes y no hay desbordes (PC) | Pasa | `ins_ui_test.dart` |
| QA-INS-005 | teléfono y observaciones se guardan, y al editar reaparecen igual | Pasa | `ins_ui_test.dart` |
| QA-INS-010 | posible duplicado: avisa con el nombre existente, se descarta con «es otra persona», se guarda igual; tildes y mayúsculas coinciden y otro apellido no | Pasa | `ins_ui_test.dart` |
| QA-INS-012/013 | «Guardar y registrar otro» limpia todo el formulario y numera seguido; un doble toque no registra a nadie dos veces | Pasa | `ins_ui_test.dart` |
| QA-INS-014 | dos toques en «Guardar» dentro del MISMO fotograma (un dedo no los da, pero un teclado o un ratón con rebote sí) registran a la persona una sola vez [Defecto QA-BUG-013] | **Falla al activarla** (QA-BUG-013); omitida con `skip` | `ins_ui_test.dart` |
| QA-INS-020 | vincular matrimonio y grupo desde el formulario: la esposa queda en el equipo del esposo y se muestra a qué equipo fue | Pasa | `ins_ui_test.dart` |
| QA-INS-021 | iglesia nueva: se añade al catálogo desde el formulario; repetir una existente da un mensaje en español | Pasa | `ins_ui_test.dart` |
| QA-INS-023 | evento sin equipos ni hospedaje: se inscribe sin pedir ni mostrar nada de eso | Pasa | `ins_ui_test.dart` |
| QA-INS-030/004 | inscripción completa en móvil: errores, éxito, «registrar a otra persona», nombre de 100 letras y lista, sin desbordes | Pasa | `ins_ui_test.dart` |
| QA-INS-040 | 20 inscripciones seguidas por la interfaz: números 1–20 sin saltos, todas con equipo y reparto equilibrado | Pasa | `ins_ui_test.dart` |

### Configuración del evento

| ID | Escenario (pasos y resultado esperado) | Resultado real | Archivo |
|---|---|---|---|
| QA-CFG-001 | crear evento: nombre obligatorio, rango de fechas, criterios de balance confirmables, terminar con lo pendiente y volver a Configuración | Pasa | `cfg_seg_test.dart` |
| QA-CFG-002 | un operador no configura ni inscribe mientras el evento se está configurando | Pasa | `cfg_seg_test.dart` |
| QA-CFG-010 | los topes editados se guardan y no admiten negativos; el evento valida nombre y fechas | Pasa | `cfg_seg_test.dart` |
| QA-CFG-011 | eliminar un evento borra TODO lo suyo y conserva el catálogo de iglesias | Pasa | `cfg_seg_test.dart` |

### Equipos

| ID | Escenario (pasos y resultado esperado) | Resultado real | Archivo |
|---|---|---|---|
| QA-EQP-001 | con 120 inscritos seguidos y 6 equipos se cumplen los topes de tamaño y de hombres–mujeres | Pasa | `eq_data_test.dart` |
| QA-EQP-001b | 120 personas con 2, 3, 4, 6 y 8 equipos y 6 conjuntos de datos distintos: SIEMPRE se cumplen los tres topes | **Falla al activarla** (QA-BUG-001); omitida con `skip` | `eq_data_test.dart` |
| QA-EQP-001c | en 6 combinaciones (2 y 6 equipos, 3 conjuntos de datos) el tamaño nunca pasa de 2; se informan sexo y edad | Pasa | `eq_data_test.dart` |
| QA-EQP-002 | todas las personas quedan con equipo y ninguno queda vacío | Pasa | `eq_data_test.dart` |
| QA-EQP-003 | equipos sin gente al inicio: las 6 primeras personas (sin pareja) caen en 6 equipos distintos | **Falla al activarla** (QA-BUG-002); omitida con `skip` | `eq_data_test.dart` |
| QA-EQP-003b | al inicio el reparto se mantiene dentro del tope de tamaño aunque haya equipos vacíos (24 personas sin pareja) | Pasa | `eq_data_test.dart` |
| QA-EQP-004 | durante la inscripción (desde la nº 12) el tamaño no pasa de 3 de diferencia (2 + un matrimonio) | Pasa | `eq_data_test.dart` |
| QA-EQP-005 | regla del cónyuge: cada matrimonio queda en el MISMO equipo | Pasa | `eq_data_test.dart` |
| QA-EQP-006 | el matrimonio cuya esposa llega 10 inscripciones después también queda junto | Pasa | `eq_data_test.dart` |
| QA-EQP-007.10 | 100 personas en 10 equipos: el tamaño no pasa de 3 (tope 2 más un matrimonio); sexo y edad se informan | Pasa | `eq_data_test.dart` |
| QA-EQP-007.2 | 100 personas en 2 equipos: el tamaño no pasa de 3 (tope 2 más un matrimonio); sexo y edad se informan | Pasa | `eq_data_test.dart` |
| QA-EQP-007.3 | 100 personas en 3 equipos: el tamaño no pasa de 3 (tope 2 más un matrimonio); sexo y edad se informan | Pasa | `eq_data_test.dart` |
| QA-EQP-007.4 | 100 personas en 4 equipos: el tamaño no pasa de 3 (tope 2 más un matrimonio); sexo y edad se informan | Pasa | `eq_data_test.dart` |
| QA-EQP-007.8 | 100 personas en 8 equipos: el tamaño no pasa de 3 (tope 2 más un matrimonio); sexo y edad se informan | Pasa | `eq_data_test.dart` |
| QA-EQP-007b | 100 personas en 4, 8 y 10 equipos: la edad media entre equipos no pasa de 3 años | **Falla al activarla** (QA-BUG-001); omitida con `skip` | `eq_data_test.dart` |
| QA-EQP-008 | el resultado es repetible: mismos datos y mismo orden dan los mismos equipos | Pasa | `eq_data_test.dart` |
| QA-EQP-009 | evento sin equipos, o con equipos aún sin crear: no se asigna nada y no falla | Pasa | `eq_data_test.dart` |
| QA-EQP-010 | con topes más estrictos (tamaño ±1, H–M 2, edad 2) y 120 personas el sistema los cumple | **Falla al activarla** (QA-BUG-001); omitida con `skip` | `eq_data_test.dart` |
| QA-EQP-011 | las personas de un grupo «mantener juntos» se reparten por separado al inscribirse (documentado) | Pasa | `eq_data_test.dart` |
| QA-EQP-020 | cambiar de equipo a una persona actualiza los conteos | Pasa | `eq_data_test.dart` |
| QA-EQP-021 | al pasar de equipo al capitán, su equipo queda sin capitán | Pasa | `eq_data_test.dart` |
| QA-EQP-022 | intercambiar a dos personas de equipos distintos | Pasa | `eq_data_test.dart` |
| QA-EQP-023 | intercambiar en el mismo equipo o con alguien sin equipo da un mensaje en español | Pasa | `eq_data_test.dart` |
| QA-EQP-024 | nombre de equipo repetido y capitán ajeno se rechazan en español | Pasa | `eq_data_test.dart` |
| QA-EQP-025 | borrar un equipo deja sin equipo a su gente | Pasa | `eq_data_test.dart` |
| QA-EQP-026 | el número de equipos a crear debe estar entre 1 y 40 | Pasa | `eq_data_test.dart` |
| QA-EQP-030 | generar para quien no tiene equipo: propuesta que cumple los topes y se aplica | Pasa | `eq_data_test.dart` |
| QA-EQP-031 | la propuesta no cambia nada hasta aceptarla | Pasa | `eq_data_test.dart` |
| QA-EQP-032 | deshacer tras aceptar devuelve a cada persona a su equipo anterior | Pasa | `eq_data_test.dart` |
| QA-EQP-033 | generar para solo los sin equipo respeta a quienes ya tienen equipo | Pasa | `eq_data_test.dart` |
| QA-EQP-034 | «Generar equipos» mantiene juntos a los matrimonios y a los grupos «mantener juntos» | Pasa | `eq_data_test.dart` |
| QA-EQP-035 | sin equipos creados la propuesta avisa en español, no falla | Pasa | `eq_data_test.dart` |
| QA-EQP-036 | un grupo «mantener juntos» muy grande puede romper el tope de tamaño: la propuesta lo avisa | Pasa | `eq_data_test.dart` |
| QA-EQP-050 | «Generar equipos» con 120 personas sin equipo: propuesta equilibrada, Descartar no cambia nada, Aceptar asigna a todos y «Deshacer» lo revierte | Pasa | `hosp_eq_ui_test.dart` |

### Hospedaje

| ID | Escenario (pasos y resultado esperado) | Resultado real | Archivo |
|---|---|---|---|
| QA-HOS-001 | a TODA persona que necesita hospedaje se le asigna uno con la sugerencia | Pasa | `hosp_data_test.dart` |
| QA-HOS-002 | ninguna sobrecapacidad: ocupación ≤ plazas en cada hospedaje | Pasa | `hosp_data_test.dart` |
| QA-HOS-003 | compatibilidad por sexo: los albergues de hombres/mujeres solo tienen a su sexo | Pasa | `hosp_data_test.dart` |
| QA-HOS-004 | matrimonios juntos: cada pareja queda en el mismo hospedaje de matrimonios | Pasa | `hosp_data_test.dart` |
| QA-HOS-005 | con las plazas justas (sin holgura) también se logra, o se informa el déficit | Pasa | `hosp_data_test.dart` |
| QA-HOS-010 | con muy pocas plazas la propuesta informa cuántas faltan y no asigna de más | Pasa | `hosp_data_test.dart` |
| QA-HOS-011 | sin ningún hospedaje compatible la propuesta lo dice en español | Pasa | `hosp_data_test.dart` |
| QA-HOS-012 | sin hospedajes creados no hay propuestas y no falla | Pasa | `hosp_data_test.dart` |
| QA-HOS-020 | forzar a un hombre en un hospedaje de mujeres: avisa de compatibilidad y NO bloquea | Pasa | `hosp_data_test.dart` |
| QA-HOS-021 | pasarse de la capacidad avisa con cifras y deja continuar | Pasa | `hosp_data_test.dart` |
| QA-HOS-022 | un matrimonio separado en hospedaje de matrimonios avisa de la persona sin cónyuge | Pasa | `hosp_data_test.dart` |
| QA-HOS-023 | asignar a un grupo entero (5 personas) a un hospedaje y ver su ocupación | Pasa | `hosp_data_test.dart` |
| QA-HOS-024 | «dejar para después»: quien necesita y no tiene hospedaje queda pendiente y se cuenta en el reporte | Pasa | `hosp_data_test.dart` |
| QA-HOS-025 | borrar un hospedaje deja sin asignar a sus ocupantes y devuelve cuántos | Pasa | `hosp_data_test.dart` |
| QA-HOS-026 | validaciones del hospedaje en español: nombre, capacidad 0/501, repetido | Pasa | `hosp_data_test.dart` |
| QA-HOS-027 | registrar a las parejas UNA POR UNA con la sugerencia del formulario deja a los dos en el mismo hospedaje | **Falla al activarla** (QA-BUG-003); omitida con `skip` | `hosp_data_test.dart` |
| QA-HOS-030 | un PDF válido por cada hospedaje con gente, con y sin teléfono | Pasa | `hosp_data_test.dart` |
| QA-HOS-031 | el PDF de un albergue de 24 personas con nombres con ñ y tildes se genera sin error | Pasa | `hosp_data_test.dart` |
| QA-HOS-040 | al borrar a un asistente se libera su plaza de hospedaje y no cuenta en equipos | Pasa | `hosp_data_test.dart` |
| QA-HOS-041 | al borrar a una persona casada su cónyuge queda sin pareja (según PLAN.md: se limpia pareja, equipo y hospedaje) | **Falla al activarla** (QA-BUG-004); omitida con `skip` | `hosp_data_test.dart` |
| QA-HOS-042 | solo el administrador borra: un operador recibe un mensaje en español | Pasa | `hosp_data_test.dart` |
| QA-HOS-050 | «Sugerir hospedaje» con 120 inscritos: la propuesta cubre a todos, se acepta y nadie queda sin lugar ni sobre la capacidad | Pasa | `hosp_eq_ui_test.dart` |
| QA-HOS-051 | con pocas plazas la pantalla avisa cuántas faltan y «Asignar a quienes caben» deja al resto pendiente | Pasa | `hosp_eq_ui_test.dart` |

### Exportación e importación CSV

| ID | Escenario (pasos y resultado esperado) | Resultado real | Archivo |
|---|---|---|---|
| QA-CSV-001 | el archivo exportado tiene las 17 columnas, BOM, separador «;» y filas CRLF, una por persona | Pasa | `csv_test.dart` |
| QA-CSV-002 | plantilla vacía: solo los títulos, y al leerla no da filas ni errores | Pasa | `csv_test.dart` |
| QA-CSV-003 | archivo vacío o de solo espacios: mensaje en español, sin fallar | Pasa | `csv_test.dart` |
| QA-CSV-004 | el CSV no lleva usuarios, contraseñas ni código de recuperación | Pasa | `csv_test.dart` |
| QA-CSV-010 | exportar 120 personas de A e importarlas a un evento vacío de B (mismos hospedajes y equipos) conserva todo | Pasa | `csv_test.dart` |
| QA-CSV-011 | la segunda exportación (de B) es idéntica a la de A salvo los id | Pasa | `csv_test.dart` |
| QA-CSV-012 | textos difíciles (;  ,  comillas, saltos de línea, tabulador, emoji) sobreviven al viaje de ida y vuelta | Pasa | `csv_test.dart` |
| QA-CSV-013 | una celda que empieza con «=» se exporta tal cual (riesgo conocido de Excel: se evaluaría como fórmula) | **Falla al activarla** (QA-BUG-005); omitida con `skip` | `csv_test.dart` |
| QA-CSV-020 | separador «;», «,» o tabulador dan las mismas filas | Pasa | `csv_test.dart` |
| QA-CSV-021 | UTF-8 con y sin BOM, ANSI (Windows-1252), saltos \n y \r\n se leen igual | Pasa | `csv_test.dart` |
| QA-CSV-022 | columnas en otro orden, con alias (género, notas, cónyuge) y columnas desconocidas | Pasa | `csv_test.dart` |
| QA-CSV-023 | UTF-16 (Excel «Texto Unicode») no se entiende: da un mensaje en español, no un fallo | Pasa | `csv_test.dart` |
| QA-CSV-024 | sexo escrito como H, M, V, F, masculino, femenino, Hombre, Mujer; otro texto se rechaza con su fila | Pasa | `csv_test.dart` |
| QA-CSV-025 | filas con errores variados: cada una con su número de fila y las buenas se importan | Pasa | `csv_test.dart` |
| QA-CSV-030 | importar el mismo archivo dos veces no duplica: la segunda vez actualiza por id | Pasa | `csv_test.dart` |
| QA-CSV-031 | actualizar por id cambia edad, teléfono y observaciones sin tocar equipo, hospedaje ni número | Pasa | `csv_test.dart` |
| QA-CSV-032 | 30 personas nuevas («seguir inscribiendo desde Excel») se suman con números seguidos | Pasa | `csv_test.dart` |
| QA-CSV-033 | las personas que llegan por CSV quedan SIN equipo aunque el evento reparta equipos automáticamente (observación) | **Falla al activarla** (QA-BUG-006); omitida con `skip` | `csv_test.dart` |
| QA-CSV-034 | duplicados: persona ya existente y repetida en el archivo se omiten; con «incluir duplicados» se importan | Pasa | `csv_test.dart` |
| QA-CSV-035 | id o número repetidos en el archivo se rechazan en las filas repetidas | Pasa | `csv_test.dart` |
| QA-CSV-036 | el número del archivo ya ocupado por otra persona: se importa como nueva con otro número | Pasa | `csv_test.dart` |
| QA-CSV-037 | hospedaje o equipo que no existen: avisa fila por fila, importa a la persona sin eso | Pasa | `csv_test.dart` |
| QA-CSV-038 | parejas: bien formadas se vinculan; a un número que no existe o a sí mismo avisan | Pasa | `csv_test.dart` |
| QA-CSV-039 | parejas contradictorias (A→B, B→C): no deja a nadie en un estado roto y avisa | **Falla al activarla** (QA-BUG-007); omitida con `skip` | `csv_test.dart` |
| QA-CSV-040 | grupos: varios por celda con «\|», se crean los que no existen y no se repiten | Pasa | `csv_test.dart` |
| QA-CSV-050 | un archivo de 1000 filas se lee, se revisa e importa; tiempos medidos | Pasa | `csv_test.dart` |
| QA-CSV-060 | al importar a un evento vacío se conservan los números del archivo aunque haya huecos | **Falla al activarla** (QA-BUG-008); omitida con `skip` | `csv_test.dart` |

### Copias .mievento

| ID | Escenario (pasos y resultado esperado) | Resultado real | Archivo |
|---|---|---|---|
| QA-BAK-001 | la copia de 120 personas trae todas las tablas del evento con sus cantidades | Pasa | `bak_test.dart` |
| QA-BAK-002 | la copia no contiene usuarios, contraseñas ni códigos de recuperación | Pasa | `bak_test.dart` |
| QA-BAK-003 | con contraseña: sin ella se pide, con una errónea se rechaza, con la correcta abre; y los nombres no se ven en el archivo | Pasa | `bak_test.dart` |
| QA-BAK-004 | contraseña con tildes, ñ, espacios y emoji funciona | Pasa | `bak_test.dart` |
| QA-BAK-010 | A → B: personas, hospedajes, equipos, parejas, grupos, iglesias y números coinciden | Pasa | `bak_test.dart` |
| QA-BAK-011 | abrir la misma copia dos veces no duplica nada (todo «omitido») | Pasa | `bak_test.dart` |
| QA-BAK-012 | abrir una copia en la misma base de donde salió no cambia nada | Pasa | `bak_test.dart` |
| QA-BAK-013 | el evento queda abierto y utilizable en B: se puede seguir inscribiendo con el equipo y número siguientes | Pasa | `bak_test.dart` |
| QA-BAK-020 | A inscribe nº 121 y B inscribe otro nº 121: al fusionar se renumera uno y no se pierde a nadie | Pasa | `bak_test.dart` |
| QA-BAK-021 | gana la fila más reciente: un cambio nuevo de B llega a A; un cambio viejo de B no pisa uno nuevo de A | Pasa | `bak_test.dart` |
| QA-BAK-022 | el borrado lógico viaja: lo que B borra, A lo ve borrado | Pasa | `bak_test.dart` |
| QA-BAK-023 | la misma iglesia creada en dos dispositivos con ids distintos se une, sin duplicarla | Pasa | `bak_test.dart` |
| QA-BAK-024 | las marcas de comida hechas en B llegan a A tras fusionar, sin duplicarse | Pasa | `bak_test.dart` |
| QA-BAK-025 | las marcas de tiempo se guardan en segundos: dos cambios del mismo segundo en dos dispositivos se resuelven a favor del local (observación) | Pasa | `bak_test.dart` |
| QA-BAK-030 | archivo vacío, texto cualquiera o bytes al azar: mensaje en español | Pasa | `bak_test.dart` |
| QA-BAK-031 | archivo cortado a la mitad: se rechaza, nunca se importa a medias | Pasa | `bak_test.dart` |
| QA-BAK-032 | datos modificados sin actualizar la suma: «dañada o incompleta» | Pasa | `bak_test.dart` |
| QA-BAK-033 | un solo byte cambiado dentro del archivo: se rechaza | Pasa | `bak_test.dart` |
| QA-BAK-034 | formato más nuevo: pide actualizar la app y no importa | Pasa | `bak_test.dart` |
| QA-BAK-035 | un ZIP cualquiera (sin manifest) y un manifest de otra app se rechazan | Pasa | `bak_test.dart` |
| QA-BAK-036 | una copia con una fila corrupta (JSON válido, campo inválido) no deja la base a medias (todo o nada) | Pasa | `bak_test.dart` |
| QA-BAK-040 | cada 20 cambios se guarda sola una copia legible; se conservan solo las últimas 2 (rotación) | Pasa | `bak_test.dart` |

### Escenario Windows → móvil

| ID | Escenario (pasos y resultado esperado) | Resultado real | Archivo |
|---|---|---|---|
| QA-WIN-001 | A (Windows) exporta CSV y .mievento por la interfaz; B (móvil) importa el CSV y, en otra base, abre la copia: todo coincide con A | Pasa | `windows_movil_test.dart` |
| QA-WIN-002 | B (móvil) sigue inscribiendo y marcando comidas, exporta de vuelta y A lo abre: se fusiona sin duplicados | Pasa | `windows_movil_test.dart` |

### Control de comidas

| ID | Escenario (pasos y resultado esperado) | Resultado real | Archivo |
|---|---|---|---|
| QA-COM-001 | tipos y sesiones: Desayuno/Almuerzo/Cena y uno propio; nombre repetido o vacío se rechaza en español | Pasa | `comidas_test.dart` |
| QA-COM-002 | marcar a 100 de 120: contadores (inscritos/pasaron/faltan) y porcentaje exactos | Pasa | `comidas_test.dart` |
| QA-COM-003 | marcar dos veces avisa «ya pasó» y no cuenta doble; «repetir a propósito» deja el registro pero la persona cuenta una vez | Pasa | `comidas_test.dart` |
| QA-COM-004 | deshacer quita a la persona de «pasaron» y se puede volver a marcar | Pasa | `comidas_test.dart` |
| QA-COM-005 | sesión cerrada: no deja marcar (mensaje en español); al reabrir sí; el cierre no borra las marcas | Pasa | `comidas_test.dart` |
| QA-COM-006 | marcar a una persona borrada o inexistente da un mensaje claro | Pasa | `comidas_test.dart` |
| QA-COM-007 | una persona borrada después de pasar no se cuenta en el resumen y el total baja a 119 | Pasa | `comidas_test.dart` |
| QA-COM-008 | buscar por nombre sin tildes, en cualquier orden, por número y por iglesia; sin resultados | Pasa | `comidas_test.dart` |
| QA-COM-009 | «ya pasó» ignorado con «Entendido» se cuenta como repetido evitado | Pasa | `comidas_test.dart` |
| QA-COM-020 | resumen por equipo: la suma de equipos (incluido «Sin equipo») coincide con 120 y con los que pasaron | Pasa | `comidas_test.dart` |
| QA-COM-021 | llegadas cada 15 minutos: sin saltarse tramos vacíos y la suma es la de personas que pasaron | Pasa | `comidas_test.dart` |
| QA-COM-022 | CSV y Excel de 120 personas: Sí/No coinciden con los registros, con BOM y en el orden de llegada | Pasa | `comidas_test.dart` |
| QA-COM-023 | PRIVACIDAD: la imagen para WhatsApp no cambia si cambian todos los nombres (solo lleva cifras), con 120 personas y 6 equipos | Pasa | `comidas_test.dart` |
| QA-COM-030 | PC con 120 personas y 100 ya marcadas: contadores en vivo, marcar por número con Enter y por nombre sin tildes, «ya pasó», deshacer, pendientes, cierre, exportar y reabrir | Pasa | `comidas_ui_test.dart` |
| QA-COM-031 | móvil con 120 personas: se marca por número y por nombre, los contadores caben y no hay desbordes (letra al 130 %) | Pasa | `comidas_ui_test.dart` |

### Seguridad y permisos

| ID | Escenario (pasos y resultado esperado) | Resultado real | Archivo |
|---|---|---|---|
| QA-SEG-001 | el operador no ve Configuración, Copias ni Usuarios, no elimina asistentes ni eventos; el administrador sí | Pasa | `cfg_seg_test.dart` |
| QA-SEG-002 | administrador inicial admin/admin: aviso en el acceso y banner fijo; al cambiar la contraseña desaparece (y una clave floja se rechaza) | Pasa | `cfg_seg_test.dart` |
| QA-SEG-003 | en la pantalla de acceso, tras 5 contraseñas erróneas se bloquea con un mensaje de espera, incluso con la contraseña correcta | Pasa | `cfg_seg_test.dart` |
| QA-SEG-010 | bloqueo progresivo: 30 s, 1 min, 5 min, 15 min y se mantiene en 15 min; un acierto reinicia | Pasa | `cfg_seg_test.dart` |
| QA-SEG-011 | un usuario que no existe recibe el mismo mensaje que una clave errónea (no revela cuentas) | Pasa | `cfg_seg_test.dart` |
| QA-SEG-012 | inicio de sesión con el ejecutor REAL (Isolate): entra, rechaza y cambia la clave | Pasa | `cfg_seg_test.dart` |
| QA-SEG-013 | cambio de contraseña: exige la actual, mínimo 6, distinta del usuario; en español | Pasa | `cfg_seg_test.dart` |
| QA-SEG-014 | código de recuperación: restablece, sirve una sola vez y entrega un código nuevo | Pasa | `cfg_seg_test.dart` |
| QA-SEG-015 | el operador no crea usuarios ni resetea claves; no se deja el sistema sin administrador | Pasa | `cfg_seg_test.dart` |
| QA-SEG-016 | un usuario desactivado no entra | Pasa | `cfg_seg_test.dart` |

### Robustez e interfaz

| ID | Escenario (pasos y resultado esperado) | Resultado real | Archivo |
|---|---|---|---|
| QA-ROB-001 | abrir lista, buscar, exportar/importar CSV, generar equipos, copia .mievento, reportes y alta nº 1001 | Pasa | `robustez_test.dart` |
| QA-ROB-002 | el PDF de reportes con 1000 inscritos se genera (hoy falla desde ~600: «más de 20 páginas») | **Falla al activarla** (QA-BUG-009); omitida con `skip` | `robustez_test.dart` |
| QA-ROB-010 | 1000 inscritos en la lista: se abre, cuenta bien y la búsqueda filtra, sin desbordes | Pasa | `robustez_test.dart` |
| QA-ROB-011 | móvil 400×900 con letra al 100 %: ninguna pantalla se desborda ni queda cargando | Pasa | `robustez_test.dart` |
| QA-ROB-011 | móvil 400×900 con letra al 130 %: ninguna pantalla se desborda ni queda cargando | Pasa | `robustez_test.dart` |
| QA-ROB-011 | móvil 360×640 con letra al 100 %: ninguna pantalla se desborda ni queda cargando [Defecto QA-BUG-010] | **Falla al activarla** (QA-BUG-010); omitida con `skip` | `robustez_test.dart` |
| QA-ROB-011 | móvil 360×640 con letra al 150 %: ninguna pantalla se desborda ni queda cargando [Defecto QA-BUG-010] | **Falla al activarla** (QA-BUG-010); omitida con `skip` | `robustez_test.dart` |
| QA-ROB-012 | ventana de portátil 1366×768 al 125 % (1093×614 lógicos) con 120 personas: ninguna pantalla se desborda ni queda cargando, y todas se alcanzan desde el menú | Pasa | `robustez_test.dart` |
| QA-ROB-012 | ventana de portátil 1366×768 al 150 % (911×512 lógicos) con 120 personas: ninguna pantalla se desborda ni queda cargando, y todas se alcanzan desde el menú [Defecto QA-BUG-011] | **Falla al activarla** (QA-BUG-011); omitida con `skip` | `robustez_test.dart` |
| QA-ROB-013 | datos raros en la base (edad 0, sexo desconocido, nombre vacío, equipo y hospedaje borrados): todas las pantallas responden sin spinner infinito ni errores | Pasa | `robustez_test.dart` |
| QA-ROB-020 | los datos sobreviven a cerrar y volver a abrir la base (archivo real en carpeta temporal) | Pasa | `robustez_test.dart` |

### Reportes

| ID | Escenario (pasos y resultado esperado) | Resultado real | Archivo |
|---|---|---|---|
| QA-REP-001 | las cinco secciones suman 120 y cada cifra coincide con un conteo directo de los datos | Pasa | `reportes_test.dart` |
| QA-REP-002 | el CSV del listado trae las 120 filas, sin teléfono por defecto y con teléfono si se pide | Pasa | `reportes_test.dart` |
| QA-REP-003 | el Excel trae «Resumen» y «Asistentes» con las mismas cifras que las secciones y 120 filas de personas | Pasa | `reportes_test.dart` |
| QA-REP-004 | el PDF de reportes con 120 personas se genera, y con 300 se reparte en más hojas | Pasa | `reportes_test.dart` |
| QA-REP-005 | reportes de un evento sin personas: todo en cero y sin fallar | Pasa | `reportes_test.dart` |

### Datos de prueba entregados

| ID | Escenario (pasos y resultado esperado) | Resultado real | Archivo |
|---|---|---|---|
| QA-DAT-001 | asistentes_120.csv se importa completo a un evento vacío: 120 personas, con equipo, hospedaje, parejas y grupos | Pasa | `datasets_test.dart` |
| QA-DAT-002 | plantilla_vacia.csv: no tiene filas ni errores | Pasa | `datasets_test.dart` |
| QA-DAT-003 | importar_nuevos_30.csv sobre las 120: 30 nuevas, sin errores ni duplicados, números 121–150 | Pasa | `datasets_test.dart` |
| QA-DAT-004 | importar_con_errores.csv sobre las 120: 8 nuevas, 2 duplicados omitidos y 11 filas con error, cada una con su motivo | Pasa | `datasets_test.dart` |
| QA-DAT-005 | importar_ansi.csv (Windows-1252) se lee con tildes y ñ y se importa: 8 personas | Pasa | `datasets_test.dart` |
| QA-DAT-006 | los dos .mievento se abren en una base vacía (el segundo con contraseña) y traen lo mismo | Pasa | `datasets_test.dart` |
### Núcleo (texto, duplicados, rangos)

| ID | Escenario (pasos y resultado esperado) | Resultado real | Archivo |
|---|---|---|---|
| QA-TXT-001 | tildes, diéresis y ñ se igualan, también en mayúsculas | Pasa | `texto_qa_test.dart` |
| QA-TXT-002 | espacios, tabuladores y saltos de línea se colapsan; vacío y solo espacios dan vacío | Pasa | `texto_qa_test.dart` |
| QA-TXT-003 | el apóstrofe separa palabras: «O'Farrill» y «O Farrill» son lo mismo para duplicados | Pasa | `texto_qa_test.dart` |
| QA-TXT-004 | José Núñez, JOSE NUNEZ y jose núñez dan la misma clave de duplicado | Pasa | `texto_qa_test.dart` |
| QA-TXT-005 | quien escribe «OFarrill» sin apóstrofe encuentra «O'Farrill» | **Falla al activarla** (QA-BUG-012); omitida con `skip` | `texto_qa_test.dart` |
| QA-TXT-006 | letras fuera de la tabla de tildes (ã, ç, ø, ß, ł) se tratan como su letra base | **Falla al activarla** (QA-BUG-012); omitida con `skip` | `texto_qa_test.dart` |
| QA-TXT-010 | 1000 identificadores nuevos son UUID v7 válidos y no se repiten | Pasa | `texto_qa_test.dart` |
| QA-TXT-011 | los rangos de edad por defecto cubren de 12 en adelante; menores de 12 caen fuera (aparecen como «Sin rango») | Pasa | `texto_qa_test.dart` |
| QA-TXT-012 | rangos solapados o invertidos se rechazan con mensaje en español | Pasa | `texto_qa_test.dart` |

---

## 8. Riesgos y límites honestos

**Qué NO se pudo probar (y por tanto no se afirma):**

- **Dispositivos reales.** Todo corrió en el motor de pruebas de Flutter con base en memoria. No se probó en un teléfono Android ni en una PC con Windows reales (instalación, ventana, gestos táctiles, teclado virtual, rotación).
- **Compartir en Android y «Guardar como» de Windows**: se sustituyeron por `MemoryFileSaver`/`MemoryFilePick`. El comportamiento real de `share_plus` y `file_selector` no se probó.
- **Impresora real.** Los PDF se generaron y se validó su cabecera (`%PDF-`) y su número de páginas; **no se abrieron en un visor, no se imprimieron y no se revisó su aspecto**.
- **Excel real.** Los CSV se leyeron con el lector de la app y con Python (`csv`, delimitador `;`, `utf-8-sig`); los `.xlsx` se abrieron como ZIP/XML. No se abrieron en Microsoft Excel ni en LibreOffice.
- **Cifrado del `.mievento`**: se comprobó con la propia librería (contraseña correcta/errónea, el texto no aparece en claro); no se abrió con 7-Zip.
- **Rendimiento de gama baja.** Los tiempos son del entorno de pruebas; en un teléfono modesto serán mayores (se desconoce cuánto).
- **Fuentes.** En las pruebas las fuentes no están cargadas (ancho «Ahem»): los desbordes de texto aparecen antes que en un dispositivo real. Los de QA-BUG-010/011 deben confirmarse en un dispositivo.
- **Dos dispositivos «reales».** Se simularon con dos bases en el mismo proceso; no hubo red, ni dos aparatos, ni reloj distinto entre ellos. Si el reloj de un dispositivo está mal puesto, la regla «gana lo más reciente» podría elegir mal; no se probó.
- **Cortes bruscos** (apagar el equipo con la app abierta): solo se probó cerrar y reabrir la base (QA-ROB-020); no se forzó una interrupción en plena escritura.
- **Concurrencia**: nunca dos operadores a la vez (el diseño es un operador por turno).
- **Accesibilidad** (lector de pantalla, contraste), **idiomas/teclados** distintos del español, **zonas horarias** (las horas de comida se guardan en UTC; las llegadas cada 15 minutos se probaron con horas sintéticas).
- **Migraciones desde versiones anteriores de la base**: existen pruebas del proyecto, no se ampliaron.
- La **protección de la base** (no está cifrada, aviso ya conocido en PLAN.md) no se probó: es una limitación de diseño.

**Limitaciones de las propias pruebas:**

- Los datos son ficticios y generados; la distribución real de edades/sexos de un evento podría dar resultados de balance distintos (la matriz de QA-BUG-001 muestra que el resultado depende mucho de los datos).
- El repositorio avanzó durante el trabajo (commits `9210081` y `cfa2269`, que tocan `main.dart`, `attendee_form.dart` y `social_section.dart`). Las pruebas se ejecutaron completas contra `cfa2269` y los defectos de interfaz se volvieron a comprobar en esa versión; los de datos no dependen de esos archivos.
- Las pruebas de interfaz usan esperas cortas simuladas; los tiempos de interfaz no son tiempos de usuario.
- El «doble toque» se probó de forma realista (un fotograma entre toques); con un dedo real la secuencia puede ser distinta.

**Riesgos para el evento (de más a menos):**

1. Balance de equipos no garantizado con el equipo automático (BUG-001) → la gente verá avisos o equipos desiguales si no se usa «Generar equipos» al final.
2. No poder sacar el PDF de reportes con muchas personas (BUG-009).
3. Matrimonios separados en hospedaje si se inscriben por separado (BUG-003) y personas importadas sin equipo (BUG-006).
4. Pantallas pequeñas / letra grande / ventanas bajas (BUG-010/011): posible dificultad de uso a voluntarios mayores.
5. Datos que se corrompen en silencio por falta de limpieza al borrar (BUG-004) y números de inscripción que cambian al importar CSV (BUG-008).

---

## 9. Recomendaciones

1. **Corregir primero BUG-001 y BUG-009** (alta). Para BUG-001, reutilizar la puntuación de `generateTeams` dentro de `suggestTeam`; añadir un botón «Equilibrar ahora» que ofrezca reorganizar cuando haya avisos.
2. **Mientras tanto, procedimiento para el evento**: al terminar de inscribir, abrir «Equipos → Generar equipos → reorganizar a todos» y revisar el aviso; exportar reportes en Excel/CSV si hay más de 500 personas.
3. **Matrimonios**: inscribir a los dos juntos con «Inscribir al cónyuge desde la ficha»; si se inscriben separados, «Dejar para después» el hospedaje y usar «Sugerir hospedaje» con los dos.
4. **Reactivar las pruebas omitidas** a medida que se corrijan: buscar `skip:` en `apps/mi_evento/test/qa/` (y `packages/mi_evento_core/test/qa/texto_qa_test.dart`) y quitar el argumento; en las de interfaz la etiqueta `[Defecto QA-BUG-0nn]` está en el nombre.
5. **Probar en dispositivos reales** antes del evento: un teléfono Android modesto (compartir, letra grande, 360 px), una PC Windows con la pantalla del evento (ventana baja), una impresora y Excel de verdad, con los archivos de `qa-datasets/`.
6. **Dejar `test/qa` en el CI** (≈ 2 minutos). Si se quiere acortar, las pruebas de interfaz largas (`ins_ui_test`, `robustez_test`) pueden pasar a una ejecución nocturna.
7. **Plantillas de uso**: en el CSV de Excel advertir de la fórmula (`=`) y guardar con «CSV UTF-8»; y avisar que hospedajes y equipos deben existir con el mismo nombre.
8. **Mejoras de poca complejidad**: cerrojo en `_save` (BUG-013), `normalizeText` más completo (BUG-012), menú lateral desplazable (BUG-011), rango «0–11» o «Sin rango» explícito en reportes.

---

## 10. Cómo ejecutar y archivos entregados

```
export PATH=/opt/sdk/flutter/bin:$PATH CI=true
cd apps/mi_evento && timeout 580 flutter test test/qa          # ≈ 2 min (170 pruebas)
cd packages/mi_evento_core && dart test test/qa                # núcleo (9 pruebas)
cd apps/mi_evento && timeout 580 flutter test qa/generate_qa_dataset_test.dart   # regenera qa-datasets/ (manual, no corre en el CI)
```

| Archivo | Contenido |
|---|---|
| `apps/mi_evento/test/qa/qa_support.dart`, `qa_ui_support.dart` | Utilidades: personas ficticias con semilla, imitación del guardado del formulario, hospedajes realistas, arranque de «dispositivos». |
| `ins_ui_test.dart` | Inscripción por la interfaz (PC, móvil, ráfaga). |
| `cfg_seg_test.dart` | Configuración en dos momentos, seguridad y permisos. |
| `eq_data_test.dart`, `hosp_data_test.dart` | Equipos y hospedaje con 120 personas. |
| `hosp_eq_ui_test.dart` | Pantallas «Sugerir hospedaje» y «Generar equipos» con 120 personas. |
| `csv_test.dart`, `bak_test.dart`, `reportes_test.dart` | CSV, copias `.mievento`, reportes. |
| `windows_movil_test.dart` | Escenario Windows → móvil. |
| `comidas_test.dart`, `comidas_ui_test.dart` | Control de comidas. |
| `robustez_test.dart` | Rendimiento (1000), letra grande, ventana baja, datos raros, persistencia. |
| `datasets_test.dart` | Comprueba que los archivos de `qa-datasets/` se pueden importar. |
| `packages/mi_evento_core/test/qa/texto_qa_test.dart` | Núcleo: texto, duplicados, rangos. |
| `apps/mi_evento/qa/generate_qa_dataset_test.dart` | Generador manual de datos. |
| `qa-datasets/` | `asistentes_120.csv`, `plantilla_vacia.csv`, `importar_nuevos_30.csv`, `importar_con_errores.csv`, `importar_ansi.csv`, `evento_qa.mievento`, `evento_qa_con_clave.mievento` (contraseña `qa-clave-larga-2026`) y `LEEME.md`. |
