import 'package:flutter/material.dart';
import '../../core/models/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/animated_glass_card.dart';

class SettingsPage extends StatelessWidget {
  final AppSettings settings;
  final Future<void> Function() onImport;
  final Future<void> Function() onExport;
  const SettingsPage({super.key, required this.settings, required this.onImport, required this.onExport});

  @override Widget build(BuildContext context) => AnimatedBuilder(animation: settings, builder: (context, _) => Scaffold(
    appBar: AppBar(title: const Text('تنظیمات', style: TextStyle(fontWeight: FontWeight.w900))),
    body: ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 36), children: [
      const _SectionTitle('زبان برنامه'),
      AnimatedGlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('زبان رابط کاربری', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6), const Text('زبان مورد نظر را انتخاب کن. فارسی، انگلیسی و ۱۳ زبان دیگر پشتیبانی می‌شوند.'),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: settings.languageCode, decoration: const InputDecoration(prefixIcon: Icon(Icons.language_rounded), labelText: 'زبان'),
          items: [for (final language in AppSettings.languages) DropdownMenuItem(value: language.code, child: Text(language.name))], onChanged: (v) { if (v != null) settings.setLanguage(v); }),
      ])),
      const SizedBox(height: 18), const _SectionTitle('ظاهر و شیشه‌ای'),
      AnimatedGlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('تم رنگی', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), const SizedBox(height: 12),
        SizedBox(height: 82, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: AppTheme.themes.length, separatorBuilder: (_, __) => const SizedBox(width: 10), itemBuilder: (context, i) { final t = AppTheme.themes[i]; final selected = i == settings.themeIndex; return GestureDetector(onTap: () => settings.setTheme(i), child: AnimatedContainer(duration: const Duration(milliseconds: 280), width: 92, padding: const EdgeInsets.all(9), decoration: BoxDecoration(gradient: LinearGradient(colors: [t.primary, t.secondary]), borderRadius: BorderRadius.circular(20), border: Border.all(color: selected ? Colors.white : Colors.white54, width: selected ? 3 : 1)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(selected ? Icons.check_circle_rounded : Icons.palette_outlined, color: Colors.white), const SizedBox(height: 4), Text(t.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11))]))); })),
        const SizedBox(height: 8), SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, title: const Text('Glassmorphism', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: const Text('Blur، شفافیت، حاشیه نورانی و عمق بیشتر'), value: settings.glass, onChanged: (v) => settings.setBool('glass', v)),
        if (settings.glass) ...[Text('شدت شفافیت: ${(settings.glassOpacity * 100).round()}٪'), Slider(value: settings.glassOpacity, min: .30, max: .85, divisions: 11, onChanged: settings.setGlassOpacity)],
      ])),
      const SizedBox(height: 18), const _SectionTitle('تجربه و مرور هوشمند'),
      AnimatedGlassCard(child: Column(children: [
        _SwitchRow(Icons.auto_awesome_rounded, 'انیمیشن‌های ویژه', 'حرکت کارت‌ها و افکت‌های نرم', settings.animations, (v) => settings.setBool('animations', v)),
        _SwitchRow(Icons.vibration_rounded, 'بازخورد لمسی', 'هنگام امتیازدهی', settings.haptics, (v) => settings.setBool('haptics', v)),
        _SwitchRow(Icons.flip_rounded, 'نمایش خودکار پاسخ', 'پاسخ کارت به صورت خودکار باز شود', settings.autoReveal, (v) => settings.setBool('auto_reveal', v)),
        _SwitchRow(Icons.linear_scale_rounded, 'نمایش پیشرفت', 'نوار پیشرفت جلسه', settings.showProgress, (v) => settings.setBool('show_progress', v)),
        _SwitchRow(Icons.timer_outlined, 'تایمر مرور', 'زمان جلسه روی صفحه', settings.showTimer, (v) => settings.setBool('show_timer', v)),
      ])),
      const SizedBox(height: 18), const _SectionTitle('هدف روزانه'),
      AnimatedGlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(Icons.flag_rounded), const SizedBox(width: 10), const Text('هدف مرور روزانه', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)), const Spacer(), Text('${settings.dailyGoal} کارت', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900))]), Slider(value: settings.dailyGoal.toDouble(), min: 5, max: 100, divisions: 19, label: '${settings.dailyGoal}', onChanged: (v) => settings.setDailyGoal(v.round()))])),
      const SizedBox(height: 18), const _SectionTitle('پشتیبان‌گیری'),
      AnimatedGlassCard(child: Column(children: [const Text('تمام دسته‌ها، کارت‌ها، خانه‌ها، تصاویر کارت، تگ‌ها و وضعیت مرور در فایل JSON ذخیره می‌شوند.'), const SizedBox(height: 14), Row(children: [Expanded(child: FilledButton.icon(onPressed: onExport, icon: const Icon(Icons.file_upload_outlined), label: const Text('خروجی گرفتن'))), const SizedBox(width: 10), Expanded(child: OutlinedButton.icon(onPressed: onImport, icon: const Icon(Icons.file_download_outlined), label: const Text('وارد کردن')))]), const SizedBox(height: 10), const Text('فایل پشتیبان را روی دستگاه دیگر منتقل کن و واردش کن.', style: TextStyle(fontSize: 12))])),
      const SizedBox(height: 18), const _SectionTitle('قابلیت‌های بیشتر'),
      const AnimatedGlassCard(child: Column(children: [
        _ActionRow(Icons.photo_library_rounded, 'کارت‌های تصویری', 'برای هر دو طرف کارت عکس اضافه کن.'),
        _ActionRow(Icons.layers_rounded, 'خانه‌های نامحدود', 'هر تعداد خانه که لازم داری بساز، تغییر نام بده یا حذف کن.'),
        _ActionRow(Icons.category_rounded, 'مدیریت دسته‌ها', 'دسته‌ها را تغییر نام بده یا حذف کن.'),
        _ActionRow(Icons.swipe_rounded, 'امتیازدهی با حرکت', 'در صفحه مرور کارت را به چپ یا راست بکش.'),
      ])),
    ],),
  ));
}
class _SectionTitle extends StatelessWidget { final String text; const _SectionTitle(this.text); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(text, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary))); }
class _SwitchRow extends StatelessWidget { final IconData icon; final String title, subtitle; final bool value; final ValueChanged<bool> onChanged; const _SwitchRow(this.icon, this.title, this.subtitle, this.value, this.onChanged); @override Widget build(BuildContext context) => SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, secondary: Icon(icon, color: Theme.of(context).colorScheme.primary), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(subtitle), value: value, onChanged: onChanged); }
class _ActionRow extends StatelessWidget { final IconData icon; final String title, subtitle; const _ActionRow(this.icon, this.title, this.subtitle); @override Widget build(BuildContext context) => ListTile(contentPadding: EdgeInsets.zero, leading: CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: .10), child: Icon(icon, color: Theme.of(context).colorScheme.primary)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(subtitle)); }
