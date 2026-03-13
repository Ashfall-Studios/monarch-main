AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("Monarch_RankVendor_Open")
util.AddNetworkString("Monarch_RankVendor_Select")
if SERVER then
	util.AddNetworkString("Monarch_RankVendor_List")
end

Monarch = Monarch or {}
Monarch.VendorRegistry = Monarch.VendorRegistry or { list = {} }

Monarch._removedRankVendorUIDs = Monarch._removedRankVendorUIDs or {}

local function VendorPersistPath()
	file.CreateDir("monarch")
	file.CreateDir("monarch/maps")
	file.CreateDir("monarch/maps/" .. game.GetMap())
	return "monarch/maps/" .. game.GetMap() .. "/vendors.json"
end

local function Vendor_Register(ent)
	if not IsValid(ent) then return end
	Monarch.VendorRegistry.list = Monarch.VendorRegistry.list or {}
	local uid = "rankvendor_" .. tostring(ent:EntIndex()) .. "_" .. math.floor(CurTime())
	ent._persistUID = uid
	local rec = {
		class = ent:GetClass(),
		uid = uid,
		pos = { x = ent:GetPos().x, y = ent:GetPos().y, z = ent:GetPos().z },
		ang = { p = ent:GetAngles().p, y = ent:GetAngles().y, r = ent:GetAngles().r },
		model = ent:GetModel(),
		vendorID = ent.GetRankVendorID and ent:GetRankVendorID() or "default",
		name = ent.GetVendorName and ent:GetVendorName() or "Rank Vendor",
		desc = ent.GetVendorDesc and ent:GetVendorDesc() or "Purchase ranks and promotions",
		teams = ent.GetRequiredTeamsStr and ent:GetRequiredTeamsStr() or "",
		team = ent.GetRequiredTeam and ent:GetRequiredTeam() or 0
	}
	Monarch.VendorRegistry.list[uid] = rec
end

