-- sprites.lua — ORIGINAL graphics, drawn from scratch with love.graphics.
-- No imported art: characters are hand-authored pixel grids (drawn as rects),
-- tiles/coins/background are procedural. This is an "edge" file (love.* lives here).

local sprites = {}

-- palette: single-char keys -> {r,g,b}. Space = transparent.
local PAL = {
  R = { 0.86, 0.20, 0.18 },   -- cap / shirt red
  O = { 0.20, 0.34, 0.80 },   -- overalls blue
  S = { 0.99, 0.80, 0.62 },   -- skin
  M = { 0.45, 0.27, 0.12 },   -- hair / mustache brown
  E = { 0.12, 0.10, 0.10 },   -- eye / pupil
  G = { 0.96, 0.96, 0.98 },   -- glove white
  B = { 0.40, 0.22, 0.10 },   -- boots brown
  -- goomba
  K = { 0.52, 0.34, 0.16 },   -- body brown
  W = { 0.98, 0.98, 0.98 },   -- eye white
  F = { 0.28, 0.16, 0.07 },   -- feet dark
}

-- hero, facing right (12 x 16). Stretched to fit the entity box.
local HERO = {
  "   RRRR     ",
  "  RRRRRR    ",
  "  MMSSSES   ",
  "  MSSSSES   ",
  "  MSSSSSS   ",
  "   SMMSS    ",
  "  RRRRRR    ",
  " GRROOORRG  ",
  " GRROOORRG  ",
  " GRROOORRG  ",
  "   OOOOO    ",
  "  OOOOOOO   ",
  "  OO  OO    ",
  "  OO  OO    ",
  " BBB  BBB   ",
  " BBB  BBB   ",
}

local GOOMBA = {
  "   KKKK     ",
  "  KKKKKK    ",
  " KKKKKKKK   ",
  " KWWKKWWK   ",
  " KWEKKEWK   ",
  " KKKKKKKK   ",
  " KKKKKKKK   ",
  "  KKKKKK    ",
  "  FF  FF    ",
  " FFF  FFF   ",
}

local qfont                                   -- lazy: love.graphics ready by scene.load
local function questionFont()
  qfont = qfont or love.graphics.newFont(30)
  return qfont
end

local function gridSize(g) return #(g[1]), #g end

-- draw a pixel grid into box (bx,by,bw,bh); flip horizontally if facing < 0.
local function drawGrid(g, bx, by, bw, bh, flip)
  local gw, gh = gridSize(g)
  local sx, sy = bw / gw, bh / gh
  for row = 1, gh do
    local line = g[row]
    for col = 1, gw do
      local ch = line:sub(col, col)
      local c = PAL[ch]
      if c then
        love.graphics.setColor(c[1], c[2], c[3])
        local px = flip and (gw - col) or (col - 1)
        love.graphics.rectangle("fill", bx + px * sx, by + (row - 1) * sy,
                                math.ceil(sx), math.ceil(sy))
      end
    end
  end
end

-- ---- bevel block helper ---------------------------------------------------
local function bevel(x, y, s, base, light, dark, inset)
  inset = inset or s * 0.12
  love.graphics.setColor(light)
  love.graphics.rectangle("fill", x, y, s, s)
  love.graphics.setColor(dark)
  love.graphics.polygon("fill", x, y + s, x + s, y + s, x + s, y)
  love.graphics.setColor(base)
  love.graphics.rectangle("fill", x + inset, y + inset, s - 2 * inset, s - 2 * inset)
end

-- ---- public draws ---------------------------------------------------------
function sprites.player(p)
  -- brief invulnerability blink after taking a hit
  if p.invuln and p.invuln > 0 and math.floor(p.invuln * 12) % 2 == 0 then return end
  drawGrid(HERO, p.x, p.y, p.w, p.h, p.facing < 0)
end

function sprites.goomba(g)
  if g.dying then
    -- squashed: a flat brown patty
    love.graphics.setColor(0.52, 0.34, 0.16)
    love.graphics.rectangle("fill", g.x, g.y + g.h - 12, g.w, 12)
    return
  end
  drawGrid(GOOMBA, g.x, g.y, g.w, g.h, g.facing > 0)
end

function sprites.coin(x, y, s, t)
  local wob = math.abs(math.sin((t or 0) * 4)) * 0.6 + 0.4   -- spin
  local cx, cy = x + s / 2, y + s / 2
  love.graphics.setColor(0.82, 0.62, 0.10)
  love.graphics.ellipse("fill", cx, cy, s * 0.30 * wob, s * 0.34)
  love.graphics.setColor(0.99, 0.85, 0.25)
  love.graphics.ellipse("fill", cx, cy, s * 0.22 * wob, s * 0.26)
  love.graphics.setColor(1, 1, 1, 0.8)
  love.graphics.ellipse("fill", cx - s * 0.05 * wob, cy - s * 0.06, s * 0.05 * wob, s * 0.10)
end

