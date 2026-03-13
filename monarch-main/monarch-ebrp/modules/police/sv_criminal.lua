if not SERVER then return end

Monarch = Monarch or {}
Monarch.Police = Monarch.Police or {}
Monarch.Police.Criminal = Monarch.Police.Criminal or {}

util.AddNetworkString("Monarch.Police.Criminal.Open")
util.AddNetworkString("Monarch.Police.Criminal.GetData")
util.AddNetworkString("Monarch.Police.Criminal.RecordArrest")
util.AddNetworkString("Monarch.Police.Criminal.AddCharge")
util.AddNetworkString("Monarch.Police.Criminal.RemoveCharge")
util.AddNetworkString("Monarch.Police.Criminal.UpdateData")

local function EnsureDataDir()
	file.CreateDir("monarch")
	file.CreateDir("monarch/police")
	file.CreateDir("monarch/police/criminal")
end

local function GetCriminalPath()
	return "monarch/police/criminal/records_" .. game.GetMap() .. ".json"
end

local function LoadCriminalRecords()
	EnsureDataDir()
	if file.Exists(GetCriminalPath(), "DATA") then
		local data = util.JSONToTable(file.Read(GetCriminalPath(), "DATA") or "{}") or {}
		Monarch.Police.Criminal.Records = data.records or {}
	else
		Monarch.Police.Criminal.Records = {}
	end
end

local function SaveCriminalRecords()
	EnsureDataDir()
	local payload = { records = Monarch.Police.Criminal.Records }
	file.Write(GetCriminalPath(), util.TableToJSON(payload, true))
end

function Monarch.Police.Criminal.GetRecord(charID)
	for _, record in ipairs(Monarch.Police.Criminal.Records) do
		if tostring(record.char_id) == tostring(charID) then
			return record
		end
	end

	local record = {
		char_id = tostring(charID),
		char_name = "",
		arrest_count = 0,
		active_charges = {},
		conviction_count = 0,
		last_arrest = nil,
		notes = ""
	}
	table.insert(Monarch.Police.Criminal.Records, record)
	SaveCriminalRecords()
	return record
end

function Monarch.Police.Criminal.RecordArrest(charID, charName, reason, arresterName)
	local record = Monarch.Police.Criminal.GetRecord(charID)
	record.char_name = charName
	record.arrest_count = (record.arrest_count or 0) + 1
	record.last_arrest = os.time()

	table.insert(record.active_charges, {
		charge = reason,
		date = os.time(),
		by = arresterName
	})

	SaveCriminalRecords()

	net.Start("Monarch.Police.Criminal.UpdateData")
		net.WriteTable(Monarch.Police.Criminal.Records)
	net.Broadcast()

	return record
end

function Monarch.Police.Criminal.AddCharge(charID, chargeDescription, officerName)
	local record = Monarch.Police.Criminal.GetRecord(charID)

	table.insert(record.active_charges, {
		charge = chargeDescription,
		date = os.time(),
		by = officerName
	})

	SaveCriminalRecords()

	net.Start("Monarch.Police.Criminal.UpdateData")
		net.WriteTable(Monarch.Police.Criminal.Records)
	net.Broadcast()
end

function Monarch.Police.Criminal.RemoveCharge(charID, chargeIndex)
	local record = Monarch.Police.Criminal.GetRecord(charID)

	if record.active_charges[chargeIndex] then
		table.remove(record.active_charges, chargeIndex)
		SaveCriminalRecords()

		net.Start("Monarch.Police.Criminal.UpdateData")
			net.WriteTable(Monarch.Police.Criminal.Records)
		net.Broadcast()

		return true
	end
	return false
end

function Monarch.Police.Criminal.ConvictCharacter(charID)
	local record = Monarch.Police.Criminal.GetRecord(charID)
	record.conviction_count = (record.conviction_count or 0) + 1
	record.active_charges = {}
	SaveCriminalRecords()

	net.Start("Monarch.Police.Criminal.UpdateData")
		net.WriteTable(Monarch.Police.Criminal.Records)
	net.Broadcast()
end

net.Receive("Monarch.Police.Criminal.GetData", function(len, ply)
	if not IsValid(ply) or not ply:IsAdmin() then return end

	net.Start("Monarch.Police.Criminal.UpdateData")
		net.WriteTable(Monarch.Police.Criminal.Records)
	net.Send(ply)
end)

net.Receive("Monarch.Police.Criminal.RecordArrest", function(len, ply)
	if not IsValid(ply) or not ply:IsAdmin() then return end

	local charID = net.ReadString()
	local charName = net.ReadString()
	local reason = net.ReadString()

	Monarch.Police.Criminal.RecordArrest(charID, charName, reason, ply:GetName())
end)

net.Receive("Monarch.Police.Criminal.AddCharge", function(len, ply)
	if not IsValid(ply) or not ply:IsAdmin() then return end

	local charID = net.ReadString()
	local charge = net.ReadString()

	Monarch.Police.Criminal.AddCharge(charID, charge, ply:GetName())
end)

net.Receive("Monarch.Police.Criminal.RemoveCharge", function(len, ply)
	if not IsValid(ply) or not ply:IsAdmin() then return end

	local charID = net.ReadString()
	local chargeIndex = net.ReadUInt(16)

	Monarch.Police.Criminal.RemoveCharge(charID, chargeIndex)
end)

hook.Add("InitPostEntity", "Monarch.Police.Criminal.Load", function()
	LoadCriminalRecords()
end)

hook.Add("ShutDown", "Monarch.Police.Criminal.Save", function()
	SaveCriminalRecords()
end)
