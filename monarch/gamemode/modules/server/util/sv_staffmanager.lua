if not SERVER then return end

util.AddNetworkString("Monarch_Staff_RequestStats")
util.AddNetworkString("Monarch_Staff_StatsData")
util.AddNetworkString("Monarch_Staff_Reload")
util.AddNetworkString("Monarch_Staff_SetGroupSID")
util.AddNetworkString("Monarch_Staff_Add")
util.AddNetworkString("Monarch_Staff_AddStrike")
util.AddNetworkString("Monarch_Staff_RemoveStrike")
util.AddNetworkString("Monarch_Staff_RemoveStrikeById")

util.AddNetworkString("Monarch_Tools_GetNotes")
util.AddNetworkString("Monarch_Tools_NotesData")
util.AddNetworkString("Monarch_Tools_AddNote")
util.AddNetworkString("Monarch_Tools_RemoveNote")

Monarch = Monarch or {}

local DATA_DIR = "monarch"
local DATA_FILE = DATA_DIR .. "/staff_stats.txt"

Monarch.StaffStats = Monarch.StaffStats or {}

local function ToSID64(id)
    if not id or id == "" then return "" end
    id = tostring(id)
    if string.match(id, "^%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d$") then
        return id
    end
    if string.find(id, "STEAM_") then
        local ok, sid64 = pcall(util.SteamIDTo64, id)
        if ok and sid64 then return sid64 end
    end
    return id
end

local function EnsureDir()
    if not file.Exists(DATA_DIR, "DATA") then file.CreateDir(DATA_DIR) end
end

local function NormalizeKeyFromString(s)
    if not s or s == "" then return "" end
    s = tostring(s)
    if string.match(s, "^%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d$") then return s end
    if string.find(s, "e", 1, true) or string.find(s, "E", 1, true) then
        local asNum = tonumber(s)
        if asNum then
            local whole = string.format("%.0f", asNum)
            if #whole >= 17 and string.match(whole, "^%d+$") then
                return string.sub(whole, -17)
            end
        end
    end

    local digits = string.gsub(s, "[^0-9]", "")
    if #digits >= 17 then
        local tail = string.sub(digits, -17)
        if string.match(tail, "^%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d$") then
            return tail
        end
    end
    return ""
end

function Monarch.LoadStaffStats()
    EnsureDir()
    if not file.Exists(DATA_FILE, "DATA") then
        Monarch.StaffStats = {}
        file.Write(DATA_FILE, util.TableToJSON(Monarch.StaffStats, true))
        return
    end
    local raw = file.Read(DATA_FILE, "DATA") or "{}"
    local ok, tbl = pcall(util.JSONToTable, raw)
    if ok and type(tbl) == "table" then
        Monarch.StaffStats = tbl
    else
        Monarch.StaffStats = {}
    end
    local cleaned = {}
    for sid, rec in pairs(Monarch.StaffStats) do
        local raw = tostring(sid or "")
        local inner = tostring((rec and rec.sid) or "")
        local candidate = inner ~= "" and inner or raw

        local key = ToSID64(candidate)
        if key == "" or not string.match(key, "^%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d$") then
            local repaired = NormalizeKeyFromString(candidate)
            if repaired ~= "" then key = repaired end
        end
        rec = rec or {}
        rec.sid = key ~= "" and key or candidate
        rec.tickets = tonumber(rec.tickets) or 0
        rec.total_time = tonumber(rec.total_time) or 0
        rec.group = rec.group or "user"
        rec.name = rec.name or key ~= "" and key or raw
        rec.last_active = tonumber(rec.last_active) or 0
        rec.strikes = rec.strikes or {}
        rec.strike_points = tonumber(rec.strike_points) or 0
        if key ~= "" and string.match(key, "^%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d$") then
            cleaned[key] = rec
        else
            cleaned[candidate] = rec
        end
    end
    Monarch.StaffStats = cleaned
    Monarch.SaveStaffStats()
end

