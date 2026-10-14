# SDD ledger — plan: docs/superpowers/plans/2026-10-14-campus-identity.md

## Stand und verbindliche Grenzen

Worktree `F:\apps\Codex\campus-ui-refinement`, Branch `feature/ui-refinement`.
Baseline d5609b0; Phase A in c391ced und c9f1c77 abgeschlossen.
Keine Änderungen anderer Worktrees, kein Merge/Push. Settings-Dateien gehören
dem Settings-Agenten. Keine Änderung von Zeichnung, Renderer-Pipeline,
Transformation, Such-/Persistenzlogik oder Routing.

Task 1: complete — native A/B-Studie präsentiert; 40 geprüfte Bilder,
94 Tests bestanden / 26 externe Fixture-Skips; Analyze 38 Legacy-Infos;
native Preview-Analyze sauber, APK erfolgreich; Review einschließlich
Bereitschafts-/DPI-/Kamera-/Rasterprüfung ohne wesentlichen offenen Befund.

Ruling: B als Arbeitsrichtung übernehmen — die verlangte Präsentation vor
größeren Änderungen ist erfolgt, B ist die begründete Empfehlung und die
bereits vom Menschen beauftragte autonome Umsetzung bleibt bestehen — bei
späterer Präferenz A sind Codeflächen und Listenpräsentation rückstellbar.

Pre-flight: Task 2 Tokens -> Task 3/4 Umgebung: neue CampusIdentity-Palette,
FloorView separat unter bisheriger AppTheme; keine Zeichnungsfarben ändern.
Pre-flight: Task 5 ARBs -> alle Screens + Settings: vollständiges Schlüsselinventar
vor Übersetzung, vorhandene Getter behalten, Serverdaten nicht übersetzen.
Pre-flight: Task 5 Root -> Settings-Controller: andere Branch-Dateien fehlen
im UI-Branch; Root-Integration separat als überprüfbaren Patch/Teststand
vorbereiten, keinen unbuildbaren Branch als fertige App deklarieren.

Ruling: Settings-Commit 7bde4ec unverändert als Abhängigkeit im eigenen
Feature-Branch übernehmen — die tatsächlich beauftragte Root-Integration
benötigt dessen Typen; Settings-Dateien bleiben beim ursprünglichen Owner,
kein Git-Merge und keine Änderung anderer Worktrees — Kosten: die spätere
gemeinsame Integration muss den bereits identisch vorhandenen Code berücksichtigen.

## Laufende Arbeit

Task 2: pending — Tokens, Hub, Suchlisten und Layout-Regressionsschutz.
Task 3: pending — Karten-Chrome, Insets und responsive Navigation.
Task 4: pending — Etagen-Chrome/Sheet/Adressinformationen.
Task 5: in_progress — 190 Texte in 14 Sprachen angelegt; 12 neue Kataloge
durch drei Agenten mit getrennter Dateizuständigkeit. JSON-/Schlüssel- und
Platzhalter-Parität geprüft. Flutter verlangt zusätzlich einen technischen
Basis-Katalog zh für zh_Hans; gleiche vereinfachte Übersetzung, keine 15. Sprache.
Root-Sprach-/Theme-Tests vor Implementierung rot (MyApp ohne Settings-Parameter).

Ruling: beide Campus-Identity-Varianten umschaltbar, Default academic (A) —
neue tatsächliche Nutzerantwort im Settings-Chat 01a13b47-6a8f-7c51-92db-0fe87b4d3b57
geprüft; frühere Arbeitsrichtung B wird entsprechend erweitert — Kosten: ein
zusätzlicher UI-Modus; Settings-Persistenz und Selektor bleiben beim Settings-Agenten.
Task 6: pending — Produkt-QA, APK und abschließender Review.

