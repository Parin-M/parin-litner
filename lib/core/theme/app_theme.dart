import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF080D19),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF766CFF), brightness: Brightness.dark),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(.055),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      );
}
