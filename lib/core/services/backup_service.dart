import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import '../models/app_models.dart';

class BackupService {
  Future<bool> exportDecks(List<Deck> decks) async {
    final payload = {
      'app': 'Parin Litner',
      'format': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'decks': decks.map((e) => e.toJson()).toList(),
    };
    final bytes = Uint8List.fromList(utf8.encode(const JsonEncoder.withIndent('  ').convert(payload)));
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'ذخیره پشتیبان Parin Litner',
      fileName: 'parin_litner_backup.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: bytes,
    );
    return path != null;
  }

  Future<List<Deck>?> importDecks() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json'], withData: true);
    if (result == null || result.files.single.bytes == null) return null;
    final text = utf8.decode(result.files.single.bytes!);
    final decoded = jsonDecode(text) as Map<String, dynamic>;
    final list = (decoded['decks'] as List?) ?? [];
    return list.map((e) => Deck.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }
}
