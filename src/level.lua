-- level.lua — world data, built programmatically for precise column placement
-- (hand-aligned ASCII across 15 rows is too error-prone to verify). Pure data,
-- no love.*. Produces { w, h, grid (rows of single-char strings), spawns }.
--
-- Tile glyphs:
--   ' ' empty   '#' ground   'B' brick   '?' coin-block   'P' pipe
--   'o' coin    'F' flag pole '=' flag base   (runtime adds 'U' used-block)
-- Spawn glyphs are stripped from the grid and returned as entities:
--   '@' player   'g' goomba

local W, H = 180, 15           -- columns, rows (1-indexed). Ground = bottom 2 rows.
local GROUND = H - 1           -- top row of the 2-tall ground band (surface row)

local g = {}                   -- g[row][col] = char
for r = 1, H do
  g[r] = {}
  for c = 1, W do g[r][c] = " " end
end

local spawns = { player = nil, goombas = {} }

local function set(c, r, ch) if g[r] and c >= 1 and c <= W then g[r][c] = ch end end
local function fillGround(c1, c2)
  for c = c1, c2 do g[H][c] = "#"; g[H - 1][c] = "#" end
end

-- ground with two pits
fillGround(1, 68)
fillGround(72, 106)
fillGround(110, W)

-- a low row of bricks/blocks the player can bonk (row 10: ~3 tiles above ground)
local BR = 10
set(17, BR, "?")
-- brick + coin-block cluster, coins floating above
for i, ch in ipairs({ "B", "?", "B", "B", "?", "B" }) do set(20 + i, BR, ch) end
for c = 22, 26 do set(c, BR - 2, "o") end
-- a single high coin-block
set(24, BR - 4, "?")

-- pipes (col, height in tiles). Sit on the ground surface, 2 tiles wide.
local function pipe(col, height)
  for h = 0, height - 1 do
    set(col, GROUND - h, "P")
    set(col + 1, GROUND - h, "P")
  end
end
pipe(30, 2)
pipe(40, 3)
pipe(49, 4)
pipe(59, 4)

-- goombas patrolling the field (one row above the surface; they fall onto it)
for _, c in ipairs({ 26, 45, 64, 90, 98, 132 }) do
  spawns.goombas[#spawns.goombas + 1] = { col = c, row = GROUND - 1 }
end

-- floating coins to lure the player over the first pit
for c = 69, 71 do set(c, BR - 1, "o") end

-- mid-level brick arch
for c = 82, 88 do set(c, BR - 3, "B") end
for c = 84, 86 do set(c, BR - 1, "o") end

-- ascending staircase (classic end-of-level), heights 1..4
for i = 0, 3 do
  for h = 0, i do set(130 + i, GROUND - h, "#") end
end
-- descending staircase
for i = 0, 3 do
  for h = 0, (3 - i) do set(136 + i, GROUND - h, "#") end
end

-- flag pole + base, then a couple of "castle" blocks
local FCOL = 165
for r = 3, GROUND do set(FCOL, r, "F") end
set(FCOL, 2, "F")                       -- pole topper
for c = 170, 172 do                     -- castle stub
  set(c, GROUND, "=")
  set(c, GROUND - 1, "=")
end
set(171, GROUND - 2, "=")

-- player start (one row above the surface; falls onto it on frame 1)
spawns.player = { col = 4, row = GROUND - 1 }

-- freeze grid rows into strings for cheap access + readable debug dumps
local rows = {}
for r = 1, H do rows[r] = table.concat(g[r]) end

return {
  w = W,
  h = H,
  ground_row = GROUND,
  grid = rows,         -- array of H strings, each W chars
  spawns = spawns,
}
