local args = {...}
local mainContainer, window, localization, config = args[1], args[2], args[3], args[4]


require("advancedLua")
local component = require("component")
local computer require("computer")
local GUI = require("GUI")
local buffer = require("doubleBuffering")
local image = require("image")
local MineOSPaths = require("MineOSPaths")
local MineOSCore = require("MineOSCore")
local MineOSInterface = require("MineOSInterface")
local unicode = require("unicode")
local event = require("event")
local fs = require("filesystem")
local web = require("web")

local resourcesPath = MineOSCore.getCurrentScriptDirectory()
local module = {}
module.name = "Status"

module.onTouch = function()
  window.contentContainer:deleteChildren()

  local menuList = window.contentContainer:addChild(GUI.list(1, 1, 23, window.contentContainer.height, 3, 0, 0xE1E1E1, 0x4B4B4B, 0xD2D2D2, 0x4B4B4B, 0x3366CC, 0xE1E1E1))
  local menuContentContainer = window.contentContainer:addChild(GUI.container(menuList.width + 1, 1, window.contentContainer.width - menuList.width, window.contentContainer.height))

  local function about()
    menuContentContainer:deleteChildren()
    menuContentContainer:addChild(GUI.text(3,2,0x000000, "Current Version: " .. BaseSettings.Version))
    menuContentContainer:addChild(GUI.text(3,3,0x000000, "Version timestamp: " .. BaseSettings.VersionStamp))
    MineOSInterface.mainContainer:drawOnScreen()
  end

  local function settings()
    menuContentContainer:deleteChildren()

    local formLayout = menuContentContainer:addChild(GUI.layout(3,2, menuContentContainer.width-4, menuContentContainer.height, 2,1))
    formLayout.showGrid = false
    formLayout:setCellAlignment(1,1, GUI.alignment.horizontal.left, GUI.alignment.vertical.top)
    formLayout:setCellAlignment(2,1, GUI.alignment.horizontal.left, GUI.alignment.vertical.top)
    formLayout:setColumnWidth(1, GUI.sizePolicies.percentage, 0.3)
    formLayout:setColumnWidth(2, GUI.sizePolicies.percentage, 0.7)
    formLayout:setCellFitting(1,1, true, false)

    formLayout:setCellPosition(1, 1, formLayout:addChild(GUI.label(3,2,15,3,0x000000,"Refined Storage:"))):setAlignment(GUI.alignment.horizontal.left, GUI.alignment.vertical.center)
    local comboDefaultRS = formLayout:setCellPosition(2, 1, formLayout:addChild(GUI.comboBox(3, 2, 35, 3, 0xFFFFFF, 0x2D2D2D, 0xCCCCCC, 0x888888)))

    comboDefaultRS:addItem("Auto")
    for _,name in pairs(BaseSettings.RS) do
      comboDefaultRS:addItem(name)
    end

    MineOSInterface.mainContainer:drawOnScreen()
  end

  local function update()
    activity(true)
    menuContentContainer:deleteChildren()

    local updateLabel = menuContentContainer:addChild(GUI.label(1,1,menuContentContainer.width,menuContentContainer.height, 0x000000, "Checking for updates..."))
    updateLabel:setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.center)
    MineOSInterface.mainContainer:drawOnScreen()

    if tryDownload(BaseSettings.UpdateURL, "/tmp/version.cfg") then
      versionData = unserializeFile("/tmp/version.cfg")
      fs.remove("/tmp/version.cfg")

      if tonumber(versionData.VersionStamp) > BaseSettings.VersionStamp then
        updateLabel.text = "New update available, " .. BaseSettings.Version .. " => " .. versionData.Version
        local updateButton = menuContentContainer:addChild(GUI.button(math.floor(menuContentContainer.width/2-26/2),10,26,3,0x3366CC,0xFFFFFF,0xAAAAAA,0x000000,"Update Now"))
        updateButton.onTouch = function()
          activity(true)

          -- Disable interface, .disabled = true not working.
          for i = 1, menuList.itemSize do
            menuList:getItem(i).onTouch = function() return end
          end
          menuList.select = function(object) return object end
          for i = 1, window.tabBar.itemSize do
            window.tabBar:getItem(i).onTouch = function() return end
          end
          window.tabBar.select = function(object) return object end

          updateButton:delete()
          local dlImg = image.load(resourcesPath .. "/../Icons/Downloading.pic")
          local img = menuContentContainer:addChild(GUI.image(math.floor(menuContentContainer.width/2 - image.getWidth(dlImg)/2),2,dlImg))

          local progress = menuContentContainer:addChild(GUI.progressBar(math.floor(menuContentContainer.width/2-50/2),math.floor(menuContentContainer.height/2)+2,50,0x3392FF,0xBBBBBB,0x555555,0,true,false))

          updateLabel.text = "Downloading file list..."
          -- menuContentContainer:draw()
          --buffer.draw()
          MineOSInterface.mainContainer:drawOnScreen()

          if tryDownload(BaseSettings.FilesURL, resourcesPath .. "../Files.cfg") then
            filesData = unserializeFile(resourcesPath .. "../Files.cfg")
            fs.remove(resourcesPath .. "../Files.cfg")

            for i = 1, #filesData.duringInstall do
              updateLabel.text = "Downloading " .. string.limit(filesData.duringInstall[i].path, 50 - 12 - 1, "center")
              progress.value = math.round(i/#filesData.duringInstall*100)
              window:draw() -- for the activity spinner
              menuContentContainer:draw()
              buffer.draw()
              --os.sleep(1)
              web.download(filesData.duringInstall[i].url, filesData.duringInstall[i].path)
            end

            img:delete()
            progress:delete()
            updateLabel.text = "Update complete, please restart this app"
            local okImg = image.load(resourcesPath .. "/../Icons/OK.pic")
            local img = menuContentContainer:addChild(GUI.image(math.floor(menuContentContainer.width/2 - image.getWidth(okImg)/2),3,okImg))

            menuContentContainer:draw()
            buffer.draw()

            activity(false)
          end
        end
      else
        updateLabel.text = "You are up to date, current version: " .. versionData.Version

        local okImg = image.load(resourcesPath .. "/../Icons/OK.pic")
        local img = menuContentContainer:addChild(GUI.image(math.floor(menuContentContainer.width/2 - image.getWidth(okImg)/2),3,okImg))
      end
    end
    activity(false)
  end

  menuList:addItem("About").onTouch = function()
    about()
  end

  menuList:addItem("Settings").onTouch = function() settings() end
  menuList:addItem("Update").onTouch = function() update() end

  menuList:getItem(1).onTouch()

end

----

return module
