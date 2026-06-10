-- world.lua — PURE game logic. No `love.*` here, so busted can test it headless.
-- A sprite drifts and bounces off the 1280x800 bounds; player input nudges it.

local World = {}
World.__index = World

function World.new(w, h)
  local self = setmetatable({}, World)
  self.w = w or 1280
  self.h = h or 800
  self.x = self.w / 2
  self.y = self.h / 2
  self.vx = 180          -- autonomous drift so a still screenshot still shows life
  self.vy = 120
  self.r = 40
  self.speed = 360       -- player nudge speed (px/s)
  return self
end

-- move: { left=bool, right=bool, up=bool, down=bool } (any may be nil)
function World:update(dt, move)
  move = move or {}
  if move.left  then self.x = self.x - self.speed * dt end
  if move.right then self.x = self.x + self.speed * dt end
  if move.up    then self.y = self.y - self.speed * dt end
  if move.down  then self.y = self.y + self.speed * dt end

  -- autonomous drift
  self.x = self.x + self.vx * dt
  self.y = self.y + self.vy * dt

  -- bounce off walls (clamp + reflect)
  if self.x < self.r            then self.x = self.r;            self.vx = -self.vx end
  if self.x > self.w - self.r   then self.x = self.w - self.r;   self.vx = -self.vx end
  if self.y < self.r            then self.y = self.r;            self.vy = -self.vy end
  if self.y > self.h - self.r   then self.y = self.h - self.r;   self.vy = -self.vy end
end

return World
