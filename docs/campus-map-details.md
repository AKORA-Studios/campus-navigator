# Interaktive Campuskarte – technischer Bericht

Stand: 14.10.2026. Entwicklung ausschließlich auf `feature/campus-map`, ausgehend
von `aab8dba`. Sicherung und Architektur vor Beginn: [Baseline](campus-map-baseline.md).

## Verhalten und Integration

Die bisherige Raumsuche bleibt der Startbildschirm. Eine kompakte Material-3-
Navigationsleiste wechselt zwischen Raumsuche und Campuskarte. Die Karte wird
erst beim ersten Aufruf erzeugt. Suchtext, Favoriten, Verlauf, Auswahl und Kamera
bleiben beim Wechsel erhalten. Auf Telefonen steht die Gebäudeinformation unter
der Karte, auf Tablets ab 840 logischen Pixeln in einer 320-Pixel-Seitenspalte.
Details scrollen bei wenig Platz oder großer Schrift. Die Tastatur erhält Platz;
die Suche zentriert das Gebäude erst nach ihrem Schließen.

Die Karte bietet Verschieben, Pinch-/Doppeltipp-Zoom, Zoomtasten, Campus-Rückkehr,
lokale Gebäudesuche sowie einen expliziten Standortknopf. Sie folgt zunächst dem
Systemthema; der Kartenstilknopf schaltet die Karte zusätzlich unabhängig um.
Gebäude erhalten eine kontrastierende Auswahlkontur und Kürzel ab Zoom 16.
Leere Kartenflächen wählen kein vermeintlich nächstes Gebäude aus.

Die Etagenplanaktion verwendet den gemeinsamen `loadBuildingFloor`-Resolver:
Gebäudeseite lesen, einen tatsächlich verlinkten Plan wählen, Etage 00 bevorzugen,
anschließend den bestehenden `BuildingScreen` öffnen. Bei fehlenden Plänen bleibt
die Karte erhalten und die Aktion wird als „Kein Etagenplan“ deaktiviert.
Netzwerkfehler bleiben wiederholbar. Nach einem Tab-Wechsel werden verspätete
Etagenplanantworten verworfen und ihre Bilder freigegeben.

Renderer, `FloorView`, Etagenparser, Raumhervorhebung und alle Originalplan-Goldens
bleiben unverändert. Die Campuskarte erzeugt keine erfundenen Favoriten-IDs:
TU-Gebäudekürzel und Suchregionen sind unterschiedliche Identitäten. Favoriten
werden wie bisher über die Raumsuche gespeichert und geöffnet.

## Kartenbibliothek und Anbieter

