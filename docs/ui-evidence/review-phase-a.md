# Review der Designstudie (Phase A)

14.10.2026 · unabhängiger Read-only-Review nach dem Superpowers-
Code-Reviewer-Auftrag. Umfang: Vorschau, Aufnahme-Werkzeuge, Bildnachweise und
deren Trennung vom Produkt. Keine Freigabe der noch ausstehenden Produktphase.

Bestätigt: Produktdateien, Pubspec und bestehende Tests unverändert; FloorView
unter bisheriger AppTheme; A/B-Grundrissbereiche identisch in allen drei Größen
und beiden Helligkeiten; Bildpfade, Abmessungen und SHA-256 passend zum Manifest.
Die gespeicherten repräsentativen Ansichten zeigten vollständige Daten.

Gefunden: feste Aufnahmeverzögerung konnte bei langsamem/kaltem Datenladen
unvollständige Inhalte aufnehmen; APB-Kamera konnte vor Katalogauflösung auf
einem Fallback starten. Außerdem fehlte die Prüfung der tatsächlichen DPI.

Behoben: Map-Konstruktion erst nach APB-Auflösung; gerenderter Zustandsnachweis
für Variante/Szene/Helligkeit/Breite, Daten und Kacheln; maximal 30 Sekunden
Wartezeit; geprüfte DPI; A/B-Abgleich von Kamera und Rasterstufe. Kalter Lauf
mit geleerten Caches erfolgreich. Alle 40 Bilder erneut aufgenommen.

Nachprüfung: alle 40 regenerierten Bilder samt Manifest, Bereitschaft und
12 Karten-/Etagen-A/B-Paaren geprüft; kein verbleibender wesentlicher Befund.
Der Reviewer hat keine SDK-/Emulator-Befehle ausgeführt; deren protokollierte
Durchführung stammt vom UI-Agenten.

Ausgenommen: Präsentationsaktionen statt Produktbindung, 14-Sprachen-/Settings-
Integration, große Schrift/RTL/TalkBack und vollständige Funktionsabnahme.
Diese bleiben explizit in Phase B/C des Umsetzungsplans.

Bewertung: bereit zur Designpräsentation, kein Merge und keine Releasefreigabe.
