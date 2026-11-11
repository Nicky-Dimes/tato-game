# MASTER BUILD DIRECTIVE — FINISH THE ENTIRE TATO! GAME

**Role:** Lead Godot engineer, 2D game artist, animator, level designer, gameplay designer, QA engineer and release engineer. Execute and integrate production work, not another proposal. Read `CLAUDE.md` first.

## Goal and boundaries

Deliver a beautiful, original, **fully playable** 2D action-platformer with **all 30 stages in six worlds**, hub and trial room, all **12 attack powers**, **21 regular enemy types**, **six multi-attack bosses**, story/menus/save/load/accessibility, complete asset library, audio, and tested browser/desktop exports. Retain Godot 4.7.2, GDScript and Compatibility renderer unless the owner explicitly authorizes a change.

**The current project is a tested engineering baseline, not a release-quality art build.** The desired visuals are `REFERENCE/01_OFFICIAL_TARGET_GAMEPLAY_GOOSE.jpeg` and `02_OFFICIAL_PRODUCTION_BOARD.png`. Tato must be a **white baby goose**; any recent concept image that shows a puppy is an error and must be discarded. Owner feedback consistently rejects prototype-like vector backgrounds, procedural wallpaper rocks, generic cutout sprites, sparse levels and uneven visual styles.

## What to build, not just describe

**Art pipeline:** Independently painted source layers; 16:9 high-detail parallax; seamlessly tiled terrain/raised platforms/slopes; transparent props; separate character and enemy animation cels; power icons/projectiles/trails/impact FX; HUD, screens and world maps. Author original artwork with valid rights and complete provenance. All objects must live in the actual Godot coordinate/animation system. **Never put gameplay objects or HUD into background images.**

**Tato:** Expressive and readable with rich idle/walk/run/jump/fall/land/honk/attack/hurt/recover/eat/glide/roll/swim animations. Clean silhouettes and 2-wing/2-leg anatomy. Use existing `tato_visual.gd` contract (192×192, feet (96,168), faces right). Replace fake deformations/still cycling with actual newly drawn cels, including attack-specific character acting.

**Combat:** Preserve one active power, 12 distinct attacks, obvious animations and projectiles, enemies that telegraph attacks, hitstop/impact/sounds/knockback when appropriate, plentiful but readable enemies, cozy difficulty. Keep all existing power definitions and IDs. Make every weapon genuinely useful in ordinary fights and boss fights; avoid float-only powers with no combat action.

**Campaign:** W1 Grassland/Sunny Meadows, W2 Orchard, W3 Candy Carnival, W4 Icy Pond, W5 Windy Mill, W6 Castle Feast. For EACH: three main stages, one optional/bonus stage and a boss stage. Distinct art/lighting/animation/encounters, individual world props and hazards, stages that feel authored rather than formulaic. Rework level geometry only after maintaining reachable exits and intact collectibles; test robot progression.

**Interface:** Premium readable HUD (Tato portrait, 5 hearts, single power badge/charge, coins, notes/map progress, pause), attractive title/menus, map/journal/save slots/results, settings/controls. Keep touch controls kid-friendly and accessibility behavior intact.

**Finishing:** audio polish, controller/touch validation, consistent fonts/licensing, optimization, debug checks, complete manual playthroughs, web/mobile browser QA, export and GitHub CI. Do not publish without actual release validation.

## Workflow and acceptance

1. Freeze baseline and set up a Git branch. Verify Godot engine exact version and run all tests.
2. Make a *vertical-quality* world one with standalone game-ready assets, integrate, screenshot and compare with owner-approved target. **Do not call a low-quality screenshot complete.**
3. Replace the outdated visual assets for every other world using the same high-quality standard. Build enemies and action animations in parallel with world art as viable.
4. Maintain and actually update `PRODUCTION_BACKLOG.csv`. Treat every asset as a named deliverable, not a vague "polish" line.
5. Verify per-state animation, UI, attacks, collisions, collectibles, level pacing, bosses and saves.
6. Run full automated tests, manual visual QA and release builds before marking complete.
7. Report genuine artifacts: source commits, standalone assets, in-engine screenshots, logs, and actual playable builds. No promises of asynchronous progress or invented completion.

## Owner-acceptance gates

- **G1: Asset quality:** target art reproduced in distinct usable assets, crisp at 1280×720 and scaled screens; no obvious repeats, giant baked background collectibles, background crop blur, extra wings, dog mascot, clipped labels, or unlicensed assets.
- **G2: Integration:** gameplay screenshot directly from Godot resembles approved reference in composition, shading, detail density, color, depth and consistent style.
- **G3: Animation:** independently authored frames for Tato and all adversaries; run/jump/land/hit/attack clearly read while moving and attacking.
- **G4: Gameplay:** one active attack power, enemies abundant and fair, 5 hearts and forgiving respawn, all levels finishable.
- **G5: Engineering:** import clean, every resource loads, 39 tests pass, all 24 non-boss stages completed by smoke robot, six boss fights functional, no serious runtime errors; record benign warnings separately.
- **G6: Release:** web and desktop exports run, gamepad/touch behavior tested, license provenance reviewed, GitHub repo actually built/deployed with owner's approval.

**Do not declare TATO! finished until G1–G6 are genuinely complete.** If unable to create enough high-quality art in one session, preserve exact state and continue in subsequent active sessions; do not substitute glossy concept screenshots for finished game assets.
