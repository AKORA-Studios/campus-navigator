# Einstellungen und Sprachwahl

## Zuständigkeit und Integration

Dieser Branch enthält den Einstellungsbildschirm, persistente Einstellungsdaten,
Cache-Wartung und deren Tests. Der UI-Branch `feature/ui-refinement` besitzt
`main.dart`, die bestehenden Screens und sämtliche ARB-Kataloge. Die beiden
Branches bleiben getrennt; diese Datei ist der Integrationsvertrag.

### Root-App

Erzeuge den Controller vor `runApp`, damit gespeicherte Präferenzen vor dem
ersten Frame geladen werden. `AppSettingsScope` muss oberhalb der
`MaterialApp` liegen:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = AppSettingsController();
  await settings.load();
  runApp(AppSettingsScope(
    controller: settings,
    child: const MyApp(),
  ));
}
```

Die `MaterialApp` verwendet `AppSettingsScope.of(context).themeMode` als
`themeMode`, `.locale` als `locale` und `AppLocalizations.supportedLocales` als
`supportedLocales`. `null` bei `locale` folgt der Gerätesprache. Der Callback
kanonisiert Geräte-Locale-Werte und fällt für nicht unterstützte Sprachen auf
Englisch zurück. Ein explizites Standard-Skript einer unterstützten Sprache,
etwa `de-Latn-DE` oder `ar-Arab-SA`, verwendet den vorhandenen Sprachkatalog.
Skripte mit eigener Katalogbedeutung bleiben spezifisch: `zh` wird zu
`zh-Hans`, während das nicht angebotene `zh-Hant` auf Englisch zurückfällt:

```dart
localeResolutionCallback: (deviceLocale, _) =>
    AppSettingsController.resolveLocale(deviceLocale),
