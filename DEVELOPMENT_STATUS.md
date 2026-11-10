# TATO! — Development status at handoff

Snapshot date: 2026-11-10 (second handoff, version 0.2.0). Git tag of this exact state:
`handoff-2-2026-11-10`. The first handoff is tag `handoff-2026-11-10`.
Written for the pause while the art, animation and gameplay overhaul happens elsewhere.

> **Updated for the second handoff (2026-11-10, version 0.2.0, tag
> `handoff-2-2026-11-10`).** ChatGPT's overhaul v1 is merged and tested. Since the
> first handoff: Tato has idle, jump, fall, land, attack, pickup and hurt animations;
> every creature and boss cycles four motion frames; hits pause, shake and spark;
> defeated creatures fly off; far creatures rest; main stages have three checkpoints
> and bonus stages two; the six worlds use PNG backgrounds and tile atlases; HUD plates;
> web, macOS, Windows and Linux exports build. Sections 7 and 8 below are rewritten to
> match. The test counts are current: 39 of 39.

How to read this file:

- **Works (tested)** — built, and an automated test or an on-screen check confirmed it.
  Each line says which.
- **Built, not checked** — code exists and loads, but nobody has seen or played it properly.
- **Planned** — not started.

An honest summary first: **the game is complete as a system and plays from the title
screen to the credits, but it looks and feels like a first build.** The code, data and
tests are in good order. The art is cut-outs from concept boards plus generated tiles and
backgrounds, most characters do not animate, and no person has played the campaign from
start to finish. The overhaul is aimed at exactly the weakest parts.

---

## 1. Completed and functional

| Area | State | How it was checked |
|---|---|---|
| Project opens, every script / scene / resource loads | Works | `tools/CheckScripts.tscn`: 122 files, 0 problems |
| Tato's movement: walk, run, jump (variable height, coyote time, jump buffer), 3 flaps, glide, crouch-slide, swim, one-way platforms, slopes, ice | Works | 7 movement tests; seen on screen |
| One active food power, newest pickup replaces it | Works | unit + combat tests |
| All 12 food powers attack and hit creatures | Works | combat test fires each one at a creature |
| Plain honk attack when Tato holds no power | Works | combat test; seen on screen |
| Stomping creatures; prickly ones cannot be stomped | Works | combat test |
| 5 hearts, hurt + brief invulnerability, checkpoint respawn with nothing lost | Works | combat test |
| Coins (100 refill hearts), Treasure Notes (3 per stage), hidden Star, keys + locks, Question Blocks, crates, springs, 20 level pickups | Works | combat + level tests |
| 21 creatures (18 + fire / ice / shock slimes) spawn, move, attack, can be defeated | Works | every kind is placed in a stage; robot playthrough runs past all of them |
| 6 bosses: intro, three attacks each, health bar, defeat opens the goal | Works | boss test beats all six |
| 30 stages + Home Nest + trial room load and can be finished | Works | level tests; a robot player reaches the goal in all 24 non-boss stages |
| Save / load, 3 slots, backup file, migration from older saves | Works | 7 save tests |
| Title screen, save-slot picker, settings (4 tabs, key remapping), storybook, world map, credits, pause, Snack Notebook, wardrobe, results card | Works | "every screen" test opens and presses them with error catching on; title, slots, storybook, map, Home Nest seen on screen |
| HUD: hearts, power badge, coins, notes, keys, boss bar | Works | seen on screen |
| Touch controls (move, jump, attack, pause) | Works | drawn at phone size in a browser; synthetic touch events moved and jumped Tato |
| Keyboard controls and remapping | Works | tests drive the same input actions; remap test |
| Web export (release) runs | Works | Chromium-based browser only (see section 8) |
| Web page: loading screen, safe-area insets, resolution cap for older devices, offline cache, picks up a new version at start | Works | update pickup confirmed once in the browser |

Automated suite: **39 tests, all passing** (15 unit, 23 integration, 1 robot playthrough),
about 40 seconds. The runner fails a test if the game logs any script or engine error.

