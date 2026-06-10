# jumpman

You inherit `../../CLAUDE.md` (the gamelab shared stack, tools, and conventions) —
this file holds only THIS game's specifics.

## Design
A side-scrolling platformer with *Super Mario Bros.*-style **physics/feel** but a
deliberately **non-Mario look**: it's re-skinned with Kenney's CC0 **"New Platformer
Pack"** (clean vector art) — green round-headed hero, purple slime enemy, grass/dirt
terrain, brick & coin blocks, hex coins, green-block pillars (in place of pipes),
and a green flag goal. A **blaster power-up** is hidden in the **`!` block** near the
start: bonk it to pop the blaster out, then **walk over it to collect** — only then
can the hero shoot (held in-hand with a bobbing arm). With it, **Right Bumper** fires
**laser bolts** that fly dead-straight in the facing direction and vaporize slimes
(no gravity or bounce, unlike Mario's arcing fireball). Core loop: run, jump, grab
the blaster, then shoot/stomp slimes, bonk `?`-blocks for coins, dodge pits, reach
the flag. **Two courses:** overworld **1-1**, then a darker **underground 1-2**
(SMB-style) — clear one to advance, carrying score/lives/blaster.

Art lives in `assets/` (player/ enemy/ tiles/ bg/), copied from
`asset-library/new-platformer-pack` — **CC0, no attribution required**
(`assets/KENNEY-LICENSE.txt`). To restyle, drop in a different Kenney pack and remap
paths in `src/sprites.lua`. (History: the first cut used hand-drawn procedural
pixel art; we swapped to Kenney art to move it away from looking like Mario.)

The name is a nod to Mario's debut billing as "Jumpman" in *Donkey Kong* —
trademark-clean.

## Architecture
- **`src/world.lua`** — PURE logic (no `love.*`): tile-grid AABB collision
  (axis-separated), run/jump physics with **variable jump height** (hold = higher),
  goomba AI + stomp, coins/`?`-blocks, flag goal. Fully busted-tested.
- **`src/level.lua`** (overworld) + **`src/level2.lua`** (underground) — the courses,
  built **programmatically** (not hand-aligned ASCII) so column placement is exact.
  Each returns `{w,h,grid,spawns,theme}`. `scene.lua` holds the ordered `levels`
  list; clearing one advances to the next, carrying score/lives/blaster.
  **Themes** (`theme` field → `sprites.setTheme`) swap ground/brick/pillar art +
  background: `overworld` (grass/dirt + parallax hills) vs `underground` (stone/grey
  brick/blue block + dark cavern).
- **`src/sprites.lua`** — rendering edge (the `love.*` side): loads the Kenney PNGs
  from `assets/` and draws player/enemy/tiles/coins/background (image cache + simple
  walk-cycle animation off the wall clock).
- **`src/scene.lua`** — camera, visible-tile culling, HUD (with readability bars),
  win overlay; wires input → world → sprites.
- **`src/input.lua`** — action map (below).
- **`src/music.lua`** — ORIGINAL background music, synthesized in pure Lua (a looping
  4-bar chiptune; no audio file). **`src/sfx.lua`** — CC0 Kenney SFX (jump/coin/
  stomp/bump/hurt/win) + a synthesized pit-fall sweep. Both silent under the harness
  (`_G.HARNESS`, set in `main.lua`); `scene.lua` fires SFX on world state-edges.

### Tile glyphs (`level.lua` / `world.lua`)
`#` ground · `B` brick (breakable only when big) · `?` coin-block → `U` spent ·
`G` gun-block (`!`, releases the blaster power-up) → `U` · `P` solid pillar (green
block; logic treats it like the old pipe) · `o` coin · `F` flag · `=` castle/base.
Spawns: `@` player, `g` slime.

## Controls (gamepad-first; keyboard mirrors)
| action | keyboard | gamepad |
|--------|----------|---------|
| move   | Arrows / A,D | D-pad L/R |
| jump   | Z / Space / W / Up (hold = higher) | A / B |
| run    | Shift / X | X / Y |
| shoot  | F | Right Bumper (R1) |
| quit   | Esc | Start |

Harness example: `tools/shot jumpman --keys "right+run:54,jump+right:14,right:28"`.

## Status / TODO
Working: physics, collision, camera, slimes + stomp, coins, `?`-blocks, flag win,
death/respawn, HUD, parallax background, **Kenney CC0 art re-skin**, **blaster
power-up** (`!` block → collect → forward laser bolts; held in-hand w/ walk bob),
music + SFX, **two levels** (overworld 1-1 → underground 1-2) with theme swap +
carry-over progression. 30 specs green.
Next: mushroom power-up (big/small code paths exist but no spawn yet) · flag-slide
+ level-complete sequence · more enemies (koopa) · sound · additional courses ·
juice (stomp squash already in; add coin-collect sparkle, landing dust).
