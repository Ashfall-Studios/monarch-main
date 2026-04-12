AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

local THIRST_DECAY = 2
local HUNGER_DECAY = 3
local EXHAUSTION_DECAY = 2.5
local TICK_TIME = 90 -- ! Time each seperately via config values

if SERVER then
    timer.Create("PlayerNeedsTimer", TICK_TIME, 0, function()
        for _, ply in player.Iterator() do
            if ply.ShouldNeedsLower == false then return end
            if not IsValid(ply) then continue end

            local teamData = (Monarch and Monarch.Team and Monarch.Team[ply:Team()]) or nil
            local hungerFactor = tonumber(teamData and teamData.hungerFactor) or 1
            local hungerDecay = math.max(0, HUNGER_DECAY * hungerFactor)

            local newHydration = math.max(ply:GetNWInt("Hydration", 100) - THIRST_DECAY, 0)
            local newHunger = math.max(ply:GetNWInt("Hunger", 100) - hungerDecay, 0)
            local newExhaustion = math.max(ply:GetNWInt("Exhaustion", 100) - EXHAUSTION_DECAY, 0)

            ply:SetNWInt("Hydration", newHydration)
            ply:SetNWInt("Hunger", newHunger)
            ply:SetNWInt("Exhaustion", newExhaustion)
        end
    end)
end

if SERVER then
    Monarch = Monarch or {}
    Monarch.Loot = Monarch.Loot or { Defs = Monarch.Loot and Monarch.Loot.Defs or {}, Ref = Monarch.Loot and Monarch.Loot.Ref or {} }
    timer.Simple(0, function()
        if not (Monarch and Monarch.RegisterLoot) then return end
        if Monarch.Loot and Monarch.Loot.Defs and Monarch.Loot.Defs["test_loot"] then return end
        Monarch.RegisterLoot({
            UniqueID = "test_loot",
            UseName = "Opening Crate...",
            Model = "models/props_junk/wood_crate001a.mdl",
            OpenTime = 1.2,
            OpenSound = "foley/containers/wood_wardrobe_open.mp3",
            CloseSound = "foley/containers/wood_wardrobe_close.mp3",
            CanStore = false,
            CapacityX = 5,
            CapacityY = 2,
            LootTable = {
                mat_screws = { rolls = 6, rarity = 1 },
                food_bread = { rolls = 1, rarity = 4 },
            }
        })
    end)

    -- Handy command to spawn a test loot crate at your aim pos
    concommand.Add("monarch_spawn_testloot", function(ply)
        if not IsValid(ply) or not ply:IsAdmin() then return end
        local tr = ply:GetEyeTrace()
        if not tr or not tr.HitPos then return end
        local ent = ents.Create("monarch_loot")
        if not IsValid(ent) then return end
        ent:SetPos(tr.HitPos + Vector(0,0,10))
        ent:Spawn()
        ent:Activate()
        if ent.CPPISetOwner then pcall(function() ent:CPPISetOwner(ply) end) end
        if ent.SetLootDef then ent:SetLootDef("test_loot") end
    end, nil, "Spawn a temporary test loot crate with 'test_loot' definition at your aim position.")
end

hook.Add( "OnNPCDropItem", "Monarch.RemoveNPCDrops", function( npc, item )
	item:Remove()
end)

hook.Add("PlayerDroppedWeapon", "PrintWhenDrop", function(owner, wep)
	wep:Remove()
end)