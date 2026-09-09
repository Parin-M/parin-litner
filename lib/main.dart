import 'package:flutter/material.dart';
import 'core/models/app_models.dart';
import 'core/models/app_settings.dart';
import 'core/services/storage_service.dart';
import 'core/services/backup_service.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    await settings.load();
    final data = await storage.load();
    if (data.isEmpty) {
      data.add(Deck(id: 'demo', name: 'شروع سریع', description: 'کارت‌های نمونه'));
      data.first.cards.addAll([
        FlashCard(id: '1', front: 'Leitner چیست؟', back: 'یک روش مرور فاصله‌دار برای انتقال کارت‌ها بین خانه‌ها.'),
        FlashCard(id: '2', front: 'Flutter چیست؟', back: 'فریم‌ورک ساخت رابط کاربری چندسکویی با Dart.'),
      ]);
    }
    if (mounted) setState(() { decks = data; loading = false; });
  }

  Future<void> _save() async {
    await storage.save(decks);
    if (mounted) setState(() {});
  }

  Future<void> _import() async {
    try {
      final incoming = await backup.importDecks();
      if (incoming == null || !mounted) return;
      final replace = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Import کارت‌ها'),
          content: Text('${incoming.length} دسته پیدا شد. داده‌های فعلی جایگزین شوند؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ادغام')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('جایگزینی')),
          ],
        ),
      );
      if (replace == true) {
        decks = incoming;
      } else {
        for (final d in incoming) {
          final i = decks.indexWhere((x) => x.name == d.name);
          if (i < 0) {
            decks.add(d);
          } else {
            decks[i].cards.addAll(d.cards);
          }
        }
      }
      await _save();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import ناموفق بود: $e')));
    }
  }

  Future<void> _export() async {
    try {
      final ok = await backup.exportDecks(decks);
      if (ok && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فایل پشتیبان ذخیره شد')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export ناموفق بود: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settings,
      builder: (_, __) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Parin Litner',
        theme: AppTheme.light(settings.themeIndex, glass: settings.glass, glassOpacity: settings.glassOpacity),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: loading
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : HomePage(
                  decks: decks,
                  onChanged: _save,
                  onImport: _import,
                  onExport: _export,
                  settings: settings,
                ),
        ),
      ),
    );
  }
}
