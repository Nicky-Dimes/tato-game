# Character, Enemy, Boss and Interaction Animation Specification

## Tato appearance — locked identity

Tato is a small, fluffy, white baby **goose** with oversized sparkling eyes, rosy cheeks, short orange beak, orange webbed feet and tiny expressive wings. His open-beaked honk and personality are central. Strict anatomy: **2 wings total, 2 legs/feet total, never more; the far wing can be obscured in profile.** Keep body outline and proportions stable across poses. No dog ears, snout, paws, human arms, extra wings or species swaps. Red scarf is a permissible established accessory; preserve known art identity over optional clothing.

Existing runtime contract (`PROJECT/game/scripts/player/tato_visual.gd`): right-facing 192×192 transparent frames, resting foot anchor **(96,168)**, displayed `SPRITE_SCALE=0.76`. The engine flips horizontally for left-facing. Ensure every pose fits same size, feet alignment and global visual center. Update animation mappings if new frame names change. Do not simply squash an idle pose to create purported walk/attack loops.

## Minimum production animation cels and performance goals

| State | Unique frame target | Motion notes |
|---|---:|---|
| Idle | 8 | Gentle belly breathing, blink, little head turns/wing adjustment; not mechanical bounce |
| Walk | 10 | Clear alternating webbed feet, weight transfer, body mass follow-through, wing counter-swing |
| Run | 12 | Distinct faster gait, anticipation, airborne stride, impact/compression, speed trails sparingly |
| Jump start | 4 | Anticipation crouch, strong push-off, feet lift, wings react |
| Jump airborne | 4 | Readable rising pose, flaps only with gameplay input |
| Fall | 6 | Hanging feathers/feet, worried or focused expression, readable velocity change |
| Land | 6 | Touchdown, body squash, settled feathers, dust/contact on separate FX layer |
| Honk (no power) | 8 | Open beak with expressive eyes, chest puff, short sound-wave FX, recoil |
| Powered attack | 10 | Clear anticipation, cast, release, follow-through and settle. Food-specific overlays or unique variants required |
| Eat/pickup | 8 | Reach, gobble, delight, new-power sparkle, real power replacement acknowledgment |
| Hurt | 6 | Hit-direction recoil, feathers, invulnerability blink, recovery readability |
| Recover | 6 | Resolve from knockback/landing; do not loop a damaged expression |
| Glide / flap | 6 each | Two wings in perspective, controlled air response, short and long holds |
| Swim | 8 | Feet/wing paddles, surface ripples with separate FX |
| Roll | 8 | Round body kinetic motion, rotations but eyes/beak still recognize Tato |
| Cheer / win | 8 | Celebration, hop, star reaction and readable eyes |
| Sleep/relax | 8 | Idle variants for menus/Home Nest |

Time animation from gameplay velocity; preserve animation logic from existing movement state. Record how attack-cast frames align to projectile spawn, and how contact FX align to collisions. Avoid impossible limbs in in-betweens. Reduced Motion must reduce unrelated ambient movement without removing gameplay-critical telegraphs.

## Enemy animation matrix — each of the 21 actual types

Actual IDs: `slime_blob`, `fire_slime`, `ice_slime`, `shock_slime`, `mushroom_hopper`, `apple_chomper`, `hedgehog_roller`, `turtle_tank`, `crab_snipper`, `onion_knight`, `rock_golem`, `carrot_archer`, `pepper_goblin`, `ice_puffin`, `candy_imp`, `mole_digger`, `bee_buzzer`, `crow_swooper`, `ghost_poof`, `pie_bat`, `balloon_jelly`.

Each must have distinct **idle (4–6), move/flight (8), windup/attack (6–8), hit (3–5), defeat (6–8)** cels, with tuned exceptions for natural lack of limbs or sustained hover. Unique telegraph sprites or edge highlights for enemies that cannot safely be stomped. If the enemy has ranged attacks, projectile source and release frame must match. The existing `enemy_data.gd` is authoritative for AI roles/attributes; do not unintentionally change enemy behavior by replacing art.

## Boss animation matrix — six named bosses, three attacks each

| Boss | World | Required attack sets |
|---|---|---|
| Mega Mushroot | W1 Grassland | Stomp, Spore Burst, Hop Slam |
| Gigantapple | W2 Orchard | Bite Rush, Seed Shot, Rolling Bite |
| Candy King | W3 Candy Carnival | Candy Rain, Sugar Wave, Bounce Core |
| Frost Puffin Lord | W4 Icy Pond | Ice Beam, Ice Spike, Blizzard Spin |
| Sky Airship Turtle | W5 Windy Mill | Propeller Gust, Cannon Volley, Wind Dash |
| Chef Castle Golem | W6 Castle Feast | Food Bomb, Cake Wave, Feast Slam |

Each requires distinct idle/anticipation/attack/recovery/hit/phase-shift/defeat action, with arena-readable effects and appropriate scale. All three attacks should visually differ. Bosses may retain the existing logic, health and battle triggers, but must have a professional animation response to every state.

## Interactable state machines

- **Checkpoint bell:** idle sparkle -> hit/swung bell -> brighter activated glow -> saved-state indicator. Bell must respond instantly and remain visibly activated.
- **Power bowl:** idle hover -> pickup pulse -> food icon rises/swirls -> consumed state; only one slot active and replacement is clear.
- **Question block:** anticipation bob -> spring/recoil -> shower of pickups -> depleted state.
- **Crate:** intact -> crack -> fragment burst -> removed, with readable hit feedback.
- **Spring pad:** uncompressed -> contact squash -> launch stretch -> return.
- **Goal sign / flag:** idle -> celebratory wave -> win pose -> results transition.
- **Coins, notes, stars, hearts:** slow idle hover and shine; collect burst and audio; separate outlines to distinguish interactable from decorative background.
- **Terrain hazards:** warning tell -> active -> cooldown where relevant; readable and non-punishing for children.
- **Moving platforms / water / weather:** meaningful motion loops; they should always visually match actual collision/platform position.

## Animation QA acceptance

- Inspect actual extracted consecutive frames in a side-by-side and flipbook animation, not a sparse contact sheet.
- Reject jarring center/feet shifts; no wing duplication; no floating under/above collisions.
- Run actual walk, run, jump, land and all 12 powers in Godot with camera tracking.
- Test disabled cosmetics, scales and accessibility modes.
- Include 1280×720 engine screenshots, short captured motion or GIF when feasible, and original editable art source.
