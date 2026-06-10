-- sprites.lua — rendering edge (love.* lives here). Art is Kenney's CC0
-- "New Platformer Pack" (vector style), copied into assets/. Same public draw
-- API as before (player/goomba/coin/tile/background) so scene.lua is unchanged
-- apart from passing a grassTop hint for ground tiles.

local sprites = {}

-- ---- image cache ----------------------------------------------------------
local cache = {}
local function img(path)
  local i = cache[path]
  if not i then
    i = love.graphics.newImage("assets/" .. path)
    i:setFilter("linear", "linear")
    cache[path] = i
  end
  return i
end

-- animation phase from the wall clock (cosmetic only; render-side)
local function anim(fps, n)
  return (math.floor(love.timer.getTime() * fps) % n)
end

-- draw a sprite bottom-center-anchored inside an AABB box, flipped by facing.
-- sizeMul scales the art relative to box height (Kenney frames have padding);
-- yoff nudges the feet onto the ground.
local function drawBoxed(image, box, facing, sizeMul, yoff)
  local iw, ih = image:getDimensions()
  local scale = (box.h * (sizeMul or 1)) / ih
  local sx = (facing and facing < 0) and -scale or scale
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(image, box.x + box.w / 2, box.y + box.h + (yoff or 0),
                     0, sx, scale, iw / 2, ih)
end

-- ---- characters -----------------------------------------------------------
function sprites.player(p)
  if p.invuln and p.invuln > 0 and math.floor(p.invuln * 12) % 2 == 0 then return end
  local frame
  if not p.onGround then
    frame = "player/jump.png"
  elseif math.abs(p.vx) > 25 then
    frame = (anim(10, 2) == 0) and "player/walk_a.png" or "player/walk_b.png"
  else
    frame = "player/idle.png"
  end
  drawBoxed(img(frame), p, p.facing, 2.0, 6)
  -- held blaster, pointing the way the player faces
  local g = img("player/blaster.png")
  local giw, gih = g:getDimensions()
  local gsc = (p.h * 0.78) / gih
  local sx = (p.facing < 0) and -gsc or gsc
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(g, p.x + p.w / 2 + p.facing * p.w * 0.36, p.y + p.h * 0.56,
                     0, sx, gsc, giw / 2, gih / 2)
end

-- a laser bolt: the art is a vertical bolt, so rotate 90° to fly horizontally
function sprites.laser(L)
  local image = img("fx/laser.png")
  local iw, ih = image:getDimensions()
  local len, thick = L.w + 20, L.h + 8
  local rot = (L.dir < 0) and -math.pi / 2 or math.pi / 2
  -- additive glow pass + tinted core so it reads as a hot energy bolt, not a white bar
  love.graphics.setBlendMode("add")
  love.graphics.setColor(1.0, 0.20, 0.30)
  love.graphics.draw(image, L.x + L.w / 2, L.y + L.h / 2, rot,
                     (thick * 1.6) / iw, (len * 1.15) / ih, iw / 2, ih / 2)
  love.graphics.setBlendMode("alpha")
  love.graphics.setColor(1.0, 0.45, 0.55)
  love.graphics.draw(image, L.x + L.w / 2, L.y + L.h / 2, rot,
                     thick / iw, len / ih, iw / 2, ih / 2)
end

function sprites.goomba(g)
  if g.dying then
    drawBoxed(img("enemy/flat.png"), g, g.facing, 1.3, 6)
    return
  end
  local frame = (anim(8, 2) == 0) and "enemy/walk_a.png" or "enemy/walk_b.png"
  drawBoxed(img(frame), g, g.facing, 1.45, 6)
end

-- ---- coin (tile + popped effect) ------------------------------------------
function sprites.coin(x, y, s, t)
  local image = img("tiles/coin.png")
  local iw, ih = image:getDimensions()
  local base = s / ih
  local spin = 0.55 + 0.45 * math.abs(math.sin((t or 0) * 4))   -- fake rotation
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(image, x + s / 2, y + s / 2, 0, base * spin, base, iw / 2, ih / 2)
end

-- ---- tiles ----------------------------------------------------------------
local TILE_IMG = {
  ["B"] = "tiles/brick.png",
  ["?"] = "tiles/qblock.png",
  ["U"] = "tiles/used.png",
  ["P"] = "tiles/block.png",    -- green block stack (replaces the Mario pipe)
  ["="] = "tiles/used.png",     -- end-castle stub
}

function sprites.tile(ch, x, y, s, opts, t)
  opts = opts or {}
  if ch == "F" then
    -- the flag art is a self-contained flag-on-a-post; draw it large and anchored
    -- bottom-center to the tile's base (the ground surface) — no separate pole.
    local image = img("tiles/flag.png")
    local iw, ih = image:getDimensions()
    local sc = (s * 2.7) / ih
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(image, x + s * 0.5, y + s, 0, sc, sc, iw / 2, ih)
    return
  end

  local path = (ch == "#")
    and (opts.grassTop and "tiles/ground_top.png" or "tiles/ground_dirt.png")
    or TILE_IMG[ch]
  if not path then return end

  local image = img(path)
  local iw, ih = image:getDimensions()
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(image, x, y, 0, s / iw, s / ih)
end

-- ---- parallax background --------------------------------------------------
function sprites.background(camX, vw, vh)
  local image = img("bg/hills.png")
  local iw, ih = image:getDimensions()
  local scale = vh / ih
  local tileW = iw * scale
  local ox = -((camX * 0.4) % tileW)
  love.graphics.setColor(1, 1, 1)
  for i = -1, math.ceil(vw / tileW) + 1 do
    love.graphics.draw(image, ox + i * tileW, 0, 0, scale, scale)
  end
end

return sprites
