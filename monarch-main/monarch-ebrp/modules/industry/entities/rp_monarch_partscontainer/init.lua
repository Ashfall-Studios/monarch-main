AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props/CS_militia/crate_extrasmallmill.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(SOLID_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
end

function ENT:Use(ply)
    local fl = ents.Create("rp_monarch_spareparts")
    fl:SetPos(self:GetPos() + Vector(0,0,50))
    fl:Spawn()
end