-- sfx.lua — CC0 sound effects (Kenney New Platformer Pack), played on game events.
-- Sources are cloned per play so overlapping triggers don't cut each other off.

local sfx = {}
local pool = {}

local FILES = {
  jump  = "assets/sfx/jump.ogg",
  coin  = "assets/sfx/coin.ogg",
  stomp = "assets/sfx/stomp.ogg",
  bump  = "assets/sfx/bump.ogg",
  hurt  = "assets/sfx/hurt.ogg",
  win   = "assets/sfx/win.ogg",
}

-- synthesized "fall into a pit" sound: a descending square-wave pitch sweep with
-- a decay tail (no such sound in the pack, so we make one — matches music.lua).
local function buildFall()
  local SR, dur = 44100, 0.6
  local n = math.floor(SR * dur)
  local data = love.sound.newSoundData(n, SR, 16, 1)
  local phase = 0
  for i = 0, n - 1 do
    local p = i / n
    local f = 660 * (1 - p) + 110 * p          -- sweep 660Hz -> 110Hz
    phase = phase + f / SR
    local sq = ((phase % 1) < 0.5) and 1 or -1
    data:setSample(i, sq * 0.5 * (1 - p) * (1 - p))   -- quadratic decay
  end
  return love.audio.newSource(data)
end

-- synthesized laser "pew": a fast downward square-wave chirp with a snappy decay.
local function buildLaser()
  local SR, dur = 44100, 0.16
  local n = math.floor(SR * dur)
  local data = love.sound.newSoundData(n, SR, 16, 1)
  local phase = 0
  for i = 0, n - 1 do
    local p = i / n
    local f = 1500 * (1 - p) + 380 * p          -- 1500Hz -> 380Hz
    phase = phase + f / SR
    local sq = ((phase % 1) < 0.5) and 1 or -1
    data:setSample(i, sq * 0.4 * (1 - p))        -- linear decay
  end
  return love.audio.newSource(data)
end

function sfx.load()
  if _G.HARNESS or not love.audio then return end
  for name, path in pairs(FILES) do
    local ok, src = pcall(love.audio.newSource, path, "static")
    if ok then pool[name] = src end
  end
  local okf, fall = pcall(buildFall);  if okf then pool.fall = fall end
  local okl, laser = pcall(buildLaser); if okl then pool.laser = laser end
end

function sfx.play(name, vol)
  local s = pool[name]
  if not s then return end
  local v = s:clone()
  v:setVolume(vol or 0.6)
  v:play()
end

return sfx
