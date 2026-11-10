# TATO! — Handoff notes for ChatGPT

You are receiving the real, current TATO! project (Godot 4.7.2, GDScript) for an art,
animation, gameplay and quality overhaul. Claude will take the project back afterwards,
merge your work and finish the game. These notes are meant to make your changes drop in
cleanly.

The Godot project is the `game/` folder. Open `game/project.godot`.

## 1. Read these first, in this order

1. `UPDATED_GAMEPLAY_REQUIREMENTS.md` — what the game must be.
2. `DEVELOPMENT_STATUS.md` — what exists, what is weak, what is untested.
3. `PROJECT_ARCHITECTURE.md` — how the code is organised and what is fragile.
4. `assets/reference/` — the owner's eight approved art boards. **This is the art
   direction.** Tato's look comes from `approved_concept_sheet.png`,
   `refined_game_sheet.png`, `movement_anatomy_sheet.png` and `direction_sheet.png`.
5. `docs/art/*.png` — contact sheets of every picture currently in the game, so you can
   see today's art at a glance (`tato_contact_sheet.png` is all of Tato's frames).

Then the code that matters most for the overhaul:

| What | File |
|---|---|
| Tato's animation table and drawing | `game/scripts/player/tato_visual.gd` |
| Tato's movement, attack, hurt | `game/scripts/player/tato.gd` |
| Creature numbers and which picture each uses | `game/scripts/enemies/enemy_data.gd` |
| Creature base behaviour and how its picture is shown | `game/scripts/enemies/enemy.gd` (+ `walker.gd`, `flyer.gd`, `mole.gd`) |
| Bosses | `game/scripts/bosses/boss.gd` |
| Shots (drawn in code) | `game/scripts/components/projectile.gd`, function `_draw()` |
| Hit bursts, sparkles, floating text | `game/scripts/core/fx.gd` |
| The 12 powers | `game/scripts/food/abilities/*.gd`, numbers in `game/data/foods/*.tres` |
| Backgrounds | `game/scripts/level/backdrop.gd` |
| Terrain drawing | `game/scripts/level/terrain.gd`, atlas layout in `tools/art/art_tiles.py` |
| Stage layouts | `tools/build_levels.py` → `game/data/levels/*.txt` |
| Interface look | `game/scripts/ui/ui_theme.gd`, `hud.gd`, `touch_controls.gd` |

## 2. What needs the most improvement (in priority order)

1. **Tato's animation.** Few frames, several states borrow frames, no idle, no blink, no
   landing, no attack pose, wing shape varies. He must stay a fluffy white baby goose
   with big eyes, rosy cheeks, tiny wings and orange feet, with **exactly two wings and
   two legs in every frame**.
2. **Creatures and bosses do not animate at all.** One still picture each; they slide.
3. **Attack and hit feedback.** Shots are plain shapes; hits only flash and squash.
4. **Backgrounds.** Three flat generated layers per world.
5. **Tiles, platforms and props.** Generated autotile; props are tiny and soft.
6. **Stage design.** Built from repeating chunks; flat stretches; little surprise.
7. **Interface art.** Flat code-built panels and buttons.
8. **Boss presentation** and the nearly empty **Home Nest**.

## 3. Where the art lives and the exact rules for replacing it

All game pictures are under `game/assets/`. Sizes below are today's files.

### Tato — `game/assets/sprites/tato/*.png` (36 files)

- Loaded by `TatoVisual.frame_texture()` straight from this folder by file name.
- **Every frame: 192×192 px, transparent, facing right, feet resting at x = 96, y = 168.**
  The constants are `ANCHOR` and `SPRITE_SCALE` (0.76) in `tato_visual.gd`.
- To redraw a frame, keep its file name and that geometry.
- For sharper art you may use 384×384 with feet at (192, 336); then `ANCHOR` must become
  `Vector2(192, 336)` and `SPRITE_SCALE` 0.38. All frames must share one size.
- To add frames, add PNGs with new names (suggested: `idle_0..3`, `blink_0`, `fall_0..1`,
  `land_0..2`, `attack_0..2`, `hurt_0`, `swim_0..3`, `turn_0`) and list them in the
  `ANIMS` table at the top of `tato_visual.gd`. One line per animation:
  `"walk": [["walk_0", "walk_1", ...], frames_per_second, loop]`.
