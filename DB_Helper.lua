--[[
==================================================================
  Lua Helper Library for MUD Scripting
  A collection of common utility functions to make scripting easier.
==================================================================
--]]


------------------------------------------------------------------
-- EXAMPLE USAGE
------------------------------------------------------------------

-- Example: Using the new Database Manager
-- function manageMyData()
--   -- Create a new database instance
--   local myDB = DBManager:new()
--
--   -- Set some data for a character
--   myDB:set("accounts.Vadi.characters.MyWarrior.gold", 5000)
--   myDB:set("accounts.Vadi.characters.MyWarrior.equipment.mainHand", "Broadsword")
--
--   -- Save the database
--   myDB:save("player_database.lua")
--
--   -- Later, you can load it
--   local loadedDB = DBManager:new(loadDBFromFile("player_database.lua"))
--   local gold = loadedDB:get("accounts.Vadi.characters.MyWarrior.gold")
--   cecho("My warrior has " .. gold .. " gold.\n")
-- end

-- Example: Using the new Web Browser
-- function setupBrowser()
--   -- Create a browser in GUI.Box7
--   createWebBrowser({
--     parent = GUI.Box7,
--     name = "forumBrowser",
--     home = "http://forums.torilmud.org/" -- Set the home page
--   })
-- end


------------------------------------------------------------------
-- SECTION 1: ADVANCED FILE HANDLING & SERIALIZATION
-- A more robust system for saving and loading complex, nested tables.
-- This replaces the simple file handlers with a system that can
-- handle the kind of nested data a real database requires.
------------------------------------------------------------------

-- A mini-library inspired by Serpent, for safely serializing complex Lua tables.
local Serpent = {
  indent = "  ",
  level = 0
}

function Serpent.dump(tbl)
  Serpent.level = 0
  local success, result = pcall(Serpent._dump, tbl)
  if success then return result else return nil end
end

function Serpent._dump(tbl)
  local tblType = type(tbl)
  if tblType ~= "table" then
    if tblType == "string" then return string.format("%q", tbl) end
    return tostring(tbl)
  end

  Serpent.level = Serpent.level + 1
  local parts = {}
  local indent = string.rep(Serpent.indent, Serpent.level)
  local isList = #tbl > 0 and not next(tbl, #tbl)

  if isList then
    for i = 1, #tbl do
      table.insert(parts, indent .. Serpent._dump(tbl[i]))
    end
  else
    for k, v in pairs(tbl) do
      local key = type(k) == "string" and string.format("[%q]", k) or string.format("[%s]", Serpent._dump(k))
      table.insert(parts, indent .. key .. " = " .. Serpent._dump(v))
    end
  end

  Serpent.level = Serpent.level - 1
  local outerIndent = string.rep(Serpent.indent, Serpent.level)
  return "{\n" .. table.concat(parts, ",\n") .. "\n" .. outerIndent .. "}"
end

--- Saves a complex table to a file using the robust Serpent serializer.
-- @param tbl The table to save.
-- @param filename The name of the file (e.g., "player_database.lua").
function saveDBToFile(tbl, filename)
  if not tbl or not filename then return false end
  local path = getMudletHomeDir() .. "/" .. filename
  local file, err = io.open(path, "w")
  if not file then
    cecho(string.format("<red>Error saving file: %s\n", err))
    return false
  end

  local dataString = Serpent.dump(tbl)
  if dataString then
    file:write("return " .. dataString)
    file:close()
    cecho(string.format("<green>Successfully saved database to %s\n", filename))
    return true
  else
    cecho(string.format("<red>Error: Could not serialize database table.\n"))
    file:close()
    return false
  end
end

--- Loads a database file that was saved with saveDBToFile.
-- @param filename The name of the file to load.
-- @return The loaded table, or nil if an error occurred.
function loadDBFromFile(filename)
  if not filename then return nil end
  local path = getMudletHomeDir() .. "/" .. filename
  local success, data = pcall(dofile, path)
  if success and type(data) == "table" then
    cecho(string.format("<green>Successfully loaded database from %s\n", filename))
    return data
  else
    cecho(string.format("<yellow>Notice: Could not load file '%s'. It may not exist yet.\n", filename))
    return nil
  end
end


------------------------------------------------------------------
-- SECTION 2: STRING UTILITIES
------------------------------------------------------------------

--- Splits a string into a table of substrings based on a separator.
function splitString(str, sep)
  if not str then return {} end
  sep = sep or " "
  local parts = {}
  for part in string.gmatch(str, "([^" .. sep .. "]+)") do
    table.insert(parts, part)
  end
  return parts
end

--- Checks if a string contains a specific word (case-insensitive).
function containsWord(str, word)
  if not str or not word then return false end
  return str:lower():find("%f[%w]" .. word:lower() .. "%f[^%w]")
end


------------------------------------------------------------------
-- SECTION 3: DEBUGGING
------------------------------------------------------------------

--- A powerful function to print the contents of any table in a readable format.
function inspect(tbl, name)
  name = name or "Table"
  cecho(string.format("\n<yellow>--[ Inspecting: %s ]---------------------------\n", name))
  if not tbl or type(tbl) ~= "table" then
    cecho("<red>  Not a valid table.\n")
    return
  end
  cecho(Serpent.dump(tbl)) -- Use the powerful serializer to print the table
  cecho("<yellow>----------------------------------------------------\n")
end

------------------------------------------------------------------
-- SECTION 4: GUI MANAGEMENT
------------------------------------------------------------------

