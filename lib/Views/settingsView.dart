import 'package:campus_navigator/api/storage.dart';
import 'package:flutter/material.dart';

class SettingsView extends StatefulWidget {
  SettingsView({super.key, required this.name});

  final String name;

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  String username = "";
  String password = "";
  bool passwordInvisible = true;

  @override
  void initState() {
    super.initState();

    Storage().getUsername().then((value) {
      setState(() {
        username = value ?? "";
      });
    });
    Storage().getPassword().then((value) {
      setState(() {
        password = value ?? "";
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.name),
        ),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(10.0),
            child: Column(children: [
              Text("Username: ${Storage.Shared.username}"),
              TextField(
                decoration: const InputDecoration(
                    hintText: 'Neuen benutznamen hier eingeben'),
                onChanged: (newValue) {
                  print(newValue);
                },
              ),
              TextField(
                obscureText: passwordInvisible,
                decoration: const InputDecoration(
                    hintText: 'Neues Password hier eingeben'),
                onChanged: (newValue) {
                  print(newValue);
                },
              ),
              Text("Password: "),
              ElevatedButton(
                  onPressed: null, child: const Text("Daten speichern")),
            ])));
  }
}
