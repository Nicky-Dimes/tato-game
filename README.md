# TATO! — A Little Goose With a Big Appetite

**Production handoff / design package · v0.1 · 2026-11-10**

A bright, original 2D action-adventure puzzle-platformer starring Tato, a tiny fluffy goose whose magical meals change how Tato moves, explores, and interacts with the world.

> STATUS: **Comprehensive production specification, not a completed game.** The three art boards in `assets/reference/` are visual references, not animation atlases. The `game/` folder is a scaffold; Claude should implement the project according to this brief before release.

## First steps with Claude
1. Read `claude/CLAUDE_HANDOFF_PROMPT.md`, then `docs/GAME_DESIGN_DOCUMENT.md`, `docs/TECHNICAL_DESIGN.md`, and `docs/ART_ANIMATION_BIBLE.md`.
2. Use Godot 4.7.x **standard (GDScript)**, Compatibility renderer, with a 1280×720 logical viewport and 2D art. Target desktop first and browser second.
3. Implement the vertical slice described in `docs/PRODUCTION_ROADMAP.md`; do not claim the full game is complete until its acceptance tests pass.
4. Use original or correctly licensed art/audio; reference images require individual isolated production sprites, consistent pivots, and clean topology.
5. Keep gameplay systems data-driven. Run validation and test exports with the same Godot version used for development.

## Documents
- `docs/GAME_DESIGN_DOCUMENT.md` — story, mechanics, progression, foods, fusion recipes, worlds, enemies, bosses, puzzles, UI, accessibility.
- `docs/TECHNICAL_DESIGN.md` — architecture, input, physics, state machine, data schemas, save format, testing, performance and publishing.
- `docs/ART_ANIMATION_BIBLE.md` — approved visual direction, strict two-wing rule, animation frame counts and asset production pipeline.
- `docs/CONTENT_MATRIX.csv` — production backlog, levels and story beats.
- `docs/PRODUCTION_ROADMAP.md` — staged Claude tasks, definition of done, release criteria.
- `claude/CLAUDE_HANDOFF_PROMPT.md` — copy/paste master implementation assignment.
- `claude/SPRINT_01_PROMPT.md` — first actionable implementation request.

## Creative guardrails
- Do **not** copy Kirby characters, art, music, enemy designs, character transformations, set-pieces, dialogue, or stage layouts. Food-based abilities are a broad mechanic; distinguish TATO! through ingredient pairing, goose honk acoustics, environmental recipes, flavor interactions, and branching traversal.
- Tato has **exactly two wings and two legs**. In side view, one near wing and one far wing (far wing partly occluded), never an additional arm-like limb. Walk and run must have stable anatomy and clearly alternating webbed-foot contact.
- Cute first: the wide-eyed, round, pink-cheeked gosling pictured on the approved concept sheet is the baseline, not an enormous amorphous blob.
- No generated graphic is automatically a collision-ready sprite or a commercially licensed sound. Maintain source and rights manifest.

## Repository readiness
The package is designed to become a GitHub repository. Initialize it, implement the Godot project, test, and then publish. GitHub Pages can host a compatible **single-threaded** Godot web build; verify the current exporter and browser support. Export preset/templates and GitHub Pages settings must be configured by the developer. Avoid committing generated large export binaries to source control unnecessarily.

## Attribution & license
Art references originated in user-directed concept-generation sessions. Do not assume rights for third-party assets introduced later. **No public project license has been selected**; keep repository private until the owner picks licensing and confirms asset rights.
