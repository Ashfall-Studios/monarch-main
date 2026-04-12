if SERVER then
    if Monarch._WhitelistSysLoaded then return end
    Monarch._WhitelistSysLoaded = true

    util.AddNetworkString("Monarch_WhitelistChanged")
    util.AddNetworkString("Monarch_RequestWhitelistSync")
    util.AddNetworkString("Monarch_RankLadder")

    Monarch = Monarch or {}
    Monarch.CharWhitelist = Monarch.CharWhitelist or {}

    local function GlobalDir()
        file.CreateDir("monarch")
        return "monarch"
    end

    local function PersistPath()
        return GlobalDir() .. "/char_whitelists.json"
    end

    local function LoadCharWhitelists()
        local path = PersistPath()
        local map = game.GetMap() or "default"
        if not file.Exists(path, "DATA") then
            local legacy = string.format("monarch/maps/%s/char_whitelists.json", map)
            if file.Exists(legacy, "DATA") then
                local rawLegacy = file.Read(legacy, "DATA") or "{}"
                local okL, tblL = pcall(util.JSONToTable, rawLegacy)
                Monarch.CharWhitelist = (okL and istable(tblL)) and tblL or {}
                file.Write(path, util.TableToJSON(Monarch.CharWhitelist or {}, true))
                return
            end
            Monarch.CharWhitelist = {}
            return
        end
        local raw = file.Read(path, "DATA") or "{}"
        local ok, tbl = pcall(util.JSONToTable, raw)
        if not ok then
            Monarch.CharWhitelist = {}
            return
        end
        Monarch.CharWhitelist = istable(tbl) and tbl or {}
    end

    local function SaveCharWhitelists()
        local path = PersistPath()
        file.Write(path, util.TableToJSON(Monarch.CharWhitelist or {}, true))
    end

    local function CharKey(ply)
        local sid = IsValid(ply) and ply:SteamID64() or ""
        local charid = (IsValid(ply) and (ply.MonarchLastCharID or ply._monarchCharID)) or "__default"
        return sid ~= "" and (sid .. "::" .. tostring(charid)) or ""
    end

    function Monarch.GetWhitelistLevels(ply)
        LoadCharWhitelists()
        local key = CharKey(ply)
        if key == "" then return {} end
        local map = Monarch.CharWhitelist[key] or {}
        return map
    end

    function Monarch.SetWhitelistLevel(ply, teamId, level)
        LoadCharWhitelists()
        local key = CharKey(ply)
        if key == "" then return end
        Monarch.CharWhitelist[key] = Monarch.CharWhitelist[key] or {}
        Monarch.CharWhitelist[key][tonumber(teamId) or 0] = tonumber(level) or 0
        SaveCharWhitelists()
    end

    function Monarch_SetWhitelistNW(ply, teamId, level)
        if not IsValid(ply) then return end
        teamId = tonumber(teamId) or 0
        level = tonumber(level) or 0

        Monarch.SetWhitelistLevel(ply, teamId, level)
        ply:SetNWInt("MonarchWhitelist_" .. teamId, level)
        net.Start("Monarch_WhitelistChanged")
        net.Send(ply)
    end

    function Monarch_SetWhitelistNWBulk(ply, map)
        if not IsValid(ply) then return end
        if type(map) ~= "table" then return end
        for k, v in pairs(map) do
            local teamId = tonumber(k) or 0
            local level = tonumber(v) or 0
            ply:SetNWInt("MonarchWhitelist_" .. teamId, level)
        end
        net.Start("Monarch_WhitelistChanged")
        net.Send(ply)
    end

    net.Receive("Monarch_RequestWhitelistSync", function(_, ply)
        if not IsValid(ply) then return end
        local wl = Monarch.GetWhitelistLevels and Monarch.GetWhitelistLevels(ply) or {}
        wl = wl or {}

        local generic = tonumber(wl[0] or wl.generic or 0) or 0
        ply:SetNWInt("MonarchWhitelist_0", generic)

        for teamId, level in pairs(wl) do
            if isnumber(teamId) and teamId > 0 then
                ply:SetNWInt("MonarchWhitelist_" .. teamId, tonumber(level) or 0)
            end
        end

        net.Start("Monarch_WhitelistChanged")
        net.Send(ply)

        local ladder = {}
        if Monarch and Monarch.RankVendors then
            for _, vend in pairs(Monarch.RankVendors) do
                for _, r in ipairs(vend.ranks or {}) do
                    if r.team and r.whitelistLevel then
                        local tid = tonumber(r.team)
                        if tid then
                            ladder[tid] = ladder[tid] or {}
                            table.insert(ladder[tid], { lvl = tonumber(r.whitelistLevel) or 0, name = r.grouprank or r.name or r.id })
                        end
                    end
                end
            end
            for tid, arr in pairs(ladder) do
                table.SortByMember(arr, "lvl", true)
            end
        end
        net.Start("Monarch_RankLadder")
            net.WriteTable(ladder)
        net.Send(ply)
    end)

    hook.Add("OnCharacterActivated", "Monarch_ApplyPersistedWhitelist", function(ply, charData)
        if not IsValid(ply) then return end
        local wl = Monarch.GetWhitelistLevels and Monarch.GetWhitelistLevels(ply) or {}
        Monarch_SetWhitelistNWBulk(ply, wl)
    end)
end
