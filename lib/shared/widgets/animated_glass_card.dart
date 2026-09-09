import 'package:flutter/material.dart';

class AnimatedGlassCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const AnimatedGlassCard({super.key, required this.child, this.onTap});
  @override State<AnimatedGlassCard> createState() => _AnimatedGlassCardState();
}
class _AnimatedGlassCardState extends State<AnimatedGlassCard> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, -1.2 * _c.value),
        child: InkWell(
          borderRadius: BorderRadius.circular(24), onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.light ? Colors.white.withOpacity(.66) : Colors.white.withOpacity(.055),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: primary.withOpacity(.12 + .04 * _c.value)),
              boxShadow: [BoxShadow(color: primary.withOpacity(.07 + .05 * _c.value), blurRadius: 26, spreadRadius: 1)],
            ), child: child,
          ),
        ),
      ), child: widget.child,
    );
  }
}

class PageReveal extends StatelessWidget {
  final Widget child;
  const PageReveal({super.key, required this.child});
  @override Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1), duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic,
    builder: (_, value, child) => Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 18 * (1 - value)), child: child)), child: child,
  );
}
