import 'package:flutter/material.dart';
import 'core/models/app_models.dart';
import 'core/models/app_settings.dart';
import 'core/services/storage_service.dart';
import 'core/services/backup_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/helpers.dart';
import 'core/i18n/app_strings.dart';
import 'features/home/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorWidget.builder = (details) => Material(
        color: const Color(0xFFF3F6FF),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Parin Litner\n\nخطای نمایش این بخش رخ داد. لطفاً دوباره تلاش کنید.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
  runApp(const ParinLitnerApp());
}

class ParinLitnerApp extends StatefulWidget {
  const ParinLitnerApp({super.key});
  @override
  State<ParinLitnerApp> createState() => _ParinLitnerAppState();
}

class _ParinLitnerAppState extends State<ParinLitnerApp> {
  final storage = StorageService();
  final backup = BackupService();
  final settings = AppSettings();
  List<Deck> decks = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      try { await settings.load(); } catch (_) {}
      List<Deck> data;
      try { data = await storage.load(); } catch (_) { data = []; }
      if (data.isEmpty) {
        data = [Deck(id: 'demo', name: 'شروع سریع', description: 'کارت‌های نمونه')];
        data.first.cards.addAll([
          FlashCard(id: '1', front: 'Leitner چیست؟', back: 'یک روش مرور فاصله‌دار برای انتقال کارت‌ها بین خانه‌ها.'),
          FlashCard(id: '2', front: 'Flutter چیست؟', back: 'فریم‌ورک ساخت رابط کاربری چندسکویی با Dart.'),
        ]);
      }
      if (!mounted) return;
      setState(() { decks = data; loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        decks = [Deck(id: 'demo', name: 'Parin Litner', description: 'Ready to learn')];
        loading = false;
      });
    }
  }

  Future<void> _save() async {
    try { await storage.save(decks); } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _import() async {
    try {
      final incoming = await backup.importDecks();
      if (incoming == null || !mounted) return;
      final replace = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(AppStrings.t(context, 'import')),
          content: Text('${incoming.length} ${AppStrings.t(context, 'backup_found')}'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppStrings.t(context, 'merge'))),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(AppStrings.t(context, 'replace'))),
          ],
        ),
      );
      if (replace == null) return;
      if (replace) {
        decks = incoming;
      } else {
        for (final source in incoming) {
          final targetIndex = decks.indexWhere((d) => d.name.trim().toLowerCase() == source.name.trim().toLowerCase());
          if (targetIndex < 0) { decks.add(source); continue; }
          final target = decks[targetIndex];
          final map = <int, int>{};
          for (var i = 0; i < source.boxes.length; i++) {
            final sb = source.boxes[i];
            var ti = target.boxes.indexWhere((b) => b.name.trim().toLowerCase() == sb.name.trim().toLowerCase());
            if (ti < 0) { target.boxes.add(LeitnerBox(id: uid(), name: sb.name, colorValue: sb.colorValue)); ti = target.boxes.length - 1; }
            map[i] = ti;
          }
          final ids = target.cards.map((c) => c.id).toSet();
          for (final sc in source.cards) {
            if (ids.contains(sc.id)) continue;
            final cc = FlashCard(id: uid(), front: sc.front, back: sc.back, tags: sc.tags, boxIndex: map[sc.boxIndex] ?? 0, dueAt: sc.dueAt, favorite: sc.favorite, reviews: sc.reviews, lapses: sc.lapses, frontImage: sc.frontImage, backImage: sc.backImage);
            target.cards.add(cc);
            ids.add(cc.id);
          }
        }
      }
      await _save();
    } catch (_) {}
  }

  Future<void> _export() async { try { await backup.exportDecks(decks); } catch (_) {} }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: settings,
        builder: (context, _) {
          final localeParts = settings.languageCode.split('-');
          final locale = Locale.fromSubtags(
            languageCode: localeParts.first,
            countryCode: localeParts.length > 1 ? localeParts[1] : null,
          );
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Parin Litner',
            locale: locale,
            supportedLocales: [
              for (final l in AppSettings.languages)
                Locale.fromSubtags(
                  languageCode: l.code.split('-').first,
                  countryCode: l.code.contains('-') ? l.code.split('-')[1] : null,
                ),
            ],
            theme: AppTheme.light(settings.themeIndex, glass: settings.glass, glassOpacity: settings.glassOpacity),
            home: LocaleScope(
              settings: settings,
              child: Directionality(
                textDirection: settings.language.rtl ? TextDirection.rtl : TextDirection.ltr,
                child: loading
                    ? const Scaffold(body: Center(child: CircularProgressIndicator()))
                    : HomePage(decks: decks, onChanged: _save, onImport: _import, onExport: _export, settings: settings),
              ),
            ),
          );
        },
      );
}
