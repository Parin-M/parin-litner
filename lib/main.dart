import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

void main() {
  runApp(const ParinLitnerApp());
}

// ============================================================
// MODELS
// ============================================================

class FlashCard {
  FlashCard({
    required this.front,
    required this.back,
    this.tag = '',
    this.box = 1,
    DateTime? dueAt,
    this.intervalDays = 1,
  }) : dueAt = dueAt ?? DateTime.now();

  String front;
  String back;
  String tag;
  int box;
  DateTime dueAt;
  int intervalDays;

  bool get isDue =>
      dueAt.isBefore(DateTime.now()) ||
      dueAt.isAtSameMomentAs(DateTime.now());
}

class Deck {
  Deck({
    required this.name,
    this.icon = Icons.menu_book_rounded,
  });

  String name;
  IconData icon;
  final List<FlashCard> cards = [];

  int get dueCount => cards.where((c) => c.isDue).length;

  double get progress {
    if (cards.isEmpty) return 0;
    final learned = cards.where((c) => c.box >= 3).length;
    return learned / cards.length;
  }
}

// ============================================================
// STORE
// ============================================================

class AppStore extends ChangeNotifier {
  bool darkMode = true;
  bool reminderEnabled = true;

  int reminderHour = 20;
  int reminderMinute = 30;

  int xp = 1240;
  int streak = 7;
  int reviewedToday = 12;

  final List<Deck> decks = [
    Deck(name: 'انگلیسی'),
    Deck(name: 'برنامه‌نویسی'),
    Deck(name: 'دانش عمومی'),
  ];

  AppStore() {
    decks[0].cards.addAll([
      FlashCard(
        front: 'Beautiful',
        back: 'زیبا',
        tag: 'Vocabulary',
        box: 3,
        intervalDays: 3,
        dueAt: DateTime.now(),
      ),
      FlashCard(
        front: 'Persistent',
        back: 'پایدار / پیگیر',
        tag: 'Vocabulary',
        box: 2,
        intervalDays: 2,
        dueAt: DateTime.now(),
      ),
      FlashCard(
        front: 'Improve',
        back: 'بهبود دادن',
        tag: 'Vocabulary',
        box: 1,
        intervalDays: 1,
        dueAt: DateTime.now(),
      ),
    ]);

    decks[1].cards.addAll([
      FlashCard(
        front: 'What is Flutter?',
        back: 'یک فریم‌ورک رابط کاربری برای ساخت اپلیکیشن‌های چندسکویی.',
        tag: 'Flutter',
        box: 2,
      ),
      FlashCard(
        front: 'What is a Widget?',
        back: 'ساختمان اصلی رابط کاربری در Flutter.',
        tag: 'Flutter',
        box: 4,
        intervalDays: 7,
      ),
    ]);

    decks[2].cards.add(
      FlashCard(
        front: 'پایتخت ژاپن چیست؟',
        back: 'توکیو',
        box: 1,
      ),
    );
  }

  List<FlashCard> get allCards {
    return decks.expand((deck) => deck.cards).toList();
  }

  int get totalCards => allCards.length;

  int get learnedCount {
    return allCards.where((card) => card.box >= 3).length;
  }

  int get dueCount {
    return allCards.where((card) => card.isDue).length;
  }

  double get progress {
    if (totalCards == 0) return 0;
    return learnedCount / totalCards;
  }

  void toggleTheme() {
    darkMode = !darkMode;
    notifyListeners();
  }

  void addDeck(String name) {
    if (name.trim().isEmpty) return;
    decks.add(Deck(name: name.trim()));
    notifyListeners();
  }

  void deleteDeck(int index) {
    if (index < 0 || index >= decks.length) return;
    decks.removeAt(index);
    notifyListeners();
  }

  void addCard(
    int deckIndex,
    String front,
    String back,
    String tag,
  ) {
    if (front.trim().isEmpty || back.trim().isEmpty) return;

    decks[deckIndex].cards.add(
      FlashCard(
        front: front.trim(),
        back: back.trim(),
        tag: tag.trim(),
      ),
    );

    notifyListeners();
  }

