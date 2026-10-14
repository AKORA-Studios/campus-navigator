# Campus Navigator: gezielte UI- und Dark-Mode-Korrekturen

Stand: 12.10.2026. Privater technischer Entwicklungsversuch. Ausgangspunkt ist
`master` bei `0441326300600ceff155dad0e1b0a89b2d4f3710`. Alle Änderungen liegen lokal
auf `work/ui-polish-and-darkmode`. `master` wurde weder geändert noch gepusht.

## Umfang und Prioritäten

Die funktionierenden Etagenpläne und ihre originalen Bildkacheln bleiben erhalten.
Die Prüfung basiert auf dem Flutter-Quellcode, den drei Geräte-Screenshots,
dem Machbarkeitsbericht, seinen API-Belegen und gezielten Einzelabrufen.
Der HTML-Prototyp ist eine technische Referenz; seine Karten-/Dashboard-Gestaltung
wurde nicht als Designvorlage übernommen.

| Priorität | Befund vorher | Änderung / konkreter Nutzen |
| --- | --- | --- |
| P0 | Dunkelmatrix mischt RGB-Kanäle; schwarze Striche bleiben schwarz | RGB-Inversion mit begrenzter Helligkeit und unveränderter Alpha-Komponente; technische Linien bleiben sichtbar |
| P0 | Painter vergleicht Bilddaten mit sich selbst und ignoriert Theme/Filter | Unveränderliche Snapshots von Helligkeit, Label-Farbe und Filtern; Bilder melden Ankunft über ihren Notifier |
| P0 | Überlappende BEY-Beschriftungen; sehr große Einzeltexte | Raum-ID → serverseitige Ebene/Index → Polygon; begrenzte Schriftgrößen, ausgewähltes Label erhält Kollisionsvorrang |
| P0 | Cache-Konstruktor weist Parameter sich selbst zu | Tatsächliche Initialisierung; gültige Einträge wiederverwenden, abgelaufene neu laden |
| P1 | Alle Kachelanfragen starten sofort, Fehler entweichen | Vier Worker je Etage und global höchstens vier laufende Bild-HTTP-Anfragen; Teilfehler bleiben lokal |
| P1 | Dekodierte Bilder bleiben beim Verlassen erhalten | Nur die aktuelle Etage behält Bilder; Dispose stoppt neue Aufgaben und gibt Bilder/Codec frei |
| P1 | Vollbreites Infofenster verdeckt standardmäßig 30 % der Ansicht | Smartphone startet mit 64px-Header; ab 840px Breite 300px-Seitenbereich |
| P1 | Plan wird nach Bildschirmhöhe statt verfügbarer Fläche gezeichnet | LayoutBuilder, zentrierte Einpassung des vollständigen Kachel-Canvas; kein Plan unter dem eingeklappten Header |
| P1 | Zoom kann den Plan fast unsichtbar verkleinern | Untergrenze 0,8, Obergrenze 16; erreichbare 48px-Schaltfläche „Gesamte Etage“ |
| P1 | Gesuchter Raum auf dem Telefon beim Start sehr klein | Moderate Zielzentrierung bis Faktor 3, Tablet startet mit Gesamtsicht |
| P1 | Rückwechsel zur Etage verliert das Ziel, Belegungsaktion bleibt bei falscher Etage aktiv | Originaler Raum-URL wird erneut verwendet; Belegungsdaten/Fehler werden beim Wechsel zurückgesetzt |
| P1 | Suche nach jedem Tastendruck; nur acht Ergebnisse, veraltete Vorschläge | 400ms-Pause bzw. sofortige Enter-Suche; alle gelieferten Treffer; veraltete Antworten werden ausgeblendet |
| P2 | Geringer Hellmodus-Kontrast der türkisfarbenen Texte und teilweise transparente Vordergrundfarben | Dunklerer Akzent im Hellmodus, heller im Dunkelmodus; opaque Material-3-Farbpaare |

## Raumzuordnung BEY 318

Live bestätigt wurden die folgenden Suchpfade:

| Suche | Technische Raum-ID | Etage |
| --- | --- | --- |
| APB E069 | `542100.2860` | `00` |
| BEY 318 | `111103.5220` | `03` |

