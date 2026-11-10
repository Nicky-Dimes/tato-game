# TATO! — Complete Game Design Document

**Edition:** Product definition v0.1 (implementation-ready intent; values require playtesting).  
**Genre:** 2D exploration-based puzzle-platformer / cozy action-adventure.  
**Camera:** 2D side view, parallax environments, subtle dynamic follow.  
**Audience:** All-ages; primarily ages 8+, accessible to casual and experienced players.  
**Platforms:** Windows, macOS, Linux and browser, optional mobile adaptation later.  
**Playtime target:** 5–8 hours main story; 10–14 hours with optional exploration.  
**Tone:** Curious, joyful, a little mischievous; nonviolent slapstick.

## 1. One-sentence pitch
Tato is a tiny gosling with a giant appetite who blends magical food powers and expressive honks to rescue lost recipes, restore a fractured living cookbook, and reunite a fantastical world through inventive puzzles and playful adventure.

## 2. Pillars
1. **Food is a creative verb:** eating a snack changes a move, while combining a pair creates emergent traversal and puzzle tools.
2. **Honk has personality and purpose:** resonant sound manipulates the environment; every flavor changes its timbre and function.
3. **Exploration rewards curiosity:** visible early secrets become accessible through new snack combinations; no tedious fetch chains.
4. **Tato is a character, not a weapon:** nuanced expressions, strong silhouette, no borrowed mascot behavior.
5. **Readable game feel:** punchy anticipation, brief squash-and-stretch, clean silhouettes, strong audio/visual feedback.

## 3. Story
### Setup
In the floating valley of **Crumboria**, a communal magical cookbook called the **Great Recipe Book** keeps the seasons, gardens, streams, and festivities in balance. At the annual First Feast, the book's six Flavor Pages scatter when a gust from the mysterious **Silent Bell** sweeps across the valley, draining color and sound from its food magic. Tato — a newly hatched goose famous for honking at absolutely everything — sets off with a tiny travel satchel to retrieve the pages.

### Central mystery
The Silent Bell is not a villainous weapon; it was built by the anxious kitchen guardian **Cloche**, who feared magical cooking had become chaotic and wasteful. Cloche sealed the book to control the valley, accidentally spreading tasteless silence. Each recovered Flavor Page reveals a memory that complicates Tato's understanding. The final resolution is cooperative: Tato uses a blended honk to harmonize, not destroy, the bell.

### Main characters
- **Tato:** enthusiastic, innocent, snack-obsessed, courageous through curiosity; communicates in honks and expressive gestures, never long spoken exposition.
- **Mimi:** an elderly field mouse librarian and recipe archivist. Gives context, keeps the recipe book in Tato's home, offers gentle hints only when requested.
- **Puddle:** a tiny frog mapmaker who unlocks region maps and notices optional paths.
- **Pep:** a competitive but goodhearted squirrel chef who teaches recipe combinations through trials and light comedy.
- **Cloche:** a round brass kitchen guardian, polite and overprotective rather than cruel; final rival and later ally.
- **The Six Keepers:** friendly inhabitants attached to seasonal Flavor Pages; each region has a different keeper and local problem.

### Three-act narrative structure
**Act I — A Really Bad Picnic (Worlds 1–2):** Tato discovers Pepper, Bubbleberry, Honeycomb and the idea of fusing foods. Retrieve first two pages. First encounter with Cloche's flavor-draining drones.
**Act II — Too Much of a Good Thing (Worlds 3–5):** Powers become more sophisticated; helpers and rival chefs disagree about restoring the cookbook. Tato discovers that uncontrolled recipes can be wasteful, not just funny. Recover pages three through five.
**Act III — The Quietest Dinner (World 6):** Complete the book, travel to the Silent Kitchen, use learned recipe interactions in a multi-stage ending sequence, befriend Cloche, celebrate with a communal feast.

## 4. Player controls
Move, jump, flap briefly, eat/interact, primary honk/ability, swap active food slot, fusion ability, pause/map. Keyboard, controller, and remappable bindings. Support optional hold-to-honk mode, buffered jump, coyote time and reduced-input complexity.

### Baseline moves
- Waddle / run, variable-height jump, short air-flap to soften fall, crouch, belly slide on downward slopes.
- Eat snacks when in range; no swallowing enemies. Food has clearly indicated category, duration and availability.
- Neutral honk emits a short cone that shakes loose fruit, activates chimes and attracts friendly creatures. It can stun lightweight hazards briefly, not injure beings.
- Roll is unlocked via watermelon early in World 2; later can be used for slopes, switches and barriers.

