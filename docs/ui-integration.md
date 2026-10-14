# Campus Identity / Settings – Integrationsvertrag

Stand 14.10.2026. Produktintegration im UI-Worktree umgesetzt und getestet.
Keine Branches zusammengeführt, kein Merge/Push. Settings-Abhängigkeiten wurden
unverändert im eigenen Feature-Branch übernommen:

| Settings-Commit | identischer Cherry-pick im UI-Branch | Inhalt |
|---|---|---|
| `7bde4ec` | `33f43cc` | persistente Einstellungen und Datenaktionen |
| `b6edc03` | `1f51dcb` | Stilwahl A/B, A Standard und Reset |
| `5fc1e44` | `3159195` | sprachunabhängige Stilwahl im Widget-Test |
| `83f3e96` | `6413f87` | explizite unterstützte Locale-Skripte |

Produkt-Code: `2178490`, Accessibility: `5ecaf5a`, Stilübersetzungen: `1ebb0fd`.
Review-Korrekturen: `ee5fd37` (Tabellen, Sheet-Höhe, Querformat-Kartenwerkzeuge).
Finaler Smartphone-Dichte-Fix: `45ecad4`.

Geprüft: 152 Tests bestanden / 26 externe Fixture-Skips; Analyze 36 bestehende
Infos ohne Fehler/Warnung (Exitcode 1); Debug-Build erfolgreich. APK:
`build/campus-navigator-campus-identity-debug.apk`, SHA-256
`A55C3F7EB7D91EC64825DD7C606A43875FA8006F3E1A9EF77BB7BAA171B3BD4B`.

## Dateibesitz

| UI-Agent: `feature/ui-refinement` | Settings-Agent: `feature/settings` |
|---|---|
| Nicht-Settings-Screens, UI-Komponenten | `settings_screen.dart` |
| alle `lib/l10n/app_*.arb` | `lib/settings/**`, Settings-Tests |
| `lib/main.dart`: abgestimmte Root-Anbindung | Settings-Persistenz/Storage |
| Hub-Settings-Route, Kartentheme-Anbindung | Cache-Verwaltung, erforderliche Pubspec-Änderungen |
| neue lokale `CampusIdentity`-Tokens | Übernahme der freigegebenen Tokens in Settings |

`lib/ui/styling.dart` bleibt für die vorhandene Zeichnungspalette zunächst
unverändert. Painter, Transformationen und Planparser werden nicht bearbeitet.
Gemeinsame Navigation (`home_screen.dart`) ist eine dokumentierte UI-Änderung.
Die UI-Palette ist in `lib/ui/campus_identity.dart` implementiert. Settings
erbt sie über MaterialApp; keine Änderung seiner Seiten durch den UI-Agenten.

## Gegen den vorhandenen Settings-Code gelesene Schnittstellen

- `AppSettingsController()`; `Future<void> load()`.
- `ThemeMode themeMode`, `Locale? locale` (null = Gerätesprache).
- `CampusMapThemeMode campusMapThemeMode`: automatic/light/dark.
- `AppCampusIdentityStyle campusIdentityStyle`: academic/wayfinding.
  `setCampusIdentityStyle(...)` speichert über den Settings-Controller.
  Academic = A ist Standard und Resetwert. Die Nutzerentscheidung verlangt
  beide wählbaren Varianten. B zeigt kompakte Gebäudecodes; vollständige
  Raum-/Gebäudenamen, IDs und die Karten-Labelbegrenzung bleiben erhalten.
- `static List<Locale> supportedLocales` und
  `static Locale resolveLocale(Locale? locale)` (Fallback Englisch,
  `zh` ohne Script wird `zh-Hans`).
- `AppSettingsScope(controller: controller, child: child)`;
  `AppSettingsScope.of(context)` und `.maybeOf(context)`.
- `SettingsScreen(places: _places)` verwendet den vorhandenen Hub-PlaceStore.

Root initialisiert Flutter-Bindings, lädt den Controller vor runApp und bindet
ThemeMode/Locale/Resolver mit einem Listener. Die Karte liest den gespeicherten
Modus; automatic folgt der aktuellen App-Helligkeit. Der UI-Agent implementiert
keine neuen Settings-Schlüssel und keine Persistenz.

## Sprachkataloge

Bestätigte lokale Kataloge: de, en, fr, es, it, pt, pl, ru, tr, ar, hi,
zh-Hans, ja, ko. Lokalisierte Semantik/Tooltipps/Fehler gehören dazu;
Gebäude-/Raumnamen vom Server und Identifikatoren werden nicht übersetzt.

Vereinbarte Settings-Getter für alle Kataloge:

```
settingsAppearanceTitle settingsThemeTitle settingsThemeSystem
settingsThemeLight settingsThemeDark settingsLanguageTitle
settingsLanguageSystem settingsMapThemeTitle settingsMapThemeAutomatic
settingsMapThemeLight settingsMapThemeDark settingsDataTitle
settingsCacheSize settingsCacheUnavailable settingsClearCache
settingsClearCacheDescription settingsClearHistory settingsClearHistoryDescription
settingsCancel settingsConfirm settingsAboutTitle settingsVersion
settingsUnofficialNotice settingsSources settingsRepository settingsLicenses
settingsDone settingsRestoreDefaults settingsCacheActionSuccess
settingsCacheActionFailure settingsHistoryActionSuccess settingsHistoryActionFailure
settingsSaveFailure settingsRestoreDefaultsDescription settingsCacheBytesUnit
settingsCacheKilobytesUnit settingsCacheMegabytesUnit settingsLocalDataTitle
settingsLocalDataDescription settingsDataSourcesDescription
settingsShowPassword settingsHidePassword settingsCredentialsLoadFailure
settingsIdentityStyleTitle settingsIdentityAcademic settingsIdentityWayfinding
```

Letzter Getter: gespeicherte Anmeldeeinstellungen konnten nicht geladen werden;
Bearbeitung bleibt pausiert. Kein Rohfehler/kein Passwort in Fehlermeldungen.
Quellentext: TU-Navigator für Gebäude/Pläne, OSM mit Attribution für Kacheln,
inoffizielles Community-Projekt. Keine behauptete Rechtefreigabe für TU-/AKORA-
Zeichnungen; Herkunft und gegebenenfalls offene Rechtefragen getrennt nennen.

## Gemeinsame Prüfung vor späterer Integration

1. Beide Agenten liefern ihre exakten Commit-IDs und einen sauberen Status.
2. Nutzerkoordiniert beide Änderungen in einer separaten Testkopie prüfen.
   Bereits vorhandene identische Settings-Cherry-picks berücksichtigen;
   nicht blind erneut anwenden. Andere Feature-Worktrees unverändert lassen.
3. ARB-Generierung/Root/Settings/Kartentheme zusammen prüfen; keine unbuildbare
   Root-Änderung als fertige eigenständige APK deklarieren.
4. Getestete Commit-Paare, Analyze-/Testausgabe und APK-Hash dokumentieren.
5. App-Neustart, Systemsprache, alle Einstellungen, Verlaufslöschung mit
   gemeinsamem Store und beide Kartenmodi im Emulator testen.

Emulator `emulator-5554` nur zeitlich abgestimmt verwenden. `emulator-5562`
war offline und gehört nicht zu dieser Prüfung. SDK/ADB benötigen in dieser
Sitzung Sandbox-Eskalation; das ist kein Fehler des App-Codes.
