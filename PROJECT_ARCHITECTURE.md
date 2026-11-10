# TATO! — Project architecture

Godot 4.7.2, GDScript, Compatibility renderer. The Godot project is the `game/` folder
(`game/project.godot`). Everything below is how the code works **today**.

The one idea to hold on to: **almost nothing is laid out in the Godot editor.** There are
only seven small `.tscn` scenes. Stages, creatures, props, menus and the HUD are built in
code at run time from data files. To change what the game contains you edit data and
scripts, not scenes.

## Folder map

```
game/
  project.godot, export_presets.cfg, default_bus_layout.tres, icon.svg
  autoload/          nine always-loaded singletons (below)
  scenes/            boot/Main, levels/Level, player/Tato, menus/{MainMenu,Storybook,WorldMap,Credits}
  scripts/
    boot/            main.gd: reads start-up switches, opens the title or a stage
    core/            layers.gd (collision layers, TILE=64), art.gd (picture loader),
                     fx.gd (code-drawn effects), world_kit.gd (which world-board picture is which)
    player/          tato.gd, tato_visual.gd, power_slot.gd, ability_runner.gd
    food/            food_definition.gd, recipe_definition.gd, ability_strategy.gd, abilities/<power>.gd x12
    components/      hit.gd (damage), projectile.gd (shots), effect_pulse.gd, noodle_rope.gd
    enemies/         enemy_data.gd (table), enemy.gd (base), walker.gd, flyer.gd, mole.gd
    bosses/          boss.gd (all six bosses)
    level/           level.gd, level_data.gd, terrain.gd, entity_factory.gd, camera_rig.gd,
                     backdrop.gd, water_pool.gd, ice_sheet.gd
    props/           pickups, bowls, checkpoints, goal, blocks, hazards, gimmicks, hub furniture
    story/           story.gd (reads the text files), hint_nest.gd
    ui/              ui_theme.gd, hud.gd, touch_controls.gd, menus and panels
  data/
    foods/*.tres     one FoodDefinition per power (numbers and text)
    levels/*.txt     one text file per stage
    text/*.json      signpost tips, story pages, names, dialogue
  assets/
    sprites/         tato/, tato_big/, enemies/, bosses/, items/, pickups/, powers/, ui/,
                     cards/, world/, bg/ (+ override/, empty, see "Art loading")
    tiles/           tiles_<theme>.svg terrain atlases
    audio/           sfx/, voice/, music/ (.ogg)
    fonts/           Fredoka (OFL)
    ui/              logo.png, boot_splash.png
  web/               shell.html (the web page) and icons
  tests/             test_runner.gd, test_case.gd, unit/, integration/, smoke/
  tools/             CheckScripts.tscn and small editor helpers
tools/               (repo root) Python and Node generators: art cutting, art generation,
                     audio synthesis, stage builder, build.sh
assets/reference/    the owner's eight art boards (source of the cut-out art)
docs/                design, controls, development, art pipeline, asset rights, old handoff docs
```

## Autoloads (order matters; later ones use earlier ones)

| Name | File | Responsibility |
|---|---|---|
| Settings | `autoload/Settings.gd` | options (sound, Cozy Mode, comfort, touch, quality); saved to `user://settings.json`; applies volumes / UI scale |
| Controls | `autoload/Controls.gd` | input actions `move_left/right/up/down, jump, attack, pause`; key and gamepad remapping; touch-device detection; button-name prompts |
| SaveService | `autoload/SaveService.gd` | reads / writes `user://saves/slot_N.json` with a backup copy; schema version 2; `migrate()` |
| FoodDB | `autoload/FoodDB.gd` | loads the 12 `FoodDefinition`s; builds the named Flavor Burst for any pair |
| LevelDB | `autoload/LevelDB.gd` | world and stage tables, unlock order, loads and caches stage files |
| GameState | `autoload/GameState.gd` | the live profile: hearts (max 5), coins, keys, collected notes / stars / pages, cleared stages, cosmetics; signals for the HUD |
| AudioService | `autoload/AudioService.gd` | plays effects (pooled, at most ten voices), honks, music with fades and ducking |
| Captions | `autoload/Captions.gd` | optional on-screen captions for sounds |
| Game | `autoload/Game.gd` | scene changes with a fade, which stage is being played, what to open after a stage |

