> **v0.3.0 correction update:** Read `CORRECTION_PASS_REPORT.md` and `README_START_HERE.md` for the current source, captures and verification. Fredoka is now included. The baseline observations below are preserved as historical evidence, not current completion claims.

# QA, Build, Review and GitHub Release Gates

## Exact engine and baseline commands

Use **Godot 4.7.2 standard** GDScript Compatibility, not .NET or another 4.x. On Linux:

```bash
# From the PROJECT/ folder
export GODOT=/path/to/Godot_v4.7.2-stable_linux.x86_64
chmod +x "$GODOT"
./tools/check.sh               # import, 123 script/scene/resource check, all 39 tests
./tools/check.sh quick         # import + resource check + 15 unit tests

# Explicit individual commands
"$GODOT" --headless --path game --import
"$GODOT" --headless --path game res://tools/CheckScripts.tscn
"$GODOT" --headless --fixed-fps 60 --path game res://tests/TestRunner.tscn
"$GODOT" --headless --fixed-fps 60 --path game res://tests/TestRunner.tscn -- --group=integration
"$GODOT" --headless --fixed-fps 60 --path game res://tests/TestRunner.tscn -- --group=smoke --stage=W1
```

Headless validates logic, not visuals. For actual screenshots (Linux virtual display with `xvfb-run` and software OpenGL):

```bash
mkdir -p QA_OUTPUT
GODOT_SILENCE_ROOT_WARNING=1 xvfb-run -a "$GODOT" --path game --rendering-driver opengl3 -- \
  --level=W1-L1 --at=22 \
  --shot=QA_OUTPUT/sunny_%d.png --shot-after=130 --shot-count=4 --shot-every=12 \
  --press=move_right,attack
```

Document the screenshot stage, frame, source commit and whether the input was automated. Do not show an image-generation concept mockup as if it came from the game.

## Fresh results included

- `QA_LOGS/01_import.log`: import exited successfully; emitted expected security warning when run as root.
- `QA_LOGS/02_resources.log`: **123 files checked, 0 problems**.
- `QA_LOGS/03_unit.log`: **15 passed, 0 failed**.
- `QA_LOGS/04_integration.log`: **23 passed, 0 failed**; exit-time resource warnings recorded.
- `QA_LOGS/05_full.log`: **39 passed, 0 failed**, took 47.3 seconds; robot logged goals for 24 non-boss campaign stages. The suite deliberately tests recovering a corrupt save and prints an expected JSON parse error during that test; shutdown also reports resource leak warnings. Test runner reports PASS regardless. Review warnings before public release.
- `QA_LOGS/06_capture.log`: real visual capture exited successfully; Linux sandbox lacks usable audio output (dummy audio fallback), and emits shutdown warnings.
- `REFERENCE/11_CURRENT_GODOT_RENDER.png` and `12_CURRENT_GODOT_ACTION.png`: fresh actual Godot frames.

**Interpretation:** The engineering test foundation is good. These checks DO NOT certify polished art, level entertainment, full boss playthroughs, browser exports, mobile behavior or copyright permissions.

## Per-asset / stage QA gates

- Render imported sprite alone on white, black and colorful background; inspect matte/halo and limb count.
- Run every animation as a full flipbook in Godot; no frame jumps, disappearing wings, sliding feet or impact timing errors.
- Each of 12 food powers must show cast, shot, contact/impact and proper state; single slot changes reliably.
- Every enemy and boss must visibly communicate attack, hit, invulnerability and defeat states.
- Terrain has no hard tile seams/repeated visible wallpaper effect, and decorative scenery cannot conceal hazards or player.
- Collision never diverges from animated moving platforms or bridge/hazard contact.
- Every stage can reach all intended collectibles and its goal; no gaps impossible for the actual character physics.
- Cozy Mode, captions, reduced motion, no-flash options, touch controls, controller remapping and saving still work after art changes.
- Capture actual game screenshots at 1280×720 and mobile portrait/landscape responsive test sizes. Test on representative lower-end hardware when available.

## Release and repository

A production-ready release requires all gates below, not just test counts.

1. Clean source branch and readable diffs, no vendor engine binaries or generated `.godot/` cache in Git. Retain `.import` metadata Godot generated but never hand-author UID files.
2. Complete asset rights/provenance review: the project uses owner-created/generated art boards, original audio and SIL OFL 1.1 Fredoka font; the owner must confirm any image-generation service's commercial terms and distribution rights.
3. Lint/import/script/resource check, 39 tests pass. Document and address unexpected engine/audio warnings on real target platforms.
4. Manual playthrough all 30 stages and bosses, touch/controller QA, several save/load cycles, device performance/memory checks.
5. Build from clean checkout with **matching Godot 4.7.2 export templates**. `PROJECT/tools/build.sh web`, then desktop targets per `PROJECT/docs/DEVELOPMENT.md`.
6. Test hosted web export in real browsers and on iPhone/iPad; check WebGL2 compatibility and sound unlock/user gesture; avoid relying on headless passing as proof.
7. Configure GitHub Actions from `PROJECT/.github/workflows/`, check artifacts, repository README, release notes, screenshots and licensing. No screenshots from concept art labelled gameplay.
8. Publish through the owner's GitHub account **only when access and approval are available**; never claim deployed without a real URL and a tested live build.
9. Obtain owner's approval that actual game visuals match `REFERENCE/01...`; a generated standalone concept is insufficient.

## Completion certificate template (do not prefill success)

```text
Commit / tag:
Godot version:
Date/time:
Asset production: [complete / not complete]
Full test output: [39/39 or details]
24 non-boss robot stages: [pass/fail]
6 boss fights manually verified: [yes/no]
All 30 stages visually reviewed: [yes/no]
Controls/Cozy/Reduced Motion/Accessibility checked: [yes/no]
Real web export tested in browser: [yes/no]
Desktop builds tested: [yes/no]
Image/font/audio rights reviewed: [yes/no]
Owner visual approval: [yes/no]
GitHub repo URL (only if created):
Public playable URL (only if deployed and tested):
Known unresolved issues:
```

## Verification of the exact font-excluded handoff copy

To avoid redistributing any font binaries, the downloadable handoff excludes `Fredoka.ttf` (see `FONT_DEPENDENCY.md`). A separate test of that *exact* copy produced:

- `QA_LOGS/07_packaged_import.log`: Godot resource import command exited successfully with no reported warning/error lines.
- `QA_LOGS/08_packaged_resources.log`: 123 checked files, zero problems.
- `QA_LOGS/10_packaged_unit.log`: 15/15 passed.
- `QA_LOGS/11_packaged_integration.log`: 23/23 passed.
- `QA_LOGS/09_packaged_full.log`: combined campaign run was interrupted/stalled partway through W4-L1 and **did not produce a final result**. The original source (before omitting the font) produced 39/39 in `05_full.log`. Re-run the full suite once the font is restored and your environment can complete it.
