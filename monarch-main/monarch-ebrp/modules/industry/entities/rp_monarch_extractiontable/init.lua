AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

util.AddNetworkString("UseTime")

function ENT:Initialize()
    self:SetModel("models/props_wasteland/cafeteria_table001a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(SOLID_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self.processing = false
    self.processEndTime = 0
    self.hasContainer = false
end

function ENT:Think()
    self:SetNWBool("HasContainer", self.hasContainer)
    self:NextThink(CurTime())
    return true
end

function ENT:Use(ply)
    if self.processing then
        return
    end

    if not self.hasContainer then
        return
    end

    self:ProcessContainer(ply)
end

function ENT:Touch(ent)
    if ent:GetClass() == "rp_monarch_container" and not self.hasContainer and not self.processing then
        self.hasContainer = true
        ent:Remove()
    end
end

function ENT:ProcessContainer(ply)
    self.processing = true
    local processTime = 3

    self:EmitSound("foley/industrial/disassemble_crate" .. math.random(1,6).. ".mp3", SNDLVL_75dB, 100, 1, CHAN_AUTO)

    net.Start("UseTime")
    net.WriteFloat(processTime)
    net.Broadcast()

    timer.Simple(processTime, function()
        if not IsValid(self) then return end

        for i = 1, math.random(2,4) do
            local material = ents.Create("rp_monarch_materials")
            if IsValid(material) then
                material:SetPos(self:GetPos() + Vector(0, 0, 20))
                material:Spawn()
            end
        end

        self.hasContainer = false
        self.processing = false
    end)
end