### Feel targets (initial tuning)
Movement target ~210 px/s, acceleration ~1400 px/s², deceleration ~1700 px/s², ground jump velocity ~-465 px/s, gravity ~1250 px/s²; coyote 0.10 s; buffered jump 0.12 s. Not final production constants: tune for obstacles and accessibility. Collision body remains stable during cosmetic squash/stretch; abilities can explicitly switch collision shape.

## 5. Core loop
**Explore → spot obstacle/secret → find ingredient → eat or equip → try a power → combine flavors → solve traversal/puzzle → collect a Recipe Scrap → unlock a shortcut or page → return to hub to cook, customize, and learn.**

### Snack slots and resource model
Tato has two **Flavor Pockets**, A and B. Each pocket contains up to one ability ingredient. Eating a new magical food while pockets are full prompts replace-A / replace-B, with 2-second slow-motion selection (no punishment). Physical ingredients are collected and added to nearby snack bowls, not endless global consumables. Pockets persist through the level until checkpoint, region exit or intentional swap. Core abilities cost **Honk Charge**, replenished by environment interactions and collectible crumbs; movement-based ability effects require no charge or low maintenance charge to prevent soft locks. Fusion uses both pockets and moderate charge. All mandatory routes provide the required ingredient or an alternate solution within the same puzzle region.

## 6. Fundamental food powers
| ID | Ingredient | Basic move | Utility | Risk/counterplay | First use |
|---|---|---|---|---|---|
| PEPPER | Spicy Pepper | Fire Honk: cone of warmth | Melt wax, light braziers, propel pinwheels | Overheats ice, awakens sleepy pollen | W1 |
| BUBBLE | Bubbleberry | Bubble Float | Cross gaps, rise on thermal currents, trap lightweight objects | Spiky thorns pop bubble | W1 |
| HONEY | Honeycomb | Sticky Waddle | Walk sticky walls/ceilings, drag loose gears | Water rinses stickiness | W2 |
| MELON | Watermelon | Melon Roll | Smash fragile crates, weigh switches, ride slopes | Cannot fit narrow gaps | W2 |
| FROST | Frostberry | Ice Slide | Freeze shallow water, cool vents, make surfaces slick | Heat melts ice | W3 |
| POPCORN | Popcorn | Pop Bounce | Bounce vertically off pads, pop sealed pods | Gusts change trajectory | W3 |
| NOODLE | Stretchy Noodles | Noodle Neck | Reach handles, peek through openings, wrap levers | Short stationary wind-up | W4 |
| CITRUS | Zesty Citrus | Flash Zing | Activate mirrors, reveal hidden ink and bright fungi | Needs line of sight | W4 |
| MINT | Moonmint | Quiet Honk | Sneak past listening flowers, calm storm moths | Limited duration | W5 |
| JAM | Starberry Jam | Jam Trail | Paint temporary paths and moving-platform links | Washes away in rain | W5 |
| TRUFFLE | Thunder Truffle | Drumbeat Honk | Trigger heavy resonant plates, timed machinery | Long charge-up | W6 |
| PASTRY | Cloud Puff Pastry | Feathercloud | Create temporary soft stepping clouds | Dissolves in wind | W6 |

### Fusion design principles
- Fusions are **recipes** that use two equipped ingredients; discovery permanently records a recipe, but execution still requires access to those flavors.
- Every successful fusion gets a unique visual silhouette, name, sound and contextual tutorial.
- Fusion may never trap the player: a reset plate repositions loose puzzle objects and restores the food sources.
- World critical path introduces 1–2 fusions per world, optional puzzles invite free experimentation.

### Twelve signature fusion recipes
| Pair | Recipe name | Function |
|---|---|---|
| PEPPER + BUBBLE | Steam Lift | Make a rising thermal bubble carrying Tato or light objects |
| PEPPER + HONEY | Caramel Coat | Harden sticky resin into a bridge for a short duration |
| BUBBLE + HONEY | Taffy Balloon | Elastic tether to pull a suspended platform |
| MELON + HONEY | Sticky Bowling | Roll onto vertical curved tracks and cling to magnetic-like syrup paths |
| FROST + MELON | Snowball Express | Become a larger chilled rolling sphere and chill moving belts |
| FROST + POPCORN | Frost Pop | Rapid bouncing that freezes touched puddles in small bursts |
| POPCORN + BUBBLE | Bubble Pop Jet | Controlled upward sequence of bubble bursts |
| NOODLE + HONEY | Tether Noodle | Anchor and swing from designated handles |
| CITRUS + FROST | Prism Chill | Create temporary ice prisms to redirect beams |
| MINT + JAM | Quiet Ink | Paint invisible-to-enemies paths revealed by special flowers |
| TRUFFLE + PASTRY | Thundercloud | Float a cloud that triggers large sound-sensitive mechanisms |
| CITRUS + PASTRY | Sunbeam Steps | Reveal and briefly solidify glowing cloud platforms |