## Scene flow

`Main.tscn` → title (`MainMenu.tscn`) → pick a save slot → `Storybook.tscn` (opening) →
`Level.tscn` playing `W1-L1` → results card → Home Nest (`Level.tscn` playing `HUB`) or
`WorldMap.tscn` → next stage … → after a boss, a storybook page → after the last boss,
the ending storybook → `Credits.tscn`.

`Level.tscn` is one scene used for every stage, the Home Nest and the trial room.
`Game.level_id` says which stage file to build.

## How each system works

### Player movement and physics — `scripts/player/tato.gd`

`Tato` is a `CharacterBody2D` using `move_and_slide()`. State enum: `IDLE, WALK, RUN,
JUMP, FALL, CROUCH, SLIDE, SWIM, ATTACK, ABILITY, HURT, DISABLED`. All tuning numbers are
constants at the top of the file (walk 215, run 335 after half a second of walking, jump
−690, gravity 1500 rising / 1850 falling, 3 flaps of −350, glide fall 165, coyote time
0.10 s, jump buffer 0.12 s, stomp bounce −520, 1.6 s of invulnerability after a hit).

- A held jump clears two tiles; three needs a flap. The stage chunks assume this.
- One-way platforms sit on their own collision layer; holding down drops through.
- Ice changes acceleration; water (an `Area2D`) switches to swimming.
- `set_disabled(true)` freezes input for menus, the goal and cutscenes.
- The movement tests (`tests/integration/test_movement.gd`) pin these numbers down. If
  you change the feel, expect to update those tests on purpose.

### Animation state handling — `scripts/player/tato_visual.gd`

`TatoVisual` is a child of Tato. Each frame it asks `player.anim_hint()` for a name
("idle", "walk", "run", "jump", "fall", "glide", "flap", "crouch", "slide", "swim",
"honk", "hurt", "cheer", "roll" …) and plays that entry of the `ANIMS` table:
`name -> [list of frame names, frames per second, loop]`. A frame name is a PNG in
`assets/sprites/tato/` (so `"walk_0"` is `walk_0.png`). Walk and run speed up and slow
down with Tato's velocity.

On top of the frames the script adds squash and stretch, lean, a spin for rolls, the
invulnerability blink, a blob shadow, honk marks and the hat. **Frames are plain
individual PNG files shown on one `Sprite2D`; there is no sprite sheet, AnimationPlayer
or skeleton.**

Geometry every Tato frame must share: 192×192 px canvas, feet resting at (96, 168),
facing right, drawn scale 0.76. See `CHATGPT_HANDOFF.md` for how to replace them safely.

### Food-power selection and activation

- `FoodDefinition` (`data/foods/<id>.tres`): name, text, icon, damage, cooldown,
  duration, element, which script runs it.
- `PowerSlot` (`scripts/player/power_slot.gd`): holds **one** power id. `pick_up(id)`
  returns the id it replaced.
- A food bowl (`props/power_bowl.gd`) calls `Tato.collect_power(id)`. That swaps the slot,
  plays the Flavor Burst if a power was replaced, and updates the HUD badge.
- Pressing attack calls `Tato.press_attack()`. With a power it asks `AbilityRunner` to
  `try_activate(definition)`, which checks the cooldown and runs the power's
  `AbilityStrategy` script (`start`, `tick`, `stop`; some override movement, e.g. Garlic
  Dash). With no power it does `plain_honk()`, a short-range burst in front of Tato.
- The power is kept until another bowl replaces it.

### Projectiles, attacks and damage

- `Hit` (`components/hit.gd`) is the single way anything takes damage. Targets implement
  `take_hit(damage, info) -> bool`; `info` carries `element`, `source`, `dir`, `knock`.
  `Hit.burst(...)` hits everything in a circle, `Hit.line(...)` along a segment.
