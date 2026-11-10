# TATO! — Integrated production overhaul, first implementation pass

**Source:** `TATO_CURRENT_PROJECT_HANDOFF.zip`, November 10, 2026. The original ZIP remains untouched.

This directory is a modified *actual Godot game project*. Open **`game/project.godot`** in Godot 4 to import the new artwork and then run the game.

## What has actually been changed in game files

1. **Player animation:** Added 34 transparent, foot-aligned PNG animation frames (`game/assets/sprites/tato/`). The animation state table in `tato_visual.gd` now uses six idle frames, eight walk frames, eight run frames, multi-frame jump and fall, four-frame landing, four-frame attack/honk, pickup and hurt. `tato.gd` connects ability activation to the visual attack pose *after* AbilityRunner is initialized. The player's `landed` signal triggers a landing pose. These generated frames are animation *extensions from source art* — not yet bespoke hand-drawn full-frame animations.
2. **Enemies and bosses:** Added 84 enemy frames + 24 boss frames (`sprites/{enemies,bosses}/anim/`). The existing sprite machines switch frames based on motion/AI state; enemies additionally wobble, hop, breathe, recoil and show hit squash. These are **procedurally deformed frames**, an interim animation system pending professional frame-by-frame redraw.
3. **World layers:** Added 18 new 1024px-wide transparent parallax images for all six core worlds (three layers per world), using the original `bg/<theme>_far/mid/clouds` short names so the existing `Art.tex` loader picks them up. These are source assets in the correct folders. Their style is still illustrative vector-style and does not yet match the premium hand-painted target.
4. **Level tiles:** Created six color/detail-textured 512×960 tile atlases; modified `terrain.gd` to use these `.png` files when present and fall back to the original SVG otherwise. Tile coordinates and collision design stay unchanged.
5. **HUD:** Two original richly edged wood/plum HUD backplate textures are now wired into `hud.gd`, behind the existing fully functional hearts, food-power badge and counters.
6. **Combat VFX:** `projectile.gd` fire attacks have animated layered flame and ember trails; `fx.gd` has glossy puff clouds, star-burst sparkles and double-layer rings.

## What is preserved

- All 6 worlds and 30 campaign stages; existing level data untouched.
- All 12 current food powers; one active food power remains the rule.
- All 21 enemies, 6 bosses, menus, saves, controls, health, checkpoints and save migration.
- Existing image file names and their import metadata. Original SVGs and sprite PNGs are retained.

## Honest limits and required validation

This handoff is **an implemented first pass, not a certified finished visual overhaul**. There is no Godot executable available in the authoring runtime, so runtime parsing, engine imports, 39 automated game tests, browser playthrough and device testing were **not executed** here. A static asset audit was performed; see `PRODUCTION_PATCH_MANIFEST.json`. This should be tested by Claude in Godot **before** merging to the release branch.

The generated additions do not replace the need for professionally drawn individual Tato, creature and boss animation poses; and the world backgrounds need a final paint-over to reach the polished target sheet. The project does not yet fully meet the requested premium art quality.

## Claude reintegration sequence

1. Open `game/project.godot` in Godot 4, allow newly added PNGs to import. Capture all parse, load and runtime errors.
2. Run `game/tests` via the repository test runner, fix any failures caused by this patch. Perform movement and attack visual QA, including landing state and abilities triggered after instantiation.
3. Open each core world and inspect both parallax repeat behavior and textured tiles. Revert or adjust layers if visibility/height is wrong in any world.
4. Verify no UI clipping on smaller devices; adjust the art-backed HUD layout.
5. Preserve the architecture, using explicit art overrides; improve authored key poses and integrate frame-by-frame character animations rather than continuing to rely only on derived variants.
6. Keep existing gameplay functionality and original level data during the merge. Treat new art as experimental until game-tested.

### Useful previews (not gameplay screenshots)

- `TATO_animation_frames_preview.jpg`
- `TATO_world_parallax_assets_preview.jpg`

