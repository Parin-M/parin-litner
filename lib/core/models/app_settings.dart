import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguage {
  final String code;
  final String name;
  final bool rtl;
  const AppLanguage(this.code, this.name, {this.rtl = false});
}

class AppSettings extends ChangeNotifier {
  static const languages = <AppLanguage>[
    AppLanguage('fa', 'فارسی', rtl: true),
    AppLanguage('en', 'English'),
    AppLanguage('da', 'Dansk'),
    AppLanguage('de', 'Deutsch'),
    AppLanguage('de-CH', 'Schweizerdeutsch'),
    AppLanguage('de-AT', 'Österreichisches Deutsch'),
    AppLanguage('nl', 'Nederlands'),
    AppLanguage('es', 'Español'),
    AppLanguage('pt', 'Português'),
    AppLanguage('ar', 'العربية', rtl: true),
    AppLanguage('fi', 'Suomi'),
    AppLanguage('no', 'Norsk'),
    AppLanguage('fr', 'Français'),
    AppLanguage('ja', '日本語'),
    AppLanguage('he', 'עברית', rtl: true),
  ];

  int themeIndex = 0;
  String languageCode = 'fa';
  bool animations = true;
  bool haptics = true;
  bool autoReveal = false;
  bool showProgress = true;
  bool showTimer = true;
  bool glass = true;
  double glassOpacity = .62;
  int dailyGoal = 20;

  AppLanguage get language => languages.firstWhere((x) => x.code == languageCode, orElse: () => languages.first);

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    themeIndex = (p.getInt('theme_index') ?? 0).clamp(0, 8).toInt();
    languageCode = p.getString('language_code') ?? 'fa';
    if (!languages.any((x) => x.code == languageCode)) languageCode = 'fa';
    animations = p.getBool('animations') ?? true;
    haptics = p.getBool('haptics') ?? true;
    autoReveal = p.getBool('auto_reveal') ?? false;
    showProgress = p.getBool('show_progress') ?? true;
    showTimer = p.getBool('show_timer') ?? true;
    glass = p.getBool('glass') ?? true;
    glassOpacity = p.getDouble('glass_opacity') ?? .62;
    dailyGoal = p.getInt('daily_goal') ?? 20;
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    if (!languages.any((x) => x.code == value)) return;
    languageCode = value;
    final p = await SharedPreferences.getInstance();
    await p.setString('language_code', value);
    notifyListeners();
  }

  Future<void> setTheme(int value) async {
    themeIndex = value.clamp(0, 8).toInt();
    final p = await SharedPreferences.getInstance();
    await p.setInt('theme_index', themeIndex);
    notifyListeners();
  }

  Future<void> setBool(String key, bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, value);
    switch (key) {
      case 'animations': animations = value; break;
      case 'haptics': haptics = value; break;
      case 'auto_reveal': autoReveal = value; break;
      case 'show_progress': showProgress = value; break;
      case 'show_timer': showTimer = value; break;
      case 'glass': glass = value; break;
    }
    notifyListeners();
  }

  Future<void> setGlassOpacity(double value) async {
    glassOpacity = value;
    final p = await SharedPreferences.getInstance();
    await p.setDouble('glass_opacity', value);
    notifyListeners();
  }

  Future<void> setDailyGoal(int value) async {
    dailyGoal = value;
    final p = await SharedPreferences.getInstance();
    await p.setInt('daily_goal', value);
    notifyListeners();
  }
}
