-- world.lua — PURE game logic (no love.*), so busted tests it headless.
-- Side-scrolling platformer: tile-grid collision, run/jump physics with variable
-- jump height, stompable goombas, coin/coin-blocks, a flag goal. Rendering and
-- input live at the edges (scene.lua / input.lua); this module just simulates.

local World = {}
World.__index = World

-- ---- tuning ---------------------------------------------------------------
local TILE      = 48
World.TILE      = TILE

local GRAVITY   = 2600      -- px/s^2 normal fall
local JUMP_HOLD = 1150      -- reduced gravity while ascending & holding jump
local MAX_FALL  = 1100
local JUMP_V    = -880      -- initial jump velocity (≈ 3 tiles peak)

local WALK_ACC  = 1500
local RUN_ACC   = 2100
local MAX_WALK  = 320
local MAX_RUN   = 560
local FRICTION  = 1700      -- ground decel when no input
local AIR_ACC   = 1000      -- horizontal accel while airborne

local GOOMBA_V  = 70

local SOLID = { ["#"] = true, ["B"] = true, ["?"] = true, ["P"] = true,
                ["U"] = true, ["="] = true }

local function sign(n) return n > 0 and 1 or (n < 0 and -1 or 0) end
local function clamp(v, lo, hi) return v < lo and lo or (v > hi and hi or v) end

local function overlap(a, b)
  return a.x < b.x + b.w and a.x + a.w > b.x
     and a.y < b.y + b.h and a.y + a.h > b.y
end

-- ---- construction ---------------------------------------------------------
function World.new(level)
  local self = setmetatable({}, World)
  self.level = level
  self.w, self.h = level.w, level.h
  self.pxw, self.pxh = level.w * TILE, level.h * TILE

  -- mutable 2D char grid (so blocks can change at runtime)
  self.tiles = {}
  for r = 1, level.h do
    self.tiles[r] = {}
    local rowstr = level.grid[r]
    for c = 1, level.w do
      self.tiles[r][c] = rowstr:sub(c, c)
    end
  end

  -- entities
  local ps = level.spawns.player
  self.spawn = { x = (ps.col - 1) * TILE, y = (ps.row - 1) * TILE }
  self.player = {
    x = self.spawn.x, y = self.spawn.y, w = 34, h = 44,
    vx = 0, vy = 0, onGround = false, facing = 1,
    big = false, jumping = false, jumpHeld = false, invuln = 0,
  }

  self.goombas = {}
  for _, gs in ipairs(level.spawns.goombas) do
    self.goombas[#self.goombas + 1] = {
      x = (gs.col - 1) * TILE, y = (gs.row - 1) * TILE,
      w = 40, h = 40, vx = -GOOMBA_V, vy = 0,
      onGround = false, facing = -1, dying = false, dyt = 0,
    }
  end

  self.effects = {}     -- coin pops etc. (purely cosmetic)
  self.score, self.coins, self.lives = 0, 0, 3
  self.time = 0
  self.dead, self.won, self.respawn_t = false, false, 0
  return self
end

-- ---- tile helpers ---------------------------------------------------------
function World:tileAt(c, r)
  if r < 1 or r > self.h or c < 1 or c > self.w then return " " end
  return self.tiles[r][c]
end

function World:solidAt(c, r)
  if r > self.h then return false end          -- below map = pit (fall through)
  return SOLID[self:tileAt(c, r)] == true
end

local function colAt(px) return math.floor(px / TILE) + 1 end
local function rowAt(px) return math.floor(px / TILE) + 1 end

-- Resolve one axis against the grid AFTER the body has already been moved.
-- Returns a hit descriptor {c, r, side} or nil.
function World:resolve(e, axis)
  local c1, c2 = colAt(e.x), colAt(e.x + e.w - 0.001)
  local r1, r2 = rowAt(e.y), rowAt(e.y + e.h - 0.001)
  for r = r1, r2 do
    for c = c1, c2 do
      if self:solidAt(c, r) then
        if axis == "x" then
          if e.vx > 0 then e.x = (c - 1) * TILE - e.w
          elseif e.vx < 0 then e.x = c * TILE end
          local hit = { c = c, r = r, side = e.vx > 0 and "right" or "left" }
          e.vx = 0
          return hit
        else
          if e.vy > 0 then
            e.y = (r - 1) * TILE - e.h; e.onGround = true; e.vy = 0
            return { c = c, r = r, side = "bottom" }
          elseif e.vy < 0 then
            e.y = r * TILE; e.vy = 0
            return { c = c, r = r, side = "top" }
          end
        end
      end
    end
  end
  return nil
end

