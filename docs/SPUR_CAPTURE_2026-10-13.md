# TerraLineGPS – experimentelle Spurerfassung (13.10.2026)

**Status:** experimenteller LS25-SP-Testbuild; bisher kein Spieltest, kein FBM-Release.
**Version:** 0.9.9.60 (unverändert)
**Basis:** letzter durch Nutzer geprüfter Spurführungs-Diagnosebuild.

## Änderung
- `scripts/SteeringController.lua`: beim Aktivieren geometrische Position/Ausrichtung und nächste Spur frisch bestimmen. Sicherheitsprüfung **vor** GPS-EIN.
- Für neue SP-Spurerfassung: maximal 12 km/h, maximal 25° Kursfehler, Seitenabstand maximal min(2,50 m, 48 % Arbeitsbreite); ansonsten verständliche Ablehnung.
- Kontrollierte Übergabe an bestehende Spurhaltung nach 800 ms mit höchstens 0,25 m Versatz und 5° Kursfehler.
- Während der Erfassung: manuelle Übernahme, Trend-Watchdog und Zeitlimit 18 s.
- Normale Spurhaltung: bisherige Regelparameter, 30 km/h, 1,20 m / 42%-Abstandsgrenze und 20°-Grenze **unverändert**.
- Multiplayer: keine experimentelle neue Spurerfassung; bestehende MP-Spurhaltung unverändert.
- Höhe, Dicke, Farben, Material und 60-m-GPS-Linien unverändert.
- Keine 30-km/h-Grenztoleranz in diesem Build.

## Nachweise
- 27 Lua-Dateien syntaktisch geprüft, XML validiert und 45-Dateien-ZIP auf CRC geprüft.
- Mocktests: Stillstand, Anfahren, Moduswechsel, Breiten 3 m und 9 m, Grenzablehnung, Handübernahme, 30-km/h-Schutz, Multiplayer-Schutz und Spur-Neuerfassung erfolgreich.
- **Noch nicht:** Funktion in echter GIANTS-Engine, Traktoren anderer Hersteller, Multiplayer-Fahrtest.

**Vollständiges lokal erzeugtes Installationspaket:**
`FS25_TerraLineGPS_Beta.zip`, SHA-256
`797cb554a34144362fb94f8c67b27d7b130eed8fcbc924c7d3182c2fc5d72f02`

**Wichtige Einschränkung GitHub:** Dieser Branch enthält den aktuellen `SteeringController.lua` sowie diese Entwicklungsnotiz. Die Grafikdateien des vollständigen ZIP-Testbuilds (farbige 3D-Bänder u. a.) sind *nicht vollständig* mit diesem GitHub-Branch abgeglichen. Den Branch bis dahin nicht für einen Komplettrelease-Build verwenden.
