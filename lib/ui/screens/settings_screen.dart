import 'package:campus_navigator/api/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../styling.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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

  saveData() async {
    await Storage.Shared.editUsername(_usernameController.text);
    await Storage.Shared.editpassword(_passwordController.text);
    await Storage.Shared.editUniversity(
        tudSelected ? UserUniversity.TUD : UserUniversity.HTW);

    setState(() {
      updateView = !updateView;
    });
  }

  deleteData() async {
    await Storage.Shared.editUsername("");
    await Storage.Shared.editpassword("");
    await Storage.Shared.editUniversity(UserUniversity.TUD);

    setState(() {
      updateView = !updateView;
    });
  }

  List<Widget> licenceView(localizations) {
    return settingsSection(
        title: localizations.settingsScreen_licenceSection,
        children: [
          TextButton.icon(
              onPressed: () {
                showLicensePage(
                    context: context, applicationName: "Campus Navigator");
              },
              icon: const Icon(Icons.receipt_long_outlined),
              label: Text(localizations.settingsScreen_licenceButton))
        ]);
  }

  Widget settingsHeading(String title) {
    return SizedBox(
      child: Text(title, style: Styling.settingsHeadingStyle),
    );
  }

  Widget descriptionWidget(BuildContext context, String description) {
    return RichText(
      text: TextSpan(
        children: [
          WidgetSpan(
            child: Icon(Icons.info,
                size: 15,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(150)),
          ),
          const WidgetSpan(child: SizedBox(width: 5)),
          TextSpan(
            text: description,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(150)),
          ),
        ],
      ),
    );
  }

  List<Widget> settingsSection(
      {required String title,
      String? description,
      required List<Widget> children}) {
    if (description != null) {
      children = [
        descriptionWidget(context, description),
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

  List<Widget> cacheSettingsSection(localizations) {
    return settingsSection(
        title: localizations.settingsScreen_cacheSectionTitle,
        description: localizations.settingsScreen_cacheDescription,
        children: [
          SegmentedButton<CacheDuration>(
            multiSelectionEnabled: false,
            showSelectedIcon: false,
            style: Styling.settingsSegmentedButtonStyle,
            segments: <ButtonSegment<CacheDuration>>[
              ButtonSegment<CacheDuration>(
                value: CacheDuration.day,
                label: Column(
                  children: [
                    const Icon(Icons.calendar_view_day),
                    Text(localizations.settingsScreen_optionDay),
                  ],
                ),
              ),
              ButtonSegment<CacheDuration>(
                value: CacheDuration.week,
                label: Column(
                  children: [
                    const Icon(Icons.calendar_view_week),
                    Text(localizations.settingsScreen_optionWeek),
                  ],
                ),
              ),
              ButtonSegment<CacheDuration>(
                value: CacheDuration.month,
                label: Column(
                  children: [
                    const Icon(Icons.calendar_view_month),
                    Text(localizations.settingsScreen_optionMonth),
                  ],
                ),
              ),
              ButtonSegment<CacheDuration>(
                value: CacheDuration.year,
                label: Column(
                  children: [
                    const Icon(Icons.calendar_today),
                    Text(localizations.settingsScreen_optionYear),
                  ],
                ),
              ),
            ],
            selected: <CacheDuration>{cacheDuration},
            onSelectionChanged: (Set<CacheDuration> newSelection) async {
              Storage.Shared.setCacheDuration(newSelection.first);

              setState(() {
                cacheDuration = newSelection.first;
              });
            },
          ),
          const SizedBox(height: 15),
          desctructiveDialogButton(context,
              title: localizations.settingsScreen_cacheEmptyTitle,
              content: localizations.settingsScreen_cacheEmptyDescription,
              confirmText: localizations.settingsScreen_cacheEmptyAction,
              onConfirm: () async {
            await DefaultCacheManager().emptyCache();
          })
        ]);
  }

  List<Widget> prefetchSection(localizations) {
    return settingsSection(
        title: localizations.settingsScreen_PrefetchingTitle,
        description: localizations.settingsScreen_PrefetchingDescription,
        children: [
          SegmentedButton<PrefetchingLevel>(
            multiSelectionEnabled: false,
            showSelectedIcon: false,
            style: Styling.settingsSegmentedButtonStyle,
            segments: <ButtonSegment<PrefetchingLevel>>[
              ButtonSegment<PrefetchingLevel>(
                  value: PrefetchingLevel.none,
                  label: Text(localizations.settingsScreen_PrefetchingNone,
                      textAlign: TextAlign.center)),
              ButtonSegment<PrefetchingLevel>(
                  value: PrefetchingLevel.firstResult,
                  label: Text(localizations.settingsScreen_PrefetchingFirst,
                      textAlign: TextAlign.center)),
              ButtonSegment<PrefetchingLevel>(
                value: PrefetchingLevel.allResults,
                label: Text(localizations.settingsScreen_PrefetchingAll,
                    textAlign: TextAlign.center),
              ),
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

  List<Widget> qualityLevelSection(localizations) {
    // TODO: Show example images of the quality steps, maybe using POT background
    return settingsSection(
        title: localizations.settingsScreen_QualityLevelTitle,
        description: localizations.settingsScreen_QualityLevelDescription,
        children: [
          Slider.adaptive(
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

  List<Widget> settingsForm(localizations) {
    return [
      ...settingsSection(
          title: localizations.settingsScreen_LoginTitle,
          description: localizations.settingsScreen_LoginDescription,
          children: [
            TextField(
              maxLines: 1,
              autocorrect: false,
              controller: _usernameController,
              decoration: InputDecoration(
                  labelText: localizations.settingsScreen_LoginUsername,
                  hintText:
                      localizations.settingsScreen_LoginUsernameDescription),
            ),
            TextField(
              maxLines: 1,
              autocorrect: false,
              obscureText: passwordInvisible,
              controller: _passwordController,
              decoration: InputDecoration(
                  hintText: localizations.settingsScreen_LoginPasswordHint,
                  labelText: localizations.settingsScreen_LoginPassword,
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
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(localizations.settingsScreen_University),
                SegmentedButton(
                  showSelectedIcon: false,
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
                  style: Styling.settingsSegmentedButtonStyle,
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
                    child: Text(localizations.settingsScreen_LoginUpdate)),
                desctructiveDialogButton(context,
                    title: localizations.settingsScreen_LoginDelete,
                    content:
                        localizations.settingsScreen_LoginDeleteDescription,
                    confirmText:
                        localizations.settingsScreen_LoginDeleteConfirmation,
                    onConfirm: () async {
                  await deleteData();
                })
              ],
            ),
          ]),
      ...cacheSettingsSection(localizations),
      ...prefetchSection(localizations),
      ...qualityLevelSection(localizations),
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
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(localizations.settingsScreen_Title),
        ),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(15.0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ...settingsForm(localizations),
              ...licenceView(localizations),
              Center(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [const Text("App version"), Text(appVersion)],
              ))
            ])));
  }
}

Widget desctructiveDialogButton(BuildContext context,
    {required String title,
    required String content,
    String abortText = "Abbrechen",
    String confirmText = "Bestätigen",
    Future<void> Function()? onConfirm}) {
  return ElevatedButton.icon(
      style: Styling.desctructiveButtonStyle(context),
      onPressed: () {
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog.adaptive(
                title: Text(title),
                content: Text(content),
                actions: [
                  TextButton(
                    child: Text(abortText),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    style: Styling.desctructiveButtonStyle(context),
                    child: Text(confirmText),
                    onPressed: () async {
                      if (onConfirm != null) {
                        await onConfirm();
                      }
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            });
      },
      icon: const Icon(Icons.delete),
      label: Text(title));
}