- `Projectile` (`components/projectile.gd`) is an `Area2D` made by
  `Projectile.fire(parent, position, velocity, options)`. Options: `look` (which
  code-drawn shape), `damage`, `element`, `life`, `radius`, `fall`, `spin`, `pierce`,
  `bounces`, `wobble`, `splash`, `hostile` (creature shots that hurt Tato), `source`.
  It must keep `monitorable = true` or it passes through the ground.
- `EffectPulse` tells scenery about elements ("cold" freezes water, "heat" melts ice).
- Creatures can be frozen, stuck (honey), bubbled or stunned; these are timers on
  `enemy.gd`.
- Tato is hurt through `Tato.hurt(from)`: lose a heart, knock back, blink. Cozy Mode and
  "Endless hearts" in Settings stop hearts running out.

### Enemy AI and spawning

- Creatures are **not** scenes. `EnemyData.STATS` is a table: name, behaviour script
  (`walker`, `flyer` or `mole`), hit points, speed, on-screen height `h`, which way the
  drawing faces (`faces`), whether it can be stomped, coins dropped, and trait keys
  (`hop`, `lunge`, `roll`, `shell`, `guard`, `shot`, `pattern` …).
- A stage file places a creature by a letter; `EntityFactory.create()` builds an
  `Enemy` node with the right script and loads `sprites/enemies/<kind>.png`.
- `walker.gd`: patrol, turn at walls and ledges, plus the trait (hop, lunge at Tato,
  roll, shoot on a timer). `flyer.gd`: patrol, swoop, wave, bob, or shy. `mole.gd`: hide,
  pop up near Tato, throw.
- Every creature in a stage runs every frame, wherever the camera is (there is no
  sleep-when-far logic yet; a likely first optimisation for older phones). Creatures do
  not respawn within a stage.
- `boss.gd` runs all six bosses from `Boss.DATA` with modes
  `INTRO → IDLE → WARN → ATTACK → REST → … → DEFEATED`; each attack is a function in
  that file. Defeat fires the level trigger `"boss"`, which reveals the goal flag.

### Level loading and progression

