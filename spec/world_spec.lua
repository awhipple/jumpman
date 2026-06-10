-- Example busted spec. Pure logic only (no love.*), runs headless via `tools/test`.
-- Run from the game root: `busted` (default path is ./spec).

local World = require("src.world")

describe("World", function()
  it("starts centered", function()
    local w = World.new(1280, 800)
    assert.are.equal(640, w.x)
    assert.are.equal(400, w.y)
  end)

  it("drifts over time", function()
    local w = World.new(1280, 800)
    local x0, y0 = w.x, w.y
    w:update(1 / 60)
    assert.is_true(w.x ~= x0 or w.y ~= y0)
  end)

  it("nudges with player input", function()
    local w = World.new(1280, 800)
    w.vx, w.vy = 0, 0           -- isolate input from autonomous drift
    local x0 = w.x
    w:update(0.1, { right = true })
    assert.is_true(w.x > x0)
  end)

  it("stays within bounds and reflects at walls", function()
    local w = World.new(400, 400)
    w.vx, w.vy = 10000, 10000   -- slam into the far walls
    w:update(1)
    assert.is_true(w.x <= w.w - w.r and w.x >= w.r)
    assert.is_true(w.y <= w.h - w.r and w.y >= w.r)
    assert.is_true(w.vx < 0 and w.vy < 0)  -- velocity flipped
  end)
end)
