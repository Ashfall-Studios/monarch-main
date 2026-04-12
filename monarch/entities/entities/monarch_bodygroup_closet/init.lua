AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

if SERVER then
    util.AddNetworkString("Monarch_BodygroupCloset_Open")
    util.AddNetworkString("Monarch_BodygroupCloset_Update")
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

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end

    if not activator.MonarchActiveChar then
        activator:ChatAddText(Color(255, 100, 100), "You must have an active character to use this.")
        return
    end

    net.Start("Monarch_BodygroupCloset_Open")
    net.WriteString(activator.MonarchActiveChar.bodygroups or "{}")
    net.Send(activator)
end

net.Receive("Monarch_BodygroupCloset_Update", function(len, ply)
    if not IsValid(ply) or not ply.MonarchActiveChar then return end

    local skin = net.ReadUInt(8) or 0
    local bodygroupCount = net.ReadUInt(8)
    local bodygroups = {}

    for i = 1, bodygroupCount do
        local bgID = net.ReadUInt(8)
        local bgValue = net.ReadUInt(8)
        bodygroups[bgID] = bgValue
    end

    local playerModel = ply:GetModel()

    if Monarch and Monarch.FilterAllowedBodygroups then
        bodygroups = Monarch.FilterAllowedBodygroups(playerModel, bodygroups)
    end

    ply:SetSkin(math.Clamp(tonumber(skin) or 0, 0, 255))
    for bgID, bgValue in pairs(bodygroups) do
        ply:SetBodygroup(tonumber(bgID), tonumber(bgValue))
    end

end)
