# Campus Identity – Ausgangsbasis und Entwürfe

## Fertiger Produktstand

Die folgenden Abschnitte dokumentieren die historische Ausgangsanalyse und
Phase-A-Studie. Die tatsächliche Implementierung und finale Verifikation
stehen im [Ergebnisbericht](../ui-refinement-results.md), die Produktbilder
in [Produktvergleich](product-comparison.md). `product/` enthält echte
Produktansichten; `identity-a/` und `identity-b/` bleiben Designvorschauen.

Finale Suite: 152 bestanden, 26 externe Fixture-Skips. Analyzer: 36 bestehende
Infos, keine Warnung/Fehler, Exitcode 1. Android-Debug-APK erfolgreich.
Die Architekturzeichnungspipeline blieb unverändert.

Stand: 14.10.2026. Worktree `campus-ui-refinement`, Branch
`feature/ui-refinement`, Vergleichs-Commit
`d5609b07acc386f24446752afa70966112bb680c`.

## Herkunft der Ausgangsbilder

- `baseline-exact/`: neu aus dem unveränderten Vergleichs-Commit gebaute APK.
- `baseline/`: erste Untersuchung der zuvor installierten APK. Deren
  Quellstand ist nicht zuverlässig nachweisbar; diese Bilder dokumentieren
  Beobachtungen, gelten aber nicht als exakter Vorher-Nachher-Nachweis.
- `identity-a/` und `identity-b/`: native Flutter-Entwürfe, separates
  QA-Entrypoint `tools/ui_identity_preview.dart`. Keine fertige Produktversion.

Die Ausgangs-APK liegt lokal unter
`build/ui-refinement-checks/baseline-d5609b.apk` (ignoriertes Build-Artefakt).
SHA-256: `AAC6655819127D221D8A3E8F9534F35CE1EA8D82F553AAC24CDC2DF5303159AA`.

## Bisher geprüft

- Offline `flutter pub get`: erfolgreich, Lockfile unverändert.
- `flutter analyze --no-pub`: ein bestehender Info-Hinweis
  `non_constant_identifier_names` für `APIServices.Shared`; keine Fehler oder
  Warnungen. Exitcode 1, daher kein vollständig grüner Analyze-Lauf.
- Erneuter vollständiger Lauf nach Anlegen der Vorschau: 38 Info-Hinweise,
  keine Fehler/Warnungen, Exitcode 1. Alle Befunde liegen in unveränderten
  Produkt-/Testdateien; `git diff d5609b0 -- lib test analysis_options.yaml`
  ist leer. Die unterschiedliche Anzahl im ersten Lauf ist nicht abschließend
  erklärt; für die weitere Abnahme gilt der aktuelle vollständige Lauf.
  Die separate Vorschauanalyse meldet keine Befunde.
- `flutter test --no-pub --reporter expanded`: 94 bestanden, 26 übersprungen.
  Die übersprungenen Tests benötigen externe `PRIVATE_PLAN_DIR` bzw.
  `REAL_PLAN_DIR`-Grundrissdateien. Vier vorhandene synthetische Golden-Tests
  liefen erfolgreich.
- Android-Debug-Build: erfolgreich, 197.769.315 Bytes.
- Emulator `emulator-5554`, Android 14: Start, BEY-318-Suche, Raumöffnung,
  Favoriten/Verlauf, APB-Gebäudeauswahl, Etagenaufruf, Zurück-Navigation,
  vollständiger Grundriss, Hell/Dunkel, Tablet-Seitenleisten untersucht.

## Befunde

**Erhalten:** direkte Favoriten und Verlauf; stabile Raumidentität und
Hervorhebung; vollständige, scharfe Grundrisse; Karteninteraktion und
Gebäudeaktionen; seitliche Informationen auf breiten Tablets.

**Verbessern:** rechts abgeschnittenes WIP-Badge; redundante technische
Suchmetadaten; Platzverbrauch bei geöffneter Karten-Tastatur; englische
Adressüberschrift `Buildingadresses`; uneinheitlich lokalisierte UI-Texte.
Die Ursache des Tastaturproblems muss vor einer Verhaltensänderung anhand
der Scaffold-/Insets-Kette verifiziert werden.