## 2. Partially implemented

- **Tato's animation** — frame animation exists but is thin; see section 7.
- **Creature and boss animation** — four near-identical motion frames each plus code
  motion. They no longer slide rigidly, but nothing is drawn in a second pose.
- **Attack visuals** — every shot, beam, bomb and effect is drawn in code from circles,
  polygons and small bursts. They work; they do not look good.
- **Flavor Burst** — when a new power replaces the old one a named burst plays (66 names,
  one shared effect coloured by element). It is a flourish, never required.
- **Story** — storybook pages (board paintings + a sentence) for the opening, after each
  boss, and the ending. No characters to talk to, no cutscenes. A dialogue box exists but
  no stage uses it for a character.
- **Wardrobe** — hats bought with coins; the "hats" are item icons placed on Tato's head.
- **Stage design** — all 24 non-boss stages are assembled by `tools/build_levels.py` from
  a library of about 50 hand-drawn chunks. They are finishable and vary per world, but
  they are formulaic: similar length, similar rhythm, long flat stretches.
- **Home Nest** — works (world gates, wardrobe crate, signposts) but is nearly empty.
- **Sound and music** — 66 effects, 14 honks, 12 music loops, all generated by a script.
  They play. No person has listened to them yet.
- **Gamepad** — mapped and remappable; never tried with a real controller.
- **Desktop exports** — macOS, Windows and Linux build with `tools/build.sh all`. The
  macOS app was launched and ran a stage. Windows and Linux files have not been run.
- **CI** — three GitHub workflows are written; they have never run (there is no remote).
- **Performance on 2018–2019 iPhones / iPads** — designed for (single-threaded web
  export, capped resolution, one tile map, no particle systems) but **not measured**.

## 3. Not started

- Replacement art: animated Tato, animated creatures and bosses, painted backgrounds,
  drawn tiles, drawn effects, drawn interface. (The overhaul.)
- Characters to meet (no approved art for any).
- Testing on a real iPhone or iPad, or in Safari at all.
- Play-testing by people; difficulty and pacing tuning from that.
- Publishing: no GitHub remote, no licence chosen, nothing is online.
- Translations.

## 4. Worlds and stages that exist

Each world has three stages, a bonus stage and a boss stage (files in
`game/data/levels/`, names in `game/autoload/LevelDB.gd`).

| World | Stages (L1, L2, L3, bonus) | Boss |
|---|---|---|
| 1 Grassland | Honk Hill, Bouncy Meadow, Hedgehog Hollow, Coin Dash | Mega Mushroot |
| 2 Orchard | Apple Lane, Mole Orchard, Treetop Tumble, Bee Line | Gigantapple |
| 3 Candy Carnival | Sprinkle Street, Conveyor Carnival, Cotton Candy Climb, Balloon Bash | Candy King |
| 4 Icy Pond | Slippy Shore, Icicle Cavern, Frozen Falls, Puffin Slide | Frost Puffin Lord |
| 5 Windy Mill | Breezy Bluffs, Gusty Gears, Above the Clouds, Tailwind Trial | Sky Airship Turtle |
| 6 Castle Feast | Banquet Bridge, Kitchen Keep, The Great Hall, Feast Gauntlet | Chef Castle Golem |

Plus `HUB` (Home Nest) and `TRIAL` (a room with every food bowl). Total 32 stage files,
and `TEST.txt` used by nothing in the campaign.

## 5. Food powers that actually work

All twelve fire, hit and have their own script (`game/scripts/food/abilities/`):

