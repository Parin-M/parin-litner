import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/app_models.dart';
import '../../core/models/app_settings.dart';
import '../../core/services/music_service.dart';

class StudyPage extends StatefulWidget {
  final Deck deck;
  final VoidCallback onChanged;
  final AppSettings settings;
  final List<FlashCard>? studyCards;
  const StudyPage({super.key, required this.deck, required this.onChanged, required this.settings, this.studyCards});
  @override State<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage> with SingleTickerProviderStateMixin {
  late final List<FlashCard> queue;
  late final AnimationController flipController;
  Timer? timer;
  int index = 0;
  int seconds = 0;
  bool revealed = false;
  bool locked = false;
  bool musicStarted = false;
  final music = MusicService.instance;

  @override
  void initState() {
    super.initState();
    queue = (widget.studyCards ?? widget.deck.cards.where((card) => !card.dueAt.isAfter(DateTime.now())).toList())..shuffle();
    flipController = AnimationController(vsync: this, duration: Duration(milliseconds: widget.settings.animations ? 520 : 1));
    if (widget.settings.showTimer) timer = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() => seconds++); });
    if (widget.settings.musicEnabled && queue.isNotEmpty) _startMusic();
    if (widget.settings.autoReveal && queue.isNotEmpty) Future.delayed(const Duration(milliseconds: 650), () { if (mounted) _reveal(); });
  }

  Future<void> _startMusic() async { try { await music.play(widget.settings.musicTrack, volume: widget.settings.musicVolume); musicStarted = true; } catch (_) {} }
  @override void dispose() { timer?.cancel(); flipController.dispose(); if (musicStarted) music.stop(); super.dispose(); }
  void _reveal() { if (locked || queue.isEmpty) return; setState(() => revealed = !revealed); if (revealed) flipController.forward(); else flipController.reverse(); }
  void _feedback({bool heavy = false}) { if (!widget.settings.haptics) return; if (heavy) HapticFeedback.heavyImpact(); else HapticFeedback.selectionClick(); }

  void _rate(int rating) {
    if (locked || queue.isEmpty || index >= queue.length || !revealed) return;
    final card = queue[index]; card.reviews++;
    final lastBox = max(0, widget.deck.boxes.length - 1); final now = DateTime.now();
    switch (rating) {
      case 0: card.lapses++; card.boxIndex = 0; card.dueAt = now.add(const Duration(minutes: 10)); break;
      case 1: card.boxIndex = min(lastBox, max(0, card.boxIndex)); card.dueAt = now.add(const Duration(days: 1)); break;
      case 2: card.boxIndex = min(lastBox, max(0, card.boxIndex + 1)); card.dueAt = now.add(Duration(days: [1, 2, 4, 7, 14, 30][min(card.boxIndex, 5)])); break;
      default: card.boxIndex = min(lastBox, max(0, card.boxIndex + 2)); card.dueAt = now.add(Duration(days: [2, 4, 7, 14, 30, 60][min(card.boxIndex, 5)]));
    }
    widget.onChanged(); _feedback();
    if (index + 1 < queue.length) {
      setState(() { index++; revealed = false; }); flipController.reset();
      if (widget.settings.autoReveal) Future.delayed(const Duration(milliseconds: 380), () { if (mounted && !locked) _reveal(); });
    } else { setState(() => locked = true); _feedback(heavy: true); _showCompletion(); }
  }

  void _swipe(DragEndDetails details) { if (!revealed || locked) return; final velocity = details.primaryVelocity ?? 0; if (velocity > 500) _rate(2); else if (velocity < -500) _rate(1); }
  Future<void> _showCompletion() async { await Future.delayed(const Duration(milliseconds: 260)); if (!mounted) return; await showDialog<void>(context: context, barrierDismissible: false, builder: (_) => _CompletionDialog(count: queue.length, seconds: seconds)); if (mounted) Navigator.pop(context); }
  String _time() => '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';

  @override Widget build(BuildContext context) {
    if (queue.isEmpty) return Scaffold(appBar: AppBar(title: const Text('مرور')), body: const Center(child: Text('در این حالت کارتی برای مرور نداری 🎉')));
    final card = queue[index]; final progress = ((index + (revealed ? .65 : .2)) / queue.length).clamp(0.0, 1.0).toDouble();
    return Scaffold(appBar: AppBar(title: Text('${index + 1} / ${queue.length}'), actions: [
      if (widget.settings.musicEnabled) IconButton(onPressed: () async { if (musicStarted) { await music.pause(); setState(() => musicStarted = false); } else { await _startMusic(); setState(() {}); } }, icon: Icon(musicStarted ? Icons.music_note_rounded : Icons.music_off_rounded), tooltip: 'موسیقی'),
      if (widget.settings.showTimer) Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Center(child: Text(_time(), style: const TextStyle(fontWeight: FontWeight.w800)))),
    ]), body: Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 18), child: Column(children: [
      if (widget.settings.showProgress) ...[ClipRRect(borderRadius: BorderRadius.circular(99), child: TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: progress), duration: const Duration(milliseconds: 450), builder: (_, value, __) => LinearProgressIndicator(value: value, minHeight: 7))), const SizedBox(height: 12)],
      Expanded(child: GestureDetector(onTap: _reveal, onHorizontalDragEnd: _swipe, child: AnimatedBuilder(animation: flipController, builder: (_, __) { final angle = flipController.value * pi; final isFront = angle < pi / 2; final face = isFront ? _FlashCardView(key: const ValueKey('front'), text: card.front, image: card.frontImage, revealed: false, label: 'سؤال • برای دیدن پاسخ ضربه بزن') : Transform(alignment: Alignment.center, transform: Matrix4.rotationY(pi), child: _FlashCardView(key: const ValueKey('back'), text: card.back, image: card.backImage, revealed: true, label: 'پاسخ • برای برگشت ضربه بزن')); return Transform(alignment: Alignment.center, transform: Matrix4.identity()..setEntry(3, 2, 0.0015)..rotateY(angle), child: face); }))),
      const SizedBox(height: 14),
      if (revealed) ...[const Text('برای امتیازدهی، کارت را به چپ یا راست هم بکشید.', textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: TextStyle(fontSize: 12)), const SizedBox(height: 8), Row(children: [Expanded(child: _Rate('دوباره', Icons.refresh_rounded, Colors.redAccent, () => _rate(0))), const SizedBox(width: 7), Expanded(child: _Rate('سخت', Icons.trending_down_rounded, Colors.orange, () => _rate(1))), const SizedBox(width: 7), Expanded(child: _Rate('خوب', Icons.check_rounded, Colors.green, () => _rate(2))), const SizedBox(width: 7), Expanded(child: _Rate('آسان', Icons.bolt_rounded, Colors.cyan, () => _rate(3)))]),] else const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('کارت را لمس کن تا پاسخ را ببینی.', textDirection: TextDirection.rtl)),
    ])));
  }
}

