# Interne Projektmarkierung und Integrität

In zwei Lua-Dateien steht dieser rein dokumentarische Kommentar:

```lua
-- TerraLine GPS | Interne Projektmarke: Hallo hier bin ich, der CODE! | TL-GPS/2026-10-12
```

Er erzeugt keine Laufzeitausgabe und ändert das Programmverhalten nicht.

Integrität kann auf Windows z. B. mit `certutil -hashfile DATEI.zip SHA256`
geprüft werden. Nach jedem neuen Build ändert sich sein Hash bei Änderungen
an den enthaltenen Dateien. Datei-Hashes sind kein Kopierschutz.

Versionsmarken lassen sich nach dem ersten Push mit Git-Tags dokumentieren:

```bash
git tag v0.9.9.44
git push origin v0.9.9.44
```

**Nur nach bestätigtem privaten Push taggen.** Keine personenbezogenen Daten
oder vertraulichen Token in Git-Kommentaren hinterlassen.
