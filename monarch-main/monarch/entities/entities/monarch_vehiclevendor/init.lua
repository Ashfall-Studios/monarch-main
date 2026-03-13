AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("Monarch_VehicleVendorOpen")
util.AddNetworkString("Monarch_VehicleVendorSpawn")
util.AddNetworkString("Monarch_VehicleVendorNotify")

Monarch = Monarch or {}
Monarch.VehicleVendors = Monarch.VehicleVendors or {}
Monarch.VehicleOwnership = Monarch.VehicleOwnership or {}
Monarch.VehicleVendorRegistry = Monarch.VehicleVendorRegistry or { list = {} }
Monarch._removedVehicleVendorUIDs = Monarch._removedVehicleVendorUIDs or {}

local function EnsureMapDir()
	file.CreateDir("monarch")
	file.CreateDir("monarch/maps")
	file.CreateDir("monarch/maps/" .. game.GetMap())
end

local function VehicleOwnershipPath()
	return "monarch/maps/" .. game.GetMap() .. "/vehicle_ownership.json"
end

local function VehicleVendorPersistPath()
	return "monarch/maps/" .. game.GetMap() .. "/vehiclevendors.json"
end

local function LoadVehicleOwnership()
	EnsureMapDir()
	if file.Exists(VehicleOwnershipPath(), "DATA") then
		local data = util.JSONToTable(file.Read(VehicleOwnershipPath(), "DATA") or "{}") or {}
		Monarch.VehicleOwnership = data
	end
end

local function SaveVehicleOwnership()
	EnsureMapDir()
	file.Write(VehicleOwnershipPath(), util.TableToJSON(Monarch.VehicleOwnership, true))
end

local function GetPlayerVehicles(ply)
	local charID = ply.MonarchID or (ply.MonarchActiveChar and ply.MonarchActiveChar.id) or ply.MonarchLastCharID
	if not charID then return {} end
	return Monarch.VehicleOwnership[tostring(charID)] or {}
end

local function AddPlayerVehicle(ply, vehClass)
	local charID = ply.MonarchID or (ply.MonarchActiveChar and ply.MonarchActiveChar.id) or ply.MonarchLastCharID
	if not charID then return false end
	Monarch.VehicleOwnership[tostring(charID)] = Monarch.VehicleOwnership[tostring(charID)] or {}
	if not table.HasValue(Monarch.VehicleOwnership[tostring(charID)], vehClass) then
		table.insert(Monarch.VehicleOwnership[tostring(charID)], vehClass)
		SaveVehicleOwnership()
		return true
	end
	return false
end

local function PlayerOwnsVehicle(ply, vehClass)
	local owned = GetPlayerVehicles(ply)
	return table.HasValue(owned, vehClass)
end

local function DespawnPlayerVehicles(ply)
	for _, veh in ipairs(ents.GetAll()) do
		if IsValid(veh) and veh._MonarchOwner == ply then
			veh:Remove()
		end
	end
end

local function VehicleVendor_Register(ent)
	if not IsValid(ent) then return end
	Monarch.VehicleVendorRegistry.list = Monarch.VehicleVendorRegistry.list or {}
	local uid = "vehiclevendor_" .. tostring(ent:EntIndex()) .. "_" .. math.floor(CurTime())
	ent._persistUID = uid
	local rec = {
		class = ent:GetClass(),
		uid = uid,
		pos = { x = ent:GetPos().x, y = ent:GetPos().y, z = ent:GetPos().z },
		ang = { p = ent:GetAngles().p, y = ent:GetAngles().y, r = ent:GetAngles().r },
		model = ent:GetModel(),
		vendorID = ent.GetVendorID and ent:GetVendorID() or "default",
		name = ent.GetVendorName and ent:GetVendorName() or "Vehicle Vendor",
		desc = ent.GetVendorDesc and ent:GetVendorDesc() or "Purchase and spawn vehicles",
		team = ent.GetRequiredTeam and ent:GetRequiredTeam() or 0
	}
	Monarch.VehicleVendorRegistry.list[uid] = rec
end

