# Informe de QA — Mi Evento en Windows (simulado)

Estado: COMPLETO · inicio 2026-11-24T09:36:14.536094 · duración 6 min

## Pasos

| Paso | Resultado | Evidencia |
|---|---|---|
| 0 · Arranque y entrada a la app a 1366x768 (100 %) | Pasa | 2 comprobaciones OK |
| 1 · Crear evento por la UI y configurar hospedajes (22) y equipos (8) | Pasa | 8 comprobaciones OK |
| 2a · Formulario «Registrar»: etiquetas, sexo M/F, obligatorios, Tab | Pasa | 14 comprobaciones OK |
| 2b · Registrar 42+ personas a mano (iglesia nueva provincia→municipio→comunidad, matrimonios, preinscritos, hospedaje) | Pasa | 14 comprobaciones OK |
| 2c · Duplicado: aviso al escribir, diálogo al guardar (cancelar / guardar igual) y pantalla de éxito | Pasa | 5 comprobaciones OK |
| 3a · Importar CSV A (confirmados): ;, UTF-8 con BOM, matrimonios por pareja_numero, filas malas y duplicado | Pasa | 7 comprobaciones OK |
| 3b · Importar CSV B «como preinscripción» (, sin BOM, Windows-1252, columnas en otro orden, hospedaje del archivo ignorado) | Pasa | 7 comprobaciones OK |
| 3c · Totales tras el registro | Pasa | 4 comprobaciones OK |
| 4 · Confirmar asistencia por la UI: una a una + «Deshacer», subconjunto, búsqueda y «a los que se ven» | Pasa | 11 comprobaciones OK |
| 5a · Duplicar evento (todo) por «Mis eventos» → menú → Duplicar evento… | Pasa | 11 comprobaciones OK |
| 5b · Duplicar evento solo estructura (sin participantes) | Pasa | 3 comprobaciones OK |
| 5c · Pasar participantes a otro evento…: omite repetidos | Pasa | 4 comprobaciones OK |
| 6 · Reportes y comidas cuentan SOLO confirmados; aviso al marcar a un preinscrito; filtro «Preinscritos» | Pasa | 6 comprobaciones OK |
| 7.1 · Comidas · sesión «Almuerzo viernes» (Almuerzo): marcas por la UI, resto por repositorio, cierre y exportaciones | Pasa | 16 comprobaciones OK |
| 7.2 · Comidas · sesión «Cena viernes» (Cena): marcas por la UI, resto por repositorio, cierre y exportaciones | Pasa | 10 comprobaciones OK |
| 7.3 · Comidas · sesión «Almuerzo sábado» (Almuerzo): marcas por la UI, resto por repositorio, cierre y exportaciones | Pasa | 10 comprobaciones OK |
| 7.4 · Comidas · sesión «Cena sábado» (Cena): marcas por la UI, resto por repositorio, cierre y exportaciones | Pasa | 10 comprobaciones OK |
| 7.5 · Comidas · sesión «Almuerzo domingo» (Almuerzo): marcas por la UI, resto por repositorio, cierre y exportaciones | Pasa | 10 comprobaciones OK |
| 7.6 · Comidas · sesión «Cena domingo» (Cena): marcas por la UI, resto por repositorio, cierre y exportaciones | Pasa | 10 comprobaciones OK |
| 7.7 · Comidas · totales | Pasa | 3 comprobaciones OK |
| 8a · Confirmar a todos (los preinscritos que quedaban) por la UI | Pasa | 3 comprobaciones OK |
| 8b · Hospedaje: «Sugerir hospedaje» → aceptar (varias rondas) hasta ubicar a todos | Pasa | 0 comprobaciones OK |
| 8b2 · Hospedaje: comprobar la propuesta aceptada y, si hay sobrecupo, reubicar a mano por la ficha (buscador y filtros) | Falla | FALLA: la propuesta aceptada no excede la capacidad de ningún hospedaje (1 con sobrecupo) |
| 8c · Hospedaje: asignación manual con buscador y filtros del formulario (reasignar solteros) y de quienes queden | Pasa | 2 comprobaciones OK |
| 8d · Hospedaje: pendientes finales por «Asignar personas» del hospedaje (buscador, filtro y grupo) y verificación | Pasa | 5 comprobaciones OK |
| 9a · Asistentes: búsqueda, filtros (sexo/iglesia/hospedaje/equipo/asistencia), tabla ordenable y CSV | Pasa | 13 comprobaciones OK |
| 9b · Hospedajes: búsqueda, filtro «Acepta», plazas libres, tabla ordenable y CSV | Pasa | 6 comprobaciones OK |
| 9c · Equipos: búsqueda y CSV (con «Sin equipo») | Pasa | 3 comprobaciones OK |
| 9d · Mis eventos: búsqueda, tabla ordenable y CSV | Pasa | 5 comprobaciones OK |
| 10a · Exportaciones de «Copias de seguridad»: plantilla, CSV de asistentes y respaldo CSV del evento | Pasa | 2 comprobaciones OK |
| 10b · Reportes finales (todos confirmados): xlsx, csv (con y sin teléfono) y pdf | Pasa | 7 comprobaciones OK |
| 10c · CSV de asistentes y respaldo de CADA evento | Pasa | 4 comprobaciones OK |
| 11 · Ida y vuelta del respaldo CSV: reabrir en una base vacía y comparar | Pasa | 8 comprobaciones OK |
| 12 · Pasada a 1920x1080 por todas las pantallas | Pasa | 16 comprobaciones OK |
| 13 · Cifras finales | Pasa | 0 comprobaciones OK |

## Detalle por paso

### 0 · Arranque y entrada a la app a 1366x768 (100 %) — PASA (0s)

- OK: tras entrar como admin se ve «Mis eventos» con «Crear evento»
- OK: ventana de 1366x768 a dpr 1

### 1 · Crear evento por la UI y configurar hospedajes (22) y equipos (8) — PASA (22s)

- OK: el calendario de rango (1366x768) deja fechas «inicio → fin»
- OK: al crear se abre la pantalla de configuración del evento
- OK: mientras se configura no hay menú «Registrar»
- OK: estado de hospedajes: «22 hospedajes · 312 plazas» (esperado 22 y 312 plazas)
- Mezcla de hospedajes creados por la UI: {Solo hombres: 5, Solo mujeres: 5, Matrimonios: 6, Sin preferencia: 6}
- OK: estado de equipos: «8 equipos»
- OK: terminar la configuración abre el panel del evento
- OK: en la base hay 22 hospedajes
- OK: en la base hay 8 equipos

