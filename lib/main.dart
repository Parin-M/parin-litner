import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  late final AppStore store;
  try {
    store = await AppStore.load();
  } catch (_) {
    // Never let a bad/corrupt local preference prevent the app from opening.
    store = AppStore(
      AppStore.seedDecks(),
      darkMode: true,
      xp: 0,
      streak: 0,
      reminderEnabled: true,
      reminderHour: 20,
      reminderMinute: 0,
    );
  }
  runApp(ParinLitnerApp(store: store));
}

class AppStore extends ChangeNotifier {
  AppStore(this.decks, {required this.darkMode, required this.xp, required this.streak, required this.reminderEnabled, required this.reminderHour, required this.reminderMinute});

  List<Deck> decks;
  bool darkMode;
  int xp;
  int streak;
  bool reminderEnabled;
  int reminderHour;
  int reminderMinute;

  static Future<AppStore> load() async {
    final p = await SharedPreferences.getInstance();
    List<Deck> decks = seedDecks();
    final raw = p.getString('decks_v3') ?? p.getString('decks_v2');
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          decks = decoded
              .map((e) => Deck.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      } catch (_) {
        // Keep the safe seed data when old/corrupt local data exists.
        decks = seedDecks();
      }
    }
    return AppStore(
      decks,
      darkMode: p.getBool('dark_v3') ?? p.getBool('dark_v2') ?? true,
      xp: p.getInt('xp_v3') ?? p.getInt('xp_v2') ?? 1250,
      streak: p.getInt('streak_v3') ?? p.getInt('streak_v2') ?? 7,
      reminderEnabled: p.getBool('reminder_enabled') ?? true,
      reminderHour: p.getInt('reminder_hour') ?? 20,
      reminderMinute: p.getInt('reminder_minute') ?? 0,
    );
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('decks_v3', jsonEncode(decks.map((e) => e.toJson()).toList()));
    await p.setBool('dark_v3', darkMode);
    await p.setInt('xp_v3', xp);
    await p.setInt('streak_v3', streak);
    await p.setBool('reminder_enabled', reminderEnabled);
    await p.setInt('reminder_hour', reminderHour);
    await p.setInt('reminder_minute', reminderMinute);
    notifyListeners();
  }

  void toggleTheme() { darkMode = !darkMode; save(); }
  void addDeck(String name) { decks.add(Deck(name: name, icon: Icons.auto_awesome_rounded, cards: [])); save(); }
  void deleteDeck(int i) { decks.removeAt(i); save(); }
  void addCard(int deckIndex, String front, String back, {String tag = ''}) { decks[deckIndex].cards.add(CardItem(front: front, back: back, tag: tag)); save(); }
  void deleteCard(int deckIndex, int cardIndex) { decks[deckIndex].cards.removeAt(cardIndex); save(); }

  void review(CardItem card, int rating) {
    final now = DateTime.now();
    card.reviews++;
    card.lastReviewed = now;
    if (rating == 1) {
      card.box = 1;
      card.intervalDays = 0;
      card.dueAt = now.add(const Duration(minutes: 1));
    } else if (rating == 2) {
      card.intervalDays = math.max(1, (card.intervalDays * 1.2).round()).toInt();
      card.box = math.max(1, card.box).toInt();
      card.dueAt = now.add(Duration(days: card.intervalDays));
    } else if (rating == 3) {
      card.box = math.min(5, card.box + 1).toInt();
      card.intervalDays = _intervalForBox(card.box);
      card.dueAt = now.add(Duration(days: card.intervalDays));
    } else {
      card.box = math.min(5, card.box + 2).toInt();
      card.intervalDays = _intervalForBox(card.box + 1);
      card.dueAt = now.add(Duration(days: card.intervalDays));
    }
    xp += rating == 4 ? 25 : rating == 3 ? 15 : rating == 2 ? 8 : 5;
    save();
  }

  int _intervalForBox(int box) {
    switch (box.clamp(1, 6).toInt()) {
      case 1: return 1;
      case 2: return 2;
      case 3: return 4;
      case 4: return 8;
      case 5: return 16;
      default: return 30;
    }
  }

  List<CardItem> dueCards([int? deckIndex]) {
    final now = DateTime.now();
    final list = <CardItem>[];
    final source = deckIndex == null ? decks : [decks[deckIndex]];
    for (final deck in source) {
      for (final card in deck.cards) if (card.dueAt.isBefore(now) || card.dueAt.isAtSameMomentAs(now)) list.add(card);
    }
    return list;
  }

  int get totalCards => decks.fold(0, (a, d) => a + d.cards.length);
  int get dueCount => dueCards().length;
  int get learnedCount => decks.fold(0, (a, d) => a + d.cards.where((c) => c.box >= 4).length);

  String exportJson() => const JsonEncoder.withIndent('  ').convert({'app': 'Parin Litner', 'version': 2, 'decks': decks.map((e) => e.toJson()).toList()});

  Future<bool> importJson(String raw) async {
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final incoming = (data['decks'] as List).map((e) => Deck.fromJson(Map<String, dynamic>.from(e))).toList();
      decks = incoming;
      await save();
      return true;
    } catch (_) { return false; }
  }

  static List<Deck> seedDecks() => [
    Deck(name: 'انگلیسی', icon: Icons.language_rounded, cards: [
      CardItem(front: 'Sustainable', back: 'پایدار، ماندگار', tag: 'Vocabulary', box: 3),
      CardItem(front: 'Opportunity', back: 'فرصت', tag: 'Vocabulary', box: 2),
      CardItem(front: 'Accurate', back: 'دقیق', tag: 'Vocabulary', box: 4),
      CardItem(front: 'Consistent', back: 'سازگار، ثابت', tag: 'Vocabulary', box: 1),
    ]),
    Deck(name: 'زیست‌شناسی', icon: Icons.eco_rounded, cards: [
      CardItem(front: 'Photosynthesis', back: 'فتوسنتز', tag: 'Plants', box: 2),
      CardItem(front: 'Mitochondria', back: 'میتوکندری', tag: 'Cell', box: 3),
    ]),
    Deck(name: 'برنامه‌نویسی', icon: Icons.code_rounded, cards: [
      CardItem(front: 'Widget', back: 'ویجت / جزء رابط کاربری', tag: 'Flutter', box: 4),
      CardItem(front: 'State', back: 'وضعیت', tag: 'Flutter', box: 3),
    ]),
    Deck(name: 'ریاضی', icon: Icons.functions_rounded, cards: [
      CardItem(front: 'Derivative', back: 'مشتق', tag: 'Calculus', box: 2),
      CardItem(front: 'Integral', back: 'انتگرال', tag: 'Calculus', box: 5),
    ]),
  ];
}

