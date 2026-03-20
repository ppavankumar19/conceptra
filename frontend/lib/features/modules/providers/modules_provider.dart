import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants.dart';
import '../../../shared/services/api_client.dart';

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

class ModuleParameter {
  final String name;
  final String label;
  final String unit;
  final double min;
  final double max;
  final double step;
  final double defaultValue;

  const ModuleParameter({
    required this.name,
    required this.label,
    required this.unit,
    required this.min,
    required this.max,
    required this.step,
    required this.defaultValue,
  });

  factory ModuleParameter.fromJson(Map<String, dynamic> json) {
    // Backend sends min_value / max_value / default_value (Pydantic schema names).
    // Support both key styles for forward/backward compat.
    final minVal = (json['min_value'] ?? json['min'] as num?)?.toDouble() ?? 0.0;
    final maxVal = (json['max_value'] ?? json['max'] as num?)?.toDouble() ?? 100.0;
    final defVal = (json['default_value'] ?? json['default'] as num?)?.toDouble() ?? minVal;
    return ModuleParameter(
      name: json['name'] as String,
      label: json['label'] as String,
      unit: json['unit'] as String? ?? '',
      min: minVal,
      max: maxVal,
      step: (json['step'] as num?)?.toDouble() ?? 0.1,
      defaultValue: defVal,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'label': label,
        'unit': unit,
        'min': min,
        'max': max,
        'step': step,
        'default': defaultValue,
      };
}

class Module {
  final String id;
  final String title;
  final String description;
  final String subject;
  final String topic;
  final int difficultyLevel;
  final int gradeMin;
  final int gradeMax;
  final List<ModuleParameter> parameters;

  const Module({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.topic,
    required this.difficultyLevel,
    required this.gradeMin,
    required this.gradeMax,
    required this.parameters,
  });

  static int _parseDifficulty(Map<String, dynamic> json) {
    // Backend sends string: "beginner" | "intermediate" | "advanced"
    // Frontend uses int: 1 | 2 | 3
    final raw = json['difficulty'] as String? ?? json['difficulty_level']?.toString();
    switch (raw) {
      case 'intermediate': return 2;
      case 'advanced':     return 3;
      default:             return 1; // beginner or unknown
    }
  }

  factory Module.fromJson(Map<String, dynamic> json) => Module(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        subject: json['subject'] as String,
        topic: json['topic'] as String? ?? '',
        difficultyLevel: _parseDifficulty(json),
        gradeMin: (json['grade_min'] as num?)?.toInt() ?? 6,
        gradeMax: (json['grade_max'] as num?)?.toInt() ?? 12,
        parameters: (json['parameters'] as List<dynamic>?)
                ?.map((p) =>
                    ModuleParameter.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'subject': subject,
        'topic': topic,
        'difficulty_level': difficultyLevel,
        'grade_min': gradeMin,
        'grade_max': gradeMax,
        'parameters': parameters.map((p) => p.toJson()).toList(),
      };
}

// ---------------------------------------------------------------------------
// Modules list state & notifier
// ---------------------------------------------------------------------------

class ModulesState {
  final List<Module> modules;
  final bool isLoading;
  final String? error;
  final bool isOffline;
  final String searchQuery;
  final String? subjectFilter;
  final int? difficultyFilter;
  final int page;
  final bool hasMore;

  const ModulesState({
    this.modules = const [],
    this.isLoading = false,
    this.error,
    this.isOffline = false,
    this.searchQuery = '',
    this.subjectFilter,
    this.difficultyFilter,
    this.page = 1,
    this.hasMore = true,
  });

