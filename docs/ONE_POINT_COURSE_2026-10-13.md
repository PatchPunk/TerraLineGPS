# TerraLineGPS – One-Point A, forward-only guide (2026-10-13)

Status: experimental test; version remains **0.9.9.60**. No FBM release; no LS25 game or multiplayer verification yet.

New behavior: **Ctrl+Alt+Y** creates A at the tractor and an internal 30m forward B. Red center and yellow work-width guides are immediately available **ahead only**, up to 60m, not behind. Steering has a valid reference after the first button press. A stays the pivot for Alt+J and Alt+N (+/-0.5 degrees, accelerating on hold), Alt+R and the 180-degree direction action. Rotation while driving remains blocked beyond 2 km/h.

The input action is rebindable in the game. A fallback polls Ctrl+Alt+Y and is edge-triggered and debounced against native action events. Menu page 4 and README were updated. Saved farm courses retain the existing A/B XML format.

The complete installable user test ZIP is the **source of truth**:
`FS25_TerraLineGPS_Beta.zip`
SHA-256 `8df56a8a8b2a369b046315d2481312c6e1e339f24b14c67ed552012b22a2fcc6`, 45 entries.

The packaged files were CRC-checked, both XMLs parsed, all 27 Lua files passed syntax checking. Local Lua mock tests passed for first-click A, heading 0/90, A pivot, +/-0.5, >2km/h rejection, only forward red/yellow rendering, and Ctrl+Alt+Y fallback/deduplication.

No edits to the steering controller, 30 km/h hard speed limit, sound, GUI developer unlock, colored 3D line materials or the **user supplied** `icon_terraline.dds` in the ZIP.

**Repository sync limitation:** This commit saves the changed relevant source logic in this branch, but the GitHub tree is NOT byte-identical to the full ZIP. In particular the existing repository TrackRenderer and GPSFieldTest scripts contain older differences from the previous graphics and keyboard builds; the latest user-supplied binary icon and 3D mesh files also remain unsynced. Do not attempt a public release by directly exporting this branch. Reconcile the complete ZIP first.

Existing two-point courses still load as saved; their headings and coordinates are preserved.
