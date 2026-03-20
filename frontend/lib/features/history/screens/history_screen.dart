import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants.dart';
import '../providers/history_provider.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../generated/l10n/app_localizations.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
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
      final state = ref.read(historyProvider);
      if (!state.isLoading && state.hasMore) {
        ref.read(historyProvider.notifier).fetchHistory();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final historyState = ref.watch(historyProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.historyTitle),
        automaticallyImplyLeading: false,
      ),
      body: _buildBody(context, l10n, historyState, colorScheme),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    HistoryState state,
    ColorScheme colorScheme,
  ) {
    if (state.isLoading && state.sessions.isEmpty) {
      return AppLoadingWidget(message: l10n.loadingHistory);
    }

    if (state.error != null && state.sessions.isEmpty) {
      return AppErrorWidget(
        message: state.error,
        onRetry: () => ref.read(historyProvider.notifier).refresh(),
      );
    }

    if (state.sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_rounded,
              size: 72,
              color: colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.emptyHistory,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.emptyHistorySubtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.35),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(historyProvider.notifier).refresh(),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: state.sessions.length + (state.isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= state.sessions.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return _HistorySessionCard(session: state.sessions[index]);
            },
          ),
        ),
      ),
    );
  }
}

class _HistorySessionCard extends StatefulWidget {
  final HistorySession session;

  const _HistorySessionCard({required this.session});

  @override
  State<_HistorySessionCard> createState() => _HistorySessionCardState();
}

class _HistorySessionCardState extends State<_HistorySessionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final subjectColor = AppConstants.subjectColor(widget.session.subject);
    final subjectColorLight = AppConstants.subjectColorLight(widget.session.subject);
    final dateStr = DateFormat('MMM d, yyyy · HH:mm').format(widget.session.createdAt);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 14),
        transform: Matrix4.identity()
          ..translate(0.0, _isHovered ? -2.0 : 0.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: subjectColor.withValues(alpha: isDark ? 0.2 : 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Subject icon circle
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: subjectColorLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.session.subject == AppConstants.subjectPhysics
                        ? Icons.bolt_rounded
                        : widget.session.subject == AppConstants.subjectMathematics
                            ? Icons.functions_rounded
                            : Icons.science_rounded,
                    color: subjectColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.session.moduleName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l10n.resultValue(
                          widget.session.resultValue.toStringAsFixed(2),
                          widget.session.resultUnit,
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: subjectColor,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l10n.sessionDate(dateStr),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