**Rules for unspecified combinations:** every combination must produce either a useful generic enhancement (e.g., faster projectile, extended duration) or a playful reaction. Never produce an inexplicable no-op. Show the specific recipe names only once discovered.

## 7. Level structure & world-by-world campaign
The game contains a hub and **six worlds**, each with 3 main stages, 1 optional challenge, a finale and collectible return visits. Levels are nonlinear internally, but story progress is sequentially gated at region entrances. Suggested 2–5 min per individual puzzle beat, 12–20 min per standard stage, 20–30 min finale.

### Hub — Home Nest / First Feast Square
Book podium, world gate, snack trial room, wardrobe, recipe archive, map, accessibility settings and replay portal. NPC dialog changes after each page. The first 5 minutes are playable, not a long cutscene.

### World 1 — Picnic Patch (sunny orchard & garden)
**Theme:** bread baskets, picnic cloths, wooden bridges, windmills, honey flowers.  
**Ability teaching:** neutral honk, PEPPER, BUBBLE, Steam Lift.  
**Stages:** 1-1 The Missing Muffin (waddle, jump, honk, eat); 1-2 Berry Breeze (Bubble Float, breezes); 1-3 The Warm Windmill (Pepper, wind switches, simple pairing); 1-X Crumb Chase (optional time trial).  
**Finale:** **Puddle Puffer**, an inflated friendly water balloon frog who clogs the windmill. Redirect bubbles and steam without harming it.  
**Page:** Golden Crumb Page.  
**Story:** Mimi recognizes the Silent Bell mark.

### World 2 — Syrupwood Farm (barns & golden groves)
**Theme:** syrup rivers, apple crates, wooden farm gears, gentle animals.  
**Ability teaching:** HONEY, MELON, Caramel Coat, Sticky Bowling.  
**Stages:** 2-1 Sticky Situation; 2-2 Rolling Harvest; 2-3 The Barn That Turned Sideways; 2-X The Great Rolling Race.  
**Finale:** **Barrelback**, a walking barrel automaton; activate weight plates and gum its wheels.  
**Page:** Amber Glaze Page.  
**Story:** Pep challenges Tato to collect without wasting.

### World 3 — Frostpop Fair (winter carnival)
**Theme:** ice ponds, popcorn rides, festival lights.  
**Ability teaching:** FROST, POPCORN, Snowball Express, Frost Pop.  
**Stages:** 3-1 A Slippery Welcome; 3-2 Pop Goes the Platform; 3-3 The Carousel of Cold; 3-X Endless Bounce.  
**Finale:** **Whirligig**, an ice carousel awakened by the bell, solved via rhythm and freeze timing.  
**Page:** Frosted Sugar Page.  
**Story:** Tato witnesses Cloche collecting magic to prevent chaos.

### World 4 — Noodlebrook Market (busy canals & bazaar)
**Theme:** noodle canals, lanterns, citrus mirrors, moving carts.  
**Ability teaching:** NOODLE, CITRUS, Tether Noodle, Prism Chill revisited.  
**Stages:** 4-1 Market Detour; 4-2 Lantern Labyrinth; 4-3 The Longest Noodle; 4-X Chef's Secret Alley.  
**Finale:** **The Twin Teapots**, partner ceramic robots controlled by sound; solve two linked spatial puzzles.  
**Page:** Tangy Spark Page.  
**Story:** Cloche's previous role as kitchen guardian is revealed.

### World 5 — Moonberry Marsh (glowing night wetlands)
**Theme:** bioluminescent flowers, sound-sensitive moths, watercolor mist.  
**Ability teaching:** MINT, JAM, Quiet Ink, contrast between loud and quiet honks.  
**Stages:** 5-1 A Very Quiet Honk; 5-2 Painted Paths; 5-3 The Whispering Bog; 5-X Glow Trail Hunt.  
**Finale:** **The Echo Owl**, lost within a sound maze. Make harmony and soothe the owl instead of fighting.  
**Page:** Midnight Berry Page.  
**Story:** The Silent Bell is making the valley sick, despite Cloche's intention.

### World 6 — The Silent Kitchen (floating clockwork castle)
**Theme:** brass kitchens, silent chimes, shifting gravity plates, cloud ovens.  
**Ability teaching:** TRUFFLE, PASTRY, Thundercloud, Sunbeam Steps; reprises previous combinations.  
**Stages:** 6-1 The Quiet Gate; 6-2 Cloud Oven Climb; 6-3 The Missing Last Note; 6-X The Perfect Feast Trial.  
**Finale:** **Cloche & the Silent Bell**, 3 stages: repair sonic generators, chain three recipe reactions, perform a final honk harmony with forgiving rhythm cues.  
**Page:** Hearthsong Page.  
**Ending:** cookbook restored, community feast, Cloche apologizes and joins as a helper. New Game+ optional discovery challenges, no story contradiction.

