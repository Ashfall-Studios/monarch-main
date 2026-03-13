AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props/stalker2/wood_crate_02/w_wood_crate_02.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(SOLID_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
end

function ENT:Use(ply)
    local tables = ents.FindByClass("rp_monarch_extractiontable")
    local nearestTable = nil
    local minDist = 300

    for _, ent in ipairs(tables) do
        if IsValid(ent) then
            local dist = self:GetPos():Distance(ent:GetPos())
            if dist < minDist then
                nearestTable = ent
                minDist = dist
            end
        end
    end

    nearestTable:ProcessContainer(self, ply)
    print("Used container on extraction table")
end