class Deck {
  Deck({required this.name, required this.icon, required this.cards});
  String name;
  IconData icon;
  List<CardItem> cards;
  double get progress => cards.isEmpty ? 0 : cards.where((c) => c.box >= 3).length / cards.length;
  Map<String, dynamic> toJson() => {'name': name, 'icon': icon.codePoint, 'cards': cards.map((e) => e.toJson()).toList()};
  factory Deck.fromJson(Map<String, dynamic> j) => Deck(name: j['name'] as String, icon: IconData((j['icon'] as num?)?.toInt() ?? Icons.layers_rounded.codePoint, fontFamily: 'MaterialIcons'), cards: (j['cards'] as List? ?? []).map((e) => CardItem.fromJson(Map<String, dynamic>.from(e))).toList());
}

class CardItem {
  CardItem({required this.front, required this.back, this.tag = '', this.box = 1, DateTime? dueAt, this.intervalDays = 1, this.reviews = 0, DateTime? lastReviewed}) : dueAt = dueAt ?? DateTime.now();
  String front;
  String back;
  String tag;
  int box;
  int intervalDays;
  int reviews;
  DateTime dueAt;
  DateTime? lastReviewed;
  Map<String, dynamic> toJson() => {'front': front, 'back': back, 'tag': tag, 'box': box, 'intervalDays': intervalDays, 'reviews': reviews, 'dueAt': dueAt.toIso8601String(), 'lastReviewed': lastReviewed?.toIso8601String()};
  factory CardItem.fromJson(Map<String, dynamic> j) => CardItem(front: j['front'] as String, back: j['back'] as String, tag: j['tag'] as String? ?? '', box: (j['box'] as num?)?.toInt() ?? 1, intervalDays: (j['intervalDays'] as num?)?.toInt() ?? 1, reviews: (j['reviews'] as num?)?.toInt() ?? 0, dueAt: DateTime.tryParse(j['dueAt'] as String? ?? '') ?? DateTime.now(), lastReviewed: DateTime.tryParse(j['lastReviewed'] as String? ?? ''));
}

