import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'ui/screens/home_screen.dart';
import 'settings/app_settings_controller.dart';
import 'settings/app_settings_scope.dart';
import 'ui/campus_identity.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = AppSettingsController();
  await settings.load();
  runApp(MyApp(settings: settings));
}

class MyApp extends StatefulWidget {
  final AppSettingsController? settings;
  const MyApp({super.key, this.settings});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppSettingsController _settings;
  @override
  void initState() {
    super.initState();
    _settings = widget.settings ?? AppSettingsController();
    if (!_settings.loaded) _settings.load();
  }

  @override
  void dispose() {
    if (widget.settings == null) _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppSettingsScope(
        controller: _settings,
        child: const _CampusApp(),
      );
}

class _CampusApp extends StatelessWidget {
  const _CampusApp();

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    return MaterialApp(
      title: 'Campus Navigator',
      theme: CampusIdentity.themeData(Brightness.light),
      darkTheme: CampusIdentity.themeData(Brightness.dark),
      themeMode: settings.themeMode,
      locale: settings.locale,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppSettingsController.supportedLocales,
      localeResolutionCallback: (locale, _) =>
          AppSettingsController.resolveLocale(locale),
    );
  }
}
