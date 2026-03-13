
if not SERVER then return end

Monarch = Monarch or {}
Monarch.Loyalty = Monarch.Loyalty or {}
Monarch.Loyalty.Data = Monarch.Loyalty.Data or {}
Monarch.Loyalty.Notes = Monarch.Loyalty.Notes or {}

Monarch.Loyalty._charScoped = true

local function getCharID(ply)
    if not IsValid(ply) then return nil end
    if ply.GetCharID then
        local cid = ply:GetCharID()
        if cid then return tostring(cid) end
    end
    if ply.MonarchActiveChar and ply.MonarchActiveChar.id then
        return tostring(ply.MonarchActiveChar.id)
    end
    if ply.MonarchLastCharID then
        return tostring(ply.MonarchLastCharID)
    end
    return nil
end

local function getCharName(ply)
    if not IsValid(ply) then return "Unknown" end

    if ply.MonarchActiveChar and ply.MonarchActiveChar.name then
        local n = ply.MonarchActiveChar.name
        if isstring(n) and n ~= "" then return n end
    end

    if ply.GetCharName then
        local n = ply:GetCharName()
        if isstring(n) and n ~= "" then return n end
    end

    if ply.GetRPName then
        local n = ply:GetRPName()
        if isstring(n) and n ~= "" then return n end
    end

    return ply:Nick()
end

local function ensureCharRecord(charKey, defaults)
    if not charKey then return nil end
    charKey = tostring(charKey)

    if not Monarch.Loyalty.Data[charKey] then
        Monarch.Loyalty.Data[charKey] = {
            char_id = charKey,
            steamid = defaults and defaults.steamid or "Unknown",
            name = defaults and defaults.name or "Unknown",
            loyalty_points = 0,
            party_tier = 0,
            tax_rate = 0.30,
            last_updated = os.time(),
        }
    end

    return Monarch.Loyalty.Data[charKey]
end

local function findPlayerByCharID(charKey)
    if not charKey then return nil end

    for _, p in ipairs(player.GetAll()) do
        local cid = getCharID(p)
        if cid and tostring(cid) == tostring(charKey) then
            return p
        end
    end

    return nil
end

local function ensureAllPlayers()
    for _, p in ipairs(player.GetAll()) do
        Monarch.Loyalty.GetPlayerData(p)
    end
    return Monarch.Loyalty.Data
end

local function rebuildAndSyncNames()
    for _, p in ipairs(player.GetAll()) do
        local d = Monarch.Loyalty.GetPlayerData(p)
        if d then
            d.name = getCharName(p)
        end
    end
end

util.AddNetworkString("Monarch_Loyalty_Sync")
util.AddNetworkString("Monarch_Loyalty_RequestData")
util.AddNetworkString("Monarch_Loyalty_UpdateTier")
util.AddNetworkString("Monarch_Loyalty_UpdateParty")
util.AddNetworkString("Monarch_Loyalty_UpdateNote")
util.AddNetworkString("Monarch_Loyalty_UpdateTax")

local DATA_PATH = "monarch/loyalty_data.txt"
local NOTES_PATH = "monarch/loyalty_notes.txt"

function Monarch.Loyalty.Load()
    Monarch.Loyalty.Data = Monarch.Loyalty.Data or {}
    Monarch.Loyalty.Notes = Monarch.Loyalty.Notes or {}

    if file.Exists(DATA_PATH, "DATA") then
        local json = file.Read(DATA_PATH, "DATA")
        if json and json ~= "" then
            local data = util.JSONToTable(json)
            if data and type(data) == "table" then
                for charKey, record in pairs(data) do
                    if charKey and tostring(charKey) ~= "" then
                        Monarch.Loyalty.Data[tostring(charKey)] = record
                    end
                end
            end
        end
    end

    if file.Exists(NOTES_PATH, "DATA") then
        local json = file.Read(NOTES_PATH, "DATA")
        if json and json ~= "" then
            local data = util.JSONToTable(json)
            if data and type(data) == "table" then
                for charKey, note in pairs(data) do
                    if charKey and tostring(charKey) ~= "" then
                        Monarch.Loyalty.Notes[tostring(charKey)] = note
                    end
                end
            end
        end
    end
end

