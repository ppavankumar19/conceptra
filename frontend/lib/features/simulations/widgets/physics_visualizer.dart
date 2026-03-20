import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../providers/simulation_provider.dart';

/// Returns the appropriate visualizer widget for a given simulation topic.
Widget buildVisualizer({
  required SimulationResult result,
  required String topic,
  required Color color,
}) {
  switch (topic) {
    case 'speed':
      return _MotionVisualizer(result: result, color: color,
        description: 'The ball moves along the track. Faster speed = the ball covers more distance in the same time. Speed = Distance ÷ Time.');
    case 'acceleration':
      return _MotionVisualizer(result: result, color: color,
        description: 'Watch the ball accelerate — it starts slow and gets faster. Acceleration measures how quickly velocity changes over time.');
    case 'force':
      return _ForceVisualizer(result: result, color: color,
        description: 'The arrow shows the force applied to the box. Larger force or smaller mass → greater acceleration (F = m × a).');
    case 'pressure':
      return _ForceVisualizer(result: result, color: color,
        description: 'Pressure = Force ÷ Area. The same force on a smaller area creates higher pressure — like a nail vs. your palm.');
    case 'pendulum':
      return _PendulumVisualizer(result: result, color: color,
        description: 'The pendulum swings at its natural period T. Longer string → slower swing. The bob weight does not affect the period!');
    case 'projectile':
      return _ProjectileVisualizer(result: result, color: color,
        description: 'The ball follows a parabolic path. 45° launch angle gives maximum range. Gravity pulls it down throughout the flight.');
    case 'ohms_law':
      return _CircuitVisualizer(result: result, color: color,
        description: 'Electrons flow through the circuit. The zigzag is the resistor. Higher resistance = less current for the same voltage (V = I × R).');
    case 'work_energy':
      return _WorkVisualizer(result: result, color: color,
        description: 'Work is done when a force moves an object. The block slides as force is applied over a distance. W = F × d × cos(θ).');
    case 'density':
      return _DensityVisualizer(result: result, color: color,
        description: 'The container fills with particles representing matter. More particles in the same volume = higher density. ρ = Mass ÷ Volume.');
    case 'gravitational_force':
      return _GravitationalForceVisualizer(result: result, color: color,
        description: 'Two masses attract each other. The pulsing force line shows gravitational pull. Greater mass or shorter distance = stronger force.');
    case 'ideal_gas':
      return _IdealGasVisualizer(result: result, color: color,
        description: 'Gas molecules bounce inside the container. The thermometer shows temperature. PV = nRT — higher temp → faster molecules → more pressure.');
    case 'pythagorean':
      return _PythagoreanVisualizer(result: result, color: color,
        description: 'A right triangle with sides a and b, and hypotenuse c. The theorem states: c² = a² + b². The square marker shows the 90° angle.');
    case 'area_circle':
      return _AreaCircleVisualizer(result: result, color: color,
        description: 'The circle expands to show its area. The radius line (r) is the key: Area = π × r². Double the radius → 4× the area!');
    case 'simple_interest':
      return _SimpleInterestVisualizer(result: result, color: color,
        description: 'The bars compare Principal (P), Simple Interest (SI), and Total amount. SI = (P × R × T) ÷ 100. Interest stays the same each year.');
    case 'linear_equation':
      return _LinearEquationVisualizer(result: result, color: color,
        description: 'A straight line of the form y = mx + c. The slope (m) controls steepness, and the y-intercept (c) is where it crosses the y-axis.');
    case 'quadratic':
      return _QuadraticVisualizer(result: result, color: color,
        description: 'A parabola (U-shape) of the form y = ax² + bx + c. The vertex is the peak/valley. If a > 0 it opens upward, if a < 0 it opens downward.');
    case 'trigonometry':
      return _WaveVisualizer(result: result, color: color,
        description: 'A sine wave oscillates between -1 and +1. Trigonometric functions (sin, cos, tan) relate angles to ratios of triangle sides.');
    default:
      return _GenericValueVisualizer(result: result, color: color,
        description: 'The calculated result is shown below. Adjust the parameters and recalculate to see how values change.');
  }
}

// ── Motion Visualizer (speed / acceleration) ──────────────────────────────

class _MotionVisualizer extends StatefulWidget {
  final SimulationResult result;
  final Color color;
  final String description;
  const _MotionVisualizer({required this.result, required this.color, required this.description});

  @override
  State<_MotionVisualizer> createState() => _MotionVisualizerState();
}

class _MotionVisualizerState extends State<_MotionVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return _VisualizerCard(
      title: '${widget.result.resultLabel}: ${widget.result.resultValue.toStringAsFixed(2)} ${widget.result.resultUnit}',
      description: widget.description,
      color: widget.color,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          return CustomPaint(
            size: const Size(double.infinity, 120),
            painter: _MotionPainter(progress: _anim.value, color: widget.color),
          );
        },
      ),
    );
  }
}

