Monarch = Monarch or {}
Monarch.Skills = Monarch.Skills or {
    Registry = {},
    Thresholds = {
        [1] = 0, 
        [2] = 100,
        [3] = 250,
        [4] = 550,
        [5] = 775,
        [6] = 825,
        [7] = 1115,
        [8] = 1500,
        [9] = 1800,
        [10] = 2000,
    },
    LevelNames = {
        [1] = "Beginner",
        [2] = "Novice",
        [3] = "Advanced",
        [4] = "Professional",
    },
    Data = {},
    ClientData = {},
    XPPerSecondCraft = 1,
    Debug = true,
    _lastDbg = {},
    _dbgRate = 0.75,
}

local Skills = Monarch.Skills

function Monarch.RegisterSkill(def)
    if type(def) ~= "table" then return end
    local id = def.id or def.ID or def.UniqueID
    if type(id) ~= "string" or id == "" then
        MsgC(Color(255,0,0), "[Monarch Skills] Skill registration missing id\n")
        return
    end
    def.Name = def.Name or id
    def.XPPerSecond = tonumber(def.XPPerSecond or def.XPRate)
    Skills.Registry[id] = def

end

function Monarch.GetSkill(id)
    return Skills.Registry and Skills.Registry[id]
end

function Skills.GetLevelForXP(xp)
    xp = tonumber(xp) or 0
    local lvl = 1
    for i = 1, 100 do
        local t = Skills.Thresholds[i]
        if not t then break end
        if xp >= t then lvl = i else break end
    end
    return lvl
end

function Skills.GetLevelName(lvl)
    lvl = tonumber(lvl) or 1
    local names = Skills.LevelNames or {}
    if names[lvl] then return names[lvl] end
    local maxIdx = 0
    for i, _ in pairs(names) do if i > maxIdx then maxIdx = i end end
    if maxIdx > 0 then return names[maxIdx] end
    return "Level " .. tostring(lvl)
end

local function getCharID(ply)
    if not IsValid(ply) then return nil end
    if ply.MonarchActiveChar and ply.MonarchActiveChar.id then
        local cid = tostring(ply.MonarchActiveChar.id)
        return cid
    end
    local sid = "steamid_" .. ply:SteamID64()
    return sid
end

local function ensureLoaded(charid, ply)
    if CLIENT then return end
    Skills.Data = Skills.Data or {}
    if Skills.Data[charid] ~= nil then
        return
    end
    if not file.Exists("monarch/skills", "DATA") then file.CreateDir("monarch/skills") end
    local charPath = string.format("monarch/skills/char_%s.txt", tostring(charid))
    if file.Exists(charPath, "DATA") then
        local raw = file.Read(charPath, "DATA") or "{}"
        local t = util.JSONToTable(raw) or {}
        Skills.Data[charid] = t
        if next(Skills.Data[charid]) ~= nil then return end
    else
        Skills.Data[charid] = {}
    end

    local steamPath
    if IsValid(ply) then
        steamPath = "monarch/skills/steamid_" .. tostring(ply:SteamID64()) .. ".txt"
    else
        for _, p in player.Iterator() do
            if p.MonarchActiveChar and tostring(p.MonarchActiveChar.id) == tostring(charid) then
                steamPath = "monarch/skills/steamid_" .. tostring(p:SteamID64()) .. ".txt"
                break
            end
        end
    end
    if steamPath and file.Exists(steamPath, "DATA") then
        local raw = file.Read(steamPath, "DATA") or "{}"
        local t = util.JSONToTable(raw) or {}
        Skills.Data[charid] = t
        PrintTable(t)
        local js = util.TableToJSON(t or {}, true)
        file.Write(charPath, js)
    else
    end
end

local function persist(charid)
    if CLIENT then return end
    if not charid then return end
    if not file.Exists("monarch/skills", "DATA") then file.CreateDir("monarch/skills") end
    local path = string.format("monarch/skills/char_%s.txt", tostring(charid))
    local js = util.TableToJSON(Skills.Data[charid] or {}, true)
    file.Write(path, js)
