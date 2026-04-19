--Triggers:
--new trigger group "Shop" -- disable
--regex: ^\s*(\d+)\)\s+(.+?)\s{2,}for\s+(.+)\.\s*$
-- perl regex
--lua code
--ShopLib.captureItem(matches[2], matches[3], matches[4])

--new trigger group "Shop_End" -- disable
--regex: ^$
-- perl regex
--lua code
--ShopLib.captureEnd()

-- ============================================================
-- ShopLib.lua  —  Shop data store for TorilMUD
-- Uses table.save / table.load for persistence (no SQLite)
-- ============================================================

ShopLib              = ShopLib  or {}
shopdata             = shopdata  or {}
ShopLib.currentVnum  = nil
ShopLib.listStarted  = false

local SHOPFILE   = getMudletHomeDir() .. "/shopdata.lua"
local EXPORTFILE = getMudletHomeDir() .. "/shopdata_export.txt"

-- ══════════════════════════════════════════════════════════════
-- PERSISTENCE
-- ══════════════════════════════════════════════════════════════

function ShopLib.save()
    table.save(SHOPFILE, shopdata)
    cecho("<grey>[ShopLib] Saved.\n")
end

function ShopLib.load()
    local f = io.open(SHOPFILE, "r")
    if not f then
        cecho("<grey>[ShopLib] No save file found, starting fresh.\n")
        shopdata = {}
        return
    end
    f:close()
    shopdata = {}
    table.load(SHOPFILE, shopdata)
    local count = 0
    for _ in pairs(shopdata) do count = count + 1 end
    cecho(string.format("<grey>[ShopLib] Loaded %d shops.\n", count))
end

-- ══════════════════════════════════════════════════════════════
-- ITEM LOOKUP HELPER
-- Finds the long cache entry for an item matched to a shop area.
-- Falls back to first name match if no area match found.
-- ══════════════════════════════════════════════════════════════

function ShopLib.findItemForShop(itemname, area)
    if not TorilLib.longcache or #TorilLib.longcache == 0 then return nil end
    local lname    = itemname:lower()
    local larea    = area:lower()
    local fallback = nil
    for _, item in ipairs(TorilLib.longcache) do
        if item.name_lower:find(lname, 1, true) then
            if not fallback then fallback = item end
            if item.location:lower():find(larea, 1, true) then
                return item
            end
        end
    end
    return fallback
end

-- ══════════════════════════════════════════════════════════════
-- ADD SHOP
-- ══════════════════════════════════════════════════════════════

function ShopLib.addShop(vnum, keeper, zone, area, notes)
    vnum   = tonumber(vnum)
    keeper = tostring(keeper or "Unknown")
    zone   = tostring(zone   or "Unknown")
    area   = tostring(area   or "Unknown")
    notes  = tostring(notes  or "")
    shopdata[vnum] = {
        vnum   = vnum,
        keeper = keeper,
        zone   = zone,
        area   = area,
        notes  = notes,
        items  = {}
    }
    ShopLib.currentVnum = vnum
    ShopLib.listStarted = false
    enableTrigger("Shop")
    enableTrigger("Shop_End")
    tempTimer(0.5, function() send("list " .. keeper) end)
    cecho(string.format("<green>[ShopLib] Shop %d (%s) in %s — capturing list...\n", vnum, keeper, area))
end

-- ══════════════════════════════════════════════════════════════
-- TRIGGER CALLBACKS
-- Shop trigger regex:      ^\s*(\d+)\)\s+(.+?)\s{2,}for\s+(.+)\.\s*$
-- Shop trigger script:     ShopLib.captureItem(matches[2], matches[3], matches[4])
-- Shop_End trigger regex:  ^$
-- Shop_End trigger script: ShopLib.captureEnd()
-- ══════════════════════════════════════════════════════════════

