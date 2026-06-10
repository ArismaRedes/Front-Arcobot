import 'package:flutter/material.dart';
import 'package:front_arcobot/core/theme/design_tokens.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    const primary = ArcobotColors.guideTurquoise;
    const secondary = ArcobotColors.skyBlue;
    const surface = ArcobotColors.surface;
    const surfaceContainer = Color(0xFFF0F7FF);

    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      secondary: secondary,
      surface: surface,
      onSurface: ArcobotColors.textPrimary,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      outline: ArcobotColors.softBorder,
      error: ArcobotColors.coral,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: ArcobotColors.backgroundCloud,
      fontFamily: 'Nunito',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          height: 1.1,
          color: ArcobotColors.textPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          height: 1.1,
          color: ArcobotColors.textPrimary,
        ),
        displaySmall: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          height: 1.15,
          color: ArcobotColors.textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          height: 1.2,
          color: ArcobotColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.2,
          color: ArcobotColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          height: 1.25,
          color: ArcobotColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.3,
          color: ArcobotColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.35,
          color: ArcobotColors.textSecondary,
        ),
      ),
      cardTheme: const CardThemeData(
        color: surface,
        elevation: 0,
        shadowColor: Color(0x00000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(ArcobotRadii.lg)),
          side: BorderSide(color: ArcobotColors.softBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ArcobotRadii.md),
          borderSide: const BorderSide(color: ArcobotColors.softBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ArcobotRadii.md),
          borderSide: const BorderSide(color: ArcobotColors.softBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ArcobotRadii.md),
          borderSide: const BorderSide(
            color: ArcobotColors.guideTurquoise,
            width: 1.8,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        labelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: ArcobotColors.textSecondary,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(64),
          backgroundColor: primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ArcobotRadii.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(64),
          side: const BorderSide(color: ArcobotColors.softBorder),
          foregroundColor: ArcobotColors.textPrimary,
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ArcobotRadii.md),
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: ArcobotColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ArcobotColors.textPrimary,
        contentTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Tema oscuro del panel de adultos (docentes/admins).
  /// Envuelve las pantallas del panel con `Theme(data: AppTheme.dark, ...)`
  /// para que inputs, botones y snackbars hereden la paleta oscura.
  static ThemeData get dark {
    const accent = ArcobotPanelColors.accent;

    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
    ).copyWith(
      primary: accent,
      onPrimary: ArcobotPanelColors.onAccent,
      secondary: ArcobotColors.skyBlue,
      surface: ArcobotPanelColors.card,
      onSurface: ArcobotPanelColors.textOnDark,
      outline: ArcobotPanelColors.border,
      error: ArcobotPanelColors.errorText,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: ArcobotPanelColors.bg,
      fontFamily: 'Nunito',
      cardTheme: const CardThemeData(
        color: ArcobotPanelColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: ArcobotPanelColors.border, width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ArcobotPanelColors.input,
        hintStyle: const TextStyle(
          color: ArcobotPanelColors.hint,
          fontSize: 13,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: ArcobotPanelColors.border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: accent, width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: ArcobotPanelColors.onAccent,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: ArcobotPanelColors.input,
          foregroundColor: ArcobotPanelColors.subtle,
          side: const BorderSide(color: ArcobotPanelColors.border, width: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ArcobotPanelColors.input,
        contentTextStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: ArcobotPanelColors.textOnDark,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: ArcobotPanelColors.border,
        thickness: 1,
      ),
    );
  }
}
