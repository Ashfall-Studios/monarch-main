
if not SERVER then return end

Monarch = Monarch or {}
Monarch.Police = Monarch.Police or {}
Monarch.Police.Detainees = Monarch.Police.Detainees or {}

util.AddNetworkString("Monarch.Police.Detainees.GetData")
util.AddNetworkString("Monarch.Police.Detainees.Arrest")
util.AddNetworkString("Monarch.Police.Detainees.Release")
util.AddNetworkString("Monarch.Police.Detainees.UpdateData")
util.AddNetworkString("Monarch.Police.Detainees.GetCharges")

local CellVectors = {
    Vector(-3365.593018, 10240.222656, 7504.03125),
    Vector(-3208.858887, 10249.137695, 7504.03125)
}

Monarch.Police.Detainees.Charges = {
    {name = "Petty Theft", time = 300}, 
    {name = "Assault", time = 600}, 
    {name = "Armed Robbery", time = 900}, 
    {name = "Murder", time = 1800}, 
    {name = "Treason", time = 3600}, 
    {name = "Custom", time = 600} 
}

local function EnsureDataDir()
	file.CreateDir("monarch")
	file.CreateDir("monarch/police")
	file.CreateDir("monarch/police/detainees")
end

local function GetDetaineePath()
	return "monarch/police/detainees/detainees_" .. game.GetMap() .. ".json"
end

local function LoadDetainees()
	EnsureDataDir()
	if file.Exists(GetDetaineePath(), "DATA") then
		local data = util.JSONToTable(file.Read(GetDetaineePath(), "DATA") or "{}") or {}
		Monarch.Police.Detainees.List = data.detainees or {}
	else
		Monarch.Police.Detainees.List = {}
	end
end

local function SaveDetainees()
	EnsureDataDir()
	local payload = { detainees = Monarch.Police.Detainees.List }
	file.Write(GetDetaineePath(), util.TableToJSON(payload, true))
end

