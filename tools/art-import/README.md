# Art import (2026-11-06)

How the new hero, enemy and boss pictures in `assets/` were cut from the Canva sheets
(`BOY.png`, `GIRL.png`, `LAPU.png` ... `ENEMIES.png`, `BOSSES.png`). A record, not a build step:
the scripts use Node and the `sharp` package, and point at the folder the sheets were in
(`C:/Users/PC/Downloads/NEW ASSETS/`).

Order: `crop.js` (hero cells) -> `heroes.js`; `eb.js` -> `ebbuild.js` (enemies, bosses); `quant.js`
(shrinks the PNGs to 256 colours and writes them into `assets/`).

Rule used everywhere: the middle of a picture's bottom edge is the figure's feet, and the game
draws a picture at pixels / 2.5 units (`lib/game/art_scale.dart`). A hero's walking picture is about
240x300 pixels = 96x120 units. Walk, jump, hurt pictures share one canvas per hero; attack, idle and
win pictures share a wider one so the slash effect fits.

Per hero: `walk_1..4` (Lapu 5), `jump`, `hurt`, `attack_1..4` (Lapu 3), `idle`, `win`.
`attack_1` is the ground strike, `attack_2` then `attack_3` the air strike, `attack_4` the recovery.
Per enemy: `_1.._3` walking pictures, `_idle`, `_hurt`, `_attack`.
Per boss: `_idle`, `_move`, `_attack`, `_special`, `_hurt`, `_defeated`.

## Era artifact icons (2026-11-08)

`artifacts.js` cuts the 60 artifact icons out of `NEW ARTIFACTS.png` (6 era blocks, 2 rows x 5 icons each,
black title text between them is dropped by colour; small leftover pieces such as the flag's edge are grouped
with their icon). Each icon is trimmed, fitted into a 128x128 transparent square (4% margin) and quantised to
256 colours: `assets/collectibles/artifact_<eraId>_<1..10>.png` (about 530 KB in all). Run with
`node artifacts.js [canvas]` (needs `sharp`: `npm i sharp` in any folder, then `NODE_PATH=<that>/node_modules`).
It also writes a contact sheet to `C:/temp/artifacts_sheet.png` to check the order by eye. The game picks the
picture with `artifactAsset(eraId, index)` in `lib/models/artifact_art.dart`.

Maria Clara (2026-11-08): `mariaclara.js`. Her sheet (`MARIA CLARA.png`) has the 12 poses twice; the bottom copy
has no frame line and is the one cut. Same hero contract (4 walk, jump, hurt, 4 attack, idle, win), 258x304 walk
canvas and 408x304 attack canvas. The script clears faint edge fringes before cutting, then shrinks to 256 colours
into `assets/characters/mariaclara_*.png`. Needs `sharp` on NODE_PATH and an empty working folder (it writes `out/`).
