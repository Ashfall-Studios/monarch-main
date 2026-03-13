
if not SERVER then return end

Monarch = Monarch or {}
Monarch.Police = Monarch.Police or {}
Monarch.Police.Bail = Monarch.Police.Bail or {}

util.AddNetworkString("Monarch.Police.Bail.GetData")
util.AddNetworkString("Monarch.Police.Bail.SetBail")
util.AddNetworkString("Monarch.Police.Bail.PostBail")
util.AddNetworkString("Monarch.Police.Bail.RevokeBail")
util.AddNetworkString("Monarch.Police.Bail.UpdateData")

local function EnsureDataDir()
	file.CreateDir("monarch")
	file.CreateDir("monarch/police")
	file.CreateDir("monarch/police/bail")
end

local function GetBailPath()
	return "monarch/police/bail/bail_" .. game.GetMap() .. ".json"
end

local function LoadBail()
	EnsureDataDir()
	if file.Exists(GetBailPath(), "DATA") then
		local data = util.JSONToTable(file.Read(GetBailPath(), "DATA") or "{}") or {}
		Monarch.Police.Bail.Records = data.records or {}
	else
		Monarch.Police.Bail.Records = {}
	end
end

local function SaveBail()
	EnsureDataDir()
	local payload = { records = Monarch.Police.Bail.Records }
	file.Write(GetBailPath(), util.TableToJSON(payload, true))
end

function Monarch.Police.Bail.SetBail(charID, charName, bailAmount, setBy)

	for _, record in ipairs(Monarch.Police.Bail.Records) do
		if tostring(record.char_id) == tostring(charID) then
			record.bail_amount = bailAmount
			record.set_by = setBy
			record.set_time = os.time()
			SaveBail()

			net.Start("Monarch.Police.Bail.UpdateData")
				net.WriteTable(Monarch.Police.Bail.Records)
			net.Broadcast()

			return record
		end
	end

	local record = {
		char_id = tostring(charID),
		char_name = charName,
		bail_amount = bailAmount,
		set_by = setBy,
		set_time = os.time(),
		posted = false,
		posted_by = nil,
		posted_time = nil,
		posted_amount = 0
	}

	table.insert(Monarch.Police.Bail.Records, record)
	SaveBail()

	net.Start("Monarch.Police.Bail.UpdateData")
		net.WriteTable(Monarch.Police.Bail.Records)
	net.Broadcast()

	return record
end

function Monarch.Police.Bail.PostBail(charID, posterName, amount)
	for _, record in ipairs(Monarch.Police.Bail.Records) do
		if tostring(record.char_id) == tostring(charID) then
			if amount >= record.bail_amount then
				record.posted = true
				record.posted_by = posterName
				record.posted_time = os.time()
				record.posted_amount = amount
				SaveBail()

				net.Start("Monarch.Police.Bail.UpdateData")
					net.WriteTable(Monarch.Police.Bail.Records)
				net.Broadcast()

				return true
			end
			return false
		end
	end
	return false
end

function Monarch.Police.Bail.RevokeBail(charID, revokedBy)
	for _, record in ipairs(Monarch.Police.Bail.Records) do
		if tostring(record.char_id) == tostring(charID) then
			record.posted = false
			record.posted_by = nil
			record.posted_time = nil
			record.posted_amount = 0
			record.revoked_by = revokedBy
			record.revoked_time = os.time()
			SaveBail()

			net.Start("Monarch.Police.Bail.UpdateData")
				net.WriteTable(Monarch.Police.Bail.Records)
			net.Broadcast()

			return true
		end
	end
	return false
end

function Monarch.Police.Bail.GetBailRecord(charID)
	for _, record in ipairs(Monarch.Police.Bail.Records) do
		if tostring(record.char_id) == tostring(charID) then
			return record
		end
	end
	return nil
end

function Monarch.Police.Bail.IsBailPosted(charID)
	local record = Monarch.Police.Bail.GetBailRecord(charID)
	return record and record.posted or false
end

net.Receive("Monarch.Police.Bail.GetData", function(len, ply)
	if not IsValid(ply) or not ply:IsAdmin() then return end

	net.Start("Monarch.Police.Bail.UpdateData")
		net.WriteTable(Monarch.Police.Bail.Records)
	net.Send(ply)
end)

net.Receive("Monarch.Police.Bail.SetBail", function(len, ply)
	if not IsValid(ply) or not ply:IsAdmin() then return end

	local charID = net.ReadString()
	local charName = net.ReadString()
	local bailAmount = net.ReadUInt(32)

	Monarch.Police.Bail.SetBail(charID, charName, bailAmount, ply:GetName())
end)

net.Receive("Monarch.Police.Bail.PostBail", function(len, ply)
	if not IsValid(ply) then return end

	local charID = net.ReadString()
	local posterName = ply:GetName()
	local moneyAvailable = ply:GetNWInt("Money", 0)

	local record = Monarch.Police.Bail.GetBailRecord(charID)
	if record and record.bail_amount and moneyAvailable >= record.bail_amount then
		Monarch.Police.Bail.PostBail(charID, posterName, record.bail_amount)

		if ply.SetLocalSyncVar and _G.SYNC_MONEY then
			local newMoney = moneyAvailable - record.bail_amount
			ply:SetNWInt("Money", newMoney)
			ply:SetLocalSyncVar(SYNC_MONEY, newMoney)
		end

		ply:Notify("You posted bail of $" .. record.bail_amount)
	elseif not record then
		ply:Notify("No bail record found for this character")
	else
		ply:Notify("Insufficient funds. Required: $" .. (record.bail_amount or 0))
	end
end)

net.Receive("Monarch.Police.Bail.RevokeBail", function(len, ply)
	if not IsValid(ply) or not ply:IsAdmin() then return end

	local charID = net.ReadString()

	Monarch.Police.Bail.RevokeBail(charID, ply:GetName())
end)

hook.Add("InitPostEntity", "Monarch.Police.Bail.Load", function()
	LoadBail()
end)

hook.Add("ShutDown", "Monarch.Police.Bail.Save", function()
	SaveBail()
end)
