# Campus Identity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Die bestehende Campus-App außerhalb der Einstellungen kompakt,
konsistent und zugänglich im gewählten Campus-Identity-Stil verbessern.

**Architecture:** Bestehende Screens, Controller und API-Flows weiterverwenden.
Ein kleiner UI-Token-Baustein versorgt die umgebende Oberfläche; die vorhandene
Zeichnungspalette bleibt separat. Settings und Root-Anbindung werden anhand
der abgestimmten Schnittstellen in getrennten Commits integriert.

**Tech Stack:** Flutter 3.24.5 / Dart 3.5.4, Material 3, vorhandenes flutter_map
7.0.2, generierte ARB-Lokalisierung, bestehende Android-/ADB-Werkzeuge.

**Spec:** `docs/superpowers/specs/2026-10-14-campus-identity-design.md`

## Global Constraints

- Ausschließlich `F:\apps\Codex\campus-ui-refinement`, `feature/ui-refinement`.
  Rücksetz-/Vergleichspunkt `d5609b07acc386f24446752afa70966112bb680c`.
- Kein Merge, Force-Push oder Änderung von `master`/anderen Worktrees.
- Auswahl A/B vor größeren Produktänderungen; Phase A enthält nur Vorschauen.
- Keine Änderung der Rendering-Pipeline, Raumgeometrien, Farbtransformationen
  und architektonischen Zeichnungen. Keine neuen Routingverfahren.
- Keine neuen Abhängigkeiten; Roboto/Systemschrift, Material-Icons, 4-/8-dp-
  Raster; wichtige Touchziele mindestens 48 × 48 dp.
- Zielgrößen 393 × 852, 800 × 1280, 1280 × 800 dp; Hell und Dunkel;
  zusätzlich kompakte Smartphonebreite, große Schrift und Arabic RTL.
- Settings/Persistenz bleiben beim Settings-Agenten. Gemeinsame Dateien nur
  nach festgehaltener Zuständigkeit; Integrationsänderungen separat dokumentieren.
- 14 bestätigte Sprachen: de, en, fr, es, it, pt, pl, ru, tr, ar, hi, zh-Hans,
  ja, ko. Gerätesprache als Standard; sonst Englisch; keine Übersetzung
  von Server-Gebäude-/Raumnamen und Identifikatoren.

## Review Focus

1. Viele Favoriten, lange Namen und 200-%-Text: erreichbar, kein Overflow,
   keine gekürzten Aktionsziele (Aufgabe 2).
2. Suche während alter Netzantworten/Keyboard-Wechsel: korrekte Ergebnisse,
   kein Verlust von Eingabe, Kamera oder Auswahl (Aufgabe 3).
3. Gebäude ohne Adresse/Etage/Route und Offline-Karte: klare Zustände,
   keine erfundenen Informationen (Aufgabe 3).
4. Rotation mit geöffnetem Sheet und Raumwechsel: korrekter Raum,
   vollständiger Grundriss und funktionierendes Zurück (Aufgabe 4).
5. Systemlocale, zh-Varianten, arabische Richtung und Theme-Wechsel:
   kanonische Sprache, lesbare UI, unveränderte Zeichnung (Aufgabe 5).

---

### Aufgabe 1: Ausgangsbasis und Variantenentscheidung (Phase A)

**Files:** `docs/ui-evidence/**`, `tools/ui_identity_preview.dart`,
`tools/preview-identity.ps1`, Spec und dieser Plan.

**Interfaces:** Vorschau-Entrypoint getrennt von `lib/main.dart`;
JSON `{variant: a|b, scene: hub|results|map|floor, dark: bool}` nur im
Debug-App-Verzeichnis; verwendet unverändertes `FloorView(data)`.

- [x] Branch/Status und Quellstand prüfen; Ausgangs-APK sichern.
- [x] Vorhandene Ansichten einschließlich Tablets/Hell/Dunkel untersuchen;
  Befunde und Grenzen von APK-/Screenshot-Herkunft dokumentieren.
