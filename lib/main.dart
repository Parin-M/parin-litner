import 'package:flutter/material.dart';
import 'core/models/app_models.dart';
import 'core/models/app_settings.dart';
import 'core/services/storage_service.dart';
import 'core/services/backup_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/helpers.dart';
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
  String? startupError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // Settings are optional at startup. A storage/plugin failure must never
      // prevent the application shell from being displayed.
      try {
        await settings.load();
      } catch (_) {}

      List<Deck> data;
      try {
        data = await storage.load();
      } catch (_) {
        data = [];
      }

      if (data.isEmpty) {
        data = [Deck(id: 'demo', name: 'شروع سریع', description: 'کارت‌های نمونه')];
        data.first.cards.addAll([
          FlashCard(id: '1', front: 'Leitner چیست؟', back: 'یک روش مرور فاصله‌دار برای انتقال کارت‌ها بین خانه‌ها.'),
          FlashCard(id: '2', front: 'Flutter چیست؟', back: 'فریم‌ورک ساخت رابط کاربری چندسکویی با Dart.'),
        ]);
      }

      if (!mounted) return;
      setState(() {
        decks = data;
        loading = false;
      });
    } catch (e) {
      // Last-resort fallback: always render a usable app instead of leaving
      // the launcher activity on a blank/crashed screen.
      if (!mounted) return;
      setState(() {
        decks = [Deck(id: 'demo', name: 'شروع سریع', description: 'کارت‌های نمونه')];
        decks.first.cards.addAll([
          FlashCard(id: '1', front: 'خوش آمدید', back: 'برنامه Parin Litner آماده است.'),
        ]);
        startupError = e.toString();
        loading = false;
      });
    }
  }

  Future<void> _save() async {
    try {
      await storage.save(decks);
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _import() async {
    try {
      final incoming = await backup.importDecks();
      if (incoming == null || !mounted) return;

      final replace = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('وارد کردن پشتیبان'),
          content: Text(
            '${incoming.length} دسته پیدا شد.\n\n'
            '«ادغام» اطلاعات جدید را کنار اطلاعات فعلی اضافه می‌کند.\n'
            '«جایگزینی» کل اطلاعات فعلی را با فایل پشتیبان عوض می‌کند.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ادغام')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('جایگزینی')),
          ],
        ),
      );

      if (replace == null) return;

      if (replace) {
        decks = incoming;
      } else {
        for (final sourceDeck in incoming) {
          final targetIndex = decks.indexWhere(
            (target) => target.name.trim().toLowerCase() == sourceDeck.name.trim().toLowerCase(),
          );

          if (targetIndex < 0) {
            decks.add(sourceDeck);
            continue;
          }

          final target = decks[targetIndex];
          final boxIndexMap = <int, int>{};

          for (var sourceIndex = 0; sourceIndex < sourceDeck.boxes.length; sourceIndex++) {
            final sourceBox = sourceDeck.boxes[sourceIndex];
            var targetBoxIndex = target.boxes.indexWhere(
              (box) => box.name.trim().toLowerCase() == sourceBox.name.trim().toLowerCase(),
            );

            if (targetBoxIndex < 0) {
              target.boxes.add(
                LeitnerBox(
                  id: uid(),
                  name: sourceBox.name,
                  colorValue: sourceBox.colorValue,
                ),
              );
              targetBoxIndex = target.boxes.length - 1;
            }
            boxIndexMap[sourceIndex] = targetBoxIndex;
          }

          final existingIds = target.cards.map((card) => card.id).toSet();
          for (final sourceCard in sourceDeck.cards) {
            if (existingIds.contains(sourceCard.id)) continue;
            final copied = FlashCard(
              id: uid(),
              front: sourceCard.front,
              back: sourceCard.back,
              tags: sourceCard.tags,
              boxIndex: boxIndexMap[sourceCard.boxIndex] ?? 0,
              dueAt: sourceCard.dueAt,
              favorite: sourceCard.favorite,
              reviews: sourceCard.reviews,
              lapses: sourceCard.lapses,
            );
            target.cards.add(copied);
            existingIds.add(copied.id);
          }
        }
      }

      await _save();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${incoming.length} دسته با موفقیت وارد شد ✓')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('وارد کردن فایل ناموفق بود: $e')),
        );
      }
    }
  }

  Future<void> _export() async {
    try {
      final ok = await backup.exportDecks(decks);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فایل پشتیبان ذخیره شد ✓')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خروجی گرفتن ناموفق بود: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settings,
      builder: (_, __) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Parin Litner',
        theme: AppTheme.light(
          settings.themeIndex,
          glass: settings.glass,
          glassOpacity: settings.glassOpacity,
        ),
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
