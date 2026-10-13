# TerraLineGPS – Page 4 operating guide (2026-10-13)

- **Experimental test build** of TerraLineGPS, version **0.9.9.60**, NOT released to FBM.
- Only the **in-game page 4** at `scripts/GPSMenuPage4.lua` and local ZIP `CHANGELOG.txt` have changed.
- Left panel keeps the existing control/keybind quick guide, page navigation and developer lock.
- Right panel now explicitly describes straight A/B GPS guidance, parallel lanes, steering in either direction, saved farm courses, visual appearance controls, lateral shifting, and native tachometer GPS status.
- It also states current limits: **30 km/h hard steering cutoff without a tolerance**, experimental SP-only lane acquisition **up to 12 km/h**, excessive steering offset/direction causing GPS to switch off, and manual steering takeover.
- **No contour courses, headland recognition, or ProSeed compatibility** are implemented. All three are planned as a **future add-on**, not in this beta.
- Steering, farm save/load, native GIANTS interaction and multiplayer logic unchanged.
- All **27 Lua files** parse, both XML files are well-formed, complete 45-entry ZIP CRC passes, 43/45 entries identical to last tested build.
- **Awaiting LS25 interface visual test** (menu text fit and readability). No new published release.
- Installable 45-file ZIP SHA-256: `b152c14eafbe74319e843115d9e310cb2160b0246f6299c2cae92b718993d569`.

## Repository synchronization caveat

The latest in-game page 4 Lua is exactly committed here. The GitHub branch is still **not a complete representation of the current test ZIP**: previously developed 3D GPS ribbon assets and renderer/controller companion sources remain out-of-sync. Do NOT build or publish a full release directly from this branch yet.
