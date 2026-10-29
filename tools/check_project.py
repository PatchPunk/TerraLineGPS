#!/usr/bin/env python3
"""Static package validation (does not validate in-game behavior)."""
from pathlib import Path
from zipfile import ZipFile
import xml.etree.ElementTree as ET
from subprocess import run
ROOT=Path(__file__).resolve().parents[1]
zipfile=ROOT/'dist/FS25_TerraLineGPS.zip'
if not zipfile.exists(): raise SystemExit('Run python tools/build_mod.py first')
with ZipFile(zipfile) as z:
  assert z.testzip() is None
  assert 'modDesc.xml' in z.namelist()
  root=ET.fromstring(z.read('modDesc.xml'))
  assert root.findtext('version')=='1.0.0.0'
  for name in z.namelist():
    if name.endswith('.xml'): ET.fromstring(z.read(name))
  files=[n for n in z.namelist() if n.endswith('.lua')]
  assert len(files)==29,(len(files),'Lua files')
  print('PASS',len(z.namelist()),'files,',len(files),'Lua scripts, all XML valid')
print('For Lua syntax and GIANTS TestRunner, run your game/test environment.')
