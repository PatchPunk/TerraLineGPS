TERRALINE GPS - VERSION 1.0.0.0 - PRE-RELEASE / FBM + GITHUB
Landwirtschafts-Simulator 25 (PC) | Autor: PatchPunk
Kontakt: patchpunk@mail.de | Stand: 29.10.2026

TEST- UND VEROEFFENTLICHUNGSSTATUS
- Pre-Release fuer Forbidden Mods (FBM); Upload muss vom Autor erfolgen.
- Offizieller GIANTS TestRunner: Phase 18 am 29.10.2026 15/15 PASS,
  ohne Lua-Warnungen. Die MP-Geraeteerkennung/Versatzkorrektur wurde
  danach gezielt angepasst und ist noch NICHT im Spiel getestet.
- Einzelspieler: A/B-Erfassung, GPS-Lenkung, NewGUI und Arbeitsbreiten-/
  Mähwerksversatz vom Entwickler positiv getestet.
- Dedicated Server mit einem Client: Server-Synchronisation, GPS-Lenkung,
  Kursabfragen und Hofwechsel durch Spiel-LOGs belegt.
- Durch den Entwickler bestaetigt: Kurs nach SERVERNEUSTART erneut laden;
  Kurs dauerhaft loeschen und nach Neustart entfernt.
- NICHT bestaetigt: zwei gleichzeitig spielende Nutzer auf demselben Hof,
  konfliktfreie Kursverwaltung bei gleichzeitigen Eingriffen.
- Keine Konsolen-Freigabe, wegen Lua-Skripten PC-only.

FUNKTIONEN
- Freie A/B-Spuren und automatische Lenkassistenz auf geraden parallelen Bahnen.
- A/B in drei Schritten: Alt+B 1x scharfstellen und drei weisse Vorschau-
  Linien anzeigen; 2x A setzen/Messung beginnen; 3x B nach >=20 m festlegen.
- Rote/gruene Mittellinie, gelbe Arbeitsgrenzen, Linienhoehe/-dicke.
- Arbeitsbreite, Spuren verschieben, 90-Grad-Winkel, 0,1-Grad-Feindrehung.
- Ausgewaehlte Front-, Heck- und Seitenmaehwerkskombinationen werden mit
  Gesamtbreite und Versatz erkannt; unklare Kombinationen sind gesperrt.
- GPS-Status im GIANTS-Tacho, originaler LS25-GPS-Ein-/Ausschaltton.
- Optionale TerraLine-GPS-Ausstattung an geeigneten Fahrzeugen im Shop
  (+10.000 Euro).
- Kurse hofbezogen benennen, speichern, laden und loeschen.

TASTEN (im Spiel umbelegbar)
Linke Alt+T         Hauptschalter ein/aus
Linke Alt+B         1x scharfstellen / 2x A / 3x B (mind. 20 m)
Linke Alt+X         GPS-Lenkung kurz ein/aus; ca. 3s halten: Spur 1 setzen
Linke Alt+M         Einstellungsmenue ein/aus
Linke Alt+R         Kurs um 90 Grad drehen
Rechte Alt+W        Feinwinkelmodus (im Stillstand) ein/aus
Linke Alt+J / N     Winkel im Modus um +0,1 / -0,1 Grad aendern
Linke Alt+Bild hoch / runter  Kurs rechts / links verschieben

SPIELSTAND UND MULTIPLAYER
WICHTIG: Nach Kurs speichern oder loeschen MUSS der LS25-Spielstand
explizit gespeichert werden. Kursdaten: terralineGPS.xml im Savegame.
Vor dem Update immer ein Savegame-Backup erstellen. Alte TerraLine-ZIPs
entfernen; Server und Clients benoetigen exakt das gleiche ZIP.
Automatische Geraeteerkennung inkl. stabilisierter Maehwerk-Gesamtbreite
und automatische Geraeteversatzkorrektur sind im Multiplayer FREIGESCHALTET,
aber NOCH NICHT im Spiel mit zwei Spielern getestet (experimentell).
Geraete-Auto im eigenen Traktor bei Stillstand und GPS AUS einschalten;
auf "Bereit" warten. Bei unklarer Geometrie bleibt die GPS-Lenkung gesperrt
bzw. schaltet ab. GPS-Lenkung im MP nur nahe und parallel zur Spur aktivieren. Maximal 30 km/h; Sicherheitsabschaltungen bleiben aktiv.
Keine Konturlenkung; FieldContour und Tramline Manager nicht enthalten.

FEHLER MELDEN: patchpunk@mail.de (LS25-Version, Reproduktionsschritte,
log.txt). Nicht offiziell von GIANTS Software hergestellt.
