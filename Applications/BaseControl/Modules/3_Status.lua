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
module.name = "Status"

module.onTouch = function()
  window.contentContainer:deleteChildren()
end

----

return module
