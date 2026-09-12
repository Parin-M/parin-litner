import 'package:flutter/material.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/models/app_settings.dart';
import '../../core/services/music_service.dart';
import '../../core/theme/app_theme.dart';
import '../about/about_page.dart';
import '../insights/achievements_page.dart';

class SettingsPage extends StatefulWidget {
  final AppSettings settings;
  final Future<void> Function() onImport;
  final Future<void> Function() onExport;
  final List<dynamic>? decks;
  const SettingsPage({super.key, required this.settings, required this.onImport, required this.onExport, this.decks});
  @override State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final music = MusicService.instance;
  bool previewPlaying = false;
  String s(String key) => AppStrings.t(context, key);

  @override
  void dispose() {
    if (previewPlaying) music.stop();
    super.dispose();
  }

  Future<void> _languagePicker() async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final q = controller.text.trim().toLowerCase();
          final list = AppSettings.languages.where((item) => q.isEmpty || '${item.nativeName} ${item.name} ${item.code}'.toLowerCase().contains(q)).toList();
          return AlertDialog(
            title: Text(s('language')),
            content: SizedBox(
              width: double.maxFinite,
              height: 500,
              child: Column(children: [
                TextField(controller: controller, onChanged: (_) => setDialogState(() {}), decoration: InputDecoration(hintText: s('search'), prefixIcon: const Icon(Icons.search_outlined))),
                const SizedBox(height: 8),
                Expanded(child: ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, index) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final lang = list[index];
                    final active = lang.code == widget.settings.languageCode;
                    return ListTile(
                      leading: CircleAvatar(child: Text(lang.code.split('-').first.toUpperCase())),
                      title: Text(lang.nativeName, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(lang.name),
                      trailing: active ? Icon(Icons.check_circle, color: Theme.of(dialogContext).colorScheme.primary) : null,
                      onTap: () async { await widget.settings.setLanguage(lang.code); if (dialogContext.mounted) Navigator.pop(dialogContext); },
                    );
                  },
                )),
              ]),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(s('cancel')))],
          );
        },
      ),
    );
    controller.dispose();
  }

  Future<void> _togglePreview() async {
    try {
      if (previewPlaying) {
        await music.pause();
      } else {
        await music.play(widget.settings.musicTrack, volume: widget.settings.musicVolume);
      }
      if (mounted) setState(() => previewPlaying = !previewPlaying);
    } catch (_) {
      if (mounted) setState(() => previewPlaying = false);
    }
  }

  Future<void> _openAchievements() async {
    final decks = widget.decks ?? <dynamic>[];
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AchievementsPage(decks: decks.cast(), settings: widget.settings)));
  }

  Future<void> _openAbout() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutPage()));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.settings,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: Text(s('settings'))),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
          children: [
            _Section(title: s('language'), icon: Icons.language_outlined, child: ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.translate_outlined), title: Text(s('ui_language'), style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(AppStrings.names[widget.settings.languageCode] ?? widget.settings.languageCode), trailing: const Icon(Icons.chevron_right), onTap: _languagePicker)),
            const SizedBox(height: 12),
            _Section(title: s('appearance'), icon: Icons.palette_outlined, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s('theme'), style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              SizedBox(height: 92, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: AppTheme.themes.length, separatorBuilder: (_, index) => const SizedBox(width: 9), itemBuilder: (_, index) {
                final theme = AppTheme.themes[index];
                final active = index == widget.settings.themeIndex;
                return InkWell(borderRadius: BorderRadius.circular(18), onTap: () => widget.settings.setTheme(index), child: Container(width: 120, padding: const EdgeInsets.all(8), decoration: BoxDecoration(gradient: LinearGradient(colors: [theme.primary, theme.secondary]), borderRadius: BorderRadius.circular(18), border: Border.all(color: active ? Colors.white : Colors.white54, width: active ? 3 : 1)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(active ? Icons.check_circle : Icons.palette_outlined, color: Colors.white), const SizedBox(height: 4), Text('${index + 1}. ${theme.name}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11))])));
              })),
              SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, title: Text(s('glass')), subtitle: Text(s('glass_sub')), value: widget.settings.glass, onChanged: (v) => widget.settings.setBool('glass', v)),
              if (widget.settings.glass) Row(children: [Expanded(child: Slider(value: widget.settings.glassOpacity, min: .30, max: .90, divisions: 12, onChanged: widget.settings.setGlassOpacity)), Text('${(widget.settings.glassOpacity * 100).round()}%')]),
            ])),
            const SizedBox(height: 12),
            _Section(title: s('experience'), icon: Icons.tune_outlined, child: Column(children: [
              _SwitchRow('animations', Icons.auto_awesome_outlined, widget.settings.animations),
              _SwitchRow('haptics', Icons.vibration_outlined, widget.settings.haptics),
              _SwitchRow('auto_reveal', Icons.flip_outlined, widget.settings.autoReveal),
              _SwitchRow('progress', Icons.linear_scale_outlined, widget.settings.showProgress),
              _SwitchRow('timer', Icons.timer_outlined, widget.settings.showTimer),
              ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.flag_outlined), title: Text(s('daily_goal')), trailing: Text('${widget.settings.dailyGoal}'), subtitle: Slider(value: widget.settings.dailyGoal.toDouble(), min: 5, max: 100, divisions: 19, onChanged: (v) => widget.settings.setDailyGoal(v.round()))),
            ])),
            const SizedBox(height: 12),
            _Section(title: s('music'), icon: Icons.music_note_outlined, child: Column(children: [
              SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, title: Text(s('music_study')), value: widget.settings.musicEnabled, onChanged: (v) async { await widget.settings.setBool('music_enabled', v); if (!v) { await music.stop(); if (mounted) setState(() => previewPlaying = false); } }),
              if (widget.settings.musicEnabled) ...[
                DropdownButtonFormField<String>(initialValue: widget.settings.musicTrack, isExpanded: true, decoration: InputDecoration(labelText: s('music')), items: [for (final track in MusicService.tracks) DropdownMenuItem(value: track.id, child: Text(track.title))], onChanged: (v) async { if (v != null) { await widget.settings.setMusicTrack(v); if (previewPlaying) await music.play(v, volume: widget.settings.musicVolume); } }),
                Row(children: [const Icon(Icons.volume_down_outlined), Expanded(child: Slider(value: widget.settings.musicVolume, min: .05, max: .8, divisions: 15, onChanged: (v) async { await widget.settings.setMusicVolume(v); if (previewPlaying) await music.setVolume(v); })), const Icon(Icons.volume_up_outlined)]),
                Align(alignment: AlignmentDirectional.centerStart, child: OutlinedButton.icon(onPressed: _togglePreview, icon: Icon(previewPlaying ? Icons.pause : Icons.play_arrow), label: Text(s('music_btn')))),
              ],
            ])),
            const SizedBox(height: 12),
            _Section(title: s('backup'), icon: Icons.backup_outlined, child: Row(children: [Expanded(child: OutlinedButton.icon(onPressed: widget.onExport, icon: const Icon(Icons.upload_file_outlined), label: Text(s('export')))), const SizedBox(width: 10), Expanded(child: OutlinedButton.icon(onPressed: widget.onImport, icon: const Icon(Icons.download_outlined), label: Text(s('import'))))])),
            const SizedBox(height: 12),
            _Section(title: '✨ More', icon: Icons.auto_awesome_outlined, child: Column(children: [
              ListTile(contentPadding: EdgeInsets.zero, leading: const CircleAvatar(child: Icon(Icons.workspace_premium_outlined)), title: const Text('Achievement Center', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: const Text('Badges, daily challenges and progress'), trailing: const Icon(Icons.chevron_right), onTap: _openAchievements),
              const Divider(height: 1),
              ListTile(contentPadding: EdgeInsets.zero, leading: const CircleAvatar(child: Icon(Icons.info_outline_rounded)), title: const Text('About', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: const Text('About Parin Litner and its creator'), trailing: const Icon(Icons.chevron_right), onTap: _openAbout),
            ])),
          ],
        ),
      ),
    );
  }

  Widget _SwitchRow(String key, IconData icon, bool value) => SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, secondary: Icon(icon), title: Text(s(key), style: const TextStyle(fontWeight: FontWeight.w700)), value: value, onChanged: (v) => widget.settings.setBool(key, v));
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _Section({required this.title, required this.icon, required this.child});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .72), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: .9)), boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: .08), blurRadius: 20, offset: const Offset(0, 7))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Row(children: [Icon(icon, color: scheme.primary), const SizedBox(width: 8), Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)))]), const Divider(height: 22), child]));
  }
}
