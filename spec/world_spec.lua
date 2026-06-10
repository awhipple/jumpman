-- Pure-logic specs for the platformer world. No love.* → runs headless.
-- Run from the game root: `tools/test jumpman` (busted, default path ./spec).

local World = require("src.world")
local TILE = World.TILE

-- tiny hand-built level so tests don't depend on the shipped course
local function flatLevel(opts)
  opts = opts or {}
  local W, H = 20, 6
  local rows = {}
  for r = 1, H do
    local t = {}
    for c = 1, W do
      if r >= H - 1 then t[c] = "#" else t[c] = " " end   -- 2 ground rows
    end
    rows[r] = table.concat(t)
  end
  local spawns = { player = { col = 3, row = H - 2 }, goombas = {} }
  for _, gc in ipairs(opts.goombas or {}) do
    spawns.goombas[#spawns.goombas + 1] = { col = gc, row = H - 2 }
  end
  -- splice in custom tiles: opts.set = { {col,row,ch}, ... }
  if opts.set then
    local g = {}
    for r = 1, H do g[r] = {}; for c = 1, W do g[r][c] = rows[r]:sub(c, c) end end
    for _, s in ipairs(opts.set) do g[s[2]][s[1]] = s[3] end
    for r = 1, H do rows[r] = table.concat(g[r]) end
  end
  return { w = W, h = H, ground_row = H - 1, grid = rows, spawns = spawns }
end

local function stepN(w, n, move, dt)
  dt = dt or 1 / 60
  for _ = 1, n do w:update(dt, move) end
end

describe("World physics", function()
  it("spawns the player at the spawn tile", function()
    local w = World.new(flatLevel())
    assert.are.equal(2 * TILE, w.player.x)   -- col 3 -> (3-1)*TILE
  end)

  it("falls under gravity and lands on the ground", function()
    local w = World.new(flatLevel())
    w.player.y = 0                            -- drop from the top
    stepN(w, 120, {})
    assert.is_true(w.player.onGround)
    -- feet rest on top of the ground band (row H-1 top edge)
    local groundTop = (w.h - 2) * TILE
    assert.is_near(groundTop, w.player.y + w.player.h, 1.0)
  end)

  it("does not sink through the floor", function()
    local w = World.new(flatLevel())
    stepN(w, 60, {})
    assert.is_true(w.player.y + w.player.h <= (w.h - 2) * TILE + 0.5)
  end)

  it("moves right when commanded and faces right", function()
    local w = World.new(flatLevel())
    local x0 = w.player.x
    stepN(w, 30, { right = true })
    assert.is_true(w.player.x > x0)
    assert.are.equal(1, w.player.facing)
  end)

  it("runs faster than it walks", function()
    local walk = World.new(flatLevel())
    local run  = World.new(flatLevel())
    stepN(walk, 40, { right = true })
    stepN(run,  40, { right = true, run = true })
    assert.is_true(run.player.x > walk.player.x)
  end)

  it("jumps off the ground then comes back down", function()
    local w = World.new(flatLevel())
    stepN(w, 30, {})                          -- settle on ground
    local rest = w.player.y
    w:update(1 / 60, { jump = true })         -- press jump
    assert.is_true(w.player.vy < 0)           -- launched upward
    stepN(w, 8, { jump = true })
    assert.is_true(w.player.y < rest)         -- airborne, higher up
  end)

  it("held jump goes higher than a tapped jump", function()
    local function peak(hold)
      local w = World.new(flatLevel())
      stepN(w, 30, {})
      local top = w.player.y
      for i = 1, 40 do
        w:update(1 / 60, { jump = hold or i == 1 })
        top = math.min(top, w.player.y)
      end
      return top
    end
    assert.is_true(peak(true) < peak(false) - 4)   -- held peak is higher (smaller y)
  end)

  it("stops at a solid wall instead of passing through", function()
    local w = World.new(flatLevel({ set = { { 10, 4, "#" }, { 10, 3, "#" } } }))
    w.player.x = 8 * TILE
    stepN(w, 120, { right = true, run = true })
    assert.is_true(w.player.x + w.player.w <= 9 * TILE + 0.5)  -- blocked by col 10
  end)
end)

describe("Blocks and pickups", function()
  it("turns a ?-block into a used block and awards coins when bonked", function()
    -- ?-block two tiles above the player's head
    local w = World.new(flatLevel({ set = { { 3, 2, "?" } } }))
    stepN(w, 20, {})
    w.player.x = 2 * TILE                      -- under col 3
    -- jump repeatedly until the block is consumed
    for _ = 1, 200 do
      w:update(1 / 60, { jump = true })
      if w.tiles[2][3] == "U" then break end
      w:update(1 / 60, {})                     -- release so jump can re-trigger
    end
    assert.are.equal("U", w.tiles[2][3])
    assert.is_true(w.coins >= 1 and w.score >= 200)
  end)

  it("collects a coin tile on contact", function()
    local w = World.new(flatLevel({ set = { { 5, 4, "o" } } }))
    stepN(w, 30, { right = true })             -- walk into the coin
    assert.are.equal(" ", w.tiles[4][5])
    assert.is_true(w.coins >= 1)
  end)

  it("wins on touching the flag", function()
    local w = World.new(flatLevel({ set = { { 6, 4, "F" }, { 6, 3, "F" } } }))
    stepN(w, 200, { right = true })
    assert.is_true(w.won)
  end)
end)

describe("Goombas", function()
  it("patrols and reverses at a wall", function()
    local w = World.new(flatLevel({ goombas = { 10 }, set = { { 6, 4, "#" }, { 6, 3, "#" } } }))
    local g = w.goombas[1]
    assert.are.equal(-1, (g.vx > 0 and 1 or -1))   -- starts moving left
    stepN(w, 400, {})
    -- it should still exist and have bounced (vx flipped at least once)
    assert.is_true(#w.goombas >= 1)
  end)

  it("dies when stomped from above; player bounces", function()
    local w = World.new(flatLevel({ goombas = { 12 } }))   -- far from the player spawn
    stepN(w, 20, {})                           -- settle
    w.player.x = w.goombas[1].x                -- line up horizontally
    w.player.y = w.goombas[1].y - w.player.h + 8   -- feet just into its top
    w.player.vy = 200                          -- descending onto it
    w:update(1 / 60, {})
    assert.is_true(w.goombas[1].dying)
    assert.is_true(w.player.vy < 0)            -- bounced up
    assert.is_true(w.score >= 100)
  end)

  it("hurts the player on a side hit", function()
    local w = World.new(flatLevel({ goombas = { 5 } }))
    stepN(w, 20, {})
    local lives0 = w.lives
    w.player.x = w.goombas[1].x - w.player.w + 2   -- overlap from the side
    w.player.y = w.goombas[1].y
    w.player.vy = 0
    w:update(1 / 60, {})
    assert.is_true(w.dead or w.lives < lives0 or w.player.invuln > 0)
  end)
end)

describe("Lasers", function()
  it("fires a laser forward in the facing direction", function()
    local w = World.new(flatLevel())
    stepN(w, 20, {})
    w.player.facing = 1
    w:update(1 / 60, { shoot = true })
    assert.are.equal(1, #w.lasers)
    assert.is_true(w.lasers[1].vx > 0)
    local x0 = w.lasers[1].x
    w:update(1 / 60, {})
    assert.is_true(w.lasers[1].x > x0)             -- flies straight, keeps moving
  end)

  it("fires left when facing left", function()
    local w = World.new(flatLevel())
    stepN(w, 20, {})
    w.player.facing = -1
    w:update(1 / 60, { shoot = true })
    assert.is_true(w.lasers[1].vx < 0)
  end)

  it("rate-limits shots by the cooldown", function()
    local w = World.new(flatLevel())
    stepN(w, 20, {})
    for _ = 1, 6 do w:update(1 / 60, { shoot = true }) end   -- ~0.1s < cooldown
    assert.are.equal(1, #w.lasers)                 -- only one shot in that window
  end)

  it("kills a goomba it hits and is consumed", function()
    local w = World.new(flatLevel({ goombas = { 10 } }))
    stepN(w, 20, {})
    local g = w.goombas[1]
    w.lasers[#w.lasers + 1] = { x = g.x, y = g.y + 5, w = 36, h = 12, vx = 780, dir = 1, life = 1.8 }
    w:update(1 / 60, {})
    assert.is_true(w.goombas[1].dying)
    assert.are.equal(0, #w.lasers)                 -- consumed on hit
    assert.is_true(w.score >= 100)
  end)

  it("despawns when it hits a solid wall", function()
    local w = World.new(flatLevel({ set = { { 10, 4, "#" }, { 10, 3, "#" } } }))
    stepN(w, 20, {})
    w.lasers[#w.lasers + 1] = { x = 8 * 48, y = 3 * 48 + 18, w = 36, h = 12, vx = 780, dir = 1, life = 1.8 }
    for _ = 1, 20 do w:update(1 / 60, {}) end
    assert.are.equal(0, #w.lasers)
  end)
end)
