import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/modules/screens/module_list_screen.dart';
import '../features/modules/screens/module_detail_screen.dart';
import '../features/simulations/screens/simulation_screen.dart';
import '../features/history/screens/history_screen.dart';
import '../features/progress/screens/progress_screen.dart';
import '../features/profile/screens/profile_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ValueNotifier<bool>(false);

  ref.listen<AsyncValue<AuthState>>(authStateProvider, (previous, next) {
    authNotifier.value = next.whenOrNull(data: (s) => s.isAuthenticated) ?? false;
  });

  ref.onDispose(() => authNotifier.dispose());

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home/modules',
    debugLogDiagnostics: false,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authAsync = ref.read(authStateProvider);
      final isLoading = authAsync.isLoading;
      if (isLoading) return null;

      final isAuthenticated =
          authAsync.whenOrNull(data: (s) => s.isAuthenticated) ?? false;

      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      // Module list is public — browsable without login
      final isPublicRoute = state.matchedLocation == '/home/modules';

      // Handle OAuth callback — redirect root path or any unknown path
      if (state.matchedLocation == '/' ||
          state.matchedLocation.isEmpty ||
          state.uri.toString().contains('access_token') ||
          state.uri.toString().contains('refresh_token')) {
        return '/home/modules';
      }

      if (!isAuthenticated && !isAuthRoute && !isPublicRoute) {
        return '/login';
      }
      if (isAuthenticated && isAuthRoute) {
        return '/home/modules';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: RegisterScreen(),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return HomeScreen(location: state.matchedLocation, child: child);
        },
        routes: [
          GoRoute(
            path: '/home/modules',
            name: 'modules',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ModuleListScreen(),
            ),
          ),
          GoRoute(
            path: '/home/modules/:moduleId',
            name: 'moduleDetail',
            pageBuilder: (context, state) {
              final moduleId = state.pathParameters['moduleId']!;
              return MaterialPage(
                child: ModuleDetailScreen(moduleId: moduleId),
              );
            },
          ),
          GoRoute(
            path: '/home/simulate/:moduleId',
            name: 'simulate',
            pageBuilder: (context, state) {
              final moduleId = state.pathParameters['moduleId']!;
              return MaterialPage(
                child: SimulationScreen(moduleId: moduleId),
              );
            },
          ),
          GoRoute(
            path: '/home/history',
            name: 'history',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HistoryScreen(),
            ),
          ),
          GoRoute(
            path: '/home/progress',
            name: 'progress',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProgressScreen(),
            ),
          ),
          GoRoute(
            path: '/home/profile',
            name: 'profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),
    ],
    // Instead of showing "Page not found", redirect to home.
    // This handles OAuth callbacks with hash fragments and any unknown routes.
    onException: (context, state, router) {
      router.go('/home/modules');
    },
  );
});
