--[[
==================================================================
PowerDBManager Script v2.0
- Builds a database of character powers, including custom cooldowns.
- Automatically fetches power details from the MUD.
- Creates a dynamic UI in GUI.Box2 with clickable, square buttons
  that disable during their specific cooldown period.
==================================================================
--]]

-- Initialize our Character Database. This will hold all power info.
if not chDB then
  chDB = {
    powers = {}, -- Stores data for each power, indexed by alias (e.g., chDB.powers.cc)
    ui = {}      -- Stores the UI elements (buttons)
  }
end

------------------------------------------------------------------
-- SECTION 1: DATA CAPTURE & PARSING
------------------------------------------------------------------

-- This function is called by a trigger when it captures a power's help file.
-- It parses the text and saves the data to our database.
function parsePowerHelp(text)
  -- Capture the name, alias, and recharge time from the text block
  local name = text:match("Name%s+:%s+(.-)%s+%[")
  local alias = text:match("Name%s+:%s+.-%s+%[(%w+)%]")
  local rechargeLine = text:match("Recharge%s+:%s+(.+)")

  if not (name and alias and rechargeLine) then
    cecho("<red>Error parsing power help file.\n")
    return
  end

  local rechargeSeconds = 10 -- Default cooldown if we can't parse it
  local num, unit = rechargeLine:match("(%d+)%s+(%w+)")
  num = tonumber(num)

  if num and unit then
    if unit:match("minute") then
      rechargeSeconds = num * 60
    elseif unit:match("second") then
      rechargeSeconds = num
    end
  end

  -- Save the extracted data into our database
  chDB.powers[alias] = {
    name = name,
    recharge = rechargeSeconds,
    isReady = true
  }
  cecho(string.format("<gold>DB: Saved '%s' (%s) with a %d sec cooldown.\n", name, alias, rechargeSeconds))
end

-- This function takes the raw text from the 'powers all' command,
-- extracts all the aliases, and then automatically sends the help
-- command for each one to build our database.
function fetchAllPowerDetails(powerListText)
  local aliasesToFetch = {}
  -- Use gmatch to find every alias in the text
  for alias in powerListText:gmatch("%[%s*(%w+)%s*%]") do
    table.insert(aliasesToFetch, alias)
  end

  cecho("<green>Found " .. #aliasesToFetch .. " powers. Fetching details...\n")

  -- Use a temporary timer to send commands one by one,
  -- preventing spam and giving the MUD time to respond.
  local i = 1
  tempTimer(0.5, function()
    if i <= #aliasesToFetch then
      send("powers help " .. aliasesToFetch[i])
      i = i + 1
      return true -- Continue the timer
    else
      -- We've fetched all details. Now, build the UI.
      cecho("<green>All power details fetched. Building UI...\n")
      setupPowerButtons()
      return false -- Stop the timer
    end
  end)
end

------------------------------------------------------------------
-- SECTION 2: UI CREATION
------------------------------------------------------------------

-- This function builds the button UI inside GUI.Box2
function setupPowerButtons()
  -- First, clear any old buttons
  for _, button in pairs(chDB.ui) do
    button:delete()
  end
  chDB.ui = {}

  -- Create a container that will arrange our buttons in a grid
  local grid = Geyser.Grid:new({
    name = "powersGrid",
    parent = GUI.Box2, -- Place this inside your existing GUI.Box2
    gridWidth = 4, -- How many buttons per row (change as you like)
    itemWidth = 50, -- Width of each button
    itemHeight = 50 -- Height of each button (making them square)
  })

  -- Loop through all the powers we have in our database
  for alias, data in pairs(chDB.powers) do
    -- Create the button
    local button = Geyser.Button:new({
      name = "btn_" .. alias,
      message = alias:upper() -- Show the alias on the button
    }, grid) -- Add the button to our grid container

    chDB.ui[alias] = button -- Save a reference to the button

    -- Style for when the button is ready
    local readyStyle = [[
      background-color: rgb(30, 80, 30);
      color: white;
      border: 2px outset beige;
      border-radius: 5px;
      font-size: 14px;
      font-weight: bold;
    ]]

    -- Style for when the button is on cooldown
    local cooldownStyle = [[
      background-color: rgb(100, 20, 20);
      color: grey;
      border: 2px inset black;
      border-radius: 5px;
      font-size: 14px;
      font-weight: bold;
    ]]

    button:setStyleSheet(readyStyle)

    -- This function runs when you click the button
    button:setOnRelease(function()
      if chDB.powers[alias].isReady then
        -- 1. Send the command
        send(alias)

        -- 2. Start the cooldown
        chDB.powers[alias].isReady = false
        local countdown = chDB.powers[alias].recharge
        button:disable() -- Make the button unclickable
        button:setStyleSheet(cooldownStyle)

        -- 3. Create a timer to manage the countdown
        tempTimer(0, function()
          if countdown > 0 then
            button:setText(countdown .. "s")
            countdown = countdown - 1
            return true -- Continue timer
          else
            -- Cooldown finished! Reset the button
            chDB.powers[alias].isReady = true
            button:setText(alias:upper())
            button:setStyleSheet(readyStyle)
            button:enable() -- Make it clickable again
            return false -- Stop timer
          end
        end)
      end
    end)
  end
end