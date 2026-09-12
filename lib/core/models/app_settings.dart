import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguage {
  final String code;
  final String name;
  final String nativeName;
  final bool rtl;
  const AppLanguage(this.code, this.name, this.nativeName, {this.rtl = false});
}

class AppSettings extends ChangeNotifier {
  static const languages = <AppLanguage>[
    AppLanguage('fa', 'Persian', 'فارسی', rtl: true),
    AppLanguage('en', 'English', 'English'),
    AppLanguage('de', 'German', 'Deutsch'),
    AppLanguage('de-CH', 'Swiss German', 'Deutsch (Schweiz)'),
    AppLanguage('de-AT', 'Austrian German', 'Deutsch (Österreich)'),
    AppLanguage('nl', 'Dutch', 'Nederlands'),
    AppLanguage('es', 'Spanish', 'Español'),
    AppLanguage('pt', 'Portuguese', 'Português'),
    AppLanguage('fr', 'French', 'Français'),
    AppLanguage('da', 'Danish', 'Dansk'),
    AppLanguage('no', 'Norwegian', 'Norsk'),
    AppLanguage('fi', 'Finnish', 'Suomi'),
    AppLanguage('sv', 'Swedish', 'Svenska'),
    AppLanguage('is', 'Icelandic', 'Íslenska'),
    AppLanguage('el', 'Greek', 'Ελληνικά'),
    AppLanguage('ar', 'Arabic', 'العربية', rtl: true),
    AppLanguage('he', 'Hebrew', 'עברית', rtl: true),
    AppLanguage('ja', 'Japanese', '日本語'),
    AppLanguage('ko', 'Korean', '한국어'),
    AppLanguage('it', 'Italian', 'Italiano'),
    AppLanguage('tr', 'Turkish', 'Türkçe'),
  ];

  static const musicTrackIds = <String>{'lofi_night', 'rainy_focus', 'deep_focus'};

  int themeIndex = 0;
  String languageCode = 'fa';
  bool animations = true, haptics = true, autoReveal = false, showProgress = true, showTimer = true, glass = true;
  double glassOpacity = .62;
  int dailyGoal = 20;
  bool musicEnabled = false;
  String musicTrack = 'lofi_night';
  double musicVolume = .35;

  AppLanguage get language => languages.firstWhere((x) => x.code == languageCode, orElse: () => languages.first);
  Locale get locale {
    final p = languageCode.split('-');
    return Locale.fromSubtags(languageCode: p.first, countryCode: p.length > 1 ? p[1] : null);
  }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    themeIndex = (p.getInt('theme_index') ?? 0).clamp(0, 19).toInt();
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
    musicEnabled = p.getBool('music_enabled') ?? false;
    musicTrack = p.getString('music_track') ?? 'lofi_night';
    if (!musicTrackIds.contains(musicTrack)) musicTrack = 'lofi_night';
    musicVolume = p.getDouble('music_volume') ?? .35;
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
    themeIndex = value.clamp(0, 19).toInt();
    final p = await SharedPreferences.getInstance();
    await p.setInt('theme_index', themeIndex);
    notifyListeners();
  }

  Future<void> setBool(String key, bool value) async {
    switch (key) {
      case 'animations': animations = value; break;
      case 'haptics': haptics = value; break;
      case 'auto_reveal': autoReveal = value; break;
      case 'show_progress': showProgress = value; break;
      case 'show_timer': showTimer = value; break;
      case 'glass': glass = value; break;
      case 'music_enabled': musicEnabled = value; break;
    }
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, value);
    notifyListeners();
  }

  Future<void> setGlassOpacity(double v) async {
    glassOpacity = v.clamp(.30, .90).toDouble();
    await (await SharedPreferences.getInstance()).setDouble('glass_opacity', glassOpacity);
    notifyListeners();
  }

  Future<void> setDailyGoal(int v) async {
    dailyGoal = v.clamp(5, 100).toInt();
    await (await SharedPreferences.getInstance()).setInt('daily_goal', dailyGoal);
    notifyListeners();
  }

  Future<void> setMusicTrack(String v) async {
    if (!musicTrackIds.contains(v)) return;
    musicTrack = v;
    await (await SharedPreferences.getInstance()).setString('music_track', v);
    notifyListeners();
  }

  Future<void> setMusicVolume(double v) async {
    musicVolume = v.clamp(0, 1).toDouble();
    await (await SharedPreferences.getInstance()).setDouble('music_volume', musicVolume);
    notifyListeners();
  }
}