Die BEY-Etagenantwort enthält für `111103.5220` ausdrücklich `raeume`, Index `19`.
`raumclick.raeume19` benennt diesen Raum als `318`; die runde Geometrie ist korrekt.
`319A` besitzt die andere ID `111103.5240` und Index `21`. Seine Labelposition liegt
nur etwa 12 Plan-Einheiten von der Beschriftung `318` entfernt. Die alte individuell
skalierte Schriftgröße ließ die beiden Texte ineinanderlaufen. Es gibt in diesen
Belegen keinen Hinweis darauf, dass der Suchtreffer versehentlich Raum 319A auswählt.
Die ausgewählte Beschriftung liegt in den getesteten APB-/BEY-Daten jeweils im
zugehörigen Polygon. Die APB-ID wurde zusätzlich im strukturierten Etagen-JSON gefunden.

Der neue Parser bevorzugt den ID-Eintrag in `searchhelp` und prüft ihn, wenn vorhanden,
gegen `raumclick`. Ein unbekannter ID-Eintrag darf bei vorhandener Mapping-Tabelle keine
zufällige Legacy-Hervorhebung übernehmen. Ein kleiner künstlicher Test enthält bewusst
einen widersprüchlichen `permahighlightRaum`-Aufruf und prüft genau diesen Fall.
Die größere Nachbarfläche und die ursprünglichen Labeldaten werden nicht verändert;
beim Zeichnen wird nur ein tatsächlich mit dem Ziel-Label überlappender Nachbartext
unterdrückt. Beim Etagenaufruf ohne Ziel bleibt die normale Beschriftung erhalten.

## Kleines Designsystem und Entscheidungen

- Material 3, bestehende Typografieskala. AppBar: titleLarge, Seitendetails: titleMedium,
  Header: titleSmall; Adressüberschrift auf 16px begrenzt.
- Eine ruhige Türkis-Akzentfamilie: Hellmodus `#006C68`, Dunkelmodus `#8BD2C9`.
  Planhintergrund hell weiß, dunkel `#161C20`; warme, gedämpfte Zielmarkierung.
- Abstände 8/12/16px; Toolbar 52px; kompakter Info-Header 64px; Touchziele mindestens
  Material-übliche 48px. Rundung 12px nur am ausziehbaren Fenster, keine neuen Schatten.
- Layerfolge: Flächen → vollständige Rasterdetails → Symbole → Zielkontur → Labels.
  Transparente Flächen bleiben transparent; Kontur und kleine Labelunterlage vermeiden
  eine kräftige deckende Färbung der gesamten technischen Zeichnung.
- Der Header lässt sich per Tipp öffnen und wieder schließen; Ziehen und Snap-Punkte
  bleiben erhalten. Schließen bedeutet Einklappen, sodass die Details erreichbar bleiben.
- Tablet-Schwelle 840px lässt 540px Planbreite neben 300px Details zu. Kleinere Tablets
  oder Hochformat nutzen die Telefonvariante. Die Seitenansicht beginnt oben.

Die maximale Bildqualität und sämtliche Kachelpfade sind unverändert. Caching und
Lebensdauer wurden korrigiert, ohne die detaillierten Pläne durch grobe JSON-Flächen
zu ersetzen. JSON ist für Raum-Identität und Metadaten langfristig sinnvoll. Eine
Migration braucht jedoch einen Vertragstest für Kachel-Metadaten, Symbole und die
Koordinatenabbildung. Diese Version enthält daher noch den vorhandenen HTML-Adapter.

## Netzwerk und Speicher

GET-Text und Such-POSTs nutzen denselben Cache; Suchparameter gehören zum Cache-Key.
Zeitlimit pro Request: 25 Sekunden. Gleiche gleichzeitig ausstehende Antworten werden
zusammengefasst. Bildaufrufe nutzen den injizierten Client. Geteilt werden Antwortbytes,
keine dekodierten ui.Image-Instanzen: jede Etage besitzt und entsorgt ihre Bilder.
Kein Gesamtcampus-Crawl und keine neuen Abhängigkeiten im App-Betrieb außer der expliziten
Deklaration des ohnehin verwendeten, bisher transitiven `url_launcher`.