class _MotionPainter extends CustomPainter {
  final double progress;
  final Color color;
  _MotionPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Road
    final roadPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, size.height * 0.6),
        Offset(size.width, size.height * 0.6),
        [color.withValues(alpha: 0.1), color.withValues(alpha: 0.3)],
      )
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(0, size.height * 0.6, size.width, 10),
          const Radius.circular(5)),
      roadPaint,
    );
    // Dashed center line
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 8; i++) {
      final x = (size.width / 8) * i + progress * (size.width / 8);
      canvas.drawLine(
        Offset(x % size.width, size.height * 0.65),
        Offset((x + size.width / 16) % size.width, size.height * 0.65),
        linePaint,
      );
    }
    // Trail gradient
    final ballX = progress * (size.width - 44) + 22;
    final ballY = size.height * 0.52;
    for (int i = 5; i >= 1; i--) {
      final tx = ballX - i * 14.0;
      if (tx > 0) {
        final trailPaint = Paint()
          ..color = color.withValues(alpha: 0.06 * (5 - i + 1))
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(tx, ballY), 18 - i * 2.0, trailPaint);
      }
    }
    // Ball with glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(ballX, ballY), 22, glowPaint);
    final ballPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(ballX - 5, ballY - 5),
        20,
        [Colors.white.withValues(alpha: 0.6), color],
      );
    canvas.drawCircle(Offset(ballX, ballY), 18, ballPaint);
    // Highlight
    canvas.drawCircle(
      Offset(ballX - 6, ballY - 6),
      5,
      Paint()..color = Colors.white.withValues(alpha: 0.5),
    );
    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(ballX, size.height * 0.65), width: 38, height: 8),
      Paint()..color = color.withValues(alpha: 0.2),
    );
  }

  @override
  bool shouldRepaint(_MotionPainter old) => old.progress != progress;
}

// ── Force Visualizer ──────────────────────────────────────────────────────

class _ForceVisualizer extends StatefulWidget {
  final SimulationResult result;
  final Color color;
  final String description;
  const _ForceVisualizer({required this.result, required this.color, required this.description});
  @override
  State<_ForceVisualizer> createState() => _ForceVisualizerState();
}

class _ForceVisualizerState extends State<_ForceVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return _VisualizerCard(
      title: '${widget.result.resultLabel}: ${widget.result.resultValue.toStringAsFixed(2)} ${widget.result.resultUnit}',
      description: widget.description,
      color: widget.color,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) => CustomPaint(
          size: const Size(double.infinity, 120),
          painter: _ForcePainter(progress: _anim.value, color: widget.color),
        ),
      ),
    );
  }
}

class _ForcePainter extends CustomPainter {
  final double progress;
  final Color color;
  _ForcePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    // Box
    final boxPaint = Paint()..color = color.withValues(alpha:0.2)..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: 50, height: 40), const Radius.circular(6)), boxPaint);
    final borderPaint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: 50, height: 40), const Radius.circular(6)), borderPaint);
    // Arrow
    final arrowLength = 60.0 * progress;
    final arrowPaint = Paint()..color = color..strokeWidth = 4..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx + 25, cy), Offset(cx + 25 + arrowLength, cy), arrowPaint);
    if (arrowLength > 10) {
      final path = Path()
        ..moveTo(cx + 25 + arrowLength, cy)
        ..lineTo(cx + 25 + arrowLength - 12, cy - 8)
        ..lineTo(cx + 25 + arrowLength - 12, cy + 8)
        ..close();
      canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(_ForcePainter old) => old.progress != progress;
}

// ── Pendulum Visualizer ───────────────────────────────────────────────────

class _PendulumVisualizer extends StatefulWidget {
  final SimulationResult result;
  final Color color;
  final String description;
  const _PendulumVisualizer({required this.result, required this.color, required this.description});
  @override
  State<_PendulumVisualizer> createState() => _PendulumVisualizerState();
}

class _PendulumVisualizerState extends State<_PendulumVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    // Use the actual period from result
    final periodMs = (widget.result.resultValue * 1000).clamp(500, 4000).toInt();
    _ctrl = AnimationController(vsync: this, duration: Duration(milliseconds: periodMs));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return _VisualizerCard(
      title: 'Period T = ${widget.result.resultValue.toStringAsFixed(3)} s',
      description: widget.description,
      color: widget.color,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) => CustomPaint(
          size: const Size(double.infinity, 130),
          painter: _PendulumPainter(swing: (_anim.value * 2 - 1) * 0.5, color: widget.color),
        ),
      ),
    );
  }
}

class _PendulumPainter extends CustomPainter {
  final double swing; // -0.5 to 0.5 radians
  final Color color;
  _PendulumPainter({required this.swing, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    const pivotY = 16.0;
    const stringLength = 95.0;
    final angle = swing;
    final bobX = cx + stringLength * math.sin(angle);
    final bobY = pivotY + stringLength * math.cos(angle);
    // Arc trace
    final arcPaint = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, pivotY), width: stringLength * 2, height: stringLength * 2),
      math.pi / 2 - 0.5, 1.0, false, arcPaint,
    );
    // String with gradient
    final stringPaint = Paint()
      ..shader = ui.Gradient.linear(Offset(cx, pivotY), Offset(bobX, bobY), [
        color.withValues(alpha: 0.5),
        color,
      ])
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx, pivotY), Offset(bobX, bobY), stringPaint);
    // Pivot
    canvas.drawCircle(
      Offset(cx, pivotY), 6,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
    // Bob glow
    canvas.drawCircle(
      Offset(bobX, bobY), 18,
      Paint()
        ..color = color.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    // Bob
    canvas.drawCircle(
      Offset(bobX, bobY), 14,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(bobX - 4, bobY - 4), 14,
          [Colors.white.withValues(alpha: 0.5), color],
        ),
    );
    canvas.drawCircle(
      Offset(bobX, bobY), 14,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_PendulumPainter old) => old.swing != swing;
}

// ── Projectile Visualizer ─────────────────────────────────────────────────