-- draw one map tile. opts.pipeTop / opts.poleTop tweak special tiles.
function sprites.tile(ch, x, y, s, opts, t)
  opts = opts or {}
  if ch == "#" then                              -- ground / dirt
    bevel(x, y, s, { 0.62, 0.38, 0.18 }, { 0.74, 0.50, 0.26 }, { 0.42, 0.24, 0.10 }, s * 0.06)
    love.graphics.setColor(0.42, 0.24, 0.10, 0.5)
    love.graphics.rectangle("line", x + s * 0.5, y, 1, s)
    love.graphics.rectangle("line", x, y + s * 0.5, s, 1)
  elseif ch == "B" then                          -- brick
    love.graphics.setColor(0.70, 0.34, 0.18); love.graphics.rectangle("fill", x, y, s, s)
    love.graphics.setColor(0.30, 0.14, 0.06)
    for ry = 0, 3 do                              -- mortar rows, offset bond
      local yy = y + ry * s / 4
      love.graphics.rectangle("fill", x, yy, s, 1.5)
      local off = (ry % 2 == 0) and 0 or s / 2
      love.graphics.rectangle("fill", x + off, yy, 1.5, s / 4)
      love.graphics.rectangle("fill", x + ((off + s / 2) % s), yy, 1.5, s / 4)
    end
  elseif ch == "?" then                          -- coin block (pulsing)
    local g = 0.55 + 0.25 * (0.5 + 0.5 * math.sin((t or 0) * 6))
    bevel(x, y, s, { 0.95, g, 0.10 }, { 1.0, 0.92, 0.4 }, { 0.70, 0.48, 0.05 })
    -- little bevel studs in the corners
    love.graphics.setColor(0.70, 0.48, 0.05)
    for _, cn in ipairs({ { 0.12, 0.12 }, { 0.78, 0.12 }, { 0.12, 0.78 }, { 0.78, 0.78 } }) do
      love.graphics.rectangle("fill", x + s * cn[1], y + s * cn[2], s * 0.10, s * 0.10)
    end
    local f = questionFont()
    local sc = s / 48
    local tw, th = f:getWidth("?") * sc, f:getHeight() * sc
    love.graphics.setFont(f)
    love.graphics.setColor(0.30, 0.20, 0.02)
    love.graphics.print("?", x + s / 2 - tw / 2, y + s / 2 - th / 2, 0, sc, sc)
  elseif ch == "U" then                          -- spent block
    bevel(x, y, s, { 0.45, 0.30, 0.16 }, { 0.58, 0.42, 0.24 }, { 0.30, 0.18, 0.08 })
  elseif ch == "P" then                          -- pipe
    love.graphics.setColor(0.16, 0.62, 0.24); love.graphics.rectangle("fill", x, y, s, s)
    love.graphics.setColor(0.30, 0.80, 0.36); love.graphics.rectangle("fill", x + s * 0.12, y, s * 0.18, s)
    love.graphics.setColor(0.08, 0.40, 0.14); love.graphics.rectangle("fill", x + s * 0.80, y, s * 0.12, s)
    if opts.pipeTop then                          -- lip overhangs the body
      love.graphics.setColor(0.16, 0.62, 0.24)
      love.graphics.rectangle("fill", x - s * 0.10, y, s * 1.20, s * 0.34)
      love.graphics.setColor(0.30, 0.80, 0.36)
      love.graphics.rectangle("fill", x - s * 0.06, y + s * 0.04, s * 0.30, s * 0.24)
      love.graphics.setColor(0.08, 0.40, 0.14)
      love.graphics.rectangle("line", x - s * 0.10, y, s * 1.20, s * 0.34)
    end
  elseif ch == "=" then                          -- castle / base stone
    bevel(x, y, s, { 0.66, 0.66, 0.70 }, { 0.80, 0.80, 0.84 }, { 0.44, 0.44, 0.48 }, s * 0.05)
  elseif ch == "F" then                          -- flag pole segment
    love.graphics.setColor(0.55, 0.57, 0.60)
    love.graphics.rectangle("fill", x + s * 0.45, y, s * 0.10, s)
    if opts.poleTop then
      love.graphics.setColor(0.20, 0.78, 0.30)   -- pennant
      love.graphics.polygon("fill", x + s * 0.45, y + s * 0.1,
                            x + s * 0.45, y + s * 0.6, x - s * 0.6, y + s * 0.35)
      love.graphics.setColor(0.95, 0.95, 0.40)   -- ball on top
      love.graphics.circle("fill", x + s * 0.5, y, s * 0.12)
    end
  end
end

-- ---- parallax background --------------------------------------------------
function sprites.background(camX, vw, vh)
  -- sky gradient
  for i = 0, 20 do
    local f = i / 20
    love.graphics.setColor(0.36 + 0.10 * f, 0.62 + 0.10 * f, 0.95)
    love.graphics.rectangle("fill", 0, vh * f / 1, vw, vh / 20 + 1)
  end
  -- distant hills (slow parallax)
  love.graphics.setColor(0.30, 0.66, 0.32)
  local hx = -(camX * 0.3) % 520
  for i = -1, math.ceil(vw / 520) + 1 do
    local bx = hx + i * 520
    love.graphics.arc("fill", "pie", bx, vh - 96, 150, math.pi, 2 * math.pi)
    love.graphics.arc("fill", "pie", bx + 300, vh - 96, 100, math.pi, 2 * math.pi)
  end
  -- clouds (slower parallax)
  love.graphics.setColor(1, 1, 1, 0.92)
  local cx = -(camX * 0.15) % 460
  for i = -1, math.ceil(vw / 460) + 1 do
    local bx, by = cx + i * 460, 90 + (i % 2) * 70
    love.graphics.ellipse("fill", bx, by, 52, 28)
    love.graphics.ellipse("fill", bx + 46, by + 6, 40, 24)
    love.graphics.ellipse("fill", bx - 40, by + 8, 34, 20)
  end
end

return sprites
