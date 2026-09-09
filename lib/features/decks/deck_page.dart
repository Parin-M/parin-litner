import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/models/app_models.dart';
import '../../core/utils/helpers.dart';
import '../../shared/widgets/animated_glass_card.dart';
import '../cards/card_editor.dart';
import '../study/study_page.dart';

class DeckPage extends StatefulWidget {
  final Deck deck;
  final VoidCallback onChanged;

  const DeckPage({
    super.key,
    required this.deck,
    required this.onChanged,
  });

  @override
  State<DeckPage> createState() => _DeckPageState();
}

class _DeckPageState extends State<DeckPage> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final deck = widget.deck;
    final cards = deck.cards.where((card) {
      final haystack = '${card.front} ${card.back} ${card.tags}'.toLowerCase();
      return haystack.contains(query.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(deck.name),
        actions: [
          IconButton(
            onPressed: _editDeck,
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            onPressed: _boxes,
            icon: const Icon(Icons.view_module_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editCard(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('کارت جدید'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) => setState(() => query = value),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'جستجوی کارت...',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.tonalIcon(
                onPressed: _study,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('مرور'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: deck.boxes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final box = deck.boxes[i];
                final count = deck.cards.where((c) => c.boxIndex == i).length;
                return SizedBox(
                  width: 120,
                  child: AnimatedGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.inventory_2_rounded, color: boxColor(box)),
                        const Spacer(),
                        Text(
                          box.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text('$count کارت'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          if (cards.isEmpty)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Center(child: Text('کارت پیدا نشد')),
            ),
          ...cards.map((card) {
            final boxIndex = deck.boxes.isEmpty
                ? 0
                : min(card.boxIndex, deck.boxes.length - 1);
            final boxName = deck.boxes.isEmpty ? 'خانه' : deck.boxes[boxIndex].name;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AnimatedGlassCard(
                onTap: () => _editCard(card),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            card.front,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            card.back,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 7),
                          Text(
                            '$boxName • ${card.tags}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        card.favorite = !card.favorite;
                        setState(() {});
                        widget.onChanged();
                      },
                      icon: Icon(
                        card.favorite
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: card.favorite ? Colors.amber : null,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _editDeck() async {
    final controller = TextEditingController(text: widget.deck.name);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ویرایش دسته'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'نام'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لغو'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
    final name = controller.text.trim();
    controller.dispose();
    if (ok == true && name.isNotEmpty) {
      widget.deck.name = name;
      setState(() {});
      widget.onChanged();
    }
  }

  Future<void> _editCard([FlashCard? card]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CardEditor(deck: widget.deck, card: card),
      ),
    );
    if (changed == true) {
      setState(() {});
      widget.onChanged();
    }
  }

  void _study() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudyPage(
          deck: widget.deck,
          onChanged: () {
            setState(() {});
            widget.onChanged();
          },
        ),
      ),
    );
  }

  Future<void> _boxes() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BoxManager(
        deck: widget.deck,
        onChanged: () {
          setState(() {});
          widget.onChanged();
        },
      ),
    );
  }
}

class BoxManager extends StatefulWidget {
  final Deck deck;
  final VoidCallback onChanged;

  const BoxManager({
    super.key,
    required this.deck,
    required this.onChanged,
  });

  @override
  State<BoxManager> createState() => _BoxManagerState();
}

class _BoxManagerState extends State<BoxManager> {
  Future<void> _rename(int index) async {
    final controller = TextEditingController(text: widget.deck.boxes[index].name);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('نام خانه'),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لغو'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
    final name = controller.text.trim();
    controller.dispose();
    if (ok == true && name.isNotEmpty) {
      widget.deck.boxes[index].name = name;
      setState(() {});
      widget.onChanged();
    }
  }

  void _add() {
    final index = widget.deck.boxes.length;
    widget.deck.boxes.add(
      LeitnerBox(
        id: uid(),
        name: 'خانه ${index + 1}',
        colorValue: Colors.primaries[index % Colors.primaries.length].value,
      ),
    );
    setState(() {});
    widget.onChanged();
  }

  Future<void> _delete(int index) async {
    if (widget.deck.boxes.length <= 1) return;
    final removed = widget.deck.boxes.removeAt(index);
    for (final card in widget.deck.cards) {
      if (card.boxIndex == index) {
        card.boxIndex = 0;
      } else if (card.boxIndex > index) {
        card.boxIndex--;
      }
    }
    setState(() {});
    widget.onChanged();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${removed.name} حذف شد')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'مدیریت خانه‌ها',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  onPressed: _add,
                  icon: const Icon(Icons.add_circle_rounded),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.deck.boxes.length,
                itemBuilder: (_, index) {
                  final box = widget.deck.boxes[index];
                  final count = widget.deck.cards
                      .where((card) => card.boxIndex == index)
                      .length;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: boxColor(box),
                      child: Text('${index + 1}'),
                    ),
                    title: Text(box.name),
                    subtitle: Text('$count کارت'),
                    trailing: Wrap(
                      children: [
                        IconButton(
                          onPressed: () => _rename(index),
                          icon: const Icon(Icons.edit_rounded),
                        ),
                        IconButton(
                          onPressed: () => _delete(index),
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