```

Damit bleibt `zh-Hans` vereinfachtes Chinesisch. Die unterstützten ARB-Sprachen
sind Deutsch, Englisch, Französisch,
Spanisch, Italienisch, Portugiesisch, Polnisch, Russisch, Türkisch, Arabisch,
Hindi, vereinfachtes Chinesisch, Japanisch und Koreanisch.

### Einstieg in die Einstellungen

Die Suche und der Einstellungsbildschirm müssen dieselbe `PlaceStore`-Instanz
verwenden. In `SearchScreen` muss die Route lauten:

```dart
MaterialPageRoute<void>(
  builder: (_) => SettingsScreen(places: _places),
)
```

So aktualisiert „Suchverlauf löschen“ genau den Verlauf, den Suche, Favoriten
und Verlauf bereits beobachten. Ohne `places` wird die Verlaufsaktion nicht
angezeigt.

### Campuskarte

`CampusMapScreen` liest `campusMapThemeMode` aus demselben Controller.
`automatic` folgt der effektiven Helligkeit des App-Themes; `light` und `dark`
setzen nur den Stil der Campuskarte. Der Etagenplan-Renderer bleibt unverändert.

Die UI-Integration liest `AppSettingsScope.of(context).campusIdentityStyle`.
`AppCampusIdentityStyle.academic` wählt den Entwurf Option A und ist der
Standard; `AppCampusIdentityStyle.wayfinding` wählt Option B. Beide
Campus-Identity-Entwürfe bleiben erreichbar. Die Einstellung wird sofort im
Controller aktualisiert und über Neustarts gespeichert.

## Controller- und Speichervertrag

`lib/settings/app_settings_controller.dart` enthält Modell, unterstützte
Sprachen, Speicheradapter und `AppSettingsController`. Der Standardadapter
verwendet das vorhandene `FlutterSecureStorage`; Tests können `AppSettingsStore`
mit einem In-Memory-Store ersetzen.

| Einstellung | Schlüssel | Standard |
| --- | --- | --- |
| App-Theme | `AppThemeMode` | `system` |
| Campus-Kartenstil | `CampusMapThemeMode` | `automatic` |
| Campus Identity | `CampusIdentityStyle` | `academic` (Option A) |
| Sprache | `AppLocale` | nicht gespeichert (`null` = Gerät) |

Ungültige Werte werden zu System-Theme, automatischem Kartenstil, Campus
Identity Option A oder Gerätesprache. `academic` bezeichnet Option A,
`wayfinding` Option B. `restoreAppearanceDefaults()` entfernt nur diese vier
Schlüssel und stellt damit Option A als Standard wieder her.
Das löscht keine Zugangsdaten, Favoriten oder den Verlauf. Neue Controller
laden mit `await controller.load()`; Setter speichern seriell und benachrichtigen
abhängige Widgets unmittelbar.

`Storage` fängt nun außerdem beschädigte Werte der bereits vorhandenen
Netzwerkoptionen ab. Standards sind Cache-Dauer ein Tag, Prefetching des ersten
Ergebnisses, Qualitätsstufe 4 und Universität TUD.

## Lokale Daten und Cache

`CacheMaintenance` behandelt temporäre Ressourcencaches separat von
Nutzerdaten. „Cache leeren“ ruft `emptyCache()` für `DefaultCacheManager`, den
OSM-Kachelcache `campusOsmTilesV1` und den Gebäudedatencache
`campusBuildingsV1` auf. Es versucht alle drei Stores auch dann zu leeren, wenn
einer fehlschlägt, und meldet Teilerfolge als Fehler. Die Speicheranzeige
summiert Dateien dieser drei Cache-Verzeichnisse im temporären Ordner; wenn der
Ordner nicht lesbar ist, wird „nicht verfügbar“ angezeigt.

Favoriten, Verlauf, verschlüsselte Zugangsdaten und App-Einstellungen liegen
außerhalb dieser Cache-Manager. Die Verlaufsaktion ruft ausschließlich
`PlaceStore.clearHistory()` auf, das Favoriten erhält.

Kann Secure Storage Nutzername, Passwort oder Hochschulauswahl nicht lesen,
bleibt die Anmeldungseinstellung gesperrt. Damit kann ein leeres oder
unvollständiges Formular keine vorhandenen Zugangsdaten überschreiben; die
übrigen gespeicherten Optionen werden weiterhin mit ihren sicheren
Standardwerten geladen.

## Übersetzungsschlüssel und Dateibesitz

Die ARB-Kataloge gehören zum UI-Branch. Für die neuen Einstellungszeilen liest
`SettingsScreen` die in diesem Branch abgestimmten Getter dynamisch; bis die
ARB-Kataloge zusammen integriert werden, verwendet es verständliche englische
Fallbacktexte. Beim Zusammenführen müssen alle unten aufgelisteten Schlüssel in
allen 14 Katalogen vorhanden sein:

```text
settingsAppearanceTitle, settingsThemeTitle, settingsThemeSystem,
settingsThemeLight, settingsThemeDark, settingsLanguageTitle,
settingsLanguageSystem, settingsMapThemeTitle, settingsMapThemeAutomatic,
settingsMapThemeLight, settingsMapThemeDark, settingsDataTitle,
settingsCacheSize, settingsCacheUnavailable, settingsClearCache,
settingsClearCacheDescription, settingsClearHistory,
settingsClearHistoryDescription, settingsCancel, settingsConfirm,
settingsAboutTitle, settingsVersion, settingsUnofficialNotice,
settingsSources, settingsRepository, settingsLicenses, settingsRestoreDefaults,
settingsRestoreDefaultsDescription, settingsCacheActionSuccess,
settingsCacheActionFailure, settingsHistoryActionSuccess,
settingsHistoryActionFailure, settingsSaveFailure, settingsCacheBytesUnit,
settingsCacheKilobytesUnit, settingsCacheMegabytesUnit,
settingsLocalDataTitle, settingsLocalDataDescription,
settingsDataSourcesDescription, settingsShowPassword, settingsHidePassword,
settingsCredentialsLoadFailure, settingsIdentityStyleTitle,
settingsIdentityAcademic, settingsIdentityWayfinding
```

Der UI-Branch lokalisiert zusätzlich alle bestehenden Screens, die bereits
vorhandenen Einstellungsfelder und die drei Campus-Identity-Schlüssel in
denselben 14 ARB-Katalogen.

## App-Informationen und Rechtehinweise

Die Einstellungsseite zeigt Paketversion und Buildnummer, öffnet die
Abhängigkeitslizenzen mit Flutter `showLicensePage` und verweist auf
`https://github.com/Infinizius/campus-navigator`. Die Quellenangabe nennt
`navigator.tu-dresden.de` für Campus- und Grundrissdaten sowie
OpenStreetMap-Mitwirkende für Kartenkacheln. Die App wird als inoffizielles
Community-Projekt beschrieben; die Rechte am ursprünglichen AKORA-Code und an
TU-Grundrissdaten werden ausdrücklich als ungeklärt bezeichnet.

## Frühere Android-Nachweise aus dem Settings-Branch

Die folgenden Screenshots stammen aus dem eigenständigen Settings-Branch vor
der Root-App-Integration. Sie dokumentieren den Einstellungsbildschirm,
Persistenz nach Prozessneustart, Cache-Leeren und den Erhalt von Favoriten und
Verlauf. Sie belegen nicht die Integration in die aktuelle Root-App; dafür
gelten die aktuellen Tests und Emulatorprüfungen des Release-Kandidaten.

- [`settings-main-portrait.png`](settings-evidence/settings-main-portrait.png)
- [`settings-system-dark.png`](settings-evidence/settings-system-dark.png)
- [`settings-after-restart.png`](settings-evidence/settings-after-restart.png)
- [`language-options.png`](settings-evidence/language-options.png)
- [`data-cache.png`](settings-evidence/data-cache.png)
- [`local-data-actions.png`](settings-evidence/local-data-actions.png)
- [`clear-cache-dialog.png`](settings-evidence/clear-cache-dialog.png)
- [`cache-cleared.png`](settings-evidence/cache-cleared.png)
- [`favorites-after-cache-clear.png`](settings-evidence/favorites-after-cache-clear.png)
- [`reset-dialog.png`](settings-evidence/reset-dialog.png)
