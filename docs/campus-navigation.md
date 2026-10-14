# Google-Maps-Navigation 1.2.1

14.10.2026 · `feature/campus-map` · Anwendungscode `5573e8c`.
Die vorherige Campuskarte ist bei `85d2aa8` gesichert. Der Folgeauftrag ändert
nur den Navigationsbutton und seine Fehlerbehandlung, den sicheren URL-Zugriff,
Tests und die Versionsnummer. Kartenrenderer, Gebäudeauswahl, Etagenpläne und
Favoriten bleiben erhalten.

## Verhalten

„Navigieren“ verwendet einen Navigationspfeil und eine Touchhöhe von mindestens
48 logischen Pixeln. Der Link lautet:

```text
https://www.google.com/maps/dir/?api=1&destination=LAT%2CLON&travelmode=walking
```

`url_launcher` öffnet ihn mit `LaunchMode.externalApplication`.
Nach dem [offiziellen Google-Maps-URL-Standard](https://developers.google.com/maps/documentation/urls/get-started)
übernimmt unter Android die aktive installierte Maps-App den Link; ohne Maps
übernimmt der Browser. Die Android-Linkzuordnung bleibt maßgeblich.
Es gibt keine neue Android-Bibliothek und keinen API-Schlüssel.

Die Campus-App liest dafür keinen eigenen Standort und fordert keine
Standortfreigabe an. Google Maps bestimmt seinen Startpunkt selbst. Es wird kein
`origin` übertragen. Ein fehlgeschlagener oder mit Exception abgebrochener Start
zeigt eine Meldung und lässt die Aktion erneut zu. Ohne gültigen geografischen
Zielpunkt bleibt der Button deaktiviert; die URL-Erstellung liefert sicher `null`.

## Herkunft des Ziels

Ein erneuter Einzelabruf von
[GET /m/json_gebaeude/all](https://navigator.tu-dresden.de/m/json_gebaeude/all)
am 14.10.2026 enthält 217 Gebäude. **Alle 217 Listen `eingänge` sind leer.**
Damit ist weder ein Haupteingang noch ein anderer öffentlicher Eingang zuverlässig
identifiziert. Unbekannte Metadaten oder bloße Namen werden nicht als bestätigte
Eingänge interpretiert. Eine automatische Eingangsauswahl wäre erst nach
Validierung eines tatsächlichen Datenformats zulässig.

Der Fallback bleibt der vorhandene Gebäudepunkt: Mitte der Begrenzung des
flächenmäßig größten gültigen TU-Umrisses. `punkte[].x` ist WGS84-Längengrad,
`punkte[].y` WGS84-Breitengrad. Lokale Etagenplan-Koordinaten werden nicht verwendet.

| Gebäude | Breitengrad | Längengrad |
| --- | --- | --- |
| APB / Andreas-Pfitzmann-Bau | 51.02546115 | 13.72293115 |
| BAR / Barkhausen-Bau | 51.02680695 | 13.72351765 |

Die Oberfläche kennzeichnet das Ziel weiterhin als **Gebäudepunkt, Eingang nicht
bestätigt**. Der Punkt kann in einem Innenhof liegen; ein bestimmter oder
barrierefreier Zugang wird nicht zugesagt.

## Qualität und Nachweise

- 111 Tests bestanden, ein optionaler alter privater Fixturetest übersprungen.
  Darin 24 unveränderte Originalplan-Goldens und sechs neue Navigationsprüfungen:
  bekannte APB-/BAR-Ziele, URL-Parameter, fehlende/projizierte Koordinaten,
  unbestätigte Eingänge, Startfehler/Exception und deaktivierter Button.
- `flutter analyze`: keine Fehler oder Warnungen, weiterhin 38 vorhandene
  Stilhinweise. Standardaufruf Exit 1; `--no-fatal-infos` erfolgreich.
- Android-Debug- und Release-Build erfolgreich. Die bekannten Kotlin-Metadaten-
  Hinweise der vorhandenen Toolchain bleiben beim Release-Lint bestehen.
- Reproduzierbarer Emulatorablauf: `python tools/smoke-campus-navigation.py`.
  Maps wird für den Browserfall vorübergehend deaktiviert und anschließend
  wiederhergestellt; keine Deinstallation und kein Löschen von App-Daten.
  Chrome muss seine erstmalige Einrichtung abgeschlossen haben.
- Android 14/API 34: APB und BAR öffnen Maps; die tatsächlichen Empfänger-Intents
  enthalten jeweils die oben genannten Koordinaten, `api=1` und `travelmode=walking`.
  Bei deaktivierter Maps-App erhält Chrome dieselbe APB-URL. Android-Zurück
  erhält in allen drei Fällen die Auswahl. Die Campus-Standortfreigabe war dabei
  verweigert und blieb verweigert. Acht Geräteprüfungen erfolgreich.
- Zusätzlich mit der neuen APK auf Tabletgröße geprüft: Seitenspalte mit
  Navigationsbutton, APB-Etagenplan öffnen und mit erhaltener Auswahl zurückkehren.
  Das Laufzeitprotokoll enthält keine Flutter-/AndroidRuntime-Fehler.

APKs, Screenshots, tatsächliche Android-Intent-Protokolle, API-Antwort,
Prüfsummen und Git-Bundle liegen unter
`F:\apps\Codex\campus-navigation-evidence`. Die vorherige vollständige
Campus-Abnahme liegt weiterhin unter `F:\apps\Codex\campus-map-evidence`.

Release-APK: 54.887.493 Bytes / 52,3 MiB; SHA256:
`c5c6cbab585bc6a128b796d5b22401c4dd5b345a6febf09ae60cfafff8ea1165`.
Zusätzlich liegt die Debug-APK vor. Beide wurden als Update installiert;
die installierte Release-Datei wurde nochmals über ihre Prüfsumme abgeglichen.

Die APK 1.2.1 (4) ist eine lokal signierte Testausgabe für Android 6/API 23 oder
neuer. Ein Update erhält die vorhandenen App-Daten. Physische Geräte, tatsächliche
Fußwege und verlässliche Eingangsdaten bleiben ungeprüft. Die Emulatorprüfung
verwendet den bereits dokumentierten SwiftShader-Testpfad.
