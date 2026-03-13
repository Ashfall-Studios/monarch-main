# Monarch Framework - Gameplay & Item Systems


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

