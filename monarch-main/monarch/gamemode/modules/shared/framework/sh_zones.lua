Monarch = Monarch or {}
Monarch.Zones = Monarch.Zones or {
    Registry = {},
    Active = {},
}

local Zones = Monarch.Zones

function Zones.Register(zoneId, def)
    if not zoneId or not def then return end
    def.id = zoneId
    Zones.Registry[zoneId] = def

end

function Zones.Get(zoneId)
    return Zones.Registry[zoneId]
end

function Zones.GetAll()
    return Zones.Registry
end

function Zones.GetZoneAt(pos)
    if not isvector(pos) then return nil end
    for zoneId, zone in pairs(Zones.Registry) do
        if zone.pos and zone.size then
            local zpos = isvector(zone.pos) and zone.pos or Vector(zone.pos.x or 0, zone.pos.y or 0, zone.pos.z or 0)
            local zsize = isvector(zone.size) and zone.size or Vector(zone.size.x or 16, zone.size.y or 16, zone.size.z or 16)
            local min = zpos - zsize * 0.5
            local max = zpos + zsize * 0.5
            if pos.x >= min.x and pos.x <= max.x and
               pos.y >= min.y and pos.y <= max.y and
               pos.z >= min.z and pos.z <= max.z then
                return zoneId, zone
            end
        end
    end
    return nil
end

if SERVER then
    util.AddNetworkString("Monarch_ZonesSync")
    util.AddNetworkString("Monarch_ZoneChanged")
    util.AddNetworkString("Monarch_ZoneDelete")
    util.AddNetworkString("Monarch_ZoneTeleport")

    function Zones.SyncToClient(ply)
        if not IsValid(ply) then return end
        net.Start("Monarch_ZonesSync")
            local count = 0
            for _ in pairs(Zones.Registry) do count = count + 1 end
            net.WriteUInt(count, 16)
            for zoneId, zone in pairs(Zones.Registry) do
                net.WriteString(tostring(zoneId))
                net.WriteString(tostring(zone.name or ""))
                net.WriteVector(isvector(zone.pos) and zone.pos or Vector(0,0,0))
                net.WriteVector(isvector(zone.size) and zone.size or Vector(0,0,0))
                net.WriteBool(zone.illegal or false)
            end
        net.Send(ply)
    end

    function Zones.NotifyZoneChange(ply, newZoneId)
        if not IsValid(ply) then return end
        net.Start("Monarch_ZoneChanged")
            net.WriteString(tostring(newZoneId or ""))
        net.Send(ply)
    end
else
    net.Receive("Monarch_ZonesSync", function()
        local count = net.ReadUInt(16)
        Zones.Registry = {}
        for i = 1, count do
            local zoneId = net.ReadString()
            local name = net.ReadString()
            local pos = net.ReadVector()
            local size = net.ReadVector()
            local illegal = net.ReadBool()
            Zones.Registry[zoneId] = {
                id = zoneId,
                name = name,
                pos = pos,
                size = size,
                illegal = illegal,
            }
        end
    end)

    net.Receive("Monarch_ZoneChanged", function()
        local zoneId = net.ReadString()
        if zoneId == "" then zoneId = nil end
        Zones.Active = zoneId
        if zoneId then
            local zone = Zones.Registry[zoneId]
            if zone then
            end
        end
        hook.Run("Monarch_ZoneChanged", zoneId)
    end)
end

