if not SERVER then return end

Monarch = Monarch or {}
Monarch.Police = Monarch.Police or {}
Monarch.Police.Warrants = Monarch.Police.Warrants or {}

util.AddNetworkString("Monarch.Police.Warrants.Open")
util.AddNetworkString("Monarch.Police.Warrants.GetData")
util.AddNetworkString("Monarch.Police.Warrants.IssueWarrant")
util.AddNetworkString("Monarch.Police.Warrants.RevokeWarrant")
util.AddNetworkString("Monarch.Police.Warrants.UpdateData")

local function EnsureDataDir()
	file.CreateDir("monarch")
	file.CreateDir("monarch/police")
	file.CreateDir("monarch/police/warrants")
end

local function GetWarrantPath()
	return "monarch/police/warrants/warrants_" .. game.GetMap() .. ".json"
end

local function LoadWarrants()
	EnsureDataDir()
	if file.Exists(GetWarrantPath(), "DATA") then
		local data = util.JSONToTable(file.Read(GetWarrantPath(), "DATA") or "{}") or {}
		Monarch.Police.Warrants.List = data.warrants or {}
	else
		Monarch.Police.Warrants.List = {}
	end
end

local function SaveWarrants()
	EnsureDataDir()
	local payload = { warrants = Monarch.Police.Warrants.List }
	file.Write(GetWarrantPath(), util.TableToJSON(payload, true))
end

function Monarch.Police.Warrants.IssueWarrant(charID, charName, reason, issuedBy, crimeSeverity)
	EnsureDataDir()

	local warrant = {
		char_id = tostring(charID),
		char_name = charName,
		reason = reason,
		issued_by = issuedBy,
		issued_time = os.time(),
		severity = crimeSeverity or "misdemeanor",
		active = true,
		arrests = 0
	}

	table.insert(Monarch.Police.Warrants.List, warrant)
	SaveWarrants()

	net.Start("Monarch.Police.Warrants.UpdateData")
		net.WriteTable(Monarch.Police.Warrants.List)
	net.Broadcast()

	return warrant
end

function Monarch.Police.Warrants.RevokeWarrant(charID)
	for i, warrant in ipairs(Monarch.Police.Warrants.List) do
		if tostring(warrant.char_id) == tostring(charID) then
			table.remove(Monarch.Police.Warrants.List, i)
			SaveWarrants()

			net.Start("Monarch.Police.Warrants.UpdateData")
				net.WriteTable(Monarch.Police.Warrants.List)
			net.Broadcast()

			return true
		end
	end
	return false
end

function Monarch.Police.Warrants.GetWarrantForPlayer(charID)
	for _, warrant in ipairs(Monarch.Police.Warrants.List) do
		if tostring(warrant.char_id) == tostring(charID) and warrant.active then
			return warrant
		end
	end
	return nil
end

function Monarch.Police.Warrants.RecordArrest(charID)
	for _, warrant in ipairs(Monarch.Police.Warrants.List) do
		if tostring(warrant.char_id) == tostring(charID) then
			warrant.arrests = (warrant.arrests or 0) + 1
			warrant.last_arrest = os.time()
			SaveWarrants()

			net.Start("Monarch.Police.Warrants.UpdateData")
				net.WriteTable(Monarch.Police.Warrants.List)
			net.Broadcast()

			return warrant
		end
	end
	return nil
end

net.Receive("Monarch.Police.Warrants.GetData", function(len, ply)
	if not IsValid(ply) or not ply:IsAdmin() then return end

	net.Start("Monarch.Police.Warrants.UpdateData")
		net.WriteTable(Monarch.Police.Warrants.List)
	net.Send(ply)
end)

net.Receive("Monarch.Police.Warrants.IssueWarrant", function(len, ply)
	if not IsValid(ply) or not ply:IsAdmin() then return end

	local charID = net.ReadString()
	local charName = net.ReadString()
	local reason = net.ReadString()
	local severity = net.ReadString()

	Monarch.Police.Warrants.IssueWarrant(charID, charName, reason, ply:GetName(), severity)
end)

net.Receive("Monarch.Police.Warrants.RevokeWarrant", function(len, ply)
	if not IsValid(ply) or not ply:IsAdmin() then return end

	local charID = net.ReadString()
	Monarch.Police.Warrants.RevokeWarrant(charID)
end)

hook.Add("InitPostEntity", "Monarch.Police.Warrants.Load", function()
	LoadWarrants()
end)

hook.Add("ShutDown", "Monarch.Police.Warrants.Save", function()
	SaveWarrants()
end)
