# QA de punta a punta — reglas nuevas y «continuar desde Excel»

Fecha: 25 de noviembre de 2026 · sobre `main` tras los PR #4–#8. Todo se probó en el **entorno de
pruebas de Flutter** (SQLite en memoria, ventana simulada). **No se probó en Windows, móvil ni Excel
reales.**

## Qué se ejecutó

| Prueba | Alcance | Resultado |
|---|---|---|
| `test/qa/e2e_fase_test.dart` E2E-1 | Evento de 216 personas (25 matrimonios): hospedaje + equipos; ningún hospedaje con gente incompatible, ningún matrimonio del mismo sexo, numeración 1–216, provincia/municipio de la iglesia | Pasa |
| E2E-2 | Bloqueos por todas las vías (datos, CSV, cambiar «acepta», matrimonio del mismo sexo) | Pasa |
| E2E-3 | Preinscripción (216) → confirmar 100 por CSV → idempotencia → desconfirmar (se bloquea, todo o nada, con comidas) | Pasa |
| E2E-4 ×3 | **Fallo crítico:** CSV de iglesias, hospedajes, asistentes (+20 escritas a mano en Excel) y equipos, guardados como Excel ES (`;`, ANSI), Excel EN (`,`) y «Texto Unicode» (UTF-16, tab), con ceros de teléfono perdidos y filas/columnas vacías → importados en una base VACÍA: 236 personas, numeración conservada, nombres con tildes/ñ intactos, hospedajes y equipos idénticos al original, matrimonios conservados, reimportar no duplica | Pasa |
| E2E-5 | Pasando por **LibreOffice real** (CSV → XLSX → CSV): reimporta las 216 personas y sus matrimonios | Pasa |
| `qa/windows_qa_test.dart` (UI real, 1366×768 y 1920×1080, 35 pasos) | Registro, importaciones, confirmación, comidas, hospedaje, equipos, reportes, copias | **35/35 pasos, 0 defectos** (informe: `docs/QA-windows-informe-auto.md`) |

## Defectos encontrados y corregidos

1. **La línea `sep=;` de los CSV no se reconocía si otra hoja de cálculo la guardaba rellena de
   separadores o entre comillas** (`"sep=;"`, `sep=;;;;`): la importación fallaba con «Faltan columnas».
   Corregido en `parseCsv` (con test).
2. La tabla de *Confirmar asistencia* dejaba la última fila bajo el aviso «Asistencia confirmada»:
   se añadió margen inferior.
3. El guion de QA de Windows estaba desactualizado respecto a las tablas nuevas (se actualizó; no era
   un defecto de la app).

## Lo que NO se pudo probar

- **Excel real.** Se simuló su manera de guardar (separador, codificación, ceros) y se probó con
  LibreOffice, pero `sep=;` solo lo obedece Excel: confirmar con el `.exe` del CI.
- Windows y móvil reales (táctil, teclado en pantalla, rendimiento con 1000+).
- Excel puede alterar al editar: pierde ceros iniciales en teléfonos y reescribe fechas (los eventos
  aceptan `d/m/aaaa`).
