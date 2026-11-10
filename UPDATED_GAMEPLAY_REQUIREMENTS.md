# TATO! — Updated gameplay requirements

Recorded from the owner's handoff instruction of 2026-11-10. **This is the direction in
force.** Where it disagrees with any older document in `docs/` or `docs/handoff/`, this
file wins.

## The game in one sentence

TATO! is a colourful, polished, kid-friendly action-platformer about exciting
food-powered combat. It should be genuinely entertaining, not mainly about floating
around and solving simple power-up puzzles.

## Requirements, and where the current build stands

"Met" means the mechanic exists and is tested. It does not mean it feels good yet.

| # | Requirement | Current build |
|---|---|---|
| 1 | Only ONE active food power at a time | **Met.** `PowerSlot` holds one power. |
| 2 | Collecting a new power replaces the current one | **Met.** |
| 3 | Every food power gives a useful attack or combat ability | **Met mechanically.** All 12 attack. Their look and punch are weak. |
| 4 | No mandatory two-food combinations | **Met.** Nothing needs two foods. A "Flavor Burst" flourish plays when a power is swapped; it is optional and can be removed. |
| 5 | Many enemies with varied attack patterns and behaviours | **Partly.** 21 creatures exist, but behaviours are simple (patrol, hop, lunge, shoot, swoop). They now wobble through four motion frames; no drawn attack or hurt poses. |
| 6 | More engaging combat, movement, secrets and collectibles | **Partly.** Coins, 3 Treasure Notes and a hidden Star per stage, keys, 20 pickups, world treats. Stages are formulaic and flat in places. |
| 7 | Strong visual feedback for attacks and enemy reactions | **Partly (improved in 0.2.0).** Every hit has a brief pause, shake, sparks and a ring; defeated creatures fly off spinning. Shots are still plain shapes apart from the fire shot. |
| 8 | Five starting hearts and plentiful health recovery | **Met.** 5 hearts; heart pickups, Extra Heal, fruit, 100 coins refill. |
| 9 | Frequent checkpoints and forgiving respawns | **Met.** Three checkpoint bells in each main stage, two in each bonus stage; a boss arena restarts at its entrance. Respawn keeps coins, notes and keys; no lives, no game over. |
| 10 | Accessible for children, enjoyable for all ages | **Unproven.** Cozy Mode, Endless hearts, hold-to-attack and captions exist. No child or adult has play-tested it. |
| 11 | Fully animated Tato with no extra limbs | **Partly.** Two wings and two feet in every frame. Idle, walk, run, jump, fall, land, attack, pickup and hurt animations exist, but the added frames are re-posed copies, not new drawings. |
| 12 | Beautiful layered environments across all six worlds | **Not met.** Three layers per world; one tree shape recoloured across worlds. |

## Character rule (unchanged, absolute)

Tato is an adorable, fluffy white baby goose with large expressive eyes, rosy cheeks,
tiny wings and orange feet. **Exactly two wings and two legs** in every drawing, frame
and pose.

## What must improve most (owner's list)

- Characters that slide like static cut-outs.
- Incomplete walking and running cycles.
- Missing jump, fall and landing animation.
- Inconsistent wing anatomy.
- Weak attack and projectile visuals.
- Flat, overly simple background scenery.
- Poorly integrated enemies and environmental objects.
- Basic-looking tiles, platforms and interface graphics.

## Controls (unchanged)

Three buttons: move, jump, attack. Keyboard, gamepad and touch. Touch-first, landscape.

## Targets that still apply from earlier instructions

- Runs well on 2018–2019 iPhones and iPads in the browser.
- Six worlds, each with stages and a boss, a beginning and an ending.
- Nothing is published until the owner chooses a licence and says so.

## Open questions for the owner (not decided, not assumed)

- Keep, restyle or drop the Flavor Burst flourish?
- Should a respawn give back the power Tato held at the checkpoint (current behaviour)
  or the one held when hearts ran out?
- Should Grassland get a treat of its own like the other five worlds?
