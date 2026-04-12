if not SERVER then return end

util.AddNetworkString("Monarch_Tools_GiveTools")
util.AddNetworkString("Monarch_Tools_Ban")
util.AddNetworkString("Monarch_Tools_Warn")
util.AddNetworkString("Monarch_Tools_Kick")
util.AddNetworkString("Monarch_Tools_GetNotes")
util.AddNetworkString("Monarch_Tools_AddNote")
util.AddNetworkString("Monarch_Tools_NotesData")
util.AddNetworkString("Monarch_Tools_GetLogs")
util.AddNetworkString("Monarch_Tools_LogsData")
util.AddNetworkString("Monarch_Tools_Freeze")
util.AddNetworkString("Monarch_Tools_Unfreeze")
util.AddNetworkString("Monarch_Tools_CloakToggle")
util.AddNetworkString("Monarch_Tools_NoclipToggle")
util.AddNetworkString("Monarch_Tools_Bring")
util.AddNetworkString("Monarch_Tools_Goto")
util.AddNetworkString("Monarch_Tools_SpectateStart")
util.AddNetworkString("Monarch_Tools_SpectateStop")
util.AddNetworkString("Monarch_Tools_CleanupProps")
util.AddNetworkString("Monarch_Admin_GetAllChars")
util.AddNetworkString("Monarch_Admin_AllChars")
util.AddNetworkString("Monarch_Admin_UpdateChar")
util.AddNetworkString("Monarch_Admin_UpdateCharResult")
util.AddNetworkString("Monarch_CharDelete")
util.AddNetworkString("Monarch_Staff_SetGroup")

Monarch = Monarch or {}

Monarch.AdminLogs = Monarch.AdminLogs or {}
local LOG_LIMIT = 500
local function AddAdminLog(action, admin, target, duration, reason)
    local rec = {
        time = os.time(),
        action = action or "",
        adminName = IsValid(admin) and admin:Nick() or tostring(admin),
        adminSID = IsValid(admin) and admin:SteamID64() or tostring(admin),
        targetName = IsValid(target) and target:Nick() or tostring(target),
        targetSID = IsValid(target) and target:SteamID64() or tostring(target),
        duration = duration or 0,
        reason = reason or ""
    }
    table.insert(Monarch.AdminLogs, rec)
    if #Monarch.AdminLogs > LOG_LIMIT then
        table.remove(Monarch.AdminLogs, 1)
    end
end

local function IsAdmin(ply)
    if Monarch and Monarch.IsAdminRank then return Monarch.IsAdminRank(ply) end
    return IsValid(ply) and ply:IsAdmin()
end

local function IsSuperAdmin(ply)
    if Monarch and Monarch.IsSuperAdminRank then return Monarch.IsSuperAdminRank(ply) end
    return IsValid(ply) and ply:IsSuperAdmin()
end

net.Receive("Monarch_Tools_GiveTools", function(_, ply)
    if not IsAdmin(ply) then return end
    if not IsValid(ply) then return end

    if ply:HasWeapon("weapon_physgun") and ply:HasWeapon("gmod_tool") then
        ply:StripWeapon("weapon_physgun")  
        ply:StripWeapon("gmod_tool")
        AddAdminLog("give_tools", ply, ply, 0, "Removed staff tools.")
        return
    end

    ply:Give("weapon_physgun")
    ply:Give("gmod_tool")
    timer.Simple(0, function()
        if IsValid(ply) then ply:SelectWeapon("weapon_physgun") end
    end)

    AddAdminLog("give_tools", ply, ply, 0, "Gave staff tools.")
end)

net.Receive("Monarch_Tools_Ban", function(_, ply)
    if not IsAdmin(ply) then return end
    local target = net.ReadEntity()
    local minutes = net.ReadUInt(16) or 0
    local reason = net.ReadString() or ""
    if not IsValid(target) or not target:IsPlayer() then if ply.Notify then ply:Notify("Invalid target.") end return end
    local sid = target:SteamID()
    if minutes > 0 then
        game.ConsoleCommand(string.format("banid %d %s kick\n", minutes, sid))
        game.ConsoleCommand("writeid\n")
    end
    target:Kick(reason ~= "" and reason or "Banned")
    if ply.Notify then ply:Notify("Banned "..target:Nick().." for "..tostring(minutes).." minute(s).") end
    AddAdminLog("ban", ply, target, minutes, reason)
end)

