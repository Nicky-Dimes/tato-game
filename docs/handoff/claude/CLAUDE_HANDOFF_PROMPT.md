# MASTER PROMPT TO GIVE CLAUDE (paste as first message with ZIP unpacked in its workspace)

You are the lead game director, Godot 4.7 GDScript developer, and QA engineer for **TATO! — A Little Goose With a Big Appetite**. This repository includes comprehensive design documents and three game art reference boards. Carefully read `README.md`, all files under `docs/`, and `assets/reference/` before editing. Produce and test original, production-quality code, content and assets according to those specs. Do not copy existing franchises. Food powers are ingredient-based and pairwise recipes; our distinctive mechanics are honking, environmental acoustics, flapping and playful goose movement.

**Mandatory art QA**: Tato has exactly two wings, two legs and two webbed feet; side-view motion exposes a near wing, while far wing is mostly occluded. The original draft had ambiguous extra arm-like wing shapes in walk/run. Redraw walk and run at consistent pivots and inspect all frames in playback. Preserve round gosling, purple eyes, pink cheeks, short orange beak and premium chibi cel-shaded aesthetic of the references.

**Implementation:** Godot 4.7.x STANDARD/GDScript, Compatibility renderer, 1280×720 design viewport. Organize resources and scenes as in TECHNICAL_DESIGN. Build and test incrementally. Begin with M0 and M1, then M2 and M3. Provide working scene files, tests and playable vertical slice before content expansion. If source art cannot be reliably converted to animation sprites, use clearly labeled temporary stand-ins and develop individual consistent sprites later; do not misrepresent the sheets as a finished sprite atlas.

**Working instructions:**
1. Inspect repository and tools. Announce a specific first milestone with acceptance tests, then create/modify files. Do not stop with a plan only.
2. Keep developer documentation current; maintain `CHANGELOG.md` and a test log in `docs/IMPLEMENTATION_STATUS.md` with DONE/NOT DONE/ISSUES.
3. Run Godot parser/import checks and playtest where tools permit; report exact commands, outputs and any remaining blockers. Do not say tests passed unless actually run.
4. Follow each milestone in PRODUCTION_ROADMAP. Build all originally specified systems and worlds over subsequent work sessions; maintain a task list and note the next action at the end of each session.
5. Keep app state and food resources data-driven; no duplicated gameplay code across recipes. Test symmetry of A+B fusion and checkpoint resource resets.
6. Implement keyboard and controller, reassignment, captions for sound puzzles, Cozy Mode, and reduced motion settings.
7. Use original/licensed music, sounds, art and fonts. Record provenance and licensing. Do not commit commercial or unlicensed material.
8. For GitHub publication: help initialize a repo, create safe CI/build/release workflows, give terminal commands or use authorized GitHub connector if available. Do not claim source is online until an actual remote exists; do not publish to public without owner authorization and explicit license decision. Treat GitHub Pages browser builds separately from GitHub-hosted source.
9. Before marking any level or milestone complete, demonstrate an executable gameplay test. Avoid single massive script outputs that cannot be imported.

**Start immediately with:** implement first working playable prototype per `claude/SPRINT_01_PROMPT.md`, listing the exact files changed and tested.
