# Terrain Material Rebuild — v1

All six world material sets have new **seamless, world-space illustrated stone textures** created as separate PNG assets. A per-world atlas mask preserves turf/platform silhouette and existing terrain collisions. The new `rock_worldspace.gdshader` and a small insertion in `game/scripts/level/terrain.gd` link these to the actual Godot TileMapLayer.

The intent is to eliminate the visible 32px rock wallpaper repetition. This is not a complete redraw of the world, enemies or UI, nor a full art parity claim. Results are subject to real render and Godot QA.
