Die Etagenpläne verlieren im Dunkelmodus technische Linien, und bei BEY 318 überlagert
„319A“ die richtige Zielbeschriftung. Diese Änderung korrigiert die transparente
Kacheldarstellung und prüft die Auswahl über die technische Raum-ID. Die detaillierten
architektonischen Hintergründe bleiben erhalten.

Das Smartphone zeigt zunächst einen kompakten Info-Header und zentriert den Zielraum;
Tablets ab 840px Breite zeigen Details seitlich. Ein Fit-Button setzt Zoom/Verschieben
zurück. Cache-Initialisierung, Ablaufzeiten, parallele Kachelabrufe, Bild-Lebensdauer,
veraltete Suchantworten und der Rückwechsel zur Ziel-Etage sind korrigiert.

Validierung: 29 Flutter-Tests bestanden, vier synthetische Golden-Vergleiche enthalten.
Private APB-/BEY-Renderläufe bestanden in Telefon-/Tabletmaßen und Hell/Dunkel.
Analyzer ohne Fehler/Warnungen mit weiterhin vorhandenen Info-Lints. Android-Build
wegen der lokalen Netzwerkbedingungen noch nicht abgeschlossen; ein erfolgreicher
Actions-Lauf und die Installation der neuen APK sind vor Übernahme erforderlich.

Der Workflow führt Tests und den Debug-APK-Build auch auf
`work/ui-polish-and-darkmode` aus. Keine neuen TU-Originaldaten im Repository.
Favoriten, Campuskarte und JSON-Migration bleiben getrennte Folgearbeiten.

Details, Rechtefragen und Prüfgrenzen: `docs/ui-polish.md`.