class _ProjectileVisualizer extends StatefulWidget {
  final SimulationResult result;
  final Color color;
  final String description;
  const _ProjectileVisualizer({required this.result, required this.color, required this.description});
  @override
  State<_ProjectileVisualizer> createState() => _ProjectileVisualizerState();
}

class _ProjectileVisualizerState extends State<_ProjectileVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.linear);
    _ctrl.repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return _VisualizerCard(
      title: 'Range: ${widget.result.resultValue.toStringAsFixed(1)} m',
      description: widget.description,
      color: widget.color,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) => CustomPaint(
          size: const Size(double.infinity, 130),
          painter: _ProjectilePainter(progress: _anim.value, color: widget.color),
        ),
      ),
    );
  }
}

class _ProjectilePainter extends CustomPainter {
  final double progress;
  final Color color;
  _ProjectilePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final groundY = h - 15.0;
    // Ground
    canvas.drawLine(Offset(0, groundY), Offset(w, groundY),
        Paint()..color = color.withValues(alpha:0.3)..strokeWidth = 2);
    // Parabola path
    final pathPaint = Paint()..color = color.withValues(alpha:0.2)..style = PaintingStyle.stroke..strokeWidth = 2..strokeCap = StrokeCap.round;
    final path = Path();
    for (int i = 0; i <= 100; i++) {
      final t = i / 100;
      final x = t * (w - 20) + 10;
      final y = groundY - (4 * (h - 40) * t * (1 - t));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, pathPaint);
    // Ball at current position
    final t = progress;
    final ballX = t * (w - 20) + 10;
    final ballY = groundY - (4 * (h - 40) * t * (1 - t));
    canvas.drawCircle(Offset(ballX, ballY), 12, Paint()..color = color);
    // Shadow
    canvas.drawOval(Rect.fromCenter(center: Offset(ballX, groundY + 3), width: 20, height: 6),
        Paint()..color = color.withValues(alpha:0.2));
  }

  @override
  bool shouldRepaint(_ProjectilePainter old) => old.progress != progress;
}

// ── Circuit Visualizer (Ohm's Law) ────────────────────────────────────────

class _CircuitVisualizer extends StatefulWidget {
  final SimulationResult result;
  final Color color;
  final String description;
  const _CircuitVisualizer({required this.result, required this.color, required this.description});
  @override
  State<_CircuitVisualizer> createState() => _CircuitVisualizerState();
}

class _CircuitVisualizerState extends State<_CircuitVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _anim = Tween<double>(begin: 0, end: 1).animate(_ctrl);
    _ctrl.repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return _VisualizerCard(
      title: 'Current I = ${widget.result.resultValue.toStringAsFixed(4)} A',
      description: widget.description,
      color: widget.color,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) => CustomPaint(
          size: const Size(double.infinity, 120),
          painter: _CircuitPainter(flow: _anim.value, color: widget.color),
        ),
      ),
    );
  }
}

class _CircuitPainter extends CustomPainter {
  final double flow;
  final Color color;
  _CircuitPainter({required this.flow, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cy = h / 2;
    final linePaint = Paint()..color = color.withValues(alpha:0.5)..strokeWidth = 2.5..style = PaintingStyle.stroke;
    // Circuit rectangle
    const margin = 24.0;
    final rect = Rect.fromLTRB(margin, cy - 28, w - margin, cy + 28);
    canvas.drawRect(rect, linePaint);
    // Battery (left side)
    final batPaint = Paint()..color = color..strokeWidth = 3;
    canvas.drawLine(Offset(margin, cy - 12), Offset(margin, cy + 12), batPaint);
    canvas.drawLine(Offset(margin - 5, cy - 6), Offset(margin - 5, cy + 6), batPaint..strokeWidth = 6);
    // Resistor (top side) - zigzag
    final zPath = Path();
    final zStart = w / 2 - 30.0;
    final zEnd = w / 2 + 30.0;
    zPath.moveTo(zStart, cy - 28);
    for (int i = 0; i < 6; i++) {
      final x = zStart + i * 10.0;
      zPath.lineTo(x + 5, cy - 28 + (i.isEven ? -8 : 8));
    }
    zPath.lineTo(zEnd, cy - 28);
    canvas.drawPath(zPath, linePaint);
    // Flowing electrons
    final electronPaint = Paint()..color = color..style = PaintingStyle.fill;
    // Perimeter positions
    final perimeter = 2 * (rect.width + rect.height);
    for (int i = 0; i < 4; i++) {
      final pos = (flow + i / 4.0) % 1.0;
      final dist = pos * perimeter;
      Offset ePos;
      if (dist < rect.width) {
        ePos = Offset(rect.left + dist, rect.top);
      } else if (dist < rect.width + rect.height) {
        ePos = Offset(rect.right, rect.top + (dist - rect.width));
      } else if (dist < 2 * rect.width + rect.height) {
        ePos = Offset(rect.right - (dist - rect.width - rect.height), rect.bottom);
      } else {
        ePos = Offset(rect.left, rect.bottom - (dist - 2 * rect.width - rect.height));
      }
      canvas.drawCircle(ePos, 4, electronPaint);
    }
  }

  @override
  bool shouldRepaint(_CircuitPainter old) => old.flow != flow;
}

// ── Work Visualizer ───────────────────────────────────────────────────────

class _WorkVisualizer extends StatefulWidget {
  final SimulationResult result;
  final Color color;
  final String description;
  const _WorkVisualizer({required this.result, required this.color, required this.description});
  @override
  State<_WorkVisualizer> createState() => _WorkVisualizerState();
}

class _WorkVisualizerState extends State<_WorkVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return _VisualizerCard(
      title: 'Work Done: ${widget.result.resultValue.toStringAsFixed(2)} J',
      description: widget.description,
      color: widget.color,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) => CustomPaint(
          size: const Size(double.infinity, 120),
          painter: _WorkPainter(progress: _anim.value, color: widget.color),
        ),
      ),
    );
  }
}

