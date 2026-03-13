AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

util.AddNetworkString("Monarch_SetRecepticleName")

local RECEPTACLE_DB_PATH = "monarch_ebrp/receptacles.json"
local RECEPTACLE_DATA = {}

local function LoadReceptacleData()
    if file.Exists(RECEPTACLE_DB_PATH, "DATA") then
        local data = file.Read(RECEPTACLE_DB_PATH, "DATA")
        if data then
            RECEPTACLE_DATA = util.JSONToTable(data) or {}
        end
    end
end

local function SaveReceptacleData()
    if not file.Exists("monarch_ebrp", "DATA") then
        file.CreateDir("monarch_ebrp")
    end
    file.Write(RECEPTACLE_DB_PATH, util.TableToJSON(RECEPTACLE_DATA, true))
end

local function GetReceptacleKey(pos)

    local x = math.Round(pos.x)
    local y = math.Round(pos.y)
    local z = math.Round(pos.z)
    return x .. "," .. y .. "," .. z
end

LoadReceptacleData()

function ENT:Initialize()
    self:SetModel("models/props_lab/reciever_cart.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(SOLID_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    self.StoredPackages = {}

    local key = GetReceptacleKey(self:GetPos())
    if RECEPTACLE_DATA[key] then
        self:SetRecepticleName(RECEPTACLE_DATA[key])
    else
        self:SetRecepticleName("")
    end

    timer.Simple(0.1, function()
        if not IsValid(self) then return end
        self:RegisterReceptacle()
    end)
end

function ENT:RegisterReceptacle()

    local receptacleName = self:GetRecepticleName()
    if receptacleName and receptacleName ~= "" and UpdateFactoryLog then
        UpdateFactoryLog(receptacleName, 0, "ACTIVE")
    end
end

function ENT:SetName(name)
    self:SetRecepticleName(name or "")
end

function ENT:Touch(ent)

    if ent:GetClass() ~= "rp_monarch_finishedpackage" then return end

    local ent_idx = ent:EntIndex()

    self.StoredPackages[ent_idx] = true

    local receptacleName = self:GetRecepticleName()
    if receptacleName and receptacleName ~= "" and UpdateFactoryLog then
        local packageCount = table.Count(self.StoredPackages)
        UpdateFactoryLog(receptacleName, packageCount, "ACTIVE")
    end

    for stored_idx, _ in pairs(self.StoredPackages) do
        local stored_ent = Entity(stored_idx)
        if not IsValid(stored_ent) then
            self.StoredPackages[stored_idx] = nil
        end
    end

    ent:Remove()
end

net.Receive("Monarch_SetRecepticleName", function(len, ply)
    local ent = net.ReadEntity()
    local name = net.ReadString()

    if not IsValid(ent) then return end
    if not IsValid(ply) then return end
    if ent:GetClass() ~= "rp_monarch_recepticle" then return end
    if not gamemode.Call("CanProperty", ply, "recepticle_setname", ent) then return end

    name = string.sub(name, 1, 64) 
    ent:SetRecepticleName(name)

    local key = GetReceptacleKey(ent:GetPos())
    if name and name ~= "" then
        RECEPTACLE_DATA[key] = name
    else
        RECEPTACLE_DATA[key] = nil
    end
    SaveReceptacleData()

    if name and name ~= "" and UpdateFactoryLog then
        UpdateFactoryLog(name, table.Count(ent.StoredPackages or {}), "ACTIVE")
    end
end)