# Claude Code — integrate, validate, then finish TATO!

Read `PRODUCTION_OVERHAUL_README.md` and `PRODUCTION_PATCH_MANIFEST.json` first. This is a modified complete project, not a design-only package. Compare it against the tagged original handoff. Import in Godot, run the complete automated suite and repair parser or runtime regressions before proceeding.

Priorities: (1) test and integrate new Tato animation assets and landing/attack state changes; (2) verify enemy/boss frame switching and attack collision; (3) verify new backgrounds, tiles, HUD plates and VFX in all six worlds; (4) replace interim deformation-based frames with genuinely hand-authored full character/enemy/boss animation cels; (5) replace vector-style distant backgrounds with coherent detailed illustrated world layers at the approved premium quality; (6) full campaign gameplay pacing and child playtesting with kid-friendly difficulty; (7) actual device, browser, GitHub Actions and release tests. Preserve one-active-power rule, 5 hearts, 12 powers, saves and stage progression. Keep a clear changelog. Do not claim tests pass if not run.

Do not confuse reference sheets in `docs/production/style_reference_only/` with production sprites. Gameplay assets are in `game/assets/`; integration code has already been changed.
