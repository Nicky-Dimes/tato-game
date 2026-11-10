# Art pipeline

## Where the pictures come from

The owner's eight art boards in `assets/reference/` are the source of truth:

| Board | Used for |
|---|---|
| `movement_anatomy_sheet.png` | Tato's animation frames (walk, run, jump, roll), expressions |
| `approved_concept_sheet.png`, `refined_game_sheet.png` | first identity boards (reference) |
| `direction_sheet.png` | big Tato drawings, world cards, mock screen |
| `items_powerups_sheet.png` | coins, star, heart, key, note, blocks, bowls, 20 pickups, 12 power icons, action demos |
| `enemies_bosses_sheet.png` | 18 creatures, 3 slime variants, 6 bosses |
| `world_assets_sheet.png` | per-world tiles, hazards, props, flags, signposts, bowls; world paintings |
| `gameplay_redesign_sheet.png` | touch buttons, defeat / respawn Tato, extra-heal, mock screens |

Nothing is redrawn. Two tools cut the boards into transparent PNGs:

```bash
python3 tools/art/extract_tato.py --sheet       # -> game/assets/sprites/tato/  + docs/art/tato_contact_sheet.png
python3 tools/art/extract_sheets.py --review    # -> game/assets/sprites/{enemies,bosses,items,pickups,powers,ui,tato_big,cards,world}/
```

`--review` writes contact sheets to `docs/art/cut_*.png`. **Look at them after every
change** (stray label pieces and merged neighbours show up there).

How cutting works (`tools/art/cutter.py`): the plain backdrop is flooded away from the
edge of a rectangle; painted or gradient backdrops are flooded by small colour steps
that stop at outlines; plum name tags behind icons are treated as backdrop; the edge
pixels have the backdrop colour un-mixed so sprites sit cleanly on any background.

## Rules

- **Tato has exactly two wings and two feet** in every frame. The walk and run frames
  used are the anatomy board's (one near wing, far wing hidden, alternating feet).
- One level of detail everywhere: sprites are shown close to their source size.
- A sharper picture can replace any cut-out without code changes: put it at
  `game/assets/sprites/override/<folder>_<name>.png` (e.g. `override/enemies_slime_blob.png`).

## What is generated instead of cut, and why

- **Terrain tiles** (`tools/art/art_tiles.py`): ground has to tile seamlessly in any
  shape; the boards only show small samples. Colours follow the world board.
- **Parallax backgrounds** (`tools/art/art_backgrounds.py`): the boards' paintings are
  ~340 px wide, too small to stretch behind a stage. They are used as world cards and
  on the world map instead.
- **Shots and effects**: drawn in code to match the action demos on the item board.

## Known limits

The boards are 1448x1086, so the world-kit drawings are only 40-60 px across and look
soft when enlarged. Larger source sheets (for example one sheet per category from the
owner's image tool) can be dropped into the same cutter.
