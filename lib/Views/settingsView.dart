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
  bool updateView = false;

  @override
  void initState() {
    super.initState();

    Storage.Shared.getUsername().then((value) {
      setState(() {
        username = value ?? "";
      });
    });
    Storage.Shared.getPassword().then((value) {
      setState(() {
        password = value ?? "";
      });
    });
  }

  void saveData() async {
    await Storage.Shared.editUsername(username);
    await Storage.Shared.editpassword(password);
    setState(() {
      updateView = !updateView;
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
              TextField(
                maxLines: 1,
                autocorrect: false,
                decoration: const InputDecoration(
                    labelText: 'Benutzername',
                    hintText: 'Neuen Benutzernamen hier eingeben'),
                onChanged: (newValue) {
                  username = newValue;
                },
              ),
              TextField(
                maxLines: 1,
                autocorrect: false,
                obscureText: passwordInvisible,
                decoration: InputDecoration(
                    hintText: 'Neues Passwort hier eingeben',
                    labelText: 'Passwort ${password.length}',
                    // this button is used to toggle the password visibility
                    suffixIcon: IconButton(
                        icon: Icon(passwordInvisible
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            passwordInvisible = !passwordInvisible;
                          });
                        })),
                onChanged: (newValue) {
                  password = newValue;
                },
              ),
              Padding(padding: EdgeInsets.all(10)),
              ElevatedButton(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    saveData();
                  },
                  child: const Text("Daten aktualisieren")),
            ])));
  }
}
