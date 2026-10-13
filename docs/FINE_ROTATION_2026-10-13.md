# TerraLineGPS – Feinrotation & Bedienhinweise (13.10.2026)

**Status:** ungetesteter LS25-Testbuild, kein neuer FBM-Release. Modversion bleibt 0.9.9.60.

## Code in diesem Commit

- `scripts/GPSCourseManager.lua`: `rotateStep(deltaDegrees)` benutzt die existierende bewährte Winkeleingabe; Drehpunkt A bleibt fest. Stop/Reset vor der Drehung; Veränderung nur bei max. 2 km/h.
- `scripts/GPSMenuPage1.lua`: Direkte Feindrehung im Spurführungsmenü, +/- und Schrittweiten 0.1/0.5/1/5 Grad.
- `scripts/GPSMenuPage3.lua`: Direkte Feindrehung bei gespeicherten Kursen; bestehende Winkel-Eingabe und 90-Grad-Aktion bleiben.
- `scripts/GPSMenuPage4.lua`: Bedienhinweise korrigiert, Drittanbieter-Vergleich und Addon-Text entfernt. Nur tatsächlich vorhandene Funktionen und Grenzen dargestellt.
- **Steuerungsregelung, Spurfang, 30-km/h-Grenze und 3D-Linien-Renderer: unverändert.**

## Neues Standard-Mod-Icon

Der Nutzer hat das DDS-Icon `icon_terraline1.dds` verbindlich als TerraLineGPS-Standard festgelegt.
Die **vollständige lokale ZIP enthält diese Datei bereits exakt** als `icon_terraline.dds`, 512x512 DXT1.
SHA-256 der Icon-Datei: `9da09ce24e12a2a44b4b92640fef4b1011f0e4001dbf2c0955bff3df36ad2f49`.

## Teststand

- 27 Lua-Dateien syntaktisch geprüft mit LuaTeX-Lua;
- Feindrehung mit simuliertem Motor/GPS: Winkel +/-, Drehrichtungen, 360-Grad-Umsprung, stationäre Sperre, A-Pivot, Reset OK;
- XML gültig, komplettes installierbares ZIP enthält 45 Dateien, CRC OK;
- GIANTS-LS25-Spieltest der neuen Menübedienung und Lenkgeometrie steht noch aus.

**Vollständiges Testpaket:** `FS25_TerraLineGPS_Beta.zip`
SHA-256: `549b5208752ffa23f6f6917d9ef1355de26e56b4546a2df5b4360bd9ce815de7`.

## Wichtiger GitHub-Abgleich

Der Commit bewahrt die neu geschriebenen Drehfunktionen und die Bedienung in den vier Lua-Dateien. Die Repository-Fassung von `GPSMenuPage1.lua` ist **nicht bytegleich** mit dem letzten vollständig getesteten ZIP (bisherige unsynchronisierte Darstellungsänderungen). Auch das **neue binäre DDS-Icon und andere ältere 3D-Ribbon-Assets sind derzeit noch nicht nach GitHub hochgeladen**. Die lokale ZIP ist die verbindliche vollständige Quelle dieses Testbuilds. Daher **nicht direkt aus diesem GitHub-Branch ein vollständiges Release bauen**. Vor öffentlicher Freigabe die verbleibenden Ressourcen synchronisieren und vergleichen.
