local GUI = require("GUI")
local MineOSInterface = require("MineOSInterface")
local buffer = require("doubleBuffering")
local fs = require("filesystem")
local web = require("web")

---

BaseSettings = {
  VersionStamp = 12344,
  UpdateURL    = "https://raw.githubusercontent.com/fspijkerman/basecontrol/master/Version.cfg",
  FilesURL     = "https://raw.githubusercontent.com/fspijkerman/basecontrol/master/Files.cfg",
}

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
