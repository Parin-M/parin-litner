import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/models/app_models.dart';
import '../../core/models/app_settings.dart';
import '../../core/utils/helpers.dart';
import '../../core/i18n/app_strings.dart';
import '../../shared/widgets/animated_glass_card.dart';
import '../cards/card_editor.dart';
import '../study/study_page.dart';

class DeckPage extends StatefulWidget {
  final Deck deck; final VoidCallback onChanged; final AppSettings settings;
  const DeckPage({super.key, required this.deck, required this.onChanged, required this.settings});
  @override State<DeckPage> createState() => _DeckPageState();
}

class _DeckPageState extends State<DeckPage> {
  String query = '';
  String s(String key) => AppStrings.t(context, key);

  @override Widget build(BuildContext context) {
    final currentDeck = widget.deck;
    final normalizedQuery = query.trim().toLowerCase();
    final cards = currentDeck.cards.where((card) => normalizedQuery.isEmpty || '${card.front} ${card.back} ${card.tags}'.toLowerCase().contains(normalizedQuery)).toList();
    return Scaffold(
      appBar: AppBar(title: Text(currentDeck.name), actions: [
        IconButton(onPressed: _editDeck, icon: const Icon(Icons.edit_rounded), tooltip: s('rename')),
        IconButton(onPressed: _boxes, icon: const Icon(Icons.view_module_rounded), tooltip: s('boxes')),
        IconButton(onPressed: _deleteDeck, icon: const Icon(Icons.delete_outline_rounded), tooltip: s('delete')),
      ]),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _editCard(), icon: const Icon(Icons.add_rounded), label: Text(s('new_card'))),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [
        Row(children: [Expanded(child: TextField(onChanged: (value) => setState(() => query = value), decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: s('search')))), const SizedBox(width: 10), FilledButton.tonalIcon(onPressed: _study, icon: const Icon(Icons.play_arrow_rounded), label: Text(s('study')))]),
        const SizedBox(height: 16),
        SizedBox(height: 104, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: currentDeck.boxes.length, separatorBuilder: (_, __) => const SizedBox(width: 10), itemBuilder: (_, i) { final box = currentDeck.boxes[i]; final count = currentDeck.cards.where((c) => c.boxIndex == i).length; return SizedBox(width: 120, child: AnimatedGlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.inventory_2_rounded, color: boxColor(box)), const Spacer(), Text(box.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)), Text('$count ${s('cards_count')}')]))); })),
        const SizedBox(height: 16),
        if (cards.isEmpty) Padding(padding: const EdgeInsets.all(30), child: Center(child: Text(s('no_cards')))),
        ...cards.map((card) { final boxIndex = currentDeck.boxes.isEmpty ? 0 : min(card.boxIndex, currentDeck.boxes.length - 1); final boxName = currentDeck.boxes.isEmpty ? s('box') : currentDeck.boxes[boxIndex].name; return Padding(padding: const EdgeInsets.only(bottom: 10), child: AnimatedGlassCard(onTap: () => _editCard(card), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(card.front.isEmpty ? '🖼️' : card.front, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), const SizedBox(height: 5), Text(card.back.isEmpty ? '🖼️' : card.back, maxLines: 2, overflow: TextOverflow.ellipsis), const SizedBox(height: 7), Text('$boxName • ${card.tags}', style: const TextStyle(fontSize: 12))])), IconButton(onPressed: () { card.favorite = !card.favorite; setState(() {}); widget.onChanged(); }, icon: Icon(card.favorite ? Icons.star_rounded : Icons.star_border_rounded, color: card.favorite ? Colors.amber : null))]))); }),
      ]),
    );
  }

  Future<void> _deleteDeck() async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: Text('${s('delete')}؟'), content: Text('${currentName()}\n\n${widget.deck.cards.length} ${s('cards_count')}'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s('cancel'))), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(s('delete')))]));
    if (ok == true && mounted) Navigator.pop(context, 'deleted');
  }

  String currentName() => widget.deck.name;

  Future<void> _editDeck() async {
    final controller = TextEditingController(text: widget.deck.name);
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: Text(s('rename')), content: TextField(controller: controller, decoration: InputDecoration(labelText: s('new_deck_hint'))), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s('cancel'))), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(s('save')))]));
    final name = controller.text.trim(); controller.dispose();
    if (ok == true && name.isNotEmpty) { widget.deck.name = name; setState(() {}); widget.onChanged(); }
  }

  Future<void> _editCard([FlashCard? card]) async { final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => CardEditor(deck: widget.deck, card: card))); if (changed == true && mounted) { setState(() {}); widget.onChanged(); } }

  Future<void> _study() async {
    final currentDeck = widget.deck;
    final mode = await showModalBottomSheet<String>(context: context, showDragHandle: true, builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 12), child: Align(alignment: AlignmentDirectional.centerStart, child: Text(s('study_type'), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)))), ListTile(leading: const Icon(Icons.bolt_rounded), title: Text(s('cards_ready')), subtitle: Text('${currentDeck.cards.where((c) => !c.dueAt.isAfter(DateTime.now())).length} ${s('cards_count')}'), onTap: () => Navigator.pop(context, 'due')), ListTile(leading: const Icon(Icons.all_inclusive_rounded), title: Text(s('all')), subtitle: Text('${currentDeck.cards.length} ${s('cards_count')}'), onTap: () => Navigator.pop(context, 'all')), ListTile(leading: const Icon(Icons.star_rounded), title: Text(s('favorite_only')), subtitle: Text('${currentDeck.cards.where((c) => c.favorite).length} ${s('cards_count')}'), onTap: () => Navigator.pop(context, 'favorites'))])));
    if (!mounted || mode == null) return;
    final now = DateTime.now();
    final selected = mode == 'all' ? [...currentDeck.cards] : mode == 'favorites' ? currentDeck.cards.where((c) => c.favorite).toList() : currentDeck.cards.where((c) => !c.dueAt.isAfter(now)).toList();
    if (selected.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s('no_review')))); return; }
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => StudyPage(deck: widget.deck, settings: widget.settings, studyCards: selected, onChanged: () { setState(() {}); widget.onChanged(); })));
  }

  Future<void> _boxes() async { await showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (_) => BoxManager(deck: widget.deck, onChanged: () { setState(() {}); widget.onChanged(); })); }
}

