local function Monarch_StatusTick()
	local cfg = Monarch and Monarch.Status or nil
	if not cfg then return end

	for _, ply in ipairs(player.GetAll()) do
		if not IsValid(ply) or not ply:Alive() then continue end

        if ply.GetHunger then
            local hunger = ply:GetHunger() or 0
			if hunger <= (cfg.HungerThreshold or 5) then
				ply._monarchNextStarve = ply._monarchNextStarve or 0
				if CurTime() >= ply._monarchNextStarve then
					ply._monarchNextStarve = CurTime() + (cfg.StarveTick or 1)
					if ply:Health() > (cfg.StarveMinHP or 3) then
						local dmg = DamageInfo()
						dmg:SetDamage(cfg.StarveDamage or 1)
						dmg:SetDamageType(DMG_NERVEGAS)
						dmg:SetAttacker(game.GetWorld())
						dmg:SetInflictor(game.GetWorld())
						ply:TakeDamageInfo(dmg)
					end
				end
			end
        end

		if ply.IsBleeding and ply:IsBleeding() and ply:Health() > cfg.BleedMinHP then
			ply._monarchNextBleed = ply._monarchNextBleed or 0
			if CurTime() >= ply._monarchNextBleed then
				ply._monarchNextBleed = CurTime() + (cfg.BleedTick or 2)
				local dmg = DamageInfo()
				dmg:SetDamage(cfg.BleedDamage or 2)
				dmg:SetDamageType(DMG_SLASH)
				dmg:SetAttacker(game.GetWorld())
				dmg:SetInflictor(game.GetWorld())
				ply:TakeDamageInfo(dmg)
				if ply:Health() <= 10 and math.random() < 0.1 then
					ply:SetBleeding(false)
				end
			end
		end

		if ply.HasDisease and ply:HasDisease() and ply:Health() > 1 then
			ply._monarchNextDisease = ply._monarchNextDisease or 0
			if CurTime() >= ply._monarchNextDisease then
				ply._monarchNextDisease = CurTime() + (cfg.DiseaseTick or 3)
				local dmg = DamageInfo()
				dmg:SetDamage(cfg.DiseaseDamage or 1)
				dmg:SetDamageType(DMG_POISON)
				dmg:SetAttacker(game.GetWorld())
				dmg:SetInflictor(game.GetWorld())
				ply:TakeDamageInfo(dmg)
			end
		end
	end
end

hook.Add("Think", "Monarch_Status_Tick", Monarch_StatusTick)

hook.Add("PlayerDeath", "MonarchSchema_ClearGasMask", function(ply)
	if IsValid(ply) then
		ply.HasGasMask = false
		ply:SetNWBool("MonarchHasGasMask", false)
		ply:SetBodygroup(9, 0)
	end
end)

hook.Add("PlayerSpawn", "MonarchSchema_ClearGasMaskOnSpawn", function(ply)
	if IsValid(ply) then
		ply.HasGasMask = false
		ply:SetNWBool("MonarchHasGasMask", false)
		ply:SetBodygroup(9, 0)
	end
end)

hook.Add("PlayerDisconnected", "MonarchSchema_ClearGasMaskOnDisconnect", function(ply)
	if IsValid(ply) then
		ply.HasGasMask = false
		ply:SetNWBool("MonarchHasGasMask", false)
	end
end)

local CURFEW_START_HOUR = 3
local CURFEW_END_HOUR = 6
local CURFEW_START_SOUND = "overwatch/citywide/other_languages/overwatch_russian_offworldrelocation.mp3"
local CURFEW_END_SOUND = "overwatch/citywide/other_languages/overwatch_russian_inactionconspiracy.mp3"

local curfewActive = false
local lastHour = -1

util.AddNetworkString("Curfew_Start")
util.AddNetworkString("Curfew_End")
util.AddNetworkString("Curfew_SyncTime")

local function GetGameHour()
	local cycleTime = 3600 / 1.5
	local posInCycle = CurTime() % cycleTime
	local hour = math.floor((posInCycle / cycleTime) * 24)
	return hour
end

local function IsCurfewTime(hour)
	return hour >= CURFEW_START_HOUR and hour < CURFEW_END_HOUR
end

local function BroadcastCurfewStart()
	net.Start("Curfew_Start")
	net.Broadcast()
end

local function BroadcastCurfewEnd()
	net.Start("Curfew_End")
	net.Broadcast()
end

hook.Add("Think", "Monarch_CurfewCheck", function()
	local currentHour = GetGameHour()

	if currentHour == lastHour then return end

	local wasInCurfew = IsCurfewTime(lastHour)
	local shouldBeCurfew = IsCurfewTime(currentHour)

	if shouldBeCurfew and not wasInCurfew then
		curfewActive = true
		BroadcastCurfewStart()
	end

	if not shouldBeCurfew and wasInCurfew then
		curfewActive = false
		BroadcastCurfewEnd()
	end

	lastHour = currentHour
end)

hook.Add("PlayerInitialSpawn", "Monarch_CurfewSync", function(ply)
	timer.Simple(0.5, function()
		if not IsValid(ply) then return end

		local hour = GetGameHour()
		net.Start("Curfew_SyncTime")
			net.WriteUInt(hour, 8)
		net.Send(ply)

		if IsCurfewTime(hour) then
			net.Start("Curfew_Start")
			net.Send(ply)
		end
	end)
end)

Monarch = Monarch or {}
Monarch.Loyalty = Monarch.Loyalty or {}

if not Monarch.Loyalty._charScoped then
	AddCSLuaFile("monarch-ebrp/modules/loyalty/sh_lyt.lua")
	AddCSLuaFile("monarch-ebrp/modules/loyalty/cl_lyt.lua")
	include("monarch-ebrp/modules/loyalty/sh_lyt.lua")
	include("monarch-ebrp/modules/loyalty/sv_lyt.lua")
end
