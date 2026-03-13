meta = FindMetaTable("Player")
INV_CONFISCATED = 0
INV_PLAYER = 1
INV_STORAGE = 2
local STORAGE_SLOT_END = 200

Monarch.Inventory = Monarch.Inventory or {}
Monarch.Inventory.Data = Monarch.Inventory.Data or {}

if SERVER then
	util.AddNetworkString("Monarch_Inventory_Update")
	util.AddNetworkString("Monarch_Inventory_Request")
	util.AddNetworkString("Monarch_Inventory_ExecuteAction")
end

hook.Add("DatabaseConnected", "Monarch_Inventory_TableInit", function()
	local sql = [[
		CREATE TABLE IF NOT EXISTS `monarch_inventory` (
			`id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
			`uniqueid` VARCHAR(128) NOT NULL,
			`ownerid` INT UNSIGNED NOT NULL,
			`storagetype` TINYINT UNSIGNED NOT NULL DEFAULT 1,
			`slot` INT UNSIGNED NOT NULL DEFAULT 1,
			`amount` INT UNSIGNED NOT NULL DEFAULT 1,
			`equipped` TINYINT(1) NOT NULL DEFAULT 0,
			`clip` INT NOT NULL DEFAULT 0,
			`durability` INT UNSIGNED NOT NULL DEFAULT 100,
			PRIMARY KEY (`id`),
			INDEX `idx_owner` (`ownerid`),
			INDEX `idx_uniqueid` (`uniqueid`),
			INDEX `idx_owner_store` (`ownerid`, `storagetype`),
			INDEX `idx_owner_slot` (`ownerid`, `slot`)
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
	]]
	if mysql and mysql.RawQuery then
		mysql:RawQuery(sql, function() end)

		local alters = {
			[[ALTER TABLE `monarch_inventory` ADD COLUMN IF NOT EXISTS `slot` INT UNSIGNED NOT NULL DEFAULT 1 AFTER `storagetype`;]],
			[[ALTER TABLE `monarch_inventory` ADD COLUMN IF NOT EXISTS `amount` INT UNSIGNED NOT NULL DEFAULT 1 AFTER `slot`;]],
			[[ALTER TABLE `monarch_inventory` ADD COLUMN IF NOT EXISTS `equipped` TINYINT(1) NOT NULL DEFAULT 0 AFTER `amount`;]],
			[[ALTER TABLE `monarch_inventory` ADD COLUMN IF NOT EXISTS `clip` INT NOT NULL DEFAULT 0 AFTER `equipped`;]],
			[[ALTER TABLE `monarch_inventory` ADD COLUMN IF NOT EXISTS `durability` INT UNSIGNED NOT NULL DEFAULT 100 AFTER `clip`;]],
			[[ALTER TABLE `monarch_inventory` ADD COLUMN IF NOT EXISTS `constrained` TINYINT(1) NOT NULL DEFAULT 0 AFTER `clip`;]],
			[[ALTER TABLE `monarch_inventory` ADD INDEX IF NOT EXISTS `idx_owner_slot` (`ownerid`, `slot`);]],
		}
		for _, stmt in ipairs(alters) do
			mysql:RawQuery(stmt, function() end)
		end
	end
end)

local invDebug = CreateConVar("monarch_inv_debug", "0", FCVAR_ARCHIVE, "Enable inventory debug logging (0/1)")
local autosaveCvar = CreateConVar("monarch_inv_autosave_sec", "180", FCVAR_ARCHIVE, "Autosave interval for player inventories (seconds)")

timer.Create("Monarch_Inventory_Autosave", autosaveCvar:GetInt(), 0, function()
	for _, ply in player.Iterator() do
		if IsValid(ply) then
			local charID = (ply.MonarchActiveChar and ply.MonarchActiveChar.id) or ply.MonarchID or ply.MonarchLastCharID
			if not ply._invLoaded then continue end
			if charID and Monarch and Monarch.Inventory and Monarch.Inventory.SaveForOwner then
				Monarch.Inventory.SaveForOwner(ply, charID)
			end
		end
	end
end)

local function IsConstrainedItem(item)
	if not istable(item) then return false end
	if item.constrained == true then return true end
	return (tonumber(item.constrained) or 0) ~= 0
end

local function BeginInventoryTransition(ply, ownerid)
	if not IsValid(ply) then return nil, nil end
	local sid = ply:SteamID64()
	local seq = (tonumber(ply._invLoadSeq) or 0) + 1
	ply._invLoadSeq = seq
	ply._invLoaded = false
	ply.beenInvSetup = false
	ply._equipRestoreDone = false

	timer.Remove("Monarch_RestoreEquips_DB_" .. sid)
	timer.Remove("Monarch_RestoreEquips_" .. sid)

	Monarch.Inventory = Monarch.Inventory or {}
	Monarch.Inventory.Data = Monarch.Inventory.Data or {}
	Monarch.Inventory.Data[sid] = {}
	if ownerid then
		Monarch.Inventory.Data[ownerid] = Monarch.Inventory.Data[ownerid] or {}
		Monarch.Inventory.Data[ownerid][1] = {}
	end

	net.Start("Monarch_Inventory_Update")
		net.WriteTable({})
	net.Send(ply)

	return seq, sid
end

function Monarch.Inventory.LoadForOwner(ply, ownerid, onLoaded)
	if not IsValid(ply) or not ownerid then return end
	local loadSeq, sid = BeginInventoryTransition(ply, ownerid)
	if not loadSeq then return end
	local q = mysql:Select("monarch_inventory")
	q:Select("uniqueid")
	q:Select("storagetype")
	q:Select("slot")
	q:Select("amount")
	q:Select("equipped")
	q:Select("clip")
	q:Select("durability")
	q:Select("constrained")
	q:Where("ownerid", ownerid)
	q:OrderByAsc("slot")
	q:Callback(function(rows)
		if not IsValid(ply) then return end
		if ply._invLoadSeq ~= loadSeq then return end
		local inv = {}
		local maxSlots = 30
		local function getSlotLimit(storageType)
			if tonumber(storageType or 1) == INV_STORAGE then
				return STORAGE_SLOT_END
			end
			return maxSlots
		end
		if type(rows) == "table" and #rows > 0 then
			for _, r in ipairs(rows) do
				local cls = tostring(r.uniqueid or "")
				local isConstrained = (tonumber(r.constrained) or 0) ~= 0
				local st = tonumber(r.storagetype or 1) or 1
				local slot = math.floor(tonumber(r.slot or 0) or 0)
				local maxAllowed = getSlotLimit(st)
				if slot < 1 or slot > maxAllowed then slot = 0 end
				if cls ~= "" and slot > 0 and not isConstrained then
					inv[slot] = {
						id = cls,
						class = cls,
						amount = math.max(1, math.floor(tonumber(r.amount or 1) or 1)),
						equipped = (tonumber(r.equipped) or 0) ~= 0,
						restricted = false,
						constrained = false,
						storagetype = st,
						clip = math.floor(tonumber(r.clip or 0) or 0),
						durability = math.Clamp(math.floor(tonumber(r.durability or 100) or 100), 0, 100),
					}
				end
			end
		end
		if table.Count(inv) == 0 then
			local json = ply:GetPData("MonarchInventory_" .. tostring(ownerid), "[]")
			local raw = util.JSONToTable(json) or {}
			if istable(raw) and raw.__charid and raw.items then
				raw = raw.items
			end

			if istable(raw) then
				if #raw > 0 then
					for _, item in ipairs(raw) do
						local cls = tostring(item.class or item.id or "")
						local isConstrained = IsConstrainedItem(item)
						local st = tonumber(item.storagetype or 1) or 1
						local slot = math.floor(tonumber(item.slot or 0) or 0)
						local maxAllowed = getSlotLimit(st)
						if cls ~= "" and slot > 0 and slot <= maxAllowed and not isConstrained then
							inv[slot] = {
								id = cls,
								class = cls,
								amount = math.max(1, math.floor(tonumber(item.amount or 1) or 1)),
								equipped = item.equipped or false,
								restricted = item.restricted or false,
								storagetype = st,
								clip = math.floor(tonumber(item.clip or 0) or 0),
								durability = math.Clamp(math.floor(tonumber(item.durability or 100) or 100), 0, 100),
							}
						end
					end
				else
					for slot, item in pairs(raw) do
						if istable(item) then
							local cls = tostring(item.class or item.id or "")
							local isConstrained = IsConstrainedItem(item)
							local st = tonumber(item.storagetype or 1) or 1
							local s = math.floor(tonumber(item.slot or slot or 0))
							local maxAllowed = getSlotLimit(st)
							if cls ~= "" and s > 0 and s <= maxAllowed and not isConstrained then
								inv[s] = {
									id = cls,
									class = cls,
									amount = math.max(1, math.floor(tonumber(item.amount or 1) or 1)),
									equipped = item.equipped or false,
									restricted = item.restricted or false,
									storagetype = st,
									clip = math.floor(tonumber(item.clip or 0) or 0),
									durability = math.Clamp(math.floor(tonumber(item.durability or 100) or 100), 0, 100),
								}
							end
						end
					end
				end
			end
		end

		local equippedItems = {}
		for slot = 1, 20 do
			if inv[slot] and inv[slot].equipped then
				table.insert(equippedItems, {slot = slot, item = inv[slot]})
			end
		end

		if #equippedItems > 0 then
			local nextEquipSlot = 21
			for _, data in ipairs(equippedItems) do
				if nextEquipSlot <= 30 then
					inv[nextEquipSlot] = table.Copy(data.item)
					inv[nextEquipSlot].equipped = true
					inv[data.slot] = nil
					nextEquipSlot = nextEquipSlot + 1
				end
			end
		end

		Monarch.Inventory.Data = Monarch.Inventory.Data or {}
		Monarch.Inventory.Data[sid] = inv
		ply.MonarchID = ownerid
		Monarch.Inventory.Data[ownerid] = Monarch.Inventory.Data[ownerid] or {}
		Monarch.Inventory.Data[ownerid][1] = {}
		for i = 1, maxSlots do
			local item = inv[i]
			if item then
				Monarch.Inventory.Data[ownerid][1][i] = table.Copy(item)
			end
		end
		ply.beenInvSetup = true

		net.Start("Monarch_Inventory_Update")
			net.WriteTable(inv)
		net.Send(ply)

		ply._invLoaded = true

		if onLoaded and type(onLoaded) == "function" then
			onLoaded(ply, inv)
		end

		if not ply._equipRestoreDone then
			local sid = ply:SteamID64()
			local maxSlots = MONARCH_INV_MAX_SLOTS or 20
			local tries = 0
			local timerName = "Monarch_RestoreEquips_DB_" .. sid
			timer.Create(timerName, 0.25, 40, function()
				if not IsValid(ply) then timer.Remove(timerName) return end
				if ply._invLoadSeq ~= loadSeq then timer.Remove(timerName) return end
				tries = tries + 1
				local flat = Monarch.Inventory.Data and Monarch.Inventory.Data[sid]
				if not flat then return end
				local defs = Monarch.Inventory and Monarch.Inventory.Items
				if not defs or table.Count(defs) == 0 then
					return
				end
				for slot = 1, maxSlots do
					local item = flat[slot]
					if item and istable(item) and item.equipped then
						local class = item.class or item.id
						if class and class ~= "" then
							local def
							if Monarch.Inventory.ItemsRef and Monarch.Inventory.ItemsRef[class] then
								def = Monarch.Inventory.Items and Monarch.Inventory.Items[Monarch.Inventory.ItemsRef[class]]
							else
								def = Monarch.Inventory.Items and Monarch.Inventory.Items[class]
							end
							if def then
								if type(def.OnUse) == "function" then
									local ok, res = pcall(def.OnUse, ply, slot, item, def)
									if (not ok) or (res == nil or res == false) then
										ok, res = pcall(def.OnUse, def, ply, item, slot)
									end
									if ok and istable(res) then
										if res.equipped == true then item.equipped = true end
										if res.unequipped == true then item.equipped = false end
										if res.remove == true then flat[slot] = nil end
									end
								end
								if def.WeaponClass then
									if not ply:HasWeapon(def.WeaponClass) then
										ply:Give(def.WeaponClass)
									end
									local wep = ply:GetWeapon(def.WeaponClass)
									if IsValid(wep) and item.clip and isnumber(item.clip) and wep.SetClip1 then
										wep:SetClip1(item.clip)
									end
									item.equipped = true
								end
							end
						end
					end
				end
				local saveCharID = (ply.MonarchActiveChar and ply.MonarchActiveChar.id) or ply.MonarchID or ply.MonarchLastCharID or ownerid
				if saveCharID and Monarch and Monarch.Inventory and Monarch.Inventory.SaveForOwner then
					Monarch.Inventory.SaveForOwner(ply, saveCharID, flat)
				end
				if Monarch and Monarch.SaveInventoryPData then Monarch.SaveInventoryPData(ply, flat) end
				net.Start("Monarch_Inventory_Update")
					net.WriteTable(flat)
				net.Send(ply)

				ply._equipRestoreDone = true
				timer.Remove(timerName)
			end)
		end
	end)
	q:Execute()
end
function Monarch.Inventory.SaveForOwner(ply, ownerid, inv)
	if not IsValid(ply) or not ownerid then return end
	inv = inv 
		or (Monarch.Inventory.Data and Monarch.Inventory.Data[ownerid] and Monarch.Inventory.Data[ownerid][1]) 
		or (Monarch.Inventory.Data and Monarch.Inventory.Data[ply:SteamID64()]) 
		or {}

	local slots = {}
	for k, v in pairs(inv) do
		local slot = tonumber(k)
		if slot and istable(v) then
			slot = math.floor(slot)
			if slot > 0 and not IsConstrainedItem(v) then table.insert(slots, slot) end
		end
	end
	table.sort(slots)
	local del = mysql:Delete("monarch_inventory")
	del:Where("ownerid", ownerid)
	del:Callback(function()
		for _, slot in ipairs(slots) do
			local item = inv[slot]
			local cls = item and (item.class or item.id)
			if cls and cls ~= "" then
				local ins = mysql:Insert("monarch_inventory")
				ins:Insert("uniqueid", cls)
				ins:Insert("ownerid", ownerid)
				ins:Insert("storagetype", tonumber(item.storagetype or 1) or 1)
				ins:Insert("slot", slot)
				ins:Insert("amount", math.max(1, math.floor(tonumber(item.amount or 1) or 1)))
				ins:Insert("equipped", item.equipped and 1 or 0)
				ins:Insert("clip", math.floor(tonumber(item.clip or 0) or 0))
				ins:Insert("durability", math.Clamp(math.floor(tonumber(item.durability or 100) or 100), 0, 100))
				ins:Insert("constrained", item.constrained and 1 or 0)
				ins:Execute()
			end
		end
	end)
	del:Execute()
end

function Monarch.SaveInventoryPData(ply, invOverride)
	if not IsValid(ply) then return end
	local charID = (ply.MonarchActiveChar and ply.MonarchActiveChar.id) or ply.MonarchLastCharID
	if not charID then return end

	Monarch.Inventory = Monarch.Inventory or {}
	Monarch.Inventory.Data = Monarch.Inventory.Data or {}

	local sid = ply:SteamID64()
	local flat = {}
	local maxSlots = MONARCH_INV_MAX_SLOTS or 20

	local inv = invOverride
	if not inv then
		local charStore = Monarch.Inventory.Data[charID]
		if charStore and charStore[1] then
			inv = charStore[1]
		else
			inv = Monarch.Inventory.Data[sid] or {}
		end
	end

	for slot, item in pairs(inv) do
		if istable(item) then
			if IsConstrainedItem(item) then continue end
			local cls = tostring(item.class or item.id or "")
			local s = tonumber(slot)
			if cls ~= "" and s and s > 0 and s <= maxSlots then
				s = math.floor(s)
				table.insert(flat, {
					slot = s,
					id = cls,
					class = cls,
					amount = math.max(1, math.floor(tonumber(item.amount or 1) or 1)),
					equipped = item.equipped or false,
					restricted = item.restricted or false,
					constrained = item.constrained or false,
					storagetype = tonumber(item.storagetype or 1) or 1,
					clip = math.floor(tonumber(item.clip or 0) or 0),
					durability = math.Clamp(math.floor(tonumber(item.durability or 100) or 100), 0, 100),
				})
			end
		end
	end

	local json = util.TableToJSON(flat) or "[]"
	ply:SetPData("MonarchInventory_" .. tostring(charID), json)
end

function Monarch.LoadInventoryForChar(ply, charID, onLoaded)
	if not IsValid(ply) or not charID then return end
	local loadSeq, sid = BeginInventoryTransition(ply, charID)
	if not loadSeq then return end
	Monarch.Inventory = Monarch.Inventory or {}
	Monarch.Inventory.Data = Monarch.Inventory.Data or {}

	local json = ply:GetPData("MonarchInventory_" .. tostring(charID), "[]")
	local raw = util.JSONToTable(json) or {}
	local maxSlots = MONARCH_INV_MAX_SLOTS or 20
	local function getSlotLimit(storageType)
		if tonumber(storageType or 1) == INV_STORAGE then
			return STORAGE_SLOT_END
		end
		return maxSlots
	end

	local function addFlat(dst, slot, item)
		local cls = tostring(item.class or item.id or "")
		if IsConstrainedItem(item) then return end
		local st = tonumber(item.storagetype or 1) or 1
		local maxAllowed = getSlotLimit(st)
		if not slot or slot < 1 or slot > maxAllowed or cls == "" then return end
		slot = math.floor(slot)
		table.insert(dst, {
			slot = slot,
			id = cls,
			class = cls,
			amount = math.max(1, math.floor(tonumber(item.amount or 1) or 1)),
			equipped = item.equipped or false,
			restricted = item.restricted or false,
			constrained = item.constrained or false,
			storagetype = st,
			clip = math.floor(tonumber(item.clip or 0) or 0),
			durability = math.Clamp(math.floor(tonumber(item.durability or 100) or 100), 0, 100),
		})
	end

	if istable(raw) and raw.__charid and raw.items then
		raw = raw.items
	end

	local flat = {}
	if istable(raw) then
		if #raw > 0 then
			for _, item in ipairs(raw) do
				addFlat(flat, tonumber(item.slot or 0), item)
			end
		else
			for slot, item in pairs(raw) do
				addFlat(flat, tonumber(item.slot or slot), item)
			end
		end
	end
	Monarch.Inventory.Data[sid] = {}
	for _, item in ipairs(flat) do
		local cls = tostring(item.class or item.id or "")
		local slot = math.floor(tonumber(item.slot or 0) or 0)
		local maxAllowed = getSlotLimit(item.storagetype)
		if slot < 1 or slot > maxAllowed then slot = 0 end
		if cls ~= "" and slot > 0 then
			Monarch.Inventory.Data[sid][slot] = {
				id = cls,
				class = cls,
				amount = math.max(1, math.floor(tonumber(item.amount or 1) or 1)),
				equipped = item.equipped or false,
				restricted = item.restricted or false,
				constrained = item.constrained or false,
				storagetype = tonumber(item.storagetype or 1) or 1,
				clip = math.floor(tonumber(item.clip or 0) or 0),
			}
		end
	end

	ply.MonarchID = charID
	Monarch.Inventory.Data[ply.MonarchID] = Monarch.Inventory.Data[ply.MonarchID] or {}
	Monarch.Inventory.Data[ply.MonarchID][1] = {}
	for i = 1, maxSlots do
		local item = Monarch.Inventory.Data[sid][i]
		if item then
			Monarch.Inventory.Data[ply.MonarchID][1][i] = table.Copy(item)
		end
	end

	ply.beenInvSetup = true

	net.Start("Monarch_Inventory_Update")
		net.WriteTable(Monarch.Inventory.Data[sid])
	net.Send(ply)

	if ply._invLoadSeq ~= loadSeq then return end
	ply._invLoaded = true

	if onLoaded and type(onLoaded) == "function" then
		onLoaded(ply, Monarch.Inventory.Data[sid])
	end

	if ply._equipRestoreDone then return end
	local tries = 0
	local timerName = "Monarch_RestoreEquips_" .. sid
	timer.Create(timerName, 0.25, 40, function()
		if not IsValid(ply) then timer.Remove(timerName) return end
		if ply._invLoadSeq ~= loadSeq then timer.Remove(timerName) return end
		tries = tries + 1
		local inv = Monarch.Inventory.Data[sid]
		if not inv then return end
		local defs = Monarch.Inventory and Monarch.Inventory.Items
		if not defs or table.Count(defs) == 0 then
			return
		end
		for slot = 1, maxSlots do
			local item = inv[slot]
			if item and istable(item) and item.equipped then
				local class = item.class or item.id
				if not class or class == "" then continue end
				local def
				if Monarch.Inventory.ItemsRef and Monarch.Inventory.ItemsRef[class] then
					def = Monarch.Inventory.Items and Monarch.Inventory.Items[Monarch.Inventory.ItemsRef[class]]
				else
					def = Monarch.Inventory.Items and Monarch.Inventory.Items[class]
				end
				if def then
					if type(def.OnUse) == "function" then
						local ok, res = pcall(def.OnUse, ply, slot, item, def)
						if (not ok) or (res == nil or res == false) then
							ok, res = pcall(def.OnUse, def, ply, item, slot)
						end
						if ok and istable(res) then
							if res.equipped == true then item.equipped = true end
							if res.unequipped == true then item.equipped = false end
							if res.remove == true then inv[slot] = nil end
						end
					end
					if def.WeaponClass then
						if not ply:HasWeapon(def.WeaponClass) then
							ply:Give(def.WeaponClass)
						end
						local wep = ply:GetWeapon(def.WeaponClass)
						if IsValid(wep) and item.clip and isnumber(item.clip) and wep.SetClip1 then
							wep:SetClip1(item.clip)
						end
						item.equipped = true
					end
				end
			end
		end
		local charIDSave = (ply.MonarchActiveChar and ply.MonarchActiveChar.id) or ply.MonarchID or ply.MonarchLastCharID or charID
		if charIDSave and Monarch and Monarch.Inventory and Monarch.Inventory.SaveForOwner then
			Monarch.Inventory.SaveForOwner(ply, charIDSave, inv)
		end
		if Monarch and Monarch.SaveInventoryPData then Monarch.SaveInventoryPData(ply, inv) end
		net.Start("Monarch_Inventory_Update")
			net.WriteTable(inv)
		net.Send(ply)

		ply._equipRestoreDone = true
		timer.Remove(timerName)
	end)
end

do
	local meta = FindMetaTable("Player")
	function meta:SyncInventory()
		local sid = self:SteamID64()
		Monarch.Inventory = Monarch.Inventory or {}
		Monarch.Inventory.Data = Monarch.Inventory.Data or {}
		local flat = Monarch.Inventory.Data[sid] or {}
		net.Start("Monarch_Inventory_Update")
			net.WriteTable(flat)
		net.Send(self)
	end
end

hook.Add("PlayerDisconnected", "Monarch_SaveInv_OnDisconnect", function(ply)
	if not IsValid(ply) then return end
	local charID = (ply.MonarchActiveChar and ply.MonarchActiveChar.id) or ply.MonarchLastCharID or ply.MonarchID
	if charID and Monarch and Monarch.Inventory and Monarch.Inventory.SaveForOwner then
		Monarch.Inventory.SaveForOwner(ply, charID)
	end
end)
function Monarch.Inventory.DBAddItem(ownerid, class, storageType)
	local query = mysql:Insert("monarch_inventory")
	query:Insert("uniqueid", class)
	query:Insert("ownerid", ownerid)
	query:Insert("storagetype", storageType or 1)
	query:Execute()
end
function Monarch.Inventory.DBRemoveItem(ownerid, class, storetype, limit)
	local query = mysql:Delete("monarch_inventory")
	query:Where("ownerid", ownerid)
	query:Where("uniqueid", class)
	query:Where("storagetype", storetype or 1)
	query:Limit(limit or 1)

	query:Execute()
end
function Monarch.Inventory.DBClearInventory(ownerid, storageType)
	local query = mysql:Delete("monarch_inventory")
	query:Where("ownerid", ownerid)
	query:Where("storagetype", storageType or 1)
	query:Execute()
end
function Monarch.Inventory.DBUpdateStoreType(ownerid, class, limit, oldType, newType)
  limit = limit or 1

  local safeClass = mysql:Escape(class)

  local sql = string.format([[
    UPDATE `monarch_inventory`
       SET `storagetype` = %d
     WHERE `ownerid` = %d
       AND `uniqueid` = '%s'
       AND `storagetype` = %d
     LIMIT %d;
  ]],
    newType,
    ownerid,
    safeClass,
    oldType,
    limit
  )

    mysql:RawQuery(sql, function(result, status, lastid) end)
end
function Monarch.Inventory.SpawnItem(itemClass, pos)
	local itemKey = Monarch.Inventory.ItemsRef[itemClass]
	local itemData = itemKey and Monarch.Inventory.Items[itemKey]
	if not itemData then
		print("[Monarch] SpawnItem failed: itemData not found for class " .. tostring(itemClass))
		return nil
	end
	print("[Monarch] Attempting to spawn entity 'monarch_item' for class " .. tostring(itemClass))
	local ent = ents.Create("monarch_item")
	if not IsValid(ent) then
		print("[Monarch] SpawnItem failed: entity creation failed for class " .. tostring(itemClass))
		return nil
	end
	print("[Monarch] Entity 'monarch_item' created: " .. tostring(ent))
	ent:SetPos(pos)
	ent:SetModel(itemData.Model or "models/props_junk/cardboard_box004a.mdl")
	ent:SetItemClass(itemClass)
	ent:Spawn()
	ent:Activate()
	print("[Monarch] Entity 'monarch_item' spawned and activated: " .. tostring(ent))
	return ent
end
function Monarch.Inventory.SpawnBench(class, pos, ang)
    local benchClass = impulse.Inventory.Benches[class]
    if not benchClass then return end

	local bench = ents.Create("Monarch_bench")
	bench:SetBench(benchClass)
	bench:SetPos(pos)
	bench:SetAngles(ang)
	bench:Spawn()

	return bench
end
function meta:GetInventory(storage)
	return Monarch.Inventory.Data[self.MonarchID][storage or 1]
end
function meta:CanHoldItem(itemclass, amount)
	local item = Monarch.Inventory.Items[Monarch.Inventory.ClassToNetID(itemclass)]
	local weight = (item.Weight or 0) * (amount or 1)
	local addedweight = 0
	if self.HasBackpack then
		addedweight = 10
	end 

	return true
end
function meta:CanHoldItemStorage(itemclass, amount)
end
function meta:HasInventoryItem(itemclass, amount)
	local has = self.InventoryRegister[itemclass]

	if amount then
		if has and has >= amount then
			return true, has
		else
			return false, has
		end
	end

	if has then
		return true, has
	end

	return false
end
function meta:HasInventoryItemStorage(itemclass, amount)
	local has = self.InventoryStorageRegister[itemclass]

	if amount then
		if has and has >= amount then
			return true, has
		else
			return false, has
		end
	end

	if has then
		return true, has
	end

	return false
end
function meta:HasInventoryItemSpecific(id, storetype)
	if not self.beenInvSetup then return false end
	local storetype = storetype or 1
	local has = Monarch.Inventory.Data[self.MonarchID][storetype][id]

	if has then
		return true, has
	end

	return false
end
function meta:HasIllegalInventoryItem(storetype)
	if not self.beenInvSetup then return false end
	local storetype = storetype or 1
	local inv = self:GetInventory(storetype)

	for v,k in pairs(inv) do
		local itemclass = Monarch.Inventory.ClassToNetID(k.class)
		local item = Monarch.Inventory.Items[itemclass]

		if not k.restricted and item.Illegal then
			return true, v
		end
	end

	return false
end
function meta:IsInventoryItemRestricted(id, storetype)
	if not self.beenInvSetup then return false end
	local storetype = storetype or 1
	local has = Monarch.Inventory.Data[self.MonarchID][storetype][id]

	if has then
		return has.restricted
	end

	return false
end
function meta:TakeInventoryItem(invid, storetype, moving)
	if not self.beenInvSetup then return end

	local storetype = storetype or 1
	local amount = amount or 1
	local MonarchID = self.MonarchID
	local item = Monarch.Inventory.Data[MonarchID][storetype][invid]
		if not item then return end
	local itemid = Monarch.Inventory.ClassToNetID(item.class)
	local weight = (Monarch.Inventory.Items[itemid].Weight or 0) * amount

	if not moving then
		Monarch.Inventory.DBRemoveItem(MonarchID, item.class, storetype, 1)
	end

	if storetype == 1 then
				self.InventoryRegister = self.InventoryRegister or {}
		local regvalue = self.InventoryRegister[item.class] or -99999
				if regvalue == -99999 then

					self.InventoryRegister[item.class] = 0
					return
				end
		self.InventoryRegister[item.class] = regvalue - 1

		if self.InventoryRegister[item.class] < 1 then
			self.InventoryRegister[item.class] = nil
		end
	elseif storetype == 2 then
				self.InventoryStorageRegister = self.InventoryStorageRegister or {}
		local regvalue = self.InventoryStorageRegister[item.class]
		self.InventoryStorageRegister[item.class] = regvalue - 1

		if self.InventoryStorageRegister[item.class] < 1 then
			self.InventoryStorageRegister[item.class] = nil
		end
	end

	if item.equipped then
		self:SetInventoryItemEquipped(invid, false)
	end

	local clip = item.clip

	hook.Run("OnInventoryItemRemoved", self, storetype, item.class, item.id, item.equipped, item.restricted, invid)
	Monarch.Inventory.Data[MonarchID][storetype][invid] = nil
	self:SyncInventory()
	do
		local charID = self.MonarchID or (self.MonarchActiveChar and self.MonarchActiveChar.id)
		if charID and Monarch and Monarch.Inventory and Monarch.Inventory.SaveForOwner then
			Monarch.Inventory.SaveForOwner(self, charID)
		end
	end

	return clip
end
function meta:ClearInventory(storetype)
	if not self.beenInvSetup then return end
	local storetype = storetype or 1

	local inv = self:GetInventory(storetype)

	for v,k in pairs(inv) do
		self:TakeInventoryItem(v, storetype, true)
	end

	Monarch.Inventory.DBClearInventory(self.MonarchID, storetype)

	net.Start("MonarchInvClear")
	net.WriteUInt(storetype, 4)
	net.Send(self)
end
function meta:ClearRestrictedInventory(storetype)
	if not self.beenInvSetup then return end
	local storetype = storetype or 1

	local inv = self:GetInventory(storetype)

	for v,k in pairs(inv) do
		if k.restricted then
			self:TakeInventoryItem(v, storetype, true)
		end
	end

	net.Start("MonarchInvClearRestricted")
	net.WriteUInt(storetype, 4)
	net.Send(self)
end
function meta:ClearIllegalInventory(storetype)
	if not self.beenInvSetup then return end
	local storetype = storetype or 1

	local inv = self:GetInventory(storetype)

	for v,k in pairs(inv) do
		local itemData = Monarch.Inventory.Items[k.id]

		if itemData and itemData.Illegal then
			self:TakeInventoryItem(v)
		end
	end
end
function meta:TakeInventoryItemClass(itemclass, storetype, amount)
	if not self.beenInvSetup then return end

	local storetype = storetype or 1
	local amount = amount or 1
	local MonarchID = self.MonarchID

	local count = 0
	for v,k in pairs(Monarch.Inventory.Data[MonarchID][storetype]) do
		if k.class == itemclass then
			count = count + 1
			self:TakeInventoryItem(v, storetype)

			if count == amount then
				return
			end
		end
	end
end
function meta:SetInventoryItemEquipped(itemid, state)
	self.InventoryEquipGroups = self.InventoryEquipGroups or {}
	local inv = Monarch.Inventory.Data[self:SteamID64()]
	if (not inv) and self.MonarchID and Monarch.Inventory.Data[self.MonarchID] then
		inv = Monarch.Inventory.Data[self.MonarchID][1]
	end
	if not inv then return end

	local item = inv[itemid]
	if not istable(item) then return end
	local itemKey = nil
	if item.class and Monarch.Inventory.ItemsRef then
		itemKey = Monarch.Inventory.ItemsRef[item.class]
	end
	local itemclass = (itemKey and Monarch.Inventory.Items[itemKey]) or Monarch.Inventory.Items[item.class]
	if not itemclass then return end

	local function resolveItemDef(itemData)
		if not istable(itemData) then return nil end
		local cls = itemData.class or itemData.id
		if not cls then return nil end
		if Monarch.Inventory.ItemsRef and Monarch.Inventory.ItemsRef[cls] then
			return Monarch.Inventory.Items[Monarch.Inventory.ItemsRef[cls]]
		end
		return Monarch.Inventory.Items[cls]
	end

	local egNorm = Monarch.NormalizeEquipGroup(itemclass.EquipGroup)

	local onEquip = itemclass.OnEquip
	local unEquip = itemclass.UnEquip
	local sourceSlot = itemid
	local targetSlot = itemid

	local canChangeEquip = hook.Run("Monarch_CanChangeInventoryEquipState", self, itemid, state, item, itemclass, inv)
	if canChangeEquip == false then
		return
	end

	if state then
		if itemclass.CanEquip and not itemclass.CanEquip(item, self) then
			return
		end
		local canEquip = hook.Run("PlayerCanEquipItem", self, itemclass, item)
		if canEquip ~= nil and not canEquip then
			return
		end
		if itemid < 1 or itemid > 20 then return end
		local equipSlot = nil
		if itemclass.EquipGroup then
			local wantedGroup = Monarch.NormalizeEquipGroup(itemclass.EquipGroup)
			for slot = 21, 30 do
				if inv[slot] then
					local existingClass = resolveItemDef(inv[slot])
					if existingClass and Monarch.NormalizeEquipGroup(existingClass.EquipGroup) == wantedGroup then
						self:SetInventoryItemEquipped(slot, false)
						equipSlot = slot
						break
					end
				end
			end
		end
		if not equipSlot then
			for slot = 21, 30 do
				if not inv[slot] then
					equipSlot = slot
					break
				end
			end
		end

		if not equipSlot then
			self:Notify("No free equipment slot available.")
			return
		end
		targetSlot = equipSlot
		inv[equipSlot] = table.Copy(item)
		inv[equipSlot].equipped = true
		inv[itemid] = nil
		if onEquip then
			onEquip(inv[equipSlot], self, itemclass, equipSlot)
		end

	else
		if itemid < 21 or itemid > 30 then return end
		local freeSlot = nil
		for slot = 1, 20 do
			if not inv[slot] then
				freeSlot = slot
				break
			end
		end

		if not freeSlot then
			self:Notify("Your inventory is full so you cannot unequip this item.")
			return
		end
		targetSlot = freeSlot
		if itemclass.EquipGroup then
			self.InventoryEquipGroups[itemclass.EquipGroup] = nil
		end
		if itemclass.WeaponClass then
			local wep = self:GetWeapon(itemclass.WeaponClass)
			if IsValid(wep) then
				self:StripWeapon(itemclass.WeaponClass)
			end
		end
		if unEquip then
			unEquip(item, self, itemclass, itemid)
		end
		inv[freeSlot] = table.Copy(item)
		inv[freeSlot].equipped = false
		inv[itemid] = nil
	end
	hook.Run("Monarch_InventoryEquipStateChanged", self, sourceSlot, targetSlot, state, item, itemclass)
local charID = self.MonarchID or (self.MonarchActiveChar and self.MonarchActiveChar.id)
if charID and Monarch and Monarch.Inventory and Monarch.Inventory.SaveForOwner then
	Monarch.Inventory.SaveForOwner(self, charID)
end

local sid = self:SteamID64()
local inv = Monarch.Inventory.Data and Monarch.Inventory.Data[sid]

self:SyncInventory()
end

function meta:DropInventoryItem(itemid)
    if not self.MonarchID then return end

    local item = Monarch.Inventory.Data[self.MonarchID][1][itemid]

    if not item then return end

    local itemKey = Monarch.Inventory.ItemsRef[item.class or item.id]
    local itemclass = itemKey and Monarch.Inventory.Items[itemKey]

    if not itemclass then return end

	local canDrop = hook.Run("Monarch_CanDropInventoryItem", self, itemid, item, itemclass)
	if canDrop == false then
		return
	end

    if item.restricted and not itemclass.DropIfRestricted then
        self:Notify("You cannot drop this item.")
        return
    end

    if item.equipped then
        self:Notify("You cannot drop an equipped item. Unequip it first.")
        return
    end

	local locked = itemclass.Locked or item.Locked or item.locked

	if locked then
		self:Notify("This item can not be dropped.")
		return
	end

    self.DroppedItemsC = self.DroppedItemsC or 0

    local limit = 30

    if self.DroppedItemsC >= limit then
        self:Notify("You can only have up to " .. limit .. " dropped items at once.")
        return
    end

    local trace = {}
    trace.start = self:EyePos()
    trace.endpos = trace.start + self:GetAimVector() * 45
    trace.filter = self
    local tr = util.TraceLine(trace)

	self:TakeInventoryItem(itemid)

	local charID = self.MonarchID or (self.MonarchActiveChar and self.MonarchActiveChar.id)
	if charID and Monarch and Monarch.Inventory and Monarch.Inventory.SaveForOwner then
		Monarch.Inventory.SaveForOwner(self, charID)
	end

    local ent = Monarch.Inventory.SpawnItem(item.class or item.id, tr.HitPos + Vector(0, 0, 10))

    if IsValid(ent) then
        ent.ItemOwner = self
        ent.IsRestrictedItem = item.restricted or false

        if itemclass.WeaponClass and item.clip then
            ent.ItemClip = item.clip
        end

        self.DroppedItemsC = self.DroppedItemsC + 1
        self.DroppedItemsCA = (self.DroppedItemsCA or 0) + 1
        self.DroppedItems = self.DroppedItems or {}
        self.NextItemDrop = CurTime() + 2
        ent.DropIndex = self.DroppedItemsCA
        self.DroppedItems[self.DroppedItemsCA] = ent

        self:Notify("You dropped " .. itemclass.Name)
		hook.Run("Monarch_InventoryItemDropped", self, itemid, item, itemclass, ent)
	else
		hook.Run("Monarch_InventoryItemDropFailed", self, itemid, item, itemclass)
    end
end

function meta:DropInventoryItemClass(itemClass, amount)
    if not self.MonarchID then return end

    amount = math.min(amount or 1, 50)
    local dropped = 0

    for k, v in pairs(Monarch.Inventory.Data[self.MonarchID][1]) do
        if (v.class == itemClass or v.id == itemClass) and not v.equipped then
            self:DropInventoryItem(k)
            dropped = dropped + 1

            if dropped >= amount then
                break
            end
        end
    end

	if dropped > 0 then
        local itemKey = Monarch.Inventory.ItemsRef[itemClass]
        local itemData = itemKey and Monarch.Inventory.Items[itemKey]
        local itemName = itemData and itemData.Name or itemClass
		self:Notify("You dropped " .. dropped .. "x " .. itemName)
		do
			local charID = self.MonarchID or (self.MonarchActiveChar and self.MonarchActiveChar.id)
			if charID and Monarch and Monarch.Inventory and Monarch.Inventory.SaveForOwner then
				Monarch.Inventory.SaveForOwner(self, charID)
			end
		end
    else
        self:Notify("No items to drop.")
    end
end

function meta:HasInventoryItem(itemClass)
    local inv = (Monarch.Inventory and Monarch.Inventory.Data and Monarch.Inventory.Data[self:SteamID64()]) or {}
    for _, v in pairs(inv) do
        if istable(v) and (v.class == itemClass or v.id == itemClass) then
            return true
        end
    end
    return false
end

function meta:GetInventoryItemCount(itemClass)
    local inv = (Monarch.Inventory and Monarch.Inventory.Data and Monarch.Inventory.Data[self:SteamID64()]) or {}
    local count = 0
    for _, v in pairs(inv) do
        if istable(v) and (v.class == itemClass or v.id == itemClass) then
            count = count + 1
        end
    end
    return count
end
function meta:SetupInventory()
    Monarch.Inventory = Monarch.Inventory or {}
    Monarch.Inventory.Data = Monarch.Inventory.Data or {}
    local sid = self:SteamID64()
    Monarch.Inventory.Data[sid] = Monarch.Inventory.Data[sid] or {}
    self.beenInvSetup = true
    self.InventoryEquipGroups = {}
		self.InventoryRegister = self.InventoryRegister or {}
		self.InventoryStorageRegister = self.InventoryStorageRegister or {}
    timer.Simple(0.2, function()
        if IsValid(self) then self:SyncInventory() end
    end)
end
util.AddNetworkString("MonarchInventorySync")

util.AddNetworkString("Monarch_DropItem")

net.Receive("Monarch_DropItem", function(len, ply)
	local slotID = net.ReadUInt(8)
	if not slotID then return end

	ply:DropInventoryItem(slotID)
end)
net.Receive("Monarch_Inventory_Request", function(_, ply)
end)
concommand.Add("monarch_inv_save", function(ply)
	if not IsValid(ply) then return end
	local charID = (ply.MonarchActiveChar and ply.MonarchActiveChar.id) or ply.MonarchID or ply.MonarchLastCharID
	if not charID then
		if ply.ChatPrint then ply:ChatPrint("[Monarch] No active character to save.") end
		return
	end
	Monarch.Inventory.SaveForOwner(ply, charID)
	if ply.ChatPrint then ply:ChatPrint("[Monarch] Inventory saved for character #" .. tostring(charID) .. ".") end
end, nil, "Save your current character's inventory to MySQL")

concommand.Add("monarch_inv_load", function(ply)
	if not IsValid(ply) then return end
	local charID = (ply.MonarchActiveChar and ply.MonarchActiveChar.id) or ply.MonarchID or ply.MonarchLastCharID
	if not charID then
		if ply.ChatPrint then ply:ChatPrint("[Monarch] No active character to load.") end
		return
	end
	Monarch.Inventory.LoadForOwner(ply, charID)
	if ply.ChatPrint then ply:ChatPrint("[Monarch] Inventory loaded for character #" .. tostring(charID) .. ".") end
end, nil, "Load your current character's inventory from MySQL")

util.AddNetworkString("Monarch_Inventory_DropAndListForSale")

net.Receive("Monarch_Inventory_DropAndListForSale", function(len, ply)
    local slotID = net.ReadUInt(8)
    local price = net.ReadUInt(32)

    if not ply.MonarchID then return end
    if price <= 0 then return end

    local inv = Monarch.Inventory.Data[ply.MonarchID]
    if not inv or not inv[1] then return end

	local item = inv[1][slotID]
	if not item then
		print("[Monarch] DropAndListForSale: No item found for slotID " .. tostring(slotID))
		return
	end
	local itemClassStr = tostring(item.UniqueID or item.class or item.id)
	local itemKey = Monarch.Inventory.ItemsRef[itemClassStr]
	print("[Monarch] DropAndListForSale: itemClassStr=" .. itemClassStr .. ", itemKey=" .. tostring(itemKey))
	local itemclass = itemKey and Monarch.Inventory.Items[itemKey]
	if not itemclass then
		print("[Monarch] DropAndListForSale: No itemclass found for itemKey " .. tostring(itemKey))
		return
	end
    if itemclass.CanSell == false then
        if ply.Notify then ply:Notify("This item cannot be sold.") end
        return
    end
	if itemclass.Locked or item.Locked or item.locked then
		if ply.Notify then ply:Notify("This item is locked and cannot be dropped.") end
		return
	end
    if item.restricted and not itemclass.DropIfRestricted then
        if ply.Notify then ply:Notify("You cannot drop this item.") end
        return
    end
    if item.equipped then
        if ply.Notify then ply:Notify("You cannot sell an equipped item. Unequip it first.") end
        return
    end
    local trace = {}
    trace.start = ply:EyePos()
    trace.endpos = trace.start + ply:GetAimVector() * 45
    trace.filter = ply
    local tr = util.TraceLine(trace)
    ply:TakeInventoryItem(slotID)
	local ent = Monarch.Inventory.SpawnItem(item.class or item.id, tr.HitPos + Vector(0, 0, 10))
	if not IsValid(ent) then
		if ply.Notify then ply:Notify("Failed to place item in world. Please contact staff.") end
		print("[Monarch] DropAndListForSale failed: entity not spawned for class " .. tostring(item.class or item.id))
		return
	end
	local phys = ent:GetPhysicsObject()
	if IsValid(phys) then 
		phys:EnableMotion(false)
		phys:Wake()
	end
	timer.Simple(0, function()
		if IsValid(ent) then
			ent:UprightOnGround()
		end
	end)
	timer.Simple(0.1, function()
		if IsValid(ent) and IsValid(ply) then
			ent:SetNWBool("ForSale", true)
			ent:SetNWInt("SalePrice", price)
			ent:SetNWEntity("Seller", ply)
			if ply.Notify then 
				ply:Notify("Listed " .. (itemclass.Name or "item") .. " for sale at "..((Monarch and Monarch.FormatMoney) and Monarch.FormatMoney(price) or ("$"..price))..".") 
			end
		end
	end)
end)

net.Receive("Monarch_Inventory_ExecuteAction", function(len, ply)
	if not IsValid(ply) then return end
	
	local slotID = net.ReadUInt(8)
	local actionID = net.ReadString()
	
	if not slotID or not actionID or actionID == "" then return end
	
	local inv = Monarch.Inventory.Data and Monarch.Inventory.Data[ply:SteamID64()]
	if not inv then return end
	
	local item = inv[slotID]
	if not item then return end
	
	local itemKey = Monarch.Inventory.ItemsRef and Monarch.Inventory.ItemsRef[item.class or item.id]
	local itemDef = itemKey and Monarch.Inventory.Items[itemKey]
	
	if not itemDef then return end
	
	if not itemDef.Actions or not itemDef.Actions[actionID] then return end
	
	local action = itemDef.Actions[actionID]

	local canRunHook = hook.Run("Monarch_CanRunInventoryAction", ply, slotID, actionID, item, itemDef, action)
	if canRunHook == false then
		hook.Run("Monarch_InventoryActionBlocked", ply, slotID, actionID, item, itemDef, action, "hook")
		return
	end
	
	local canRun = true
	if type(action.CanRun) == "function" then
		local ok, result = pcall(action.CanRun, item, ply)
		if ok then
			canRun = result and true or false
		else
			canRun = false
			ErrorNoHalt("[Monarch] Action CanRun error: " .. tostring(result) .. "\n")
		end
	end
	
	if not canRun then
		hook.Run("Monarch_InventoryActionBlocked", ply, slotID, actionID, item, itemDef, action, "canrun")
		return
	end

	local actionSucceeded = false
	local actionResult = nil
	
	if type(action.OnRun) == "function" then
		local ok, result = pcall(action.OnRun, item, ply)
		if not ok then
			ErrorNoHalt("[Monarch] Action OnRun error: " .. tostring(result) .. "\n")
		else
			actionSucceeded = true
			actionResult = result
		end
	else
		actionSucceeded = true
	end

	hook.Run("Monarch_InventoryActionExecuted", ply, slotID, actionID, item, itemDef, action, actionSucceeded, actionResult)
end)

Monarch.Inventory.Items = Monarch.Inventory.Items or {}
Monarch.Inventory.ItemsRef = Monarch.Inventory.ItemsRef or {}

local ITEM = {}
ITEM.__index = ITEM

function ITEM:RegisterAction(actionID, actionData)
	if not actionID or not actionData then
		ErrorNoHalt("ITEM:RegisterAction: actionID and actionData are required!\n")
		return
	end
	
	if not actionData.name then
		ErrorNoHalt("ITEM:RegisterAction: actionData must have a 'name' field!\n")
		return
	end
	
	self.Actions = self.Actions or {}
	self.Actions[actionID] = actionData
end

function Monarch.RegisterItem(itemData)
	if not itemData or not itemData.UniqueID then
		ErrorNoHalt("Monarch.RegisterItem: Item must have a UniqueID field!\n")
		return
	end

	if itemData.DeathDrop == nil then
		itemData.DeathDrop = true
	end

	if itemData.Locked then
		if type(itemData.Stats) == "function" then
			local originalStatsFn = itemData.Stats
			itemData.Stats = function(ply, itemData)
				local result = originalStatsFn(ply, itemData)
				if result and result ~= "None" then
					return result .. "\n<color=200, 100, 100>Constrained</color>"
				else
					return "<color=200, 100, 100>Constrained</color>"
				end
			end
		elseif itemData.Stats then
			itemData.Stats = itemData.Stats .. "\n<color=200, 100, 100>Constrained</color>"
		else
			itemData.Stats = "<color=200, 100, 100>Constrained</color>"
		end
	else

		if itemData.DeathDrop then
			if type(itemData.Stats) == "function" then
				local originalStatsFn = itemData.Stats
				itemData.Stats = function(ply, itemData)
					local result = originalStatsFn(ply, itemData)
					if result and result ~= "None" then
						return result .. "\n<color=200, 200, 200>Death Drop</color>"
					else
						return "<color=200, 200, 200>Death Drop</color>"
					end
				end
			elseif itemData.Stats then
				itemData.Stats = itemData.Stats .. "\n<color=200, 200, 200>Death Drop</color>"
			else
				itemData.Stats = "<color=200, 200, 200>Death Drop</color>"
			end
		else
			if type(itemData.Stats) == "function" then
				local originalStatsFn = itemData.Stats
				itemData.Stats = function(ply, itemData)
					local result = originalStatsFn(ply, itemData)
					if result and result ~= "None" then
						return result .. "\n<color=100, 200, 100>Keeps on Death</color>"
					else
						return "<color=100, 200, 100>Keeps on Death</color>"
					end
				end
			elseif itemData.Stats then
				itemData.Stats = itemData.Stats .. "\n<color=100, 200, 100>Keeps on Death</color>"
			else
				itemData.Stats = "<color=100, 200, 100>Keeps on Death</color>"
			end
		end
	end

	local uniqueID = itemData.UniqueID
	
	setmetatable(itemData, ITEM)
	
	if itemData.Actions and istable(itemData.Actions) then
		for actionID, actionDataTable in pairs(itemData.Actions) do
			itemData:RegisterAction(actionID, actionDataTable)
		end
	end
	
	Monarch.Inventory.Items[uniqueID] = itemData
	Monarch.Inventory.ItemsRef[uniqueID] = uniqueID
end
