import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../providers/modules_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../generated/l10n/app_localizations.dart';

// Subject → icon mapping
IconData _subjectIcon(String subject) {
  switch (subject.toLowerCase()) {
    case 'physics':
      return Icons.bolt_rounded;
    case 'mathematics':
      return Icons.functions_rounded;
    case 'chemistry':
      return Icons.science_rounded;
    default:
      return Icons.school_rounded;
  }
}

class ModuleCard extends ConsumerStatefulWidget {
  final Module module;
  final int animationIndex;

  const ModuleCard({
    super.key,
    required this.module,
    this.animationIndex = 0,
  });

  @override
  ConsumerState<ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends ConsumerState<ModuleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnim;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 160),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  void _openModule(BuildContext context, bool isAuthenticated) {
    if (isAuthenticated) {
      context.go('/home/modules/${widget.module.id}');
    } else {
      context.go('/login');
    }
  }

  void _startModule(BuildContext context, bool isAuthenticated) {
    if (isAuthenticated) {
      context.go('/home/simulate/${widget.module.id}');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final subjectColor = AppConstants.subjectColor(widget.module.subject);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + widget.animationIndex * 40),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 16 * (1 - value)),
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        );
      },
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTapDown: (_) => _pressCtrl.forward(),
            onTapUp: (_) {
              _pressCtrl.reverse();
              _openModule(context, isAuthenticated);
            },
            onTapCancel: () => _pressCtrl.reverse(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              transform: Matrix4.identity()
                ..translate(0.0, _isHovered ? -4.0 : 0.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _isHovered
                        ? subjectColor.withValues(alpha: isDark ? 0.3 : 0.2)
                        : (isDark
                            ? Colors.black.withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.06)),
                    blurRadius: _isHovered ? 20 : 8,
                    offset: Offset(0, _isHovered ? 8 : 2),
                    spreadRadius: _isHovered ? 1 : 0,
                  ),
                ],
              ),
              child: Card(
                clipBehavior: Clip.antiAlias,
                margin: EdgeInsets.zero,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: _isHovered
                        ? subjectColor.withValues(alpha: 0.3)
                        : Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF2D2460)
                            : const Color(0xFFE8E5F0),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Gradient header ─────────────────────────────
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            subjectColor,
                            subjectColor.withValues(alpha: 0.75),
                          ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Faded background icon
                          Positioned(
                            right: -6,
                            bottom: -6,
                            child: Icon(
                              _subjectIcon(widget.module.subject),
                              size: 52,
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          // Top-right: difficulty badge
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                AppConstants.difficultyLabel(
                                    widget.module.difficultyLevel),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                          // Bottom-left: subject label
                          Positioned(
                            left: 10,
                            bottom: 8,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _subjectIcon(widget.module.subject),
                                  size: 14,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.module.subject.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Body ───────────────────────────────────────
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Expanded(
                              child: Text(
                                widget.module.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      height: 1.25,
                                      fontSize: 14,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Grade range
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.school_outlined,
                                  size: 12,
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.4),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Class ${widget.module.gradeMin}–${widget.module.gradeMax}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Start button
                            SizedBox(
                              width: double.infinity,
                              height: 32,
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _startModule(context, isAuthenticated),
                                icon: Icon(
                                  isAuthenticated
                                      ? Icons.play_arrow_rounded
                                      : Icons.lock_outline_rounded,
                                  size: 14,
                                ),
                                label: Text(
                                  isAuthenticated
                                      ? l10n.startButton
                                      : 'Sign In',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: subjectColor,
                                  foregroundColor: Colors.white,
                                  minimumSize: Size.zero,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
