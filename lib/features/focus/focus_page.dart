import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/models/app_settings.dart';
import '../../core/services/music_service.dart';

class FocusPage extends StatefulWidget {
  final AppSettings settings;
  const FocusPage({super.key, required this.settings});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> {
  Timer? _timer;
  int _selectedMinutes = 25;
  int _remaining = 25 * 60;
  bool _running = false;
  bool _musicPlaying = false;

  String s(String key) => AppStrings.t(context, key);

  void _selectMinutes(int minutes) {
    if (_running) return;
    setState(() {
      _selectedMinutes = minutes;
      _remaining = minutes * 60;
    });
  }

  Future<void> _toggle() async {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    setState(() => _running = true);
    if (widget.settings.musicEnabled && !_musicPlaying) {
      try {
        await MusicService.instance.play(widget.settings.musicTrack, volume: widget.settings.musicVolume);
        if (mounted) setState(() => _musicPlaying = true);
      } catch (_) {}
    }
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) return;
      if (_remaining <= 1) {
        _timer?.cancel();
        setState(() {
          _remaining = 0;
          _running = false;
        });
        if (_musicPlaying) {
          await MusicService.instance.stop();
          if (mounted) setState(() => _musicPlaying = false);
        }
        if (mounted) {
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(s('focus_done')),
              content: Text('${_selectedMinutes} ${s('focus_minutes')}'),
              actions: [FilledButton(onPressed: () => Navigator.pop(context), child: Text(s('great')))],
            ),
          );
        }
        return;
      }
      setState(() => _remaining--);
    });
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _remaining = _selectedMinutes * 60;
    });
  }

  String _formatTime() {
    final minutes = (_remaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_musicPlaying) MusicService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = _selectedMinutes * 60;
    final progress = total == 0 ? 0.0 : (1 - _remaining / total).clamp(0.0, 1.0).toDouble();
    return Scaffold(
      appBar: AppBar(title: Text(s('focus_mode'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(26),
              child: Column(
                children: [
                  Icon(Icons.self_improvement_outlined, size: 54, color: scheme.primary),
                  const SizedBox(height: 10),
                  Text(s('focus_title'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(s('focus_sub'), textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 28),
                  Stack(alignment: Alignment.center, children: [
                    SizedBox(width: 220, height: 220, child: CircularProgressIndicator(value: progress, strokeWidth: 12)),
                    Text(_formatTime(), style: const TextStyle(fontSize: 46, fontWeight: FontWeight.w900)),
                  ]),
                  const SizedBox(height: 28),
                  Text(s('select_duration'), style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  SegmentedButton<int>(segments: [
                    ButtonSegment(value: 15, label: Text(s('minutes_15'))),
                    ButtonSegment(value: 25, label: Text(s('minutes_25'))),
                    ButtonSegment(value: 45, label: Text(s('minutes_45'))),
                  ], selected: {_selectedMinutes}, onSelectionChanged: (value) => _selectMinutes(value.first)),
                  const SizedBox(height: 22),
                  Row(children: [
                    Expanded(child: FilledButton.icon(onPressed: _toggle, icon: Icon(_running ? Icons.pause : Icons.play_arrow), label: Text(_running ? s('pause') : s('start_focus')))),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(onPressed: _reset, tooltip: s('reset'), icon: const Icon(Icons.restart_alt)),
                  ]),
                  if (widget.settings.musicEnabled) ...[
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(_musicPlaying ? Icons.music_note : Icons.music_off),
                      title: Text(s('focus_music')),
                      trailing: Switch(value: _musicPlaying, onChanged: (_) => _toggleMusic()),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleMusic() async {
    if (_musicPlaying) {
      await MusicService.instance.pause();
      if (mounted) setState(() => _musicPlaying = false);
    } else {
      try {
        await MusicService.instance.play(widget.settings.musicTrack, volume: widget.settings.musicVolume);
        if (mounted) setState(() => _musicPlaying = true);
      } catch (_) {}
    }
  }
}