--- Clears all child elements from a given Geyser container.
function clearContainer(container)
  if not container or not container.getChildren then return end
  local children = container:getChildren()
  for _, child in ipairs(children) do
    child:delete()
  end
end

--- Creates a clickable button with extensive options and adds it to a container.
function addButton(options)
  options = options or {}
  if not options.parent or not options.name then
    cecho("<red>GUI Error: addButton requires 'parent' and 'name' in options table.\n")
    return
  end
  local button = Geyser.Label:new({
    name = options.name,
    message = options.text or "",
    width = options.width or 0,
    height = options.height or 0
  }, options.parent)
  if options.style and type(options.style) == "table" then
    local css = ""
    for prop, value in pairs(options.style) do
      css = css .. string.format("%s: %s;\n", prop, value)
    end
    button:setStyleSheet(css)
  end
  if options.onClick and type(options.onClick) == "function" then
    button:setOnRelease(options.onClick)
  end
  return button
end

--- Moves the Mudlet map to a specified container.
function setMap(container)
  if not container then return end
  if gmcp.Mapper and gmcp.Mapper.container then
    gmcp.Mapper.container:reparent(container)
    gmcp.Mapper.container:show()
  else
    cecho("<yellow>Map object not available. Is mapping enabled?\n")
  end
end

------------------------------------------------------------------
-- SECTION 5: DATABASE MANAGEMENT (NEW)
------------------------------------------------------------------

DBManager = { _db = {} }
DBManager.__index = DBManager

--- Creates a new database manager instance.
function DBManager:new(initialData)
  local obj = { _db = initialData or {} }
  setmetatable(obj, DBManager)
  return obj
end

--- Retrieves a value from the database using a dot-separated path.
-- @param path (string) e.g., "accounts.myaccount.characters.main.inventory"
function DBManager:get(path)
  local current = self._db
  for key in string.gmatch(path, "[^.]+") do
    if type(current) ~= "table" or not current[key] then return nil end
    current = current[key]
  end
  return current
end

--- Sets a value in the database using a dot-separated path.
-- Creates nested tables as needed.
-- @param path (string) e.g., "accounts.myaccount.characters.main.gold"
-- @param value The value to set.
function DBManager:set(path, value)
  local current = self._db
  local keys = splitString(path, ".")
  for i = 1, #keys - 1 do
    local key = keys[i]
    if not current[key] or type(current[key]) ~= "table" then
      current[key] = {}
    end
    current = current[key]
  end
  current[keys[#keys]] = value
end

--- Imports data from another file, mapping old keys to new paths.
-- @param sourceFilename The file to import data from.
-- @param mapping A table describing how to map the data, e.g., { old_key = "new.path.in.db" }
function DBManager:import(sourceFilename, mapping)
  local sourceData = loadDBFromFile(sourceFilename)
  if not sourceData then
    cecho(string.format("<red>DB Import Error: Could not load source file '%s'.\n", sourceFilename))
    return
  end
  for oldKey, newPath in pairs(mapping) do
    if sourceData[oldKey] then
      self:set(newPath, sourceData[oldKey])
      cecho(string.format("<cyan>  Imported '%s' -> '%s'\n", oldKey, newPath))
    end
  end
end

--- Saves the entire database to a file.
function DBManager:save(filename)
  return saveDBToFile(self._db, filename)
end

------------------------------------------------------------------
-- SECTION 6: WEB BROWSER (NEW & UPDATED)
------------------------------------------------------------------

--- Creates a simple web browser inside a Geyser container.
-- NOTE: This is NOT a real browser. It cannot handle JS or complex CSS.
-- It is only suitable for simple, text-based forums and websites.
-- @param options A table of parameters:
--   - parent (Geyser obj): The container to create the browser in. REQUIRED.
--   - name (string): A unique name for the browser. REQUIRED.
--   - home (string): The default URL to load.
function createWebBrowser(options)
  options = options or {}
  if not options.parent or not options.name then
    cecho("<red>GUI Error: createWebBrowser requires 'parent' and 'name'.\n")
    return
  end

  local container = Geyser.VBox:new({ name = options.name .. "_container" }, options.parent)
  local navBar = Geyser.HBox:new({ name = options.name .. "_navBar", height = 30 }, container)
  local display = Geyser.Label:new({ name = options.name .. "_display" }, container)
  display:setStyleSheet("padding: 5px; border-top: 2px solid grey;")

  local addressBar = Geyser.LineEdit:new({ name = options.name .. "_addressBar" }, navBar)
  local goButton = Geyser.Button:new({ name = options.name .. "_goButton", width = 40, message = "Go" }, navBar)
  -- New button to open the link in the system's default browser
  local externalButton = Geyser.Button:new({ name = options.name .. "_externalButton", width = 100, message = "Open Externally" }, navBar)

  -- This function handles internal navigation
  local function navigate(url)
    addressBar:setText(url)
    display:echo("<i>Loading " .. url .. "...</i>")
    -- getHTTP is an asynchronous function. We provide a callback function
    -- that will run once the web request is complete.
    getHTTP(url, function(success, responseBody)
      if success then
        display:echo(responseBody)
      else
        display:echo("<p style='color:red;'>Failed to load page.</p>")
      end
    end)
  end

  -- Wire up the buttons
  goButton:setOnRelease(function() navigate(addressBar:getText()) end)
  addressBar:setOnEnter(function() navigate(addressBar:getText()) end)
  -- Wire up the new external button using Mudlet's openURL function
  externalButton:setOnRelease(function() openURL(addressBar:getText()) end)

  if options.home then navigate(options.home) end
end