- [x] Ausgangs-Analyze, Tests und Android-Debug-Build ausführen; Logs sichern.
- [x] A/B mit identischen Inhalten auf den drei Größen und Hell/Dunkel
  aufnehmen; Layout, Labels, Textkontrast und sichtbare Kartenfläche prüfen.
- [x] Plan selbst gegen alle Spec-Anforderungen prüfen.
- [x] Vergleichsgalerie und kurze Begründung zur Präsentation bereitstellen.
- [x] Beide Varianten umschaltbar; bestätigter Standard A (Modern Academic).
- [x] Baseline-Commit `c391ced` erstellen.
- [x] Design/Plan-Commit erstellen.

### Aufgabe 2: Tokens, Campus Hub und Suchlisten (Phase B)

**Files:** Create `lib/ui/campus_identity.dart`; Modify
`lib/ui/screens/search_screen.dart`; Test
`test/regression/search_favorites_widget_test.dart` und
`test/regression/campus_identity_layout_test.dart` (neu).

**Interfaces:** `CampusIdentity.themeData(Brightness brightness) -> ThemeData`
aus der Spec; `PlaceStore`/`RoomSearchController` unverändert;
`SearchScreen({PlaceStore? places, RoomSearchController? search,
Future<BuildingPageData> Function(SavedPlace)? loadPlace})` erhalten.

- [ ] Fehler reproduzierend testen: 25 Favoriten scrollbar und letzter
  erreichbar; 320-dp-Breite und 200-%-Text ohne Flutter-Overflow; Favorit
  toggelt dieselbe Place-ID; Suchmetadaten ohne doppelte Raumkennung.
- [ ] Nur diese Tests laufen lassen; vor der Änderung erwartete Layout-
  bzw. Hierarchiefehler dokumentieren, bereits grüne Regressionen erhalten.
- [ ] Gewählte A/B-Präsentation mit 48-dp-Aktionen implementieren;
  WIP-Hinweis innerhalb einer erreichbaren Aktion platzieren;
  zwei Listen ab 720 dp Inhaltsbreite, vorhandene Suchzustände erhalten.
- [ ] Leere Favoriten/Verlauf, keine Treffer, Lade-/Speicherfehler und
  Retry im vorhandenen Controller testen; Enter-Suche, Löschen,
  Tastatur-Schließen und direktes Öffnen im Emulator prüfen.
- [ ] Fokussierte Tests und Analyze ausführen; Screenshots vergleichen;
  Commit `feat(ui): refine campus hub and search hierarchy`.

### Aufgabe 3: Kartenfläche und Gebäudeinformationen

**Files:** Modify `lib/ui/screens/campus_map_screen.dart`,
`lib/ui/screens/home_screen.dart`; Test
`test/regression/campus_map_widget_test.dart`,
`test/regression/place_navigation_test.dart`,
`test/regression/campus_identity_layout_test.dart`.

**Interfaces:** bestehende Catalog-/Tile-/Location-Services und
`loadBuildingFloor(String code)` unverändert; IndexedStack/lazy map erhalten;
840-dp-Schwelle für Seitenleiste; Rail ab 1000 dp Gerätebreite.

- [ ] Karten-Tastaturproblem in 393-dp-Ansicht reproduzieren; Insets durch
  Home-/Map-Scaffold verfolgen, Ursache anhand tatsächlicher Constraints
  festhalten, erst dann den zuständigen Scaffold korrigieren.
- [ ] Regressionen: Tastatur/schnelle Suchwechsel/Tabwechsel behalten
  Auswahl und Kamera; Kartenfläche bleibt positiv groß; keine Adresse,
  ungültige Route oder keine Etage erzeugt keinen falschen Buttonaufruf.
