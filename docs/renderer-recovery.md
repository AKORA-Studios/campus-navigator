# Renderer-Wiederherstellung

Stand: 13.10.2026, Windows / Flutter 3.24.5 / Android-14-Emulator `campus_api34`.
Entwicklungsbranch: `codex/renderer-recovery`. `master` bleibt auf `0441326`.
Ausgangscode: `37d4d68` aus `work/ui-polish-and-darkmode`; Umgebungssicherung: `f61ff12`.

## Befund und Änderungen

Die stärkste Ursache für blasse Wände war die feste Kachelstufe 8. Der TU-Server zeichnet Linien auch dort mit sehr geringer Rasterbreite. Beim Verkleinern auf eine Gesamtansicht verschwinden diese Linien. Ein direkter Vergleich unveränderter Stufen 1 und 8 reproduziert den Fehler (`renderer-evidence/raster-resolution.png`). Die neue Auswahl verwendet die nächste Originalstufe zum Wert `fit × zoom × sqrt(clamp(Pixeldichte, 1, 4))`. Die reduzierte Berücksichtigung der Pixeldichte entstand aus Emulatorvergleichen: reine physische Auflösung erzeugte zu dünne Linien; reine logische Auflösung machte kleine Symbole grob. Die Einstellung „Qualitätsstufen“ begrenzt weiterhin die höchste Stufe.

`PageImageData` lädt zuerst eine kleine vollständige Karte, hält beim Stufenwechsel die vorherige Darstellung sichtbar und veröffentlicht neue Kacheln gemeinsam. Vier Arbeiter, Abbruch veralteter Stufen, Freigabe der alten Bilder nach dem Frame und kein dauerhaftes Halten aller Auflösungen begrenzen den Aufwand. Ein fehlgeschlagener Wechsel erhält die vorherige Karte. Ein realer weiterer Fehler war die Behandlung leerer HTTP-200-Kacheln als Netzwerkfehler: Der TU-Server verwendet sie für leere Randbereiche. Sie gelten jetzt als transparent; HTTP-Fehler und defekte PNGs bleiben Fehler.

Die PNG-Geometrie, vollständige Canvas-Ausdehnung, zentrierten Koordinaten und Serverpositionen bleiben erhalten. Zeichenreihenfolge: Hintergrund → zurückhaltende Polygonfüllungen → transparente Zielraumfüllung → Original-PNGs → Symbole → dünne Zielkontur → Beschriftung. Die ursprüngliche Füllungsalpha wird multipliziert und nicht überschrieben.

Hellmodus erhält die Raster-RGB-Werte. Ein zoomabhängiger Alphafaktor verstärkt teilweise gedeckte feine Linien, ohne transparente Hintergründe zu füllen. Dunkelmodus invertiert die Luminanz und erhält einen Teil der Chrominanz: violette technische Linien werden nicht mehr gelb. Beide Transformationen sind GPU-Farbmatrizen; es gibt keine CPU-Pixeloperation pro Frame und keine geometrische Verdickung, die Türöffnungen schließen könnte.

Die früheren individuellen Schriftgrößen aus Raumextent und Textlänge konnten etwa „304“ übergroß machen. Beschriftungen sind jetzt einzeilig, auf 12 logische Pixel beziehungsweise 16 für das Ziel begrenzt und zusätzlich an Serverextents angepasst. Das Ziel hat Vorrang. Andere Texte erhalten wenige begrenzte Ausweichpositionen; nicht lesbare oder weiterhin kollidierende Texte entfallen. Ein schmaler Glyphenrand ersetzt die deckende Textbox. Die Zielkontur bleibt bei 1,4 logischen Pixeln. Zoom löst einen Repaint aus; reines Verschieben verwendet weiterhin die aufgezeichnete Karte. Bildankunft, Thema und Filtersnapshots lösen ebenfalls zuverlässig neue Zeichnung aus.

Raumidentitäten wurden gegen die Originalzuordnung `searchhelp`/`raumclick` geprüft: BEY E25 `111100.5360`, E26 `111100.5370`, 318 `111103.5220`, 319A `111103.5240`, APB E069 `542100.2860`. Die Polygone benachbarter IDs sind verschieden. Die nahe beieinanderliegenden Originalpositionen von 318/319A erklären die frühere Textkollision; die Zielgeometrie wird nicht aus einer Textposition abgeleitet.

## Visuelle Prüfung und Messung

