-- conf.lua — LÖVE window/runtime config. `new-game` substitutes jumpman.
function love.conf(t)
  t.identity = "jumpman"   -- save-directory name (per-game namespace)
  t.version  = "11.5"            -- the version we run on dev box AND the Steam Deck
  t.window.title  = "jumpman"
  t.window.width  = 1280         -- Steam Deck native resolution
  t.window.height = 800
  t.window.resizable = true
  t.window.vsync  = 1
  -- modules
  t.modules.joystick = true      -- gamepad-first (Deck)
  t.modules.physics  = false     -- flip on per-game if you need box2d
  t.console = false
end
