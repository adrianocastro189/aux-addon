# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **aux-addon**, a World of Warcraft 1.12 (Vanilla) auction house replacement addon for Turtle WoW. It provides advanced auction house features including automatic scanning, price history tracking, sophisticated filtering, and efficient posting.

## Development Workflow

**No build process required.** This is a Lua addon that runs directly in the WoW client:

- Copy the `aux-addon` folder to `World of Warcraft\Interface\AddOns\`
- Restart WoW or use `/reload` to see changes
- Check the `FrameXML.log` file in WoW folder for Lua errors
- Enable "Show Lua Errors" in WoW interface options for debugging

## Architecture

### Module System

The addon uses a custom module system defined in `libs/package.lua`:

```lua
-- At the top of every file
module 'aux.module.name'

-- Export functions by assigning to M
function M.public_function() ... end

-- Import other modules
local other = require 'aux.other.module'
```

- `M` table is the module's public interface
- `_M` is the module's private environment
- `require` returns the public interface of another module

### Event System and Threading

The addon implements cooperative multitasking via `control.lua`:

- `thread(function)` - Create a new thread
- `wait(condition, callback)` - Yield and resume when condition is met
- `when(condition, callback)` - Wait for condition then execute
- `event_listener(event, callback)` - Listen for WoW events
- `on_next_event(event, callback)` - One-time event listener

Conditions are typically functions like `later(seconds)` or `signal()`.

### Table Management

`libs/T.lua` provides table pooling for memory efficiency:

- `T.acquire()` - Get a temporary table from pool
- `T.release(t)` - Return table to pool
- `T.temp(t)` - Mark for auto-release (use: `T.temp(t)` or `T.temp - t`)
- `T.static(t)` - Prevent auto-release (use: `T.static(t)` or `T.static - t`)
- `T.list(...)` / `T.map(...)` / `T.set(...)` - Create collections
- `T.vararg-function(arg)` - Handle variable arguments

**Convention**: Always use `T.temp(t)` or `T.static(t)` on acquired tables.

### Data Persistence

Data is stored via WoW's `SavedVariables` in the `aux` global table:

- `aux.account` - Account-wide settings (scale, theme, ignore_owner, etc.)
- `aux.realm` - Realm-wide data (characters, recent searches)
- `aux.faction` - Faction-specific data (price history, post settings)
- `aux.character` - Character-specific settings (tooltip options)

Access via:
- `aux.account_data` - Account settings
- `aux.character_data` - Character settings
- `aux.realm_data` - Realm data
- `aux.faction_data` - Faction data (includes history and post settings)

### UI Architecture

- Main frame defined in `frame.lua` - `aux_frame` is the root
- Tabs are registered with `aux.tab(name)` and receive OPEN/CLOSE/USE_ITEM/CLICK_LINK events
- GUI components in `gui/` folder use the `aux.gui` module
- Two themes: "blizzard" (default) and "modern" - toggle with `/aux theme`

## File Organization

```
libs/
  package.lua       # Module system
  T.lua              # Table pooling and utilities
  ChatThrottleLib.lua # Chat bandwidth management

core/
  scan.lua           # Auction scanning logic
  post.lua           # Posting logic
  history.lua        # Price history calculations
  disenchant.lua     # Disenchant value calculations
  tooltip.lua        # Tooltip additions
  slash.lua          # Slash command handling
  cache.lua          # Item caching
  crafting.lua       # Crafting cost integration
  stack.lua          # Stack size utilities
  shortcut.lua       # Keyboard shortcuts

tabs/
  search/            # Search tab (core.lua, frame.lua, filter.lua, saved.lua, results.lua)
  post/              # Post tab (core.lua, frame.lua)
  auctions/          # My Auctions tab (core.lua, frame.lua)
  bids/              # My Bids tab (core.lua, frame.lua)
  wppa/              # WPPA compatibility tab (core.lua, frame.lua)

gui/
  core.lua           # Base UI components
  listing.lua        # Table/list components
  auction_listing.lua # Auction display tables
  item_listing.lua   # Item inventory listings
  purchase_summary.lua # Purchase tracking UI

util/
  info.lua           # Item information utilities
  filter.lua         # Filter parsing and evaluation
  money.lua          # Money formatting/serialization
  persistence.lua    # Settings serialization
  completion.lua     # Search box autocompletion
  sort.lua           # Sorting utilities
  scan.lua           # Scan state utilities
  export.lua         # Data export functionality

Root files:
  aux-addon.lua      # Main addon file, event handling
  frame.lua          # Main frame definition
  util.lua           # General utilities
  control.lua        # Threading and event control
  color.lua          # Color definitions
  localization.lua   # Key bindings
```

## Key Concepts

### Auction Scanning

Scans are managed in `core/scan.lua` and `util/scan.lua`:
- Queries combine Blizzard filters (affect server pages) and post-filters (client-side)
- Rate limited: one page request per ~4 seconds
- Use `scan.abort(scan_id)` to cancel

### Filter Syntax

Filters use slash-separated parts with Polish notation for logical operators:

```
-- Examples:
wrangler's wristbands/exact/or2/and2/+3 agility/+3 stamina/price/1g
or/and2/profit/5g/percent/60/bid-profit/5g
recipe/usable/not/libram
felcloth/exact/stack/5
```

### Price History

- Daily value = minimum buyout for that day
- Market value = median of last 11 daily values (weighted by age)
- Stored per-faction in `faction_data.history`

### Post Tab Price Adjustment

The Unit Buyout Price field in the Post tab supports modifier-click shortcuts for quick price adjustments:

| Modifier    | Action           | Example                 |
| ----------- | ---------------- | ----------------------- |
| Alt+Click   | Decrease by 1c   | 1g 52s 31c → 1g 52s 30c |
| Ctrl+Click  | Decrease by 5s   | 1g 52s 31c → 1g 47s 31c |
| Shift+Click | Previous ten max | 1g 52s 31c → 1g 49s 99c |

When any modifier-click is used, the Unit Starting Price is also updated to match the buyout price.

### Slash Commands

Key commands for testing:
- `/aux scale <factor>` - Scale UI
- `/aux theme` - Toggle between blizzard/modern themes
- `/aux clear item cache` - Clear item cache
- `/aux populate wdb` - Populate item database
- `/aux search <query>` - Execute search from command line
- `/aux post duration <2|8|24>` - Set default duration (in hours)

## Important Notes

- Turtle WoW specific: Cross-faction data sharing on "Nordanaar" server (all treated as Horde)
- Turtle WoW deposit fee: Displayed fee is reduced by 40% (approximation)
- Turtle WoW auction durations: Accurate 2h/8h/24h (not 12h/24h/48h)
- Optional dependency on ShaguTweaks for vendor price fallback
