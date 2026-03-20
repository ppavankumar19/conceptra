import 'package:flutter/material.dart';

class AppConstants {
  // Grade range
  static const int minGrade = 6;
  static const int maxGrade = 12;

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 700);
  static const Duration resultRevealAnimation = Duration(milliseconds: 600);

  // API timeouts
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Pagination
  static const int defaultPageSize = 20;

  // Hive box names
  static const String modulesBoxName = 'modules_cache';
  static const String sessionsBoxName = 'sessions_cache';
  static const String syncQueueBoxName = 'sync_queue';
  static const String userPrefsBoxName = 'user_prefs';

  // Subject identifiers
  static const String subjectPhysics = 'physics';
  static const String subjectMathematics = 'mathematics';
  static const String subjectChemistry = 'chemistry';

  // Difficulty levels
  static const int difficultyBasic = 1;
  static const int difficultyIntermediate = 2;
  static const int difficultyAdvanced = 3;

  // Subject colors — kept in sync with SubjectColors.light in theme.dart
  static const Color physicsColor = Color(0xFF0EA5E9);       // Sky Cyan
  static const Color physicsColorLight = Color(0xFFE0F2FE);
  static const Color mathematicsColor = Color(0xFF7C3AED);   // Violet
  static const Color mathematicsColorLight = Color(0xFFEDE9FE);
  static const Color chemistryColor = Color(0xFFDB2777);     // Pink
  static const Color chemistryColorLight = Color(0xFFFCE7F3);
  static const Color defaultSubjectColor = Color(0xFF5B21B6);
  static const Color defaultSubjectColorLight = Color(0xFFEDE9FE);

  // Mastery thresholds
  static const int masteryBronze = 3;
  static const int masterySilver = 7;
  static const int masteryGold = 15;

  // Mastery badge colors
  static const Color masteryBronzeColor = Color(0xFFCD7F32);
  static const Color masterySilverColor = Color(0xFF9E9E9E);
  static const Color masteryGoldColor = Color(0xFFFFB300);

  // Progress stat color
  static const Color progressGreenColor = Color(0xFF43A047);

  // Prefs keys
  static const String prefsThemeMode = 'theme_mode';
  static const String prefsLocale = 'locale';

  static Color subjectColor(String subject) {
    switch (subject.toLowerCase()) {
      case subjectPhysics:
        return physicsColor;
      case subjectMathematics:
        return mathematicsColor;
      case subjectChemistry:
        return chemistryColor;
      default:
        return defaultSubjectColor;
    }
  }

  static Color subjectColorLight(String subject) {
    switch (subject.toLowerCase()) {
      case subjectPhysics:
        return physicsColorLight;
      case subjectMathematics:
        return mathematicsColorLight;
      case subjectChemistry:
        return chemistryColorLight;
      default:
        return defaultSubjectColorLight;
    }
  }

  static String difficultyLabel(int level) {
    switch (level) {
      case difficultyBasic:
        return 'Basic';
      case difficultyIntermediate:
        return 'Intermediate';
      case difficultyAdvanced:
        return 'Advanced';
      default:
        return 'Unknown';
    }
  }

  static Color difficultyColor(int level) {
    switch (level) {
      case difficultyBasic:
        return const Color(0xFF43A047);
      case difficultyIntermediate:
        return const Color(0xFFFB8C00);
      case difficultyAdvanced:
        return const Color(0xFFE53935);
      default:
        return const Color(0xFF757575);
    }
  }
}
