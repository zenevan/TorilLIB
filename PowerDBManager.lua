--[[
==================================================================
PowerDBManager Script v2.1 (Simplified & More Reliable)
==================================================================
--]]

-- Initialize our Character Database
if not chDB then
  chDB = {
    powers = {},
    ui = {}
  }
end

------------------------------------------------------------------
-- SECTION 1: DATA CAPTURE & PARSING
------------------------------------------------------------------

function parsePowerHelp(text)
  local alias = text:match("Name%s+:%s+.-%s+%[(%w+)%]")
  local rechargeLine = text:match("Recharge%s+:%s+(.+)")

  if not alias then
    cecho("<red>DB PARSE ERROR: Could not find alias in help text.\n")
    return
  end

  local rechargeSeconds = 10 -- Default cooldown
  if rechargeLine then
    local num, unit = rechargeLine:match("(%d+)%s+(%w+)")
    if num and unit then
      num = tonumber(num)
      if unit:match("minute") then
        rechargeSeconds = num * 60
      elseif unit:match("second") then
        rechargeSeconds = num
      end
    end
  end

  chDB.powers[alias] = {
    name = text:match("Name%s+:%s+(.-)%s+%["),
    recharge = rechargeSeconds,
    isReady = true
  }
  cecho(string.format("<gold>DB: Saved '%s' with a %d sec cooldown.\n", alias, rechargeSeconds))
end

function fetchAllPowerDetails(powerListText)
  -- Clear old data to start fresh
  chDB.powers = {}

  local aliasesToFetch = {}
  for alias in powerListText:gmatch("%[%s*(%w+)%s*%]") do
    table.insert(aliasesToFetch, alias)
  end

  if #aliasesToFetch == 0 then
    cecho("<red>ERROR: No power aliases found in the list. The gmatch loop failed.\n")
    return
  end

  cecho("<green>Found " .. #aliasesToFetch .. " powers. Fetching details...\n")

  -- This new function will create a reliable chain of commands
  local function fetchNext(currentIndex)
    -- This is our stop condition. If we're past the end of the list, we're done.
    if currentIndex > #aliasesToFetch then
      cecho("<green>All power details fetched. Building UI!\n")
      setupPowerButtons()
      return -- This ends the chain
    end

    -- Get the current alias and send the command
    local alias = aliasesToFetch[currentIndex]
    send("powers help " .. alias)

    -- Create a NEW, single-shot timer that will call this function
    -- again for the NEXT item in the list after a short delay.
    -- This is more reliable than a single repeating timer.
    tempTimer(1.1, function()
      fetchNext(currentIndex + 1)
    end)
  end

  -- Start the chain reaction by fetching the very first item (index 1)
  fetchNext(1)
end

------------------------------------------------------------------
-- SECTION 2: UI CREATION
------------------------------------------------------------------
-- This table will hold our UI container
if not ui then ui = {} end

function setupPowerButtons(powerListText)
  -- <<< CHANGE 1: The cleanup is now much simpler.
  -- If our button container already exists from a previous run, delete it and all its contents.
  if ui.powersContainer then
    ui.powersContainer:delete()
  end

  -- <<< CHANGE 2: Create a new VBox to automatically stack our buttons.
  -- This VBox is placed inside your GUI.Box2.
  ui.powersContainer = Geyser.VBox:new({
    name = "powersContainer", -- Give it a name for the cleanup code above
  }, GUI.Box2)

  -- Trim the incoming text block
  local plist = string.trim(powerListText)

  -- Loop through each line of the captured text
  for line in string.gmatch(plist, "[^\r\n]+") do
    -- Use a pattern to capture the Power Name and its Alias
    local powerName, alias = line:match([[^\s*([A-Za-z\s]+?)\s+\[\s*(\w+)\s*\]])

    if powerName and alias then
      powers[powerName] = {
        alias = alias,
        isReady = true
      }

      -- <<< CHANGE 3: Add the button to our new VBox, not directly to GUI.Box2.
      local button = Geyser.Label:new({
        name = "btn_" .. alias,
        message = powerName
      }, ui.powersContainer) -- The VBox is now the parent

      -- The rest of your code for styling and cooldowns is perfect and needs no changes.
      button:setStyleSheet([[
        background-color: rgb(30, 80, 30);
        color: white;
        border-style: outset;
        border-width: 2px;
        border-radius: 5px;
        border-color: beige;
        padding: 5px;
        margin-bottom: 2px;
      ]])

      button:setOnRelease(function()
        if powers[powerName].isReady then
          send(powers[powerName].alias)
          powers[powerName].isReady = false
          local countdown = 10

          button:setStyleSheet([[
            background-color: rgb(100, 20, 20);
            color: grey;
            border-style: inset;
            border-width: 2px;
            border-radius: 5px;
            border-color: black;
            padding: 5px;
            margin-bottom: 2px;
          ]])

          tempTimer(0, function()
            if countdown > 0 then
              button:setText(powerName .. " (" .. countdown .. "s)")
              countdown = countdown - 1
              return true
            else
              powers[powerName].isReady = true
              button:setText(powerName)
              button:setStyleSheet([[
                background-color: rgb(30, 80, 30);
                color: white;
                border-style: outset;
                border-width: 2px;
                border-radius: 5px;
                border-color: beige;
                padding: 5px;
                margin-bottom: 2px;
              ]])
              return false
            end
          end)
        end
      end)
    end
  end
end