# TerraLine GPS – Farming Simulator 25

**Status:** private Multiplayer-Entwicklungsfassung **0.9.9.45** (12.10.2026); noch kein freigegebenes v1.0.

TerraLine GPS ergänzt A/B-Spurführung, gespeicherte Kurse, Lenkassistent,
manuellen Spurversatz, automatische Geräteversatz-Korrektur,
einstellbare Linienoptik und eine passwortgeschützte Entwicklerdiagnose.
Die Hauptfunktion wurde in **0.9.9.43** im Spiel getestet und bestätigt;
**0.9.9.44** war der dokumentierte stabile Ausgangsstand. **0.9.9.45** erweitert die serverseitige Hofkurs-Verwaltung und schaltet MP ausschließlich für Entwicklungstests frei.

## Installation für LS25

Aus den Quellen eine Spiele-ZIP erstellen:

```bash
python tools/build_mod.py
```

Das Ergebnis `dist/FS25_TerraLineGPS_v0_9_9_45.zip` direkt in den
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
git commit -m "TerraLine GPS v0.9.9.45 – MP-Entwicklungsstand"
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

## Multiplayer-Entwicklungsstand v0.9.9.45 (NICHT freigegeben)

Dies ist ein **technischer MP-Testbuild**, keine fertige Multiplayerversion.
Die `modDesc.xml` erlaubt das Laden auf MP-Servern nur zum Testen. Die
GPS-Lenkung ist dort noch nicht freigegeben oder auf mehrere gleichzeitige
Fahrer geprüft. Zum Testen zunächst ohne aktivierte GPS-Lenkung beginnen.

- Gespeicherte Kurse tragen eine `farmId`, ältere SP-Kurse werden Farm 1 zugeordnet.
- Der Server speichert `terralineGPS.xml`; Clients schreiben **keine** lokalen Kursdateien.
- Die eigene Hofzugehörigkeit wird **serverseitig** anhand der Verbindung geprüft.
- Beim Beitritt und etwa alle 10 Sekunden holt ein Client nur Kurse des eigenen Hofs.
- Erstellen/Löschen wird als Anfrage an den Server geschickt. Das Menü zeigt die
  Anfrage zunächst als gesendet an; auf die Serverbestätigung/Synchronisierung warten.
- Laufende A/B-Spur und Lenkung eines Traktors werden nicht durch empfangene
  Hofkurslisten überschrieben; Kurs laden bleibt eine Aktion des lokalen Fahrers.
- Nach Hofwechsel löscht der Client seinen bisherigen Hofkurs-Cache.

Noch offen: unmittelbarer Push an alle Hofmitglieder, genauere Rollenrechte,
per-Fahrzeug-Lenkzustände und physische Lenkautorität auf Dedicated-Servern.
Siehe `docs/MP_TESTPLAN.md`.
