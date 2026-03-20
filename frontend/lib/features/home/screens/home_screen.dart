import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/offline_banner.dart';
import '../../../shared/providers/theme_locale_provider.dart';
import '../../../generated/l10n/app_localizations.dart';

/// Breakpoint at which we switch from bottom nav to side drawer.
const double _kWideBreakpoint = 768;

/// Provider to share sidebar collapsed state.
final sidebarCollapsedProvider = StateProvider<bool>((ref) => false);

class HomeScreen extends ConsumerWidget {
  final Widget child;
  final String location;

  const HomeScreen({
    super.key,
    required this.child,
    required this.location,
  });

  int _currentIndex(String location) {
    if (location.startsWith('/home/history')) return 1;
    if (location.startsWith('/home/progress')) return 2;
    if (location.startsWith('/home/profile')) return 3;
    return 0;
  }

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home/modules');
      case 1:
        context.go('/home/history');
      case 2:
        context.go('/home/progress');
      case 3:
        context.go('/home/profile');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentIndex = _currentIndex(location);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _kWideBreakpoint;

        if (isWide) {
          return _WideLayout(
            currentIndex: currentIndex,
            isDark: isDark,
            colorScheme: colorScheme,
            l10n: l10n,
            onDestinationSelected: (i) =>
                _onDestinationSelected(context, i),
            child: child,
          );
        }

