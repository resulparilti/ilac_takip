import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Yaşlı kullanıcı odaklı tasarım token'ları.
/// Referans: tasarim_sablon.html (primary mavi, secondary yeşil, büyük tipografi).
abstract final class AppColors {
  static const Color primary = Color(0xFF005BBF);
  static const Color primaryContainer = Color(0xFF1A73E8);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color secondary = Color(0xFF006E2C);
  static const Color secondaryContainer = Color(0xFF86F898);
  static const Color onSecondaryContainer = Color(0xFF00722F);

  static const Color tertiary = Color(0xFFBB1712);
  static const Color tertiaryContainer = Color(0xFFDF3429);

  static const Color surface = Color(0xFFFAF9FD);
  static const Color surfaceContainer = Color(0xFFEFEDF1);
  static const Color surfaceContainerLow = Color(0xFFF4F3F7);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1A1B1E);
  static const Color onSurfaceVariant = Color(0xFF414754);
  static const Color outline = Color(0xFF727785);
  static const Color outlineVariant = Color(0xFFC1C6D6);

  static const Color error = Color(0xFFBA1A1A);
  static const Color warning = Color(0xFFE6A700);
  static const Color success = Color(0xFF006E2C);
}

abstract final class AppSpacing {
  static const double marginMobile = 20;
  static const double stackSm = 12;
  static const double stackMd = 24;
  static const double stackLg = 48;
  static const double tapTargetMin = 48;
}

/// Yazı / buton ölçeği (Ayarlar'dan kişiselleştirilecek).
enum UiScale {
  normal(1.0),
  large(1.15),
  extraLarge(1.3);

  const UiScale(this.factor);
  final double factor;
}

class AppTheme {
  AppTheme._();

  static ThemeData light({UiScale scale = UiScale.large}) {
    final textTheme = _textTheme(scale.factor);
    final colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimary,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onPrimary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.tertiary,
      tertiaryContainer: AppColors.tertiaryContainer,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      error: AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surface,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface.withValues(alpha: 0.92),
        foregroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineMedium?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        extendedTextStyle: textTheme.labelLarge,
        extendedPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: Size(
            64,
            AppSpacing.tapTargetMin * scale.factor,
          ),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size(
            64,
            AppSpacing.tapTargetMin * scale.factor,
          ),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72 * scale.factor.clamp(1.0, 1.2),
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
        indicatorColor: AppColors.primary.withValues(alpha: 0.15),
      ),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }

  static TextTheme _textTheme(double scale) {
    // Atkinson Hyperlegible: yaşlı / düşük görme için okunaklı font.
    final base = GoogleFonts.atkinsonHyperlegibleTextTheme();
    TextStyle s(double size, FontWeight weight, {double? height}) =>
        base.bodyLarge!.copyWith(
          fontSize: size * scale,
          fontWeight: weight,
          height: height,
          color: AppColors.onSurface,
          letterSpacing: 0,
        );

    return TextTheme(
      displayLarge: s(34, FontWeight.w700, height: 1.3),
      headlineLarge: s(28, FontWeight.w700, height: 1.3),
      headlineMedium: s(24, FontWeight.w600, height: 1.33),
      titleLarge: s(22, FontWeight.w600),
      bodyLarge: s(20, FontWeight.w400, height: 1.5),
      bodyMedium: s(18, FontWeight.w400, height: 1.55),
      labelLarge: s(18, FontWeight.w600, height: 1.33),
      labelMedium: s(16, FontWeight.w600, height: 1.25),
    );
  }
}
