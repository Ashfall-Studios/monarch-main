AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Model = "models/props_lab/monitor01a.mdl"

if SERVER then
	util.AddNetworkString("Monarch_ComputerUI_Open")
	util.AddNetworkString("monindustry_workshift_svrstart")
	util.AddNetworkString("monindustry_workshift_svrend")
	util.AddNetworkString("monindustry_workshift_end")
	util.AddNetworkString("monindustry_workshift_start")
	util.AddNetworkString("monarch_workshift_setworkerstatus")
	util.AddNetworkString("monarch_workshift_statusupdated")
	util.AddNetworkString("monarch_workshift_notification")
	util.AddNetworkString("monarch_shift_setquota")
	util.AddNetworkString("monarch_shift_quotaupdate")
	util.AddNetworkString("monarch_shift_setreceptacle")
	util.AddNetworkString("monarch_shift_receptacleupdate")
	util.AddNetworkString("monarch_shift_factorylogupdate")
end

local SendShiftSync

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

function ENT:Use(activator)
    if not IsValid(activator) or not activator:IsPlayer() then return end

    activator._computerNext = activator._computerNext or 0

    activator._computerNext = CurTime() + 2

	SendShiftSync(activator)

    net.Start("Monarch_ComputerUI_Open")
    net.Send(activator)
end

net.Receive("monindustry_workshift_svrstart", function()
    net.Start("monindustry_workshift_start")
    net.Broadcast()
end)

net.Receive("monindustry_workshift_svrend", function()
    net.Start("monindustry_workshift_end")
    net.Broadcast()
end)

local WORKER_DATA = {

}

local QUOTA_DATA = {

}

local RECEPTACLE_DATA = {

}

local FACTORY_LOGS = {

}

SendShiftSync = function(ply)
	if not IsValid(ply) then return end

	for name, data in pairs(QUOTA_DATA) do
		net.Start("monarch_shift_quotaupdate")
		net.WriteString(name)
		net.WriteUInt(data.quota or 0, 16)
		net.WriteUInt(data.current or 0, 16)
		net.Send(ply)
	end

	for name, data in pairs(FACTORY_LOGS) do
		net.Start("monarch_shift_factorylogupdate")
		net.WriteString(name)
		net.WriteUInt(data.count or 0, 16)
		net.WriteString(data.status or "OK")
		net.Send(ply)
	end

	for name, uid in pairs(RECEPTACLE_DATA) do
		net.Start("monarch_shift_receptacleupdate")
		net.WriteString(name)
		net.WriteString(uid or "")
		net.Send(ply)
	end
end

net.Receive("monarch_workshift_setworkerstatus", function(len, ply)
	local workerName = net.ReadString()
	local newStatus = net.ReadString()
	local notification = net.ReadString()

	WORKER_DATA[workerName] = {
		status = newStatus,
		notify = notification
	}

	net.Start("monarch_workshift_statusupdated")
	net.WriteString(workerName)
	net.WriteString(newStatus)
	net.WriteString(notification)
	net.Broadcast()

	if notification and notification ~= "" then
		net.Start("monarch_workshift_notification")
		net.WriteString(workerName)
		net.WriteString(newStatus)
		net.WriteString(notification)
        net.WritePlayer(ply)
		net.Broadcast()
	end
end)

net.Receive("monarch_shift_setquota", function(len, ply)
	local receptacleName = net.ReadString()
	local quotaAmount = net.ReadUInt(16)

	QUOTA_DATA[receptacleName] = {
		quota = quotaAmount,
		current = QUOTA_DATA[receptacleName] and QUOTA_DATA[receptacleName].current or 0
	}

	net.Start("monarch_shift_quotaupdate")
	net.WriteString(receptacleName)
	net.WriteUInt(quotaAmount, 16)
	net.WriteUInt(QUOTA_DATA[receptacleName].current, 16)
	net.Broadcast()
end)

net.Receive("monarch_shift_setreceptacle", function(len, ply)
	local receptacleName = net.ReadString()
	local receptacleUID = net.ReadString()

	RECEPTACLE_DATA[receptacleName] = receptacleUID

	net.Start("monarch_shift_receptacleupdate")
	net.WriteString(receptacleName)
	net.WriteString(receptacleUID)
	net.Broadcast()
end)

function UpdateFactoryLog(receptacleName, count, status)
	FACTORY_LOGS[receptacleName] = {
		count = count,
		status = status
	}

	local quotaData = QUOTA_DATA[receptacleName] or {quota = 0, current = 0}
	quotaData.current = count
	QUOTA_DATA[receptacleName] = quotaData

	net.Start("monarch_shift_factorylogupdate")
	net.WriteString(receptacleName)
	net.WriteUInt(count, 16)
	net.WriteString(status)
	net.Broadcast()

	net.Start("monarch_shift_quotaupdate")
	net.WriteString(receptacleName)
	net.WriteUInt(quotaData.quota or 0, 16)
	net.WriteUInt(quotaData.current or 0, 16)
	net.Broadcast()
end

_G.UpdateFactoryLog = UpdateFactoryLog