import 'package:flutter/material.dart';

class ZTheme {
  static const Color primary = Color(0xFF1677FF);
  static const Color secondary = Color(0xFF2D9CFF);
  static const Color gold = Color(0xFFFFC34D);
  static const Color goldDeep = Color(0xFFB87912);
  static const Color accent = Color(0xFF4FC3FF);
  static const Color danger = Color(0xFFFF5D68);
  static const Color surfaceDark = Color(0xFF070B12);
  static const Color panelDark = Color(0xFF101722);
  static const Color surfaceLight = Color(0xFFF3F5F8);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.light, secondary: secondary, tertiary: gold);
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: surfaceLight,
      useMaterial3: true,
      fontFamily: 'sans',
      cardTheme: CardTheme(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)), color: Colors.white),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none)),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.dark, secondary: secondary, tertiary: gold);
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: surfaceDark,
      useMaterial3: true,
      cardTheme: CardTheme(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)), color: panelDark),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: const Color(0xFF151D29), border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none)),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF080C13),
        indicatorColor: gold.withValues(alpha: .14),
        labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: .7))),
      ),
    );
  }

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF07101C), Color(0xFF183354), Color(0xFF6B4310)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
