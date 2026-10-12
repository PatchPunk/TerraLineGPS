## 0.9.9.60 Bilingual Candidate – 12.10.2026
- Added English translations `README_EN.txt` and `PROJECT_NOTICE_EN.txt`; original German `README.txt` retained. Updated German `PROJECT_NOTICE.txt` to the supplied version.
- Release ZIP contains 41 files; no Lua, XML, audio or graphic code/content changes relative to previous v0.9.9.60 candidate. ZIP CRC/integrity verified. In-game testing still pending; do not publish or merge.

## 0.9.9.60 – 12.10.2026 (PUBLIC BETA CANDIDATE – NOT YET RELEASED)
- Free public PC beta candidate for Mod für Farming Simulator 25 under author PatchPunk; readme/description/notices updated to real v59 confirmed capabilities and known two-player MP limitation.
- Disabled active steering-test console command `gsGPSSteerTest`; `GPSSteeringDiagnostics.start` fails closed whenever beta mode is enabled or unset. No changes to the actual GPS assist steering module.
- Farm course permissions confirmed by owner: ALL members of same farm can save/delete farm courses; existing server farm-ID check enforces isolation. No farm manager-only permission gate.
- Code changes limited to `scripts/Config.lua`, `scripts/GPSFieldTest.lua`, `scripts/SteeringDiagnostics.lua`, plus updated `modDesc.xml`, `README.txt`, `PROJECT_NOTICE.txt`. 33 other ZIP members byte-identical to v59.
- 27/27 Lua syntax checked; XML parsed; ZIP 39 files CRC OK; live Lua mock diagnostics checks pass for beta flag ON/missing. Original v59 unchanged. **Public-Beta candidate NOT YET INGAME TESTED OR PUBLISHED**. PR remains Draft.

## 0.9.9.59 – 12.10.2026 (DEZENTE, GLEICHMAESSIGE BADGE-TRANSPARENZ)
- Nutzer bestätigt v58-Position und Design der Statusplakette links neben Geschwindigkeitstacho. Gewünscht: leichte Transparenz.
- `GPSTachoStatus.lua`: Badge-Hintergrund Alpha .78 statt .88. Drei aneinanderstoßende Teilflächen ohne Overdraw (oben / Mitte / unten) statt sich überlagernder Rechtecke; verhindert ungleichmäßig abgedunkeltes Zentrum. Symbol/Statusbalken/Text unverändert, keine neue Zeichengeometrie außerhalb vorhandener Badge-Abmessungen.
- Nur GPSTachoStatus.lua sowie README.txt, Config.lua, modDesc.xml geändert. Tests: 27/27 Lua Syntax; echte Lua Runtime Assertions für alle 3 Zustände und nicht überlappende Hintergründe; ZIP CRC/XML und Bytevergleich übriger Skripte erfolgreich.
- Reale LS25-Transparenz noch nicht nach Nutzer-Update bestätigt. Multiplayer-Zwei-Spieler- und Host-Abnahmetests offen.

## 0.9.9.58 – 12.10.2026 (KOMPAKTE TACHOPLAKETTE – NUTZER FREIGEGEBEN)
- Screenshot-Test v57: TerraLine-Text überlappt mit Weizen-/Füllstandsbalken und passt nicht zum nativen Tacho. Nutzer hat kompakte dunkle Plakette **links neben dem runden Geschwindigkeitsmesser** genehmigt.
- Neue `GPSTachoStatus`-Darstellung: kompakte dunkle 124×55 HUD-Pixel-Plakette, native `gui.icon_gps`-Grafik, kleiner farbiger Statusbalken, zwei Textzeilen `TL GPS` und `AUS` (grau) / `BEREIT` (grün) / `AUTO AKTIV` (grün).
- Position orientiert sich an `SpeedMeterDisplay.speedBg.x` und der **vertikalen Tachomitte**; skaliert mit nativer HUD-Pixelumrechnung. Die Füllstandsanzeige bleibt frei. Bei Platzmangel oder ohne Ausstattung wird nichts gezeichnet.
- 27 Lua-Syntaxprüfungen, Lua-Mock-Laufzeittest für Anzeige in allen drei Zuständen, Abstände, Ausrüstungsfilter und Platzmangel erfolgreich. ZIP unverändert 39 Dateien. Noch kein LS25-Ingame-Beweis.
- Alle Shop-, Menü-, Steering-, CourseManager-, FarmCourseEvent- und GPSFieldTest-Skripte bytegenau unverändert gegenüber v57. Draft-PR bleibt offen.

