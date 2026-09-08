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
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: HomePage(),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            const LogoMark(),
            const SizedBox(height: 24),
            const Text(
              'یادگیری هوشمند، ساده و ماندگار',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Parin Litner • نسخه پایدار پایه',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.65),
              ),
            ),
            const SizedBox(height: 28),
            const GlassCard(
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 56,
                    color: Color(0xFF8E84FF),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'برنامه با موفقیت اجرا شد',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'این نسخه عمداً ساده و پایدار است تا ابتدا اجرای صحیح برنامه روی گوشی را تأیید کنیم.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      height: 1.7,
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const GlassCard(
              child: Column(
                children: [
                  InfoRow(
                    icon: Icons.phone_android_rounded,
                    title: 'وضعیت',
                    value: 'آماده اجرا',
                  ),
                  SizedBox(height: 18),
                  Divider(height: 1),
                  SizedBox(height: 18),
                  InfoRow(
                    icon: Icons.layers_rounded,
                    title: 'نسخه',
                    value: 'پایه و پایدار',
                  ),
                  SizedBox(height: 18),
                  Divider(height: 1),
                  SizedBox(height: 18),
                  InfoRow(
                    icon: Icons.auto_awesome_rounded,
                    title: 'مرحله بعد',
                    value: 'اضافه کردن امکانات Leitner',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Parin Litner با موفقیت کار می‌کند 👍'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 5),
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

class LogoMark extends StatelessWidget {
  const LogoMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF8E84FF),
              Color(0xFF3D7BFF),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withOpacity(0.35),
              blurRadius: 30,
              spreadRadius: 4,
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

class GlassCard extends StatelessWidget {
  final Widget child;

  const GlassCard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.10),
        ),
      ),
      child: child,
    );
  }
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const InfoRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withOpacity(0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFA39CFF),
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
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.55),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
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
