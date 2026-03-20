// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Conceptra';

  @override
  String get appTagline => 'Think. Visualize. Master.';

  @override
  String get loginTitle => 'Welcome Back';

  @override
  String get loginSubtitle => 'Sign in to continue learning';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'Enter your email address';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get loginButton => 'Sign In';

  @override
  String get loginWithGoogle => 'Continue with Google';

  @override
  String get noAccountPrompt => 'Don\'t have an account?';

  @override
  String get registerLink => 'Register';

  @override
  String get registerTitle => 'Create Account';

  @override
  String get registerSubtitle => 'Join Conceptra and start learning';

  @override
  String get displayNameLabel => 'Display Name';

  @override
  String get displayNameHint => 'Enter your full name';

  @override
  String get confirmPasswordLabel => 'Confirm Password';

  @override
  String get confirmPasswordHint => 'Re-enter your password';

  @override
  String get classGradeLabel => 'Class Grade';

  @override
  String get selectGrade => 'Select your class';

  @override
  String get registerButton => 'Create Account';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get loginLink => 'Sign In';

  @override
  String get homeTitle => 'Conceptra';

  @override
  String get modulesTab => 'Modules';

  @override
  String get historyTab => 'History';

  @override
  String get progressTab => 'Progress';

  @override
  String get profileTab => 'Profile';

  @override
  String get modulesTitle => 'Explore Modules';

  @override
  String get searchModules => 'Search modules...';

  @override
  String get filterAll => 'All';

  @override
  String get filterPhysics => 'Physics';

  @override
  String get filterMathematics => 'Mathematics';

  @override
  String get filterChemistry => 'Chemistry';

  @override
  String get filterBasic => 'Basic';

  @override
  String get filterIntermediate => 'Intermediate';

  @override
  String get filterAdvanced => 'Advanced';

  @override
  String get difficultyBasic => 'Basic';

  @override
  String get difficultyIntermediate => 'Intermediate';

  @override
  String get difficultyAdvanced => 'Advanced';

  @override
  String classRange(int min, int max) {
    return 'Class $min-$max';
  }

  @override
  String get startButton => 'Start';

  @override
  String get moduleDetailTitle => 'Module Details';

  @override
  String get parametersSection => 'Parameters';

  @override
  String get startSimulation => 'Start Simulation';

  @override
  String get simulationTitle => 'Simulation';

  @override
  String get calculateButton => 'Calculate';

  @override
  String get resetButton => 'Reset';

  @override
  String get resultSection => 'Result';

  @override
  String get explanationSection => 'How It Works';

  @override
  String get graphTab => 'Graph';

  @override
  String get simulationTab => 'Simulation';

  @override
  String get formulaLabel => 'Formula';

  @override
  String get substitutionLabel => 'Calculation';

  @override
  String get conclusionLabel => 'Conclusion';

  @override
  String get historyTitle => 'My History';

  @override
  String get emptyHistory => 'No simulation history yet';

  @override
  String get emptyHistorySubtitle =>
      'Start a simulation to see your history here';

  @override
  String get progressTitle => 'My Progress';

  @override
  String get totalSessions => 'Total Sessions';

  @override
  String get modulesCompleted => 'Modules Completed';

  @override
  String get masteryLabel => 'Mastery';

  @override
  String get profileTitle => 'Profile';

  @override
  String get languageLabel => 'Language';

  @override
  String get themeLabel => 'Theme';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get logoutButton => 'Logout';

  @override
  String get editProfileButton => 'Edit Profile';

  @override
  String get saveButton => 'Save';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get offlineBanner => 'You\'re offline — cached data shown';

  @override
  String get retryButton => 'Retry';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNetwork => 'Network error. Check your connection.';

  @override
  String get errorAuth => 'Authentication failed. Please login again.';

  @override
  String get errorNotFound => 'Module not found.';

  @override
  String get errorValidationEmail => 'Please enter a valid email address';

  @override
  String get errorValidationPassword =>
      'Password must be at least 8 characters';

  @override
  String get errorValidationPasswordMatch => 'Passwords do not match';

  @override
  String get errorValidationName => 'Name cannot be empty';

  @override
  String get errorValidationGrade => 'Please select your class grade';

  @override
  String get loadingModules => 'Loading modules...';

  @override
  String get loadingSimulation => 'Running simulation...';

  @override
  String get loadingHistory => 'Loading history...';

  @override
  String get loadingProgress => 'Loading progress...';

  @override
  String get noModulesFound => 'No modules found';

  @override
  String get noModulesFoundSubtitle => 'Try adjusting your filters';

  @override
  String sessionDate(String date) {
    return 'Session on $date';
  }

  @override
  String resultValue(String value, String unit) {
    return 'Result: $value $unit';
  }

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'Hindi';

  @override
  String get languageTelugu => 'Telugu';

  @override
  String get roleStudent => 'Student';

  @override
  String get roleTeacher => 'Teacher';

  @override
  String gradeClass(int grade) {
    return 'Class $grade';
  }

  @override
  String get simulationQueued =>
      'Simulation saved offline. Will sync when connected.';

  @override
  String get syncComplete => 'Offline sessions synced successfully.';

  @override
  String get emptyProgress => 'No progress data yet';

  @override
  String get emptyProgressSubtitle =>
      'Complete simulations to track your progress';
}
