# Replacement pictures go here

A PNG in this folder replaces a picture of the game without any code change.

Name it `<folder>_<name>.png`, after the picture it replaces in `game/assets/sprites/`:

| To replace | Put here |
|---|---|
| `enemies/slime_blob.png` | `enemies_slime_blob.png` |
| `bosses/candy_king.png` | `bosses_candy_king.png` |
| `items/coin.png` | `items_coin.png` |
| `bg/grassland_far.svg` | `bg_grassland_far.png` |
| `world/icy_flag0.png` | `world_icy_flag0.png` |

The loader (`game/scripts/core/art.gd`) looks here first, then in the normal folder.
The original stays where it is, as reference.

**Not covered by this folder:** Tato's animation frames (`sprites/tato/*.png`, loaded by
`scripts/player/tato_visual.gd`) and the terrain atlases (`assets/tiles/`). Replace
those in place; see `CHATGPT_HANDOFF.md` at the top of the project.
