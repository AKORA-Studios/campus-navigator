import 'package:flutter/material.dart';

class Styling {
  static const primaryColor = Color(0xff51bcb6);
  static const secondaryColor = Color(0xff6da4ce);

  static const settingsHeadingStyle =
      TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: primaryColor);

  static final settingsSegmentedButtonStyle = ButtonStyle(
      backgroundColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return Styling.primaryColor;
        } else {
          return Colors.transparent;
        }
      }),
      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
        const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16.0)),
        ),
      ),
      alignment: Alignment.center);

  static desctructiveButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.error,
        foregroundColor: Colors.black);
  }
}

class AppTheme {
  static ThemeData themeData(ColorScheme colorScheme) {
    return ThemeData(
        colorScheme: colorScheme,
        canvasColor: colorScheme.surface,
        scaffoldBackgroundColor: colorScheme.surface,
        appBarTheme: const AppBarTheme(elevation: 0, scrolledUnderElevation: 0),
        dividerTheme: DividerThemeData(color: colorScheme.outlineVariant),
        highlightColor: Colors.transparent,
        useMaterial3: true,
        focusColor: const Color(0xff88ccb4),
        sliderTheme: SliderThemeData.fromPrimaryColors(
            primaryColor: colorScheme.primary,
            primaryColorDark: darkColorScheme.primary,
            primaryColorLight: lightColorScheme.primary,
            // This should maybe be onPrimary?
            valueIndicatorTextStyle: const TextStyle(color: Colors.white)));
  }

  // One restrained accent; all foreground/background pairs are opaque.
  static final lightColorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xff006c68),
    brightness: Brightness.light,
  ).copyWith(
      surface: const Color(0xfffafbfb),
      onSurface: const Color(0xff20292d),
      primary: const Color(0xff006c68),
      onPrimary: Colors.white);

  static final darkColorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xff006c68),
    brightness: Brightness.dark,
  ).copyWith(
      surface: const Color(0xff20282d),
      onSurface: const Color(0xffedf1f3),
      primary: const Color(0xff8bd2c9),
      onPrimary: const Color(0xff003733));
}
