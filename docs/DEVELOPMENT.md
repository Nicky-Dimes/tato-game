# Development

Engine: **Godot 4.7.2 standard** (GDScript). Renderer: Compatibility (WebGL 2 on the web).
Design size 1280x720, stretched with `canvas_items` / `expand`, landscape.

All commands run from the repository root.

## First run

```bash
godot --headless --path game --import      # imports art; registers class names
godot --path game                          # play
godot --path game -- --level=W3-L2         # jump straight into a stage (throwaway save)
godot --path game -- --level=W1-L1 --at=120   # ... starting 120 columns in
```

Run `--import` again after adding a picture or a script that declares `class_name`.

Screenshots from the real game window (it quits by itself afterwards):

```bash
godot --path game -- --level=W3-L1 --at=60 --shot=/tmp/shot_%d.png --shot-after=150 --shot-count=4 --shot-every=8 --press=move_right,attack
```

## Checks and tests

```bash
godot --headless --path game res://tools/CheckScripts.tscn      # every script / scene / resource loads
godot --headless --fixed-fps 60 --path game res://tests/TestRunner.tscn        # all tests
godot --headless --fixed-fps 60 --path game res://tests/TestRunner.tscn -- --group=unit
godot --headless --fixed-fps 60 --path game res://tests/TestRunner.tscn -- --only=test_combat
```

- `tests/unit` — powers and the single slot, Flavor Burst symmetry, saves and migration,
  every stage file, "every item on the boards is used", art present for everything
- `tests/integration` — movement feel, attacks (all twelve), hearts and respawn, blocks,
  keys and pickups, finishing a stage, all six bosses
- `tests/smoke` — a robot plays every non-boss stage from start to goal

`--fixed-fps 60` lets the headless run go faster than real time (the whole suite takes
about 40 seconds; the robot plays 24 stages in about 30). `-- --stage=W3` limits the
robot to one world. The runner exits non-zero if any test fails (CI relies on that).

## Building

```bash
tools/build.sh web        # build/web/index.html  (single-threaded; works on GitHub Pages)
tools/build.sh macos      # build/macos/Tato.zip
tools/build.sh windows    # build/windows/Tato.exe
tools/build.sh linux      # build/linux/Tato.x86_64
tools/build.sh all
```

Export templates for 4.7.2 must be installed (Godot editor: Editor > Manage Export Templates).
To try the web build locally: `python3 -m http.server 8780 --directory build/web` and open
http://localhost:8780 . Add `?level=W2-L1` to jump to a stage, `?dpr=1` to force a lower
render resolution.

## Making content

| To change | Edit | Then run |
|---|---|---|
| A stage's layout | `tools/build_levels.py` (chunks + stage lists) or the `.txt` file itself | `python3 tools/build_levels.py` |
| A power's numbers / text | `game/data/foods/<id>.tres` (or `tools/gen_power_data.py`) | — |
| A power's behaviour | `game/scripts/food/abilities/<id>.gd` | — |
| A creature's numbers | `game/scripts/enemies/enemy_data.gd` | — |
| A boss | `game/scripts/bosses/boss.gd` (`DATA` + attack code) | — |
| Signpost tips, story pages | `game/data/text/*.json` | — |
| Pictures cut from the boards | `tools/art/extract_sheets.py` | `python3 tools/art/extract_sheets.py --review` |
| Tato's animation frames | `tools/art/extract_tato.py` | `python3 tools/art/extract_tato.py --sheet` |
| Terrain tiles / backgrounds | `tools/art/art_tiles.py`, `art_backgrounds.py` | `python3 tools/art/make_art.py` |
| Sounds and music | `tools/audio/make_audio.mjs` | `node tools/audio/make_audio.mjs` |

The art tools need only Python 3; the audio tool needs Node 18+ and ffmpeg.

### Stage file format (`game/data/levels/<id>.txt`)

```
[meta]      id, world, theme, kind (core / optional / boss / hub), hints = a | b | c
[legend]    one line per custom letter:   P = power FIRE_PEPPER
[map]       one character per 64 px cell
```

Terrain: `#` ground, `%` blocks, `=` thin platform, `/` `\` slopes (in the row above the
floor they rise from), `~` water, `i` ice. Built-in items: `@` start, `E` goal, `C`
checkpoint, `o` coin, `h` heart, `H` extra heal, `*` star, `n` note, `k` key, `L` lock,
`?` question block, `B` crate, `S` spring, `^` spikes. Everything else goes through the
legend; the types are listed in `game/scripts/level/entity_factory.gd`.

A jump clears two tiles; three needs a flap. Gaps up to four tiles are comfortable.

## Code map

```
game/autoload/      Settings, Controls, SaveService, FoodDB, LevelDB, GameState, AudioService, Captions, Game
game/scripts/player tato.gd (movement + attack), tato_visual.gd, power_slot.gd, ability_runner.gd
game/scripts/food   power definitions and the twelve attack scripts
game/scripts/components   hit.gd (damage), projectile.gd (shots), effect_pulse.gd
game/scripts/enemies      enemy.gd + walker / flyer / mole behaviours, enemy_data.gd
game/scripts/bosses       boss.gd
game/scripts/level  level.gd, level_data.gd, terrain.gd, entity_factory.gd, camera, backdrop
game/scripts/props  pickups, bowls, blocks, hazards, gimmicks, hub furniture
game/scripts/ui     HUD, touch controls, menus, notebook, wardrobe, world map, storybook
```

## Devices

The web build is tuned for 2018-2019 iPads and iPhones: single-threaded export, capped
render resolution (`game/web/shell.html`), one tile map and plain sprites, no particle
systems, at most ten sound voices. "Graphics detail" in Settings (or `?dpr=`) changes the
resolution cap.

## Trying the web build on a phone or tablet (same Wi-Fi)

The engine only starts on a secure connection. `http://localhost` on the same computer
is fine; another device needs HTTPS:

```bash
tools/build.sh web
python3 tools/serve_https.py        # prints https://<this computer's address>:8443
```

The certificate is made locally, so the browser warns once ("This Connection Is Not
Private"); choose Show Details and visit the website. Plain `http://<address>` from
another device shows "This browser is missing: Secure Context".
