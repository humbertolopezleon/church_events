import 'package:material_ui/material_ui.dart';

/// Identidad visual del diseño aprobado (azul Esperanza, naranja Atardecer).
/// Las fuentes Nunito y Atkinson Hyperlegible se empaquetarán como assets (sin red);
/// mientras tanto cae a la fuente del sistema.
class Brand {
  static const azul = Color(0xFF1D4E89);
  static const azulSuave = Color(0xFFE6EEF8);
  static const naranja = Color(0xFFE07A2E);
  static const naranjaSuave = Color(0xFFFDEBDD);
  static const exito = Color(0xFF1B7A43);
  static const exitoSuave = Color(0xFFE3F4EA);
  static const aviso = Color(0xFFE8B53A);
  static const avisoSuave = Color(0xFFFFF3CC);
  static const avisoTexto = Color(0xFF6B4600);
  static const error = Color(0xFFB3261E);
  static const tinta = Color(0xFF18202B);
  static const fondo = Color(0xFFF5F3EE);
  static const gris = Color(0xFF4A5565);
  static const borde = Color(0xFFD5D9E0);
}

/// Títulos y números grandes: Nunito ExtraBold (fuente variable, eje de peso).
TextStyle headStyle(double size, {Color? color}) => TextStyle(
    fontFamily: 'Nunito',
    fontSize: size,
    color: color,
    fontWeight: FontWeight.w800,
    fontVariations: const [FontVariation('wght', 800)]);

/// Texto de cuerpo: Atkinson Hyperlegible (con una fuente de sistema como respaldo sin red).
const _sans = 'Atkinson';

TextStyle bodyStyle(double size,
        {Color? color, FontWeight weight = FontWeight.w400}) =>
    TextStyle(
        fontFamily: _sans, fontSize: size, color: color, fontWeight: weight);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: Brand.azul).copyWith(
    primary: Brand.azul,
    secondary: Brand.naranja,
    error: Brand.error,
    surface: Colors.white,
    onSurface: Brand.tinta,
  );
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
  final button = bodyStyle(17, weight: FontWeight.w700);
  // Todos los estilos pasan por Atkinson: un textTheme propio (con Roboto) o un TextStyle sin
  // familia hacían que botones y títulos de diálogo salieran en Roboto.
  final base = Typography.blackMountainView.apply(
      fontFamily: _sans, bodyColor: Brand.tinta, displayColor: Brand.tinta);
  return ThemeData(
    useMaterial3: true,
    fontFamily: _sans,
    colorScheme: scheme,
    scaffoldBackgroundColor: Brand.fondo,
    // Texto base 18 sp (mínimo 16), secundario 15 sp.
    textTheme: base.copyWith(
      bodyLarge: base.bodyLarge!.copyWith(fontSize: 18),
      bodyMedium: base.bodyMedium!.copyWith(fontSize: 18),
      bodySmall: base.bodySmall!.copyWith(fontSize: 15, color: Brand.gris),
      labelLarge: base.labelLarge!.copyWith(fontSize: 17),
      labelMedium: base.labelMedium!.copyWith(fontSize: 15),
      titleMedium: base.titleMedium!.copyWith(fontSize: 18),
      titleSmall: base.titleSmall!.copyWith(fontSize: 16),
    ),
    appBarTheme: AppBarTheme(
        backgroundColor: Brand.azul,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        titleTextStyle: headStyle(24, color: Colors.white)),
    cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Brand.borde))),
    dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        titleTextStyle:
            bodyStyle(22, color: Brand.tinta, weight: FontWeight.w700),
        contentTextStyle: bodyStyle(18, color: Brand.tinta),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)))),
    filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
            minimumSize: const Size(64, 56), shape: shape, textStyle: button)),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
            minimumSize: const Size(64, 56),
            shape: shape,
            side: const BorderSide(color: Brand.azul, width: 2),
            textStyle: button)),
    textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
            minimumSize: const Size(64, 44), shape: shape, textStyle: button)),
    chipTheme: ChipThemeData(
        labelStyle: bodyStyle(16, color: Brand.tinta),
        side: const BorderSide(color: Brand.borde)),
    popupMenuTheme: PopupMenuThemeData(
        textStyle: bodyStyle(17, color: Brand.tinta),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    snackBarTheme:
        SnackBarThemeData(contentTextStyle: bodyStyle(16, color: Colors.white)),
    tooltipTheme:
        TooltipThemeData(textStyle: bodyStyle(14, color: Colors.white)),
    listTileTheme: ListTileThemeData(
        titleTextStyle:
            bodyStyle(17, color: Brand.tinta, weight: FontWeight.w700),
        subtitleTextStyle: bodyStyle(15, color: Brand.gris)),
    dataTableTheme: DataTableThemeData(
        dataTextStyle: bodyStyle(16, color: Brand.tinta),
        headingTextStyle:
            bodyStyle(16, color: Brand.tinta, weight: FontWeight.w700)),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      labelStyle: bodyStyle(16, color: Brand.gris),
      hintStyle: bodyStyle(17, color: Brand.gris),
      helperStyle: bodyStyle(15, color: Brand.gris),
      errorStyle: bodyStyle(15, color: Brand.error),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF8A93A3), width: 1.5)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Brand.azul, width: 2)),
    ),
    navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: Brand.azulSuave,
        height: 68,
        labelTextStyle:
            WidgetStatePropertyAll(bodyStyle(14, color: Brand.tinta))),
  );
}
