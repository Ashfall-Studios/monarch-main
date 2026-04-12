AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_interiors/SinkKitchen01a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end
end

function ENT:Use(activator, caller)
    local ply = IsValid(activator) and activator or caller
    if not IsValid(ply) or not ply:IsPlayer() then return end

    net.Start("Monarch_DrinkStart")
        net.WriteEntity(self)
    net.Send(ply)
end

function ENT:Drink(ply)
    local hydration = ply:GetHydration()
    ply:SetHydration(math.min(hydration + 25, 100))

    local chance = math.random(1, 100)

    if chance <= 25 then

        ply:SetHealth(math.min(ply:Health() - math.random(1,8), ply:GetMaxHealth()))
        ply:EmitSound("impulse_redux/misc/tc_breathing.wav")
        ply:EmitSound("player/pl_pain6.wav")
    end
end