- Names the game already asks for: `idle, look, walk, run, jump, fall, glide, flap,
  crouch, slide, swim, honk, eat, hurt, cheer, ball, roll, curl, float, climb, stretch,
  charge`. "honk" is the attack pose.
- There is no landing animation state yet; adding one needs a small code change in
  `tato.gd` (`anim_hint()`) — do it or leave a note and Claude will.

### Creatures — `game/assets/sprites/enemies/<kind>.png` (21 files, 68–95 px tall)

- One picture per creature, drawn standing with its feet on the bottom edge, centred.
- The game scales it to the height `h` in `EnemyData.STATS` (46–86 px on screen), so any
  resolution works. Aim for about 2× the on-screen height.
- `faces` in `EnemyData.STATS` says which way the picture looks (1 right, −1 left).
- **Animation is not wired.** If you draw frames, please use this naming so they can be
  hooked up without guessing, and keep one canvas size per creature:
  `<kind>_idle_0.png`, `<kind>_move_0..n.png`, `<kind>_attack_0..n.png`,
  `<kind>_hurt_0.png`, `<kind>_defeat_0..n.png`. Keep `<kind>.png` as the base picture.
  The sprite is created in `enemy.gd` (`sprite = Art.standing("enemies/" + kind)`).

### Bosses — `game/assets/sprites/bosses/<id>.png` (6 files, 124–145 px tall)

- Shown 170–215 px tall, so today they are enlarged and soft. Aim for 400–512 px tall.
- Same naming idea for frames: `<id>_idle_0`, `<id>_warn_0`, `<id>_attack_<name>_0..n`,
  `<id>_hurt_0`, `<id>_defeat_0..n`. Attack names are in `Boss.DATA`.

### Items, pickups, power icons, touch buttons

- `sprites/items/`, `sprites/pickups/`, `sprites/powers/`, `sprites/ui/`.
- Sized in code, so same name at any resolution is a safe replacement.

### World pieces — `game/assets/sprites/world/<world>_<part><n>.png`

- Tiles, hazards, props, flags, signposts, bowls and treats cut from the world board.
  Which file plays which role is the `KITS` table in `game/scripts/core/world_kit.gd`.
- Only the files named `_tile`, `_hazard`, `_prop`, `_flag`, `_sign`, `_bowl`, `_gem`
  are used. Files named `_a`, `_b`, `_c` are leftovers from an earlier cut.

### Backgrounds — `game/assets/sprites/bg/<theme>_{clouds,far,mid}.svg`

- Themes: `grassland, orchard, candy, icy, windy, castle, nest`. (`picnic_*` is unused.)
- Each is 1024×420, transparent above the skyline, **tiles left-to-right** (seamless).
- A PNG with the same base name in the same folder (or in `sprites/override/`) is used
  instead of the SVG automatically.
- Sky colours are the `SKIES` table in `backdrop.gd`. A fourth or fifth layer is one
  more `_add_layer(...)` line there.

### Terrain atlases — `game/assets/tiles/tiles_<theme>.svg`

- 512×960 px: 8 columns × 15 rows of 64 px sub-tiles; four sub-tiles make one 64 px
  cell. Three materials (ground rows 0–4, blocks rows 5–9, ice rows 10–14). The exact
  layout is in the comment at the top of `tools/art/art_tiles.py`.
- The `.svg` extension is written in `terrain.gd` (`_build_tiles()`). A PNG atlas with
  the same layout works after changing that one path.
- The older atlases `tiles_{picnic,farm,fair,market,marsh,kitchen}.svg` are unused.

### Effects and shots

- No picture files today. Shots are drawn in `projectile.gd` `_draw()` by a `look` name:
  `fire, ice, bubble, honey, melon, kernel, tomato, arrow, bolt`. Bursts are in `fx.gd`.
- If you draw effect art, put it in a new folder `game/assets/sprites/fx/` named after
  the look (`fx/fire_0.png` …) and either wire it or note it.

