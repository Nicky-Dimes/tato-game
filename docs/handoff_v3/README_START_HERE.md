# TATO! — corrected source handoff, v0.3.0

Updated November 11, 2026. Godot **4.7.2 stable**, GDScript, Compatibility renderer.

Read **CORRECTION_PASS_REPORT.md** first. This package contains actual revised game source, integrated art, animation atlases, gameplay interface, build/test automation, real engine captures and QA logs. It is a working review build; the original production art/release acceptance gates are still open.

## Start

1. Open `PROJECT/game/project.godot` in Godot 4.7.2.
2. From `PROJECT/`, set `GODOT=/path/to/Godot_v4.7.2-stable_linux.x86_64` and run `bash tools/check.sh`.
3. Inspect `QA_CORRECTIONS/final/` and `QA_CORRECTIONS/browser_qa.json` for measured results.
4. Review `QA_CORRECTIONS/frames_*.png`: these are **actual engine atlas audits at normalized display sizes**, not gameplay scale. The four additions are marked NEW.
5. Review `QA_CORRECTIONS/boss_scale_*.png` for **actual gameplay size**. The QA flag adds one ordinary Rock Golem to each boss arena for comparison; normal campaign data is unchanged.
6. Review `QA_CORRECTIONS/gameplay.mp4`, `final_gameplay.png` and `world_1.png` through `world_6.png` for actual Godot output. See manifests for automated inputs and capture timing.

## Concrete changes

- Tato remains a white gosling with two wings and two webbed feet.
- **236 production cels:** Tato 20, 21 regular enemies × 8, six bosses × 8. The owner's four-extra-frames request added **112 cels across all 28 characters**.
- Tight atlas regions, measured scale and foot anchors prevent neighboring sprite fragments and the previously observed Rock Golem shrinkage.
- Regular enemy configured heights are **46–86 px**; bosses are **170–215 px**. A regression test checks actual ink-height scaling in every boss cel and the Rock Golem's eight cels.
- Independent original far scenery for all six worlds, separate foliage/cloud/sky planes, new terrain material textures, and no fixed screenshot-derived foreground strip.
- Functional HUD with five hearts, one power, real cooldown readiness, coins/notes/keys, stage objectives and progress, Pause, Notebook and Map controls. Keyboard/gamepad prompts update with bindings; touch pause uses the same button.
- Fredoka is now included from official upstream with its SIL OFL license. The old missing-font blocker is resolved.
- Test checks isolate saves/settings, enforce the engine version, retain logs and reject incomplete runs. Builds fail on import/export errors. GitHub workflow download/template paths are repaired; remote workflows have not been run here.

## Scope still open

The older specifications remain quality targets. **Eight aggregate enemy/boss cels are not eight cels per action.** Tato's 20 shared production cels do not meet every per-state minimum in `CHARACTER_AND_ACTION_ANIMATIONS.md`. Some special-form animations, props, pickups and VFX retain baseline art. Terrain still uses the original autotile geometry with a revised material, rather than a complete new corner/slope atlas. Physical device/controller testing, family playtests, Windows/macOS exports and final owner visual approval remain pending.

The approved illustration remains `REFERENCE/01_OFFICIAL_TARGET_GAMEPLAY_GOOSE.jpeg`. It is a target, not a gameplay capture. Nothing has been published to GitHub or public hosting.

Historical baseline reports in `QA_LOGS/` and older `PROJECT/*.md` describe earlier revisions. Updated backlog rows distinguish implementation from remaining production work.

Separate playable archives: `TATO_Web_Playable.zip` and `TATO_Linux_Playable.zip`. Web must be served over HTTP(S); a local Python web-server command is included in its archive.
