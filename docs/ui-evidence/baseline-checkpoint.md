# Ausgangsbasis – UI-Untersuchung

14.10.2026 · `feature/ui-refinement` · unveränderter Produktstand
`d5609b07acc386f24446752afa70966112bb680c`.

`baseline-exact` wurde mit der aus diesem Quellstand neu gebauten Android-APK
aufgenommen. `baseline` dokumentiert die zuvor installierte APK; deren
Quellstand ist unbekannt, deshalb keine exakten Pixel-Vergleiche darauf stützen.
Vorhandene Favoriten/Verlauf wurden beim Installieren erhalten.

Ausgangs-Build: erfolgreich. APK lokal
`build/ui-refinement-checks/baseline-d5609b.apk`, SHA-256
`AAC6655819127D221D8A3E8F9534F35CE1EA8D82F553AAC24CDC2DF5303159AA`.
Tests: 94 bestanden, 26 wegen fehlender externer Grundriss-Fixtures übersprungen.
Erster Analyze-Lauf: ein Info-Hinweis, Exitcode 1; kein grüner Analyze-Stand.
Die vollständigen Ausgaben stehen in `checks/baseline-*.txt`.

Untersucht: Hub, Suche BEY 318, direkte Favoriten/Verlauf, Raumhervorhebung,
Raumdetails, APB-Karte und Etagenaufruf, Zurück-Navigation, Fit-Aktion,
Hell/Dunkel, Tablet-Hoch-/Querformat.

Erhalten: Suchfunktion und Raumidentität, direkte Favoriten, Renderer und
Zeichnungsfarben, Kartenkamera/Gesten, Tablet-Seitenleisten.
Verbesserungsansätze: abgeschnittenes WIP-Badge; redundante Suchmetadaten;
Kartenfläche bei geöffneter Tastatur; Adressüberschrift; unvollständige
Lokalisierung. Ursache des Tastaturlayouts noch zu verifizieren.

Nicht vollständig geprüft: echte Standortermittlung, externes Routing-Endziel,
Belegungsdaten mit Login, alle Netz-/Offline-Zustände, TalkBack/große Schrift.
Keine Produktdatei in diesem Zwischenstand verändert; kein Merge.