## 8. Encounter philosophy
Enemies are **mischievous food-magic sprites and machines**, not real animals to hurt. Responses are knockback, stun, redirect, pacify, evade and environmental resolution. No blood, death animations, or punitive failure scenes.

### Common hazards & encounter units
- **Crumb Mites:** travel in predictable trails; honk scatters them temporarily.
- **Syrup Slimes:** slow movement; use cold, heat or alternate path.
- **Forklings:** animated cutlery on patrol; activate mirrors to distract.
- **Bubble Bats:** drift along air vents; pop via terrain interaction.
- **Hush Moths:** activate alarms when hearing loud honks; use Mint.
- **Clockwork Crabs:** transport crates; redirect their path with food scents.
- **Whistle Weeds:** release timed wind; use for lift or hide between gusts.
- **Pudding Pods:** swell when warmed, creating platforms.

### Boss rules
Each boss is a **three-phase environmental puzzle** with clear telegraphs, short checkpointed retries, no health-damage grind, and a playful nonlethal final beat. Boss abilities teach a skill used in subsequent exploration.

## 9. Collectibles, rewards, and customization
- **6 Flavor Pages** — mandatory campaign milestones.
- **72 Recipe Scraps** — 12 per world, puzzle/exploration rewards; ~42 needed for standard finale, remainder optional.
- **36 Goose Pins** — 6 per world; unlock cosmetic hats, scarves, ankle ribbons and nest decorations (no paywalls).
- **24 Secret Dishes** — 4 per world, found through clever combinations; flavorful flavor text and optional completion goals.
- **Feather Medals** — stage achievements (exploration, clever path, no forced speedrun); cosmetic only.
- **Chef's Trial** — replayable optional challenge rooms.

No microtransactions, lootboxes, battle pass or real-money upgrades. Save outfit and unlocked recipes. Cosmetics must not obscure eyes, wings, collision or ability VFX.

## 10. Player health and failure
Three **Comfort Feathers** in standard mode, replenished at checkpoints. Environmental mishaps knock Tato to the last safe platform with minor feather loss; zero feathers resets to nearest discovered snack station. No life count; no persistent currency loss. Optional **Cozy Mode** eliminates feather loss, lengthens timers and increases honk range. Optional **Challenge Mode** shortens windows but does not lock story rewards.

## 11. UI/UX
Main menu: Play, Continue, Chapters, Wardrobe, Settings, Credits, Quit. HUD: 3 Comfort Feathers, A/B pocket ingredient icons, Honk Charge arc, contextual fusion indicator, world region/collectibles unobtrusive. Pause: map, notebook recipes, hints, settings, quit to hub. Audio cues plus visual captions. Recipe discovery uses a 2-second delight animation, skippable. Map marks known branches and undiscovered paths as silhouettes, never spoilers.

### Tutorials
Show one concept in context and test it within 20 seconds. Use icon+motion and 1-sentence hint rather than long tutorial dialogue. Controls remain visible in pause menu. A **Hint Nest** offers progressive hints: gentle nudge → ingredient clue → explicit action, with no penalties.

## 12. Accessibility
Remappable keyboard/controller; adjustable UI scale; high-contrast prompts; color-blind readable shapes for ingredients; subtitles for honk/audio puzzle cues; reduced camera shake/flash; motion sensitivity slider; hold/toggle alternatives; assist mode with infinite Comfort Feathers; configurable time windows; no gameplay information conveyed only through colors or audio. Save settings independently from play progress.

## 13. Sound direction
Tato has a library of expressive honks (neutral, happy, surprised, angry, sleepy, wet, icy, echoing), all original. World music is light instrumental and loopable with distinct thematic palettes. Allow separate music/SFX/voice buses. Ability pairings add tiny harmonic countermelodies. Avoid references to recognizable existing game melodies.

## 14. Challenge and secrets
Mandatory path must be completable using foods available within the area. Returning with later recipes reveals alternate routes and collectibles, not arbitrary dead ends. No random procedural level generation in v1: carefully authored puzzles are the defining value. A procedural **Chef's Trial remix** is a post-launch possibility only.

## 15. Completion metrics / scope
Six fully built worlds, each with 3 core stages, 1 optional stage, 1 finale = 30 authored levels plus hub and tutorials; 12 base ingredients; 12 named core fusions; 6 bosses; all UI, saves, sound, localization-ready strings, and accessible mode. This is a substantial commercial-size project; deliver in milestones rather than assuming a single Claude prompt can finish it reliably.
