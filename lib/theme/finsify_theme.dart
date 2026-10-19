import 'package:flutter/material.dart';

@immutable
class FinsifyColors extends ThemeExtension<FinsifyColors> {
  const FinsifyColors({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceInset,
    required this.outline,
    required this.primaryText,
    required this.secondaryText,
    required this.accent,
    required this.onAccent,
    required this.accentContainer,
    required this.chartStart,
    required this.chartEnd,
    required this.chartBaseline,
  });

  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceInset;
  final Color outline;
  final Color primaryText;
  final Color secondaryText;
  final Color accent;
  final Color onAccent;
  final Color accentContainer;
  final Color chartStart;
  final Color chartEnd;
  final Color chartBaseline;

  static const light = FinsifyColors(
    background: Color(0xFFF8FAFD),
    surface: Colors.white,
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceInset: Color(0xFFF0F3F9),
    outline: Color(0xFFE0E5EC),
    primaryText: Color(0xFF0C1830),
    secondaryText: Color(0xFF52647B),
    accent: Color(0xFF5547D9),
    onAccent: Colors.white,
    accentContainer: Color(0xFFEAE6FF),
    chartStart: Color(0xFFB496E3),
    chartEnd: Color(0xFF6547A9),
    chartBaseline: Color(0xFFC8D6E2),
  );

  static const dark = FinsifyColors(
    background: Color(0xFF071522),
    surface: Color(0xFF102238),
    surfaceRaised: Color(0xFF142A42),
    surfaceInset: Color(0xFF0D1D31),
    outline: Color(0xFF1B3855),
    primaryText: Color(0xFFF1F6FD),
    secondaryText: Color(0xFF9BAFC7),
    accent: Color(0xFF09B8F0),
    onAccent: Color(0xFF061521),
    accentContainer: Color(0xFF173B51),
    chartStart: Color(0xFF63D5F7),
    chartEnd: Color(0xFF1687B3),
    chartBaseline: Color(0xFF35516A),
  );

  @override
  FinsifyColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceInset,
    Color? outline,
    Color? primaryText,
    Color? secondaryText,
    Color? accent,
    Color? onAccent,
    Color? accentContainer,
    Color? chartStart,
    Color? chartEnd,
    Color? chartBaseline,
  }) {
    return FinsifyColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceInset: surfaceInset ?? this.surfaceInset,
      outline: outline ?? this.outline,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      accentContainer: accentContainer ?? this.accentContainer,
      chartStart: chartStart ?? this.chartStart,
      chartEnd: chartEnd ?? this.chartEnd,
      chartBaseline: chartBaseline ?? this.chartBaseline,
    );
  }

  @override
  FinsifyColors lerp(ThemeExtension<FinsifyColors>? other, double t) {
    if (other is! FinsifyColors) return this;
    return FinsifyColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceInset: Color.lerp(surfaceInset, other.surfaceInset, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      accentContainer: Color.lerp(accentContainer, other.accentContainer, t)!,
      chartStart: Color.lerp(chartStart, other.chartStart, t)!,
      chartEnd: Color.lerp(chartEnd, other.chartEnd, t)!,
      chartBaseline: Color.lerp(chartBaseline, other.chartBaseline, t)!,
    );
  }
}

extension FinsifyThemeContext on BuildContext {
  FinsifyColors get finsifyColors =>
      Theme.of(this).extension<FinsifyColors>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? FinsifyColors.dark
          : FinsifyColors.light);
}

ThemeData buildFinsifyTheme({required bool dark}) {
  final palette = dark ? FinsifyColors.dark : FinsifyColors.light;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: palette.accent,
        brightness: dark ? Brightness.dark : Brightness.light,
      ).copyWith(
        primary: palette.accent,
        onPrimary: palette.onAccent,
        secondary: palette.accent,
        onSecondary: palette.onAccent,
        surface: palette.surface,
        onSurface: palette.primaryText,
        outline: palette.outline,
        error: dark ? const Color(0xFFFF8A80) : const Color(0xFFB3261E),
      );

  return ThemeData(
    brightness: dark ? Brightness.dark : Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: palette.background,
    cardColor: palette.surface,
    dividerColor: palette.outline,
    useMaterial3: true,
    extensions: [palette],
    appBarTheme: AppBarTheme(
      backgroundColor: palette.surface,
      foregroundColor: palette.primaryText,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: palette.primaryText,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: TextStyle(color: palette.primaryText),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surfaceInset,
      labelStyle: TextStyle(color: palette.secondaryText),
      hintStyle: TextStyle(color: palette.secondaryText),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: palette.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: palette.accent, width: 1.5),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.surfaceRaised,
      contentTextStyle: TextStyle(color: palette.primaryText),
      behavior: SnackBarBehavior.floating,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: palette.accent,
      selectionColor: palette.accent.withValues(alpha: 0.28),
      selectionHandleColor: palette.accent,
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(animationDuration: const Duration(milliseconds: 180)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(animationDuration: const Duration(milliseconds: 180)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(animationDuration: const Duration(milliseconds: 180)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(animationDuration: const Duration(milliseconds: 180)),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(animationDuration: const Duration(milliseconds: 180)),
    ),
  );
}
