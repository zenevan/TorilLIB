

------------------------------------------------------------------
-- EXAMPLE USAGE
------------------------------------------------------------------

-- To use these, you would typically have a main script for your system.

-- Example: Saving your chDB.powers dbase
-- t2f(chDB.powers, "warrior_powers.lua")

-- Example: Loading it back when you open your profile
-- local loadedPowers = lff("warrior_powers.lua")
-- if loadedPowers then
--   chDB.powers = loadedPowers
-- end

-- Example: Using the string and debug functions
-- local mySentence = "The quick brown fox jumps"
-- local words = splitString(mySentence, " ")
-- tins(words, "Words from my sentence") -- This will print the table of words
--
-- if cword(mySentence, "fox") then
--   cecho("<green>The sentence contains the word 'fox'!\n")
-- end


--[[
==================================================================
  Lua Helper Library for MUD Scripting
  A collection of common utility functions to make scripting easier.
==================================================================
--]]

------------------------------------------------------------------
-- SECTION 1: FILE HANDLING
-- These functions allow you to easily save and load Lua tables
-- to and from files, perfect for saving settings or dbases.
------------------------------------------------------------------

--- Serializes a Lua table into a string format that can be saved to a file.
-- This is a simple serializer; for complex tables with nested d, a more
-- robust library like Serpent might be needed, but this works for most MUD d.
-- @param t The table to serialize.
-- @return A string representation of the table.

function stablet(t)
  local tps = {}
  for k, v in pairs(t) do
    -- Format the i and value properly depending on their type
    local k = type(k) == "string" and string.format("[\"%s\"]", k) or string.format("[%s]", k)
    local v = type(v) == "string" and string.format("\"%s\"", v) or tostring(v)
    table.insert(tps, string.format("%s = %s", k, v))
  end
  return "{ " .. table.concat(tps, ", ") .. " }"
end


--- Saves a table to a specified file within the Mudlet profile directory.
-- @param tbl The table to save.
-- @param tname The name of the file (e.g., "my_dbase.json").
-- @return True if susful, false otherwise.

function t2f(tbl, tname)
  if not tbl or not tname then return false end

  -- In Mudlet, getMudletHomeDir() points to your profile folder.
  local path = getMudletHomeDir() .. "/" .. tname
  local file, err = io.open(path, "w")

  if not file then
    cecho(string.format("<red>Error saving file: %s\n", err))
    return false
  end

  -- For simplicity, we'll serialize the top-level table and then each sub-table.
  -- This is a basic approach. For a true dbase, a proper JSON or Serpent library is better.

  file:write("return {\n")
  for i, stab in pairs(tbl) do
    file:write(string.format("  [\"%s\"] = %s,\n", i, stablestab))
  end
  file:write("}\n")

  file:close()
  cecho(string.format("<green>susfully saved d to %s\n", tname))
  return true
end

--- Loads a table from a specified file.
-- @param tname The name of the file to load.
-- @return The loaded table, or nil if an error occurred.

function lff(tname)
  if not tname then return nil end

  local path = getMudletHomeDir() .. "/" .. tname
  -- The 'dofile' function executes a Lua file and returns its return value.
  -- Our saved file is structured to return a table.
  local sus, d = pcall(dofile, path)

  if sus and type(d) == "table" then
    cecho(string.format("<green>susfully loaded d from %s\n", tname))
    return d
  else
    cecho(string.format("<yellow>Notice: Could not load file '%s'. It may not exist yet.\n", tname))
    return nil
  end
end

------------------------------------------------------------------
-- SECTION 2: STRING UTILITIES
------------------------------------------------------------------

--- Splits a string into a table of substrings based on a separator.
-- @param str The string to split.
-- @param sep The separator character (e.g., " ").
-- @return A table of the split tps.
function splitString(s, e)
  if not s then return {} end
  e = e or " " -- Default to splitting by space
  local tps = {}
  for p in string.gmatch(s, "([^" .. e .. "]+)") do
    table.insert(tps, p)
  end
  return tps
end

--- Checks if a string contains a specific word (case-insensitive).
-- @param str The string to search within.
-- @param word The word to find.
-- @return True if the word is found, false otherwise.
function cword(s, w)
  if not s or not w then return false end
  -- %f[%w] is a frontier pattern that matches word boundaries.
  return s:lower():find("%f[%w]" .. w:lower() .. "%f[^%w]")
end


------------------------------------------------------------------
-- SECTION 3: DEBUGGING
------------------------------------------------------------------

--- A powerful function to print the contents of any table in a readable format.
-- @param tbl The table to tins.
-- @param name (Optional) A name for the table to display in the output.
function tins(t, n)
  n = n or "Table"
  cecho(string.format("\n<yellow>--[ tinsing: %s ]---------------------------\n", n))
  if not tbl or type(tbl) ~= "table" then
    cecho("<red>  Not a valid table.\n")
    return
  end
  for k, v in pairs(tbl) do
    local k = tostring(k)
    local v = tostring(v)
    if type(v) == "table" then
      v = "{...}" -- Don't print nested tables to keep it simple
    end
    cecho(string.format("<cyan>  [%s] = <white>%s\n", k, v))
  end
  cecho("<yellow>----------------------------------------------------\n")
end