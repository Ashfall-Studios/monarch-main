AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/items/ammocrate_smg1.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(SOLID_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    self.openSequence = self:LookupSequence("Open")
    self.Delay = 0
end

local ammoValues = {
    ["Pistol"] = 94,
    ["357"] = 18,
    ["SMG1"] = 500,
    ["slam"] = 3,
    ["Grenade"] = 1,
    ["AR2"] = 300,
    ["Buckshot"] = 52,
    ["XBowBolt"] = 45
}

function ENT:Use(caller, activator)
    if self.Delay > CurTime() then return end
    self.Delay = CurTime() + 1.5

    self:ResetSequence(self.openSequence)
    self:EmitSound("items/ammocrate_open.wav")
    caller:EmitSound("items/itempickup.wav")

    timer.Simple(self:SequenceDuration(self.openSequence), function()
        if not IsValid(self) then return end
        self:ResetSequence(0)
        self:EmitSound("items/ammocrate_close.wav")
    end)

    for v,k in pairs(activator:GetWeapons()) do
        local ammoName = game.GetAmmoName(k:GetPrimaryAmmoType())

        if ammoValues[ammoName] then
            local ammoCount = activator:GetAmmoCount(ammoName)

            if ammoCount and ammoCount < ammoValues[ammoName] then
                activator:SetAmmo(ammoValues[ammoName] or 250, k:GetPrimaryAmmoType())
            end
        end
    end
end