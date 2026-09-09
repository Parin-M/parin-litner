import 'package:flutter/material.dart';

class AppTheme {
  static const themes = <ThemeOption>[
    ThemeOption('آسمان', Color(0xFF3F51B5), Color(0xFF2196F3)),
    ThemeOption('نعنایی', Color(0xFF00897B), Color(0xFF26A69A)),
    ThemeOption('مرجانی', Color(0xFFE64A19), Color(0xFFFF7043)),
    ThemeOption('رز', Color(0xFFC2185B), Color(0xFFEC407A)),
    ThemeOption('یاسی', Color(0xFF6A1B9A), Color(0xFF8E24AA)),
    ThemeOption('اقیانوس', Color(0xFF0277BD), Color(0xFF00838F)),
    ThemeOption('لیمویی', Color(0xFF689F38), Color(0xFF9E9D24)),
    ThemeOption('طلایی', Color(0xFFEF6C00), Color(0xFFF9A825)),
    ThemeOption('لاوندر', Color(0xFF5E35B1), Color(0xFF3949AB)),
    ThemeOption('شیشه خالص', Color(0xFF536DFE), Color(0xFF7E57C2), pureGlass: true),
  ];

  static ThemeData light(int index, {bool glass = true, double glassOpacity = .62}) {
    final safeIndex = index.clamp(0, themes.length - 1).toInt();
    final selected = themes[safeIndex];
    final seed = selected.primary;
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light);
    final surface = selected.pureGlass ? Colors.white.withValues(alpha: .88) : Colors.white.withValues(alpha: glass ? .94 : 1);

    return ThemeData(
      useMaterial3: false,
      brightness: Brightness.light,
      primaryColor: seed,
      colorScheme: scheme,
      scaffoldBackgroundColor: selected.pureGlass ? const Color(0xFFE9EEF9) : const Color(0xFFF5F5F5),
      fontFamily: 'sans-serif',
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: seed,
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: false,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: selected.pureGlass ? 1 : 2,
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(3)), borderSide: BorderSide(color: Color(0xFFDDDDDD))),
        enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(3)), borderSide: BorderSide(color: Color(0xFFDDDDDD))),
        focusedBorder: OutlineInputBorder(borderRadius: const BorderRadius.all(Radius.circular(3)), borderSide: BorderSide(color: seed, width: 2)),
        labelStyle: const TextStyle(color: Color(0xFF666666)),
      ),
      dividerTheme: const DividerThemeData(thickness: 1, space: 1),
      listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2), dense: false),
      floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: seed, foregroundColor: Colors.white, elevation: 6, shape: const CircleBorder()),
      buttonTheme: ButtonThemeData(buttonColor: seed, textTheme: ButtonTextTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)), materialTapTargetSize: MaterialTapTargetSize.padded),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: seed, foregroundColor: Colors.white, elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12))),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(foregroundColor: seed, side: BorderSide(color: seed.withValues(alpha: .5)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11))),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: seed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)))),
      switchTheme: SwitchThemeData(trackColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.selected) ? seed.withValues(alpha: .45) : Colors.black26), thumbColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.selected) ? seed : Colors.white)),
      sliderTheme: SliderThemeData(activeTrackColor: seed, thumbColor: seed, overlayColor: seed.withValues(alpha: .12)),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: seed),
    );
  }
}

class ThemeOption {
  final String name;
  final Color primary;
  final Color secondary;
  final bool pureGlass;
  const ThemeOption(this.name, this.primary, this.secondary, {this.pureGlass = false});
}
