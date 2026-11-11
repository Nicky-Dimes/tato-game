# Changelog

## 0.4.0 merged — 2026-11-11 (branch `handoff-v4`, then `main`)

ChatGPT's v0.4.0 gameplay revision (their commit `7e46497`) brought in as received and
checked on macOS with Godot 4.7.2: 132 files load, art validator passes, 47 of 47 tests
pass, six worlds and two boss arenas captured from the real game window with no errors,
web / macOS / Windows / Linux exports rebuilt, exported macOS app launched and ran a stage.

- From ChatGPT: higher jump (about 4.6 tiles held), longer coyote time and jump buffer,
  wider bounce pads, optional platform routes and many more creatures in all 24 non-boss
  stages, forward-guided bubbles, shader colour fix for fading run cels, painted props
  and attack effect frames, cream HUD, fixed 16:9 framing.
- Kept on top: the macOS fix in `tools/check.sh` (their copy still had the bash 3.2 bug).
- Their notes: `docs/handoff_v4/`.

## 0.2.0 — 2026-11-10

- Overhaul v1 merged into `main`.
- Hits feel solid: a blink of hit-pause, a small shake, sparks and a ring on every hit;
  defeated creatures are knocked up and away spinning. Bosses shake and pause on hits.
  Hit-pause and spin are off with Reduced Motion.
- Creatures more than about a screen and a half away rest until Tato comes near
  (less work for older phones and tablets).
- One more checkpoint bell in every non-boss stage (main stages now have three, bonus
  stages two). Candy treat added to the one stage that lacked it.
- macOS, Windows and Linux exports now build (`tools/build.sh all`); the macOS app was
  launched and ran a stage. Windows and Linux files were built but not run.
- README screenshots.

## 0.3.0 merged — 2026-11-11 (branch `handoff-v3`, then `main`)

ChatGPT's corrected handoff v0.3.0 (their commit `f3a89ae`) brought in as received and
checked on macOS with Godot 4.7.2: clean import, 128 files load, art validator passes
(28 characters, 236 cels), 43 of 43 tests pass, six worlds and two boss arenas captured
from the real game window with no errors, and web, macOS, Windows and Linux exports
build. The exported macOS app was launched and ran a stage.

- One fix on top: `tools/check.sh` stopped with "args[@]: unbound variable" under the
  bash 3.2 that macOS ships.
- An earlier, superseded package (Sunny Meadows pass 5) was not merged.
- Their notes are in `docs/handoff_v3/`. Open scope is listed in
  `docs/handoff_v3/CORRECTION_PASS_REPORT.md` and `README_START_HERE.md`.

## Overhaul v1 merged — 2026-11-10 (branch `overhaul-v1`)

ChatGPT's `TATO_PRODUCTION_OVERHAUL_V1.zip` brought in as received, then checked in Godot
(ChatGPT could not run it): clean import, 122 files load, 39 of 39 tests pass, all six
worlds captured on screen.

- From ChatGPT: 34 more Tato frames with idle, jump, fall, land, attack, pickup and hurt
  animations wired; 4 motion frames for every creature and boss; PNG backgrounds and tile
  atlases for the six worlds; HUD backplates; richer fire shot and effects.
- Fixed after the merge: the new background layers did not repeat cleanly (trees cut in
  half at each repeat). They are now doubled with a mirrored copy at load time.
- Added: `--shot=` debug option that saves real game screenshots from the desktop build.
- ChatGPT's own note stands: the new frames are derived from the existing drawings, not
  newly drawn animation, and the backgrounds are not yet the painted target.

## Handoff snapshot — 2026-11-10 (tag `handoff-2026-11-10`)

Development paused for an external art / animation / gameplay overhaul. Added the four
handoff documents at the top of the project and `game/assets/sprites/override/`.
No game features changed after the last 0.1.0 work listed below.

## 0.1.0 — 2026-11-10

First build.

- Godot 4.7.2 project: Compatibility renderer, 1280x720 design size, landscape, web + desktop presets
- Tato: walk, run, jump (coyote time, jump buffer, variable height), flap x3, glide, belly slide, swim, honk
- Redesign to the owner's five boards: one active attack power, five hearts, three buttons
- 12 attack power-ups and 66 Flavor Bursts; 18 creatures + 3 slime variants; 6 bosses
- 30 stages in six worlds, Home Nest, Snack Trial Room, world map, storybook, credits
- Coins, Treasure Notes, Stars, keys, Question Blocks, crates, 20 level pickups, wardrobe
- All character / creature / item / boss art cut from the owner's boards
- Generated terrain tiles, parallax backgrounds, sound effects and music
- Three save slots with backup and migration; settings; remappable controls; touch controls
- Automated tests (unit, integration, robot playthrough) and CI workflows
