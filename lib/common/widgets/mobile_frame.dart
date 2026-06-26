import 'package:flutter/material.dart';

/// On wide viewports (web/desktop), TailorTrack is a phone-shaped app, not
/// a responsive desktop layout — so above [_maxPhoneWidth] we center the
/// UI in a phone-width column instead of letting cards/grids stretch
/// across the whole browser window. Below that width (a real phone), this
/// is a no-op passthrough.
class MobileFrame extends StatelessWidget {
  final Widget child;
  const MobileFrame({super.key, required this.child});

  static const double _maxPhoneWidth = 430;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= _maxPhoneWidth) return child;

    return ColoredBox(
      color: Theme.of(context).brightness == Brightness.dark ? Colors.black : const Color(0xFFE7E9EC),
      child: Center(
        child: SizedBox(
          width: _maxPhoneWidth,
          child: child,
        ),
      ),
    );
  }
}