local function Vendor_SaveAll()
	file.CreateDir("monarch")
	file.CreateDir("monarch/maps")
	file.CreateDir("monarch/maps/" .. game.GetMap())

	local existingData = {}
	if file.Exists(VendorPersistPath(), "DATA") then
		local existing = util.JSONToTable(file.Read(VendorPersistPath(), "DATA") or "{}") or {}
		existingData = existing.list or {}
	end

	local spawnedUIDs = {}
	local list = {}

	for _, ent in ipairs(ents.FindByClass("monarch_rankvendor")) do
		if IsValid(ent) then
			local pos = ent:GetPos()
			local ang = ent:GetAngles()
			local uid = ent._persistUID or ("rankvendor_" .. tostring(ent:EntIndex()))
			spawnedUIDs[uid] = true

			list[#list + 1] = {
				class = ent:GetClass(),
				uid = uid,
				pos = { x = pos.x, y = pos.y, z = pos.z },
				ang = { p = ang.p, y = ang.y, r = ang.r },
				model = ent:GetModel(),
				vendorID = ent.GetRankVendorID and ent:GetRankVendorID() or "default",
				name = ent.GetVendorName and ent:GetVendorName() or "Rank Vendor",
				desc = ent.GetVendorDesc and ent:GetVendorDesc() or "Purchase ranks and promotions",
				teams = ent.GetRequiredTeamsStr and ent:GetRequiredTeamsStr() or "",
				team = ent.GetRequiredTeam and ent:GetRequiredTeam() or 0
			}
		end
	end

	for _, rec in ipairs(existingData) do
		if not spawnedUIDs[rec.uid] and not Monarch._removedRankVendorUIDs[rec.uid] then
			list[#list + 1] = rec
		end
	end

	local payload = { list = list }
	file.Write(VendorPersistPath(), util.TableToJSON(payload, false))
	print("[Monarch] Rank vendors saved (" .. #list .. " vendors) to " .. VendorPersistPath())
	Monarch._removedRankVendorUIDs = {}
end

local function Vendor_SaveSingle(ent)
	if not IsValid(ent) or ent:GetClass() ~= "monarch_rankvendor" then return end

	file.CreateDir("monarch")
	file.CreateDir("monarch/maps")
	file.CreateDir("monarch/maps/" .. game.GetMap())

	local existingData = {}
	local path = VendorPersistPath()
	if file.Exists(path, "DATA") then
		local t = util.JSONToTable(file.Read(path, "DATA") or "{}") or {}
		existingData = t.list or {}
	end

	local uid = ent._persistUID or ("rankvendor_" .. tostring(ent:EntIndex()) .. "_" .. math.floor(CurTime()))
	if not ent._persistUID then ent._persistUID = uid end

	local found = false
	local list = {}

	for _, rec in ipairs(existingData) do
		if Monarch._removedRankVendorUIDs[rec.uid] then
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
				vendorID = ent.GetRankVendorID and ent:GetRankVendorID() or "default",
				name = ent.GetVendorName and ent:GetVendorName() or "Rank Vendor",
				desc = ent.GetVendorDesc and ent:GetVendorDesc() or "Purchase ranks and promotions",
				teams = ent.GetRequiredTeamsStr and ent:GetRequiredTeamsStr() or "",
				team = ent.GetRequiredTeam and ent:GetRequiredTeam() or 0
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
			vendorID = ent.GetRankVendorID and ent:GetRankVendorID() or "default",
			name = ent.GetVendorName and ent:GetVendorName() or "Rank Vendor",
			desc = ent.GetVendorDesc and ent:GetVendorDesc() or "Purchase ranks and promotions",
			teams = ent.GetRequiredTeamsStr and ent:GetRequiredTeamsStr() or "",
			team = ent.GetRequiredTeam and ent:GetRequiredTeam() or 0
		}
	end

	local payload = { list = list }
	file.Write(VendorPersistPath(), util.TableToJSON(payload, true))
	print("[Monarch] Rank vendor saved: " .. uid)
end

Monarch.RankVendor_SaveSingle = Vendor_SaveSingle

local function Vendor_LoadAll()
	Monarch.VendorRegistry.list = {}
	file.CreateDir("monarch")
	file.CreateDir("monarch/maps")
	file.CreateDir("monarch/maps/" .. game.GetMap())
	local path = VendorPersistPath()
	local t
	if file.Exists(path, "DATA") then
		t = util.JSONToTable(file.Read(path, "DATA") or "{}") or {}
	else

		local legacy = "monarch/vendors_" .. game.GetMap() .. ".json"
		if file.Exists(legacy, "DATA") then
			t = util.JSONToTable(file.Read(legacy, "DATA") or "{}") or {}
		end
	end
	if not t then return end
	local list = t.list or {}

	local loadedByPos = {}

	for _, rec in pairs(list) do
		if rec.class == "monarch_rankvendor" then
			local posKey = string.format("%.0f_%.0f_%.0f", rec.pos.x, rec.pos.y, rec.pos.z)
			if not loadedByPos[posKey] then
				loadedByPos[posKey] = true
				local ent = ents.Create("monarch_rankvendor")
				if IsValid(ent) then
					ent:SetPos(Vector(rec.pos.x, rec.pos.y, rec.pos.z))
					ent:SetAngles(Angle(rec.ang.p, rec.ang.y, rec.ang.r))
					ent:Spawn()
					ent:SetModel(rec.model or ent:GetModel())
					ent:SetRankVendorID(rec.vendorID or "default")
					ent:SetVendorName(rec.name or "Rank Vendor")
					ent:SetVendorDesc(rec.desc or "Purchase ranks and promotions")
				if rec.teams and rec.teams ~= "" then
					ent:SetRequiredTeamsStr(rec.teams)
				else
					ent:SetRequiredTeam(tonumber(rec.team) or 0)
				end
					ent._persistUID = rec.uid
					Vendor_Register(ent)
				end
			end
		end
	end
end

Monarch.RankVendor_LoadAll = Vendor_LoadAll

hook.Add("InitPostEntity", "Monarch_RankVendor_LoadPersist", function()
	Vendor_LoadAll()
end)

concommand.Add("monarch_save_vendors", function(ply)
	if IsValid(ply) and not ply:IsAdmin() then return end
	Vendor_SaveAll()
	if Monarch and Monarch.ItemVendor_SaveAll then Monarch.ItemVendor_SaveAll() end
	if IsValid(ply) and ply.Notify then ply:Notify("Saved all vendors to disk.") end
end)

concommand.Add("monarch_dump_vendors", function(ply)
	if IsValid(ply) and not ply:IsAdmin() then return end
	local map = game.GetMap()
	local rankPath = VendorPersistPath()
	local itemPath = "monarch/itemvendors_" .. map .. ".json"

	local function dumpFile(path, label)
		if file.Exists(path, "DATA") then
			local t = util.JSONToTable(file.Read(path, "DATA") or "{}") or {}
			local list = t.list or {}
			print(string.format("[Monarch] %s in %s: %d", label, path, table.Count(list)))
			for _, rec in pairs(list) do
				print(string.format("  - %s id=%s model=%s pos=(%.1f,%.1f,%.1f) ang=(%.1f,%.1f,%.1f)",
					label == "Rank Vendors" and "rank" or "item",
					tostring(rec.vendorID), tostring(rec.model),
					rec.pos and rec.pos.x or 0, rec.pos and rec.pos.y or 0, rec.pos and rec.pos.z or 0,
					rec.ang and rec.ang.p or 0, rec.ang and rec.ang.y or 0, rec.ang and rec.ang.r or 0))
			end
		else
			print(string.format("[Monarch] %s file missing: %s", label, path))
		end
	end

	dumpFile(rankPath, "Rank Vendors")
	dumpFile(itemPath, "Item Vendors")

	local rankLive = ents.FindByClass("monarch_rankvendor")
	print(string.format("[Monarch] Live rank vendors: %d", #rankLive))
	for _, e in ipairs(rankLive) do
		local p = e:GetPos()
		local a = e:GetAngles()
		print(string.format("  - rank id=%s model=%s pos=(%.1f,%.1f,%.1f) ang=(%.1f,%.1f,%.1f)",
			tostring(e.GetRankVendorID and e:GetRankVendorID() or ""), tostring(e:GetModel()),
			p.x, p.y, p.z, a.p, a.y, a.r))
	end
	local itemLive = ents.FindByClass("monarch_vendor")
	print(string.format("[Monarch] Live item vendors: %d", #itemLive))
	for _, e in ipairs(itemLive) do
		local p = e:GetPos()
		local a = e:GetAngles()
		print(string.format("  - item id=%s model=%s pos=(%.1f,%.1f,%.1f) ang=(%.1f,%.1f,%.1f)",
			tostring(e.GetVendorID and e:GetVendorID() or ""), tostring(e:GetModel()),
			p.x, p.y, p.z, a.p, a.y, a.r))
	end

	if IsValid(ply) and ply.Notify then ply:Notify("Dumped vendor info to server console.") end
end)

function ENT:Initialize()
	self:SetModel("models/Humans/Group01/male_07.mdl")
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
		local name = self.MonarchSaveData.name or "Rank Vendor"
		local desc = self.MonarchSaveData.desc or "Purchase ranks"
		local model = self.MonarchSaveData.model or self:GetModel()
		local teams = self.MonarchSaveData.teams or ""
		local team = tonumber(self.MonarchSaveData.team or 0) or 0

		self:SetRankVendorID(vendorID)
		self:SetVendorName(name)
		self:SetVendorDesc(desc)
		self:SetModel(model)
		
		if teams and teams ~= "" then
			self:SetRequiredTeamsStr(teams)
		elseif team > 0 then
			self:SetRequiredTeam(team)
		end
	else
		self:SetRankVendorID("default")
		self:SetVendorName("Rank Vendor")
		self:SetVendorDesc("Purchase ranks and promotions")
		self:SetRequiredTeam(0)
	end

	if Monarch and Monarch.RankVendors and Monarch.RankVendors[self:GetRankVendorID()] then
		local cfg = Monarch.RankVendors[self:GetRankVendorID()]
		if cfg.model then self:SetModel(cfg.model) end
		if cfg.name then self:SetVendorName(cfg.name) end
		if cfg.desc then self:SetVendorDesc(cfg.desc) end
		
		-- Support both single team and multiple teams
		if cfg.teams ~= nil then
			-- Multiple teams
			self:SetRequiredTeams(cfg.teams)
		elseif cfg.team ~= nil then
			-- Single team (backward compatibility)
			self:SetRequiredTeams(tonumber(cfg.team) or 0)
		end
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

	Vendor_Register(ent)

	return ent
end

function ENT:Use(activator, caller)
	if not IsValid(activator) or not activator:IsPlayer() then return end
	if (activator._rankVendorNext or 0) > CurTime() then return end
	activator._rankVendorNext = CurTime() + 0.5

	if not activator:Alive() then return end

	if not self:IsPlayerTeamAllowed(activator) then
		local allowedTeams = self:GetRequiredTeamsTable()
		local teamNames = {}
		for _, teamId in ipairs(allowedTeams) do
			table.insert(teamNames, team.GetName(teamId) .. " (" .. teamId .. ")")
		end
		local msg = "You must be on one of these teams: " .. table.concat(teamNames, ", ")
		if activator.Notify then
			activator:Notify(msg)
		end
		return
	end

	local vendorID = self:GetRankVendorID()
	local ranks = {}
	local vendorConfig = nil

	if Monarch and Monarch.RankVendors and Monarch.RankVendors[vendorID] then
		vendorConfig = Monarch.RankVendors[vendorID]
		ranks = vendorConfig.ranks or {}
	end

	local function isEligible(ply, vend, r, silent)
		if r.team and r.team > 0 and ply:Team() ~= r.team then
			return false, "Wrong team"
		end

		local custom = r.CustomCheck or r.customCheck
		if isfunction(custom) then
			local ok, rsn = pcall(custom, ply, vend, r)
			if ok and rsn ~= nil then 
				if rsn == false then
					return false, select(2, pcall(custom, ply, vend, r)) or "Not eligible" 
				end
			elseif not ok then
				return false, "CustomCheck error"
			end
			local allowed, reason = custom(ply, vend, r)
			if allowed == false then return false, reason or "Not eligible" end
		end

		if r.whitelistLevel then
			local teamForWL = r.team or vend:GetRequiredTeam() or 0
			if teamForWL > 0 then
				if not (ply.HasWhitelist and ply:HasWhitelist(teamForWL, r.whitelistLevel)) then
					return false, r.lockedReason or "Whitelist required"
				end
			end
		end

		if r.requiredWhitelistTeam and r.requiredWhitelistLevel then
			if not (ply.HasWhitelist and ply:HasWhitelist(r.requiredWhitelistTeam, r.requiredWhitelistLevel)) then
				return false, r.lockedReason or "Insufficient whitelist level"
			end
		end

		local wl = r.whitelist
		if istable(wl) then
			local ok = false
			if istable(wl.steamids) then
				local sid64 = (ply.SteamID64 and ply:SteamID64()) or ""
				local sid = (ply.SteamID and ply:SteamID()) or ""
				for _, id in ipairs(wl.steamids) do
					if id == sid64 or id == sid then ok = true break end
				end
			end
			if not ok and istable(wl.usergroups) then
				local grp = (ply.GetUserGroup and ply:GetUserGroup()) or "user"
				for _, g in ipairs(wl.usergroups) do
					if isstring(g) and string.lower(g) == string.lower(grp) then ok = true break end
				end
			end
			if not ok and istable(wl.teams) then
				for _, t in ipairs(wl.teams) do
					if tonumber(t) == ply:Team() then ok = true break end
				end
			end
			if not ok then
				return false, r.lockedReason or "Not whitelisted"
			end
		end

		if isfunction(r.canPurchase) then
			local ok, reason = r.canPurchase(ply, r, vend)
			if ok == false then return false, reason or "Not eligible" end
		end

		if isfunction(r.CanBuy) then
			local ok, rsn = r.CanBuy(ply, vend, r, silent)
			if ok == false then return false, rsn or "Cannot afford" end
		end
		if vendorConfig and isfunction(vendorConfig.CanBuy) then
			local ok, rsn = vendorConfig.CanBuy(ply, vend, r, silent)
			if ok == false then return false, rsn or "Cannot purchase" end
		end
		if isfunction(vend.CanBuy) then
			local ok, rsn = vend:CanBuy(ply, r, silent)
			if ok == false then return false, rsn or "Cannot purchase" end
		end

		local hok, hreason = hook.Run("Monarch.RankVendorCustomCheck", ply, vend, r)
		if hok == false then return false, hreason or "Access denied" end
		if hok == true then return true end
		return true
	end

	net.Start("Monarch_RankVendor_Open")
		net.WriteEntity(self)
		net.WriteString(self:GetVendorName())
		net.WriteString(self:GetVendorDesc())
		net.WriteUInt(#ranks, 16)
		for _, rank in ipairs(ranks) do
			net.WriteString(rank.id or "")
			net.WriteString(rank.name or "Rank")
			net.WriteString(rank.desc or "")
			net.WriteString(rank.model or "")
			net.WriteUInt(rank.price or 0, 32)
			net.WriteUInt(rank.team or 0, 16)
			net.WriteString(rank.group or "")
			net.WriteString(rank.grouprank or "")
			local allowed, reason = isEligible(activator, self, rank, true)
			net.WriteBool(allowed and true or false)
			net.WriteString(reason or "")

			net.WriteUInt(rank.whitelistLevel or 0, 8)
			net.WriteUInt(rank.requiredWhitelistTeam or 0, 16)
			net.WriteUInt(rank.requiredWhitelistLevel or 0, 8)
		end
	net.Send(activator)
end

net.Receive("Monarch_RankVendor_Select", function(len, ply)
	if not IsValid(ply) then return end
	local vendor = net.ReadEntity()
	local rankID = net.ReadString()

	local prevPos = ply:GetPos()
	local prevAng = ply:EyeAngles()

	if not IsValid(vendor) or vendor:GetClass() ~= "monarch_rankvendor" then return end
	if vendor:GetPos():Distance(ply:GetPos()) > 200 then return end

	local vendorID = vendor:GetRankVendorID()
	if not Monarch or not Monarch.RankVendors or not Monarch.RankVendors[vendorID] then
		if ply.Notify then ply:Notify("Rank vendor not configured.") end
		return
	end

	local vendorData = Monarch.RankVendors[vendorID]
	local rankData = nil

	for _, rank in ipairs(vendorData.ranks or {}) do
		if rank.id == rankID then
			rankData = rank
			break
		end
	end

	if not rankData then
		if ply.Notify then ply:Notify("Rank not found.") end
		return
	end

	if vendorID == "workforce_terminal" and rankData.id ~= "wrk_offduty" then
		if not (Monarch and Monarch.Dispatch and Monarch.Dispatch.IsWorkforceIntakeActive and Monarch.Dispatch.IsWorkforceIntakeActive()) then
			if ply.Notify then
				ply:Notify("Workforce intake is not currently active.")
			end
			return
		end
	end

	if rankData.team and rankData.team > 0 and ply:Team() ~= rankData.team then
		if ply.Notify then ply:Notify("You must be on the correct team.") end
		return
	end

	local function UnequipAllInventoryItems(targetPly)
		if not IsValid(targetPly) then return end

		if targetPly.SetInventoryItemEquipped then
			for slot = 1, 30 do
				pcall(function()
					targetPly:SetInventoryItemEquipped(slot, false)
				end)
			end
			return
		end

		local charID = (targetPly.MonarchActiveChar and targetPly.MonarchActiveChar.id) or targetPly.MonarchID or targetPly.MonarchLastCharID
		if not charID then return end

		Monarch.Inventory = Monarch.Inventory or {}
		Monarch.Inventory.Data = Monarch.Inventory.Data or {}
		local invStore = Monarch.Inventory.Data[charID]
		if not (istable(invStore) and istable(invStore[1])) then return end

		local inv = invStore[1]
		for _, item in pairs(inv) do
			if istable(item) and item.equipped then
				local class = item.class or item.id
				local def = nil
				if Monarch.Inventory.ItemsRef and Monarch.Inventory.Items and class then
					local idx = Monarch.Inventory.ItemsRef[class]
					if idx then
						def = Monarch.Inventory.Items[idx]
					end
				end
				if def and def.WeaponClass then
					targetPly:StripWeapon(def.WeaponClass)
				end
				item.equipped = false
			end
		end

		if Monarch.Inventory.SaveForOwner then
			Monarch.Inventory.SaveForOwner(targetPly, charID, inv)
		end
		if Monarch.SaveInventoryPData then
			Monarch.SaveInventoryPData(targetPly, inv)
		end
		if targetPly.SyncInventory then
			targetPly:SyncInventory()
		end
	end

	local function isEligible(p, vend, r, silent)
		if r.team and r.team > 0 and p:Team() ~= r.team then
			return false, "Wrong team"
		end

		local custom = r.CustomCheck or r.customCheck
		if isfunction(custom) then
			local allowed, reason = custom(p, vend, r)
			if allowed == false then return false, reason or "Not eligible" end
		end

		if r.whitelistLevel then

			local teamForWL = r.team
			if not teamForWL or teamForWL == 0 then
				teamForWL = p:Team()
			end
			if not teamForWL or teamForWL == 0 then
				teamForWL = vend:GetRequiredTeam() or 0
			end
			if teamForWL > 0 then
				if not (p.HasWhitelist and p:HasWhitelist(teamForWL, r.whitelistLevel)) then
					return false, r.lockedReason or "Whitelist required"
				end
			end
		end
		if r.requiredWhitelistTeam and r.requiredWhitelistLevel then
			if not (p.HasWhitelist and p:HasWhitelist(r.requiredWhitelistTeam, r.requiredWhitelistLevel)) then
				return false, r.lockedReason or "Insufficient whitelist level"
			end
		end
		local wl = r.whitelist
		if istable(wl) then
			local ok = false
			if istable(wl.steamids) then
				local sid64 = (p.SteamID64 and p:SteamID64()) or ""
				local sid = (p.SteamID and p:SteamID()) or ""
				for _, id in ipairs(wl.steamids) do
					if id == sid64 or id == sid then ok = true break end
				end
			end
			if not ok and istable(wl.usergroups) then
				local grp = (p.GetUserGroup and p:GetUserGroup()) or "user"
				for _, g in ipairs(wl.usergroups) do
					if isstring(g) and string.lower(g) == string.lower(grp) then ok = true break end
				end
			end
			if not ok and istable(wl.teams) then
				for _, t in ipairs(wl.teams) do
					if tonumber(t) == p:Team() then ok = true break end
				end
			end
			if not ok then
				return false, r.lockedReason or "Not whitelisted"
			end
		end
		if isfunction(r.canPurchase) then
			local ok, rsn = r.canPurchase(p, r, vend)
			if ok == false then return false, rsn or "Not eligible" end
		end

		if isfunction(r.CanBuy) then
			local ok, rsn = r.CanBuy(p, vend, r, silent)
			if ok == false then return false, rsn or "Cannot afford" end
		end
		if vendorData and isfunction(vendorData.CanBuy) then
			local ok, rsn = vendorData.CanBuy(p, vend, r, silent)
			if ok == false then return false, rsn or "Cannot purchase" end
		end
		if isfunction(vend.CanBuy) then
			local ok, rsn = vend:CanBuy(p, r, silent)
			if ok == false then return false, rsn or "Cannot purchase" end
		end
		local hok, hreason = hook.Run("Monarch.RankVendorCustomCheck", p, vend, r)
		if hok == false then return false, hreason or "Access denied" end
		if hok == true then return true end
		return true
	end
	local allowed, reason = isEligible(ply, vendor, rankData, false)
	if not allowed then
		if ply.Notify then ply:Notify(reason or "You are not allowed to select this rank.") end
		return
	end

	UnequipAllInventoryItems(ply)

	if ply.RemoveConstrainedItems then
		ply:RemoveConstrainedItems()
	end

	-- Only set team if the rank defines one (temporary only, no DB save)
	if rankData.team and rankData.team > 0 then
		ply:SetTeam(rankData.team)
	end

	if rankData.model and util.IsValidModel(rankData.model) then
		ply:SetModel(rankData.model)
	end

	if rankData.group and rankData.group ~= "" then
		if ply.SetRPGroup then
			ply:SetRPGroup(rankData.group)
		end

		if ply.MonarchActiveChar and mysql then
			ply.MonarchActiveChar.rpgroup = rankData.group
			local q = mysql:Update("monarch_players")
			q:Update("rpgroup", rankData.group)
			q:Where("id", ply.MonarchActiveChar.id)
			q:Execute()
		end
	end

	if rankData.grouprank and rankData.grouprank ~= "" then
		if ply.SetRPGroupRank then
			ply:SetRPGroupRank(rankData.grouprank)
		end

		if ply.MonarchActiveChar and mysql then
			ply.MonarchActiveChar.rpgrouprank = rankData.grouprank
			local q = mysql:Update("monarch_players")
			q:Update("rpgrouprank", rankData.grouprank)
			q:Where("id", ply.MonarchActiveChar.id)
			q:Execute()
		end
	end

	if ply.Notify then
		ply:Notify("You have clocked in for your shift as a " .. (rankData.name or "nil") .. ".")
	end

	if rankData.respawn then
		timer.Simple(0.5, function()
			if IsValid(ply) then
				ply:Spawn()

				if isvector(prevPos) then ply:SetPos(prevPos) end

				if isfunction(rankData.onBecome) then
					safeCall = true
					local ok, err = pcall(rankData.onBecome, ply)
					if not ok then
						print("[Monarch] RankVendor onBecome error: ", err)
					end
				end
			end
		end)
	else

		if isvector(prevPos) then ply:SetPos(prevPos) end

		if isfunction(rankData.onBecome) then
			local ok, err = pcall(rankData.onBecome, ply)
			if not ok then
				print("[Monarch] RankVendor onBecome error: ", err)
			end
		end
	end
end)

Monarch = Monarch or {}
Monarch.RankVendors = Monarch.RankVendors or {}

Monarch.RankVendors["default"] = {
	name = "Rank Recruiter",
	desc = "Purchase ranks and promotions",
	model = "models/Humans/Group01/male_07.mdl",
	team = 0, 
	ranks = {

	}
}
