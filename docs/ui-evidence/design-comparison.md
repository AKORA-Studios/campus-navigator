# Campus Identity – Vergleich A / B

Native Flutter-Screenshots, gleicher Dateninhalt, gleiche Kamera und Größe.
Phase A: diese Bilder zeigen Entwürfe, keine fertig implementierte App.

## Smartphone: 393 × 852 dp

| Modern Academic – A | Campus Wayfinding – B |
|---|---|
| ![A Hub](identity-a/hub-phone-light.png) | ![B Hub](identity-b/hub-phone-light.png) |
| ![A Suchresultat](identity-a/results-phone-light.png) | ![B Suchresultat](identity-b/results-phone-light.png) |
| ![A Karte](identity-a/map-phone-light.png) | ![B Karte](identity-b/map-phone-light.png) |
| ![A Etage](identity-a/floor-phone-light.png) | ![B Etage](identity-b/floor-phone-light.png) |
| ![A dunkler Hub](identity-a/hub-phone-dark.png) | ![B dunkler Hub](identity-b/hub-phone-dark.png) |
| ![A dunkle Karte](identity-a/map-phone-dark.png) | ![B dunkle Karte](identity-b/map-phone-dark.png) |
| ![A dunkle Etage](identity-a/floor-phone-dark.png) | ![B dunkle Etage](identity-b/floor-phone-dark.png) |

## Tablet: 800 × 1280 dp

| Modern Academic – A | Campus Wayfinding – B |
|---|---|
| ![A Hub](identity-a/hub-tablet-portrait-light.png) | ![B Hub](identity-b/hub-tablet-portrait-light.png) |
| ![A Karte](identity-a/map-tablet-portrait-light.png) | ![B Karte](identity-b/map-tablet-portrait-light.png) |
| ![A Etage](identity-a/floor-tablet-portrait-light.png) | ![B Etage](identity-b/floor-tablet-portrait-light.png) |
| ![A dunkle Karte](identity-a/map-tablet-portrait-dark.png) | ![B dunkle Karte](identity-b/map-tablet-portrait-dark.png) |
| ![A dunkle Etage](identity-a/floor-tablet-portrait-dark.png) | ![B dunkle Etage](identity-b/floor-tablet-portrait-dark.png) |

## Tablet: 1280 × 800 dp

| Modern Academic – A | Campus Wayfinding – B |
|---|---|
| ![A Hub](identity-a/hub-tablet-landscape-light.png) | ![B Hub](identity-b/hub-tablet-landscape-light.png) |
| ![A Karte](identity-a/map-tablet-landscape-light.png) | ![B Karte](identity-b/map-tablet-landscape-light.png) |
| ![A Etage](identity-a/floor-tablet-landscape-light.png) | ![B Etage](identity-b/floor-tablet-landscape-light.png) |
| ![A dunkle Karte](identity-a/map-tablet-landscape-dark.png) | ![B dunkle Karte](identity-b/map-tablet-landscape-dark.png) |
| ![A dunkle Etage](identity-a/floor-tablet-landscape-dark.png) | ![B dunkle Etage](identity-b/floor-tablet-landscape-dark.png) |

## Bewertung

**A:** vertraute Material-Symbole, vollständige Raumkennung im Zeilentitel,
ruhigere Karte mit Code nur am gewählten Gebäude. Geringere visuelle Betonung.

**B:** klarer Bezug zwischen Codefläche in Suche, Gebäudecode auf Karte und
Raumansicht. Bessere schnelle Zuordnung, besonders bei gemischten Favoriten.
Zusätzliche Kartenlabels müssen im Produkt weiter zoomabhängig begrenzt werden.

**Empfehlung B**, mit den ruhigen Flächen und kompakten Listen beider Entwürfe.
Kein Korallrot als zusätzlicher Schmuck: der bestehende Grundriss zeigt den
Zielraum bereits zuverlässig. Zeichnungsfarben und Renderer sind unverändert.

Geprüft und korrigiert: geschlossene Rauminformation konstant 72 dp in der
Vorschau; auf Tablets keine halb sichtbare zusätzliche Überschrift;
Seiteninformationen oben ausgerichtet; Rail-Indikator aus derselben Palette.
Im Produkt muss die geschlossene Höhe zusätzlich große Schrift berücksichtigen.

Bedienproben: [Raum-Sheet ausgezogen](interaction-probes/floor-sheet-expanded.png),
[Kartenzoom](interaction-probes/map-zoom.png). Favoriten-/Route-/Settings-Aktionen
in der Studie sind bewusst Präsentationsflächen; Produktbindung folgt Phase B.

## Vergleich mit dem unveränderten Produkt

| Original d5609b0 | Entwurf B |
|---|---|
| ![Original Hub](baseline-exact/hub-phone-light.png) | ![B Hub](identity-b/hub-phone-light.png) |
| ![Original Etage](baseline-exact/floor-phone-light.png) | ![B Etage](identity-b/floor-phone-light.png) |
| ![Original Tablet dunkel](baseline-exact/floor-tablet-landscape-dark.png) | ![B Tablet dunkel](identity-b/floor-tablet-landscape-dark.png) |

Der Vergleich zeigt die UI-Flächen und Hierarchie. Die geänderte verfügbare
Canvas-Höhe beeinflusst automatisch den vorhandenen Fit und die Darstellung;
es ist kein Nachweis pixelidentischer Renderer-Ausgabe. Dafür sind die
vorhandenen Renderer-Regressionen und spätere Szenen mit gleichem Viewport
maßgeblich. Weitere Angaben und Testgrenzen: [README](README.md).
