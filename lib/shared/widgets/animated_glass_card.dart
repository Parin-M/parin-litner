import 'dart:ui';
import 'package:flutter/material.dart';

class AnimatedGlassCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const AnimatedGlassCard({super.key, required this.child, this.onTap});
  @override State<AnimatedGlassCard> createState() => _AnimatedGlassCardState();
}

class _AnimatedGlassCardState extends State<AnimatedGlassCard> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);
  bool pressed = false;

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final glass = theme.cardTheme.color ?? Colors.white.withValues(alpha: .62);
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final pulse = Curves.easeInOut.transform(_c.value);
        return AnimatedScale(
          scale: pressed ? .985 : 1,
          duration: const Duration(milliseconds: 120),
          child: Transform.translate(
            offset: Offset(0, -1.5 * pulse),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(26),
                    onTap: widget.onTap,
                    onHighlightChanged: (v) => setState(() => pressed = v),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: glass.a.clamp(.18, .9)),
                            Colors.white.withValues(alpha: (glass.a * .58).clamp(.10, .65)),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: Colors.white.withValues(alpha: .72), width: 1.2),
                        boxShadow: [
                          BoxShadow(color: primary.withValues(alpha: .08 + .06 * pulse), blurRadius: 30, spreadRadius: 1),
                        ],
                      ),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

class PageReveal extends StatelessWidget {
  final Widget child;
  const PageReveal({super.key, required this.child});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 650),
    curve: Curves.easeOutBack,
    builder: (_, value, child) => Opacity(opacity: value.clamp(0, 1), child: Transform.translate(offset: Offset(0, 24 * (1 - value)), child: Transform.scale(scale: .97 + .03 * value, child: child))),
    child: child,
  );
}
