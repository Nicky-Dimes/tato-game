# TATO! — Handoff notes for ChatGPT (round two)

This is the real, current TATO! project (Godot 4.7.2, GDScript), version 0.2.0. It
already contains everything from your first pass (`TATO_PRODUCTION_OVERHAUL_V1`),
tested and merged, plus the work done since. Claude takes the project back afterwards.

The Godot project is the `game/` folder. Open `game/project.godot`.

**New this round: you can run it.** `GODOT_SETUP_FOR_CHATGPT.md` gives the exact engine
version, the official download, and one command (`tools/check.sh`) that imports the
project, loads every file and runs all 39 tests.

## 1. What happened to round one

Brought in unchanged, then run in Godot for the first time: clean import, every file
loads, 39 of 39 tests pass, all six worlds seen on screen. Nothing of yours was removed.

Kept and working:

- 34 Tato frames and the longer animation table (idle, jump, fall, land, attack,
  pickup, hurt), landing and attack states.
- Four motion frames per creature and boss with frame switching, bob, recoil, squash.
- PNG tile atlases, HUD backplates, the fire shot and effect changes.
- PNG parallax layers for the six worlds.

Fixed after the merge:

- **The parallax layers did not repeat.** Trees were cut in half and hills stepped at
  every repeat (left and right edges did not match). `backdrop.gd` now doubles any
  such layer with a mirrored copy. New layers should simply be seamless.

Honest assessment, agreeing with your own README:

- Tato's new frames are re-posed copies of the earlier drawings (rotated, squashed,
  reused), not new animation drawings.
- Creature and boss frames are the same picture slightly warped.
- The backgrounds use one tree shape recoloured for every world (pink in Candy, purple
  in Castle with plain box houses) and have stair-stepped edges when enlarged. They are
  not yet better than the generated layers they replaced.

Added by Claude since (version 0.2.0):

- Hit-pause, shake, sparks and a ring on every hit; defeated creatures fly off spinning.
- Creatures far from Tato rest until he comes near.
- One more checkpoint per stage; web, macOS, Windows and Linux exports build.
- A screenshot option for the desktop build and `tools/check.sh`.

## 2. What is still missing (the owner's list, unchanged)

Read `UPDATED_GAMEPLAY_REQUIREMENTS.md`. In priority order:

1. **Tato drawn as real animation**: distinct key poses for idle, walk, run, jump,
   fall, land, attack and hurt, with consistent wing anatomy. He stays a fluffy white
   baby goose with big eyes, rosy cheeks, tiny wings and orange feet, with **exactly
   two wings and two legs in every frame**.
2. **Creatures and bosses drawn in more than one pose** (move, attack, hurt, defeat).
3. **Attack and projectile art.** Only the fire shot has been improved.
4. **Backgrounds**: distinct, layered scenery per world, seamless left to right.
5. **Tiles, platforms, props**: the small world pieces are 40–60 px in the source.
6. **Stage design**: built from repeating chunks; flat stretches; little surprise.
7. **Interface art** beyond the two HUD plates (buttons, panels, menus).

The approved art direction is the eight boards in `assets/reference/`. Screenshots of
the game as it looks now are in `docs/screenshots/` and `docs/art/overhaul_v1_*.png`.

## 3. Where things are

| What | File |
|---|---|
| Tato's animation table and drawing | `game/scripts/player/tato_visual.gd` |
| Tato's movement, attack, hurt | `game/scripts/player/tato.gd` |
| Creature numbers | `game/scripts/enemies/enemy_data.gd` |
| Creature behaviour, frame switching, hit feedback | `game/scripts/enemies/enemy.gd` (+ `walker.gd`, `flyer.gd`, `mole.gd`) |
| Bosses | `game/scripts/bosses/boss.gd` |
| Shots (drawn in code) | `game/scripts/components/projectile.gd`, `_draw()` |
| Bursts, sparkles, rings, floating text | `game/scripts/core/fx.gd` |
| The 12 powers | `game/scripts/food/abilities/*.gd`, numbers in `game/data/foods/*.tres` |
| Backgrounds (and the mirror fix) | `game/scripts/level/backdrop.gd` |
| Terrain drawing | `game/scripts/level/terrain.gd`; atlas layout in `tools/art/art_tiles.py` |
| Stage layouts | `tools/build_levels.py` → `game/data/levels/*.txt` |
| Interface | `game/scripts/ui/ui_theme.gd`, `hud.gd`, `touch_controls.gd` |

`PROJECT_ARCHITECTURE.md` explains how each system works and what is fragile.
`DEVELOPMENT_STATUS.md` says what is tested and what is not.

## 4. Art contracts (as the code works today)

### Tato — `game/assets/sprites/tato/*.png` (70 files)

- Loaded by file name from this folder. **192×192 px, transparent, facing right, feet
  at x = 96, y = 168** (`ANCHOR`, `SPRITE_SCALE = 0.76` in `tato_visual.gd`).
- For sharper art, 384×384 with feet at (192, 336) works if `ANCHOR` becomes
  `Vector2(192, 336)` and `SPRITE_SCALE` 0.38. Every frame must share one size.
- Animations are the `ANIMS` table: `"name": [[frame names], frames per second, loop]`.
  In use now: `idle` (idle_0..5), `walk` (walk_0..4 + walk_extra_0..2), `run`
  (run_0..4 + run_extra_0..2), `jump` (jump_start_0..2), `fall` (fall_0..2), `land`
  (land_0..3), `attack` and `honk` (attack_0..3), `eat` (pickup_0..3), `hurt`
  (hurt_0..3), plus glide, flap, crouch, slide, swim, cheer, roll.
