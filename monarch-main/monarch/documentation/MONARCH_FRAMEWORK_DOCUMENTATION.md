# Monarch Framework Documentation

Complete API documentation for the Monarch Roleplay Framework. This document covers all available functions, utilities, and systems for developers creating schemas and modules.

The remainder of this file is kept as a legacy consolidated reference.

## Table of Contents

1. [Player Meta Functions](#player-meta-functions)
2. [Money System](#money-system)
3. [XP System](#xp-system)
4. [Character System](#character-system)
5. [Name System](#name-system)
6. [Whitelist System](#whitelist-system)
7. [Voice Mode System](#voice-mode-system)
8. [Skills System](#skills-system)
9. [Inventory System](#inventory-system)
10. [Door System](#door-system)
11. [Chat Commands](#chat-commands)
12. [Utility Functions](#utility-functions)
13. [Introduction System](#introduction-system)
14. [Animation System](#animation-system)
15. [Model Scaling System](#model-scaling-system)
16. [Time System](#time-system)
17. [Faction System](#faction-system)
18. [User Interfaces - UI Scaling System](#user-interfaces---ui-scaling-system)
19. [Hooks & Events](#hooks--events)

---

## Player Meta Functions

Functions attached to the Player entity that can be called with `ply:FunctionName()`

### Core Player Functions

#### ply:Notify(message, kind, length)
Display a notification to the player.
- **Parameters:**
  - `message` (string): Message to display
  - `kind` (number): Optional. 0=generic, 1=error, 2=undo, 3=hint (default: 0)
  - `length` (number): Optional. Duration in seconds (default: 3)
- **Returns:** None
- **Realm:** Shared (works on both client and server)
- **Example:**
```lua
ply:Notify("Welcome to the server!", 0, 5)
ply:Notify("Error: Invalid input", 1, 3)
```

---

## Money System

### ply:GetMoney()
Get the player's current money amount.
- **Returns:** number - Current money amount
- **Realm:** Shared
- **Example:**
```lua
local money = ply:GetMoney()
print("Player has $" .. money)
```

### ply:AddMoney(amount, reason)
Add money to the player's account.
- **Parameters:**
  - `amount` (number): Amount to add (must be positive)
  - `reason` (string): Optional. Reason for the money gain (shown in notification)
- **Returns:** boolean - True if successful
- **Realm:** Server only
- **Example:**
```lua
ply:AddMoney(500, "Quest reward")
ply:AddMoney(1000, "Salary payment")
```

### ply:TakeMoney(amount, reason)
Remove money from the player's account.
- **Parameters:**
  - `amount` (number): Amount to remove (must be positive)
  - `reason` (string): Optional. Reason for the money loss
- **Returns:** boolean - True if successful (false if insufficient funds)
- **Realm:** Server only
- **Example:**
```lua
if ply:TakeMoney(250, "Shop purchase") then
    -- Purchase successful
else
    ply:Notify("You don't have enough money!", 1)
end
```

### ply:SetMoney(amount)
Set the player's money to a specific amount.
- **Parameters:**
  - `amount` (number): New money amount (must be non-negative)
- **Returns:** boolean - True if successful
- **Realm:** Server only
- **Example:**
```lua
ply:SetMoney(5000)
```

### ply:CanAfford(amount)
Check if the player can afford a specific amount.
- **Parameters:**
  - `amount` (number): Amount to check
- **Returns:** boolean - True if player has enough money
- **Realm:** Shared
- **Example:**
```lua
if ply:CanAfford(1000) then
    ply:TakeMoney(1000, "Item purchase")
    -- Give item
else
    ply:Notify("Insufficient funds!", 1)
end
```

---

## XP System ---> DEPRECATED. No longer used in the base framework.

### ply:GetXP()
Get the player's current XP amount.
- **Returns:** number - Current XP amount
- **Realm:** Shared
- **Example:**
```lua
local xp = ply:GetXP()
```

### ply:AddXP(amount, reason)
Add XP to the player.
- **Parameters:**
  - `amount` (number): Amount of XP to add
  - `reason` (string): Optional. Reason for XP gain
- **Returns:** boolean - True if successful
- **Realm:** Server only
- **Example:**
```lua
ply:AddXP(100, "Completed quest")
```

### ply:TakeXP(amount, reason)
Remove XP from the player.
- **Parameters:**
  - `amount` (number): Amount of XP to remove
  - `reason` (string): Optional. Reason for XP loss
- **Returns:** boolean - True if successful (false if insufficient XP)
- **Realm:** Server only
- **Example:**
```lua
ply:TakeXP(50, "Death penalty")
```

### ply:SetXP(amount)
Set the player's XP to a specific amount.
- **Parameters:**
  - `amount` (number): New XP amount
- **Returns:** boolean - True if successful
- **Realm:** Server only
- **Example:**
```lua
ply:SetXP(1000)
```

---

## Character System

### ply:GetCharID()
Get the player's active character ID.
- **Returns:** number/nil - Character ID or nil if no active character
- **Realm:** Shared
- **Example:**
```lua
local charID = ply:GetCharID()
if charID then
    print("Character ID: " .. charID)
end
```

### ply:GetCharData()
Get the player's complete character data table.
- **Returns:** table - Character data table (empty if no active character)
- **Realm:** Shared
- **Example:**
```lua
local charData = ply:GetCharData()
print("Name:", charData.name)
print("Model:", charData.model)
```

### ply:HasActiveChar()
Check if the player has an active character.
- **Returns:** boolean - True if player has an active character
- **Realm:** Shared
- **Example:**
```lua
if not ply:HasActiveChar() then
    ply:Notify("You must create a character first!")
    return
end
```

### ply:GetCharModel()
Get the player's character model path.
- **Returns:** string - Model path
- **Realm:** Shared
- **Example:**
```lua
local model = ply:GetCharModel()
```

### ply:GetCharSkin()
Get the player's character skin number.
- **Returns:** number - Skin number (default: 0)
- **Realm:** Shared
- **Example:**
```lua
local skin = ply:GetCharSkin()
```

### ply:IsFemaleChar()
Check if the player's character is female.
- **Returns:** boolean - True if character is female
- **Realm:** Shared
- **Example:**
```lua
if ply:IsFemaleChar() then
    -- Female-specific logic
end
```

### Physical Description Functions

#### ply:GetHeight()
Get character height description.
- **Returns:** string - Height description
- **Realm:** Shared

#### ply:GetWeight()
Get character weight description.
- **Returns:** string - Weight description
- **Realm:** Shared

#### ply:GetHairColor()
Get character hair color.
- **Returns:** string - Hair color
- **Realm:** Shared

#### ply:GetEyeColor()
Get character eye color.
- **Returns:** string - Eye color
- **Realm:** Shared

#### ply:GetAge()
Get character age.
- **Returns:** number - Age (default: 0)
- **Realm:** Shared

#### ply:GetPhysicalDescription()
Get all physical description data at once.
- **Returns:** table - Table containing height, weight, hair, eyes, age
- **Realm:** Shared
- **Example:**
```lua
local desc = ply:GetPhysicalDescription()
print("Age:", desc.age)
print("Height:", desc.height)
print("Hair:", desc.hair)
```

---

## Name System

### ply:GetRPName()
Get the player's current roleplay name (includes temporary names).
- **Returns:** string - Current RP name
- **Realm:** Shared
- **Example:**
```lua
local name = ply:GetRPName()
```

### ply:GetBaseRPName()
Get the player's base RP name (ignores temporary names).
- **Returns:** string - Base RP name
- **Realm:** Shared
- **Example:**
```lua
local baseName = ply:GetBaseRPName()
```

### ply:GetCharName()
Get the character's saved database name.
- **Returns:** string - Character name from database
- **Realm:** Shared
- **Example:**
```lua
local charName = ply:GetCharName()
```

### ply:SetRPName(name, saveToDb)
Set the player's RP name.
- **Parameters:**
  - `name` (string): New RP name
  - `saveToDb` (boolean): Optional. If true, saves permanently to database (default: false)
- **Returns:** None
- **Realm:** Shared (but database save only works server-side)
- **Example:**
```lua
-- Temporary name
ply:SetRPName("John Smith")

-- Permanent name (saved to database)
ply:SetRPName("John Smith", true)
```

### ply:SetTempRPName(tempName, prefix, suffix)
Set a temporary RP name with optional prefix/suffix.
- **Parameters:**
  - `tempName` (string): Temporary name
  - `prefix` (string): Optional. Prefix to add before name
  - `suffix` (string): Optional. Suffix to add after name
- **Returns:** boolean - True if successful
- **Realm:** Server only
- **Example:**
```lua
ply:SetTempRPName("Smith", "Dr.", "MD")
-- Results in: "Dr. Smith MD"

ply:SetTempRPName("John Doe")
-- Results in: "John Doe"
```

### ply:RestoreRPName()
Restore the player's original RP name (remove temporary name).
- **Returns:** boolean - True if successful
- **Realm:** Server only
- **Example:**
```lua
ply:RestoreRPName()
```

### ply:HasTempRPName()
Check if the player has a temporary RP name active.
- **Returns:** boolean - True if temporary name is set
- **Realm:** Shared
- **Example:**
```lua
if ply:HasTempRPName() then
    print("Player has a temporary name")
end
```

### ply:RequestTempRPName(newName)
Request a temporary RP name change (realm-safe).
- **Parameters:**
  - `newName` (string): New temporary name
- **Returns:** boolean - True if request was sent/processed
- **Realm:** Shared
- **Example:**
```lua
ply:RequestTempRPName("Disguised Person")
```

---

## Whitelist System

### ply:SetWhitelist(teamID, level)
Set a whitelist level for a specific team.
- **Parameters:**
  - `teamID` (number): Team ID to whitelist for
  - `level` (number): Whitelist level (default: 1)
- **Returns:** boolean - True if successful
- **Realm:** Shared
- **Example:**
```lua
ply:SetWhitelist(TEAM_POLICE, 2)
```

### ply:GetWhitelist(teamID)
Get the whitelist level for a specific team.
- **Parameters:**
  - `teamID` (number): Team ID to check
- **Returns:** number - Whitelist level (0 if not whitelisted)
- **Realm:** Shared
- **Example:**
```lua
local level = ply:GetWhitelist(TEAM_POLICE)
if level >= 2 then
    -- Player has level 2+ whitelist
end
```

### ply:HasWhitelist(teamID, requiredLevel)
Check if player has a specific whitelist level or higher.
- **Parameters:**
  - `teamID` (number): Team ID to check
  - `requiredLevel` (number): Required level (default: 1)
- **Returns:** boolean - True if player meets requirement
- **Realm:** Shared
- **Example:**
```lua
if ply:HasWhitelist(TEAM_MEDIC, 1) then
    -- Player can join medic team
end
```

### ply:RemoveWhitelist(teamID)
Remove whitelist for a specific team.
- **Parameters:**
  - `teamID` (number): Team ID to remove whitelist from
- **Returns:** boolean - True if successful
- **Realm:** Shared
- **Example:**
```lua
ply:RemoveWhitelist(TEAM_POLICE)
```

### ply:ClearAllWhitelists()
Remove all whitelists from the player.
- **Returns:** boolean - True if successful
- **Realm:** Shared
- **Example:**
```lua
ply:ClearAllWhitelists()
```

### ply:GetAllWhitelists()
Get all active whitelists for the player.
- **Returns:** table - Table of whitelists with levels and team data
- **Realm:** Shared
- **Example:**
```lua
local whitelists = ply:GetAllWhitelists()
for teamID, data in pairs(whitelists) do
    print(data.name .. " - Level " .. data.level)
end
```

---

## Voice Mode System

The voice mode system allows players to switch between different voice chat modes with varying hearing distances.

### ply:GetVoiceMode()
Get the player's current voice mode ID.
- **Returns:** string - Voice mode ID (e.g., "speaking", "whispering", "shouting")
- **Realm:** Shared
- **Example:**
```lua
local mode = ply:GetVoiceMode()
print("Current mode:", mode)
```

### ply:SetVoiceMode(modeId)
Set the player's voice mode.
- **Parameters:**
  - `modeId` (string): Voice mode ID to set
- **Returns:** boolean - True if successful
- **Realm:** Shared
- **Example:**
```lua
ply:SetVoiceMode("whispering")
```

### ply:GetVoiceModeData()
Get the complete data table for the player's current voice mode.
- **Returns:** table - Voice mode data (contains id, name, distance, color, description)
- **Realm:** Shared
- **Example:**
```lua
local modeData = ply:GetVoiceModeData()
print("Mode:", modeData.name)
print("Distance:", modeData.distance)
```

### ply:GetVoiceDistance()
Get the hearing distance for the player's current voice mode.
- **Returns:** number - Distance in units
- **Realm:** Shared
- **Example:**
```lua
local distance = ply:GetVoiceDistance()
```

### ply:CycleVoiceMode()
Cycle to the next voice mode.
- **Returns:** boolean - True if successful
- **Realm:** Shared
- **Example:**
```lua
ply:CycleVoiceMode() -- Switches to next mode in order
```

### Monarch.VoiceModes.Register(modeData)
Register a new voice mode.
- **Parameters:**
  - `modeData` (table): Mode data table with required fields:
    - `id` (string): Unique identifier
    - `name` (string): Display name
    - `distance` (number): Hearing distance in units
    - `color` (Color): Optional. UI color (default: white)
    - `description` (string): Optional. Description
- **Returns:** boolean - True if successful
- **Realm:** Shared
- **Example:**
```lua
Monarch.VoiceModes.Register({
    id = "yelling",
    name = "Yelling",
    distance = 900,
    color = Color(255, 200, 100),
    description = "Louder than speaking"
})
```

### Monarch.VoiceModes.GetMode(id)
Get a voice mode by its ID.
- **Parameters:**
  - `id` (string): Mode ID
- **Returns:** table/nil - Mode data or nil if not found
- **Realm:** Shared
- **Example:**
```lua
local mode = Monarch.VoiceModes.GetMode("speaking")
```

### Monarch.VoiceModes.GetAllModes()
Get all registered voice modes.
- **Returns:** table - Table of all modes
- **Realm:** Shared
- **Example:**
```lua
local modes = Monarch.VoiceModes.GetAllModes()
for id, mode in pairs(modes) do
    print(mode.name, mode.distance)
end
```

### Monarch.VoiceModes.GetModeOrder()
Get the ordered list of mode IDs (for cycling).
- **Returns:** table - Array of mode IDs
- **Realm:** Shared
- **Example:**
```lua
local order = Monarch.VoiceModes.GetModeOrder()
```

### Monarch.VoiceModes.GetNextMode(currentMode)
Get the next mode in the cycle.
- **Parameters:**
  - `currentMode` (string): Current mode ID
- **Returns:** string - Next mode ID
- **Realm:** Shared
- **Example:**
```lua
local next = Monarch.VoiceModes.GetNextMode("speaking")
```

### Server-Side Voice Mode Functions

#### Monarch.VoiceModes.SetPlayerMode(ply, modeId)
*Server only* - Set a player's voice mode and notify them.
- **Parameters:**
  - `ply` (Player): Player to set mode for
  - `modeId` (string): Mode ID to set
- **Realm:** Server only

#### Monarch.VoiceModes.GetPlayerMode(ply)
*Server only* - Get a player's current voice mode.
- **Parameters:**
  - `ply` (Player): Player to check
- **Returns:** string - Mode ID
- **Realm:** Server only

---

## Skills System

The skills system tracks XP and levels for various skills.

### Monarch.RegisterSkill(skillDef)
Register a new skill.
- **Parameters:**
  - `skillDef` (table): Skill definition with fields:
    - `id` (string): Unique skill identifier
    - `Name` (string): Display name
    - `XPPerSecond` (number): Optional. XP rate override
- **Returns:** None
- **Realm:** Shared
- **Example:**
```lua
Monarch.RegisterSkill({
    id = "mining",
    Name = "Mining",
    XPPerSecond = 2
})
```

### Monarch.GetSkill(id)
Get a skill definition by ID.
- **Parameters:**
  - `id` (string): Skill ID
- **Returns:** table/nil - Skill definition or nil
- **Realm:** Shared
- **Example:**
```lua
local skill = Monarch.GetSkill("crafting")
```

### Monarch.Skills.GetLevelForXP(xp)
Calculate the level for a given XP amount.
- **Parameters:**
  - `xp` (number): XP amount
- **Returns:** number - Level
- **Realm:** Shared
- **Example:**
```lua
local level = Monarch.Skills.GetLevelForXP(500)
```

### Monarch.Skills.GetLevelName(level)
Get the human-friendly name for a level.
- **Parameters:**
  - `level` (number): Level number
- **Returns:** string - Level name (e.g., "Beginner", "Novice")
- **Realm:** Shared
- **Example:**
```lua
local name = Monarch.Skills.GetLevelName(3)
```

---

## Inventory System

### Monarch.Inventory.LoadForOwner(ply, ownerid)
*Server only* - Load inventory from database for an owner ID.
- **Parameters:**
  - `ply` (Player): Player to load for
  - `ownerid` (string): Owner ID (usually character ID)
- **Realm:** Server only

### Monarch.Inventory.SaveForOwner(ply, ownerid, inv)
*Server only* - Save inventory to database.
- **Parameters:**
  - `ply` (Player): Player saving
  - `ownerid` (string): Owner ID
  - `inv` (table): Inventory data
- **Realm:** Server only

### Monarch.Inventory.DBAddItem(ownerid, class, storageType)
*Server only* - Add an item to the database inventory.
- **Parameters:**
  - `ownerid` (string): Owner ID
  - `class` (string): Item class
  - `storageType` (string): Storage type (e.g., "INV", "STORAGE")
- **Realm:** Server only

### Monarch.Inventory.DBRemoveItem(ownerid, class, storetype, limit)
*Server only* - Remove an item from the database inventory.
- **Parameters:**
  - `ownerid` (string): Owner ID
  - `class` (string): Item class
  - `storetype` (string): Storage type
  - `limit` (number): Optional. Max number to remove
- **Realm:** Server only

### Monarch.Inventory.SpawnItem(itemClass, pos)
*Server only* - Spawn an item entity in the world.
- **Parameters:**
  - `itemClass` (string): Item class to spawn
  - `pos` (Vector): Position to spawn at
- **Returns:** Entity - Spawned item entity
- **Realm:** Server only
- **Example:**
```lua
local item = Monarch.Inventory.SpawnItem("food_bread", ply:GetPos())
```

### Item Runtime Systems

#### Durability System
Durability is an item-level runtime system used for breakable/consumable equipment.

- **Enable durability:** set `Durability = true` in the item definition.
- **Starting value:** first read is seeded from `StartingDurability` or `DurabilityStart` or `DefaultDurability` (fallback `100`).
- **Storage:** runtime value is persisted in `itemData.durability` (clamped `0-100`).
- **Stacking interaction:** durability-enabled items are treated as non-stackable by inventory give logic.

Durability is reduced through `ShouldLoseDurability` and applied by framework runtime hooks:

- `ShouldLoseDurability(...)` return behavior:
  - `true` -> lose `1`
  - number -> lose that amount (floored, min `0`)
  - table `{ lose = true, amount = n }` -> lose `n`
  - anything else / falsey -> no durability loss
- On durability reaching `0`:
  - `OnDurabilityDrained(ply, slot, itemData, context)` is called
  - equipped weapon is stripped (if applicable)
  - item is removed from inventory slot

Useful durability callbacks:

- `GetDurability(itemData)`
- `SetDurability(itemData, value)`
- `ShouldLoseDurability(ply, slot, itemData, def, context)`
- `OnDurabilityDrained(ply, slot, itemData, context)`
- `WeaponUsed(ply, slot, itemData, weapon, context)`

#### Stacking System
Stacking is controlled by item definition flags and stack limits.

- `CanStack = true` or `Stackable = true` enables stacking.
- `MaxStack` or `StackSize` sets per-slot stack cap.
- If stacking is enabled but no cap is provided, default cap is `5`.
- Constrained items (`metadata.constrained`) do not stack and are stored one per slot.
- Durability items (`Durability = true`) are forced non-stackable.

#### Equip System
Inventory uses a grid/equipment split:

- Main inventory slots: `1-20`
- Equipment slots: `21-30`

Common item fields that affect equip flow:

- `EquipGroup` (prevents multiple equipped items in same normalized group)
- `WeaponClass` (auto-give/strip weapon on equip/unequip)
- `WeaponOverrideClip` and runtime `clip` persistence
- `ShouldRemoveOnEquip` (consume/remove item when equipped)

Related hooks and callbacks:

- `CanEquip(ply)`
- `OnEquip(ply, itemClass, uid)`
- `UnEquip(ply, itemClass, uid)`
- `OnRemove(ply, slot, itemData, def)`
- Hook: `Monarch_CanChangeInventoryEquipState`
- Hook: `Monarch_InventoryEquipStateChanged`

#### Custom Action System
Items can expose custom actions via `item.Actions` and `ITEM:RegisterAction(actionID, actionData)`.

- Action schema:
  - `name` (required display label)
  - `CanRun(item, ply)` optional gate
  - `OnRun(item, ply)` action executor
- Trigger path: `Monarch_Inventory_ExecuteAction` net message.
- Framework hooks:
  - `Monarch_CanRunInventoryAction`
  - `Monarch_InventoryActionBlocked`
  - `Monarch_InventoryActionExecuted`

#### Durability Item Example

```lua
Monarch.RegisterItem({
  UniqueID = "example_durable_weapon",
  Name = "Example Durable Weapon",
  WeaponClass = "weapon_example",
  Durability = true,
  StartingDurability = 100,
  ShouldLoseDurability = function(self, ply, slot, itemData, context)
    if context and context.action == "weapon_use" then
      return 1
    end
    return 0
  end,
  OnDurabilityDrained = function(self, ply, slot, itemData, context)
    if IsValid(ply) and ply.Notify then
      ply:Notify("Your weapon has broken.", 1)
    end
  end
})
```

---

## Door System

### Monarch.Doors.SetDoorForSale(door, forSale, price)
*Server only* - Set a door for sale.
- **Parameters:**
  - `door` (Entity): Door entity
  - `forSale` (boolean): Whether door is for sale
  - `price` (number): Sale price
- **Realm:** Server only

### Monarch.Doors.SetDoorGroup(door, groupName)
*Server only* - Set a door's access group.
- **Parameters:**
  - `door` (Entity): Door entity
  - `groupName` (string): Group name
- **Realm:** Server only

### Monarch.Doors.SetDoorOwner(door, ply)
*Server only* - Set a door's owner.
- **Parameters:**
  - `door` (Entity): Door entity
  - `ply` (Player): Owner player
- **Realm:** Server only

### Monarch.Doors.SetDoorLocked(door, locked)
*Server only* - Lock or unlock a door.
- **Parameters:**
  - `door` (Entity): Door entity
  - `locked` (boolean): Lock state
- **Realm:** Server only

---

## Chat Commands

### Monarch.RegisterChatCommand(command, config)
Register a new chat command.
- **Parameters:**
  - `command` (string): Command trigger (e.g., "/give")
  - `config` (table): Configuration table with fields:
    - `callback` (function): Function to call
    - `adminOnly` (boolean): Optional. Require admin
    - `hideMessage` (boolean): Optional. Hide the command message
    - `takeArgs` (boolean): Optional. Pass arguments to callback
- **Returns:** None
- **Realm:** Shared
- **Example:**
```lua
Monarch.RegisterChatCommand("/heal", {
    callback = function(ply, args)
        ply:SetHealth(100)
        ply:Notify("You've been healed!")
    end,
    adminOnly = true,
    takeArgs = true
})
```

### Monarch.FindPlayer(info)
Find a player by partial name or SteamID.
- **Parameters:**
  - `info` (string): Player name or SteamID (partial match supported)
- **Returns:** Player/nil - Found player or nil
- **Realm:** Shared
- **Example:**
```lua
local target = Monarch.FindPlayer("John")
if target then
    print("Found:", target:Nick())
end
```

---

## Utility Functions

All utility functions are in the `Monarch.Utils` namespace.

### Monarch_ShowUseBar(parentPanel, duration, labelText, onDone, allowMovement)
Show a circular progress overlay for timed actions.
- **Parameters:**
  - `parentPanel` (Panel/nil): Parent panel for the overlay. Falls back to `vgui.GetWorldPanel()`.
  - `duration` (number): Duration in seconds. Internally clamped to a minimum of `0.05`.
  - `labelText` (string): Optional text shown under the progress circle (default fallback is "Using item...").
  - `onDone` (function): Optional callback fired when the timer finishes.
  - `allowMovement` (boolean): Optional. If `false`, captures mouse/keyboard input while active (except inventory-overlay mode).
- **Returns:** Panel/nil - Active overlay panel (DPanel) that can be removed to cancel.
- **Realm:** Client
- **Behavior Notes:**
  - Only one active use overlay exists at a time; existing overlay is removed when a new one is shown.
  - When inventory is open, the bar renders in inventory-overlay mode and uses world panel parenting.
  - If the returned panel is removed early, `onDone` is not called.
- **Example:**
```lua
Monarch_ShowUseBar(vgui.GetWorldPanel(), 3, "Processing...", function()
    LocalPlayer():ConCommand("say Finished processing")
end, false)
```

```lua
local overlay = Monarch_ShowUseBar(vgui.GetWorldPanel(), 5, "Lockpicking...")
timer.Simple(1.5, function()
    if IsValid(overlay) then overlay:Remove() end -- cancel
end)
```

### Monarch.Utils.IsEmpty(str)
Check if a string is empty or nil.
- **Parameters:**
  - `str` (string): String to check
- **Returns:** boolean - True if empty or nil
- **Realm:** Shared
- **Example:**
```lua
if Monarch.Utils.IsEmpty(name) then
    print("Name is empty!")
end
```

### Monarch.Utils.Clamp(value, min, max)
Clamp a number between min and max.
- **Parameters:**
  - `value` (number): Value to clamp
  - `min` (number): Minimum value
  - `max` (number): Maximum value
- **Returns:** number - Clamped value
- **Realm:** Shared
- **Example:**
```lua
local health = Monarch.Utils.Clamp(hp, 0, 100)
```

### Monarch.Utils.FormatMoney(amount)
Format a money amount with comma separators.
- **Parameters:**
  - `amount` (number): Amount to format
- **Returns:** string - Formatted string (e.g., "$1,234")
- **Realm:** Shared
- **Example:**
```lua
local formatted = Monarch.Utils.FormatMoney(5000)
-- Returns: "$5,000"
```

### Monarch.Utils.GetDistance(a, b)
Get distance between two entities or positions.
- **Parameters:**
  - `a` (Entity/Vector): First entity or position
  - `b` (Entity/Vector): Second entity or position
- **Returns:** number - Distance in units
- **Realm:** Shared
- **Example:**
```lua
local dist = Monarch.Utils.GetDistance(ply1, ply2)
```

### Monarch.Utils.IsWithinDistance(ply1, ply2, distance)
Check if two players are within a certain distance.
- **Parameters:**
  - `ply1` (Player): First player
  - `ply2` (Player): Second player
  - `distance` (number): Maximum distance
- **Returns:** boolean - True if within distance
- **Realm:** Shared
- **Example:**
```lua
if Monarch.Utils.IsWithinDistance(ply1, ply2, 200) then
    -- Players are close enough
end
```

### Monarch.Utils.GetPlayersInRadius(source, distance, filter)
Get all players within a radius of a position or entity.
- **Parameters:**
  - `source` (Vector/Entity): Source position or entity
  - `distance` (number): Radius distance
  - `filter` (function): Optional. Filter function (return true to include player)
- **Returns:** table - Array of players within radius
- **Realm:** Shared
- **Example:**
```lua
local nearby = Monarch.Utils.GetPlayersInRadius(ply:GetPos(), 500)
for _, nearbyPly in ipairs(nearby) do
    print(nearbyPly:Nick() .. " is nearby")
end

-- With filter
local nearbyPolice = Monarch.Utils.GetPlayersInRadius(ply:GetPos(), 500, function(p)
    return p:Team() == TEAM_POLICE
end)
```

### Monarch.Utils.Sanitize(str, allowSpaces)
Sanitize a string by removing special characters.
- **Parameters:**
  - `str` (string): String to sanitize
  - `allowSpaces` (boolean): Optional. Allow spaces (default: false)
- **Returns:** string - Sanitized string
- **Realm:** Shared
- **Example:**
```lua
local clean = Monarch.Utils.Sanitize("Hello! World?")
-- Returns: "HelloWorld"

local cleanWithSpaces = Monarch.Utils.Sanitize("Hello! World?", true)
-- Returns: "Hello World"
```

### Monarch.Utils.TableCopy(original)
Create a deep copy of a table.
- **Parameters:**
  - `original` (table): Table to copy
- **Returns:** table - Copied table
- **Realm:** Shared
- **Example:**
```lua
local original = {a = 1, b = {c = 2}}
local copy = Monarch.Utils.TableCopy(original)
copy.b.c = 3
-- original.b.c is still 2
```

---

## Introduction System

The introduction system allows players to introduce themselves to others.

### Monarch.Introductions.GetKnownName(observer, target)
*Server only* - Get the name that an observer knows for a target.
- **Parameters:**
  - `observer` (Player): Player observing
  - `target` (Player): Player being observed
- **Returns:** string/nil - Known name or nil
- **Realm:** Server only

### Monarch.Introductions.IntroducePlayer(introducer, target, observer, customName)
*Server only* - Introduce a player to another.
- **Parameters:**
  - `introducer` (Player): Player doing the introduction
  - `target` (Player): Player being introduced
  - `observer` (Player): Player being introduced to
  - `customName` (string): Optional. Custom name for introduction
- **Realm:** Server only

### Monarch.Introductions.GetDisplayName(ply)
*Client only* - Get the display name for a player (checks introductions).
- **Parameters:**
  - `ply` (Player): Player to get name for
- **Returns:** string - Display name
- **Realm:** Client only

### Monarch.Introductions.SetDefaultTeamKnowledge(rules)
*Server only* - Set default team-to-team name knowledge rules.
- **Parameters:**
  - `rules` (table): Key is observer team ID, value is either:
    - `true` to know all teams
    - table map `{ [targetTeamId] = true }`
    - table array `{ targetTeamId1, targetTeamId2, ... }`
- **Realm:** Server only

### Monarch.Introductions.GetDefaultTeamKnowledge()
*Server only* - Get current default team-to-team name knowledge rules.
- **Returns:** table - Current rules table
- **Realm:** Server only

### Monarch.Introductions.ApplyDefaultTeamKnowledge(observer, specificTarget)
*Server only* - Apply default team knowledge to one observer.
- **Parameters:**
  - `observer` (Player): Player who should know names by default
  - `specificTarget` (Player): Optional. Apply only to this target
- **Realm:** Server only

---

## Whitelist Functions (Server)

### Monarch.GetWhitelistLevels(ply)
*Server only* - Get all whitelist levels for a player from database.
- **Parameters:**
  - `ply` (Player): Player to check
- **Realm:** Server only

### Monarch.SetWhitelistLevel(ply, teamId, level)
*Server only* - Set whitelist level and sync to database.
- **Parameters:**
  - `ply` (Player): Player to set whitelist for
  - `teamId` (number): Team ID
  - `level` (number): Whitelist level
- **Realm:** Server only

---

## Staff Management

### Monarch.LoadStaffStats()
*Server only* - Load staff statistics from file.
- **Realm:** Server only

### Monarch.SaveStaffStats()
*Server only* - Save staff statistics to file.
- **Realm:** Server only

### Monarch.StaffSetGroupPersist(sid64, name, group)
*Server only* - Persistently set a player's staff group.
- **Parameters:**
  - `sid64` (string): SteamID64
  - `name` (string): Player name
  - `group` (string): Staff group (e.g., "admin", "moderator")
- **Realm:** Server only

---

## Examples

### Complete Money Shop Example
```lua
-- Register shop command
Monarch.RegisterChatCommand("/shop", {
    callback = function(ply, args)
        if not ply:HasActiveChar() then
            ply:Notify("You need a character to shop!", 1)
            return
        end
        
        local items = {
            {name = "Bread", price = 50, class = "food_bread"},
            {name = "Water", price = 30, class = "drink_water"},
            {name = "Medkit", price = 200, class = "item_medkit"}
        }
        
        -- Show shop menu
        net.Start("ShowShopMenu")
            net.WriteTable(items)
        net.Send(ply)
    end
})

-- Handle purchase
net.Receive("BuyItem", function(len, ply)
    local itemClass = net.ReadString()
    local price = net.ReadUInt(16)
    
    if not ply:CanAfford(price) then
        ply:Notify("You can't afford this!", 1)
        return
    end
    
    if ply:TakeMoney(price, "Shop purchase") then
        Monarch.Inventory.DBAddItem(ply:GetCharID(), itemClass, "INV")
        ply:Notify("Purchase successful!", 0)
    end
end)
```

### Proximity Voice Chat Example
```lua
-- Check if players can hear each other
hook.Add("PlayerCanHearPlayersVoice", "CustomProximity", function(listener, talker)
    if not IsValid(listener) or not IsValid(talker) then return false end
    
    -- Use voice mode distance
    local distance = talker:GetVoiceDistance()
    
    if Monarch.Utils.IsWithinDistance(listener, talker, distance) then
        return true, true -- Can hear, use 3D audio
    else
        return false -- Cannot hear
    end
end)
```

### Character Physical Description Display
```lua
-- Display physical description to nearby players
function ShowPhysicalDescription(ply, target)
    if not Monarch.Utils.IsWithinDistance(ply, target, 200) then
        ply:Notify("You're too far away!", 1)
        return
    end
    
    local desc = target:GetPhysicalDescription()
    local message = string.format(
        "%s\nAge: %d\nHeight: %s\nWeight: %s\nHair: %s\nEyes: %s",
        target:GetRPName(),
        desc.age,
        desc.height,
        desc.weight,
        desc.hair,
        desc.eyes
    )
    
    ply:Notify(message, 3, 10)
end
```

---

## Best Practices

### 1. Always Check Validity
```lua
-- Good
if IsValid(ply) and ply:HasActiveChar() then
    ply:AddMoney(100, "Reward")
end

-- Bad
ply:AddMoney(100, "Reward") -- Could error if ply is invalid
```

### 2. Use Realm-Safe Functions
```lua
-- Good - Works on both client and server
local money = ply:GetMoney()

-- Bad - Only works on server
if SERVER then
    local money = ply:GetMoney()
end
```

### 3. Provide User Feedback
```lua
-- Good
if ply:TakeMoney(500, "Shop purchase") then
    ply:Notify("Purchase successful!", 0)
else
    ply:Notify("Insufficient funds!", 1)
end

-- Bad
ply:TakeMoney(500) -- Player doesn't know what happened
```

### 4. Use Utility Functions
```lua
-- Good
if Monarch.Utils.IsWithinDistance(ply1, ply2, 200) then
    -- Do something
end

-- Bad
if ply1:GetPos():Distance(ply2:GetPos()) <= 200 then
    -- Do something
end
```

---

## Animation System

The animation system allows you to control player animations, gestures, and sequences.

### ply:PlayGesture(gesture, restart)
Play a gesture animation on the player (e.g., wave, salute).
- **Parameters:**
  - `gesture` (number): Gesture activity ID (e.g., `ACT_GMOD_GESTURE_WAVE`)
  - `restart` (boolean): Optional. Restart if already playing (default: true)
- **Returns:** boolean - True if successful
- **Realm:** Shared
- **Example:**
```lua
-- Wave gesture
ply:PlayGesture(ACT_GMOD_GESTURE_WAVE)

-- Salute gesture
ply:PlayGesture(ACT_GMOD_GESTURE_SALUTE)

-- Point gesture without restart
ply:PlayGesture(ACT_GMOD_GESTURE_POINT, false)
```

**Common Gesture Activities:**
- `ACT_GMOD_GESTURE_WAVE` - Wave
- `ACT_GMOD_GESTURE_AGREE` - Thumbs up
- `ACT_GMOD_GESTURE_DISAGREE` - Thumbs down
- `ACT_GMOD_GESTURE_BECON` - Beckon/come here
- `ACT_GMOD_GESTURE_BOW` - Bow
- `ACT_GMOD_GESTURE_SALUTE` - Salute
- `ACT_GMOD_GESTURE_CHEER` - Cheer
- `ACT_SIGNAL_FORWARD` - Signal forward
- `ACT_SIGNAL_HALT` - Stop signal

### ply:StopGesture()
Stop the current gesture animation.
- **Returns:** boolean - True if successful
- **Realm:** Shared
- **Example:**
```lua
ply:StopGesture()
```

### ply:PlaySequence(sequenceName)
Play an animation sequence by name.
- **Parameters:**
  - `sequenceName` (string): Name of the sequence
- **Returns:** boolean - True if successful
- **Realm:** Shared
- **Example:**
```lua
ply:PlaySequence("wave")
ply:PlaySequence("cheer")
ply:PlaySequence("salute")
```

**Note:** To get the name of the current animation sequence, use the built-in Entity method:
```lua
local currentAnim = ply:GetSequenceName(ply:GetSequence())
print("Currently playing:", currentAnim)
```

### ply:SetAnimationRate(rate)
Set the playback speed of animations.
- **Parameters:**
  - `rate` (number): Playback rate (1.0 = normal, 2.0 = double speed, 0.5 = half speed)
- **Returns:** boolean - True if successful
- **Realm:** Shared
- **Example:**
```lua
-- Slow motion
ply:SetAnimationRate(0.5)

-- Normal speed
ply:SetAnimationRate(1.0)

-- Fast forward
ply:SetAnimationRate(2.0)
```

### ply:RestartAnimation()
Restart the current animation from the beginning.
- **Returns:** boolean - True if successful
- **Realm:** Shared
- **Example:**
```lua
ply:RestartAnimation()
```

### Animation System Example
```lua
-- Create a wave command
Monarch.RegisterChatCommand("/wave", {
    callback = function(ply)
        ply:PlayGesture(ACT_GMOD_GESTURE_WAVE)
        
        -- Stop the gesture after 2 seconds
        timer.Simple(2, function()
            if IsValid(ply) then
                ply:StopGesture()
            end
        end)
    end
})

-- Slow motion on crouch
hook.Add("KeyPress", "SlowMotionCrouch", function(ply, key)
    if key == IN_DUCK then
        ply:SetAnimationRate(0.5)
    end
end)

hook.Add("KeyRelease", "NormalSpeedCrouch", function(ply, key)
    if key == IN_DUCK then
        ply:SetAnimationRate(1.0)
    end
end)
```

---

## Model Scaling System

The scaling system allows you to change the size of players and manipulate individual bones.

### ply:SetScale(scale, duration)
Set the player's model scale (size).
- **Parameters:**
  - `scale` (number): Scale multiplier (1.0 = normal, 2.0 = double size, 0.5 = half size)
  - `duration` (number): Optional. Transition duration in seconds (default: 0 = instant)
- **Returns:** boolean - True if successful
- **Realm:** Server only (applies to all clients)
- **Example:**
```lua
-- Make player twice as big instantly
ply:SetScale(2.0)

-- Shrink player to half size over 2 seconds
ply:SetScale(0.5, 2)

-- Giant player
ply:SetScale(5.0)

-- Tiny player
ply:SetScale(0.25)
```

**Note:** Scale is clamped between 0.1 and 10 to prevent extreme values. Collision hull is automatically adjusted.

### ply:GetScale()
Get the player's current model scale.
- **Returns:** number - Current scale multiplier
- **Realm:** Shared
- **Example:**
```lua
local currentScale = ply:GetScale()
print("Player scale:", currentScale)

if currentScale > 1.5 then
    print("Player is enlarged!")
end
```

### ply:ResetScale(duration)
Reset player scale to normal (1.0).
- **Parameters:**
  - `duration` (number): Optional. Transition duration (default: 0)
- **Returns:** boolean - True if successful
- **Realm:** Server only
- **Example:**
```lua
-- Reset instantly
ply:ResetScale()

-- Reset over 1 second
ply:ResetScale(1)
```

### ply:ScaleBone(boneID, scale)
Scale a specific bone on the player's model.
- **Parameters:**
  - `boneID` (number): Bone ID to scale
  - `scale` (Vector): Scale vector for each axis (X, Y, Z)
- **Returns:** boolean - True if successful
- **Realm:** Shared
- **Example:**
```lua
-- Make head bigger
local headBone = ply:LookupBone("ValveBiped.Bip01_Head1")
if headBone then
    ply:ScaleBone(headBone, Vector(2, 2, 2))
end

-- Stretch arms horizontally
local leftArmBone = ply:LookupBone("ValveBiped.Bip01_L_UpperArm")
if leftArmBone then
    ply:ScaleBone(leftArmBone, Vector(1, 3, 1))
end
```

### ply:ResetBoneScales()
Reset all bone scales to normal.
- **Returns:** boolean - True if successful
- **Realm:** Shared
- **Example:**
```lua
ply:ResetBoneScales()
```

### Scaling System Examples
```lua
-- Growth potion effect
function ApplyGrowthPotion(ply)
    local currentScale = ply:GetScale()
    local newScale = math.min(currentScale * 1.5, 3.0) -- Max 3x size
    
    ply:SetScale(newScale, 1.5) -- Grow over 1.5 seconds
    ply:Notify("You feel yourself growing larger!", 0)
    
    -- Revert after 30 seconds
    timer.Simple(30, function()
        if IsValid(ply) then
            ply:ResetScale(1.5)
            ply:Notify("You return to normal size", 0)
        end
    end)
end

-- Shrink ray weapon
function ShrinkPlayer(ply)
    if SERVER then
        local currentScale = ply:GetScale()
        if currentScale > 0.3 then
            ply:SetScale(currentScale * 0.8, 0.5)
            ply:Notify("You've been shrunk!", 1)
        end
    end
end

-- Big head mode (silly effect)
function EnableBigHeadMode(ply)
    local headBone = ply:LookupBone("ValveBiped.Bip01_Head1")
    if headBone then
        ply:ScaleBone(headBone, Vector(3, 3, 3))
    end
end
```

---

## Time System

The time system manages in-game time cycles, allowing for dynamic day/night cycles.

### Monarch.Time.GetFormatted(use24Hour)
Get the current in-game time as a formatted string.
- **Parameters:**
  - `use24Hour` (boolean): Optional. Use 24-hour format (default: false = 12-hour with AM/PM)
- **Returns:** string - Formatted time string
- **Realm:** Shared
- **Example:**
```lua
local time12 = Monarch.Time.GetFormatted()
-- Returns: "03:45 PM"

local time24 = Monarch.Time.GetFormatted(true)
-- Returns: "15:45"
```

### Monarch.Time.GetHour()
Get the current in-game hour (0-23).
- **Returns:** number - Current hour
- **Realm:** Shared
- **Example:**
```lua
local hour = Monarch.Time.GetHour()
print("Current hour:", hour) -- e.g., 15
```

### Monarch.Time.GetMinute()
Get the current in-game minute (0-59).
- **Returns:** number - Current minute
- **Realm:** Shared
- **Example:**
```lua
local minute = Monarch.Time.GetMinute()
print("Current minute:", minute) -- e.g., 45
```

### Monarch.Time.GetTime()
Get both hour and minute as a table.
- **Returns:** table - Table with 'hour' and 'minute' keys
- **Realm:** Shared
- **Example:**
```lua
local time = Monarch.Time.GetTime()
print(string.format("Time: %02d:%02d", time.hour, time.minute))
```

### Monarch.Time.IsDaytime()
Check if it's currently daytime (6 AM - 6 PM).
- **Returns:** boolean - True if daytime
- **Realm:** Shared
- **Example:**
```lua
if Monarch.Time.IsDaytime() then
    print("The sun is out!")
else
    print("It's nighttime")
end
```

### Monarch.Time.IsNighttime()
Check if it's currently nighttime (6 PM - 6 AM).
- **Returns:** boolean - True if nighttime
- **Realm:** Shared
- **Example:**
```lua
if Monarch.Time.IsNighttime() then
    -- Enable night vision
    -- Spawn nocturnal creatures
end
```

### Monarch.Time.GetPeriod()
Get a descriptive time period.
- **Returns:** string - Time period ("Morning", "Afternoon", "Evening", or "Night")
- **Realm:** Shared
- **Example:**
```lua
local period = Monarch.Time.GetPeriod()
ply:Notify("Good " .. period .. "!", 0)
-- Returns: "Good Morning!", "Good Afternoon!", etc.
```

### Monarch.Time.SetTime(hour, minute)
*Server only* - Set the current in-game time.
- **Parameters:**
  - `hour` (number): Hour to set (0-23)
  - `minute` (number): Optional. Minute to set (0-59, default: 0)
- **Returns:** boolean - True if successful
- **Realm:** Server only
- **Example:**
```lua
-- Set to 3:45 PM
Monarch.Time.SetTime(15, 45)

-- Set to midnight
Monarch.Time.SetTime(0, 0)

-- Set to noon
Monarch.Time.SetTime(12, 0)
```

### Monarch.Time.SetCycleDuration(seconds)
*Server only* - Set the duration of a full day/night cycle.
- **Parameters:**
  - `seconds` (number): Duration in real-world seconds
- **Returns:** boolean - True if successful
- **Realm:** Server only
- **Example:**
```lua
-- 30 minute cycle
Monarch.Time.SetCycleDuration(1800)

-- 1 hour cycle
Monarch.Time.SetCycleDuration(3600)

-- 10 minute cycle (fast)
Monarch.Time.SetCycleDuration(600)
```

**Default:** 2400 seconds (40 minutes)

### Monarch.Time.RealToGameTime(realSeconds)
Convert real-world seconds to in-game time.
- **Parameters:**
  - `realSeconds` (number): Real-world seconds
- **Returns:** number - Equivalent in-game seconds
- **Realm:** Shared
- **Example:**
```lua
-- How long is 5 real seconds in game time?
local gameSeconds = Monarch.Time.RealToGameTime(5)
print("5 real seconds = " .. gameSeconds .. " game seconds")
```

### Monarch.Time.GameToRealTime(gameSeconds)
Convert in-game seconds to real-world seconds.
- **Parameters:**
  - `gameSeconds` (number): In-game seconds
- **Returns:** number - Equivalent real-world seconds
- **Realm:** Shared
- **Example:**
```lua
-- How long is 1 game hour in real time?
local realSeconds = Monarch.Time.GameToRealTime(3600)
print("1 game hour = " .. realSeconds .. " real seconds")
```

### Monarch.Time.Get() (Legacy)
Backward compatibility function for getting formatted time.
- **Returns:** string - Formatted 12-hour time with AM/PM
- **Realm:** Shared
- **Example:**
```lua
local time = Monarch.Time.Get()
-- Returns: "03:45 PM"
```

### Time System Examples

#### Dynamic Lighting Based on Time
```lua
if CLIENT then
    hook.Add("RenderScreenspaceEffects", "DynamicDayNight", function()
        local hour = Monarch.Time.GetHour()
        local darkness = 0
        
        -- Calculate darkness level
        if hour >= 0 and hour < 6 then
            darkness = 0.7 -- Very dark at night
        elseif hour >= 6 and hour < 8 then
            darkness = 0.3 -- Dawn
        elseif hour >= 8 and hour < 18 then
            darkness = 0 -- Daytime
        elseif hour >= 18 and hour < 20 then
            darkness = 0.3 -- Dusk
        else
            darkness = 0.7 -- Night
        end
        
        -- Apply color modify
        local tab = {
            ["$pp_colour_addr"] = 0,
            ["$pp_colour_addg"] = 0,
            ["$pp_colour_addb"] = 0,
            ["$pp_colour_brightness"] = -darkness,
            ["$pp_colour_contrast"] = 1,
            ["$pp_colour_colour"] = 1 - (darkness * 0.5),
            ["$pp_colour_mulr"] = 0,
            ["$pp_colour_mulg"] = 0,
            ["$pp_colour_mulb"] = 0
        }
        DrawColorModify(tab)
    end)
end
```

#### Time-Based Shop Hours
```lua
function CanAccessShop(ply)
    local hour = Monarch.Time.GetHour()
    local period = Monarch.Time.GetPeriod()
    
    -- Shop open 8 AM - 8 PM
    if hour >= 8 and hour < 20 then
        return true
    else
        ply:Notify("The shop is closed. Open hours: 8:00 AM - 8:00 PM", 1)
        ply:Notify("Current time: " .. Monarch.Time.GetFormatted(), 0)
        return false
    end
end
```

#### Time-Based Salary System
```lua
-- Give salary every in-game hour
local lastSalaryHour = -1

hook.Add("Think", "HourlySalary", function()
    local currentHour = Monarch.Time.GetHour()
    
    if currentHour ~= lastSalaryHour then
        lastSalaryHour = currentHour
        
        for _, ply in player.Iterator() do
            if ply:Alive() and ply:HasActiveChar() then
                local salary = 50 -- Base salary
                ply:AddMoney(salary, "Hourly salary")
            end
        end
    end
end)
```

#### Time Command
```lua
Monarch.RegisterChatCommand("/time", {
    callback = function(ply, args)
        local time = Monarch.Time.GetFormatted()
        local period = Monarch.Time.GetPeriod()
        local isDaytime = Monarch.Time.IsDaytime()
        
        ply:Notify("Current time: " .. time, 0, 5)
        ply:Notify(period .. " - " .. (isDaytime and "Daytime" or "Nighttime"), 0, 5)
    end
})

-- Admin set time command
Monarch.RegisterChatCommand("/settime", {
    adminOnly = true,
    takeArgs = true,
    callback = function(ply, args)
        if not args[1] then
            ply:Notify("Usage: /settime <hour> [minute]", 1)
            return
        end
        
        local hour = tonumber(args[1])
        local minute = tonumber(args[2]) or 0
        
        if not hour or hour < 0 or hour > 23 then
            ply:Notify("Hour must be between 0 and 23", 1)
            return
        end
        
        if Monarch.Time.SetTime(hour, minute) then
            ply:Notify(string.format("Time set to %02d:%02d", hour, minute), 0)
        end
    end
})
```


## Faction System

A comprehensive faction management system for organizing players into groups with roles, permissions, and hierarchical structure.

### Server-Side Faction Functions

#### Monarch.Factions.Create(founderSteamID, name, founderRole, color, logoIndex)
Create a new faction.
- **Parameters:**
  - `founderSteamID` (string): The founder's Steam ID (64-bit)
  - `name` (string): Faction name (max 64 characters)
  - `founderRole` (string): The founder's initial role name
  - `color` (table): Color table with `{r, g, b}` values (0-255)
  - `logoIndex` (number): Logo index from 1-17
- **Returns:** table - The created faction object, or nil on error
- **Realm:** Server only
- **Example:**
```lua
local faction = Monarch.Factions.Create("76561198123456789", "Warriors", "Founder", {r=200, g=50, b=50}, 1)
if faction then
    print("Faction created with ID: " .. faction.id)
end
```

#### Monarch.Factions.GetByID(factionID)
Get a faction by its ID.
- **Parameters:**
  - `factionID` (number): The faction's ID
- **Returns:** table - The faction object, or nil if not found
- **Realm:** Server only
- **Example:**
```lua
local faction = Monarch.Factions.GetByID(1)
if faction then
    print("Faction: " .. faction.name)
end
```

#### Monarch.Factions.GetByFounder(founderSteamID)
Get a faction by the founder's Steam ID.
- **Parameters:**
  - `founderSteamID` (string): The founder's Steam ID
- **Returns:** table - The faction object, or nil if not found
- **Realm:** Server only
- **Example:**
```lua
local faction = Monarch.Factions.GetByFounder("76561198123456789")
```

#### Monarch.Factions.GetPlayerFaction(steamID)
Get the faction that a player is a member of.
- **Parameters:**
  - `steamID` (string): The player's Steam ID
- **Returns:** table - The faction object, or nil if player is not in a faction
- **Realm:** Server only
- **Example:**
```lua
local faction = Monarch.Factions.GetPlayerFaction(ply:SteamID64())
if faction then
    print(ply:Nick() .. " is in faction: " .. faction.name)
end
```

#### Monarch.Factions.Edit(factionID, field, value)
Edit a faction's properties.
- **Parameters:**
  - `factionID` (number): The faction's ID
  - `field` (string): The field to edit ("name", "color", or "logoIndex")
  - `value` (varies): The new value for the field
- **Returns:** boolean - True if successful
- **Realm:** Server only
- **Example:**
```lua
Monarch.Factions.Edit(1, "name", "New Faction Name")
Monarch.Factions.Edit(1, "color", {r=100, g=150, b=200})
Monarch.Factions.Edit(1, "logoIndex", 5)
```

#### Monarch.Factions.AddMember(factionID, memberSteamID, role)
Add a member to a faction.
- **Parameters:**
  - `factionID` (number): The faction's ID
  - `memberSteamID` (string): The new member's Steam ID
  - `role` (string): The member's initial role name
- **Returns:** boolean - True if successful
- **Realm:** Server only
- **Example:**
```lua
Monarch.Factions.AddMember(1, "76561198987654321", "Member")
```

#### Monarch.Factions.RemoveMember(factionID, memberSteamID)
Remove a member from a faction.
- **Parameters:**
  - `factionID` (number): The faction's ID
  - `memberSteamID` (string): The member's Steam ID
- **Returns:** boolean - True if successful
- **Realm:** Server only
- **Example:**
```lua
Monarch.Factions.RemoveMember(1, "76561198987654321")
```

### Role Management Functions

#### Monarch.Factions.CreateRole(factionID, name, color, precedence, permissions)
Create a new role within a faction.
- **Parameters:**
  - `factionID` (number): The faction's ID
  - `name` (string): Role name (max 32 characters)
  - `color` (table): Color table with `{r, g, b}` values
  - `precedence` (number): Role hierarchy level (higher = more authority)
  - `permissions` (table): Optional permissions table (see Permission System below)
- **Returns:** table - The created role object
- **Realm:** Server only
- **Example:**
```lua
local role = Monarch.Factions.CreateRole(1, "Officer", {r=200, g=200, b=100}, 50, {
    invite = true,
    kick = true,
    manageRoles = false
})
```

#### Monarch.Factions.UpdateRole(factionID, roleID, name, color, precedence, permissions)
Update an existing role.
- **Parameters:**
  - `factionID` (number): The faction's ID
  - `roleID` (string): The role's ID
  - `name` (string): New role name
  - `color` (table): New color table
  - `precedence` (number): New precedence level
  - `permissions` (table): New permissions table
- **Returns:** boolean - True if successful
- **Realm:** Server only
- **Example:**
```lua
Monarch.Factions.UpdateRole(1, "role_12345", "Senior Officer", {r=255, g=200, b=100}, 75, {
    invite = true,
    kick = true,
    editInfo = true,
    manageRoles = true
})
```

#### Monarch.Factions.DeleteRole(factionID, roleID)
Delete a role from a faction.
- **Parameters:**
  - `factionID` (number): The faction's ID
  - `roleID` (string): The role's ID
- **Returns:** boolean - True if successful
- **Realm:** Server only
- **Example:**
```lua
Monarch.Factions.DeleteRole(1, "role_12345")
```

#### Monarch.Factions.GetRoles(factionID)
Get all roles in a faction.
- **Parameters:**
  - `factionID` (number): The faction's ID
- **Returns:** table - Table of role objects indexed by roleID
- **Realm:** Server only
- **Example:**
```lua
local roles = Monarch.Factions.GetRoles(1)
for roleID, role in pairs(roles) do
    print(role.name .. " (Precedence: " .. role.precedence .. ")")
end
```

### Permission System

The Faction system includes a dynamic permission registration system for managing role-based access control.

#### Monarch.Factions.RegisterPermission(key, label, description)
Register a new permission type that can be assigned to roles.
- **Parameters:**
  - `key` (string): Unique permission identifier (e.g., "kick", "editInfo")
  - `label` (string): Human-readable permission name
  - `description` (string): Optional description of what this permission allows
- **Returns:** None
- **Realm:** Server only
- **Example:**
```lua
-- Custom permissions defined by your schema
Monarch.Factions.RegisterPermission("banMember", "Ban Members", "Allow members to permanently ban other players from the faction")
Monarch.Factions.RegisterPermission("editRules", "Edit Faction Rules", "Allow members to modify the faction's rule list")
Monarch.Factions.RegisterPermission("manageTreasury", "Manage Treasury", "Allow members to control faction funds and treasury")
```

#### Monarch.Factions.GetPermission(key)
Get information about a registered permission.
- **Parameters:**
  - `key` (string): The permission key
- **Returns:** table - Permission table with `key`, `label`, and `description` fields, or nil if not registered
- **Realm:** Server only
- **Example:**
```lua
local perm = Monarch.Factions.GetPermission("kick")
if perm then
    print(perm.label .. ": " .. perm.description)
end
```

#### Monarch.Factions.GetAllPermissions()
Get all registered permissions.
- **Returns:** table - Table of all registered permissions indexed by key
- **Realm:** Server only
- **Example:**
```lua
local allPerms = Monarch.Factions.GetAllPermissions()
for key, perm in pairs(allPerms) do
    print(key .. ": " .. perm.label)
end
```

#### Monarch.Factions.IsPermissionRegistered(key)
Check if a permission type is registered.
- **Parameters:**
  - `key` (string): The permission key
- **Returns:** boolean - True if registered
- **Realm:** Server only
- **Example:**
```lua
if Monarch.Factions.IsPermissionRegistered("customPerm") then
    print("Custom permission exists")
end
```

#### Monarch.Factions.HasPermission(steamID, permissionKey)
Check if a player has a specific permission in their faction.
- **Parameters:**
  - `steamID` (string): The player's Steam ID
  - `permissionKey` (string): The permission to check
- **Returns:** boolean - True if the player has the permission
- **Realm:** Server only
- **Notes:**
  - Faction founders automatically have all permissions
  - Other members are checked against their assigned role's permissions
- **Example:**
```lua
if Monarch.Factions.HasPermission(ply:SteamID64(), "kick") then
    -- Player can kick members
else
    ply:Notify("You don't have permission to kick members", 1)
end
```

### Built-in Permissions

The following permissions are registered by default:

- `invite` - Invite Members: Allow members to invite new players to the faction
- `editInfo` - Edit Faction Info: Allow members to edit faction name, color, and logo
- `kick` - Kick Members: Allow members to kick other players from the faction
- `lockInvites` - Lock Invites: Allow members to lock/unlock faction invitations
- `manageRoles` - Manage Roles: Allow members to create, edit, and delete faction roles
- `makeAnnouncements` - Make Announcements: Allow members to post announcements to the faction
- `editMemberRoles` - Edit Member Roles: Allow members to change other members' roles

### Usage Example: Setting Up a Complete Faction with Permissions

```lua
-- Create a faction
local faction = Monarch.Factions.Create("76561198123456789", "Knights", "Founder", {r=150, g=150, b=200}, 3)

-- Register custom permission (in addition to built-in ones)
Monarch.Factions.RegisterPermission("trainMembers", "Train Members", "Allow members to train new recruits")

-- Create Officer role with specific permissions
local officerRole = Monarch.Factions.CreateRole(faction.id, "Officer", {r=200, g=180, b=100}, 50, {
    invite = true,
    kick = true,
    editInfo = false,
    lockInvites = true,
    manageRoles = false,
    makeAnnouncements = true,
    editMemberRoles = true,
    trainMembers = true
})

-- Create Member role with limited permissions
local memberRole = Monarch.Factions.CreateRole(faction.id, "Member", {r=100, g=150, b=200}, 10, {
    invite = true,
    kick = false,
    editInfo = false,
    lockInvites = false,
    manageRoles = false,
    makeAnnouncements = false,
    editMemberRoles = false,
    trainMembers = false
})

-- Add a member as an Officer
Monarch.Factions.AddMember(faction.id, "76561198987654321", "Officer")

-- Check permission
if Monarch.Factions.HasPermission("76561198987654321", "kick") then
    print("Officer can kick members")
end

```

### Client-Side Access

The client has read-only access to faction data and registered permissions:

- `Monarch.Factions.PlayerFaction` - The player's current faction (table or nil)
- `Monarch.Factions.AllFactions` - Public faction list (limited data)
- `Monarch.Factions.RegisteredPermissions` - Table of all registered permissions from the server

---

## User Interfaces - UI Scaling System

**File:** `gamemode/modules/client/cl_scale.lua`

The UI Scaling System provides responsive scaling utilities for creating dynamic user interfaces that adapt to different screen resolutions. All scaling is based on a reference resolution of 1920x1080, with scaling calculations cached and updated automatically when the screen size changes.

### Core Scaling Functions

#### Monarch.UI.GetScale()
Returns the current scaling factors, recalculating if the screen size has changed.
- **Returns:** 
  - `scale` (number) - The uniform scale factor (minimum of X and Y scale)
  - `scaleX` (number) - Horizontal scale factor (width ratio)
  - `scaleY` (number) - Vertical scale factor (height ratio)
- **Realm:** Client
- **Example:**
```lua
local scale, sx, sy = Monarch.UI.GetScale()
print("Uniform scale:", scale)
print("X scale:", sx, "Y scale:", sy)
```

#### Monarch.UI.Scale(v)
Scales a value uniformly using the minimum scale factor (maintains aspect ratio).
- **Parameters:**
  - `v` (number): Value to scale
- **Returns:** number - Scaled value (rounded to nearest integer)
- **Realm:** Client
- **Example:**
```lua
local scaledSize = Monarch.UI.Scale(100)  -- Scales 100 uniformly
local scaledFont = Monarch.UI.Scale(24)   -- Scales font size
```

#### Monarch.UI.ScaleX(v)
Scales a value horizontally using the X scale factor.
- **Parameters:**
  - `v` (number): Value to scale
- **Returns:** number - Horizontally scaled value (rounded to nearest integer)
- **Realm:** Client
- **Example:**
```lua
local scaledWidth = Monarch.UI.ScaleX(500)
local scaledX = Monarch.UI.ScaleX(150)
```

#### Monarch.UI.ScaleY(v)
Scales a value vertically using the Y scale factor.
- **Parameters:**
  - `v` (number): Value to scale
- **Returns:** number - Vertically scaled value (rounded to nearest integer)
- **Realm:** Client
- **Example:**
```lua
local scaledHeight = Monarch.UI.ScaleY(300)
local scaledY = Monarch.UI.ScaleY(100)
```

#### Monarch.UI.ScaleFont(sz)
Scales a font size uniformly. This is an alias for `Monarch.UI.Scale()`.
- **Parameters:**
  - `sz` (number): Font size to scale
- **Returns:** number - Scaled font size
- **Realm:** Client
- **Example:**
```lua
local scaledFontSize = Monarch.UI.ScaleFont(32)
```

#### Monarch.UI.ScreenCenter()
Returns the center coordinates of the screen.
- **Returns:** 
  - `x` (number) - Center X coordinate
  - `y` (number) - Center Y coordinate
- **Realm:** Client
- **Example:**
```lua
local centerX, centerY = Monarch.UI.ScreenCenter()
panel:SetPos(centerX - panel:GetWide() / 2, centerY - panel:GetTall() / 2)
```

#### Monarch.UI.BlinkAlpha(baseAlpha)
Calculates a blinking alpha value using a sine wave, useful for animated UI elements.
- **Parameters:**
  - `baseAlpha` (number): Optional. Base alpha value (0-255). Default: 255
- **Returns:** number - Blinking alpha value (0-255)
- **Realm:** Client
- **Example:**
```lua
-- In Paint function
surface.SetDrawColor(255, 255, 255, Monarch.UI.BlinkAlpha(200))
surface.DrawRect(x, y, w, h)
```

### Workbar System

#### Monarch.MakeWorkbar(time, text, callback, freeze)
Creates and displays an animated progress bar (workbar) for time-based actions (e.g., crafting, looting).
- **Parameters:**
  - `time` (number): Duration in seconds
  - `text` (string): Text to display on the workbar
  - `callback` (function): Optional. Function to call when the workbar completes
  - `freeze` (boolean): Optional. Whether to freeze the player during the action (default: false)
- **Returns:** DPanel - The workbar panel
- **Realm:** Client
- **Notes:**
  - The workbar displays centered on screen
  - Players can press SPACE to cancel the workbar
  - The player is frozen during the action if `freeze` is true
  - The workbar automatically removes itself when complete
- **Example:**
```lua
Monarch.MakeWorkbar(5, "Looting...", function()
    print("Looting complete!")
end, true)  -- Freezes player while looting

-- Another example without freezing
Monarch.MakeWorkbar(3, "Crafting...", function()
    ply:AddMoney(100, "Crafted item")
end)
```

### Shorthand Functions

For convenience, the following shorthand functions are available globally:

```lua
Scale(v)      -- Alias for Monarch.UI.Scale(v)
ScaleX(v)     -- Alias for Monarch.UI.ScaleX(v)
ScaleY(v)     -- Alias for Monarch.UI.ScaleY(v)
ScaleFont(sz) -- Alias for Monarch.UI.ScaleFont(sz)
```

### Usage Recommendations

1. **Always use scaling for UI positions and sizes** - This ensures your UI looks correct on all resolutions
2. **Use `Scale()` for uniform scaling** - Maintains aspect ratio and looks consistent
3. **Use `ScaleX()` and `ScaleY()` separately** - When you need different scaling for width and height
4. **Cache values when possible** - Don't scale the same value repeatedly in loops
5. **Test on different resolutions** - The reference resolution is 1920x1080

### Example: Creating a Responsive Panel

```lua
local panel = vgui.Create("DPanel")
panel:SetSize(Monarch.UI.Scale(400), Monarch.UI.Scale(300))
panel:SetPos(Monarch.UI.ScaleX(100), Monarch.UI.ScaleY(100))

local label = vgui.Create("DLabel", panel)
label:SetText("Hello World")
label:SizeToContents()
label:SetPos(Monarch.UI.Scale(20), Monarch.UI.Scale(20))
label:SetFont("Monarch_Font_" .. Monarch.UI.ScaleFont(20))
```

---

## Hooks & Events

This section documents useful framework and engine hooks used for extending Monarch behavior.

### Character Lifecycle Hooks

#### OnCharacterActivated
Fired when a character is fully activated server-side (after character data is applied and activation completes).
- **Parameters:**
  - `ply` (Player): Activated player
  - `charData` (table): Active character data table
- **Returns:** None
- **Realm:** Server
- **Example:**
```lua
hook.Add("OnCharacterActivated", "MySchema_ApplyCharacterState", function(ply, charData)
    if not IsValid(ply) then return end

    print("Character activated:", charData.id, "for", ply:Nick())
    -- Example: run your schema-specific post-load logic here
end)
```

#### Monarch_CanSelectCharacter
Fired before a character selection request is processed.
- **Parameters:**
  - `ply` (Player): Player selecting a character
  - `charID` (number): Requested character ID
  - `charName` (string): Requested character name
- **Returns:** `false` to block selection, `nil` to allow
- **Realm:** Server

#### Monarch_CharacterDataSelected
Fired after DB character row is loaded and mapped into `ply.MonarchActiveChar`, before inventory load/final activation.
- **Parameters:**
  - `ply` (Player)
  - `charData` (table): Active character table used by framework
  - `dbRow` (table): Raw DB row
- **Returns:** None
- **Realm:** Server

#### Monarch_ShouldSpawnCharacter
Fired during character activation to determine if Monarch should call `ply:Spawn()`.
- **Parameters:**
  - `ply` (Player)
  - `charData` (table)
- **Returns:** `false` to skip default spawn, `nil`/other to allow
- **Realm:** Server

#### Monarch_PreCharacterActivated / Monarch_PostCharacterActivated
Lifecycle hooks around activation completion.
- **Parameters:**
  - `ply` (Player)
  - `charData` (table)
- **Returns:** None
- **Realm:** Server

#### Monarch_PostCharacterSpawn
Fired after spawn stage during activation (or immediately after skipped spawn path), right before `OnCharacterActivated`.
- **Parameters:** `ply`, `charData`
- **Returns:** None
- **Realm:** Server

#### Monarch_CanUpdateCharacterPhysical
Fired before RP physical fields are updated (height/weight/hair/eye/age).
- **Parameters:**
  - `ply` (Player)
  - `charData` (table)
  - `height`, `weight`, `hair`, `eye` (string)
  - `age` (number)
- **Returns:** `false` to block update
- **Realm:** Server

#### Monarch_CharacterPhysicalUpdated
Fired after physical fields are written and DB update callback returns.
- **Parameters:**
  - `ply` (Player)
  - `charData` (table)
  - `fields` (table): `{height, weight, haircolor, eyecolor, age}`
- **Returns:** None
- **Realm:** Server

### Core Gameplay Hooks

#### Monarch_PreScalePlayerDamage / Monarch_PostScalePlayerDamage
Hooks around custom hitgroup damage scaling in `GM:ScalePlayerDamage`.
- **Parameters:**
  - `ply` (Player): Damaged player
  - `group` (number): Hitgroup
  - `dat` (CTakeDamageInfo)
- **Returns:**
  - `Monarch_PreScalePlayerDamage`: return `true` to fully bypass Monarch default scaling
  - `Monarch_PostScalePlayerDamage`: ignored
- **Realm:** Server

#### Monarch_CanEmitForcedFootstep
Fired before Monarch emits its forced low-speed footstep sound.
- **Parameters:**
  - `ply` (Player)
  - `matType` (number): Surface material ID
  - `velocity` (number)
  - `stepInterval` (number)
  - `trace` (table): Trace result used for material detection
- **Returns:** `false` to suppress emission
- **Realm:** Server

#### Monarch_GetForcedFootstepSound
Override hook for forced footstep playback data.
- **Parameters:**
  - `ply`, `matType`
  - `soundPath` (string)
  - `pitch` (number)
  - `volume` (number)
  - `trace` (table)
- **Returns:** table `{sound=string, pitch=number, volume=number}` to override any value
- **Realm:** Server

#### Monarch_ForcedFootstepPlayed
Fired after forced footstep sound is emitted.
- **Parameters:** `ply`, `matType`, `soundPath`, `pitch`, `volume`, `trace`
- **Returns:** None
- **Realm:** Server

### Money Hooks

#### Monarch_CanGiveMoney / Monarch_CanPlayerGiveMoney
Pre-validation hooks for money transfer requests.
- **Parameters:** `giver`, `target`, `amount`
- **Returns:** `false` to block transfer
- **Realm:** Server

#### Monarch_MoneyTransferred / Monarch_PlayerGaveMoney
Post-transfer hooks fired after a successful transfer.
- **Parameters:**
  - `Monarch_MoneyTransferred`: `giver`, `target`, `amount`, `message`
  - `Monarch_PlayerGaveMoney`: `giver`, `target`, `amount`
- **Returns:** None
- **Realm:** Server

#### Monarch_CanSetMoney / Monarch_MoneySetByAdmin
Hooks for admin-set money operations.
- **Parameters:**
  - `Monarch_CanSetMoney`: `admin`, `target`, `newAmount`
  - `Monarch_MoneySetByAdmin`: `admin`, `target`, `oldAmount`, `newAmount`
- **Returns:** `Monarch_CanSetMoney` can return `false` to block
- **Realm:** Server

#### Monarch_PlayerMoneySet / Monarch_CanChangePlayerMoney / Monarch_PlayerMoneyChanged
Hooks for direct cash changes.
- **Parameters:**
  - `Monarch_PlayerMoneySet`: `ply`, `oldAmount`, `newAmount`
  - `Monarch_CanChangePlayerMoney`: `ply`, `delta`, `currentAmount`
  - `Monarch_PlayerMoneyChanged`: `ply`, `oldAmount`, `newAmount`, `delta`
- **Returns:** `Monarch_CanChangePlayerMoney` can return `false` to block
- **Realm:** Server

#### Monarch_CanChangePlayerBankMoney / Monarch_PlayerBankMoneyChanged
Hooks for bank/carded balance changes.
- **Parameters:** `ply`, `delta`, `currentAmount` (pre-hook) and `ply`, `oldAmount`, `newAmount`, `delta` (post-hook)
- **Returns:** pre-hook can return `false` to block
- **Realm:** Server

#### Monarch_ShouldDropCashOnDeath / Monarch_CashDroppedOnDeath
Hooks around death cash drop.
- **Parameters:**
  - `Monarch_ShouldDropCashOnDeath`: `ply`, `cashAmount`
  - `Monarch_CashDroppedOnDeath`: `ply`, `cashEntity`, `droppedAmount`
- **Returns:**
  - `Monarch_ShouldDropCashOnDeath`: `false` blocks drop, number overrides amount
- **Realm:** Server

### Inventory Hooks

#### Monarch_CanGiveInventoryItem / Monarch_InventoryItemGiven / Monarch_InventoryGiveBlocked
Hooks around `ply:GiveInventoryItem(...)`.
- **Parameters:**
  - `Monarch_CanGiveInventoryItem`: `ply`, `itemClass`, `amount`, `metadata`, `itemDef`
  - `Monarch_InventoryItemGiven`: `ply`, `itemClass`, `actuallyAdded`, `requestedAmount`, `metadata`, `itemDef`, `remaining`
  - `Monarch_InventoryGiveBlocked`: `ply`, `itemClass`, `requestedAmount`, `metadata`, `reason`
- **Returns:**
  - `Monarch_CanGiveInventoryItem`: `false` blocks; number overrides requested amount
- **Realm:** Server

#### Monarch_CanChangeInventoryEquipState / Monarch_InventoryEquipStateChanged
Hooks around equip/unequip operations.
- **Parameters:**
  - `Monarch_CanChangeInventoryEquipState`: `ply`, `slot`, `state`, `item`, `itemDef`, `inventoryTable`
  - `Monarch_InventoryEquipStateChanged`: `ply`, `sourceSlot`, `targetSlot`, `state`, `item`, `itemDef`
- **Returns:** pre-hook can return `false` to block
- **Realm:** Server

#### Monarch_CanDropInventoryItem / Monarch_InventoryItemDropped / Monarch_InventoryItemDropFailed
Hooks around inventory item dropping.
- **Parameters:**
  - `Monarch_CanDropInventoryItem`: `ply`, `slot`, `item`, `itemDef`
  - `Monarch_InventoryItemDropped`: `ply`, `slot`, `item`, `itemDef`, `entity`
  - `Monarch_InventoryItemDropFailed`: `ply`, `slot`, `item`, `itemDef`
- **Returns:** pre-hook can return `false` to block drop
- **Realm:** Server

#### Monarch_CanRunInventoryAction / Monarch_InventoryActionBlocked / Monarch_InventoryActionExecuted
Hooks around custom item actions (`Monarch_Inventory_ExecuteAction`).
- **Parameters:**
  - `Monarch_CanRunInventoryAction`: `ply`, `slot`, `actionID`, `item`, `itemDef`, `actionDef`
  - `Monarch_InventoryActionBlocked`: same + `reason` (`"hook"` or `"canrun"`)
  - `Monarch_InventoryActionExecuted`: same + `success` (bool), `result` (any)
- **Returns:** pre-hook can return `false` to block execution
- **Realm:** Server

### Chat Extension Hooks

#### PlayerSay (Engine Hook)
Used by Monarch to decorate IC chat messages server-side. You can also use it to filter or transform chat text.
- **Parameters:**
  - `ply` (Player): Speaking player
  - `text` (string): Raw chat message
  - `teamChat` (boolean): Team chat flag
- **Returns:** `string` to replace message, or `""` to block, or `nil` to keep default
- **Realm:** Server
- **Example:**
```lua
hook.Add("PlayerSay", "MySchema_TagIC", function(ply, text)
    if string.StartWith(text, "/") or string.StartWith(text, "!") then return end
    return "[IC] " .. text
end)
```

#### OnPlayerChat (Engine Hook)
Used by Monarch on the client to parse `!` and `/` commands and optionally hide command text from chat.
- **Parameters:**
  - `ply` (Player): Speaker
  - `strText` (string): Chat text
  - `bTeam` (boolean): Team chat flag
  - `bDead` (boolean): Dead chat flag
- **Returns:** `true` to hide default chat display, `nil`/`false` to allow
- **Realm:** Client

#### MonarchChatCommandRegistered
Custom Monarch hook fired whenever `Monarch.RegisterChatCommand` registers a command.
- **Parameters:**
  - `cmd` (table): Registered command table (`name`, `aliases`, `adminOnly`, `usage`, etc.)
- **Returns:** None
- **Realm:** Shared
- **Example:**
```lua
hook.Add("MonarchChatCommandRegistered", "MySchema_LogCommands", function(cmd)
    print("Registered command:", cmd.name)
end)
```

#### MonarchCommandChatPrint
Custom Monarch client hook used for rendering command output (e.g., `/help`) when an output font is specified.
- **Parameters:**
  - `fontName` (string): Requested font name
  - `segments` (table): Chat segments passed to `chat.AddText`
- **Returns:** None
- **Realm:** Client
- **Example:**
```lua
hook.Add("MonarchCommandChatPrint", "MySchema_CommandPrinter", function(fontName, segments)
    chat.AddText(Color(100, 200, 255), "[CMD] ")
    chat.AddText(unpack(segments))
end)
```

### Team / Rank Related Hooks

#### OnPlayerChangedTeam (Engine Hook)
Best hook for reacting to team changes (whether changed by `ply:Monarch_SetTeam(...)` or direct `ply:SetTeam(...)`).
- **Parameters:**
  - `ply` (Player): Player whose team changed
  - `oldTeam` (number): Previous team ID
  - `newTeam` (number): New team ID
- **Returns:** None
- **Realm:** Server
- **Example:**
```lua
hook.Add("OnPlayerChangedTeam", "MySchema_TeamChangeNotice", function(ply, oldTeam, newTeam)
    if not IsValid(ply) then return end
    ply:Notify("You changed teams: " .. tostring(oldTeam) .. " -> " .. tostring(newTeam))
end)
```

#### Monarch_RanksUpdated
Custom Monarch hook fired client-side when rank config sync data is received.
- **Parameters:** None
- **Returns:** None
- **Realm:** Client
- **Example:**
```lua
hook.Add("Monarch_RanksUpdated", "MySchema_RefreshRankUI", function()
    print("Ranks config updated from server")
    -- Refresh rank-dependent UI here
end)
```

### Sync / Data Hooks

#### CreateSyncVars
Custom Monarch shared hook fired after built-in sync vars are registered, intended for registering additional sync vars.
- **Parameters:** None
- **Returns:** None
- **Realm:** Shared

#### OnSyncUpdate
Custom Monarch client hook fired when a sync var is set/updated/removed.
- **Parameters:**
  - `varID` (number): Sync variable ID
  - `targetID` (number): Target entity index
  - `newValue` (any): Updated value (may be `nil` when var is removed)
- **Returns:** None
- **Realm:** Client

### Additional Utility Hooks

#### DatabaseConnected
Fired when the Monarch MySQL connection succeeds.
- **Parameters:** None
- **Returns:** None
- **Realm:** Shared (typically server)
- **Example:**
```lua
hook.Add("DatabaseConnected", "MySchema_DbReady", function()
    print("Database connected, safe to run startup queries.")
end)
```

#### DatabaseConnectionFailed
Fired when the MySQL connection fails.
- **Parameters:**
  - `errorText` (string): Driver/connection error string
- **Returns:** None
- **Realm:** Shared (typically server)
- **Example:**
```lua
hook.Add("DatabaseConnectionFailed", "MySchema_DbFailLog", function(errorText)
    print("DB connection failed:", errorText)
end)
```

#### Monarch_SettingChanged
Fired client-side after `Monarch.SetSetting(...)` changes the effective setting value.
- **Parameters:**
  - `name` (string): Setting key
  - `newEffectiveValue` (any): New resolved/effective value
  - `oldEffectiveValue` (any): Previous resolved/effective value
  - `newValue` (any): Raw incoming value that was set
- **Returns:** None
- **Realm:** Client

#### MonarchThemeChanged
Fired client-side when `Monarch.Theme.Set(name)` changes theme.
- **Parameters:**
  - `name` (string): New theme name
- **Returns:** None
- **Realm:** Client

#### PostLoadFonts
Fired client-side after Monarch core fonts are created, useful for defining dependent custom fonts.
- **Parameters:** None
- **Returns:** None
- **Realm:** Client
- **Example:**
```lua
hook.Add("PostLoadFonts", "MySchema_CreateFonts", function()
    surface.CreateFont("MySchema_Title", {
        font = "Arial",
        size = 28,
        weight = 700,
        antialias = true
    })
end)
```

#### DisplayMenuMessages
Fired when main menu is first built so addons can add startup messages/popups.
- **Parameters:**
  - `menu` (Panel): Main menu panel instance
- **Returns:** None
- **Realm:** Client

#### OnMenuFirstLoad
Fired alongside menu bootstrapping after main menu creation.
- **Parameters:**
  - `menu` (Panel): Main menu panel instance
- **Returns:** None
- **Realm:** Client

#### PostReloadToolsMenu
Fired when splash/loading flow transitions into the main menu.
- **Parameters:** None
- **Returns:** None
- **Realm:** Client

#### SetupInventoryModel
Fired while constructing the inventory character model preview.
- **Parameters:**
  - `panel` (Panel): Inventory panel context
  - `ent` (Entity): Clientside model preview entity
- **Returns:** None
- **Realm:** Client

#### Monarch_ZoneChanged
Fired client-side when active zone changes.
- **Parameters:**
  - `zoneId` (string/nil): New active zone ID, or `nil` when leaving zones
- **Returns:** None
- **Realm:** Client
- **Example:**
```lua
hook.Add("Monarch_ZoneChanged", "MySchema_ZoneNotify", function(zoneId)
    if zoneId then
        chat.AddText(Color(120, 220, 120), "Entered zone: ", Color(255, 255, 255), zoneId)
    else
        chat.AddText(Color(220, 120, 120), "Left zone")
    end
end)
```

#### Monarch_OnTryInventory
Fired client-side when the player presses down the binded inventory key
- **Parameters:**
  - `ply` (Player): The local player
- **Returns:** None
- **Realm:** Client
- **Example:**
```lua
hook.Add("Monarch_OnTryInventory", "MySchema_InvModify", function(ply)
    if ply:IsValid() then return false -- never allow the inventory to open!
end)
```

### Notes

- Prefer `OnCharacterActivated` for "character loaded" logic in base Monarch.
- `Monarch_CharLoaded` is emitted during character activation (alongside `OnCharacterActivated`) for compatibility with existing addons.
- For team/rank side effects, rely on `OnPlayerChangedTeam` and `Monarch_RanksUpdated` rather than patching core files.


#### Monarch.RegisterChatType(uniqueID, fontType, textColor, canSeeFn)
Register or overwrite a chat type.
- **Parameters:**
  - `uniqueID` (string): Unique type ID (normalized lowercase)
  - `fontType` (string): Font name used by typed dispatch
  - `textColor` (Color): Message color used by typed dispatch
  - `canSeeFn` (function): Visibility callback `function(listener, speaker, message, context) -> boolean`
- **Returns:** `true, chatTypeTable` on success, `false, reason` on failure
- **Realm:** Shared

#### Monarch.GetChatType(uniqueID)
Get a registered chat type definition.
- **Returns:** table/nil
- **Realm:** Shared

#### Monarch.SendChatMessage(chatType, message)
Convenience sender for message-only output.
- **Server behavior:** broadcasts typed message to all players
- **Client behavior:** prints local typed message
- **Returns:** `true` on success, or `false, "unknown-chat-type"`
- **Realm:** Shared

#### Monarch.GetChatTypeRecipients(uniqueID, speaker, message, context)
Resolve recipients from a chat type visibility callback.
- **Returns:** array of players (always includes speaker fallback if valid)
- **Realm:** Server

#### Monarch.SendChatType(uniqueID, speaker, prefixColor, prefix, userColor, userData, message, recipients)
Low-level typed chat sender used by framework systems.
- **Returns:** `true` on success, or `false, "unknown-chat-type"`
- **Realm:** Server

### IC Chat Decorator API

#### Monarch.RegisterICChatDecorator(id, fn)
Register a decorator that can add prefixes/suffixes to IC speech.

#### Monarch.BuildICChatDecorations(ply, message)
Build merged prefix/suffix from all decorators.

### Item Creation (`Monarch.RegisterItem`)

Register items with:

```lua
Monarch.RegisterItem({
  UniqueID = "example_item",
  Name = "Example Item",
  Description = "An example.",
  Model = "models/props_junk/PopCan01a.mdl",
  Weight = 1
})
```

#### Core attributes
- `UniqueID` (string, required): unique item key.
- `Name` (string): display name.
- `Description` (string): UI description.
- `Model` (string): model path.
- `Weight` (number): inventory weight value.
- `CanSell` (bool): sellability.
- `CanStack` (bool): stack behavior.
- `Illegal`/`illegal` (bool): contraband flag.
- `restricted`/`Restricted` (bool): restriction flag (used by vendor eligibility).
- `Stats` (string): extra stat text.
- `UseName`, `EquipName` (string): action labels.
- `UseTime` (number): use duration.
- `Workbar` (string): progress label.

#### Craft/dismantle attributes
- `CraftTime` (number), `CraftSound` (string): stored in `Monarch.Inventory.CraftInfo`.
- `Dismantle` (table of item class strings), `DismantleSound` (string).

#### Weapon/attachment attributes
- `WeaponClass` (string): auto on-equip weapon handling.
- `WeaponOverrideClip` (number): clip override.
- `ShouldRemoveOnEquip` (bool): remove item after equip.
- `AttachmentClass` (string): attachment equip flow.

#### Durability attributes
- `StartingDurability` / `DurabilityStart` / `DefaultDurability` (number 0-100).

#### Item callbacks
- `OnUse(ply, slot, itemData, def)`
- `CanEquip(ply)`
- `OnEquip(ply, itemClass, uid)`
- `UnEquip(ply, itemClass, uid)`
- `SetDurability(itemData, value)`
- `GetDurability(itemData)`
- `OnDurabilityDrained(ply, slot, itemData, context)`
- `WeaponUsed(ply, slot, itemData, weapon, context)`

### Item Vendor Creation (`Monarch.Vendors`)

```lua
Monarch.Vendors["vendor_id"] = {
  name = "Vendor Name",
  desc = "Vendor Description",
  model = "models/Humans/Group01/male_02.mdl",
  team = TEAM_CITIZEN,
  CanBuy = function(ply, vendorEnt, item) return true end,
  CustomCheck = function(ply, vendorEnt, item) return true end,
  items = {
    {
      class = "item_class",
      name = "Item Name",
      desc = "Item Desc",
      model = "models/...mdl",
      price = 50,
      sellPrice = 25,
      stock = 100
    }
  }
}
```

#### Vendor-level attributes
- `name`, `desc`, `model` (string)
- `team` (number): required team on entity use
- `CanBuy`/`canBuy` (function)
- `CustomCheck`/`customCheck` (function)
- `items` (array)

#### Vendor item attributes
- `class` (string, required)
- `name`, `desc`, `model` (string)
- `price` (number)
- `sellPrice` (number; `<= 0` means not sellable)
- `stock` (number; `> 0` enables stock tracking)
- `constrained` (bool)
- `CanBuy`/`canBuy` (function)
- `CustomCheck`/`customCheck` (function)
- `canPurchase` (function)
- `requiredWhitelistTeam` (number)
- `requiredWhitelistLevel` (number)
- `restricted`/`Restricted` (bool)
- `allowRestricted` (bool)
- `restrictionCheck` (function)

### Rank Vendor Creation (`Monarch.RankVendors`)

```lua
Monarch.RankVendors["terminal_id"] = {
  name = "Rank Terminal",
  desc = "Join role tracks",
  model = "models/props_combine/breenconsole.mdl",
  team = TEAM_CP,
  CanBuy = function(ply, vendorEnt, rankDef, silent) return true end,
  ranks = {
    {
      id = "rank_id",
      name = "Rank Name",
      desc = "Rank Desc",
      team = TEAM_CP,
      model = "models/...mdl",
      whitelistLevel = 1,
      respawn = false,
      onBecome = function(ply) end
    }
  }
}
```

#### Rank-vendor attributes
- `name`, `desc`, `model` (string)
- `team` (number)
- `CanBuy` (function)
- `ranks` (array)

#### Rank entry attributes
- `id` (string, required)
- `name`, `desc`, `model` (string)
- `price` (number; for UI/custom logic)
- `team` (number)
- `group` (string), `grouprank` (string)
- `respawn` (bool)
- `onBecome(ply)` (function)
- `CanBuy(ply, vend, rank, silent)` (function)
- `CustomCheck`/`customCheck` (function)
- `canPurchase` (function)
- `whitelistLevel` (number)
- `requiredWhitelistTeam` (number)
- `requiredWhitelistLevel` (number)
- `whitelist` (table with optional `steamids`, `usergroups`, `teams`)
- `lockedReason` (string)

### Vehicle Vendor Creation (`Monarch.VehicleVendors`)

```lua
Monarch.VehicleVendors["vehicle_vendor_id"] = {
  name = "Motor Depot",
  desc = "Purchase and spawn vehicles",
  model = "models/Humans/Group01/male_02.mdl",
  team = TEAM_CITIZEN,
  vehicles = {
    {
      class = "vehicle_class",
      name = "Vehicle Name",
      desc = "Vehicle Desc",
      model = "models/...mdl",
      price = 1000,
      CustomCheck = function(ply, vend, veh) return true end
    }
  }
}
```

#### Vehicle-vendor attributes
- `name`, `desc`, `model` (string)
- `team` (number)
- `vehicles` (array)

#### Vehicle entry attributes
- `class` (string, required)
- `name`, `desc`, `model` (string)
- `price` (number)
- `CustomCheck(ply, vendorEnt, vehicleData)` (function)

### Persistence Fields Used by Vendor Editors

Saved vendor records include:
- `class`, `uid`
- `pos` (`x,y,z`), `ang` (`p,y,r`)
- `model`
- `vendorID`
- `name`, `desc`
- `team` (item/vehicle/rank vendors)
- `teams` (rank vendor allowed-team string)
