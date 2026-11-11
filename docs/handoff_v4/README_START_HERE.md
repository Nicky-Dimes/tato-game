# TATO! v0.4.0 — playable gameplay revision

Open `PROJECT/game/project.godot` in Godot **4.7.2 stable**. Read `CORRECTION_PASS_REPORT.md` for the current implementation and limits; `CLAUDE_START_PROMPT.md` is the updated continuation prompt.

This is the revised build following the owner's hands-on feedback: much higher jumps, broad bounce pads and landings, populated platform routes, larger/more frequent enemies including flyers, forward-guided bubbles, stable opaque Tato colors, new painted props/attack effects, readable cream HUD and consistent 16:9 framing.

From `PROJECT/`, set `GODOT=/path/to/Godot_v4.7.2-stable_linux.x86_64` and run `bash tools/check.sh`. The current evidence is **QA_CORRECTIONS/v04/**: 47 passing tests, 132 resources with zero problems, exact shader-color comparison, real game screenshots/video and exported-build smoke results. Older evidence elsewhere in QA_CORRECTIONS is retained as history.

The three current archives are `TATO_v04_Claude_Handoff.zip`, `TATO_v04_Web_Playable.zip` and `TATO_v04_Linux_Playable.zip`. Web must run through HTTP(S); the playable ZIP includes the command. The handoff contains source and review evidence, without engine binaries, export templates or runtime caches.

All 112 additional character cels and the Rock Golem/Castle Golem fixes are preserved. Normal enemies now have configured heights of 62–108 px; bosses remain 170–215 px. The pose audits normalize sizes for comparison and do not show gameplay scale.

Owner art/fun approval, a human pacing pass over all 30 stages, full per-state animation targets, remaining art/terrain/power polish and physical-device/controller/audio/performance verification are still pending. The illustration in REFERENCE/01_OFFICIAL_TARGET_GAMEPLAY_GOOSE.jpeg is a quality target, not a gameplay screenshot. Nothing has been publicly published.
