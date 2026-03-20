import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/services/api_client.dart';
import '../../auth/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class ModuleProgress {
  final String moduleId;
  final String moduleName;
  final String subject;
  final int sessionCount;
  final int masteryLevel; // 0=none, 1=bronze, 2=silver, 3=gold
  final double completionRatio; // 0.0 - 1.0

  const ModuleProgress({
    required this.moduleId,
    required this.moduleName,
    required this.subject,
    required this.sessionCount,
    required this.masteryLevel,
    required this.completionRatio,
  });

  factory ModuleProgress.fromJson(Map<String, dynamic> json) => ModuleProgress(
        moduleId: json['module_id'] as String? ?? '',
        moduleName: json['module_name'] as String? ??
            json['module']?['title'] as String? ?? 'Unknown',
        subject: json['subject'] as String? ??
            json['module']?['subject'] as String? ?? 'physics',
        sessionCount: (json['session_count'] as num?)?.toInt() ?? 0,
        masteryLevel: (json['mastery_level'] as num?)?.toInt() ?? 0,
        completionRatio: (json['completion_ratio'] as num?)?.toDouble() ?? 0.0,
      );
}

class ProgressData {
  final int totalSessions;
  final int modulesCompleted;
  final List<ModuleProgress> moduleProgress;

  const ProgressData({
    required this.totalSessions,
    required this.modulesCompleted,
    required this.moduleProgress,
  });

  factory ProgressData.fromJson(Map<String, dynamic> json) => ProgressData(
        totalSessions: (json['total_sessions'] as num?)?.toInt() ?? 0,
        modulesCompleted: (json['modules_completed'] as num?)?.toInt() ?? 0,
        moduleProgress: (json['module_progress'] as List<dynamic>? ?? [])
            .map((m) =>
                ModuleProgress.fromJson(m as Map<String, dynamic>))
            .toList(),
      );
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final progressProvider = FutureProvider.autoDispose<ProgressData>((ref) async {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  if (!isAuthenticated) {
    return const ProgressData(totalSessions: 0, modulesCompleted: 0, moduleProgress: []);
  }
  final dio = ref.watch(apiClientProvider);
  final response = await dio.get<Map<String, dynamic>>('/progress');
  return ProgressData.fromJson(response.data!);
});