function ShopLib.captureItem(listnum, name, price)
    if not ShopLib.currentVnum then
        echo("[ShopLib] captureItem: no currentVnum set\n")
        return
    end
    if not ShopLib.listStarted then
        shopdata[ShopLib.currentVnum].items = {}
        ShopLib.listStarted = true
    end
    local vnum    = ShopLib.currentVnum
    local listnum = tonumber(listnum)
    local name    = tostring(name  or ""):trim()
    local price   = tostring(price or ""):trim()
    local items   = shopdata[vnum].items
    items[#items + 1] = { listnum = listnum, name = name, price = price }
    table.sort(items, function(a, b) return a.listnum < b.listnum end)
    local found = ShopLib.findItemForShop(name, shopdata[vnum].area)
    if found then
        cecho("\n")
        longDisplayItem(found, "  ")
    end
end

function ShopLib.captureEnd()
    if not ShopLib.listStarted then return end
    local v = ShopLib.currentVnum
    ShopLib.listStarted = false
    ShopLib.currentVnum = nil
    disableTrigger("Shop")
    disableTrigger("Shop_End")
    ShopLib.save()
    ShopLib.view(v)
end

-- ══════════════════════════════════════════════════════════════
-- MANUAL ITEM ADD / DELETE
-- ══════════════════════════════════════════════════════════════

function ShopLib.addItem(vnum, listnum, name, price)
    vnum    = tonumber(vnum)
    listnum = tonumber(listnum)
    name    = tostring(name  or ""):trim()
    price   = tostring(price or ""):trim()
    if not shopdata[vnum] then
        echo(string.format("[ShopLib] addItem: shop vnum %d not found. Add shop first.\n", vnum))
        return
    end
    local items = shopdata[vnum].items
    for i, item in ipairs(items) do
        if item.listnum == listnum then table.remove(items, i); break end
    end
    items[#items + 1] = { listnum = listnum, name = name, price = price }
    table.sort(items, function(a, b) return a.listnum < b.listnum end)
    ShopLib.save()
    cecho(string.format("<green>[ShopLib] Item %d added to shop %d.\n", listnum, vnum))
end

function ShopLib.deleteShop(vnum)
    vnum = tonumber(vnum)
    if not shopdata[vnum] then
        cecho(string.format("<yellow>[ShopLib] No shop at vnum %d.\n", vnum)); return
    end
    shopdata[vnum] = nil
    ShopLib.save()
    cecho(string.format("<red>[ShopLib] Shop %d deleted.\n", vnum))
end

function ShopLib.deleteItem(vnum, listnum)
    vnum    = tonumber(vnum)
    listnum = tonumber(listnum)
    if not shopdata[vnum] then
        cecho(string.format("<yellow>[ShopLib] No shop at vnum %d.\n", vnum)); return
    end
    local items = shopdata[vnum].items
    for i, item in ipairs(items) do
        if item.listnum == listnum then
            table.remove(items, i)
            ShopLib.save()
            cecho(string.format("<red>[ShopLib] Item %d removed from shop %d.\n", listnum, vnum))
            return
        end
    end
    cecho(string.format("<yellow>[ShopLib] Item %d not found in shop %d.\n", listnum, vnum))
end

-- ══════════════════════════════════════════════════════════════
-- DISPLAY
-- ══════════════════════════════════════════════════════════════

function ShopLib.view(vnum)
    vnum = tonumber(vnum)
    local shop = shopdata[vnum]
    if not shop then
        cecho(string.format("<yellow>[ShopLib] No shop found at vnum %d.\n", vnum)); return
    end
    cecho("<white>────────────────────────────────────────────────────────\n")
    cecho(string.format("<cyan>Vnum   : <white>%d\n",   shop.vnum))
    cecho(string.format("<cyan>Keeper : <white>%s\n",   shop.keeper))
    cecho(string.format("<cyan>Zone   : <white>%s\n",   shop.zone))
    cecho(string.format("<cyan>Area   : <white>%s\n",   shop.area))
    if shop.notes ~= "" then
        cecho(string.format("<cyan>Notes  : <grey>%s\n", shop.notes))
    end
    cecho("<white>────────────────────────────────────────────────────────\n")
    if #shop.items == 0 then
        cecho("<grey>  No items recorded.\n")
    else
        for _, item in ipairs(shop.items) do
            cecho(string.format(
                "<green>%2d) <white>%-42s <yellow>%s\n",
                item.listnum, item.name, item.price))
            local found = ShopLib.findItemForShop(item.name, shop.area)
            if found then longDisplayItem(found, "    ") end
        end
    end
    cecho("<white>────────────────────────────────────────────────────────\n")
    cecho(string.format("<grey>%d item(s)\n", #shop.items))
end

function ShopLib.list()
    local sorted = {}
    for _, shop in pairs(shopdata) do sorted[#sorted + 1] = shop end
    table.sort(sorted, function(a, b)
        if a.area ~= b.area then return a.area < b.area end
        return a.vnum < b.vnum
    end)
    if #sorted == 0 then cecho("<yellow>[ShopLib] No shops recorded.\n"); return end
    cecho("<white>──────────────────────────────────────────────────────────────────────────\n")
    cecho("<cyan>  Vnum   Area                 Zone                 Keeper           Items\n")
    cecho("<white>──────────────────────────────────────────────────────────────────────────\n")
    for _, shop in ipairs(sorted) do
        cecho(string.format(
            "<green>%6d <white>%-20s <grey>%-20s <white>%-20s <yellow>%d\n",
            shop.vnum, shop.area, shop.zone, shop.keeper, #shop.items))
    end
    cecho("<white>──────────────────────────────────────────────────────────────────────────\n")
    cecho(string.format("<grey>Total: %d shops\n", #sorted))
end

function ShopLib.listArea(areaname)
    local larea = areaname:lower()
    local found = {}
    for _, shop in pairs(shopdata) do
        if shop.area:lower():find(larea, 1, true) then
            found[#found + 1] = shop
        end
    end
    table.sort(found, function(a, b) return a.vnum < b.vnum end)
    if #found == 0 then
        cecho(string.format("<yellow>No shops found in area matching '%s'.\n", areaname)); return
    end
    cecho(string.format("<white>── Shops in '<cyan>%s<white>' ────────────────────────────────\n", areaname))
    cecho("<white>──────────────────────────────────────────────────────────────────────────\n")
    for _, shop in ipairs(found) do
        cecho(string.format(
            "<green>%6d <white>%-20s <grey>%-20s <white>%-20s <yellow>%d items\n",
            shop.vnum, shop.keeper, shop.zone, shop.area, #shop.items))
    end
    cecho("<white>──────────────────────────────────────────────────────────────────────────\n")
    cecho(string.format("<grey>%d shop(s)\n", #found))
end

-- ══════════════════════════════════════════════════════════════
-- SEARCH
-- ══════════════════════════════════════════════════════════════

function ShopLib.stat(xsqlstring)
    local terms = xsqlstring:split(",")
    for i = 1, #terms do terms[i] = terms[i]:trim() end
    local results = {}
    for vnum, shop in pairs(shopdata) do
        for _, item in ipairs(shop.items) do
            local haystack = item.name:lower()
            local match = true
            for _, term in ipairs(terms) do
                local negate = term:sub(1,1) == "-"
                if negate then term = term:sub(2) end
                local found = haystack:find(term:lower(), 1, true) ~= nil
                if negate and found         then match = false; break end
                if not negate and not found then match = false; break end
            end
            if match then
                results[#results + 1] = {
                    vnum    = vnum,
                    keeper  = shop.keeper,
                    area    = shop.area,
                    zone    = shop.zone,
                    listnum = item.listnum,
                    name    = item.name,
                    price   = item.price
                }
            end
        end
    end
    return results
end

function ShopLib.buy(searchstring)
    local terms = searchstring:gsub("%s+", ",")
    local results = ShopLib.stat(terms)
    if #results == 0 then
        cecho(string.format("<yellow>Nothing found matching '%s' in any shop.\n", searchstring)); return
    end
    cecho(string.format(
        "<white>── Where to buy '<cyan>%s<white>' ──────────────────────────────────────\n",
        searchstring))
    for _, r in ipairs(results) do
        cecho(string.format("<green>%-44s <yellow>%s\n", r.name, r.price))
        cecho(string.format(
            "<grey>  Keeper: <white>%-25s <grey>Area: <white>%-20s <grey>Vnum: <white>%d  <grey>Buy#: <white>%d\n",
            r.keeper, r.area, r.vnum, r.listnum))
        cecho("<grey>  ·\n")
    end
    cecho(string.format("<grey>%d result(s)\n", #results))
end

function ShopLib.find(searchstring)
    local lsearch = searchstring:lower()
    local results = {}

    -- search long cache for items matching name or stats containing the term
    local longmatches = {}
    if TorilLib.longcache and #TorilLib.longcache > 0 then
        for _, item in ipairs(TorilLib.longcache) do
            if item.name_lower:find(lsearch, 1, true)
            or item.stats_lower:find(lsearch, 1, true) then
                longmatches[item.name_lower] = item
            end
        end
    end

    -- find those items in shopdata, bidirectional partial name match
    for vnum, shop in pairs(shopdata) do
        for _, item in ipairs(shop.items) do
            local lname = item.name:lower()
            local longitem = nil
            for lkey, lval in pairs(longmatches) do
                if lkey:find(lname, 1, true) or lname:find(lkey, 1, true) then
                    longitem = lval
                    break
                end
            end
            if lname:find(lsearch, 1, true) or longitem then
                results[#results + 1] = {
                    vnum    = vnum,
                    keeper  = shop.keeper,
                    area    = shop.area,
                    zone    = shop.zone,
                    listnum = item.listnum,
                    name    = item.name,
                    price   = item.price,
                    long    = longitem or ShopLib.findItemForShop(item.name, shop.area)
                }
            end
        end
    end

    if #results == 0 then
        cecho(string.format("<yellow>Nothing found matching '%s'.\n", searchstring)); return
    end
    cecho(string.format(
        "<white>── Find '<cyan>%s<white>' ──────────────────────────────────────\n",
        searchstring))
    for _, r in ipairs(results) do
        cecho(string.format("<green>%2d) <white>%-42s <yellow>%s\n",
            r.listnum, r.name, r.price))
        cecho(string.format(
            "<grey>    Keeper: <white>%-25s <grey>Area: <white>%-20s <grey>Vnum: <white>%d\n",
            r.keeper, r.area, r.vnum))
        if r.long then longDisplayItem(r.long, "    ") end
        cecho("<grey>    ·\n")
    end
    cecho(string.format("<grey>%d result(s)\n", #results))
end

-- ══════════════════════════════════════════════════════════════
-- EXPORT / IMPORT
-- ══════════════════════════════════════════════════════════════

function ShopLib.export()
    local f = io.open(EXPORTFILE, "w")
    if not f then
        cecho("<red>[ShopLib] Export failed: cannot open " .. EXPORTFILE .. "\n"); return
    end
    local shopcount, itemcount = 0, 0
    local sorted = {}
    for _, shop in pairs(shopdata) do sorted[#sorted + 1] = shop end
    table.sort(sorted, function(a, b) return a.vnum < b.vnum end)
    for _, shop in ipairs(sorted) do
        f:write(string.format("SHOP|%d|%s|%s|%s|%s\n",
            shop.vnum,
            tostring(shop.keeper or ""):gsub("|", "/"),
            tostring(shop.zone   or ""):gsub("|", "/"),
            tostring(shop.area   or ""):gsub("|", "/"),
            tostring(shop.notes  or ""):gsub("|", "/")))
        shopcount = shopcount + 1
        for _, item in ipairs(shop.items) do
            f:write(string.format("ITEM|%d|%d|%s|%s\n",
                shop.vnum,
                item.listnum,
                tostring(item.name  or ""):gsub("|", "/"),
                tostring(item.price or ""):gsub("|", "/")))
            itemcount = itemcount + 1
        end
    end
    f:close()
    cecho(string.format(
        "<green>[ShopLib] Exported %d shops, %d items to:\n<grey>%s\n",
        shopcount, itemcount, EXPORTFILE))
end

function ShopLib.import(filepath)
    filepath = filepath or EXPORTFILE
    local f = io.open(filepath, "r")
    if not f then
        cecho("<red>[ShopLib] Import failed: cannot open " .. filepath .. "\n"); return
    end
    local shopcount, itemcount, errors = 0, 0, 0
    for line in f:lines() do
        line = line:trim()
        if line ~= "" then
            local parts = {}
            for part in line:gmatch("([^|]+)") do parts[#parts + 1] = part end
            local rtype = parts[1]
            if rtype == "SHOP" then
                local vnum = tonumber(parts[2])
                if vnum then
                    shopdata[vnum] = {
                        vnum   = vnum,
                        keeper = tostring(parts[3] or "Unknown"),
                        zone   = tostring(parts[4] or "Unknown"),
                        area   = tostring(parts[5] or "Unknown"),
                        notes  = tostring(parts[6] or ""),
                        items  = shopdata[vnum] and shopdata[vnum].items or {}
                    }
                    shopcount = shopcount + 1
                else
                    errors = errors + 1
                end
            elseif rtype == "ITEM" then
                local vnum    = tonumber(parts[2])
                local listnum = tonumber(parts[3])
                local name    = tostring(parts[4] or "")
                local price   = tostring(parts[5] or "")
                if vnum and listnum and shopdata[vnum] then
                    local items = shopdata[vnum].items
                    for i, item in ipairs(items) do
                        if item.listnum == listnum then table.remove(items, i); break end
                    end
                    items[#items + 1] = { listnum = listnum, name = name, price = price }
                    table.sort(items, function(a, b) return a.listnum < b.listnum end)
                    itemcount = itemcount + 1
                else
                    errors = errors + 1
                end
            end
        end
    end
    f:close()
    ShopLib.save()
    cecho(string.format(
        "<green>[ShopLib] Imported %d shops, %d items. <red>%d error(s).\n",
        shopcount, itemcount, errors))
end

-- ══════════════════════════════════════════════════════════════
-- HELP
-- ══════════════════════════════════════════════════════════════

function ShopLib.help()
    cecho([[
<white>── #shop commands ──────────────────────────────────────────────────
<cyan>#shop list                           <white>all shops
<cyan>#shop list <area>                    <white>shops in area (partial ok)
<cyan>#shop view <vnum>                    <white>full item list with stats for one shop
<cyan>#shop add <keeper>                   <white>add shop at current location (auto vnum)
<cyan>#shop add <vnum> <keeper>|<zone>|<area>  <white>add shop manually
<cyan>#shop item <vnum> <#> <n> | <price>  <white>add item to shop manually
<cyan>#shop del <vnum>                     <white>delete entire shop
<cyan>#shop delitem <vnum> <#>             <white>delete one item
<cyan>#shop stat <term,term,-term>         <white>raw item search no stats
<cyan>#shop buy <words>                    <white>quick price and location lookup
<cyan>#shop find <words>                   <white>find item with full stats across all shops
<cyan>#shop export                         <white>export all shops to text file
<cyan>#shop import                         <white>import shops from text file
<white>────────────────────────────────────────────────────────────────────
<grey>Examples:
  #shop add 1.merchant
  #shop add 2.merchant
  #shop add 838 Gondeth|Store Lobby|Waterdeep
  #shop item 838 1 A scroll of faerie mischief | 3 platinum
  #shop find bark scroll
  #shop buy potion of sight
  #shop stat scroll,-dark
  #shop list Waterdeep
  #shop view 838
]])
end

-- ══════════════════════════════════════════════════════════════
-- COMMAND DISPATCHER
-- Alias regex:  ^#shop\s*(.*)$
-- Alias script: ShopLib.cmd(matches[2])
-- ══════════════════════════════════════════════════════════════

function ShopLib.cmd(argstring)
    argstring = (argstring or ""):trim()
    if argstring == "" then ShopLib.help(); return end

    local cmd, rest = argstring:match("^(%S+)%s*(.*)")
    cmd  = (cmd  or ""):lower()
    rest = (rest or ""):trim()

    if cmd == "list" then
        if rest == "" then ShopLib.list()
        else ShopLib.listArea(rest) end

    elseif cmd == "view" then
        local vnum = rest:match("^(%d+)")
        if not vnum then cecho("<yellow>Usage: #shop view <vnum>\n"); return end
        ShopLib.view(vnum)

    elseif cmd == "add" then
        if rest == "" then
            cecho("<yellow>Usage: #shop add <keeper>  or  #shop add <vnum> <keeper>|<zone>|<area>\n"); return
        end
        local vnum, params = rest:match("^(%d+)%s+(.+)")
        if vnum and not rest:match("^%d+%.") then
            local parts = params:split("|")
            ShopLib.addShop(
                vnum,
                (parts[1] or "Unknown"):trim(),
                (parts[2] or "Unknown"):trim(),
                (parts[3] or "Unknown"):trim())
        else
            local keeper = rest:trim()
            local function tryAdd()
                local av = map:getRoom()
                local az = map:getCurrentZone() or "Unknown"
                local ar = map:getRoomname()    or "Unknown"
                if av then
                    ShopLib.addShop(tonumber(av), keeper, tostring(ar), tostring(az))
                    return true
                end
                return false
            end
            if not tryAdd() then
                cecho("<yellow>[ShopLib] No vnum — trying scan...\n")
                send("scan")
                tempTimer(1, function()
                    if not tryAdd() then
                        cecho("<yellow>[ShopLib] Still no vnum — trying @find...\n")
                        expandAlias("@find")
                        tempTimer(1, function()
                            if not tryAdd() then
                                cecho("<red>[ShopLib] Cannot determine vnum. Get your map in sync first.\n")
                                cecho("<grey>Try walking to a known room or using the mapper to locate yourself.\n")
                            end
                        end)
                    end
                end)
            end
        end

    elseif cmd == "item" then
        local vnum, listnum, nameAndPrice = rest:match("^(%d+)%s+(%d+)%s+(.*)")
        if not vnum then
            cecho("<yellow>Usage: #shop item <vnum> <listnum> <n> | <price>\n"); return
        end
        local name, price = nameAndPrice:match("^(.-)%s*|%s*(.+)$")
        if not name then
            cecho("<yellow>Separate name and price with |  e.g.: A scroll of fire | 3 platinum\n"); return
        end
        ShopLib.addItem(vnum, listnum, name:trim(), price:trim())

    elseif cmd == "del" then
        local vnum = rest:match("^(%d+)")
        if not vnum then cecho("<yellow>Usage: #shop del <vnum>\n"); return end
        ShopLib.deleteShop(vnum)

    elseif cmd == "delitem" then
        local vnum, listnum = rest:match("^(%d+)%s+(%d+)")
        if not vnum then cecho("<yellow>Usage: #shop delitem <vnum> <listnum>\n"); return end
        ShopLib.deleteItem(vnum, listnum)

    elseif cmd == "stat" then
        if rest == "" then cecho("<yellow>Usage: #shop stat <search,terms>\n"); return end
        local results = ShopLib.stat(rest)
        if #results == 0 then
            cecho("<yellow>No items found matching: " .. rest .. "\n"); return
        end
        cecho("<white>──────────────────────────────────────────────────────────────────\n")
        cecho("<cyan>  Vnum   Area                 #  Item                          Price\n")
        cecho("<white>──────────────────────────────────────────────────────────────────\n")
        for _, r in ipairs(results) do
            cecho(string.format(
                "<green>%6d <white>%-20s <yellow>%2d <white>%-30s <orange>%s\n",
                r.vnum, r.area, r.listnum, r.name, r.price))
        end
        cecho(string.format("<grey>%d result(s)\n", #results))

    elseif cmd == "buy" then
        if rest == "" then cecho("<yellow>Usage: #shop buy <item name words>\n"); return end
        ShopLib.buy(rest)

    elseif cmd == "find" then
        if rest == "" then cecho("<yellow>Usage: #shop find <item name words>\n"); return end
        ShopLib.find(rest)

    elseif cmd == "export" then
        ShopLib.export()

    elseif cmd == "import" then
        ShopLib.import(rest ~= "" and rest or nil)

    elseif cmd == "help" then
        ShopLib.help()

    else
        ShopLib.help()
    end
end

-- ══════════════════════════════════════════════════════════════
-- AUTO-LOAD
-- ══════════════════════════════════════════════════════════════

ShopLib.load()