class BoxManager extends StatefulWidget { final Deck deck; final VoidCallback onChanged; const BoxManager({super.key, required this.deck, required this.onChanged}); @override State<BoxManager> createState() => _BoxManagerState(); }
class _BoxManagerState extends State<BoxManager> {
  String s(String key) => AppStrings.t(context, key);
  Future<void> _rename(int index) async { final controller = TextEditingController(text: widget.deck.boxes[index].name); final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: Text(s('rename')), content: TextField(controller: controller), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s('cancel'))), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(s('save')))])); final name = controller.text.trim(); controller.dispose(); if (ok == true && name.isNotEmpty) { widget.deck.boxes[index].name = name; setState(() {}); widget.onChanged(); } }
  void _add() { final index = widget.deck.boxes.length; widget.deck.boxes.add(LeitnerBox(id: uid(), name: '${s('box')} ${index + 1}', colorValue: Colors.primaries[index % Colors.primaries.length].value)); setState(() {}); widget.onChanged(); }
  Future<void> _delete(int index) async { if (widget.deck.boxes.length <= 1) return; final removed = widget.deck.boxes.removeAt(index); for (final card in widget.deck.cards) { if (card.boxIndex == index) card.boxIndex = 0; else if (card.boxIndex > index) card.boxIndex--; } setState(() {}); widget.onChanged(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${removed.name} ${s('delete')}'))); }
  @override Widget build(BuildContext context) => SafeArea(child: Padding(padding: const EdgeInsets.all(18), child: Column(mainAxisSize: MainAxisSize.min, children: [Row(children: [Expanded(child: Text(s('boxes'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))), IconButton(onPressed: _add, icon: const Icon(Icons.add_circle_rounded))]), const SizedBox(height: 10), Flexible(child: ListView.builder(shrinkWrap: true, itemCount: widget.deck.boxes.length, itemBuilder: (_, index) { final box = widget.deck.boxes[index]; final count = widget.deck.cards.where((card) => card.boxIndex == index).length; return ListTile(leading: CircleAvatar(backgroundColor: boxColor(box), child: Text('${index + 1}')), title: Text(box.name), subtitle: Text('$count ${s('cards_count')}'), trailing: Wrap(children: [IconButton(onPressed: () => _rename(index), icon: const Icon(Icons.edit_rounded)), IconButton(onPressed: () => _delete(index), icon: const Icon(Icons.delete_outline_rounded))])); }))])));
}