  ModulesState copyWith({
    List<Module>? modules,
    bool? isLoading,
    String? error,
    bool? isOffline,
    String? searchQuery,
    String? subjectFilter,
    int? difficultyFilter,
    int? page,
    bool? hasMore,
    bool clearError = false,
    bool clearSubjectFilter = false,
    bool clearDifficultyFilter = false,
  }) {
    return ModulesState(
      modules: modules ?? this.modules,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      isOffline: isOffline ?? this.isOffline,
      searchQuery: searchQuery ?? this.searchQuery,
      subjectFilter: clearSubjectFilter ? null : subjectFilter ?? this.subjectFilter,
      difficultyFilter: clearDifficultyFilter ? null : difficultyFilter ?? this.difficultyFilter,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  List<Module> get filteredModules {
    return modules.where((m) {
      final matchesSearch = searchQuery.isEmpty ||
          m.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          m.description.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesSubject =
          subjectFilter == null || m.subject == subjectFilter;
      final matchesDifficulty =
          difficultyFilter == null || m.difficultyLevel == difficultyFilter;
      return matchesSearch && matchesSubject && matchesDifficulty;
    }).toList();
  }
}

class ModulesNotifier extends StateNotifier<ModulesState> {
  final Dio _dio;
  Box? _box;

  ModulesNotifier(this._dio) : super(const ModulesState()) {
    _initHive();
  }

  Future<void> _initHive() async {
    _box = await Hive.openBox(AppConstants.modulesBoxName);
    await fetchModules();
  }

  Future<void> fetchModules({bool refresh = false}) async {
    if (state.isLoading) return;
    final page = refresh ? 1 : state.page;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/modules',
        queryParameters: {
          'page': page,
          'page_size': AppConstants.defaultPageSize,
        },
      );

      final data = response.data!;
      // Backend wraps paginated results in { "data": [...], "meta": {...} }
      final rawModules = (data['data'] as List<dynamic>?
          ?? data['modules'] as List<dynamic>?
          ?? data['items'] as List<dynamic>?
          ?? []);
      final modules = rawModules
          .map((m) => Module.fromJson(m as Map<String, dynamic>))
          .toList();

      // Cache to Hive
      await _cacheModules(modules);

      final allModules = refresh ? modules : [...state.modules, ...modules];
      state = state.copyWith(
        modules: allModules,
        isLoading: false,
        isOffline: false,
        page: page + 1,
        hasMore: modules.length >= AppConstants.defaultPageSize,
      );
    } catch (e) {
      // Try offline cache
      final cached = await _loadCachedModules();
      if (cached.isNotEmpty) {
        state = state.copyWith(
          modules: cached,
          isLoading: false,
          isOffline: true,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: _friendlyError(e),
        );
      }
    }
  }

  Future<void> refresh() => fetchModules(refresh: true);

  static String _friendlyError(Object e) {
    if (e is DioException) {
      if (e.error is ApiException) return (e.error as ApiException).message;
      if (e.response != null) return 'Server error (HTTP ${e.response!.statusCode}).';
      if (e.type == DioExceptionType.connectionError) {
        return 'Cannot reach the server. Make sure the backend is running.';
      }
    }
    return e.toString();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSubjectFilter(String? subject) {
    if (subject == null || state.subjectFilter == subject) {
      state = state.copyWith(clearSubjectFilter: true);
    } else {
      state = state.copyWith(subjectFilter: subject);
    }
  }

  void setDifficultyFilter(int? difficulty) {
    if (difficulty == null || state.difficultyFilter == difficulty) {
      state = state.copyWith(clearDifficultyFilter: true);
    } else {
      state = state.copyWith(difficultyFilter: difficulty);
    }
  }

  Future<void> _cacheModules(List<Module> modules) async {
    final box = _box;
    if (box == null) return;
    final encoded = modules.map((m) => jsonEncode(m.toJson())).toList();
    await box.put('modules_list', encoded);
  }

  Future<List<Module>> _loadCachedModules() async {
    final box = _box;
    if (box == null) return [];
    final raw = box.get('modules_list');
    if (raw == null) return [];
    return (raw as List)
        .map((s) => Module.fromJson(jsonDecode(s as String) as Map<String, dynamic>))
        .toList();
  }
}

final modulesProvider =
    StateNotifierProvider<ModulesNotifier, ModulesState>((ref) {
  final dio = ref.watch(apiClientProvider);
  return ModulesNotifier(dio);
});

// ---------------------------------------------------------------------------
// Single module provider
// ---------------------------------------------------------------------------

final moduleDetailProvider =
    FutureProvider.family<Module, String>((ref, moduleId) async {
  final dio = ref.watch(apiClientProvider);

  // Try cache first
  final box = await Hive.openBox(AppConstants.modulesBoxName);
  final raw = box.get('module_$moduleId');
  if (raw != null) {
    try {
      return Module.fromJson(jsonDecode(raw as String) as Map<String, dynamic>);
    } catch (_) {}
  }

  final response = await dio.get<Map<String, dynamic>>('/modules/$moduleId');
  // Backend wraps single-item responses in { "success": true, "data": {...} }
  final rawModule = (response.data!['data'] as Map<String, dynamic>?) ?? response.data!;
  final module = Module.fromJson(rawModule);

  // Cache it
  await box.put('module_$moduleId', jsonEncode(module.toJson()));

  return module;
});