function Monarch.Loyalty.Save()
    if not file.Exists("monarch", "DATA") then
        file.CreateDir("monarch")
    end

    local json = util.TableToJSON(Monarch.Loyalty.Data, true)
    if json and json ~= "" then
        file.Write(DATA_PATH, json)
    end

    local notesJson = util.TableToJSON(Monarch.Loyalty.Notes, true)
    if notesJson and notesJson ~= "" then
        file.Write(NOTES_PATH, notesJson)
    end
end

function Monarch.Loyalty.GetPlayerData(ply)
    local charid = getCharID(ply)
    if not charid then return nil end
    charid = tostring(charid)

    if not Monarch.Loyalty.Data[charid] then
        Monarch.Loyalty.Data[charid] = {
            char_id = charid,
            steamid = ply:SteamID() or "Unknown",
            name = getCharName(ply),
            char_name = getCharName(ply),
            loyalty_points = 0,
            party_tier = 0,
            tax_rate = 0.30,
            last_updated = os.time(),
        }
    end

    local d = Monarch.Loyalty.Data[charid]
    d.char_id = charid
    d.steamid = ply:SteamID() or d.steamid or "Unknown"
    local cname = getCharName(ply)
    d.name = cname
    d.char_name = cname
    d.loyalty_points = tonumber(d.loyalty_points) or 0
    d.party_tier = tonumber(d.party_tier) or 0
    d.tax_rate = tonumber(d.tax_rate) or 0.30
    d.last_updated = os.time()

    return d
end

function Monarch.Loyalty.SetLoyaltyTier(ply, tier, skipNotification)
    local points = math.Clamp(tonumber(tier) or 0, 0, 65535)
    local data = Monarch.Loyalty.GetPlayerData(ply)
    if not data then return end

    local oldPoints = tonumber(data.loyalty_points) or 0
    data.loyalty_points = points
    data.last_updated = os.time()
    Monarch.Loyalty.Save()
    Monarch.Loyalty.SyncToAll()

    if not skipNotification and IsValid(ply) and points > oldPoints then
        local gain = points - oldPoints
        net.Start("Monarch_LoyaltyGain")
        net.WriteInt(math.Clamp(gain, 0, 127), 8)
        net.Send(ply)
    end
end

function Monarch.Loyalty.SetPartyTier(ply, tier)
    tier = math.Clamp(tonumber(tier) or 0, 0, 4)
    local data = Monarch.Loyalty.GetPlayerData(ply)
    if not data then return end
    data.party_tier = tier
    data.last_updated = os.time()
    Monarch.Loyalty.Save()
    Monarch.Loyalty.SyncToAll()
end

function Monarch.Loyalty.SetTaxRate(ply, rate)
    rate = math.Clamp(tonumber(rate) or 0.30, 0, 1)
    local data = Monarch.Loyalty.GetPlayerData(ply)
    if not data then return end
    data.tax_rate = rate
    data.last_updated = os.time()
    Monarch.Loyalty.Save()
    Monarch.Loyalty.SyncToAll()
end

function Monarch.Loyalty.GetNote(charKey)
    if not charKey then return "" end
    charKey = tostring(charKey)
    return Monarch.Loyalty.Notes[charKey] or ""
end

function Monarch.Loyalty.SetNote(charKey, note)
    if not charKey then return end
    charKey = tostring(charKey)
    if note and note ~= "" then
        Monarch.Loyalty.Notes[charKey] = note
    else
        Monarch.Loyalty.Notes[charKey] = nil
    end
    Monarch.Loyalty.Save()
end

function Monarch.Loyalty.SyncToPlayer(ply)
    if not IsValid(ply) then return end

	ensureAllPlayers()
	rebuildAndSyncNames()

    net.Start("Monarch_Loyalty_Sync")
    local validCount = 0
    for _, data in pairs(Monarch.Loyalty.Data) do
        if data.char_id then
            validCount = validCount + 1
        end
    end

    net.WriteUInt(validCount, 16)
    for charKey, data in pairs(Monarch.Loyalty.Data) do
        if data.char_id then
            net.WriteString(charKey)
            net.WriteString(data.steamid or "Unknown")
            net.WriteString(data.name or "Unknown")
            net.WriteString(data.char_name or data.name or "Unknown")
			net.WriteUInt(data.loyalty_points or 0, 16)
            net.WriteUInt(data.party_tier or 0, 4)
            net.WriteFloat(data.tax_rate or 0.30)
            net.WriteString(Monarch.Loyalty.GetNote(charKey))
        end
    end
    net.Send(ply)
end