- Redrawing a frame under its existing name needs no code change.

### Creatures — `game/assets/sprites/enemies/`

- Base picture `<kind>.png`; motion frames `anim/<kind>_0.png` … `_3.png`.
- `enemy.gd` cycles the four frames by time (faster while moving) and falls back to the
  base picture if a frame is missing. All frames of one creature must share one canvas
  size, feet on the bottom edge, centred.
- The game scales to the height `h` in `EnemyData.STATS`, so resolution is free. Aim
  for about twice the on-screen height (46–86 px on screen).
- `faces` in `EnemyData.STATS`: which way the picture looks (1 right, −1 left).
- There are no separate attack, hurt or defeat frames yet. If you draw them, name them
  `anim/<kind>_attack_0..n.png`, `anim/<kind>_hurt_0.png`, `anim/<kind>_defeat_0..n.png`
  and wire them in `enemy.gd`, or leave a note.

### Bosses — `game/assets/sprites/bosses/`

- Same scheme: `<id>.png` and `anim/<id>_0..3.png`. Sources are 124–145 px tall and are
  shown 170–215 px tall, so they are enlarged and soft. Aim for 400–512 px tall.

### Backgrounds — `game/assets/sprites/bg/<theme>_{clouds,far,mid}.png`

- Themes: `grassland, orchard, candy, icy, windy, castle` (and `nest`, still SVG).
- 1024 px wide today (clouds 280 tall, far 420, mid 380), transparent above the skyline.
- **Must repeat left to right with matching edges.** Wider (2048) is fine and reduces
  visible repetition.
- Sky colours: `SKIES` in `backdrop.gd`. One more layer is one more `_add_layer(...)`.

### Terrain atlases — `game/assets/tiles/tiles_<theme>.png`

- 512×960: 8 columns × 15 rows of 64 px sub-tiles; four sub-tiles make one 64 px cell.
  Layout is in the comment at the top of `tools/art/art_tiles.py`. `terrain.gd` uses
  the PNG when present and the SVG otherwise.

### HUD — `game/assets/sprites/ui/hud_left.png`, `hud_right.png`

- Stretched to fixed rectangles in `hud.gd`. Known issues: the right plate is much
  wider than its contents, and pop-up messages overlap its corner.

### Everything else

- Items, pickups, power icons, touch buttons, world pieces: same name at any
  resolution is a safe replacement (they are sized in code).
- `game/assets/sprites/override/<folder>_<name>.png` replaces any picture loaded
  through `Art.tex` without code changes. It does not apply to Tato's frames or the
  terrain atlases.
- Shots are drawn in code by `look` name: `fire, ice, bubble, honey, melon, kernel,
  tomato, arrow, bolt`. Picture-based shots would go in `game/assets/sprites/fx/`.

## 5. Decisions that must be preserved

- Godot 4.7.2, GDScript, Compatibility renderer, single-threaded web export.
- One active food power; a new pickup replaces it. Five hearts. Three buttons.
- No lives, no game over. Tato: two wings, two legs, always.
- Stages are text files built at run time; all damage goes through `Hit` /
  `take_hit(damage, info)`; pictures through `Art`; input through `Controls`;
  progress through `GameState`; saves through `SaveService` (new profile fields need a
  default in `new_profile()`).
- Reduced Motion must keep switching off spins, pauses and flashes you add.
- Nothing is published. No licence has been chosen.
- The tests should keep passing, or be changed on purpose with a note saying why.

## 6. Things that break the project if done casually

- Do not delete, rename or hand-write `.import` or `.uid` files. Do not rename or move
  existing files or folders, `class_name` classes, or autoloads.
- Do not re-run the generators unless you mean to overwrite their output:
  `tools/art/extract_tato.py`, `extract_sheets.py`, `make_art.py`,
  `tools/build_levels.py` (rewrites every stage file), `tools/audio/make_audio.mjs`.
  **`make_art.py` and the extract scripts would not touch your PNG backgrounds, tiles
  or `anim/` frames, but they do rewrite the base creature pictures and Tato's original
  frames.**
- Stage files are generated: change `tools/build_levels.py` and re-run it, or hand-edit
  a stage and say so. Each stage needs exactly three Treasure Notes, a start and a
  goal; non-boss stages also need one hidden Star, a checkpoint and a food bowl. A jump
  clears two tiles; three needs a flap.
- Keep it light for 2018–2019 iPhones and iPads (guidelines, not measured limits):
  Tato frames up to 384 px, creature frames about 256 px tall, bosses up to 512,
  background layers up to 2048×1024, no full-screen shaders or heavy particles.

## 7. What to send back

1. The whole project folder zipped, same structure, **without `game/.godot/`**.
2. `CHANGES_FROM_CHATGPT.md` at the top level: every file added or changed and why;
   new art with sizes and anchor points; anything left for Claude to wire; any change
   to gameplay rules, numbers or stages.
3. **The output of `tools/check.sh`**, pasted into that file. If Godot could not be
   run, say so plainly and say which script edits were therefore not executed.
4. Please do not reformat code you are not changing.

Today's artwork is preserved in this ZIP and in Claude's Git history at tag
`handoff-2-2026-11-10`, so replacing files in place is acceptable.
