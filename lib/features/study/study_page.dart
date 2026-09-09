import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/models/app_models.dart';
import '../../core/models/app_settings.dart';

class StudyPage extends StatefulWidget {
  final Deck deck;
  final VoidCallback onChanged;
  final AppSettings settings;
  const StudyPage({super.key, required this.deck, required this.onChanged, required this.settings});
  @override State<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage> with SingleTickerProviderStateMixin {
  late List<FlashCard> queue;
  int index = 0;
  bool revealed = false;
  bool locked = false;
  late final AnimationController flip;
  Timer? timer;
  int seconds = 0;

  @override
  void initState() {
    super.initState();
    queue = widget.deck.cards.where((card) => !card.dueAt.isAfter(DateTime.now())).toList()..shuffle();
    flip = AnimationController(vsync: this, duration: Duration(milliseconds: widget.settings.animations ? 520 : 1));
    timer = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() => seconds++); });
    if (widget.settings.autoReveal && queue.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () { if (mounted) reveal(); });
    }
  }

  @override
  void dispose() { timer?.cancel(); flip.dispose(); super.dispose(); }

  void reveal() {
    if (locked || queue.isEmpty) return;
    setState(() => revealed = !revealed);
    if (revealed) { flip.forward(); } else { flip.reverse(); }
  }

  void rate(int movement) {
    if (locked || queue.isEmpty || index >= queue.length || !revealed) return;
    final card = queue[index];
    card.reviews++;
    if (movement == 0) {
      card.lapses++;
      card.boxIndex = 0;
      card.dueAt = DateTime.now().add(const Duration(minutes: 10));
    } else {
      final lastBox = max(0, widget.deck.boxes.length - 1);
      card.boxIndex = min(lastBox, max(0, card.boxIndex + movement));
      const intervals = [1, 2, 4, 7, 14, 30];
      final intervalIndex = min(card.boxIndex, intervals.length - 1);
      card.dueAt = DateTime.now().add(Duration(days: intervals[intervalIndex]));
    }
    widget.onChanged();
    if (index + 1 < queue.length) {
      setState(() { index++; revealed = false; });
      flip.reset();
      if (widget.settings.haptics) HapticFeedback.selectionClick();
    } else {
      setState(() => locked = true);
      if (widget.settings.haptics) HapticFeedback.heavyImpact();
      _finishDialog();
    }
  }

  Future<void> _finishDialog() async {
    await Future.delayed(const Duration(milliseconds: 260));
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CompletionDialog(count: queue.length, seconds: seconds),
    ).then((_) { if (mounted) Navigator.pop(context); });
  }

  void _swipe(DragEndDetails details) {
    if (!revealed || locked) return;
    final velocity = details.primaryVelocity ?? 0;
    if (velocity > 500) rate(2);       // راست = آسان
    else if (velocity < -500) rate(1); // چپ = خوب
  }

  String _time() => '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    if (queue.isEmpty) return Scaffold(appBar: AppBar(title: const Text('مرور')), body: const Center(child: Text('کارت آماده مرور نداری 🎉')));
    final card = queue[index];
    final progress = (index + (revealed ? .65 : .2)) / queue.length;
    return Scaffold(
      appBar: AppBar(
        title: Text('${index + 1} / ${queue.length}'),
        actions: [if (widget.settings.showTimer) Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Center(child: Text(_time(), style: const TextStyle(fontWeight: FontWeight.w800))))],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
        child: Column(children: [
          if (widget.settings.showProgress) ...[
            ClipRRect(borderRadius: BorderRadius.circular(99), child: TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: progress.clamp(0, 1)), duration: const Duration(milliseconds: 450), builder: (_, v, __) => LinearProgressIndicator(value: v, minHeight: 7))),
            const SizedBox(height: 12),
          ],
          Expanded(child: GestureDetector(onTap: reveal, onHorizontalDragEnd: _swipe, child: AnimatedBuilder(animation: flip, builder: (_, __) {
            final angle = flip.value * pi;
            final back = _FlashCardView(text: card.back, revealed: true, label: 'پاسخ • برای برگشت ضربه بزن');
            final front = _FlashCardView(text: card.front, revealed: false, label: 'سؤال • برای دیدن پاسخ ضربه بزن');
            return Transform(alignment: Alignment.center, transform: Matrix4.identity()..setEntry(3, 2, .0015)..rotateY(angle), child: angle < pi / 2 ? front : Transform(alignment: Alignment.center, transform: Matrix4.rotationY(pi), child: back));
          }))),
          const SizedBox(height: 14),
          if (revealed) ...[
            const Text('برای امتیازدهی می‌توانی کارت را هم به چپ/راست بکشید.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _Rate('دوباره', Icons.refresh_rounded, Colors.redAccent, () => rate(0))),
              const SizedBox(width: 7), Expanded(child: _Rate('سخت', Icons.trending_down_rounded, Colors.orange, () => rate(0))),
              const SizedBox(width: 7), Expanded(child: _Rate('خوب', Icons.check_rounded, Colors.green, () => rate(1))),
              const SizedBox(width: 7), Expanded(child: _Rate('آسان', Icons.bolt_rounded, Colors.cyan, () => rate(2))),
            ]),
          ] else const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('کارت را لمس کن یا بالا/پایین نرو؛ با یک ضربه پاسخ را ببین.')),
        ]),
      ),
    );
  }
}

class _FlashCardView extends StatelessWidget {
  final String text; final bool revealed; final String label;
  const _FlashCardView({required this.text, required this.revealed, required this.label});
  @override Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(width: double.infinity, padding: const EdgeInsets.all(28), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white.withValues(alpha: .78), scheme.primary.withValues(alpha: .06)]), borderRadius: BorderRadius.circular(34), border: Border.all(color: Colors.white.withValues(alpha: .82), width: 1.4), boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: .13), blurRadius: 34, spreadRadius: 2)]), child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: Icon(revealed ? Icons.lightbulb_rounded : Icons.help_outline_rounded, key: ValueKey(revealed), size: 48, color: scheme.primary)), const SizedBox(height: 22), AnimatedSwitcher(duration: const Duration(milliseconds: 280), transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child)), child: Text(text, key: ValueKey(text), textAlign: TextAlign.center, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900, height: 1.4)), const SizedBox(height: 20), Text(label, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurface.withValues(alpha: .52), fontWeight: FontWeight.w600))])));
  }
}

class _Rate extends StatelessWidget {
  final String text; final IconData icon; final Color color; final VoidCallback onTap;
  const _Rate(this.text, this.icon, this.color, this.onTap);
  @override Widget build(BuildContext context) => FilledButton.tonalIcon(onPressed: onTap, icon: Icon(icon, color: color), label: Text(text));
}

class _CompletionDialog extends StatelessWidget {
  final int count, seconds;
  const _CompletionDialog({required this.count, required this.seconds});
  @override Widget build(BuildContext context) {
    return Dialog(child: Padding(padding: const EdgeInsets.all(26), child: Column(mainAxisSize: MainAxisSize.min, children: [TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: 1), duration: const Duration(milliseconds: 700), curve: Curves.elasticOut, builder: (_, v, __) => Transform.scale(scale: v, child: const Icon(Icons.emoji_events_rounded, size: 72)),), const SizedBox(height: 12), const Text('جلسه تمام شد! 🎉', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)), const SizedBox(height: 8), Text('$count کارت در ${seconds ~/ 60} دقیقه و ${seconds % 60} ثانیه'), const SizedBox(height: 18), FilledButton(onPressed: () => Navigator.pop(context), child: const Text('عالیه'))])));
  }
}
