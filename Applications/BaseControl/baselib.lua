local component = require("component")
local GUI = require("GUI")
local MineOSInterface = require("MineOSInterface")
local buffer = require("doubleBuffering")
local fs = require("filesystem")
local web = require("web")

---

BaseSettings = {
  Version      = "0.5.0-alpha",
  VersionStamp = 1525616211,
  UpdateURL    = "https://raw.githubusercontent.com/fspijkerman/basecontrol/master/Version.cfg",
  FilesURL     = "https://raw.githubusercontent.com/fspijkerman/basecontrol/master/Files.cfg",
  RS           = {},
  defaultRS    = "",
}

_G.BaseConfig = {}
_G.logData = {}

function saveConfig()
  table.toFile(resourcesPath .. "config", _G.BaseConfig)
  return _G.BaseConfig
end

function loadConfig()
  if fs.exists(resourcesPath .. "config") then
    _G.BaseConfig = table.fromFile(resourcesPath .. "config")
  else
    saveConfig()
  end
end

function log(msg)
  -- crude way to limit memory usage
  if #_G.logData > 50 then
    _G.logData = {}
  end
  table.insert(_G.logData, msg)
end

function string.startswith(string, start)
  return string.sub(string, 1, string.len(start)) == start
end

function detectRS()
  BaseSettings.RS = {}
  for _,name in component.list("block_refinedstorage") do
    table.insert(BaseSettings.RS, name)
  end

  return BaseSettings.RS
end
detectRS()

local function capture(table, key, rest)
  return function(...)
    local args = {...}
    log("[RSMock] Catched RS call: " .. key)
  end
end

local function rsMock()
  mock = {}
  mt = { __index = capture }
  setmetatable(mock,mt)
  return mock
end

function getRS()
  if #BaseSettings.RS == 0 then
    log("No refined storage blocks detected")
    return rsMock()
  end

  if component.isAvailable(BaseSettings.defaultRS) then
    return component[BaseSettings.defaultRS]
  end

  -- Return first available.
  for _,v in pairs(BaseSettings.RS) do
    if component[v].isConnected() == true then
      return component[v]
    end
  end

  log("no connected RS found")
  return rsMock()
end

function unserializeFile(path)
  local file = io.open(path, "r")
  local data = require("serialization").unserialize(file:read("*a"))
  file:close()
  return data
end

function tryDownload(...)
  local success, reason = web.download(...)
  if not success then
    GUI.error(reason)
  end
  return success
end

activityWidget = window:addChild(GUI.object(window.width-4, 1, 4, 3))
activityWidget.hidden = true
activityWidget.position = 0
activityWidget.color1 = 0x99FF80
activityWidget.color2 = 0x00B640
activityWidget.draw = function(activityWidget)
  buffer.text(activityWidget.x + 1, activityWidget.y, activityWidget.position == 1 and activityWidget.color1 or activityWidget.color2, "⢀")
  buffer.text(activityWidget.x + 2, activityWidget.y, activityWidget.position == 1 and activityWidget.color1 or activityWidget.color2, "⡀")

  buffer.text(activityWidget.x + 3, activityWidget.y + 1, activityWidget.position == 2 and activityWidget.color1 or activityWidget.color2, "⠆")
  buffer.text(activityWidget.x + 2, activityWidget.y + 1, activityWidget.position == 2 and activityWidget.color1 or activityWidget.color2, "⢈")

  buffer.text(activityWidget.x + 1, activityWidget.y + 2, activityWidget.position == 3 and activityWidget.color1 or activityWidget.color2, "⠈")
  buffer.text(activityWidget.x + 2, activityWidget.y + 2, activityWidget.position == 3 and activityWidget.color1 or activityWidget.color2, "⠁")

  buffer.text(activityWidget.x, activityWidget.y + 1, activityWidget.position == 4 and activityWidget.color1 or activityWidget.color2, "⠰")
  buffer.text(activityWidget.x + 1, activityWidget.y + 1, activityWidget.position == 4 and activityWidget.color1 or activityWidget.color2, "⡁")
end

local overrideWindowDraw = window.draw
window.draw = function(...)
  if not activityWidget.hidden then
    activityWidget.position = activityWidget.position + 1
    if activityWidget.position > 4 then
      activityWidget.position = 1
    end
  end

  return overrideWindowDraw(...)
end

function activity(state)
  activityWidget.hidden = not state
  MineOSInterface.mainContainer:drawOnScreen()
end

function detectRS()
  for k,v in ipairs(component) do
    log(tostring(k))
  end
end

