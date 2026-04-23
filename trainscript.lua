-------------------------------------------------
--         Put your Lua functions here.        --
--                                             --
-- Note that you can also use external Scripts --
-------------------------------------------------
-- various functions used with the xp trains

function NextTrainStop()
  local currentroom = map:getRoom()
  local hpPercent = prompt:get("hp") / prompt:get("maxhp")
  local mvPercent = prompt:get("mv") / prompt:get("maxmv")

  callNextTrain=nil

  -- if currently tanking anything, don't move
  if inCombat() then
    cecho("<red>[Still in combat - not leaving room]\n")
    return
  end  

   -- Delay 60 seconds if less then 50% hp or movement
   if hpPercent < .5 or mvPercent < .3 then
    tempTimer(45, [[NextTrainStop()]])
    
    send("gcmd [Train paused 45 seconds: Low movement or hp]")


    return
   end

  -- look has been sent but not received - recall function after 1 second if grouped player fighting
  if type(groupList:whoTanking()) == "table" and not look:get() then
    for k,v in pairs( groupList:whoTanking() ) do
      if groupList:ingroup(k) and v ~= 0 then
        echoDebug("<red>[look sent and not received]\n")
        tempTimer(1, [[NextTrainStop()]])
        return
      end
    end
  end

  if NyyLIB.smtrainposition == nil then
    assert(currentroom, "[Error: room id is nil]")

    if map:getCurrentZone() == "Ashstone" then
      --getPath(currentroom, 87415)
      --mud:send("gcmd [Stopping train and returning to bank (87415)" .. " <." .. compressSpeedwalk() .. ">]")
     -- expandAlias("@fwalk 87415", false)
    else
      --getPath(currentroom, 48603)
      --mud:send("gcmd [Stopping train and returning to inn (48603)" .. " <." .. compressSpeedwalk() .. ">]")
      --expandAlias("@fwalk 48603", false)
    end

    expandAlias("@resettrain", false)
  else
    -- increment train position
    
    NyyLIB.smtrainposition = NyyLIB.smtrainposition + 1

    if NyyLIB.smtrainposition > #NyyLIB.smtrainstops then
      NyyLIB.smtrainposition = 1

      if not silent then
        printStats(3)
      end

      expandAlias("@stats write", false)

      --mud:send("gcmd [Resetting Stats]")
      --resetStats()
    end

    NyyLIB.nextstop = NyyLIB.smtrainstops[NyyLIB.smtrainposition][1]
    enableTrigger("trainstation")

    assert(currentroom, "[Error: room id is nil]")
    if getPath(currentroom, NyyLIB.nextstop) then

      local str = NyyLIB.smtrainstops[NyyLIB.smtrainposition][2]
      local nextmob = string.gsub(" "..str, "%W%l", string.upper):sub(2)
      expandAlias("#wwings")
      if not silent then
        mud:send("gcmd [Moving to: " .. nextmob ..
              " (" .. NyyLIB.smtrainstops[NyyLIB.smtrainposition][1] .. ") " ..
               " <." .. compressSpeedwalk() .. ">]")
      end      
    end
    NyyLIB.traintarget=false
  
    if currentroom ~= NyyLIB.nextstop then
      -- maybe needed? map:countMovement() == 0
      if not fwalkQue then
        fwalkQue=true
        echoDebug("<red>[NextTrainStop() : Queueing fwalk in 3 seconds]\n")
        tempTimer(3, [[expandAlias("@fwalk " .. NyyLIB.nextstop)]])
      else
        echoDebug("<red>fwalk already queued]\n")
      end
    end
  end
end

