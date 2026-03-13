AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

util.AddNetworkString("ShipmentUseTime")

function ENT:Initialize()
    self:SetModel("models/props_wasteland/cafeteria_table001a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(SOLID_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self.processing = false
    self.processEndTime = 0
    self.hasShipment = false
end

function ENT:Think()
    self:SetNWBool("HasShipment", self.hasShipment)
    self:NextThink(CurTime())
    return true
end

function ENT:Use(ply)
    if self.processing then
        return
    end

    if not self.hasShipment then
        return
    end

    self:ProcessShipment(ply)
end

function ENT:Touch(ent)
    if ent:GetClass() == "rp_monarch_shipment" and not self.hasShipment and not self.processing then
        self.hasShipment = true
        ent:Remove()
    end
end

function ENT:ProcessShipment(ply)    
    self.processing = true
    local processTime = 5

    self:EmitSound("foley/industrial/disassemble_crate" .. math.random(1,6).. ".mp3", SNDLVL_75dB, 100, 1, CHAN_AUTO)

    net.Start("ShipmentUseTime")
    net.WriteFloat(processTime)
    net.Broadcast()

    timer.Simple(processTime, function()
        if not IsValid(self) then return end

        for i = 1, math.random(2,4) do
            local container = ents.Create("rp_monarch_container")
            if IsValid(container) then
                container:SetPos(self:GetPos() + Vector(0, 0, 20))
                container:Spawn()
            end
        end

        self.hasShipment = false
        self.processing = false
    end)
end