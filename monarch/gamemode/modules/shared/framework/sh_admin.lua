Monarch = Monarch or {}
Monarch.Ranks = Monarch.Ranks or {}

Monarch.Ranks.Config = Monarch.Ranks.Config or {
    ranks = {
        {
            id = "owner",
            name = "Owner",
            color = Color(255, 0, 0, 255),
            permission = "superadmin",
            order = 100
        },
        {
            id = "operator",
            name = "Operator",
            color = Color(255, 10, 10, 255),
            permission = "superadmin",
            order = 90
        },
        {
            id = "director",
            name = "Director",
            color = Color(255, 30, 30, 255),
            permission = "superadmin",
            order = 85
        },
        {
            id = "superadmin",
            name = "Super Admin",
            color = Color(255, 50, 50, 255),
            permission = "superadmin",
            order = 80
        },
        {
            id = "senioradmin",
            name = "Senior Admin",
            color = Color(255, 165, 0, 255),
            permission = "admin",
            order = 70
        },
        {
            id = "admin",
            name = "Admin",
            color = Color(0, 255, 200, 255),
            permission = "admin",
            order = 60
        },
        {
            id = "jradmin",
            name = "Junior Admin",
            color = Color(100, 150, 255, 255),
            permission = "admin",
            order = 50
        },
        {
            id = "moderator",
            name = "Moderator",
            color = Color(150, 255, 150, 255),
            permission = "admin",
            order = 40
        },
        {
            id = "trialmod",
            name = "Trial Moderator",
            color = Color(180, 255, 180, 255),
            permission = "admin",
            order = 30
        },
        {
            id = "vip",
            name = "VIP",
            color = Color(255, 215, 0, 255),
            permission = "user",
            order = 20
        },
        {
            id = "donator",
            name = "Donator",
            color = Color(255, 255, 100, 255),
            permission = "user",
            order = 15
        },
        {
            id = "supporter",
            name = "Supporter",
            color = Color(255, 200, 100, 255),
            permission = "user",
            order = 10
        },
        {
            id = "user",
            name = "User",
            color = Color(255, 255, 255, 255),
            permission = "user",
            order = 1
        }
    }
}

if SERVER then
    local function RegisterULXGroup(id, inherits)
        if ULib and ULib.ucl and ULib.ucl.addGroup then
            inherits = inherits or "user"
            if not (ULib.ucl.groups and ULib.ucl.groups[id]) then
                ULib.ucl.addGroup(id, inherits)
            end
        end
    end 
    local function RegisterCAMIGroup(id, displayName, inherits)
        if CAMI and CAMI.RegisterUsergroup then
            local ug = { Name = id, DisplayName = displayName or id, Inherits = inherits or "user" }
            pcall(function() CAMI.RegisterUsergroup(ug, "Monarch") end)
        end
    end 
    function Monarch.Ranks.RegisterGroups()
        for _, rank in ipairs(Monarch.Ranks.Config.ranks or {}) do
            local id = string.lower(rank.id or "")
            if id ~= "" then
                local inh = "user"
                local perm = string.lower(rank.permission or "user")
                if perm == "admin" then inh = "admin" elseif perm == "superadmin" then inh = "superadmin" end
                RegisterULXGroup(id, inh)
                RegisterCAMIGroup(id, rank.name or id, inh)
            end
        end
    end
    function Monarch.Ranks.Load()
        if not file.Exists("monarch", "DATA") then
            file.CreateDir("monarch")
        end

        local path = "monarch/ranks_config.txt"
        if file.Exists(path, "DATA") then
            local raw = file.Read(path, "DATA")
            local data = util.JSONToTable(raw or "{}") or {}
            if data.ranks and #data.ranks > 0 then
                Monarch.Ranks.Config = data
            end
        else
            Monarch.Ranks.Save()
        end
        Monarch.Ranks.RegisterGroups()
    end

    function Monarch.Ranks.Save()
        if not file.Exists("monarch", "DATA") then
            file.CreateDir("monarch")
        end

        local path = "monarch/ranks_config.txt"
        local json = util.TableToJSON(Monarch.Ranks.Config, true)
        file.Write(path, json)
    end

    Monarch.Ranks.Load()
end

function Monarch.Ranks.Get(id)
    id = string.lower(tostring(id or ""))
    for _, rank in ipairs(Monarch.Ranks.Config.ranks or {}) do
        if string.lower(rank.id or "") == id then
            return rank
        end
    end
    return nil
end

function Monarch.Ranks.GetColor(id)
    local rank = Monarch.Ranks.Get(id)
    if rank and rank.color then
        return rank.color
    end
    return Color(255, 255, 255, 255)
