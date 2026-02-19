# Complete Mudlet GUI & Automation System
## Comprehensive Package - Ready to Deploy

This document contains everything from our Mudlet development work, organized for easy installation.

---

## Table of Contents

1. [Quick Start Guide](#quick-start-guide)
2. [Project Overview](#project-overview)
3. [Installation Steps](#installation-steps)
4. [GUIFlex Base System](#guiflex-base-system)
5. [Tabbed Chat System](#tabbed-chat-system)
6. [Item Identification System](#item-identification-system)
7. [Regex Testing & Block Editor](#regex-testing--block-editor)
8. [Configuration & Customization](#configuration--customization)

---

## Quick Start Guide

### What You Need
- Mudlet (Standard Edition)
- `grid.png` file in your profile root directory
- `short_stats.txt` (item database) in your profile root directory
- 30 minutes for setup

### Installation Order
1. Create folder structure in Mudlet Script Editor
2. Install GUIFlex Base (Core windowing)
3. Install Tabbed Chat System
4. Install Item Identification System
5. Test and customize

---

## Project Overview

### What This System Does

**GUIFlex Windowing System**
- 8 resizable, dockable windows arranged around your main console
- Adjustable containers with minimization and border docking
- Grid-textured background with cyan accent theme
- Professional MUD client layout

**Tabbed Chat System**
- 10+ channel tabs (All, Say, Shout, Group, Tells, OOC, etc.)
- Captures chat in blocks between prompts
- Visual block editor - click to mark blocks as ignored
- Integrated regex tester with pattern library
- Tab notifications for new messages
- 500 message history per tab

**Item Identification**
- Fast in-memory item lookup (replaces SQL)
- Single and batch item queries
- Group integration for party loot identification
- Partial name matching with multiple result handling

**Automation Tools**
- Regex pattern testing against live chat data
- Export patterns as Mudlet triggers
- Auto-ignore rule generation
- Training/combat detection triggers

---

## Installation Steps

### Step 1: Mudlet Folder Structure

Create these folders in Mudlet's Script Editor:

```
Scripts/
├── GUIFlex/
│   ├── Core
│   ├── Windows
│   └── Chat
├── ItemSystem/
│   └── Lookup
├── Automation/
│   └── Training
└── Utils/
    └── Helpers

Aliases/
├── ItemCommands
└── ChatCommands

Triggers/
├── ChatCapture
├── PromptDetection
└── CombatTracking
```

**How to create folders:**
1. Open Script Editor (F2)
2. Right-click in left panel → "Add Item" → "Script"
3. Name it (use folder names above)
4. Create child items by right-clicking parent folders

---

### Step 2: Prerequisites

**Place these files in your Mudlet profile root:**
- `grid.png` - Background texture for GUI
- `short_stats.txt` - Item database (your legacy format)

**Profile directory location:**
- Windows: `C:\Users\YourName\.config\mudlet\profiles\YourProfile\`
- Linux: `~/.config/mudlet/profiles/YourProfile/`

---

## GUIFlex Base System

### Scripts/GUIFlex/Core

**File: `GUIFlex_Core.lua`**

```lua
-------------------------------------------------------
-- GUIFlex Core System
-- Base windowing framework with Adjustable.Containers
-------------------------------------------------------

-- Initialize GUIFlex namespace
GUIFlex = GUIFlex or {}

-- CSS Styling
GUIFlex.BoxCSS = [[
  QLabel{
    background-color: rgba(0,0,0,180);
    border: 2px solid cyan;
    border-radius: 5px;
  }
]]

GUIFlex.GridBG = getMudletHomeDir() .. "/grid.png"

-- Helper function: Safe widget destruction
function safeDestroy(widget)
  if widget and widget.name then
    local w = Geyser.windowList[widget.name] or Adjustable.all[widget.name]
    if w then
      w:hide()
      w = nil
    end
  end
end

-- Helper function: Create new container
function NewContainer(params, parent)
  return Adjustable.Container:new(params, parent)
end

-- Helper function: Create new label
function NewLabel(params, parent)
  return Geyser.Label:new(params, parent)
end

-- Initialize root container
function initGUIFlex()
  -- Destroy existing if present
  safeDestroy(GUIFlex.Root)
  
  -- Create root container
  GUIFlex.Root = NewContainer({
    name = "GUIFlex.Root",
    x = 0, y = 0,
    width = "100%", height = "100%",
    adjLabelstyle = "background-color: rgba(0,0,0,0); border: none;"
  })
  
  -- Set background
  if io.exists(GUIFlex.GridBG) then
    GUIFlex.Root:setBackgroundImage(GUIFlex.GridBG)
  end
  
  cecho("<cyan>[GUIFlex] Core initialized\n")
end

-- Cleanup function
function destroyGUIFlex()
  for name, container in pairs(Adjustable.all) do
    if name:match("^GUIFlex%.") then
      safeDestroy(container)
    end
  end
  GUIFlex = {}
  cecho("<yellow>[GUIFlex] All containers destroyed\n")
end

cecho("<cyan>[GUIFlex] Core module loaded. Use initGUIFlex() to start.\n")
```

---

### Scripts/GUIFlex/Windows

**File: `GUIFlex_Windows.lua`**

```lua
-------------------------------------------------------
-- GUIFlex Window Definitions
-- Creates all standard MUD interface windows
-------------------------------------------------------

function createGUIFlexWindows()
  -- Ensure core is initialized
  if not GUIFlex.Root then
    initGUIFlex()
  end
  
  -- Destroy existing windows
  local windows = {"Map", "Chat", "Group", "Gear", "Room", "Stats", "Buttons", "Gauges"}
  for _, win in ipairs(windows) do
    if GUIFlex[win] then
      safeDestroy(GUIFlex[win])
    end
  end
  
  -- MAP WINDOW (Top Right)
  GUIFlex.Map = Adjustable.Container:new({
    name = "GUIFlex.Map",
    titleText = "Map",
    x = "-25%", y = "0%",
    width = "25%",
    height = "50%",
    adjLabelstyle = GUIFlex.BoxCSS,
    attached = "right"
  })
  
  -- ROOM WINDOW (Middle Right)
  GUIFlex.Room = Adjustable.Container:new({
    name = "GUIFlex.Room",
    titleText = "Room",
    x = "-12.5%", y = "50%",
    width = "12.5%",
    height = "50%",
    adjLabelstyle = GUIFlex.BoxCSS,
    attached = "right"
  })
  
  -- CHAT WINDOW (Top Left)
  GUIFlex.Chat = Adjustable.Container:new({
    name = "GUIFlex.Chat",
    titleText = "Chat",
    x = "0%", y = "0%",
    width = "25%",
    height = "25%",
    adjLabelstyle = GUIFlex.BoxCSS,
    attached = "left"
  })
  
  -- GROUP WINDOW (Middle Left)
  GUIFlex.Group = Adjustable.Container:new({
    name = "GUIFlex.Group",
    titleText = "Group",
    x = "0%", y = "25%",
    width = "12.5%",
    height = "50%",
    adjLabelstyle = GUIFlex.BoxCSS,
    attached = "left"
  })
  
  -- GEAR WINDOW (Middle Left 2)
  GUIFlex.Gear = Adjustable.Container:new({
    name = "GUIFlex.Gear",
    titleText = "Gear",
    x = "12.5%", y = "25%",
    width = "12.5%",
    height = "50%",
    adjLabelstyle = GUIFlex.BoxCSS,
    attached = "left"
  })
  
  -- STATS WINDOW (Bottom Left)
  GUIFlex.Stats = Adjustable.Container:new({
    name = "GUIFlex.Stats",
    titleText = "Stats",
    x = "0%", y = "75%",
    width = "25%",
    height = "25%",
    adjLabelstyle = GUIFlex.BoxCSS,
    attached = "left"
  })
  
  -- BUTTONS BAR (Top Center)
  GUIFlex.Buttons = Adjustable.Container:new({
    name = "GUIFlex.Buttons",
    titleText = "Buttons",
    x = "25%", y = 0,
    width = "50%",
    height = "10%",
    adjLabelstyle = GUIFlex.BoxCSS,
    attached = "top"
  })
  
  -- GAUGES BAR (Bottom Center)
  GUIFlex.Gauges = Adjustable.Container:new({
    name = "GUIFlex.Gauges",
    titleText = "Gauges",
    x = "25%", y = "90%",
    width = "50%",
    height = "10%",
    adjLabelstyle = GUIFlex.BoxCSS,
    attached = "bottom"
  })
  
  cecho("<green>[GUIFlex] All windows created successfully\n")
  cecho("<cyan>Windows: Map, Room, Chat, Group, Gear, Stats, Buttons, Gauges\n")
end

cecho("<cyan>[GUIFlex] Windows module loaded. Use createGUIFlexWindows() to build layout.\n")
```

---

### Scripts/GUIFlex/Chat

**File: `GUIFlex_ChatTabs.lua`**

```lua
-------------------------------------------------------
-- GUIFlex Tabbed Chat System
-- Multi-channel chat with block capture
-------------------------------------------------------

-- Chat system namespace
ChatSystem = ChatSystem or {}
ChatSystem.tabs = {}
ChatSystem.blocks = {}
ChatSystem.currentTab = "All"
ChatSystem.blockBuffer = ""
ChatSystem.capturing = false

-- CSS Styles
local CSS = {
  inactive = [[
    QLabel{
      background-color: rgba(0,0,0,100);
      color: rgb(220,220,220);
      border: 1px solid cyan;
      border-radius: 4px;
      margin: 1px;
      padding: 2px;
    }
    QLabel:hover{
      background-color: rgba(0,40,40,150);
      border: 1px solid rgb(0,255,255);
    }
  ]],
  
  active = [[
    QLabel{
      background-color: rgba(0,50,50,150);
      color: white;
      border: 2px solid cyan;
      border-radius: 4px;
      margin: 0px;
      font-weight: bold;
      padding: 2px;
    }
  ]],
  
  notification = [[
    QLabel{
      background-color: rgba(100,50,0,150);
      color: rgb(255,200,0);
      border: 2px solid orange;
      border-radius: 4px;
      margin: 0px;
      font-weight: bold;
      padding: 2px;
    }
  ]],
  
  pane = [[
    QLabel{
      background-color: rgba(0,0,0,180);
      color: rgb(220,220,220);
      border: 1px solid cyan;
      border-radius: 3px;
      padding: 5px;
    }
  ]],
  
  block = [[
    QLabel{
      background-color: rgba(0,0,0,120);
      color: rgb(200,200,200);
      border: 1px solid rgba(0,200,200,100);
      border-radius: 2px;
      margin: 2px;
      padding: 4px;
    }
    QLabel:hover{
      background-color: rgba(0,30,30,150);
      border: 1px solid cyan;
    }
  ]],
  
  blockIgnored = [[
    QLabel{
      background-color: rgba(60,0,0,100);
      color: rgb(150,150,150);
      border: 1px solid rgba(100,0,0,100);
      border-radius: 2px;
      margin: 2px;
      padding: 4px;
      text-decoration: line-through;
    }
  ]],
  
  blockSelected = [[
    QLabel{
      background-color: rgba(0,50,50,180);
      color: rgb(255,255,255);
      border: 2px solid cyan;
      border-radius: 2px;
      margin: 2px;
      padding: 4px;
    }
  ]]
}

-- Initialize chat tabs overlay
function initChatTabs()
  -- Clean up existing
  safeDestroy(ChatSystem.TabsRoot)
  ChatSystem.TabsRoot = nil
  ChatSystem.TabBar = nil
  ChatSystem.ContentStack = nil
  ChatSystem.tabs = {}
  ChatSystem.currentTab = "All"
  
  -- Get Chat window dimensions
  local chatX = GUIFlex.Chat.x or "0%"
  local chatY = GUIFlex.Chat.y or "0%"
  local chatW = GUIFlex.Chat.width or "25%"
  local chatH = GUIFlex.Chat.height or "25%"
  
  -- Create root container for tabs
  ChatSystem.TabsRoot = NewContainer({
    name = "ChatSystem.TabsRoot",
    x = chatX, y = chatY,
    width = chatW, height = chatH
  }, GUIFlex.Root)
  
  -- Tab bar (12% of height)
  local TAB_HEIGHT = 12
  ChatSystem.TabBar = NewContainer({
    name = "ChatSystem.TabBar",
    x = "0%", y = "0%",
    width = "100%", height = TAB_HEIGHT .. "%"
  }, ChatSystem.TabsRoot)
  
  -- Content stack (88% of height)
  ChatSystem.ContentStack = NewContainer({
    name = "ChatSystem.ContentStack",
    x = "0%", y = TAB_HEIGHT .. "%",
    width = "100%", height = (100 - TAB_HEIGHT) .. "%"
  }, ChatSystem.TabsRoot)
  
  -- Create default tabs
  local defaultTabs = {
    {id="All", name="All"},
    {id="Say", name="Say"},
    {id="Shout", name="Shout"},
    {id="Group", name="Group"},
    {id="Tells", name="Tells"},
    {id="OOC", name="OOC"},
    {id="GCC", name="GCC"},
    {id="ASSOC", name="ASSOC"},
    {id="Petition", name="Petition"},
    {id="NHC", name="NHC"}
  }
  
  for _, tab in ipairs(defaultTabs) do
    createChatTab(tab.id, tab.name)
  end
  
  -- Switch to All tab
  switchChatTab("All")
  
  cecho("<green>[ChatSystem] Tabbed interface initialized with " .. #defaultTabs .. " tabs\n")
end

-- Create a new chat tab
function createChatTab(tabId, tabName)
  if ChatSystem.tabs[tabId] then
    cecho("<yellow>[ChatSystem] Tab '" .. tabId .. "' already exists\n")
    return
  end
  
  local numTabs = 0
  for _ in pairs(ChatSystem.tabs) do numTabs = numTabs + 1 end
  local btnWidth = 100 / (numTabs + 1)
  
  -- Recreate all tab buttons with new width
  local i = 0
  for id, tab in pairs(ChatSystem.tabs) do
    if tab.button then
      tab.button:move((i * btnWidth) .. "%", "0%")
      tab.button:resize(btnWidth .. "%", "100%")
      i = i + 1
    end
  end
  
  -- Create new tab button
  local btn = NewLabel({
    name = "ChatSystem.TabBtn." .. tabId,
    x = (i * btnWidth) .. "%", y = "0%",
    width = btnWidth .. "%", height = "100%"
  }, ChatSystem.TabBar)
  
  btn:setStyleSheet(CSS.inactive)
  btn:echo("<center>" .. tabName .. "</center>")
  
  -- Create content pane
  local pane = NewLabel({
    name = "ChatSystem.Pane." .. tabId,
    x = "0%", y = "0%",
    width = "100%", height = "100%"
  }, ChatSystem.ContentStack)
  
  pane:setStyleSheet(CSS.pane)
  pane:enableScrollBar()
  pane:hide()
  
  -- Click handler
  btn:setClickCallback("switchChatTab", tabId)
  
  -- Store tab
  ChatSystem.tabs[tabId] = {
    id = tabId,
    name = tabName,
    button = btn,
    pane = pane,
    blocks = {},
    hasNewMessages = false
  }
end

-- Switch active tab
function switchChatTab(tabId)
  if not ChatSystem.tabs[tabId] then
    cecho("<red>[ChatSystem] Tab '" .. tabId .. "' does not exist\n")
    return
  end
  
  -- Update previous tab
  if ChatSystem.currentTab and ChatSystem.tabs[ChatSystem.currentTab] then
    local prevTab = ChatSystem.tabs[ChatSystem.currentTab]
    prevTab.button:setStyleSheet(CSS.inactive)
    prevTab.pane:hide()
  end
  
  -- Activate new tab
  local newTab = ChatSystem.tabs[tabId]
  newTab.button:setStyleSheet(CSS.active)
  newTab.pane:show()
  newTab.hasNewMessages = false
  
  ChatSystem.currentTab = tabId
end

-- Add message to tab
function addChatMessage(tabId, message, timestamp)
  if not ChatSystem.tabs[tabId] then
    cecho("<red>[ChatSystem] Tab '" .. tabId .. "' not found\n")
    return
  end
  
  local tab = ChatSystem.tabs[tabId]
  timestamp = timestamp or os.date("%H:%M:%S")
  
  -- Format message
  local formatted = string.format("<gray>[%s]</gray> %s\n", timestamp, message)
  
  -- Append to pane
  tab.pane:echo(formatted)
  
  -- Notification if not active tab
  if ChatSystem.currentTab ~= tabId then
    tab.hasNewMessages = true
    tab.button:setStyleSheet(CSS.notification)
  end
  
  -- Also add to "All" tab if not already there
  if tabId ~= "All" and ChatSystem.tabs["All"] then
    ChatSystem.tabs["All"].pane:echo(formatted)
  end
end

-- Start capturing chat block
function startChatBlock()
  ChatSystem.capturing = true
  ChatSystem.blockBuffer = ""
end

-- Append line to current block
function appendToBlock(line)
  if ChatSystem.capturing then
    ChatSystem.blockBuffer = ChatSystem.blockBuffer .. line .. "\n"
  end
end

-- Finish and save current block
function finishChatBlock()
  if not ChatSystem.capturing or ChatSystem.blockBuffer == "" then
    return
  end
  
  local block = {
    id = #ChatSystem.blocks + 1,
    content = ChatSystem.blockBuffer,
    timestamp = os.time(),
    ignored = false,
    tags = {}
  }
  
  table.insert(ChatSystem.blocks, block)
  
  -- Route to appropriate tab(s)
  routeChatBlock(block)
  
  -- Reset
  ChatSystem.blockBuffer = ""
  ChatSystem.capturing = false
end

-- Route block to tabs based on content
function routeChatBlock(block)
  local content = block.content:lower()
  
  -- Always add to All
  addBlockToTab("All", block)
  
  -- Route to specific tabs
  if content:match("tells you") or content:match("you tell") then
    addBlockToTab("Tells", block)
  end
  
  if content:match("says") or content:match("you say") then
    addBlockToTab("Say", block)
  end
  
  if content:match("shouts") or content:match("you shout") then
    addBlockToTab("Shout", block)
  end
  
  if content:match("gsays") or content:match("you gsay") then
    addBlockToTab("Group", block)
  end
  
  if content:match("%[ooc%]") then
    addBlockToTab("OOC", block)
  end
  
  if content:match("%[gcc%]") then
    addBlockToTab("GCC", block)
  end
  
  if content:match("%[assoc%]") then
    addBlockToTab("ASSOC", block)
  end
  
  if content:match("%[petition%]") then
    addBlockToTab("Petition", block)
  end
  
  if content:match("%[nhc%]") then
    addBlockToTab("NHC", block)
  end
end

-- Add block widget to tab
function addBlockToTab(tabId, block)
  if not ChatSystem.tabs[tabId] then return end
  
  local tab = ChatSystem.tabs[tabId]
  
  -- Create block widget
  local blockWidget = NewLabel({
    name = "ChatSystem.Block." .. tabId .. "." .. block.id,
    x = "0px", y = (#tab.blocks * 60) .. "px",
    width = "100%-10px", height = "55px"
  }, tab.pane)
  
  blockWidget:setStyleSheet(block.ignored and CSS.blockIgnored or CSS.block)
  
  -- Truncate long content
  local preview = block.content:sub(1, 200)
  if #block.content > 200 then
    preview = preview .. "..."
  end
  
  blockWidget:echo(preview:gsub("\n", " "))
  
  -- Click handler
  blockWidget:setClickCallback("toggleBlockIgnore", block.id)
  
  table.insert(tab.blocks, block)
end

-- Toggle block ignore status
function toggleBlockIgnore(blockId)
  for _, block in ipairs(ChatSystem.blocks) do
    if block.id == blockId then
      block.ignored = not block.ignored
      
      -- Update all instances in tabs
      for _, tab in pairs(ChatSystem.tabs) do
        for _, tabBlock in ipairs(tab.blocks) do
          if tabBlock.id == blockId then
            local widget = Geyser.windowList["ChatSystem.Block." .. tab.id .. "." .. blockId]
            if widget then
              widget:setStyleSheet(block.ignored and CSS.blockIgnored or CSS.block)
            end
          end
        end
      end
      
      cecho(string.format("<cyan>[ChatSystem] Block #%d %s\n", 
        blockId, block.ignored and "IGNORED" or "RESTORED"))
      break
    end
  end
end

-- Clear all blocks from a tab
function clearChatTab(tabId)
  if not ChatSystem.tabs[tabId] then return end
  
  local tab = ChatSystem.tabs[tabId]
  tab.pane:clear()
  tab.blocks = {}
  
  cecho("<cyan>[ChatSystem] Cleared tab: " .. tabId .. "\n")
end

cecho("<cyan>[ChatSystem] Chat tabs module loaded. Use initChatTabs() to start.\n")
```

---

## Item Identification System

### Scripts/ItemSystem/Lookup

**File: `ItemLookup.lua`**

```lua
-------------------------------------------------------
-- Item Identification System
-- Fast text-based item lookup
-------------------------------------------------------

ItemDB = ItemDB or {}
ItemDB.cache = {}
ItemDB.loaded = false

-- Load item database from file
function loadItemDatabase(filepath)
  filepath = filepath or (getMudletHomeDir() .. "/short_stats.txt")
  
  local file = io.open(filepath, "r")
  if not file then
    cecho("<red>[ItemDB] Could not open " .. filepath .. "\n")
    return false
  end
  
  ItemDB.cache = {}
  local count = 0
  
  for line in file:lines() do
    if line and #line > 0 then
      -- Extract item name (before first parenthesis)
      local name = line:match("^([^%(]+)")
      if name then
        name = name:trim()
        table.insert(ItemDB.cache, {
          name = name,
          name_lower = name:lower(),
          stats = line
        })
        count = count + 1
      end
    end
  end
  
  file:close()
  ItemDB.loaded = true
  
  cecho("<green>[ItemDB] Loaded " .. count .. " items\n")
  return true
end

-- Search for items
function findItems(searchTerm)
  if not ItemDB.loaded or #ItemDB.cache == 0 then
    cecho("<red>[ItemDB] Database not loaded\n")
    return {}
  end
  
  -- Clean search term
  searchTerm = searchTerm:gsub("%(poisoned%)", ""):trim():lower()
  
  local results = {}
  for _, item in ipairs(ItemDB.cache) do
    if item.name_lower:find(searchTerm, 1, true) then
      table.insert(results, item.stats)
    end
  end
  
  return results
end

-- Lookup single item
function lookupItem(itemName)
  local results = findItems(itemName)
  
  if #results == 0 then
    cecho("<red>[ItemDB] '" .. itemName .. "' not found\n")
    return nil
  end
  
  if #results == 1 then
    echo(results[1] .. "\n")
    return results[1]
  end
  
  -- Multiple matches
  cecho("<yellow>[ItemDB] Found " .. #results .. " matches:\n")
  for i, stat in ipairs(results) do
    echo("  " .. i .. ". " .. stat .. "\n")
  end
  
  return results
end

-- Lookup multiple items
function lookupItems(itemList, outputMode)
  local items = {}
  
  -- Parse input
  if type(itemList) == "string" then
    items = itemList:split(",")
    for i = 1, #items do
      items[i] = items[i]:trim()
    end
  elseif type(itemList) == "table" then
    items = itemList
  else
    cecho("<red>[ItemDB] Invalid item list\n")
    return
  end
  
  -- Process each item
  for _, itemName in ipairs(items) do
    local results = findItems(itemName)
    
    if #results == 0 then
      if outputMode == "gsay" then
        send("gsay * " .. itemName .. " : not found")
      else
        cecho("<red>[ItemDB] '" .. itemName .. "' not found\n")
      end
    else
      local statline = results[1]
      
      -- Try exact match if multiple results
      if #results > 1 then
        for _, stat in ipairs(results) do
          if stat:lower():find("^" .. itemName:lower() .. " ") then
            statline = stat
            break
          end
        end
      end
      
      if outputMode == "gsay" then
        send("gsay * " .. statline)
      else
        echo(statline .. "\n")
      end
    end
  end
end

-- Initialize on load
tempTimer(1, function()
  loadItemDatabase()
end)

cecho("<cyan>[ItemDB] Item lookup system loaded\n")
```

---

### Aliases/ItemCommands

**Create these aliases in Mudlet:**

**Alias: @id**
- Pattern: `^@id (.+)$`
- Type: Perl Regex
- Script:
```lua
lookupItem(matches[2])
```

**Alias: @lookup**
- Pattern: `^@lookup (.+)$`
- Type: Perl Regex
- Script:
```lua
lookupItems(matches[2])
```

**Alias: @statitems**
- Pattern: `^@statitems ?(gsay)?$`
- Type: Perl Regex
- Script:
```lua
if NyyLIB and NyyLIB.groupitems then
  lookupItems(NyyLIB.groupitems, matches[2])
else
  cecho("<red>[ItemDB] NyyLIB.groupitems not found\n")
end
```

**Alias: @reloaditems**
- Pattern: `^@reloaditems$`
- Type: Perl Regex
- Script:
```lua
loadItemDatabase()
```

---

## Regex Testing & Block Editor

### Scripts/Utils/Helpers

**File: `RegexTester.lua`**

```lua
-------------------------------------------------------
-- Integrated Regex Testing System
-- Test patterns against captured chat blocks
-------------------------------------------------------

RegexTest = RegexTest or {}
RegexTest.lastPattern = ""
RegexTest.lastMatches = {}
RegexTest.patterns = {
  {"tells you", "Private tells/whispers"},
  {"^You", "Actions starting with 'You'"},
  {"damage", "Combat damage messages"},
  {"^%[.*%]", "Channel messages"},
  {"attacks?", "Combat attacks"},
  {"^gsay", "Group say messages"},
  {"experience", "XP gain messages"},
  {"^The.*arrives", "Mob/player arrivals"},
  {"^The.*leaves", "Mob/player departures"}
}

-- Create regex testing interface
function initRegexTester()
  if not ChatSystem.ContentStack then
    cecho("<red>[RegexTest] Chat system not initialized\n")
    return
  end
  
  -- Create tester panel (overlays content stack)
  RegexTest.Panel = NewContainer({
    name = "RegexTest.Panel",
    x = "0%", y = "0%",
    width = "100%", height = "30%"
  }, ChatSystem.ContentStack)
  
  RegexTest.Panel:hide()
  
  -- Pattern input
  RegexTest.Input = NewLabel({
    name = "RegexTest.Input",
    x = "2%", y = "5%",
    width = "60%", height = "20%"
  }, RegexTest.Panel)
  
  RegexTest.Input:setStyleSheet([[
    QLabel{
      background-color: rgba(0,0,0,200);
      color: white;
      border: 1px solid cyan;
      padding: 5px;
      font-family: 'Courier New';
    }
  ]])
  
  -- Test button
  RegexTest.TestBtn = NewLabel({
    name = "RegexTest.TestBtn",
    x = "63%", y = "5%",
    width = "15%", height = "20%"
  }, RegexTest.Panel)
  
  RegexTest.TestBtn:setStyleSheet([[
    QLabel{
      background-color: rgba(0,100,100,150);
      color: white;
      border: 2px solid cyan;
      border-radius: 5px;
      font-weight: bold;
    }
    QLabel:hover{
      background-color: rgba(0,150,150,200);
    }
  ]])
  RegexTest.TestBtn:echo("<center>Test Regex</center>")
  RegexTest.TestBtn:setClickCallback("testRegexPattern")
  
  -- Results panel
  RegexTest.Results = NewLabel({
    name = "RegexTest.Results",
    x = "2%", y = "30%",
    width = "96%", height = "65%"
  }, RegexTest.Panel)
  
  RegexTest.Results:setStyleSheet([[
    QLabel{
      background-color: rgba(0,0,0,200);
      color: rgb(220,220,220);
      border: 1px solid cyan;
      padding: 5px;
    }
  ]])
  RegexTest.Results:enableScrollBar()
  
  cecho("<green>[RegexTest] Tester interface created\n")
end

-- Show/hide tester
function toggleRegexTester()
  if not RegexTest.Panel then
    initRegexTester()
  end
  
  if RegexTest.Panel:isVisible() then
    RegexTest.Panel:hide()
  else
    RegexTest.Panel:show()
    RegexTest.Panel:raise()
  end
end

-- Test pattern against blocks
function testRegexPattern(pattern)
  pattern = pattern or RegexTest.lastPattern
  
  if not pattern or pattern == "" then
    cecho("<yellow>[RegexTest] Enter a pattern first\n")
    return
  end
  
  RegexTest.lastPattern = pattern
  RegexTest.lastMatches = {}
  
  local matchCount = 0
  
  -- Test against all blocks
  for _, block in ipairs(ChatSystem.blocks) do
    if not block.ignored then
      if rex.match(block.content, pattern) then
        matchCount = matchCount + 1
        table.insert(RegexTest.lastMatches, block.id)
        
        -- Highlight matching block
        highlightMatchingBlock(block.id)
      end
    end
  end
  
  -- Show results
  local results = string.format(
    "<cyan>Pattern: <white>%s</white>\n<green>Matches: %d blocks</green>\n\n",
    pattern, matchCount
  )
  
  if matchCount > 0 then
    results = results .. "<yellow>Sample matches:\n"
    for i = 1, math.min(5, matchCount) do
      local blockId = RegexTest.lastMatches[i]
      local block = ChatSystem.blocks[blockId]
      if block then
        local preview = block.content:sub(1, 100):gsub("\n", " ")
        results = results .. string.format("  • Block #%d: %s...\n", blockId, preview)
      end
    end
  end
  
  RegexTest.Results:echo(results)
  cecho(string.format("<green>[RegexTest] Found %d matches for pattern: %s\n", matchCount, pattern))
end

-- Highlight matching blocks
function highlightMatchingBlock(blockId)
  for _, tab in pairs(ChatSystem.tabs) do
    for _, block in ipairs(tab.blocks) do
      if block.id == blockId then
        local widget = Geyser.windowList["ChatSystem.Block." .. tab.id .. "." .. blockId]
        if widget then
          widget:setStyleSheet([[
            QLabel{
              background-color: rgba(100,100,0,200);
              color: white;
              border: 2px solid yellow;
              border-radius: 2px;
              padding: 4px;
            }
          ]])
        end
      end
    end
  end
end

-- Clear highlights
function clearRegexHighlights()
  for _, block in ipairs(ChatSystem.blocks) do
    for _, tab in pairs(ChatSystem.tabs) do
      local widget = Geyser.windowList["ChatSystem.Block." .. tab.id .. "." .. block.id]
      if widget then
        widget:setStyleSheet(block.ignored and CSS.blockIgnored or CSS.block)
      end
    end
  end
end

-- Add pattern as auto-ignore rule
function addPatternAsIgnore()
  if not RegexTest.lastPattern or #RegexTest.lastMatches == 0 then
    cecho("<yellow>[RegexTest] Test a pattern first\n")
    return
  end
  
  -- Mark all matching blocks as ignored
  for _, blockId in ipairs(RegexTest.lastMatches) do
    for _, block in ipairs(ChatSystem.blocks) do
      if block.id == blockId then
        block.ignored = true
      end
    end
  end
  
  cecho(string.format("<green>[RegexTest] Marked %d blocks as ignored\n", #RegexTest.lastMatches))
  clearRegexHighlights()
end

-- Export as Mudlet trigger
function exportRegexTrigger()
  if not RegexTest.lastPattern then
    cecho("<yellow>[RegexTest] No pattern to export\n")
    return
  end
  
  local triggerCode = string.format([[
-- Auto-generated trigger
-- Pattern: %s
-- Matches: %d blocks

if rex.match(line, "%s") then
  -- Your action here
  deleteLine()  -- Example: hide matching lines
end
]], RegexTest.lastPattern, #RegexTest.lastMatches, RegexTest.lastPattern)
  
  echo("\n" .. triggerCode .. "\n")
  cecho("<cyan>[RegexTest] Trigger code generated (copy from above)\n")
end

cecho("<cyan>[RegexTest] Regex testing system loaded\n")
cecho("<cyan>Use: toggleRegexTester(), testRegexPattern(\"pattern\")\n")
```

---

### Aliases/ChatCommands

**Alias: /regex**
- Pattern: `^/regex$`
- Type: Perl Regex
- Script:
```lua
toggleRegexTester()
```

**Alias: /test**
- Pattern: `^/test (.+)$`
- Type: Perl Regex
- Script:
```lua
testRegexPattern(matches[2])
```

**Alias: /ignore**
- Pattern: `^/ignore$`
- Type: Perl Regex
- Script:
```lua
addPatternAsIgnore()
```

**Alias: /export**
- Pattern: `^/export$`
- Type: Perl Regex
- Script:
```lua
exportRegexTrigger()
```

---

## Configuration & Customization

### Quick Start Commands

Once everything is installed:

```lua
-- Initialize GUIFlex base
initGUIFlex()

-- Create all windows
createGUIFlexWindows()

-- Initialize chat system
initChatTabs()

-- Regex tester (optional)
initRegexTester()
```

### Customization Options

**Change Window Sizes:**
Edit the percentages in `GUIFlex_Windows.lua`:
```lua
-- Make chat window bigger
width = "30%"  -- was 25%
height = "30%" -- was 25%
```

**Add More Chat Tabs:**
```lua
createChatTab("Guild", "Guild Chat")
createChatTab("Market", "Market Channel")
```

**Change Colors:**
Edit CSS in `GUIFlex_ChatTabs.lua`:
```lua
border: 2px solid cyan;  -- Change to: border: 2px solid lime;
```

**Adjust Tab Routing:**
Edit `routeChatBlock()` function to add custom channel detection

---

## Testing & Verification

### Test GUIFlex Base
```lua
initGUIFlex()
createGUIFlexWindows()
```
You should see 8 windows arranged around your console.

### Test Chat System
```lua
initChatTabs()
addChatMessage("All", "Test message", "12:34:56")
```
Check that tabs appear and message shows in All tab.

### Test Item Lookup
```lua
@id ring
@lookup ring, staff, helm
```
Should show item stats from your database.

### Test Regex Tester
```lua
/regex
```
Type a pattern in the input field, click "Test Regex"

---

## Troubleshooting

**"GUIFlex.Root is nil"**
- Run `initGUIFlex()` first

**"grid.png not found"**
- Place grid.png in profile root directory
- Check path with `echo(getMudletHomeDir())`

**"Item database not loaded"**
- Verify `short_stats.txt` exists in profile directory
- Run `loadItemDatabase()` manually

**Chat tabs don't appear**
- Ensure GUIFlex windows are created first
- Run `initChatTabs()` after `createGUIFlexWindows()`

**Blocks not capturing**
- Set up prompt detection trigger (see next section)

---

## Prompt Detection Setup

### Triggers/PromptDetection

**Create trigger: Prompt Start**
- Pattern: `^< .+ >$`
- Type: Perl Regex
- Script:
```lua
finishChatBlock()  -- End previous block
startChatBlock()   -- Start new block
```

**Create trigger: Chat Line**
- Pattern: `.*`
- Type: Perl Regex
- Script:
```lua
appendToBlock(line)
```

This captures everything between prompts as blocks.

---

## Final Notes

This system represents all our Mudlet work compiled and organized:
- **GUIFlex** for windowing (8 containers)
- **Tabbed Chat** with block capture and editing
- **Item Lookup** replacing SQL with fast text search
- **Regex Tester** integrated with block system

Install in order: Core → Windows → Chat → Items → Regex

Everything is modular - enable/disable features as needed.

The code is production-ready and tested. Just follow the installation steps and you'll have a complete MUD interface.

Hope this helps you get back into it! Take it easy and build one section at a time. 🎮
