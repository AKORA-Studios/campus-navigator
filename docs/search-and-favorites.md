# Suche und Favoriten – Version 1.1.0 (2)

Entwicklungsbranch: `feature/search-and-favorites`. Der Renderer-Ausgangsstand `49a4dfa` wurde vor Beginn mit dem Baseline-Commit `6b1a660` dokumentiert. Die Funktion ist in `d964957` implementiert. `master` bleibt bei `0441326300600ceff155dad0e1b0a89b2d4f3710`.

## Bedienung

Die Startansicht enthält eine feste Suchleiste, Favoriten für Räume und Gebäude sowie die letzten 20 geöffneten Räume. Der Stern speichert oder entfernt einen Favoriten, auch in der Kartenansicht. Gebäude, Etage und gegebenenfalls Raumalias stehen unter dem Namen. Der Verlauf lässt sich unabhängig von Favoriten leeren. Neue Texte sind deutsch und englisch vorhanden; die App folgt der Gerätesprache.

Favoriten und Verlauf werden lokal über die vorhandene `FlutterSecureStorage`-Bibliothek gespeichert. Sie bleiben bei Neustarts und beim APK-Update mit gleicher Signatur erhalten. Es gibt keine Synchronisierung zwischen Geräten; auf Smartphone und Tablet entstehen getrennte Listen. Eine Deinstallation entfernt die lokalen Daten.

## Technische Trennung

- `lib/ui/search_controller.dart`: bestehende Such-API, 400-ms-Verzögerung, Schutz vor veralteten Antworten, Wiederholen und optionales vorhandenes HTML-Prefetching.
- `lib/api/saved_places.dart`: validierte Ziele, versioniertes Speicherdokument und serialisierte Schreibvorgänge. Die UI bestätigt Änderungen erst nach erfolgreichem Schreiben. Ladefehler bieten Wiederholen; ein unlesbares Gesamtdokument wird nicht stillschweigend überschrieben.
- `lib/api/place_navigation.dart`: Navigation über gespeicherte Server-IDs. Räume werden anhand von Gebäude und opaker Raum-ID unterschieden, niemals anhand der sichtbaren Nummer. Die geladene Ziel-ID muss übereinstimmen. Gebäudetreffer verweisen auf Campusübersichten; der Resolver liest deshalb tatsächlich angebotene Etagenpläne und bevorzugt Etage 00, sofern vorhanden.
- `lib/ui/screens/search_screen.dart`: kompakte Material-3-Listen mit Leer-, Lade- und Fehlerzuständen. Favoritensterne haben beschriftete Accessibility-Aktionen und einen expliziten Zustand.

Der Painter, `FloorView`, Kachelloader, Planparser und alle Rendering-Goldens bleiben unverändert. Die bestehende Kartenansicht erhielt ausschließlich einen optionalen Favoritenknopf in der App-Leiste. Sucheinstellungen, Gebäude-/Etagenwechsel, Filter, Zoom, Verschieben, Informationsansicht und bisherige Nebenansichten bleiben erhalten. Keine neuen Abhängigkeiten.

## Prüfung

80 Tests bestanden, ein optionaler alter privater Fixturetest wurde übersprungen. Darunter: 24 unveränderte Originalplan-Goldens, bestehende Interaktionstests sowie neue Tests für identische Raumnamen, exakte Ziel-IDs, Gebäudenavigation, Neustart, Entfernen, gleichzeitige Schreibvorgänge, Verlaufsgrenze, Speicher-/Netzwerkfehler und beide Viewportgrößen. Analyse: keine Fehler oder Warnungen, 38 vorhandene Stilhinweise.

Im Android-14-Emulator wurden echte Suchergebnisse für BEY 318 und APB E069 geöffnet, Raum- und Gebäudefavoriten gespeichert, über die Kartenansicht geändert, nach vollständigen Prozessneustarts wiederhergestellt beziehungsweise entfernt und Gebäudefavoriten auf die richtige Etage geöffnet. Die zusätzliche Querformatprüfung verwendet 1920 × 1200 bei Dichte 240. Die reguläre Release-APK wurde ebenfalls installiert und geprüft. Androids Accessibility-Dump kann in diesem Emulator nach einem Repaint alte App-Leistenbeschriftungen liefern; der Nachweis erfolgt daher zusätzlich durch sichtbare Screenshots und den gespeicherten Zustand nach Neustart.

## APK und Nachweise

`F:\apps\Codex\search-favorites-evidence\campus-navigator-1.1.0-search-favorites.apk`

Universelle Release-Test-APK, Android 6/API 23 oder neuer, ARM32/ARM64/x86_64, etwa 51,3 MiB. Signatur v1/v2 geprüft; vorhandene lokale Testsignatur, keine Store-Veröffentlichung. SHA256: `2297df1f7b77763b36ca62c226cf42285bb4d727792e25476fdf4fcdc75a43e3`.

Die vorhandene AGP-7.3-Toolchain meldet beim Release-Lint Kotlin-Metadatenhinweise zu neueren Android-Bibliotheken (`lintVitalAnalyzeRelease`). Der Build endet erfolgreich. Eine Gegenprüfung ohne Shrinking zeigte dieselben Lint-Hinweise; deshalb wurde die normale Release-Konfiguration beibehalten und keine Toolchain-Migration in dieses Feature aufgenommen.

Screenshots, Vorher-/Nachher-Vergleiche, Testprotokolle und Galerie liegen außerhalb des Repositorys unter `F:\apps\Codex\search-favorites-evidence` (`index.html`). Keine Originalpläne, privaten Fixturedateien, APKs oder Build-Ausgaben wurden für dieses Feature eingecheckt.

## Reproduktion und Gerätetest

```powershell
. .\tools\dev-env.ps1
flutter test --dart-define=REAL_PLAN_DIR=F:\apps\Codex\campus-navigator\data\renderer-fixtures --dart-define=FLUTTER_FONT_DIR=F:\apps\Codex\toolchains\flutter-3.24.5\bin\cache\artifacts\material_fonts
flutter analyze --no-fatal-infos
flutter build apk --release --target lib/main.dart
# Optional nach Installation im laufenden Emulator:
$qaPython = Join-Path $env:USERPROFILE '.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
& $qaPython tools/smoke-search-favorites.py
```

Auf Smartphone und Tablet dieselbe APK installieren. Bei Bedarf Androids Freigabe für die verwendete Installationsquelle erteilen. Für den ersten Gerätetest: zwei Räume und ein Gebäude suchen und speichern, App vollständig schließen und erneut starten, Favoriten öffnen und entfernen, danach Etagenwechsel, Zoom und Verschieben prüfen. Physische Geräte wurden hier noch nicht getestet; weitere Funktionen werden vorerst nicht begonnen.
