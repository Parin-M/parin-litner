import 'package:flutter/material.dart';
import '../../core/models/app_models.dart';
import '../../core/models/app_settings.dart';
import '../../core/utils/helpers.dart';
import '../../shared/widgets/animated_glass_card.dart';
import '../decks/deck_page.dart';
import '../settings/settings_page.dart';

class HomePage extends StatelessWidget {
  final List<Deck> decks; final VoidCallback onChanged; final Future<void> Function() onImport; final Future<void> Function() onExport; final AppSettings settings;
  const HomePage({super.key, required this.decks, required this.onChanged, required this.onImport, required this.onExport, required this.settings});

  @override Widget build(BuildContext context) {
    final total = decks.fold<int>(0, (sum, deck) => sum + deck.cards.length);
    final due = decks.fold<int>(0, (sum, deck) => sum + dueCount(deck));
    return PageReveal(child: Scaffold(
      appBar: AppBar(title: const Text('Parin Litner', style: TextStyle(fontWeight: FontWeight.w900)), actions: [
        IconButton(onPressed: onImport, icon: const Icon(Icons.file_download_outlined), tooltip: 'وارد کردن فایل'),
        IconButton(onPressed: onExport, icon: const Icon(Icons.file_upload_outlined), tooltip: 'خروجی گرفتن'),
        IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsPage(settings: settings, onImport: onImport, onExport: onExport))), icon: const Icon(Icons.tune_rounded), tooltip: 'تنظیمات'),
      ],),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _newDeck(context), icon: const Icon(Icons.create_new_folder_rounded), label: const Text('دسته جدید')),
      body: ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 100), children: [
        _HeroBanner(total: total, due: due, goal: settings.dailyGoal), const SizedBox(height: 14),
        Row(children: [Expanded(child: _Stat('کارت‌ها', '$total', Icons.style_rounded)), const SizedBox(width: 10), Expanded(child: _Stat('امروز', '$due', Icons.bolt_rounded))]),
        const SizedBox(height: 18), const Text('دسته‌های یادگیری', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 12),
        if (decks.isEmpty) const AnimatedGlassCard(child: Padding(padding: EdgeInsets.all(22), child: Text('هنوز دسته‌ای نساخته‌ای. از دکمه «دسته جدید» شروع کن.', textAlign: TextAlign.center))),
        ...decks.map((deck) => Padding(padding: const EdgeInsets.only(bottom: 12), child: AnimatedGlassCard(onTap: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => DeckPage(deck: deck, onChanged: onChanged, settings: settings)));
          if (result == 'deleted') decks.removeWhere((d) => d.id == deck.id);
          onChanged();
        }, child: _deckTile(context, deck)))),
      ]),
    ));
  }

  Widget _deckTile(BuildContext context, Deck deck) { final color = Color(int.parse('FF${deck.colorHex}', radix: 16)); final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: .58); return Row(children: [Container(width: 54, height: 54, decoration: BoxDecoration(gradient: LinearGradient(colors: [color, Theme.of(context).colorScheme.primary]), borderRadius: BorderRadius.circular(17)), child: const Icon(Icons.layers_rounded, color: Colors.white)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(deck.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text('${deck.cards.length} کارت • ${dueCount(deck)} کارت آماده مرور', style: TextStyle(color: muted))])), const Icon(Icons.chevron_left_rounded)]); }

  Future<void> _newDeck(BuildContext context) async { final controller = TextEditingController(); final name = await showDialog<String>(context: context, builder: (_) => AlertDialog(title: const Text('دسته جدید'), content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'نام دسته')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('لغو')), FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('ساختن'))])); controller.dispose(); if (name == null || name.isEmpty) return; decks.add(Deck(id: uid(), name: name)); onChanged(); }
}

class _HeroBanner extends StatelessWidget { final int total; final int due; final int goal; const _HeroBanner({required this.total, required this.due, required this.goal}); @override Widget build(BuildContext context) { final primary = Theme.of(context).colorScheme.primary; final progress = goal <= 0 ? 0.0 : (due / goal).clamp(0.0, 1.0).toDouble(); return AnimatedGlassCard(child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [primary.withValues(alpha: .14), primary.withValues(alpha: .03)]), borderRadius: BorderRadius.circular(18)), padding: const EdgeInsets.all(16), child: Row(children: [Stack(alignment: Alignment.center, children: [SizedBox(width: 64, height: 64, child: CircularProgressIndicator(value: progress, strokeWidth: 7, backgroundColor: primary.withValues(alpha: .10))), Icon(progress >= 1 ? Icons.emoji_events_rounded : Icons.auto_awesome_rounded, color: primary, size: 28)]), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(progress >= 1 ? 'هدف امروز کامل شد! 🎉' : 'آماده‌ی یک مرور کوتاه؟', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)), const SizedBox(height: 5), Text('$due از $goal کارت امروز • مجموع $total کارت', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .60)))]))]))); } }
class _Stat extends StatelessWidget { final String title; final String value; final IconData icon; const _Stat(this.title, this.value, this.icon); @override Widget build(BuildContext context) => AnimatedGlassCard(child: Row(children: [Icon(icon, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)), Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .58)))])])); }
