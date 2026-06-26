import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

/// The TailorTrack logo mark: a needle threading a loop, rendered in white
/// on an emerald gradient rounded square. Sized by [size].
class BrandLogo extends StatelessWidget {
  final double size;
  const BrandLogo({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF15A06E), AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: size * 0.3, offset: Offset(0, size * 0.12)),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.24),
        child: CustomPaint(painter: _NeedlePainter()),
      ),
    );
  }
}

class _NeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Needle shaft (diagonal)
    canvas.drawLine(Offset(size.width * 0.18, size.height * 0.9), Offset(size.width * 0.82, size.height * 0.18), paint);

    // Eye of the needle (small circle near the top)
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.18), size.width * 0.1, paint);

    // Thread loop curving off the eye
    final thread = Path()
      ..moveTo(size.width * 0.82, size.height * 0.18)
      ..cubicTo(
        size.width * 1.05, size.height * 0.32,
        size.width * 0.45, size.height * 0.45,
        size.width * 0.62, size.height * 0.62,
      );
    canvas.drawPath(
      thread,
      paint
        ..strokeWidth = size.width * 0.08
        ..color = Colors.white.withOpacity(0.85),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// The "TailorTrack" wordmark in a premium display serif. [color] defaults
/// to the brand emerald; pass white when placing on a dark surface.
class BrandWordmark extends StatelessWidget {
  final double fontSize;
  final Color? color;
  const BrandWordmark({super.key, this.fontSize = 26, this.color});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'Tailor', style: TextStyle(color: color ?? AppColors.primary)),
          TextSpan(text: 'Track', style: TextStyle(color: (color ?? AppColors.primaryDark).withOpacity(color == null ? 1 : 0.85))),
        ],
      ),
      style: GoogleFonts.fraunces(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.0,
      ),
    );
  }
}

/// Logo mark + wordmark side by side, used in the Home header.
class BrandLockup extends StatelessWidget {
  final double logoSize;
  final double fontSize;
  const BrandLockup({super.key, this.logoSize = 40, this.fontSize = 26});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandLogo(size: logoSize),
        const SizedBox(width: 10),
        BrandWordmark(fontSize: fontSize),
      ],
    );
  }
}