Noch nicht vollständig geprüft: reale Standortberechtigungen/Position,
externes Routing-Endziel, Belegungsplan mit Zugangsdaten, Offline-Verhalten
aller APIs, Textskalierung und TalkBack, alle 14 Sprachen.

## Messgrößen für weitere Bilder

Identische Inhalte und Kameras in beiden Varianten. Zielgrößen:
393 × 852 dp (1179 × 2556 px, 480 dpi), 800 × 1280 dp
(1200 × 1920 px, 240 dpi), 1280 × 800 dp
(1920 × 1200 px, 240 dpi). Systemleisten gehören zum Screenshot.
`baseline/` verwendet teilweise die ursprüngliche Emulatorgröße
1080 × 1920 px bei 420 dpi; diese Bilder werden nicht mit den neuen
393-dp-Entwürfen als identische Gerätegröße verglichen.

Die Entwürfe verwenden echte TU-Gebäudegeometrien, OSM-Kacheln und den
unveränderten `FloorView` für BEY 318. Listeninhalte sind identische
Präsentationsdaten; Suche, Favoriten und externe Aktionen in den Entwürfen
sind keine implementierte Produktfunktion. Diese bleiben Gegenstand von
Phase B und C.

## Reproduzierbarkeit der Designstudie

```powershell
. .\tools\dev-env.ps1
flutter --suppress-analytics build apk --debug --no-pub -t tools/ui_identity_preview.dart
adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk
adb -s emulator-5554 shell am force-stop com.example.campus_navigator
.\tools\preview-identity.ps1 -Variant b -Scene hub
adb -s emulator-5554 shell am start -n com.example.campus_navigator/.MainActivity
.\tools\capture-identity.ps1
```

Die Vorschau verwendet dasselbe Android-Paket für vorhandene Cache-Daten;
Favoriten, Verlauf, Zugangsdaten und Einstellungen werden nicht verändert.
Die konfigurierte QA-JSON-Datei ist ausschließlich dem separaten Entrypoint
bekannt. Produkt-APK anschließend wieder installieren. Die Aufnahme sperrt
die Geräte-Rotation auf 0, damit der virtuelle Sensor die Größen nicht
vertauscht. Abmessungen und SHA-256 pro Bild stehen in
`identity-manifest.json`; 40 Bilder, beide Varianten, alle drei Größen,
jeweils Hell/Dunkel. Smartphone zusätzlich mit Suchresultat.

Aktuelle Vorschau-APK: `build/ui-refinement-checks/campus-identity-preview.apk`,
SHA-256 `66F1EC4CB0888288808E08531649DE5D4895A2FEA9B466C82875A86BB045AA14`.
Aus diesem Worktree mit `-t tools/ui_identity_preview.dart` gebaut und
installiert. Kein Release und keine Produkt-APK der fertigen Überarbeitung.
UI-Vergleich: [Designvergleich](design-comparison.md).

Der Aufnahmelauf prüft jetzt innerhalb von maximal 30 Sekunden pro Szene:
angewendete Variante/Szene/Helligkeit, gerenderte Breite, geladenes APB und
Kartendaten, abgeschlossene fehlerfreie Kacheln sowie initiale Grundrissbilder.
Die Karte wird erst nach APB-Auflösung konstruiert. Rasterstufe muss stabil
sein; A/B dürfen keine unterschiedlichen Rasterstufen oder Kartenkameras
verwenden. Größe und tatsächliche DPI werden ebenfalls geprüft. Ein Lauf
mit zuvor geleerten Caches hat alle 40 Bilder erfolgreich erzeugt.
Dieser technische Check ersetzt weiterhin keine visuelle Kontrolle.

Nach Aufnahme Emulator wiederherstellen:

```powershell
adb -s emulator-5554 shell wm size reset
adb -s emulator-5554 shell wm density reset
adb -s emulator-5554 shell wm user-rotation free
adb -s emulator-5554 shell cmd uimode night no
```
