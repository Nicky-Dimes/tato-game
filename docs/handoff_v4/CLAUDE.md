> Current source is v0.4.0. Read the root README_START_HERE.md, CORRECTION_PASS_REPORT.md and QA_CORRECTIONS/v04/ first. Preserve the higher jump, wide pads/routes, correct shader tinting and guided bubbles. Current suite: 47 tests; original 39-test references below are historical.

# CLAUDE.md — TATO! Lead Development Agent

**Read `README_START_HERE.md` and `MASTER_BUILD_DIRECTIVE.md` before editing.** This repository is a **working game**, not a blank project. The owner has rejected previous low-quality decorative passes. Do not reset the game or deliver more concept-only artwork.

## Objective

Finish **TATO! — A Little Goose With a Big Appetite** as a beautiful, complete, family-friendly original action-platformer. Honor `REFERENCE/01_OFFICIAL_TARGET_GAMEPLAY_GOOSE.jpeg`: the visual quality and Tato's goose identity are nonnegotiable. Produce and integrate real assets into `PROJECT/game/`. Maintain original gameplay systems and expand them without regressing accessibility, playability or saves.

## Source-of-truth order

1. Latest explicit owner requests, including the approved goose screenshot in `REFERENCE/01...`.
2. This root-level `CLAUDE.md`, `MASTER_BUILD_DIRECTIVE.md`, production specs, backlog and QA gates.
3. Actual current code and data in `PROJECT/game/` (for implementation reality).
4. Existing `PROJECT/docs/` and original art sheets for details.
5. Any older handoff/status text is historical and may be stale.

## Behavior rules

- **Act on the actual files.** Draw/export individually usable art, import, integrate, test, capture in-engine output. No more iteration consisting only of a mockup or a prompt.
- Preserve a clean Git baseline first; work on a feature branch, commit each independently testable milestone, and keep changelogs.
- Tato has exactly **2 wings, 2 feet**, baby goose features. Never replace him with a dog/puppy. Do not hallucinate an approved design change.
- Maintain **12 single-slot food powers, 21 enemy types, six bosses, 30 stages**, and existing save/control systems. If improving gameplay, be additive and safe.
- No mandatory food mixing; a one-time Flavor Burst when replacing a power is okay. Each active food power needs a useful attack.
- Make enemies plentiful, animated, distinct and fair; prioritize child-friendly readability over difficulty spikes.
- Check newly generated sprites for identical anatomy, transparent edges, consistent silhouette, correct anchor, no pasted labels/background fragments, no uncanny extra limbs.
- Avoid stretching small reference-art crops to fill a huge scene. Generate separate original high-resolution parallax plates/terrain/props, export with correct alpha, and animate where appropriate.
- Do not overwrite the approved reference images. Never silently regenerate existing asset sheets with generators and discard new production art.
- Every milestone: import -> script/resource check -> unit/integration -> gameplay screenshot -> review against approved target; run all 47 and stage smoke checks before release.
- Never claim an automated test has passed if it has not run. Separate test success from visual approval. Report blockers and remaining scope honestly.
- Work progressively across *all six worlds*, not just Sunny Meadows. Full campaign, boss levels and extras required. Do not declare done after one sprint.
- Respect code/graphics architecture and older mobile hardware. Keep draw calls, animation memory and texture atlas size appropriate. Retain Reduced Motion, Cozy Mode and captions.
- Publishing to an owner's GitHub repo is conditional on actual account access and appropriate approval. Do not fabricate repository URLs, CI status or successful deployment.

## First work session

1. Inspect `REFERENCE/00_READ_FIRST_VISUAL_COMPARISON.jpg` and current game screenshot.
2. Open `PROJECT/game/project.godot` with Godot 4.7.2 and run `PROJECT/tools/check.sh`.
3. Read `PROJECT/scripts/level/backdrop.gd` **via actual path** `PROJECT/game/scripts/level/backdrop.gd`, `terrain.gd`, `tato_visual.gd`, `PROJECT/docs/ART_PIPELINE.md` and `ART_PRODUCTION_AND_INTEGRATION.md`.
4. Make **genuine production assets** for Sunny Meadows: clean parallax without HUD/coins/enemies, seamless detailed ground, grass edge, separate props; integrate and capture Godot proof. No screenshot-derived scenic wallpaper.
5. Resolve blockers, gain owner visual approval using actual in-engine capture, then expand the pipeline to W2–W6 while finishing enemy/character animation and UI.
6. Maintain `PRODUCTION_BACKLOG.csv` with honest statuses, including screenshot evidence for completed items.

## Commands

From `PROJECT/`:

```bash
export GODOT=/path/to/Godot_v4.7.2-stable_linux.x86_64
./tools/check.sh                # imports, checks resources, 39 tests
./tools/check.sh quick          # 15 unit tests
$GODOT --path game -- --level=W1-L1
$GODOT --path game -- --level=W1-L1 --shot=/tmp/tato_%d.png --shot-after=150 --shot-count=4 --shot-every=8 --press=move_right,attack
```

See `QA_BUILD_AND_RELEASE.md` for Linux screenshot dependencies and release gates.

## Corrected v0.3.0 continuation

Read `CORRECTION_PASS_REPORT.md` before using baseline instructions. Source PNG atlases, tight regions, normalized foot anchors, restored font and the four-extra-cels-per-character request are implemented. Preserve these changes. The original per-state art minimums and release gates remain production targets, not completed claims.