### The `override` folder

`game/assets/sprites/override/<folder>_<name>.png` replaces a picture without code
changes and leaves the original in place. It works for everything loaded through
`Art.tex` (creatures, bosses, items, pickups, icons, world pieces, backgrounds, cards).
It does **not** apply to Tato's frames or the terrain atlases.

## 4. Decisions that must be preserved

- Godot 4.7.2, GDScript, Compatibility renderer, single-threaded web export.
- One active food power; a new pickup replaces it. Five hearts. Three buttons.
- No lives and no game over; checkpoints give everything back.
- Stages are text files built at run time by `Level` + `EntityFactory`. No per-stage
  scenes.
- All damage goes through `Hit` and `take_hit(damage, info)`.
- Pictures are found by short name through `Art`; input goes through the actions in
  `Controls`; progress goes through `GameState`; saves through `SaveService`.
- Save files: if you add a profile field, add its default in
  `SaveService.new_profile()` so old saves still load.
- Tato: two wings, two legs, always.
- Nothing is published or made public. No licence has been chosen.
- The tests in `game/tests/` should keep passing, or be changed on purpose with a note.

## 5. Things that will break the project if done casually

- **Do not delete, rename or hand-write `.import` or `.uid` files.** New files you add
  will get theirs when Godot next opens the project; that is fine.
- **Do not rename or move existing files or folders.** Code finds them by path.
- Do not rename `class_name` classes or the autoloads in `project.godot`.
- Do not re-run the generators unless you mean to overwrite their output:
  `tools/art/extract_tato.py`, `tools/art/extract_sheets.py`, `tools/art/make_art.py`
  (pictures), `tools/build_levels.py` (all stage files),
  `tools/audio/make_audio.mjs` (all audio).
- **Stage files are generated.** To change stages, edit the chunks and stage lists in
  `tools/build_levels.py` and re-run it, or hand-edit `game/data/levels/<id>.txt` and
  say so in your change list so the builder is not run over it.
- Each stage needs exactly three Treasure Notes (`n`), a start `@` and a goal `E`;
  non-boss stages also need one hidden Star (`*`), a checkpoint and a food bowl. A jump clears two tiles;
  three needs a flap. Gaps up to four tiles are comfortable.
- Keep the game light for 2018–2019 iPhones and iPads. Guidelines, not measured limits:
  Tato frames up to 384 px, creature frames up to about 256 px tall, bosses up to 512,
  background layers up to 2048×1024, no full-screen shaders, no large particle counts.
- GDScript here uses static typing and tabs. If Godot cannot be run to check a script,
  keep code edits small and say which ones were not run.

## 6. Please preserve, do not replace in place where avoidable

The owner wants today's artwork kept as reference even where it will be replaced.
Preferred: put new pictures in `sprites/override/` or under new file names, so the
originals stay. Where a file must be overwritten (Tato's frames, tile atlases), that is
acceptable: the originals are also kept in this ZIP and in Claude's Git history at tag
`handoff-2026-11-10`.

Do not remove content that looks unfinished or unused. List it instead.

## 7. What to send back

1. **The whole project folder, zipped, with the same structure** (not only the changed
   files).
2. A file at the top level named `CHANGES_FROM_CHATGPT.md` listing:
   - every file added, changed or removed, with a line saying why;
   - which script changes were actually run in Godot and which were not;
   - new art and the sizes / anchor points used;
   - anything left for Claude to wire up (for example creature animation frames);
   - any change to gameplay rules, numbers or stage files.
3. Please do not reformat or reorder code you are not changing, so the differences can
   be compared line by line.

## 8. How Claude checked this snapshot

On 2026-11-10, with Godot 4.7.2 on macOS:

```
godot --headless --path game --import                                   exit 0, no errors or warnings
godot --headless --path game res://tools/CheckScripts.tscn              121 files, 0 problems
godot --headless --fixed-fps 60 --path game res://tests/TestRunner.tscn 39 passed, 0 failed
```

The same three commands were then repeated on a fresh copy unpacked from the handoff
ZIP (results in `DEVELOPMENT_STATUS.md`, section "Handoff verification").