class _WorkPainter extends CustomPainter {
  final double progress;
  final Color color;
  _WorkPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final groundY = size.height - 20.0;
    // Ground
    canvas.drawLine(Offset(0, groundY), Offset(size.width, groundY),
        Paint()..color = color.withValues(alpha:0.3)..strokeWidth = 2);
    // Block position
    final blockX = 20 + progress * (size.width - 80);
    final blockY = groundY - 36.0;
    final boxPaint = Paint()..color = color.withValues(alpha:0.25);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(blockX, blockY, 36, 36), const Radius.circular(4)), boxPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(blockX, blockY, 36, 36), const Radius.circular(4)),
        Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2);
    // Force arrow
    final arrowEnd = blockX + 36 + 40;
    canvas.drawLine(Offset(blockX + 36, groundY - 18), Offset(arrowEnd, groundY - 18),
        Paint()..color = color..strokeWidth = 3..strokeCap = StrokeCap.round);
    final arrowPath = Path()
      ..moveTo(arrowEnd, groundY - 18)
      ..lineTo(arrowEnd - 10, groundY - 25)
      ..lineTo(arrowEnd - 10, groundY - 11)
      ..close();
    canvas.drawPath(arrowPath, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_WorkPainter old) => old.progress != progress;
}

// ── Density Visualizer ────────────────────────────────────────────────────

class _DensityVisualizer extends StatefulWidget {
  final SimulationResult result;
  final Color color;
  final String description;
  const _DensityVisualizer({required this.result, required this.color, required this.description});
  @override
  State<_DensityVisualizer> createState() => _DensityVisualizerState();
}

class _DensityVisualizerState extends State<_DensityVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return _VisualizerCard(
      title: 'Density: ${widget.result.resultValue.toStringAsFixed(2)} kg/m³',
      description: widget.description,
      color: widget.color,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) => CustomPaint(
          size: const Size(double.infinity, 120),
          painter: _DensityPainter(fill: _anim.value, color: widget.color),
        ),
      ),
    );
  }
}

class _DensityPainter extends CustomPainter {
  final double fill;
  final Color color;
  _DensityPainter({required this.fill, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    const containerH = 80.0;
    const containerW = 60.0;
    final top = size.height / 2 - containerH / 2;
    final rect = Rect.fromCenter(center: Offset(cx, size.height / 2), width: containerW, height: containerH);
    // Fill
    final fillHeight = containerH * fill;
    final fillRect = Rect.fromLTWH(cx - containerW / 2, top + containerH - fillHeight, containerW, fillHeight);
    final rrect = RRect.fromRectAndRadius(fillRect, const Radius.circular(4));
    canvas.drawRRect(rrect, Paint()..color = color.withValues(alpha:0.3));
    // Particles
    if (fill > 0.1) {
      final particlePaint = Paint()..color = color.withValues(alpha:0.7);
      final numParticles = (fill * 12).round();
      for (int i = 0; i < numParticles; i++) {
        final px = cx - containerW / 2 + 8 + (i % 4) * 13.0;
        final py = top + containerH - (i ~/ 4 + 1) * 14.0;
        canvas.drawCircle(Offset(px, py), 4, particlePaint);
      }
    }
    // Container border
    final containerRRect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    canvas.drawRRect(containerRRect, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2.5);
  }

  @override
  bool shouldRepaint(_DensityPainter old) => old.fill != fill;
}

// ── Wave Visualizer (math topics) ─────────────────────────────────────────

class _WaveVisualizer extends StatefulWidget {
  final SimulationResult result;
  final Color color;
  final String description;
  const _WaveVisualizer({required this.result, required this.color, required this.description});
  @override
  State<_WaveVisualizer> createState() => _WaveVisualizerState();
}

class _WaveVisualizerState extends State<_WaveVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _anim = Tween<double>(begin: 0, end: 2 * math.pi).animate(_ctrl);
    _ctrl.repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return _VisualizerCard(
      title: '${widget.result.resultLabel}: ${widget.result.resultValue.toStringAsFixed(4)} ${widget.result.resultUnit}',
      description: widget.description,
      color: widget.color,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) => CustomPaint(
          size: const Size(double.infinity, 100),
          painter: _WavePainter(phase: _anim.value, color: widget.color),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double phase;
  final Color color;
  _WavePainter({required this.phase, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final midY = size.height / 2;
    for (int i = 0; i <= size.width.toInt(); i++) {
      final x = i.toDouble();
      final y = midY - 30 * math.sin(2 * math.pi * x / size.width + phase);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, Paint()..color = color..strokeWidth = 2.5..style = PaintingStyle.stroke);
    // Axis
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY),
        Paint()..color = color.withValues(alpha:0.2)..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.phase != phase;
}

// ── Gravitational Force Visualizer ────────────────────────────────────────

class _GravitationalForceVisualizer extends StatefulWidget {
  final SimulationResult result;
  final Color color;
  final String description;
  const _GravitationalForceVisualizer({required this.result, required this.color, required this.description});
  @override
  State<_GravitationalForceVisualizer> createState() => _GravitationalForceVisualizerState();
}

class _GravitationalForceVisualizerState extends State<_GravitationalForceVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));
    _anim = Tween<double>(begin: 0, end: 2 * math.pi).animate(_ctrl);
    _ctrl.repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return _VisualizerCard(
      title: 'Gravitational Force: ${widget.result.resultValue.toStringAsExponential(3)} N',
      description: widget.description,
      color: widget.color,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) => CustomPaint(
          size: const Size(double.infinity, 130),
          painter: _GravitationalForcePainter(phase: _anim.value, color: widget.color),
        ),
      ),
    );
  }
}