-- ---- player ---------------------------------------------------------------
function World:updatePlayer(dt, move)
  local p = self.player
  local accel = p.onGround and (move.run and RUN_ACC or WALK_ACC) or AIR_ACC
  local maxv  = move.run and MAX_RUN or MAX_WALK
  local dir   = (move.right and 1 or 0) - (move.left and 1 or 0)

  if dir ~= 0 then
    p.vx = clamp(p.vx + dir * accel * dt, -maxv, maxv)
    p.facing = dir
  elseif p.onGround then
    local s = FRICTION * dt
    p.vx = (math.abs(p.vx) <= s) and 0 or (p.vx - s * sign(p.vx))
  end

  -- jump (edge-triggered; variable height while held)
  if move.jump and not p.jumpHeld and p.onGround then
    p.vy = JUMP_V; p.jumping = true
  end
  if not move.jump then p.jumping = false end
  p.jumpHeld = move.jump and true or false

  local grav = (p.jumping and move.jump and p.vy < 0) and JUMP_HOLD or GRAVITY
  p.vy = math.min(p.vy + grav * dt, MAX_FALL)

  -- integrate + collide, axis-separated
  p.x = clamp(p.x + p.vx * dt, 0, self.pxw - p.w)
  self:resolve(p, "x")
  p.onGround = false
  p.y = p.y + p.vy * dt
  local hy = self:resolve(p, "y")
  if hy and hy.side == "top" then self:bumpBlock(hy.c, hy.r) end

  if p.invuln > 0 then p.invuln = p.invuln - dt end
  if p.y > self.pxh then self:killPlayer(true) end
end

-- head-bonk a block from below
function World:bumpBlock(c, r)
  local ch = self:tileAt(c, r)
  if ch == "?" then
    self.tiles[r][c] = "U"
    self.coins = self.coins + 1
    self.score = self.score + 200
    self:coinPop(c, r)
  elseif ch == "B" and self.player.big then
    self.tiles[r][c] = " "
    self.score = self.score + 50
  end
end

function World:coinPop(c, r)
  self.effects[#self.effects + 1] = {
    x = (c - 1) * TILE + TILE / 2, y = (r - 1) * TILE,
    vy = -520, life = 0.5, type = "coin",
  }
end

function World:killPlayer(pit)
  local p = self.player
  if not pit and p.invuln > 0 then return end
  self.dead = true
  self.lives = self.lives - 1
  p.vy = -720
  self.respawn_t = 1.4
end

function World:respawnPlayer()
  local p = self.player
  p.x, p.y, p.vx, p.vy = self.spawn.x, self.spawn.y, 0, 0
  p.onGround, p.invuln, p.big = false, 1.0, false
  p.h = 44
  self.dead = false
  if self.lives <= 0 then self.lives = 3 end   -- soft reset for now
end

-- ---- goombas --------------------------------------------------------------
function World:updateGoombas(dt)
  for i = #self.goombas, 1, -1 do
    local g = self.goombas[i]
    if g.dying then
      g.dyt = g.dyt - dt
      if g.dyt <= 0 then table.remove(self.goombas, i) end
    else
      g.vy = math.min(g.vy + GRAVITY * dt, MAX_FALL)
      g.x = g.x + g.vx * dt
      if self:resolve(g, "x") then g.vx = -g.vx; g.facing = sign(g.vx) end
      g.onGround = false
      g.y = g.y + g.vy * dt
      self:resolve(g, "y")
      if g.y > self.pxh then table.remove(self.goombas, i) end
    end
  end
end

function World:playerGoombas()
  local p = self.player
  for _, g in ipairs(self.goombas) do
    if not g.dying and overlap(p, g) then
      -- stomp when descending onto the goomba's top
      if p.vy > 0 and (p.y + p.h) - g.y < g.h then
        g.dying = true; g.dyt = 0.35; g.vx = 0; g.h = 20; g.y = g.y + 20
        p.vy = JUMP_V * 0.55
        self.score = self.score + 100
      elseif p.invuln <= 0 then
        if p.big then
          p.big = false; p.h = 44; p.y = p.y + 42; p.invuln = 1.2
        else
          self:killPlayer(false)
        end
      end
    end
  end
end

-- ---- pickups / goal -------------------------------------------------------
function World:collectCoins()
  local p = self.player
  local c1, c2 = colAt(p.x), colAt(p.x + p.w - 0.001)
  local r1, r2 = rowAt(p.y), rowAt(p.y + p.h - 0.001)
  for r = r1, r2 do
    for c = c1, c2 do
      local ch = self:tileAt(c, r)
      if ch == "o" then
        self.tiles[r][c] = " "
        self.coins = self.coins + 1
        self.score = self.score + 100
      elseif ch == "F" then
        self.won = true
      end
    end
  end
end

function World:updateEffects(dt)
  for i = #self.effects, 1, -1 do
    local e = self.effects[i]
    e.y = e.y + e.vy * dt
    e.vy = e.vy + 1400 * dt
    e.life = e.life - dt
    if e.life <= 0 then table.remove(self.effects, i) end
  end
end

-- ---- top-level tick -------------------------------------------------------
-- move = { left, right, jump, run, down } (any may be nil)
function World:update(dt, move)
  move = move or {}
  self:updateEffects(dt)
  if self.won then return end
  if self.dead then
    self.player.vy = self.player.vy + GRAVITY * dt
    self.player.y = self.player.y + self.player.vy * dt
    self.respawn_t = self.respawn_t - dt
    if self.respawn_t <= 0 then self:respawnPlayer() end
    return
  end
  self:updatePlayer(dt, move)
  self:updateGoombas(dt)
  self:playerGoombas()
  self:collectCoins()
  self.time = self.time + dt
end

-- camera x so the player sits ~40% from the left, clamped to the level
function World:cameraX(viewW)
  local p = self.player
  local cx = (p.x + p.w / 2) - viewW * 0.4
  return clamp(cx, 0, math.max(0, self.pxw - viewW))
end

return World
