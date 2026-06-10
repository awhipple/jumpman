-- input.lua — action-name input abstraction (gamepad-first, keyboard mirrors).
-- Query with input.down("left"). In the screenshot harness, scripted input is fed
-- via input.setOverride(set), so the same action queries drive both real play and
-- `tools/shot --keys`.

local input = {}

-- action -> { keys = {...}, buttons = {...} }  (Deck-friendly defaults)
input.bindings = {
  left   = { keys = { "left",  "a" }, buttons = { "dpleft"  } },
  right  = { keys = { "right", "d" }, buttons = { "dpright" } },
  up     = { keys = { "up",    "w" }, buttons = { "dpup"    } },
  down   = { keys = { "down",  "s" }, buttons = { "dpdown"  } },
  action = { keys = { "space", "return" }, buttons = { "a" } },
  cancel = { keys = { "escape", "backspace" }, buttons = { "b" } },
}

input.override = nil  -- when non-nil (harness), a set: { action = true, ... }

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
