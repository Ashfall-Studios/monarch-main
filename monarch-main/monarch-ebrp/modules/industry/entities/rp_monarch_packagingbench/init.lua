AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

util.AddNetworkString("PackageUseTime")

function ENT:Initialize()
    self:SetModel("models/props_wasteland/cafeteria_table001a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(SOLID_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self.processing = false
    self.productsCollected = 0
    self.processedProducts = {}
end

function ENT:Think()
    self:SetNWInt("ProductCount", self.productsCollected or 0)
    self:SetNWBool("IsProcessing", self.processing)
    self:NextThink(CurTime())
    return true
end

function ENT:Touch(ent)
    if not self.processedProducts then
        self.processedProducts = {}
    end

    if ent:GetClass() == "rp_monarch_product" and not self.processedProducts[ent] and not self.processing then
        if (self.productsCollected or 0) < 3 then
            self.productsCollected = (self.productsCollected or 0) + 1
            self.processedProducts[ent] = true
            ent:Remove()
        end
    end
end

function ENT:Use(ply)
    if self.processing then
        return
    end

    if (self.productsCollected or 0) < 3 then
        return
    end

    self.processing = true
    local processTime = 20

    self:EmitSound("foley/industrial/packaging_box1.mp3", SNDLVL_75dB, 100, 1, CHAN_AUTO)
    net.Start("PackageUseTime")
    net.WriteFloat(processTime)
    net.Broadcast()

    timer.Simple(processTime, function()
        if not IsValid(self) then return end

        local finishedPkg = ents.Create("rp_monarch_finishedpackage")
        if IsValid(finishedPkg) then
            finishedPkg:SetPos(self:GetPos() + Vector(0, 0, 25))
            finishedPkg:Spawn()
        end

        self:EmitSound("foley/industrial/package_finished"..math.random(1,6)..".mp3", SNDLVL_75dB, 100, 1, CHAN_AUTO)

        self.productsCollected = 0
        self.processedProducts = {}
        self.processing = false
    end)
end