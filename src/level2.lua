-- level2.lua — the UNDERGROUND course (theme "underground": stone floor/ceiling,
-- grey bricks, blue-block pillars, dark background). Same data contract + glyphs as
-- level.lua; built programmatically so column placement is exact. No gun block —
-- the player carries the blaster collected in level 1.

local W, H = 150, 15
local GROUND = H - 1                 -- surface row (top of the 2-tall floor band)

local g = {}
for r = 1, H do g[r] = {}; for c = 1, W do g[r][c] = " " end end
local spawns = { player = nil, goombas = {} }

local function set(c, r, ch) if g[r] and c >= 1 and c <= W then g[r][c] = ch end end
local function fillRow(r, c1, c2, ch) for c = c1, c2 do set(c, r, ch) end end
local function fillGround(c1, c2)
  for c = c1, c2 do g[H][c] = "#"; g[H - 1][c] = "#" end
end

-- enclosing cavern: a stone ceiling across the top, stone floor with two pits
fillRow(1, 1, W, "#")
fillGround(1, 43); fillGround(47, 95); fillGround(99, W)

-- brick stalactites hanging from the ceiling (obstacles; corridor stays open below)
local function hang(col, depth) for r = 2, 1 + depth do set(col, r, "B") end end
hang(12, 4); hang(13, 4)
hang(30, 5)
hang(70, 3); hang(71, 3)
hang(110, 4)

-- stone steps rising from the floor
local function stepUp(col, h) for k = 0, h - 1 do set(col, GROUND - k, "#") end end
stepUp(22, 2); stepUp(23, 3)
stepUp(60, 2); stepUp(61, 3); stepUp(62, 2)

-- blue-block pillars (the underground "pipes")
local function pillar(col, height)
  for h = 0, height - 1 do set(col, GROUND - h, "P"); set(col + 1, GROUND - h, "P") end
end
pillar(35, 3); pillar(80, 4)

-- floating brick platforms with coins above
for c = 15, 19 do set(c, 8, "B") end
for c = 16, 18 do set(c, 7, "o") end
for c = 50, 55 do set(c, 8, "B") end
for c = 51, 54 do set(c, 7, "o") end

-- coin blocks + a coin arch
set(28, 9, "?"); set(48, 9, "?")
for i, ch in ipairs({ "?", "B", "?" }) do set(75 + i, 9, ch) end
for c = 76, 78 do set(c, 7, "o") end

-- coin trails arcing over each pit (reward the jump)
for c = 44, 46 do set(c, 12, "o") end
for c = 96, 98 do set(c, 12, "o") end

-- slimes patrolling the corridor
for _, c in ipairs({ 18, 40, 56, 84, 105, 122 }) do
  spawns.goombas[#spawns.goombas + 1] = { col = c, row = GROUND - 1 }
end

-- end-of-level staircase (up then down), then the flag
for i = 0, 3 do for k = 0, i do set(130 + i, GROUND - k, "#") end end
for i = 0, 3 do for k = 0, (3 - i) do set(136 + i, GROUND - k, "#") end end
set(144, GROUND - 1, "F")

spawns.player = { col = 3, row = GROUND - 1 }

local rows = {}
for r = 1, H do rows[r] = table.concat(g[r]) end

return { w = W, h = H, ground_row = GROUND, theme = "underground", grid = rows, spawns = spawns }
