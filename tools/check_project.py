#!/usr/bin/env python3
"""Static project check; not a substitute for LS25 or GIANTS TestRunner."""
from pathlib import Path
from xml.etree import ElementTree as ET
import struct

root = Path(__file__).resolve().parents[1]
xml = ET.parse(root / "modDesc.xml").getroot()
assert xml.attrib.get("descVersion") == "114"
assert (xml.findtext("version") or "").strip()
icon_name = (xml.findtext("iconFilename") or "").strip()
assert (root / icon_name).is_file()
for el in xml.findall("extraSourceFiles/sourceFile"):
    assert (root / el.attrib["filename"]).is_file(), el.attrib["filename"]
for f in (root / "gui").rglob("*.dds"):
    assert f.read_bytes()[:4] == b"DDS ", f
for f in (root / "sounds").rglob("*.wav"):
    assert f.read_bytes()[:4] == b"RIFF", f
assert (root / "icon_terraline.dds").read_bytes()[:4] == b"DDS "
assert "Hallo hier bin ich, der CODE!" in (root / "scripts/Config.lua").read_text(encoding="utf-8")
print("Static structure, XML, DDS/WAV signatures and code marker: OK")
