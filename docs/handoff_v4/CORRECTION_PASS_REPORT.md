# TATO! v0.4.0 — gameplay and presentation revision

November 11, 2026. Source implementation `7e46497ac3b903a3cb79f398ab4c023b83791a21`. Godot 4.7.2 stable.

This revision responds to the owner's playable-build feedback: small pads, low jump, sparse routes/enemies, fading run frames, bubbles rising before contact, weak attack effects and an oversized sky area in tall windows. This is an implemented review build. Owner approval, family playtests and the full production-art acceptance gates remain open.

## Changes to play

- A held jump now clears roughly 294 px, about 4.6 tiles, versus roughly 159 px previously. Taps also rise higher; air flaps are stronger. Coyote time is 0.16 s and jump buffering is 0.18 s.
- Bounce pads have new broad painted mushrooms/springs, a 144 px visual width and a 152 px landing region. Ground landing slivers are widened. Holding Jump gives a stronger pad launch.
- All 24 non-boss stages gain repeatable optional routes. The additions include 508 grass platforms, 59 moving rafts, 68 log steps, 132 bounce pads, 123 breakable crate obstacles, 984 route coins and 87 wing pickups. Ground traversal remains available in the added one-way-platform areas; crates can be jumped or attacked. These are procedural additions to authored base chunks; a human pacing pass still matters.
- Added 280 flying-enemy placements and 114 ground-enemy placements across those stages. Existing enemy types are reused; configured heights increased to 62–108 px. Boss heights remain 170–215 px, and every boss cel must still be larger than the largest regular-enemy cel in the automated ink-height check.
- Bubble Trap sends two bubbles forward at 480/525 px/s from a lower muzzle. They gently track a nearby enemy's height during the first 1.15 s, then drift upward. Their lifetime is 2.3 s. Actual hit tests cover a ground enemy 380 px away in both directions.
- A stage finishes when Tato crosses the active goal line, including a high spring/flap arc above the flag. Boss-linked goals still require activation. Fixed a shallow-water floating-state oscillation exposed by the new jump tuning.

## Art and interface

- Fixed the cause of alternating dark/color-faded run cels: the silhouette shader multiplied the sampled texture twice through Godot's fragment COLOR. A GPU comparison now renders masked and unmasked samples identically, with RGB difference 0.0. Background/terrain tint handling received the same correction.
- Removed Tato's damage-recovery opacity cycling; the goose stays opaque during running and recovery. Existing hit sound, movement recoil and recovery timing remain.
- Added three original RGBA sheets: 16 painted play props, 8 painted hazards/interactions, and 16 attack/impact frames. Broad mushrooms, springs, signs, wooden crates, question blocks, flag, bell, food bowl, grass islands, log platforms and clouds replace active low-resolution crops in those paths. Fire, bubble, ice and impact effects animate through four painted frames each. Some other power effects and special-form drawings still use older assets.
- HUD plates use a readable cream/plum palette and larger power/objective text, retaining five hearts, one active attack, cooldown readiness, coin/note counters, Pause, Notebook and Map. A consistent Tato portrait replaces the mismatched portrait crop.
- Keeps the game composition at 16:9 in tall/wide windows rather than expanding the world to fill excess height. Letterboxing prevents the large empty-sky layout in the owner's tall-window screenshots. Buttons and touch coordinates are verified after resizing.

## Verification

- Full source checks: **132 script/scene/resource files, zero problems; 47 tests passed, zero failed**. Includes robot traversal to all 24 non-boss goals, six boss checks, movement, swimming, saves and interface tests. See `QA_CORRECTIONS/v04/final/`.
- GPU shader probe: masked/unmasked RGB difference 0.0, retained in `shader_color.log`.
- Prop-region authoring regenerates the shipped JSON byte-for-byte without altering PNGs. Campaign regeneration in an isolated authoring tree reproduces every shipped level exactly; the base generator now reapplies the v0.4 routes.
- Actual Godot screenshots/video and exported-build smoke results are under `QA_CORRECTIONS/v04/`. Browser checks use desktop keyboard/mouse, a simulated 844×390 touch viewport and the owner's 1043×959 tall-window size. A standalone Linux run loads its embedded exported resources, without the source project's --path.
- Web and Linux archives are built from this revision with matching 4.7.2 export templates. Nothing has been published to GitHub/public hosting; files are delivered privately to the owner's OneDrive folder.

The full tests intentionally exercise invalid-save recovery, so JSON diagnostics appear. Known engine shutdown ObjectDB/resource-retention warnings remain. Native software rendering reports unsupported V-Sync. Software Chromium in this cloud machine is slow; these are functional checks, not physical-device performance certification.

## Handoff and remaining work

All v0.3 animation fixes are retained: 236 active production cels, including 112 added cels across all 28 characters; tight regions, anchors and masks; stable Rock Golem scale; the corrected Castle Golem with one face and a closed torso window. The earlier normalized pose audits are historical v0.3 evidence, not v0.4 gameplay-size proofs.

Continue with owner review of the actual v0.4 gameplay, then human stage pacing, difficulty/reward tuning and a terrain-edge/variation pass. Some terrain repetition, baseline art and power acting remain. Meet the original per-state animation requirements (eight aggregate enemy/boss cels are not eight per action), verify physical controllers/mobile/audio and low-end performance, and build/test Windows/macOS before release. The added encounters have automated reachability coverage, but that does not establish that every encounter is fun or family-balanced.

From `PROJECT/`, set `GODOT` to the 4.7.2 standard binary and run `bash tools/check.sh`, `bash tools/build.sh web`, or `bash tools/build.sh linux`. `python3 tools/build_levels.py` regenerates base stages plus the new routes. To edit base route geometry, edit the chunk generator; to retune the added playground modules, edit `tools/enrich_levels.py`. `tools/art/prepare_play_props.py` reads the PNGs and regenerates prop-region JSON (Pillow/numpy/scipy); the PNGs stay intact.