class ParinLitnerApp extends StatelessWidget {
  const ParinLitnerApp({super.key, required this.store});
  final AppStore store;
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: store, builder: (_, __) => MaterialApp(debugShowCheckedModeBanner: false, title: 'Parin Litner', theme: appTheme(false), darkTheme: appTheme(true), themeMode: store.darkMode ? ThemeMode.dark : ThemeMode.light, home: ParinLitnerInherited(store: store, child: HomeShell(store: store))));
}

ThemeData appTheme(bool dark) {
  final base = ColorScheme.fromSeed(seedColor: const Color(0xFF7D6BFF), brightness: dark ? Brightness.dark : Brightness.light);
  return ThemeData(useMaterial3: true, brightness: dark ? Brightness.dark : Brightness.light, colorScheme: base, scaffoldBackgroundColor: dark ? const Color(0xFF07111F) : const Color(0xFFF3F6FB), fontFamily: 'sans');
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.store});
  final AppStore store;
  @override State<HomeShell> createState() => _HomeShellState();
}
class _HomeShellState extends State<HomeShell> with SingleTickerProviderStateMixin {
  int index = 0;
  late final AnimationController ambient;
  @override void initState() { super.initState(); ambient = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat(reverse: true); }
  @override void dispose() { ambient.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final pages = [Dashboard(store: widget.store), DecksPage(store: widget.store), const SizedBox.shrink(), StatsPage(store: widget.store), ProfilePage(store: widget.store)];
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(extendBody: true, body: Stack(children: [AnimatedBuilder(animation: ambient, builder: (_, __) => CustomPaint(painter: AmbientPainter(ambient.value), child: const SizedBox.expand())), SafeArea(child: AnimatedSwitcher(duration: const Duration(milliseconds: 420), transitionBuilder: (child, a) => FadeTransition(opacity: a, child: SlideTransition(position: Tween(begin: const Offset(0, .03), end: Offset.zero).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)), child: child)), child: KeyedSubtree(key: ValueKey(index), child: pages[index])))]), floatingActionButton: FloatingActionButton(onPressed: () => showAddDeck(context), child: const Icon(Icons.add_rounded)), floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked, bottomNavigationBar: GlassNav(index: index, onTap: (i) => setState(() => index = i))));
  }
  Future<void> showAddDeck(BuildContext context) async { final c = TextEditingController(); await showDialog(context: context, builder: (_) => AlertDialog(title: const Text('دسته جدید'), content: TextField(controller: c, autofocus: true, decoration: const InputDecoration(hintText: 'مثلاً لغات IELTS')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('لغو')), FilledButton(onPressed: () { if (c.text.trim().isNotEmpty) widget.store.addDeck(c.text.trim()); Navigator.pop(context); }, child: const Text('ساخت'))])); }
}

class AmbientPainter extends CustomPainter {
  AmbientPainter(this.t); final double t;
  @override void paint(Canvas canvas, Size size) { final p = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 75); p.color = const Color(0xFF7562FF).withOpacity(.16); canvas.drawCircle(Offset(size.width * (.15 + .08 * t), size.height * .12), 130, p); p.color = const Color(0xFF34C6FF).withOpacity(.11); canvas.drawCircle(Offset(size.width * (.85 - .08 * t), size.height * .38), 160, p); p.color = const Color(0xFFFF6BCB).withOpacity(.06); canvas.drawCircle(Offset(size.width * .55, size.height * (.9 - .04 * t)), 170, p); }
  @override bool shouldRepaint(covariant AmbientPainter oldDelegate) => oldDelegate.t != t;
}

class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap});
  final Widget child; final EdgeInsets padding; final VoidCallback? onTap;
  @override Widget build(BuildContext context) { final dark = Theme.of(context).brightness == Brightness.dark; return ClipRRect(borderRadius: BorderRadius.circular(24), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18), child: Material(color: dark ? Colors.white.withOpacity(.055) : Colors.white.withOpacity(.72), child: InkWell(onTap: onTap, child: Container(padding: padding, decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: dark ? Colors.white.withOpacity(.09) : Colors.white, width: 1)), child: child))))); }
}