## 0.9.9.57 – 12.10.2026 (SHOP-XML-FIX + MENÜ-SPERRE + NATIVER FS25-TACHO)
- Logs v56: Server und Client melden unerlaubte XML-Schema-Zugriffe `vehicle#type` bei `data/placeables/...`: Shop-Eligibility prüft Kategorie jetzt VOR XML-Zugriff.
- Ein Fahrzeug ohne gekaufte TerraLine-Ausstattung kann das Menü nicht mehr über Alt+M (native und Fallback), Konsolenbefehl oder anderen `GPSMenu.toggle`-Aufruf öffnen. Offenes Menü schließt bei Fahrzeugwechsel oder Ausbau automatisch.
- Die zusätzliche Statusanzeige im GIANTS-Tacho war unsichtbar, da die v55/v56-Version `gaugeBackgroundElement` aus älteren FS-Versionen verwendete. FS25 dokumentiert `SpeedMeterDisplay.speedBg`; Statuslabel wird nun an die echte Position des Speedmeter-Overlays gekoppelt, inkl. HUD-Skalierung.
- Drei freigegebene Statusfarben/-texte beibehalten, ohne Ausstattung keine Anzeige. Kein neues Menü oder Layout.
- Test: 27 Lua-Skripte syntaktisch kompiliert; Lua-Mocktest native Konfiguration 0/10000, Placeable-Ausschluss ohne Fahrzeug-XML-Zugriff, Menü-Sperre und Auto-Close, Tacho AUS/BEREIT/AKTIV. ZIP 39 Dateien OK. Echte GIANTS-Rendering-Validierung ausstehend.
- SteeringController, GPSCourseManager, GPSFarmCourseEvent und TrackPosition exakt unverändert zu v56.

## 0.9.9.56 – 12.10.2026 (KRITISCHER SHOP-CRASH-HOTFIX)
- Nutzerlogs von v55 Server/Client: `GPSVehicleEquipment.lua:62: attempt to call a table value` tausendfach bei jedem Fahrzeuglade/Engine-Update, danach `Script error in openIntervalTimer: No more interval timers`. V55 darf nicht weiter genutzt werden.
- Native `ConfigurationUtil.getConfigurationsFromXML` via `Utils.overwrittenFunction`: `manager` und `superFunc` standen in falscher Reihenfolge; korrektes Weiterleiten des Originalaufrufs und Ergebnisses hergestellt.
- Fehler bei TerraLine-OPTIONALER Shop-Ergänzung werden abgefangen und führen zu sicherem Einmal-Fallback; kein per-frame-Fehlerspam. Native Funktion bleibt autoritativ.
- Tests 27 Lua-Syntax, 200 wiederholte fehlerhafte Calls ohne Spam, native Manager/Super-Aufruf, 0/10K, Trailer-Ausschluss. ZIP validiert, Lenk-/Kurs-/Netz-/Tachodateien byte-identisch zu v55.
- Echter Ingame-Shop/Werkstatt-Test steht aus; bei weiterem unerwarteten Problem auf v54 zurückrollen.

## 0.9.9.55 – 12.10.2026 (EXPERIMENTELL / NATIVE SHOP-KONFIGURATION + TACHO)
- Fahrzeug-Konfigurations-API nach GIANTS Precision-Farming-Vorbild: neue `terraLineGPS`-Option in Standard-Fahrzeugshop und nativer Werkstatt, 0 € AUS (Standard) / 10.000 € EIN. Der Preis wird vom Spiel über `VehicleConfigurationItem.price` verarbeitet, kein manueller Geldabzug.
- Fahrzeugmerkmale gehen mit GIANTS `vehicle.configurations` in Savegame und Netzwerk, nicht in das TerraLine-Hofkurs-XML. Nichtmotorisierte Geräte ausgeschlossen.
- Ohne Ausrüstung kein GPS; vorhandene Fahrzeuge standardmäßig ohne neue Ausrüstung und ohne rückwirkende Kosten. Lokales GPS pro Fahrzeug, bei Hofwechsel/Ausbauen automatisch AUS.
- Dreistufige Statuszeile am vorhandenen SpeedMeterDisplay; ohne Ausstattung keine Anzeige. Kein neuer Shop-Bildschirm.
- Alle bestehenden 30-km/h-Steuerungs- und Hofkursdateien unverändert; Tests 27 Lua-Syntax, XML/ZIP, Mock-Shop/Anzeige/Fahrzeugwechsel bestanden.
- **Noch nicht im LS25 selbst bestätigt**: Shopanzeige, Werkstatt-Umbau, Kaufpreis und reale Synchronisierung. Draft-PR nicht mergen.

