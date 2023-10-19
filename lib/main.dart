import 'package:flutter/material.dart';
import 'package:flutter_testy/form.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const FirstPage(),
    );
  }
}

class FirstPage extends StatelessWidget {
  const FirstPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Uno'),
      ),
      body: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[MyCustomForm()],
      ),
    );
  }
}

class SecondPage extends StatelessWidget {
  final String data;

  const SecondPage({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Des'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text(
            'Pageee deees',
            style: TextStyle(fontSize: 50),
          ),
          ElevatedButton(
              child: const Text('Go to pagee des'),
              onPressed: () {
                Navigator.of(context).pop();
              })
        ],
      ),
    );
  }
}
