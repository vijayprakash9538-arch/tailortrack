import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_radius.dart';

/// Builds the light and dark Material 3 themes for TailorTrack.
///
/// We use Inter as the cross-platform stand-in for SF Pro Display — it has
/// near-identical proportions and ships free via google_fonts, avoiding font
/// licensing concerns while keeping the "premium SaaS" feel on every platform.
class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.primaryDark,
      onSecondary: Colors.white,
      error: AppColors.statusOverdue,
      onError: Colors.white,
      surface: isDark ? AppColors.cardDark : AppColors.card,
      onSurface: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
    );

    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final baseTextTheme = GoogleFonts.interTextTheme().apply(
      bodyColor: textColor,
      displayColor: textColor,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: baseTextTheme,
      // Soft, premium ink feedback for every tappable surface.
      splashFactory: InkRipple.splashFactory,
      splashColor: AppColors.primary.withOpacity(0.08),
      highlightColor: Colors.black.withOpacity(0.03),
      iconTheme: IconThemeData(color: textColor, size: 19),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 52,
        actionsIconTheme: const IconThemeData(size: 19),
        iconTheme: const IconThemeData(size: 19),
        titleTextStyle: baseTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 18),
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.cardDark : AppColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: const WidgetStatePropertyAll(AppColors.primary),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(50)),
          textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button))),
          elevation: const WidgetStatePropertyAll(0),
          // Premium grey "press" overlay layered over the emerald.
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return Colors.black.withOpacity(0.16);
            if (states.contains(WidgetState.hovered)) return Colors.black.withOpacity(0.06);
            return null;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(50),
          side: const BorderSide(color: AppColors.primary),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.cardDark : AppColors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? AppColors.cardDark : AppColors.card,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        selectedIconTheme: const IconThemeData(size: 20),
        unselectedIconTheme: const IconThemeData(size: 20),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.borderDark : AppColors.border,
        space: 1,
        thickness: 1,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        iconSize: 20,
      ),
      chipTheme: ChipThemeData(
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
        backgroundColor: isDark ? AppColors.cardDark : AppColors.card,
        selectedColor: AppColors.primaryLight,
        showCheckmark: false,
      ),
    );
  }
}
