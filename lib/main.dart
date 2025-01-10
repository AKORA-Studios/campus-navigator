import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'ui/screens/search_screen.dart';
import 'ui/styling.dart';

void main() {
  runApp(const MyApp());
}

final colorScheme = ColorScheme.fromSeed(
    seedColor: Colors.deepPurple, brightness: Brightness.light);

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Navigator',
      theme: AppTheme.themeData(AppTheme.lightColorScheme),
      darkTheme: AppTheme.themeData(AppTheme.darkColorScheme),
      debugShowCheckedModeBanner: false,
      home: const SearchScreen(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const [Locale('en'), Locale('de')],
    );
  }
}
