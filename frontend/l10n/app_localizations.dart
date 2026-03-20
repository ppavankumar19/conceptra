import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('te')
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'Conceptra'**
  String get appTitle;

  /// App tagline
  ///
  /// In en, this message translates to:
  /// **'Think. Visualize. Master.'**
  String get appTagline;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue learning'**
  String get loginSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get emailHint;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginButton;

  /// No description provided for @loginWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get loginWithGoogle;

  /// No description provided for @noAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccountPrompt;

  /// No description provided for @registerLink.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerLink;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join Conceptra and start learning'**
  String get registerSubtitle;

  /// No description provided for @displayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayNameLabel;

  /// No description provided for @displayNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get displayNameHint;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get confirmPasswordHint;

  /// No description provided for @classGradeLabel.
  ///
  /// In en, this message translates to:
  /// **'Class Grade'**
  String get classGradeLabel;

  /// No description provided for @selectGrade.
  ///
  /// In en, this message translates to:
  /// **'Select your class'**
  String get selectGrade;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerButton;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @loginLink.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginLink;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Conceptra'**
  String get homeTitle;

  /// No description provided for @modulesTab.
  ///
  /// In en, this message translates to:
  /// **'Modules'**
  String get modulesTab;

  /// No description provided for @historyTab.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTab;

  /// No description provided for @progressTab.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progressTab;

  /// No description provided for @profileTab.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTab;

  /// No description provided for @modulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore Modules'**
  String get modulesTitle;

  /// No description provided for @searchModules.
  ///
  /// In en, this message translates to:
  /// **'Search modules...'**
  String get searchModules;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterPhysics.
  ///
  /// In en, this message translates to:
  /// **'Physics'**
  String get filterPhysics;

  /// No description provided for @filterMathematics.
  ///
  /// In en, this message translates to:
  /// **'Mathematics'**
  String get filterMathematics;

  /// No description provided for @filterChemistry.
  ///
  /// In en, this message translates to:
  /// **'Chemistry'**
  String get filterChemistry;

  /// No description provided for @filterBasic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get filterBasic;

  /// No description provided for @filterIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get filterIntermediate;

  /// No description provided for @filterAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get filterAdvanced;

  /// No description provided for @difficultyBasic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get difficultyBasic;

  /// No description provided for @difficultyIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get difficultyIntermediate;

  /// No description provided for @difficultyAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get difficultyAdvanced;

  /// No description provided for @classRange.
  ///
  /// In en, this message translates to:
  /// **'Class {min}-{max}'**
  String classRange(int min, int max);

  /// No description provided for @startButton.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startButton;

  /// No description provided for @moduleDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Module Details'**
  String get moduleDetailTitle;

  /// No description provided for @parametersSection.
  ///
  /// In en, this message translates to:
  /// **'Parameters'**
  String get parametersSection;

  /// No description provided for @startSimulation.
  ///
  /// In en, this message translates to:
  /// **'Start Simulation'**
  String get startSimulation;

  /// No description provided for @simulationTitle.
  ///
  /// In en, this message translates to:
  /// **'Simulation'**
  String get simulationTitle;

  /// No description provided for @calculateButton.
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get calculateButton;

  /// No description provided for @resetButton.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetButton;

  /// No description provided for @resultSection.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get resultSection;

  /// No description provided for @explanationSection.
  ///
  /// In en, this message translates to:
  /// **'How It Works'**
  String get explanationSection;

  /// No description provided for @graphTab.
  ///
  /// In en, this message translates to:
  /// **'Graph'**
  String get graphTab;

  /// No description provided for @simulationTab.
  ///
  /// In en, this message translates to:
  /// **'Simulation'**
  String get simulationTab;

  /// No description provided for @formulaLabel.
  ///
  /// In en, this message translates to:
  /// **'Formula'**
  String get formulaLabel;

  /// No description provided for @substitutionLabel.
  ///
  /// In en, this message translates to:
  /// **'Calculation'**
  String get substitutionLabel;

  /// No description provided for @conclusionLabel.
  ///
  /// In en, this message translates to:
  /// **'Conclusion'**
  String get conclusionLabel;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'My History'**
  String get historyTitle;

  /// No description provided for @emptyHistory.
  ///
  /// In en, this message translates to:
  /// **'No simulation history yet'**
  String get emptyHistory;

  /// No description provided for @emptyHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start a simulation to see your history here'**
  String get emptyHistorySubtitle;

  /// No description provided for @progressTitle.
  ///
  /// In en, this message translates to:
  /// **'My Progress'**
  String get progressTitle;

  /// No description provided for @totalSessions.
  ///
  /// In en, this message translates to:
  /// **'Total Sessions'**
  String get totalSessions;

  /// No description provided for @modulesCompleted.
  ///
  /// In en, this message translates to:
  /// **'Modules Completed'**
  String get modulesCompleted;

  /// No description provided for @masteryLabel.
  ///
  /// In en, this message translates to:
  /// **'Mastery'**
  String get masteryLabel;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @themeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// No description provided for @logoutButton.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutButton;

  /// No description provided for @editProfileButton.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileButton;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline — cached data shown'**
  String get offlineBanner;

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your connection.'**
  String get errorNetwork;

  /// No description provided for @errorAuth.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please login again.'**
  String get errorAuth;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'Module not found.'**
  String get errorNotFound;

  /// No description provided for @errorValidationEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get errorValidationEmail;

  /// No description provided for @errorValidationPassword.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get errorValidationPassword;

  /// No description provided for @errorValidationPasswordMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get errorValidationPasswordMatch;

  /// No description provided for @errorValidationName.
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty'**
  String get errorValidationName;

  /// No description provided for @errorValidationGrade.
  ///
  /// In en, this message translates to:
  /// **'Please select your class grade'**
  String get errorValidationGrade;

  /// No description provided for @loadingModules.
  ///
  /// In en, this message translates to:
  /// **'Loading modules...'**
  String get loadingModules;

  /// No description provided for @loadingSimulation.
  ///
  /// In en, this message translates to:
  /// **'Running simulation...'**
  String get loadingSimulation;

  /// No description provided for @loadingHistory.
  ///
  /// In en, this message translates to:
  /// **'Loading history...'**
  String get loadingHistory;

  /// No description provided for @loadingProgress.
  ///
  /// In en, this message translates to:
  /// **'Loading progress...'**
  String get loadingProgress;

  /// No description provided for @noModulesFound.
  ///
  /// In en, this message translates to:
  /// **'No modules found'**
  String get noModulesFound;

  /// No description provided for @noModulesFoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filters'**
  String get noModulesFoundSubtitle;

  /// No description provided for @sessionDate.
  ///
  /// In en, this message translates to:
  /// **'Session on {date}'**
  String sessionDate(String date);

  /// No description provided for @resultValue.
  ///
  /// In en, this message translates to:
  /// **'Result: {value} {unit}'**
  String resultValue(String value, String unit);

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageHindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get languageHindi;

  /// No description provided for @languageTelugu.
  ///
  /// In en, this message translates to:
  /// **'Telugu'**
  String get languageTelugu;

  /// No description provided for @roleStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get roleStudent;

  /// No description provided for @roleTeacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get roleTeacher;

  /// No description provided for @gradeClass.
  ///
  /// In en, this message translates to:
  /// **'Class {grade}'**
  String gradeClass(int grade);

  /// No description provided for @simulationQueued.
  ///
  /// In en, this message translates to:
  /// **'Simulation saved offline. Will sync when connected.'**
  String get simulationQueued;

  /// No description provided for @syncComplete.
  ///
  /// In en, this message translates to:
  /// **'Offline sessions synced successfully.'**
  String get syncComplete;

  /// No description provided for @emptyProgress.
  ///
  /// In en, this message translates to:
  /// **'No progress data yet'**
  String get emptyProgress;

  /// No description provided for @emptyProgressSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Complete simulations to track your progress'**
  String get emptyProgressSubtitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'te'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