        // ── Narrow layout: AppBar + Bottom nav ────────────────────
        return Scaffold(
          appBar: AppBar(
            title: const Text('Conceptra'),
            leading: Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded),
                tooltip: 'Menu',
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            actions: [
              _ThemeToggleButton(isDark: isDark),
            ],
          ),
          drawer: _AppDrawer(
            currentIndex: currentIndex,
            isDark: isDark,
            colorScheme: colorScheme,
            l10n: l10n,
            onDestinationSelected: (i) {
              Navigator.of(context).pop(); // close drawer
              _onDestinationSelected(context, i);
            },
          ),
          body: Column(
            children: [
              const OfflineBanner(),
              Expanded(child: child),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (i) =>
                _onDestinationSelected(context, i),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: const Icon(Icons.history_outlined),
                selectedIcon: const Icon(Icons.history_rounded),
                label: l10n.historyTab,
              ),
              NavigationDestination(
                icon: const Icon(Icons.bar_chart_outlined),
                selectedIcon: const Icon(Icons.bar_chart_rounded),
                label: l10n.progressTab,
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline_rounded),
                selectedIcon: const Icon(Icons.person_rounded),
                label: l10n.profileTab,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wide layout with collapsible sidebar
// ─────────────────────────────────────────────────────────────────────────────

class _WideLayout extends ConsumerWidget {
  final int currentIndex;
  final bool isDark;
  final ColorScheme colorScheme;
  final AppLocalizations l10n;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  const _WideLayout({
    required this.currentIndex,
    required this.isDark,
    required this.colorScheme,
    required this.l10n,
    required this.onDestinationSelected,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCollapsed = ref.watch(sidebarCollapsedProvider);

    return Scaffold(
      body: Row(
        children: [
          // ── Collapsible sidebar ──────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            width: isCollapsed ? 72 : 240,
            child: _SidebarContent(
              currentIndex: currentIndex,
              isCollapsed: isCollapsed,
              isDark: isDark,
              colorScheme: colorScheme,
              l10n: l10n,
              onDestinationSelected: onDestinationSelected,
              onToggleCollapse: () =>
                  ref.read(sidebarCollapsedProvider.notifier).state =
                      !isCollapsed,
            ),
          ),
          // Divider
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: isDark
                ? const Color(0xFF2D2460)
                : const Color(0xFFE8E5F0),
          ),
          // ── Main content ─────────────────────────────────
          Expanded(
            child: Column(
              children: [
                const OfflineBanner(),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sidebar content (used in both wide and drawer)
// ─────────────────────────────────────────────────────────────────────────────

class _SidebarContent extends ConsumerWidget {
  final int currentIndex;
  final bool isCollapsed;
  final bool isDark;
  final ColorScheme colorScheme;
  final AppLocalizations l10n;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onToggleCollapse;

  const _SidebarContent({
    required this.currentIndex,
    required this.isCollapsed,
    required this.isDark,
    required this.colorScheme,
    required this.l10n,
    required this.onDestinationSelected,
    required this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sidebarBg = isDark
        ? const Color(0xFF120D24)
        : Colors.white;

    return Container(
      color: sidebarBg,
      child: Column(
        children: [
          // ── Brand header + hamburger ──────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              isCollapsed ? 16 : 20,
              28,
              isCollapsed ? 16 : 16,
              20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.85),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Hamburger toggle
                    InkWell(
                      onTap: onToggleCollapse,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isCollapsed
                              ? Icons.menu_rounded
                              : Icons.menu_open_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    if (!isCollapsed) ...[
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Conceptra',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                if (!isCollapsed) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Text(
                      'Learn by Simulation',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Nav items ──────────────────────────────────────────
          _SidebarNavItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home_rounded,
            label: 'Home',
            isSelected: currentIndex == 0,
            isCollapsed: isCollapsed,
            colorScheme: colorScheme,
            onTap: () => onDestinationSelected(0),
          ),
          _SidebarNavItem(
            icon: Icons.history_outlined,
            selectedIcon: Icons.history_rounded,
            label: l10n.historyTab,
            isSelected: currentIndex == 1,
            isCollapsed: isCollapsed,
            colorScheme: colorScheme,
            onTap: () => onDestinationSelected(1),
          ),
          _SidebarNavItem(
            icon: Icons.bar_chart_outlined,
            selectedIcon: Icons.bar_chart_rounded,
            label: l10n.progressTab,
            isSelected: currentIndex == 2,
            isCollapsed: isCollapsed,
            colorScheme: colorScheme,
            onTap: () => onDestinationSelected(2),
          ),
          _SidebarNavItem(
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
            label: l10n.profileTab,
            isSelected: currentIndex == 3,
            isCollapsed: isCollapsed,
            colorScheme: colorScheme,
            onTap: () => onDestinationSelected(3),
          ),

          const Spacer(),

          // ── Theme toggle ──────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 12 : 16,
              vertical: 8,
            ),
            child: _ThemeToggleButton(isDark: isDark, isCollapsed: isCollapsed),
          ),

          // ── Footer ───────────────────────────────────────────
          if (!isCollapsed)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 16, 20),
              child: Text(
                'v1.0 · Conceptra',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
            )
          else
            const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual sidebar nav item with hover
// ─────────────────────────────────────────────────────────────────────────────

class _SidebarNavItem extends StatefulWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final bool isCollapsed;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.isCollapsed,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isSelected || _isHovered;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isCollapsed ? 12 : 14,
        vertical: 2,
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: Tooltip(
          message: widget.isCollapsed ? widget.label : '',
          preferBelow: false,
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.symmetric(
                horizontal: widget.isCollapsed ? 0 : 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? widget.colorScheme.primary.withValues(alpha: 0.12)
                    : _isHovered
                        ? widget.colorScheme.primary.withValues(alpha: 0.06)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: widget.isSelected
                      ? widget.colorScheme.primary.withValues(alpha: 0.2)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: widget.isCollapsed
                  ? Center(
                      child: Icon(
                        widget.isSelected ? widget.selectedIcon : widget.icon,
                        size: 22,
                        color: isActive
                            ? widget.colorScheme.primary
                            : widget.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                      ),
                    )
                  : Row(
                      children: [
                        Icon(
                          widget.isSelected
                              ? widget.selectedIcon
                              : widget.icon,
                          size: 20,
                          color: isActive
                              ? widget.colorScheme.primary
                              : widget.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          widget.label,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: widget.isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isActive
                                ? widget.colorScheme.primary
                                : widget.colorScheme.onSurface
                                    .withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Drawer for narrow screens
// ─────────────────────────────────────────────────────────────────────────────

class _AppDrawer extends StatelessWidget {
  final int currentIndex;
  final bool isDark;
  final ColorScheme colorScheme;
  final AppLocalizations l10n;
  final ValueChanged<int> onDestinationSelected;

  const _AppDrawer({
    required this.currentIndex,
    required this.isDark,
    required this.colorScheme,
    required this.l10n,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: isDark ? const Color(0xFF120D24) : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Brand header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withValues(alpha: 0.85),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Conceptra',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Learn by Simulation',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Nav items
            _DrawerItem(
              icon: Icons.home_rounded,
              label: 'Home',
              isSelected: currentIndex == 0,
              colorScheme: colorScheme,
              onTap: () => onDestinationSelected(0),
            ),
            _DrawerItem(
              icon: Icons.history_rounded,
              label: l10n.historyTab,
              isSelected: currentIndex == 1,
              colorScheme: colorScheme,
              onTap: () => onDestinationSelected(1),
            ),
            _DrawerItem(
              icon: Icons.bar_chart_rounded,
              label: l10n.progressTab,
              isSelected: currentIndex == 2,
              colorScheme: colorScheme,
              onTap: () => onDestinationSelected(2),
            ),
            _DrawerItem(
              icon: Icons.person_rounded,
              label: l10n.profileTab,
              isSelected: currentIndex == 3,
              colorScheme: colorScheme,
              onTap: () => onDestinationSelected(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? colorScheme.primary
            : colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected
              ? colorScheme.primary
              : colorScheme.onSurface.withValues(alpha: 0.8),
        ),
      ),
      selected: isSelected,
      selectedTileColor: colorScheme.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      onTap: onTap,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Theme toggle button (sun / moon)
// ─────────────────────────────────────────────────────────────────────────────

class _ThemeToggleButton extends ConsumerWidget {
  final bool isDark;
  final bool isCollapsed;

  const _ThemeToggleButton({
    required this.isDark,
    this.isCollapsed = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isCollapsed) {
      return IconButton(
        onPressed: () =>
            ref.read(themeModeProvider.notifier).toggle(),
        icon: Icon(
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          size: 20,
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        tooltip: isDark ? 'Light mode' : 'Dark mode',
      );
    }

    return IconButton(
      onPressed: () =>
          ref.read(themeModeProvider.notifier).toggle(),
      icon: Icon(
        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
        size: 20,
        color: colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      tooltip: isDark ? 'Light mode' : 'Dark mode',
    );
  }
}