| Lösung | Bewertung für dieses Projekt |
| --- | --- |
| [flutter_map](https://docs.fleaflet.dev/) | Pure Flutter, OSM-Rasterquellen, integriertes Polygon-Hit-Testing/Culling, Widgets und Tests ohne neue native Karten-Engine; gewählt |
| [MapLibre GL](https://pub.dev/packages/maplibre_gl) | Flexible native Vektorkarten; die aktuelle Version verlangt eine neuere Flutter-/Dart-/JDK-Toolchain, zusätzlich Stil-/Tile-Infrastruktur nötig |
| [Google Maps Flutter](https://pub.dev/packages/google_maps_flutter) | Gute Android-Integration, aber Google-Kartenplattform und API-Konfiguration statt der gewünschten OSM-Basiskarte |

`flutter_map 7.0.2` und `latlong2 0.9.1` passen zur bestehenden Flutter-3.24.5/
Dart-3.5.4-Toolchain. Version 8 benötigt ein SDK-Upgrade, das bewusst separat
bleibt. Wegen der `web`-Constraints waren `package_info_plus 6.0.0`, `http 1.2.2`
und wenige transitive Lockdatei-Anpassungen nötig. Kein pauschales Paketupgrade.

Quelle: `https://tile.openstreetmap.org/{z}/{x}/{y}.png`.
Die [OSMF-Kachelrichtlinie](https://operations.osmfoundation.org/policies/tiles/)
ist berücksichtigt:

- Ständig sichtbarer Link „© OpenStreetMap contributors“; TU-Gebäudedaten separat
  verlinkt. Die Quellenzeile liegt außerhalb des Auswahlbereichs und bleibt sichtbar.
- Identifizierender User-Agent `CampusNavigator/1.2` mit Repository-Kontakt-URL.
- Eigenständiger persistenter Kachelcache: HTTP-Cache-Control und ETag über
  `flutter_cache_manager`, ohne Cache-Header standardmäßig sieben Tage.
  Höchstens 1500 Cacheeinträge, Bereinigung nach 30 Tagen Nichtbenutzung.
- Höchstens vier gleichzeitige Abrufe, Standard-Kachelaktualisierung der Bibliothek,
  `panBuffer: 0`, abgebrochene noch wartende Ausschnitte werden übersprungen.
  Höhere Pixeldichte wird mit passenden sichtbaren Kacheln bedient.
- Keine Gebietsdownloads, Hintergrundvorbereitung, Zoomstufen-Scans oder Offlinepakete.
  Offline werden ausschließlich zuvor betrachtete, vorhandene Kacheln wiederverwendet.
- Dunkelstil als lokale GPU-Farbmatrix derselben Quelle; kein zweiter Tileabruf.

Die Kachel-URL lässt sich beim Build mit `--dart-define=CAMPUS_TILE_URL=...`
ersetzen. Bei einem Anbieterwechsel müssen Attribution, Cache- und Nutzungsregeln
im Quellcode passend angepasst werden. OSM ist ein Best-effort-Dienst ohne SLA.

## Tatsächlich geprüftes TU-Datenformat

Öffentlicher Einzelabruf:
[GET /m/json_gebaeude/all](https://navigator.tu-dresden.de/m/json_gebaeude/all).
Keine zusätzliche formale API-Spezifikation lag im Repository vor. Maßgeblich
sind daher die gespeicherte Originalantwort und der dokumentierte Testauszug
unter `test/fixtures/`.

- JSON-Liste mit **217 Gebäuden**, `application/json; charset=ISO-8859-1`.
- `krz`, `name`, `teilgeb` mit Gebäudenummern und Adressbestandteilen,
  `stdetage`, `punkte`, `eingänge`, weitere optionale Informationen.
- `punkte` ist eine Liste unabhängiger Umrisse aus `{x, y}`. **x = Längengrad,
  y = Breitengrad in Grad**. Beispiel erster APB-Punkt:
  `LatLng(51.0255663, 13.7234797)`. Die Kartenbibliothek übernimmt Web Mercator;
  keine empirischen Canvas-Offsets oder doppelte Projektion.
- Vollständiger Parserlauf: **217 Gebäude, 404 gültige Umrisse, 5187 Eckpunkte**.
  `U0021A` und `PA4` haben keine nutzbaren Umrisse und bleiben suchbar.
- Kürzel mit Umlauten wie GÖR/MÜL werden exakt erhalten. Die echte TU-Suche
  bestätigte Kennungen `dresden/geb/gör`, `dresden/geb/mül`, `johannstadt/geb/dür`.
  Keine Transliteration in erfundene URL-Kürzel.
- Alle 217 Eingangslisten waren leer. Das Routenziel ist daher ausdrücklich als
  **Gebäudepunkt, Eingang nicht bestätigt** beschriftet. Verwendet wird die Mitte
  der Begrenzung des größten Umrisses. Die externe Google-Maps-Wegbeschreibung
  enthält nur das Ziel und den Fußgängermodus, keinen ausgelesenen Nutzerstandort.
- Fehlerhafte Punkte verwerfen den betroffenen Umriss vollständig, statt Lücken
  mit erfundenen Verbindungslinien zu überbrücken. Andere gültige Umrisse bleiben.
  Nicht endliche/ungültige Koordinaten, degenerierte Ringe und übergroße Geometrien
  werden abgefangen. Es gibt keine Annahme, dass `stdetage` einen Plan garantiert.

## Cache, Standort und Ausfälle

Die Gebäudedaten haben einen separaten öffentlichen Cache mit 24 Stunden
Frischezeit. Vorhandene Daten erscheinen sofort; abgelaufene Daten werden einmal
im Hintergrund aktualisiert. Bei Fehlern bleibt der alte Datensatz mit Hinweis
sichtbar. Ein ungültiger Serverdatensatz überschreibt keinen gültigen Cache.
Ohne TU-Daten bleibt die OSM-Basiskarte bedienbar. Cache-Schreibfehler werden
ebenfalls angezeigt. Manuelle Wiederholungen sind möglich; keine Pollingschleife.

Standortzugriff beginnt ausschließlich nach dem Tippen auf den Standortknopf.
Android fragt die Laufzeitberechtigung ab. Ablehnung und abgeschaltete Dienste
haben verständliche Meldungen; die übrige Karte funktioniert weiter. Die Anzeige
ist eine ausdrücklich beschriftete letzte Einzelmessung, kein Hintergrundtracking.
Erneutes Tippen misst neu und zentriert. Die App fordert keine Hintergrundberechtigung.

Polygondefinitionen werden zwischen Pan-Frames wiederverwendet, unsichtbare
Umrisse durch die Bibliothek ausgeblendet und Punkte nicht pro Frame neu geparst.
Das verhindert unnötige Arbeit bei gleichzeitig vielen sichtbaren Gebäuden.

## Reproduktion

```powershell
. .\tools\dev-env.ps1
flutter analyze --no-fatal-infos
flutter test --dart-define=REAL_PLAN_DIR=F:/apps/Codex/campus-navigator/data/renderer-fixtures --dart-define=FLUTTER_FONT_DIR=F:/apps/Codex/toolchains/flutter-3.24.5/bin/cache/artifacts/material_fonts
flutter build apk --debug
flutter build apk --release
dart run tools/inspect_campus.dart F:/apps/Codex/campus-map-evidence/tu-buildings.json
# Nach Installation im vorhandenen emulator-5554:
# Mit dem Python-Runtimepfad aus docs/development-environment.md ausführen:
# python tools/smoke-campus-map.py
```

## Abschließende Prüfung und Artefakte

Anwendungscode: Commit `63e7b86cb5e595c86f66701f1f327776cffc0c9b`.
Die ersten Schritte liegen in `e30b3d0` (Feature), `6c77f9e` (Umlautkürzel)
und `660a594` (Zentrierung nach Tastaturende). Der Fokus-Fix `5e1b397` verhindert, dass
die Gebäudesuche nach dem Rückweg aus dem Etagenplan erneut den Fokus erhält.
`2e47a0b` entfernt die verzögerte Kachelaktualisierung: Sie hatte beim Suchzoom
das Laden neuer Detailkacheln verhindert. Ein gezielter Widget-Test prüft jetzt
die tatsächlich gestarteten nativen Zoom-19-Kacheln auf einem hochauflösenden
Display. Der native Bildvergleich bestätigt den scharfen Nachladezustand.
`63e7b86` trennt außerdem ausstehende dekodierte Kachelbilder nach ihrer
Abbruch-Lebensdauer. Ein zuvor abgebrochener Abruf darf seinen transparenten
Platzhalter nicht an eine neue sichtbare Kachel derselben URL vererben.
Ein echter ImageStream-Test reproduzierte diesen Fehler vor der Korrektur und
prüft jetzt die tatsächlich ausgegebenen Pixel; der Dateicache bleibt URL-basiert.

| Prüfung | Ergebnis |
| --- | --- |
| `flutter test` mit Originalplan-Fixtures | **105 bestanden**, ein optionaler alter privater Fixturetest übersprungen; darunter 24 unveränderte Originalplan-Goldens |
| Analyse | Keine Fehler oder Warnungen, 38 bereits vorhandene Stilhinweise; Standardaufruf Exit 1 wegen dieser Infos, `--no-fatal-infos` erfolgreich |
| Android-Debug-Build | Erfolgreich |
| Zusätzlicher Release-Build | Erfolgreich; vorhandene AGP-/Kotlin-Metadatenhinweise beim Android-Release-Lint bleiben bestehen |
| APK-Signaturen | Beide APKs erfolgreich geprüft, Signaturschemata v1/v2 |
| Android-14-Emulator | Vollständiger Durchlauf mit finaler Release-APK erfolgreich: Telefon 1080×2400/Dichte 420 und Tablet 1920×1200/Dichte 240 |

Der Geräteablauf prüfte: Campus öffnen, APB suchen und durch Polygonberührung
auswählen, echten Etagenplan 00 öffnen, mit erhaltener Auswahl zurückkehren,
Barkhausen auswählen, helle/dunkle Karte verwenden, Standort nativ verweigern
und anschließend ausdrücklich erlauben, Tablet-Seitenbereich und Verschieben,
Neustart ohne Wi-Fi/Mobilfunk mit vorhandenen Cacheeinträgen sowie vorhandene
Favoriten und Raumsuche APB E069 einschließlich Raumhervorhebung.
Die Favoritenliste war vor und nach dem Ablauf identisch.
Zusätzlich wurden der Android-System-Dunkelmodus samt Navigationsleiste,
GÖR → echter Etagenplan 00 → zurück sowie die Routenübergabe an die installierte
Google-Maps-App erfolgreich geprüft. Der externe Activity-Wechsel ist in
`route-external-activity.txt` protokolliert. Eine Navigation vor Ort wurde nicht durchgeführt.

Im `auto`-Grafikmodus des lokalen Emulators 37.2.12 traten bei wiederholten
Größen-/Themenwechseln Grafikartefakte bis hin zu fehlenden Schriftzeichen auf.
Ein Neustart allein beseitigte sie nicht dauerhaft. Die abschließenden Nachweise
verwenden deshalb einen Kaltstart mit `-gpu swiftshader -feature -Vulkan -no-snapshot`.
Die unveränderte APK wurde auf diesem Testpfad erneut geprüft; die App-Renderer
wurden nicht auf Softwaredarstellung umgestellt. Android dokumentiert Software-
Grafik als Alternative bei Problemen mit `auto`/`host`:
[Grafikbeschleunigung des Emulators](https://developer.android.com/studio/run/emulator-acceleration).
Die genaue Ursache des `auto`-Befunds bleibt ungeklärt; die Prüfung ersetzt
keinen Hardware-/Bildratenvergleich auf physischen Geräten.

Androids UIAutomator lieferte gelegentlich eine leere Hierarchie und wurde vom
Testskript erneut abgefragt. Die abschließende Laufzeitprüfung enthielt keine
Flutter- oder AndroidRuntime-Fehler. Grafikmodus und Startprotokolle stehen
separat unter `render-environment.json` und `emulator-software.log`.

Alle Dateien liegen unter `F:\apps\Codex\campus-map-evidence`:

- `campus-navigator-1.2.0-campus-map.apk`: installierbare universelle Release-Test-APK,
  54.887.536 Bytes / 52,3 MiB, Version **1.2.0 (3)**, Android 6/API 23 oder neuer,
  ARM32, ARM64 und x86_64; bestehende lokale Testsignatur.
- `campus-navigator-1.2.0-campus-map-debug.apk`: zusätzlich geforderte Debug-APK,
  218.170.145 Bytes. Beide APKs wurden als Updates installiert, ohne App-Daten zu löschen.
- `index.html`: Galerie unveränderter Emulatoraufnahmen auf beiden Bildschirmgrößen.
- `manifest.json`: Prüfsummen, Quellstand und Geräteprüfungen.
- `flutter-test-final.log`, `flutter-analyze-final.log`, `build-debug-final.log`,
  `build-release-final.log`, `emulator-smoke.log`, `emulator-runtime-errors.txt`:
  tatsächliche Prüfprotokolle.
- `before-campus-map.bundle`: verifizierte Sicherung vor dem Feature.
  `campus-map-final.bundle`: abschließende Sicherung einschließlich neuer Commits.
  Die bisherigen Branchspitzen und `master` wurden nicht verändert; kein Push.

SHA256 der Release-Test-APK:
`e98ae0442f49a3cedcc21c63d1f4679e324a22227104099f89aa4debe545e9be`.
SHA256 der Debug-APK:
`578bf892ae2732e0b22c720a899ea5da78f60f3835b31f2b80cfd3afd0dc3662`.

## Verbleibende Einschränkungen

- Noch keine Prüfung auf physischen Android-Geräten; reale GPS-Genauigkeit,
  Akkunutzung über längere Zeit und Bildraten auf schwächeren Geräten bleiben offen.
  Die Standortaufnahme zeigt eine simulierte Emulatorposition.
- Das vorhandene `location 6.0.2` prüft unter Android die genaue Standortfreigabe.
  Eine ausschließlich ungefähre Freigabe kann als verweigert behandelt werden;
  die Basiskarte und Gebäudesuche bleiben dabei nutzbar. Kein Hintergrundtracking.
- Keine validierten Eingangsdaten; ein Gebäudepunkt kann in einem Innenhof liegen.
  Es gibt keine Zusage eines barrierefreien Zugangs und keine eigene Wegeführung.
- Keine flächendeckende Offlinekarte. Ein Erststart ohne Netz hat keinen
  Kachel-/Gebäudebestand; vorhandene Cachedateien können vom Betriebssystem entfernt werden.
- Zwei Datensätze haben keine zeichnungsfähige Geometrie. Adressen stammen aus
  der TU-Antwort und können mehrere Teilgebäude zusammenfassen. Änderungen am
  undokumentierten API-Schema oder an der TU-Planverfügbarkeit bleiben externe Risiken.
- Die bestehenden Flutter-/Android-Werkzeuge wurden beibehalten. Ein Upgrade der
  Flutter-3.24-Toolchain, ein Wechsel auf `flutter_map 8` und eine neuere Android-Lint-
  Toolchain gehört in einen gesonderten, erneut visuell geprüften Schritt.
- Die Git-Bundles liegen lokal auf demselben Datenträger; keine externe oder
  Cloud-Sicherung. Die APK ist eine lokal signierte Testausgabe, keine Store-Veröffentlichung.

