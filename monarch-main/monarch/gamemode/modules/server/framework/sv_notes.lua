if not SERVER then return end

util.AddNetworkString("Monarch_Tools_GetNotes")
util.AddNetworkString("Monarch_Tools_NotesData")
util.AddNetworkString("Monarch_Tools_AddNote")
util.AddNetworkString("Monarch_Tools_RemoveNote")
util.AddNetworkString("Monarch_Tools_GetWarns")
util.AddNetworkString("Monarch_Tools_WarnsData")
util.AddNetworkString("Monarch_Tools_RemoveWarn")
util.AddNetworkString("Monarch_Tools_RemoveWarnById")

Monarch = Monarch or {}
Monarch.Notes = Monarch.Notes or {}
Monarch.Warns = Monarch.Warns or {}

local DATA_DIR = "monarch"
local DATA_FILE = DATA_DIR .. "/player_notes.txt"
local WARNS_FILE = DATA_DIR .. "/player_warns.txt"
local WARN_DIR = "monarch/moderation/warns"
local NOTE_DIR = "monarch/moderation/notes"

local function EnsureDir()
    if not file.Exists(DATA_DIR, "DATA") then file.CreateDir(DATA_DIR) end
end

local function LoadNotes()
    EnsureDir()
    if not file.Exists(DATA_FILE, "DATA") then
        Monarch.Notes = {}
        file.Write(DATA_FILE, util.TableToJSON(Monarch.Notes, true))
        return
    end
    local raw = file.Read(DATA_FILE, "DATA") or "{}"
    local ok, tbl = pcall(util.JSONToTable, raw)
    Monarch.Notes = (ok and istable(tbl)) and tbl or {}
end

local function SaveNotes()
    EnsureDir()
    file.Write(DATA_FILE, util.TableToJSON(Monarch.Notes or {}, true))
end

local function LoadWarns()
    EnsureDir()
    if not file.Exists(WARNS_FILE, "DATA") then
        Monarch.Warns = {}
        file.Write(WARNS_FILE, util.TableToJSON(Monarch.Warns, true))
        return
    end
    local raw = file.Read(WARNS_FILE, "DATA") or "{}"
    local ok, tbl = pcall(util.JSONToTable, raw)
    Monarch.Warns = (ok and istable(tbl)) and tbl or {}

    local migrated = false
    for sid, arr in pairs(Monarch.Warns) do
        if istable(arr) then
            for i, rec in ipairs(arr) do
                if not rec.id or tostring(rec.id) == "" then
                    rec.id = tostring(rec.time or os.time()) .. "-" .. tostring(rec.admin or "unknown") .. "-" .. tostring(math.random(100000,999999))
                    migrated = true
                end
            end
        end
    end
    if migrated then
        print("[Monarch Warns] Migration: backfilled warn ids; saving updated warns file")
        SaveWarns()
    end
end

local function EnsureWarnDir()
    file.CreateDir("monarch")
    file.CreateDir("monarch/moderation")
    file.CreateDir(WARN_DIR)
end

local function EnsureNoteDir()
    file.CreateDir("monarch")
    file.CreateDir("monarch/moderation")
    file.CreateDir(NOTE_DIR)
end

local function BackfillIds(arr)
    local migrated = false
    for _, rec in ipairs(arr) do
        if not rec.id or tostring(rec.id) == "" then
            rec.id = tostring(rec.time or os.time()) .. "-" .. tostring(rec.admin or "unknown") .. "-" .. tostring(math.random(100000,999999))
            migrated = true
        end
    end
    return migrated
end

local function BackfillNoteIds(arr)
    local migrated = false
    for _, rec in ipairs(arr) do
        if not rec.id or tostring(rec.id) == "" then
            rec.id = tostring(rec.time or os.time()) .. "-" .. tostring(rec.admin or "unknown") .. "-" .. tostring(math.random(100000,999999))
            migrated = true
        end
    end
    return migrated
end

