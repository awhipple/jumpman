-- music.lua — ORIGINAL background music, synthesized in pure Lua (no audio files).
-- A looping 4-bar chiptune (I–V–vi–IV in C: C · G · Am · F): pulse-wave melody over
-- a square bass, with per-note attack/release envelopes to keep it click-free.
-- Built once into a SoundData at load; played as a looping Source.

local music = {}
local SR = 44100
local BPM = 140

local function midi(n) return 440 * 2 ^ ((n - 69) / 12) end

-- melody: eighth notes (MIDI #, 0 = rest), 4 bars × 8 = 32 steps
local MEL = {
  72, 76, 79, 76, 84, 79, 76, 72,   -- C : C E G E  C6 G E C
  74, 79, 83, 79, 86, 83, 79, 74,   -- G : D G B G  D6 B G D
  76, 81, 84, 81, 88, 84, 81, 76,   -- Am: E A C E  E6 C A E
  77, 81, 84, 81, 89, 84, 81, 77,   -- F : F A C A  F6 C A F
}
-- bass: quarter notes (one per 2 eighths), 16 steps
local BASS = { 48, 48, 55, 48, 43, 43, 50, 43, 45, 45, 52, 45, 41, 41, 48, 41 }

-- precompute frequencies so the inner sample loop stays cheap
local MELF, BASSF = {}, {}
for i, n in ipairs(MEL)  do MELF[i]  = (n > 0) and midi(n) or 0 end
for i, n in ipairs(BASS) do BASSF[i] = (n > 0) and midi(n) or 0 end

local function pulse(t, f, duty) return ((t * f) % 1) < duty and 1 or -1 end

local source

function music.build()
  local spE   = math.floor((60 / BPM) / 2 * SR)   -- samples per eighth note
  local total = spE * #MEL
  local data  = love.sound.newSoundData(total, SR, 16, 1)
  local atk, rel = 240, 1100                       -- envelope ramps (samples)
  for i = 0, total - 1 do
    local e  = math.floor(i / spE) + 1             -- eighth index 1..32
    local q  = math.floor((e - 1) / 2) + 1         -- bass quarter index
    local ti = i % spE                             -- sample offset within eighth
    local env = 1
    if ti < atk then env = ti / atk
    elseif ti > spE - rel then env = (spE - ti) / rel end
    if env < 0 then env = 0 end

    local t = i / SR
    local s = 0
    if MELF[e]  > 0 then s = s + pulse(t, MELF[e], 0.5)  * 0.22 * env end
    if BASSF[q] > 0 then s = s + pulse(t, BASSF[q], 0.5) * 0.15 * env end
    if s > 1 then s = 1 elseif s < -1 then s = -1 end
    data:setSample(i, s)
  end
  return data
end

function music.start()
  if _G.HARNESS then return end          -- silent under the screenshot harness
  if source or not love.audio then return end
  local ok, data = pcall(music.build)
  if not ok then return end
  source = love.audio.newSource(data)
  source:setLooping(true)
  source:setVolume(0.40)
  source:play()
end

function music.stop() if source then source:stop() end end

return music