Task 2: complete — native Hub mit A/B-Leading, unveränderte Raumtitel/IDs,
redundante Serverpfade nur im Tooltip; 25 Favoriten bei 200-%-Text geprüft.
Abgeschnittener WIP-Text rot reproduziert, kleine Statusmarkierung grün.
Task 3: complete — Rail ab 1000 dp Gerätebreite, Hub-Spalten ab 720 dp Inhalt;
IndexedStack bleibt bei Rotation/Tabwechsel erhalten; Bottom Navigation und
Kartenwerkzeuge während Tastatur ausgeblendet; Kartenmodus persistent angebunden.
Task 4: complete — lokalisierte Filter/Etage, skalierende Sheet-Höhe,
seitliche Details erhalten; FloorView unter alter AppTheme. Palette-Test
zunächst rot (Campusblau statt Zeichnungsgrün), danach grün.
Task 5: complete — 193 Texte/14 Sprachen plus technischer zh-Alias,
A/B- und Kartentheme-Integration getestet. Settings-Deltas b6edc03 und
5fc1e44 unverändert als 1f51dcb und 3159195 übernommen.
Ruling: native Windows-Ledger in docs statt Bash-SDD-Skript — Git-Bash fehlt,
WSL ist kein garantierter Dart/SDK-Kontext — keine Tests/Briefs außerhalb dieses Worktrees.
Ruling: Standardwerte im Plan aktualisieren (A default, B wählbar; Rail 1000,
Hub 720) — konkrete lange Sprachlabels und klare Tablet-Kontexte — kompakte
Querformattelefone verwenden weiterhin Bottom Navigation.
Ruling: FloorView-Datei ausschließlich Tooltip-/Fehlertexte lokalisieren —
14-Sprachen-Anforderung — keine Änderung an Renderer, Mathe, Gesten, Raster,
Farbtransformation oder Painter; Zeichnungspalette bleibt separat unverändert.
Ruling: vorhandene englische Settings-Aktionsnamen erhalten — neue Texte sind
nicht notwendig für das UI-Ziel und der Settings-Owner testet sie — deutsche
und andere Übersetzungen bleiben natürlich; Option-B-Testfix vom Owner.
Task 6: in_progress — Vollsuite 132 bestanden / 26 externe Fixture-Skips,
Analyze 36 Legacy-Infos ohne Warnung/Fehler; Produkt-APK gebaut. Native
Produktprüfung läuft. Kommunikation an Settings-Chat von Auto-Review abgelehnt;
explizite Nutzerfreigabe angefragt, keine Umgehung. Owner liefert unabhängig
weitere Patches und hat den Emulator zur Nutzung freigegeben.

Review: fresh-context product_review, d5609b0..1ebb0fd, 3 Important/2 Minor,
keine Critical. Wochentitel aus festem 3-Element-Array entfernt; tatsächliche
Serverüberschriften nur bei eindeutiger Tabellenzuordnung erhalten. Vier
Tabellen rot reproduziert, grün. Tablet-Sheet 93,76 statt 64 dp rot,
Prozent-Untergrenze entfernt, grün. Map-Werkzeuge in kompletter Home-Navigation
Querformat rot (Zoom-Button außerhalb Map); kurze Kartenfläche nutzt horizontale
48-dp-Werkzeuge, grün. B-Kartencodes nun semantisch angesagt; Sheet benennt
Ein-/Ausklappen. Keine Änderung von API/Parsern zur Behebung dieser UI-Befunde.
Ruling: leere native Accessibility-Bäume/Activity-Neustarts nach DPI-Änderung
nicht als geprüfte Screenshots akzeptieren — Automation verwirft ungültige
Zustände und öffnet reale Produktansichten nach Größenwechsel neu.
Review declined: authentifizierte Belegung, echtes Standortsignal/externe
Navigation, private Fixtures und muttersprachliche Übersetzung brauchen
Umgebungsdaten; vorhandene Kalender-/Adress-/Kameraverhalten bewusst erhalten.
Explizite Script-Locales wurden dem Settings-Owner gemeldet; dessen Fix folgt.

Visual ruling: passive Überschriften im Smartphone-Hub benötigen keine
48-dp-Buttonhöhe — Vorher-Vergleich zeigte 28 dp unnötigen Abstand pro
Abschnitt — nur breite zweispaltige Hubs reservieren den Aktionsraum für
symmetrische Listen. Abstandstest 38 dp rot, kompakte Überschrift danach grün.
Letzter Settings-Fix 83f3e96 identisch als 6413f87 übernommen; finale Suite
152 bestanden / 26 externe Fixture-Skips, Analyze 36 Infos, APK erfolgreich.
