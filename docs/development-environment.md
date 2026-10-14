# Lokale Entwicklungsumgebung – 13.10.2026

Repository: `F:\apps\Codex\campus-navigator`, Remote
`https://github.com/Infinizius/campus-navigator.git`.
Aktiver Branch: `codex/renderer-recovery`.

## Git und Ausgangslage

Der ursprüngliche Arbeitsordner war leer. Das Repository wurde neu geklont.
`master` und `origin/master` bleiben auf
`0441326300600ceff155dad0e1b0a89b2d4f3710`.
Auf ausdrücklichen Wunsch wurde der Entwicklungsbranch anschließend per
Fast-forward auf `origin/work/ui-polish-and-darkmode` übernommen:
`37d4d6898b6a87404b11ab649107d67dbfa1dec8`.
Kein Push und keine eigenen Änderungen an `lib/` oder Rendering-Referenzbildern.

Die vier späteren Commits ändern Cache/Bildladen (`2e44eda`), Renderer und
Raumidentität (`af55871`), Etagenoberfläche (`e61a414`) und Regressionstests
(`37d4d68`). Insgesamt 34 Dateien, 1870 hinzugefügte und 913 entfernte Zeilen.
Der ursprüngliche APK-Workflow auf master nahm vor dem Build temporäre
Abhängigkeits- und Android-Konfigurationsänderungen vor. Seine Existenz ist
kein Nachweis eines unveränderten, erfolgreich gebauten master.

## Werkzeuge und Nutzung

Lokale SDKs außerhalb des Git-Repositories unter `F:\apps\Codex\toolchains`:

| Werkzeug | Version |
| --- | --- |
| Git | 2.53.0.windows.3, gebündeltes Codex-Git |
| Flutter | 3.24.5, Framework `dec2ee5c1f` |
| Dart | 3.5.4 |
| Java | Temurin JDK 17.0.20.1+1 |
| Android | Platform API 33/34, Build Tools 30.0.3/34.0.0, Platform Tools 37.0.1 |
| Gradle | Projekt-Wrapper 7.5 |
| Android Gradle Plugin / Kotlin im Hauptprojekt | 7.3.0 / 1.9.0 |

Flutter wurde aus dem offiziellen Repository am Release-Tag installiert.
Ein zusätzlicher Flutter-3.22.3/Dart-3.4.4-Checkout dient dem Ausgangsvergleich.
Das gebündelte Git hatte zunächst einen unvollständigen Helper-Suchpfad;
`GIT_EXEC_PATH` auf dessen `mingw64\bin` behebt HTTPS-Klonen.

In einer PowerShell im Repository:

```powershell
. .\tools\dev-env.ps1
git status --short --branch
flutter --version
flutter doctor -v
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
adb devices -l
```

Das Skript setzt PATH und SDK-/Cache-Pfade nur für diese Shell. Die lokale
Flutter-Konfiguration zeigt ebenfalls auf Android SDK und JDK. Windows- und
Linux-Desktopziele wurden deaktiviert: Hier wird Android entwickelt, und
Windows-Plugin-Symlinks scheiterten ohne Windows-Entwicklermodus.
Android-SDK-Lizenzen wurden angenommen. Android Studio wurde nicht installiert;
die Kommandozeilenwerkzeuge übernehmen den Build.

## Tatsächliche Prüfergebnisse

Ausgangsstand master mit Flutter 3.22.3:

- Paketauflösung funktionierte, änderte aber zehn SDK-gebundene Lock-Einträge;
  Original-Lockdatei danach wiederhergestellt. Daher kein Nachweis einer
  exakt mit der ursprünglichen Lockdatei aufgelösten Umgebung.
- `flutter analyze --no-pub`: 50 Meldungen, darunter vier Fehler aus den
  verschachtelten Starterprojekten `android/test` und `ios/test` und ein
  unbenutzter Import.
- `flutter test --no-pub`: 14 erfolgreiche Testausführungen. Der Sammeltest
  ruft dieselben API-/Navigationstests erneut auf.
- APK-Build gestartet, während der erstmaligen Gradle-Einrichtung nach der
  geänderten Branch-Vorgabe beendet. Kein fertiger master-APK-Nachweis.

Neuester Entwicklungsstand mit Flutter 3.24.5:

- `flutter pub get`: erfolgreich, versionierte Lockdatei unverändert;
  112 neuere Paketversionen liegen außerhalb der aktuellen Constraints.
  Kein pauschales Dependency-Upgrade durchgeführt.
- `flutter analyze`: 44 Info-Meldungen, keine Fehler oder Warnungen;
  Exitcode 1 wegen der vorhandenen Lints. Die Analyse-Ausschlüsse für die
  verschachtelten Starterprojekte stammen bereits aus dem anderen Branch.
- `flutter test`: 25 erfolgreich, vier Golden-Vergleiche fehlgeschlagen,
  ein optionaler Test übersprungen. Die vier Abweichungen betragen
  130/72/128/72 Pixel (0,08/0,01/0,08/0,01 %). Linux-Referenzen gegen Windows
  sind eine mögliche Ursache, bislang kein bewiesener Rendererfehler.
  Diagnosebilder liegen unter `test/regression/failures/`; Referenzen erhalten.
