--Proposal of new structure.

--### Capture groups
--
--| `matches[N]` | Content         | Example         |
--|:---:|:----------------|:----------------|
--| `matches[1]` | Full line match | *(whole line)*  | Throw away for debug, send to function for parse maybe
--| `matches[2]` | Position number | `102`           | Current Position
--| `matches[3]` | Character name  | `Krainor`       | What is character name?
--| `matches[4]` | Level           | `17`            | What level is it?
--| `matches[5]` | Class           | `Paladin`       | What class is it?
--| `matches[6]` | Race            | `Human`         | What race is it?
--|              | Date            | 12/12/2012      | last day we played this character
--|              | Time            | 12:30:20        | last time we were on this character
--|              | Gear            | true|false      | did i stow gear in main storage
--|              | Room            | 34567           | last known room number
--|              | Zone            | Waterdeep       | last known zone
--|              | Hometown        | Waterdeep       | Hometown of Character

Claude Generated MD:
Prompt Used:
help me write a lua script in mudlet with these exact instructions, each class has a position number, loop through this list, capture all the data in an overall variable called accdata, i want to assign all variables at the top of a script thagt receives all data from this one regex trigger, and just write a library in lua that parses this stuff, and  the regex to make it all work in an md file all the code in this md file Accoun.md heres the sample 
)
 95) Atesa                     Level 17 Necromancer (Drow Elf)
 96) Zic                       Level 19 Warrior (Barbarian)
 97) Eyata                     Level 12 Warrior (Drow Elf)
 98) Wowidomble                Level  3 Wizard (Gnome)
 99) Mashunonoenmio            Level  1 Elementalist (Moon Elf)
100) Legil                     Level  1 Invoker (Halfling)
101) Onre                      Level  5 Rogue (Human)
102) Krainor                   Level 17 Paladin (Human)
103) Jiwega                    Level 12 Necromancer (Drow Elf)
104) Sewothe                   Level 20 Rogue (Drow Elf)
105) Notoppilile               Level 18 Wizard (Gnome)
106) Popoppanele               Level  1 Rogue (Gnome)
107) Ashisole                  Level  1 Rogue (Moon Elf)
108) Noslile                   Level  1 Rogue (Halfling)
109) Ramiane                   Level  1 Rogue (Moon Elf)
110) Cabmelu                   Level  1 Rogue (Moon Elf)
111) Cetag                     Level  1 Rogue (Shield Dwarf)
112) Tamiwee                   Level  1 Rogue (Drow Elf)
113) Yizas                     Level 13 Warrior (Yuan-Ti)
114) Dacpi                     Level  1 Rogue (Shield Dwarf)

Result:

First error i notice, he tries to send matches within lua script....

fixed code myself


[placeholder]



`# Accoun.md — TorilMUD Account Character List Parser

---

## Regex Trigger

**Trigger type:** Perl Regex  
**Name:** `AccLib_capture_char`  
**Pattern:**

```
^\s*(\d+)\)\s+(\S+)\s+Level\s+(\d+)\s+([\w\s\-]+?)\s+\(([^)]+)\)$
```

### Capture groups

| `matches[N]` | Content         | Example         |
|:---:|:----------------|:----------------|
| `matches[1]` | Full line match | *(whole line)*  |
| `matches[2]` | Position number | `102`           |
| `matches[3]` | Character name  | `Krainor`       |
| `matches[4]` | Level           | `17`            |
| `matches[5]` | Class           | `Paladin`       |
| `matches[6]` | Race            | `Human`         |

---

## Trigger Script

Paste this as the script body of the `AccLib_capture_char` trigger.  
All raw captures are assigned at the top before any logic runs.

```lua
-- ============================================================
-- AccLib_capture_char  —  trigger script
-- Fires once per matching line from the account character list
-- ============================================================

-- ── Raw captures assigned at top ────────────────────────────
local position  = tonumber(matches[2])
local charName  = matches[3]
local charLevel = tonumber(matches[4])
local charClass = (matches[5] or ""):match("^%s*(.-)%s*$")   -- trim whitespace
local charRace  = (matches[6] or ""):match("^%s*(.-)%s*$")   -- trim whitespace

-- ── Accumulate into accdata via library ─────────────────────
AccLib.addEntry(position, charName, charLevel, charClass, charRace)
```

> **Note:** `charClass` and `charRace` are trimmed because the greedy regex can
> occasionally catch a leading/trailing space on multi-word values like
> `Shield Dwarf` or `Moon Elf`.

---

## AccLib — Lua Library

Create a **new Script** in Mudlet named `AccLib` and paste the entire block below.
This script must load **before** the trigger fires (put it higher in the script list,
or in a package init file).

```lua
-- ============================================================
-- AccLib.lua  —  Account character list parser / store
-- ============================================================

AccLib  = AccLib  or {}
accdata = accdata or {}   -- global accumulator: accdata[position] = entry table

-- ──────────────────────────────────────────────────────────────
-- AccLib.reset()
--   Wipe accdata.  Call before sending the account list command
--   so stale characters from a previous query don't linger.
-- ──────────────────────────────────────────────────────────────
function AccLib.reset()
    accdata = {}
    cecho("<grey>[AccLib] accdata cleared.\n")
end

