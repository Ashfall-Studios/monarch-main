

monarch = monarch or {}
monarch.Sync = monarch.Sync or {}
monarch.Sync.Vars = monarch.Sync.Vars or {}
monarch.Sync.VarsConditional = monarch.Sync.VarsConditional or {}
monarch.Sync.Data = monarch.Sync.Data or {}
local syncVarsID = 0

SYNC_ID_BITS = 8
SYNC_MAX_VARS = 255

SYNC_BOOL = 1
SYNC_STRING =  2
SYNC_INT = 3
SYNC_BIGINT = 4
SYNC_HUGEINT = 5
SYNC_MINITABLE = 6
SYNC_INTSTACK = 7

SYNC_TYPE_PUBLIC = 1
SYNC_TYPE_PRIVATE = 2

local entMeta = FindMetaTable("Entity")

function monarch.Sync.RegisterVar(type, conditional)
	syncVarsID = syncVarsID + 1

	if syncVarsID > SYNC_MAX_VARS then
		print("[Monarch] WARNING: Sync var limit hit! (255)")
	end

	monarch.Sync.Vars[syncVarsID] = type

	if conditional then
		monarch.Sync.VarsConditional[syncVarsID] = conditional
	end

	return syncVarsID
end

local ioRegister = {}
ioRegister[SERVER] = {}
ioRegister[CLIENT] = {}

function monarch.Sync.DoType(type, value)
	return ioRegister[SERVER or CLIENT][type](value)
end

if CLIENT then

	function entMeta:GetSyncVar(varID, fallback)
		local targetData = monarch.Sync.Data[self.EntIndex(self)]

		if targetData != nil then
			if targetData[varID] != nil then
				return targetData[varID]
			end
		end
		return fallback
	end

	net.Receive("iSyncU", function(len)
		local targetID = net.ReadUInt(16)
		local varID = net.ReadUInt(SYNC_ID_BITS)
		local syncType = monarch.Sync.Vars[varID]
		local newValue = monarch.Sync.DoType(syncType)
		local targetData = monarch.Sync.Data[targetID]

		if not targetData then
			monarch.Sync.Data[targetID] = {}
			targetData = monarch.Sync.Data[targetID]
		end

		targetData[varID] = newValue

		hook.Run("OnSyncUpdate", varID, targetID, newValue)
	end)

	net.Receive("iSyncUlcl", function(len)
		local targetID = net.ReadUInt(8)
		local varID = net.ReadUInt(SYNC_ID_BITS)
		local syncType = monarch.Sync.Vars[varID]
		local newValue = monarch.Sync.DoType(syncType)
		local targetData = monarch.Sync.Data[targetID]

		if not targetData then
			monarch.Sync.Data[targetID] = {}
			targetData = monarch.Sync.Data[targetID]
		end

		targetData[varID] = newValue

		hook.Run("OnSyncUpdate", varID, targetID, newValue)
	end)

	net.Receive("iSyncR", function()
		local targetID = net.ReadUInt(16)

		monarch.Sync.Data[targetID] = nil
	end)

	net.Receive("iSyncRvar", function()
		local targetID = net.ReadUInt(16)
		local varID = net.ReadUInt(SYNC_ID_BITS)
		local syncEnt = monarch.Sync.Data[targetID]

		if syncEnt then
			if monarch.Sync.Data[targetID][varID] != nil then
				monarch.Sync.Data[targetID][varID] = nil
			end
		end

		hook.Run("OnSyncUpdate", varID, targetID)
	end)
end

ioRegister[SERVER][SYNC_BOOL] = function(val) return net.WriteBool(val) end
ioRegister[CLIENT][SYNC_BOOL] = function(val) return net.ReadBool() end
ioRegister[SERVER][SYNC_INT] = function(val) return net.WriteUInt(val, 8) end
ioRegister[CLIENT][SYNC_INT] = function(val) return net.ReadUInt(8) end
ioRegister[SERVER][SYNC_BIGINT] = function(val) return net.WriteUInt(val, 16) end
ioRegister[CLIENT][SYNC_BIGINT] = function(val) return net.ReadUInt(16) end
ioRegister[SERVER][SYNC_HUGEINT] = function(val) return net.WriteUInt(val, 32) end
ioRegister[CLIENT][SYNC_HUGEINT] = function(val) return net.ReadUInt(32) end
ioRegister[SERVER][SYNC_STRING] = function(val) return net.WriteString(val) end
ioRegister[CLIENT][SYNC_STRING] = function(val) return net.ReadString() end
ioRegister[SERVER][SYNC_MINITABLE] = function(val) return net.WriteData(pon.encode(val), 32) end
ioRegister[CLIENT][SYNC_MINITABLE] = function(val) return pon.decode(net.ReadData(32)) end
ioRegister[SERVER][SYNC_INTSTACK] = function(val) 
	local count = net.WriteUInt(#val, 8)

	for v,k in pairs(val) do
		net.WriteUInt(k, 8)
	end

	return
end
ioRegister[CLIENT][SYNC_INTSTACK] = function(val) 
	local count = net.ReadUInt(8)
	local compiled =  {}

	for k = 1, count do
		table.insert(compiled, (net.ReadUInt(8)))
	end

	return compiled
end

SYNC_RPNAME = monarch.Sync.RegisterVar(SYNC_STRING)
SYNC_XP = monarch.Sync.RegisterVar(SYNC_HUGEINT)
SYNC_MONEY = monarch.Sync.RegisterVar(SYNC_HUGEINT)
SYNC_BANKMONEY = monarch.Sync.RegisterVar(SYNC_HUGEINT)
SYNC_WEPRAISED = monarch.Sync.RegisterVar(SYNC_BOOL)
SYNC_CLASS = monarch.Sync.RegisterVar(SYNC_INT)
SYNC_RANK = monarch.Sync.RegisterVar(SYNC_INT)
SYNC_ARRESTED = monarch.Sync.RegisterVar(SYNC_BOOL)
SYNC_HUNGER = monarch.Sync.RegisterVar(SYNC_INT)
SYNC_TYPING = monarch.Sync.RegisterVar(SYNC_BOOL)
SYNC_BROKENLEGS = monarch.Sync.RegisterVar(SYNC_BOOL)
SYNC_BLEEDING = monarch.Sync.RegisterVar(SYNC_BOOL)
SYNC_PROPCOUNT = monarch.Sync.RegisterVar(SYNC_INT)
SYNC_CRAFTLEVEL = monarch.Sync.RegisterVar(SYNC_INT)
SYNC_TROPHYPOINTS = monarch.Sync.RegisterVar(SYNC_BIGINT)
SYNC_INCOGNITO = monarch.Sync.RegisterVar(SYNC_BOOL)

SYNC_GROUP_NAME = monarch.Sync.RegisterVar(SYNC_STRING)
SYNC_GROUP_RANK = monarch.Sync.RegisterVar(SYNC_STRING)

SYNC_COS_FACE = monarch.Sync.RegisterVar(SYNC_INT) 
SYNC_COS_HEAD = monarch.Sync.RegisterVar(SYNC_INT)
SYNC_COS_CHEST = monarch.Sync.RegisterVar(SYNC_INT)

SYNC_DOOR_NAME = monarch.Sync.RegisterVar(SYNC_STRING)
SYNC_DOOR_GROUP = monarch.Sync.RegisterVar(SYNC_INT)
SYNC_DOOR_BUYABLE = monarch.Sync.RegisterVar(SYNC_BOOL)
SYNC_DOOR_OWNERS = monarch.Sync.RegisterVar(SYNC_INTSTACK)

hook.Run("CreateSyncVars")
