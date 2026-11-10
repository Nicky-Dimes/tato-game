# TATO! — the game as built

A bright side-scrolling action platformer for all ages. Tato, a little goose with a big
appetite, eats, bounces and bops through six worlds to bring home the six Flavor Pages
of the Great Recipe Book.

Design direction (owner's boards, 2026-11-10): **1 active power · attack-based · lots of
enemies · easy for kids · hard to die · frequent checkpoints · three buttons.**

## Controls
Move, **Jump** (press again in the air to flap, up to three times; hold to glide) and
**Attack**. Down crouches, belly-slides when running, and drops through thin platforms.
Up (or Attack) talks to things in the Home Nest. See `docs/CONTROLS.md`.

## Hearts
Five hearts. A bump costs one, with a knock-back and a moment of safety. Out of hearts:
Tato flops and pops back at the last checkpoint bell with full hearts. Coins, stars and
notes are kept; there are no lives. Heart pickups heal one, Extra Heal fills them,
fruit heals one, and every 100 coins refills them. Cozy Mode makes hearts endless.

## Powers (one at a time — the newest food bowl replaces the old power)
| Food | Attack | What it does |
|---|---|---|
| Fire Pepper | Fire Shot | fireball straight ahead; melts ice blocks |
| Bubbleberry | Bubble Trap | two wobbly bubbles; a caught creature floats away |
| Watermelon | Multi Shot | three slices in a fan |
| Honeycomb | Honey Shot | a glob that glues a creature to the spot |
| Popcorn | Pop Shot | kernels arc up and out |
| Noodle | Noodle Whip | long whip through everything; grabs coins |
| Frostberry | Freeze Shot | freezes creatures into steps; freezes water |
| Cocoa Shield | Shield Guard | nothing hurts Tato; shots bounce back |
| Garlic Dash | Dash Attack | zoom through creatures, crates and cracked walls |
| Thunder Corn | Lightning Shot | a bolt that jumps between creatures |
| Lemon Beam | Laser Beam | a beam through everything in a line |
| Tomato Bomb | Bomb Blast | lobbed bomb with a big splat; breaks cracked walls |

With no power the attack is a **honk** (a short bop in front of Tato).
Picking up a new power while holding a different one sets off a **Flavor Burst**
(a ring that bops everything nearby). All 66 pairs are named and recorded in the notebook.
Data: `game/data/foods/*.tres`; scripts: `game/scripts/food/abilities/`.

## Creatures (all defeated by "poofing"; they drop coins)
Mushroom Hopper, Slime Blob (+ Fire, Ice and Shock Slimes), Apple Chomper, Bee Buzzer,
Hedgehog Roller, Turtle Tank, Crow Swooper, Ghost Poof, Crab Snipper, Mole Digger,
Onion Knight, Carrot Archer, Pie Bat, Ice Puffin, Candy Imp, Pepper Goblin, Rock Golem,
Balloon Jelly. Most can be jumped on; prickly, hot or shocking ones cannot.
Data: `game/scripts/enemies/enemy_data.gd`.

## Worlds
| # | World | Gimmick | New powers | Boss (three attacks) |
|---|---|---|---|---|
| 1 | Grassland | Bounce Mushroom | Fire Pepper, Bubbleberry | Mega Mushroot — Stomp, Spore Burst, Hop Slam |
| 2 | Orchard | Falling Apples | Watermelon, Honeycomb | Gigantapple — Bite Rush, Seed Shot, Rolling Bite |
| 3 | Candy Carnival | Candy Conveyor | Popcorn, Noodle | Candy King — Candy Rain, Sugar Wave, Bounce Core |
| 4 | Icy Pond | Slick Ice | Frostberry, Cocoa Shield | Frost Puffin Lord — Ice Beam, Ice Spike, Blizzard Spin |
| 5 | Windy Mill | Wind Gust | Garlic Dash, Thunder Corn | Sky Airship Turtle — Propeller Gust, Cannon Volley, Wind Dash |
| 6 | Castle Feast | Drawbridge | Lemon Beam, Tomato Bomb | Chef Castle Golem — Food Bomb, Cake Wave, Feast Slam |

Each world: three stages, a bonus stage, a boss. 30 stages in all, plus the Home Nest
(world gates, Snack Notebook, wardrobe) and the Snack Trial Room (every power to try).

## Things to find
- **Coins** everywhere; 100 refill hearts; they also buy hats at the wardrobe.
- **Treasure Notes**: three hidden in every stage.
- **Stars**: up to three per stage (finish it, find all three notes, find the hidden Star).
- **Keys** open locked blocks. **Question Blocks**, **crates** and **cracked walls** hold surprises.
- **Level pickups** (all 20 from the item board): gem, crystal (treasure); flower, leaf,
  candy, moon, sun (charms); cherry, grape, banana, corn (fruit: heal); clover (double
  coins); orb (guard bubble); feather (floaty fall); mushroom (super jump); wings
  (endless flaps); magnet; time (slow motion); rainbow star (invincible); egg (surprise).

## Story
Storybook pages (pictures from the boards) open the game, follow each boss and close it.
Nobody is hurt: the bosses only wanted to be invited to the feast.

## Accessibility
Cozy Mode, endless hearts, hold-to-attack, captions for important sounds, reduced
motion, screen-shake amount, reduced flashes, text size, remappable keyboard and gamepad
controls, touch button size and visibility, a graphics-detail switch for older devices.
