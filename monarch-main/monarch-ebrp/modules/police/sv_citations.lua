if not SERVER then return end

Monarch = Monarch or {}
Monarch.Police = Monarch.Police or {}
Monarch.Police.Citations = Monarch.Police.Citations or {}

util.AddNetworkString("Monarch.Police.Citations.GetData")
util.AddNetworkString("Monarch.Police.Citations.IssueCitation")
util.AddNetworkString("Monarch.Police.Citations.PayCitation")
util.AddNetworkString("Monarch.Police.Citations.MarkPaid")
util.AddNetworkString("Monarch.Police.Citations.UpdateData")
util.AddNetworkString("Monarch.Police.Citations.NotifyIssued")

local function EnsureDataDir()
	file.CreateDir("monarch")
	file.CreateDir("monarch/police")
	file.CreateDir("monarch/police/citations")
end

local function GetCitationPath()
	return "monarch/police/citations/citations_" .. game.GetMap() .. ".json"
end

local function LoadCitations()
	EnsureDataDir()
	if file.Exists(GetCitationPath(), "DATA") then
		local data = util.JSONToTable(file.Read(GetCitationPath(), "DATA") or "{}") or {}
		Monarch.Police.Citations.List = data.citations or {}
	else
		Monarch.Police.Citations.List = {}
	end
end

local function SaveCitations()
	EnsureDataDir()
	local payload = { citations = Monarch.Police.Citations.List }
	file.Write(GetCitationPath(), util.TableToJSON(payload, true))
end

function Monarch.Police.Citations.IssueCitation(charID, charName, violation, fineAmount, officerName, notes)
	local citation = {
		id = "CITE_" .. os.time() .. "_" .. math.random(1000, 9999),
		char_id = tostring(charID),
		char_name = charName,
		violation = violation,
		fine_amount = fineAmount or 100,
		issued_by = officerName,
		issued_time = os.time(),
		paid = false,
		paid_time = nil,
		notes = notes or ""
	}

	table.insert(Monarch.Police.Citations.List, citation)
	SaveCitations()

	net.Start("Monarch.Police.Citations.UpdateData")
		net.WriteTable(Monarch.Police.Citations.List)
	net.Broadcast()

	for _, ply in ipairs(player.GetAll()) do
		local active = ply.MonarchActiveChar
		if active and tostring(active.id) == tostring(charID) then
			net.Start("Monarch.Police.Citations.NotifyIssued")
				net.WriteString(citation.violation or "Violation")
				net.WriteUInt(citation.fine_amount or 0, 32)
				net.WriteString(officerName or "Officer")
			net.Send(ply)
			break
		end
	end

	return citation
end

function Monarch.Police.Citations.GetOutstandingCitations(charID)
	local outstanding = {}
	for _, citation in ipairs(Monarch.Police.Citations.List) do
		if tostring(citation.char_id) == tostring(charID) and not citation.paid then
			table.insert(outstanding, citation)
		end
	end
	return outstanding
end

function Monarch.Police.Citations.PayCitation(citationID, playerCharID)
	for _, citation in ipairs(Monarch.Police.Citations.List) do
		if citation.id == citationID and tostring(citation.char_id) == tostring(playerCharID) then
			citation.paid = true
			citation.paid_time = os.time()
			SaveCitations()

			net.Start("Monarch.Police.Citations.UpdateData")
				net.WriteTable(Monarch.Police.Citations.List)
			net.Broadcast()

			return citation
		end
	end
	return nil
end

function Monarch.Police.Citations.GetTotalOutstandingFines(charID)
	local total = 0
	for _, citation in ipairs(Monarch.Police.Citations.List) do
		if tostring(citation.char_id) == tostring(charID) and not citation.paid then
			total = total + (citation.fine_amount or 0)
		end
	end
	return total
end

net.Receive("Monarch.Police.Citations.GetData", function(len, ply)
	if not IsValid(ply) or not ply:IsAdmin() then return end

	net.Start("Monarch.Police.Citations.UpdateData")
		net.WriteTable(Monarch.Police.Citations.List)
	net.Send(ply)
end)

net.Receive("Monarch.Police.Citations.IssueCitation", function(len, ply)
	if not IsValid(ply) or not ply:IsAdmin() then return end

	local charID = net.ReadString()
	local charName = net.ReadString()
	local violation = net.ReadString()
	local fineAmount = net.ReadUInt(32)
	local notes = net.ReadString()

	Monarch.Police.Citations.IssueCitation(charID, charName, violation, fineAmount, ply:GetRPName(), notes)
end)

net.Receive("Monarch.Police.Citations.PayCitation", function(len, ply)
	if not IsValid(ply) then return end

	local citationID = net.ReadString()
	local charID = ply.MonarchActiveChar and ply.MonarchActiveChar.id or 0

	local citation = Monarch.Police.Citations.PayCitation(citationID, charID)
	if citation then
		if ply.SetLocalSyncVar and _G.SYNC_MONEY then
			local currentMoney = ply:GetNWInt("Money", 0)
			local newMoney = math.max(0, currentMoney - citation.fine_amount)
			ply:SetNWInt("Money", newMoney)
			ply:SetLocalSyncVar(SYNC_MONEY, newMoney)
		end
		ply:Notify("You paid a citation fine of $" .. citation.fine_amount)
	end
end)

net.Receive("Monarch.Police.Citations.MarkPaid", function(len, ply)
	if not IsValid(ply) or not ply:IsAdmin() then return end

	local citationID = net.ReadString()
	local charID = net.ReadString()

	Monarch.Police.Citations.PayCitation(citationID, charID)
end)

hook.Add("InitPostEntity", "Monarch.Police.Citations.Load", function()
	LoadCitations()
end)

hook.Add("ShutDown", "Monarch.Police.Citations.Save", function()
	SaveCitations()
end)
