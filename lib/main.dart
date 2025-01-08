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
    //   final localizations = AppLocalizations.of(context)!;

    return MaterialApp(
      title: 'Test',
      theme: AppTheme.themeData(AppTheme.lightColorScheme),
      darkTheme: AppTheme.themeData(AppTheme.darkColorScheme),
      debugShowCheckedModeBanner: false,
      home: const SearchScreen(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,

      /*localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        //    AppLocalizations.delegate, // Add this line
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],*/
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('de', 'DE'),
      ],
    );
  }
}
