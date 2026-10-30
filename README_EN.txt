TERRALINE GPS - VERSION 1.0.0.0 - PRE-RELEASE / FBM + GITHUB
Farming Simulator 25 (PC) | Author: PatchPunk
Contact: patchpunk@mail.de | Updated: 2026-10-29

TESTING / PUBLICATION STATUS
- Pre-release for Forbidden Mods (FBM); author upload required.
- GIANTS TestRunner on Phase 18 (2026-10-29): 15/15 PASS, no Lua warnings.
  MP implement detection/offset assistance has since been changed and has
  NOT yet been verified by an in-game MP test.
- Singleplayer developer-tested: A/B, steering, NewGUI, mower width/offset.
- Dedicated server with one client: server course messages, steering,
  farm change and list requests observed in real game logs.
- Developer-confirmed: course loads after server restart; permanent deletion
  of a course persists across a restart.
- NOT CONFIRMED: two simultaneous players on the same farm or concurrent
  editing of the same shared course list.
- PC ONLY. Lua-based script mods cannot be console crossplay releases.

FEATURES
- Custom straight A/B guidance with automatic steering assistance.
- Three presses of Left Alt+B: arm and show three white preview lines;
  set A and start measuring; set B after a minimum of 20 m.
- Red/green guidance center line, yellow width guides, adjustable
  3D line height and thickness.
- Lateral lane shift, 90-degree rotation and fine angle in 0.1-degree steps.
- Selected front/rear/side mower combinations have measured working width
  and lateral offset; unsupported/uncertain layouts are safely rejected.
- Status at GIANTS speedometer and original base-game GPS sounds.
- Optional TerraLine GPS equipment on compatible vehicles (+EUR 10,000).
- Named, farm-specific courses: save, load, delete.

DEFAULT KEYBINDS (rebindable in game)
Left Alt+T        Power on/off
Left Alt+B        Arm / A / B (minimum 20 m)
Left Alt+X        Tap: steering on/off; hold ~3s: renumber lane 1
Left Alt+M        Settings menu
Left Alt+R        Rotate 90 degrees
Right Alt+W       Fine-angle mode (while stopped)
Left Alt+J / N    Angle +0.1 / -0.1 degrees in fine-angle mode
Left Alt+Page Up / Down   Shift course right / left

SAVEGAMES / MULTIPLAYER
IMPORTANT: After saving or deleting a course, ALSO SAVE THE FS25 GAME.
Course data are stored in terralineGPS.xml in the savegame directory.
Back up the savegame before updating. Remove all older TerraLine ZIPs;
server and clients must use the identical archive.
Automatic implement detection (including stabilized multi-mower width) and
implement-offset steering are now ENABLED for local MP drivers, but remain
EXPERIMENTAL and unverified with two simultaneous players.
Enable implement-auto while stopped with GPS steering OFF, in your own
tractor, and wait for a ready measurement. Uncertain geometries prevent
activation or cause safe disengagement. In MP engage steering only near
and aligned with the course. Steering
is limited to 30 km/h and has safety disengagements.
Straight A/B guidance only; no contour mode or tramline manager included.

BUG REPORTS: patchpunk@mail.de (game version, steps, log.txt).
Not an official GIANTS Software product.
