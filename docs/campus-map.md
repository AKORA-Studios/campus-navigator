# Campuskarte 1.2.0 – kurzer technischer Bericht

14.10.2026 · Branch **`feature/campus-map`** · Anwendungscode **`63e7b86`**.
Ausgangsstand `aab8dba` war sauber und wurde vor Beginn als vollständiges,
verifiziertes Git-Bundle gesichert. `master`, `feature/search-and-favorites`
und `codex/renderer-recovery` bleiben unverändert; kein Push.

## Ergebnis

Eine beim ersten Aufruf geladene Material-3-Campuskarte ergänzt die bisherige Startansicht.
Die untere Navigation wechselt schnell zwischen Karte und Raumsuche und erhält
Suchtext, Favoriten, Verlauf und Kamera. Gebäude lassen sich per Umriss oder
lokaler Suche auswählen. Telefon: kompakte Informationen unter der Karte;
Tablet: Seitenspalte. Heller/dunkler Kartenstil, Zoom, Verschieben und
Campus-/Standort-Rückkehr sind vorhanden.

`flutter_map 7.0.2` passt zur vorhandenen Flutter-3.24.5-Toolchain. OSM-Kacheln
erhalten sichtbare Quellenangaben, einen identifizierenden User-Agent,
HTTP-/ETag-Caching, maximal vier gleichzeitige Abrufe und ausschließlich
benötigte Ansichten. Keine Gebietsdownloads oder Offlinepakete.
Der Dunkelstil verwendet dieselben Kacheln mit lokaler Farbmatrix.

Die [öffentliche TU-Schnittstelle](https://navigator.tu-dresden.de/m/json_gebaeude/all)
lieferte ISO-8859-1-JSON: **217 Gebäude, 404 gültige Umrisse, 5187 Punkte**.
`x` ist Längengrad, `y` Breitengrad; die Bibliothek übernimmt die Kartenprojektion.
Umlautkürzel wie GÖR bleiben erhalten. Fehlerhafte Umrisse werden einzeln
verworfen; zwei Gebäude ohne Geometrie bleiben suchbar. Ein separater
24-Stunden-Gebäudecache bietet bei Netzausfällen vorhandene Daten an.

Der Etagenplan-Aufruf verwendet den gemeinsamen vorhandenen Resolver und öffnet
einen tatsächlich angebotenen Plan. Renderer, Etagenparser, Raumhervorhebung
und Originalplan-Goldens wurden nicht geändert. Die externe Route verwendet
einen Gebäudepunkt; ein Eingang ist ausdrücklich nicht bestätigt.
Standortzugriff erfolgt ausschließlich auf Knopfdruck als einzelne Messung.

## Nachweise

- **105 Tests bestanden**, ein optionaler alter privater Fixturetest übersprungen;
  darin 24 unveränderte Originalplan-Goldens und die bestehende Suche/Favoriten-Suite.
- `flutter analyze`: keine Fehler oder Warnungen, 38 vorhandene Stilhinweise.
  Standardaufruf deshalb Exit 1; mit `--no-fatal-infos` erfolgreich.
- Android-Debug- und Release-Build erfolgreich; Signaturen v1/v2 geprüft.
  Bestehende AGP-/Kotlin-Metadatenhinweise beim Release-Lint bleiben bestehen.
- Finale Release-APK im Android-14-Emulator geprüft: Smartphone 1080×2400,
  Tablet 1920×1200. APB per Polygon auswählen → Etage 00 → zurück;
  Barkhausen; beide Kartenstile; native Standortablehnung und Freigabe;
  Tablet-Verschieben; Offline-Neustart; unveränderte Favoriten und APB-E069-Raumsuche.
- Zusätzlich geprüft: Android-System-Dunkelmodus mit dunkler Navigation,
  GÖR-Auswahl samt echtem Etagenplan 00 und Rückweg sowie die tatsächliche
  Routenübergabe an die installierte Google-Maps-App.
- Ein im Rückweg erkannter Fokusfehler wurde behoben und abgesichert: Die
  Such-Tastatur öffnet sich nach dem Etagenplan nicht erneut.
  Im lokalen Emulator zeigte `auto` wiederholt Schriftartefakte bei Größen-/Themenwechseln.
  Die Schlussprüfung verwendet deshalb SwiftShader mit deaktiviertem Vulkan und Kaltstart;
  der App-Renderer blieb unverändert. Die genaue Ursache im `auto`-Pfad ist offen.
- Der Suchzoom lädt nach einem gezielten Fix die passende native Kachelstufe.
  Das wurde durch einen zunächst fehlschlagenden Widget-Test sowie die scharfe
  Kartendarstellung im Emulator bestätigt; unnötige verzögerte Event-Bündelung entfällt.
- Ein weiterer zunächst fehlschlagender Test reproduziert die Wiederverwendung eines
  abgebrochenen Kachelbildes. Getrennte Ladevorgänge verhindern nun leere Ersatzkacheln;
  der persistente Kachelcache bleibt nach URL geteilt.

## Dateien

`F:\apps\Codex\campus-map-evidence` enthält APKs, unveränderte Screenshots,
`index.html` als Galerie, Prüfprotokolle, `manifest.json` mit Prüfsummen sowie
die verifizierten Git-Bundles vor und nach der Entwicklung.

Die universelle **Release-Test-APK 1.2.0 (3)** benötigt Android 6/API 23 oder neuer,
unterstützt ARM32/ARM64/x86_64 und ist **52,3 MiB** groß. Zusätzlich liegt die
geforderte Debug-APK vor. Installation als Update erhält die vorhandenen App-Daten.

Release-SHA256:
`e98ae0442f49a3cedcc21c63d1f4679e324a22227104099f89aa4debe545e9be`.

## Verbleibende Einschränkungen

- Physische Geräte, reale GPS-Genauigkeit und belastbare Bildratenmessungen stehen aus.
  Die vorhandene Android-Standortbibliothek verlangt genaue Freigabe; ausschließlich
  ungefähre Freigabe kann als verweigert behandelt werden. Keine Hintergrundortung.
- Alle TU-Eingangslisten waren leer. Das Routenziel ist ein Gebäudepunkt;
  ein bestätigter oder barrierefreier Eingang wird nicht behauptet.
- Offline funktionieren nur bereits gespeicherte Gebäudedaten und betrachtete Kacheln.
  TU-Datenqualität, Planverfügbarkeit und OSM-Verfügbarkeit bleiben externe Abhängigkeiten.
- Die ältere Flutter-/Android-Toolchain bleibt bewusst erhalten. Emulator-Grafikbefund
  und Release-Lint-Hinweise sind dokumentiert; keine Store-Veröffentlichung.
- Die Backups liegen lokal auf demselben Datenträger, ohne externe Sicherung.

[Implementierungsdetails, Quellen, Reproduktionsbefehle und vollständige Prüfliste](campus-map-details.md).
