# World-by-World and Stage-by-Stage Art Production Plan

This document is **production direction** grounded in the actual six worlds and stage IDs. Visual treatments beyond the existing code are newly proposed requirements, not claims that the assets already exist. Each world has **Wn-L1, Wn-L2, Wn-L3, Wn-X (bonus), Wn-B (boss)** in `PROJECT/game/data/levels/`. Keep map and reward progression reachable. The existing text levels are one-character-per-64px-cell data; see `PROJECT/docs/DEVELOPMENT.md`.

## Shared authoring constraints (every stage)

- Original, independent sky/far/mid/near terrain/optional foreground plates with parallax and clean seams; **no object/pickup/player/label/UI in background art**.
- Seamless terrain atlas and believable traversable platforms, cliffs and slopes with ground shadow/foliage. Match material palette to the world.
- At least 4 decor families per world with size variety, and animated environmental details tied to a meaningful setting (not just generic glimmer particles).
- All enemies and collectibles distinctly readable and foregrounded. Enemy attacks readable for young players, frequent gentle healing/clear checkpoints.
- Design varied verticality and alternate routes while respecting existing physics (jump 2 cells, flap for harder gaps). Robot and manual traversal must pass.
- Every world has its own level-entry screenshot, standard combat screenshot, bonus/secret screenshot, and boss screenshot captured directly from Godot.
- Each asset must be versioned and reusable across multiple stages; no baked cinematic screenshots posing as parallax.

## W1 — Grassland / Sunny Meadows

**Existing gameplay anchor:** bounce mushrooms, Fire Pepper, Bubbleberry, boss Mega Mushroot. **Visual master style world** because the approved target shows lush, sunny, detailed grassy cliffs, rivers, bridge, distant castle, waterfall, lanterns, flowers and soft rolling hills.

**Production art:** clear sky, detailed non-repeating distant hills/woodlands with small castle/windmill, independent stone bridge and waterfalls in midground, illustrated tree canopies and roots, shrubs/fences/flower clusters, foreground water/ripples/rocks/lily pads; rich warm stone under grassy platform tops. Diverse rock edge silhouettes and floating island variants. Appropriate shaded Tato sprite and shadow on top of actual ground.

**Interactions:** mushroom bounce compression, sliding grass, checkpoint bells, question-block squash, glowing food bowls, slime/hopper/bee enemy animations, projectile fire/water effects. Avoid huge empty brown bands and blurry duplicated scenic crops.

**Stage direction:** W1-L1 teaches movement/honk/fire with layered interactive detail; W1-L2 introduces varied elevations and combat rhythms; W1-L3 asks for more agile enemy and food-attack usage; W1-X uses alternate route/collectible-focused set dressing; W1-B is a distinct illuminated meadow arena for Mega Mushroot, three clear telegraphs.

## W2 — Orchard

**Existing gameplay anchor:** falling apples, Watermelon and Honeycomb, Gigantapple boss. **Production palette:** ripe reds/oranges/greens, warm dappled sunlight, wooden paths, fruit leaves, friendly rural festival scenery.

**Production art:** flowering/fruiting orchard trees as separated parallax, harvest crates, fence posts, baskets, apple blossoms, carts, ladders and hanging fruit silhouettes. Warm earth and root-like terrain material, moss transition, selective sunbeams. Different orchard regions by stage (spring blossoms, mature orchard, harvesting festival). Avoid static apple stickers scattered without visual logic.

**Interactions:** animated falling fruit, sticky honey visuals and enemy freeze-in-place, watermelon fan shots, springy apples and fruit pickups. Boss arena with rolling apple hazard tells and depth-appropriate spectators. W2-L1..L3 steadily layer hazards/enemies; W2-X reward route; W2-B Gigantapple.

## W3 — Candy Carnival

**Existing gameplay anchor:** candy conveyor, Popcorn and Noodle, Candy King boss. **Production palette:** luminous pink, mint, warm gold, blueberry purple, icing highlights with deep plum outlines.