class Dashboard extends StatelessWidget {
  const Dashboard({super.key, required this.store}); final AppStore store;
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 120), children: [Row(children: [const LogoMark(), const SizedBox(width: 12), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Parin Litner', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)), Text('Learn • Remember • Grow', style: TextStyle(fontSize: 11, color: Colors.white54))])), IconButton(onPressed: store.toggleTheme, icon: Icon(store.darkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded))]), const SizedBox(height: 20), GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('سلام 👋', style: TextStyle(color: Colors.white60)), const SizedBox(height: 5), const Text('امروز چی یاد می‌گیری؟', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)), const SizedBox(height: 20), Row(children: [Metric('🔥', '${store.streak}', 'روز استریک'), Metric('⚡', '${store.xp}', 'XP'), Metric('⏳', '${store.dueCount}', 'مرور امروز')])])), const SizedBox(height: 18), Row(children: [const Expanded(child: Text('دسته‌های من', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))), TextButton(onPressed: () {}, child: const Text('همه'))]), GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: store.decks.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.25), itemBuilder: (_, i) => DeckTile(deck: store.decks[i], onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DeckDetailPage(store: store, deckIndex: i))))), const SizedBox(height: 18), GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(Icons.auto_graph_rounded), const SizedBox(width: 10), const Expanded(child: Text('مرور هوشمند', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800))), Text('${store.dueCount} کارت')]), const SizedBox(height: 15), LinearProgressIndicator(value: store.totalCards == 0 ? 0 : ((store.totalCards - store.dueCount).clamp(0, store.totalCards) / store.totalCards).toDouble(), minHeight: 8, borderRadius: BorderRadius.circular(8)), const SizedBox(height: 9), Text('${store.learnedCount} کارت در باکس‌های ۴ و ۵', style: const TextStyle(fontSize: 12, color: Colors.white54))]))]);
}

class Metric extends StatelessWidget { const Metric(this.icon, this.value, this.label, {super.key}); final String icon, value, label; @override Widget build(BuildContext c) => Expanded(child: Column(children: [Text(icon, style: const TextStyle(fontSize: 19)), const SizedBox(height: 3), Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)), Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54))])); }

class DeckTile extends StatelessWidget { const DeckTile({super.key, required this.deck, required this.onTap}); final Deck deck; final VoidCallback onTap; @override Widget build(BuildContext c) => GlassCard(onTap: onTap, padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: Colors.white.withOpacity(.07), borderRadius: BorderRadius.circular(14)), child: Icon(deck.icon)), const Spacer(), Text(deck.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)), Text('${deck.cards.length} کارت', style: const TextStyle(fontSize: 11, color: Colors.white54)), const SizedBox(height: 8), LinearProgressIndicator(value: deck.progress, minHeight: 5, borderRadius: BorderRadius.circular(5))])); }

class DecksPage extends StatefulWidget { const DecksPage({super.key, required this.store}); final AppStore store; @override State<DecksPage> createState() => _DecksPageState(); }
class _DecksPageState extends State<DecksPage> {
  String query = '';
  @override Widget build(BuildContext context) { final list = widget.store.decks.where((d) => d.name.toLowerCase().contains(query.toLowerCase())).toList(); return ListView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 120), children: [const Text('دسته‌ها', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)), const SizedBox(height: 6), const Text('مدیریت درس‌ها و کارت‌های تو', style: TextStyle(color: Colors.white54)), const SizedBox(height: 16), TextField(onChanged: (v) => setState(() => query = v), decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'جستجوی دسته‌ها')), const SizedBox(height: 16), ...list.map((deck) { final i = widget.store.decks.indexOf(deck); return Padding(padding: const EdgeInsets.only(bottom: 12), child: GlassCard(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DeckDetailPage(store: widget.store, deckIndex: i))), child: Row(children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(.07), borderRadius: BorderRadius.circular(16)), child: Icon(deck.icon)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(deck.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), Text('${deck.cards.length} کارت • ${(deck.progress * 100).round()}٪ پیشرفت', style: const TextStyle(fontSize: 12, color: Colors.white54)), const SizedBox(height: 9), LinearProgressIndicator(value: deck.progress, minHeight: 5, borderRadius: BorderRadius.circular(5))])), PopupMenuButton<String>(onSelected: (v) { if (v == 'delete') { widget.store.deleteDeck(i); setState(() {}); } }, itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('حذف دسته'))])]))); })]); }
}

