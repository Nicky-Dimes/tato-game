# TATO! Technical Architecture & Engineering Requirements

## Technology
**Engine:** Godot 4.7.x standard build (GDScript), pinned to 4.7.2 if confirmed available on developer machine; renderer `gl_compatibility` for WebGL 2.0 web export. **Viewport:** 1280×720 reference, stretch canvas/items via testing; scalable window and safe-area UI for web/mobile. **Source:** Git; normalize text LF and store art masters separately if large. **Avoid C#** for Godot 4 web target. Prefer single-threaded web export compatible with static hosting; test cross-origin requirements if enabling threads. Official export docs: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html

## File layout to implement
```
game/
  project.godot
  autoload/ GameState.gd SaveService.gd AudioService.gd Accessibility.gd
  data/ foods/*.tres recipes/*.tres levels/*.tres localization/*.csv
  scenes/ boot/Main.tscn menus/MainMenu.tscn hub/Hub.tscn
          player/Tato.tscn player/Tato.gd
          levels/World01/Stage01.tscn ...
          props/FoodPickup.tscn Props/Interactable.tscn
          puzzles/PressurePlate.tscn ...
          ui/HUD.tscn RecipeJournal.tscn PauseMenu.tscn
          enemies/CrumbMite.tscn ... bosses/...
  scripts/ player/ components/ food/ puzzle/ dialogue/ save/ accessibility/
  assets/ sprites/ vfx/ tiles/ ui/ audio/ fonts/
  tests/ unit/ integration/ smoke/
```

## Domain model
- `FoodDefinition` resource: stable ID, display name, icon, tint, initial charges, AbilityStrategy script/resource, default behavior tags, unlock region.
- `RecipeDefinition`: canonical `food_a`, `food_b` sorted by ID; result ID, ability strategy, resource cost, duration, cooldown, VFX, environment tags, discovery flag.
- `FoodInventory`: two `FoodSlot`s; emits `slot_changed`, `recipe_available`, `honk_charge_changed` signals. Cannot equip null by side effect; UI prompts replacement.
- `PlayerController`: intent-based move/jump, finite state machine (Idle/Walk/Run/Jump/Fall/Honk/Ability/Roll/Hurt/Disabled), `CharacterBody2D` with dedicated animation tree; no animation frame drives collision position unexpectedly.
- `AbilityRunner`: supports instant, channel, toggle, projectile and traversal ability; signals for `ability_started`, `ability_resolved`, `ability_ended`; world logic listens to events, not direct player references.
- `PuzzleInteractable`: groups and typed events (`heat`, `cold`, `sticky`, `bubble`, `light`, `resonance`, `weight`, `quiet`, `paint`, `cloud`). Puzzles declare required tags and clear visual response.
- `CheckpointService`: writes stage spawn, inventory restore conditions, optional collectibles, unlocked shortcuts.
- `SaveService`: atomic JSON save in `user://`, migration version, backup file, no arbitrary code execution from serialized data.

## Food fusions: deterministic lookup pseudocode
```
func canonical_pair(a: StringName, b: StringName) -> String:
    var names := [str(a), str(b)]
    names.sort()
    return names[0] + "|" + names[1]

func resolve(a: FoodDefinition, b: FoodDefinition) -> RecipeDefinition:
    return recipe_by_pair.get(canonical_pair(a.id, b.id))
```
Recipes must work regardless of slot order. Returning no special recipe should trigger documented default reaction or cosmetic combination, not silently fail.

## Ability trigger rules
- Primary action triggers currently highlighted pocket ability; tap uses base honk if empty, hold previews effect shape.
- Fusion uses A+B, with a dedicated control and contextual `can_fuse` signal.
- Ability has startup, active, recovery, cooldown; fixed resource costs; if activation cannot complete, do not charge resources.
- Gameplay-critical ingredient source restores after death/reset and remains accessible from the same puzzle room.
- All interactable hitboxes and visual effects have separate collision layers; authoritative collision detection is independent of VFX.

## Physics and movement
Default initial motion constants from GDD; physics ticks 60 Hz. Use `CharacterBody2D.move_and_slide()`, floor snap appropriately, robust coyote time and jump buffering. Animated skeleton visuals may compress but collision capsule must remain consistent except explicit transformation. Roll mode has defined new shape and tunneling checks. Moving platforms carry the player without double transforms. Camera follow uses bounded lerp/look-ahead and never causes motion sickness in assist mode.

