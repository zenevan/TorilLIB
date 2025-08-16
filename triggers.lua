

Triggers:
^(.*)$

-- This script goes in your 'catch_rescue_calls' trigger

-- Make sure your database is loaded
if not myDB then
  myDB = DBManager:new(loadDBFromFile("player_database.lua"))
end

-- Get the full line that this trigger captured
local line = matches[2]

-- Get your list of rescue phrases from the database
local rescue_phrases = myDB:get("triggers.rescue_phrases")

-- If the list doesn't exist, stop here to prevent errors
if not rescue_phrases then return end

-- Loop through each phrase in your database list
for _, phrase_pattern in ipairs(rescue_phrases) do
  -- Use string.match() to see if the current line matches the pattern
  local victim = line:match(phrase_pattern)

  -- If a match is found...
  if victim then
    -- 'victim' will contain the part of the string captured by %w+
    -- For "Arlith needs help!", victim would be "Arlith"
    cecho(string.format("<red>MATCH FOUND! Victim: %s. Rescuing now...\n", victim))
    send("rescue " .. victim)

    -- Stop checking, since we already found a match and took action
    break
  end
end





-- This would be in a script you run once, or in an alias like 'addrescue <phrase>'

-- Initialize your database if it doesn't exist
if not myDB then
  myDB = DBManager:new(loadDBFromFile("player_database.lua"))
end

-- Set up the table to hold your rescue trigger phrases
myDB:set("triggers.rescue_phrases", {
  "%w+ needs help!",
  "Someone shouts for help!",
  "You hear a cry for help from the %w+."
})

-- Save the database so the data persists
myDB:save("player_database.lua")

-- You can view your new data with an alias
-- inspect(myDB:get("triggers"), "My Triggers")