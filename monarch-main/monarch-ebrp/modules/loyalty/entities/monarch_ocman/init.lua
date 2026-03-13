
AddCSLuaFile("monarch-ebrp/modules/loyalty/sh_lyt.lua")
AddCSLuaFile("monarch-ebrp/modules/loyalty/cl_lyt.lua")
AddCSLuaFile("monarch-ebrp/modules/police/cl_police.lua")
include("monarch-ebrp/modules/loyalty/sh_lyt.lua")
include("monarch-ebrp/modules/loyalty/sv_lyt.lua")

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Model = "models/props_lab/monitor01a.mdl"

if SERVER then
    util.AddNetworkString("Monarch_OcmanUI_Open")
end

function ENT:Initialize()
    self:SetModel(self.Model)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end
end

function ENT:Use(activator)
    if not IsValid(activator) or not activator:IsPlayer() then return end

    activator._computerNext = activator._computerNext or 0

    activator._computerNext = CurTime() + 2

    net.Start("Monarch_OcmanUI_Open")
    net.Send(activator)
end
