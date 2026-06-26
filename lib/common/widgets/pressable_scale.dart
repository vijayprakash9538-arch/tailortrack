import 'package:flutter/material.dart';

/// Wraps a tappable child so it gently scales down and dims while pressed,
/// giving the premium, tactile "squeeze" feel on every CTA. Pair with the
/// button's own ripple — this adds the scale/grey, the button adds the
/// ripple.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  const PressableScale({super.key, required this.child, this.onTap, this.pressedScale = 0.97});

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _set(bool v) => setState(() => _pressed = v);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // No onTap when the child handles its own tap (e.g. an InkWell): we
      // only listen for press up/down so the child still wins the gesture
      // arena and shows its ripple, while we add the scale/dim.
      onTap: widget.onTap,
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _pressed ? 0.85 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: widget.child,
        ),
      ),
    );
  }
}
