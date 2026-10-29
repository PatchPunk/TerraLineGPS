# TerraLine GPS – Farming Simulator 25

**Version:** 1.0.0.0 · **Platform:** PC · **Author:** PatchPunk

TerraLine GPS extends Farming Simulator 25 with custom straight A/B
courses, parallel guidance, automatic steering assistance, configurable
3D guidance lines, optional in-shop GPS equipment, and per-farm course
management. The 2026-10-29 GIANTS TestRunner passed 15/15 checks without
Lua warnings on the unchanged Phase-18 script baseline.

**Testing status:** Singleplayer and one-client dedicated-server use were
tested. Saved courses load after a server restart and deletions persist,
confirmed by the developer. **Two simultaneous players are not yet validated.**
PC-only; no console crossplay. Automatic implement-offset steering is disabled
in multiplayer.

## Controls

| Shortcut (default) | Action |
| --- | --- |
| Left Alt+T | TerraLine power |
| Left Alt+B | 1: arm/white previews, 2: A, 3: B (after 20 m) |
| Left Alt+X | Toggle steering; hold approx. 3 seconds to renumber lane 1 |
| Left Alt+M | Open menu |
| Left Alt+R | Rotate lane 90 degrees |
| Right Alt+W | Fine-angle mode (stopped) |
| Left Alt+J / N | Adjust fine-angle by +0.1 / -0.1 degree |
| Left Alt+Page Up / Down | Shift course right / left |

## Saving courses

When you save or delete a course in the TerraLine menu, you **must also save
the FS25 savegame**. Courses are persisted in `terralineGPS.xml` in the
savegame. Always back up savegames before updating.

## Installation

Use `FS25_TerraLineGPS.zip` in the FS25 `mods` directory. Remove older
copies first. The dedicated server and every client need the identical ZIP.

## Building the ZIP from source

```bash
python tools/build_mod.py
python tools/check_project.py
```

The output is `dist/FS25_TerraLineGPS.zip`. This is a packaging/static
check, **not** a substitute for the GIANTS TestRunner or live game tests.

## Release channels and source

- Forbidden Mods: 1.0.0.0 PC pre-release, author upload required.
- GitHub: 1.0.0.0 source and installable ZIP, public release by the owner.
- GIANTS ModHub: **not planned for this release**.

**License / assets:** No open-source license is granted unless a separate
LICENSE file is explicitly added by the owner. Public availability of source
does not imply rights to redistribute, modify or republish. The origin and
rights of code, icon, GUI artwork, and sounds should be verified before a
public release.

Contact: **patchpunk@mail.de** · TerraLine GPS is not an official GIANTS mod.
