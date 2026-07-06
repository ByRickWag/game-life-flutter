import 'package:flutter/material.dart';

import '../design_system/game_design_system.dart';

class AppTheme {
  static const Color background = GameColors.background;
  static const Color surface = GameColors.surface;
  static const Color surfaceSoft = GameColors.surfaceSoft;
  static const Color primary = GameColors.primary;
  static const Color secondary = GameColors.reward;
  static const Color success = GameColors.success;
  static const Color danger = GameColors.danger;

  static ThemeData get darkTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: GameColors.primary,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(
        brightness: Brightness.dark,
        primary: GameColors.primary,
        secondary: GameColors.reward,
        surface: GameColors.surface,
        error: GameColors.danger,
        onPrimary: GameColors.textPrimary,
        onSecondary: GameColors.background,
        onSurface: GameColors.textPrimary,
      ),
      scaffoldBackgroundColor: GameColors.background,
      fontFamily: 'Roboto',
      visualDensity: VisualDensity.standard,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: GameColors.background.withValues(alpha: 0.92),
        foregroundColor: GameColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GameTextStyles.sectionTitle,
        iconTheme: const IconThemeData(color: GameColors.textSecondary),
        actionsIconTheme: const IconThemeData(color: GameColors.textSecondary),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: GameColors.backgroundAlt,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: GameColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: GameRadius.card,
          side: const BorderSide(color: GameColors.borderSoft),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: GameColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: GameColors.primary.withValues(alpha: 0.22),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? GameColors.textPrimary : GameColors.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? GameColors.primary : GameColors.textMuted,
            size: selected ? 25 : 23,
          );
        }),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: GameColors.textMuted,
        textColor: GameColors.textSecondary,
        selectedColor: GameColors.textPrimary,
        selectedTileColor: GameColors.primary.withValues(alpha: 0.14),
        shape: RoundedRectangleBorder(borderRadius: GameRadius.button),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: GameColors.surfaceSoft,
        selectedColor: GameColors.primary.withValues(alpha: 0.22),
        disabledColor: GameColors.surface,
        secondarySelectedColor: GameColors.reward.withValues(alpha: 0.22),
        side: const BorderSide(color: GameColors.borderSoft),
        labelStyle: GameTextStyles.caption,
        secondaryLabelStyle: GameTextStyles.caption.copyWith(color: GameColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: GameRadius.chip),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: GameColors.primary,
        foregroundColor: GameColors.textPrimary,
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 6,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GameRadius.lg)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          backgroundColor: GameColors.primary,
          foregroundColor: GameColors.textPrimary,
          textStyle: GameTextStyles.button,
          shape: RoundedRectangleBorder(borderRadius: GameRadius.button),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: GameColors.textPrimary,
          side: const BorderSide(color: GameColors.border),
          textStyle: GameTextStyles.button,
          shape: RoundedRectangleBorder(borderRadius: GameRadius.button),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: GameColors.primarySoft,
          textStyle: GameTextStyles.button,
          shape: RoundedRectangleBorder(borderRadius: GameRadius.button),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: GameColors.surfaceSoft.withValues(alpha: 0.86),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: GameColors.textMuted),
        hintStyle: const TextStyle(color: GameColors.textDisabled),
        border: OutlineInputBorder(
          borderRadius: GameRadius.button,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: GameRadius.button,
          borderSide: const BorderSide(color: GameColors.borderSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: GameRadius.button,
          borderSide: const BorderSide(color: GameColors.primarySoft, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: GameRadius.button,
          borderSide: const BorderSide(color: GameColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: GameRadius.button,
          borderSide: const BorderSide(color: GameColors.danger, width: 1.4),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: GameColors.surfaceRaised,
        contentTextStyle: GameTextStyles.body.copyWith(color: GameColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: GameRadius.button),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: GameColors.primary,
        linearTrackColor: GameColors.surfaceOverlay,
      ),
      dividerTheme: const DividerThemeData(
        color: GameColors.borderSoft,
        thickness: 1,
        space: 24,
      ),
      textTheme: const TextTheme(
        headlineMedium: GameTextStyles.display,
        titleLarge: GameTextStyles.title,
        titleMedium: GameTextStyles.sectionTitle,
        titleSmall: GameTextStyles.cardTitle,
        bodyLarge: GameTextStyles.body,
        bodyMedium: GameTextStyles.body,
        bodySmall: GameTextStyles.caption,
        labelLarge: GameTextStyles.button,
        labelSmall: GameTextStyles.caption,
      ),
    );
  }
}
