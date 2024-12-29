import 'package:campus_navigator/api/storage.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Styling.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key, required this.name});

  final String name;

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool tudSelected = true;

  bool passwordInvisible = true;
  bool updateView = false;

  CacheDuration cacheDuration = CacheDuration.day;

  String appVersion = "?.?.? (?.?)";

  @override
  void initState() {
    super.initState();

    (() async {
      final usernameValue = await Storage.Shared.getUsername();

      final passwordValue = await Storage.Shared.getPassword();
      final tudSelectedValue = await Storage.Shared.getUniversity();

      final cacheDurationValue = await Storage.Shared.getCacheDuration();

      final packageInfo = await PackageInfo.fromPlatform();
      // String appName = packageInfo.appName;
      // String packageName = packageInfo.packageName;
      String version = packageInfo.version;
      String buildNumber = packageInfo.buildNumber;

      setState(() {
        _usernameController.text = usernameValue ?? "";
        _passwordController.text = passwordValue ?? "";

        tudSelected = tudSelectedValue == "1";

        cacheDuration = cacheDurationValue;

        appVersion = version + "(" + buildNumber + ")";
      });
    })();
  }

  String get username => _usernameController.text;
  String get password => _passwordController.text;

  void saveData() async {
    await Storage.Shared.editUsername(_usernameController.text);
    await Storage.Shared.editpassword(_passwordController.text);
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
    "maps_toolkit": "https://pub.dev/packages/maps_toolkit/license",
    "package_info_plus": "https://pub.dev/packages/package_info_plus/license"
  };

  Widget licenceView() {
    List<Widget> childs = [];

    childs.add(settingsHeading("Dependencies licences"));

    for (String key in licences.keys) {
      childs.add(SelectableText.rich(TextSpan(children: [
        TextSpan(
            text: key,
            style: const TextStyle(
                decorationColor: Styling.primaryColor,
                decoration: TextDecoration.underline),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                openLicence(licences[key]!);
              }),
      ])));
    }
    childs.add(const SizedBox(height: 20));
    childs.add(const Text("Powerd by Flutter"));
    return Column(children: childs);
  }

  void openLicence(String url) async {
    final Uri _url = Uri.parse(url);
    if (!await launchUrl(_url)) {
      launchUrl(_url);
    }
  }

  Widget settingsHeading(String title) {
    return SizedBox(
      child: Text(title, style: Styling.settingsHeadingStyle),
    );
  }

  List<Widget> settingsSection(
      {required String title,
      String? description,
      required List<Widget> children}) {
    if (description != null) {
      children.insert(0, Text(description));
      children.insert(1, const SizedBox(height: 10));
    }

    return [
      settingsHeading(title),
      Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children),
      ),
      const SizedBox(height: 10)
    ];
  }

  MaterialStateProperty<Color?> backgroundColorProperty() {
    return MaterialStateProperty.resolveWith((states) {
      if (states.firstOrNull == MaterialState.selected) {
        return Styling.primaryColor;
      } else {
        return Colors.transparent;
      }
    });
  }

  List<Widget> settingsForm() {
    return [
      ...settingsSection(
          title: "Anmeldedaten",
          description: "ZIH Login Daten zum abrufen des Raumbelegungsplans",
          children: [
            TextField(
              maxLines: 1,
              autocorrect: false,
              controller: _usernameController,
              decoration: const InputDecoration(
                  labelText: 'Benutzername',
                  hintText: 'Neuen Benutzernamen hier eingeben'),
            ),
            TextField(
              maxLines: 1,
              autocorrect: false,
              obscureText: passwordInvisible,
              controller: _passwordController,
              decoration: InputDecoration(
                  hintText: 'Neues Passwort hier eingeben',
                  labelText: 'Passwort',
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
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text("Ausgewählte Universität: "),
                const SizedBox(
                  width: 20,
                ),
                SegmentedButton(
                  segments: const [
                    ButtonSegment(
                      value: true,
                      label: Text("TUD"),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text("HTW"),
                    )
                  ],
                  selected: <bool>{tudSelected},
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      ),
                    ),
                  ),
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      tudSelected = newSelection.first;
                    });
                  },
                )
              ],
            ),
          ]),
      const SizedBox(height: 20),
      ...settingsSection(
          title: "Cache Duration",
          description:
              'This controls for how long search resulst should be cached, selecting longer durations reduces data usage and improves perfomance but might lead to inaccurate results',
          children: [
            SegmentedButton<CacheDuration>(
              multiSelectionEnabled: false,
              style: ButtonStyle(backgroundColor: backgroundColorProperty()),
              segments: const <ButtonSegment<CacheDuration>>[
                ButtonSegment<CacheDuration>(
                    value: CacheDuration.day,
                    label: Text('Day'),
                    icon: Icon(Icons.calendar_view_day)),
                ButtonSegment<CacheDuration>(
                    value: CacheDuration.week,
                    label: Text('Week'),
                    icon: Icon(Icons.calendar_view_week)),
                ButtonSegment<CacheDuration>(
                    value: CacheDuration.month,
                    label: Text('Month'),
                    icon: Icon(Icons.calendar_view_month)),
                ButtonSegment<CacheDuration>(
                    value: CacheDuration.year,
                    label: Text('Year'),
                    icon: Icon(Icons.calendar_today)),
              ],
              selected: <CacheDuration>{cacheDuration},
              onSelectionChanged: (Set<CacheDuration> newSelection) async {
                await Storage.Shared.setCacheDuration(newSelection.first);

                setState(() {
                  cacheDuration = newSelection.first;
                });
              },
            ),
          ]),
      const SizedBox(height: 30),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
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
              child: const Text("Daten löschen"))
        ],
      ),
    ];
  }

  List<Widget> sectionSpacing() {
    return [
      const SizedBox(height: 20),
      const Divider(),
      const SizedBox(height: 20),
    ];
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
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ...settingsForm(),
              ...sectionSpacing(),
              licenceView(),
              ...sectionSpacing(),
              const Text("App version"),
              Text(appVersion)
            ])));
  }
}
