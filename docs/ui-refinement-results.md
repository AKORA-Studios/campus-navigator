# Campus Identity – Ergebnis

Worktree `F:\apps\Codex\campus-ui-refinement`, Branch `feature/ui-refinement`.
Vergleichspunkt `d5609b0`; Produktstand `45ecad4`. Kein Merge und kein Push.

## Gestaltungsentscheidung

Beide eng verwandten Entwürfe wurden zuerst mit 40 nativen Screenshots
präsentiert: [A/B-Studie](ui-evidence/design-comparison.md).
Die bestätigte Nutzerwahl ist **A – Modern Academic als Standard** und
**B – Campus Wayfinding zum Umschalten**. Beide nutzen dieselbe ruhige
Farbwelt und Informationsstruktur. A verwendet vertraute Material-Symbole;
B verbindet Listen, Karte und Raumdetails durch kompakte Gebäudecodes.
Vollständige Raum-/Gebäudenamen und Server-IDs bleiben erhalten.

## Probleme und Änderungen

| Gefunden | Umsetzung | Konkreter Nutzen |
|---|---|---|
| WIP-Badge rechts abgeschnitten | kleine Statusmarkierung, lokalisierter Entwicklungs-Hinweis | vollständig erreichbare Aktion auch bei 320 dp |
| wiederholte technische Raum-Pfade | Gebäude/Etage sichtbar, vollständiger Servertext im Tooltip | schnellere Orientierung ohne Informationsverlust |
| schmale einzelne Liste auf Tablets | zwei scrollbare Listen, Rail auf breiten Geräten | Favoriten und Verlauf parallel erreichbar |
| Tastatur beansprucht Kartenfläche | Bottom Navigation und Kartenwerkzeuge beim Tippen ausgeblendet | mehr Fläche für Vorschläge und Karte |
| feste vertikale Werkzeuge bei geringer Höhe | horizontale Gruppe in kurzen Karten | Zoom-/Standortaktionen im Querformat erreichbar |
| Sheet verdeckt Fit-Aktion auf hohen Tablets | geschlossene Höhe entspricht tatsächlichem Header | Grundrissfläche und Bedienelemente sichtbar |
| uneinheitliche Farbe/Typografie | lokale CampusIdentity-Tokens, Roboto/Systemschrift, klare Linien | konsistente ruhige Hierarchie |
| gemischte Sprache und unbenannte Icons | 14 vollständige Kataloge, typisierte Platzhalter, Android-Semantik | verständliche Bedienung einschließlich RTL |
| feste Annahme von drei Belegungstabellen | echte Serverüberschriften, sichere unklare Zuordnung | keine erfundene Woche und kein RangeError |

Die Smartphone-Abschnitte behalten kompakte passive Überschriften. Nur
zweispaltige Hubs reservieren die Höhe der danebenliegenden Aktion.
Wichtige Aktionen besitzen mindestens 48-dp-Touchflächen. Normale UI-Texte
verwenden kontrastreiche Farben; Stahlblau und Korallrot werden nicht als
normale Textfarben eingesetzt. Keine Logos, Verläufe, Illustrationen oder
neuen UI-Abhängigkeiten.

## Bewusst erhalten

Painter, Architekturzeichnungen, Raumgeometrien, Raster-/Tile-Pipeline,
Farbtransformation, Pan/Pinch/Fit und Raumhervorhebung sind unverändert.
FloorView liegt unter der bisherigen AppTheme. Sein Dateidiff betrifft
ausschließlich lokalisierte Tooltip-/Fehlertexte und die Fit-Beschriftung für
Accessibility. `styling.dart` blieb unverändert.

Suchcontroller, API-/Suchsemantik, PlaceStore, Favoriten-/Verlaufsspeicherung,
Gebäudekoordinaten, geometrische Kartenauswahl und externe Routing-Übergabe
blieben erhalten. Die verzögert erzeugte Karte und beide Tabs behalten ihren
Zustand. Servernamen und serverseitige Belegungsüberschriften werden nicht
als erfundene Übersetzungen ersetzt.

## Verifikation

- `flutter analyze --no-pub`: **36 vorhandene Info-Lints**, keine Fehler oder
  Warnungen. Exitcode 1; nicht als vollständig grüner Analyze-Lauf bezeichnet.
- `flutter test --no-pub --reporter expanded`: **152 bestanden, 26 übersprungen**.
  Die Skips benötigen externe `PRIVATE_PLAN_DIR` / `REAL_PLAN_DIR`-Fixtures.
  Vorhandene synthetische Renderer-Goldens bestanden.
- `flutter build apk --debug --no-pub`: erfolgreich, APK installiert.
- Native Produktserie: A/B, Hell/Dunkel, Hub/APB-Karte/BEY-318-Etage auf
  393×852, 800×1280 und 1280×800 dp. Größe, SHA-256 und APK-Herkunft stehen
  in [product-manifest.json](ui-evidence/product-manifest.json).
- Widget-/Regressionstests: 25 Favoriten bei 200-%-Text, Suche/Fehler/Retry,
  keine Treffer, lange Ergebnislisten, exakte Raum-ID, Etagenwechsel, Filter,
  Fit/Pan/Pinch, Navigation/Kamera, Karten-/Stilpersistenz und alle 14 Sprachen.
- [Unabhängiger Review und behobene Befunde](ui-evidence/review-product.md).

Keine muttersprachliche Freigabe der Übersetzungen, kein auditiver TalkBack-Test,
keine authentifizierte Live-Belegung, keine Aussage über echte GPS-Genauigkeit
oder reale Gebäudeeingänge am Routingziel. Netzwerkfehler und fehlende API-Daten
sind durch kontrollierte Regressionstests geprüft. Eine APK allein gilt nicht
als visuelle Abnahme.

Die ergänzende native Serie mit großen Schriften, Smartphone-Rotation und
einzelnen Sprachproben bleibt offen; dafür liegen Widget-Tests vor. Der Nutzer
wünscht jetzt den Abschluss ohne weitere Perfektionierung. Sinnvoller späterer
Feinschliff: den Zielraum bei stark ausgezogenen Raumdetails sichtbar halten.

## APK und Integration

Installierbare Debug-APK: `build/campus-navigator-campus-identity-debug.apk`.
SHA-256: `A55C3F7EB7D91EC64825DD7C606A43875FA8006F3E1A9EF77BB7BAA171B3BD4B`.
Kein Release-Artefakt. Alle SDK-Befehle nutzen `tools/dev-env.ps1`.

[Integrationsvertrag](ui-integration.md) listet die vier unveränderten
Settings-Abhängigkeiten und den tatsächlichen API-Vertrag. Gemeinsame
UI-Änderungen sind `main.dart`, `home_screen.dart` und die neue Tokendatei;
Settings-Seiten/Persistenz gehören weiterhin dem anderen Agenten.
Bereits vorhandene identische Cherry-picks bei der späteren Integration
berücksichtigen. Branch und Worktree bleiben bestehen.
