# Campus Identity – Gestaltung und Grenzen

14.10.2026 · Phase B · A als Standard, B umschaltbar (bestätigte Nutzerwahl).

## Ziel und Gestaltungsrichtung

Ein kompaktes Android-Navigationswerkzeug mit eigener akademischer Identität:
ruhige Flächen, präzise Hierarchie, Gebäudekürzel als Orientierung und native
Material-3-Bedienung. Keine offiziellen TU-Logos, dekorativen Illustrationen,
Verläufe, Unschärfen oder zusätzlichen Abhängigkeiten.

**A – Modern Academic:** kleine Material-Symbole vor Listenzeilen, vollständige
Raumbezeichnung als Titel, zurückhaltende Abschnittsüberschriften. Gebäudecodes
werden als sachliche Information gezeigt. Vorteil: vertraute, ruhige Android-UI.

**B – Campus Wayfinding:** identische Struktur und Farbwelt; feste, kompakte
Codeflächen für APB/BEY/BAR; vollständige Raumnamen daneben; Kennzeichnung der
Listenabschnitte. Die vorhandene Karten-Labelbegrenzung bleibt erhalten. Vorteil: der Gebäudecode
verbindet Suche, Karte und Etagenansicht visuell.

**Nutzerentscheidung:** A ist Standard, B bleibt auswählbar. Kartenlabels müssen bei der Sichtprüfung
lesbar bleiben. Codes dürfen keine Gebäudenamen verdrängen oder bei geringer
Zoomstufe kollidieren. Im Produkt muss die vorhandene zoomabhängige
Labelbegrenzung erhalten bleiben. A bleibt die zurückhaltendere Alternative.

## Gemeinsame Design-Tokens (Vorschlag)

| Rolle | Hell | Dunkel | Verwendung |
|---|---|---|---|
| Primär | `#173657` | `#A6C9EB` | wichtige Aktionen, Auswahl |
| Auf Primär | `#FFFFFF` | `#102B45` | Buttontext |
| Primärfläche | `#E3ECF3` | `#233E55` | Auswahl, Codeflächen |
| Hintergrund | `#F5F7F8` | `#151A20` | ruhige Hauptfläche |
| Informationsfläche | `#FFFFFF` | `#1B222A` | Suche, Panels |
| Haupttext | `#263442` | `#E5EBF0` | Titel, Inhalte |
| Sekundärtext | `#526372` | `#B0BDC9` | Adresse, Etage |
| Stahlblau | `#527D9B` | `#A4BED0` | grafische Akzente |
| Trennlinie | `#D1DAE2` | `#37434F` | Flächengrenzen |
| Ziel-Akzent | `#C65A45` | `#E78F7B` | optionaler UI-Marker |

Berechnete sRGB-Kontraste: Primär/Weiß 12,34:1; Haupttext/Hintergrund
11,83:1; Sekundärtext/Hintergrund 5,77:1; dunkler Haupttext/Hintergrund
14,55:1; dunkler Sekundärtext/Hintergrund 9,14:1. Stahlblau (4,10:1) und
Korallrot (3,95:1) auf hellem Hintergrund sind **keine normalen Textfarben**.
Fehler/Warnungen bleiben semantische Material-Farben; Zielrot ist kein Fehler.
Der optionale Korallakzent wird nur eingesetzt, wenn eine zusätzliche
Raumkennzeichnung tatsächlich erforderlich ist; keine zweite Farbe allein
zur Dekoration. Die vorhandene Raumhervorhebung bleibt unverändert.

Roboto/Systemschrift: 20 sp App-Bar, 16 sp Zeilentitel, 14 sp Abschnitt/Inhalt,
12–13 sp unterstützende Information. 4-/8-dp-Raster; Außenabstand 16 dp;
Panelbreite Karte 320 dp, Grundriss 300 dp; Radius 4 dp Code, 8 dp Suche/Button.
Wichtige Ziele mindestens 48 × 48 dp. Textvergrößerung darf keine festen
Zeilenhöhen erzwingen; lange Gebäude-/Raumnamen erhalten bis zu zwei Zeilen.

## Ansichten

- **Hub:** Suche unmittelbar unter App-Bar, Favoriten und Verlauf direkt
  erreichbar. Keine Dashboard-Kacheln. Bei mindestens 680 dp Inhaltsbreite
  zwei Listen nebeneinander. Viele Favoriten bleiben scrollbar, ohne versteckte
  Beschränkung. Vorhandene Suche/PlaceStore und Datenidentität erhalten.
- **Karte:** Suchfeld über der Kartenfläche; Werkzeuge in einer schmalen
  Gruppe. Auswahl unten am Smartphone, seitlich bei breiten Tablets.
  Etagen/Navigieren mit 48-dp-Touchflächen. Attribution immer sichtbar;
  Auswahl, Kamera, Standort, Routing und echte Geometrien erhalten.
- **Etage:** kompakte App-Bar, 48-dp-Etagen-/Filterzeile, ausziehbare Information
  am Smartphone; bestehende 300-dp-Seitenleiste ab 840 dp. Collapsed-Sheet
  anhand realer Inhalts-/Schrifthöhe dimensionieren, nicht pauschal prozentual.
  Grundriss vollständig mit vorhandener Fit-Aktion erreichbar.
- **Navigation:** bestehende zwei Ziele; ab 1000 dp Gerätebreite schmale NavigationRail als
  prüfbarer Vorschlag. IndexedStack und verzögertes Laden bleiben erhalten.

## Unveränderliche Bereiche / Integration

Keine Änderungen an Painter, Rendering-Pipeline, Raumgeometrie,
Farbtransformation, Zeichnungsdaten, Touch-/Zoom-Transformationen, Such-API,
Persistenz oder Routingverfahren. In den Entwürfen wird `FloorView` unverändert
unter der bisherigen `AppTheme` verwendet. Auch im Produkt müssen die
Zeichnungsfarben unabhängig von der neuen UI-Palette bleiben.

Settings-Dateien gehören dem Settings-Agenten. Der UI-Agent besitzt die
übrigen Screens, ARBs und ausdrücklich abgestimmte Root-Integration.
Globale `styling.dart`-Änderungen sind zunächst nicht vorgesehen.
Die zuvor vom Nutzer bestätigten 14 Sprachen und Settings-Schnittstellen
gehören zum Umsetzungsplan; sie sind kein Bestandteil der festen deutschen
Präsentationsdaten dieser Entwürfe.

## Nachweise und Entscheidung

Siehe `docs/ui-evidence/README.md` und Bildordner `identity-a`, `identity-b`.
Beide Varianten verwenden gleiche Inhalte, Kameras und Gerätegrößen.
Die Vorschau demonstriert Gestaltung, Scrollen, Tastatur, Kartenzoom und
unveränderten Grundriss; ihre Datenaktionen sind noch keine Produktfunktion.
Nach Präsentation bestätigte der Nutzer A als Standard und wünscht einen Stilwechsel zu B.
Umsetzung und Integration erfolgen ausschließlich auf
`feature/ui-refinement`, ohne Merge nach `master`.
