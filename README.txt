TerraLine GPS v0.9.9.58 — PC / Multiplayer-Entwicklungstest

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

MP TESTBUILD 0.9.9.47 (nach Dedicated-Neustart-/Hof-Feedback)
- Hofbezogener GPS-Hauptschalter: jeder Hof hat einen getrennten lokalen AN/AUS-Zustand. Beim allerersten Betreten eines Hofs AUS. Hofwechsel beeinflusst andere Hoefe nicht.
- Server-Schreibhook FSBaseMission.saveSavegame: nach regulaerem Spielstand-Save wird terralineGPS.xml aus dem Serverspeicher neu geschrieben, damit das Spiel die eigene XML nicht dauerhaft entfernt.
- Server-Logs melden SERVER-LOAD, SERVER-SAVE-HOOK installiert und SERVER-SAVE-HOOK mit Dateipfad und Anzahl Kurse; auf Host/Dedicated vergleichen.
- ACHTUNG: Die schon verlorenen Kurse aus frueheren Versionen werden nicht automatisch zurueckgewonnen; vorhandene Server-Spielstanddateien sichern.
- Kauf-/Werkstatt-Option +10.000 Euro ist separat geplant, hier NICHT eingebaut.

MP TESTBUILD 0.9.9.48 (Kursliste nach Hofwechsel)
- Client merkt sich pro Hof nur die zuletzt VOM SERVER bestaetigten Kurse.
- Beim Hofwechsel werden A/B und Lenkung weiterhin zurueckgesetzt. Die passende Hofliste erscheint sofort aus dem Cache.
- Parallel dazu wird eine neue Server-Kursliste angefordert. Serverantwort hat Vorrang, auch bei geloeschten Kursen.
- Verspaetete Antworten anderer Hoefe werden ignoriert. Server-/Client-Logs zeigen REQUEST/SNAPSHOT-Abgleich.
- Versionsanzeige aller drei Menue-Seiten nutzt zentral GPSConfig.version statt einer fest codierten alten Version.
- Hofgetrenntes GPS AN/AUS aus 0.9.9.47 unveraendert. Kein Server-Neustart-Test in diesem Build nachgewiesen.

Version 0.9.9.52: Korrigiert MP-Kursabfrage (REQUEST ohne Payload), stabilisiert Kurs-Speicherpfad bei tempsavegame und testet clientseitige Lenkeingabe via Drivable.axisSide. MP-Lenkung experimentell, noch nicht im LS25 bestaetigt.

Version 0.9.9.52: MP GPS lenkt sanfter (bis 18 km/h, max 0.075) und schreibt Hofkurse beim regulaeren GIANTS ItemSystem.save nach tempsavegame. Bitte auf Dedicated Server mit Savegame-Backup pruefen.

Version 0.9.9.52: MP-Lenkung verwendet einen Vorhaltepunkt auf der A/B-Linie und die regulaere Fahrzeug-Lenkeingabe (setSteeringInput), damit Drivable die echte Rad-/Lenkradbewegung berechnet und im MP uebertraegt. Signkonvention fuer Richtung korrigiert; 18-km/h-Schutz und bestehende SP-Regelung bleiben. Server-Kursspeicherung aus v0.9.9.50 unveraendert. Noch nicht ingame getestet.


v0.9.9.52 - experimenteller MP-Lenkrichtungstest:
- MP: Vorzeichen des normalen Drivable-Lenkeingangs umgekehrt, nachdem v51
  laut Fahrtest von der A/B-Linie weglenkte. Lenkberechnung unveraendert.
- Neue Client-Logzeile: GPS-LENK MP INPUT: offset / logisch / an Drivable.
- Test ausschliesslich bei niedriger Geschwindigkeit auf freiem Feld.
- Kurs-Speicherung (serverseitig) unveraendert wie v0.9.9.50/v51.
- Keine MP-Freigabe vor einem erfolgreichen echten Fahrtest.


v0.9.9.57 - MP 30 km/h + ruhiges Konsolenprotokoll:
- MP-Spurhaltung ist bis 30 km/h aktivierbar und schaltet oberhalb von 30 km/h ab; Richtungsregelung aus v0.9.9.52 bleibt unveraendert.
- Laufende Messwerte (Lenkwert, Trend, Spurabweichung, Geraetespur, wiederholte Kurs-Polls) sind standardmaessig stumm.
- Bei GPSConfig.showDiagnostics=true erscheinen diese Meldungen als [TerraLine GPS] DIAG ...
- GPS EIN/AUS, Sicherheitsstopps, Save/Load und Fehler bleiben im normalen Log.
- Neuer Log-Praefix [TerraLine GPS] statt [GPSFieldTest].
- Server-Kursspeicherung und Sync unveraendert.


