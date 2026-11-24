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

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: Brand.azul).copyWith(
    primary: Brand.azul,
    secondary: Brand.naranja,
    error: Brand.error,
    surface: Colors.white,
    onSurface: Brand.tinta,
  );
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Atkinson',
    colorScheme: scheme,
    scaffoldBackgroundColor: Brand.fondo,
    // La fuente va AQUÍ: un textTheme propio (con Roboto) anula `ThemeData.fontFamily`,
    // y el cuerpo de la app nunca llegaba a usar Atkinson Hyperlegible.
    textTheme: Typography.blackMountainView.apply(
        fontFamily: 'Atkinson',
        bodyColor: Brand.tinta,
        displayColor: Brand.tinta),
    appBarTheme: AppBarTheme(
        backgroundColor: Brand.azul,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: headStyle(22, color: Colors.white)),
    cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Brand.borde))),
    filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
            minimumSize: const Size(64, 56),
            shape: shape,
            textStyle:
                const TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
            minimumSize: const Size(64, 56),
            shape: shape,
            side: const BorderSide(color: Brand.azul, width: 2),
            textStyle:
                const TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF8A93A3), width: 1.5)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Brand.azul, width: 2)),
    ),
    navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: Brand.azulSuave,
        height: 68),
  );
}