**Production art:** frosted platforms and support struts, candy kiosks, moving conveyor mechanisms, carnival lights and signage, lollipop forests, cake strata, confetti, playful but readable hazard edges. Independent candy architecture in 3 depth layers; no repeated giant UI candy icons.

**Interactions:** candy conveyor animation physically aligned to actual movement, popcorn projectile arcs, noodle whip reach and coin grab, falling candy warnings. Boss candy rain/wave/bounce distinguished by shapes and colors. W3-L1..L3 progression from gentle motion to denser carnival; W3-X secret sweets route; W3-B Candy King.

## W4 — Icy Pond

**Existing gameplay anchor:** slippery ice, Frostberry and Cocoa Shield, Frost Puffin Lord boss. **Production palette:** layered cyan/teal, lavender ice shadows, icy-white highlights, warm hearth accents for contrast.

**Production art:** reflective frozen pond/ice shelves, crystalline caves, snowy caps, frozen reeds, icicles, drifting snow (optional reduced-motion), aurora/soft winter sky, transparent ice thickness and refraction details. Cracks on hazards should read immediately.

**Interactions:** slide contact particles, freeze shots creating real usable steps, cocoa-shield protection/bounces, flowing/frozen water transitions and corresponding sound; ice enemies with readable telegraphs. W4-X treasure under ice; W4-B Frost Puffin Lord with ice beam/spike/blizzard sequences.

## W5 — Windy Mill

**Existing gameplay anchor:** wind gust, Garlic Dash and Thunder Corn, Sky Airship Turtle boss. **Production palette:** fresh turquoise, sun-warmed stone, sky blue, light cream clouds, vivid flowers and golden wood accents.

**Production art:** high meadows and suspended bridges, windmills with correctly centered rotating blades, swaying flags/cloth, weather vanes, cloud trails, gust streamers, airship silhouettes and distant rolling hills. Clear separation between decorative winds and physics-relevant gusts.

**Interactions:** visible gust lines tied to active wind direction, dash speed trails and impact, chain lightning attack, moving platforms/airship elements with aligned collision. W5-L1..L3 escalate wind and airborne combat; W5-X risky aerial reward route with checkpoint; W5-B Sky Airship Turtle with gust/cannons/dash.

## W6 — Castle Feast

**Existing gameplay anchor:** drawbridge, Lemon Beam and Tomato Bomb, Chef Castle Golem boss. **Production palette:** royal lilac/plum, warm copper/gold, honey candlelight and richly textured stone with bright feast colors.

**Production art:** detailed exterior battlements, banners, stained-glass windows, banquet halls, tiled kitchens, oven/light sources, torch reflections, drawbridge/chain mechanisms, chandeliers and service passages. Distinct silhouettes and clear active-interactive cues for levers/doors/bridges.

**Interactions:** beam lighting, tomato splats, breakable castle wall, boss food bombs and cake waves, animated kitchen props, confetti payoff at story end. W6-L1..L3 story tension builds; W6-X hidden banquet rewards; W6-B Chef Castle Golem with three attack types and celebratory resolution.

## Required level acceptance evidence

For each stage `Wn-L1`, `Wn-L2`, `Wn-L3`, `Wn-X`, `Wn-B`:

1. Attach 1280×720 Godot screenshot from start, combat midpoint, reward area and finale/boss. Label stage ID and Git commit.
2. Track all actual enemies/power-ups/collectibles, not just decorative art; show an action example using a real implemented food power.
3. Verify no backdrop-baked platforms/coins/props; everything gameplay-relevant is a real entity.
4. Run smoke robot for non-boss stages, boss script and manual checks for boss stages, accessibility quick check.
5. Rate the art against official target for detail, coherent color, depth, consistency, readability and stability; do not mark visually approved until actual owner acceptance.

**Technical source:** level data lives in `PROJECT/game/data/levels/`, world metadata in `PROJECT/game/autoload/LevelDB.gd`, world renderer in `PROJECT/game/scripts/level/backdrop.gd` and `terrain.gd`.
