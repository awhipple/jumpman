-- input.lua — action-name input abstraction (gamepad-first, keyboard mirrors).
-- Query with input.down("jump"). In the screenshot harness, scripted input is fed
-- via input.setOverride(set), so the same action queries drive both real play and
-- `tools/shot --keys "right:40,right+jump:18"`.

local input = {}

-- action -> { keys = {...}, buttons = {...} }  (Steam Deck-friendly defaults)
input.bindings = {
  left  = { keys = { "left",  "a" },            buttons = { "dpleft"  } },
  right = { keys = { "right", "d" },            buttons = { "dpright" } },
  down  = { keys = { "down",  "s" },            buttons = { "dpdown"  } },
  -- A/B button / space / up to jump; hold for a higher jump.
  jump  = { keys = { "space", "up", "z", "w" }, buttons = { "a", "b" } },
  -- run/dash: hold to move faster (classic B-button dash).
  run   = { keys = { "lshift", "rshift", "x" }, buttons = { "x", "y" } },
  -- shoot the laser: Right Bumper (R1); keyboard mirror F.
  shoot = { keys = { "f" },                     buttons = { "rightshoulder" } },
  -- quit: every game has a quit (button or menu) — Start / Esc here.
  quit  = { keys = { "escape" },                buttons = { "start" } },
}

input.override = nil  -- when non-nil (harness), a set: { jump = true, ... }

function input.setOverride(set) input.override = set end

function input.down(action)
  if input.override ~= nil then
    return input.override[action] == true
  end
  local b = input.bindings[action]
  if not b then return false end
  for _, k in ipairs(b.keys or {}) do
    if love.keyboard.isDown(k) then return true end
  end
  if love.joystick then
    local js = love.joystick.getJoysticks()[1]
    if js and js:isGamepad() then
      for _, btn in ipairs(b.buttons or {}) do
        if js:isGamepadDown(btn) then return true end
      end
    end
  end
  return false
end

return input
