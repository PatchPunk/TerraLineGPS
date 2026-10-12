# TerraLine GPS – Ingame-Releaseprüfung v0.9.9.60

**Prüfdatum:** 12.10.2026, 23:16–23:28 Uhr (Log-Zeitstempel)  
**Entwickler / Herausgeber:** PatchPunk  
**Geprüfte Mod:** `FS25_TerraLineGPS_v0_9_9_60_beta_bilingual_contact_candidate.zip` (Hash im GIANTS Client-/Server-Log: `1c05f806018ca0044d6e2addb013850c`)  
**Umgebung:** LS25 1.24.0.0, Client + Dedicated Server, ein verbundener Spieler, FS25-Modtraktoren / Anbaugerät Carrier XL 625  
**Nachweise:** `log(20261012-212911).txt`, `log_2026-10-12_23-16-21.txt`, acht echte LS25-Screenshots vom Test.

## Ergebnisse – durch Screenshot und/oder Log belegt

| Prüfpunkt | Ergebnis und belegbare Details |
|---|---|
| Spielstart | **PASS** – v0.9.9.60 auf Client und Dedicated Server geladen, Entwicklername `PatchPunk` serverseitig bestätigt |
| Lua-Fehler im Test | **PASS** – 0 `Error`-, `Failed`- oder `Exception`-Meldungen in beiden vorgelegten Logs |
| Shopkonfiguration | **PASS für Sichtbarkeit** – native Option `TERRALINE GPS` im CLAAS-Arion-Kaufmenü sichtbar, gewählte Option `OHNE` +0 €; Log registriert native Konfiguration; der gezeigte Screenshot belegt noch nicht selbst eine `MIT` +10.000 €-Auswahl |
| Ohne TerraLine Ausrüstung | **PASS** – GPS-Menü am nicht ausgerüsteten Fahrzeug durch Gate gesperrt (Client 23:20:31); fehlendes GPS-Tacho-Badge am Vergleichsfahrzeug sichtbar |
| Mit TerraLine Ausrüstung | **PASS** – eigener Status links vom Tacho; GPS-System auf Fendt 939 aktiviert, 6,10 m Carrier XL 625 erkannt |
| A/B-Punkte und GPS-Spuren | **PASS** – A 23:25:20, B 23:25:50 gesetzt, 20-m-Mindestabstand im Test eingehalten; farbige Führungslinien in Außen-/Kabinenansicht sichtbar |
| Assist-Lenkung | **PASS für Aktivierung und Eingabeweg** – GPS-Lenkung aktiviert 23:26:09 und erneut 23:27:45; `GPS-LENK MP: Lenkeingabe nach Anfahren aktiv` 23:27:49. **Spurhaltequalität, 30-km/h-Grenze und Fehlertoleranz nicht allein durch Logs bestätigt.** |
| Einstellmenü | **PASS** – Seite Spurführung und Seite Speicher per Screenshots und Log bestätigt |
| Hofkurs löschen | **PASS** – 2 hofbezogene Löschungen von Client ausgelöst und von Server für Hof 2 bestätigt (23:27:07 und 23:27:10) |
| Hofkurs speichern | **PASS** – Kurs `Stoppelsturz Feld 54 6M` von Server für Hof 2 bestätigt (23:27:32); anschließend lokal geladen |
| Save-Hook | **PASS für Snapshot-Schreibung** – 3 Hofkurse von Server in `tempsavegame/terralineGPS.xml` geschrieben (23:28:41), Spielstand erfolgreich gespeichert 23:28:44. Wiederladen nach **erneutem** Restart in genau v60 noch nicht gezeigt |
| Zwei gleichzeitige MP-Spieler | **OFFEN** – kein Test mit zwei Fahrern in getrennten Fahrzeugen / Farmen |
| Hosted MP + vollständige SP-Regression | **OFFEN** |

## Nicht blockierende Warnungen und offene Punkte

1. **Aufräumen des Client-Modordners:** `FS25_TerraLineGPS_v0_9_9_59` ist dort zusätzlich als *entpacktes Verzeichnis* vorhanden, weswegen das Spiel warnt: `Only zip mods are supported in multiplayer`. Im Test wurde v0.9.9.60 geladen, aber der v59-Ordner sollte entfernt werden.
2. **TerraLine Sounds:** Je eine Performance-Warnung zu `sounds/gpsActivate.wav` und `sounds/gpsDeactivate.wav` wegen Raw-Audio-Format. Keine Lua-Fehler oder Abbrüche; spätere kompatible Audio-Optimierung getrennt planen.
3. **Server:** Einmal `Warning: Saving while already saving` bei 23:28:44; anschließend `Game saved successfully (savegame2)`. Ursache nicht nachgewiesen; bei wiederholten Tests beobachten.
4. **Fremdmods:** Doppelte Übersetzungskennungen im `FS25_ClaasArion660`, weitere Fendt-Mod-/LOD-/Physik-Warnungen; bislang kein Nachweis, dass TerraLine sie auslöst.
5. **Öffentliche Beta-Kommunikation:** Zwei-Spieler-MP sowie eigener Hosted-Server ausdrücklich als nicht abschließend bestätigt kommunizieren. Ein rechtmäßiger, kostenfreier Mod für FS25; keine GIANTS-Partnerschaft behaupten.

## Empfohlene echte Upload-Bilder (unverändert, 2048×1152)

- `01_Shop_TerraLine_Konfiguration.png` – ursprüngliche Aufnahme `fsScreen_2026_10_12_23_19_40.png`
- `02_GPS_Spuren_Aussenansicht.png` – `fsScreen_2026_10_12_23_26_04.png`
- `03_Cockpit_GPS_aktiv.png` – `fsScreen_2026_10_12_23_26_15.png`
- `04_TerraLine_Menue_Spurfuehrung.png` – `fsScreen_2026_10_12_23_26_55.png`
- `05_TerraLine_Menue_Kursspeicher.png` – `fsScreen_2026_10_12_23_27_40.png`

Die Bilder sind im separaten Archiv `TerraLineGPS_v0_9_9_60_ForbiddenMods_Screenshots.zip` verpackt. Die tatsächliche Upload-Beschränkung (Anzahl, MB, Auflösung) auf Forbidden Mods ist noch zu prüfen.

**Release-Status:** Vorbehaltlich deiner Bestätigung der tatsächlichen Lenkfunktion im Fahrbetrieb ist v0.9.9.60 als **öffentlicher Beta-Testkandidat** tauglich; noch nicht veröffentlicht. GitHub `main` und v0.9.9.59 unverändert; privater Entwicklungs-PR bleibt Draft. Empfehlung vor Downloadportal-Upload: finale Mod-ZIP unter kanonischem Namen `FS25_TerraLineGPS.zip` getrennt validieren (Modidentität kann sich beim Umbenennen ändern), und im Portal genau dessen Vorgaben bestätigen.