function Monarch.SaveStaffStats()
    EnsureDir()
    local out = {}
    for sid, rec in pairs(Monarch.StaffStats or {}) do
        local raw = tostring(sid or "")
        local key = ToSID64(raw)
        if key == "" or not string.match(key, "^%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d$") then
            local repaired = NormalizeKeyFromString(raw)
            if repaired ~= "" then key = repaired end
        end
        rec.sid = key ~= "" and key or raw
        if key ~= "" and string.match(key, "^%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d$") then
            out[key] = rec
        else
            out[raw] = rec
        end
    end
    file.Write(DATA_FILE, util.TableToJSON(out, true))
end

local function BuildStaffSnapshot()
    local out = {}
    for sid, rec in pairs(Monarch.StaffStats or {}) do
        local ply = player.GetBySteamID64(sid)
        if istable(rec.strikes) then
            for i, s in ipairs(rec.strikes) do
                if not s.id or tostring(s.id) == "" then
                    s.id = tostring(s.time or os.time()) .. "-" .. tostring(s.admin or "unknown") .. "-" .. tostring(math.random(100000,999999))
                end
            end
        end
        out[sid] = {
            name = (IsValid(ply) and ply:Nick()) or rec.name or sid,
            group = rec.group or "user",
            tickets = tonumber(rec.tickets) or 0,
            total_time = tonumber(rec.total_time) or 0,
            last_active = tonumber(rec.last_active) or 0,
            online = IsValid(ply),
            strikes = rec.strikes or {},
            strike_points = tonumber(rec.strike_points) or 0,
        }
    end
    return out
end

function Monarch.StaffSetGroupPersist(sid64, name, group)
    if not sid64 or sid64 == "" then return end
    Monarch.StaffStats = Monarch.StaffStats or {}
    local rec = Monarch.StaffStats[sid64] or { tickets = 0, total_time = 0 }
    rec.sid = sid64
    rec.name = name or rec.name or sid64
    rec.group = string.lower(group or rec.group or "user")
    rec.last_active = os.time()
    Monarch.StaffStats[sid64] = rec
    Monarch.SaveStaffStats()
end

hook.Add("PlayerInitialSpawn", "Monarch_ApplyStaffGroup", function(ply)
    timer.Simple(1, function()
        if not IsValid(ply) then return end
        local sid = ply:SteamID64()
        local data = Monarch.StaffStats and Monarch.StaffStats[sid]

        if data and data.group and data.group ~= "" then
            ply:SetUserGroup(data.group)
            return
        end

        local def = (Config and Config.DefaultOperator) or nil
        if def and def ~= "" then
            local want = ToSID64(def)
            if want ~= "" and want == sid then
                ply:SetUserGroup("operator")
                Monarch.StaffSetGroupPersist(sid, ply:Nick(), "operator")
            end
        end
    end)
end)

net.Receive("Monarch_Staff_RequestStats", function(_, admin)
    if not IsValid(admin) or not ((Monarch.IsAdminRank and Monarch.IsAdminRank(admin)) or admin:IsAdmin()) then return end
    for _, p in player.Iterator() do
        if IsValid(p) then
            local sid = p:SteamID64()
            local rec = Monarch.StaffStats[sid]
            if not rec then
                local g = string.lower(p:GetUserGroup() or "user")
                rec = { sid = sid, name = p:Nick(), group = g, tickets = 0, total_time = 0, last_active = os.time(), strikes = {}, strike_points = 0 }
                if (Monarch.IsAdminRank and Monarch.IsAdminRank(p)) or p:IsAdmin() then
                    Monarch.StaffStats[sid] = rec
                end
            else
                rec.name = p:Nick()
                rec.group = string.lower(p:GetUserGroup() or rec.group or "user")
                rec.last_active = os.time()
                rec.sid = sid
            end
        end
    end
    Monarch.SaveStaffStats()
    local out = {}
    for sid, rec in pairs(Monarch.StaffStats or {}) do
        if not out[sid] then
            local ply = player.GetBySteamID64(sid)
            out[sid] = {
                name = (IsValid(ply) and ply:Nick()) or rec.name or sid,
                group = rec.group or "user",
                tickets = tonumber(rec.tickets) or 0,
                total_time = tonumber(rec.total_time) or 0,
                last_active = tonumber(rec.last_active) or 0,
                online = IsValid(ply),
                strikes = rec.strikes or {},
                strike_points = tonumber(rec.strike_points) or 0,
            }
        end
    end
    for _, p in ipairs(player.GetAll() or {}) do
        if IsValid(p) then
            local sid = p:SteamID64()
            if not out[sid] then
                out[sid] = {
                    name = p:Nick(),
                    group = string.lower(p:GetUserGroup() or "user"),
                    tickets = 0,
                    total_time = 0,
                    last_active = os.time(),
                    online = true,
                    strikes = {},
                    strike_points = 0,
                }
            end
        end
    end
    net.Start("Monarch_Staff_StatsData")
        net.WriteTable(out)
    net.Send(admin)
end)

