AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Model = "models/props_lab/citizenradio.mdl"

function ENT:Initialize()
    self:SetModel(self.Model)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self.IsOn = false

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end
end

local radioSongs = {
    "radio/anthem.mp3",
    "radio/rusanthem.mp3",
    "radio/soviet.mp3"
}

function ENT:Use(activator)
    if not IsValid(activator) or not activator:IsPlayer() then return end

    self.IsOn = not self.IsOn

    if self.IsOn then btnpress = "music_radio/radio_on.mp3" else btnpress = "music_radio/radio_off.mp3" end

    if self.IsOn then
        local indx = math.random(1, #radioSongs)
        self:EmitSound(radioSongs[indx], 64, 100)
    end

    self:EmitSound(btnpress, 55, 100)

    if not self.IsOn then
        for _,song in pairs(radioSongs) do
            self:StopSound(song)
        end
    end
end