class _GravitationalForcePainter extends CustomPainter {
  final double phase;
  final Color color;
  _GravitationalForcePainter({required this.phase, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    // Two masses: one larger (left), one smaller (right)
    final pulse = 0.5 + 0.5 * math.sin(phase);
    // Mass 1 (left)
    final m1x = cx - 60;
    final m1r = 22.0 + pulse * 4;
    canvas.drawCircle(Offset(m1x, cy), m1r + 6,
        Paint()..color = color.withValues(alpha: 0.15)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawCircle(Offset(m1x, cy), m1r,
        Paint()..shader = ui.Gradient.radial(Offset(m1x - 5, cy - 5), m1r, [Colors.white.withValues(alpha: 0.5), color]));
    // Mass 2 (right)
    final m2x = cx + 60;
    final m2r = 14.0 + pulse * 2;
    canvas.drawCircle(Offset(m2x, cy), m2r + 4,
        Paint()..color = color.withValues(alpha: 0.12)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawCircle(Offset(m2x, cy), m2r,
        Paint()..shader = ui.Gradient.radial(Offset(m2x - 3, cy - 3), m2r, [Colors.white.withValues(alpha: 0.4), color.withValues(alpha: 0.8)]));
    // Force line between them (pulsing)
    final lineAlpha = 0.3 + 0.4 * pulse;
    final linePaint = Paint()
      ..color = color.withValues(alpha: lineAlpha)
      ..strokeWidth = 2 + pulse * 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(m1x + m1r, cy), Offset(m2x - m2r, cy), linePaint);
    // Arrows pointing inward
    final arrowPaint = Paint()..color = color..style = PaintingStyle.fill;
    // Arrow on left mass side (pointing right)
    final al = m1x + m1r + 8;
    final arrowL = Path()..moveTo(al, cy)..lineTo(al + 10, cy - 6)..lineTo(al + 10, cy + 6)..close();
    canvas.drawPath(arrowL, arrowPaint);
    // Arrow on right mass side (pointing left)
    final ar = m2x - m2r - 8;
    final arrowR = Path()..moveTo(ar, cy)..lineTo(ar - 10, cy - 6)..lineTo(ar - 10, cy + 6)..close();
    canvas.drawPath(arrowR, arrowPaint);
    // Labels
    _drawLabel(canvas, 'M₁', Offset(m1x, cy + m1r + 12), color);
    _drawLabel(canvas, 'M₂', Offset(m2x, cy + m2r + 12), color);
  }

  void _drawLabel(Canvas canvas, String text, Offset pos, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy));
  }

  @override
  bool shouldRepaint(_GravitationalForcePainter old) => old.phase != phase;
}

// ── Ideal Gas Visualizer ──────────────────────────────────────────────────

class _IdealGasVisualizer extends StatefulWidget {
  final SimulationResult result;
  final Color color;
  final String description;
  const _IdealGasVisualizer({required this.result, required this.color, required this.description});
  @override
  State<_IdealGasVisualizer> createState() => _IdealGasVisualizerState();
}

class _IdealGasVisualizerState extends State<_IdealGasVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000));
    _anim = Tween<double>(begin: 0, end: 1).animate(_ctrl);
    _ctrl.repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return _VisualizerCard(
      title: 'Volume: ${widget.result.resultValue.toStringAsFixed(4)} m³',
      description: widget.description,
      color: widget.color,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) => CustomPaint(
          size: const Size(double.infinity, 130),
          painter: _IdealGasPainter(time: _anim.value, color: widget.color),
        ),
      ),
    );
  }
}

class _IdealGasPainter extends CustomPainter {
  final double time;
  final Color color;
  _IdealGasPainter({required this.time, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    const containerW = 100.0;
    const containerH = 90.0;
    final rect = Rect.fromCenter(center: Offset(cx, size.height / 2), width: containerW, height: containerH);
    // Container
    final containerPaint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2.5;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), containerPaint);
    // Fill background
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        Paint()..color = color.withValues(alpha: 0.06));
    // Particles bouncing around
    final seed = 42;
    final rng = math.Random(seed);
    final particlePaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 12; i++) {
      final speedX = 0.5 + rng.nextDouble() * 1.5;
      final speedY = 0.3 + rng.nextDouble() * 1.2;
      final phase = rng.nextDouble() * 2 * math.pi;
      final px = rect.left + 8 + (rect.width - 16) * (0.5 + 0.45 * math.sin(time * 2 * math.pi * speedX + phase));
      final py = rect.top + 8 + (rect.height - 16) * (0.5 + 0.45 * math.cos(time * 2 * math.pi * speedY + phase * 1.3));
      final opacity = 0.5 + 0.5 * math.sin(time * 2 * math.pi + i);
      particlePaint.color = color.withValues(alpha: 0.3 + 0.5 * opacity);
      canvas.drawCircle(Offset(px, py), 3.5, particlePaint);
      // Small motion trail
      final trailPaint = Paint()..color = color.withValues(alpha: 0.1);
      canvas.drawCircle(Offset(px - 3 * math.sin(time * 2 * math.pi * speedX + phase),
          py - 3 * math.cos(time * 2 * math.pi * speedY + phase * 1.3)), 2, trailPaint);
    }
    // Thermometer symbol on the right
    final thX = rect.right + 18;
    final thH = containerH * 0.7;
    final thTop = size.height / 2 - thH / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(thX - 3, thTop, 6, thH), const Radius.circular(3)),
      Paint()..color = color.withValues(alpha: 0.25),
    );
    // Fill level (pulsing)
    final fillLevel = 0.4 + 0.3 * math.sin(time * 2 * math.pi);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(thX - 3, thTop + thH * (1 - fillLevel), 6, thH * fillLevel), const Radius.circular(3)),
      Paint()..color = color.withValues(alpha: 0.6),
    );
  }

  @override
  bool shouldRepaint(_IdealGasPainter old) => old.time != time;
}

