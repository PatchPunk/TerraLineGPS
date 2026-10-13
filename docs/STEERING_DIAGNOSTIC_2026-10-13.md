# TerraLineGPS steering diagnostics – 2026-10-13

**Status:** experimental test; no FBM release. Internal mod version remains 0.9.9.60.

This branch is based on `feature/mp-farm-courses` at commit `6220870795f904c6f71f95a1c63307efa79829e9`, whose `scripts/SteeringController.lua` exactly matched the reference ZIP (`ce639d8e64e2d8ed9576f41ce83aed5e9e5a023b`).

## Source change saved here

- `scripts/SteeringController.lua`: diagnostics only, logging activation rejections, chosen track, lateral deviation, heading error, speed, direction, raw steering and computed command at activation, start/stop and at bounded intervals.
- Existing steering math, speed limits, safety thresholds and assistance logic remain unchanged.

## Local complete test artifact

`FS25_TerraLineGPS_Beta.zip` (the complete 45-file steering-diagnostics testbuild, 2026-10-13).
SHA-256: `3a2c0780daec0359654b4291b8f495b858a3ea529081425afb15ecd4fd21481d`

**IMPORTANT – not a complete ZIP source mirror:** The prior 2026-10-13 3D ribbon / colored-mesh updates are present in the complete test ZIP, but **are not yet synchronized in this GitHub branch**. In particular `scripts/GPSLineVisuals.lua`, colored DDS assets, other changed renderer scripts and local `CHANGELOG.txt` must be reconciled before considering this GitHub branch a fully reproducible source tree. Do not build a release from this branch as-is.

## Testing

Offline Lua parser: 27 Lua scripts successful. Simulated controller: parking/pause, resume, manual takeover, 1.2 m offset guard, 20 degree heading guard, and activation rejection retain prior behavior. In-game steering test and dedicated multiplayer testing still outstanding.

## Addon scope

ProSeed integration, headland recognition and contour-parallel courses belong to a future **TerraLineGPS addon**, not this bug-fix build.
