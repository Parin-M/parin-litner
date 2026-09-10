import 'package:flutter/material.dart';
import '../../core/models/app_models.dart';
import '../../core/models/app_settings.dart';
import '../../core/utils/helpers.dart';
import '../../core/i18n/app_strings.dart';
import '../../shared/widgets/animated_glass_card.dart';
import '../decks/deck_page.dart';
import '../settings/settings_page.dart';

class HomePage extends StatefulWidget {
  final List<Deck> decks; final VoidCallback onChanged; final Future<void> Function() onImport; final Future<void> Function() onExport; final AppSettings settings;
  const HomePage({super.key, required this.decks, required this.onChanged, required this.onImport, required this.onExport, required this.settings});
  @override State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String s(String k) => AppStrings.t(context, k);
  int get total => widget.decks.fold(0, (n, d) => n + d.cards.length);
  int get due => widget.decks.fold(0, (n, d) => n + dueCount(d));

  @override Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = widget.settings.dailyGoal <= 0 ? 0.0 : (due / widget.settings.dailyGoal).clamp(0.0, 1.0).toDouble();
    return Scaffold(
      appBar: AppBar(title: const Text('Parin Litner', style: TextStyle(fontWeight: FontWeight.w800)), actions: [
        IconButton(onPressed: widget.onImport, icon: const Icon(Icons.file_open_outlined), tooltip: s('import')),
        IconButton(onPressed: widget.onExport, icon: const Icon(Icons.save_alt_outlined), tooltip: s('export')),
        IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsPage(settings: widget.settings, onImport: widget.onImport, onExport: widget.onExport))), icon: const Icon(Icons.tune_outlined), tooltip: s('settings')),
      ]),
      floatingActionButton: FloatingActionButton.extended(onPressed: _newDeck, icon: const Icon(Icons.add_rounded), label: Text(s('new_deck'))),
      body: RefreshIndicator(
        onRefresh: () async { await Future<void>.delayed(const Duration(milliseconds: 120)); if (mounted) setState(() {}); },
        child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.fromLTRB(16, 10, 16, 100), children: [
          AnimatedGlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text(progress >= 1 ? s('goal_done') : s('ready'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))), Icon(progress >= 1 ? Icons.emoji_events_outlined : Icons.school_outlined, color: scheme.primary, size: 30)]),
            const SizedBox(height: 14),
            ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: progress, minHeight: 9)),
            const SizedBox(height: 8),
            Text('$due / ${widget.settings.dailyGoal}   •   $total ${s('cards_count')}', style: TextStyle(color: scheme.onSurfaceVariant)),
          ])),
          const SizedBox(height: 14),
          Row(children: [Expanded(child: _stat(s('cards'), total.toString(), Icons.style_outlined)), const SizedBox(width: 10), Expanded(child: _stat(s('today'), due.toString(), Icons.today_outlined))]),
          const SizedBox(height: 20),
          Text(s('decks'), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)), const SizedBox(height: 10),
          if (widget.decks.isEmpty) AnimatedGlassCard(child: Center(child: Padding(padding: const EdgeInsets.all(18), child: Text(s('no_cards'))))),
          for (final deck in List<Deck>.from(widget.decks)) Padding(padding: const EdgeInsets.only(bottom: 10), child: AnimatedGlassCard(onTap: () async { final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => DeckPage(deck: deck, settings: widget.settings, onChanged: () { if (mounted) setState(() {}); widget.onChanged(); }))); if (result == 'deleted' && mounted) { widget.decks.removeWhere((d) => d.id == deck.id); await widget.onChanged(); setState(() {}); } }, child: Row(children: [CircleAvatar(radius: 27, backgroundColor: _color(deck.colorHex, scheme.primary), child: const Icon(Icons.layers_outlined, color: Colors.white)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(deck.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)), const SizedBox(height: 5), Text('${deck.cards.length} ${s('cards_count')}  •  ${dueCount(deck)} ${s('ready_count')}', style: TextStyle(color: scheme.onSurfaceVariant))])), const Icon(Icons.chevron_left_rounded)]))),
        ]),
      ),
    );
  }

  Widget _stat(String title, String value, IconData icon) => AnimatedGlassCard(child: Row(children: [Icon(icon, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), Text(title, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))]))]));
  Color _color(String raw, Color fallback) { try { final clean = raw.replaceFirst('#',''); return Color(int.parse(clean.length == 6 ? 'FF$clean' : clean, radix: 16)); } catch (_) { return fallback; } }
  Future<void> _newDeck() async { final c = TextEditingController(); final name = await showDialog<String>(context: context, builder: (_) => AlertDialog(title: Text(s('new_deck')), content: TextField(controller: c, autofocus: true, decoration: InputDecoration(labelText: s('new_deck_hint'))), actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(s('cancel'))), FilledButton(onPressed: () => Navigator.pop(context, c.text.trim()), child: Text(s('create')))])); c.dispose(); if (name == null || name.isEmpty) return; widget.decks.add(Deck(id: uid(), name: name)); if (mounted) setState(() {}); await widget.onChanged(); }
}
