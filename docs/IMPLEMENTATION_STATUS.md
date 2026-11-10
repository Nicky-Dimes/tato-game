# TATO! — Implementation status

> **Superseded on 2026-11-10.** The current, accurate status is
> [`DEVELOPMENT_STATUS.md`](../DEVELOPMENT_STATUS.md) at the top of the project. This
> file is the older running log, kept unchanged below for history; parts of it are out
> of date (for example it predates the tests, the audio and the web checks).

Living progress file. Newest facts at the top. `DONE` = built **and** checked the way
the line says; `BUILT` = code exists but has not been verified yet; `NOT DONE` = still to do.

## Design direction in force (owner, 2026-11-10 15:21)

The owner supplied five new boards (`assets/reference/*_sheet.png`) with the instruction
"all five must be saved and every item used". They redesign the game and **override the
older GDD wherever the two disagree** (owner rule: newest instruction wins):

| Topic | Old GDD (v0.1) | Now (the five boards) |
|---|---|---|
| Powers | two Flavor Pockets + 12 fusion recipes, puzzle tools | **one active attack power**; the newest pickup replaces it |
| Power list | Pepper, Bubble, Honey, Melon, Frost, Popcorn, Noodle, Citrus, Mint, Jam, Truffle, Pastry | Fire Pepper, Frostberry, Bubbleberry, Honeycomb, Watermelon, Popcorn, Noodle, Thunder Corn, Tomato Bomb, Garlic Dash, Lemon Beam, Cocoa Shield |
| Health | 3 Comfort Feathers | **5 hearts**; Heal (+1) and Extra Heal (fill) pickups; "hard to die" |
| Enemies | 8 nonviolent puzzle creatures | **18 enemies** (+ fire / ice / shock slimes), defeated with attacks (they poof) |
| Bosses | Puddle Puffer ... Cloche | Mega Mushroot, Gigantapple, Candy King, Frost Puffin Lord, Sky Airship Turtle, Chef Castle Golem |
| Worlds | Picnic Patch ... Silent Kitchen | Grassland, Orchard, Candy Carnival, Icy Pond, Windy Mill, Castle Feast |
| Controls | move, jump, eat, honk, fuse, swap | **move, jump, attack** (+ pause) |
| Collectibles | scraps, pins, dishes | coins, stars, treasure notes (3 per stage), keys, 20 level pickups |

Kept from the old design because the boards do not contradict it: Tato himself and the
two-wings/two-feet rule, the honk (it is the attack when no power is held), checkpoints with
no lives, Cozy Mode and the accessibility options, save slots, the Home Nest hub, the
30-stage campaign shape (6 worlds x 3 stages + bonus + boss), and the recipe notebook
(it now records "Flavor Bursts": the one-off burst when a new power replaces a different one).

## Art

- DONE (looked at contact sheets in `docs/art/cut_*.png`): every drawing is **cut from the
  owner's boards**, not redrawn — `python3 tools/art/extract_sheets.py --review`:
  18 enemies + 3 slime variants, 6 bosses, 6 core items, spring pad / crate / question block /
  move button, 3 food bowls, 20 level pickups, 12 power icons, extra-heal, touch buttons
  (move / jump / attack), big Tato drawings (front, side, cheer, defeat, respawn),
  6 world cards, 5 mock screens, 6 world scene paintings, 12 power "action demo" strips,
  and the six world kits (tiles, hazards, props, checkpoint, signpost, bowl, collectibles).
- DONE: Tato's animation frames cut from the first three boards (`tools/art/extract_tato.py`).
- KNOWN LIMITS: the boards are 1448x1086, so world-kit drawings are only ~40-60 px and look
  soft when enlarged; a few are still stuck together (e.g. coin+star) or missing
  (grassland signpost/bowl, windy collectibles, castle bowl). Terrain tiles and parallax
  backgrounds are generated (`tools/art/make_art.py`) because seamless tiles cannot be cut
  from thumbnails. Sharper art needs bigger source sheets from the owner's image tool.

## Engine foundation

- DONE (tests): project boots headless; settings, controls + remapping, save slots with
  backup + migration, level text format, terrain builder, camera, touch controls, menus.
- DONE (7 integration tests): walk/run, jump height, short hop, coyote time, jump buffer,
  flap x3 + glide, one-way platforms + drop-through, slopes, swimming, belly slide.
- DONE: web export runs in the in-app browser at 60 fps (1024x768 canvas).

## NOT DONE — in this order

1. Rebuild powers as 12 single-slot attacks; remove pockets/fusion code and old puzzle props.
2. Hearts, coins, stars, notes, keys, question blocks, power bowls, 20 pickups.
3. 18 enemies (+3 slimes) with HP and defeat; 6 bosses with three attacks each.
4. World gimmicks: bounce mushroom, falling apples, candy conveyor, slick ice, wind gust, drawbridge.
5. 30 stages + Home Nest; world map; story screens; ending; credits.
6. Sound effects and music (generated, original).
7. Full campaign test pass; iOS Simulator check; desktop + web release builds.
8. CI workflows, README with screenshots, release notes; publishing steps for the owner.

## How to run things

See `docs/DEVELOPMENT.md` (to be written) — short version, from the repo root:

    godot --headless --path game --import
    godot --headless --path game res://tools/CheckScripts.tscn
    godot --headless --path game res://tests/TestRunner.tscn
    godot --headless --path game --export-debug "Web" ../build/web/index.html
