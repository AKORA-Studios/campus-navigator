import 'package:campus_navigator/search_view.dart';
import 'package:flutter/material.dart';

import 'Styling.dart';

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
      title: 'Test',
      theme: ThemeData(colorScheme: colorScheme),
      home: const FirstPage(),
    );
  }
}

class FirstPage extends StatelessWidget {
  const FirstPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData(AppTheme.lightColorScheme),
      darkTheme: AppTheme.themeData(AppTheme.darkColorScheme),
      home: const MyCustomForm(),
    );
  }
}
