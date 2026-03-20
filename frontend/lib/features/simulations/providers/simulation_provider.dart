import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants.dart';
import '../../../shared/providers/connectivity_provider.dart';
import '../../../shared/services/api_client.dart';
import '../../../shared/services/offline_sync.dart';
import '../../modules/providers/modules_provider.dart';

// ---------------------------------------------------------------------------
// Result model
// ---------------------------------------------------------------------------

class SimulationResult {
  final double resultValue;
  final String resultUnit;
  final String resultLabel;
  final String formula;
  final String substitution;
  final String conclusion;
  final List<GraphPoint> graphData;
  final String sessionId;
  final String topic;

  const SimulationResult({
    required this.resultValue,
    required this.resultUnit,
    required this.resultLabel,
    required this.formula,
    required this.substitution,
    required this.conclusion,
    required this.graphData,
    required this.sessionId,
    required this.topic,
  });

  factory SimulationResult.fromJson(Map<String, dynamic> json) {
    final explanation = json['explanation'] as Map<String, dynamic>? ?? {};
    final graphRaw = json['graph_data'] as List<dynamic>? ?? [];
    return SimulationResult(
      resultValue: (json['result_value'] as num? ?? 0).toDouble(),
      resultUnit: json['result_unit'] as String? ?? '',
      resultLabel: json['result_label'] as String? ?? 'Result',
      formula: explanation['formula'] as String? ?? '',
      substitution: explanation['substitution'] as String? ?? '',
      conclusion: explanation['conclusion'] as String? ?? '',
      graphData: graphRaw
          .map((p) => GraphPoint.fromJson(p as Map<String, dynamic>))
          .toList(),
      sessionId: json['session_id'] as String? ?? '',
      topic: json['topic'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'result_value': resultValue,
        'result_unit': resultUnit,
        'result_label': resultLabel,
        'formula': formula,
        'substitution': substitution,
        'conclusion': conclusion,
        'graph_data': graphData.map((p) => p.toJson()).toList(),
        'session_id': sessionId,
        'topic': topic,
      };

  SimulationResult copyWith({
    double? resultValue,
    String? resultUnit,
    String? resultLabel,
    String? formula,
    String? substitution,
    String? conclusion,
    List<GraphPoint>? graphData,
    String? sessionId,
    String? topic,
  }) {
    return SimulationResult(
      resultValue: resultValue ?? this.resultValue,
      resultUnit: resultUnit ?? this.resultUnit,
      resultLabel: resultLabel ?? this.resultLabel,
      formula: formula ?? this.formula,
      substitution: substitution ?? this.substitution,
      conclusion: conclusion ?? this.conclusion,
      graphData: graphData ?? this.graphData,
      sessionId: sessionId ?? this.sessionId,
      topic: topic ?? this.topic,
    );
  }
}

class GraphPoint {
  final double x;
  final double y;

  const GraphPoint(this.x, this.y);

  factory GraphPoint.fromJson(Map<String, dynamic> json) => GraphPoint(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {'x': x, 'y': y};
}

// ---------------------------------------------------------------------------
// Simulation state
// ---------------------------------------------------------------------------

class SimulationState {
  final Map<String, double> parameters;
  final bool isLoading;
  final SimulationResult? result;
  final String? error;
  final bool isOfflineQueued;

  const SimulationState({
    this.parameters = const {},
    this.isLoading = false,
    this.result,
    this.error,
    this.isOfflineQueued = false,
  });

  SimulationState copyWith({
    Map<String, double>? parameters,
    bool? isLoading,
    SimulationResult? result,
    String? error,
    bool? isOfflineQueued,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return SimulationState(
      parameters: parameters ?? this.parameters,
      isLoading: isLoading ?? this.isLoading,
      result: clearResult ? null : result ?? this.result,
      error: clearError ? null : error ?? this.error,
      isOfflineQueued: isOfflineQueued ?? this.isOfflineQueued,
    );
  }
}

// ---------------------------------------------------------------------------
// StateNotifier
// ---------------------------------------------------------------------------

class SimulationNotifier extends StateNotifier<SimulationState> {
  final Dio _dio;
  final OfflineSyncService _offlineSync;
  final bool _isOnline;
  final Module? _module;
  // ignore: unused_field
  Box? _cacheBox;

  SimulationNotifier({
    required Dio dio,
    required OfflineSyncService offlineSync,
    required bool isOnline,
    Module? module,
  })  : _dio = dio,
        _offlineSync = offlineSync,
        _isOnline = isOnline,
        _module = module,
        super(const SimulationState()) {
    _initDefaults();
  }

  void _initDefaults() {
    final module = _module;
    if (module == null) return;
    final defaults = <String, double>{};
    for (final param in module.parameters) {
      defaults[param.name] = param.defaultValue;
    }
    state = state.copyWith(parameters: defaults);
  }

  void updateParameter(String name, double value) {
    final updated = Map<String, double>.from(state.parameters);
    updated[name] = value;
    state = state.copyWith(parameters: updated, clearError: true);
  }

  Future<void> runSimulation(String moduleId) async {
    state = state.copyWith(isLoading: true, clearError: true, clearResult: true);

    if (!_isOnline) {
      // Queue for offline sync
      final pending = PendingSimulation(
        id: const Uuid().v4(),
        moduleId: moduleId,
        parameters: Map.from(state.parameters),
        queuedAt: DateTime.now(),
      );
      await _offlineSync.queueSimulation(pending);
      state = state.copyWith(
        isLoading: false,
        isOfflineQueued: true,
      );
      return;
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/simulate',
        data: {
          'module_id': moduleId,
          'parameters': state.parameters,
        },
      );

      final apiData = response.data!['data'] as Map<String, dynamic>;
      final result = SimulationResult.fromJson(apiData);

      // Cache result
      final box = await Hive.openBox(AppConstants.sessionsBoxName);
      await box.put(result.sessionId, jsonEncode(result.toJson()));

      state = state.copyWith(
        isLoading: false,
        result: result,
        isOfflineQueued: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _friendlyError(e),
      );
    }
  }

  static String _friendlyError(Object e) {
    if (e is DioException) {
      // Our error interceptor re-wraps API exceptions into DioException.error
      // Check that first before falling through to the type-based switch.
      if (e.error is ApiException) return (e.error as ApiException).message;

      // If there's an HTTP response it reached the server — not a connectivity issue.
      final response = e.response;
      if (response != null) {
        final detail = response.data;
        if (detail is Map) {
          final msg = detail['error']?['message'] ??
              detail['detail']?['message'] ??
              detail['detail'];
          if (msg != null) return msg.toString();
        }
        return 'Server error (HTTP ${response.statusCode}).';
      }

      switch (e.type) {
        case DioExceptionType.connectionError:
          return 'Cannot reach the server. Make sure the backend is running at localhost:8000.';
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Request timed out. The server may be overloaded.';
        default:
          return 'Network error: ${e.message ?? e.type.name}';
      }
    }
    return e.toString();
  }

  void resetSimulation() {
    state = const SimulationState();
    _initDefaults();
  }
}

// ---------------------------------------------------------------------------
// Provider factory
// ---------------------------------------------------------------------------

final simulationProvider = StateNotifierProvider.family
    .autoDispose<SimulationNotifier, SimulationState, String>(
  (ref, moduleId) {
    final dio = ref.watch(apiClientProvider);
    final offlineSync = ref.watch(offlineSyncProvider);
    final isOnline = ref.watch(isOnlineProvider);
    final moduleAsync = ref.watch(moduleDetailProvider(moduleId));
    final module = moduleAsync.whenOrNull(data: (m) => m);

    return SimulationNotifier(
      dio: dio,
      offlineSync: offlineSync,
      isOnline: isOnline,
      module: module,
    );
  },
);
