-- scene.lua — wires pure logic (world) to rendering + input. love.* lives here.

local World = require("src.world")
local input = require("src.input")

local scene = {}

function scene.load()
  scene.world = World.new(1280, 800)
  scene.t = 0
  scene.frame = 0
  scene.font = love.graphics.newFont(22)
end

function scene.update(dt)
  scene.t = scene.t + dt
  scene.frame = scene.frame + 1
  scene.world:update(dt, {
    left  = input.down("left"),
    right = input.down("right"),
    up    = input.down("up"),
    down  = input.down("down"),
  })
end

function scene.draw()
  love.graphics.clear(0.10, 0.12, 0.16)
  local w = scene.world

  -- the sprite
  love.graphics.setColor(0.30, 0.80, 0.90)
  love.graphics.circle("fill", w.x, w.y, w.r)
  love.graphics.setColor(1, 1, 1, 0.9)
  love.graphics.circle("line", w.x, w.y, w.r)

  -- HUD (proves the loop end-to-end in a screenshot)
  love.graphics.setFont(scene.font)
  love.graphics.setColor(1, 1, 1)
  love.graphics.print(("gamelab • %s"):format(_G.GAME_SLUG or "template"), 24, 24)
  love.graphics.print(
    ("frame %d   t=%.2fs   pos=(%.0f, %.0f)"):format(scene.frame, scene.t, w.x, w.y),
    24, 56)
  love.graphics.setColor(0.7, 0.7, 0.75)
  love.graphics.print("arrows / WASD / D-pad to nudge", 24, 800 - 44)
end

return scene
