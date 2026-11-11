# Production Art — Source Files, Exports and Godot Integration

**Production target:** `REFERENCE/01_OFFICIAL_TARGET_GAMEPLAY_GOOSE.jpeg`. It is a complete illustration, NOT a sprite atlas or a screenshot from the game. Art needs to be independently authored as its own game-ready images. Tato is a **gosling**—not a puppy, duck puppy hybrid or person.

## Non-negotiable look

Premium whimsical hand-painted / cel-shaded 2D chibi game art: bright sunny colors with warm highlights and cool lavender/navy shadows, purposeful dark plum outlines, varied rock shape/lighting, lively foliage, softly dimensional highlights, layered painterly landscapes, clean readable silhouettes and no muddy blur. The character, enemies, scenery, VFX and interface must be drawn in the same visual language. Match the target's richness without copying a frame wholesale into a background.

**Hierarchy:** primary play lane readable first, enemies/attack telegraphs second, rewards/pickups third, decorative layers last. Reference art is dense but the actual game must preserve visibility of threats and hazards on 1280×720 desktop and phone-sized screens. Avoid visual clutter in collision zones.

## Export rulebook

| Asset | Production target | Delivery / restrictions |
|---|---|---|
| Tato frames | 192×192 px with feet anchored (96,168), right-facing, same scale | Transparent RGBA PNGs, consistent padding, no cast shadows baked into body sprite. More source resolution may be maintained separately. |
| Enemy frames | Same logical sprite canvas and ground/flight anchor per enemy; not every enemy same canvas | Independent PNG cels or validated atlas; unique idle, move, attack, hurt, defeat; no label or colored sheet background fragments. |
| Boss frames | Larger stable shared canvas, attack range and anchors documented | Unique attack windups, effects and defeat frames; no background fused into sprite. |
| Food and pickups | Designed at gameplay display size; legible 24–64px on screen | Isolated transparent art, shadow on independent FX layer if necessary. |
| Props and interactables | True independent image sets, not screenshots | Separate idle/activate/break/collected frames; standardized origin and sprite sizes in accompanying manifest. |
| Terrain | Work on exact engine cell/atlas layout; visible game cells are 64×64 world pixels | Seamless top/side/bottom/inner/outer corners, slope transitions, cliffs, rock fill; do not scale whole concept screenshots into tiles. |
| Parallax | Original wide **sky / far landscape / mid landscape / near decorative / optional foreground** plates | Sky and far layers may be opaque; others RGBA; independent art without HUD, coins, powerups, enemies, or question blocks. Wrap seams invisible at repeated x; preserve distant/near focus. |
| HUD / menus | Independent scaled 9-slice panels and icons; text live in Godot | Legible text, correct heart count, single active power badge, coin/note counters, pause, touch controls. Avoid baked numeric counts. |
| Attack VFX | Each food visually distinct, strong action/hit silhouette | Projectile, trail, cast flash, contact impact and disappearance as separate images/cels; prefer additive FX and restrained motion. |

**File formats:** PNG RGBA for runtime assets, SVG/vector source or layered source files kept with proper editability. Do not flatten animation or gameplay objects into scenery. Keep originals organized under `PROJECT/assets/production_source/` if used; imported runtime PNGs in the proper existing `game/assets` paths. Save documented source licenses and generator provenance. Never distribute a font file separately as a deliverable outside the licensed project.

## Exact Godot integration map