// ── Pythagorean Visualizer ────────────────────────────────────────────────

class _PythagoreanVisualizer extends StatefulWidget {
  final SimulationResult result;
  final Color color;
  final String description;
  const _PythagoreanVisualizer({required this.result, required this.color, required this.description});
  @override
  State<_PythagoreanVisualizer> createState() => _PythagoreanVisualizerState();
}

class _PythagoreanVisualizerState extends State<_PythagoreanVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return _VisualizerCard(
      title: 'Hypotenuse c = ${widget.result.resultValue.toStringAsFixed(3)}',
      description: widget.description,
      color: widget.color,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) => CustomPaint(
          size: const Size(double.infinity, 130),
          painter: _PythagoreanPainter(progress: _anim.value, color: widget.color),
        ),
      ),
    );
  }
}

class _PythagoreanPainter extends CustomPainter {
  final double progress;
  final Color color;
  _PythagoreanPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    // Triangle vertices (right angle at bottom-left)
    final ax = cx - 50; // bottom-left (right angle)
    final ay = cy + 35;
    final bx = cx + 50; // bottom-right
    final by = ay;       // same y
    final cpx = ax;      // top-left
    final cpy = cy - 35;
    // Draw sides with animation
    final sidePaint = Paint()..color = color..strokeWidth = 2.5..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    // Side a (bottom)
    canvas.drawLine(Offset(ax, ay), Offset(ax + (bx - ax) * progress, ay), sidePaint);
    // Side b (left vertical)
    canvas.drawLine(Offset(ax, ay), Offset(ax, ay + (cpy - ay) * progress), sidePaint);
    // Hypotenuse c (animated last, diagonal)
    if (progress > 0.3) {
      final hypProgress = ((progress - 0.3) / 0.7).clamp(0.0, 1.0);
      final hypPaint = Paint()..color = color..strokeWidth = 3.5..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(bx, by),
        Offset(bx + (cpx - bx) * hypProgress, by + (cpy - by) * hypProgress),
        hypPaint,
      );
    }
    // Right angle marker
    if (progress > 0.5) {
      const markSize = 10.0;
      final markPaint = Paint()..color = color.withValues(alpha: 0.5)..strokeWidth = 1.5..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(ax + markSize, ay), Offset(ax + markSize, ay - markSize), markPaint);
      canvas.drawLine(Offset(ax + markSize, ay - markSize), Offset(ax, ay - markSize), markPaint);
    }
    // Fill triangle with transparent color
    if (progress > 0.6) {
      final fillAlpha = ((progress - 0.6) / 0.4).clamp(0.0, 1.0) * 0.12;
      final fillPath = Path()..moveTo(ax, ay)..lineTo(bx, by)..lineTo(cpx, cpy)..close();
      canvas.drawPath(fillPath, Paint()..color = color.withValues(alpha: fillAlpha));
    }
    // Labels
    if (progress > 0.8) {
      _drawLabel(canvas, 'a', Offset((ax + bx) / 2, ay + 14), color);
      _drawLabel(canvas, 'b', Offset(ax - 14, (ay + cpy) / 2), color);
      _drawLabel(canvas, 'c', Offset((bx + cpx) / 2 + 10, (by + cpy) / 2 - 6), color);
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset pos, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_PythagoreanPainter old) => old.progress != progress;
}

// ── Area Circle Visualizer ────────────────────────────────────────────────

class _AreaCircleVisualizer extends StatefulWidget {
  final SimulationResult result;
  final Color color;
  final String description;
  const _AreaCircleVisualizer({required this.result, required this.color, required this.description});
  @override
  State<_AreaCircleVisualizer> createState() => _AreaCircleVisualizerState();
}

class _AreaCircleVisualizerState extends State<_AreaCircleVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return _VisualizerCard(
      title: 'Area: ${widget.result.resultValue.toStringAsFixed(2)} m²',
      description: widget.description,
      color: widget.color,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) => CustomPaint(
          size: const Size(double.infinity, 130),
          painter: _AreaCirclePainter(progress: _anim.value, color: widget.color),
        ),
      ),
    );
  }
}

