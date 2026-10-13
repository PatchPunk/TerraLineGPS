# TerraLineGPS – A/B course rollback + tractor-center fine rotation (2026-10-13)

**Experimental TESTBUILD, not published on FBM. ModDesc version remains 0.9.9.60.**

The user rejected the immediately prior one-point pivot experiment. This branch intentionally starts at `feature/keyboard-course-rotation-20261013`, NOT at the discarded `feature/one-point-forward-course-20261013`. Traditional **Alt+B, Alt+B** course creation, >=20m spacing and previously saved A/B courses are retained.

**Actual functions in the complete test ZIP**:
- **Right Alt + W** toggles the fine angle mode. **Alt+J / Alt+N** rotate clockwise/counterclockwise by 0.1 degree per keypress; holding progressively accelerates like the existing lateral shift input. When the mode is OFF, J/N do not rotate.
- Both A and B rotate mathematically around the CURRENT VEHICLE CENTER, instead of point A. This applies consistently to line rendering, lane selection and steering reference. Speed must be <=2 km/h. The angle mode exits on acceleration, current tractor change, A/B reset, menu opening or GPS power-off.
- The red/green center and two yellow width edges are displayed 40m ahead AND 40m behind the projected tractor position (display-only).
- Existing core steering controller (30km/h hard cutoff), line graphics/materials, user-provided DDS icon, 90-degree key, original numerical angle editor, A/B save format, and HUD are unchanged.
- Updated page 4 and DE/EN README in the complete ZIP.

**Validated locally:** 27 Lua files syntax-load correctly; XML parses; ZIP has 45 CRC-clean entries. Mock tests pass for fixed tractor center, +0.1/-0.1 reversible geometry, rejection above 2km/h, rejection without A/B, mode key fallback and debouncing, and red/yellow 40m+40m renderer. **Actual LS25 game and Multiplayer tests pending.**

Complete test ZIP SHA-256:
`ca231186425cd10d2de6b8b7a57ece4f9c720a2415487c5b284e4c9bbc35157f`
File: `FS25_TerraLineGPS_Beta.zip`.

**Important repository caveat:** Five affected scripts/XML in this branch are saved, but this GitHub branch remains NOT an exact source mirror of the installable ZIP. Some older versions of GPSFieldTest.lua, TrackRenderer.lua and other graphics assets are already different in GitHub versus the latest user-tested full ZIP. The icon DDS, latest ribbon mesh resources, updated bilingual readmes and local CHANGELOG are also not fully synchronized. The complete local ZIP is the source of truth. Do NOT build a public release from this branch without reconciling every asset/file.