### 2a · Formulario «Registrar»: etiquetas, sexo M/F, obligatorios, Tab — PASA (1s)

- OK: campo obligatorio marcado con * : «Nombre *»
- OK: campo obligatorio marcado con * : «Primer apellido *»
- OK: campo obligatorio marcado con * : «Sexo *»
- OK: campo obligatorio marcado con * : «Edad *»
- OK: campo obligatorio marcado con * : «Iglesia *»
- OK: segundo apellido dice (opcional)
- OK: teléfono dice (opcional)
- OK: la lista de sexo ofrece «M (Hombre)» y «F (Mujer)»
- OK: guardar vacío avisa «Falta el nombre»
- OK: Tab: nombre → primer apellido
- OK: Tab: primer apellido → segundo apellido
- OK: Tab: (sexo) → edad
- OK: Tab: edad → teléfono
- OK: Tab: teléfono → iglesia

### 2b · Registrar 42+ personas a mano (iglesia nueva provincia→municipio→comunidad, matrimonios, preinscritos, hospedaje) — PASA (55s)

- OK: provincia/municipio (Matanzas/Perico) vienen de la iglesia elegida
- OK: provincia y municipio no son campos editables
- OK: comunidad nueva «Varadero» avisa que se añadirá al guardar
- OK: comunidad nueva «Centro Urbano» avisa que se añadirá al guardar
- OK: la comunidad «Varadero» se sugiere al escribir «Var» (municipio Cárdenas)
- OK: comunidad nueva «Miramar» avisa que se añadirá al guardar
- Los filtros de la lista de hospedajes del formulario («Con plazas libres», «Solo los que aceptan…») y el buscador siguen activos al pulsar «Guardar y registrar otro» (el formulario se limpia, ellos no).
- OK: comunidad nueva «Casa Blanca» avisa que se añadirá al guardar
- OK: tras el formulario hay 42 personas (esperado 42)
- OK: preinscritos por formulario: 21 (esperado 21)
- OK: los matrimonios tienen el mismo estado (preinscrito/confirmado) en ambos cónyuges; parejas: 4
- OK: todas las personas del formulario tienen equipo automático
- Hospedaje aceptado/elegido en el formulario: 14 personas: #1 F → Casa Hno. Elier Piñeiro; #2 M → Casa Hno. Elier Piñeiro; #3 M → Casa Hno. Elier Piñeiro; #4 M → Casa Hno. Elier Piñeiro; #5 M → Casa Hno. Elier Piñeiro; #6 F → Casa Hno. Elier Piñeiro; #7 M → Casa Hno. Julián Báez; #8 M → Casa Hno. Julián Báez; #9 F → Casa Hna. Carmen Soto; #10 F → Casa Hna. Carmen Soto; #11 M → Casa Hna. Rosa Leyva; #12 F → Casa Hna. Carmen Soto; #13 M → Casa Hna. Rosa Leyva; #14 F → Casa Hna. Carmen Soto
- OK: hay nombres con tildes/ñ (41 personas)
- Iglesias creadas por la UI: 7; comunidades: {Varadero, Centro Urbano, Miramar, Casa Blanca}
- OK: catálogo de iglesias = 7 (esperado 7)
- OK: la comunidad «Varadero» quedó guardada en las iglesias de Cárdenas (2)

### 2c · Duplicado: aviso al escribir, diálogo al guardar (cancelar / guardar igual) y pantalla de éxito — PASA (2s)

- OK: aviso de duplicado al escribir mismo nombre y primer apellido (mayúsculas/sin tildes)
- OK: al guardar con mismo nombre y apellidos sale el diálogo «¿Ya está registrado?»
- OK: cancelar el diálogo no guarda nada
- Segundo intento de guardar: diálogo de duplicado visible=true
- OK: «Es otra persona, guardar» la guarda (homónimo, edad 24)
- OK: pantalla de éxito con el número de inscripción

### 3a · Importar CSV A (confirmados): ;, UTF-8 con BOM, matrimonios por pareja_numero, filas malas y duplicado — PASA (2s)

- OK: csv-A-confirmados: vista previa antes de importar
- csv-A-confirmados · vista previa: «63 personas nuevas · 0 se actualizan · 1 posibles duplicados · 2 filas con errores»
- csv-A-confirmados · avisos/errores mostrados: Las personas nuevas quedan preinscritas y su asistencia se confirma el día del evento. Se ignoran el hospedaje y el equipo del archivo. | Fila 65: falta el nombre. | Fila 66: el sexo «Otro» no se entiende (usa Hombre o Mujer).
- csv-A-confirmados · con «incluir duplicados»: «64 personas nuevas · 0 se actualizan · 2 filas con errores»
- OK: csv-A-confirmados: pantalla de resultado
- csv-A-confirmados · resultado: Nuevas personas: 63 | Personas actualizadas: 0 | Omitidas por posible duplicado: 1 | Iglesias nuevas en el catálogo: 2 | Con equipo asignado automáticamente: 63 | Grupos nuevos: 4
- OK: CSV A: nuevas personas 63 (esperado 63); malas: 2; duplicado omitido: 1
- OK: las personas del CSV A quedan CONFIRMADAS (63/63)
- Fila con sexo «M» y nombre «Mario»: se importó como sexo=F (en el formulario «M» = Hombre).
- OK: matrimonios vinculados: 16 (esperado 16)
- Grupos en el evento tras el CSV A: [Misioneros de Jovellanos, Familia Núñez, Coro de Colón, Jóvenes Ebenezer]
- OK: el CSV creó iglesias nuevas en el catálogo (total 9)
- OK: personas sin equipo tras importar: 0

### 3b · Importar CSV B «como preinscripción» (, sin BOM, Windows-1252, columnas en otro orden, hospedaje del archivo ignorado) — PASA (1s)