local function LoadWarnsForSid(sid)
    sid = tostring(sid or "")
    if sid == "" then return {} end
    EnsureWarnDir()
    local path = WARN_DIR .. "/" .. sid .. ".json"
    local arr = {}
    if file.Exists(path, "DATA") then
        arr = util.JSONToTable(file.Read(path, "DATA") or "[]") or {}
    else
        arr = Monarch.Warns[sid] or {}
    end
    if not istable(arr) then arr = {} end
    if BackfillIds(arr) then
        file.Write(path, util.TableToJSON(arr, true))
    end
    Monarch.Warns[sid] = arr
    return arr
end

local function LoadNotesForSid(sid)
    sid = tostring(sid or "")
    if sid == "" then return {} end
    EnsureNoteDir()
    local path = NOTE_DIR .. "/" .. sid .. ".json"
    local arr = {}
    if file.Exists(path, "DATA") then
        arr = util.JSONToTable(file.Read(path, "DATA") or "[]") or {}
    else
        arr = Monarch.Notes[sid] or {}
    end
    if not istable(arr) then arr = {} end
    if BackfillNoteIds(arr) then
        file.Write(path, util.TableToJSON(arr, true))
    end
    Monarch.Notes[sid] = arr
    return arr
end

local function WriteNotesForSid(sid, arr)
    sid = tostring(sid or "")
    if sid == "" then return end
    EnsureNoteDir()
    arr = arr or {}
    Monarch.Notes[sid] = arr
    local path = NOTE_DIR .. "/" .. sid .. ".json"
    file.Write(path, util.TableToJSON(arr, true))
end

local function WriteWarnsForSid(sid, arr)
    sid = tostring(sid or "")
    if sid == "" then return end
    EnsureWarnDir()
    arr = arr or {}
    Monarch.Warns[sid] = arr
    local path = WARN_DIR .. "/" .. sid .. ".json"
    file.Write(path, util.TableToJSON(arr, true))
end

local function SaveWarns()
    EnsureDir()
    file.Write(WARNS_FILE, util.TableToJSON(Monarch.Warns or {}, true))
end

Monarch.SaveNotes = SaveNotes
Monarch.SaveWarns = SaveWarns

local function IsStaff(ply)
    if not IsValid(ply) then return false end
    if Monarch.IsAdminRank and Monarch.IsAdminRank(ply) then return true end
    return ply:IsAdmin()
end

local function ToSID64(id)
    if not id or id == "" then return "" end
    id = tostring(id)
    if string.match(id, "^%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d$") then return id end
    if string.find(id, "STEAM_") then
        local ok, sid64 = pcall(util.SteamIDTo64, id)
        if ok and sid64 then return sid64 end
    end
    return id
end

net.Receive("Monarch_Tools_GetNotes", function(_, ply) 
    if not IsStaff(ply) then return end
    local sid = ToSID64(net.ReadString() or "")
    if sid == "" then return end
    local arr = LoadNotesForSid(sid)
    net.Start("Monarch_Tools_NotesData")
        net.WriteString(sid)
        net.WriteTable(arr)
    net.Send(ply)
end)

net.Receive("Monarch_Tools_AddNote", function(_, ply)
    if not IsStaff(ply) then return end
    local sid = ToSID64(net.ReadString() or "")
    local text = string.sub(net.ReadString() or "", 1, 500)
    if sid == "" or text == "" then return end
    local arr = LoadNotesForSid(sid)
    table.insert(arr, {
        time = os.time(),
        admin = ply:SteamID64(),
        adminName = ply:Nick(),
        text = text,
        id = tostring(os.time()) .. "-" .. tostring(ply:SteamID64() or "unknown") .. "-" .. tostring(math.random(100000,999999))
    })
    WriteNotesForSid(sid, arr)
    net.Start("Monarch_Tools_NotesData")
        net.WriteString(sid)
        net.WriteTable(arr)
    net.Send(ply)
end)