end

function Skills.GetXP(ply, skillId)
    if not IsValid(ply) then return 0 end
    if SERVER then
        local charid = getCharID(ply)
        if not charid then return 0 end
        ensureLoaded(charid, ply)
        if Skills.Data[charid] and next(Skills.Data[charid]) == nil then
            local charPath = string.format("monarch/skills/char_%s.txt", tostring(charid))
            local steamPath = "monarch/skills/steamid_" .. tostring(ply:SteamID64()) .. ".txt"
            if file.Exists(steamPath, "DATA") then
                local raw = file.Read(steamPath, "DATA") or "{}"
                local t = util.JSONToTable(raw) or {}
                Skills.Data[charid] = t
                local js = util.TableToJSON(t or {}, true)
                file.Write(charPath, js)
            end
        end
        local t = Skills.Data[charid]
        local xp = t and t[skillId] or 0

        return tonumber(xp) or 0
    else
        local nwXP = ply:GetNWInt("Skill_" .. skillId .. "_XP", -1)
        if nwXP >= 0 then
            if Skills.Debug then
                local now = CurTime()
                local last = Skills._lastDbg["xp:" .. skillId] or 0
                if (now - last) >= (Skills._dbgRate or 0.75) then
                    Skills._lastDbg["xp:" .. skillId] = now
                end
            end
            return nwXP
        end
        local xp = Skills.ClientData and Skills.ClientData[skillId] or 0
        if Skills.Debug then
            local now = CurTime()
            local last = Skills._lastDbg["xpcli:" .. skillId] or 0
            if (now - last) >= (Skills._dbgRate or 0.75) then
                Skills._lastDbg["xpcli:" .. skillId] = now
            end
        end
        return tonumber(xp) or 0
    end
end

function Skills.GetLevel(ply, skillId)
    if CLIENT and IsValid(ply) then
        local nwLvl = ply:GetNWInt("Skill_" .. skillId .. "_Level", -1)
        if nwLvl >= 0 then
            if Skills.Debug then
                local now = CurTime()
                local last = Skills._lastDbg["lvl:" .. skillId] or 0
                if (now - last) >= (Skills._dbgRate or 0.75) then
                    Skills._lastDbg["lvl:" .. skillId] = now
                end
            end
            return nwLvl
        end
    end
    local lvl = Skills.GetLevelForXP(Skills.GetXP(ply, skillId))
    if CLIENT and Skills.Debug then
        local now = CurTime()
        local last = Skills._lastDbg["lvlcalc:" .. skillId] or 0
        if (now - last) >= (Skills._dbgRate or 0.75) then
            Skills._lastDbg["lvlcalc:" .. skillId] = now
        end
    end
    return lvl
end

function Skills.AddXP(ply, skillId, amount)
    if not IsValid(ply) then return end
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return end
    local charid = getCharID(ply)
    if not charid then return end
    ensureLoaded(charid, ply)
    local oldXP = tonumber(Skills.Data[charid][skillId] or 0) or 0
    local oldLevel = Skills.GetLevelForXP(oldXP)
    Skills.Data[charid][skillId] = (Skills.Data[charid][skillId] or 0) + amount
    local newXP = tonumber(Skills.Data[charid][skillId] or 0) or 0
    local newLevel = Skills.GetLevelForXP(newXP)
    persist(charid)
    if SERVER then
        local newLvl = newLevel
        ply:SetNWInt("Skill_" .. skillId .. "_XP", newXP)
        ply:SetNWInt("Skill_" .. skillId .. "_Level", newLvl)

        hook.Run("Monarch_OnSkillIncreased", ply, skillId, amount, oldXP, newXP, oldLevel, newLevel)

        local def = Monarch.GetSkill and Monarch.GetSkill(skillId)
        local skillName = (def and def.Name) or tostring(skillId)
        net.Start("Monarch_SkillXPGain")
            net.WriteString(tostring(skillId))
            net.WriteString(tostring(skillName))
            net.WriteInt(math.Clamp(amount, 0, 32767), 16)
        net.Send(ply)

        if Skills.SyncToClient then Skills.SyncToClient(ply) end
    end