24 identische Vorher-/Nachher-Szenarien: drei Etagen, beide Themen, Gesamtansicht und 3-fach vergrößerter Zielausschnitt. Smartphone: 1080×2400 Pixel bei Dichte 3; Tablet-Viewport: 1920×1200 bei Dichte 1,5, auf demselben Emulator. Zusätzlich wurde die reguläre App über die echte Suche/API getestet. Die Displayübersteuerung wird zurückgesetzt.

Die offizielle [TU-Website](https://navigator.tu-dresden.de/) wurde für alle drei Etagen und Detailausschnitte im Browser geprüft. Ein auf logische Pixel normalisierter BEY-Vergleich zeigt Referenz, Ausgangsdarstellung und beide neuen Themen nebeneinander. Website und App haben unterschiedliche Bedienleisten; diese Referenz ist ein geometrisch angenäherter Vergleich, kein pixelidentisches Website-Golden. Die AKORA-Serie spielt den originalen `master`-Painter mit denselben Daten/Kameras ab; nur dessen Fit-Ausdehnung und Zentrierung wurden für den Vergleich angeglichen. Produktionscode wird dadurch nicht ersetzt.

Profile-Messung: BEY 03, Zielausschnitt, 221 gewertete Frames je Bewegung, 20 Anlauf-Frames ausgeschlossen.

| Bewegung | Version | UI p95 | Raster p95 | Dekodierte Kacheln/Symbole |
|---|---|---:|---:|---:|
| Verschieben | Ausgang | 0,270 ms | 17,831 ms | 112,52 MiB |
| Verschieben | Neu | 0,236 ms | 17,772 ms | 8,80 MiB |
| Zoomen | Ausgang | 0,277 ms | 7,130 ms | 112,52 MiB |
| Zoomen | Neu | 2,437 ms | 5,785 ms | 8,80 MiB |

Das zusätzliche Zeichnen beim Zoom erhöht die UI-Zeit, bleibt in diesem Versuch unter dem Framebudget. Die Rasterzeit verbessert sich. Verschieben liegt bei beiden Versionen im Emulator stellenweise knapp über 16,7 ms. Der Bildspeicherwert ist `Breite × Höhe × 4` der aktiven dekodierten Bilder, keine Aussage über den gesamten Prozess-/GPU-Speicher. `dumpsys meminfo` zeigte etwa 91–112 MiB PSS ohne entsprechende deutliche Gesamtsenkung. Rohdaten liegen unter `renderer-evidence/performance`. Der Versuch misst Zeichnen mit geladener Karte, keine Netzlatenz und keine reale Geräte-GPU.

## Tests und Artefakte

- Gesamtlauf mit Originalfixtures: 60 Tests bestanden; ein älterer optionaler Private-Plan-Test ohne dessen separates Fixtureformat übersprungen. Standardtests einschließlich synthetischer Goldens, Suche, Filter, Information, Etagenwechsel und Gesten bestanden.
- 24 strikte lokale Goldens mit eingefrorenen Originalplänen und ein Test der benachbarten Raum-IDs bestanden. Keine Bildtoleranz eingeführt. Originaldaten/Goldens bleiben im ignorierten `data/renderer-fixtures`; vier kleine synthetische Referenzen sind versioniert. Die Referenzen wurden auf Windows geprüft; andere Skia-/Hostversionen können Rasterabweichungen zeigen.
- Neue Tests prüfen Farbton/Alpha, zoomfeste Zielkontur, vollständigen Kachelwechsel, veraltete Anfragen, Fehler/Retry, Qualitätsobergrenze und echte leere HTTP-200-Kacheln.
- Analyse: keine Fehler/Warnungen, 40 bestehende Stilhinweise außerhalb des überarbeiteten Renderers. `flutter analyze` beendet sich deshalb mit 1; `--no-fatal-infos` besteht.
- Reguläre Debug-APK mit `lib/main.dart` erfolgreich gebaut und im Emulator installiert: `F:\apps\Codex\renderer-evidence\campus-navigator-renderer-test.apk`.
- APK-SHA256: `22ed244a85a63fb760d33c3bca6efc223d913323808a143d5da92edb89e75aa4`.
- Bilder, Vergleichsgalerie, Referenzen und Messdaten: `F:\apps\Codex\renderer-evidence`; Einstieg `index.html`, Detailvergleich `comparisons/bey03-reference-detail.png`.

Nachvollziehbare Produktionsschritte: `d4d624c` (Schrift/Kontur), `d721836` (leere Kacheln), `beb033b` (Rasterfarben/Alpha), `c43f331` (adaptive Auflösung und sichere Wechsel). Keine neuen App-Abhängigkeiten; Suche, API-Endpunkte, Gebäude-/Etagenauswahl und Informationsansicht wurden erhalten.

Verbleibende Grenzen: Geprüft wurden die drei angeforderten Etagen, kein vollständiger Campusbestand und kein physisches Android-Gerät. Sehr dichte Gesamtansichten blenden kollidierende Nebenbeschriftungen aus; hineinzoomen macht sie wieder lesbar. Nach einem tatsächlichen Downloadfehler bleibt die letzte komplette Stufe sichtbar; ein erneuter Zoomwechsel beziehungsweise erneutes Öffnen versucht den Abruf nochmals.

## Reproduktion

PowerShell im Repository:

```powershell
. .\tools\dev-env.ps1
$qaPython = Join-Path $env:USERPROFILE '.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
& $qaPython tools/fetch-renderer-fixtures.py
flutter test --dart-define=REAL_PLAN_DIR=F:\apps\Codex\campus-navigator\data\renderer-fixtures --dart-define=FLUTTER_FONT_DIR=F:\apps\Codex\toolchains\flutter-3.24.5\bin\cache\artifacts\material_fonts
flutter build apk --debug --target lib/main.dart
```

Für neue Golden-Referenzen bewusst `--update-goldens` verwenden und anschließend visuell prüfen. Für Emulatorserien in einem zweiten Terminal `& $qaPython -m http.server 8765 --bind 127.0.0.1 --directory data/renderer-fixtures` ausführen, `tools/renderer_preview.dart` bauen und installieren; `& $qaPython tools/capture-renderer.py <Ausgabeordner>` erstellt die 24 Szenarien, `--legacy` die AKORA-Serie. `tools/benchmark-renderer.py` benötigt eine Profile-APK dieser Vorschau. Die Vorschau verwendet denselben produktiven Kachelloader gegen eingefrorene Antworten. Danach stets die reguläre APK installieren; die Vorschau enthält keine Suchoberfläche.

## Nachprüfung: größere Raumnummern und unterscheidbare Gänge

Ausgangsstand ist Commit `6b057e2`; dessen Screenshots bleiben im Evidenzordner `final` erhalten. Die feste Beschränkung auf 12 logische Pixel ließ normale Raumnummern auch beim Hineinzoomen klein bleiben. Sie beginnen jetzt bei 14 und wachsen kontrolliert bis 20 Pixel; Zielnummern von 18 bis 24 Pixel. Die Website dient mit ihrer zoomabhängigen Schrift und 24-Pixel-Obergrenze als Referenz. Serverpositionen, individuelle Platzbegrenzung, einzeilige Darstellung und Kollisionsprüfung bleiben erhalten. Sehr kleine Räume können weiterhin kleinere Beschriftungen benötigen.

Alle drei Originalpläne enthalten `korridorData` und `vestibulesData` mit echten Gang-/Vorbereichspolygonen, aber `fill: null`. Die bisherige Schleife übersprang sie deshalb. Diese Geometrie erhält nun eine ruhige blaugraue Füllung: hell `#dce6e9`, dunkel `#303f46`. Sie liegt unter Raumfüllungen, Zielhervorhebung und sämtlichen Original-PNGs. Keine aus Gebäudegrenzen geschätzte Innenfläche, keine neuen Pixeltransformationen oder Abhängigkeiten. Für Etagen ohne diese Serverpolygone bleibt der bisherige Hintergrund erhalten.

24 gleiche Emulatoransichten (BEY 00/E25, BEY 03/318, APB 00/E069; hell/dunkel, Smartphone/Tablet, Gesamtansicht/Zielausschnitt) wurden aufgenommen und visuell verglichen. 318 und 319A bleiben im Zielausschnitt getrennt lesbar; Außenflächen und Innenhöfe bleiben ausgespart. Vergleichsgalerie: `F:\apps\Codex\renderer-evidence\labels-corridors\index.html`. Die bisherigen Rasterfilter und die adaptive Kachelauflösung wurden nicht verändert.

61 Tests einschließlich 24 aktualisierter Originalplan-Goldens bestehen, ein optionaler alter privater Fixturetest bleibt übersprungen. Ein zusätzlicher Pixeltest prüft in beiden Modi die exakten Gang-/Vorbereichsflächen, unveränderten Außenhintergrund und darüber erhaltene Wandlinien. Analyse weiterhin ohne Fehler/Warnungen bei 40 bestehenden Stilhinweisen. Reguläre Android-Debug-APK: `F:\apps\Codex\renderer-evidence\campus-navigator-labels-corridors-test.apk`.