class DeckDetailPage extends StatefulWidget { const DeckDetailPage({super.key, required this.store, required this.deckIndex}); final AppStore store; final int deckIndex; @override State<DeckDetailPage> createState() => _DeckDetailPageState(); }
class _DeckDetailPageState extends State<DeckDetailPage> {
  String query = '';
  @override Widget build(BuildContext context) { final deck = widget.store.decks[widget.deckIndex]; final cards = deck.cards.where((c) => c.front.toLowerCase().contains(query.toLowerCase()) || c.back.contains(query) || c.tag.toLowerCase().contains(query.toLowerCase())).toList(); return Scaffold(appBar: AppBar(title: Text(deck.name), actions: [IconButton(onPressed: () => StudyPage.open(context, widget.store, widget.deckIndex), icon: const Icon(Icons.play_circle_outline_rounded))]), floatingActionButton: FloatingActionButton(onPressed: () => addCard(context), child: const Icon(Icons.add_rounded)), body: ListView(padding: const EdgeInsets.fromLTRB(20, 10, 20, 100), children: [TextField(onChanged: (v) => setState(() => query = v), decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'جستجوی کارت')), const SizedBox(height: 14), GlassCard(child: Row(children: [Expanded(child: Text('${deck.cards.length} کارت', style: const TextStyle(fontWeight: FontWeight.w800))), Text('${(deck.progress * 100).round()}٪ یادگیری')]))), const SizedBox(height: 12), ...cards.map((card) { final ci = deck.cards.indexOf(card); return Padding(padding: const EdgeInsets.only(bottom: 10), child: GlassCard(child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(card.front, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), const SizedBox(height: 4), Text(card.back, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white60)), const SizedBox(height: 7), Wrap(spacing: 6, children: [Chip(label: Text('باکس ${card.box}')), if (card.tag.isNotEmpty) Chip(label: Text(card.tag)), Chip(label: Text(card.dueAt.isBefore(DateTime.now()) ? 'آماده مرور' : '${card.intervalDays} روز دیگر'))])])), IconButton(onPressed: () { widget.store.deleteCard(widget.deckIndex, ci); setState(() {}); }, icon: const Icon(Icons.delete_outline_rounded))]))); })]); }
  Future<void> addCard(BuildContext context) async { final front = TextEditingController(); final back = TextEditingController(); final tag = TextEditingController(); await showDialog(context: context, builder: (_) => AlertDialog(title: const Text('کارت جدید'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: front, decoration: const InputDecoration(labelText: 'روی کارت')), TextField(controller: back, decoration: const InputDecoration(labelText: 'پشت کارت')), TextField(controller: tag, decoration: const InputDecoration(labelText: 'برچسب (اختیاری)'))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('لغو')), FilledButton(onPressed: () { if (front.text.trim().isNotEmpty && back.text.trim().isNotEmpty) widget.store.addCard(widget.deckIndex, front.text.trim(), back.text.trim(), tag: tag.text.trim()); Navigator.pop(context); setState(() {}); }, child: const Text('ذخیره'))])); }
}

