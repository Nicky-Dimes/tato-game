# TATO! Art & Animation Bible

## Authoritative references
1. `assets/reference/approved_concept_sheet.png` — overall art, identity, cheerful colors and personality.  
2. `assets/reference/refined_game_sheet.png` — game-wide ability look, revised movement.  
3. `assets/reference/movement_anatomy_sheet.png` — targeted walk/run anatomy and profile reference.  
These are **conceptual** image boards. They are not perfectly aligned, transparent animation sprites, and must be redrawn/extracted and verified individually before implementation. If any graphic conflicts with this document's anatomy requirements, this document wins.

## Tato shape bible
- Baby **goose** (gosling), not duck/chicken: goose-like orange bill, orange webbed feet and a softly elongated upper neck despite a chibi silhouette.
- Big head about 42–48% of standing height; round pear-shaped body, soft belly; tiny triangular white feather tuft; rosy cheek blush.
- Two **purple/lilac irises**, glossy highlights, dark pupils; coherent forward gaze for front view and one visible eye for profile.
- Small orange beak; open honk shape and closed neutral shape; tongue only inside open mouth.
- **Exactly two wings, two legs, two webbed feet**. Wings anchor at left/right side of upper torso, never grow from the back of the head or middle of belly. Far-side wing normally partly hidden in side view. Wing tips have 3–4 soft-feather lobes, not fingers or extra arms.
- At no time may a walk/run frame show three separate arm-like shapes. During a stride: near wing = short tapered wing hugging side or lifted slightly; far wing = a tiny occluded silhouette only when pose requires it. Both remain physically attached to torso.
- Legs alternate one grounded contact foot / one swinging foot; one body center; head doesn't split; no extra shadow mistaken for appendage.

## Style and palette
Clean premium chibi storybook aesthetic (as approved), not forced pixelation. Deliberate navy/dark plum outlines instead of absolute black. Cream-white feather base, pale-lavender shade, warm peach rim light; orange-yellow beak and feet; pink cheek blush; iridescent purple eyes. Approx palette suggestions: `#FFF9EF`, `#F6E9F5`, `#DCC7F0`, `#301444`, `#FFB81E`, `#FF790B`, `#F5A2A8`, `#765CA9`. These are starting values, not exact sampled brand swatches. Avoid photo textures, heavy realistic highlights or gradient banding.

## Rendering and technical delivery
- Native art designed at 256×256 per base pose (transparent PNG), 4× sampled for HD presentation, with center alignment to consistent foot anchor. Game may use larger master art at 512×512 with 256 equivalent collision templates.
- Tato canonical base canvas: **384×384 px** per frame to allow wing/extreme jump extent; pivot ground at `(192,342)`; normal collision capsule approximately 54×70 in 1280×720 logical game coordinates, subject to tests.
- Use spritesheets at constant frame dimensions or individual PNGs. Export animations with no stray merged sprites, no cut-off feathers, no placeholder checkerboard baked in.
- Separate shadows into reusable animation/camera layer rather than baking a hard shadow into transparent sprites.
- Deliver `.png` frame sequence, animation metadata `.tres` or JSON, artist source file (e.g. `.aseprite` or `.kra` or `.psd`), and a contact sheet for review.
- Every frame labeled with animation name, facing, zero-based index, duration and pivot; sprite flipping only when asymmetry and light direction make it safe.

