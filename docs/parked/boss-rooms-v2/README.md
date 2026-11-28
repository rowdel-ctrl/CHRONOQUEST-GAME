# Boss rooms v2 (PARKED, nothing built in the game)

Decided 2026-11-28: the user liked the idea but said "save this new layout" and build the other items first.
Mockup (private artifact): https://claude.ai/artifact/Vt4rQUvXmSXk64dC5cERdu

## What it is
All six boss arenas get a new left half (mirrored for the right), made only of SOLID ground blocks, no floating
platforms, nothing taller than 4 tiles (96 units). A different kind of structure in each room:

| Era | Layout (runs of [columns, height in tiles], left half, 49 columns before the stage) |
|---|---|
| pre-colonial | boulders: `[2,7],[6,0],[5,-1],[2,0],[2,2],[2,0],[3,3],[2,0],[2,2],[23,0]` |
| spanish | gatehouse: `[2,7],[6,0],[4,0],[5,3],[4,0],[5,3],[23,0]` |
| nationalism | plaza dais: `[2,7],[8,2],[3,1],[4,0],[2,2],[3,3],[2,2],[25,0]` |
| american | sandbag barricades: `[2,7],[6,0],[2,1],[2,0],[1,1],[3,0],[2,2],[4,0],[2,3],[25,0]` |
| ww2 | collapsed bridge ramp: `[2,7],[6,0],[4,-1],[1,1],[2,0],[2,1],[2,2],[2,3],[3,4],[25,0]` |
| modern | marble ziggurat: `[2,7],[6,0],[8,0],[2,1],[2,2],[2,3],[4,4],[2,3],[2,2],[2,1],[17,0]` |

`check_layouts.js` runs each through the arena solver (run it with `node check_layouts.js <outdir>`): all six pass
(0 trap spots, every raised block reachable, minion spots 38 and 42 keep 6 flat columns each side, boss ground reachable).
Rule learned: a block 1 column wide cannot be stood on, and a tower's inner side must be climbable too (it failed first when it dropped straight to 48).

## Consequences to remember when building it
- `tools/levelgen/arenas.js` needs solid-block specs (no `towers`, no `scroll_spot` requirement, the "ledge out of the minions' reach" rule dropped).
- The Spanish look: a stone tile sheet for the boss room only (see the stone mockup: SeKQWdTwoHQ4ToTnhTrw7P); the other five eras need their own sheets (rock, brick, sandbag, concrete, marble).
- Minions cannot climb or jump (wall check, `EnemyComponent._wallAhead`), so a block is safe once you are well inside it; the edge of a 1 to 2 tile block can still be touched.
- Boss-room question scroll spots (`scroll_spot`) are NOT used by the fight any more (the rune is), so they can go.
- Optional later: ledges attached to a block (balcony, scaffold) if the rooms feel flat.
