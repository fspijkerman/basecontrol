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
  
  local menuList = window.contentContainer:addChild(GUI.list(1, 1, 23, window.contentContainer.height, 3, 0, 0xE1E1E1, 0x4B4B4B, 0xD2D2D2, 0x4B4B4B, 0x3366CC, 0xE1E1E1))
  local menuContentContainer = window.contentContainer:addChild(GUI.container(menuList.width + 1, 1, window.contentContainer.width - menuList.width, window.contentContainer.height))

  menuList:addItem("About")
  menuList:addItem("Settings")
  menuList:addItem("Update")
  local test = menuContentContainer:addChild(GUI.text(3,2,0x000000, "Version 0.1-alpha"))
end

----

return module
