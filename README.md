# TerraLine GPS – Farming Simulator 25

**Status:** private Multiplayer-Entwicklungsfassung **0.9.9.54** (12.10.2026); noch kein freigegebenes v1.0.

TerraLine GPS ergänzt A/B-Spurführung, gespeicherte Kurse, Lenkassistent,
manuellen Spurversatz, automatische Geräteversatz-Korrektur,
einstellbare Linienoptik und eine passwortgeschützte Entwicklerdiagnose.
Die Hauptfunktion wurde in **0.9.9.43** im Spiel getestet und bestätigt;
**0.9.9.44** war der dokumentierte stabile Ausgangsstand. **0.9.9.53** erweitert die serverseitige Hofkurs-Verwaltung und schaltet MP ausschließlich für Entwicklungstests frei.

## Installation für LS25

Aus den Quellen eine Spiele-ZIP erstellen:

```bash
python tools/build_mod.py
```

Das Ergebnis `dist/FS25_TerraLineGPS_v0_9_9_54.zip` direkt in den
FS25-Modordner kopieren, **nicht** entpacken. Ältere TerraLine-GPS-ZIPs vorher
aus dem Modordner entfernen. Vor Tests Spielstand sichern.

## Bedienung (Standard, im Spiel umbelegbar)

| Eingabe | Funktion |
|---|---|
| `Alt+T` | Gesamtes TerraLine GPS ein/aus |
| `Alt+B` | Punkt A/B setzen, mindestens 20 m Abstand |
| `Alt+X` | GPS-Lenkung ein/aus |
| `Alt+M` | Menü öffnen/schließen |
| `Alt+R` | Spur 90° drehen |
| `Alt+Bild↑ / Alt+Bild↓` | Gesamten A/B-Kurs in 1-cm-Schritten verschieben |

Die zwei zusätzlichen Buttons im Entwicklermenü sind noch Platzhalter.
Die Entwickler-PIN ist im Lua-Quellcode einsehbar und **kein echter Zugriffsschutz**.

## Repository-Organisation

- `scripts/` – Lua-Code für GPS, Lenkung, Kurse, Menü und Diagnose
- `gui/` – DDS-Menügrafiken und Vorschauen
- `sounds/` – Aktivierungs-/Deaktivierungstöne
- `modDesc.xml` – LS25-Mod-Metadaten und Eingabebelegung
- `docs/` – Projektstand, Rechteprüfung und Versionshistorie
- `tools/` – reproduzierbarer Mod-ZIP-Build und einfache Strukturprüfung

## GitHub: privat halten

1. Auf GitHub ein neues Repository `TerraLineGPS` mit Sichtbarkeit **Private** anlegen.
2. Projektordner lokal entpacken und im Terminal öffnen.
3. Folgende Befehle ausführen (nur wenn das GitHub-Repository noch leer ist):

```bash
git init -b main
git add .
git commit -m "TerraLine GPS v0.9.9.46 – MP-Entwicklungsstand"
git remote add origin https://github.com/DEIN-BENUTZERNAME/TerraLineGPS.git
git push -u origin main
```

`DEIN-BENUTZERNAME` durch den eigenen GitHub-Benutzernamen ersetzen.
Für die Anmeldung im Browser bzw. mit Git Credential Manager authentifizieren;
**niemals** Passwörter oder Tokens in die Repository-Dateien schreiben.

## Rechte und Veröffentlichung

Der private Repository-Zugang ersetzt **keine** Lizenzierung und ist **kein**
Kopierschutz. Derzeit ist **keine Open-Source-Lizenz** vergeben. Bitte vor
Weitergabe die Rechte an Quellcode, Grafiken und Sounds prüfen. Siehe
[`docs/RIGHTS_AND_ASSETS.md`](docs/RIGHTS_AND_ASSETS.md).

## Qualitätssicherung

```bash
python tools/check_project.py
python tools/build_mod.py
```

Diese Checks prüfen Dateistruktur, XML und Build – **nicht** die reale
Funktion im LS25 oder den offiziellen GIANTS TestRunner.

## Multiplayer-Entwicklungsstand v0.9.9.46 (NICHT freigegeben)

Dies ist ein **technischer MP-Testbuild**, keine fertige Multiplayerversion.
Die `modDesc.xml` erlaubt das Laden auf MP-Servern nur zum Testen. Die
GPS-Lenkung ist dort noch nicht freigegeben oder auf mehrere gleichzeitige
Fahrer geprüft. Zum Testen zunächst ohne aktivierte GPS-Lenkung beginnen.

