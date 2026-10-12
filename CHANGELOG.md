## 0.9.9.51 – 12.10.2026 (EXPERIMENTELL / MP-VORHALTEPUNKT + NORMALER LENKEINGANG)
- MP-Lenkeinfluss aus direkter Drivable.axisSide-Manipulation auf reguläre `vehicle:setSteeringInput`-Aufrufe umgestellt. GIANTS integriert die Lenkbewegung und versendet die vorhandene Fahrzeug-Update-Stream-Synchronisierung.
- Geometrische Vorhaltepunkt-Steuerung: Korrekturrichtung anhand der relativen Position und Fahrtrichtung normalisiert, ohne Änderung am funktionierenden SP-Regler.
- Manuelle Lenkbewegung über Schwellwert schaltet Assistenz ab, GPU/MP-Testgeschwindigkeit weiterhin auf 18 km/h begrenzt, Watchdog bleibt aktiv.
- Kursspeicherung/Server-Synchronisierung bytegenau unverändert gegenüber v0.9.9.50.
- 25 Lua-Skripte syntaktisch kompiliert. Geometrietests für linke und rechte Seiten sowie Gegenrichtung und manuellen Abbruch bestanden. **Echter Dedicated-Lenktest offen.**

## 0.9.9.50 – 12.10.2026 (EXPERIMENTELL / SANFTER MP-REGLER + TEMP-SAVE)
- MP-spezifische Steuerkorrektur deutlich abgeschwächt, Lenkwert auf +/-0.075 begrenzt und MP-Geschwindigkeitssperre bei >18 km/h. Bestehender SP-Regler und Sicherheits-Watchdog unverändert.
- FS25 übernimmt Multiplayer-Saves über einen temporären Snapshot. Kursdaten werden mit `ItemSystem.save` in dessen Verzeichnis geschrieben; der ursprüngliche Savegame-Pfad bleibt zur Ladenutzung fixiert. Verhindert das bisherige Verschwinden von XML-Daten beim Save-Promote.
- Neue Server-Logmeldungen `SERVER-SAVE-TEMP` bzw. `SERVER-SAVE-TEMP FEHLER` liefern Nachweis über Pfad und Kursanzahl.
- Geprüft: 25 Lua-Dateien syntaktisch, simulierter temporärer Savegame-Transfer und Neustart mit zwei Höfen, MP-Regler-Grenzwerte vs. unveränderte SP-Berechnung. Ingame-Lenkung und G-Portal-Persistenz müssen getestet werden.

## 0.9.9.49 – 12.10.2026 (EXPERIMENTELL / KURSABFRAGE + SPEICHERPFAD + MP-LENKEINGABE)
- GPSFarmCourseEvent: REQUEST hat absichtlich keinen Payload und darf nicht als unbekannter Opcode verworfen werden. Beitritt/Hofwechsel laden jetzt initial Kurse vom Server.
- Kursmanager: Original-Spielstanddatei beim ersten Load fixieren, nicht erneut aus tempsavegame laden oder die Kurstabelle leeren. Speichervorgang behält Hofkurse.
- MP-Client: experimentelle Korrektur über Drivable.axisSide mit normaler Netzwerk-Dirtystate-Synchronisierung, lokaler Fahrer-/Fahrzeugprüfung und manueller Übersteuerung; keine Änderungen am bisherigen SP-Physikpfad.
- Tests: 25 Lua-Skripte Syntax, XML/ZIP, simulierte Server-REQUEST-Verarbeitung, tempsavegame-Persistenz und MP-Lenkeingabe bestanden.
- Echte Ingame-Prüfung, besonders gleichzeitige Lenkung auf Dedicated Server, weiterhin offen.

## 0.9.9.48 – 12.10.2026 (EXPERIMENTELL / HOFKURS-CACHE + VERSIONSANZEIGE)
- Beim Hofwechsel zerstört der Client seine vorherige Hofkurs-Liste nicht mehr; bestätigte Snapshots sind strikt per Farm-ID zwischengespeichert.
- Sofortige Anzeige der passenden Hofliste und erneute Serverabfrage; verspätete Antworten für falsche Farm werden ignoriert.
- Neuer Server-Snapshot bleibt maßgeblich und ersetzt den Zwischenspeicher, auch wenn er leer ist.
- Versionswert zentral in GPSConfig.version, alle GUI-Seiten verwenden diesen Wert (Fix für sichtbare 0.9.9.46 in v47).
- Diagnose: Client-REQUEST und Server-REQUEST zeigen Farm und Kursanzahl.
- Tests: 25 Lua-Dateien kompiliert; isolierte Lua-Simulation für Farm 1 → Farm 2 → Farm 1, stale response, leere Serverliste und Reset bestanden.
- Echte Multiplayer-Regression und G-Portal-Neustart weiterhin ausstehend.

