import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/models/app_models.dart';
import '../../core/utils/helpers.dart';

class StudyPage extends StatefulWidget {
  final Deck deck;
  final VoidCallback onChanged;

  const StudyPage({
    super.key,
    required this.deck,
    required this.onChanged,
  });

  @override
  State<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage>
    with SingleTickerProviderStateMixin {
  late List<FlashCard> queue;
  int index = 0;
  bool back = false;
  late final AnimationController flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  @override
  void initState() {
    super.initState();
    queue = widget.deck.cards
        .where((card) => !card.dueAt.isAfter(DateTime.now()))
        .toList()
      ..shuffle();
  }

  @override
  void dispose() {
    flip.dispose();
    super.dispose();
  }

  void reveal() {
    setState(() => back = !back);
    if (back) {
      flip.forward();
    } else {
      flip.reverse();
    }
  }

  void rate(int move) {
    final card = queue[index];
    card.reviews++;

    if (move == 0) {
      card.lapses++;
      card.boxIndex = 0;
      card.dueAt = DateTime.now().add(const Duration(minutes: 10));
    } else {
      card.boxIndex = min(widget.deck.boxes.length - 1, card.boxIndex + move);
      final days = [1, 2, 4, 7, 14, 30][min(card.boxIndex, 5)];
      card.dueAt = DateTime.now().add(Duration(days: days));
    }

    widget.onChanged();

    if (index + 1 < queue.length) {
      setState(() {
        index++;
        back = false;
      });
      flip.reset();
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (queue.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('مرور')),
        body: const Center(child: Text('کارت آماده مرور نداری 🎉')),
      );
    }

    final card = queue[index];
    final text = back ? card.back : card.front;

    return Scaffold(
      appBar: AppBar(title: Text('${index + 1} / ${queue.length}')),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: reveal,
                child: AnimatedBuilder(
                  animation: flip,
                  builder: (context, child) {
                    final angle = flip.value * pi;
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0014)
                        ..rotateY(angle),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF161E35), Color(0xFF0E1425)],
                          ),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Center(
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..rotateY(back ? pi : 0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  back
                                      ? Icons.lightbulb_rounded
                                      : Icons.help_outline_rounded,
                                  size: 44,
                                  color: const Color(0xFF6D63FF),
                                ),
                                const SizedBox(height: 22),
                                Text(
                                  text,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 27,
                                    fontWeight: FontWeight.w900,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  back ? 'پاسخ' : 'برای دیدن پاسخ ضربه بزن',
                                  style: const TextStyle(color: Colors.white54),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (back)
              Row(
                children: [
                  Expanded(
                    child: _Rate(
                      'دوباره',
                      Icons.refresh_rounded,
                      Colors.redAccent,
                      () => rate(0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Rate(
                      'سخت',
                      Icons.trending_down_rounded,
                      Colors.orange,
                      () => rate(1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Rate(
                      'خوب',
                      Icons.check_rounded,
                      Colors.green,
                      () => rate(1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Rate(
                      'آسان',
                      Icons.bolt_rounded,
                      Colors.cyan,
                      () => rate(2),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Rate extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _Rate(this.text, this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onTap,
      icon: Icon(icon, color: color),
      label: Text(text),
    );
  }
}
