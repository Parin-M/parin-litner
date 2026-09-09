import 'package:flutter/material.dart';
import '../../core/models/app_models.dart';
import '../../core/utils/helpers.dart';
import '../../shared/widgets/animated_glass_card.dart';
import '../decks/deck_page.dart';
import '../settings/settings_page.dart';

class HomePage extends StatelessWidget {
  final List<Deck> decks;
  final VoidCallback onChanged;
  final Future<void> Function() onImport;
  final Future<void> Function() onExport;
  const HomePage({super.key, required this.decks, required this.onChanged, required this.onImport, required this.onExport});

  @override
  Widget build(BuildContext context) {
    final total = decks.fold<int>(0, (s, d) => s + d.cards.length);
    final due = decks.fold<int>(0, (s, d) => s + dueCount(d));
    return PageReveal(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Parin Litner', style: TextStyle(fontWeight: FontWeight.w900)),
          actions: [
            IconButton(onPressed: onImport, icon: const Icon(Icons.file_download_outlined), tooltip: 'Import'),
            IconButton(onPressed: onExport, icon: const Icon(Icons.file_upload_outlined), tooltip: 'Export'),
            IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())), icon: const Icon(Icons.tune_rounded)),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _newDeck(context),
          icon: const Icon(Icons.create_new_folder_rounded),
          label: const Text('دسته جدید'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
          children: [
            Row(children: [Expanded(child: _Stat('کارت‌ها', '$total', Icons.style_rounded)), const SizedBox(width: 10), Expanded(child: _Stat('امروز', '$due', Icons.bolt_rounded))]),
            const SizedBox(height: 16),
            const Text('دسته‌های یادگیری', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            if (decks.isEmpty) const AnimatedGlassCard(child: Padding(padding: EdgeInsets.all(22), child: Text('هنوز دسته‌ای نساخته‌ای. از دکمه «دسته جدید» شروع کن.', textAlign: TextAlign.center))),
            ...decks.map((d) => Padding(padding: const EdgeInsets.only(bottom: 12), child: AnimatedGlassCard(onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => DeckPage(deck: d, onChanged: onChanged))); onChanged(); }, child: _deckTile(d))))),
          ],
        ),
      ),
    );
  }

  Widget _deckTile(Deck d) => Row(children: [
        Container(width: 54, height: 54, decoration: BoxDecoration(color: Color(int.parse('FF${d.colorHex}', radix: 16)), borderRadius: BorderRadius.circular(17)), child: const Icon(Icons.layers_rounded)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(d.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text('${d.cards.length} کارت • ${dueCount(d)} کارت آماده مرور', style: const TextStyle(color: Colors.white60))])),
        const Icon(Icons.chevron_left_rounded),
      ]);

  Future<void> _newDeck(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(context: context, builder: (_) => AlertDialog(title: const Text('دسته جدید'), content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'نام دسته')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('لغو')), FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('ساختن'))]));
    if (name == null || name.isEmpty) return;
    decks.add(Deck(id: uid(), name: name));
    onChanged();
  }
}

class _Stat extends StatelessWidget {
  final String title, value; final IconData icon;
  const _Stat(this.title, this.value, this.icon);
  @override Widget build(BuildContext context) => AnimatedGlassCard(child: Row(children: [Icon(icon, color: const Color(0xFF9A92FF)), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)), Text(title, style: const TextStyle(color: Colors.white60))])]));
}
