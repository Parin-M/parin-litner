import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/models/app_models.dart';
import '../../core/models/app_settings.dart';
import '../../core/utils/helpers.dart';
import '../../core/i18n/app_strings.dart';
import '../cards/card_editor.dart';
import '../study/study_page.dart';

class DeckPage extends StatefulWidget {
  final Deck deck;
  final VoidCallback onChanged;
  final AppSettings settings;
  const DeckPage({super.key, required this.deck, required this.onChanged, required this.settings});
  @override State<DeckPage> createState() => _DeckPageState();
}

class _DeckPageState extends State<DeckPage> {
  String query = '';
  String s(String key) => AppStrings.t(context, key);

  @override
  Widget build(BuildContext context) {
    final deck = widget.deck;
    final normalized = query.trim().toLowerCase();
    final cards = deck.cards.where((card) {
      if (normalized.isEmpty) return true;
      return '${card.front} ${card.back} ${card.tags}'.toLowerCase().contains(normalized);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(deck.name), actions: [
        IconButton(onPressed: _editDeck, icon: const Icon(Icons.edit), tooltip: s('rename')),
        IconButton(onPressed: _boxes, icon: const Icon(Icons.view_module), tooltip: s('boxes')),
        IconButton(onPressed: _deleteDeck, icon: const Icon(Icons.delete_outline), tooltip: s('delete')),
      ]),
      floatingActionButton: FloatingActionButton(onPressed: () => _editCard(), child: const Icon(Icons.add)),
      body: SafeArea(child: ListView(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 80),
        children: [
          Row(children: [
            Expanded(child: TextField(onChanged: (v) => setState(() => query = v), decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: s('search')))),
            const SizedBox(width: 8),
            ElevatedButton.icon(onPressed: _study, icon: const Icon(Icons.play_arrow), label: Text(s('study'))),
          ]),
          const SizedBox(height: 10),
          SizedBox(height: 92, child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: max(1, deck.boxes.length),
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              if (deck.boxes.isEmpty) return SizedBox(width: 110, child: Card(child: Center(child: Text(s('box')))));
              final box = deck.boxes[i];
              final count = deck.cards.where((c) => c.boxIndex == i).length;
              return SizedBox(width: 120, child: Card(child: Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Icon(Icons.inventory_2_outlined, color: boxColor(box)), const Spacer(), Text(box.name, maxLines: 1, overflow: TextOverflow.ellipsis), Text('$count ${s('cards_count')}', style: TextStyle(color: Theme.of(context).hintColor))]))));
            },
          )),
          const SizedBox(height: 12),
          Text('${cards.length} ${s('cards')}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          if (cards.isEmpty) Card(child: Padding(padding: const EdgeInsets.all(24), child: Center(child: Text(s('no_cards'))))),
          ...cards.map((card) {
            final boxIndex = deck.boxes.isEmpty ? 0 : min(max(0, card.boxIndex), deck.boxes.length - 1);
            final boxName = deck.boxes.isEmpty ? s('box') : deck.boxes[boxIndex].name;
            final title = card.front.trim().isEmpty ? '🖼️' : card.front.trim();
            final answer = card.back.trim().isEmpty ? '🖼️' : card.back.trim();
            return Card(
              margin: const EdgeInsets.only(bottom: 7),
              child: ListTile(
                onTap: () => _editCard(card),
                leading: CircleAvatar(backgroundColor: boxColor(deck.boxes.isEmpty ? LeitnerBox(id: '', name: '', colorValue: Theme.of(context).colorScheme.primary.value) : deck.boxes[boxIndex]), child: Text('${boxIndex + 1}')),
                title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('$answer\n$boxName${card.tags.trim().isEmpty ? '' : ' • ${card.tags.trim()}'}', maxLines: 2, overflow: TextOverflow.ellipsis),
                isThreeLine: true,
                trailing: IconButton(onPressed: () { card.favorite = !card.favorite; setState(() {}); widget.onChanged(); }, icon: Icon(card.favorite ? Icons.star : Icons.star_border, color: card.favorite ? Colors.amber : null)),
              ),
            );
          }),
        ],
      )),
    );
  }

  Future<void> _deleteDeck() async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: Text('${s('delete')}؟'),
      content: Text('${widget.deck.name}\n\n${widget.deck.cards.length} ${s('cards_count')}'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s('cancel'))), ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(s('delete')))],
    ));
    if (ok == true && mounted) Navigator.pop(context, 'deleted');
  }

  Future<void> _editDeck() async {
    final controller = TextEditingController(text: widget.deck.name);
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: Text(s('rename')), content: TextField(controller: controller, autofocus: true), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s('cancel'))), ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(s('save')))]));
    final name = controller.text.trim(); controller.dispose();
    if (ok == true && name.isNotEmpty) { widget.deck.name = name; setState(() {}); widget.onChanged(); }
  }

  Future<void> _editCard([FlashCard? card]) async {
    final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => CardEditor(deck: widget.deck, card: card)));
    if (changed == true && mounted) { setState(() {}); widget.onChanged(); }
  }

  Future<void> _study() async {
    final due = widget.deck.cards.where((c) => !c.dueAt.isAfter(DateTime.now())).toList();
    final choice = await showModalBottomSheet<String>(context: context, showDragHandle: true, builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [ListTile(title: Text(s('study_type'), style: const TextStyle(fontWeight: FontWeight.w700))), ListTile(leading: const Icon(Icons.bolt), title: Text(s('cards_ready')), subtitle: Text('${due.length} ${s('cards_count')}'), onTap: () => Navigator.pop(context, 'due')), ListTile(leading: const Icon(Icons.all_inclusive), title: Text(s('all')), subtitle: Text('${widget.deck.cards.length} ${s('cards_count')}'), onTap: () => Navigator.pop(context, 'all')), ListTile(leading: const Icon(Icons.star), title: Text(s('favorite_only')), subtitle: Text('${widget.deck.cards.where((c) => c.favorite).length} ${s('cards_count')}'), onTap: () => Navigator.pop(context, 'favorites'))])));
    if (!mounted || choice == null) return;
    final selected = choice == 'all' ? [...widget.deck.cards] : choice == 'favorites' ? widget.deck.cards.where((c) => c.favorite).toList() : due;
    if (selected.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s('no_review')))); return; }
    Navigator.push(context, MaterialPageRoute(builder: (_) => StudyPage(deck: widget.deck, settings: widget.settings, studyCards: selected, onChanged: widget.onChanged)));
  }

  Future<void> _boxes() async {
    await showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => _BoxManager(deck: widget.deck, onChanged: () { if (mounted) setState(() {}); widget.onChanged(); }));
  }
}

