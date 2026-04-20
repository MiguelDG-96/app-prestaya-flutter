import 'package:flutter/material.dart';

class AppTheme {
  // Colores principales
  static const Color primary = Color(0xFF7B61FF);
  static const Color secondary = Color(0xFF4A3C6E);
  static const Color accent = Color(0xFF00C853);
  static const Color background = Color(0xFFF8F9FB);
  static const Color surface = Colors.white;
  static const Color text = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF7D848D);
  static const Color border = Color(0xFFE8EBF0);
  static const Color error = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFC107);
  static const Color money = Color(0xFF2E7D32);

  // Gradientes
  static const List<Color> splashGradient = [
    Color(0xFF2E1E45),
    Color(0xFF0F0A1E),
  ];

  // Espaciado
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;

  // Bordes
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 20.0;
  static const double radiusXl = 30.0;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: text,
      ),
      scaffoldBackgroundColor: background,
      dividerColor: border,
      
      // Estilo de Texto
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: text, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: text, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: text),
        bodyMedium: TextStyle(color: textSecondary),
      ),

      // Botones
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          elevation: 0,
        ),
      ),

      // Inputs (TextFields)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      ),
    );
  }
}
