# jumpman

You inherit `../../CLAUDE.md` (the gamelab shared stack, tools, and conventions) —
this file holds only THIS game's specifics.

## Design
A side-scrolling platformer in the mold of the original *Super Mario Bros.* World
1‑1, built with **100% original, hand-drawn graphics** (no imported sprites — the
hero and goomba are hand-authored pixel grids in `src/sprites.lua`, everything else
is procedural). Core loop: run and jump rightward across a tile course, bonk
`?`-blocks for coins, stomp goombas, dodge pits, reach the flag.

The name is a nod to Mario's debut billing as "Jumpman" in *Donkey Kong* — and
keeps us trademark-clean while we draw our own art.

## Architecture
- **`src/world.lua`** — PURE logic (no `love.*`): tile-grid AABB collision
  (axis-separated), run/jump physics with **variable jump height** (hold = higher),
  goomba AI + stomp, coins/`?`-blocks, flag goal. Fully busted-tested.
- **`src/level.lua`** — the course, built **programmatically** (not hand-aligned
  ASCII) so column placement is exact and verifiable. Returns `{w,h,grid,spawns}`.
- **`src/sprites.lua`** — all rendering / original art (the `love.*` edge).
- **`src/scene.lua`** — camera, visible-tile culling, HUD, win overlay; wires
  input → world → sprites.
- **`src/input.lua`** — action map (below).

### Tile glyphs (`level.lua` / `world.lua`)
`#` ground · `B` brick (breakable only when big) · `?` coin-block → `U` spent ·
`P` pipe · `o` coin · `F` flag pole · `=` castle/base. Spawns: `@` player, `g` goomba.

## Controls (gamepad-first; keyboard mirrors)
| action | keyboard | gamepad |
|--------|----------|---------|
| move   | Arrows / A,D | D-pad L/R |
| jump   | Z / Space / W / Up (hold = higher) | A / B |
| run    | Shift / X | X / Y |
| quit   | Esc | Start |

Harness example: `tools/shot jumpman --keys "right+run:54,jump+right:14,right:28"`.

## Status / TODO
Working: physics, collision, camera, goombas + stomp, coins, `?`-blocks, flag win,
death/respawn, HUD, parallax background. 14 specs green.
Next: mushroom power-up (big/small code paths exist but no spawn yet) · flag-slide
+ level-complete sequence · more enemies (koopa) · sound · additional courses ·
juice (stomp squash already in; add coin-collect sparkle, landing dust).
