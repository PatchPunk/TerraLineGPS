# TerraLineGPS 0.9.10.0 — Freigabevorbereitung (13.10.2026)

**Status: vom Mod-Autor nach LS25-Singleplayer-Tests als neue Release-Fassung ausgewählt. Noch nicht extern hochgeladen/veröffentlicht.**

## Was neu ist
- Optimierte Spuraktivierung/Spurerfassung im Singleplayer (nur bis 12 km/h für die zusätzliche Einfangphase).
- **Klassisches A/B**: Alt+B setzt A, mindestens 20 m danach Alt+B setzt B.
- Weiße gestrichelte **25-m-Vorschau nach A**, ausschließlich bis B gesetzt ist. Anschließend rote/grüne Mittellinie und gelbe Arbeitsbreitengrenzen.
- Rote/grüne Mitte und gelbe Außengrenzen je **40 m vor/hinter** dem Traktor; Sichtbarkeit auch in der Innenkamera bestätigt.
- **Rechte Alt+W** Winkelmodus; **Alt+J / Alt+N** fein um die aktuelle Traktormitte drehen (je 0,1°, wiederholt schneller bei gehaltenen Tasten).
- Höhen- und Dickenverstellung farbiger 3D-Linien, aktualisierte Anleitung im Menü (Info-Seite 4).
- Stark reduzierte normale **log.txt**: eine Versionsstartmeldung, Warnungen, Fehler und sicherheitsbedingte Abschaltungen; Debug-Ausgabe nur bei aktivierter Diagnose.
- **30-km/h-Grenze bleibt ohne Toleranz**; Sicherheitsabschaltungen und Lenkeingriffserkennung bleiben erhalten.
- Bestehendes TerraLine-DDS-Icon beibehalten. Keine Aussagen über eine neue Multiplayerfreigabe.

## Fertiges installierbares Modpaket (lokaler Release-Kandidat)
Dateiname: `FS25_TerraLineGPS_Beta.zip`  
Version: `0.9.10.0`  
SHA-256: `0bc810dd0a98719ad2ac1464cc8d169e2ea99658a53c3f45681de187eca5ca74`  
Inhalt: 45 Dateien (27 Lua-Skripte). Syntax aller Lua-Skripte, XML-Struktur und ZIP-CRC offline geprüft. Logging funktional offline geprüft.

## GitHub-Status / WARNUNG
**Dieser Staging-Branch ist bewusst noch keine vollständige 1:1-Kopie der Release-ZIP.** Der alte `main` enthält ältere Source-/Icon-/Grafikstände. Es wäre irreführend und fehleranfällig, aus diesem Branch direkt einen Release zu erzeugen. Der Quellabgleich muss vollständig erfolgen, bevor GitHub als Veröffentlichungsquelle dient.

Das GitHub-Repository `PatchPunk/TerraLineGPS` ist zurzeit **private**. Über die aktuelle Connector-Schnittstelle ist keine Änderung der Repo-Sichtbarkeit und kein Hochladen eines GitHub-Release-Assets möglich. **Keine GitHub- oder FBM-Veröffentlichung durch diesen Commit.**

Damit **nur die neue Version öffentlich** wird, sind alte Branches/alte Commit-Historie eines bestehenden Repos als mögliche Sichtbarkeitsquelle zu beachten, bevor die Repo-Sichtbarkeit auf public gestellt wird.