## 0.9.9.47 – 12.10.2026 (EXPERIMENTELL / MP-PERSISTENZ + HOFTRENNUNG)
- Korrigiert: Der GIANTS-Server-Save-Vorgang kann fremde XML-Dateien entfernen. Der Kursmanager schreibt terralineGPS.xml per FSBaseMission.saveSavegame-Hook nach jedem regulaeren Spielstand-Save erneut.
- Mehr Diagnose: SERVER-LOAD mit tatsächlichem Pfad und Kursanzahl, SERVER-SAVE-HOOK installiert und Anzahl der gespeicherten Kurse bzw. Fehler.
- TerraLine-Hauptschalter lokal je Hof getrennt: bei erstmaligem Hofbeitritt AUS; beim Wechsel kein Uebernehmen des Zustands anderer Hoefe. Alle aktiven Lenkungen werden beim Hofwechsel gestoppt.
- Unveraendert: GPS-Steuerung, A/B-Geometrie, GUI und bestehende Netzwerknachrichten.
- Simulation: reguläres Speichern bereinigt XML, Hook stellt die Datei wieder her, nach Neustart laedt der Server den Kurs; getrennte Hauptschalter Hof 1/2 getestet.
- Echte G-Portal-Neustart-Pruefung noch offen. Bereits geloeschte Kursdateien werden nicht automatisch wiederhergestellt.

## 0.9.9.46 – 12.10.2026 (EXPERIMENTELL / MP-BUGFIX)
- TerraLine GPS ist beim Laden eines Spielstands zunächst AUS.
- Aktive A/B-Linie, Kursname und GPS-Lenkung werden bei Hofwechsel (Host und Client) zurückgesetzt.
- Authentische Serverergebnisse für Hofkurs speichern/löschen statt voreiliger Erfolgsanzeige.
- Laden eines Hofkurses nur aus dem tatsächlich sichtbaren Bestand derselben Farm.
- MP-Event-Stream- und Lua-Testläufe bestanden; kein realer LS25-MP-Test.
- Geplante Fahrzeugshop-Ausstattung (+10.000 Euro) noch NICHT eingebaut.

## 0.9.9.45 – 12.10.2026 (EXPERIMENTELL)
- Erste MP-Datenstruktur: serververwaltete Hofkurse mit Farm-ID und Legacy-Farm-1-Migration.
- GIANTS-Netzwerk-Event fuer Hofkurs-Listen, Speichern und Loeschen; serverseitige Hofzugehoerigkeitspruefung.
- Client-Synchronisierung bei Hofwechsel/Beitritt und alle ca. 10 Sekunden; keine lokalen XML-Schreibzugriffe der Clients.
- MP-Testfreigabe in modDesc nur zum gezielten Testen, NICHT Freigabe der Multiplayer-Lenkung.
- Bewaehrte Lenkregelung und 3D-Linien unveraendert.

# Änderungsverlauf

## 0.9.9.44 – 12.10.2026
- Privates GitHub-Projekt vorbereitet (README, Rechtehinweise, .gitignore, Build- und Prüfscripts).
- Zwei interne Kennzeichnungskommentare ergänzt (ohne Programmverhalten zu ändern).
- Spielmod-Version erhöht; keine Änderungen an Lenkung, Feldrendering, Bedienung oder Menügrafiken.

## 0.9.9.43 – 12.10.2026
- Hauptschalter (Alt+T / Menütaste) für TerraLine GPS hinzugefügt.
- GPS-Funktionen, Felddarstellung und Anzeige werden beim Abschalten pausiert.

## 0.9.9.42
- Automatische Geräteversatzkorrektur in der Feld-Darstellung vom manuellen Kursversatz getrennt.

## 0.9.9.41
- Bestätigte Menü-/Symbolgrafiken und Blueprint-Vorschauen übernommen.

## Ältere Versionen
- Entwicklerdiagnose mit Feldnummer, Farmland und Geräteoffset.
- A/B-Erkennung und Spurführung, Gerätekorrektur, gespeicherte Kurse.

Die Versionshistorie ab 0.9.9.41 ist eine Zusammenfassung der bestätigten
Entwicklungsschritte; sie stellt keine vollständige Liste aller früheren
Einzeländerungen dar.
