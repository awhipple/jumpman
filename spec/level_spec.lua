-- Validates the two shipped courses build into playable worlds. Pure data + logic.

local World = require("src.world")

local function checkLevel(level, name, theme)
  describe(name, function()
    it("declares its theme", function()
      assert.are.equal(theme, level.theme)
    end)

    it("builds a world with a player spawn", function()
      local w = World.new(level)
      assert.is_true(w.w > 0 and w.h > 0)
      assert.is_truthy(w.player)
    end)

    it("spawns the player onto solid ground (settles)", function()
      local w = World.new(level)
      for _ = 1, 120 do w:update(1 / 60, {}) end
      assert.is_true(w.player.onGround)
      assert.is_false(w.dead)            -- didn't spawn into a pit
    end)

    it("has a goal flag", function()
      local hasF = false
      for _, row in ipairs(level.grid) do if row:find("F") then hasF = true end end
      assert.is_true(hasF)
    end)
  end)
end

checkLevel(require("src.level"),  "Level 1 (overworld)",   "overworld")
checkLevel(require("src.level2"), "Level 2 (underground)", "underground")