class _AreaCirclePainter extends CustomPainter {
  final double progress;
  final Color color;
  _AreaCirclePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = math.min(size.width, size.height) / 2 - 15;
    final r = maxR * progress;
    // Glow
    canvas.drawCircle(Offset(cx, cy), r + 6,
        Paint()..color = color.withValues(alpha: 0.15)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    // Filled circle
    canvas.drawCircle(Offset(cx, cy), r,
        Paint()..shader = ui.Gradient.radial(Offset(cx, cy), r > 0 ? r : 1, [
          color.withValues(alpha: 0.15),
          color.withValues(alpha: 0.3),
        ]));
    // Circumference
    canvas.drawCircle(Offset(cx, cy), r,
        Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2.5);
    // Radius line
    if (progress > 0.3) {
      final lineProgress = ((progress - 0.3) / 0.7).clamp(0.0, 1.0);
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + r * lineProgress, cy),
        Paint()..color = color..strokeWidth = 2..strokeCap = StrokeCap.round,
      );
      // 'r' label
      if (lineProgress > 0.5) {
        final tp = TextPainter(
          text: TextSpan(text: 'r', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(cx + r / 2 - tp.width / 2, cy - 16));
      }
    }
    // Center dot
    canvas.drawCircle(Offset(cx, cy), 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_AreaCirclePainter old) => old.progress != progress;
}

// ── Simple Interest Visualizer ────────────────────────────────────────────

class _SimpleInterestVisualizer extends StatefulWidget {
  final SimulationResult result;
  final Color color;
  final String description;
  const _SimpleInterestVisualizer({required this.result, required this.color, required this.description});
  @override
  State<_SimpleInterestVisualizer> createState() => _SimpleInterestVisualizerState();
}

class _SimpleInterestVisualizerState extends State<_SimpleInterestVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return _VisualizerCard(
      title: 'Total Amount: ₹${widget.result.resultValue.toStringAsFixed(2)}',
      description: widget.description,
      color: widget.color,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) => CustomPaint(
          size: const Size(double.infinity, 130),
          painter: _SimpleInterestPainter(progress: _anim.value, color: widget.color),
        ),
      ),
    );
  }
}

class _SimpleInterestPainter extends CustomPainter {
  final double progress;
  final Color color;
  _SimpleInterestPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final groundY = h - 16.0;
    // Ground line
    canvas.drawLine(Offset(20, groundY), Offset(w - 20, groundY),
        Paint()..color = color.withValues(alpha: 0.3)..strokeWidth = 1.5);
    // 3 bars: Principal, Interest, Total
    const barCount = 3;
    final barW = (w - 80) / barCount;
    final barGap = 12.0;
    final maxBarH = h - 50.0;
    final heights = [0.45, 0.25, 0.70]; // relative heights
    final labels = ['P', 'SI', 'Total'];
    final colors = [
      color.withValues(alpha: 0.6),
      color.withValues(alpha: 0.4),
      color,
    ];
    for (int i = 0; i < barCount; i++) {
      final barH = maxBarH * heights[i] * progress;
      final x = 30 + i * (barW + barGap);
      final y = groundY - barH;
      // Bar
      final barRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, y, barW, barH),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      canvas.drawRRect(barRect, Paint()..color = colors[i]);
      canvas.drawRRect(barRect, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.5);
      // Label below bar
      if (progress > 0.5) {
        final tp = TextPainter(
          text: TextSpan(
            text: labels[i],
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x + barW / 2 - tp.width / 2, groundY + 3));
      }
    }
    // Coin icon hint (₹) above the total bar
    if (progress > 0.7) {
      final coinX = 30 + 2 * (barW + barGap) + barW / 2;
      final coinY = groundY - maxBarH * heights[2] * progress - 14;
      final tp = TextPainter(
        text: TextSpan(text: '₹', style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(coinX - tp.width / 2, coinY - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_SimpleInterestPainter old) => old.progress != progress;
}

// ── Generic Value Visualizer ─────────────────────────────────────────────

// ── Linear Equation Visualizer ────────────────────────────────────────────

class _LinearEquationVisualizer extends StatefulWidget {
  final SimulationResult result;
  final Color color;
  final String description;
  const _LinearEquationVisualizer({required this.result, required this.color, required this.description});
  @override
  State<_LinearEquationVisualizer> createState() => _LinearEquationVisualizerState();
}

class _LinearEquationVisualizerState extends State<_LinearEquationVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return _VisualizerCard(
      title: '${widget.result.resultLabel}: ${widget.result.resultValue.toStringAsFixed(4)} ${widget.result.resultUnit}',
      description: widget.description,
      color: widget.color,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) => CustomPaint(
          size: const Size(double.infinity, 130),
          painter: _LinearLinePainter(progress: _anim.value, color: widget.color),
        ),
      ),
    );
  }
}