function Monarch.Loyalty.SyncToAll()
	ensureAllPlayers()
	rebuildAndSyncNames()
    for _, ply in ipairs(player.GetAll()) do
        Monarch.Loyalty.SyncToPlayer(ply)
    end
end

hook.Add("PlayerInitialSpawn", "Monarch_Loyalty_AutoSeed", function(ply)
    ensureAllPlayers()
    timer.Simple(1, function()
        if IsValid(ply) then
            Monarch.Loyalty.SyncToAll()
        end
    end)
end)

timer.Create("Monarch_Loyalty_PeriodicSync", 15, 0, function()
    ensureAllPlayers()
    Monarch.Loyalty.SyncToAll()
end)

net.Receive("Monarch_Loyalty_RequestData", function(len, ply)

    ensureAllPlayers()
    rebuildAndSyncNames()
    Monarch.Loyalty.SyncToPlayer(ply)
end)

net.Receive("Monarch_Loyalty_UpdateTier", function(len, ply)
    if not ply:IsAdmin() then return end

    local charKey = tostring(net.ReadString() or "")
    local points = net.ReadUInt(16)

    if charKey == "" then return end

    local target = findPlayerByCharID(charKey)
    if IsValid(target) then
        Monarch.Loyalty.GetPlayerData(target)
        rebuildAndSyncNames()
        Monarch.Loyalty.SetLoyaltyTier(target, points)
    else
        local data = ensureCharRecord(charKey)
        if data then
            data.loyalty_points = math.Clamp(points, 0, 65535)
            data.last_updated = os.time()
            Monarch.Loyalty.Save()
            Monarch.Loyalty.SyncToAll()
        end
    end
end)

net.Receive("Monarch_Loyalty_UpdateParty", function(len, ply)
    if not ply:IsAdmin() then return end

    local charKey = tostring(net.ReadString() or "")
    local tier = net.ReadUInt(4)

    if charKey == "" then return end

    local target = findPlayerByCharID(charKey)
    if IsValid(target) then
        Monarch.Loyalty.GetPlayerData(target)
        rebuildAndSyncNames()
        Monarch.Loyalty.SetPartyTier(target, tier)
    else
        local data = ensureCharRecord(charKey)
        if data then
            data.party_tier = math.Clamp(tier, 0, 4)
            data.last_updated = os.time()
            Monarch.Loyalty.Save()
            Monarch.Loyalty.SyncToAll()
        end
    end
end)

net.Receive("Monarch_Loyalty_UpdateTax", function(len, ply)
    if not ply:IsAdmin() then return end

    local charKey = tostring(net.ReadString() or "")
    local rate = net.ReadFloat()

    if charKey == "" then return end

    local target = findPlayerByCharID(charKey)
    if IsValid(target) then
        Monarch.Loyalty.GetPlayerData(target)
        rebuildAndSyncNames()
        Monarch.Loyalty.SetTaxRate(target, rate)
    else
        local data = ensureCharRecord(charKey)
        if data then
            data.tax_rate = math.Clamp(rate, 0, 1)
            data.last_updated = os.time()
            Monarch.Loyalty.Save()
            Monarch.Loyalty.SyncToAll()
        end
    end
end)

net.Receive("Monarch_Loyalty_UpdateNote", function(len, ply)
    if not ply:IsAdmin() then return end

    local charKey = tostring(net.ReadString() or "")
    local note = net.ReadString()

    if charKey == "" then return end

    Monarch.Loyalty.SetNote(charKey, note)
    rebuildAndSyncNames()
    Monarch.Loyalty.SyncToAll()
end)

hook.Add("PlayerInitialSpawn", "Monarch_Loyalty_Init", function(ply)
    Monarch.Loyalty.GetPlayerData(ply)
    timer.Simple(1, function()
        if IsValid(ply) then
            Monarch.Loyalty.SyncToPlayer(ply)
        end
    end)
end)

hook.Add("Initialize", "Monarch_Loyalty_Load", function()
    Monarch.Loyalty.Load()
end)

hook.Add("ShutDown", "Monarch_Loyalty_Save_OnShutdown", function()
    Monarch.Loyalty.Save()
end)

hook.Add("Monarch_CharLoaded", "Monarch_Loyalty_OnCharLoaded", function(ply, charData)
    if not IsValid(ply) then return end
    Monarch.Loyalty.GetPlayerData(ply)
    Monarch.Loyalty.SyncToPlayer(ply)
end)
