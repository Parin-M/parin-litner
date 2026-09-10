import 'package:flutter/material.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/models/app_settings.dart';
import '../../core/services/music_service.dart';
import '../../core/theme/app_theme.dart';

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
  String search = '';

  String s(String key) => AppStrings.t(context, key);

  @override
  void dispose() {
    if (previewPlaying) music.stop();
    super.dispose();
  }

  Future<void> _languagePicker() async {
    final controller = TextEditingController();
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final needle = controller.text.trim().toLowerCase();
            final languages = AppSettings.languages.where((item) {
              return needle.isEmpty || '${item.nativeName} ${item.name} ${item.code}'.toLowerCase().contains(needle);
            }).toList();
            return AlertDialog(
              title: Text(s('language')),
              content: SizedBox(
                width: double.maxFinite,
                height: 520,
                child: Column(
                  children: [
                    TextField(
                      controller: controller,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: s('search')),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.separated(
                        itemCount: languages.length,
                        separatorBuilder: (_, index) => const Divider(height: 1),
                        itemBuilder: (_, index) {
                          final language = languages[index];
                          final selected = language.code == widget.settings.languageCode;
                          return ListTile(
                            leading: CircleAvatar(child: Text(language.code.split('-').first.toUpperCase())),
                            title: Text(language.nativeName, style: const TextStyle(fontWeight: FontWeight.w800)),
                            subtitle: Text(language.name),
                            trailing: selected ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary) : null,
                            onTap: () async {
                              await widget.settings.setLanguage(language.code);
                              if (dialogContext.mounted) Navigator.pop(dialogContext);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(s('cancel')))],
            );
          },
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.settings,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: Text(s('settings'))),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
            children: [
              _GlassSection(
                title: s('language'),
                icon: Icons.language_outlined,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.translate_outlined),
                  title: Text(s('ui_language'), style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('${AppStrings.names[widget.settings.languageCode] ?? widget.settings.languageCode} • ${widget.settings.languageCode}'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: _languagePicker,
                ),
              ),
              const SizedBox(height: 12),
              _GlassSection(
                title: s('appearance'),
                icon: Icons.palette_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s('theme'), style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 102,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: AppTheme.themes.length,
                        separatorBuilder: (_, index) => const SizedBox(width: 10),
                        itemBuilder: (_, index) {
                          final theme = AppTheme.themes[index];
                          final active = index == widget.settings.themeIndex;
                          return GestureDetector(
                            onTap: () => widget.settings.setTheme(index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 124,
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [theme.primary, theme.secondary]),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: active ? Colors.white : Colors.white54, width: active ? 3 : 1),
                                boxShadow: [BoxShadow(color: theme.primary.withValues(alpha: .18), blurRadius: 12)],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(active ? Icons.check_circle : Icons.palette_outlined, color: Colors.white),
                                  const SizedBox(height: 4),
                                  Text('${index + 1}. ${theme.name}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(s('glass'), style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(s('glass_sub')),
                      value: widget.settings.glass,
                      onChanged: (value) => widget.settings.setBool('glass', value),
                    ),
                    if (widget.settings.glass)
                      Row(children: [
                        Expanded(child: Slider(value: widget.settings.glassOpacity, min: .30, max: .90, divisions: 12, onChanged: widget.settings.setGlassOpacity)),
                        Text('${(widget.settings.glassOpacity * 100).round()}%'),
                      ]),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _GlassSection(
                title: s('experience'),
                icon: Icons.tune_outlined,
                child: Column(children: [
                  _switchRow('animations', Icons.auto_awesome_outlined, widget.settings.animations),
                  _switchRow('haptics', Icons.vibration_outlined, widget.settings.haptics),
                  _switchRow('auto_reveal', Icons.flip_outlined, widget.settings.autoReveal),
                  _switchRow('progress', Icons.linear_scale_outlined, widget.settings.showProgress),
                  _switchRow('timer', Icons.timer_outlined, widget.settings.showTimer),
                  ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.flag_outlined), title: Text(s('daily_goal')), trailing: Text('${widget.settings.dailyGoal}'), subtitle: Slider(value: widget.settings.dailyGoal.toDouble(), min: 5, max: 100, divisions: 19, onChanged: (v) => widget.settings.setDailyGoal(v.round()))),
                ]),
              ),
              const SizedBox(height: 12),
              _GlassSection(
                title: s('music'),
                icon: Icons.music_note_outlined,
                child: Column(children: [
                  SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, title: Text(s('music_study')), value: widget.settings.musicEnabled, onChanged: (value) async { await widget.settings.setBool('music_enabled', value); if (!value) { await music.stop(); if (mounted) setState(() => previewPlaying = false); } }),
                  if (widget.settings.musicEnabled) ...[
                    DropdownButtonFormField<String>(
                      initialValue: widget.settings.musicTrack,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: s('music')),
                      items: [for (final track in MusicService.tracks) DropdownMenuItem(value: track.id, child: Text(track.title))],
                      onChanged: (value) async { if (value != null) { await widget.settings.setMusicTrack(value); if (previewPlaying) await music.play(value, volume: widget.settings.musicVolume); } },
                    ),
                    Row(children: [const Icon(Icons.volume_down_outlined), Expanded(child: Slider(value: widget.settings.musicVolume, min: .05, max: .8, divisions: 15, onChanged: (value) async { await widget.settings.setMusicVolume(value); if (previewPlaying) await music.setVolume(value); })), const Icon(Icons.volume_up_outlined)]),
                    Align(alignment: AlignmentDirectional.centerStart, child: OutlinedButton.icon(onPressed: () async { if (previewPlaying) { await music.pause(); } else { await music.play(widget.settings.musicTrack, volume: widget.settings.musicVolume); } if (mounted) setState(() => previewPlaying = !previewPlaying); }, icon: Icon(previewPlaying ? Icons.pause : Icons.play_arrow), label: Text(s('music_btn')))),
                  ],
                ]),
              ),
              const SizedBox(height: 12),
              _GlassSection(
                title: s('backup'),
                icon: Icons.backup_outlined,
                child: Row(children: [Expanded(child: OutlinedButton.icon(onPressed: onExport, icon: const Icon(Icons.upload_file_outlined), label: Text(s('export')))), const SizedBox(width: 10), Expanded(child: OutlinedButton.icon(onPressed: onImport, icon: const Icon(Icons.download_outlined), label: Text(s('import'))))]),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _switchRow(String key, IconData icon, bool value) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      secondary: Icon(icon),
      title: Text(s(key), style: const TextStyle(fontWeight: FontWeight.w700)),
      value: value,
      onChanged: (next) => widget.settings.setBool(key, next),
    );
  }
}

class _GlassSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _GlassSection({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .70),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: .88)),
        boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: .07), blurRadius: 22, offset: const Offset(0, 7))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Row(children: [Icon(icon, color: scheme.primary), const SizedBox(width: 8), Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)))]), const Divider(height: 22), child]),
    );
  }
}
