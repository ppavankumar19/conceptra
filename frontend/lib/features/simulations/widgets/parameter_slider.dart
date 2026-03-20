import 'package:flutter/material.dart';

import '../../modules/providers/modules_provider.dart';

class ParameterSlider extends StatelessWidget {
  final ModuleParameter parameter;
  final double value;
  final ValueChanged<double> onChanged;

  const ParameterSlider({
    super.key,
    required this.parameter,
    required this.value,
    required this.onChanged,
  });

  String _formatValue(double v) {
    // Use scientific notation for very large or very small values
    if (v.abs() >= 1e9 || (v.abs() < 0.01 && v != 0)) {
      return v.toStringAsExponential(2);
    }
    if (parameter.step < 1) {
      return v.toStringAsFixed(2);
    }
    return v.toStringAsFixed(0);
  }

  int _divisions() {
    final range = parameter.max - parameter.min;
    if (parameter.step <= 0 || range <= 0) return 200;
    final raw = (range / parameter.step).round();
    // Cap at 500 to prevent integer overflow for wide-range parameters
    // (e.g. Gravitational Force mass1: min=1, max=1e30, step=0.1)
    return raw.clamp(10, 500);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayValue = '${_formatValue(value)} ${parameter.unit}';

    return Semantics(
      label:
          '${parameter.label}: $displayValue, minimum ${parameter.min}, maximum ${parameter.max}',
      slider: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Label
              Flexible(
                child: Text(
                  parameter.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              // Value chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  displayValue,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          // Unit description
          Text(
            'Range: ${_formatValue(parameter.min)} – ${_formatValue(parameter.max)} ${parameter.unit}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                  fontSize: 10,
                ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                _formatValue(parameter.min),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
              ),
              Expanded(
                child: ExcludeSemantics(
                  child: Slider(
                    value: value.clamp(parameter.min, parameter.max),
                    min: parameter.min,
                    max: parameter.max,
                    divisions: _divisions(),
                    onChanged: onChanged,
                  ),
                ),
              ),
              Text(
                _formatValue(parameter.max),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