v0.9.9.57 - Entwicklerdiagnose per Menue schaltbar:
- Im bereits vorhandenen Entwicklermenue sind die beiden Options-Tasten jetzt DIAG EIN und DIAG AUS.
- Diagnose startet standardmaessig AUS; Freischalten des Entwicklermenues aendert dies nicht.
- Im laufenden Spiel kann der Entwickler die detaillierten Logger-Messwerte lokal umschalten.
- Kurs-Speicherung, 30-km/h-Grenze und bestaetigte MP-Lenkrichtung bleiben unveraendert.


## 0.9.9.57 (EXPERIMENTELL)
Fahrzeug-Konfiguration TerraLine GPS im nativen LS25-Shop: Ohne (0 EUR, Standard), Mit (+10.000 EUR). Mit dem Fahrzeug gespeicherte Ausstattung, ueber die originale Werkstatt-Konfiguration nachruestbar. Bei alten Fahrzeugen standardmaessig nicht eingebaut. Nur mit GPS-Ausstattung Aktivierung moeglich. Native Tacho-Anzeige: TL GPS AUS (grau), TL GPS BEREIT (gruen), TL AUTO AKTIV (gruen). GPS startet pro Fahrzeug AUS. Keine neue Shopseite. 


v0.9.9.57 - Kritischer Shop-Hotfix:
- Verwechslung von manager und superFunc in Utils.overwrittenFunction behoben.
- Der originale GIANTS-Fahrzeugloader wird korrekt weitergereicht.
- Die TerraLine-Zusatzkonfiguration deaktiviert sich bei eigenem Fehler einmalig ohne Log-Flut.
- Die funktionierende 30-km/h-Lenkung, Kurs-Persistenz und Tacho-Darstellung sind unveraendert.
- Test im LS25 Shop / Dedicated erforderlich.


v0.9.9.57 - Natives Shop-GPS und Tacho (Hotfix):
- Kein TerraLine-GPS-Menue mehr, wenn das kontrollierte Fahrzeug keine gekaufte Ausstattung besitzt; Alle Zugriffswege gesperrt.
- In Fahrzeugen mit TerraLine GPS bleibt das Menue auch bei Hauptschalter AUS erreichbar.
- Tachoanzeige repariert: FS25 benutzt speedBg (nicht gaugeBackgroundElement wie FS22).
- Status: TL GPS AUS / TL GPS BEREIT / TL AUTO AKTIV; ohne Ausstattung keine Anzeige.
- Shop-XML-Pruefung ignoriert Gebaeude- und andere Nichtfahrzeug-Kategorien vor dem Zugriff auf vehicle XML-Felder.
- Lenkung, Kurs-Speicherung, MP-Kommunikation und 30-km/h-Grenze unveraendert.
- Test: V57 muss auf Client und Server installiert sein; Shop und Tacho real pruefen.


v0.9.9.58 - Kompakte Tachoplakette (freigegebener Entwurf):
- Kleiner dunkler TL-GPS-Status LINKS neben dem runden Geschwindigkeitstacho.
- Kein Text mehr ueber Weizen-/Fuellstandsanzeige oder Tacho!
- Original GIANTS GPS-Symbol, Status AUS (grau), BEREIT (gruen), AUTO AKTIV (gruen).
- Native HUD-Skalierung bestimmt Position und Masse; ohne Ausruestung unsichtbar.
- Shop, 10000-EUR-Konfiguration, Menuesperre, GPS-Lenkung und Farmkurse unveraendert.
- Lokale Lua-/HUD-Tests bestanden; LS25-Ingame-Darstellung noch pruefen.


v0.9.9.59 - Dezente Transparenz der seitlichen Tachoplakette:
- Auf Nutzertest basierende, genehmigte Position LINKS neben dem Geschwindigkeitstacho bleibt exakt unveraendert.
- Dunkler Hintergrund jetzt mit gleichmaessig leichter Transparenz (Alpha 0.78).
- Drei Rechteckstreifen ohne gegenseitige Ueberlappung statt doppelter Alpha-Ueberlagerung in der Mitte.
- GPS-Symbol, Statusfarben, Text, 10000-Euro-Shopkonfiguration und restlicher GPS-Code unveraendert.
- Nach LS25-Update auf Client/Server pruefen.