- A stage is a text file: `[meta]` (id, world, theme, kind, hints), `[legend]` (what
  each custom letter means), `[map]` (one character per 64 px cell).
  Terrain letters: `#` ground, `%` blocks, `=` thin platform, `/` `\` slopes, `~` water,
  `i` ice. Built-in items: `@` start, `E` goal, `C` checkpoint, `o` coin, `h` heart,
  `*` star, `n` note, `k` key, `L` lock, `?` Question Block, `B` crate, `S` spring,
  `^` spikes.
- `LevelData.parse()` reads it. `Level` (`level/level.gd`) then builds: `Terrain`
  (merged collision boxes, slope triangles, one-way strips, water, and one
  `TileMapLayer` drawing an autotiled atlas), `Backdrop` (sky gradient + three parallax
  layers), every entity through `EntityFactory`, Tato, the camera, the HUD, touch
  controls and the pause menu.
- **Stage files are generated.** `tools/build_levels.py` assembles 30 stages from chunks
  and overwrites `game/data/levels/*.txt` when run. Hand edits to those files are lost
  the next time it runs unless the builder is changed too.
- Progression lives in `LevelDB` (order and unlock rules) and `GameState.mark_cleared()`
  (stars: clear the stage, find all three notes, find the hidden star).

### Health, respawning and checkpoints

- `GameState.hearts` (max 5). Hearts and Extra Heal pickups restore; 100 coins refill.
- A checkpoint bell (`props/checkpoint.gd`) calls `Level.activate_checkpoint()`.
- At zero hearts: the defeat picture shows briefly, then
  `Level.respawn_at_checkpoint()` puts Tato back with full hearts. Coins, notes and keys
  are kept; the power is set back to the one Tato held when the checkpoint was rung.
  There are no lives and no game over.
- Falling out of the stage costs one heart and returns Tato to the last safe ground
  (or to the checkpoint if that was the last heart).

### Saving, settings and UI

- Saves: JSON per slot, written to a temporary file then renamed, with a `.bak` copy
  that is used if the main file is damaged. `migrate()` upgrades older saves and
  tolerates wrong types. On the web, Godot stores `user://` in the browser's IndexedDB.
- Settings are a separate file, so erasing a save never loses options.
- All interface is built in code with `ui_theme.gd` (colours, panel and button styles,
  font). The HUD and touch controls are `CanvasLayer`s created by `Level`.
- Touch controls read real touch events and feed the same input actions as the
  keyboard, so game code never asks "is this touch?".

### Asset loading and rendering

- `Art.tex("enemies/slime_blob")` loads a picture by short name and caches it. It looks
  in this order: `assets/sprites/override/enemies_slime_blob.png`, then
  `assets/sprites/enemies/slime_blob.png`, then the same name with `.svg`.
  **Dropping a file into `override/` replaces a picture without touching code.**
- Sprites are sized in code: `Art.sized(name, height_px)` scales a picture to a height on
  screen, so a replacement at a different resolution still appears the same size.
- Terrain: `terrain.gd` loads `res://assets/tiles/tiles_<theme>.svg` (the `.svg`
  extension is written in that file) as an 8×15 atlas of 64 px sub-tiles, drawn at half
  scale so four sub-tiles make one 64 px cell. Layout is documented at the top of
  `tools/art/art_tiles.py`.
- Backgrounds: `backdrop.gd` loads `bg/<theme>_clouds`, `_far`, `_mid` through `Art.tex`.
- Effects (`core/fx.gd`) and shots are drawn with `_draw()` calls, no textures.
- Texture filter is linear. No shaders, no particle systems, no lights.

## Fragile things — please do not break these by accident

1. **`.import` and `.uid` files.** Each asset and script has one beside it. They hold the
   resource identifiers Godot uses. Do not delete, rename or hand-write them. Replacing
   `foo.png` with a new `foo.png` and leaving `foo.png.import` alone is safe.
2. **Paths are strings.** Scripts load art and data by path. Renaming or moving a file
   breaks the game silently (a missing picture just does not draw).
3. **`class_name` scripts** (`Tato`, `Level`, `Enemy`, `Art`, `Hit`, `Projectile` …) are
   registered globally. Renaming a class or file needs every use updated and a re-import.
4. **Autoload order** in `project.godot`.
5. **Tato frame geometry** (192×192, feet at 96,168). Different sizes make Tato float or
   sink into the ground.
6. **`faces` in `EnemyData` and `Boss.DATA`.** If a replacement picture faces the other
   way, flip the picture or change the number, or the creature walks backwards.
7. **`Projectile.monitorable` must stay true.**
8. **Coins and prizes are spawned with `call_deferred`** (`Level.drop_coins`, `spill`):
   creating physics shapes inside a physics callback is an engine error.
9. **Generators overwrite their outputs.** `tools/art/extract_tato.py`,
   `extract_sheets.py` and `make_art.py` rewrite files in `game/assets/`;
   `tools/build_levels.py` rewrites `game/data/levels/`; `tools/audio/make_audio.mjs`
   rewrites `game/assets/audio/`. New hand-made assets survive only if these are not
   re-run over them (or the assets live in `sprites/override/`).
10. **The tests encode current behaviour.** `test_levels.gd` requires exactly three
    Treasure Notes and one hidden Star per stage, a food bowl in every stage, and that
    every creature, power, pickup and boss from the boards is used somewhere.
11. **The web page** (`game/web/shell.html`) handles loading, the resolution cap for
    older devices and version updates. The export preset points at it.

## Tests and tools

```bash
godot --headless --path game --import
godot --headless --path game res://tools/CheckScripts.tscn
godot --headless --fixed-fps 60 --path game res://tests/TestRunner.tscn
tools/build.sh web
```

`docs/DEVELOPMENT.md` has the full list, including how to jump straight into a stage.
