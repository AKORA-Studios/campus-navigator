import 'package:flutter/material.dart';

class Styling {
  static const primaryColor = Color(0xff51bcb6);
  static const secondaryColor = Color(0xff6da4ce);

  static const settingsHeadingStyle =
      TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: primaryColor);

  static final settingsSegmentedButtonStyle = ButtonStyle(
      backgroundColor: MaterialStateProperty.resolveWith((states) {
        if (states.firstOrNull == MaterialState.selected) {
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
}

class AppTheme {
  static ThemeData themeData(ColorScheme colorScheme) {
    return ThemeData(
        colorScheme: colorScheme,
        canvasColor: colorScheme.background,
        scaffoldBackgroundColor: colorScheme.background,
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

  static const ColorScheme lightColorScheme = ColorScheme(
    primary: Styling.primaryColor,
    onPrimary: Color(0xFFD8F1F1),
    secondary: Styling.secondaryColor,
    onSecondary: Color(0xff424242),
    error: Colors.redAccent,
    onError: Colors.white,
    background: Color(0xFFFFFFFF),
    onBackground: Colors.grey,
    surface: Color(0xFFFAFBFB),
    onSurface: Color(0xFF545454),
    brightness: Brightness.light,
  );

  static const ColorScheme darkColorScheme = ColorScheme(
    primary: Styling.primaryColor,
    secondary: Styling.secondaryColor,
    background: Color(0xFF0E0E0E),
    surface: Color(0xFF1E1E1E),
    onBackground: Color(0x5ABBBBBB),
    error: Colors.redAccent,
    onError: Colors.white,
    onPrimary: Color(0x34606060),
    onSecondary: Colors.white,
    onSurface: Colors.white,
    brightness: Brightness.dark,
  );
}