- [ ] Kompakte Such-/Werkzeuggruppe und Gebäude-Panel implementieren;
  Attribution behalten; zoomabhängige Labelbegrenzung, geometrische Auswahl,
  Standortstatus und Navigationshinweis erhalten.
- [ ] Auf Tablets Rail mit gleichen zwei Zielen anbinden; Restoring und
  verzögertes Kartenladen bleiben wie bisher. Navigation getrennt committen,
  falls sie unabhängig vom Kartenlayout geändert wird.
- [ ] Fokussierte Tests; Emulator: Suche/APB/Zurück, Zoom/Pan, Standort-
  Berechtigung, externe Navigation, Offline-/Retry-Zustände. Quellen-/Netz-
  Fehler injizieren statt produktive Services für Tests umbauen.
- [ ] Vorher/Nachher bei gleicher Kamera und Tastatur dokumentieren;
  Commit `feat(ui): improve campus map controls and selection panel`.

### Aufgabe 4: Etagen-Chrome und responsive Raumdetails

**Files:** Modify `lib/ui/screens/building_screen.dart`,
`lib/ui/components/bottom_sheet_view.dart`,
`lib/ui/components/adress_section_view.dart`; Test vorhandene
Building-/Navigation-Tests und `campus_identity_layout_test.dart`.

**Interfaces:** `BuildingScreen(room: Future<BuildingPageData>, name: String,
favoriteAction: Widget?)`; `FloorView(data: BuildingPageData)` unverändert.
Neue lokale Theme-Grenze um FloorView verwendet die bestehende Zeichnungspalette.

- [ ] Tests für lange Titel/200-%-Text, 393/800/1280-dp-Layouts,
  Sheet-Rotation und Etagenwechsel schreiben: Raum-ID bleibt korrekt,
  Seitenleiste ab 840 dp, Fit-/Filter-/Favoritaktionen erreichbar.
- [ ] Kompakte Titel-/Etagen-/Filterzeile und inhaltsabhängige geschlossene
  Sheet-Höhe umsetzen; seitliche Information 300 dp erhalten.
- [ ] Adressüberschrift und Details hierarchisch ordnen; bestehende
  Share-/Navigation-/Raumbelegungsaktionen unverändert anbinden.
- [ ] Grundriss-Screenshots gleicher Räume/Zoomzustände Hell/Dunkel
  vergleichen; Pan/Pinch/Fit, Hervorhebung, alle Filter und Etagen prüfen.
  Keine Änderung an `painter.dart`, Planparser oder Tile-Pipeline.
- [ ] Fokussierte Tests und vorhandene Renderer-Regressionen ausführen;
  externe reale Fixtures nur bei vorhandenen Pfaden verwenden;
  Commit `feat(ui): refine floor controls and room information`.

### Aufgabe 5: Lokalisierung und koordinierte Settings-Integration

**Files (UI-Agent):** `lib/l10n/app_*.arb`, `lib/main.dart`, verbleibende
Nicht-Settings-Screens/Komponenten, `docs/ui-integration.md`,
`test/regression/localization_test.dart` (neu).
**Files (Settings-Agent):** `lib/settings/**`, `settings_screen.dart`,
Settings-/Cache-Tests, notwendige Pubspec-/Cache-Anpassungen.

**Interfaces:** `AppSettingsScope.of(context)` liefert
`AppSettingsController`; `themeMode`, `locale`, `campusMapThemeMode`,
`supportedLocales`, `resolveLocale(deviceLocale)`; `SettingsScreen(places: _places)`.
`await controller.load()` vor runApp; Schnittstelle gegen den Settings-Code gelesen.

- [ ] ARB-Inventar für alle sichtbaren Texte, Fehler, Semantik und Tooltipps
  festlegen, einschließlich der vereinbarten Settings-Getters sowie
  `settingsShowPassword`/`settingsHidePassword`; Platzhalter typisieren.
- [ ] Katalog-Parität, fehlende Schlüssel/Platzhalter, de/en/unsupported,
  zh-Hans und arabische Directionality als Verhaltenstests festschreiben.
