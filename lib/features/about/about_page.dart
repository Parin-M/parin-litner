import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const _repoUrl = 'https://github.com/Parin-M/parin-litner';

  Future<void> _openRepository(BuildContext context) async {
    final uri = Uri.parse(_repoUrl);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open GitHub repository.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 36),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: scheme.primaryContainer,
                    ),
                    child: Image.asset('assets/parin_litner_icon.png'),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Parin Litner',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This software was created by Parin Mashalchian.\n\nChatGPT also helped with its creation, development, and refinement.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: scheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                child: Icon(Icons.code_rounded, color: scheme.onPrimaryContainer),
              ),
              title: const Text(
                'GitHub Repository',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: const Text('Open the Parin Litner project on GitHub'),
              trailing: const Icon(Icons.open_in_new_rounded),
              onTap: () => _openRepository(context),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Made with love on planet Earth. 🌍❤️',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