class StudyPage extends StatefulWidget { const StudyPage({super.key, required this.store, required this.deckIndex}); final AppStore store; final int deckIndex; static void open(BuildContext c, AppStore s, int i) => Navigator.push(c, MaterialPageRoute(builder: (_) => StudyPage(store: s, deckIndex: i))); @override State<StudyPage> createState() => _StudyPageState(); }
class _StudyPageState extends State<StudyPage> with SingleTickerProviderStateMixin {
  int current = 0; bool flipped = false; late AnimationController pulse;
  @override void initState() { super.initState(); pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true); }
  @override void dispose() { pulse.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) { final deck = widget.store.decks[widget.deckIndex]; final due = deck.cards.where((c) => c.dueAt.isBefore(DateTime.now()) || c.dueAt.isAtSameMomentAs(DateTime.now())).toList(); final cards = due.isEmpty ? deck.cards : due; if (cards.isEmpty) return Scaffold(appBar: AppBar(), body: const Center(child: Text('این دسته هنوز کارتی ندارد.'))); current %= cards.length; final card = cards[current]; return Scaffold(body: SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 18), child: Column(children: [Row(children: [IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)), Expanded(child: LinearProgressIndicator(value: (current + 1) / cards.length, minHeight: 7, borderRadius: BorderRadius.circular(7))), const SizedBox(width: 12), Text('${current + 1}/${cards.length}')]), const SizedBox(height: 30), Expanded(child: GestureDetector(onTap: () => setState(() => flipped = !flipped), child: AnimatedBuilder(animation: pulse, builder: (_, __) { final glow = 0.04 + pulse.value * 0.06; return Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: const Color(0xFF7C6CFF).withOpacity(glow), blurRadius: 35, spreadRadius: 3)]), child: TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: flipped ? 1 : 0), duration: const Duration(milliseconds: 650), curve: Curves.easeOutBack, builder: (_, v, __) => Transform(perspective: 0.0014, alignment: Alignment.center, transform: Matrix4.identity()..rotateY(math.pi * v), child: GlassCard(child: Center(child: Transform(alignment: Alignment.center, transform: Matrix4.identity()..rotateY(v > .5 ? math.pi : 0), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [if (card.tag.isNotEmpty) Chip(label: Text(card.tag)), Padding(padding: const EdgeInsets.all(18), child: Text(v > .5 ? card.back : card.front, textAlign: TextAlign.center, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900))), Text(v > .5 ? 'پاسخ • باکس ${card.box}' : 'برای دیدن پاسخ لمس کن', style: const TextStyle(color: Colors.white54))]))))))); }))), const SizedBox(height: 20), Row(children: [RateButton('دوباره', '1m', Icons.refresh_rounded, () => next(card, 1)), RateButton('سخت', '${math.max(1, card.intervalDays)}d', Icons.bolt_rounded, () => next(card, 2)), RateButton('خوب', '${math.max(1, card.intervalDays * 2)}d', Icons.check_rounded, () => next(card, 3)), RateButton('آسان', '${math.max(2, card.intervalDays * 4)}d', Icons.auto_awesome_rounded, () => next(card, 4))])])))); }
  void next(CardItem card, int rating) { widget.store.review(card, rating); setState(() { current++; flipped = false; }); }
}
class RateButton extends StatelessWidget { const RateButton(this.title, this.time, this.icon, this.onTap, {super.key}); final String title, time; final IconData icon; final VoidCallback onTap; @override Widget build(BuildContext c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: GlassCard(onTap: onTap, padding: const EdgeInsets.symmetric(vertical: 12), child: Column(children: [Icon(icon, size: 19), const SizedBox(height: 4), Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)), Text(time, style: const TextStyle(fontSize: 10, color: Colors.white54))])))); }

class StatsPage extends StatelessWidget { const StatsPage({super.key, required this.store}); final AppStore store; @override Widget build(BuildContext context) { final total = store.totalCards; final learned = store.learnedCount; return ListView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 120), children: [const Text('آمار', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)), const SizedBox(height: 20), GlassCard(child: Column(children: [SizedBox(height: 170, child: CustomPaint(painter: ChartPainter(), child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('${total == 0 ? 0 : ((learned / total) * 100).round()}٪', style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900)), const Text('سطح یادگیری', style: TextStyle(color: Colors.white54))])))), const Divider(height: 28), Row(children: [Metric('📚', '$total', 'کل کارت‌ها'), Metric('✓', '$learned', 'یادگرفته'), Metric('⏳', '${store.dueCount}', 'برای مرور')])])), const SizedBox(height: 14), GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('جعبه‌های لایتنر', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)), const SizedBox(height: 14), ...List.generate(5, (i) { final count = store.decks.fold(0, (a, d) => a + d.cards.where((c) => c.box == i + 1).length); final ratio = total == 0 ? 0.0 : count / total; return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [SizedBox(width: 54, child: Text('باکس ${i + 1}')), Expanded(child: LinearProgressIndicator(value: ratio, minHeight: 7, borderRadius: BorderRadius.circular(7))), const SizedBox(width: 10), Text('$count')])) })]))]); } }
class ChartPainter extends CustomPainter { @override void paint(Canvas c, Size s) { final p = Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = const Color(0xFF65C8FF); final path = Path(); for (var i = 0; i <= 40; i++) { final x = s.width * i / 40; final y = s.height * (.72 - (.18 * math.sin(i * .42) + i / 40 * .45)); if (i == 0) path.moveTo(x, y); else path.lineTo(x, y); } c.drawPath(path, p); } @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false; }