## Primary 2D animation list / target frames
| Animation | Frames | FPS | Loop | Key anatomy |
|---|---:|---:|---|---|
| idle_breathe | 6 | 7 | yes | wings attached, belly subtly rises |
| idle_blink | 4 | 7 | no | eye line stable |
| idle_look | 6 | 6 | no | face turn, unchanged limb count |
| walk | 8 | 12 | yes | alternating left/right foot, tiny wing counter-swing |
| run | 8 | 16 | yes | larger forward lean, both feet airborne in passing poses |
| stop_skid | 5 | 14 | no | body squish, trailing wing valid |
| jump_anticipate | 3 | 12 | no | crouch and wing draw-in |
| jump_ascend | 4 | 12 | no | exactly two wings, near wing visible |
| airborne_flap | 6 | 14 | yes | both wings articulate from torso, mirrored deliberately |
| fall | 3 | 8 | yes | wing angle opens, feet dangle |
| land | 4 | 14 | no | feet grounded, body squashes |
| honk_neutral | 8 | 16 | no | open beak, cheeks, slight recoil |
| honk_power | 10 | 16 | no | intensified facial expression, force ring as separate VFX |
| eat | 8 | 12 | no | peck, chew, swallow, sparkle |
| full_belly | 6 | 8 | no | satisfied cheeks, rounded tummy |
| hurt_recover | 6 | 12 | no | no distressing violent injury |
| win_dance | 12 | 12 | no | jubilant waddle/wing wiggle |
| melon_roll | 8 | 16 | yes | canonical ball form, face rotates consistently |
| bubble_float | 8 | 8 | yes | Tato inside bubble, wings small and valid |
| sticky_climb | 8 | 10 | yes | both feet attached to wall, one wing visible |
| ice_slide | 8 | 14 | yes | slick, narrow posture |
| noodle_neck | 10 | 12 | no | elongation is NECK, not a new appendage |
| popcorn_bounce | 8 | 16 | yes | puffy stretch and compression |

## Critical walk/run polish QA
### Walk 8-frame cycle
0 left contact; 1 left down; 2 passing / right lifts; 3 right forward; 4 right contact; 5 right down; 6 passing / left lifts; 7 left forward. Draw feet independently. Torso bob is about 3–5 px; near wing rotates **slightly** counter to leg step, without detaching. The side silhouette should always show the same visible near-side wing root and only a tiny far-side wing tip if necessary.

### Run 8-frame cycle
0 left contact; 1 recoil; 2 passing; 3 airborne extension; 4 right contact; 5 recoil; 6 passing; 7 airborne extension. Torso angle 8–12° forward; head shape and bill length constant. Feet alternate; no duplicated foot when stretched. Short speed streaks/dust as **separate VFX**, never attached to wings like an extra limb.

### Review gate
Overlay all walk frames at 50% opacity with the same body pivot; inspect for ghost arm/wing. Perform silhouette-only playback at 50%, 100% and 200% scale. Review all frames individually for two-wing/two-foot constraint; reject any frame with a third arm-like silhouette or duplicated joint. Check scene pacing at both target FPS and actual real-time animation loops. Export GIF/MP4 preview, but use lossless PNG sprites for game.

## Foods and transformations
Ability has three layers: (1) base character pose and animation; (2) equipment/skin effect like red warm feather tips; (3) free-floating effect layer e.g. bubbles/fire. Ability VFX must never obscure eyes or make limbs ambiguous. Every food has distinct hue plus silhouette icon for color accessibility.

### Twelve food visual identities
Pepper: scarlet/ember halo; Bubbleberry: translucent blue bubble; Honey: gold sticky trails; Melon: watermelon-green rolling rim; Frost: cyan faceted frost tips; Popcorn: popcorn clouds and yellow pop impact; Noodle: spiral neck animation with clear contour; Citrus: orange-yellow sun glints; Mint: turquoise calm aura and quiet pips; Jam: magenta paint path; Thunder Truffle: violet concentric resonance; Pastry: cream cloud step pads.

## Environments
Six named world palettes; minimum three depth planes plus interactive foreground; separate collision geometry from illustrated assets. Play spaces readable at 720p. Background decoration cannot look identical to interactables. Avoid background plates containing UI text.

## Art review / production acceptance
Each sprite must pass: identity, silhouette, anatomy, alignment, no cropped limbs, transparent alpha, consistent edge quality, camera-scale readability, eyes correct, 2 wings/2 feet, animation cycle fluidity, no third appendage, lossless export, source file included, rights documented.
