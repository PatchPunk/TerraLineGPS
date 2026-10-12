# Nutzungsrechte und Dateiquellen – vor Weitergabe prüfen

**Status 12.10.2026: privat, Rechtekette nicht vollständig nachgewiesen.**

| Bestandteil | Speicherort | Kenntnisstand | Vor Veröffentlichung prüfen |
|---|---|---|---|
| Lua-Programmcode | `scripts/*.lua` | Gemeinsame TerraLine-GPS-Entwicklung, enthält Hinweise auf GIANTS-Schnittstellen und bestehende Konzepte | Ob fremder Code wortwörtlich übernommen wurde; Autor- und Lizenzhinweise ergänzen |
| Pixel-Menüicons | `gui/icons/*.dds` | Aus gemeinsam ausgewählten Entwürfen erstellt | Freigabe/Lizenz und ggf. KI-Grafikregeln der Zielplattform |
| Handgezeichnetes Mod-Icon | `icon_terraline.dds` | Aus im Projekt abgestimmtem Entwurf erstellt | Rechte und Zielplattform-Richtlinien |
| Traktor-/Gerätevorschauen | `gui/tractorTop.dds`, `gui/planterTop.dds` | Aus vorhandenen Vorschaugrafiken und Blueprint-Umsetzung abgeleitet | Ursprung und Nutzungsrecht der Ausgangsgrafiken |
| Audiodateien | `sounds/*.wav` | Quellen aus Projektstand nicht verifizierbar | Herkunft, Urheber, Lizenz, ggf. eigene Tonerzeugung dokumentieren |
| Basisspiel/GIANTS APIs | Nutzung im Lua-Code | Externe LS25-Laufzeitschnittstellen | EULA, Modding-Regeln und Kennzeichnung beachten |

**Keine Lizenzdatei mit offenen Nutzungsrechten beilegen, bis der Rechteinhaber
und die gewünschten Bedingungen ausdrücklich festgelegt sind.**
Ohne Lizenz wird nicht automatisch eine freie Weiterverwendung erlaubt.

Die Zeile „Hallo hier bin ich, der CODE!“ ist eine Projektmarkierung, kein
zuverlässiger Plagiatsschutz, keine Zugriffssperre und kein Beweis alleiniger
Urheberschaft. Dasselbe gilt für Hashwerte: Sie belegen Dateigleichheit,
nicht Ursprung oder Rechtsinhaberschaft.

**Hinweis zum Entwicklermenü:** Das Passwort ist im Lua-Quellcode enthalten.
Es ist eine versehentliche Bedienungssperre, kein Schutz vor Inspektion.
