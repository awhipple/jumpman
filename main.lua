-- main.lua — template entry point. Two run modes:
--   • dev     (`tools/run`)  → lurker hot reload; Aaron drives, judges feel.
--   • harness (`tools/shot`) → fixed-dt stepping + PNG capture; Claude sees frames.
-- Keep love.* at the edges; pure logic lives in src/world.lua (busted-testable).

_G.GAME_SLUG = "jumpman"

local scene = require("src.scene")
local input = require("src.input")

-- virtual canvas: render at Deck-native 1280x800, letterbox-scale to the window.
local VW, VH = 1280, 800
local canvas

-- screenshot/headless harness contract
local harness = {
  active   = false,
  frames   = 60,
  out      = "/tmp/" .. _G.GAME_SLUG .. "-shot.png",
  keysraw  = nil,
  schedule = {},       -- frame(1-based) -> { action = true, ... }
  frame    = 0,
  captured = false,
  dt       = 1 / 60,   -- fixed timestep for deterministic shots
}

local lurker  -- dev mode only

-- arg parsing: tolerate `--flag value` and `--flag=value`; scan the whole arg table.
local function parseArgs()
  local a = arg or {}
  local i, n = 1, #a
  while i <= n do
    local tok = tostring(a[i])
    local k, v = tok:match("^%-%-([%w%-]+)=(.+)$")
    if k then
      if     k == "shot"   then harness.active = true
      elseif k == "frames" then harness.frames = tonumber(v) or harness.frames
      elseif k == "out"    then harness.out = v
      elseif k == "keys"   then harness.keysraw = v end
    elseif tok == "--shot"   then harness.active = true
    elseif tok == "--frames" then i = i + 1; harness.frames = tonumber(a[i]) or harness.frames
    elseif tok == "--out"    then i = i + 1; harness.out = a[i] or harness.out
    elseif tok == "--keys"   then i = i + 1; harness.keysraw = a[i]
    end
    i = i + 1
  end
end

-- --keys "right:60,up+right:20,action:5" → per-frame action sets.
-- segment = "action[+action...][:frames]"; frames defaults to 1.
local function buildSchedule(raw)
  local sched = {}
  if not raw then return sched end
  local f = 1
  for seg in raw:gmatch("[^,]+") do
    local actions, count = seg:match("^([%a%+]+):(%d+)$")
    if not actions then actions, count = seg, "1" end
    local set = {}
    for act in actions:gmatch("[^%+]+") do set[act] = true end
    for _ = 1, (tonumber(count) or 1) do sched[f] = set; f = f + 1 end
  end
  return sched
end

local function savePNG(imageData, path)
  local fileData = imageData:encode("png")   -- in-memory FileData
  local f, err = io.open(path, "wb")
  if not f then error("shot: cannot open " .. path .. ": " .. tostring(err)) end
  f:write(fileData:getString())
  f:close()
end

function love.load()
  parseArgs()
  canvas = love.graphics.newCanvas(VW, VH)
  scene.load()

  if harness.active then
    harness.schedule = buildSchedule(harness.keysraw)
    input.setOverride({})   -- harness owns input; nothing pressed by default
  else
    lurker = require("lib.lurker")   -- requires lib.lume (same dir)
    lurker.init()
    lurker.interval = 0.25           -- polling reloader (no inotify on WSL)
  end
end

function love.update(dt)
  if harness.active then
    input.setOverride(harness.schedule[harness.frame + 1] or {})
    scene.update(harness.dt)         -- fixed dt; ignore wall-clock
    harness.frame = harness.frame + 1
    if harness.frame >= harness.frames and harness.captured then
      love.event.quit()
    end
  else
    lurker.update()
    scene.update(dt)
  end
end

local function renderScene()
  love.graphics.setCanvas(canvas)
  love.graphics.push("all")
  love.graphics.origin()
  scene.draw()
  love.graphics.pop()
  love.graphics.setCanvas()
end

function love.draw()
  renderScene()

  local ww, wh = love.graphics.getDimensions()
  local s = math.min(ww / VW, wh / VH)
  local ox = (ww - VW * s) / 2
  local oy = (wh - VH * s) / 2
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(canvas, ox, oy, 0, s, s)

  if harness.active and harness.frame >= harness.frames and not harness.captured then
    harness.captured = true
    savePNG(canvas:newImageData(), harness.out)   -- synchronous readback
    print(("[shot] wrote %s after %d frames"):format(harness.out, harness.frame))
  end
end

-- Quit harness on demand if it ever runs without a target (safety net).
function love.keypressed(key)
  if key == "escape" and not harness.active then love.event.quit() end
end