-- ──────────────────────────────────────────────────────────────
-- AccLib.addEntry(position, name, level, class, race)
--   Called by the trigger script for every matched line.
-- ──────────────────────────────────────────────────────────────
function AccLib.addEntry(position, name, level, class, race)
    if not position or not name then return end
    accdata[position] = {
        position = position,
        name     = name,
        level    = level,
        class    = class,
        race     = race,
    }
end

-- ──────────────────────────────────────────────────────────────
-- AccLib.getByPosition(n)  →  entry or nil
-- ──────────────────────────────────────────────────────────────
function AccLib.getByPosition(n)
    return accdata[tonumber(n)]
end

-- ──────────────────────────────────────────────────────────────
-- AccLib.getByName(name)  →  entry or nil   (case-insensitive)
-- ──────────────────────────────────────────────────────────────
function AccLib.getByName(name)
    local lname = name:lower()
    for _, entry in pairs(accdata) do
        if entry.name:lower() == lname then
            return entry
        end
    end
    return nil
end

-- ──────────────────────────────────────────────────────────────
-- AccLib.getByClass(class)  →  list of entries  (case-insensitive)
-- ──────────────────────────────────────────────────────────────
function AccLib.getByClass(class)
    local lclass = class:lower()
    local results = {}
    for _, entry in pairs(accdata) do
        if entry.class:lower() == lclass then
            results[#results + 1] = entry
        end
    end
    table.sort(results, function(a, b) return a.position < b.position end)
    return results
end

-- ──────────────────────────────────────────────────────────────
-- AccLib.getByRace(race)  →  list of entries  (case-insensitive)
-- ──────────────────────────────────────────────────────────────
function AccLib.getByRace(race)
    local lrace = race:lower()
    local results = {}
    for _, entry in pairs(accdata) do
        if entry.race:lower() == lrace then
            results[#results + 1] = entry
        end
    end
    table.sort(results, function(a, b) return a.position < b.position end)
    return results
end

-- ──────────────────────────────────────────────────────────────
-- AccLib.getAll()  →  sorted list of all entries
-- ──────────────────────────────────────────────────────────────
function AccLib.getAll()
    local list = {}
    for _, entry in pairs(accdata) do
        list[#list + 1] = entry
    end
    table.sort(list, function(a, b) return a.position < b.position end)
    return list
end

-- ──────────────────────────────────────────────────────────────
-- AccLib.count()  →  number of characters currently in accdata
-- ──────────────────────────────────────────────────────────────
function AccLib.count()
    local n = 0
    for _ in pairs(accdata) do n = n + 1 end
    return n
end

-- ──────────────────────────────────────────────────────────────
-- AccLib.dump()
--   Pretty-prints all characters to the Mudlet output window,
--   sorted by position number.
-- ──────────────────────────────────────────────────────────────
function AccLib.dump()
    local list = AccLib.getAll()
    if #list == 0 then
        cecho("<yellow>[AccLib] accdata is empty.\n")
        return
    end
    cecho("<white>──────────────────────────────────────────────────────\n")
    cecho("<cyan>  #    Name                 Lv  Class            Race\n")
    cecho("<white>──────────────────────────────────────────────────────\n")
    for _, e in ipairs(list) do
        cecho(string.format(
            "<green>%3d) <white>%-20s <yellow>%2d  <orange>%-16s <sky>(%s)\n",
            e.position, e.name, e.level, e.class, e.race
        ))
    end
    cecho("<white>──────────────────────────────────────────────────────\n")
    cecho(string.format("<grey>Total: %d characters\n", #list))
end
```

---

## Suggested Aliases

```lua
-- Alias: acclist
-- Pattern: ^acclist$
-- Script:
AccLib.dump()

-- Alias: accreset
-- Pattern: ^accreset$
-- Script:
AccLib.reset()

-- Alias: accclass
-- Pattern: ^accclass (.+)$
-- Script:
local results = AccLib.getByClass(matches[2])
if #results == 0 then
    cecho("<yellow>No characters found for class: " .. matches[2] .. "\n")
else
    for _, e in ipairs(results) do
        cecho(string.format("<green>%3d) <white>%-20s Lv<yellow>%2d <orange>%s <sky>(%s)\n",
            e.position, e.name, e.level, e.class, e.race))
    end
end

-- Alias: accrace
-- Pattern: ^accrace (.+)$
-- Script:
local results = AccLib.getByRace(matches[2])
if #results == 0 then
    cecho("<yellow>No characters found for race: " .. matches[2] .. "\n")
else
    for _, e in ipairs(results) do
        cecho(string.format("<green>%3d) <white>%-20s Lv<yellow>%2d <orange>%s <sky>(%s)\n",
            e.position, e.name, e.level, e.class, e.race))
    end
end
```

---

## Setup Checklist

1. **Script `AccLib`** — paste the library block; save.
2. **Trigger `AccLib_capture_char`** — type: `Perl Regex`, paste the pattern, paste the trigger script body.
3. **Aliases** — add the four aliases above as needed.
4. In-game, navigate to your account character list screen.
5. Run `accreset` before each new capture session to clear stale data.
6. After the list scrolls, run `acclist` to verify.

---

## accdata Structure Reference

```lua
accdata = {
    [102] = {
        position = 102,
        name     = "Krainor",
        level    = 17,
        class    = "Paladin",
        race     = "Human",
    },
    [104] = {
        position = 104,
        name     = "Sewothe",
        level    = 20,
        class    = "Rogue",
        race     = "Drow Elf",
    },
    -- ... keyed by position number
}
```