end

function Skills.GetProgress(ply, skillId)
    local xp = Skills.GetXP(ply, skillId)
    local lvl = Skills.GetLevelForXP(xp)
    local curMin = Skills.Thresholds[lvl] or 0
    local nextMin = Skills.Thresholds[lvl + 1]
    local cur = xp - curMin
    local req = nextMin and (nextMin - curMin) or 0
    local frac = (req > 0) and (cur / req) or 1
    return lvl, math.max(0, cur), math.max(0, req), math.Clamp(frac, 0, 1)
end

function Skills.GetRate(skillId)
    local def = Skills.Registry[skillId]
    if def and def.XPPerSecond then return def.XPPerSecond end
    return Skills.XPPerSecondCraft or 1
end
if not Monarch.GetSkill or not Monarch.GetSkill("crafting") then
    Monarch.RegisterSkill({ id = "crafting", Name = "Crafting" })
end

if SERVER then
    util.AddNetworkString("Monarch_SyncSkills")
    util.AddNetworkString("Monarch_SyncSkillRegistry")
    util.AddNetworkString("Monarch_LevelUp")
    util.AddNetworkString("Monarch_SkillXPGain")

    function Skills.SyncToClient(ply)
        if not IsValid(ply) then return end
        local charid = getCharID(ply)
        if not charid then
            return
        end
        ensureLoaded(charid, ply)
        local data = Skills.Data[charid] or {}
        PrintTable(data)

        for id, xp in pairs(data) do
            local lvl = Skills.GetLevelForXP(xp)
            ply:SetNWInt("Skill_" .. id .. "_XP", tonumber(xp) or 0)
            ply:SetNWInt("Skill_" .. id .. "_Level", lvl)
        end

        net.Start("Monarch_SyncSkills")
            local count = 0
            for _ in pairs(data) do count = count + 1 end
            net.WriteUInt(count, 12)
            for id, xp in pairs(data) do
                net.WriteString(tostring(id))
                net.WriteInt(tonumber(xp) or 0, 32)
            end
        net.Send(ply)
    end

    function Skills.SyncRegistryToClient(ply)
        if not IsValid(ply) then return end
        local reg = Skills.Registry or {}
        net.Start("Monarch_SyncSkillRegistry")
            local count = 0
            for _ in pairs(reg) do count = count + 1 end
            net.WriteUInt(count, 12)
            for id, def in pairs(reg) do
                net.WriteString(tostring(id))
                net.WriteString(tostring(def.Name or id))
                local rate = tonumber(def.XPPerSecond or 0) or 0
                net.WriteInt(rate, 16)
            end
        net.Send(ply)
        if Skills.Debug then
        end
    end

    hook.Add("OnCharacterActivated", "Monarch_SkillsSyncOnActivate", function(ply, charData)
        if not IsValid(ply) then return end
        if Skills.SyncRegistryToClient then
            Skills.SyncRegistryToClient(ply)
        end
        if Skills.SyncToClient then
            Skills.SyncToClient(ply)
        end
    end)

    hook.Add("PlayerInitialSpawn", "Monarch_SkillsSyncInitial", function(ply)
        timer.Simple(1, function()
            if not IsValid(ply) then return end
            if Skills.SyncRegistryToClient then Skills.SyncRegistryToClient(ply) end
            if Skills.SyncToClient then Skills.SyncToClient(ply) end
        end)
    end)

    hook.Add("PlayerDisconnected", "Monarch_SkillsClearNW", function(ply)
        if not IsValid(ply) then return end
        for id, _ in pairs(Skills.Registry or {}) do
            ply:SetNWInt("Skill_" .. id .. "_XP", 0)
            ply:SetNWInt("Skill_" .. id .. "_Level", 0)
        end
    end)
