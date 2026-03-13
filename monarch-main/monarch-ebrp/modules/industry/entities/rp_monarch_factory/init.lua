AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

util.AddNetworkString("FactoryUseTime")

function ENT:Initialize()
    self:SetModel("models/jaggedsprings/furnace.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(SOLID_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self.processingPlayer = nil
    self.processStartTime = nil
    self:EmitSound("ambient/machines/lab_loop1.wav", SNDLVL_120dB, 100, 0.5, CHAN_STATIC)
    self.materialsToProcess = 0
    self.processedMaterials = {}
    self.isBrokenDown = false
    self.repairNeeded = nil
    self.ReqMats = math.random(2,5)
end

function ENT:Think()
    self:SetNWInt("MaterialCount", self.materialsToProcess or 0)
    self:SetNWInt("ReqMats", self.ReqMats or 2)
    self:SetNWBool("IsProcessing", self.processingPlayer ~= nil)
    self:SetNWBool("IsBroken", self.isBrokenDown)
    self:SetNWString("RepairNeeded", self.repairNeeded or "")
    self:NextThink(CurTime())
    return true
end

function ENT:Use(ply)
    if self.isBrokenDown then
        local text = "Unknown"
        if self.repairNeeded == "rp_monarch_oil" then
            text = "The factory requires an oil change."
        elseif self.repairNeeded == "rp_monarch_fuel" then
            text = "The factory is out of fuel."
        elseif self.repairNeeded == "rp_monarch_spareparts" then
            text = "One of the machine's parts has broken."
        end
        ply:Notify(text)
        return
    end

    if self.processingPlayer then
        return
    end

    if not self.ReqMats then self.ReqMats = math.random(2,5) end

    if (self.materialsToProcess or 0) < self.ReqMats then
        return
    end

    self:StartProcessing(ply)
end

function ENT:Touch(ent)
    if not self.processedMaterials then
        self.processedMaterials = {}
    end

    if self.isBrokenDown and ent:GetClass() == "rp_monarch_materials" then
        return
    end

    if self.isBrokenDown and ent:GetClass() == self.repairNeeded then
        self.isBrokenDown = false
        self.repairNeeded = nil
        ent:Remove()

        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) and self:GetPos():DistToSqr(ply:GetPos()) < 250000 then
                ply:Notify("This factory has been repaired.")
            end
        end
        return
    end

    if not self.ReqMats then self.ReqMats = math.random(2,5) end

    if (self.materialsToProcess or 0) >= self.ReqMats or self.processingPlayer then
        return
    end

    if ent:GetClass() == "rp_monarch_materials" and not self.processedMaterials[ent] then
        self.materialsToProcess = (self.materialsToProcess or 0) + 1
        self.processedMaterials[ent] = true
        self:EmitSound("foley/industrial/dump_resource_machine" ..math.random(1,3)..".mp3", SNDLVL_75dB, 100, 1, CHAN_AUTO)
        ent:Remove()
    end
end

function ENT:AddMaterial(material, ply)
    if self.processingPlayer then
        return
    end

    self.materialsToProcess = (self.materialsToProcess or 0) + 1
    if IsValid(material) then
        material:Remove()
    end
end

function ENT:StartProcessing(ply)
    if self.RepairNeeded then
        return
    end

    if not self.ReqMats then self.ReqMats = math.random(2,5) end

    self.processingPlayer = ply
    self.processStartTime = CurTime()
    local processTime = 25
    self.materialsToProcess = 0
    self:StopSound("ambient/machines/lab_loop1.wav")
    self:EmitSound("ambient/machines/machine3.wav", SNDLVL_120dB, 100, 0.5, CHAN_STATIC)

    ply:Freeze(true)

    net.Start("FactoryUseTime")
    net.WriteFloat(processTime)
    net.Send(ply)

    timer.Simple(processTime, function()
        if not IsValid(self) then return end

        self:StopSound("ambient/machines/machine3.wav")
        self:EmitSound("ambient/machines/lab_loop1.wav", SNDLVL_120dB, 100, 0.5, CHAN_STATIC)

        self.processingPlayer = nil
        self.processStartTime = nil

        if math.random(1, 100) <= 15 then
            local repairTypes = {"rp_monarch_oil", "rp_monarch_fuel", "rp_monarch_spareparts"}
            self.isBrokenDown = true
            self.repairNeeded = repairTypes[math.random(1, 3)]

            local repairName = "Unknown"
            if self.repairNeeded == "rp_monarch_oil" then
                repairName = "Oil"
            elseif self.repairNeeded == "rp_monarch_fuel" then
                repairName = "Fuel"
            elseif self.repairNeeded == "rp_monarch_spareparts" then
                repairName = "Spare Parts"
            end

            self:EmitSound("foley/industrial/mechanism_broken_"..math.random(1,6)..".mp3", SNDLVL_120dB, 100, 1, CHAN_AUTO)

            if IsValid(ply) then
                ply:Freeze(false)
                self:PostManufacture()
                local product = ents.Create("rp_monarch_product")
                if IsValid(product) then
                    product:SetPos(self:GetPos() + Vector(0, 60, 20))
                    product:Spawn()
                end
            end
            return
        end

        if IsValid(ply) then
            ply:Freeze(false)
            self:PostManufacture()
            local product = ents.Create("rp_monarch_product")
            if IsValid(product) then
                product:SetPos(self:GetPos() + Vector(0, 60, 20))
                product:Spawn()
            end
        end
    end)
end

function ENT:PostManufacture()
    self.ReqMats = math.random(2,5)
end