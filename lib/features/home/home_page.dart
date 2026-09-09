import 'package:flutter/material.dart';
import '../../core/models/app_models.dart';
import '../../core/models/app_settings.dart';
import '../../core/utils/helpers.dart';
import '../../core/i18n/app_strings.dart';
import '../../shared/widgets/animated_glass_card.dart';
import '../decks/deck_page.dart';
import '../settings/settings_page.dart';

class HomePage extends StatefulWidget {
  final List<Deck> decks;
  final VoidCallback onChanged;
  final Future<void> Function() onImport;
  final Future<void> Function() onExport;
  final AppSettings settings;
  const HomePage({super.key, required this.decks, required this.onChanged, required this.onImport, required this.onExport, required this.settings});
  @override State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String query = '';
  String s(String key) => AppStrings.t(context, key);

  @override
  Widget build(BuildContext context) {
    final total = widget.decks.fold<int>(0, (sum, deck) => sum + deck.cards.length);
    final due = widget.decks.fold<int>(0, (sum, deck) => sum + dueCount(deck));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parin Litner'),
        actions: [
          IconButton(onPressed: widget.onImport, icon: const Icon(Icons.file_download), tooltip: s('import')),
          IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsPage(settings: widget.settings, onImport: widget.onImport, onExport: widget.onExport))), icon: const Icon(Icons.settings), tooltip: s('settings')),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _newDeck(context), child: const Icon(Icons.add)),
      body: RefreshIndicator(
        onRefresh: () async { setState(() {}); },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 90),
          children: [
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Row(children: [Expanded(child: Text(due == 0 ? s('ready') : s('cards_ready'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600))), Icon(Icons.school_outlined, color: Theme.of(context).colorScheme.primary)]),
              const SizedBox(height: 14),
              LinearProgressIndicator(value: widget.settings.dailyGoal <= 0 ? 0 : (due / widget.settings.dailyGoal).clamp(0.0, 1.0).toDouble(), minHeight: 7),
              const SizedBox(height: 8),
              Text('$due / ${widget.settings.dailyGoal}    •    $total ${s('cards_count')}', style: TextStyle(color: Theme.of(context).hintColor)),
            ]))),
            const SizedBox(height: 6),
            Row(children: [Expanded(child: _stat(s('cards'), '$total', Icons.style_outlined)), const SizedBox(width: 8), Expanded(child: _stat(s('today'), '$due', Icons.today_outlined))]),
            const SizedBox(height: 16),
            Text(s('decks'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            if (widget.decks.isEmpty) Card(child: Padding(padding: const EdgeInsets.all(24), child: Center(child: Text(s('no_cards'))))),
            ...widget.decks.map((deck) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () async {
                    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => DeckPage(deck: deck, onChanged: () { if (mounted) setState(() {}); widget.onChanged(); }, settings: widget.settings)));
                    if (!mounted) return;
                    if (result == 'deleted') widget.decks.removeWhere((d) => d.id == deck.id);
                    setState(() {});
                    widget.onChanged();
                  },
                  child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
                    CircleAvatar(backgroundColor: _safeDeckColor(deck.colorHex), radius: 26, child: const Icon(Icons.layers_outlined, color: Colors.white)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(deck.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)), const SizedBox(height: 4), Text('${deck.cards.length} ${s('cards_count')}  •  ${dueCount(deck)} ${s('ready_count')}', style: TextStyle(color: Theme.of(context).hintColor))])),
                    const Icon(Icons.chevron_left),
                  ])),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _stat(String title, String value, IconData icon) => Card(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14), child: Row(children: [Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)), Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).hintColor))]))])));

  Color _safeDeckColor(String value) {
    try { return Color(int.parse('FF${value.replaceFirst('#', '')}', radix: 16)); } catch (_) { return Theme.of(context).colorScheme.primary; }
  }

  Future<void> _newDeck(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(context: context, builder: (_) => AlertDialog(title: Text(s('new_deck')), content: TextField(controller: controller, autofocus: true, decoration: InputDecoration(labelText: s('new_deck_hint'))), actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(s('cancel'))), ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text(s('build')))]));
    controller.dispose();
    if (name == null || name.isEmpty) return;
    widget.decks.add(Deck(id: uid(), name: name));
    setState(() {});
    widget.onChanged();
  }
}
