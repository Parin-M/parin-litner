import 'package:flutter/material.dart';

class AnimatedGlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const AnimatedGlassCard({super.key, required this.child, this.onTap});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white.withValues(alpha: .80), scheme.primary.withValues(alpha: .04)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: .74)),
        boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: .08), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(color: Colors.transparent, child: InkWell(borderRadius: BorderRadius.circular(20), onTap: onTap, child: content));
  }
}

class PageReveal extends StatelessWidget {
  final Widget child;
  const PageReveal({super.key, required this.child});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1), duration: const Duration(milliseconds: 260), curve: Curves.easeOut,
    builder: (_, value, child) => Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 10 * (1 - value)), child: child)), child: child,
  );
}
