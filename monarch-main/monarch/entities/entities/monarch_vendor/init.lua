AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

--[[
    CONSTRAINED ITEMS: Items that do not persist across team changes or disconnects
    
    To make an item constrained (removed when player goes off-duty), add constrained = true to the item:
    
    Monarch.Vendors["vendor_id"] = {
        name = "Vendor Name",
        items = {
            {
                class = "item_class",
                name = "Item Name",
                price = 100,
                constrained = true  -- This item will be removed when player changes team
            }
        }
    }
    
    Constrained items are automatically removed when:
    - Player changes team (PlayerChangedTeam hook)
    - Player disconnects (inventory is cleaned before disconnect)
]]

util.AddNetworkString("Monarch_VendorOpen")
util.AddNetworkString("Monarch_VendorBuy")
util.AddNetworkString("Monarch_VendorSell") 
util.AddNetworkString("Monarch_VendorNotify")

Monarch = Monarch or {}
Monarch.ItemVendorRegistry = Monarch.ItemVendorRegistry or { list = {} }

local function EnsureMapDir()
	file.CreateDir("monarch")
	file.CreateDir("monarch/maps")
	file.CreateDir("monarch/maps/" .. game.GetMap())
end

local function ItemVendorPersistPath()
	return "monarch/maps/" .. game.GetMap() .. "/itemvendors.json"
end

local function ItemVendor_Register(ent)
	if not IsValid(ent) then return end
	Monarch.ItemVendorRegistry.list = Monarch.ItemVendorRegistry.list or {}
	local uid = "vendor_" .. tostring(ent:EntIndex()) .. "_" .. math.floor(CurTime())
	ent._persistUID = uid
	local rec = {
		class = ent:GetClass(),
		uid = uid,
		pos = { x = ent:GetPos().x, y = ent:GetPos().y, z = ent:GetPos().z },
		ang = { p = ent:GetAngles().p, y = ent:GetAngles().y, r = ent:GetAngles().r },
		model = ent:GetModel(),
		vendorID = ent.GetVendorID and ent:GetVendorID() or "default",
		name = ent.GetVendorName and ent:GetVendorName() or "Vendor",
		desc = ent.GetVendorDesc and ent:GetVendorDesc() or "Browse items",
		team = ent.GetRequiredTeam and ent:GetRequiredTeam() or 0
	}
	Monarch.ItemVendorRegistry.list[uid] = rec
end

Monarch._removedVendorUIDs = Monarch._removedVendorUIDs or {}

