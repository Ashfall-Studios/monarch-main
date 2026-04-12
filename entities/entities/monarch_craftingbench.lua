AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Crafting Bench"
ENT.Category = "Monarch"
ENT.Spawnable = true

ENT.HUDDisplayText = "Interact with this to craft new items."
ENT.ShouldShowContext = false

function ENT:Initialize()
    if SERVER then
        self:SetModel("models/mosi/fallout76/furniture/workstations/tinkerstation.mdl")
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then phys:Wake() end
        self:SetUseType(SIMPLE_USE)
    end
end

function ENT:Use(activator)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    if SERVER then
        if Monarch and Monarch.CraftingOpen then
            Monarch.CraftingOpen(activator, self)
        else
            if activator and activator.Notify then
                activator:Notify("Crafting system not loaded!")
            end
        end
    end
end

if CLIENT then
    language.Add("monarch_craftingbench", "Crafting Bench")
end