function Zones.Load(mapName)
    if CLIENT then return end
    mapName = mapName or game.GetMap()
    local newFileName = string.format("monarch/zones/%s_zones.json", mapName)
    local legacyFileName = string.format("monarch/zones/%s.json", mapName)
    if not file.Exists("monarch/zones", "DATA") then
        file.CreateDir("monarch/zones")
    end
    local chosenFile = nil
    if file.Exists(newFileName, "DATA") then
        chosenFile = newFileName
    elseif file.Exists(legacyFileName, "DATA") then
        chosenFile = legacyFileName
    end
    if chosenFile then
        local raw = file.Read(chosenFile, "DATA") or "{}"

        if string.byte(raw, 1) == 239 and string.byte(raw, 2) == 187 and string.byte(raw, 3) == 191 then
            raw = string.sub(raw, 4)
        end
        local firstBrace = string.find(raw, "[{[]")
        if firstBrace and firstBrace > 1 then
            raw = string.sub(raw, firstBrace)
        end
        local data = util.JSONToTable(raw) or {}
        Zones.Registry = {}
        for zoneId, zone in pairs(data) do
            if istable(zone) then

                local pos = zone.pos
                if istable(pos) and tonumber(pos.x) and tonumber(pos.y) and tonumber(pos.z) then
                    pos = Vector(tonumber(pos.x), tonumber(pos.y), tonumber(pos.z))
                else
                    pos = nil
                end

                local size = zone.size
                if istable(size) and tonumber(size.x) and tonumber(size.y) and tonumber(size.z) then
                    size = Vector(tonumber(size.x), tonumber(size.y), tonumber(size.z))
                else
                    size = nil
                end

                if pos and size then

                    Zones.Registry[zoneId] = {
                        id = zoneId,
                        name = tostring(zone.name or ""),
                        pos = pos,
                        size = size,
                        illegal = zone.illegal or false,
                    }
                else
                    MsgC(Color(255, 150, 150), "[Zones] Skipping malformed zone ", tostring(zoneId), " during load (invalid pos/size)\n")
                end
            end
        end
        MsgC(Color(100, 255, 100), "[Zones] Loaded ", table.Count(Zones.Registry), " zones for ", mapName, "\n")

        if chosenFile == legacyFileName then
            Zones.Save(mapName)
            local backupName = string.format("monarch/zones/%s_legacy_%d.json", mapName, os.time())
            file.Write(backupName, file.Read(legacyFileName, "DATA") or "{}")
        end
    else
        Zones.Registry = {}
        MsgC(Color(255, 180, 60), "[Zones] No zone file found for ", mapName, ", starting with empty registry\n")
    end
end

function Zones.Save(mapName)
    if CLIENT then return end
    mapName = mapName or game.GetMap()
    local fileName = string.format("monarch/zones/%s_zones.json", mapName)
    if not file.Exists("monarch/zones", "DATA") then
        file.CreateDir("monarch/zones")
    end

    if file.Exists(fileName, "DATA") then
        local backupName = string.format("monarch/zones/%s_zones_backup_%d.json", mapName, os.time())
        file.Write(backupName, file.Read(fileName, "DATA") or "{}")
    end

    local function sanitizeVec(vec, fallback)
        fallback = fallback or Vector(0, 0, 0)
        if isvector(vec) then
            local x = tonumber(vec.x) or fallback.x
            local y = tonumber(vec.y) or fallback.y
            local z = tonumber(vec.z) or fallback.z
            return Vector(x, y, z)
        elseif istable(vec) then
            local x = tonumber(vec.x) or fallback.x
            local y = tonumber(vec.y) or fallback.y
            local z = tonumber(vec.z) or fallback.z
            return Vector(x, y, z)
        end
        return fallback
    end

    local validCount = 0
    local data = {}
    for zoneId, zone in pairs(Zones.Registry) do

        local posVec = sanitizeVec(zone.pos)
        local sizeVec = sanitizeVec(zone.size, Vector(16, 16, 16))

        if posVec and sizeVec then
            data[zoneId] = {
                name = zone.name,
                pos = { x = posVec.x, y = posVec.y, z = posVec.z },
                size = { x = sizeVec.x, y = sizeVec.y, z = sizeVec.z },
                illegal = zone.illegal or false,
            }
            validCount = validCount + 1
        else
            MsgC(Color(255, 150, 150), "[Zones] Skipping invalid zone ", tostring(zoneId), " (missing position/size)\n")
        end
    end
    local json = util.TableToJSON(data, true)
    if not isstring(json) then
        MsgC(Color(255, 50, 50), "[Zones] Failed to encode zones to JSON; aborting write to avoid corruption\n")
        return
    end

    file.Write(fileName, json)

    local zoneCount = validCount
end

if SERVER then
    hook.Add("InitPostEntity", "Monarch_ZonesLoad", function()
        Zones.Load()
    end)

    hook.Add("PlayerInitialSpawn", "Monarch_ZonesSync", function(ply)
        timer.Simple(0.5, function()
            if IsValid(ply) then
                Zones.SyncToClient(ply)
            end
        end)
    end)

    hook.Add("Think", "Monarch_ZoneTracking", function()
        for _, ply in player.Iterator() do
            if IsValid(ply) then
                local newZoneId = Zones.GetZoneAt(ply:GetPos())
                local oldZoneId = ply._CurrentZoneId
                if newZoneId ~= oldZoneId then
                    ply._CurrentZoneId = newZoneId
                    Zones.NotifyZoneChange(ply, newZoneId)
                end
            end
        end
    end)
end