- OK: csv-B-preinscripcion: vista previa antes de importar
- csv-B-preinscripcion · vista previa: «110 personas nuevas · 0 se actualizan»
- csv-B-preinscripcion · avisos/errores mostrados: Las personas nuevas quedan preinscritas y su asistencia se confirma el día del evento. Se ignoran el hospedaje y el equipo del archivo.
- OK: csv-B-preinscripcion: pantalla de resultado
- csv-B-preinscripcion · resultado: Nuevas personas: 110 | Personas actualizadas: 0 | Con equipo asignado automáticamente: 110
- OK: CSV B: nuevas personas 110 (esperado 110)
- OK: todas entran PREINSCRITAS (110/110)
- OK: el hospedaje escrito en el archivo se ignora en la preinscripción
- OK: iglesias en catálogo: 9 (esperado 9: las escritas en minúsculas/con espacios no se duplican)
- OK: tildes/ñ en Windows-1252 se leyeron bien (ejemplo: Sandro)

### 3c · Totales tras el registro — PASA (0s)

- OK: personas registradas: 216 (objetivo ≥ 200)
- OK: preinscritas: 131 (objetivo ≥ 100)
- Por vía: formulario 43 (preinscritos 21, confirmados 22) · CSV A 63 confirmados · CSV B 110 preinscritos.
- OK: números de inscripción únicos
- OK: sin duplicados nombre+apellido+edad (0)
- Personas por provincia/municipio: {Matanzas/Perico: 24, Matanzas/Cárdenas: 56, Matanzas/Colón: 30, La Habana/Playa: 24, Matanzas/Jovellanos: 26, Mayabeque/San José de las Lajas: 16, Villa Clara/Santa Clara: 20, Cienfuegos/Cienfuegos: 20}

### 4 · Confirmar asistencia por la UI: una a una + «Deshacer», subconjunto, búsqueda y «a los que se ven» — PASA (13s)

- OK: contador «131 por confirmar · 85 ya confirmados» coincide con la base (131 por confirmar)
- OK: confirmar a la nº 216: queda «130 por confirmar · 86 ya confirmados»
- OK: «Deshacer» la devuelve a preinscrita: «131 por confirmar · 85 ya confirmados»
- OK: se vuelve a confirmar a la nº 216
- OK: botón «Confirmar seleccionados (4)»
- OK: tras confirmar el subconjunto: «126 por confirmar · 90 ya confirmados»
- OK: búsqueda sin tilde «nunez»: «126 por confirmar · 90 ya confirmados · 16 coinciden»
- OK: búsqueda sin resultado muestra «Ningún preinscrito coincide»
- OK: diálogo de confirmación masiva con la cantidad
- Quedan 13 preinscritos sin confirmar a propósito (iglesia «Bautista Nuevo Pacto»), para comprobar que reportes y comidas cuentan SOLO confirmados; se confirman con «Confirmar a todos» en el paso 8.
- OK: quedan 13 preinscritos pendientes
- OK: contador de la pantalla = 13

### 5a · Duplicar evento (todo) por «Mis eventos» → menú → Duplicar evento… — PASA (1s)

- A 1366x768 el menú lateral no cabe: «Mis eventos» exige desplazar el menú (no es defecto: el menú se desplaza).
- OK: la copia tiene 216 participantes (original 216)
- OK: todos los de la copia están PREINSCRITOS
- OK: ids de participantes distintos a los del original
- OK: números de inscripción conservados
- OK: equipos copiados (8) con ids distintos
- OK: cada participante de la copia apunta a un equipo de la copia
- OK: hospedajes copiados (22) con ids distintos
- OK: cada hospedaje asignado en la copia es de la copia
- OK: cada persona conserva su hospedaje (por nombre) en la copia
- OK: parejas copiadas: 22 (original 22), con ids de la copia
- OK: grupos copiados: 4 (original 4) con ids distintos
- Tipos de control en la copia: []

### 5b · Duplicar evento solo estructura (sin participantes) — PASA (1s)

- OK: la copia solo-estructura no tiene participantes
- OK: equipos copiados: 8
- OK: hospedajes copiados: 22

### 5c · Pasar participantes a otro evento…: omite repetidos — PASA (5s)

- Pasar original → copia completa (ya tiene a todos): «0 personas pasadas · 216 ya estaban.»
- OK: no se duplica a nadie en la copia completa (216 → 216)
- Pasar original → copia solo-estructura (vacía): «216 personas pasadas.»
- OK: a la copia vacía pasan todos: 216 de 216
- OK: pasados como preinscritos
- Repetir el pase → copia ya llena: «0 personas pasadas · 216 ya estaban.»
- OK: repetir el pase omite repetidos (sigue en 216)

### 6 · Reportes y comidas cuentan SOLO confirmados; aviso al marcar a un preinscrito; filtro «Preinscritos» — PASA (9s)

- OK: Reportes dice «203 inscritos» (confirmados 203 de 216)
- Archivos de reportes (con 203 confirmados y 13 preinscritos): [01-reportes-con-pendientes--asistentes-congreso-nacional-qa-2026.csv, 02-reportes-con-pendientes--reportes-congreso-nacional-qa-2026.xlsx, 03-reportes-con-pendientes--reportes-congreso-nacional-qa-2026.pdf]
- OK: el CSV de reportes lista 203 filas = confirmados (203)
- OK: Comidas: «Inscritos» = 203 (confirmados 203)
- Buscar en Comidas a la preinscrita nº 110: aparece en resultados=false, mensaje «Nadie con ese nombre»=true, aviso «confirma primero»=false
- OK: MealRepo.mark rechaza al preinscrito: «Esa persona está preinscrita: confirma primero su asistencia.»
- OK: filtro Asistencia=Preinscritos: «13 de 216» (esperado 13)
- OK: CSV exportado respeta el filtro: 13 filas

### 7.1 · Comidas · sesión «Almuerzo viernes» (Almuerzo): marcas por la UI, resto por repositorio, cierre y exportaciones — PASA (29s)

- OK: contador Inscritos 203 = confirmados 203
- OK: contador «Pasaron» = 70 tras 70 marcas por la UI
- OK: Deshacer última marca: Pasaron 69
- OK: marcar a quien ya pasó muestra «YA PASÓ POR ESTA SESIÓN»
- OK: «Marcar otra vez» no suma a Pasaron (70)
- OK: lista «Faltan (…)»: Faltan (133)
- OK: tras el resto por repositorio Pasaron=193 = 193 en BD
- OK: resumen: Inscritos 203
- OK: resumen: Pasaron 193 (BD 193)
- OK: resumen: No pasaron 10
- OK: exportó csv, xlsx y png (3 archivos)
- OK: CSV de comidas: filas «Sí» 193 = 193
- OK: XLSX válido (15041 B)
- OK: PNG válido (14506 B)
- OK: reabrir la sesión permite marcar otra vez
- OK: tras reabrir y marcar a la nº 207: 194 marcas

