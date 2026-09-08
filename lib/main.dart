import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ParinLitnerApp());
}

class ParinLitnerApp extends StatelessWidget {
  const ParinLitnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Parin Litner',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B1020),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        fontFamily: 'sans',
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: SafeHomePage(),
      ),
    );
  }
}

class SafeHomePage extends StatelessWidget {
  const SafeHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Parin Litner',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            const _Logo(),
            const SizedBox(height: 24),
            const Text(
              'یادگیری هوشمند، ساده و ماندگار',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'نسخه پایه و پایدار Parin Litner',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(.65),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 28),
            _GlassCard(
              child: Column(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 52,
                    color: Color(0xFF6C63FF),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'برنامه با موفقیت اجرا شد',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'این نسخه عمداً ساده ساخته شده تا ابتدا اجرای برنامه روی گوشی را تأیید کنیم.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      height: 1.6,
                      color: Colors.white.withOpacity(.72),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _GlassCard(
              child: Column(
                children: [
                  const _InfoRow(
                    icon: Icons.phone_android_rounded,
                    title: 'وضعیت',
                    value: 'آماده اجرا',
                  ),
                  const Divider(height: 24),
                  const _InfoRow(
                    icon: Icons.flash_on_rounded,
                    title: 'مرحله',
                    value: 'نسخه پایه',
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.build_rounded,
                    title: 'امکانات',
                    value: 'در مرحله بعد اضافه می‌شوند',
                    valueColor: Colors.white.withOpacity(.65),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('همه‌چیز آماده است 👍'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'تست برنامه',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF7C6CFF),
              Color(0xFF3D7BFF),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5B61FF).withOpacity(.35),
              blurRadius: 28,
              spreadRadius: 3,
            ),
          ],
        ),
        child: const Icon(
          Icons.auto_awesome_rounded,
          size: 48,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.055),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(.10),
        ),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withOpacity(.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF9D96FF),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(.55),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