net.Receive("Monarch_Tools_RemoveNote", function(_, ply)
    if not IsStaff(ply) then return end
    local sid = ToSID64(net.ReadString() or "")
    local idx = tonumber(net.ReadUInt(16) or 0) or 0
    if sid == "" or idx <= 0 then return end
    local arr = LoadNotesForSid(sid)

    print("[Monarch Notes] Remove request: SID="..sid.." idx="..idx.." arr_exists="..tostring(istable(arr)).." arr_count="..tostring(arr and #arr or 0))

    if not istable(arr) or #arr < idx then
        print("[Monarch Notes] Remove failed: invalid index for SID " .. sid .. " (idx="..tostring(idx).." arraylen="..tostring(arr and #arr or 0)..")")
        net.Start("Monarch_Tools_NotesData")
            net.WriteString(sid)
            net.WriteTable(arr or {})
        net.Send(ply)
        return
    end
    local removed = table.remove(arr, idx)
    print("[Monarch Notes] Removed note #"..idx.." for SID "..sid.." by "..ply:Nick())
    WriteNotesForSid(sid, arr)
    net.Start("Monarch_Tools_NotesData")
        net.WriteString(sid)
        net.WriteTable(arr)
    net.Send(ply)
end)

net.Receive("Monarch_Tools_GetWarns", function(_, ply)
    if not IsStaff(ply) then return end
    local sid = ToSID64(net.ReadString() or "")
    if sid == "" then return end
    local arr = LoadWarnsForSid(sid)
    net.Start("Monarch_Tools_WarnsData")
        net.WriteString(sid)
        net.WriteTable(arr)
    net.Send(ply)
end)

net.Receive("Monarch_Tools_RemoveWarn", function(_, ply)
    if not IsStaff(ply) then return end
    local sid = ToSID64(net.ReadString() or "")
    local idx = tonumber(net.ReadUInt(16) or 0) or 0
    if sid == "" or idx <= 0 then return end
    local arr = LoadWarnsForSid(sid)

    print("[Monarch Warns] Remove request: SID="..sid.." idx="..idx.." arr_exists="..tostring(istable(arr)).." arr_count="..tostring(arr and #arr or 0))

    if not istable(arr) then arr = {} end
    if #arr < idx then
        print("[Monarch Warns] Remove failed: invalid index for SID " .. sid .. " (idx="..tostring(idx).." arraylen="..tostring(#arr)..")")
        net.Start("Monarch_Tools_WarnsData")
            net.WriteString(sid)
            net.WriteTable(arr)
        net.Send(ply)
        return
    end
    local removed = table.remove(arr, idx)
    print("[Monarch Warns] Removed warn #"..idx.." for SID "..sid.." by "..ply:Nick())
    WriteWarnsForSid(sid, arr)
    net.Start("Monarch_Tools_WarnsData")
        net.WriteString(sid)
        net.WriteTable(arr)
    net.Send(ply)
end)

net.Receive("Monarch_Tools_RemoveWarnById", function(_, ply)
    if not IsStaff(ply) then return end
    local sid = ToSID64(net.ReadString() or "")
    local warnId = tostring(net.ReadString() or "")
    if sid == "" or warnId == "" then return end
    local arr = LoadWarnsForSid(sid)
    if not istable(arr) or #arr == 0 then
        net.Start("Monarch_Tools_WarnsData")
            net.WriteString(sid)
            net.WriteTable(arr or {})
        net.Send(ply)
        return
    end
    local removed = false
    for i = #arr, 1, -1 do
        if tostring(arr[i].id or "") == warnId then
            table.remove(arr, i)
            removed = true
            break
        end
    end
    if removed then
        print("[Monarch Warns] Removed warn id="..warnId.." for SID "..sid.." by "..ply:Nick())
        WriteWarnsForSid(sid, arr)
    else
        print("[Monarch Warns] Warn id not found for SID "..sid.." id="..warnId)
    end
    net.Start("Monarch_Tools_WarnsData")
        net.WriteString(sid)
        net.WriteTable(arr or {})
    net.Send(ply)
end)

LoadNotes()
LoadWarns()
