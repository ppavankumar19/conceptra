import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Subtle animated background with very soft ambient gradients.
/// No floating particles — just gentle breathing gradient washes.
class LightPillarBackground extends StatefulWidget {
  final Color topColor;
  final Color bottomColor;
  final double intensity;
  final Widget? child;

  const LightPillarBackground({
    super.key,
    this.topColor = const Color(0xFF5227FF),
    this.bottomColor = const Color(0xFFFF9FFC),
    this.intensity = 1.0,
    this.child,
  });

  @override
  State<LightPillarBackground> createState() => _LightPillarBackgroundState();
}

class _LightPillarBackgroundState extends State<LightPillarBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _SubtleBgPainter(
            progress: _controller.value,
            topColor: widget.topColor,
            bottomColor: widget.bottomColor,
            intensity: widget.intensity,
          ),
          child: child,
        );
      },
      child: widget.child ?? const SizedBox.expand(),
    );
  }
}

class _SubtleBgPainter extends CustomPainter {
  final double progress;
  final Color topColor;
  final Color bottomColor;
  final double intensity;

  _SubtleBgPainter({
    required this.progress,
    required this.topColor,
    required this.bottomColor,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Solid dark base
    final bgPaint = Paint()..color = const Color(0xFF0D0A1F);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Very subtle top-left purple ambient glow — slowly breathes
    final breathe = 0.85 + 0.15 * math.sin(progress * math.pi * 2);
    final glowRadius = size.width * 0.5 * breathe;
    final topGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.8, -0.6),
        radius: 0.9,
        colors: [
          topColor.withValues(alpha: 0.06 * intensity),
          topColor.withValues(alpha: 0.02 * intensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), topGlow);

    // Bottom-right pink ambient glow — opposite phase
    final breathe2 = 0.85 + 0.15 * math.sin(progress * math.pi * 2 + math.pi);
    final bottomGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.7, 0.8),
        radius: 0.8,
        colors: [
          bottomColor.withValues(alpha: 0.04 * intensity * breathe2),
          bottomColor.withValues(alpha: 0.015 * intensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bottomGlow);

    // Single very faint centre pillar — almost invisible, just adds depth
    _drawFaintPillar(canvas, size, size.width * 0.35, breathe);
  }

  void _drawFaintPillar(Canvas canvas, Size size, double x, double breathe) {
    final pillarWidth = size.width * 0.06;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          topColor.withValues(alpha: 0.025 * intensity * breathe),
          bottomColor.withValues(alpha: 0.02 * intensity * breathe),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(x - pillarWidth / 2, 0, pillarWidth, size.height));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - pillarWidth / 2, 0, pillarWidth, size.height),
        Radius.circular(pillarWidth / 2),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SubtleBgPainter old) =>
      old.progress != progress;
}
