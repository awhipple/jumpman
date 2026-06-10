-- scene.lua — wires pure logic (world) to rendering + input. love.* lives here.
-- Camera follows the player; only on-screen tiles are drawn. The world canvas is
-- 1280x800 (Deck-native); the level (15 tiles ≈ 720px) sits on an 80px sky band.

local World   = require("src.world")
local level   = require("src.level")
local input   = require("src.input")
local sprites = require("src.sprites")
local music   = require("src.music")
local sfx     = require("src.sfx")

local scene = {}

local VW, VH = 1280, 800
local TILE = World.TILE
local OY = VH - level.h * TILE        -- vertical offset (sky band on top)

local function dyingCount(w)
  local n = 0
  for _, g in ipairs(w.goombas) do if g.dying then n = n + 1 end end
  return n
end

local function snapshot(w)
  return {
    onGround = w.player.onGround, coins = w.coins, lives = w.lives,
    big = w.player.big, dead = w.dead, won = w.won, dying = dyingCount(w),
  }
end

function scene.load()
  scene.world = World.new(level)
  scene.bigfont = love.graphics.newFont(40)
  scene.font = love.graphics.newFont(22)
  scene.small = love.graphics.newFont(16)
  sfx.load()
  music.start()
  scene.prev = snapshot(scene.world)
end

-- compare this frame to last to fire one-shot sounds on state transitions
local function playEvents(w, prev)
  if prev.onGround and not w.player.onGround and w.player.vy < -50 then sfx.play("jump", 0.5) end
  if w.coins > prev.coins                       then sfx.play("coin", 0.55) end
  if dyingCount(w) > prev.dying                 then sfx.play("stomp", 0.6) end
  if prev.big and not w.player.big              then sfx.play("hurt", 0.6) end   -- shrank
  if w.dead and not prev.dead                   then sfx.play("fall", 0.6) end   -- pit / death
  if w.won and not prev.won then sfx.play("win", 0.7); music.stop() end
end

function scene.update(dt)
  if input.down("quit") then love.event.quit(); return end
  local w = scene.world
  w:update(dt, {
    left  = input.down("left"),
    right = input.down("right"),
    down  = input.down("down"),
    jump  = input.down("jump"),
    run   = input.down("run"),
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
  love.graphics.print(("LIVES  %d"):format(math.max(0, w.lives)), 520, 16)
  love.graphics.print(("TIME  %d"):format(math.max(0, math.floor(400 - w.time))), 720, 16)
  love.graphics.setFont(scene.small)
  love.graphics.setColor(1, 1, 1, 0.65)
  love.graphics.printf("D-Pad move    A jump (hold = higher)    X run    Start quit",
                      0, VH - 26, VW, "center")
end

function scene.draw()
  local w = scene.world
  local camX = w:cameraX(VW)

  sprites.background(camX, VW, VH)

  love.graphics.push()
  love.graphics.translate(-camX, OY)

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
  sprites.player(w.player)

  love.graphics.pop()

  drawHUD(w)

  if w.won then
    love.graphics.setColor(0, 0, 0, 0.45)
    love.graphics.rectangle("fill", 0, VH / 2 - 70, VW, 140)
    love.graphics.setFont(scene.bigfont)
    love.graphics.setColor(1, 0.95, 0.4)
    love.graphics.printf("COURSE CLEAR!", 0, VH / 2 - 24, VW, "center")
  end
end

return scene
