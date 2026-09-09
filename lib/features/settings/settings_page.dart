import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SettingsPage extends StatelessWidget {
  final int themeIndex;
  final ValueChanged<int> onThemeChanged;
  const SettingsPage({super.key, required this.themeIndex, required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات', style: TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
        children: [
          const Text('ظاهر برنامه', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text('تم روشن، شیشه‌ای و مینیمال را انتخاب کن یا از ۸ پالت رنگی دیگر استفاده کن.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(.62))),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: AppTheme.themes.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.05),
            itemBuilder: (_, i) {
              final t = AppTheme.themes[i]; final selected = i == themeIndex;
              return InkWell(
                borderRadius: BorderRadius.circular(22), onTap: () => onThemeChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220), padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [t.primary.withOpacity(.9), t.secondary.withOpacity(.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: selected ? Colors.white : Colors.white.withOpacity(.35), width: selected ? 2.5 : 1),
                    boxShadow: [BoxShadow(color: t.primary.withOpacity(.18), blurRadius: 18)],
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(selected ? Icons.check_circle_rounded : Icons.palette_outlined, color: Colors.white, size: 28),
                    const SizedBox(height: 7), Text(t.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  ]),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          _SettingCard(icon: Icons.auto_awesome_rounded, title: 'انیمیشن‌ها', subtitle: 'حرکت نرم، شیشه‌ای و Flip سه‌بعدی کارت‌ها'),
          _SettingCard(icon: Icons.security_rounded, title: 'پشتیبان‌گیری', subtitle: 'انتقال کامل داده‌ها با Import / Export'),
          _SettingCard(icon: Icons.phone_android_rounded, title: 'طراحی واکنش‌گرا', subtitle: 'مناسب موبایل با Material 3 و RTL فارسی'),
        ],
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final IconData icon; final String title, subtitle;
  const _SettingCard({required this.icon, required this.title, required this.subtitle});
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(.58), borderRadius: BorderRadius.circular(20), border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(.10))),
      child: ListTile(contentPadding: EdgeInsets.zero, leading: CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(.12), child: Icon(icon, color: Theme.of(context).colorScheme.primary)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(subtitle)),
    ),
  );
}