local function ItemVendor_SaveAll()
	EnsureMapDir()

	local existingData = {}
	if file.Exists(ItemVendorPersistPath(), "DATA") then
		local existing = util.JSONToTable(file.Read(ItemVendorPersistPath(), "DATA") or "{}") or {}
		existingData = existing.list or {}
	else

		local legacy = "monarch/itemvendors_" .. game.GetMap() .. ".json"
		if file.Exists(legacy, "DATA") then
			local existing = util.JSONToTable(file.Read(legacy, "DATA") or "{}") or {}
			existingData = existing.list or {}
		end
	end

	local spawnedUIDs = {}
	local list = {}

	for _, ent in ipairs(ents.FindByClass("monarch_vendor")) do
		if IsValid(ent) then
			local pos = ent:GetPos()
			local ang = ent:GetAngles()
			local uid = ent._persistUID or ("vendor_" .. tostring(ent:EntIndex()))
			spawnedUIDs[uid] = true
			local team = 0
			if type(ent.GetRequiredTeam) == "function" then
				local ok, result = pcall(function() return ent:GetRequiredTeam() end)
				if ok then team = tonumber(result) or 0 end
			end
			list[#list + 1] = {
				class = ent:GetClass(),
				uid = uid,
				pos = { x = pos.x, y = pos.y, z = pos.z },
				ang = { p = ang.p, y = ang.y, r = ang.r },
				model = ent:GetModel(),
				vendorID = ent.GetVendorID and ent:GetVendorID() or "default",
				name = ent.GetVendorName and ent:GetVendorName() or "Vendor",
				desc = ent.GetVendorDesc and ent:GetVendorDesc() or "Browse items",
				team = team
			}
		end
	end

	for _, rec in ipairs(existingData) do
		if not spawnedUIDs[rec.uid] and not Monarch._removedVendorUIDs[rec.uid] then
			list[#list + 1] = rec
		end
	end

	local payload = { list = list }
	file.Write(ItemVendorPersistPath(), util.TableToJSON(payload, false))
	print("[Monarch] Item vendors saved (" .. #list .. " vendors)")
	Monarch._removedVendorUIDs = {}
end

Monarch.ItemVendor_SaveAll = ItemVendor_SaveAll

local function ItemVendor_SaveSingle(ent)
	if not IsValid(ent) or ent:GetClass() ~= "monarch_vendor" then return end

	EnsureMapDir()

	local existingData = {}
	if file.Exists(ItemVendorPersistPath(), "DATA") then
		local t = util.JSONToTable(file.Read(ItemVendorPersistPath(), "DATA") or "{}") or {}
		existingData = t.list or {}
	end

	local uid = ent._persistUID or ("vendor_" .. tostring(ent:EntIndex()) .. "_" .. math.floor(CurTime()))
	if not ent._persistUID then ent._persistUID = uid end

	local found = false
	local list = {}

	for _, rec in ipairs(existingData) do
		if Monarch._removedVendorUIDs[rec.uid] then
			continue
		elseif rec.uid == uid then

			found = true
			local pos = ent:GetPos()
			local ang = ent:GetAngles()
			list[#list + 1] = {
				class = ent:GetClass(),
				uid = uid,
				pos = { x = pos.x, y = pos.y, z = pos.z },
				ang = { p = ang.p, y = ang.y, r = ang.r },
				model = ent:GetModel(),
				vendorID = (ent.GetVendorID and ent:GetVendorID()) or "default",
				name = (ent.GetVendorName and ent:GetVendorName()) or "Vendor",
				desc = (ent.GetVendorDesc and ent:GetVendorDesc()) or "Browse items",
				team = (ent.GetRequiredTeam and ent:GetRequiredTeam()) or 0
			}
		else

			list[#list + 1] = rec
		end
	end

	if not found then
		local pos = ent:GetPos()
		local ang = ent:GetAngles()
		list[#list + 1] = {
			class = ent:GetClass(),
			uid = uid,
			pos = { x = pos.x, y = pos.y, z = pos.z },
			ang = { p = ang.p, y = ang.y, r = ang.r },
			model = ent:GetModel(),
			vendorID = (ent.GetVendorID and ent:GetVendorID()) or "default",
			name = (ent.GetVendorName and ent:GetVendorName()) or "Vendor",
			desc = (ent.GetVendorDesc and ent:GetVendorDesc()) or "Browse items",
			team = (ent.GetRequiredTeam and ent:GetRequiredTeam()) or 0
		}
	end

	local payload = { list = list }
	file.Write(ItemVendorPersistPath(), util.TableToJSON(payload, true))
	print("[Monarch] Item vendor saved: " .. uid)
end

Monarch.ItemVendor_SaveSingle = ItemVendor_SaveSingle

local function ItemVendor_LoadAll()
	Monarch.ItemVendorRegistry.list = {}
	EnsureMapDir()
	if not file.Exists(ItemVendorPersistPath(), "DATA") then return end
	local t = util.JSONToTable(file.Read(ItemVendorPersistPath(), "DATA") or "{}") or {}
	local list = t.list or {}
	for _, rec in pairs(list) do
		if rec.class == "monarch_vendor" then
			local ent = ents.Create("monarch_vendor")
			if IsValid(ent) then
				ent:SetPos(Vector(rec.pos.x, rec.pos.y, rec.pos.z))
				ent:SetAngles(Angle(rec.ang.p, rec.ang.y, rec.ang.r))
				ent:SetModel(rec.model or "models/Humans/Group01/male_02.mdl")
				ent:SetVendorID(rec.vendorID or "default")
				ent:SetVendorName(rec.name or "Vendor")
				ent:SetVendorDesc(rec.desc or "Browse items")
				ent.MonarchSaveData = rec
				ent:Spawn()
				ItemVendor_Register(ent)
			end
		end
	end
end

Monarch.ItemVendor_LoadAll = ItemVendor_LoadAll

hook.Add("InitPostEntity", "Monarch_ItemVendor_LoadPersist", function()
	ItemVendor_LoadAll()
end)

concommand.Add("monarch_save_itemvendors", function(ply)
	if IsValid(ply) and not ply:IsAdmin() then return end
	ItemVendor_SaveAll()
	if IsValid(ply) and ply.Notify then ply:Notify("Saved item vendors to disk.") end
end)

local function ResolveItemModel(class)
	if not class or class == "" then return "models/props_junk/PopCan01a.mdl" end

	if Monarch and Monarch.Items and Monarch.Items[class] then
		local m = Monarch.Items[class].model or Monarch.Items[class].Model
		if m and util.IsValidModel(m) then return m end
	end

	local entStored = scripted_ents.GetStored(class)
	if entStored then
		local t = entStored.t or entStored
		if t.Model and util.IsValidModel(t.Model) then return t.Model end
		if t.WorldModel and util.IsValidModel(t.WorldModel) then return t.WorldModel end
	end

	local swepStored = weapons.GetStored(class)
	if swepStored then
		local wt = swepStored.t or swepStored
		if wt.WorldModel and util.IsValidModel(wt.WorldModel) then return wt.WorldModel end
		if wt.ViewModel and util.IsValidModel(wt.ViewModel) then return wt.ViewModel end
	end

	return "models/props_junk/PopCan01a.mdl"
end

local function ResolveItemDef(class)
	if not class or class == "" then return nil end
	local defs = Monarch and Monarch.Inventory and Monarch.Inventory.Items or nil
	local ref = Monarch and Monarch.Inventory and Monarch.Inventory.ItemsRef or nil
	if not defs then return nil end
	if ref and ref[class] then
		return defs[ref[class]]
	end
	return defs[class]
end

local function ResolveItemDefByIndex(index)
	local idx = tonumber(index)
	if not idx then return nil end
	local defs = Monarch and Monarch.Inventory and Monarch.Inventory.Items or nil
	if not defs then return nil end
	return defs[idx]
end

local function ResolveVendorItemClass(item)
	if type(item) == "string" then
		return item
	end

	if type(item) == "number" then
		local def = ResolveItemDefByIndex(item)
		if def and def.UniqueID then return tostring(def.UniqueID) end
		return nil
	end

	if type(item) ~= "table" then
		return nil
	end

	local class = item.class or item.id or item.UniqueID or item.itemid
	if isstring(class) and class ~= "" then
		return class
	end

	local idx = item.index or item.itemIndex or item.item_id or item.netid or item[1]
	if idx ~= nil then
		local def = ResolveItemDefByIndex(idx)
		if def and def.UniqueID then return tostring(def.UniqueID) end
	end

	return nil
end

local function BuildVendorItem(item)
	local class = ResolveVendorItemClass(item)
	if not class or class == "" then return nil end

	local source = istable(item) and item or {}
	local def = ResolveItemDef(class)

	local resolved = table.Copy(source)
	resolved.class = class
	resolved.id = resolved.id or class

	if (not resolved.name or resolved.name == "") and def then
		resolved.name = def.Name or def.name or class
	end
	if (not resolved.desc or resolved.desc == "") and def then
		resolved.desc = def.Description or def.description or ""
	end
	if (not resolved.model or resolved.model == "") and def then
		resolved.model = def.Model or def.model
	end

	resolved.name = resolved.name or class
	resolved.desc = resolved.desc or ""
	resolved.model = resolved.model or ResolveItemModel(class)
	return resolved
end

local function BuildVendorItemsList(vendorData)
	local out = {}
	for _, raw in ipairs((vendorData and vendorData.items) or {}) do
		local resolved = BuildVendorItem(raw)
		if resolved then
			out[#out + 1] = resolved
		end
	end
	return out
end

local function IsVendorItemRestricted(ply, vendor, item)
	if not item then return false end
	local def = ResolveItemDef(item.class)
	local restricted = item.restricted or item.Restricted or (def and (def.Restricted or def.restricted)) or false
	if not restricted then return false end
	if item.allowRestricted == true then return false end
	if isfunction(item.restrictionCheck) then
		local ok, res = pcall(item.restrictionCheck, ply, item, vendor)
		if ok and res == true then return false end
	end
	return true
end

local function RunVendorRule(ruleFn, ply, vendor, item)
	if not isfunction(ruleFn) then return true end

	local ok, allowed, reason = pcall(ruleFn, ply, vendor, item)
	if not ok then
		return false, "Eligibility check error"
	end

	if allowed == false then
		return false, reason or "You are not eligible to purchase this."
	end

	return true
end

local function EvaluateVendorItemEligibility(ply, vendor, vendorData, item)
	if not item then
		return false, "Item not found."
	end

	local vendorCustom = (vendorData and (vendorData.CustomCheck or vendorData.customCheck)) or nil
	local ok, reason = RunVendorRule(vendorCustom, ply, vendor, item)
	if not ok then return false, reason end

	local vendorCanBuy = (vendorData and (vendorData.CanBuy or vendorData.canBuy)) or nil
	ok, reason = RunVendorRule(vendorCanBuy, ply, vendor, item)
	if not ok then return false, reason end

	local itemCustom = item.CustomCheck or item.customCheck
	ok, reason = RunVendorRule(itemCustom, ply, vendor, item)
	if not ok then return false, reason end

	local itemCanBuy = item.CanBuy or item.canBuy
	ok, reason = RunVendorRule(itemCanBuy, ply, vendor, item)
	if not ok then return false, reason end

	if isfunction(item.canPurchase) then
		local canPurchaseOk, canPurchaseAllowed = pcall(item.canPurchase, ply, item, vendor)
		if not canPurchaseOk or canPurchaseAllowed == false then
			return false, "You are not eligible to purchase this."
		end
	elseif item.requiredWhitelistTeam and item.requiredWhitelistLevel and ply.HasWhitelist then
		if not ply:HasWhitelist(item.requiredWhitelistTeam, item.requiredWhitelistLevel) then
			return false, "You are not eligible to purchase this."
		end
	end

	if IsVendorItemRestricted(ply, vendor, item) then
		return false, "You are not eligible to purchase this."
	end

	return true
end

function ENT:Initialize()
	self:SetModel("models/Humans/Group01/male_02.mdl")
	self:SetUseType(SIMPLE_USE)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_BBOX)
	self:PhysicsInit(SOLID_BBOX)
	self:DrawShadow(true)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
		phys:Sleep()
	end

	if self.MonarchSaveData then
		local vendorID = self.MonarchSaveData.vendorID or "default"
		local name = self.MonarchSaveData.name or "Vendor"
		local desc = self.MonarchSaveData.desc or "Browse items"
		local model = self.MonarchSaveData.model or self:GetModel()
		local team = tonumber(self.MonarchSaveData.team or 0) or 0

		self:SetVendorID(vendorID)
		self:SetVendorName(name)
		self:SetVendorDesc(desc)
		self:SetModel(model)
		self:SetRequiredTeam(team)
	else
		self:SetVendorID("default")
		self:SetVendorName("Vendor")
		self:SetVendorDesc("Browse items")
		self:SetRequiredTeam(0)
	end

	if Monarch and Monarch.Vendors and Monarch.Vendors[self:GetVendorID()] then
		local cfg = Monarch.Vendors[self:GetVendorID()]
		if not self.MonarchSaveData or not self.MonarchSaveData.model then
			if cfg.model then self:SetModel(cfg.model) end
		end
		if cfg.name then self:SetVendorName(cfg.name) end
		if cfg.desc then self:SetVendorDesc(cfg.desc) end
		if cfg.team ~= nil then self:SetRequiredTeam(tonumber(cfg.team) or 0) end
	end

	timer.Simple(0.1, function()
		if IsValid(self) then
			local seq = self:LookupSequence("idle_all_01") or self:LookupSequence("idle") or 0
			self:ResetSequence(seq)
		end
	end)
end

function ENT:SpawnFunction(ply, tr, class)
	if not tr.Hit then return end
	local ang = (tr.HitPos - ply:GetPos()):Angle()
	ang.p = 0
	ang.r = 0
	ang.y = ang.y + 180

	local ent = ents.Create(class)
	ent:SetPos(tr.HitPos)
	ent:SetAngles(ang)
	ent:Spawn()
	ent:Activate()

	ItemVendor_Register(ent)

	return ent
end

function ENT:OnRemove()
	local uid = self._persistUID
	if uid and Monarch.ItemVendorRegistry and Monarch.ItemVendorRegistry.list then
		Monarch.ItemVendorRegistry.list[uid] = nil
	end
end

function ENT:Use(activator, caller)
	if not IsValid(activator) or not activator:IsPlayer() then return end
	if (activator._vendorNext or 0) > CurTime() then return end
	activator._vendorNext = CurTime() + 0.5

	if not activator:Alive() then return end

	local reqTeam = 0
	if type(self.GetRequiredTeam) == "function" then
		local ok, result = pcall(function() return self:GetRequiredTeam() end)
		if ok then reqTeam = tonumber(result) or 0 end
	end
	if reqTeam > 0 and activator:Team() ~= reqTeam then
		if activator.Notify then
			activator:Notify("You must be on the " .. team.GetName(reqTeam) .. " team to use this vendor.")
		end
		return
	end

	local vendorID = self:GetVendorID()
	local items = {}
	local vendorData = nil

	if Monarch and Monarch.Vendors and Monarch.Vendors[vendorID] then
		vendorData = Monarch.Vendors[vendorID]
		items = BuildVendorItemsList(vendorData)
	end

	net.Start("Monarch_VendorOpen")
		net.WriteEntity(self)
		net.WriteString(self:GetVendorName())
		net.WriteString(self:GetVendorDesc())
		net.WriteUInt(#items, 8)
		for _, item in ipairs(items) do
			local buyPrice = tonumber(item.price or 0) or 0
			local sellPrice = tonumber(item.sellPrice or 0) or 0 
			local ownedCount = (activator.GetInventoryItemCount and activator:GetInventoryItemCount(item.class)) or 0

			local modelPath = item.model
			if not modelPath or modelPath == "" or (util.IsValidModel and not util.IsValidModel(modelPath)) then
				modelPath = ResolveItemModel(item.class)
			end

			local eligible = EvaluateVendorItemEligibility(activator, self, vendorData, item) == true
			net.WriteString(item.class or "")
			net.WriteString(item.name or item.class or "Item")
			net.WriteString(item.desc or "")
			net.WriteString(modelPath or "")
			net.WriteUInt(buyPrice, 32)
			net.WriteUInt(item.stock or 0, 16)
			net.WriteUInt(sellPrice, 32)
			net.WriteUInt(ownedCount, 16)
			net.WriteBool(eligible)
		end
	net.Send(activator)
    print("Monarch Vendor used by " .. activator:Nick() .. " for vendor ID: " .. vendorID)
end

net.Receive("Monarch_VendorBuy", function(len, ply)
	if not IsValid(ply) then return end
	local vendor = net.ReadEntity()
	local itemClass = net.ReadString()

	if not IsValid(vendor) or vendor:GetClass() ~= "monarch_vendor" then return end
	if vendor:GetPos():Distance(ply:GetPos()) > 200 then return end

	local vendorID = vendor:GetVendorID()
	if not Monarch or not Monarch.Vendors or not Monarch.Vendors[vendorID] then
		if ply.Notify then ply:Notify("Vendor not configured.") end
		return
	end

	local vendorData = Monarch.Vendors[vendorID]
	local itemData = nil

	for _, item in ipairs(BuildVendorItemsList(vendorData)) do
		if item.class == itemClass then
			itemData = item
			break
		end
	end

	if not itemData then
		if ply.Notify then ply:Notify("Item not found.") end
		return
	end

	local eligible, reason = EvaluateVendorItemEligibility(ply, vendor, vendorData, itemData)
	if not eligible then
		if ply.Notify then ply:Notify(reason or "You are not eligible to purchase this.") end
		return
	end

	if itemData.stock and itemData.stock > 0 then
		vendor._stock = vendor._stock or {}
		vendor._stock[itemClass] = vendor._stock[itemClass] or itemData.stock
		if vendor._stock[itemClass] <= 0 then
			if ply.Notify then ply:Notify("Out of stock.") end
			return
		end
	end

	local price = tonumber(itemData.price or 0) or 0

	local wallet = tonumber(ply:GetNWInt("Money", 0)) or 0

	if wallet <= 0 and ply.MonarchActiveChar then
		wallet = tonumber(ply.MonarchActiveChar.money or 0) or 0
	end

	if wallet < price then
		if ply.Notify then ply:Notify("You don't have enough money.") end
		return
	end

	if ply.GiveInventoryItem then
		local metadata = {}
		if itemData.constrained then
			metadata.constrained = true
		end
		local success = ply:GiveInventoryItem(itemClass, 1, metadata)
		if not success then
			if ply.Notify then ply:Notify("Inventory full.") end
			return
		end
	else
		if ply.Notify then ply:Notify("Inventory system not available.") end
		return
	end

	local newWallet = math.max(0, wallet - price)
	ply:SetNWInt("Money", newWallet)
	if ply.SetLocalSyncVar and _G.SYNC_MONEY then
		ply:SetLocalSyncVar(SYNC_MONEY, newWallet)
	end
	if ply.MonarchActiveChar then
		ply.MonarchActiveChar.money = newWallet
		if mysql then
			local q = mysql:Update("monarch_players")
			q:Update("money", newWallet)
			q:Where("id", ply.MonarchActiveChar.id)
			q:Execute()
		end
	end

	if itemData.stock and itemData.stock > 0 then
		vendor._stock[itemClass] = vendor._stock[itemClass] - 1
	end

	if ply.Notify then
		ply:Notify("Purchased " .. (itemData.name or "item") .. " for $" .. price)
	end

	vendor:Use(ply)
end)

net.Receive("Monarch_VendorSell", function(len, ply)
	if not IsValid(ply) then return end
	local vendor = net.ReadEntity()
	local itemClass = net.ReadString()

	if not IsValid(vendor) or vendor:GetClass() ~= "monarch_vendor" then return end
	if vendor:GetPos():Distance(ply:GetPos()) > 200 then return end

	local vendorID = vendor:GetVendorID()
	if not Monarch or not Monarch.Vendors or not Monarch.Vendors[vendorID] then
		if ply.Notify then ply:Notify("Vendor not configured.") end
		return
	end

	local vendorData = Monarch.Vendors[vendorID]
	local itemData
	for _, it in ipairs(BuildVendorItemsList(vendorData)) do
		if it.class == itemClass then itemData = it break end
	end
	if not itemData then
		if ply.Notify then ply:Notify("Item not found.") end
		return
	end

	local owned = (ply.GetInventoryItemCount and ply:GetInventoryItemCount(itemClass)) or 0
	if owned <= 0 then
		if ply.Notify then ply:Notify("You don't own this item.") end
		return
	end

	local buyPrice = tonumber(itemData.price or 0) or 0
	local sellPriceSingle = tonumber(itemData.sellPrice or 0) or 0
	if sellPriceSingle <= 0 then
		if ply.Notify then ply:Notify("This vendor will not buy that item.") end
		return
	end
	if sellPriceSingle < 0 then sellPriceSingle = 0 end
	local totalValue = sellPriceSingle
	if totalValue <= 0 then
		if ply.Notify then ply:Notify("Item has no sell value.") end
		return
	end

	if ply.TakeInventoryItemClass then
		ply:TakeInventoryItemClass(itemClass, 1, 1)
	else
		if ply.Notify then ply:Notify("Inventory system not available.") end
		return
	end

	local wallet = tonumber(ply:GetNWInt("Money", 0)) or 0
	if wallet <= 0 and ply.MonarchActiveChar then
		wallet = tonumber(ply.MonarchActiveChar.money or 0) or 0
	end
	local newWallet = wallet + totalValue
	ply:SetNWInt("Money", newWallet)
	if ply.SetLocalSyncVar and _G.SYNC_MONEY then
		ply:SetLocalSyncVar(SYNC_MONEY, newWallet)
	end
	if ply.MonarchActiveChar then
		ply.MonarchActiveChar.money = newWallet
		if mysql then
			local q = mysql:Update("monarch_players")
			q:Update("money", newWallet)
			q:Where("id", ply.MonarchActiveChar.id)
			q:Execute()
		end
	end

	if itemData.stock and itemData.stock > 0 then
		vendor._stock = vendor._stock or {}
		vendor._stock[itemClass] = (vendor._stock[itemClass] or itemData.stock) + 1
	end

	if ply.Notify then ply:Notify("Sold 1x " .. (itemData.name or "item") .. " for $" .. totalValue) end

	vendor:Use(ply)
end)

Monarch = Monarch or {}
Monarch.Vendors = Monarch.Vendors or {}

Monarch.Vendors["default"] = {
	name = "General Store",
	desc = "Basic supplies",
	model = "models/Humans/Group01/male_02.mdl",
	items = {

	}
}
