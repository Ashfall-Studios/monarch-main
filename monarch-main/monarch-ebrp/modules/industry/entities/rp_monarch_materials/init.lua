AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_junk/cardboard_box004a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(SOLID_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
end

function ENT:Use(ply)

    local factories = ents.FindByClass("rp_monarch_factory")
    local nearestFactory = nil
    local minDist = 300

    for _, ent in ipairs(factories) do
        if IsValid(ent) then
            local dist = self:GetPos():Distance(ent:GetPos())
            if dist < minDist then
                nearestFactory = ent
                minDist = dist
            end
        end
    end

    nearestFactory:AddMaterial(self, ply)
end