net.Receive("Monarch_Staff_Reload", function(_, admin)
    if not IsValid(admin) or not ((Monarch.IsAdminRank and Monarch.IsAdminRank(admin)) or admin:IsAdmin()) then return end
    Monarch.LoadStaffStats()
    local out = {}
    for sid, rec in pairs(Monarch.StaffStats or {}) do
        if not out[sid] then
            local ply = player.GetBySteamID64(sid)
            out[sid] = {
                name = (IsValid(ply) and ply:Nick()) or rec.name or sid,
                group = rec.group or "user",
                tickets = tonumber(rec.tickets) or 0,
                total_time = tonumber(rec.total_time) or 0,
                last_active = tonumber(rec.last_active) or 0,
                online = IsValid(ply),
                strikes = rec.strikes or {},
                strike_points = tonumber(rec.strike_points) or 0,
            }
        end
    end
    for _, p in ipairs(player.GetAll() or {}) do
        if IsValid(p) then
            local sid = p:SteamID64()
            if not out[sid] then
                out[sid] = {
                    name = p:Nick(),
                    group = string.lower(p:GetUserGroup() or "user"),
                    tickets = 0,
                    total_time = 0,
                    last_active = os.time(),
                    online = true,
                    strikes = {},
                    strike_points = 0,
                }
            end
        end
    end
    net.Start("Monarch_Staff_StatsData")
        net.WriteTable(out)
    net.Send(admin)
end)

net.Receive("Monarch_Staff_SetGroupSID", function(_, admin)
    if not IsValid(admin) or not (Monarch.IsSuperAdminRank and Monarch.IsSuperAdminRank(admin) or admin:IsSuperAdmin()) then return end
    local sid = net.ReadString() or ""
    local group = string.lower(net.ReadString() or "user")
    if sid == "" then return end
    local ply = player.GetBySteamID64(sid)
    Monarch.StaffSetGroupPersist(sid, IsValid(ply) and ply:Nick() or sid, group)
    if IsValid(ply) then ply:SetUserGroup(group) end
    if admin.Notify then admin:Notify("Set group for "..(IsValid(ply) and ply:Nick() or sid).." to "..group.." (persisted)") end
end)

net.Receive("Monarch_Staff_Add", function(_, admin)
    if not IsValid(admin) or not (Monarch.IsSuperAdminRank and Monarch.IsSuperAdminRank(admin) or admin:IsSuperAdmin()) then return end
    local sid = ToSID64(net.ReadString() or "")
    local name = net.ReadString() or ""
    local group = string.lower(net.ReadString() or "user")
    if sid == "" then return end
    local rec = Monarch.StaffStats[sid] or { sid = sid, tickets = 0, total_time = 0, strikes = {}, strike_points = 0 }
    if name ~= "" then rec.name = name end
    rec.group = group ~= "" and group or (rec.group or "user")
    rec.last_active = os.time()
    rec.sid = sid
    Monarch.StaffStats[sid] = rec
    Monarch.SaveStaffStats()
    local ply = player.GetBySteamID64(sid)
    if IsValid(ply) and rec.group and rec.group ~= "" then ply:SetUserGroup(rec.group) end
end)

