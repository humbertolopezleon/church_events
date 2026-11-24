# Mi Evento

Sistema offline para registrar asistentes a eventos cristianos (Android + Windows, Flutter).

- `docs/PLAN.md` — plan de arquitectura, modelo de datos, algoritmos, fases, riesgos y estimación.
- `prototype/index.html` — prototipo clicable aprobado de la interfaz (abrir en el navegador).
- `packages/mi_evento_core` — dominio compartido en Dart puro (ids, duplicados, rangos de edad, balanceo).
- `apps/mi_evento` — app Flutter (Android y Windows).

## Desarrollo

```bash
cd packages/mi_evento_core && dart pub get && dart test
cd apps/mi_evento && flutter pub get \
  && dart run build_runner build --delete-conflicting-outputs \
  && flutter analyze && flutter test
flutter run -d windows      # o un móvil Android conectado
```

Requiere Flutter estable (3.50 o superior). El APK y el instalador de Windows se compilan en CI
(`.github/workflows/ci.yml`).

## Licencia

Mi Evento es de **código visible, no de uso libre**: se publica bajo la
[PolyForm Noncommercial License 1.0.0](LICENSE).

- **Permitido sin pedir permiso:** leer el código, usarlo, modificarlo y compartirlo para fines **no comerciales**
  (uso personal, estudio, investigación, y organizaciones benéficas, religiosas o educativas sin fines de lucro
  para sus propios eventos, según define la licencia).
- **No permitido sin licencia aparte:** venderlo, ofrecerlo como servicio de pago, incluirlo en un producto
  comercial o usarlo para obtener un beneficio comercial.
- **Funciones de pago y licencias comerciales:** se ofrecerán por separado. Para un uso comercial, abre un
  *issue* en este repositorio.

Las fuentes tipográficas incluidas (`apps/mi_evento/assets/fonts/`) mantienen su propia licencia (SIL OFL;
ver los archivos `OFL-*.txt`) y no quedan cubiertas por la licencia de arriba.

Se aceptan *issues* con sugerencias y errores. Por ahora no se aceptan contribuciones de código externas, para
poder seguir ofreciendo licencias comerciales sobre todo el código.
