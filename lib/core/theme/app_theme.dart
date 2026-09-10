import 'package:flutter/material.dart';

class ThemeOption {
  final String name;
  final Color primary;
  final Color secondary;
  final Color background;
  const ThemeOption(this.name, this.primary, this.secondary, this.background);
}

class AppTheme {
  static const themes = <ThemeOption>[
    ThemeOption('آسمان', Color(0xFF3F51B5), Color(0xFF64B5F6), Color(0xFFEFF3FF)),
    ThemeOption('اقیانوس', Color(0xFF0277BD), Color(0xFF26C6DA), Color(0xFFEAF8FC)),
    ThemeOption('نعنایی', Color(0xFF00897B), Color(0xFF4DB6AC), Color(0xFFECFAF7)),
    ThemeOption('زمرد', Color(0xFF2E7D32), Color(0xFF66BB6A), Color(0xFFF0F9F0)),
    ThemeOption('لیمویی', Color(0xFF689F38), Color(0xFFAFB42B), Color(0xFFF7FBEA)),
    ThemeOption('طلایی', Color(0xFFEF6C00), Color(0xFFFFB300), Color(0xFFFFF5E7)),
    ThemeOption('مرجانی', Color(0xFFE64A19), Color(0xFFFF7043), Color(0xFFFFF0EB)),
    ThemeOption('رز', Color(0xFFC2185B), Color(0xFFEC407A), Color(0xFFFFEEF5)),
    ThemeOption('یاسی', Color(0xFF6A1B9A), Color(0xFFAB47BC), Color(0xFFF8EEFF)),
    ThemeOption('لاوندر', Color(0xFF5E35B1), Color(0xFF7E57C2), Color(0xFFF1EEFF)),
    ThemeOption('نیلی', Color(0xFF3949AB), Color(0xFF7986CB), Color(0xFFEEF0FF)),
    ThemeOption('بنفش', Color(0xFF7B1FA2), Color(0xFFBA68C8), Color(0xFFF8EDFF)),
    ThemeOption('قرمز', Color(0xFFC62828), Color(0xFFEF5350), Color(0xFFFFEEEE)),
    ThemeOption('خاکی', Color(0xFF6D4C41), Color(0xFFA1887F), Color(0xFFF8F2EF)),
    ThemeOption('فیروزه‌ای', Color(0xFF00796B), Color(0xFF26A69A), Color(0xFFE9FAF6)),
    ThemeOption('آبی یخی', Color(0xFF1565C0), Color(0xFF42A5F5), Color(0xFFEDF6FF)),
    ThemeOption('سبز تیره', Color(0xFF33691E), Color(0xFF7CB342), Color(0xFFF0F7EC)),
    ThemeOption('توتی', Color(0xFFAD1457), Color(0xFFD81B60), Color(0xFFFFEDF4)),
    ThemeOption('گرافیتی', Color(0xFF37474F), Color(0xFF78909C), Color(0xFFF0F3F5)),
    ThemeOption('شیشه خالص', Color(0xFF536DFE), Color(0xFFB388FF), Color(0xFFEAF0FF)),
  ];

  static ThemeData light(int index, {bool glass = true, double glassOpacity = .62}) {
    final t = themes[index.clamp(0, themes.length - 1).toInt()];
    final scheme = ColorScheme.fromSeed(seedColor: t.primary, brightness: Brightness.light);
    final surface = Colors.white.withValues(alpha: glass ? glassOpacity.clamp(.42, .90) : 1.0);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: t.background,
      fontFamily: 'sans-serif',
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white.withValues(alpha: glass ? .70 : .96),
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: glass ? 1 : 2,
        margin: const EdgeInsets.symmetric(vertical: 5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.white.withValues(alpha: .72)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: glass ? .72 : 1),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: scheme.outline.withValues(alpha: .22))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: scheme.outline.withValues(alpha: .18))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: scheme.primary, width: 2)),
      ),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13))),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12))),
      floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: scheme.primary, foregroundColor: scheme.onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
      dividerTheme: DividerThemeData(color: scheme.outline.withValues(alpha: .16)),
      listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 1)),
    );
  }
}
