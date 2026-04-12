# Monarch Framework - Admin, Whitelist, and Hooks


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
