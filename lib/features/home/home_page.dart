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
  String s(String key) => AppStrings.t(context, key);

  @override
  Widget build(BuildContext context) {
    final total = widget.decks.fold<int>(0, (sum, deck) => sum + deck.cards.length);
    final due = widget.decks.fold<int>(0, (sum, deck) => sum + dueCount(deck));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parin Litner', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(onPressed: widget.onImport, icon: const Icon(Icons.file_download_outlined), tooltip: s('import')),
          IconButton(onPressed: widget.onExport, icon: const Icon(Icons.file_upload_outlined), tooltip: s('export')),
          IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsPage(settings: widget.settings, onImport: widget.onImport, onExport: widget.onExport))), icon: const Icon(Icons.tune_rounded), tooltip: s('settings')),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _newDeck(context), icon: const Icon(Icons.create_new_folder_rounded), label: Text(s('new_deck'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
        children: [
          _HeroBanner(total: total, due: due, goal: widget.settings.dailyGoal),
          const SizedBox(height: 14),
          Row(children: [Expanded(child: _Stat(s('cards'), '$total', Icons.style_rounded)), const SizedBox(width: 10), Expanded(child: _Stat(s('today'), '$due', Icons.bolt_rounded))]),
          const SizedBox(height: 18),
          Text(s('decks'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          if (widget.decks.isEmpty) AnimatedGlassCard(child: Padding(padding: const EdgeInsets.all(22), child: Text(s('no_cards'), textAlign: TextAlign.center))),
          ...widget.decks.map((deck) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AnimatedGlassCard(
              onTap: () async {
                final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => DeckPage(deck: deck, onChanged: () { if (mounted) setState(() {}); widget.onChanged(); }, settings: widget.settings)));
                if (!mounted) return;
                if (result == 'deleted') widget.decks.removeWhere((d) => d.id == deck.id);
                setState(() {});
                widget.onChanged();
              },
              child: _deckTile(context, deck),
            ),
          )),
        ],
      ),
    );
  }

  Widget _deckTile(BuildContext context, Deck deck) {
    final color = _safeDeckColor(deck.colorHex);
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: .58);
    return Row(children: [
      Container(width: 54, height: 54, decoration: BoxDecoration(gradient: LinearGradient(colors: [color, Theme.of(context).colorScheme.primary]), borderRadius: BorderRadius.circular(17)), child: const Icon(Icons.layers_rounded, color: Colors.white)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(deck.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text('${deck.cards.length} ${s('cards_count')} • ${dueCount(deck)} ${s('ready_count')}', style: TextStyle(color: muted))])),
      const Icon(Icons.chevron_left_rounded),
    ]);
  }

  Color _safeDeckColor(String value) {
    try { return Color(int.parse('FF${value.replaceFirst('#', '')}', radix: 16)); } catch (_) { return Theme.of(context).colorScheme.primary; }
  }

  Future<void> _newDeck(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(context: context, builder: (_) => AlertDialog(title: Text(s('new_deck')), content: TextField(controller: controller, autofocus: true, decoration: InputDecoration(labelText: s('new_deck_hint'))), actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(s('cancel'))), FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text(s('build')))]));
    controller.dispose();
    if (name == null || name.isEmpty) return;
    widget.decks.add(Deck(id: uid(), name: name));
    setState(() {});
    widget.onChanged();
  }
}

class _HeroBanner extends StatelessWidget {
  final int total; final int due; final int goal;
  const _HeroBanner({required this.total, required this.due, required this.goal});
  @override Widget build(BuildContext context) {
    final s = (String key) => AppStrings.t(context, key);
    final primary = Theme.of(context).colorScheme.primary;
    final progress = goal <= 0 ? 0.0 : (due / goal).clamp(0.0, 1.0).toDouble();
    return AnimatedGlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(progress >= 1 ? Icons.emoji_events_rounded : Icons.auto_awesome_rounded, color: primary, size: 30), const SizedBox(width: 12), Expanded(child: Text(progress >= 1 ? s('goal_done') : s('learn_ready'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)))]),
      const SizedBox(height: 12),
      ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: progress, minHeight: 9, backgroundColor: primary.withValues(alpha: .10), valueColor: AlwaysStoppedAnimation(primary))),
      const SizedBox(height: 8),
      Text('$due / $goal • $total ${s('cards_count')}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .60))),
    ]));
  }
}

class _Stat extends StatelessWidget { final String title; final String value; final IconData icon; const _Stat(this.title, this.value, this.icon); @override Widget build(BuildContext context) => AnimatedGlassCard(child: Row(children: [Icon(icon, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)), Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .58)))])])); }
