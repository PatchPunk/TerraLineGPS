TerraLine GPS v0.9.9.46 — PC / Multiplayer-Entwicklungstest

A/B-GPS-Spurfuehrung mit gespeicherten Kursen, Lenkassistent, Spurversatz und individuell einstellbarer Linien-Optik.

Installation:
- ZIP direkt in den LS25-Modordner kopieren (nicht entpacken).
- Aeltere TerraLine-GPS-Versionen aus dem Modordner entfernen.
- Vor Tests ein Backup des Spielstands erstellen.

Tasten (im LS25-Einstellungsmenue aenderbar):
- Alt+B: A-/B-Punkt setzen; Mindestabstand 20 m
- Alt+T: Hauptschalter fuer TerraLine GPS ein/aus
- Alt+X: GPS-Lenkung ein/aus
- Alt+M: GPS-Menue
- Alt+R: Spur 90 Grad drehen
- Alt+Bildauf / Alt+Bildab: komplette Spur um 1 cm verschieben

Entwicklerdiagnose:
- Auf Menue-Seite 4 ueber das Schloss erreichbar.
- Feldnummer, Farmland, Koordinaten und Geraeteoffset koennen im Diagnosemenue abgefragt werden.
- Diagnose-Snapshot schreibt Werte nur auf ausdruecklichen Klick ins Log.
- OPTION 1 / OPTION 2 sind bewusst noch ohne Funktion.

Hinweise zur Veroeffentlichung:
- Nur PC; Multiplayer supported=true NUR fuer Entwicklungs- und Synchronisationstests. MP-Lenkung ist noch nicht freigegeben.
- Mod-Icon: icon_terraline.dds, 512 x 512, DXT1/BC1, 1 Mipmap-Stufe (keine generierten Mipmaps).
- Rechte an allen Code-, Bild- und Tonbestandteilen vor einer Veroeffentlichung pruefen.
- Offizieller GIANTS TestRunner und reale Ingame-Tests stehen noch aus.
- Keine Freigabe fuer die ModHub-Einreichung ohne diese Tests.

UI v0.9.9.43: freigegebene TerraLine-Pixelgrafiken fuer Kopfzeile, Spurfuehrung, Speicher und Info & Version. Handgezeichnetes Mod-Icon eingebunden.

UI v0.9.9.43: vier +/- Buttons zwischen den Trennern zentriert. Arbeitsbreiten-/Spurfuehrungsvorschau zeigt die freigegebenen Blueprint-Konturen von Traktor und Arbeitsgeraet. Keine Lenk- oder Kursberechnung geaendert.

NEU v0.9.9.43: TerraLine GPS Hauptschalter.
  Alt+T / LS25 frei belegbare Aktion / SYSTEM AN-AUS im Menue Seite Spurführung.
  AUS stoppt sofort die automatische Lenkung, blendet GPS-Linien und GPS-Tacho-Integration aus
  und pausiert automatische Hilfsberechnungen. A/B und gespeicherte Kurse bleiben erhalten.
  Beim erneuten Einschalten bleibt die GPS-Lenkung bewusst AUS, bis Alt+X gedrueckt wird.
  Der Hauptschalter startet nach dem Laden eines Spielstands standardmaessig AUS.
  Diagnose-Befehl gsGPSPower [on|off|toggle].

GitHub-/Projektstand v0.9.9.44: nur Kommentare zur internen Projektmarkierung
und Dokumentation ergaenzt. Keine geaenderte GPS-Funktion.

MP TESTBUILD 0.9.9.46
- Gemeinsame Hofkurse ueber Farm-ID; Server allein schreibt terralineGPS.xml.
- Clientes holen den Kursbestand beim Beitritt und alle rund 10 Sekunden ab.
- Auf Client-Seite werden Speicher-/Loeschanfragen an den Server gesendet.
- Bestehende v0.9.9.44 Singleplayer-Referenz bleibt unveraendert.
- Vor MP-Test Savegame sichern, alle Clients brauchen exakt dieselbe Mod-ZIP.
- GPS-Lenkung im Multiplayer NOCH NICHT produktionsreif.

MP TESTBUILD 0.9.9.46 (Korrektur nach MP-Tester-Feedback)
- TerraLine GPS startet AUS, bis Alt+T oder SYSTEM AUS/AN benutzt wird.
- Ein Hofwechsel entfernt sofort die lokale A/B-Linie, die aktive Kursanzeige und die aktive GPS-Lenkung, auch beim Host.
- Clients bekommen eine explizite Server-Bestaetigung oder Ablehnung beim Speichern/Loeschen.
- Ein Kursname wird nicht mehr vor der bestaetigten Speicherung als gespeichert dargestellt.
- Fremde Hofkurse koennen nicht ueber die lokale Kursverwaltung geladen werden.
- Shop-Aufpreis (10.000 Euro) ist fuer die folgende Entwicklungsstufe vorgesehen; NICHT in diesem Build aktiv.