  void deleteCard(int deckIndex, int cardIndex) {
    if (deckIndex < 0 || deckIndex >= decks.length) return;
    if (cardIndex < 0 || cardIndex >= decks[deckIndex].cards.length) return;

    decks[deckIndex].cards.removeAt(cardIndex);
    notifyListeners();
  }

  void rateCard(FlashCard card, int rating) {
    switch (rating) {
      case 1:
        card.box = 1;
        card.intervalDays = 1;
        break;

      case 2:
        card.box = math.max(1, card.box);
        card.intervalDays = math.max(1, card.intervalDays);
        break;

      case 3:
        card.box = math.min(5, card.box + 1);
        card.intervalDays = math.max(1, card.intervalDays * 2);
        break;

      case 4:
        card.box = math.min(5, card.box + 2);
        card.intervalDays = math.max(2, card.intervalDays * 4);
        break;
    }

    card.dueAt = DateTime.now().add(
      Duration(days: card.intervalDays),
    );

    xp += rating * 10;
    reviewedToday++;

    notifyListeners();
  }
}

// ============================================================
// APP
// ============================================================

class ParinLitnerApp extends StatefulWidget {
  const ParinLitnerApp({super.key});

  @override
  State<ParinLitnerApp> createState() => _ParinLitnerAppState();
}

class _ParinLitnerAppState extends State<ParinLitnerApp> {
  final AppStore store = AppStore();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Parin Litner',
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode:
              store.darkMode ? ThemeMode.dark : ThemeMode.light,
          home: HomePage(store: store),
        );
      },
    );
  }
}

// ============================================================
// THEME
// ============================================================

