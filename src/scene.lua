-- scene.lua — wires pure logic (world) to rendering + input. love.* lives here.
-- Camera follows the player; only on-screen tiles are drawn. The world canvas is
-- 1280x800 (Deck-native); the level (15 tiles ≈ 720px) sits on an 80px sky band.

local World   = require("src.world")
local level   = require("src.level")
local input   = require("src.input")
local sprites = require("src.sprites")

local scene = {}

local VW, VH = 1280, 800
local TILE = World.TILE
local OY = VH - level.h * TILE        -- vertical offset (sky band on top)

function scene.load()
  scene.world = World.new(level)
  scene.bigfont = love.graphics.newFont(40)
  scene.font = love.graphics.newFont(22)
  scene.small = love.graphics.newFont(16)
end

function scene.update(dt)
  if input.down("quit") then love.event.quit(); return end
  scene.world:update(dt, {
    left  = input.down("left"),
    right = input.down("right"),
    down  = input.down("down"),
    jump  = input.down("jump"),
    run   = input.down("run"),
  })
end

local function drawHUD(w)
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
        if ch == "P" then
          opts = { pipeTop = (w:tileAt(c, r - 1) ~= "P") }
        elseif ch == "F" then
          opts = { poleTop = (w:tileAt(c, r - 1) ~= "F") }
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