class _BoxManager extends StatefulWidget {
  final Deck deck; final VoidCallback onChanged;
  const _BoxManager({required this.deck, required this.onChanged});
  @override State<_BoxManager> createState() => _BoxManagerState();
}

class _BoxManagerState extends State<_BoxManager> {
  String s(String key) => AppStrings.t(context, key);

  Future<void> _add() async {
    final controller = TextEditingController(text: '${s('box')} ${widget.deck.boxes.length + 1}');
    final name = await showDialog<String>(context: context, builder: (_) => AlertDialog(title: Text(s('add_box')), content: TextField(controller: controller, autofocus: true, decoration: InputDecoration(labelText: s('box_name'))), actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(s('cancel'))), ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text(s('save')))]));
    controller.dispose();
    if (name == null || name.isEmpty) return;
    widget.deck.boxes.add(LeitnerBox(id: uid(), name: name, colorValue: Colors.primaries[widget.deck.boxes.length % Colors.primaries.length].value));
    setState(() {}); widget.onChanged();
  }

  Future<void> _rename(int index) async {
    final controller = TextEditingController(text: widget.deck.boxes[index].name);
    final name = await showDialog<String>(context: context, builder: (_) => AlertDialog(title: Text(s('rename')), content: TextField(controller: controller, autofocus: true), actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(s('cancel'))), ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text(s('save')))]));
    controller.dispose();
    if (name == null || name.isEmpty) return;
    widget.deck.boxes[index].name = name; setState(() {}); widget.onChanged();
  }

  Future<void> _delete(int index) async {
    if (widget.deck.boxes.length <= 1) return;
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: Text(s('delete_box')), content: Text(s('delete_box_confirm')), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s('cancel'))), ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(s('delete')))]));
    if (ok != true) return;
    widget.deck.boxes.removeAt(index);
    for (final card in widget.deck.cards) {
      if (card.boxIndex == index) card.boxIndex = 0;
      else if (card.boxIndex > index) card.boxIndex--;
    }
    setState(() {}); widget.onChanged();
  }

  @override
  Widget build(BuildContext context) => SafeArea(child: ConstrainedBox(constraints: const BoxConstraints(maxHeight: 560), child: Column(mainAxisSize: MainAxisSize.min, children: [Padding(padding: const EdgeInsets.fromLTRB(16, 6, 8, 6), child: Row(children: [Expanded(child: Text(s('boxes'), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700))), IconButton(onPressed: _add, icon: const Icon(Icons.add))])), const Divider(height: 1), Expanded(child: ListView.builder(itemCount: widget.deck.boxes.length, itemBuilder: (_, i) { final box = widget.deck.boxes[i]; final count = widget.deck.cards.where((c) => c.boxIndex == i).length; return ListTile(leading: CircleAvatar(backgroundColor: boxColor(box), child: Text('${i + 1}', style: const TextStyle(color: Colors.white))), title: Text(box.name), subtitle: Text('$count ${s('cards_count')}'), trailing: Wrap(children: [IconButton(onPressed: () => _rename(i), icon: const Icon(Icons.edit)), IconButton(onPressed: () => _delete(i), icon: const Icon(Icons.delete_outline))])); }))])));
}