- Gespeicherte Kurse tragen eine `farmId`, ältere SP-Kurse werden Farm 1 zugeordnet.
- Der Server speichert `terralineGPS.xml`; Clients schreiben **keine** lokalen Kursdateien.
- Die eigene Hofzugehörigkeit wird **serverseitig** anhand der Verbindung geprüft.
- Beim Beitritt und etwa alle 10 Sekunden holt ein Client nur Kurse des eigenen Hofs.
- Erstellen/Löschen wird als Anfrage an den Server geschickt. Das Menü zeigt die
  Anfrage zunächst als gesendet an. **Erst eine positive Serverbestätigung** setzt den Kursnamen als gespeichert; Ablehnungen werden im Kursmenü angezeigt.
- Laufende A/B-Spur und Lenkung eines Traktors werden nicht durch empfangene
  Hofkurslisten überschrieben; Kurs laden bleibt eine Aktion des lokalen Fahrers.
- Nach einem Hofwechsel werden **auch beim Host** die alte A/B-Linie, die aktive Kursanzeige und die lokale GPS-Lenkung zurückgesetzt. Der serverseitige Hofkursbestand bleibt unverändert.

Noch offen: unmittelbarer Push an alle Hofmitglieder, genauere Rollenrechte,
per-Fahrzeug-Lenkzustände und physische Lenkautorität auf Dedicated-Servern.
Siehe `docs/MP_TESTPLAN.md`.

## Änderungen v0.9.9.46 (MP-Bugfix-Stand)
- Hauptschalter startet nach jedem Spielstart standardmäßig AUS. Einschalten erfolgt mit Alt+T oder im TerraLine-Menü.
- Beim Hofwechsel (auch beim Host) verschwinden die alte A/B-Geometrie, die aktive Kursanzeige und die GPS-Lenkung; gespeicherte Hofkurse werden nicht gelöscht.
- Bei Multiplayer-Speicher-/Löschvorgängen schickt der Server explizit eine Erfolg-/Fehlerantwort. Ein nur versendeter Kurs gilt im UI nicht als gespeichert.
- Fremde Hofkurse können nicht geladen werden.
- Die 10.000-€-TerraLine-Ausstattung im Fahrzeugshop wird als eigenständiger nächster Entwicklungsschritt geplant; **in 0.9.9.46 nicht enthalten**.

**MP-Tests mit zwei Clients und Dedicated Server stehen noch aus.**

## Änderungen v0.9.9.47 – erneuter MP-Test nach Server-Neustart
- Auf dem Dedicated Server wird die Kursdatei **nach jedem regulaeren Spielstand-Save** mit dem `FSBaseMission.saveSavegame`-Hook neu geschrieben.
- Fuer die Ursachenpruefung erscheinen `SERVER-LOAD`, `SERVER-SAVE-HOOK installiert` und `SERVER-SAVE-HOOK: N Hofkurse ...` im Server-Log.
- GPS-Hauptschalter ist pro Hof **lokal getrennt**. Erstbesuch eines Hofs startet AUS, erneuter Besuch verwendet den zuletzt in dieser Sitzung geschalteten Hofzustand. GPS-Lenkung stoppt beim Wechsel stets.
- **Testfolge:** Testkurs in Hof 1 anlegen → in Hof 2 anlegen → Spiel speichern → Server stoppen → Server starten → je Hof die Kurse laden. Danach `SERVER-LOAD` und `SERVER-SAVE-HOOK` im Dedicated-Log kontrollieren.
- Sicherheitsregel: Vor dem Test Savegame sichern. Kursdaten aus v0.9.9.46 nur erhalten, falls deren `terralineGPS.xml` im Original-Savegame noch existiert. Nicht automatisch rekonstruierbar.
- Shop-Option (+10.000 EUR) weiterhin separat vorgesehen, NICHT eingebaut.

## MP-Test v0.9.9.53 (Hofwechsel / Version)
- Korrigiert: Beim Wechsel zwischen Hoefen wird die empfangene Kursliste nicht mehr unwiderruflich geleert.
- Pro Farm wird **nur ein zuvor vom Server bestaetigter Snapshot** lokal zwischengespeichert.
- Auf jedem Hofwechsel fordert der Client weiterhin einen frischen, verbindlichen Snapshot an; der Server ist autoritativ und darf den Cache ersetzen (auch leeren).
- Verspaetete Serverantworten eines anderen Hofs werden verworfen.
- GUI-Version wird auf allen Menue-Seiten zentral aus `GPSConfig.version` gelesen.
- Keine Aenderung an GPS-Lenkung oder am getrennten Hof-Hauptschalter.
- Bestehende KI-/Shop-Ausstattung weiterhin unveraendert; die 10.000-Euro-Shopoption ist separat geplant.
- Mehr Diagnose zum Kurslisten-Request im Server- und Client-Log.


