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

  @override
  void initState() {
    super.initState();
    setState(() {
      username = Storage.Shared.username;
      password = Storage.Shared.password;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Open in Web',
              onPressed: () {},
            ),
          ],
        ),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(10.0),
            child: Column(children: [
              Text("Username:"),
              TextFormField(
                initialValue: username,
                onChanged: (newValue) {
                  print(newValue);
                },
              ),
              Text("Password: "),
              ElevatedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.share),
                  label: const Text("Raumbelegungsplan ansehen")),
            ])));
  }
}