## 0.9.9.54 – 12.10.2026 (ENTWICKLERDIAGNOSE EIN/AUS)
- Die zwei bereits sichtbaren aber bislang funktionslosen Optionsbuttons im Entwicklermenü werden zu `DIAG EIN` und `DIAG AUS` mit funktionierenden Klick-Aktionen und Zustandsmarkierung.
- Nach Entsperren kann die detaillierte Diagnose per `GPSDeveloperMenu.setDiagnosticsEnabled` lokal aktiviert/deaktiviert werden. Standardwert beim Modstart `GPSConfig.showDiagnostics=false`; der Spielstand speichert diese Option nicht.
- `GPSLogger.debug` und die optionale Ingame-Diagnose reagieren sofort, wichtige Info-/Fehlerlogs bleiben auch bei AUS sichtbar. Zugang nur über entsperrtes Entwicklermenü.
- Bestehende Layoutpositionen bleiben unverändert. `SNAPSHOT INS LOG` funktioniert weiter.
- Lua-Syntaxprüfung 25/25, simulierter UI-Klick- und Logger-Test sowie ZIP-Prüfung erfolgreich. Keine Änderungen an SteeringController, CourseManager, FarmCourseEvent oder TrackPosition. Echte GUI-Prüfung im LS25 steht noch aus.

## 0.9.9.53 – 12.10.2026 (MP 30 KM/H + LOG-BEREINIGUNG)
- GPS-Lenkung SP/MP: einheitliche Geschwindigkeitsgrenze 30 km/h für Aktivieren und Sicherheitsabschaltung; bisherige 18-km/h-MP-Testbegrenzung entfernt.
- Sichtbare Konsolenkennung `[TerraLine GPS]` statt `[GPSFieldTest]`. Interne Klassen, GIANTS-InputActions und Dateipfade absichtlich unverändert.
- `GPSLogger.debug` für regelmäßig wiederkehrende Telemetrie; nur aktiv, wenn `GPSConfig.showDiagnostics=true`. Wichtiges Status- und Fehlerlogging bleibt in `GPSLogger.info`.
- SP/MP-Kursdatenpersistenz, Events und bestätigte v52-MP-Lenkrichtung nicht verändert.
- 25 Lua-Syntaxprüfungen bestanden; geprüft, dass GPSFarmCourseEvent.lua, GPSFieldTest.lua, A/B und TrackPosition bytegenau identisch zu v52 sind. Noch kein Fahrtest bei 30 km/h.

## 0.9.9.52 – 12.10.2026 (EXPERIMENTELL / MP LENKRICHTUNG)
- V51-Dedicated-Client-Logs: `GPS-LENK MP-CLIENT` aktiv, danach mehrfach `Abweichung zu gross`; bestätigte Nutzerbeobachtung: Steuerung lenkt in die falsche Richtung.
- Korrektur: Logischer Korrekturwert bleibt unverändert, aber vor `vehicle:setSteeringInput` wird das Vorzeichen ausschließlich für den MP-Drivable-Eingang umgekehrt. Die bisherige physische Achsenannahme aus dem alten Physics-Hook war auf dem nativen Drivable-Eingang offenbar nicht passend.
- Neues `MP INPUT`-Telemetry (Offset, logisch, an Drivable) alle ~1,5s.
- 25/25 Lua-Dateien Syntax geprüft, modDesc/ZIP konsistent. Keine Änderung an `GPSCourseManager.lua` oder bestehenden SP-Funktionen.
- Erfolgreicher MP-Lenkrichtungstest fehlt weiterhin: diese Änderung ist eine empirisch begründete Hypothese, keine bestätigte Ingame-Reparatur.

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
