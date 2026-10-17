# Character poses: brief for an artist or an image tool

ChronoQuest has five playable heroes. Each has 6 drawn pictures today: 4 for walking, 1 for jumping, 1 for getting hurt. When a student presses attack, nothing changes on the hero. This brief asks for **8 new pictures per hero, 40 in all**. The 6 old pictures stay as they are.

| Pose | Pictures | When it shows |
|---|---|---|
| idle | 2 | Standing still. Loops, 0.6 s each. |
| fall | 1 | Coming down after the top of a jump. |
| attack | 3 | Wind-up, swing, recover. Plays once in 0.25 s (0.08, 0.09, 0.08 s), then a 0.4 s pause. |
| win | 2 | After a level or boss. Loops, 0.4 s each. |

## The five heroes (as they look in the walk and jump pictures)

Look at `assets/characters/<hero>_walk_2.png` and `<hero>_jump.png` first. They are the style reference. All heroes face right.

| Hero (file prefix) | Look | Attack with |
|---|---|---|
| Datu Lapu-Lapu (`lapu`) | Bare chest, brown sash, dark headband, bare feet, long curved sword | A diagonal chop with the sword, from over the head to out in front |
| Jose Rizal (`rizal`) | Dark blue frock coat, brown hair, a book in one hand | Swings the book like a club, a wide smack. No sword. |
| Heneral Antonio Luna (`luna`) | Red uniform with gold shoulders, red cap, moustache, black boots, sabre (drawn and raised in his jump picture) | A slash with the sabre. |
| Andres Bonifacio (`bonifacio`) | White shirt, red trousers rolled up, red headband, bare feet, a bolo at his belt (raised in his jump picture) | A bolo chop, overhead then down |
| Gregorio Del Pilar (`delpilar`) | Olive uniform, red cap, blue trousers with a red stripe, a rifle, a sword at his hip | Swings the rifle butt like a club. |

## Rules for every picture

- **PNG, transparent background, 80 x 80 pixels.** The old pictures are 52 x 68. The new canvas is bigger so a raised sword or a wide swing is not cut off.
- **Same pixel art as the old pictures.** Crisp pixels, no blur, no soft edges, about the same outline, light from the upper left. Same face, same clothes, same colours as that hero's walk pictures.
- **Same size of hero.** Standing, he is about 64 pixels tall from head to toe, as in the walk pictures. Do not make him bigger in the new poses.
- **Feet.** Put the middle point between his feet at **x = 40**, and the lowest pixel of the picture on the **bottom row (y = 79)**. Do this in every picture, even `fall`: the game moves the whole picture up into the air. That keeps him from jumping sideways or sinking when the pictures change.
- **The pictures of one animation must line up.** In `idle_1` and `idle_2` the feet stay in exactly the same place (nothing slides). Only the body moves.
- **The swing should reach what it hits.** The attack hits an area about 43 pixels wide and 49 tall, starting at his body. In `attack_2` the tip of the weapon should reach about 40 pixels in front of his middle (x = 80 is the edge of the canvas).
- **No slash trail painted in.** The game adds the gold swoosh in code, so it can be seen or turned off.

## The pictures

| File | What it shows |
|---|---|
| `<hero>_idle_1.png` | Standing, weapon held loosely, relaxed. |
| `<hero>_idle_2.png` | The same, breathing in: body 1 pixel lower with the knees slightly bent, head a little lower. Feet identical to idle_1. |
| `<hero>_fall_1.png` | Dropping: arms up and out, legs apart, clothes and hair lifted. Weapon held up. |
| `<hero>_attack_1.png` | Wind-up: weapon pulled back and up behind the head, body leaning back a little. |
| `<hero>_attack_2.png` | The swing, the strongest picture: weapon fully out in front, body leaning forward. |
| `<hero>_attack_3.png` | Recover: weapon coming down, body coming upright. |
| `<hero>_win_1.png` | Cheering: weapon raised high in one hand, big smile. |
| `<hero>_win_2.png` | The same, a little higher or the free arm waving, so it looks like a small bounce. |

Replace `<hero>` with `lapu`, `rizal`, `luna`, `bonifacio`, `delpilar`. That is 8 files each: for example `lapu_attack_2.png`. They go in `assets/characters/`.

Played in a row, `attack_1`, `attack_2`, `attack_3` must read as one swing.

## Using an image tool

- Give the tool the hero's `walk_2` and `jump` pictures as reference, and ask for the same character in a new pose. Example: "Pixel art, side view facing right, the same character with the same outfit and colours as the reference, transparent background, 80 x 80, [pose from the table]."
- Expect the face and clothes to drift from picture to picture. Make all 8 pictures of one hero in one sitting and compare each with `walk_2` before keeping it.
- Tools rarely make true pixel art. Make it bigger if you must, then shrink it back to 80 x 80 with nearest-neighbour only (no smoothing) and clean up by hand.
- Check the rules above, especially the feet and the transparent background, before sending.

## Later, not needed now

Defeat: 3 pictures per hero (staggering, falling back, lying down), named `<hero>_defeat_1.png` to `_3.png`. That is 15 more.

## What happens after

Send the files with exactly these names. I check them with a script (size, transparency, lowest pixel on the bottom row, how far the feet move between the pictures of one animation), then wire them into the game: idle when standing still, fall, the attack on the attack button, win after a level. A hero with no new pictures keeps today's. The game will draw the 80 x 80 pictures at the same scale as the old ones, lined up on the feet.