class AppTheme {
  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF07111F),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF7C6CFF),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      fontFamily: 'sans',
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  static ThemeData light() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F7FC),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6255E8),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.black.withOpacity(.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// ============================================================
// HOME
// ============================================================

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.store,
  });

  final AppStore store;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(store: widget.store),
      DecksPage(store: widget.store),
      const SizedBox.shrink(),
      StatsPage(store: widget.store),
      ProfilePage(store: widget.store),
    ];

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            child: IndexedStack(
              index: selectedIndex,
              children: pages,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 10,
        onPressed: () => _showAddDeck(context),
        child: const Icon(Icons.add_rounded),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: GlassNav(
        index: selectedIndex,
        onTap: (index) {
          if (index == 2) return;
          setState(() => selectedIndex = index);
        },
      ),
    );
  }

  void _showAddDeck(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('دسته جدید'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'مثلاً لغات آلمانی',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('لغو'),
            ),
            FilledButton(
              onPressed: () {
                widget.store.addDeck(controller.text);
                Navigator.pop(context);
              },
              child: const Text('ساختن'),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================
// DASHBOARD
// ============================================================

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.store,
  });

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'سلام Parin 👋',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'وقت مرور امروز رسیده',
                    style: TextStyle(
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withOpacity(.55),
                    ),
                  ),
                ],
              ),
            ),
            const CircleAvatar(
              radius: 25,
              child: Icon(Icons.person_rounded),
            ),
          ],
        ),
        const SizedBox(height: 25),

        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'مرور امروز',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${store.dueCount} کارت آماده مرور است',
                style: const TextStyle(
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: store.totalCards == 0
                    ? 0
                    : store.reviewedToday /
                        math.max(store.totalCards, 20),
                minHeight: 9,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: store.totalCards == 0
                      ? null
                      : () {
                          StudyPage.open(
                            context,
                            store,
                            0,
                          );
                        },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('شروع مرور'),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 15),

        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.local_fire_department_rounded,
                title: 'Streak',
                value: '${store.streak}',
                subtitle: 'روز',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: Icons.bolt_rounded,
                title: 'XP',
                value: '${store.xp}',
                subtitle: 'امتیاز',
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        const SectionTitle(
          title: 'دسته‌های من',
          action: 'مشاهده همه',
        ),

        const SizedBox(height: 10),

        ...List.generate(
          store.decks.length,
          (index) {
            final deck = store.decks[index];

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DeckTile(
                deck: deck,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DeckDetailPage(
                        store: store,
                        deckIndex: index,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

// ============================================================
// DECKS
// ============================================================

class DecksPage extends StatelessWidget {
  const DecksPage({
    super.key,
    required this.store,
  });

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: [
        const Text(
          'دسته‌ها',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${store.decks.length} دسته • ${store.totalCards} کارت',
          style: const TextStyle(color: Colors.white54),
        ),
        const SizedBox(height: 20),

        ...List.generate(
          store.decks.length,
          (index) {
            final deck = store.decks[index];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DeckTile(
                deck: deck,
                showDelete: true,
                onDelete: () {
                  store.deleteDeck(index);
                },
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DeckDetailPage(
                        store: store,
                        deckIndex: index,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

// ============================================================
// DECK DETAIL
// ============================================================

class DeckDetailPage extends StatefulWidget {
  const DeckDetailPage({
    super.key,
    required this.store,
    required this.deckIndex,
  });

  final AppStore store;
  final int deckIndex;

  @override
  State<DeckDetailPage> createState() =>
      _DeckDetailPageState();
}

class _DeckDetailPageState extends State<DeckDetailPage> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final deck = widget.store.decks[widget.deckIndex];

    final cards = deck.cards.where((card) {
      final q = query.toLowerCase();
      return card.front.toLowerCase().contains(q) ||
          card.back.toLowerCase().contains(q) ||
          card.tag.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(deck.name),
        actions: [
          IconButton(
            onPressed: () {
              StudyPage.open(
                context,
                widget.store,
                widget.deckIndex,
              );
            },
            icon: const Icon(
              Icons.play_circle_outline_rounded,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addCard(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          10,
          20,
          100,
        ),
        children: [
          TextField(
            onChanged: (value) {
              setState(() => query = value);
            },
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'جستجوی کارت',
            ),
          ),
          const SizedBox(height: 15),

          GlassCard(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${deck.cards.length} کارت',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${(deck.progress * 100).round()}٪ یادگیری',
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          ...cards.map(
            (card) {
              final originalIndex =
                  deck.cards.indexOf(card);

              return Padding(
                padding:
                    const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              card.front,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              card.back,
                              maxLines: 2,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white60,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              children: [
                                Chip(
                                  label: Text(
                                    'باکس ${card.box}',
                                  ),
                                ),
                                if (card.tag.isNotEmpty)
                                  Chip(
                                    label:
                                        Text(card.tag),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          widget.store.deleteCard(
                            widget.deckIndex,
                            originalIndex,
                          );
                          setState(() {});
                        },
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _addCard(BuildContext context) {
    final front = TextEditingController();
    final back = TextEditingController();
    final tag = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('کارت جدید'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: front,
                  decoration: const InputDecoration(
                    labelText: 'سؤال / کلمه',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: back,
                  decoration: const InputDecoration(
                    labelText: 'پاسخ / معنی',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: tag,
                  decoration: const InputDecoration(
                    labelText: 'برچسب',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('لغو'),
            ),
            FilledButton(
              onPressed: () {
                widget.store.addCard(
                  widget.deckIndex,
                  front.text,
                  back.text,
                  tag.text,
                );

                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('افزودن'),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================
// STUDY
// ============================================================

class StudyPage extends StatefulWidget {
  const StudyPage({
    super.key,
    required this.store,
    required this.deckIndex,
  });

  final AppStore store;
  final int deckIndex;

  static void open(
    BuildContext context,
    AppStore store,
    int deckIndex,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudyPage(
          store: store,
          deckIndex: deckIndex,
        ),
      ),
    );
  }

  @override
  State<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage>
    with SingleTickerProviderStateMixin {
  int current = 0;
  bool flipped = false;

  late AnimationController pulse;

  @override
  void initState() {
    super.initState();

    pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deck = widget.store.decks[widget.deckIndex];

    if (deck.cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('این دسته هنوز کارتی ندارد.'),
        ),
      );
    }

    if (current >= deck.cards.length) {
      current = 0;
    }

    final card = deck.cards[current];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            15,
            20,
            20,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () =>
                        Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                    ),
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value:
                          (current + 1) / deck.cards.length,
                      minHeight: 7,
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${current + 1}/${deck.cards.length}',
                  ),
                ],
              ),

              const SizedBox(height: 25),

              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      flipped = !flipped;
                    });
                  },
                  child: AnimatedBuilder(
                    animation: pulse,
                    builder: (context, child) {
                      final glow =
                          0.04 + pulse.value * 0.06;

                      return Container(
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF7C6CFF,
                              ).withOpacity(glow),
                              blurRadius: 40,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: 0,
                            end: flipped ? 1 : 0,
                          ),
                          duration: const Duration(
                            milliseconds: 650,
                          ),
                          curve: Curves.easeOutBack,
                          builder: (
                            context,
                            value,
                            child,
                          ) {
                            final matrix =
                                Matrix4.identity()
                                  ..setEntry(
                                    3,
                                    2,
                                    0.0015,
                                  )
                                  ..rotateY(
                                    math.pi * value,
                                  );

                            final showBack =
                                value > .5;

                            return Transform(
                              alignment:
                                  Alignment.center,
                              transform: matrix,
                              child: GlassCard(
                                child: Center(
                                  child: Transform(
                                    alignment:
                                        Alignment.center,
                                    transform:
                                        Matrix4.identity()
                                          ..rotateY(
                                            showBack
                                                ? math.pi
                                                : 0,
                                          ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment
                                              .center,
                                      children: [
                                        if (card.tag
                                            .isNotEmpty)
                                          Chip(
                                            label: Text(
                                              card.tag,
                                            ),
                                          ),
                                        Padding(
                                          padding:
                                              const EdgeInsets
                                                  .all(20),
                                          child: Text(
                                            showBack
                                                ? card.back
                                                : card.front,
                                            textAlign:
                                                TextAlign
                                                    .center,
                                            style:
                                                const TextStyle(
                                              fontSize: 30,
                                              fontWeight:
                                                  FontWeight
                                                      .w900,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          showBack
                                              ? 'پاسخ • باکس ${card.box}'
                                              : 'برای دیدن پاسخ لمس کن',
                                          style:
                                              const TextStyle(
                                            color:
                                                Colors.white54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  RateButton(
                    title: 'دوباره',
                    subtitle: '1d',
                    icon: Icons.refresh_rounded,
                    onTap: () => _next(card, 1),
                  ),
                  RateButton(
                    title: 'سخت',
                    subtitle:
                        '${math.max(1, card.intervalDays)}d',
                    icon: Icons.bolt_rounded,
                    onTap: () => _next(card, 2),
                  ),
                  RateButton(
                    title: 'خوب',
                    subtitle:
                        '${math.max(1, card.intervalDays * 2)}d',
                    icon: Icons.check_rounded,
                    onTap: () => _next(card, 3),
                  ),
                  RateButton(
                    title: 'آسان',
                    subtitle:
                        '${math.max(2, card.intervalDays * 4)}d',
                    icon:
                        Icons.auto_awesome_rounded,
                    onTap: () => _next(card, 4),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _next(FlashCard card, int rating) {
    widget.store.rateCard(card, rating);

    setState(() {
      flipped = false;

      if (current <
          widget.store.decks[widget.deckIndex]
                  .cards
                  .length -
              1) {
        current++;
      } else {
        current = 0;
      }
    });
  }
}

// ============================================================
// STATS
// ============================================================

class StatsPage extends StatelessWidget {
  const StatsPage({
    super.key,
    required this.store,
  });

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        120,
      ),
      children: [
        const Text(
          'آمار',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 20),

        GlassCard(
          child: Column(
            children: [
              SizedBox(
                height: 180,
                child: CustomPaint(
                  painter: ProgressPainter(
                    progress: store.progress,
                  ),
                  child: Center(
                    child: Text(
                      '${(store.progress * 100).round()}٪',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'سطح یادگیری',
                style: TextStyle(
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 15),

        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.style_rounded,
                title: 'کارت‌ها',
                value: '${store.totalCards}',
                subtitle: 'کل',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                icon: Icons.check_circle_rounded,
                title: 'یادگرفته',
                value: '${store.learnedCount}',
                subtitle: 'کارت',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                icon: Icons.schedule_rounded,
                title: 'موعد',
                value: '${store.dueCount}',
                subtitle: 'کارت',
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        GlassCard(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'جعبه‌های لایتنر',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),

              ...List.generate(
                5,
                (index) {
                  final count = store.allCards
                      .where(
                        (card) =>
                            card.box == index + 1,
                      )
                      .length;

                  final ratio =
                      store.totalCards == 0
                          ? 0.0
                          : count / store.totalCards;

                  return Padding(
                    padding:
                        const EdgeInsets.only(bottom: 15),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 60,
                          child: Text(
                            'باکس ${index + 1}',
                          ),
                        ),
                        Expanded(
                          child:
                              LinearProgressIndicator(
                            value: ratio,
                            minHeight: 8,
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('$count'),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// PROFILE
// ============================================================

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.store,
  });

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        120,
      ),
      children: [
        GlassCard(
          child: Column(
            children: [
              const CircleAvatar(
                radius: 42,
                child: Icon(
                  Icons.person_rounded,
                  size: 42,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Parin',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Learner • Level 5',
                style: TextStyle(
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 18),
              LinearProgressIndicator(
                value: (store.xp % 2000) / 2000,
                minHeight: 8,
                borderRadius:
                    BorderRadius.circular(8),
              ),
              const SizedBox(height: 8),
              Text(
                '${store.xp % 2000} / 2,000 XP',
              ),
            ],
          ),
        ),

        const SizedBox(height: 15),

        GlassCard(
          child: Column(
            children: [
              SettingTile(
                icon: Icons.notifications_none_rounded,
                title: 'یادآوری مرور',
                value: store.reminderEnabled
                    ? 'فعال'
                    : 'خاموش',
                onTap: () {
                  store.reminderEnabled =
                      !store.reminderEnabled;
                  store.notifyListeners();
                },
              ),
              SettingTile(
                icon: Icons.schedule_rounded,
                title: 'زمان مرور',
                value:
                    '${store.reminderHour.toString().padLeft(2, '0')}:${store.reminderMinute.toString().padLeft(2, '0')}',
                onTap: () async {
                  final time =
                      await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                      hour: store.reminderHour,
                      minute: store.reminderMinute,
                    ),
                  );

                  if (time != null) {
                    store.reminderHour = time.hour;
                    store.reminderMinute =
                        time.minute;
                    store.notifyListeners();
                  }
                },
              ),
              SettingTile(
                icon: Icons.palette_outlined,
                title: 'ظاهر',
                value: store.darkMode
                    ? 'تیره'
                    : 'روشن',
                onTap: store.toggleTheme,
              ),
              SettingTile(
                icon: Icons.info_outline_rounded,
                title: 'نسخه',
                value: '2.0.0',
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// COMPONENTS
// ============================================================

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final dark =
        Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 18,
          sigmaY: 18,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: dark
                ? Colors.white.withOpacity(.055)
                : Colors.white.withOpacity(.75),
            borderRadius:
                BorderRadius.circular(26),
            border: Border.all(
              color: Colors.white.withOpacity(.10),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class GlassNav extends StatelessWidget {
  const GlassNav({
    super.key,
    required this.index,
    required this.onTap,
  });

  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final dark =
        Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(28),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 20,
          sigmaY: 20,
        ),
        child: BottomAppBar(
          color: dark
              ? const Color(0xDD0B1628)
              : const Color(0xEFFFFFFF),
          child: SizedBox(
            height: 62,
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceAround,
              children: [
                NavItem(
                  icon: Icons.home_rounded,
                  title: 'خانه',
                  selected: index == 0,
                  onTap: () => onTap(0),
                ),
                NavItem(
                  icon: Icons.layers_rounded,
                  title: 'دسته‌ها',
                  selected: index == 1,
                  onTap: () => onTap(1),
                ),
                const SizedBox(width: 45),
                NavItem(
                  icon: Icons.bar_chart_rounded,
                  title: 'آمار',
                  selected: index == 3,
                  onTap: () => onTap(3),
                ),
                NavItem(
                  icon: Icons.person_rounded,
                  title: 'پروفایل',
                  selected: index == 4,
                  onTap: () => onTap(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NavItem extends StatelessWidget {
  const NavItem({
    super.key,
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 23,
              color: selected
                  ? const Color(0xFF9A8FFF)
                  : Colors.white54,
            ),
            const SizedBox(height: 3),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: selected
                    ? const Color(0xFF9A8FFF)
                    : Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 25),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }
}

class DeckTile extends StatelessWidget {
  const DeckTile({
    super.key,
    required this.deck,
    required this.onTap,
    this.showDelete = false,
    this.onDelete,
  });

  final Deck deck;
  final VoidCallback onTap;
  final bool showDelete;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(17),
                color: const Color(
                  0xFF7C6CFF,
                ).withOpacity(.16),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    deck.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${deck.cards.length} کارت • ${deck.dueCount} مرور',
                    style: const TextStyle(
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: deck.progress,
                    minHeight: 6,
                    borderRadius:
                        BorderRadius.circular(8),
                  ),
                ],
              ),
            ),
            if (showDelete)
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                ),
              ),
            const Icon(
              Icons.chevron_left_rounded,
              color: Colors.white38,
            ),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    required this.action,
  });

  final String title;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Text(
          action,
          style: const TextStyle(
            color: Color(0xFF9A8FFF),
          ),
        ),
      ],
    );
  }
}

class RateButton extends StatelessWidget {
  const RateButton({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
        ),
        child: GlassCard(
          padding: const EdgeInsets.all(9),
          child: InkWell(
            onTap: onTap,
            borderRadius:
                BorderRadius.circular(16),
            child: Column(
              children: [
                Icon(icon, size: 22),
                const SizedBox(height: 5),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SettingTile extends StatelessWidget {
  const SettingTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(vertical: 3),
      onTap: onTap,
      leading: CircleAvatar(
        radius: 21,
        backgroundColor: const Color(
          0xFF7C6CFF,
        ).withOpacity(.12),
        child: Icon(icon),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          color: Colors.white54,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_left_rounded,
        color: Colors.white38,
      ),
    );
  }
}

// ============================================================
// BACKGROUND
// ============================================================

class AmbientBackground extends StatefulWidget {
  const AmbientBackground({super.key});

  @override
  State<AmbientBackground> createState() =>
      _AmbientBackgroundState();
}

class _AmbientBackgroundState
    extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final value = controller.value;

        return IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                top: -100 + value * 40,
                right: -80,
                child: _Orb(
                  size: 260,
                  color: const Color(
                    0xFF6255E8,
                  ).withOpacity(.13),
                ),
              ),
              Positioned(
                bottom: 100 - value * 50,
                left: -120,
                child: _Orb(
                  size: 300,
                  color: const Color(
                    0xFF00A8FF,
                  ).withOpacity(.08),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 100,
            spreadRadius: 30,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PROGRESS PAINTER
// ============================================================

class ProgressPainter extends CustomPainter {
  ProgressPainter({
    required this.progress,
  });

  final double progress;

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final center =
        Offset(size.width / 2, size.height / 2);

    final radius =
        math.min(size.width, size.height) / 2 - 20;

    final backgroundPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withOpacity(.08);

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF8B7FFF);

    canvas.drawCircle(
      center,
      radius,
      backgroundPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant ProgressPainter oldDelegate,
  ) {
    return oldDelegate.progress != progress;
  }
}
