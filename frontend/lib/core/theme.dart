import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Brand palette ───────────────────────────────────────────────────────────
// Primary  : Deep Violet  #5B21B6  (intelligence, depth)
// Accent   : Sky Cyan     #0EA5E9  (clarity, visualization)
// Surface L: #FAFAFE      soft purple-white
// Surface D: #0D0A1F      deep dark violet
// ─────────────────────────────────────────────────────────────────────────────

class SubjectColors extends ThemeExtension<SubjectColors> {
  final Color physics;
  final Color physicsLight;
  final Color mathematics;
  final Color mathematicsLight;
  final Color chemistry;
  final Color chemistryLight;

  const SubjectColors({
    required this.physics,
    required this.physicsLight,
    required this.mathematics,
    required this.mathematicsLight,
    required this.chemistry,
    required this.chemistryLight,
  });

  @override
  SubjectColors copyWith({
    Color? physics,
    Color? physicsLight,
    Color? mathematics,
    Color? mathematicsLight,
    Color? chemistry,
    Color? chemistryLight,
  }) {
    return SubjectColors(
      physics: physics ?? this.physics,
      physicsLight: physicsLight ?? this.physicsLight,
      mathematics: mathematics ?? this.mathematics,
      mathematicsLight: mathematicsLight ?? this.mathematicsLight,
      chemistry: chemistry ?? this.chemistry,
      chemistryLight: chemistryLight ?? this.chemistryLight,
    );
  }

  @override
  SubjectColors lerp(ThemeExtension<SubjectColors>? other, double t) {
    if (other is! SubjectColors) return this;
    return SubjectColors(
      physics: Color.lerp(physics, other.physics, t)!,
      physicsLight: Color.lerp(physicsLight, other.physicsLight, t)!,
      mathematics: Color.lerp(mathematics, other.mathematics, t)!,
      mathematicsLight:
          Color.lerp(mathematicsLight, other.mathematicsLight, t)!,
      chemistry: Color.lerp(chemistry, other.chemistry, t)!,
      chemistryLight: Color.lerp(chemistryLight, other.chemistryLight, t)!,
    );
  }

  static const light = SubjectColors(
    physics: Color(0xFF0EA5E9),
    physicsLight: Color(0xFFE0F2FE),
    mathematics: Color(0xFF7C3AED),
    mathematicsLight: Color(0xFFEDE9FE),
    chemistry: Color(0xFFDB2777),
    chemistryLight: Color(0xFFFCE7F3),
  );

  static const dark = SubjectColors(
    physics: Color(0xFF38BDF8),
    physicsLight: Color(0xFF0C4A6E),
    mathematics: Color(0xFFA78BFA),
    mathematicsLight: Color(0xFF2E1065),
    chemistry: Color(0xFFF472B6),
    chemistryLight: Color(0xFF500724),
  );
}

class AppTheme {
  // Conceptra brand colours
  static const _primary = Color(0xFF5B21B6);       // Deep Violet
  static const _primaryDark = Color(0xFF8B5CF6);   // Soft Violet (dark mode)
  static const _secondary = Color(0xFF0EA5E9);      // Sky Cyan

  static TextTheme _buildTextTheme(Color textColor) {
    // Use GoogleFonts.poppins() so font loads correctly via network/cache
    final base = GoogleFonts.poppinsTextTheme().apply(
      bodyColor: textColor,
      displayColor: textColor,
    );
    return base.copyWith(
      displayLarge: GoogleFonts.poppins(fontSize: 57, fontWeight: FontWeight.w700, color: textColor, letterSpacing: -0.5),
      displayMedium: GoogleFonts.poppins(fontSize: 45, fontWeight: FontWeight.w700, color: textColor),
      displaySmall: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.w600, color: textColor),
      headlineLarge: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w700, color: textColor),
      headlineMedium: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w600, color: textColor),
      headlineSmall: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w600, color: textColor),
      titleLarge: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: textColor),
      titleMedium: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: textColor, letterSpacing: 0.1),
      titleSmall: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: textColor, letterSpacing: 0.1),
      bodyLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w400, color: textColor),
      bodyMedium: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: textColor),
      bodySmall: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w400, color: textColor, letterSpacing: 0.3),
      labelLarge: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
      labelMedium: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: textColor, letterSpacing: 0.4),
      labelSmall: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: textColor, letterSpacing: 0.4),
    );
  }

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: Brightness.light,
      primary: _primary,
      secondary: _secondary,
      surface: const Color(0xFFFAFAFE),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: const Color(0xFF1A1033),
      surfaceContainerHighest: const Color(0xFFEDE9FE),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _buildTextTheme(const Color(0xFF1A1033)),
      scaffoldBackgroundColor: const Color(0xFFF5F3FF),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFEDE9FE), width: 1),
        ),
        color: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFFAFAFE),
        foregroundColor: const Color(0xFF1A1033),
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: const Color(0x1A5B21B6),
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1A1033),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFEDE9FE),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFF5B21B6));
          }
          return const IconThemeData(color: Color(0xFF9E9EAE));
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5B21B6),
            );
          }
          return const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: Color(0xFF9E9EAE),
          );
        }),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primary,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: const BorderSide(color: Color(0xFFDDD6FE), width: 1.5),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primary,
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F3FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDDD6FE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDDD6FE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDB2777), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDB2777), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: Color(0xFF6D6A85),
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: Color(0xFF9E9EAE),
        ),
        prefixIconColor: const Color(0xFF7C3AED),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFEDE9FE),
        selectedColor: _primary,
        labelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: _primary,
        thumbColor: _primary,
        overlayColor: _primary.withValues(alpha: 0.12),
        inactiveTrackColor: const Color(0xFFDDD6FE),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFEDE9FE),
        thickness: 1,
      ),
      extensions: const [SubjectColors.light],
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryDark,
      brightness: Brightness.dark,
      primary: _primaryDark,
      secondary: _secondary,
      surface: const Color(0xFF120D24),
      onPrimary: Colors.white,
      onSurface: const Color(0xFFEDE9FE),
      surfaceContainerHighest: const Color(0xFF1E1640),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _buildTextTheme(const Color(0xFFEDE9FE)),
      scaffoldBackgroundColor: const Color(0xFF0D0A1F),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF2D2460), width: 1),
        ),
        color: const Color(0xFF161133),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF120D24),
        foregroundColor: const Color(0xFFEDE9FE),
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: Colors.black26,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFEDE9FE),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF120D24),
        indicatorColor: const Color(0xFF2D2460),
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFF8B5CF6));
          }
          return const IconThemeData(color: Color(0xFF6B6880));
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8B5CF6),
            );
          }
          return const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: Color(0xFF6B6880),
          );
        }),
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryDark,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryDark,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: const BorderSide(color: Color(0xFF3730A3), width: 1.5),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryDark,
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1A1540),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2D2460)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2D2460)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primaryDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFF472B6), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFF472B6), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: Color(0xFF9D9AB8),
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: Color(0xFF6B6880),
        ),
        prefixIconColor: _primaryDark,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF1E1640),
        selectedColor: _primaryDark,
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          color: Color(0xFFEDE9FE),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: _primaryDark,
        thumbColor: _primaryDark,
        overlayColor: _primaryDark.withValues(alpha: 0.12),
        inactiveTrackColor: const Color(0xFF2D2460),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2D2460),
        thickness: 1,
      ),
      extensions: const [SubjectColors.dark],
    );
  }
}