net.Receive("Monarch_Tools_Warn", function(_, ply)
    if not IsAdmin(ply) then return end
    local target = net.ReadEntity()
    local reason = net.ReadString() or ""
    if not IsValid(target) or not target:IsPlayer() then if ply.Notify then ply:Notify("Invalid target.") end return end

    if Monarch and Monarch.Warns then
        local sid = target:SteamID64()
        Monarch.Warns[sid] = Monarch.Warns[sid] or {}
        table.insert(Monarch.Warns[sid], {
            time = os.time(),
            admin = ply:SteamID64(),
            adminName = ply:Nick(),
            reason = reason,
            id = tostring(os.time()) .. "-" .. tostring(ply:SteamID64()) .. "-" .. tostring(math.random(100000,999999))
        })
        Monarch.SaveWarns()
    end

    if target.Notify then target:Notify("You have been warned: "..reason) end
    if ply.Notify then ply:Notify("Warned "..target:Nick()..".") end
    AddAdminLog("warn", ply, target, 0, reason)
end)

net.Receive("Monarch_Tools_Kick", function(_, ply)
    if not IsAdmin(ply) then return end
    local target = net.ReadEntity()
    local reason = net.ReadString() or ""
    if not IsValid(target) or not target:IsPlayer() then if ply.Notify then ply:Notify("Invalid target.") end return end
    target:Kick(reason ~= "" and reason or "Kicked")
    if ply.Notify then ply:Notify("Kicked "..target:Nick()..".") end
    AddAdminLog("kick", ply, target, 0, reason)
end)

net.Receive("Monarch_Tools_GetLogs", function(_, ply)
    if not IsAdmin(ply) then return end
    local count = net.ReadUInt(12) or 100
    count = math.Clamp(count, 1, LOG_LIMIT)
    local total = #Monarch.AdminLogs
    local startIdx = math.max(1, total - count + 1)
    local slice = {}
    for i = startIdx, total do table.insert(slice, Monarch.AdminLogs[i]) end
    net.Start("Monarch_Tools_LogsData")
        net.WriteTable(slice)
    net.Send(ply)
end)

net.Receive("Monarch_Tools_Freeze", function(_, admin)
    if not IsAdmin(admin) then return end
    local target = net.ReadEntity()
    local enable = net.ReadBool()
    if not IsValid(target) or not target:IsPlayer() then return end
    target:Freeze(enable)
    if admin.Notify then admin:Notify((enable and "Froze " or "Unfroze ") .. target:Nick()) end
    AddAdminLog(enable and "freeze" or "unfreeze", admin, target, 0, "")
end)

net.Receive("Monarch_Admin_GetAllChars", function(_, admin)
    if not IsAdmin(admin) then return end
    if not mysql or not mysql.Select then return end
    local q = mysql:Select("monarch_players")
    q:Select("id"); q:Select("steamid"); q:Select("rpname"); q:Select("model"); q:Select("skin"); q:Select("team"); q:Select("xp"); q:Select("money")
    q:Callback(function(rows)
        local out = {}
        if type(rows) == "table" then
            for _, r in ipairs(rows) do
                table.insert(out, {
                    id = tonumber(r.id) or 0,
                    steamid = tostring(r.steamid or ""),
                    name = tostring(r.rpname or ""),
                    model = tostring(r.model or ""),
                    skin = tonumber(r.skin) or 0,
                    team = tonumber(r.team) or 1,
                    xp = tonumber(r.xp) or 0,
                    money = tonumber(r.money) or 0
                })
            end
        end
        if IsValid(admin) then
            net.Start("Monarch_Admin_AllChars")
                net.WriteTable(out)
            net.Send(admin)
        end
    end)
    q:Execute()
end)

