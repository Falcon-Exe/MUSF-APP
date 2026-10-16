import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryGreen = Color(0xFF39544B);
  static const Color darkNavy = Color(0xFF08233E);
  static const Color darkGreen = Color(0xFF233A31);
  static const Color accentTeal = Color(0xFF14B8A6);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color pageBackground = Color(0xFFF6F8FB);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color alertRed = Color(0xFFEF4444);

  static const LinearGradient identityGradient = LinearGradient(
    colors: [primaryGreen, darkGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient adminHeaderGradient = LinearGradient(
    colors: [darkNavy, primaryGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.035),
      blurRadius: 14,
      offset: const Offset(0, 6),
    ),
  ];
}

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color brand;
  final Color brandDark;
  final Color accent;
  final Color pageBackground;
  final Color surface;
  final Color surfaceAlt;
  final Color textPrimary;
  final Color textMuted;
  final Color border;
  final Color danger;

  const AppPalette({
    required this.brand,
    required this.brandDark,
    required this.accent,
    required this.pageBackground,
    required this.surface,
    required this.surfaceAlt,
    required this.textPrimary,
    required this.textMuted,
    required this.border,
    required this.danger,
  });

  static const light = AppPalette(
    brand: AppColors.primaryGreen,
    brandDark: AppColors.darkGreen,
    accent: Color(0xFF059669),
    pageBackground: Color(0xFFF6F8FB),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFECFDF5),
    textPrimary: Color(0xFF0F172A),
    textMuted: Color(0xFF64748B),
    border: Color(0xFFE2E8F0),
    danger: AppColors.alertRed,
  );

  static const dark = AppPalette(
    brand: Color(0xFF7DD3BC),
    brandDark: Color(0xFF102821),
    accent: Color(0xFF2DD4BF),
    pageBackground: Color(0xFF081311),
    surface: Color(0xFF10201D),
    surfaceAlt: Color(0xFF17352F),
    textPrimary: Color(0xFFEAF7F2),
    textMuted: Color(0xFFA5B8B2),
    border: Color(0xFF24413A),
    danger: Color(0xFFF87171),
  );

  @override
  AppPalette copyWith({
    Color? brand,
    Color? brandDark,
    Color? accent,
    Color? pageBackground,
    Color? surface,
    Color? surfaceAlt,
    Color? textPrimary,
    Color? textMuted,
    Color? border,
    Color? danger,
  }) {
    return AppPalette(
      brand: brand ?? this.brand,
      brandDark: brandDark ?? this.brandDark,
      accent: accent ?? this.accent,
      pageBackground: pageBackground ?? this.pageBackground,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
      border: border ?? this.border,
      danger: danger ?? this.danger,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      brand: Color.lerp(brand, other.brand, t)!,
      brandDark: Color.lerp(brandDark, other.brandDark, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      pageBackground: Color.lerp(pageBackground, other.pageBackground, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}

class AppTheme {
  static ThemeData light() =>
      _build(brightness: Brightness.light, palette: AppPalette.light);

  static ThemeData dark() =>
      _build(brightness: Brightness.dark, palette: AppPalette.dark);

  static ThemeData _build({
    required Brightness brightness,
    required AppPalette palette,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: palette.brand,
      brightness: brightness,
      primary: palette.brand,
      secondary: palette.accent,
      surface: palette.surface,
      error: palette.danger,
    );

    final isDark = brightness == Brightness.dark;

    return ThemeData(
      fontFamily: 'sans-serif',
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.pageBackground,
      extensions: [palette],
      appBarTheme: AppBarTheme(
        backgroundColor: palette.pageBackground,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: palette.surface,
        selectedItemColor: palette.accent,
        unselectedItemColor: palette.textMuted,
        elevation: isDark ? 0 : 12,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: isDark ? 0 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(color: palette.border),
      iconTheme: IconThemeData(color: palette.textMuted),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.accent, width: 1.5),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? palette.accent
              : palette.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? palette.accent.withValues(alpha: 0.26)
              : palette.border;
        }),
      ),
      textTheme: ThemeData(brightness: brightness).textTheme.apply(
        bodyColor: palette.textPrimary,
        displayColor: palette.textPrimary,
      ),
    );
  }
}
