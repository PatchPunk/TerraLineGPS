# TerraLine GPS – Forbidden Mods: Entwurf und Testplan

**Status:** Veröffentlichungstext vorbereitet, noch **nicht veröffentlicht**.  
**Mod-Version:** 0.9.9.60 (Public-Beta-Kandidat)  
**Autor:** PatchPunk  
**Kontakt:** patchpunk@mail.de  
**Spiel:** Farming Simulator 25 / Landwirtschafts-Simulator 25 (PC)

## Veröffentlichungsbeschreibung – Deutsch

### TerraLine GPS – GPS-Spurführung für den Landwirtschafts-Simulator 25 (Public Beta)

Mit **TerraLine GPS** erhältst du eine eigenständige A/B-Spurführung mit Lenkunterstützung für den LS25. Du setzt zwei Referenzpunkte auf dem Feld, legst deine Fahrspur an und kannst die Arbeit anschließend mit gespeicherten Kursen fortsetzen.

**Funktionen:**
- A/B-Spurführung mit zuschaltbarer Lenkunterstützung für gerade Spuren bis 30 km/h
- Benannte GPS-Kurse speichern, laden und löschen; gemeinsame Kursverwaltung pro Hof
- Spurversatz, 90°-Drehung, Arbeitsbreite und optische GPS-Einstellungen
- Geräteversatz-Diagnose
- Fahrzeuggebundene GPS-Ausstattung im normalen Shop für 10.000 € Spielgeld, in der Werkstatt nachrüstbar
- Kompakte, leicht transparente GPS-Statusanzeige neben dem originalen LS25-Tacho
- Deutsch- und englischsprachige Dokumentation

**Beta-Hinweise:** Das System wurde im Spiel und mit einem Client auf einem Dedicated Server getestet; auch Werkstattumbau sowie Kurs- und Fahrzeugausstattung nach Serverneustart wurden bestätigt. Die gleichzeitige Nutzung durch zwei Spieler und selbst gehostete Multiplayer-Partien sind noch nicht abschließend geprüft. Bitte den Spielstand vorher sichern und ältere TerraLine-Versionen aus dem Mod-Ordner entfernen.

**Nicht enthalten:** Fahrgassensteuerung, Feldrandgassen und Section Control. Diese Funktionen sind als separates Addon geplant.

**Fehler melden / Feedback:** patchpunk@mail.de. Bitte Spielversion, Mod-Version, kurze Reproduktionsschritte und möglichst das Client-/Server-Log angeben.

**Kostenloser PC-Mod von PatchPunk. Mod für Farming Simulator 25. Keine offizielle GIANTS-Modifikation.**

## Release description – English

### TerraLine GPS – A/B GPS Guidance for Farming Simulator 25 (Public Beta)

**TerraLine GPS** adds independent A/B guidance and optional steering assistance to Farming Simulator 25. Set two reference points in the field, establish your guidance line and continue working with saved courses.

**Features:**
- A/B guidance and toggleable steering assistance on straight lines at speeds up to 30 km/h
- Named GPS courses: save, load and delete; courses shared by members of the same farm
- Manual guidance-line shifting, 90° rotation, adjustable working width and line appearance
- Implement-offset diagnostics
- Vehicle-specific GPS upgrade in the regular vehicle shop for €10,000 of in-game currency, also available through the standard workshop
- Compact, slightly transparent GPS status badge next to the original FS25 speedometer
- German and English documentation

**Beta notice:** The mod has been tested in-game and with one client on a dedicated server, including workshop retrofitting and course/vehicle upgrade persistence across a server restart. Simultaneous two-player multiplayer and player-hosted sessions have not yet been fully verified. Back up your savegame before testing and remove older TerraLine versions from your mods folder.

**Not included:** Tramline management, field-edge tramlines and section control. These features are planned for a separate add-on.

**Bug reports / feedback:** patchpunk@mail.de. Please include your game and mod versions, steps to reproduce the problem and, if possible, your client/server log.

**Free PC mod by PatchPunk. Mod for Farming Simulator 25. Not an official GIANTS Software product.**

## Ingame-Abnahme vor der Veröffentlichung

