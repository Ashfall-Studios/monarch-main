Monarch = Monarch or {}
Monarch.Zones = Monarch.Zones or { Registry = {} }
local Zones = Monarch.Zones

if SERVER then

    concommand.Add("monarch_zone_delete", function(ply, cmd, args)
        if not ply:IsAdmin() then
            ply:ChatPrint("Admin only!")
            return
        end

        local zoneId = args[1]
        if not zoneId then
            ply:ChatPrint("Usage: monarch_zone_delete <zone_id>")
            return
        end

        Zones.Registry[zoneId] = nil
        Zones.Save()

        for _, p in player.Iterator() do
            Zones.SyncToClient(p)
        end

        ply:ChatPrint("Deleted zone: " .. zoneId)
    end)

    concommand.Add("monarch_zone_rename", function(ply, cmd, args)
        if not ply:IsAdmin() then
            ply:ChatPrint("Admin only!")
            return
        end

        local zoneId = args[1]
        local newName = table.concat(args, " ", 2)

        if not zoneId or not newName or newName == "" then
            ply:ChatPrint("Usage: monarch_zone_rename <zone_id> <new_name>")
            return
        end

        if not Zones.Registry[zoneId] then
            ply:ChatPrint("Zone not found: " .. zoneId)
            return
        end

        Zones.Registry[zoneId].name = newName
        Zones.Save()

        for _, p in player.Iterator() do
            Zones.SyncToClient(p)
        end

        ply:ChatPrint("Renamed zone " .. zoneId .. " to: " .. newName)
    end)

    concommand.Add("monarch_zone_illegal", function(ply, cmd, args)
        if not ply:IsAdmin() then
            ply:ChatPrint("Admin only!")
            return
        end

        local zoneId = args[1]
        if not zoneId then
            ply:ChatPrint("Usage: monarch_zone_illegal <zone_id>")
            return
        end

        if not Zones.Registry[zoneId] then
            ply:ChatPrint("Zone not found: " .. zoneId)
            return
        end

        Zones.Registry[zoneId].illegal = not Zones.Registry[zoneId].illegal
        Zones.Save()

        for _, p in player.Iterator() do
            Zones.SyncToClient(p)
        end

        local status = Zones.Registry[zoneId].illegal and "marked ILLEGAL" or "marked LEGAL"
        ply:ChatPrint("Zone " .. zoneId .. " " .. status)
    end)

    concommand.Add("monarch_zone_create", function(ply, cmd, args)
        if not ply:IsAdmin() then
            ply:ChatPrint("Admin only!")
            return
        end

        local zoneId = args[1]
        local zoneName = table.concat(args, " ", 2)

        if not zoneId or not zoneName or zoneName == "" then
            ply:ChatPrint("Usage: monarch_zone_create <zone_id> <zone_name>")
            return
        end

        if Zones.Registry[zoneId] then
            ply:ChatPrint("Zone ID already exists: " .. zoneId)
            return
        end

        local pos = ply:GetPos()
        local size = Vector(512, 512, 256)

        Zones.Register(zoneId, {
            name = zoneName,
            pos = pos,
            size = size,
            illegal = false
        })

        Zones.Save()

        for _, p in player.Iterator() do
            Zones.SyncToClient(p)
        end

        ply:ChatPrint("Created zone: " .. zoneId .. " (" .. zoneName .. ") at your position")
    end)

    hook.Add("PlayerInitialSpawn", "Monarch_ZonesSyncJoin", function(ply)
        timer.Simple(1, function()
            if IsValid(ply) then
                Zones.SyncToClient(ply)
            end
        end)
    end)

    net.Receive("Monarch_ZoneTeleport", function(len, ply)
        if not IsValid(ply) or not ply:IsAdmin() then
            ply:ChatPrint("Admin only!")
            return
        end

        local zoneId = net.ReadString()
        local zone = Zones.Get(zoneId)

        if not zone or not zone.pos then
            ply:ChatPrint("Zone not found or has no position: " .. zoneId)
            return
        end

        local teleportPos = isvector(zone.pos) and zone.pos or Vector(zone.pos.x or 0, zone.pos.y or 0, zone.pos.z or 0)
        ply:SetPos(teleportPos)
        ply:SetVelocity(Vector(0, 0, 0))
    end)

    net.Receive("Monarch_ZoneDelete", function(len, ply)
        if not IsValid(ply) or not ply:IsAdmin() then
            ply:ChatPrint("Admin only!")
            return
        end

        local zoneId = net.ReadString()

        if not Zones.Registry[zoneId] then
            ply:ChatPrint("Zone not found: " .. zoneId)
            return
        end

        local zoneName = Zones.Registry[zoneId].name or zoneId
        Zones.Registry[zoneId] = nil
        Zones.Save()

        for _, p in player.Iterator() do
            Zones.SyncToClient(p)
        end

    end)
end
