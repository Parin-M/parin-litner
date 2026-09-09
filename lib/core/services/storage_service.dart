import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';

class StorageService {
  static const _key = 'parin_litner_v4_data';

  Future<List<Deck>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw) as List;
      return decoded.map((e) => Deck.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<Deck> decks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(decks.map((e) => e.toJson()).toList()));
  }
}
