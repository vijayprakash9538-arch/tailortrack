import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../common/widgets/brand.dart';
import '../../core/theme/app_colors.dart';

/// First screen shown on launch. Animates a needle "stitching" through
/// a thread path, then hands off to Home after a short delay.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) context.go('/home');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return SizedBox(
                  width: 140,
                  height: 100,
                  child: CustomPaint(
                    painter: _ThreadPainter(progress: _controller.value),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            const BrandLogo(size: 64),
            const SizedBox(height: 16),
            const BrandWordmark(fontSize: 30),
            const SizedBox(height: 8),
            Text(
              'Smart Tailoring. Simple Management.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws a dashed thread path with a needle that travels along it as
/// [progress] animates 0 → 1.
class _ThreadPainter extends CustomPainter {
  final double progress;
  _ThreadPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(10, size.height / 2)
      ..quadraticBezierTo(size.width * 0.3, 10, size.width * 0.5, size.height / 2)
      ..quadraticBezierTo(size.width * 0.7, size.height - 10, size.width - 10, size.height / 2);

    final metrics = path.computeMetrics().first;
    final drawPath = metrics.extractPath(0, metrics.length * progress);

    final threadPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(drawPath, threadPaint);

    final tangent = metrics.getTangentForOffset(metrics.length * progress);
    if (tangent != null) {
      final needlePaint = Paint()..color = AppColors.primary;
      canvas.save();
      canvas.translate(tangent.position.dx, tangent.position.dy);
      canvas.rotate(tangent.angle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-14, -2, 28, 4), const Radius.circular(2)),
        needlePaint,
      );
      canvas.drawCircle(const Offset(12, 0), 3, Paint()..color = AppColors.primary..style = PaintingStyle.stroke..strokeWidth = 1.5);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ThreadPainter oldDelegate) => oldDelegate.progress != progress;
}