### Version 0.9.9.53 – MP-Testhinweise
- Der REQUEST-Event wird im ReadStream jetzt angenommen; beim Beitritt und Hofwechsel werden Hofkurse ohne vorherige Speicheraktion geladen.
- Der Server hält den Original-Spielstandpfad über temporäre GIANTS-Save-Verzeichnisse hinweg stabil; gespeicherte Kurse werden nicht mehr durch einen leeren tempsavegame-Snapshot überschrieben.
- Experimenteller Client-Eingabepfad für GPS-Lenkung nutzt Drivable.axisSide und GIANTS dirtyFlags statt ausschließlich eines serverseitigen Physik-Hooks. Manueller Lenkeingriff deaktiviert die Lenkung.
- Die Multiplayer-Lenkung ist **noch nicht ingame bestätigt**, daher keine Freigabe für produktive Server oder v1.0.


### 0.9.9.53 – MP-Testfix
- Vorsichtige **MP-spezifische** Lenkverstärkung mit maximal 0,075 Lenkwert und Sicherheitsabschaltung über 18 km/h; Singleplayer-Regler nicht geändert.
- Die serverseitigen Hofkurse werden bei `ItemSystem.save` direkt in den von GIANTS verwendeten Speicher-Snapshot (ggf. `tempsavegame`) geschrieben, damit sie beim Übernehmen des Spielstands nicht verschwinden.
- Serverlog `SERVER-SAVE-TEMP` zeigt Pfad und Kursanzahl. Ein echter G-Portal-Speicher- und Neustarttest ist noch erforderlich.


### v0.9.9.53 – MPUnd Lenkrad-Synchronisierung (experimentell)
Der experimentelle MP-Regler verwendet einen Vorhaltepunkt auf der aktiven A/B-Spur und übergibt das Lenksignal über die normale Fahrzeugfunktion `setSteeringInput`, statt den internen Wert `spec_drivable.axisSide` direkt zu überschreiben. Das soll die im Spiel sichtbare Lenkbewegung mit der Spurhaltung koppeln. Korrekturrichtung ist anhand der A/B-Geometrie links/rechts/reversiert simuliert, manuelle Übersteuerung stoppt GPS. MP-Tempolimit 18 km/h, Sicherheitsausschaltung und Singleplayer-Regler bleiben. Der echte Lenkrad- und MP-Fahrtest steht noch aus. Die serverseitige Hofkurs-Speicherung aus v0.9.9.50 ist unverändert.


### 0.9.9.53 – MP-Lenkrichtungstest
- Nach dem realen v51-Fahrtest (Traktor lenkt von der Linie weg, Abbruch mit 'Abweichung zu gross') wird das **Vorzeichen ausschließlich am normalen MP-Lenkeingang** umgekehrt; die Vorhaltepunkt-Geometrie, Singleplayer-Lenkung und funktionierende MP-Kursspeicherung bleiben unverändert.
- Client-Log etwa alle 1,5 Sekunden: `GPS-LENK MP INPUT` mit Spurabweichung, logischem und nativem Lenksignal.
- **Noch kein erfolgreicher Ingame-Lenktest**. Version nur vorsichtig bei 5–8 km/h auf freiem Feld testen; nicht nach `main` übernehmen.


### v0.9.9.53 – MP 30 km/h, bereinigte Logs
- SP und MP jetzt maximal 30 km/h (Prüfung bei Einschalten und während der Fahrt). Funktionierende v52-Lenkrichtung und A/B-Regelung unverändert.
- Log-Präfix `[TerraLine GPS]` statt `[GPSFieldTest]`; interner Lua-Listenername `GPSFieldTest` bleibt aus Kompatibilitätsgründen erhalten.
- Laufende Telemetrie (GPS-LENK Spur/Trend/MP INPUT, Geräteversatz-Messwerte, regelmäßige Kurs-REQUEST/SNAPSHOT-Meldungen) läuft über `GPSLogger.debug`, standardmäßig deaktiviert (`GPSConfig.showDiagnostics=false`). Ereignisse, Fehler und Speichern/Laden bleiben sichtbar. Debug-Meldungen erscheinen mit `DIAG`.
- Kursspeicherung und Netzwerkprotokoll unverändert bis auf die Logausgabe.
- Syntaxprüfung mit Lua 5.4 aller 25 Skripte, Logger-Debug-Funktionstest, ZIP/XML-Kontrolle erfolgreich. GPS-Spurhaltung bei realen 30 km/h noch nicht bestätigt.


### v0.9.9.54 – Diagnose im Entwicklermenü (experimentell)
Die beiden vorhandenen Optionsbuttons der Entwicklerdiagnose heißen nun **DIAG EIN** und **DIAG AUS** und schalten die detaillierten Konsolen- und Overlay-Messwerte des lokalen Clients live über `GPSConfig.showDiagnostics`. Standard ist **AUS**. Die Funktion ist ausschließlich im entsperrten Entwicklerbereich verfügbar, schaltet sich nicht automatisch beim Betreten ein und wird nicht als Spieleinstellung dauerhaft gespeichert. Der Snapshot-Knopf bleibt erhalten. **GPS-Lenkung, 30-km/h-Grenze, Hofkurs-Persistenz und Netzwerkcode bleiben bytegenau unverändert.**