Bei Qualität 8 ergibt das APB-Beispiel 104 Kacheln, BEY 152 Kacheln. Bei maximal 480×480
RGBA pro Kachel sind das rechnerisch ca. 91 bzw. 134 MiB dekodierte Bilder. Das ist eine
Obergrenze, keine gemessene Speicherbelegung. Es bleibt ein sinnvoller Anlass für späteres
sichtbarkeitsabhängiges Kachelladen. Aktuell werden beim Etagenwechsel alte Bilder nach
dem Frame entsorgt; Rückwechsel dekodiert die frischen Cache-Bytes erneut. Es gibt keinen
stillen Qualitätsverlust. Langsame Netze können beim ersten Laden weiterhin warten lassen.

Die eigenen TU-Prüfabrufe lagen mindestens zehn Sekunden auseinander. Für die privaten
Vergleichsbilder wurden nur fünf Kacheln in Qualitätsstufe 1 verwendet (APB: zwei,
BEY: drei). Keine originalen HTTP-Bodies oder Bildkacheln wurden ins Repository aufgenommen.

## Qualitätssicherung und Grenzen

- `flutter test`: 29 erfolgreiche Tests, ein optionaler privater Plan-Test ohne Parameter
  übersprungen. Enthalten sind vorhandene API-/Navigationstests, Cache-/Charset-/Fehlerfälle,
  Identitätsprüfung, Theme-/Filterwechsel, Gesten, Etagenwechsel und Suche.
- Vier versionierte Golden-Bilder: selbst erstellte künstliche Geometrie mit transparentem
  Raster und schwarzen Linien, jeweils Telefon/Tablet und Hell/Dunkel. Sie werden bei einem
  normalen Testlauf tatsächlich verglichen und enthalten keine TU-Daten.
- Privater Plan-Test: erfolgreich mit APB E069 und BEY 318, je 360×800 und 1280×800 sowie
  Hell/Dunkel. Prüft Raum-ID, Labelposition im Polygon und UI ohne Layoutfehler; exportiert
  acht Flutter-Renderbilder. Zusätzlich wurde der alte Renderer aus dem Basiscommit unter
  denselben Bedingungen gerendert. Separate Vergleichstafeln liegen im Testpaket.
- Interaktionstests bei 320×720 und 1280×800: Verschieben, Pinch-Zoom, Fit-Button,
  Filterauswahl, Header öffnen, Fenster nach unten ziehen, Etage 01 wählen und zur
  ursprünglichen Raum-URL zurückkehren. Ein dabei gefundener 320px-Overflow wurde behoben.
- `flutter analyze --no-fatal-infos --no-fatal-warnings`: keine Fehler oder Warnungen,
  vorhandene Info-Lints verbleiben. Unabhängige verschachtelte Android-/iOS-Starterprojekte
  sind im Root-Analyzer ausgeschlossen. Normales `flutter analyze` meldet die Info-Lints
  weiterhin und ist deshalb kein komplett sauberer Lint-Lauf.
- `git diff --check`: ohne Whitespacefehler.

Die Bilder stammen aus Flutter-Widget-Rendering unter Linux, mit Roboto/MaterialIcons,
logischen Pixelmaßen und ohne Android-Systemleisten. Im alten Canvas-Painter wurde für diese Vergleichsläufe die Schriftfamilie explizit
auf Roboto gesetzt, weil ein TextPainter ohne Familie im Flutter-Test sonst die
Platzhalterschrift Ahem verwendet. Geometrie, Größenberechnung und Zeichenreihenfolge
des alten Renderers sind unverändert. Die alten/neuen Telefonbilder
unterscheiden sich bewusst auch durch die neue Zielzentrierung. Stufe 1 ist gröber als
die tatsächliche maximale APK-Qualität. Eine echte Geräteprüfung, Bildratenmessung und
Hardware-Speicherprofilierung wurden nicht durchgeführt. Belegungsplan mit echter Anmeldung
und externe Karten-/Share-Apps wurden nicht live bedient.

