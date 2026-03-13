# Monarch Framework - Content Creation Guide


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
