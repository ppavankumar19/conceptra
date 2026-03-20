import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants.dart';
import '../providers/modules_provider.dart';
import '../widgets/module_card.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';

class ModuleListScreen extends ConsumerStatefulWidget {
  const ModuleListScreen({super.key});

  @override
  ConsumerState<ModuleListScreen> createState() => _ModuleListScreenState();
}

class _ModuleListScreenState extends ConsumerState<ModuleListScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      final state = ref.read(modulesProvider);
      if (!state.isLoading && state.hasMore) {
        ref.read(modulesProvider.notifier).fetchModules();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final modulesState = ref.watch(modulesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          // Compact branded header
          _ModuleListHeader(isOffline: modulesState.isOffline),
          // Search + filters
          _FiltersSection(modulesState: modulesState, l10n: l10n),
          // Content
          Expanded(
            child: _buildContent(context, l10n, modulesState, colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    ModulesState modulesState,
    ColorScheme colorScheme,
  ) {
    if (modulesState.isLoading && modulesState.modules.isEmpty) {
      return _buildShimmer(context);
    }

    if (modulesState.error != null && modulesState.modules.isEmpty) {
      return AppErrorWidget(
        message: modulesState.error,
        onRetry: () => ref.read(modulesProvider.notifier).refresh(),
      );
    }

    final filtered = modulesState.filteredModules;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56,
              color: colorScheme.onSurface.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noModulesFound,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.noModulesFoundSubtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(modulesProvider.notifier).refresh(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gridConfig = _responsiveGrid(constraints.maxWidth);

          return GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridConfig.columns,
              childAspectRatio: gridConfig.aspectRatio,
              crossAxisSpacing: gridConfig.spacing,
              mainAxisSpacing: gridConfig.spacing,
            ),
            itemCount: filtered.length + (modulesState.isLoading ? gridConfig.columns : 0),
            itemBuilder: (context, index) {
              if (index >= filtered.length) {
                return _ShimmerCard();
              }
              return ModuleCard(
                module: filtered[index],
                animationIndex: index,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gridConfig = _responsiveGrid(constraints.maxWidth);
        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gridConfig.columns,
            childAspectRatio: gridConfig.aspectRatio,
            crossAxisSpacing: gridConfig.spacing,
            mainAxisSpacing: gridConfig.spacing,
          ),
          itemCount: 12,
          itemBuilder: (_, __) => _ShimmerCard(),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Responsive grid configuration
// ---------------------------------------------------------------------------

class _GridConfig {
  final int columns;
  final double aspectRatio;
  final double spacing;

  const _GridConfig({
    required this.columns,
    required this.aspectRatio,
    required this.spacing,
  });
}

_GridConfig _responsiveGrid(double width) {
  if (width < 500) {
    return const _GridConfig(columns: 2, aspectRatio: 0.72, spacing: 12);
  } else if (width < 800) {
    return const _GridConfig(columns: 3, aspectRatio: 0.74, spacing: 14);
  } else if (width < 1100) {
    return const _GridConfig(columns: 4, aspectRatio: 0.76, spacing: 16);
  } else {
    return const _GridConfig(columns: 5, aspectRatio: 0.78, spacing: 16);
  }
}

// ---------------------------------------------------------------------------
// Compact filters section
// ---------------------------------------------------------------------------

class _FiltersSection extends ConsumerWidget {
  final ModulesState modulesState;
  final AppLocalizations l10n;

  const _FiltersSection({required this.modulesState, required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: SizedBox(
              height: 44,
              child: TextField(
                decoration: InputDecoration(
                  hintText: l10n.searchModules,
                  hintStyle: const TextStyle(fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: modulesState.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () =>
                              ref.read(modulesProvider.notifier).setSearchQuery(''),
                        )
                      : null,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                ),
                style: const TextStyle(fontSize: 14),
                onChanged: (value) =>
                    ref.read(modulesProvider.notifier).setSearchQuery(value),
              ),
            ),
          ),
          // Subject + difficulty chips in one compact scrollable row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _SmallChip(
                    label: l10n.filterAll,
                    selected: modulesState.subjectFilter == null &&
                        modulesState.difficultyFilter == null,
                    onTap: () {
                      ref.read(modulesProvider.notifier).setSubjectFilter(null);
                      ref.read(modulesProvider.notifier).setDifficultyFilter(null);
                    },
                  ),
                  const SizedBox(width: 6),
                  _SmallChip(
                    label: 'Physics',
                    color: AppConstants.physicsColor,
                    selected: modulesState.subjectFilter == AppConstants.subjectPhysics,
                    onTap: () => ref
                        .read(modulesProvider.notifier)
                        .setSubjectFilter(AppConstants.subjectPhysics),
                  ),
                  const SizedBox(width: 6),
                  _SmallChip(
                    label: 'Math',
                    color: AppConstants.mathematicsColor,
                    selected: modulesState.subjectFilter == AppConstants.subjectMathematics,
                    onTap: () => ref
                        .read(modulesProvider.notifier)
                        .setSubjectFilter(AppConstants.subjectMathematics),
                  ),
                  const SizedBox(width: 6),
                  _SmallChip(
                    label: 'Chemistry',
                    color: AppConstants.chemistryColor,
                    selected: modulesState.subjectFilter == AppConstants.subjectChemistry,
                    onTap: () => ref
                        .read(modulesProvider.notifier)
                        .setSubjectFilter(AppConstants.subjectChemistry),
                  ),
                  const SizedBox(width: 12),
                  Container(
                      width: 1,
                      height: 20,
                      color: Colors.grey.withValues(alpha: 0.3)),
                  const SizedBox(width: 12),
                  _SmallChip(
                    label: l10n.filterBasic,
                    color: AppConstants.difficultyColor(AppConstants.difficultyBasic),
                    selected: modulesState.difficultyFilter == AppConstants.difficultyBasic,
                    onTap: () => ref
                        .read(modulesProvider.notifier)
                        .setDifficultyFilter(AppConstants.difficultyBasic),
                  ),
                  const SizedBox(width: 6),
                  _SmallChip(
                    label: l10n.filterIntermediate,
                    color: AppConstants.difficultyColor(AppConstants.difficultyIntermediate),
                    selected: modulesState.difficultyFilter == AppConstants.difficultyIntermediate,
                    onTap: () => ref
                        .read(modulesProvider.notifier)
                        .setDifficultyFilter(AppConstants.difficultyIntermediate),
                  ),
                  const SizedBox(width: 6),
                  _SmallChip(
                    label: l10n.filterAdvanced,
                    color: AppConstants.difficultyColor(AppConstants.difficultyAdvanced),
                    selected: modulesState.difficultyFilter == AppConstants.difficultyAdvanced,
                    onTap: () => ref
                        .read(modulesProvider.notifier)
                        .setDifficultyFilter(AppConstants.difficultyAdvanced),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallChip extends StatefulWidget {
  final String label;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  const _SmallChip({
    required this.label,
    this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_SmallChip> createState() => _SmallChipState();
}

class _SmallChipState extends State<_SmallChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? Theme.of(context).colorScheme.primary;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: widget.selected
                ? effectiveColor
                : _isHovered
                    ? effectiveColor.withValues(alpha: 0.15)
                    : effectiveColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.selected
                  ? effectiveColor
                  : _isHovered
                      ? effectiveColor.withValues(alpha: 0.5)
                      : effectiveColor.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
              color: widget.selected ? Colors.white : effectiveColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE0E0E0),
      highlightColor: isDark ? const Color(0xFF3C3C3C) : const Color(0xFFF5F5F5),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 56, color: Colors.white),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        height: 14,
                        width: 80,
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 8)),
                    Container(
                        height: 14,
                        width: double.infinity,
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 4)),
                    Container(
                        height: 12,
                        width: 60,
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 8)),
                    const Spacer(),
                    Container(height: 32, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Branded gradient header
// ---------------------------------------------------------------------------

class _ModuleListHeader extends ConsumerWidget {
  final bool isOffline;
  const _ModuleListHeader({required this.isOffline});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.8),
            colorScheme.secondary.withValues(alpha: 0.7),
          ],
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, topPadding + 14, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAuthenticated
                      ? 'Explore Simulations'
                      : 'Learn Through Simulation',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAuthenticated
                      ? 'Pick a module and start exploring'
                      : 'Sign in to run simulations and track progress',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                      ),
                ),
              ],
            ),
          ),
          if (isOffline)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber[700],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off, size: 12, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Offline',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
