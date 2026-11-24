# Datos de prueba de «Mi Evento» (QA)

Generados con los servicios reales de la app y una **semilla fija** (2026). Todos los nombres,
teléfonos y observaciones son **inventados**. Evento: **Congreso QA 2026** (11 al 13 de diciembre de 2026).

## Qué contiene el evento

- **120 personas** (60 hombres y 60 mujeres), edades de 12 a 70, nombres con tildes y ñ, 9 iglesias.
- **15 matrimonios** (3 de ellos con la esposa inscrita 10 puestos después de su esposo), **5 grupos** de iglesia («mantener juntos»).
- **6 equipos** (Rojo, Azul, Verde, Amarillo, Morado, Naranja) repartidos con el equipo automático al inscribir:
  Rojo: 20 (H10/M10, edad media 36.3) | Azul: 20 (H10/M10, edad media 35.1) | Verde: 19 (H10/M9, edad media 35.8) | Amarillo: 20 (H10/M10, edad media 36.9) | Morado: 20 (H10/M10, edad media 36.5) | Naranja: 21 (H10/M11, edad media 36.4)
- **11 hospedajes** (albergues y casas; solo hombres, solo mujeres y matrimonios). 84 personas necesitan hospedaje y **todas** lo tienen (sugerencia aceptada).
  Ocupación: Albergue Central (hombres): 24/24; Albergue Juvenil (mujeres): 24/24; Albergue de la Escuela (hombres): 4/12; Casa Familia Gómez: 8/8; Casa Familia Ortiz: 2/8; Casa Familia Rivas: 10/10; Casa Familia Ñáñez: 10/10; Casa de la Hna. Carmen: 2/6; Casa de la Hna. Teresa: 0/5; Casa del Hno. Osvaldo: 0/4; Casa del Hno. Ramón: 0/6
- **2 sesiones de comida**: «Almuerzo del sábado» (90 personas marcadas, abierta) y «Cena del viernes» (60 marcadas, cerrada). 150 marcas en total.
- Contenido del respaldo CSV: events 1, ageRanges 5, churches 9, teams 6, lodgings 11, attendees 120, couples 15, groups 5, groupMembers 25, controlTypes 3, controlSessions 2, controlRecords 150.

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

1. **`asistentes_120.csv`** en un evento destino con los mismos equipos y hospedajes (y sin personas): 120 personas nuevas, 5 grupos nuevos, 0 iglesias nuevas, 0 avisos.
   El resultado es idéntico al original (nombres, edades, iglesias, teléfonos, hospedaje, equipo, parejas, grupos, números 1–120).
2. **`plantilla_vacia.csv`**: al importarla no hay filas ni errores (la vista previa no tiene nada que importar).
3. **`importar_nuevos_30.csv`** sobre un evento que ya tiene las 120: 30 personas nuevas, 0 errores, 0 duplicados; números 121 a 150.
   Las personas importadas quedan **sin equipo** (el equipo automático solo funciona al inscribir por el formulario; ver docs/QA-informe.md, QA-BUG-006).
4. **`importar_con_errores.csv`** sobre un evento que ya tiene las 120: 8 personas nuevas, 2 posibles duplicados omitidos, 11 filas con errores (filas 4, 5, 6, 7, 8, 9, 10, 11, 12, 14, 16), avisos de la revisión: 2 (1 de hospedaje y 1 de equipo), avisos al importar: 1 (pareja que no existe), grupos nuevos: 1.
   Detalle de las filas rechazadas (número de fila de Excel: motivo):
   - 4: falta el nombre.
   - 5: falta el primer apellido.
   - 6: el sexo «Otro» no se entiende (usa Hombre o Mujer).
   - 7: la edad «treinta» no es un número.
   - 8: la edad debe estar entre 1 y 110 años.
   - 9: la edad debe estar entre 1 y 110 años.
   - 10: falta la iglesia.
   - 11: «necesita_hospedaje» debe ser Sí o No.
   - 12: el número de pareja «abc» no es válido.
   - 14: el id repite el de la fila 13.
   - 16: el número 500 repite el de la fila 15.
5. **`importar_ansi.csv`**: 8 personas nuevas, 0 errores, con tildes y ñ intactas.
6. **`respaldo_evento_qa.csv`** abierto en una base vacía: 352 filas nuevas, 0 actualizadas, 0 sin cambios; quedan las 120 personas, 6 equipos, 11 hospedajes, 15 matrimonios, 5 grupos, 2 sesiones y 150 marcas.

## Cómo regenerarlos

```
cd apps/mi_evento
timeout 580 flutter test qa/generate_qa_dataset_test.dart
```

Los **contenidos** salen siempre iguales (semilla fija); los identificadores internos (`id`) y las marcas de hora cambian en cada generación.
La carpeta de salida se puede cambiar con la variable de entorno `QA_DATASETS_DIR`.
