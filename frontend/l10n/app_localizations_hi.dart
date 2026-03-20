// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'Conceptra';

  @override
  String get appTagline => 'विज़ुअलाइज़ेशन से सीखें';

  @override
  String get loginTitle => 'वापसी पर स्वागत है';

  @override
  String get loginSubtitle => 'सीखना जारी रखने के लिए साइन इन करें';

  @override
  String get emailLabel => 'ईमेल';

  @override
  String get emailHint => 'अपना ईमेल पता दर्ज करें';

  @override
  String get passwordLabel => 'पासवर्ड';

  @override
  String get passwordHint => 'अपना पासवर्ड दर्ज करें';

  @override
  String get loginButton => 'साइन इन';

  @override
  String get loginWithGoogle => 'Google से जारी रखें';

  @override
  String get noAccountPrompt => 'खाता नहीं है?';

  @override
  String get registerLink => 'रजिस्टर करें';

  @override
  String get registerTitle => 'खाता बनाएं';

  @override
  String get registerSubtitle => 'EduViz से जुड़ें और सीखना शुरू करें';

  @override
  String get displayNameLabel => 'प्रदर्शन नाम';

  @override
  String get displayNameHint => 'अपना पूरा नाम दर्ज करें';

  @override
  String get confirmPasswordLabel => 'पासवर्ड की पुष्टि करें';

  @override
  String get confirmPasswordHint => 'पासवर्ड दोबारा दर्ज करें';

  @override
  String get classGradeLabel => 'कक्षा';

  @override
  String get selectGrade => 'अपनी कक्षा चुनें';

  @override
  String get registerButton => 'खाता बनाएं';

  @override
  String get alreadyHaveAccount => 'पहले से खाता है?';

  @override
  String get loginLink => 'साइन इन';

  @override
  String get homeTitle => 'EduViz';

  @override
  String get modulesTab => 'मॉड्यूल';

  @override
  String get historyTab => 'इतिहास';

  @override
  String get progressTab => 'प्रगति';

  @override
  String get profileTab => 'प्रोफ़ाइल';

  @override
  String get modulesTitle => 'मॉड्यूल खोजें';

  @override
  String get searchModules => 'मॉड्यूल खोजें...';

  @override
  String get filterAll => 'सभी';

  @override
  String get filterPhysics => 'भौतिकी';

  @override
  String get filterMathematics => 'गणित';

  @override
  String get filterChemistry => 'रसायन विज्ञान';

  @override
  String get filterBasic => 'बेसिक';

  @override
  String get filterIntermediate => 'मध्यम';

  @override
  String get filterAdvanced => 'उन्नत';

  @override
  String get difficultyBasic => 'बेसिक';

  @override
  String get difficultyIntermediate => 'मध्यम';

  @override
  String get difficultyAdvanced => 'उन्नत';

  @override
  String classRange(int min, int max) {
    return 'कक्षा $min-$max';
  }

  @override
  String get startButton => 'शुरू करें';

  @override
  String get moduleDetailTitle => 'मॉड्यूल विवरण';

  @override
  String get parametersSection => 'पैरामीटर';

  @override
  String get startSimulation => 'सिमुलेशन शुरू करें';

  @override
  String get simulationTitle => 'सिमुलेशन';

  @override
  String get calculateButton => 'गणना करें';

  @override
  String get resetButton => 'रीसेट';

  @override
  String get resultSection => 'परिणाम';

  @override
  String get explanationSection => 'यह कैसे काम करता है';

  @override
  String get graphTab => 'ग्राफ';

  @override
  String get simulationTab => 'सिमुलेशन';

  @override
  String get formulaLabel => 'सूत्र';

  @override
  String get substitutionLabel => 'गणना';

  @override
  String get conclusionLabel => 'निष्कर्ष';

  @override
  String get historyTitle => 'मेरा इतिहास';

  @override
  String get emptyHistory => 'अभी तक कोई सिमुलेशन इतिहास नहीं';

  @override
  String get emptyHistorySubtitle =>
      'अपना इतिहास देखने के लिए सिमुलेशन शुरू करें';

  @override
  String get progressTitle => 'मेरी प्रगति';

  @override
  String get totalSessions => 'कुल सत्र';

  @override
  String get modulesCompleted => 'पूर्ण मॉड्यूल';

  @override
  String get masteryLabel => 'महारत';

  @override
  String get profileTitle => 'प्रोफ़ाइल';

  @override
  String get languageLabel => 'भाषा';

  @override
  String get themeLabel => 'थीम';

  @override
  String get lightTheme => 'हल्की';

  @override
  String get darkTheme => 'गहरी';

  @override
  String get logoutButton => 'लॉग आउट';

  @override
  String get editProfileButton => 'प्रोफ़ाइल संपादित करें';

  @override
  String get saveButton => 'सहेजें';

  @override
  String get cancelButton => 'रद्द करें';

  @override
  String get offlineBanner => 'आप ऑफ़लाइन हैं — कैश डेटा दिखाया जा रहा है';

  @override
  String get retryButton => 'पुनः प्रयास करें';

  @override
  String get errorGeneric => 'कुछ गलत हुआ। कृपया फिर से प्रयास करें।';

  @override
  String get errorNetwork => 'नेटवर्क त्रुटि। अपना कनेक्शन जांचें।';

  @override
  String get errorAuth => 'प्रमाणीकरण विफल। कृपया दोबारा लॉगिन करें।';

  @override
  String get errorNotFound => 'मॉड्यूल नहीं मिला।';

  @override
  String get errorValidationEmail => 'कृपया एक वैध ईमेल पता दर्ज करें';

  @override
  String get errorValidationPassword =>
      'पासवर्ड कम से कम 8 अक्षरों का होना चाहिए';

  @override
  String get errorValidationPasswordMatch => 'पासवर्ड मेल नहीं खाते';

  @override
  String get errorValidationName => 'नाम खाली नहीं हो सकता';

  @override
  String get errorValidationGrade => 'कृपया अपनी कक्षा चुनें';

  @override
  String get loadingModules => 'मॉड्यूल लोड हो रहे हैं...';

  @override
  String get loadingSimulation => 'सिमुलेशन चल रहा है...';

  @override
  String get loadingHistory => 'इतिहास लोड हो रहा है...';

  @override
  String get loadingProgress => 'प्रगति लोड हो रही है...';

  @override
  String get noModulesFound => 'कोई मॉड्यूल नहीं मिला';

  @override
  String get noModulesFoundSubtitle =>
      'अपने फ़िल्टर समायोजित करने का प्रयास करें';

  @override
  String sessionDate(String date) {
    return '$date को सत्र';
  }

  @override
  String resultValue(String value, String unit) {
    return 'परिणाम: $value $unit';
  }

  @override
  String get languageEnglish => 'अंग्रेज़ी';

  @override
  String get languageHindi => 'हिंदी';

  @override
  String get languageTelugu => 'तेलुगु';

  @override
  String get roleStudent => 'छात्र';

  @override
  String get roleTeacher => 'शिक्षक';

  @override
  String gradeClass(int grade) {
    return 'कक्षा $grade';
  }

  @override
  String get simulationQueued =>
      'सिमुलेशन ऑफ़लाइन सहेजी गई। कनेक्ट होने पर सिंक होगी।';

  @override
  String get syncComplete => 'ऑफ़लाइन सत्र सफलतापूर्वक सिंक हो गए।';

  @override
  String get emptyProgress => 'अभी तक कोई प्रगति डेटा नहीं';

  @override
  String get emptyProgressSubtitle =>
      'प्रगति ट्रैक करने के लिए सिमुलेशन पूरी करें';
}