class ProfilePage extends StatelessWidget { const ProfilePage({super.key, required this.store}); final AppStore store; @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 120), children: [GlassCard(child: Column(children: [const CircleAvatar(radius: 38, child: Icon(Icons.person_rounded, size: 38)), const SizedBox(height: 12), const Text('Parin', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), const Text('Learner • Level 5', style: TextStyle(color: Colors.white54)), const SizedBox(height: 15), LinearProgressIndicator(value: (store.xp % 2000) / 2000, minHeight: 7, borderRadius: BorderRadius.circular(7)), const SizedBox(height: 7), Text('${store.xp % 2000} / 2,000 XP')]))), const SizedBox(height: 14), GlassCard(child: Column(children: [SettingTile(Icons.notifications_none_rounded, 'یادآوری مرور', store.reminderEnabled ? 'فعال' : 'خاموش', onTap: () async { store.reminderEnabled = !store.reminderEnabled; await store.save(); }), SettingTile(Icons.schedule_rounded, 'زمان مرور', '${store.reminderHour.toString().padLeft(2, '0')}:${store.reminderMinute.toString().padLeft(2, '0')}', onTap: () async { final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: store.reminderHour, minute: store.reminderMinute)); if (t != null) { store.reminderHour = t.hour; store.reminderMinute = t.minute; await store.save(); } }), SettingTile(Icons.palette_outlined, 'ظاهر', store.darkMode ? 'تیره' : 'روشن', onTap: store.toggleTheme), SettingTile(Icons.import_export_rounded, 'ورود / خروجی', 'JSON', onTap: () => showDataDialog(context)), SettingTile(Icons.info_outline_rounded, 'نسخه', '2.0.0', onTap: null)]))]); }

class SettingTile extends StatelessWidget { const SettingTile(this.icon, this.title, this.value, {super.key, required this.onTap}); final IconData icon; final String title, value; final VoidCallback? onTap; @override Widget build(BuildContext c) => ListTile(onTap: onTap, leading: Icon(icon), title: Text(title), subtitle: Text(value, style: const TextStyle(color: Colors.white54)), trailing: const Icon(Icons.chevron_left_rounded)); }

Future<void> showDataDialog(BuildContext context) async { final store = _findStore(context); final controller = TextEditingController(text: store.exportJson()); await showDialog(context: context, builder: (_) => AlertDialog(title: const Text('پشتیبان‌گیری JSON'), content: SizedBox(width: 500, child: TextField(controller: controller, maxLines: 10, decoration: const InputDecoration(hintText: 'JSON'))), actions: [TextButton(onPressed: () { controller.text = store.exportJson(); }, child: const Text('خروجی')), FilledButton(onPressed: () async { final ok = await store.importJson(controller.text); if (context.mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'داده‌ها وارد شد' : 'JSON نامعتبر است'))); } }, child: const Text('ورود'))])); }
AppStore _findStore(BuildContext context) => (context.findAncestorWidgetOfExactType<ParinLitnerInherited>()?.store) ?? (throw StateError('Store unavailable'));

class ParinLitnerInherited extends InheritedWidget { const ParinLitnerInherited({super.key, required this.store, required super.child}); final AppStore store; @override bool updateShouldNotify(covariant ParinLitnerInherited oldWidget) => oldWidget.store != store; }

class GlassNav extends StatelessWidget { const GlassNav({super.key, required this.index, required this.onTap}); final int index; final ValueChanged<int> onTap; @override Widget build(BuildContext c) => ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(28)), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18), child: BottomAppBar(shape: const CircularNotchedRectangle(), notchMargin: 8, color: Theme.of(c).brightness == Brightness.dark ? const Color(0xDD0B1628) : const Color(0xE8FFFFFF), child: SizedBox(height: 62, child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [NavItem(Icons.home_rounded, 'خانه', 0, index, onTap), NavItem(Icons.layers_rounded, 'دسته‌ها', 1, index, onTap), const SizedBox(width: 42), NavItem(Icons.bar_chart_rounded, 'آمار', 3, index, onTap), NavItem(Icons.person_rounded, 'پروفایل', 4, index, onTap)])))); }
class NavItem extends StatelessWidget { const NavItem(this.icon, this.label, this.i, this.selected, this.onTap, {super.key}); final IconData icon; final String label; final int i, selected; final ValueChanged<int> onTap; @override Widget build(BuildContext c) { final active = i == selected; return InkWell(onTap: () => onTap(i), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 21, color: active ? const Color(0xFF9C8DFF) : Colors.white54), Text(label, style: TextStyle(fontSize: 10, color: active ? const Color(0xFF9C8DFF) : Colors.white54, fontWeight: active ? FontWeight.w800 : FontWeight.w400))]))); } }
class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 44});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * .30),
          boxShadow: const [BoxShadow(color: Color(0x668A6CFF), blurRadius: 18)],
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset('assets/parin_litner_icon.png', fit: BoxFit.cover),
      );
}
