# Gesicherter Ausgangsstand für die Campuskarte

14.10.2026, Branch `feature/campus-map`.

Vor dem Branchwechsel war `git status --porcelain=v1` leer. Ausgangspunkt ist
`feature/search-and-favorites` bei `aab8dba09bf2c91c14afec7c5be2c3c4252a9de3`.
Dieser Branch und `codex/renderer-recovery` bleiben unverändert. `master` bleibt
bei `0441326300600ceff155dad0e1b0a89b2d4f3710`.

Vor jeder Featureänderung wurde ein vollständiges, mit `git bundle verify`
geprüftes Backup aller lokalen und vorhandenen Remote-Referenzen angelegt:
`F:\apps\Codex\campus-map-evidence\before-campus-map.bundle`.
Das Bundle enthält auch die bisher nicht auf GitHub veröffentlichten Commits.
Es ist ein separates lokales Backup, kein Schutz gegen Ausfall dieses Datenträgers.

Architektur vor der Änderung: `MyApp` startet `SearchScreen`; dessen Controller
verwendet die TU-Suche und `PlaceStore` für Favoriten/Verlauf. Gebäudetreffer
werden über `buildingFloorQuery` auf tatsächlich angebotene Etagen aufgelöst.
`BuildingScreen` besitzt den Etagenwechsel und `FloorView` den funktionierenden
Renderer. Der ältere `LocationScreen` verwendet geschätzte Canvas-Umrechnungen
und startet Standortabfragen beim Öffnen. Er wird durch die explizite Standortaktion
der neuen Campuskarte im normalen Navigationsweg ersetzt.

Neue Dateien für geografische Daten und Kacheltransport sind von bestehenden
Plan-, Login- und Favoritencaches getrennt. Renderer, Etagenparser,
Raumhervorhebung und Referenzbilder werden nicht geändert. Es wird nichts
auf GitHub gepusht und kein bestehender Branch verschoben.
