# Correction pass — TATO! v0.3.0

November 11, 2026. Source implementation commit: `f3a89ae9456b59038984e334ff2ae4fbcfaf9b52`. Baseline: `72ae126`.

## Result

This is a concrete source/art/interface correction pass for the Claude handoff, not a finished-game release certificate. The 30-stage campaign, 12 single-slot powers, 21 enemy types, six bosses, five hearts, checkpoints, Cozy Mode, saves and menu systems are preserved.

The owner's four-additional-frames request is implemented for all 28 characters: **112 additional cels, 236 active production cels total**. Tato has20; regular enemies and bosses each have8. New movement, attack, windup and hit/recovery poses are connected to actual state. Legacy special-form drawings remain for some powers.

The reported Rock Golem shrinkage and chopped neighboring fragments were real shared-loader issues. Tight connected silhouette regions, measured ink-height normalization, per-cel foot anchors and runtime silhouette masks now isolate each sprite. The raw source PNGs remain unchanged; the mask/region metadata is technical import data. New regression checks keep all Rock Golem cels within12% of its86px target and require every boss cel to exceed the largest regular-enemy cel.

The Castle Golem's two attack poses no longer gain an extra mouth. Its dedicated corrected8-cel atlas uses one head face, while the torso window stays closed and divided by crossbars. The old Chef rows in the shared boss study sheets are superseded and never sampled at runtime. There are236 active cels, plus8 superseded source-study cels retained for provenance.

Pose audit sheets normalize character sizes to compare frames. **Gameplay regular enemies are46–86px tall and bosses170–215px tall** (about2–4.7times normal-enemy height). `boss_scale_1.png` through `boss_scale_6.png` show actual arenas, Tato and a QA-spawned ordinary86px Rock Golem; no campaign stage files were changed for these comparisons.

## Art and interface

- Original independent wide far scenery for all six worlds; separate mid foliage, clouds and sky. Removed the screen-fixed screenshot-derived meadow foreground and mirrored-seam fallback.
- New world material textures with shader edge blending; preserved terrain collision and autotile geometry. The texture still visibly repeats in places; a full bespoke terrain atlas remains a production task.
- HUD: five hearts, one named active attack, true cooldown readiness, coin/note/key counts, stage objective and spatial progress, Pause, Notebook and Map buttons. New food replaces the active slot. Remapped/device prompts update, and touch uses the same functional pause control.
- Font restored from official Google Fonts under the included SIL OFL. Fixed map-card spacing, menus use the new landscape art, and decoration now renders behind player/enemies.
- Ground rushes have a short warning. Reduced Motion preserves gameplay-critical attack poses; reduced-flash boss warnings avoid flashing.

## Verification actually run

- Godot `4.7.2.stable.official.ed1daf0bf`.
- **128 script/scene/resource files loaded, zero problems.**
- **43 tests passed, zero failed** on the final source; includes24 non-boss robot goals, six bosses and new asset/scale/interface regressions. See `QA_CORRECTIONS/final/`.
- Asset validator:236 active cels, distinct source frame hashes, valid bounds/anchors and valid compressed silhouette masks.
- Real Godot audit renders for all236 cels, six-world gameplay captures, six boss scale comparisons and a6-second engine Movie Maker clip.
- Web and Linux exports built using matching4.7.2 templates. Desktop Chromium keyboard/mouse and an844×390 simulated touch viewport exercised actual gameplay, Pause/Notebook/Map flow. The final browser report also loads the corrected Castle Golem. These are software-rendered functional checks, not hardware performance certification.
- Test and build scripts reject wrong engine versions, failed imports/exports, missing test summaries and missing outputs; save/settings/cache test data are isolated from the owner's profile. GitHub workflow URLs and web template flattening are corrected. Remote CI and publishing have not been run.

## Remaining production work

The original per-state minimums still apply:20 shared Tato cels and8 total cels per enemy/boss do not satisfy all full-action targets. More individual power acting/VFX, special-form animation, props/interactables, terrain/corner/slope art and authored stage dressing remain. All30 stages still require human visual/pacing/playtesting, physical gamepad/mobile/audio checks, lower-end hardware performance work, Windows/macOS builds and owner visual approval. Nothing has been published.

The full test log intentionally contains corrupt-save JSON diagnostics and reports known engine shutdown resource-retention warnings. Native software rendering reports unsupported V-Sync. These logs are preserved; passing functional tests does not imply a warning-free commercial release. Software Chromium has limited frame rate in this cloud VM; do not infer physical-device performance from it.

## Reproduce

From `PROJECT/`, set `GODOT` to the4.7.2 standard binary:

```bash
bash tools/check.sh
bash tools/build.sh web
bash tools/build.sh linux
bash tools/capture.sh W1-L1 /absolute/path/gameplay.png --at=22 --power=FIRE_PEPPER
bash tools/capture.sh W6-B /absolute/path/boss.png --at=15 --scale-proof --shot-after=80
```

`tools/capture.sh` uses a real display or Xvfb. `GODOT --path game res://tools/AnimationAudit.tscn -- --out=/absolute/path/QA` renders the audit pages. `tools/validate_art.py` needs only Python3. Optional `tools/art/analyse_animation.py` authoring uses Pillow/numpy/scipy; it reads PNGs and regenerates tight regions, foot anchors and masks without modifying the PNGs.

See `ART_PROVENANCE.json`, `ASSET_INVENTORY.json`, `PRODUCTION_BACKLOG.csv` and `QA_CORRECTIONS/README.md`. The source archive omits engines, export templates and caches; playable Web/Linux archives are supplied separately.
