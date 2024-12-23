import 'package:flutter/material.dart';

class Styling {
  static const primaryColor = Color(0xff51bcb6);
  static const secondaryColor = Color(0xff6da4ce);
}

class AppTheme {
  static ThemeData themeData(ColorScheme colorScheme) {
    return ThemeData(
        colorScheme: colorScheme,
        canvasColor: colorScheme.background,
        scaffoldBackgroundColor: colorScheme.background,
        highlightColor: Colors.transparent,
        useMaterial3: true,
        focusColor: Color(0xff88ccb4));
  }

  static const ColorScheme lightColorScheme = ColorScheme(
    primary: Styling.primaryColor,
    onPrimary: Color(0xFFD8F1F1),
    secondary: Styling.secondaryColor,
    onSecondary: Color(0xff424242),
    error: Colors.redAccent,
    onError: Colors.white,
    background: Color(0xFFFFFFFF),
    onBackground: Colors.white,
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
