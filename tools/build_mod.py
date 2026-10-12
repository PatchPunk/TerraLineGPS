#!/usr/bin/env python3
"""Create the LS25 gameplay ZIP from the GitHub source tree (stdlib only)."""
from pathlib import Path
from zipfile import ZipFile, ZipInfo, ZIP_DEFLATED
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]
moddesc = root / "modDesc.xml"
xml = ET.parse(moddesc).getroot()
version = (xml.findtext("version") or "").strip()
assert version, "Missing mod version"
required = {
    "modDesc.xml", "README.txt", "PROJECT_NOTICE.txt", "icon_terraline.dds",
    "gui/GPSMenu.xml",
}
required.update(f"scripts/{p.name}" for p in (root / "scripts").glob("*.lua"))
required.update(p.relative_to(root).as_posix() for d in ("gui", "sounds") for p in (root / d).rglob("*") if p.is_file())
# Verify that modDesc references each packaged script and no script is missing.
registered = {el.attrib["filename"] for el in xml.findall("extraSourceFiles/sourceFile")}
assert registered == {p for p in required if p.startswith("scripts/")}, "Lua source registrations differ"
for name in required:
    assert (root / name).is_file(), f"Missing runtime asset: {name}"
output = root / "dist" / ("FS25_TerraLineGPS_v" + version.replace(".", "_") + ".zip")
output.parent.mkdir(parents=True, exist_ok=True)
with ZipFile(output, "w", compression=ZIP_DEFLATED, compresslevel=9) as z:
    for name in sorted(required):
        info = ZipInfo(name, date_time=(2026, 10, 12, 0, 0, 0))
        info.compress_type = ZIP_DEFLATED
        info.external_attr = 0o644 << 16
        z.writestr(info, (root / name).read_bytes(), compress_type=ZIP_DEFLATED, compresslevel=9)
with ZipFile(output) as z:
    assert z.testzip() is None
print(output)