local function VehicleVendor_SaveAll()
	EnsureMapDir()

	local existingData = {}
	if file.Exists(VehicleVendorPersistPath(), "DATA") then
		local existing = util.JSONToTable(file.Read(VehicleVendorPersistPath(), "DATA") or "{}") or {}
		existingData = existing.list or {}
	end

	local spawnedUIDs = {}
	local list = {}

	for _, ent in ipairs(ents.FindByClass("monarch_vehiclevendor")) do
		if IsValid(ent) then
			local pos = ent:GetPos()
			local ang = ent:GetAngles()
			local uid = ent._persistUID or ("vehiclevendor_" .. tostring(ent:EntIndex()))
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
				name = ent.GetVendorName and ent:GetVendorName() or "Vehicle Vendor",
				desc = ent.GetVendorDesc and ent:GetVendorDesc() or "Purchase and spawn vehicles",
				team = team
			}
		end
	end

	for _, rec in ipairs(existingData) do
		if not spawnedUIDs[rec.uid] and not Monarch._removedVehicleVendorUIDs[rec.uid] then
			list[#list + 1] = rec
		end
	end

	local payload = { list = list }
	file.Write(VehicleVendorPersistPath(), util.TableToJSON(payload, false))
	print("[Monarch] Vehicle vendors saved (" .. #list .. " vendors)")
	Monarch._removedVehicleVendorUIDs = {}
end

Monarch.VehicleVendor_SaveAll = VehicleVendor_SaveAll

local function VehicleVendor_SaveSingle(ent)
	if not IsValid(ent) or ent:GetClass() ~= "monarch_vehiclevendor" then return end

	EnsureMapDir()

	local existingData = {}
	if file.Exists(VehicleVendorPersistPath(), "DATA") then
		local t = util.JSONToTable(file.Read(VehicleVendorPersistPath(), "DATA") or "{}") or {}
		existingData = t.list or {}
	end

	local uid = ent._persistUID or ("vehiclevendor_" .. tostring(ent:EntIndex()) .. "_" .. math.floor(CurTime()))
	if not ent._persistUID then ent._persistUID = uid end

	local found = false
	local list = {}

	for _, rec in ipairs(existingData) do
		if Monarch._removedVehicleVendorUIDs[rec.uid] then
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
				name = (ent.GetVendorName and ent:GetVendorName()) or "Vehicle Vendor",
				desc = (ent.GetVendorDesc and ent:GetVendorDesc()) or "Purchase and spawn vehicles",
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
			name = (ent.GetVendorName and ent:GetVendorName()) or "Vehicle Vendor",
			desc = (ent.GetVendorDesc and ent:GetVendorDesc()) or "Purchase and spawn vehicles",
			team = (ent.GetRequiredTeam and ent:GetRequiredTeam()) or 0
		}
	end

	local payload = { list = list }
	file.Write(VehicleVendorPersistPath(), util.TableToJSON(payload, true))
	print("[Monarch] Vehicle vendor saved: " .. uid)
end

Monarch.VehicleVendor_SaveSingle = VehicleVendor_SaveSingle

local function VehicleVendor_LoadAll()
	Monarch.VehicleVendorRegistry.list = {}
	EnsureMapDir()
	if not file.Exists(VehicleVendorPersistPath(), "DATA") then return end
	local t = util.JSONToTable(file.Read(VehicleVendorPersistPath(), "DATA") or "{}") or {}
	local list = t.list or {}
	for _, rec in pairs(list) do
		if rec.class == "monarch_vehiclevendor" then
			local ent = ents.Create("monarch_vehiclevendor")
			if IsValid(ent) then
				ent:SetPos(Vector(rec.pos.x, rec.pos.y, rec.pos.z))
				ent:SetAngles(Angle(rec.ang.p, rec.ang.y, rec.ang.r))
				ent:SetModel(rec.model or "models/Humans/Group01/male_02.mdl")
				ent:SetVendorID(rec.vendorID or "default")
				ent:SetVendorName(rec.name or "Vehicle Vendor")
				ent:SetVendorDesc(rec.desc or "Purchase and spawn vehicles")
				ent.MonarchSaveData = rec
				ent:Spawn()
				VehicleVendor_Register(ent)
			end
		end
	end
end

hook.Add("InitPostEntity", "Monarch_LoadVehicleVendors", function()
	VehicleVendor_LoadAll()
end)

function ENT:Initialize()
	self:SetModel("models/Humans/Group01/male_02.mdl")
	self:SetSolid(SOLID_BBOX)
	self:SetUseType(SIMPLE_USE)
	self:DropToFloor()

	local seq = self:LookupSequence("idle_all_01") or self:LookupSequence("idle") or 0
	self:ResetSequence(seq)
	self:SetPlaybackRate(1)

	if self.MonarchSaveData then
		local vendorID = self.MonarchSaveData.vendorID or "default"
		local name = self.MonarchSaveData.name or "Vehicle Vendor"
		local desc = self.MonarchSaveData.desc or "Purchase and spawn vehicles"
		local model = self.MonarchSaveData.model or self:GetModel()
		local team = tonumber(self.MonarchSaveData.team or 0) or 0

		self:SetVendorID(vendorID)
		self:SetVendorName(name)
		self:SetVendorDesc(desc)
		self:SetModel(model)
		self:SetRequiredTeam(team)
	else
		self:SetVendorID("default")
		self:SetVendorName("Vehicle Vendor")
		self:SetVendorDesc("Purchase and spawn vehicles")
		self:SetRequiredTeam(0)
	end

	if Monarch and Monarch.VehicleVendors and Monarch.VehicleVendors[self:GetVendorID()] then
		local cfg = Monarch.VehicleVendors[self:GetVendorID()]
		if cfg.model then self:SetModel(cfg.model) end
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

function ENT:Use(activator)
	if not IsValid(activator) or not activator:IsPlayer() then return end

	local vendorID = self:GetVendorID()
	if not Monarch or not Monarch.VehicleVendors or not Monarch.VehicleVendors[vendorID] then
		if activator.Notify then activator:Notify("Vehicle vendor not configured.") end
		return
	end

	local vendorData = Monarch.VehicleVendors[vendorID]
	local owned = GetPlayerVehicles(activator)

	net.Start("Monarch_VehicleVendorOpen")
		net.WriteEntity(self)
		net.WriteString(vendorData.name or "Vehicle Vendor")
		net.WriteString(vendorData.desc or "Purchase and spawn vehicles")
		net.WriteUInt(#(vendorData.vehicles or {}), 8)

		for _, veh in ipairs(vendorData.vehicles or {}) do
			local eligible = true

			if isfunction(veh.CustomCheck) then
				local ok, res = pcall(veh.CustomCheck, activator, self, veh)
				eligible = ok and (res ~= false)
			end

			local vehModel = veh.model or ""
			if vehModel == "" then
				local vehList = list.Get("Vehicles")
				if vehList and vehList[veh.class] and vehList[veh.class].Model then
					vehModel = vehList[veh.class].Model
				else
					local entTable = scripted_ents.GetStored(veh.class)
					if entTable and entTable.t and entTable.t.SpawnMenuModel then
						vehModel = entTable.t.SpawnMenuModel
					elseif entTable and entTable.t and entTable.t.Model then
						vehModel = entTable.t.Model
					end
				end
			end

			net.WriteString(veh.class or "")
			net.WriteString(veh.name or "Vehicle")
			net.WriteString(veh.desc or "")
			net.WriteString(vehModel)
			net.WriteUInt(tonumber(veh.price) or 0, 32)
			net.WriteBool(PlayerOwnsVehicle(activator, veh.class))
			net.WriteBool(eligible)
		end
	net.Send(activator)
end

net.Receive("Monarch_VehicleVendorSpawn", function(len, ply)
	if not IsValid(ply) then return end
	local vendor = net.ReadEntity()
	local vehClass = net.ReadString()

	if not IsValid(vendor) or vendor:GetClass() ~= "monarch_vehiclevendor" then return end
	if vendor:GetPos():Distance(ply:GetPos()) > 300 then return end

	local vendorID = vendor:GetVendorID()
	if not Monarch or not Monarch.VehicleVendors or not Monarch.VehicleVendors[vendorID] then
		if ply.Notify then ply:Notify("Vehicle vendor not configured.") end
		return
	end

	local vendorData = Monarch.VehicleVendors[vendorID]
	local vehData = nil

	for _, veh in ipairs(vendorData.vehicles or {}) do
		if veh.class == vehClass then
			vehData = veh
			break
		end
	end

	if not vehData then
		if ply.Notify then ply:Notify("Vehicle not found.") end
		return
	end

	if isfunction(vehData.CustomCheck) then
		local ok, res = pcall(vehData.CustomCheck, ply, vendor, vehData)
		if not ok or res == false then
			if ply.Notify then ply:Notify("You are not eligible to spawn this vehicle.") end
			return
		end
	end

	local alreadyOwned = PlayerOwnsVehicle(ply, vehClass)
	local price = tonumber(vehData.price) or 0

	if not alreadyOwned and price > 0 then
		local wallet = tonumber(ply:GetNWInt("Money", 0)) or 0
		if wallet <= 0 and ply.MonarchActiveChar then
			wallet = tonumber(ply.MonarchActiveChar.money or 0) or 0
		end

		if wallet < price then
			if ply.Notify then ply:Notify("You don't have enough money.") end
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

		AddPlayerVehicle(ply, vehClass)
		if ply.Notify then
			ply:Notify("Purchased " .. (vehData.name or "vehicle") .. " for $" .. price)
		end
	end

	DespawnPlayerVehicles(ply)

	local spawnPos = vendor:GetPos() + vendor:GetForward() * 200 + Vector(0, 0, 80)
	local spawnAng = vendor:GetAngles()
	spawnAng:RotateAroundAxis(spawnAng:Up(), 180)

	local vehicle = ents.Create(vehClass)
	if not IsValid(vehicle) then
		if ply.Notify then ply:Notify("Failed to spawn vehicle (invalid class).") end
		return
	end

	vehicle:SetPos(spawnPos)
	vehicle:SetAngles(spawnAng)
	vehicle._MonarchOwner = ply
	vehicle:Spawn()
	vehicle:Activate()

	if vehicle.CPPISetOwner then
		vehicle:CPPISetOwner(ply)
	end

	if ply.Notify then
		ply:Notify("Spawned " .. (vehData.name or "vehicle") .. ". Your previous vehicle was despawned.")
	end
end)

hook.Add("InitPostEntity", "Monarch_LoadVehicleOwnership", function()
	LoadVehicleOwnership()
end)

hook.Add("PlayerDisconnected", "Monarch_VehicleVendor_Cleanup", function(ply)
	DespawnPlayerVehicles(ply)
end)