end

function Monarch.Ranks.GetOrder(id)
    local rank = Monarch.Ranks.Get(id)
    if rank and rank.order then
        return rank.order
    end
    return 1
end

function Monarch.Ranks.GetPermission(id)
    local rank = Monarch.Ranks.Get(id)
    if rank and rank.permission then
        return rank.permission
    end
    return "user"
end

function Monarch.Ranks.IsAdmin(id)
    local perm = Monarch.Ranks.GetPermission(id)
    return perm == "admin" or perm == "superadmin"
end

function Monarch.Ranks.IsSuperAdmin(id)
    return Monarch.Ranks.GetPermission(id) == "superadmin"
end

function Monarch.Ranks.GetAll()
    local sorted = {}
    for _, rank in ipairs(Monarch.Ranks.Config.ranks or {}) do
        table.insert(sorted, rank)
    end
    table.sort(sorted, function(a, b)
        return (a.order or 0) > (b.order or 0)
    end)
    return sorted
end

function Monarch.Ranks.GetAdminGroups()
    local groups = {}
    for _, rank in ipairs(Monarch.Ranks.Config.ranks or {}) do
        local perm = rank.permission or "user"
        if perm == "admin" or perm == "superadmin" then
            groups[string.lower(rank.id)] = true
        end
    end
    return groups
end

function Monarch.Ranks.GetSuperAdminGroups()
    local groups = {}
    for _, rank in ipairs(Monarch.Ranks.Config.ranks or {}) do
        if (rank.permission or "user") == "superadmin" then
            groups[string.lower(rank.id)] = true
        end
    end
    return groups
end

if SERVER then
    util.AddNetworkString("Monarch_Ranks_Sync")
    util.AddNetworkString("Monarch_Ranks_Add")
    util.AddNetworkString("Monarch_Ranks_Remove")
    util.AddNetworkString("Monarch_Ranks_RequestSync")

    function Monarch.Ranks.AddOrUpdate(rankData)
        local id = string.lower(tostring(rankData.id or ""))
        if id == "" then return false end

        local found = false
        for i, rank in ipairs(Monarch.Ranks.Config.ranks or {}) do
            if string.lower(rank.id or "") == id then
                Monarch.Ranks.Config.ranks[i] = rankData
                found = true
                break
            end
        end

        if not found then
            table.insert(Monarch.Ranks.Config.ranks, rankData)
        end

        Monarch.Ranks.Save()
        Monarch.Ranks.RegisterGroups()
        Monarch.Ranks.SyncToAll()
        return true
    end

    function Monarch.Ranks.Remove(id)
        id = string.lower(tostring(id or ""))
        for i, rank in ipairs(Monarch.Ranks.Config.ranks or {}) do
            if string.lower(rank.id or "") == id then
                table.remove(Monarch.Ranks.Config.ranks, i)
                Monarch.Ranks.Save()
                Monarch.Ranks.RegisterGroups()
                Monarch.Ranks.SyncToAll()
                return true
            end
        end
        return false
    end

    function Monarch.Ranks.SyncToClient(ply)
        if not IsValid(ply) then return end
        net.Start("Monarch_Ranks_Sync")
            net.WriteTable(Monarch.Ranks.Config)
        net.Send(ply)
    end

    function Monarch.Ranks.SyncToAll()
        net.Start("Monarch_Ranks_Sync")
            net.WriteTable(Monarch.Ranks.Config)
        net.Broadcast()
    end

    hook.Add("PlayerInitialSpawn", "Monarch_Ranks_Sync", function(ply)
        timer.Simple(1, function()
            if IsValid(ply) then
                Monarch.Ranks.SyncToClient(ply)
            end
        end)
    end)

    net.Receive("Monarch_Ranks_Add", function(_, ply)
        if not IsValid(ply) or not ply:IsSuperAdmin() then return end

        local rankData = net.ReadTable() or {}
    end)

    net.Receive("Monarch_Ranks_Remove", function(_, ply)
        if not IsValid(ply) or not ply:IsSuperAdmin() then return end

        local id = net.ReadString()
    end)

    net.Receive("Monarch_Ranks_RequestSync", function(_, ply)
        if not IsValid(ply) then return end
        Monarch.Ranks.SyncToClient(ply)
    end)
else
    net.Receive("Monarch_Ranks_Sync", function()
        Monarch.Ranks.Config = net.ReadTable() or Monarch.Ranks.Config
        hook.Run("Monarch_RanksUpdated")
    end)
end