net.Receive("Monarch_Admin_UpdateChar", function(_, admin)
    if not IsAdmin(admin) then return end
    local id = net.ReadUInt(32)
    local name = net.ReadString() or ""
    local model = net.ReadString() or ""
    local team = net.ReadUInt(8) or 1
    local skin = net.ReadUInt(8) or 0
    local xp = net.ReadInt(32) or 0
    local money = net.ReadInt(32) or 0
    if not mysql or not mysql.Update then return end
    local u = mysql:Update("monarch_players")
    u:Update("rpname", name)
    u:Update("model", model)
    u:Update("team", team)
    u:Update("skin", skin)
    u:Update("xp", xp)
    u:Update("money", money)
    u:Where("id", id)
    u:Callback(function(_, ok)
        ok = ok ~= false
        if IsValid(admin) then
            net.Start("Monarch_Admin_UpdateCharResult")
                net.WriteBool(ok)
                net.WriteUInt(id, 32)
            net.Send(admin)
        end
        if ok then
            for _, ply in player.Iterator() do
                if IsValid(ply) and tonumber(ply.MonarchLastCharID or 0) == tonumber(id) then
                    if model and model ~= "" then ply:SetModel(model) end
                    ply:SetSkin(skin or 0)
                    if ply.SetMoney then ply:SetMoney(money or 0) end

                    ply.MonarchActiveChar = ply.MonarchActiveChar or {}
                    ply.MonarchActiveChar.rpname = name
                    ply.MonarchActiveChar.model = model
                    ply.MonarchActiveChar.team = team
                    ply.MonarchActiveChar.skin = skin
                    ply.MonarchActiveChar.xp = xp
                    ply.MonarchActiveChar.money = money
                end
            end
            AddAdminLog("char_update", admin, id, 0, string.format("%s|%s", name, model))
        end
    end)
    u:Execute()
end)

net.Receive("Monarch_CharDelete", function(_, admin)
    if not IsAdmin(admin) then return end
    local id = net.ReadUInt(32)
    if not mysql or not mysql.Delete then return end
    local d = mysql:Delete("monarch_players")
    d:Where("id", id)
    d:Callback(function(_, ok)
        AddAdminLog("char_delete", admin, id, 0, ok and "ok" or "fail")
    end)
    d:Execute()
end)

local STAFF_ORDER = { "user", "operator", "owner", "director", "moderator", "admin", "superadmin" }
local STAFF_RANK = {}
for i, g in ipairs(STAFF_ORDER) do STAFF_RANK[g] = i end

local function IsValidGroupId(id)
    id = string.lower(id or "user")
    if Monarch and Monarch.Ranks and Monarch.Ranks.Get then
        if Monarch.Ranks.Get(id) then return true end
    end
    if STAFF_RANK[id] then return true end
    return false
end

net.Receive("Monarch_Staff_SetGroup", function(_, admin)
    if not IsValid(admin) or not admin:IsSuperAdmin() then return end
    local target = net.ReadEntity()
    local group = string.lower(net.ReadString() or "user")
    if not IsValid(target) or not target:IsPlayer() then return end
    if not IsValidGroupId(group) then group = "user" end
    target:SetUserGroup(group)
    if Monarch and Monarch.StaffSetGroupPersist then
        Monarch.StaffSetGroupPersist(target:SteamID64(), target:Nick(), group)
    end
    if admin.Notify then admin:Notify("Set "..target:Nick().." group to "..group..".") end
    if target.Notify then target:Notify("Your group was set to "..group.." by "..admin:Nick()..".") end
    AddAdminLog("set_usergroup", admin, target, 0, group)
end)

local function SetCloak(ply, cloak)
    if not IsValid(ply) then return end
    ply:SetNoDraw(cloak)
    ply:DrawWorldModel(not cloak)
    ply:DrawShadow(not cloak)
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) then wep:SetNoDraw(cloak) end
end

net.Receive("Monarch_Tools_CloakToggle", function(_, admin)
    if not IsAdmin(admin) then return end
    local target = net.ReadEntity()
    if not IsValid(target) or not target:IsPlayer() then return end
    local newState = not target:GetNoDraw()
    SetCloak(target, newState)
    if admin.Notify then admin:Notify((newState and "Cloaked " or "Uncloaked ") .. target:Nick()) end
    AddAdminLog(newState and "cloak" or "uncloak", admin, target, 0, "")
end)

