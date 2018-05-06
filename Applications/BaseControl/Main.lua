
require("advancedLua")

local component = require("component")
local computer = require("computer")
local image = require("image")
local buffer = require("doubleBuffering")
local GUI = require("GUI")
local fs = require("filesystem")
local unicode = require("unicode")
local serial = require("serialization")
local MineOSPaths = require("MineOSPaths")
local MineOSCore = require("MineOSCore")
local MineOSInterface = require("MineOSInterface")
local event = require("event")


---

resourcesPath = MineOSCore.getCurrentScriptDirectory()
local modulesPath = resourcesPath .. "Modules/"
local localizationPath = resourcesPath .. "Localizations/"
local localization = MineOSCore.getLocalization(localizationPath)


-- print(MineOSCore.properties.language)
-- local localizationFileName = localizationPath .. MineOSCore.properties.language .. ".lang"
-- print(locatizationfileName)


mainContainer, window = MineOSInterface.addWindow(MineOSInterface.tabbedWindow(1,1,90,40))

------

--window.contentContainer = window:addChild(GUI.container(1,4, window.width, window.height-3))
window.contentContainer = window:addChild(GUI.container(1,4, 1,1))

dofile(resourcesPath .. "baselib.lua")

activity(true)
local rs = getRS()

local function loadModules()
  local fileList = fs.sortedList(modulesPath, "name", false)
  for i = 1, #fileList do
    local loadedFile,reason = loadfile(modulesPath .. fileList[i])
    if loadedFile then
      local pcallSuccess, reason = pcall(loadedFile, mainContainer, window, localization, config)
      if pcallSuccess then
        window.tabBar:addItem(reason.name).onTouch = function ()
          reason.onTouch()
        end
      else
        error("Failed to call loaded module \"" .. tostring(fileList[i]) .. "\": " .. tostring(reason))
      end
    else
      error("Failed to load module \"" .. tostring(fileList[i]) .. "\": " .. tostring(reason))
    end
  end
end

window.onResize = function(width, height)
  window.tabBar.width = width
  window.backgroundPanel.width = width
  window.backgroundPanel.height =height-3
  window.contentContainer.width = width
  window.contentContainer.height = window.backgroundPanel.height

  activityWidget.localX = window.width - activityWidget.width
  window.tabBar:getItem(window.tabBar.selectedItem).onTouch()
end
--saveConfig()
loadConfig()



-- Check if a task have missing items.
local function is_missing_items(task)
  if (task.missing.n > 0) then
    return true
  end
  return false
end

-- Check if craft is already on the tasks' queue. 
local function craft_is_on_tasks(craft, tasks)
  for i, task in ipairs(tasks) do
    if craft.name == task.stack.name then
      local missing_items = rs.getMissingItems(task.stack, task.quantity)
      for j, item in ipairs(missing_items) do
        log({text="[WARNING]: Missing " .. item.size .. " " .. item.name, color=0x880000})
        -- TODO: make cancel code here
      end
      return true
    end
  end
  return false
end


log("BaseControl v" .. BaseSettings.Version)

-- Just to be sure
if _G.craftTimer then
  event.cancel(_G.craftTimer)
end
_G.craftTimer = event.timer(5, function()
  --log("Checking for craftable items")
  local tasks = rs.getTasks()

  for i, stack in pairs(_G.BaseConfig) do
    local mod,item,damage = i:match("([^:]+):([^:]+):([^:]+)")
    local name = mod .. ":".. item
    local stack_item = {fullName=name, name=name, damage=tonumber(damage)}
    local toCraft = tonumber(stack.total)
    local skip=false

    if (rs.hasPattern(stack_item)) then
      if (stack["idle"] == true) then
        -- check if RS is idle
        local current_tasks = rs.getTasks()
        if (#current_tasks > 0) then 
          skip=true
        end
      end

      if (not craft_is_on_tasks(stack_item, tasks) and skip==false) then
        --log({text="Has Pattern: " .. tostring(i), color=0x008800})
        local rsStack = rs.getItem(stack_item, true)
        if rsStack then
          --log("Got getItem! " .. rsStack.name .. " (" .. rsStack.size .. ")")
          toCraft = toCraft - rsStack.size
        end
        if toCraft > 0 then
          log({text="Crafting: " .. i .. " (" .. toCraft .. ")", color=0x008800})
          --rs.craftItem(stack_item, toCraft)
          rs.scheduleTask(stack_item, toCraft)
        end
      else
        if (skip == false) then
          log({text="Pattern " .. tostring(i) .. " is already being crafted", color=0xFF9900})
        else
          log({text="Skipping pattern " .. tostring(i) .. " (system not idle)", color=0xFF9900})
        end
      end
    else
      log({text="Pattern not found for: " .. name .. " damage:" .. damage, color=0x880000})
    end
  end
end, math.huge)

-- Cancel all events before close
window.actionButtons.close.onTouch = function()
  if _G.craftTimer then
    event.cancel(_G.craftTimer)
  end
  if _G.outputTimer then
    event.cancel(_G.outputTimer)
  end
  window.close(window)
end

loadModules()
window.onResize(90,40)
--activity(false)