- `PROJECT/game/scripts/core/art.gd`: existing art lookup; inspect before adding resources, and preserve override conventions.
- `PROJECT/game/assets/sprites/override/`: existing override approach; verify exact naming convention by reading `art.gd` and `PROJECT/docs/ART_PIPELINE.md`.
- `PROJECT/game/scripts/level/backdrop.gd`: paints sky + `Parallax2D`, currently a key cause of stretched/cropped backdrops. Replace per-world textures carefully; preserve object/camera coordinates and repeating behavior.
- `PROJECT/game/assets/sprites/bg/{theme}_{clouds,far,mid}.png` (themes grassland, orchard, candy, icy, windy, castle; special nest/picnic): current background material slots. Add appropriately sourced new layers rather than stretching one photograph/illustration.
- `PROJECT/game/scripts/level/terrain.gd`: built runtime `TileMapLayer`, shader mask and merged physics collision. **Do not modify collision just to improve visuals.**
- `PROJECT/game/assets/tiles/tiles_{theme}.png` / `.svg`: terrain atlas art. Confirm atlas grid and shader material before regenerating.
- `PROJECT/game/assets/tiles/rock_{theme}.png`, `rock_worldspace.gdshader`, `rock_mask_{theme}.png`: existing world-space rock system. Replace/preserve as appropriate; remove repetitive wallpaper effect without expensive high-frequency shaders.
- `PROJECT/game/scripts/player/tato_visual.gd`: state-to-PNG animation table; keep 192×192 foot anchor and right-facing frames.
- `PROJECT/game/scripts/enemies/enemy.gd` and `.../bosses/boss.gd`: enemy and boss display/animation logic; add genuine animated frames instead of only procedural wiggle.
- `PROJECT/game/scripts/components/projectile.gd`, `PROJECT/game/scripts/core/fx.gd`: projectile and FX integration; replace generic drawn shapes with food-specific transparent art where needed, retain collision and damage behavior.
- `PROJECT/game/scripts/ui/hud.gd`, UI image folder and `PROJECT/game/scripts/ui/ui_theme.gd`: visually upgrade without breaking settings and touch controls.

## Required integration sequence per asset family

1. Author from the approved goose reference, no UI or gameplay baked into scenery.
2. Export independent images and assign descriptive stable filenames; create contact sheets with frame ID/pose order.
3. Check transparent alpha matte, duplicate limbs, consistent body/feet anchor, sprite size, and edge padding at 100%, 200% and on dark/light backgrounds.
4. Import Godot using **4.7.2 `--headless --import`**; let Godot create `.import` files. Never hand-edit `.uid` or `.import` files.
5. Connect to the existing live scene and gameplay state—not just to a concept preview.
6. Capture at least two real engine screenshots for the stage plus in-motion frame sequences; test at 1280×720 and narrow/mobile viewport.
7. Compare beside `REFERENCE/01...`. Reject the art if it looks like a sticker, blurry crop, out-of-scale prop, repeating rectangle, mismatched shadow or procedural placeholder.
8. Run resource/automated tests, then record the integrated filenames and screenshot evidence in the backlog.

## Specific rejection tests

- **Wrong mascot:** even a beautiful puppy illustration must be rejected. Tato is the approved baby goose.
- **Mirroring scenic paintings as a seam solution:** causes obvious duplicate bridge/tree patterns; produce proper repeating plates instead.
- **Baked objects:** coins, question blocks, power bowls, signs, enemies and HUD must not appear in parallax scenery.
- **Huge blur:** background layers must be painted at their displayed resolution; don't upscale small board cutouts into full screen.
- **Ground gap:** avoid large monotonous brown rock bands; add shaped strata, light variation and deep near-foreground structure without blocking players.
- **Pretty but nonfunctional:** in-game physics/visibility/legibility always outrank concept screenshot composition.

## Visual acceptance checklist (owner-facing)

- [ ] Fresh Godot screenshot looks substantially similar in palette, finish, detail density and character integration to reference.
- [ ] World has four or more separable, independently useful depth layers where appropriate.
- [ ] No repeated pattern, upscaled blur, hard seam, or floating cutout edges.
- [ ] Ground and floating platforms have believable transitions and cohesive material/shading.
- [ ] Characters and enemies carry matching outlines, shadows and light direction.
- [ ] HUD reads instantly at desktop and mobile sizes, shows only real game state.
- [ ] Attack actions clearly read from casting to collision and defeat.
- [ ] User explicitly approves an actual Godot visual sample before style is called finalized.