net.Receive("Monarch_Tools_NoclipToggle", function(_, admin)
    if not IsAdmin(admin) then return end
    if not IsValid(admin) then return end
    local movetype = admin:GetMoveType()
    if movetype == MOVETYPE_NOCLIP then
        admin:SetMoveType(MOVETYPE_WALK)
        if admin.Notify then admin:Notify("Noclip disabled.") end
        AddAdminLog("noclip_off", admin, admin, 0, "")
    else
        admin:SetMoveType(MOVETYPE_NOCLIP)
        if admin.Notify then admin:Notify("Noclip enabled.") end
        AddAdminLog("noclip_on", admin, admin, 0, "")
    end
end)

local function FindSafePosAround(pos, radius)
    radius = radius or 36
    local tr = util.TraceHull({
        start = pos + Vector(0,0,10),
        endpos = pos + Vector(0,0,10),
        mins = Vector(-16,-16,0),
        maxs = Vector(16,16,72),
        mask = MASK_PLAYERSOLID
    })
    if not tr.Hit then return pos end
    local dirs = {Vector(radius,0,0), Vector(-radius,0,0), Vector(0,radius,0), Vector(0,-radius,0), Vector(radius,radius,0), Vector(-radius,-radius,0)}
    for _, d in ipairs(dirs) do
        local p = pos + d
        tr = util.TraceHull({start = p, endpos = p, mins = Vector(-16,-16,0), maxs = Vector(16,16,72), mask = MASK_PLAYERSOLID})
        if not tr.Hit then return p end
    end
    return pos
end

net.Receive("Monarch_Tools_Bring", function(_, admin)
    if not IsAdmin(admin) then return end
    local target = net.ReadEntity()
    if not IsValid(target) or not target:IsPlayer() or not IsValid(admin) then return end
    local pos = FindSafePosAround(admin:GetPos() + admin:GetForward()*50, 48)
    target:SetPos(pos)
    if admin.Notify then admin:Notify("Brought "..target:Nick()..".") end
    if target.Notify then target:Notify("You have been brought by staff.") end
    AddAdminLog("bring", admin, target, 0, "")
end)

net.Receive("Monarch_Tools_Goto", function(_, admin)
    if not IsAdmin(admin) then return end
    local target = net.ReadEntity()
    if not IsValid(target) or not target:IsPlayer() or not IsValid(admin) then return end
    local pos = FindSafePosAround(target:GetPos() + target:GetForward()*40, 48)
    admin:SetPos(pos)
    if admin.Notify then admin:Notify("Teleported to "..target:Nick()..".") end
    AddAdminLog("goto", admin, target, 0, "")
end)

net.Receive("Monarch_Tools_SpectateStart", function(_, admin)
    if not IsAdmin(admin) then return end
    local target = net.ReadEntity()
    if not IsValid(target) or not target:IsPlayer() then return end
    admin:Spectate(OBS_MODE_IN_EYE)
    admin:SpectateEntity(target)
    admin._MonarchSpectating = target
    if admin.Notify then admin:Notify("Spectating "..target:Nick()..".") end
    AddAdminLog("spectate_start", admin, target, 0, "")
end)

net.Receive("Monarch_Tools_SpectateStop", function(_, admin)
    if not IsAdmin(admin) then return end
    if admin:GetObserverMode() ~= OBS_MODE_NONE then
        admin:UnSpectate()
        if admin.Notify then admin:Notify("Stopped spectating.") end
        AddAdminLog("spectate_stop", admin, admin._MonarchSpectating, 0, "")
        admin._MonarchSpectating = nil
    end
end)

local function PropOwnedBy(ent, ply)
    if not IsValid(ent) then return false end
    if ent.CPPIGetOwner then
        local ok, owner = pcall(function() return ent:CPPIGetOwner() end)
        if ok and owner == ply then return true end
    end
    if ent.GetCreator and ent:GetCreator() == ply then return true end
    return false
end

net.Receive("Monarch_Tools_CleanupProps", function(_, admin)
    if not IsAdmin(admin) then return end
    local target = net.ReadEntity()
    if not IsValid(target) or not target:IsPlayer() then return end
    local count = 0
    for _, ent in ipairs(ents.GetAll()) do
        if PropOwnedBy(ent, target) then
            if IsValid(ent) and not ent:IsPlayer() then ent:Remove() count = count + 1 end
        end
    end
    if admin.Notify then admin:Notify("Removed "..tostring(count).." prop(s) owned by "..target:Nick()..".") end
    AddAdminLog("cleanup_props", admin, target, 0, tostring(count))
end)