net.Receive("Monarch_Staff_AddStrike", function(_, admin)
    if not IsValid(admin) or not (Monarch.IsAdminRank and Monarch.IsAdminRank(admin) or admin:IsAdmin()) then return end
    local sid = ToSID64(net.ReadString() or "")
    local reason = string.sub(net.ReadString() or "", 1, 300)
    local points = math.max(1, tonumber(net.ReadUInt(8) or 1))
    if sid == "" or reason == "" then return end
    local rec = Monarch.StaffStats[sid] or { name = sid, group = "user", tickets = 0, total_time = 0, strikes = {}, strike_points = 0 }
    rec.sid = sid
    rec.strikes = rec.strikes or {}
    table.insert(rec.strikes, { time = os.time(), admin = admin:SteamID64(), adminName = admin:Nick(), reason = reason, points = points, id = tostring(os.time()) .. "-" .. tostring(admin:SteamID64()) .. "-" .. tostring(math.random(100000,999999)) })
    rec.strike_points = (tonumber(rec.strike_points) or 0) + points
    rec.last_active = os.time()
    Monarch.StaffStats[sid] = rec
    Monarch.SaveStaffStats()
    local out = BuildStaffSnapshot()
    net.Start("Monarch_Staff_StatsData")
        net.WriteTable(out)
    net.Send(admin)
end)

net.Receive("Monarch_Staff_RemoveStrike", function(_, admin)
    if not IsValid(admin) or not (Monarch.IsAdminRank and Monarch.IsAdminRank(admin) or admin:IsAdmin()) then return end
    local sid = ToSID64(net.ReadString() or "")
    local idx = tonumber(net.ReadUInt(16) or 0) or 0
    if sid == "" or idx <= 0 then return end
    local rec = Monarch.StaffStats[sid]
    if not rec or not rec.strikes or not rec.strikes[idx] then return end
    local removed = table.remove(rec.strikes, idx)
    if removed and removed.points then
        rec.strike_points = math.max(0, (tonumber(rec.strike_points) or 0) - tonumber(removed.points) )
    end
    rec.last_active = os.time()
    rec.sid = sid
    Monarch.StaffStats[sid] = rec
    Monarch.SaveStaffStats()

    local out = BuildStaffSnapshot()
    net.Start("Monarch_Staff_StatsData")
        net.WriteTable(out)
    net.Send(admin)
end)

net.Receive("Monarch_Staff_RemoveStrikeById", function(_, admin)
    if not IsValid(admin) or not (Monarch.IsAdminRank and Monarch.IsAdminRank(admin) or admin:IsAdmin()) then return end
    local sid = ToSID64(net.ReadString() or "")
    local strikeId = tostring(net.ReadString() or "")
    if sid == "" or strikeId == "" then return end
    local rec = Monarch.StaffStats[sid]
    if not rec or not istable(rec.strikes) then return end
    local removed
    for i = #rec.strikes, 1, -1 do
        if tostring(rec.strikes[i].id or "") == strikeId then
            removed = table.remove(rec.strikes, i)
            break
        end
    end
    if removed and removed.points then
        rec.strike_points = math.max(0, (tonumber(rec.strike_points) or 0) - tonumber(removed.points))
    end
    rec.last_active = os.time()
    Monarch.StaffStats[sid] = rec
    Monarch.SaveStaffStats()
    local out = BuildStaffSnapshot()
    net.Start("Monarch_Staff_StatsData")
        net.WriteTable(out)
    net.Send(admin)
end)

Monarch.LoadStaffStats()

concommand.Add("monarch_staff_forcesave", function(ply)
    if IsValid(ply) then return end
    Monarch.SaveStaffStats()
    print("[Monarch] Staff stats saved to data/" .. (DATA_FILE or "monarch/staff_stats.txt"))
end, nil, "Force-save Monarch staff stats to data file.")

concommand.Add("monarch_staff_reload", function(ply)
    if IsValid(ply) then return end
    Monarch.LoadStaffStats()
    print("[Monarch] Staff stats reloaded from data/" .. (DATA_FILE or "monarch/staff_stats.txt"))
end, nil, "Reload Monarch staff stats from data file.")
