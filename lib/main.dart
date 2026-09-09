import 'package:flutter/material.dart';
import 'core/models/app_models.dart';
import 'core/models/app_settings.dart';
import 'core/services/storage_service.dart';
import 'core/services/backup_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/helpers.dart';
import 'features/home/home_page.dart';

void main() { WidgetsFlutterBinding.ensureInitialized(); runApp(const ParinLitnerApp()); }

class ParinLitnerApp extends StatefulWidget { const ParinLitnerApp({super.key}); @override State<ParinLitnerApp> createState() => _ParinLitnerAppState(); }
class _ParinLitnerAppState extends State<ParinLitnerApp> {
  final storage = StorageService(); final backup = BackupService(); final settings = AppSettings();
  List<Deck> decks = []; bool loading = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { try { await settings.load(); } catch (_) {}
      List<Deck> data; try { data = await storage.load(); } catch (_) { data = []; }
      if (data.isEmpty) { data = [Deck(id: 'demo', name: 'شروع سریع', description: 'کارت‌های نمونه')]; data.first.cards.addAll([FlashCard(id: '1', front: 'Leitner چیست؟', back: 'یک روش مرور فاصله‌دار برای انتقال کارت‌ها بین خانه‌ها.'), FlashCard(id: '2', front: 'Flutter چیست؟', back: 'فریم‌ورک ساخت رابط کاربری چندسکویی با Dart.')]); }
      if (!mounted) return; setState(() { decks = data; loading = false; });
    } catch (_) { if (!mounted) return; setState(() { decks = [Deck(id: 'demo', name: 'Parin Litner', description: 'Ready to learn')]; loading = false; }); }
  }
  Future<void> _save() async { try { await storage.save(decks); } catch (_) {} if (mounted) setState(() {}); }
  Future<void> _import() async { try { final incoming = await backup.importDecks(); if (incoming == null || !mounted) return; final replace = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('وارد کردن پشتیبان'), content: Text('${incoming.length} دسته پیدا شد.\n\n«ادغام» اطلاعات جدید را کنار اطلاعات فعلی اضافه می‌کند.\n«جایگزینی» اطلاعات فعلی را عوض می‌کند.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ادغام')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('جایگزینی'))])); if (replace == null) return; if (replace) { decks = incoming; } else { for (final source in incoming) { final targetIndex = decks.indexWhere((d) => d.name.trim().toLowerCase() == source.name.trim().toLowerCase()); if (targetIndex < 0) { decks.add(source); continue; } final target = decks[targetIndex]; final map = <int,int>{}; for (var i=0;i<source.boxes.length;i++) { final sb=source.boxes[i]; var ti=target.boxes.indexWhere((b)=>b.name.trim().toLowerCase()==sb.name.trim().toLowerCase()); if(ti<0){target.boxes.add(LeitnerBox(id:uid(),name:sb.name,colorValue:sb.colorValue));ti=target.boxes.length-1;} map[i]=ti; } final ids=target.cards.map((c)=>c.id).toSet(); for(final sc in source.cards){ if(ids.contains(sc.id)) continue; final cc=FlashCard(id:uid(),front:sc.front,back:sc.back,tags:sc.tags,boxIndex:map[sc.boxIndex]??0,dueAt:sc.dueAt,favorite:sc.favorite,reviews:sc.reviews,lapses:sc.lapses,frontImage:sc.frontImage,backImage:sc.backImage); target.cards.add(cc); ids.add(cc.id); } } } await _save(); } catch (_) {} }
  Future<void> _export() async { try { await backup.exportDecks(decks); } catch (_) {} }
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: settings, builder: (_, __) => MaterialApp(
    debugShowCheckedModeBanner: false, title: 'Parin Litner', locale: Locale(settings.language.code.split('-').first),
    supportedLocales: [for (final l in AppSettings.languages) Locale(l.code.split('-').first)],
    theme: AppTheme.light(settings.themeIndex, glass: settings.glass, glassOpacity: settings.glassOpacity),
    home: Directionality(textDirection: settings.language.rtl ? TextDirection.rtl : TextDirection.ltr, child: loading ? const Scaffold(body: Center(child: CircularProgressIndicator())) : HomePage(decks: decks, onChanged: _save, onImport: _import, onExport: _export, settings: settings)),
  ));
}
