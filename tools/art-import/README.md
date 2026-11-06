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
