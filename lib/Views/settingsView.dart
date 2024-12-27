import 'package:campus_navigator/api/storage.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Styling.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key, required this.name});

  final String name;

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  String username = "";
  String password = "";
  bool tudSelected = true;

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
    Storage.Shared.getUniversity().then((value) {
      setState(() {
        tudSelected = value == "1";
      });
    });
  }

  void saveData() async {
    await Storage.Shared.editUsername(username);
    await Storage.Shared.editpassword(password);
    await Storage.Shared.editUniversity(tudSelected ? "1" : "2");

    setState(() {
      updateView = !updateView;
    });
  }

  Map<String, String> licences = {
    "cupertino_icons": "https://pub.dev/packages/cupertino_icons/license",
    "http": "https://pub.dev/packages/http/license",
    "html": "https://pub.dev/packages/html/license",
    "share_plus": "https://pub.dev/packages/share_plus/license",
    "maps_launcher": "https://pub.dev/packages/maps_launcher/license",
    "flutter_cache_manager":
        "https://pub.dev/packages/flutter_cache_manager/license",
    "flutter_secure_storage":
        "https://pub.dev/packages/flutter_secure_storage/license",
    "flutter_launcher_icons":
        "https://pub.dev/packages/flutter_launcher_icons/license",
    "maps_toolkit": "https://pub.dev/packages/maps_toolkit/license"
  };

  Widget licenceView() {
    List<Widget> childs = [];

    childs.add(const Text(
      "Dependencies licences",
      style: TextStyle(fontWeight: FontWeight.bold),
    ));

    for (String key in licences.keys) {
      childs.add(SelectableText.rich(TextSpan(children: [
        TextSpan(
            text: key,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Styling.primaryColor,
                decorationColor: Styling.primaryColor,
                decoration: TextDecoration.underline),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                openlicence(licences[key]!);
              }),
      ])));
    }

    return Column(children: childs);
  }

  void openlicence(String url) async {
    final Uri _url = Uri.parse(url);
    if (!await launchUrl(_url)) {
      launchUrl(_url);
    }
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
                decoration: InputDecoration(
                    labelText: 'Benutzername: $username',
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Text("HTW"),
                  Switch(
                    value: tudSelected,
                    onChanged: (value) {
                      setState(() {
                        tudSelected = value;
                      });
                    },
                  ),
                  const Text("TUD"),
                ],
              ),
              const Padding(padding: EdgeInsets.all(10)),
              ElevatedButton(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    saveData();
                  },
                  child: const Text("Daten aktualisieren")),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[200],
                      foregroundColor: Colors.black),
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    saveData();
                  },
                  child: const Text("Daten löschen")),
              SizedBox(
                height: 20,
              ),
              const Divider(),
              licenceView()
            ])));
  }
}