### 7.2 · Comidas · sesión «Cena viernes» (Cena): marcas por la UI, resto por repositorio, cierre y exportaciones — PASA (17s)

- OK: contador Inscritos 203 = confirmados 203
- OK: contador «Pasaron» = 45 tras 45 marcas por la UI
- OK: tras el resto por repositorio Pasaron=183 = 183 en BD
- OK: resumen: Inscritos 203
- OK: resumen: Pasaron 183 (BD 183)
- OK: resumen: No pasaron 20
- OK: exportó csv, xlsx y png (3 archivos)
- OK: CSV de comidas: filas «Sí» 183 = 183
- OK: XLSX válido (15038 B)
- OK: PNG válido (14472 B)

### 7.3 · Comidas · sesión «Almuerzo sábado» (Almuerzo): marcas por la UI, resto por repositorio, cierre y exportaciones — PASA (14s)

- OK: contador Inscritos 203 = confirmados 203
- OK: contador «Pasaron» = 35 tras 35 marcas por la UI
- OK: tras el resto por repositorio Pasaron=187 = 187 en BD
- OK: resumen: Inscritos 203
- OK: resumen: Pasaron 187 (BD 187)
- OK: resumen: No pasaron 16
- OK: exportó csv, xlsx y png (3 archivos)
- OK: CSV de comidas: filas «Sí» 187 = 187
- OK: XLSX válido (15106 B)
- OK: PNG válido (14462 B)

### 7.4 · Comidas · sesión «Cena sábado» (Cena): marcas por la UI, resto por repositorio, cierre y exportaciones — PASA (14s)

- OK: contador Inscritos 203 = confirmados 203
- OK: contador «Pasaron» = 30 tras 30 marcas por la UI
- OK: tras el resto por repositorio Pasaron=173 = 173 en BD
- OK: resumen: Inscritos 203
- OK: resumen: Pasaron 173 (BD 173)
- OK: resumen: No pasaron 30
- OK: exportó csv, xlsx y png (3 archivos)
- OK: CSV de comidas: filas «Sí» 173 = 173
- OK: XLSX válido (15014 B)
- OK: PNG válido (14491 B)

### 7.5 · Comidas · sesión «Almuerzo domingo» (Almuerzo): marcas por la UI, resto por repositorio, cierre y exportaciones — PASA (12s)

- OK: contador Inscritos 203 = confirmados 203
- OK: contador «Pasaron» = 20 tras 20 marcas por la UI
- OK: tras el resto por repositorio Pasaron=189 = 189 en BD
- OK: resumen: Inscritos 203
- OK: resumen: Pasaron 189 (BD 189)
- OK: resumen: No pasaron 14
- OK: exportó csv, xlsx y png (3 archivos)
- OK: CSV de comidas: filas «Sí» 189 = 189
- OK: XLSX válido (15111 B)
- OK: PNG válido (14473 B)

### 7.6 · Comidas · sesión «Cena domingo» (Cena): marcas por la UI, resto por repositorio, cierre y exportaciones — PASA (12s)

- OK: contador Inscritos 203 = confirmados 203
- OK: contador «Pasaron» = 20 tras 20 marcas por la UI
- OK: tras el resto por repositorio Pasaron=179 = 179 en BD
- OK: resumen: Inscritos 203
- OK: resumen: Pasaron 179 (BD 179)
- OK: resumen: No pasaron 24
- OK: exportó csv, xlsx y png (3 archivos)
- OK: CSV de comidas: filas «Sí» 179 = 179
- OK: XLSX válido (14988 B)
- OK: PNG válido (14451 B)

### 7.7 · Comidas · totales — PASA (0s)

- OK: 6 sesiones del plan (3 almuerzos + 3 cenas): 6 (más 1 de verificación del paso 6)
- OK: las 6 sesiones del plan quedan cerradas
- Marcas por la UI: 220 · por repositorio: 884 · activas en total: 1106
- OK: ningún preinscrito tiene marcas de comida

### 8a · Confirmar a todos (los preinscritos que quedaban) por la UI — PASA (1s)

- OK: diálogo «Confirmar a todos» con la cantidad
- OK: tras «Confirmar a todos» (eran 13) quedan 0 preinscritos
- OK: la pantalla dice que no hay preinscritos por confirmar

### 8b · Hospedaje: «Sugerir hospedaje» → aceptar (varias rondas) hasta ubicar a todos — PASA (2s)

