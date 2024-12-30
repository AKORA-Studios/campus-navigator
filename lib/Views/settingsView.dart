import 'package:campus_navigator/api/storage.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Styling.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

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
  PrefetchingLevel prefetchingLevel = PrefetchingLevel.none;
  double qualityLevel = 1;

  String appVersion = "?.?.? (?.?)";

  @override
  void initState() {
    super.initState();

    (() async {
      // The tuple is used so that the functions will be executed in parallel
      final (
        usernameValue,
        passwordValue,
        tudSelectedValue,
        cacheDurationValue,
        prefetchingLevelValue,
        qualityLevelValue,
        packageInfo
      ) = await (
        Storage.Shared.getUsername(),
        Storage.Shared.getPassword(),
        Storage.Shared.getUniversity(),
        Storage.Shared.getCacheDuration(),
        Storage.Shared.getPrefetchingLevel(),
        Storage.Shared.getQualityLevel(),
        PackageInfo.fromPlatform()
      ).wait;

      // String appName = packageInfo.appName;
      // String packageName = packageInfo.packageName;
      String version = packageInfo.version;
      String buildNumber = packageInfo.buildNumber;

      setState(() {
        _usernameController.text = usernameValue ?? "";
        _passwordController.text = passwordValue ?? "";

        tudSelected = tudSelectedValue == "1";

        cacheDuration = cacheDurationValue;
        prefetchingLevel = prefetchingLevelValue;
        qualityLevel = qualityLevelValue.toDouble();

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

  void deleteData() async {
    await Storage.Shared.editUsername("");
    await Storage.Shared.editpassword("");
    await Storage.Shared.editUniversity("1");

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

  List<Widget> licenceView() {
    List<Widget> children = [];

    for (String key in licences.keys) {
      children.add(SelectableText.rich(TextSpan(children: [
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
    children.add(const SizedBox(height: 20));
    children.add(const Text("Powerd by Flutter"));
    return settingsSection(title: "Dependencies licences", children: children);
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
      children = [
        RichText(
          text: TextSpan(
            children: [
              WidgetSpan(
                child: Icon(Icons.info,
                    size: 15,
                    color:
                        Theme.of(context).colorScheme.onSurface.withAlpha(150)),
              ),
              const WidgetSpan(child: SizedBox(width: 5)),
              TextSpan(
                text: description,
                style: TextStyle(
                    color:
                        Theme.of(context).colorScheme.onSurface.withAlpha(150)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        ...children,
      ];
    }

    return [
      settingsHeading(title),
      Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children),
      ),
      const SizedBox(height: 30)
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

  List<Widget> cacheDurationSection() {
    return settingsSection(
        title: "Cache Zeitspanne",
        description:
            'Damit wird festgelegt, wie lange die Suchergebnisse zwischengespeichert werden sollen. Die Auswahl'
            ' slängerer Zeiträume verringert den Datenverbrauch und verbessert die Leistung, kann aber zu ungenauen Ergebnissen führen.',
        children: [
          SegmentedButton<CacheDuration>(
            multiSelectionEnabled: false,
            style: ButtonStyle(backgroundColor: backgroundColorProperty()),
            segments: const <ButtonSegment<CacheDuration>>[
              ButtonSegment<CacheDuration>(
                  value: CacheDuration.day,
                  label: Text('Tag'),
                  icon: Icon(Icons.calendar_view_day)),
              ButtonSegment<CacheDuration>(
                  value: CacheDuration.week,
                  label: Text('Woche'),
                  icon: Icon(Icons.calendar_view_week)),
              ButtonSegment<CacheDuration>(
                  value: CacheDuration.month,
                  label: Text('Monat'),
                  icon: Icon(Icons.calendar_view_month)),
              ButtonSegment<CacheDuration>(
                  value: CacheDuration.year,
                  label: Text('Jahr'),
                  icon: Icon(Icons.calendar_today)),
            ],
            selected: <CacheDuration>{cacheDuration},
            onSelectionChanged: (Set<CacheDuration> newSelection) async {
              Storage.Shared.setCacheDuration(newSelection.first);

              setState(() {
                cacheDuration = newSelection.first;
              });
            },
          ),
        ]);
  }

  List<Widget> prefetchSection() {
    return settingsSection(
        title: "Prefetching",
        description:
            'Kontrolliert wie viele der Sucheregebnisse vorgeladen werden, umso mehr Ergebnisse vorgeladen werden um so höher ist die chance das der gesuchte Raum beim öffnen bereits'
            ' geladen ist (Das Laden eines ungecachten Suchergebniss transferiert ca. 30kB)',
        children: [
          SegmentedButton<PrefetchingLevel>(
            multiSelectionEnabled: false,
            style: ButtonStyle(backgroundColor: backgroundColorProperty()),
            segments: const <ButtonSegment<PrefetchingLevel>>[
              ButtonSegment<PrefetchingLevel>(
                  value: PrefetchingLevel.none,
                  label: Text('Keine'),
                  icon: Icon(Icons.not_interested)),
              ButtonSegment<PrefetchingLevel>(
                  value: PrefetchingLevel.firstResult,
                  label: Text('Erstes Ergebniss'),
                  icon: Icon(Icons.rule)),
              ButtonSegment<PrefetchingLevel>(
                  value: PrefetchingLevel.allResults,
                  label: Text('Alle Ergebnisse'),
                  icon: Icon(Icons.checklist)),
            ],
            selected: <PrefetchingLevel>{prefetchingLevel},
            onSelectionChanged: (Set<PrefetchingLevel> newSelection) async {
              Storage.Shared.setPrefetchingLevel(newSelection.first);

              setState(() {
                prefetchingLevel = newSelection.first;
              });
            },
          ),
        ]);
  }

  List<Widget> qualityLevelSection() {
    // TODO: Show example images of the quality steps, maybe using POT background
    return settingsSection(
        title: "Quality Level",
        description:
            'Entscheidet wie hoch die Auflösung der Details in der Gebäudeansicht sind, die Datennutzung steigt exponentiell mit jeder Detailstufe',
        children: [
          Slider(
            value: qualityLevel,
            min: 1,
            max: 4,
            divisions: 4,
            label: qualityLevel.round().toString(),
            onChanged: (double value) async {
              Storage.Shared.setQualityLevel(value.round());
              setState(() {
                qualityLevel = value;
              });
            },
          )
        ]);
  }

  List<Widget> settingsForm() {
    return [
      ...settingsSection(
          title: "Anmeldedaten",
          description: "ZIH Login Daten zum Abrufen des Raumbelegungsplans",
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
            const SizedBox(height: 20),
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
                      deleteData();
                    },
                    child: const Text("Daten löschen"))
              ],
            ),
          ]),
      ...cacheDurationSection(),
      ...prefetchSection(),
      ...qualityLevelSection(),
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
          title: const Text("Einstellungen"),
        ),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(10.0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ...settingsForm(),
              ...sectionSpacing(),
              ...licenceView(),
              Center(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [const Text("App version"), Text(appVersion)],
              ))
            ])));
  }
}
