# TerraLine GPS – MP-Testplan 0.9.9.45 (Entwicklungsfassung)

Vorbereitung: **Backup des Savegames** anlegen, exakt dieselbe ZIP auf Server und allen Clients, keine zweite TerraLine-Version laden, Dedicated `log.txt` und Client-Logs sammeln.

1. **Ein Hof / zwei Spieler, getrennte Traktoren**: Host/Dedicated starten, beide joinen und auf denselben Hof wechseln. Menu `Speicher` oeffnen. Kein gespeicherter Kurs sollte doppelt angezeigt werden.
2. **Hofkurs teilen**: Spieler A setzt A/B (mind. 20 m) und speichert einen einmaligen Namen. Bis zu 10 Sekunden warten; Spieler B oeffnet `Speicher` und muss ihn sehen. Spieler B laedt Kurs in seinen Traktor; bei Spieler A darf der aktive Kurs NICHT wechseln.
3. **Loeschen**: Spieler B loescht einen Testkurs, nach bis zu 10 Sekunden verschwindet er bei Spieler A.
4. **Reconnect**: Spieler B verlässt den Server, tritt wieder bei und soll den gleichen Hof-Kursbestand sehen.
5. **Zweiter Hof**: Spieler C auf einem anderen Hof darf weder Kurse von Hof A sehen noch deren ID laden/loeschen.
6. **Hofwechsel**: Client wechselt die Hofzuordnung; alte Kursliste muss sofort verschwinden.
7. **Persistenz**: Server speichern und neu starten; Hofkurse muessen erhalten bleiben. Die gespeicherte `terralineGPS.xml` enthaelt `farmId`-Attribute.
8. **SP-Regression**: alter Spielstand mit Kursen ohne `farmId` laedt weiterhin die Kurse von Hof 1.

**Vorläufig NICHT freigeben:** GPS-Lenkung mit zwei gleichzeitig fahrenden Spielern, Unbeaufsichtigtes Lenken beim Disconnect und Fahrzeuge mit wechselnden Besitz-/Kontrollrechten. Das sind separate v1.0-Blocker.

**Erwartete Konsole/Logs:** `TerraLine Kurse: Hof X: N Kurse vom Server empfangen` auf Clients. Bei unerwartetem Verlauf Logs von Dedicated + beiden Spielern beilegen.