- Ronda 1: pendientes de hospedaje 202
- Propuesta en pantalla: «Posada Betel» aparece en 3 textos de tramos; avisos visibles antes de aceptar: NINGUNO
- Tramos de la propuesta (nombre / personas / ocupación): [Posada Betel, 20 personas: Dayanis Hernández, Sandro Hernández, Dayanis Piñeiro, Yos…, Ocupación: 0 → 20 de 20 plazas, Casa Pastoral, 12 personas: Inés Hernández, Iván Hernández, Inés Núñez, Iván Núñez, J…, Ocupación: 0 → 12 de 12 plazas, Casa Familia Gómez, 10 personas: Mario Valdés, María Valdés, Osvaldo Sánchez, Yaneisy Sánc…, Ocupación: 0 → 10 de 10 plazas, Casa Familia Ortiz, 2 personas: Yaneisy Álvarez, Yosvany Álvarez, Ocupación: 0 → 2 de 10 plazas, Albergue Central Hombres, 30 personas: Abel Cabrera, Abel Núñez, Abel Ochoa, Abel Valdés, Andrés…, Ocupación: 0 → 30 de 30 plazas, Albergue Escuela Hombres, 25 personas: Joaquín Acosta, Joaquín Báez, Joaquín Hernández, Joaquín …, Ocupación: 0 → 25 de 25 plazas, Posada Betel, 20 personas: Raúl Valdés, Rubén Báez, Rubén Domínguez, Rubén O'Farrill…, Ocupación: 0 → 20 de 20 plazas, Casa Hno. Osvaldo Díaz, 10 personas: Yosvany Fernández, Yosvany García, Yosvany Leyva, Yosvany…, Ocupación: 0 → 10 de 15 plazas, Albergue Juvenil Mujeres, 30 personas: Ana Lucía Pedroso, Ana Lucía Álvarez, Beatriz Echevarría,…, Ocupación: 0 → 30 de 30 plazas, Albergue Betania Mujeres, 25 personas: Lourdes Sánchez, Lázara Báez, Lázara Echevarría, Lázara P…, Ocupación: 0 → 25 de 25 plazas, Posada Betel, 18 personas: Rosa Fernández, Sarahí Báez, Sarahí Cabrera, Sarahí Muñoz…, Ocupación: 0 → 18 de 20 plazas]
- Ronda 2: pendientes de hospedaje 0
- Sin hospedaje tras la sugerencia: 0

### 8b2 · Hospedaje: comprobar la propuesta aceptada y, si hay sobrecupo, reubicar a mano por la ficha (buscador y filtros) — FALLA (98s)

- Tras aceptar la propuesta de «Sugerir hospedaje»: hospedajes con sobrecupo [Posada Betel 58/20]; hospedajes que quedaron VACÍOS: [Casa Hno. Ramón Cruz, Casa Hna. Teresa Gil, Casa Hna. Ñuri Peña, Casa Familia Ñáñez, Casa Familia Rivas, Casa Familia Núñez, Casa Familia Peña, Casa Hno. Yunier Acosta, Posada Monte Sión]
- FALLA: la propuesta aceptada no excede la capacidad de ningún hospedaje (1 con sobrecupo)
- Reubicados a mano por la ficha: 38 (fallos 0). Hospedajes aún excedidos: 0
- OK: tras reubicar a mano no queda ningún hospedaje excedido (0)

### 8c · Hospedaje: asignación manual con buscador y filtros del formulario (reasignar solteros) y de quienes queden — PASA (9s)

- Sonda: mujer soltera nº 1 → casa de «Matrimonios»: avisos [«Casa Familia Rivas» solo acepta matrimonios y queda 1 persona sin su cónyuge: Lázara.]; el botón Guardar sigue activo=true (no se guarda)
- OK: elegir una casa de matrimonios para una mujer soltera muestra un aviso
- OK: asignadas/reasignadas 3 de 3 personas con el formulario (0 pendientes + 3 reasignaciones)
- Pendientes que no pudo resolver la asignación manual: 0

### 8d · Hospedaje: pendientes finales por «Asignar personas» del hospedaje (buscador, filtro y grupo) y verificación — PASA (1s)

- OK: diálogo «Asignar personas» abre con buscador
- OK: ningún confirmado sin hospedaje: 0 sin hospedaje ()
- OK: ningún hospedaje excede su capacidad (0 excedidos)
- OK: todos en un hospedaje compatible con su sexo/estado: 0 incompatibles ()
- OK: todos los matrimonios van juntos: 0 separados de 22
- Asignaciones de hospedaje: 216 de 216 personas (216 confirmadas).

### 9a · Asistentes: búsqueda, filtros (sexo/iglesia/hospedaje/equipo/asistencia), tabla ordenable y CSV — PASA (18s)

- OK: a 1366 px la lista es una TABLA
- OK: conteo «216 inscritos»
- OK: orden por Edad: ascendente 12 (mín 12), descendente 70 (máx 70)
- OK: búsqueda «nunez» → «22 de 216» (≥22 por nombre; también cuenta la iglesia)
- OK: filtro Sexo=Mujeres → «101 de 216» (BD 101)
- OK: CSV filtrado (mujeres): 101 filas
- OK: filtros Mujeres + Iglesia Ebenezer → «15 de 216» (BD 15)
- OK: añadir En el hospedaje=Albergue Betania Mujeres → «6 de 216» (BD 6)
- OK: añadir Equipo=Rojo → «1 de 216» (BD 1)
- OK: Asistencia=Confirmados + Hospedaje=Con hospedaje no cambia (todos lo están): «1 de 216»
- OK: sin filtros el conteo vuelve a «216 inscritos»
- OK: CSV completo: 216 filas = 216 personas
- OK: cabecera del CSV: id;numero;nombre;apellido1;apellido2;sexo;edad;iglesia;provincia;municipio;telefono;necesita_hospedaje;hospedaje;equipo;pareja_numero;grupos;observaciones

### 9b · Hospedajes: búsqueda, filtro «Acepta», plazas libres, tabla ordenable y CSV — PASA (5s)

- OK: tabla de hospedajes
- OK: búsqueda «casa»: «16 de 22» (BD 16)
- OK: filtro Acepta=Matrimonios: «6 de 22» (BD 6)
- Con «solo plazas libres» además: «5 de 22»
- OK: sin filtros: «22 hospedajes»
- OK: orden por Capacidad ascendente: primera fila 6
- OK: CSV de hospedajes: 22 filas = 22
- Cabecera: nombre;tipo;acepta;capacidad;ocupadas;libres;anfitrion;telefono;indicaciones;cercania
- Archivos filtrado: [26-hospedajes-filtrado-matrimonios-libres--hospedajes-congreso-nacional-qa-2026.csv]

### 9c · Equipos: búsqueda y CSV (con «Sin equipo») — PASA (2s)

- OK: resumen «8 equipos · 216 personas · 0 sin equipo»
- OK: búsqueda por equipo: «1 de 8»
- OK: CSV de equipos: 216 filas = 216 personas
- Equipos al final: Rojo: 27 (H15/M12, edad media 35.8) | Azul: 27 (H15/M12, edad media 35.7) | Verde: 27 (H14/M13, edad media 35.0) | Amarillo: 27 (H14/M13, edad media 35.5) | Morado: 27 (H14/M13, edad media 36.4) | Naranja: 27 (H14/M13, edad media 35.8) | Turquesa: 27 (H15/M12, edad media 36.1) | Rosa: 27 (H14/M13, edad media 35.9)

### 9d · Mis eventos: búsqueda, tabla ordenable y CSV — PASA (1s)

- OK: tabla de eventos
- OK: conteo «3 eventos»
- OK: búsqueda «estructura»: «1 de 3»
- OK: orden por Nombre descendente: primera fila «Congreso Nacional QA 2026 (solo estructura)»
- OK: CSV de eventos: 3 filas

### 10a · Exportaciones de «Copias de seguridad»: plantilla, CSV de asistentes y respaldo CSV del evento — PASA (2s)

- OK: plantilla, CSV y respaldo guardados: [30-plantilla--plantilla-asistentes.csv] [31-asistentes-backup-screen--asistentes-Congreso-Nacional-QA-2026.csv] [32-respaldo-evento--congreso-nacional-qa-2026-2026-11-24-094220.csv]
- OK: la plantilla trae solo las 17 cabeceras

### 10b · Reportes finales (todos confirmados): xlsx, csv (con y sin teléfono) y pdf — PASA (3s)

- OK: Reportes dice «216 inscritos» (todos confirmados: 216)
- OK: xlsx, csv y pdf + csv con teléfono: [33-reportes-final--asistentes-congreso-nacional-qa-2026.csv, 34-reportes-final--reportes-congreso-nacional-qa-2026.xlsx, 35-reportes-final--reportes-congreso-nacional-qa-2026.pdf] [36-reportes-final-con-telefono--asistentes-congreso-nacional-qa-2026.csv]
- OK: CSV de reportes: 216 filas = 216
- OK: XLSX con hojas Resumen y Asistentes (18634 B)
- OK: PDF válido (54848 B)
- OK: CSV de reportes: 216 filas = 216
- OK: listas PDF de hospedaje generadas con buildLodgingPdf: 2

### 10c · CSV de asistentes y respaldo de CADA evento — PASA (6s)

- OK: «Congreso Nacional QA 2026 (copia completa)»: CSV de asistentes 216 filas = 216 personas
- OK: «Congreso Nacional QA 2026 (copia completa)»: respaldo CSV guardado
- OK: «Congreso Nacional QA 2026 (solo estructura)»: CSV de asistentes 216 filas = 216 personas
- OK: «Congreso Nacional QA 2026 (solo estructura)»: respaldo CSV guardado

### 11 · Ida y vuelta del respaldo CSV: reabrir en una base vacía y comparar — PASA (1s)

- OK: personas: original 216 · restaurado 216
- OK: cada fila coincide (numero, nombre, sexo, edad, iglesia, tel, hospedaje, equipo, pareja, grupos, obs): 0 diferencias 
- OK: ids, estado (confirmado/preinscrito), confirmedAt y necesidad de hospedaje idénticos: 0 diferencias
- OK: comidas: sesiones 7/7 · marcas 1107/1107
- OK: hospedajes 22/22
- OK: equipos 8/8
- OK: grupos 4/4
- OK: el archivo exportado por la UI (32-respaldo-evento--congreso-nacional-qa-2026-2026-11-24-094220.csv) se reabre en base vacía: 216 personas

### 12 · Pasada a 1920x1080 por todas las pantallas — PASA (17s)

- OK: 1920x1080 · «Panel» sin desbordes/errores
- OK: 1920x1080 · «Asistentes» sin desbordes/errores
- OK: 1920x1080 · «Confirmar asistencia» sin desbordes/errores
- OK: 1920x1080 · «Hospedajes» sin desbordes/errores
- OK: 1920x1080 · «Equipos» sin desbordes/errores
- OK: 1920x1080 · «Comidas» sin desbordes/errores
- OK: 1920x1080 · «Reportes» sin desbordes/errores
- OK: 1920x1080 · «Configuración» sin desbordes/errores
- OK: 1920x1080 · «Copias de seguridad» sin desbordes/errores
- OK: 1920x1080: Asistentes es tabla
- OK: 1920x1080: filtros visibles (alto ≥ 720)
- Búsqueda «ñ» a 1920x1080: 210 de 216
- OK: 1920x1080: Mis eventos es tabla
- OK: 1093x614 (alto < 720): los filtros arrancan plegados
- OK: «Filtros» los despliega
- OK: «Filtros» los vuelve a plegar
- OK: 1093x614 sin desbordes

### 13 · Cifras finales — PASA (0s)

- Cifras: formulario 43 · CSV A 63 · CSV B (preinscripción) 110; confirmados 216; preinscritos 0.

## Cifras

- **hospedajes_creados_UI**: 22
- **plazas_totales**: 312
- **form_hospedaje_asignado**: 14
- **formulario_total**: 43
- **csv_A_nuevas**: 63
- **csv_B_nuevas_preinscritas**: 110
- **personas_total**: 216
- **preinscritos_inicial**: 131
- **confirmados_directos_inicial**: 85
- **preinscritos_sin_confirmar_tras_paso4**: 13
- **confirmados_tras_paso4**: 203
- **copia_completa_personas**: 216
- **pasar_participantes**: 216 pasados, repetición omitió todos
- **comidas_sesiones**: 7
- **comidas_sesiones_cerradas**: 6
- **comidas_marcas_activas_total**: 1106
- **comidas_marcas_por_UI**: 220
- **comidas_marcas_por_repositorio**: 884
- **comidas_repetidos_bloqueados**: 1
- **confirmados_final**: 216
- **hospedaje_pendiente_tras_sugerencia**: 0
- **sobrecupo_tras_sugerencia**: [Posada Betel: 58/20]
- **hospedaje_reubicados_a_mano_por_sobrecupo**: 38
- **hospedaje_manual_por_formulario**: 3
- **hospedaje_confirmados_sin_hospedaje**: 0
- **hospedaje_asignaciones**: 216
- **hospedaje_ocupacion_max**: [Albergue Central Hombres: 30/30, Albergue Escuela Hombres: 25/25, Casa Hno. Ramón Cruz: 3/15, Casa Hno. Osvaldo Díaz: 15/15, Casa Hno. Julián Báez: 15/15, Albergue Juvenil Mujeres: 30/30, Albergue Betania Mujeres: 25/25, Casa Hna. Teresa Gil: 8/15, Casa Hna. Carmen Soto: 15/15, Casa Hna. Ñuri Peña: 0/15, Casa Familia Gómez: 10/10, Casa Familia Ortiz: 2/10, Casa Familia Ñáñez: 0/8, Casa Familia Rivas: 0/8, Casa Familia Núñez: 0/6, Casa Familia Peña: 0/6, Posada Betel: 20/20, Casa Pastoral: 12/12, Casa Hno. Yunier Acosta: 0/8, Casa Hna. Rosa Leyva: 2/8, Posada Monte Sión: 0/10, Casa Hno. Elier Piñeiro: 4/6]
- **equipos_resumen**: [Rojo: 27 (H15/M12, edad media 35.8), Azul: 27 (H15/M12, edad media 35.7), Verde: 27 (H14/M13, edad media 35.0), Amarillo: 27 (H14/M13, edad media 35.5), Morado: 27 (H14/M13, edad media 36.4), Naranja: 27 (H14/M13, edad media 35.8), Turquesa: 27 (H15/M12, edad media 36.1), Rosa: 27 (H14/M13, edad media 35.9)]
- **eventos_total**: 3
- **ida_y_vuelta**: personas 216=216, diferencias de fila 0, de estado 0
- **evento_principal_personas**: 216
- **preinscritos_final**: 0
- **hombres**: 115
- **mujeres**: 101
- **vias**: formulario 43 · CSV A 63 · CSV B (preinscripción) 110
- **hospedajes_via_UI**: 22
- **eventos**: [Congreso Nacional QA 2026, Congreso Nacional QA 2026 (copia completa), Congreso Nacional QA 2026 (solo estructura)]

## Defectos

- **QA-WIN-01** (Baja, paso 2b) El interruptor «Preinscripción» no se limpia con «Guardar y registrar otro»
  - Tras guardar a una persona como preinscrita con «Guardar y registrar otro», el formulario se limpia (nombre, sexo, edad, iglesia, hospedaje…) pero «Preinscripción» sigue activado. Puede ser intencional para cargar lotes, pero quien registre después a una persona que SÍ llegó puede dejarla preinscrita sin notarlo (queda fuera de comidas y reportes hasta confirmarla).
- **QA-WIN-02** (Baja, paso 2b) El aviso verde (SnackBar) tapa el botón de acción a 1366x768
  - Tras «Guardar y registrar otro» el aviso «Listo. … quedó registrado/a como asistente nº N» (4 s) cubre la zona del botón «Guardar y registrar otro»/«Guardar asistente» (botón 704–752 px, aviso 720–768 px en una ventana de 768 px de alto): un toque inmediato cae sobre el aviso y no guarda. Con registro seguido a mano rara vez molesta (escribir tarda más de 4 s), pero en la prueba hizo fallar el segundo guardado inmediato.
- **QA-WIN-03** (Media, paso 3a) En el CSV la «M» se lee como Mujer, pero en el formulario «M (Hombre)»
  - Fila «Mario Ñáñez-Sexom;sexo=M» del CSV A se importó como mujer. El formulario de registro etiqueta «M (Hombre)/F (Mujer)», y parseSexCell (packages/mi_evento_core/lib/src/attendee_csv.dart) interpreta M como mujer (y H como hombre). Quien llene Excel pensando en la convención del formulario invierte el sexo sin aviso y afecta a hospedaje y equipos.
- **QA-WIN-04** (Baja, paso 5b) En «Mis eventos» (tabla, 1366x768) el menú ⋮ de acciones queda fuera de la ventana con nombres largos
  - Con dos eventos (el principal y su copia «… (copia completa)») la tabla es más ancha que la ventana de 1366 px y el botón ⋮ (Duplicar / Pasar participantes / Eliminar) se dibuja en x=1492, fuera de la pantalla: hay que desplazar la tabla en horizontal para llegar a las acciones del evento.
- **QA-WIN-05** (Baja, paso 6) Comidas: a un preinscrito no se le puede marcar y no hay aviso (solo «Nadie con ese nombre. ¿Falta registrarlo?»)
  - Con la persona nº 110 PREINSCRITA, en Control de comidas la búsqueda por su número no la encuentra y muestra «Nadie con ese nombre. ¿Falta registrarlo?». PLAN.md promete un aviso «confirma primero su asistencia» al marcarla; ese aviso solo existe en la capa de datos (MealRepo.mark lanza DataException), pero la pantalla filtra a los preinscritos y nunca lo muestra. Un operador creerá que la persona no está inscrita.
- **QA-WIN-06** (Alta, paso 8b2) «Sugerir hospedaje» propone más gente de la que cabe: el mismo hospedaje «Sin preferencia» se llena varias veces y no avisa
  - Con 216 personas que necesitan hospedaje (114 hombres, 100 mujeres, 22 matrimonios; 312 plazas en 22 hospedajes) la propuesta única de «Sugerir hospedaje» trae TRES tramos para «Posada Betel» (capacidad 20), cada uno «exactamente lleno», y la UI los acepta sin ningún aviso porque valida cada tramo por separado: resultado Posada Betel 58/20. Mientras, hospedajes compatibles con plazas libres quedan vacíos: Casa Hno. Ramón Cruz, Casa Hna. Teresa Gil, Casa Hna. Ñuri Peña, Casa Familia Ñáñez, Casa Familia Rivas, Casa Familia Núñez, Casa Familia Peña, Casa Hno. Yunier Acosta, Posada Monte Sión. Reproducido también a nivel de datos con suggestLodging (packages/mi_evento_core/lib/src/lodging_suggest.dart): los mismos 214 con los mismos hospedajes dan 3 tramos de 20 para «Posada Betel». Con el volumen del QA anterior (120 personas) no ocurría. Causa probable: el comodín «Sin preferencia» se reutiliza para cada categoría (matrimonios, hombres, mujeres) sin descontar lo ya asignado en los tramos anteriores.

## Archivos exportados

| Archivo | Bytes | Origen |
|---|---:|---|
| 01-reportes-con-pendientes--asistentes-congreso-nacional-qa-2026.csv | 20063 | reportes-con-pendientes |
| 02-reportes-con-pendientes--reportes-congreso-nacional-qa-2026.xlsx | 16179 | reportes-con-pendientes |
| 03-reportes-con-pendientes--reportes-congreso-nacional-qa-2026.pdf | 49640 | reportes-con-pendientes |
| 04-asistentes-filtro-preinscritos--asistentes-congreso-nacional-qa-2026.csv | 1994 | asistentes-filtro-preinscritos |
| 05-comidas-almuerzo-viernes--congreso-nacional-qa-2026-almuerzo-viernes.csv | 18166 | comidas-almuerzo-viernes |
| 06-comidas-almuerzo-viernes--congreso-nacional-qa-2026-almuerzo-viernes.xlsx | 15041 | comidas-almuerzo-viernes |
| 07-comidas-almuerzo-viernes--congreso-nacional-qa-2026-almuerzo-viernes.png | 14506 | comidas-almuerzo-viernes |
| 08-comidas-almuerzo-viernes-v2-tras-reabrir--congreso-nacional-qa-2026-almuerzo-viernes.csv | 18181 | comidas-almuerzo-viernes-v2-tras-reabrir |
| 09-comidas-cena-viernes--congreso-nacional-qa-2026-cena-viernes.csv | 18016 | comidas-cena-viernes |
| 10-comidas-cena-viernes--congreso-nacional-qa-2026-cena-viernes.xlsx | 15038 | comidas-cena-viernes |
| 11-comidas-cena-viernes--congreso-nacional-qa-2026-cena-viernes.png | 14472 | comidas-cena-viernes |
| 12-comidas-almuerzo-sabado--congreso-nacional-qa-2026-almuerzo-sabado.csv | 18076 | comidas-almuerzo-sabado |
| 13-comidas-almuerzo-sabado--congreso-nacional-qa-2026-almuerzo-sabado.xlsx | 15106 | comidas-almuerzo-sabado |
| 14-comidas-almuerzo-sabado--congreso-nacional-qa-2026-almuerzo-sabado.png | 14462 | comidas-almuerzo-sabado |
| 15-comidas-cena-sabado--congreso-nacional-qa-2026-cena-sabado.csv | 17866 | comidas-cena-sabado |
| 16-comidas-cena-sabado--congreso-nacional-qa-2026-cena-sabado.xlsx | 15014 | comidas-cena-sabado |
| 17-comidas-cena-sabado--congreso-nacional-qa-2026-cena-sabado.png | 14491 | comidas-cena-sabado |
| 18-comidas-almuerzo-domingo--congreso-nacional-qa-2026-almuerzo-domingo.csv | 18106 | comidas-almuerzo-domingo |
| 19-comidas-almuerzo-domingo--congreso-nacional-qa-2026-almuerzo-domingo.xlsx | 15111 | comidas-almuerzo-domingo |
| 20-comidas-almuerzo-domingo--congreso-nacional-qa-2026-almuerzo-domingo.png | 14473 | comidas-almuerzo-domingo |
| 21-comidas-cena-domingo--congreso-nacional-qa-2026-cena-domingo.csv | 17956 | comidas-cena-domingo |
| 22-comidas-cena-domingo--congreso-nacional-qa-2026-cena-domingo.xlsx | 14988 | comidas-cena-domingo |
| 23-comidas-cena-domingo--congreso-nacional-qa-2026-cena-domingo.png | 14451 | comidas-cena-domingo |
| 24-asistentes-filtrado-mujeres--asistentes-congreso-nacional-qa-2026.csv | 16583 | asistentes-filtrado-mujeres |
| 25-asistentes-completo--asistentes-congreso-nacional-qa-2026.csv | 35176 | asistentes-completo |
| 26-hospedajes-filtrado-matrimonios-libres--hospedajes-congreso-nacional-qa-2026.csv | 505 | hospedajes-filtrado-matrimonios-libres |
| 27-hospedajes-completo--hospedajes-congreso-nacional-qa-2026.csv | 1936 | hospedajes-completo |
| 28-equipos-completo--equipos-congreso-nacional-qa-2026.csv | 15112 | equipos-completo |
| 29-eventos--eventos.csv | 270 | eventos |
| 30-plantilla--plantilla-asistentes.csv | 159 | plantilla |
| 31-asistentes-backup-screen--asistentes-Congreso-Nacional-QA-2026.csv | 35176 | asistentes-backup-screen |
| 32-respaldo-evento--congreso-nacional-qa-2026-2026-11-24-094220.csv | 438304 | respaldo-evento |
| 33-reportes-final--asistentes-congreso-nacional-qa-2026.csv | 25640 | reportes-final |
| 34-reportes-final--reportes-congreso-nacional-qa-2026.xlsx | 18634 | reportes-final |
| 35-reportes-final--reportes-congreso-nacional-qa-2026.pdf | 54848 | reportes-final |
| 36-reportes-final-con-telefono--asistentes-congreso-nacional-qa-2026.csv | 26426 | reportes-final-con-telefono |
| 37-lista-hospedaje--Lista - Albergue Central Hombres.pdf | 19160 | lista-hospedaje (función, no UI) |
| 38-lista-hospedaje--Lista - Casa Familia Gómez.pdf | 15803 | lista-hospedaje (función, no UI) |
| 39-asistentes-evento-congreso-nacional-qa-2026-copia-completa--asistentes-Congreso-Nacional-QA-2026-copia-completa-.csv | 30864 | asistentes-evento-congreso-nacional-qa-2026-copia-completa |
| 40-respaldo-evento-congreso-nacional-qa-2026-copia-completa--congreso-nacional-qa-2026-copia-completa-2026-11-24-094226.csv | 109705 | respaldo-evento-congreso-nacional-qa-2026-copia-completa |
| 41-asistentes-evento-congreso-nacional-qa-2026-solo-estructura--asistentes-Congreso-Nacional-QA-2026-solo-estructura-.csv | 29132 | asistentes-evento-congreso-nacional-qa-2026-solo-estructura |
| 42-respaldo-evento-congreso-nacional-qa-2026-solo-estructura--congreso-nacional-qa-2026-solo-estructura-2026-11-24-094228.csv | 89025 | respaldo-evento-congreso-nacional-qa-2026-solo-estructura |
| 43-asistentes-evento-congreso-nacional-qa-2026--asistentes-Congreso-Nacional-QA-2026.csv | 35176 | asistentes-evento-congreso-nacional-qa-2026 |

## Limitaciones

- «Guardar como PDF» de la lista de un hospedaje usa Printing.sharePdf (canal de plataforma), que no pasa por el FileSaver de pruebas; se generó el PDF llamando a buildLodgingPdf (no por la UI).
- No hay Windows: es el motor de widget tests de Flutter con SQLite en memoria, ventana simulada (dpr 1) y MemoryFileSaver/MemoryFilePick; no se probaron diálogos nativos de «Guardar como…», impresión real, DPI real ni rendimiento de un equipo real.
- Drift se cuelga si se escribe desde la prueba mientras una pantalla observa hospedajes/equipos: por eso las marcas de comida «por repositorio» se escribieron con la app apagada (como cerrarla y volver a abrirla) y la pantalla se reabrió después.
- El tiempo del reloj de pruebas no avanza solo (hay que usar runAsync); los tiempos medidos no son rendimiento real.
