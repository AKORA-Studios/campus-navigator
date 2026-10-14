# TU-Gebäude-Testdaten

Öffentlicher Einzelabruf am 14.10.2026 (Europe/Berlin):
https://navigator.tu-dresden.de/m/json_gebaeude/all

Die vollständige Antwort enthielt 217 Datensätze, Content-Type
`application/json; charset=ISO-8859-1`. Dieser UTF-8-Testauszug enthält APB,
BAR und ASB, einschließlich unveränderter geografischer Punkte und IDs.
Kontakt-/Barrierefreiheitstexte wurden aus dem Testauszug entfernt; aus
`barfrei_info` bleibt ausschließlich die Adresse, die das Feature verwendet.
Alle 217 Eingangslisten waren leer. `stdetage` ist kein Nachweis, dass tatsächlich
ein Etagenplan existiert; das prüft der gemeinsame HTML-Resolver beim Öffnen.

Keine aus dem alten Canvas-Parser geschätzten Skalierungen übernehmen:
`punkte` → Liste von Umrissen → Liste `{x: longitude, y: latitude}` in Grad.
Beispiel APB: erster Punkt `(13.7234797, 51.0255663)`, nicht vertauschen.
Die Kartenbibliothek projiziert diese Gradkoordinaten selbst nach Web Mercator.
