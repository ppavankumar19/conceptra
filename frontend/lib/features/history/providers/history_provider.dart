import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../shared/services/api_client.dart';
import '../../auth/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// History item model
// ---------------------------------------------------------------------------

class HistorySession {
  final String id;
  final String moduleId;
  final String moduleName;
  final String subject;
  final double resultValue;
  final String resultUnit;
  final String resultLabel;
  final DateTime createdAt;

  const HistorySession({
    required this.id,
    required this.moduleId,
    required this.moduleName,
    required this.subject,
    required this.resultValue,
    required this.resultUnit,
    required this.resultLabel,
    required this.createdAt,
  });

  factory HistorySession.fromJson(Map<String, dynamic> json) => HistorySession(
        id: json['id'] as String,
        moduleId: json['module_id'] as String? ?? '',
        moduleName: json['module_name'] as String? ??
            json['module']?['title'] as String? ?? 'Unknown Module',
        subject: json['subject'] as String? ??
            json['module']?['subject'] as String? ?? 'physics',
        resultValue: (json['result_value'] as num?)?.toDouble() ?? 0.0,
        resultUnit: json['result_unit'] as String? ?? '',
        resultLabel: json['result_label'] as String? ?? 'Result',
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class HistoryState {
  final List<HistorySession> sessions;
  final bool isLoading;
  final String? error;
  final int page;
  final bool hasMore;

  const HistoryState({
    this.sessions = const [],
    this.isLoading = false,
    this.error,
    this.page = 1,
    this.hasMore = true,
  });

  HistoryState copyWith({
    List<HistorySession>? sessions,
    bool? isLoading,
    String? error,
    int? page,
    bool? hasMore,
    bool clearError = false,
  }) {
    return HistoryState(
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class HistoryNotifier extends StateNotifier<HistoryState> {
  final Dio _dio;
  final bool _isAuthenticated;

  HistoryNotifier(this._dio, this._isAuthenticated) : super(const HistoryState()) {
    if (_isAuthenticated) fetchHistory();
  }

  Future<void> fetchHistory({bool refresh = false}) async {
    if (!_isAuthenticated || state.isLoading) return;
    final page = refresh ? 1 : state.page;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _dio.get(
        '/simulate/history',
        queryParameters: {
          'page': page,
          'page_size': AppConstants.defaultPageSize,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final rawSessions =
          data['sessions'] as List<dynamic>? ??
          data['items'] as List<dynamic>? ??
          [];
      final sessions = rawSessions
          .map((s) =>
              HistorySession.fromJson(s as Map<String, dynamic>))
          .toList();

      final allSessions =
          refresh ? sessions : [...state.sessions, ...sessions];
      state = state.copyWith(
        sessions: allSessions,
        isLoading: false,
        page: page + 1,
        hasMore: sessions.length >= AppConstants.defaultPageSize,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() => fetchHistory(refresh: true);
}

final historyProvider =
    StateNotifierProvider.autoDispose<HistoryNotifier, HistoryState>((ref) {
  final dio = ref.watch(apiClientProvider);
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  return HistoryNotifier(dio, isAuthenticated);
});
