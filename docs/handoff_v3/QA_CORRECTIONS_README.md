# Evidence guide

`final/`: final source import, resource, art and full test logs. Runtime save/cache folders are intentionally omitted from the archive.

`browser_qa.json` and `web_*.png`: desktop Chromium and a simulated 844×390 touch viewport. `?fps=1` exposes diagnostic overlay/telemetry only for the smoke test. Software SwiftShader was used; these are functional checks, not physical phone performance certification.

`frames_*.png`: actual engine pose audits with normalized row heights. They demonstrate isolation/anchors/cels, not gameplay enemy/boss size. NEW identifies the four added cels.

`boss_scale_*.png`: actual boss arenas, with a QA-spawned standard 86px Rock Golem beside Tato and the boss. `boss_scale_manifest.json` records flags. This adds no enemies to campaign stage files.

`world_*.png`: real six-world engine captures with automated stationary attack input, taken before the last added-cel/atlas cleanup; world art and gameplay HUD are the same, but inspect latest frame audits for final character framing. `capture_manifest.json` records stage/timing.

`final_gameplay.png`, `gameplay.mp4`: Godot Movie Maker capture from W1-L1, automated move_right/attack, 181 frames at30fps. Video is actual engine output, not image-generation animation. Some new body framing was refined after this recording; final pose audits and boss-scale captures show the final atlas regions.

Baseline QA logs remain historical. The first sandbox test attempt lacked a writable home data directory and failed saves; tests now isolate saves/config/cache and rerun cleanly. Known corrupt-save-test diagnostics and engine shutdown resource warnings are retained and explained in CORRECTION_PASS_REPORT.md.