| Power | Attack | Behaviour in the game now |
|---|---|---|
| Fire Pepper | Fire Shot | fireball straight ahead; melts ice blocks |
| Bubbleberry | Bubble Trap | two wobbling bubbles; a caught creature floats away |
| Watermelon | Multi Shot | three slices in a fan |
| Honeycomb | Honey Shot | a glob that glues a creature in place |
| Popcorn | Pop Shot | kernels arc up and out |
| Noodle | Noodle Whip | long whip through everything; pulls coins in |
| Frostberry | Freeze Shot | freezes creatures into blocks Tato can stand on; freezes water |
| Cocoa Shield | Shield Guard | nothing hurts Tato; shots bounce back |
| Garlic Dash | Dash Attack | dash through creatures, crates, cracked walls |
| Thunder Corn | Lightning Shot | a bolt that jumps between creatures |
| Lemon Beam | Laser Beam | beam through everything in a line |
| Tomato Bomb | Bomb Blast | lobbed bomb with a splash; breaks cracked walls |

Numbers (damage, cooldown, duration, element) are in `game/data/foods/*.tres`.
Elements matter a little: fire slimes ignore fire and take double from ice, and so on.

## 6. Creatures and bosses implemented

All in `game/scripts/enemies/enemy_data.gd` (numbers) with three behaviour scripts.

- **Ground (walker.gd):** Mushroom Hopper (hops), Slime Blob, Fire / Ice / Shock Slime,
  Apple Chomper (lunges), Hedgehog Roller (rolls, cannot be stomped), Turtle Tank
  (4 hits, shell), Crab Snipper (fast scuttle), Onion Knight (guards from the front),
  Rock Golem (5 hits, ground pound).
- **Ranged (walker.gd + shots):** Carrot Archer (arrows), Pepper Goblin (fire), Ice Puffin
  (snow), Candy Imp (candy, hops).
- **Sneaky (mole.gd):** Mole Digger (pops up, throws rocks).
- **Flying (flyer.gd):** Bee Buzzer (patrol), Crow Swooper (swoops), Ghost Poof (shy:
  moves when Tato looks away, cannot be stomped), Pie Bat (wave), Balloon Jelly (bobs).
- **Bosses (boss.gd):** the six in the table above; three attacks each with a warning
  flash before every attack and a rest afterwards.

Behaviour is simple. Variety comes mostly from numbers and one special trait each.

## 7. Animations currently available

**Tato** — 70 PNG frames in `game/assets/sprites/tato/` (36 cut from the anatomy board,
34 added by ChatGPT as re-posed copies of those). What the game uses (`ANIMS` in
`game/scripts/player/tato_visual.gd`):

| Animation | Frames used | Honest note |
|---|---|---|
| idle | 6 (`idle_0..5`) | subtle breathing; near-identical frames; no blink |
| walk | 8 (`walk_0..4`, `walk_extra_0..2`) | usable |
| run | 8 (`run_0..4`, `run_extra_0..2`) | usable |
| jump | 3 (`jump_start_0..2`) | rotated copies |
| fall | 3 (`fall_0..2`) | |
| land | 4 (`land_0..3`) | squashed copies; plays after a hard landing |
| attack / honk | 4 (`attack_0..3`) | existing poses in sequence, not a drawn attack |
| pickup | 4 (`pickup_0..3`) | last frame is the front-view drawing |
| hurt | 4 (`hurt_0..3`) | |
| flap / glide | 1–2 (`jump_air`, `jump_flap`) | borrowed frames |
| crouch / slide | 1 (`jump_crouch`) | a still |
| swim | walk frames | borrowed |
| cheer | `cheer` + 2 borrowed | |
| roll / ball | `roll_0..3` | used by Garlic Dash |

Every frame has two wings and two legs.

Unused but present: 10 face expressions, 5 size poses, back view. Also five large Tato
drawings in `sprites/tato_big/` (title screen, defeat picture, results).

Squash, stretch, lean and a blob shadow are added in code on top of the frames.

**Creatures and bosses** — four motion frames each in `sprites/{enemies,bosses}/anim/`
(the base picture slightly warped), cycled by time, plus bob, recoil and squash in code.
No attack, hurt or defeat drawings.

**Everything else** — coins, pickups and bowls bob; effects are code-drawn.

## 8. Known bugs, visual problems and limits

