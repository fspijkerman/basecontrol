local args = {...}
local mainContainer, window, localization, config = args[1], args[2], args[3], args[4]


require("advancedLua")
local component = require("component")
local computer require("computer")
local GUI = require("GUI")
local buffer = require("doubleBuffering")
local image = require("image")
local MineOSPaths = require("MineOSPaths")
local MineOSInterface = require("MineOSInterface")
local unicode = require("unicode")
local event = require("event")

local module = {}
module.name = "Power"

module.onTouch = function()
  window.contentContainer:deleteChildren()
  local craftPanel = window.contentContainer:addChild(GUI.panel(1,1,1,1, 0xE1E1E1))
  local chart = window.contentContainer:addChild(GUI.chart(1,1, window.contentContainer.width-2, 25, 0xEEEEEE, 0xAAAAAA, 0x888888, 0xFFDB40, 0.25, 0.25, "s","t", true, {}))

  for i = 1, 100 do
    table.insert(chart.values, {i, math.random(0,80)})
  end
end

----

return module
