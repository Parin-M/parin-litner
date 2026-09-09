import 'package:flutter/material.dart';
import '../../core/models/app_settings.dart';
import '../../core/services/music_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/app_strings.dart';
import '../../shared/widgets/animated_glass_card.dart';

class SettingsPage extends StatefulWidget {
  final AppSettings settings;
  final Future<void> Function() onImport;
  final Future<void> Function() onExport;
  const SettingsPage({super.key, required this.settings, required this.onImport, required this.onExport});
  @override State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final music = MusicService.instance;
  bool previewPlaying = false;
  String s(String key) => AppStrings.t(context, key);

  @override
  void dispose() { if (previewPlaying) music.stop(); super.dispose(); }

  Future<void> _togglePreview() async {
    if (previewPlaying) { await music.pause(); } else { await music.play(widget.settings.musicTrack, volume: widget.settings.musicVolume); }
    if (mounted) setState(() => previewPlaying = !previewPlaying);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.settings,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: Text(s('settings'), style: const TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 36), children: [
        _SectionTitle(s('language')),
        AnimatedGlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s('ui_language'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6), Text(s('choose_language')), const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('language-${widget.settings.languageCode}'),
            initialValue: widget.settings.languageCode,
            isExpanded: true,
            decoration: InputDecoration(prefixIcon: const Icon(Icons.language_rounded), labelText: s('language')),
            items: [for (final language in AppSettings.languages) DropdownMenuItem(value: language.code, child: Text(language.name))],
            onChanged: (value) async { if (value != null) await widget.settings.setLanguage(value); },
          ),
        ])),
        const SizedBox(height: 18),
        _SectionTitle(s('appearance')),
        AnimatedGlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s('theme'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), const SizedBox(height: 12),
          SizedBox(height: 82, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: AppTheme.themes.length, separatorBuilder: (_, __) => const SizedBox(width: 10), itemBuilder: (context, i) {
            final t = AppTheme.themes[i]; final selected = i == widget.settings.themeIndex;
            return GestureDetector(onTap: () => widget.settings.setTheme(i), child: AnimatedContainer(duration: const Duration(milliseconds: 280), width: 102, padding: const EdgeInsets.all(9), decoration: BoxDecoration(gradient: LinearGradient(colors: [t.primary, t.secondary]), borderRadius: BorderRadius.circular(20), border: Border.all(color: selected ? Colors.white : Colors.white54, width: selected ? 3 : 1)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(selected ? Icons.check_circle_rounded : Icons.palette_outlined, color: Colors.white), const SizedBox(height: 4), Text(t.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11))])));
          })),
          SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, title: Text(s('glass'), style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(s('glass_sub')), value: widget.settings.glass, onChanged: (v) => widget.settings.setBool('glass', v)),
          if (widget.settings.glass) ...[Text('${s('glass')}: ${(widget.settings.glassOpacity * 100).round()}%'), Slider(value: widget.settings.glassOpacity, min: .30, max: .85, divisions: 11, onChanged: widget.settings.setGlassOpacity)],
        ])),
        const SizedBox(height: 18),
        _SectionTitle(s('music')),
        AnimatedGlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, secondary: Icon(Icons.music_note_rounded, color: Theme.of(context).colorScheme.primary), title: Text(s('music_study'), style: const TextStyle(fontWeight: FontWeight.w900)), value: widget.settings.musicEnabled, onChanged: (v) async { await widget.settings.setBool('music_enabled', v); if (!v) await music.stop(); }),
          if (widget.settings.musicEnabled) ...[
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(initialValue: widget.settings.musicTrack, isExpanded: true, decoration: InputDecoration(prefixIcon: const Icon(Icons.library_music_rounded), labelText: s('music')), items: [for (final track in MusicService.tracks) DropdownMenuItem(value: track.id, child: Text(track.title))], onChanged: (v) async { if (v != null) { await widget.settings.setMusicTrack(v); if (previewPlaying) await music.play(v, volume: widget.settings.musicVolume); } }),
            Row(children: [const Icon(Icons.volume_down_rounded), Expanded(child: Slider(value: widget.settings.musicVolume, min: .05, max: .8, divisions: 15, onChanged: (v) async { await widget.settings.setMusicVolume(v); if (previewPlaying) await music.setVolume(v); })), const Icon(Icons.volume_up_rounded)]),
            OutlinedButton.icon(onPressed: _togglePreview, icon: Icon(previewPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded), label: Text(previewPlaying ? s('cancel') : s('music_btn'))),
          ],
        ])),
        const SizedBox(height: 18),
        _SectionTitle(s('experience')),
        AnimatedGlassCard(child: Column(children: [
          _SwitchRow(Icons.auto_awesome_rounded, s('animations'), widget.settings.animations, (v) => widget.settings.setBool('animations', v)),
          _SwitchRow(Icons.vibration_rounded, s('haptics'), widget.settings.haptics, (v) => widget.settings.setBool('haptics', v)),
          _SwitchRow(Icons.flip_rounded, s('auto_reveal'), widget.settings.autoReveal, (v) => widget.settings.setBool('auto_reveal', v)),
          _SwitchRow(Icons.linear_scale_rounded, s('progress'), widget.settings.showProgress, (v) => widget.settings.setBool('show_progress', v)),
          _SwitchRow(Icons.timer_outlined, s('timer'), widget.settings.showTimer, (v) => widget.settings.setBool('show_timer', v)),
        ])),
        const SizedBox(height: 18),
        _SectionTitle(s('daily_goal')),
        AnimatedGlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(Icons.flag_rounded), const SizedBox(width: 10), Text(s('daily_goal'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)), const Spacer(), Text('${widget.settings.dailyGoal}')]), Slider(value: widget.settings.dailyGoal.toDouble(), min: 5, max: 100, divisions: 19, onChanged: (v) => widget.settings.setDailyGoal(v.round()))])),
        const SizedBox(height: 18),
        _SectionTitle(s('backup')),
        AnimatedGlassCard(child: Row(children: [Expanded(child: FilledButton.icon(onPressed: widget.onExport, icon: const Icon(Icons.file_upload_outlined), label: Text(s('export')))), const SizedBox(width: 10), Expanded(child: OutlinedButton.icon(onPressed: widget.onImport, icon: const Icon(Icons.file_download_outlined), label: Text(s('import'))))])),
        const SizedBox(height: 18),
        _SectionTitle(s('extra')),
        AnimatedGlassCard(child: Column(children: [
          _ActionRow(Icons.photo_library_rounded, s('add_image')),
          _ActionRow(Icons.layers_rounded, s('boxes')),
          _ActionRow(Icons.category_rounded, s('decks')),
          _ActionRow(Icons.swipe_rounded, s('swipe')),
          _ActionRow(Icons.auto_graph_rounded, s('experience')),
          _ActionRow(Icons.favorite_rounded, s('favorites')),
        ])),
      ]),
    ),
  );
}

class _SectionTitle extends StatelessWidget { final String text; const _SectionTitle(this.text); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(text, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary))); }
class _SwitchRow extends StatelessWidget { final IconData icon; final String title; final bool value; final ValueChanged<bool> onChanged; const _SwitchRow(this.icon, this.title, this.value, this.onChanged); @override Widget build(BuildContext context) => SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, secondary: Icon(icon, color: Theme.of(context).colorScheme.primary), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), value: value, onChanged: onChanged); }
class _ActionRow extends StatelessWidget { final IconData icon; final String title; const _ActionRow(this.icon, this.title); @override Widget build(BuildContext context) => ListTile(contentPadding: EdgeInsets.zero, leading: CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: .10), child: Icon(icon, color: Theme.of(context).colorScheme.primary)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800))); }
