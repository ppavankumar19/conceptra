import 'package:flutter/material.dart';

import '../providers/simulation_provider.dart';
import '../../../generated/l10n/app_localizations.dart';

class ResultCard extends StatelessWidget {
  final SimulationResult result;
  final Color subjectColor;

  const ResultCard({
    super.key,
    required this.result,
    required this.subjectColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: '${l10n.resultSection}: ${result.resultValue} ${result.resultUnit}',
      liveRegion: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, color: subjectColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.resultSection,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                result.resultLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
              ),
              const SizedBox(height: 16),
              // Animated number reveal
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: result.resultValue),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Text(
                    value.toStringAsFixed(
                        result.resultValue % 1 == 0 ? 0 : 2),
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: subjectColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1,
                        ),
                  );
                },
              ),
              if (result.resultUnit.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: subjectColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    result.resultUnit,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: subjectColor,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