else
    local function DebugDumpClientState(tag)
        if not Skills.Debug then return end
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        local now = CurTime()
        local last = Skills._lastDbg["dump"] or 0
        if (now - last) < (Skills._dbgRate or 0.75) then return end
        Skills._lastDbg["dump"] = now
        for id, def in pairs(Skills.Registry or {}) do
            local nxp = ply:GetNWInt("Skill_" .. id .. "_XP", -1)
            local nlvl = ply:GetNWInt("Skill_" .. id .. "_Level", -1)
            local cxp = Skills.ClientData and Skills.ClientData[id] or nil
            local lvl = Skills.GetLevelForXP(cxp or ((nxp >= 0) and nxp or 0))
        end
    end
    net.Receive("Monarch_SyncSkills", function()
        local n = net.ReadUInt(12)
        Skills.ClientData = {}
        for i = 1, n do
            local id = net.ReadString()
            local xp = net.ReadInt(32)
            Skills.ClientData[id] = xp
        end
        hook.Run("Monarch_SkillsUpdated")
        DebugDumpClientState("net")
    end)

    net.Receive("Monarch_SyncSkillRegistry", function()
        local n = net.ReadUInt(12)
        Skills.Registry = Skills.Registry or {}
        for i = 1, n do
            local id = net.ReadString()
            local name = net.ReadString()
            local rate = net.ReadInt(16)
            Skills.Registry[id] = Skills.Registry[id] or {}
            Skills.Registry[id].id = id
            Skills.Registry[id].Name = name
            if rate ~= 0 then Skills.Registry[id].XPPerSecond = rate end
        end
        hook.Run("Monarch_SkillsUpdated")
    end)

    local lastNWValues = {}
    hook.Add("Think", "Monarch_SkillsNWIntMonitor", function()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        local changed = false
        for id, _ in pairs(Skills.Registry or {}) do
            local xpKey = "Skill_" .. id .. "_XP"
            local lvlKey = "Skill_" .. id .. "_Level"
            local curXP = ply:GetNWInt(xpKey, -1)
            local curLvl = ply:GetNWInt(lvlKey, -1)

            if curXP >= 0 then
                local lastXP = lastNWValues[xpKey] or -1
                local lastLvl = lastNWValues[lvlKey] or -1

                if curXP ~= lastXP or curLvl ~= lastLvl then
                    lastNWValues[xpKey] = curXP
                    lastNWValues[lvlKey] = curLvl
                    changed = true
                end
            end
        end

        if changed then
            hook.Run("Monarch_SkillsUpdated")
            DebugDumpClientState("nw")
        end
    end)
end

function Skills.SetXP(ply, skillId, newXP)
    if not SERVER then return end
    if not IsValid(ply) then return end
    newXP = math.max(0, math.floor(tonumber(newXP) or 0))
    local charid = getCharID(ply)
    if not charid then return end
    ensureLoaded(charid, ply)

    local oldXP = tonumber(Skills.Data[charid][skillId] or 0) or 0
    local oldLvl = Skills.GetLevelForXP(oldXP)

    Skills.Data[charid][skillId] = newXP
    persist(charid)

    local newLvl = Skills.GetLevelForXP(newXP)
    ply:SetNWInt("Skill_" .. skillId .. "_XP", newXP)
    ply:SetNWInt("Skill_" .. skillId .. "_Level", newLvl)

    if Skills.SyncToClient then Skills.SyncToClient(ply) end

    if newLvl ~= oldLvl then
        local def = Monarch.GetSkill and Monarch.GetSkill(skillId)
        local skillName = def and def.Name or skillId
        net.Start("Monarch_LevelUp")
            net.WriteString(tostring(skillName))
            net.WriteString(tostring(skillId))
            net.WriteInt(oldLvl, 16)
            net.WriteInt(newLvl, 16)
            net.WriteInt(oldXP, 32)
            net.WriteInt(newXP, 32)
        net.Send(ply)
    end
end