## Level runtime interface
Each level defines metadata: `world_id`, `stage_id`, `spawn`, `checkpoint list`, unlocked foods, mandatory interaction graph, `recovery_spawn`, `collectibles list`, `exit_gate` and `return_to_hub`. All interactive gates must publish both visual and caption/audio state changes. No dependency on encountering a secret pickup for mandatory progression.

## Save schema (example)
```
{
  "schema_version": 1,
  "profile_id": "slot_1",
  "world_unlocks": ["W1"],
  "level_clear_ids": ["W1-L1"],
  "current_level": "W1-L2",
  "checkpoint": "cp_02",
  "food_unlocks": ["PEPPER", "BUBBLE"],
  "recipe_discoveries": ["PEPPER|BUBBLE"],
  "recipe_scraps": ["W1-L1-S01"],
  "cosmetic_unlocks": [],
  "equipped_cosmetics": [],
  "comfort_feathers": 3,
  "honk_charge": 100
}
```
`profile_id` is local, not an online identifier. Store user settings separately. Validate IDs and migrate unknown/legacy fields gracefully. Write via temp file and rename; handle browser quota failures and explain that private browsing can erase save data.

## Core input actions
`move_left`, `move_right`, `jump`, `flap`, `eat_interact`, `honk_primary`, `ability_swap`, `fusion`, `pause`, `map`, `hint`. Defaults: A/D or arrows; Space jump; E interact/eat; J honk; K fusion; Q swap; Esc pause; M map; H hint. Controller: left stick/D-pad move, south jump, west eat, east honk, north fusion, shoulder swap, start pause. All remappable.

## HUD / interface integration
HUD subscribes to signals. Two food slot icons remain visible, fusion tooltip appears only when relevant. Show ability costs clearly. Treat localization as key-value IDs; never draw all text into textures. Support UI scaling 75–150% and accessible caption overlays. Navigation by controller/keyboard only.

## Gameplay testing
Unit: canonical recipes are symmetric; duplicate pickups; safe empty inventory; cooldown; save migration; state transitions. Integration: World1 early puzzle solvable with required foods; roll cannot trap Tato; checkpoint restores food availability; Pause/resume preserves runtime; controller parity; settings persistence; browser IndexedDB save. Smoke: scene launches, main menu responds, player moves, eats, honks, fuse opens barrier, saves, reloads, reaches level end.

## Performance targets
60 FPS desktop and modern laptop; 30+ FPS baseline web hardware; limit active particles, use texture atlases, reuse nodes via object pools where beneficial, avoid unbounded audio voices. Use Godot profiler during performance pass. Manage source art size to keep web initial download reasonable (< 60 MB target, exact budget TBD by measured build).

## Development safeguards
No silent assumptions about user-authored art licensing; no API keys stored in repository; do not disable GitHub protection settings. All game content must be authored without copying copyrighted franchise expressions. Use feature branches and pull requests. Include automated static verification, unit smoke test scripts, and at least one human playtest pass per milestone.

## Publishing model
GitHub repository hosts **source**; GitHub Pages can serve an **exported web game** when its engine/version/settings work with Pages. Web target uses Compatibility renderer and single-threaded export unless deployment specifically configures required isolation headers. Export preset must be added and web export templates installed in runner. Create `index.html` export in `public/`; deploy via official Pages action or explicit branch workflow after verification. If web hosting behavior is broken, use GitHub Releases for desktop binaries and a suitable web host. GitHub hosting is not the same thing as a platform marketplace release.

## Acceptance tests
- No missing resources or parser errors when Godot loads the project headlessly.
- Player always has **two wings and two legs** across animations, reviewed visually.
- All 12 ingredients and 12 canonical fusion recipes have unique logic or deliberately documented generic reactions.
- No mandatory soft locks; stage checkpoints persist; all six boss final states reachable.
- Keyboard/controller parity; accessibility settings, captions and input remapping.
- Full menu→gameplay→ending→credits loop verified.
- Desktop exports launch on supported OS; web export tested from HTTPS in Chrome, Firefox and Safari with documented limitations.