class _LinearLinePainter extends CustomPainter {
  final double progress;
  final Color color;
  _LinearLinePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    // Axes
    final axisPaint = Paint()..color = color.withValues(alpha: 0.2)..strokeWidth = 1;
    canvas.drawLine(Offset(20, cy), Offset(w - 20, cy), axisPaint);
    canvas.drawLine(Offset(cx, 10), Offset(cx, h - 10), axisPaint);
    // Grid lines
    final gridPaint = Paint()..color = color.withValues(alpha: 0.06)..strokeWidth = 0.5;
    for (int i = 1; i <= 4; i++) {
      final gx = cx + i * (w - 40) / 8;
      final gx2 = cx - i * (w - 40) / 8;
      canvas.drawLine(Offset(gx, 10), Offset(gx, h - 10), gridPaint);
      canvas.drawLine(Offset(gx2, 10), Offset(gx2, h - 10), gridPaint);
    }
    // Line y = mx + c (slope = 0.8, intercept shifted up)
    final slope = 0.8;
    final intercept = cy * 0.3; // shifted up from center
    final lineStartX = 20.0;
    final lineEndX = (w - 20) * progress + 20;
    final lineStartY = cy - (lineStartX - cx) * slope / (w / 2) * cy - intercept;
    final lineEndY = cy - (lineEndX - cx) * slope / (w / 2) * cy - intercept;
    final linePaint = Paint()..color = color..strokeWidth = 2.5..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(lineStartX, lineStartY.clamp(5.0, h - 5)),
      Offset(lineEndX, lineEndY.clamp(5.0, h - 5)),
      linePaint,
    );
    // Y-intercept dot
    if (progress > 0.3) {
      final yIntY = cy - intercept;
      canvas.drawCircle(Offset(cx, yIntY), 5, Paint()..color = color);
      _drawLabel(canvas, 'c', Offset(cx + 10, yIntY - 8), color);
    }
    // Axis labels
    if (progress > 0.7) {
      _drawLabel(canvas, 'x', Offset(w - 16, cy + 10), color);
      _drawLabel(canvas, 'y', Offset(cx + 8, 8), color);
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset pos, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_LinearLinePainter old) => old.progress != progress;
}

// ── Quadratic Visualizer ──────────────────────────────────────────────────

class _QuadraticVisualizer extends StatefulWidget {
  final SimulationResult result;
  final Color color;
  final String description;
  const _QuadraticVisualizer({required this.result, required this.color, required this.description});
  @override
  State<_QuadraticVisualizer> createState() => _QuadraticVisualizerState();
}

class _QuadraticVisualizerState extends State<_QuadraticVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return _VisualizerCard(
      title: '${widget.result.resultLabel}: ${widget.result.resultValue.toStringAsFixed(4)} ${widget.result.resultUnit}',
      description: widget.description,
      color: widget.color,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) => CustomPaint(
          size: const Size(double.infinity, 130),
          painter: _ParabolaPainter(progress: _anim.value, color: widget.color),
        ),
      ),
    );
  }
}

class _ParabolaPainter extends CustomPainter {
  final double progress;
  final Color color;
  _ParabolaPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    // Axes
    final axisPaint = Paint()..color = color.withValues(alpha: 0.2)..strokeWidth = 1;
    canvas.drawLine(Offset(20, cy), Offset(w - 20, cy), axisPaint);
    canvas.drawLine(Offset(cx, 10), Offset(cx, h - 10), axisPaint);
    // Parabola path: y = a(x-h)^2 + k — vertex at center top
    final path = Path();
    final steps = (100 * progress).round();
    for (int i = 0; i <= steps; i++) {
      final t = i / 100;
      final x = 20 + t * (w - 40);
      final nx = (x - cx) / (w / 2 - 20); // normalized -1 to 1
      final y = cy - (1 - nx * nx) * (cy - 20); // inverted parabola
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, Paint()..color = color..strokeWidth = 2.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    // Fill under curve
    if (progress > 0.5) {
      final fillPath = Path();
      for (int i = 0; i <= steps; i++) {
        final t = i / 100;
        final x = 20 + t * (w - 40);
        final nx = (x - cx) / (w / 2 - 20);
        final y = cy - (1 - nx * nx) * (cy - 20);
        if (i == 0) {
          fillPath.moveTo(x, y);
        } else {
          fillPath.lineTo(x, y);
        }
      }
      final lastX = 20 + (steps / 100) * (w - 40);
      fillPath.lineTo(lastX, cy);
      fillPath.lineTo(20, cy);
      fillPath.close();
      canvas.drawPath(fillPath, Paint()..color = color.withValues(alpha: 0.08));
    }
    // Vertex marker
    if (progress > 0.4) {
      canvas.drawCircle(Offset(cx, 20), 5, Paint()..color = color);
      _drawLabel(canvas, 'vertex', Offset(cx, 12), color);
    }
    // Axis labels
    if (progress > 0.7) {
      _drawLabel(canvas, 'x', Offset(w - 16, cy + 10), color);
      _drawLabel(canvas, 'y', Offset(cx + 8, 8), color);
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset pos, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_ParabolaPainter old) => old.progress != progress;
}

// ── Generic Value Visualizer ─────────────────────────────────────────────

class _GenericValueVisualizer extends StatefulWidget {
  final SimulationResult result;
  final Color color;
  final String description;
  const _GenericValueVisualizer({required this.result, required this.color, required this.description});
  @override
  State<_GenericValueVisualizer> createState() => _GenericValueVisualizerState();
}

class _GenericValueVisualizerState extends State<_GenericValueVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return _VisualizerCard(
      title: widget.result.resultLabel,
      description: widget.description,
      color: widget.color,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          return Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  (widget.result.resultValue * _anim.value).toStringAsFixed(2),
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: widget.color, fontFamily: 'Poppins'),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.result.resultUnit,
                  style: TextStyle(fontSize: 16, color: widget.color.withValues(alpha:0.8), fontFamily: 'Poppins'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Shared card wrapper ───────────────────────────────────────────────────

class _VisualizerCard extends StatelessWidget {
  final String title;
  final String description;
  final Color color;
  final Widget child;

  const _VisualizerCard({required this.title, required this.description, required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : color.withValues(alpha: 0.05),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Gradient header bar
          Container(
            height: 5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.5)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: color,
                letterSpacing: 0.2,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
            child: Text(
              description,
              style: TextStyle(
                fontSize: 11,
                height: 1.4,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.55)
                    : Colors.black.withValues(alpha: 0.55),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}