- [ ] `_t(de,en)` und rohe UI-Texte durch generierte Lokalisierung ersetzen;
  alle 14 Kataloge pflegen; Serverdaten/IDs und Suchsemantik unverändert.
- [ ] Settings-Schnittstellen gegen den tatsächlich fertiggestellten Branch
  lesen und Integration als separaten UI-Commit durchführen. Root bindet
  themeMode/locale/Resolver; Kartentheme folgt automatic/light/dark.
  Keine Änderung der Settings-Persistenz durch den UI-Agenten.
- [ ] Root-/Karten-/Sprachtests im kombinierten Teststand ausführen;
  getestete Commit-Paare und Abhängigkeiten dokumentieren. Kein automatischer
  Merge; kombinierte Prüfung nur in ausdrücklich abgestimmter Testkopie.
- [ ] Langes Französisch/Russisch, Hindi/Chinesisch/Japanisch/Koreanisch,
  arabische Richtung, Geräte-/Appsprache und Theme-Wechsel im Emulator prüfen;
  unreviewte Übersetzungen ausdrücklich nennen.
- [ ] Commit `feat(l10n): localize campus views and bind app preferences`.

### Aufgabe 6: Visuelle und funktionale Abnahme (Phase C)

**Files:** `docs/ui-evidence/**`, `docs/ui-integration.md`,
`docs/ui-refinement-results.md`; APK in ignoriertem `build/` sichern.

- [ ] Identische Vorher/Nachher-Bilder: Hub, Suchresultat, APB-Karte,
  BEY-318-Etage; 393 × 852, 800 × 1280, 1280 × 800 dp; Hell/Dunkel.
- [ ] Navigation/Suche/Favoriten/Verlauf/Etagen/Kartenaktionen durchspielen;
  Tastatur, Rotation, leere Zustände, lange Texte, Netzfehler, 200-%-Schrift
  und TalkBack prüfen; reale Routing-/Standort- und Login-Grenzen nennen.
- [ ] `flutter analyze`, `flutter test`,
  `flutter build apk --debug` aus sauber dokumentiertem Quellstand ausführen.
  Bestehende Analyze-Infos nicht als grünes Analyze-Ergebnis darstellen;
  neue Warnungen/Fehler und nicht begründete Test-Skips beseitigen.
- [ ] Installierbare Produkt-APK sichern, Hash/Commit/Buildzeit dokumentieren;
  APK installieren und geänderte Interaktionen nach dem Build wieder prüfen.
- [ ] Frischen Code-Review mit Auftrag/Spec/Diff und aktuellem Teststand
  durchführen; relevante Befunde korrigieren und erneut verifizieren.
- [ ] Ergebnisbericht: Probleme, konkrete Nutzen, unveränderte Bereiche,
  Testbelege/Skips, Übersetzungsreview und Integrationsanforderungen.
  Abschließender Commit; Branch behalten, keinen Merge durchführen.

## Ausführungsbefehle / Umgebung

PowerShell im eigenen Worktree: `. .\tools\dev-env.ps1`. SDK-Befehle benötigen
in dieser Sitzung die bereits genehmigte Sandbox-Eskalation; sonst scheitert
Dart/ADB vor dem App-Code. Bestehende Toolchain weiterverwenden.

```powershell
flutter --suppress-analytics analyze --no-pub
flutter --suppress-analytics test --no-pub --reporter expanded
flutter --suppress-analytics build apk --debug --no-pub
# Ausschließlich die Designstudie:
flutter --suppress-analytics build apk --debug --no-pub -t tools/ui_identity_preview.dart
```

Die Umsetzung erfolgt eigenständig in dieser Sitzung nach Variantenwahl.
Keine weitere allgemeine Bestätigungsrunde; ungeklärte Integration oder
nachweisbare technische Blockaden werden mit konkretem Stand benannt.
