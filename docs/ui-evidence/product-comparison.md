# Produktvergleich

Native Flutter-App, echte gespeicherte Favoriten, TU-API und OSM. Die
Designstudie ist separat unter [A/B-Entwürfe](design-comparison.md) dokumentiert.
Die [Manifestdatei](product-manifest.json) enthält PNG-Größen, Hashes und APK-Herkunft.

## Gleiche Inhalte in A und B

| Gerät und Modus | A – Modern Academic | B – Campus Wayfinding |
|---|---|---|
| Smartphone Hell | [Hub](product/phone-a-light-hub.png) · [Karte](product/phone-a-light-map.png) · [Etage](product/phone-a-light-floor.png) | [Hub](product/phone-b-light-hub.png) · [Karte](product/phone-b-light-map.png) · [Etage](product/phone-b-light-floor.png) |
| Smartphone Dunkel | [Hub](product/phone-a-dark-hub.png) · [Karte](product/phone-a-dark-map.png) · [Etage](product/phone-a-dark-floor.png) | [Hub](product/phone-b-dark-hub.png) · [Karte](product/phone-b-dark-map.png) · [Etage](product/phone-b-dark-floor.png) |
| Tablet Hochformat Hell | [Hub](product/tablet-portrait-a-light-hub.png) · [Karte](product/tablet-portrait-a-light-map.png) · [Etage](product/tablet-portrait-a-light-floor.png) | [Hub](product/tablet-portrait-b-light-hub.png) · [Karte](product/tablet-portrait-b-light-map.png) · [Etage](product/tablet-portrait-b-light-floor.png) |
| Tablet Hochformat Dunkel | [Hub](product/tablet-portrait-a-dark-hub.png) · [Karte](product/tablet-portrait-a-dark-map.png) · [Etage](product/tablet-portrait-a-dark-floor.png) | [Hub](product/tablet-portrait-b-dark-hub.png) · [Karte](product/tablet-portrait-b-dark-map.png) · [Etage](product/tablet-portrait-b-dark-floor.png) |
| Tablet Querformat Hell | [Hub](product/tablet-landscape-a-light-hub.png) · [Karte](product/tablet-landscape-a-light-map.png) · [Etage](product/tablet-landscape-a-light-floor.png) | [Hub](product/tablet-landscape-b-light-hub.png) · [Karte](product/tablet-landscape-b-light-map.png) · [Etage](product/tablet-landscape-b-light-floor.png) |
| Tablet Querformat Dunkel | [Hub](product/tablet-landscape-a-dark-hub.png) · [Karte](product/tablet-landscape-a-dark-map.png) · [Etage](product/tablet-landscape-a-dark-floor.png) | [Hub](product/tablet-landscape-b-dark-hub.png) · [Karte](product/tablet-landscape-b-dark-map.png) · [Etage](product/tablet-landscape-b-dark-floor.png) |

Größen: Smartphone 393×852 dp / 1179×2556 px bei 480 dpi;
Tablet hoch 800×1280 dp / 1200×1920 px bei 240 dpi;
Tablet quer 1280×800 dp / 1920×1200 px bei 240 dpi.

Die Etagen zeigen denselben Raum BEY 318 bei „Gesamte Etage“. Karten zeigen
APB nach Gebäudesuche und Auswahl. Favoritenbestand ist gleich. Die Reihenfolge
des Verlaufs folgt tatsächlichen Besuchen während der Prüfung.

## Ausgangsversion und Produkt

| Ansicht | Quelle d5609b0 | Produkt |
|---|---|---|
| Smartphone-Hub | [Vorher](baseline-exact/hub-phone-light.png) | [Nachher](product/phone-a-light-hub.png) |
| Smartphone-Zielraum | [Vorher, Zielzoom](baseline-exact/floor-phone-light.png) | [Nachher, Zielzoom](product/phone-a-light-floor-target.png) |
| Tablet hoch, Etage Hell | [Vorher](baseline-exact/floor-tablet-portrait-light.png) | [Nachher](product/tablet-portrait-a-light-floor.png) |
| Tablet hoch, Etage Dunkel | [Vorher](baseline-exact/floor-tablet-portrait-dark.png) | [Nachher](product/tablet-portrait-a-dark-floor.png) |
| Tablet quer, Etage Hell | [Vorher](baseline-exact/floor-tablet-landscape-light.png) | [Nachher](product/tablet-landscape-a-light-floor.png) |
| Tablet quer, Etage Dunkel | [Vorher](baseline-exact/floor-tablet-landscape-dark.png) | [Nachher](product/tablet-landscape-a-dark-floor.png) |

Die Baseline am Smartphone verwendet den vorhandenen automatischen Zielzoom.
Die A/B-Produktserie verwendet bewusst Fit. Unterschiedliche Kamera-Zustände
werden daher nicht als identischer Vorher-Nachher-Vergleich ausgegeben.
Die übrigen ersten `baseline/`-Bilder haben keinen gesicherten Quellstand.

## Settings und zusätzliche Bedienzustände

- [Integrierte Settings-Seite, A ausgewählt](product/phone-settings-a-light.png).
- [Raumsuche mit Tastatur](product/phone-a-light-results-keyboard.png),
  [Ergebnisse ohne Tastatur](product/phone-a-light-results.png).
- [Ausgezogene Raumdetails](product/phone-a-light-floor-details.png).

Smartphone-Querformat, 200-%-Text und alle 14 Sprachen einschließlich RTL sind
im Widget-Test geprüft. Zusätzliche native Bilder dieser Fälle wurden zum
gewünschten zügigen Abschluss nicht mehr aufgenommen. Die ausgezogenen Details
zeigen die vorhandene Ladeaktion; sie sind kein Nachweis authentifizierter
Live-Belegungsdaten.

## Aufnahmeverfahren

`tools/product-emulator.ps1` startet echte Produktansichten und bedient
aktuelle Android-UI-Knoten. Leere Accessibility-Bäume und Knoten ohne
sichtbare Bounds werden verworfen. Dichtewechsel können die Android-Activity
neu erstellen; deshalb wird pro Gerätegröße neu navigiert. Die abschließende
Bildkontrolle prüft außerdem, dass die Hell/Dunkel-Beschriftung zur tatsächlich
sichtbaren Oberfläche passt. APK-Dateien und fehlgeschlagene Zwischenbilder
liegen ausschließlich im ignorierten Build-Verzeichnis.
