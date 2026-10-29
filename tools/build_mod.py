#!/usr/bin/env python3
"""Build the TerraLineGPS game ZIP from this repository's release sources."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parents[1]
GAME_FILES=['modDesc.xml','README.txt','README_EN.txt','CHANGELOG.txt','icon_terraline.dds']
for sub in ['assets','gui','scripts']:
    GAME_FILES += [p.relative_to(ROOT).as_posix() for p in (ROOT/sub).rglob('*') if p.is_file()]
for name in GAME_FILES:
    if not (ROOT/name).is_file(): raise SystemExit('MISSING: '+name)
ET.parse(ROOT/'modDesc.xml')
out=ROOT/'dist'/'FS25_TerraLineGPS.zip'
out.parent.mkdir(exist_ok=True)
with ZipFile(out,'w',ZIP_DEFLATED,compresslevel=9) as z:
    for name in GAME_FILES: z.write(ROOT/name,name)
with ZipFile(out) as z: assert z.testzip() is None
print(out, 'files=',len(GAME_FILES))
