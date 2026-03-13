AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

local models = {
    "models/props_canal/mattpipe.mdl",
    "models/props_junk/garbage_coffeemug001a.mdl",
    "models/props_junk/garbage_bag001a.mdl",
    "models/props_lab/citizenradio.mdl",
    "models/props_lab/jar01b.mdl",
    "models/props_junk/metalgascan.mdl",
    "models/props_junk/garbage_plasticbottle003a.mdl",
    "models/willardnetworks/food/wn_food_loaf.mdl"
}

local possibleItems = {
    ["models/props_canal/mattpipe.mdl"] = {item="wep_melee_pipe"},
    ["models/willardnetworks/food/wn_food_loaf.mdl"] = {item="food_bread"},
}

function ENT:Initialize()
    self:SetModel(models[math.random(1, #models)])
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(SOLID_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
end

function ENT:Use(activator, caller)
    if not activator:IsPlayer() then return end

    for _,v in pairs(possibleItems) do
        if self:GetModel() == _ then
            activator:GiveInventoryItem(v.item)
            break
        end
    end

    self:Remove()
end