function StartFight()
  if prompt:get("tank") ~= "" then
    return
  end
  
  -- train was just stopped
  if NyyLIB.smtrainposition == nil then
    return
  end

  local mobtarget = string.split(NyyLIB.smtrainstops[NyyLIB.smtrainposition][2], " ")[1]
  if NyyLIB.traintarget then
    setEnemy(mobtarget)

    spell:setMoving(false)

    raiseEvent("promptEvent")
    
    if groupList:size() == 1 then
      cecho("<cyan>\n[Attacking: " ..  string.title(mobtarget) .. "]\n\n")
    else
      if not silent then
        mud:send("gcmd [Attacking: " ..  string.title(mobtarget) .. "]")
      end
    end
    expandAlias("#rwings")    
    -- rogue, blackguard - apply poison
    if checkMask("venomer") then
      sendPoison()
    end  

    -- rogue: start with assassinate
    if checkMask("rog") then
      if not sendAssassinate(mobtarget) then
        mud:send("bs " .. mobtarget)
      end

      return
    end

    if checkMask("hex") then
      meleePowerUsed=false
        
      if subClass == "Hellborne" then
        useMeleePower("HS " .. mobtarget)
      end
      
      if subClass == "Voidcaller" then
        useMeleePower("SD " .. mobtarget)
      end
      
      -- recall in case power is in cooldown
      tempTimer(2, [[StartFight()]])
      return
    end



    if checkMask("ran") then
      meleePowerUsed=false
        
      if equip:getWeapon() == "Dual" then
        useMeleePower("SS " .. mobtarget)
      end
        
      if equip:getWeapon() == "Bow" then
        useMeleePower("KS " .. mobtarget)
      end
        
      -- recall in case power is in cooldown
      tempTimer(2, [[StartFight()]])
      return
    end

    if checkMask("pal") then
      -- ss is 2h, ds is 1h : TODO: need to check weapon
      if equip:getWeapon() == "TwoHand" then
        useMeleePower("ts " .. mobtarget)
      else
        useMeleePower("rc " .. mobtarget)
      end
        
      -- recall in case power is in cooldown
      tempTimer(2, [[StartFight()]])

      return
    end

    if checkMask("blk") then
      -- ss is 2h, ds is 1h : TODO: need to check weapon
      if equip:getWeapon() == "TwoHand" then
        useMeleePower("ss " .. mobtarget)
      else
        useMeleePower("ds " .. mobtarget)
      end

      -- recall in case power is in cooldown
      tempTimer(2, [[StartFight()]])

      return
    end

    if checkMask("war") then
      if table.contains( { "Ogre", "Barbarian", "Troll" }, whorace() ) then
        useMeleePower("BDS " .. mobtarget) -- bodyslam
      else
        if equip:getWeapon() == "TwoHand" then
          useMeleePower("ss " .. mobtarget) -- spinning sweep
        else
          useMeleePower("sb " .. mobtarget) -- shield block
        end

      end

      -- recall in case power is in cooldown
      tempTimer(2, [[StartFight()]])

      return
    end
    
    mud:send("kill " .. mobtarget)
  else
    -- [Players in room - Moving to next station]
    cecho("\n<red>[Target is damaged or already dead -  Moving to next station]\n")
    NextTrainStop()
  end
end

function bankDeposit()
  mud:send("get coins haversack")
  mud:send("deposit all")

  if groupList:size() > 1 then
    if not silent then
      botWarning()
    end
  end

  local trainTime= trainStartTime or getEpoch()
  
  trainStartTime= getEpoch()

  if trainStartTime - trainTime ~= 0 then
    display( trainStartTime-trainTime)
  end

  display( getTime(true, "ddd hh:mm:ss AP") )
end

-- fightreturn false: send flee
-- fightreturn true: send assist

function fleeMem()
  -- ignore trigger if in fugue
  if map:getRoom() == 93848 then
    return
  end

  if charData:get("memcount") == nil or charData:get("memcount") == 0 and not checkMask("psi") then
    fightreturn=true
    return
  end

  if not NyyLIB.castertrain then
    -- mud:send("status " .. matches[2])
    mud:send("flee")
  end

  fightreturn=true
  NyyLIB.castertrain=true
end

function botWarning()
  mud:send("gsay * [       Welcome to the crazy train!!                       ]")
  mud:send("gsay * [       This is my modifioed nysslib.                      ]")
  mud:send("gsay * [https://github.com/zenevan/SAS/blob/main/trains.txt       ]")
  mud:send("gsay * [       Welcome to the crazy train!!                       ]")
  mud:send("gsay * [       Welcome to the crazy train!!       ]")
  mud:send("gsay * [       Welcome to the crazy train!!       ]")
  mud:send("gsay * [       Welcome to the crazy train!!       ]")
  mud:send("gsay * [       Welcome to the crazy train!!       ]")
  mud:send("gsay * [       Welcome to the crazy train!!       ]")
  mud:send("gsay * [       Welcome to the crazy train!!       ]")
  
end