**Quelle:** FS25_TerraLineGPS_v0_9_9_60_beta_bilingual_contact_candidate.zip  
**Wichtig:** Die folgenden Prüfungen sind ein Testplan, **keine bereits bestätigten Ergebnisse**.

1. Bestehenden Spielstand sichern. Auf Client und Dedicated Server alle älteren TerraLine-Versionen entfernen; nur dieselbe v0.9.9.60-ZIP aktivieren. Wegen bekannter Fremdmod-Warnungen idealerweise mit möglichst wenigen zusätzlichen Mods testen.
2. Spiel starten und Log auf `Error`, `TerraLine`, fehlende Dateien und Inkompatibilitäten prüfen.
3. Fahrzeug **ohne** TerraLine-Ausstattung testen: keine GPS-Plakette, kein TerraLine-Menüzugriff.
4. Fahrzeug mit TerraLine-Ausstattung kaufen oder ausrüsten: +10.000 € Aufpreis prüfen; Plakette sollte auf AUS stehen. `Alt+T` schaltet das Gerät ein.
5. Auf einem Feld die Punkte A und B mit mindestens 20 m Abstand setzen, `Alt+X` aktiviert die Spurführung. Geradeausfahrt und korrekte Lenkung bei moderater Geschwindigkeit prüfen; anschließend deaktivieren. Sicherheitshalber nicht in der Nähe von Hindernissen testen.
6. Benannten GPS-Kurs speichern, laden und löschen. Ausstattung eines weiteren Fahrzeugs per Werkstatt ändern und prüfen, dass nur das umgerüstete Fahrzeug betroffen ist.
7. Spielstand speichern und Dedicated Server neu starten. Ausstattung und gespeicherte Hofkurse erneut prüfen.
8. Neue Client- und Server-Logs sichern. Bei auffälligen Fehlern **nicht veröffentlichen**, sondern korrigieren und den neuen Build erneut testen.

**Weiterhin offene Beta-Limitationen:** Simultaner 2-Spieler-MP-Test, eigener Hosted-MP-Test, breitere Fahrzeugkompatibilität und vollständige Singleplayer-Regression.

## Bildplan: echte LS25-Screenshots von v0.9.9.60

- `01_TerraLine_A_B_Feld.jpg` – Titelbild mit fahrendem Traktor auf dem Feld und gut sichtbaren GPS-Führungslinien. Möglichst keine offenen Menüs.
- `02_TerraLine_Fahrzeugshop.jpg` – Native Fahrzeugshop-Konfiguration „Mit TerraLine GPS“ mit +10.000 €.
- `03_TerraLine_Tacho.jpg` – Kompaktes Status-Badge neben dem LS25-Tacho, z. B. „BEREIT“ bzw. „AUTO AKTIV“.
- `04_TerraLine_Menue.jpg` – TerraLine-Einstellmenü mit erkennbaren GPS-Funktionen.

Bilder unverändert im Spiel aufnehmen (keine KI-generierten Spielszenen). Falls das Portal ein Format vorschreibt, erst nach Sichtung der tatsächlichen Portalvorgaben zuschneiden oder skalieren. Die in diesem Dokument genannten Motive sind **unsere Empfehlung**, keine nachgewiesene Pflicht von Forbidden Mods.

## Veröffentlichungs-Gate

- [x] Autor und Kontaktadresse: PatchPunk / patchpunk@mail.de
- [x] Grafiken und Sounds: laut Projektinhaber selbst beziehungsweise im Projekt erstellt, keine Übernahme aus Drittmods
- [x] Deutsche und englische README + Projekt-Notice
- [x] Gefährlicher Konsolen-Lenktest in v0.9.9.60 deaktiviert (statischer Test)
- [x] ZIP-Struktur / CRC des Kandidaten geprüft
- [ ] **Echter Ingame-Test des aktuellen Kandidaten v0.9.9.60**
- [ ] Aktuelle Client- und Server-Logs kontrollieren
- [ ] Echte Bilder aus dem aktuellen Build erhalten
- [ ] Upload-Vorgaben im eingeloggenen Forbidden-Mods-Portal prüfen
- [ ] Finale Freigabe und eigentlicher Upload durch PatchPunk

**Kein Release ohne finale Ingame-Abnahme. Keine Veröffentlichung ist bislang erfolgt.**