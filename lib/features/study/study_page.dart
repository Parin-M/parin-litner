import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/app_models.dart';
import '../../core/models/app_settings.dart';
import '../../core/services/music_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/i18n/app_strings.dart';

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
  late final AnimationController flip;
  Timer? timer;
  final music = MusicService.instance;
  int index = 0;
  int seconds = 0;
  bool revealed = false;
  bool musicPlaying = false;
  bool locked = false;

  String s(String key) => AppStrings.t(context, key);

  @override
  void initState() {
    super.initState();
    queue = List<FlashCard>.from(widget.studyCards ?? widget.deck.cards.where((c) => !c.dueAt.isAfter(DateTime.now())))..shuffle();
    flip = AnimationController(vsync: this, duration: Duration(milliseconds: widget.settings.animations ? 360 : 1));
    if (widget.settings.showTimer) {
      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => seconds++);
      });
    }
    if (queue.isNotEmpty && widget.settings.musicEnabled) _startMusic();
    if (queue.isNotEmpty && widget.settings.autoReveal) {
      Future.delayed(const Duration(milliseconds: 450), () { if (mounted) _reveal(); });
    }
  }

  Future<void> _startMusic() async {
    try {
      await music.play(widget.settings.musicTrack, volume: widget.settings.musicVolume);
      if (mounted) setState(() => musicPlaying = true);
    } catch (_) {}
  }

  void _buzz([bool heavy = false]) {
    if (!widget.settings.haptics) return;
    if (heavy) HapticFeedback.heavyImpact(); else HapticFeedback.selectionClick();
  }

  void _reveal() {
    if (locked || queue.isEmpty) return;
    setState(() => revealed = !revealed);
    if (revealed) flip.forward(); else flip.reverse();
    _buzz();
  }

  void _rate(int rating) {
    if (locked || queue.isEmpty || !revealed) return;
    final card = queue[index];
    final last = max(0, widget.deck.boxes.length - 1);
    final now = DateTime.now();
    card.reviews++;
    if (rating == 0) {
      card.lapses++;
      card.boxIndex = 0;
      card.dueAt = now.add(const Duration(minutes: 10));
    } else if (rating == 1) {
      card.boxIndex = card.boxIndex.clamp(0, last).toInt();
      card.dueAt = now.add(const Duration(days: 1));
    } else if (rating == 2) {
      card.boxIndex = min(last, max(0, card.boxIndex + 1));
      card.dueAt = now.add(Duration(days: [1, 2, 4, 7, 14, 30][min(card.boxIndex, 5)]));
    } else {
      card.boxIndex = min(last, max(0, card.boxIndex + 2));
      card.dueAt = now.add(Duration(days: [2, 4, 7, 14, 30, 60][min(card.boxIndex, 5)]));
    }
    widget.onChanged();
    _buzz();
    if (index + 1 >= queue.length) {
      setState(() => locked = true);
      _buzz(true);
      _complete();
      return;
    }
    setState(() {
      index++;
      revealed = false;
    });
    flip.reset();
    if (widget.settings.autoReveal) {
      Future.delayed(const Duration(milliseconds: 300), () { if (mounted && !locked) _reveal(); });
    }
  }

  void _swipe(DragEndDetails details) {
    if (!revealed || locked) return;
    final velocity = details.primaryVelocity ?? 0;
    if (velocity > 450) {
      _rate(2);
    } else if (velocity < -450) {
      _rate(1);
    }
  }

  Future<void> _complete() async {
    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s('done')),
        content: Text('${queue.length} ${s('cards_count')}\n${_time()}'),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: Text(s('great')))],
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  String _time() => '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';

  @override
  void dispose() {
    timer?.cancel();
    flip.dispose();
    if (musicPlaying) music.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (queue.isEmpty) {
      return Scaffold(appBar: AppBar(title: Text(s('study'))), body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(s('no_due'), textAlign: TextAlign.center))));
    }
    final card = queue[index];
    final progress = ((index + (revealed ? .9 : .2)) / queue.length).clamp(0.0, 1.0).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: Text('${index + 1} / ${queue.length}'),
        actions: [
          if (widget.settings.showTimer) Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Center(child: Text(_time()))),
          if (widget.settings.musicEnabled) IconButton(onPressed: () async { if (musicPlaying) { await music.pause(); if (mounted) setState(() => musicPlaying = false); } else { await _startMusic(); } }, icon: Icon(musicPlaying ? Icons.music_note : Icons.music_off), tooltip: s('music_btn')),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
          child: Column(
            children: [
              if (widget.settings.showProgress) ...[
                LinearProgressIndicator(value: progress, minHeight: 6),
                const SizedBox(height: 12),
              ],
              Expanded(
                child: GestureDetector(
                  onTap: _reveal,
                  onHorizontalDragEnd: _swipe,
                  child: AnimatedBuilder(
                    animation: flip,
                    builder: (context, _) {
                      final angle = flip.value * pi;
                      final frontSide = angle <= pi / 2;
                      final face = _CardFace(
                        text: frontSide ? card.front : card.back,
                        image: frontSide ? card.frontImage : card.backImage,
                        label: frontSide ? s('tap') : s('again'),
                      );
                      final transformedFace = frontSide
                          ? face
                          : Transform(alignment: Alignment.center, transform: Matrix4.rotationY(pi), child: face);
                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..setEntry(3, 2, .0012)..rotateY(angle),
                        child: transformedFace,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (revealed)
                Row(children: [
                  Expanded(child: _Rate(s('again'), Icons.refresh, () => _rate(0))),
                  const SizedBox(width: 5),
                  Expanded(child: _Rate(s('hard'), Icons.trending_down, () => _rate(1))),
                  const SizedBox(width: 5),
                  Expanded(child: _Rate(s('good'), Icons.check, () => _rate(2))),
                  const SizedBox(width: 5),
                  Expanded(child: _Rate(s('easy'), Icons.bolt, () => _rate(3))),
                ])
              else
                Padding(padding: const EdgeInsets.only(top: 4), child: Text(s('tap'))),
              if (revealed) Padding(padding: const EdgeInsets.only(top: 5), child: Text(s('swipe'))),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  final String text;
  final String? image;
  final String label;
  const _CardFace({required this.text, required this.image, required this.label});

  @override
  Widget build(BuildContext context) {
    final bytes = tryDecodeBase64Image(image);
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.style_outlined, size: 42),
              const SizedBox(height: 14),
              if (bytes != null) ...[
                SafeMemoryImage(base64: image, height: 190, width: double.infinity, fit: BoxFit.contain, borderRadius: BorderRadius.circular(3)),
                const SizedBox(height: 12),
              ],
              if (text.trim().isNotEmpty) Text(text, textAlign: TextAlign.center, textDirection: Directionality.of(context), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600, height: 1.35)),
              const SizedBox(height: 18),
              Text(label, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).hintColor)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Rate extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  const _Rate(this.text, this.icon, this.onTap);
  @override Widget build(BuildContext context) => OutlinedButton(onPressed: onTap, child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon), Text(text, maxLines: 1, overflow: TextOverflow.ellipsis)]));
}