Rechnerische Flächenauswertung bei 360×800: unüberdeckte Planfläche steigt von ungefähr
473px Höhe auf 628px, also ca. 33 %. Bei 1280×800 steigt sie trotz Seitenleiste von etwa
1280×473 auf 980×692px, also ca. 12 %. Das misst die sichtbare Zeichenfläche; der Nutzen
für einen individuellen Plan hängt zusätzlich von seiner Form und dem Zoom ab. Beim Tablet
ist vor allem der vollständige untere Planrand wieder zugänglich. Ein zusätzlicher Tipp
öffnet die eingeklappten Details auf dem Telefon; diese bewusste Abwägung gibt dem Plan
Vorrang. Der Zielraum benötigt dort üblicherweise weniger manuelles Zoomen. Eine gemessene
Zeitersparnis in einer Nutzerstudie wird nicht behauptet.

## Android und GitHub

Flutter/Dart: 3.24.5 / 3.5.4; Java 17; compileSdk 34, minSdk 23.
Die bereits im bisherigen Workflow temporär eingesetzten Kompatibilitätskorrekturen
(`win32 5.5.5`, Android-SDK-Bereinigung) sind jetzt im Projekt nachvollziehbar gespeichert.
Der Workflow heißt einheitlich `.github/workflows/build-apk.yml`. Er reagiert auf
`work/ui-polish-and-darkmode`, PRs gegen `master` und `workflow_dispatch`, führt Analyse
und Tests aus und lädt anschließend eine mit dem Debug-Key signierte APK hoch.

GitHub hat das Erstellen des gewünschten Branches mit HTTP 403
„Resource not accessible by integration“ verweigert. Deshalb kein Remote-Branch,
kein tatsächlich angelegter PR und kein verifizierter Actions-Lauf. Die PR-Beschreibung
ist vorbereitet. Der lokale APK-Build wurde versucht; reguläres Gradle scheiterte am
Netzwerk, der lokale Abhängigkeitsabruf wurde später durch eine abgebrochene
Netzwerkfreigabe beendet. Es gibt keine neue APK und keinen erfolgreich abgeschlossenen
Android-Kompilierungsnachweis. Das ist ausdrücklich noch offen.

## Bewusst zurückgestellt

Favoriten und Verlauf; neue Campuskarte mit Gebäudegeometrien; Wechsel auf JSON als
primären Floor-Adapter; Tap-Auswahl beliebiger Räume; Indoor-Routing; Offlinepakete;
sichtbarkeitsabhängige hohe Kachelqualität; vollständige Lint-/Architekturmodernisierung.
Die bestehende experimentelle Standort- und Freiraumsuche bleibt unverändert.
Ein persistenter Offline-Cache ist kein zugesicherter permanenter Download: das bestehende
Cache-System darf ältere Einträge entfernen, und abgelaufene Daten werden neu angefragt.

Vor einer Veröffentlichung bleiben AKORA-Code-Lizenz, TU-Planrechte und zulässige
Abruf-/Cache-Regeln zu klären. Diese Arbeit enthält keine massenhaften TU-Testdaten
und hat keine Nachrichten an Dritte versendet.

## Reproduktion

```sh
flutter pub get
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter build apk --debug
```

Optional mit privaten, extern bereitgestellten Belegen und den fünf PNG-Kacheln:

```sh
flutter test test/regression/private_plans_test.dart \
  --dart-define=PRIVATE_PLAN_DIR=/absolute/private-evidence \
  --dart-define=SCREENSHOT_DIR=/absolute/screenshots \
  --dart-define=FLUTTER_FONT_DIR=/absolute/flutter/bin/cache/artifacts/material_fonts
```

Erwartet werden `evidence/floorpage.body` (APB 00), `bey-floor.html` (BEY 03),
`APB00_1_0_0.png`, `APB00_1_1_0.png` und `BEY03_1_0_0.png` bis `BEY03_1_2_0.png`.
Die Testdatei bleibt ohne diese Angaben übersprungen. Die Dateien sind absichtlich
kein Bestandteil des öffentlich anwendbaren Patches.
