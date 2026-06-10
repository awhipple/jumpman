-- scene.lua — wires pure logic (world) to rendering + input. love.* lives here.
-- Camera follows the player; only on-screen tiles are drawn. The world canvas is
-- 1280x800 (Deck-native); the level sits on a band offset (VH - level height).
-- Multiple levels: clear one and it advances to the next (carrying score/lives/
-- blaster), each with its own theme (overworld / underground).

local World   = require("src.world")
local levels  = { require("src.level"), require("src.level2") }
local input   = require("src.input")
local sprites = require("src.sprites")
local music   = require("src.music")
local sfx     = require("src.sfx")

local scene = {}

local VW, VH = 1280, 800
local TILE = World.TILE
local LEVEL_CLEAR_DELAY = 2.4         -- banner time before advancing to the next level

local function dyingCount(w)
  local n = 0
  for _, g in ipairs(w.goombas) do if g.dying then n = n + 1 end end
  return n
end

local function snapshot(w)
  return {
    onGround = w.player.onGround, coins = w.coins, lives = w.lives,
    big = w.player.big, dead = w.dead, won = w.won, dying = dyingCount(w),
    shots = w.shotsFired, blaster = w.player.hasBlaster,
  }
end

-- build a level's world, apply its theme, carry stats forward from the last level
local function buildWorld(index, carry)
  local w = World.new(levels[index])
  sprites.setTheme(w.theme)
  if carry then
    w.score = carry.score
    w.lives = carry.lives
    w.player.hasBlaster = carry.hasBlaster
  end
  return w
end

function scene.loadLevel(index, carry)
  scene.levelIndex = index
  scene.world = buildWorld(index, carry)
  scene.transition = nil
  scene.prev = snapshot(scene.world)
end

function scene.load()
  scene.bigfont = love.graphics.newFont(40)
  scene.font = love.graphics.newFont(22)
  scene.small = love.graphics.newFont(16)
  sfx.load()
  music.start()
  scene.age = 0          -- seconds since launch (quit grace period)
  scene.quitPrev = false -- for edge-triggered quit
  scene.loadLevel(1)
end

-- compare this frame to last to fire one-shot sounds on state transitions
local function playEvents(w, prev)
  if w.player.hasBlaster and not prev.blaster   then sfx.play("powerup", 0.7) end
  if w.shotsFired > prev.shots                  then sfx.play("laser", 0.45) end
  if prev.onGround and not w.player.onGround and w.player.vy < -50 then sfx.play("jump", 0.5) end
  if w.coins > prev.coins                       then sfx.play("coin", 0.55) end
  if dyingCount(w) > prev.dying                 then sfx.play("stomp", 0.6) end
  if prev.big and not w.player.big              then sfx.play("hurt", 0.6) end   -- shrank
  if w.dead and not prev.dead                   then sfx.play("fall", 0.6) end   -- pit / death
  if w.won and not prev.won                     then sfx.play("win", 0.7) end
end

function scene.update(dt)
  -- Quit only on a FRESH press, and never in the first moments after launch — so a
  -- button still held from the launcher menu can't immediately snap the game shut.
  scene.age = scene.age + dt
  local q = input.down("quit")
  if scene.age > 0.4 and q and not scene.quitPrev then
    scene.quitPrev = q; love.event.quit(); return
  end
  scene.quitPrev = q

  local w = scene.world

  if w.won then                       -- level cleared: hold the banner, then advance
    scene.transition = (scene.transition or LEVEL_CLEAR_DELAY) - dt
    if scene.transition <= 0 and scene.levelIndex < #levels then
      scene.loadLevel(scene.levelIndex + 1, {
        score = w.score, lives = w.lives, hasBlaster = w.player.hasBlaster,
      })
    end
    return
  end

  w:update(dt, {
    left  = input.down("left"),
    right = input.down("right"),
    down  = input.down("down"),
    jump  = input.down("jump"),
    run   = input.down("run"),
    shoot = input.down("shoot"),
  })
  playEvents(w, scene.prev)
  scene.prev = snapshot(w)
end

local function drawHUD(w)
  -- translucent bars so text stays readable over any background
  love.graphics.setColor(0, 0, 0, 0.38)
  love.graphics.rectangle("fill", 0, 0, VW, 52)
  love.graphics.rectangle("fill", 0, VH - 30, VW, 30)
  love.graphics.setFont(scene.font)
  love.graphics.setColor(1, 1, 1)
  love.graphics.print(("SCORE  %06d"):format(w.score), 28, 16)
  love.graphics.print(("COINS  %02d"):format(w.coins), 300, 16)
  love.graphics.print(("LIVES  %d"):format(math.max(0, w.lives)), 500, 16)
  love.graphics.print(("WORLD  1-%d"):format(scene.levelIndex), 680, 16)
  love.graphics.print(("TIME  %d"):format(math.max(0, math.floor(400 - w.time))), 900, 16)
  love.graphics.setFont(scene.small)
  love.graphics.setColor(1, 1, 1, 0.65)
  love.graphics.printf("D-Pad move    A jump (hold=higher)    X run    R1 shoot    Start quit",
                      0, VH - 26, VW, "center")
end

function scene.draw()
  local w = scene.world
  local camX = w:cameraX(VW)
  local oy = VH - w.h * TILE

  sprites.background(camX, VW, VH)

  love.graphics.push()
  love.graphics.translate(-camX, oy)

  -- visible tile range
  local c0 = math.max(1, math.floor(camX / TILE))
  local c1 = math.min(w.w, math.ceil((camX + VW) / TILE) + 1)
  for r = 1, w.h do
    for c = c0, c1 do
      local ch = w.tiles[r][c]
      if ch == "o" then
        sprites.coin((c - 1) * TILE, (r - 1) * TILE, TILE, w.time)
      elseif ch ~= " " then
        local opts
        if ch == "#" then
          opts = { grassTop = (w:tileAt(c, r - 1) ~= "#") }
        end
        sprites.tile(ch, (c - 1) * TILE, (r - 1) * TILE, TILE, opts, w.time)
      end
    end
  end

  -- coin-pop effects
  for _, e in ipairs(w.effects) do
    if e.type == "coin" then sprites.coin(e.x - TILE / 2, e.y, TILE, w.time) end
  end

  for _, g in ipairs(w.goombas) do sprites.goomba(g) end
  for _, m in ipairs(w.powerups) do sprites.powerup(m) end
  for _, L in ipairs(w.lasers) do sprites.laser(L) end
  sprites.player(w.player)

  love.graphics.pop()

  drawHUD(w)

  if w.won then
    local last = scene.levelIndex >= #levels
    love.graphics.setColor(0, 0, 0, 0.45)
    love.graphics.rectangle("fill", 0, VH / 2 - 70, VW, 140)
    love.graphics.setFont(scene.bigfont)
    love.graphics.setColor(1, 0.95, 0.4)
    love.graphics.printf(last and "YOU WIN!" or "LEVEL CLEAR!", 0, VH / 2 - 24, VW, "center")
  end
end

return scene
