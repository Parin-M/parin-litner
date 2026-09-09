import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/models/app_models.dart';

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
  bool revealed = false;
  late final AnimationController flip;

  @override
  void initState() {
    super.initState();
    queue = widget.deck.cards
        .where((card) => !card.dueAt.isAfter(DateTime.now()))
        .toList()
      ..shuffle();
    flip = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
  }

  @override
  void dispose() {
    flip.dispose();
    super.dispose();
  }

  void reveal() {
    setState(() => revealed = !revealed);
    if (revealed) {
      flip.forward();
    } else {
      flip.reverse();
    }
  }

  void rate(int movement) {
    if (queue.isEmpty || index >= queue.length) return;

    final card = queue[index];
    card.reviews++;

    if (movement == 0) {
      card.lapses++;
      card.boxIndex = 0;
      card.dueAt = DateTime.now().add(const Duration(minutes: 10));
    } else {
      final lastBox = widget.deck.boxes.length - 1;
      card.boxIndex = min(lastBox, card.boxIndex + movement);
      const intervals = [1, 2, 4, 7, 14, 30];
      final intervalIndex = min(card.boxIndex, intervals.length - 1);
      card.dueAt = DateTime.now().add(
        Duration(days: intervals[intervalIndex]),
      );
    }

    widget.onChanged();

    if (index + 1 < queue.length) {
      setState(() {
        index++;
        revealed = false;
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
        body: const Center(
          child: Text('کارت آماده مرور نداری 🎉'),
        ),
      );
    }

    final card = queue[index];
    return Scaffold(
      appBar: AppBar(
        title: Text('${index + 1} / ${queue.length}'),
      ),
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
                        ..setEntry(3, 2, .0014)
                        ..rotateY(angle),
                      child: child,
                    );
                  },
                  child: _FlashCardView(
                    text: revealed ? card.back : card.front,
                    revealed: revealed,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (revealed)
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

class _FlashCardView extends StatelessWidget {
  final String text;
  final bool revealed;

  const _FlashCardView({required this.text, required this.revealed});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: scheme.primary.withValues(alpha: .12)),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: .10),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              revealed ? Icons.lightbulb_rounded : Icons.help_outline_rounded,
              size: 44,
              color: scheme.primary,
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
              revealed ? 'پاسخ' : 'برای دیدن پاسخ ضربه بزن',
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: .52),
              ),
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
