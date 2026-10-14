import 'package:flutter/material.dart';
import '../settings/app_settings_controller.dart';
import '../settings/app_settings_scope.dart';

/// UI tokens only. Floor drawings retain the established AppTheme palette.
class CampusIdentity {
  static bool wayfinding(BuildContext context) =>
      AppSettingsScope.maybeOf(context)?.campusIdentityStyle ==
      AppCampusIdentityStyle.wayfinding;

  static ThemeData themeData(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final colors = ColorScheme.fromSeed(
      seedColor: const Color(0xff173657),
      brightness: brightness,
    ).copyWith(
      primary: Color(dark ? 0xffa6c9eb : 0xff173657),
      onPrimary: Color(dark ? 0xff102b45 : 0xffffffff),
      primaryContainer: Color(dark ? 0xff233e55 : 0xffe3ecf3),
      onPrimaryContainer: Color(dark ? 0xffd9e9f6 : 0xff173657),
      secondary: Color(dark ? 0xffa4bed0 : 0xff527d9b),
      surface: Color(dark ? 0xff151a20 : 0xfff5f7f8),
      surfaceContainer: Color(dark ? 0xff20272f : 0xffedf1f4),
      surfaceContainerLow: Color(dark ? 0xff1b222a : 0xffffffff),
      surfaceContainerHighest: Color(dark ? 0xff29323c : 0xffe4eaf0),
      onSurface: Color(dark ? 0xffe5ebf0 : 0xff263442),
      onSurfaceVariant: Color(dark ? 0xffb0bdc9 : 0xff526372),
      outline: Color(dark ? 0xff7c8b99 : 0xff71808e),
      outlineVariant: Color(dark ? 0xff37434f : 0xffd1dae2),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
            color: colors.onSurface, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      dividerTheme:
          DividerThemeData(color: colors.outlineVariant, thickness: 1),
      iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(minimumSize: const Size(48, 48))),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerLow,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      )),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      )),
      navigationBarTheme: NavigationBarThemeData(
          height: 64,
          backgroundColor: colors.surfaceContainerLow,
          indicatorColor: colors.primaryContainer),
      navigationRailTheme: NavigationRailThemeData(
          backgroundColor: colors.surface,
          indicatorColor: colors.primaryContainer),
    );
  }
}

/// Non-interactive wayfinding label. Codes keep their reading order in RTL.
class BuildingCodeBadge extends StatelessWidget {
  final String code;
  final bool announceCode;
  const BuildingCodeBadge(this.code, {super.key, this.announceCode = false});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return Semantics(
        label: announceCode ? code.toUpperCase() : null,
        excludeSemantics: true,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            width: 48 * scale,
            height: scale <= 1.7 ? 40 : 16 + 14 * scale,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(4)),
            child: Text(code.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.onPrimaryContainer)),
          ),
        ));
  }
}

/// Explicit action semantics also reach Android's accessibility hierarchy.
class CampusActionButton extends StatelessWidget {
  const CampusActionButton(
      {super.key,
      required this.label,
      required this.icon,
      required this.onPressed});
  final String label;
  final Widget icon;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => Semantics(
      label: label,
      button: true,
      enabled: onPressed != null,
      onTap: onPressed,
      excludeSemantics: true,
      child: IconButton(tooltip: label, icon: icon, onPressed: onPressed));
}
