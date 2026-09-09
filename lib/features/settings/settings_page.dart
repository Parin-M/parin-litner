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

  Future<void> _chooseLanguage() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s('choose_language')),
        contentPadding: const EdgeInsets.only(top: 10, bottom: 8),
        content: SizedBox(
          width: double.maxFinite,
          height: 430,
          child: ListView.separated(
            itemCount: AppSettings.languages.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, index) {
              final language = AppSettings.languages[index];
              return RadioListTile<String>(
                value: language.code,
                groupValue: widget.settings.languageCode,
                title: Text(language.name),
                onChanged: (value) => Navigator.pop(dialogContext, value),
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(s('cancel')))],
      ),
    );
    if (selected == null) return;
    await widget.settings.setLanguage(selected);
    if (mounted) setState(() {});
  }

  Future<void> _togglePreview() async {
    if (previewPlaying) {
      await music.pause();
    } else {
      await music.play(widget.settings.musicTrack, volume: widget.settings.musicVolume);
    }
    if (mounted) setState(() => previewPlaying = !previewPlaying);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.settings,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: Text(s('settings'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        children: [
          _section(s('language'), Icons.language_outlined, [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              leading: const Icon(Icons.translate_outlined),
              title: Text(s('ui_language')),
              subtitle: Text(AppStrings.names[widget.settings.languageCode] ?? widget.settings.languageCode),
              trailing: const Icon(Icons.chevron_right),
              onTap: _chooseLanguage,
            ),
          ]),
          _section(s('appearance'), Icons.palette_outlined, [
            Padding(padding: const EdgeInsets.fromLTRB(8, 4, 8, 8), child: Text(s('theme'), style: const TextStyle(fontWeight: FontWeight.w600))),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: AppTheme.themes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final theme = AppTheme.themes[i];
                  final selected = i == widget.settings.themeIndex;
                  return InkWell(
                    onTap: () => widget.settings.setTheme(i),
                    child: Container(
                      width: 118,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(color: theme.primary, borderRadius: BorderRadius.circular(3), border: Border.all(color: selected ? Colors.black87 : Colors.transparent, width: 2)),
                      child: Center(child: Text(theme.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                    ),
                  );
                },
              ),
            ),
            SwitchListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 8), title: Text(s('glass')), subtitle: Text(s('glass_sub')), value: widget.settings.glass, onChanged: (v) => widget.settings.setBool('glass', v)),
            if (widget.settings.glass) Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Row(children: [Expanded(child: Slider(value: widget.settings.glassOpacity, min: .30, max: .85, divisions: 11, onChanged: widget.settings.setGlassOpacity)), Text('${(widget.settings.glassOpacity * 100).round()}%')])),
          ]),
          _section(s('music'), Icons.music_note_outlined, [
            SwitchListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 8), title: Text(s('music_study')), value: widget.settings.musicEnabled, onChanged: (v) async { await widget.settings.setBool('music_enabled', v); if (!v) { await music.stop(); if (mounted) setState(() => previewPlaying = false); } }),
            if (widget.settings.musicEnabled) ...[
              Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: DropdownButtonFormField<String>(value: widget.settings.musicTrack, isExpanded: true, decoration: InputDecoration(labelText: s('music')), items: [for (final track in MusicService.tracks) DropdownMenuItem(value: track.id, child: Text(track.title))], onChanged: (v) async { if (v != null) { await widget.settings.setMusicTrack(v); if (previewPlaying) await music.play(v, volume: widget.settings.musicVolume); } })),
              Row(children: [const Icon(Icons.volume_down_outlined), Expanded(child: Slider(value: widget.settings.musicVolume, min: .05, max: .8, divisions: 15, onChanged: (v) async { await widget.settings.setMusicVolume(v); if (previewPlaying) await music.setVolume(v); })), const Icon(Icons.volume_up_outlined)]),
              Align(alignment: AlignmentDirectional.centerStart, child: OutlinedButton.icon(onPressed: _togglePreview, icon: Icon(previewPlaying ? Icons.pause : Icons.play_arrow), label: Text(s('music_btn')))),
            ],
          ]),
          _section(s('experience'), Icons.tune_outlined, [
            _toggle('animations', Icons.animation_outlined),
            _toggle('haptics', Icons.vibration_outlined),
            _toggle('auto_reveal', Icons.flip_to_front_outlined),
            _toggle('progress', Icons.linear_scale_outlined),
            _toggle('timer', Icons.timer_outlined),
            ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 8), leading: const Icon(Icons.flag_outlined), title: Text(s('daily_goal')), trailing: Text('${widget.settings.dailyGoal}'), subtitle: Slider(value: widget.settings.dailyGoal.toDouble(), min: 5, max: 100, divisions: 19, onChanged: (v) => widget.settings.setDailyGoal(v.round()))),
          ]),
          _section(s('backup'), Icons.backup_outlined, [
            ButtonBar(alignment: MainAxisAlignment.start, children: [OutlinedButton.icon(onPressed: widget.onExport, icon: const Icon(Icons.upload_file_outlined), label: Text(s('export'))), OutlinedButton.icon(onPressed: widget.onImport, icon: const Icon(Icons.download_outlined), label: Text(s('import')))]),
          ]),
        ],
      ),
    ),
  );

  Widget _section(String title, IconData icon, List<Widget> children) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: AnimatedGlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, size: 21, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 8), Expanded(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)))]),
      const Divider(height: 18),
      ...children,
    ])),
  );

  Widget _toggle(String key, IconData icon) {
    final value = switch (key) {
      'animations' => widget.settings.animations,
      'haptics' => widget.settings.haptics,
      'auto_reveal' => widget.settings.autoReveal,
      'progress' => widget.settings.showProgress,
      'timer' => widget.settings.showTimer,
      _ => false,
    };
    return SwitchListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 8), secondary: Icon(icon), title: Text(s(key)), value: value, onChanged: (v) => widget.settings.setBool(key, v));
  }
}
