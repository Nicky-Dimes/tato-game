# TATO! — Production Roadmap and Definition of Done

## Delivery principle
Do not attempt 30 levels in one giant implementation. Each phase delivers a playable, tested increment. Screenshots/concept sheets are not final animation sprites. No claim of “published” without actual repo URL and exported game verification.

### Milestone 0 — Repository and foundation
**Deliver:** bootable Godot 4.7 GDScript project; Git repo; readme; correct compatibility renderer; baseline testing harness; main menu and no missing scripts. Implement input mappings and 720p responsive window. **Pass:** `godot --headless --path game --editor --quit` exits successfully; game boots on target workstation; no errors.

### Milestone 1 — Playable movement prototype
**Deliver:** polished placeholder Tato with idle, walk, run, jump, flap, honk, eat; collision, camera, checkpoints, platform movement, hit feedback, temporary HUD. **Pass:** all movement conditions exercised in a test room; consistent 2-wing/2-leg silhouette, no extra arm; 60 FPS target; full keyboard/controller test.

### Milestone 2 — First food system
**Deliver:** FoodDefinition resources, two-pocket inventory, recipe resolver, Pepper, Bubbleberry, Steam Lift; charge management; visuals, audio placeholders and restart behavior. **Pass:** pairing works A+B and B+A; critical puzzle cannot soft-lock; UI signals update correctly.

### Milestone 3 — Vertical slice (public demo quality)
**Deliver:** World 1 levels 1-1/1-2/1-3, Puddle Puffer finale, first optional challenge, first Flavor Page, hub-lite, save/load, menu/settings, gameplay subtitles and assist mode. **Pass:** 20–40 minutes of continuous fun, no blockers, playtested by 3–5 people, three test sessions on the web build. Create v0.1 demo GitHub release.

### Milestone 4 — Expanded systems
**Deliver:** 12 base foods and 12 named recipes, interactable tag architecture, NPC dialogue, map, notebook, all HUD systems, cosmetics prototype, four enemy families. **Pass:** data-driven interactions; no magic strings in stages for core ingredient behavior; recipes accessible to tests.

### Milestone 5 — Campaign content
**Deliver:** Worlds 2–6 with 25 remaining stages including optional areas and bosses, 72 scraps, 36 pins, 24 secret dishes, complete story and ending, all required NPC scenes. **Pass:** zero mandatory soft locks; every item has achievable placement; game start-to-credits tested.

### Milestone 6 — Art and sound finalization
**Deliver:** consistent production sprite frames, backgrounds, interface icons, animation state transitions, original SFX and soundtrack, VFX and captions, credits. **Pass:** movement contact sheets inspected with limb-count checklist; no placeholder content; rights manifest complete.

### Milestone 7 — Quality and publishing
**Deliver:** controller and remap tests; localization-ready UI; color-blind cues, reduced-motion option; profile/save stability; performance profiling; Windows/macOS/Linux exports; single-threaded Godot web build verified on HTTPS and GitHub Pages or fallback host. **Pass:** CI validation, documentation, version tag, release notes, privacy statement (local-only saves unless changed), repository URL, publicly playable demo URL or download link verified.

## Definition of done — each issue
1. Code and art source committed to branch.
2. Scene manually tested; no debugger errors.
3. Automated tests added for gameplay logic where feasible.
4. Asset references licensed and attributed.
5. Animation anatomy verified (especially walk/run: exactly two wings, two feet).
6. No hardcoded dependency on one screen size or input device.
7. Acceptance criteria checked and issue closed with reproduction steps/screenshots.

## Risk register
- **Scope creep:** 6 worlds × 5 levels is a substantial game; focus on vertical slice before full content.
- **AI-generated sprite inconsistency:** redraw and rig sprites using consistent pivot/anatomy; image board cannot simply be sliced into flawless cycles.
- **Browser deployment:** Compatibility renderer and WebGL2 required; export behavior may vary by hosting/browser; single-threaded export first.
- **Licensing:** concept art does not grant rights to third-party sounds/music/fonts or user-distributed assets by inference.
- **Puzzle dead ends:** required foods must regenerate at checkpoints, reset switches and moving props.
- **Overlapping abilities:** central ability resolver with tags, not bespoke branch explosion.
- **Performance:** atlas, LOD-equivalent particle caps, texture budgets and browser profiling.

## Release checklist
- [ ] Repository name and visibility chosen by owner
- [ ] Licensing choice approved
- [ ] Art/audio attribution manifest signed off
- [ ] Engine pinned, export templates installed
- [ ] Godot editor headless import passes
- [ ] All automated smoke tests pass
- [ ] All six worlds played from start to finish
- [ ] Save and recovery tested after interruption
- [ ] No animation has extra appendages
- [ ] Accessibility defaults and remaps tested
- [ ] Web browser launch verified in supported browsers
- [ ] Desktop export launches without dev dependencies
- [ ] Release tag, notes, screenshot, credits published
- [ ] GitHub Pages URL actually loads a playable build (if selected)
