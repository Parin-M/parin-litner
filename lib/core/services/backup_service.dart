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

    final bytes = Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(payload)),
    );

    // file_picker 12 uses static facade methods rather than FilePicker.platform.
    final output = await FilePicker.saveFile(
      dialogTitle: 'ذخیره پشتیبان Parin Litner',
      fileName: 'parin_litner_backup.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: bytes,
      mimeType: 'application/json',
    );

    return output != null;
  }

  Future<List<Deck>?> importDecks() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (files.isEmpty) return null;

    final file = files.first;
    final bytes = await file.readAsBytes();
    final text = utf8.decode(bytes);
    final decoded = jsonDecode(text) as Map<String, dynamic>;
    final list = (decoded['decks'] as List?) ?? const [];

    return list
        .map((e) => Deck.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
