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
local MineOSCore = require("MineOSCore")
local unicode = require("unicode")
local rs = component.block_refinedstorage_cable
local event = require("event")

--local resourcesPath = "/MineOS/Applications/BaseControl.app/" -- required for IDE
local resourcesPath = MineOSCore.getCurrentScriptDirectory()
local module = {}
module.name = "AutoCrafting"

module.onTouch = function()
  window.contentContainer:deleteChildren()
  local craftPanel = window.contentContainer:addChild(GUI.panel(1,1,1,1, 0xE1E1E1))
  local mainLayout = window.contentContainer:addChild(GUI.layout(1,1, window.contentContainer.width, window.contentContainer.height, 2, 1))
  
  mainLayout:setColumnWidth(1, GUI.sizePolicies.percentage, 0.4)
  mainLayout:setColumnWidth(2, GUI.sizePolicies.percentage, 0.6)
  mainLayout:setCellFitting(1,1, true, true)
  mainLayout:setCellFitting(2,1, true, true)

  -- Tree
  local treeLayout = mainLayout:setCellPosition(1,1, mainLayout:addChild(GUI.layout(1,1,1,1,1,2)))
  treeLayout:setRowHeight(1, GUI.sizePolicies.percentage, 1.0) -- 0.6
  --treeLayout:setRowHeight(2, GUI.sizePolicies.percentage, 0.1)
  treeLayout:setRowHeight(2, GUI.sizePolicies.absolute, 3)
  treeLayout:setCellFitting(1,1, true, true)
  treeLayout:setCellFitting(1,2, true, true)
  local tree = treeLayout:setCellPosition(1,1, treeLayout:addChild(GUI.tree(1,1,1,1, 0xE1E1E1, 0x3C3C3C, 0x3C3C3C, 0xAAAAAA, 0x3C3C3C, 0xFFFFFF,  0xBBBBBB, 0xAAAAAA, 0xC3C3C3, 0x444444, GUI.filesystemModes.both, GUI.filesystemModes.file)))
  local searchTree = treeLayout:setCellPosition(1,2, treeLayout:addChild(GUI.input(1,1,1,1, 0x444444, 0x666666, 0x888888, 0x444444, 0x262626, nil, "Search")))
  
  searchTree.onInputFinished = function()
    tree.onItemExpanded()
  end

  -- Items
  local itemsLayout = mainLayout:setCellPosition(2,1, mainLayout:addChild(GUI.layout(1,1,1,1,1,2)))
  itemsLayout:setRowHeight(1, GUI.sizePolicies.percentage, 0.6) -- 0.6
  itemsLayout:setRowHeight(2, GUI.sizePolicies.percentage, 0.4)
  itemsLayout:setCellFitting(1,1, true, false, 6,0)
  itemsLayout:setCellFitting(1,2, true, true)

  
  local infoLabel   = itemsLayout:setCellPosition(1,1, itemsLayout:addChild(GUI.label(1,1,1,1, 0x3C3C3C, "Nothing selected")):setAlignment(GUI.alignment.horizontal.center,GUI.alignment.vertical.bottom))
  local itemEnabled = itemsLayout:setCellPosition(1,1, itemsLayout:addChild(GUI.switchAndLabel(2,2,25,8, 0x66DB80, 0x1D1D1D, 0x666666, 0x999999, "Enabled", false)))
  local totalCreate = itemsLayout:setCellPosition(1,1, itemsLayout:addChild(GUI.input(1,1,1,3, 0xFFFFFF, 0x666666, 0x888888, 0xFFFFFF, 0x262626, nil, "Total")))
  local itemIdle    = itemsLayout:setCellPosition(1,1, itemsLayout:addChild(GUI.switchAndLabel(2,2,25,8, 0x66DB80, 0x1D1D1D, 0x666666, 0x999999, "Only while Idle", false)))
  
  --itemsLayout:setCellPosition(1,1, itemsLayout:addChild(GUI.input(1,1,1,3, 0xFFFFFF, 0x666666, 0x888888, 0xFFFFFF, 0x262626, nil, "Threshold")))
  local itemSubmit   = itemsLayout:setCellPosition(1,1, itemsLayout:addChild(GUI.button(1,1,1,1,0x3C3C3C, 0xFFFFFF, 0x0, 0xFFFFFF, "Save")))
  
  local outputTextBox= itemsLayout:setCellPosition(1,2, itemsLayout:addChild(GUI.textBox(1,1,1,1, 0x000000, 0x888888,_G.logData, 1,1,0)))

  totalCreate.validator = function (text)
    return tonumber(text) ~= nil
  end

  --itemTreshold.validator = function(text) return tonumber(text) ~= nil end

  local function updateList(tree, t, definitionName, offset)
    local list = {}
    for key in pairs(t) do
      table.insert(list, key)
    end

    local i, expandables = 1, {}
    while i <= #list do
      if type(t[list[i]]) == "table" then
        table.insert(expandables, list[i])
        table.remove(list, i)
      else
        i = i + 1
      end
    end

    table.sort(expandables, function(a,b) return unicode.lower(tostring(a)) < unicode.lower(tostring(b)) end)
    table.sort(list, function(a,b) return unicode.lower(tostring(a)) < unicode.lower(tostring(b)) end)

    for i = 1, #expandables do
      local definition = definitionName .. expandables[i]
      tree:addItem(tostring(expandables[i]), definition, offset, true)
      if tree.expandedItems[definition] then
        updateList(tree, t[expandables[i]], definition, offset+2)
      end
    end

    for i = 1, #list do
      tree:addItem(tostring(list[i]), {key=list[i], value=t[list[i]]}, offset, false)
    end
  end

  tree.onItemExpanded = function()
    tree.items = {}
    
    local craftable = {}

    local patterns = rs.getPatterns()
    if patterns == nil then
      return
    end
    
    for i,value in ipairs(patterns) do 
      local mod,item = value["name"]:match("([^:]+):([^:]+)")
      local label = value["label"]
      local item_name = value["name"] .. ":" .. value["damage"]

      -- Mark Actives with *
      if _G.BaseConfig[item_name] then
        label = label .. " *"
      end

      if (#searchTree.text == 0 or string.match(string.lower(label), string.lower(searchTree.text))) then
        if not craftable[mod] then
          craftable[mod] = {}
        end
        craftable[mod][label] = item_name
      end
    end

    updateList(tree, craftable, "craftable", 1)
  end

  -- TODO fixme
  if _G.outputTimer then
    event.cancel(_G.outputTimer)
  end

  _G.outputTimer = event.timer(1, function()
    outputTextBox.lines = {}
    for i = 1, #_G.logData do
      table.insert(outputTextBox.lines, _G.logData[i])
    end
    -- Scroll down
    if #outputTextBox.lines > outputTextBox.height then 
      outputTextBox.currentLine = #outputTextBox.lines-outputTextBox.height+1
    end
  end, math.huge)

  tree.onItemSelected = function()

    infoLabel.text = tostring(tree.selectedItem.value)

    if _G.BaseConfig[infoLabel.text] then
      itemEnabled.switch:setState(true)
      totalCreate.text = _G.BaseConfig[infoLabel.text]["total"]
      itemIdle.switch:setState(_G.BaseConfig[infoLabel.text]["idle"])
    else
      itemEnabled.switch:setState(false)
      totalCreate.text = ""
      itemIdle.switch:setState(false)
    end

    itemEnabled.switch.disabled = false
    if itemEnabled.switch.state == true then
      totalCreate.disabled = false
      itemIdle.switch.disabled = false
      itemSubmit.disabled = false
    else
      itemSubmit.disabled = true
      totalCreate.disabled = true
      itemIdle.switch.disabled = true
    end
  end

  itemEnabled.switch.onStateChanged = function(mainContainer, switch, eventData, state)
    if state == true then
      totalCreate.disabled = false
      itemIdle.switch.disabled = false
      itemSubmit.disabled = false
    else
      totalCreate.disabled = true
      itemIdle.switch.disabled = true
    end
  end
  itemSubmit.onTouch = function()
    if itemEnabled.switch.state then
      _G.BaseConfig[infoLabel.text] = {total=totalCreate.text, idle=itemIdle.switch.state}
     
      log({text="Saved Item " .. infoLabel.text .. " (" ..totalCreate.text .. ")", color = 0x008800})
      table.toFile(resourcesPath .. "config", _G.BaseConfig)
    else
      if _G.BaseConfig[infoLabel.text] then
        log({text="Removed Item " .. infoLabel.text, color = 0x880000})
        _G.BaseConfig[infoLabel.text] = nil
        totalCreate.text = ""
        itemIdle.switch:setState(false)
        table.toFile(resourcesPath .. "config", _G.BaseConfig)
      end
    end

    tree.onItemExpanded()
    mainContainer:draw()
    buffer.draw()
  end

  itemEnabled.switch.disabled = true
  totalCreate.disabled = true
  itemIdle.disabled = true
  itemSubmit.disabled = true
  itemSubmit.colors.disabled.background = 0x777777
  itemSubmit.colors.disabled.text = 0xD2D2D2
  tree.onItemExpanded()
end

----

return module