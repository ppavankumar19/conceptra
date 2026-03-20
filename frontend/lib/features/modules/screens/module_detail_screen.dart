import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../providers/modules_provider.dart';
import '../widgets/module_lessons.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../generated/l10n/app_localizations.dart';

class ModuleDetailScreen extends ConsumerWidget {
  final String moduleId;

  const ModuleDetailScreen({super.key, required this.moduleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final moduleAsync = ref.watch(moduleDetailProvider(moduleId));

    return moduleAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.moduleDetailTitle)),
        body: AppLoadingWidget(message: l10n.loadingModules),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.moduleDetailTitle)),
        body: AppErrorWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(moduleDetailProvider(moduleId)),
        ),
      ),
      data: (module) => _ModuleDetailContent(module: module),
    );
  }
}

class _ModuleDetailContent extends ConsumerWidget {
  final Module module;

  const _ModuleDetailContent({required this.module});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final subjectColor = AppConstants.subjectColor(module.subject);
    final subjectColorLight = AppConstants.subjectColorLight(module.subject);
    final colorScheme = Theme.of(context).colorScheme;
    final modulesState = ref.watch(modulesProvider);

    // Modules from the same subject (excluding current)
    final sameSubjectModules = modulesState.modules
        .where((m) => m.subject == module.subject && m.id != module.id)
        .toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Collapsible header ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: subjectColor,
            foregroundColor: Colors.white,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.home_rounded),
              tooltip: 'Home',
              onPressed: () => context.go('/home/modules'),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Back to Modules',
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home/modules');
                  }
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    module.subject.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Hero(
                    tag: 'module_title_${module.id}',
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        module.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          subjectColor,
                          subjectColor.withValues(alpha: 0.75),
                          subjectColor.withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                  ),
                  // Decorative large icon
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Icon(
                      _subjectIcon(module.subject),
                      size: 150,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),

                ],
              ),
            ),
          ),

          // ── Subject nav bar ─────────────────────────────────────────────
          if (sameSubjectModules.isNotEmpty)
            SliverToBoxAdapter(
              child: _SubjectNavBar(
                modules: sameSubjectModules,
                currentSubject: module.subject,
                subjectColor: subjectColor,
              ),
            ),

          // ── Main content ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badges row
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _InfoBadge(
                            label: module.subject.toUpperCase(),
                            bgColor: subjectColorLight,
                            textColor: subjectColor,
                          ),
                          _InfoBadge(
                            label: AppConstants.difficultyLabel(module.difficultyLevel),
                            bgColor: AppConstants.difficultyColor(module.difficultyLevel)
                                .withValues(alpha: 0.12),
                            textColor: AppConstants.difficultyColor(module.difficultyLevel),
                          ),
                          _InfoBadge(
                            label: l10n.classRange(module.gradeMin, module.gradeMax),
                            bgColor: colorScheme.surfaceContainerHighest,
                            textColor: colorScheme.onSurface.withValues(alpha: 0.7),
                            icon: Icons.school_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Description
                      Text(
                        module.description,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.6,
                              color: colorScheme.onSurface.withValues(alpha: 0.8),
                            ),
                      ),
                      const SizedBox(height: 24),

                      // ── Lesson section ─────────────────────────────────────
                      if (module.topic.isNotEmpty)
                        ModuleLessonWidget(
                          topic: module.topic,
                          color: subjectColor,
                        ),

                      // ── Parameters ─────────────────────────────────────────
                      if (module.parameters.isNotEmpty) ...[
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                color: subjectColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              l10n.parametersSection,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: subjectColor,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              children: module.parameters
                                  .map((param) => _ParameterRow(param: param))
                                  .toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: ElevatedButton.icon(
            onPressed: () => context.go('/home/simulate/${module.id}'),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(l10n.startSimulation),
            style: ElevatedButton.styleFrom(
              backgroundColor: subjectColor,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Subject nav bar ─────────────────────────────────────────────────────────

class _SubjectNavBar extends StatefulWidget {
  final List<Module> modules;
  final String currentSubject;
  final Color subjectColor;

  const _SubjectNavBar({
    required this.modules,
    required this.currentSubject,
    required this.subjectColor,
  });

  @override
  State<_SubjectNavBar> createState() => _SubjectNavBarState();
}

class _SubjectNavBarState extends State<_SubjectNavBar> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Text(
                    'More ${widget.currentSubject[0].toUpperCase()}${widget.currentSubject.substring(1)} Modules',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 20,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Collapsible content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: widget.modules.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final m = widget.modules[index];
                  return _SubjectNavChip(
                    module: m,
                    color: widget.subjectColor,
                  );
                },
              ),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
          if (_isExpanded) const SizedBox(height: 8),
          Divider(height: 1, color: colorScheme.outlineVariant),
        ],
      ),
    );
  }
}

class _SubjectNavChip extends StatefulWidget {
  final Module module;
  final Color color;

  const _SubjectNavChip({required this.module, required this.color});

  @override
  State<_SubjectNavChip> createState() => _SubjectNavChipState();
}

class _SubjectNavChipState extends State<_SubjectNavChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/home/modules/${widget.module.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(maxWidth: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          transform: Matrix4.identity()
            ..translate(0.0, _isHovered ? -2.0 : 0.0),
          decoration: BoxDecoration(
            color: _isHovered
                ? widget.color.withValues(alpha: 0.15)
                : widget.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? widget.color.withValues(alpha: 0.4)
                  : widget.color.withValues(alpha: 0.2),
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.module.title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.color,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                AppConstants.difficultyLabel(widget.module.difficultyLevel),
                style: TextStyle(
                  fontSize: 10,
                  color: widget.color.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Info badge ───────────────────────────────────────────────────────────────

class _InfoBadge extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;
  final IconData? icon;

  const _InfoBadge({
    required this.label,
    required this.bgColor,
    required this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Parameter row ────────────────────────────────────────────────────────────

class _ParameterRow extends StatelessWidget {
  final ModuleParameter param;

  const _ParameterRow({required this.param});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  param.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  'Unit: ${param.unit.isEmpty ? "—" : param.unit}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${param.min.toStringAsFixed(param.step < 1 ? 1 : 0)} – ${param.max.toStringAsFixed(param.step < 1 ? 1 : 0)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
              ),
              Text(
                'Default: ${param.defaultValue.toStringAsFixed(param.step < 1 ? 1 : 0)}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
