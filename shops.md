# ShopLib — TorilMUD Shop Database for Mudlet

A lightweight shop data system for TorilMUD. Stores keeper, location, area, and full item lists with prices. Supports fuzzy search, "where to buy" lookups, and auto-capture from the in-game `list` command.

---

## Requirements

- Mudlet 4.x or higher
- TorilLib installed and loaded
- `ShopLib.lua` loaded as a Script in Mudlet

---

## Installation

### Step 1 — Add the Script

1. Open Mudlet and connect to your profile.
2. Open the **Script Editor** (`Alt+E`).
3. Click **Add Item** (the `+` button).
4. Name it `ShopLib`.
5. Paste the full contents of `ShopLib.lua` into the script body.
6. Click **Save Item**, then **Save Profile**.

> ShopLib must load **after** TorilLib core scripts. Drag it below them in the script list if needed.

---

### Step 2 — Add the Main Alias

1. Open the **Alias Editor** (`Alt+A`).
2. Click **Add Item**.
3. Name it `shop_cmd`.
4. Set the **Pattern** to:
```
^#shop\s*(.*)$
```
5. Set the **Script** to:
```lua
ShopLib.cmd(matches[2])
```
6. Click **Save Item**, then **Save Profile**.

---

### Step 3 — Add the Trigger Groups

You need two trigger groups: `Shop` and `Shop_End`. Both start **disabled**. ShopLib enables them automatically when you run `#shop add`.

#### Trigger Group: Shop

1. Open the **Trigger Editor** (`Alt+T`).
2. Click **Add Group**, name it `Shop`.
3. With the `Shop` group selected, click **Add Item**.
4. Name the trigger `ShopItem`.
5. Set **Type** to `Perl Regex`.
6. Set the **Pattern** to:
```
^\s*(\d+)\)\s+(.+?)\s{2,}for\s+(.+)\.\s*$
```
7. Set the **Script** to:
```lua
ShopLib.captureItem(matches[2], matches[3], matches[4])
```
8. Click **Save Item**.
9. Click on the `Shop` **group** itself and **uncheck the enabled box** to disable the whole group.
10. Click **Save Item**, then **Save Profile**.

#### Trigger Group: Shop_End

1. Still in the Trigger Editor, click **Add Group**, name it `Shop_End`.
2. With the `Shop_End` group selected, click **Add Item**.
3. Name the trigger `ShopEnd`.
4. Set **Type** to `Perl Regex`.
5. Set the **Pattern** to:
```
^$
```
6. Set the **Script** to:
```lua
ShopLib.captureEnd()
```
7. Click **Save Item**.
8. Click on the `Shop_End` **group** itself and **uncheck the enabled box** to disable the whole group.
9. Click **Save Item**, then **Save Profile**.

---

## Usage

### Adding a Shop

Stand next to the shopkeeper in-game, then:

```
#shop add <vnum> <keeper>|<zone>|<area>
```

**Example:**
```
#shop add 838 Gondeth|Store Lobby|Waterdeep
```

- `vnum` — the room number of the shop (visible in the exits line e.g. `[838]`)
- `keeper` — name of the shopkeeper
- `zone` — the room name or local location
- `area` — the broader region or zone name

ShopLib will automatically send `list` to the MUD, capture every item and price, then display the completed shop when done.

---

### Viewing Shops

| Command | Description |
|:---|:---|
| `#shop list` | List all recorded shops |
| `#shop list Waterdeep` | List all shops in an area (partial match) |
| `#shop view 838` | Full item list for one shop by vnum |

---

### Searching

| Command | Description |
|:---|:---|
| `#shop buy bark scroll` | Find where to buy something (spaces = AND) |
| `#shop stat scroll` | Raw search — all items matching a term |
| `#shop stat scroll,-dark` | Comma-separated terms, prefix `-` to negate |

**Examples:**
```
#shop buy bark scroll
#shop stat scroll,-dark
#shop stat potion,heal
```

---

### Manual Item Management

You can add or remove individual items without re-running the full capture.

| Command | Description |
|:---|:---|
| `#shop item 838 1 A scroll of fire \| 3 platinum` | Add one item manually |
| `#shop delitem 838 5` | Remove item #5 from shop 838 |
| `#shop del 838` | Delete entire shop and all its items |

> Note the pipe `|` separator between item name and price.

---

### Help

```
#shop help
```

---

## Data Storage

Shop data is saved to:
```
<MudletHomeDir>/shopdata.lua
```

This file is written automatically after each full capture and after any manual add/delete. It is a plain Lua table file readable by `table.load`.

---

## Trigger Flow Reference

When you run `#shop add`:

1. `ShopLib.addShop()` creates the shop record and sets `ShopLib.currentVnum`
2. Both `Shop` and `Shop_End` trigger groups are enabled
3. `list` is sent to the MUD
4. Each item line fires `ShopLib.captureItem()` which appends to `shopdata[vnum].items`
5. The first blank line after the list fires `ShopLib.captureEnd()` which:
   - Disables both trigger groups
   - Saves to disk
   - Displays the completed shop via `ShopLib.view()`

---

## Troubleshooting

**`captureItem: no currentVnum set`**  
The Shop trigger fired before `ShopLib.currentVnum` was assigned. Make sure the `Shop` group is **disabled by default** and only enabled via `#shop add`. Do not enable the group manually before running the command.

**Items show as 0 in `#shop list` after adding**  
This is normal if you run `#shop list` before the capture completes. Run it again after `ShopLib.view()` has printed the completed shop.

**Shop_End trigger fires too early**  
The `^$` pattern matches any blank line. If your MUD sends a blank line before the item list, `captureEnd()` guards against this with the `ShopLib.listStarted` flag — it will not fire until at least one item has been captured.

**Duplicate items after re-running `#shop add`**  
The item list is cleared automatically on first capture via `ShopLib.listStarted`. Re-running `#shop add` on an existing shop always produces a clean list.

---

## Function Reference

| Function | Description |
|:---|:---|
| `ShopLib.addShop(vnum, keeper, zone, area)` | Add/update shop header and trigger capture |
| `ShopLib.captureItem(listnum, name, price)` | Called by trigger — appends one item |
| `ShopLib.captureEnd()` | Called by end trigger — saves and displays |
| `ShopLib.addItem(vnum, listnum, name, price)` | Manual single item add |
| `ShopLib.deleteShop(vnum)` | Delete shop and all items |
| `ShopLib.deleteItem(vnum, listnum)` | Delete one item |
| `ShopLib.view(vnum)` | Display one shop |
| `ShopLib.list()` | List all shops |
| `ShopLib.listArea(areaname)` | List shops in area |
| `ShopLib.stat(searchstring)` | Search items, returns table |
| `ShopLib.buy(searchstring)` | Where to buy, prints results |
| `ShopLib.save()` | Save to disk |
| `ShopLib.load()` | Load from disk |
| `ShopLib.import()` | Import from exported data file |
| `ShopLib.export()` | Export to main profile |
| `ShopLib.cmd(argstring)` | Main alias dispatcher |
