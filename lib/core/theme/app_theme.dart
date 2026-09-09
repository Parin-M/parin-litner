import 'package:flutter/material.dart';

class AppTheme {
  static const themes = <ThemeOption>[
    ThemeOption('آسمان', Color(0xFF5B7CFA), Color(0xFF8B5CF6)),
    ThemeOption('نعنایی', Color(0xFF10B981), Color(0xFF06B6D4)),
    ThemeOption('مرجانی', Color(0xFFFF6B6B), Color(0xFFFF9F43)),
    ThemeOption('رز', Color(0xFFEC4899), Color(0xFFF472B6)),
    ThemeOption('یاسی', Color(0xFF8B5CF6), Color(0xFFA78BFA)),
    ThemeOption('اقیانوس', Color(0xFF0EA5E9), Color(0xFF14B8A6)),
    ThemeOption('لیمو', Color(0xFF84CC16), Color(0xFF22C55E)),
    ThemeOption('طلایی', Color(0xFFF59E0B), Color(0xFFEAB308)),
    ThemeOption('لاوندر', Color(0xFF6366F1), Color(0xFF06B6D4)),
  ];

  static ThemeData light(int index) {
    final safeIndex = index.clamp(0, themes.length - 1).toInt();
    final t = themes[safeIndex];
    final scheme = ColorScheme.fromSeed(seedColor: t.primary, brightness: Brightness.light);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF5F7FB),
      fontFamily: 'sans-serif',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(color: Colors.white.withOpacity(.62), elevation: 0),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(.72),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: t.primary.withOpacity(.10))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: t.primary.withOpacity(.45), width: 1.5)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: t.primary, foregroundColor: Colors.white),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: t.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)))),
    );
  }
}

class ThemeOption {
  final String name;
  final Color primary;
  final Color secondary;
  const ThemeOption(this.name, this.primary, this.secondary);
}
