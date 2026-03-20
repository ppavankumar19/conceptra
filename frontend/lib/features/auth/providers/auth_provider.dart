import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/services/api_client.dart';

// Auth state model
class AuthState {
  final bool isAuthenticated;
  final User? currentUser;
  final Session? supabaseSession;

  const AuthState({
    required this.isAuthenticated,
    this.currentUser,
    this.supabaseSession,
  });

  const AuthState.unauthenticated()
      : isAuthenticated = false,
        currentUser = null,
        supabaseSession = null;

  AuthState.fromSession(Session session)
      : isAuthenticated = true,
        currentUser = session.user,
        supabaseSession = session;

  @override
  String toString() =>
      'AuthState(isAuthenticated: $isAuthenticated, user: ${currentUser?.email})';
}

// Provider that exposes the auth state as a stream from Supabase
final authStateProvider = StreamProvider<AuthState>((ref) {
  final supabase = Supabase.instance.client;

  return supabase.auth.onAuthStateChange.map((event) {
    final session = event.session;
    if (session != null) {
      return AuthState.fromSession(session);
    }
    return const AuthState.unauthenticated();
  });
});

// Convenience providers
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).whenOrNull(data: (s) => s.isAuthenticated) ?? false;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).whenOrNull(data: (s) => s.currentUser);
});

final currentSessionProvider = Provider<Session?>((ref) {
  return ref.watch(authStateProvider).whenOrNull(data: (s) => s.supabaseSession);
});

// Auth actions notifier
class AuthNotifier extends AsyncNotifier<void> {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<void> build() async {}

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    });
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb
            ? null  // Supabase uses Site URL automatically on web
            : 'io.supabase.conceptra://login-callback',
      );
    });
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
    required int classGrade,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'display_name': displayName,
          'class_grade': classGrade,
          'role': 'student',
        },
      );
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _client.auth.signOut();
    });
  }

  Future<void> updateProfile({
    String? displayName,
    int? classGrade,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final updates = <String, dynamic>{};
      if (displayName != null) updates['display_name'] = displayName;
      if (classGrade != null) updates['class_grade'] = classGrade;
      await _client.auth.updateUser(UserAttributes(data: updates));
    });
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, void>(AuthNotifier.new);

/// Automatically calls GET /auth/me when the user is authenticated.
/// This creates the UserProfile row in the backend on first login,
/// which is required before history, progress, and simulate endpoints work.
final profileSyncProvider = FutureProvider.autoDispose<void>((ref) async {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  if (!isAuthenticated) return;
  final dio = ref.watch(apiClientProvider);
  await dio.get<Map<String, dynamic>>('/auth/me');
});