Visual (these match the owner's list and are accurate):

- Creature and boss "animation" is one drawing wobbling.
- Tato's added frames are re-posed copies; wing shape still differs between source
  frames. Every frame has two wings and two feet.
- Shots and effects are code shapes (the fire shot is the most developed).
- The six worlds' backgrounds reuse one tree shape recoloured, with stair-stepped edges
  when enlarged. They did not repeat cleanly; the game now mirrors them at the join.
- The right HUD plate is much wider than its contents, and pop-up messages overlap it.
- World-board pieces (signposts, flags, bowls, hazards) are only 40–60 px in the source
  and look soft next to Tato.
- Slick ice shows as a lighter rectangle inside the ground.
- Interface panels and buttons are flat shapes built in code.

Behaviour and testing limits:

- **Nobody has played it through.** The robot holds right, jumps and attacks; it proves
  stages can be finished, not that they are fun or fair.
- **Never run in Safari or on an iPhone / iPad.** Xcode is not installed on the
  development Mac, so there was no simulator. The browser used for checks is
  Chromium-based.
- **No performance numbers.** A readout exists (`?fps=1` on the web, `--fps` on desktop)
  but the browser window was in the background when I tried to read it.
- Bosses were fought only by the test harness. Only Mega Mushroot's arena was seen on
  screen, and only its opening moment.
- Worlds 5 and 6, the settings screen, notebook, wardrobe, pause menu, results card and
  credits have not been looked at on screen (the tests open them without drawing).
- During startup the browser logs repeated WebGL warnings ("Framebuffer is incomplete:
  Attachment has zero size") until the first frame. Harmless there; unknown in Safari.
- **One unexplained event:** once, after I cleared the page's offline cache while it was
  still loading, the browser's saved games were gone. Three deliberate attempts to
  repeat it (normal reloads and an interrupted load) kept the save. Cause unknown.
- On iPhone / iPad, Safari can clear a website's saved data after a week without visits
  unless the game was added to the Home Screen.
- Stage `W3-L2` has no Candy treat pickup (every other stage in worlds 2–6 has one).
- The debug start `?at=<column>` can drop Tato straight onto a creature.
- Stale files that nothing uses are still in the project (kept on purpose, see
  `CHATGPT_HANDOFF.md`): old-name world cut-outs, six old tile atlases, old `picnic`
  backgrounds, `TEST.txt`.

## 9. Engine and configuration

- **Godot 4.7.2 stable**, standard build, GDScript only. No plugins, no GDExtension.
- Renderer: Compatibility (OpenGL / WebGL 2).
- Design size 1280×720, stretch `canvas_items`, aspect `expand`, landscape.
- Physics 60 ticks per second; gravity 1500; one tile = 64 px.
- Main scene `res://scenes/boot/Main.tscn`. Nine autoloads (see `PROJECT_ARCHITECTURE.md`).
- Export presets: Web (single-threaded, custom page `game/web/shell.html`, installable
  with offline cache), macOS, Windows Desktop, Linux.
- Version string `0.1.0`.

## 10. What I was doing right before this handoff

A look-at-everything pass on the web build, fixing what it showed:

1. Finished: robot playthrough of all 24 stages; a test that opens every screen; the
   test runner now fails on logged errors (this caught a broken save-slot list).
2. Finished: title screen uses the "TATO!" logo cut from the direction board.
3. Finished: camera moved closer (about 16 tiles across) so characters read larger.
4. Finished: cleaned specks and panel-frame lines off the small world pieces; each
   world's treat (apple, gummy bear, snowflake, leaf, crown) became a pickup.
5. Finished: web page keeps its loading picture until the first frame and switches to a
   newly published version at start.
6. **Interrupted:** measuring frame rate at phone size, and setting up a WebKit (Safari
   engine) run with Playwright to stand in for the missing iOS simulator. Neither
   produced a result.
7. Not reached: desktop exports, README screenshots, a real-device check.

Nothing is half-edited. The tree was committed after a clean import and a full passing
test run.
