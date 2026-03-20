import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../providers/simulation_provider.dart';

class SimulationGraph extends StatefulWidget {
  final SimulationResult result;
  final String xLabel;
  final String yLabel;
  final Color lineColor;

  const SimulationGraph({
    super.key,
    required this.result,
    this.xLabel = 'Time (s)',
    this.yLabel = 'Distance (m)',
    required this.lineColor,
  });

  @override
  State<SimulationGraph> createState() => _SimulationGraphState();
}

class _SimulationGraphState extends State<SimulationGraph>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  List<FlSpot> _buildSpots() {
    if (widget.result.graphData.isEmpty) {
      final v = widget.result.resultValue;
      return [
        const FlSpot(0, 0),
        FlSpot(1, v),
        FlSpot(2, v * 2),
        FlSpot(3, v * 3),
        FlSpot(4, v * 4),
        FlSpot(5, v * 5),
      ];
    }
    return widget.result.graphData.map((p) => FlSpot(p.x, p.y)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final spots = _buildSpots();

    if (spots.isEmpty) return const SizedBox.shrink();

    final minX = spots.map((s) => s.x).reduce((a, b) => a < b ? a : b);
    final maxX = spots.map((s) => s.x).reduce((a, b) => a > b ? a : b);
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final yRange = (maxY - minY).abs();
    final yPadding = yRange == 0 ? 1.0 : yRange * 0.15;

    final accent = widget.lineColor;
    final accentLight = accent.withValues(alpha: 0.08);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final cutoff = (_animation.value * spots.length).ceil();
        final visibleSpots = spots.take(cutoff.clamp(1, spots.length)).toList();

        return Container(
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.03)
                : accentLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accent.withValues(alpha: 0.18),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Coloured top strip
              Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    accent,
                    accent.withValues(alpha: 0.5),
                  ]),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 16, 16),
                child: SizedBox(
                  height: 280,
                  child: LineChart(
                    LineChartData(
                      minX: minX,
                      maxX: maxX,
                      minY: minY - yPadding,
                      maxY: maxY + yPadding,
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => accent.withValues(alpha: 0.9),
                          tooltipRoundedRadius: 8,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((s) {
                              return LineTooltipItem(
                                '(${s.x.toStringAsFixed(1)}, ${s.y.toStringAsFixed(2)})',
                                const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            }).toList();
                          },
                        ),
                        handleBuiltInTouches: true,
                        getTouchedSpotIndicator: (barData, spotIndexes) {
                          return spotIndexes.map((index) {
                            return TouchedSpotIndicatorData(
                              FlLine(color: accent, strokeWidth: 2, dashArray: [4, 4]),
                              FlDotData(
                                getDotPainter: (spot, percent, bar, idx) =>
                                    FlDotCirclePainter(
                                  radius: 6,
                                  color: Colors.white,
                                  strokeWidth: 3,
                                  strokeColor: accent,
                                ),
                              ),
                            );
                          }).toList();
                        },
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: yRange > 0 ? yRange / 5 : 1,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: accent.withValues(alpha: 0.12),
                          strokeWidth: 1,
                        ),
                        getDrawingVerticalLine: (value) => FlLine(
                          color: accent.withValues(alpha: 0.08),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border(
                          bottom: BorderSide(color: accent.withValues(alpha: 0.3), width: 1.5),
                          left: BorderSide(color: accent.withValues(alpha: 0.3), width: 1.5),
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          axisNameWidget: Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              widget.yLabel,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: accent.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 44,
                            getTitlesWidget: (value, meta) => Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text(
                                value.toStringAsFixed(0),
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          axisNameWidget: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              widget.xLabel,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: accent.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) => Text(
                              value.toStringAsFixed(0),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: visibleSpots,
                          isCurved: true,
                          curveSmoothness: 0.35,
                          color: accent,
                          barWidth: 3.5,
                          isStrokeCapRound: true,
                          shadow: Shadow(
                            color: accent.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                          dotData: FlDotData(
                            show: visibleSpots.length <= 15,
                            getDotPainter: (spot, percent, bar, index) =>
                                FlDotCirclePainter(
                              radius: 4,
                              color: accent,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                accent.withValues(alpha: 0.28),
                                accent.withValues(alpha: 0.04),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