function Monarch.Police.Detainees.ArrestPlayer(charID, charName, reason, arresterName, sentenceTime)

	for _, detainee in ipairs(Monarch.Police.Detainees.List) do
		if tostring(detainee.char_id) == tostring(charID) and not detainee.released then
			return nil 
		end
	end

	sentenceTime = sentenceTime or 600

	local record = {
		id = "ARREST_" .. os.time() .. "_" .. math.random(1000, 9999),
		char_id = tostring(charID),
		char_name = charName,
		reason = reason,
		arrested_by = arresterName,
		arrest_time = os.time(),
		sentence_time = sentenceTime,
		release_time = os.time() + sentenceTime,
		released = false,
		released_time = nil,
		released_by = nil,
		processing_notes = "",
		mug_shot = nil
	}

	table.insert(Monarch.Police.Detainees.List, record)
	SaveDetainees()

	for _, ply in ipairs(player.GetAll()) do
		local plyChar = ply.MonarchActiveChar or {}
		if tostring(plyChar.id) == tostring(charID) then
			local cellPos = CellVectors[math.random(1, #CellVectors)]
			ply:SetPos(cellPos)
			ply:SetVelocity(Vector(0, 0, 0))

			ply._MonarchDraggedBy = nil
			break
		end
	end

	timer.Create("MonarchDetention_" .. record.id, sentenceTime, 1, function()
		Monarch.Police.Detainees.ReleaseDetainee(charID, "System", "Sentence completed")
	end)

	net.Start("Monarch.Police.Detainees.UpdateData")
		net.WriteTable(Monarch.Police.Detainees.List)
	net.Broadcast()

	return record
end

function Monarch.Police.Detainees.ReleaseDetainee(charID, releasedBy, reason)
	for _, detainee in ipairs(Monarch.Police.Detainees.List) do
		if tostring(detainee.char_id) == tostring(charID) and not detainee.released then
			detainee.released = true
			detainee.released_time = os.time()
			detainee.released_by = releasedBy
			detainee.release_reason = reason or "Released"
			SaveDetainees()

			for _, ply in ipairs(player.GetAll()) do
				local plyChar = ply.MonarchActiveChar or {}
				if tostring(plyChar.id) == tostring(charID) then

					ply:SetNWBool("MonarchCuffed", false)
					ply:SetNWBool("MonarchCuffedBehind", false)
					if ply._MonarchOrigSpeeds then
						if ply._MonarchOrigSpeeds.walk then ply:SetWalkSpeed(ply._MonarchOrigSpeeds.walk) end
						if ply._MonarchOrigSpeeds.run then ply:SetRunSpeed(ply._MonarchOrigSpeeds.run) end
						ply._MonarchOrigSpeeds = nil
					end
					ply._MonarchDraggedBy = nil

					ply:Spawn()
					break
				end
			end

			net.Start("Monarch.Police.Detainees.UpdateData")
				net.WriteTable(Monarch.Police.Detainees.List)
			net.Broadcast()

			return detainee
		end
	end
	return nil
end

function Monarch.Police.Detainees.UpdateNotes(charID, notes)
	for _, detainee in ipairs(Monarch.Police.Detainees.List) do
		if tostring(detainee.char_id) == tostring(charID) and not detainee.released then
			detainee.processing_notes = notes
			SaveDetainees()

			net.Start("Monarch.Police.Detainees.UpdateData")
				net.WriteTable(Monarch.Police.Detainees.List)
			net.Broadcast()

			return true
		end
	end
	return false
end

function Monarch.Police.Detainees.GetCurrentDetainee(charID)
	for _, detainee in ipairs(Monarch.Police.Detainees.List) do
		if tostring(detainee.char_id) == tostring(charID) and not detainee.released then
			return detainee
		end
	end
	return nil
end

function Monarch.Police.Detainees.IsDetained(charID)
	return Monarch.Police.Detainees.GetCurrentDetainee(charID) ~= nil
end

function Monarch.Police.Detainees.GetAllDetained()
	local detained = {}
	for _, detainee in ipairs(Monarch.Police.Detainees.List) do
		if not detainee.released then
			table.insert(detained, detainee)
		end
	end
	return detained
end

net.Receive("Monarch.Police.Detainees.GetData", function(len, ply)
	if not IsValid(ply) or not ply:IsAdmin() then return end

	net.Start("Monarch.Police.Detainees.UpdateData")
		net.WriteTable(Monarch.Police.Detainees.List)
	net.Send(ply)
end)

net.Receive("Monarch.Police.Detainees.GetCharges", function(len, ply)
	if not IsValid(ply) or not ply:IsAdmin() then return end

	net.Start("Monarch.Police.Detainees.GetCharges")
		net.WriteTable(Monarch.Police.Detainees.Charges)
	net.Send(ply)
end)

net.Receive("Monarch.Police.Detainees.Arrest", function(len, ply)
	if not IsValid(ply) or not ply:IsAdmin() then return end

	local charID = net.ReadString()
	local charName = net.ReadString()
	local reason = net.ReadString()

	print("[ARREST DEBUG] Arrest request for charID:", charID, "by", ply:Nick())

	local cuffedPlayer
	for _, v in ipairs(player.GetAll()) do
		local isCuffed = v:GetNWBool("MonarchCuffed", false)
		local vChar = v.MonarchActiveChar or {}
		print("[ARREST DEBUG] Checking player", v:Nick(), "- Cuffed:", isCuffed, "CharID:", vChar.id)
		if isCuffed then
			if tostring(vChar.id) == tostring(charID) then
				print("[ARREST DEBUG] Found matching cuffed player:", v:Nick())
				cuffedPlayer = v
				break
			end
		end
	end
	if not cuffedPlayer then 
		print("[ARREST DEBUG] No cuffed player found matching charID:", charID)
		return 
	end

	local sentenceTime = net.ReadUInt(32)

	Monarch.Police.Detainees.ArrestPlayer(charID, charName, reason, ply:GetName(), sentenceTime)
end)

net.Receive("Monarch.Police.Detainees.Release", function(len, ply)
	if not IsValid(ply) or not ply:IsAdmin() then return end

	local charID = net.ReadString()
	local reason = net.ReadString()

	Monarch.Police.Detainees.ReleaseDetainee(charID, ply:GetName(), reason)
end)

hook.Add("InitPostEntity", "Monarch.Police.Detainees.Load", function()
	LoadDetainees()
end)

hook.Add("ShutDown", "Monarch.Police.Detainees.Save", function()
	SaveDetainees()
end)