class _FlashCardView extends StatelessWidget { final String text; final String? image; final bool revealed; final String label; const _FlashCardView({super.key, required this.text, required this.image, required this.revealed, required this.label}); @override Widget build(BuildContext context) { final scheme = Theme.of(context).colorScheme; final hasImage = image != null && image!.isNotEmpty; return Container(width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white.withValues(alpha: .78), scheme.primary.withValues(alpha: .06)]), borderRadius: BorderRadius.circular(34), border: Border.all(color: Colors.white.withValues(alpha: .82), width: 1.4), boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: .13), blurRadius: 34, spreadRadius: 2)]), child: Center(child: SingleChildScrollView(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: Icon(revealed ? Icons.lightbulb_rounded : Icons.help_outline_rounded, key: ValueKey(revealed), size: 48, color: scheme.primary)), const SizedBox(height: 16), if (hasImage) ...[ClipRRect(borderRadius: BorderRadius.circular(22), child: Image.memory(base64Decode(image!), height: 190, width: double.infinity, fit: BoxFit.contain)), const SizedBox(height: 16)], if (text.trim().isNotEmpty) Text(text, textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900, height: 1.4)), const SizedBox(height: 18), Text(label, textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: TextStyle(color: scheme.onSurface.withValues(alpha: .52), fontWeight: FontWeight.w600))])))); } }
class _Rate extends StatelessWidget { final String text; final IconData icon; final Color color; final VoidCallback onTap; const _Rate(this.text, this.icon, this.color, this.onTap); @override Widget build(BuildContext context) => FilledButton.tonalIcon(onPressed: onTap, icon: Icon(icon, color: color), label: Text(text, textDirection: TextDirection.rtl)); }
class _CompletionDialog extends StatelessWidget { final int count; final int seconds; const _CompletionDialog({required this.count, required this.seconds}); @override Widget build(BuildContext context) => Dialog(child: Padding(padding: const EdgeInsets.all(26), child: Column(mainAxisSize: MainAxisSize.min, children: [TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: 1), duration: const Duration(milliseconds: 700), curve: Curves.elasticOut, builder: (_, value, __) => Transform.scale(scale: value, child: const Icon(Icons.emoji_events_rounded, size: 72)), const SizedBox(height: 12), const Text('جلسه تمام شد! 🎉', textDirection: TextDirection.rtl, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)), const SizedBox(height: 8), Text('$count کارت در ${seconds ~/ 60} دقیقه و ${seconds % 60} ثانیه', textDirection: TextDirection.rtl), const SizedBox(height: 18), FilledButton(onPressed: () => Navigator.pop(context), child: const Text('عالیه', textDirection: TextDirection.rtl))]))); }
