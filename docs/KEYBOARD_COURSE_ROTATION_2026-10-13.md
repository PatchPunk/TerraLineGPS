# TerraLineGPS – Tastatur-Feindrehung (13.10.2026)

**Status:** Experimenteller Testbuild, kein neuer öffentlicher Release. Interne Modversion **0.9.9.60** bleibt unverändert.

## Benutzerwunsch / Umsetzung
- Kein neues Menü für die Feindrehung bestehender A/B-Kurse. Die zuvor ergänzten Feindrehungs-Knöpfe auf Seite 1 und 3 wurden entfernt.
- **Alt+J:** A/B-Kurs im Uhrzeigersinn in Richtung 90 Grad (+0,5 Grad pro Druck).
- **Alt+N:** gegen den Uhrzeigersinn in Richtung 270 Grad (-0,5 Grad pro Druck).
- Bei langem Tastendruck Wiederholung nach 380 ms und zunehmende Geschwindigkeit, analog zum manuellen Spurversatz.
- Beide Aktionen in `modDesc.xml` deklarierte und damit frei belegbare Tasten; Keyboard-Fallback verhindert fehlerhafte fehlende Events und Doppelbetätigung.
- Nur bereits bestehende A/B-Kurse, Drehung um A, nur bei Fahrtgeschwindigkeit maximal 2 km/h. Lenkung beim Ändern des Kurses AUS.
- Die bereits vorhandene numerische Winkeleingabe und Alt+R (90 Grad) bleiben erhalten.
- Infoseite 4 nennt die beiden Tasten; keine Hinweise auf Drittanbieter oder künftige Addon-Pläne.
- Steuerung, 30-km/h-Limit, GPS-Linien und das vom Nutzer festgelegte `icon_terraline.dds` bleiben unverändert.

## Prüfungen der vollständigen lokalen ZIP
- 45 Dateien vorhanden, 27 Lua-Dateien syntaktisch korrekt, XML valide, ZIP CRC fehlerfrei, keine zusätzlichen Dateien.
- Mock-Tests für Einzeldruck, Halten, Beschleunigen, Loslassen, Default-Tastatur-Fallback und Deduplizierung, 2-km/h-Sperre, fehlende A/B-Referenz, Menü-Sperre und festen Drehpunkt A.
- **LS25-Ingame-Test und Multiplayer-Tests noch ausstehend.**

Vollständiges installierbares Paket: `FS25_TerraLineGPS_Beta.zip`
SHA-256: `10a67d840060bf60c7e2dfc70a355dfd4740f7a70df9fcd57c364918dcd622a1`

## Repository-Synchronisierung – wichtig
Die 6 hier veränderten Lua/XML-Dateien wurden mit dem bestehenden GitHub-Quellstand synchronisiert, *nicht* durch ein vollständiges Auswechseln des ZIP-Quellbaums.
Vier resultierende Dateien (`modDesc.xml`, `GPSCourseManager.lua`, `GPSMenuPage3.lua`, `GPSMenuPage4.lua`) sind Git-Blob-SHA-identisch mit der aktuellen ZIP. Die älteren Repository-Varianten von `GPSFieldTest.lua` und `GPSMenuPage1.lua` enthalten weiterhin von der ZIP abweichende Bestandteile, obwohl der neue Hotkey-Code auch in diesen Varianten enthalten ist. Das neue binäre DDS-Icon und der zuletzt überarbeitete 3D-Liniencode sind weiter nicht vollständig in diesem Branch gespiegelt.

**Für alle Builds weiterhin die vollständige ZIP als Quellgrundlage verwenden; diesen GitHub-Branch nicht als vollständigen 1:1-Release-Stand behandeln.**