- `flutter doctor -v`: Flutter und Android-Werkzeugprüfung grün; SDK, JDK und
  Lizenzen erkannt. Einzige verbleibende Kategorie: Android Studio fehlt.
- Bei der ersten Prüfung war nur ein offline gemeldeter Emulator vorhanden.
  Anschließend wurde `campus_api34` (Pixel 2, Android 14 Google APIs x86_64)
  eingerichtet. WHPX-Hardwarebeschleunigung ist nutzbar. `emulator-5554`
  bootet erfolgreich; APK-Installation und Start von `MainActivity` erfolgreich.
  Suchbildschirm per Screenshot bestätigt, App-Prozess läuft, keine
  `FATAL EXCEPTION`/`E/flutter` im geprüften jüngsten Logauszug.
  Suche, reale Pläne und weitere Interaktionen noch nicht geprüft.
- `flutter build apk --debug --no-pub -v`: erfolgreich, Gradle 4 min 1 s,
  Flutter insgesamt ca. 250 s. Keine Änderung an Anwendungscode, Lockdatei
  oder Android-Buildkonfiguration gegenüber `37d4d68` erforderlich.
  Ergebnis: `build/app/outputs/flutter-apk/app-debug.apk`, 196734973 Bytes.
  `apksigner verify --verbose`: gültig (v1/v2); Metadatenwarnungen unter
  META-INF. Android minSdk 23, target/compileSdk 34.
  SHA256: `1EA3C931C83A37D965CE302F1DDD10AD10B16F1BAC71EC5C7B9C8794EAB2E6FD`.

Protokolle der Untersuchung liegen unter `F:\apps\Codex`:
`doctor-current.log`, `pub-get.log`, `analyze-current.log`, `test-current.log`,
`apk-current.log` sowie `analyze-baseline.log`, `test-baseline.log`,
`apk-baseline.log`.

## Reale Etagenpläne automatisiert prüfen

Der übernommene Test `test/regression/private_plans_test.dart` unterstützt
APB E069 und BEY 318. Er liest gespeicherte HTML-Antworten und PNG-Kacheln,
prüft Raumidentität, Labelposition im Polygon und Layoutausnahmen und exportiert
acht Bilder: Telefon/Tablet, jeweils hell/dunkel. Er vergleicht diese realen
Planbilder derzeit **nicht** mit Golden-Referenzen. Ohne externe Testdaten
wird er übersprungen; die Dateien liegen nicht im Repository.

```powershell
flutter test test/regression/private_plans_test.dart `
  --dart-define=PRIVATE_PLAN_DIR=F:/private-plan-fixtures `
  --dart-define=SCREENSHOT_DIR=F:/apps/Codex/plan-screenshots `
  --dart-define=FLUTTER_FONT_DIR=F:/apps/Codex/toolchains/flutter-3.24.5/bin/cache/artifacts/material_fonts
```

Benötigt: `evidence/floorpage.body`, `bey-floor.html`,
`APB00_1_0_0.png`, `APB00_1_1_0.png`, `BEY03_1_0_0.png` bis
`BEY03_1_2_0.png`. Details stehen in `docs/ui-polish.md`.

Für belastbare spätere Renderer-Arbeit: eingefrorene reale Fixtures samt
Prüfsummen, feste Flutter-Version/OS/Fonts/Pixelratio und visuell geprüfte
Golden-Referenzen verwenden. Zusätzlich Android-Screenshots auf einer festen
Emulator-/Gerätekonfiguration mit Zoom, Etagenwechsel und Filtern prüfen.
Qualitätsstufe 1 des bestehenden Tests deckt die volle Kachelqualität der APK
nicht ab. Synthetische Goldens allein beweisen keine korrekten realen Pläne.
Hier wurden keine neuen realen Daten abgerufen und keine Rendererfehler repariert.

Offizielle Installationsreferenz: https://docs.flutter.dev/install/manual

Eigene Änderungen beschränken sich auf dieses Dokument, die Skripte unter `tools/`
und einen Ignore-Eintrag für erzeugte Golden-Diagnosebilder. Das Shell-Skript
wurde mit Git-HTTPS, Flutter-Version, SDK Manager und adb praktisch geprüft.
`git diff --check` erfolgreich. Keine Referenzbilder neu erzeugt oder ersetzt.

## Emulator interaktiv nutzen

```powershell
Set-Location F:\apps\Codex\campus-navigator
.\tools\run-emulator.ps1
```

Das öffnet den Emulator, wartet auf Android, installiert die vorhandene
Debug-APK und startet die App. Maus und Tastatur bedienen den Suchbildschirm.
Für Flutter-Entwicklung mit Hot Reload:

```powershell
.\tools\run-emulator.ps1 -HotReload
```

Im Flutter-Terminal: `r` für Hot Reload, `R` für Neustart, `q` zum Beenden.
Das Emulatorfenster kann normal geschlossen werden. Die AVD-Daten liegen
unter `F:\apps\Codex\toolchains\avd`.
